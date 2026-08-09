package main

import (
	"io"
	"net"
	"os"
	"strings"
	"testing"
	"time"
)

// serveTestCLI points sockAddr at a throwaway unix socket served by the real
// control plane, so the CLI commands can be exercised end to end.
func serveTestCLI(t *testing.T, m *Manager) {
	t.Helper()
	old := sockAddr
	sockAddr = testSockPath(t)
	ln, err := net.Listen("unix", sockAddr)
	if err != nil {
		t.Fatal(err)
	}
	m.reload()
	go serve(ln, m)
	t.Cleanup(func() {
		sockAddr = old
		_ = ln.Close()
		time.Sleep(20 * time.Millisecond) // let supervise goroutines drain
	})
}

func captureStdout(t *testing.T, fn func()) string {
	t.Helper()
	old := os.Stdout
	r, w, err := os.Pipe()
	if err != nil {
		t.Fatal(err)
	}
	os.Stdout = w
	defer func() { os.Stdout = old }()
	fn()
	_ = w.Close()
	data, _ := io.ReadAll(r)
	return string(data)
}

func TestUsageOutput(t *testing.T) {
	out := captureStdout(t, usage)
	for _, want := range []string{"daemon", "install", "uninstall", "restart", "status"} {
		if !strings.Contains(out, want) {
			t.Fatalf("usage output missing %q:\n%s", want, out)
		}
	}
}

func TestMainDispatchesHelp(t *testing.T) {
	oldArgs := os.Args
	os.Args = []string{"startup", "help"}
	defer func() { os.Args = oldArgs }()
	out := captureStdout(t, func() { main() })
	if !strings.Contains(out, "daemon") || !strings.Contains(out, "status") {
		t.Fatalf("main(help) did not print usage:\n%s", out)
	}
}

func TestSendCmdStatus(t *testing.T) {
	m := newManager(t, map[string]string{"web": healthyChildBody})
	serveTestCLI(t, m)
	waitFor(t, 3*time.Second, "web running", func() bool { return m.report().find("web").Running })

	resp, err := sendCmd("status")
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(resp, `"name":"web"`) || !strings.Contains(resp, `"running":true`) {
		t.Fatalf("status response unexpected: %q", resp)
	}
}

func TestDoRestartOutputsOK(t *testing.T) {
	m := newManager(t, map[string]string{"boom": fastChildBody})
	serveTestCLI(t, m)
	waitFor(t, 3*time.Second, "boom to give up", func() bool { return m.report().find("boom").GivingUp })

	out := captureStdout(t, doRestart)
	if strings.TrimSpace(out) != "ok" {
		t.Fatalf("doRestart output = %q, want ok", out)
	}
	// restart resets boom's counter to zero
	waitFor(t, 2*time.Second, "boom reset", func() bool { return m.report().find("boom").FastFails == 0 })
}

func TestDoStatusPrintsChildState(t *testing.T) {
	m := newManager(t, map[string]string{"web": healthyChildBody})
	serveTestCLI(t, m)
	waitFor(t, 3*time.Second, "web running", func() bool { return m.report().find("web").Running })

	out := captureStdout(t, doStatus)
	for _, want := range []string{"web", "running"} {
		if !strings.Contains(out, want) {
			t.Fatalf("doStatus output missing %q:\n%s", want, out)
		}
	}
}
