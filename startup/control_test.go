package main

import (
	"encoding/json"
	"fmt"
	"net"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

// --- unit: handleConn over an in-memory pipe ---

func TestHandleConnStatus(t *testing.T) {
	m := newManager(t, map[string]string{"web": healthyChildBody})
	m.reload()
	waitFor(t, 3*time.Second, "web running", func() bool { return m.report().find("web").Running })

	client, server := net.Pipe()
	defer client.Close()
	go handleConn(server, m)

	if _, err := fmt.Fprintln(client, "status"); err != nil {
		t.Fatal(err)
	}
	var rep Report
	if err := json.NewDecoder(client).Decode(&rep); err != nil {
		t.Fatalf("decode status: %v", err)
	}
	st := rep.find("web")
	if !st.Running {
		t.Fatalf("expected web running in status, got %+v", st)
	}
}

func TestHandleConnRestart(t *testing.T) {
	m := newManager(t, map[string]string{"boom": fastChildBody})
	m.reload()
	waitFor(t, 3*time.Second, "boom to give up", func() bool { return m.report().find("boom").GivingUp })

	client, server := net.Pipe()
	defer client.Close()
	go handleConn(server, m)

	if _, err := fmt.Fprintln(client, "restart"); err != nil {
		t.Fatal(err)
	}
	reply, err := readAllConn(client)
	if err != nil {
		t.Fatal(err)
	}
	if strings.TrimSpace(reply) != "ok" {
		t.Fatalf("restart reply = %q, want ok", reply)
	}
	// after restart, boom's counter is reset to zero
	waitFor(t, 2*time.Second, "boom reset by restart", func() bool {
		st := m.report().find("boom")
		return !st.GivingUp && st.FastFails == 0
	})
}

func TestHandleConnUnknown(t *testing.T) {
	m := newManager(t, nil)
	m.reload()

	client, server := net.Pipe()
	defer client.Close()
	go handleConn(server, m)

	if _, err := fmt.Fprintln(client, "bogus"); err != nil {
		t.Fatal(err)
	}
	reply, err := readAllConn(client)
	if err != nil {
		t.Fatal(err)
	}
	if strings.TrimSpace(reply) != "unknown command" {
		t.Fatalf("unknown reply = %q", reply)
	}
}

// --- integration: the full control plane over a real unix socket ---

func TestSocketStatusAndRestart(t *testing.T) {
	m := newManager(t, map[string]string{"web": healthyChildBody, "boom": fastChildBody})
	sock := testSockPath(t)
	ln, err := net.Listen("unix", sock)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { ln.Close() })

	m.reload()
	go serve(ln, m)
	t.Cleanup(func() { time.Sleep(20 * time.Millisecond) })

	waitFor(t, 3*time.Second, "web running", func() bool {
		return m.report().find("web").Running
	})
	waitFor(t, 3*time.Second, "boom to give up", func() bool {
		return m.report().find("boom").GivingUp
	})

	// status over the socket reports both children
	body := socketCmd(t, sock, "status")
	var rep Report
	if err := json.Unmarshal([]byte(body), &rep); err != nil {
		t.Fatalf("status over socket: %v (%q)", err, body)
	}
	st := rep.find("boom")
	if !st.GivingUp {
		t.Fatalf("boom should be giving up over socket status, got %+v", st)
	}

	// restart resets boom
	reply := socketCmd(t, sock, "restart")
	if strings.TrimSpace(reply) != "ok" {
		t.Fatalf("restart reply = %q", reply)
	}
	waitFor(t, 2*time.Second, "boom reset after socket restart", func() bool {
		return m.report().find("boom").FastFails == 0
	})
}

// TestSocketRescanNewChild proves an add + restart picks up a not-yet-known
// child, e.g. a bin dropped in at runtime.
func TestSocketRescanNewChild(t *testing.T) {
	m := newManager(t, map[string]string{"a": healthyChildBody})
	sock := testSockPath(t)
	ln, err := net.Listen("unix", sock)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { ln.Close() })

	m.reload()
	go serve(ln, m)
	t.Cleanup(func() { time.Sleep(20 * time.Millisecond) })

	waitFor(t, 3*time.Second, "a running", func() bool { return m.report().find("a").Running })

	writeChild(t, m.dir, "b", healthyChildBody)
	if reply := socketCmd(t, sock, "restart"); strings.TrimSpace(reply) != "ok" {
		t.Fatalf("restart reply = %q", reply)
	}
	waitFor(t, 3*time.Second, "b supervised after restart", func() bool {
		return m.report().find("b").Running
	})
}

// --- helpers ---

func readAllConn(conn net.Conn) (string, error) {
	buf := make([]byte, 0, 512)
	tmp := make([]byte, 512)
	for {
		n, err := conn.Read(tmp)
		buf = append(buf, tmp[:n]...)
		if err != nil {
			return string(buf), nil // conn closed by server
		}
	}
}

// testSockPath returns a short unix socket path (temp-dir paths are too long
// for the ~100-byte sun_path limit) and cleans it up after the test.
func testSockPath(t *testing.T) string {
	t.Helper()
	sock := filepath.Join(os.TempDir(), fmt.Sprintf("st-%d.sock", os.Getpid()))
	t.Cleanup(func() { _ = os.Remove(sock) })
	return sock
}

// socketCmd dials a unix socket, sends one command line, and returns the raw
// response.
func socketCmd(t *testing.T, sock, cmd string) string {
	t.Helper()
	conn, err := net.Dial("unix", sock)
	if err != nil {
		t.Fatalf("dial %s: %v", sock, err)
	}
	defer conn.Close()
	if _, err := fmt.Fprintln(conn, cmd); err != nil {
		t.Fatal(err)
	}
	body, err := readAllConn(conn)
	if err != nil {
		t.Fatal(err)
	}
	return body
}
