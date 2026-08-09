package main

import (
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
	"time"
)

// --- unit: child state machine ---

func TestChildFastFailCounting(t *testing.T) {
	c := &Child{Name: "x"}
	if c.failCount() != 0 {
		t.Fatalf("new child should have 0 fast fails, got %d", c.failCount())
	}
	c.fail()
	c.fail()
	if c.failCount() != 2 {
		t.Fatalf("want 2 fast fails, got %d", c.failCount())
	}
	if c.gaveUp(3) { // 2 fails is below the limit of 3
		t.Fatal("gave up too early with 2 fast fails")
	}
	if !c.gaveUp(2) {
		t.Fatal("expected gave up at exactly 2 fast fails")
	}
	c.resetFails()
	if c.failCount() != 0 || c.gaveUp(1) {
		t.Fatalf("reset should clear count, got %d", c.failCount())
	}
}

func TestChildSetRunningFlag(t *testing.T) {
	c := &Child{Name: "x"}
	if c.status().Running {
		t.Fatal("not running before start")
	}
	c.setRunning(true)
	if !c.status().Running {
		t.Fatal("should be running after setRunning")
	}
	c.setRunning(false)
	if c.status().Running {
		t.Fatal("should stop running after clear")
	}
}

// --- unit: scanBins filtering ---

func TestScanBins(t *testing.T) {
	dir := t.TempDir()
	writeChild(t, dir, "db", fastChildBody)
	writeChild(t, dir, "webapp", fastChildBody)
	// asset: has a dot -> ignored
	writeChild(t, dir, "config.json", fastChildBody)
	// not executable -> ignored even with no dot
	if err := os.WriteFile(filepath.Join(dir, "notexec"), []byte("#!/bin/sh\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	// a directory with no dot -> ignored
	if err := os.Mkdir(filepath.Join(dir, "srv"), 0o755); err != nil {
		t.Fatal(err)
	}

	m := NewManager(dir, testConfig(t))
	got := m.scanBins()
	want := []string{"db", "webapp"} // alphabetical; config.json/notexec/srv excluded
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("scanBins = %v, want %v", got, want)
	}
}

func TestScanBinsMissingDir(t *testing.T) {
	m := NewManager(filepath.Join(t.TempDir(), "nope"), testConfig(t))
	if got := m.scanBins(); got != nil {
		t.Fatalf("scanBins on missing dir should be nil, got %v", got)
	}
}

// --- unit: binsDir resolution ---

func TestBinsDir(t *testing.T) {
	exe, err := os.Executable()
	if err != nil {
		t.Fatal(err)
	}
	if want := filepath.Join(filepath.Dir(exe), "bins"); binsDir() != want {
		t.Fatalf("binsDir() = %q, want %q", binsDir(), want)
	}
}

// --- unit: report ordering and empty state ---

func TestNewManagerAppliesDefaults(t *testing.T) {
	dir := t.TempDir()
	m := NewManager(dir, Config{})
	def := defaultConfig()
	if m.dir != dir {
		t.Fatalf("dir not preserved: %q", m.dir)
	}
	if m.cfg != def {
		t.Fatalf("zero Config should fall back to defaults, got %+v want %+v", m.cfg, def)
	}

	// partial config keeps explicit fields, fills the rest
	m2 := NewManager(dir, Config{FastFailWindow: time.Second, LogDir: "/x"})
	if m2.cfg.FastFailWindow != time.Second || m2.cfg.LogDir != "/x" {
		t.Fatalf("explicit fields lost: %+v", m2.cfg)
	}
	if m2.cfg.MaxFastFails != def.MaxFastFails || m2.cfg.RetryDelay != def.RetryDelay {
		t.Fatalf("defaults not applied: %+v", m2.cfg)
	}
}

func TestChildCount(t *testing.T) {
	m := newManager(t, map[string]string{"a": fastChildBody, "b": fastChildBody})
	if m.childCount() != 0 {
		t.Fatalf("pre-reload: want 0, got %d", m.childCount())
	}
	m.reload()
	if m.childCount() != 2 {
		t.Fatalf("post-reload: want 2, got %d", m.childCount())
	}
}

func TestReportEmptyAndSorted(t *testing.T) {
	m := newManager(t, map[string]string{"b": fastChildBody, "a": fastChildBody, "c": fastChildBody})
	m.reload()
	rep := m.report()
	if len(rep.Children) != 3 {
		t.Fatalf("want 3 children in report, got %d", len(rep.Children))
	}
	for i := 1; i < len(rep.Children); i++ {
		if rep.Children[i-1].Name >= rep.Children[i].Name {
			t.Fatalf("children not sorted: %v", rep.Children)
		}
	}

	empty := NewManager(t.TempDir(), testConfig(t))
	if r := empty.report(); len(r.Children) != 0 {
		t.Fatalf("empty manager report should have no children, got %v", r.Children)
	}
}

// --- integration: supervisor loop behaviour (fast) ---

func TestSuperviseGivesUpOnFastFails(t *testing.T) {
	m := newManager(t, map[string]string{"boom": fastChildBody})
	m.reload()

	waitFor(t, 3*time.Second, "boom to give up", func() bool {
		return m.report().find("boom").GivingUp
	})

	st := m.report().find("boom")
	if st.FastFails != m.cfg.MaxFastFails {
		t.Fatalf("boom FastFails = %d, want %d", st.FastFails, m.cfg.MaxFastFails)
	}
	if st.Running {
		t.Fatal("a given-up child should not be running")
	}
}

func TestSuperviseKeepsHealthyChildRunning(t *testing.T) {
	m := newManager(t, map[string]string{"web": healthyChildBody})
	m.reload()

	waitFor(t, 3*time.Second, "web to be running", func() bool {
		return m.report().find("web").Running
	})
	// it must still be alive after a beat, and never count fast fails
	time.Sleep(200 * time.Millisecond)
	st := m.report().find("web")
	if !st.Running {
		t.Fatal("healthy child should keep running")
	}
	if st.FastFails != 0 {
		t.Fatalf("healthy child should have 0 fast fails, got %d", st.FastFails)
	}
}

func TestReloadResetsFastFails(t *testing.T) {
	m := newManager(t, map[string]string{"boom": fastChildBody})
	m.reload()
	waitFor(t, 3*time.Second, "boom to give up", func() bool { return m.report().find("boom").GivingUp })

	// restart re-scan; the fast-fail counter must be reset to zero.
	m.reload()
	waitFor(t, 2*time.Second, "boom's reset state", func() bool {
		st := m.report().find("boom")
		return !st.GivingUp && st.FastFails == 0
	})
}

func TestReloadPicksUpNewChild(t *testing.T) {
	m := newManager(t, map[string]string{"a": healthyChildBody})
	m.reload()
	waitFor(t, 3*time.Second, "a to run", func() bool { return m.report().find("a").Running })

	// drop in a new child and reload
	writeChild(t, m.dir, "z", healthyChildBody)
	m.reload()
	waitFor(t, 3*time.Second, "z to be supervised", func() bool { return m.report().find("z").Running })
}

func TestSuperviseWritesLog(t *testing.T) {
	m := newManager(t, map[string]string{"echoer": logChildBody})
	m.reload()
	waitFor(t, 3*time.Second, "echoer log content", func() bool {
		data, err := os.ReadFile(m.logPath("echoer"))
		return err == nil && strings.Contains(string(data), "hello from child")
	})
	data, err := os.ReadFile(m.logPath("echoer"))
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(data), "=== echoer started ") {
		t.Fatalf("log missing start separater: %q", data)
	}
	if !strings.Contains(string(data), "hello from child") {
		t.Fatalf("log missing merged child output: %q", data)
	}
}

// find returns the status for name, filling a zero-value entry if absent so
// callers can keep polling without nil checks.
func (r Report) find(name string) ChildStatus {
	for _, c := range r.Children {
		if c.Name == name {
			return c
		}
	}
	return ChildStatus{}
}
