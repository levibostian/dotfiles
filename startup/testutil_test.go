package main

import (
	"os"
	"path/filepath"
	"testing"
	"time"
)

// writeChild drops an executable script into a bins dir.
func writeChild(t *testing.T, dir, name, body string) {
	t.Helper()
	if err := os.WriteFile(filepath.Join(dir, name), []byte(body), 0o755); err != nil {
		t.Fatalf("write %s: %v", name, err)
	}
}

// fastChildBody exits immediately every run, so it trips the fast-fail path.
const fastChildBody = "#!/bin/sh\nexit 0\n"

// healthyChildBody runs until killed, so it never fast-fails.
const healthyChildBody = "#!/bin/sh\nwhile true; do sleep 1; done\n"

// logChildBody prints once then stays alive, so its log records merged output
// and (being a healthy long-runner) is not re-truncated by a fast-fail restart
// mid-test, which would make log assertions flaky.
const logChildBody = "#!/bin/sh\necho hello from child\nwhile true; do sleep 1; done\n"

// testConfig returns a manager config with short timings so the supervisor
// loop makes observable progress in a fraction of a second. Logs go to a
// throwaway temp dir, not /tmp.
func testConfig(t *testing.T) Config {
	t.Helper()
	return Config{
		FastFailWindow: 250 * time.Millisecond,
		MaxFastFails:   3,
		RetryDelay:     5 * time.Millisecond,
		LogDir:         t.TempDir(),
	}
}

// newManager builds a Manager over a fresh temp bins dir with the given
// executable children and registers it for shutdown so no supervisor
// goroutines outlive the test.
func newManager(t *testing.T, names map[string]string) *Manager {
	t.Helper()
	dir := t.TempDir()
	for name, body := range names {
		writeChild(t, dir, name, body)
	}
	m := NewManager(dir, testConfig(t))
	t.Cleanup(m.Shutdown)
	return m
}

// waitFor polls condition until it is true or the timeout elapses.
func waitFor(t *testing.T, timeout time.Duration, what string, cond func() bool) {
	t.Helper()
	deadline := time.Now().Add(timeout)
	for time.Now().Before(deadline) {
		if cond() {
			return
		}
		time.Sleep(10 * time.Millisecond)
	}
	t.Fatalf("timed out waiting for %s", what)
}
