package main

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

func main() {
	cmd := "status"
	if len(os.Args) > 1 {
		cmd = os.Args[1]
	}
	switch cmd {
	case "daemon":
		runDaemon()
	case "install":
		doInstall()
	case "uninstall":
		doUninstall()
	case "restart":
		doRestart()
	case "status":
		doStatus()
	case "help", "-h", "--help":
		usage()
	default:
		log.Fatalf("unknown command %q (try 'startup help')", cmd)
	}
}

func usage() {
	fmt.Println(`usage: startup <command>

  daemon     run the supervisor loop (launchd entry point)
  install    write + load the LaunchAgent plist
  uninstall  unload + remove the plist
  restart    tell the running daemon to reload bins/ and restart all children
  status     query the running daemon for child state`)
}

const plistTemplate = `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>com.startup</string>
	<key>ProgramArguments</key>
	<array>
		<string>{{BIN}}</string>
		<string>daemon</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
	<key>KeepAlive</key>
	<true/>
	<key>EnvironmentVariables</key>
	<dict>
		<key>PATH</key>
		<string>{{PATH}}</string>
	</dict>
</dict>
</plist>
`

// minimalPath returns a small, predictable PATH for children. launchd gives
// the daemon a bare PATH (/usr/bin:/bin:/usr/sbin:/sbin), which children
// inherit — so user-installed binaries (mise, homebrew) are invisible. Rather
// than dumping a machine-specific login PATH into the plist, we construct a
// minimal one from stable locations, the same approach .cronjobs/sync-jobs
// uses. These dirs may not all exist; that is harmless.
func minimalPath() string {
	home, err := os.UserHomeDir()
	if err != nil {
		log.Fatalf("home dir: %v", err)
	}
	return strings.Join([]string{
		filepath.Join(home, ".local", "share", "mise", "shims"),
		filepath.Join(home, ".local", "bin"),
		filepath.Join(home, ".binnys"),
		"/opt/homebrew/bin",
		"/opt/homebrew/sbin",
		"/usr/local/bin",
		"/usr/bin",
		"/bin",
		"/usr/sbin",
		"/sbin",
	}, ":")
}

// plistDirOverride and launchctl are seams so install/uninstall can be tested
// without touching the real LaunchAgents dir or launchd. They are only ever
// set from tests.
var (
	plistDirOverride = ""
	launchctl        = func(args ...string) error {
		return exec.Command("launchctl", args...).Run()
	}
)

func plistPath() string {
	home, err := os.UserHomeDir()
	if err != nil {
		log.Fatalf("home dir: %v", err)
	}
	base := filepath.Join(home, "Library", "LaunchAgents")
	if plistDirOverride != "" {
		base = plistDirOverride
	}
	return filepath.Join(base, "com.startup.plist")
}

func plistContent(exe string) string {
	content := strings.ReplaceAll(plistTemplate, "{{BIN}}", exe)
	return strings.ReplaceAll(content, "{{PATH}}", minimalPath())
}

func doInstall() {
	exe, err := os.Executable()
	if err != nil {
		log.Fatalf("resolve binary path: %v", err)
	}
	path := plistPath()
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		log.Fatalf("mkdir plist dir: %v", err)
	}
	content := plistContent(exe)
	if err := os.WriteFile(path, []byte(content), 0o644); err != nil {
		log.Fatalf("write plist: %v", err)
	}
	if err := launchctl("load", path); err != nil {
		log.Fatalf("launchctl load: %v", err)
	}
	fmt.Printf("installed %s\n", path)
}

func doUninstall() {
	path := plistPath()
	_ = launchctl("unload", path)
	if err := os.Remove(path); err != nil && !os.IsNotExist(err) {
		log.Fatalf("remove plist: %v", err)
	}
	fmt.Println("uninstalled")
}

// sendCmd dials the daemon socket, writes a single command line, and returns
// the full response (the connection is closed after replying).
func sendCmd(cmd string) (string, error) {
	conn, err := net.Dial("unix", sockAddr)
	if err != nil {
		return "", err
	}
	defer conn.Close()
	if _, err := fmt.Fprintln(conn, cmd); err != nil {
		return "", err
	}
	data, err := io.ReadAll(conn)
	return string(data), err
}

func doRestart() {
	resp, err := sendCmd("restart")
	if err != nil {
		log.Fatalf("daemon not running (%v) — try 'startup install'", err)
	}
	fmt.Print(resp)
}

func doStatus() {
	resp, err := sendCmd("status")
	if err != nil {
		log.Fatalf("daemon not running (%v) — try 'startup install'", err)
	}
	var rep Report
	if err := json.Unmarshal([]byte(resp), &rep); err != nil {
		log.Fatalf("parse status: %v", err)
	}
	if len(rep.Children) == 0 {
		fmt.Println("no children in bins/")
		return
	}
	fmt.Printf("%-12s %-8s %-10s %s\n", "name", "running", "fastfails", "state")
	for _, c := range rep.Children {
		state := "down"
		switch {
		case c.Running:
			state = "running"
		case c.GivingUp:
			state = "gave up"
		}
		fmt.Printf("%-12s %-8v %-10d %s\n", c.Name, c.Running, c.FastFails, state)
	}
}
