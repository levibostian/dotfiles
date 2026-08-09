package main

import (
	"bufio"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"net"
	"os"
	"os/exec"
	"os/signal"
	"path/filepath"
	"sort"
	"strings"
	"sync"
	"syscall"
	"time"
)

// sockAddr is the control socket path. A variable (not a const) so tests can
// point the CLI at a throwaway socket instead of the real one.
var sockAddr = "/tmp/startup.sock"

// Config tunes the supervisor loop. Zero values fall back to defaults, so
// tests can shrink the timings to make fast-fail behaviour observable quickly.
type Config struct {
	FastFailWindow time.Duration // a run shorter than this counts as a fast fail
	MaxFastFails   int           // consecutive fast fails before giving up
	RetryDelay     time.Duration // pause between a child's exit and its restart
	LogDir         string        // where per-child logs are written
}

func defaultConfig() Config {
	return Config{
		FastFailWindow: 5 * time.Second,
		MaxFastFails:   10,
		RetryDelay:     1 * time.Second,
		LogDir:         "/tmp",
	}
}

// Child is one supervised process. Its live fields are guarded by mu. The
// cancel func is the only cross-goroutine handle to the running process: the
// supervisor owns the *exec.Cmd entirely, and a kill (from a restart or the
// daemon's shutdown) is delivered by cancelling the context. That threading is
// race-free because exec.CommandContext's internal goroutine performs the kill
// and never exposes cmd internals to other goroutines.
type Child struct {
	mu        sync.Mutex
	Name      string
	cancel    context.CancelFunc
	fastFails int
	running   bool
}

// ChildStatus is the observable state of a child, safe to serialize.
type ChildStatus struct {
	Name      string `json:"name"`
	Running   bool   `json:"running"`
	FastFails int    `json:"fastFails"`
	GivingUp  bool   `json:"givingUp"`
}

// Report is the response to the status command.
type Report struct {
	Children []ChildStatus `json:"children"`
}

func (c *Child) setRunning(running bool) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.running = running
}

func (c *Child) setCancel(cancel context.CancelFunc) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.cancel = cancel
}

// kill delivers a cancellation to the running child, which exec.CommandContext
// turns into a process kill. Safe to call from any goroutine. Cancelling an
// already-finished viewer or one without a cancel func is a no-op.
func (c *Child) kill() {
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.cancel != nil {
		c.cancel()
		c.cancel = nil
	}
}

// fail records one fast exit.
func (c *Child) fail() {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.fastFails++
}

// resetFails clears the fast-fail count after a run that lived long enough.
func (c *Child) resetFails() {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.fastFails = 0
}

func (c *Child) gaveUp(max int) bool {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.fastFails >= max
}

func (c *Child) status() ChildStatus {
	c.mu.Lock()
	defer c.mu.Unlock()
	return ChildStatus{Name: c.Name, Running: c.running, FastFails: c.fastFails}
}

// Manager supervises one generation of children under dir.
type Manager struct {
	mu       sync.Mutex
	dir      string // bins/
	cfg      Config
	children map[string]*Child
	stopCh   chan struct{} // closed to stop the current generation
}

// NewManager returns a Manager for dir with cfg; zeroed cfg fields fall back
// to defaults.
func NewManager(dir string, cfg Config) *Manager {
	def := defaultConfig()
	if cfg.FastFailWindow == 0 {
		cfg.FastFailWindow = def.FastFailWindow
	}
	if cfg.MaxFastFails == 0 {
		cfg.MaxFastFails = def.MaxFastFails
	}
	if cfg.RetryDelay == 0 {
		cfg.RetryDelay = def.RetryDelay
	}
	if cfg.LogDir == "" {
		cfg.LogDir = def.LogDir
	}
	return &Manager{dir: dir, cfg: cfg}
}

// binsDir resolves the live binary's sibling bins/ directory, so children run
// next to wherever the binary was installed.
func binsDir() string {
	if exe, err := os.Executable(); err == nil {
		return filepath.Join(filepath.Dir(exe), "bins")
	}
	return "bins"
}

// scanBins lists runnable children in bins/: regular files with no "." in the
// name and the executable bit set (a config.json is an asset, not a child).
// Sorted alphabetically.
func (m *Manager) scanBins() []string {
	entries, err := os.ReadDir(m.dir)
	if err != nil {
		log.Printf("scan bins: %v", err)
		return nil
	}
	var names []string
	for _, e := range entries {
		if e.IsDir() || strings.Contains(e.Name(), ".") {
			continue
		}
		info, err := e.Info()
		if err != nil {
			continue
		}
		if info.Mode()&0o111 == 0 {
			continue
		}
		names = append(names, e.Name())
	}
	sort.Strings(names)
	return names
}

// reload stops every child of the current generation (killing it and resetting
// fast-fail counters) and spawns a fresh generation from a rescan of bins/.
// Called once at daemon start and again on a restart command.
func (m *Manager) reload() {
	m.mu.Lock()
	defer m.mu.Unlock()

	if m.stopCh != nil {
		close(m.stopCh)
		for _, c := range m.children {
			c.kill()
		}
	}
	m.stopCh = make(chan struct{})
	m.spawn()
}

// spawn must be called with m.mu held. Each child is supervised by its own
// goroutine, which captures this generation's stop channel.
func (m *Manager) spawn() {
	m.children = make(map[string]*Child)
	stop := m.stopCh
	for _, name := range m.scanBins() {
		c := &Child{Name: name}
		m.children[name] = c
		go m.supervise(c, stop)
	}
}

// supervise keeps one child alive until it gives up (too many consecutive fast
// fails) or the generation is stopped. Output is truncated per run and merged
// into <LogDir>/startup-<name>.log.
func (m *Manager) supervise(c *Child, stop <-chan struct{}) {
	logPath := m.logPath(c.Name)
	for {
		select {
		case <-stop:
			return
		default:
		}
		if c.gaveUp(m.cfg.MaxFastFails) {
			return
		}

		logf, err := os.Create(logPath) // truncate each run
		if err != nil {
			log.Printf("%s: open log: %v", c.Name, err)
			if !m.sleep(m.cfg.RetryDelay, stop) {
				return
			}
			continue
		}
		fmt.Fprintf(logf, "=== %s started %s ===\n", c.Name, time.Now().Format(time.TimeOnly))

		ctx, cancel := context.WithCancel(context.Background())
		c.setCancel(cancel)
		cmd := exec.CommandContext(ctx, filepath.Join(m.dir, c.Name))
		cmd.Dir = m.dir
		cmd.Stdout = logf
		cmd.Stderr = logf
		c.setRunning(true)

		start := time.Now()
		startErr := cmd.Start()
		runtime := time.Since(start)
		if startErr != nil {
			log.Printf("%s: start: %v", c.Name, startErr)
			c.fail()
		} else {
			_ = cmd.Wait()
			c.setRunning(false)
			if runtime < m.cfg.FastFailWindow {
				c.fail()
			} else {
				c.resetFails()
			}
		}
		c.setCancel(nil)
		_ = logf.Close()

		if c.gaveUp(m.cfg.MaxFastFails) {
			log.Printf("giving up on %s after %d fast fails", c.Name, c.failCount())
			return
		}
		if !m.sleep(m.cfg.RetryDelay, stop) {
			return
		}
	}
}

func (m *Manager) logPath(name string) string {
	return filepath.Join(m.cfg.LogDir, "startup-"+name+".log")
}

func (c *Child) failCount() int {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.fastFails
}

func (m *Manager) sleep(d time.Duration, stop <-chan struct{}) bool {
	t := time.NewTimer(d)
	defer t.Stop()
	select {
	case <-stop:
		return false
	case <-t.C:
		return true
	}
}

func (m *Manager) report() Report {
	m.mu.Lock()
	defer m.mu.Unlock()
	var rep Report
	for _, c := range m.children {
		st := c.status()
		st.GivingUp = st.FastFails >= m.cfg.MaxFastFails
		rep.Children = append(rep.Children, st)
	}
	sort.Slice(rep.Children, func(i, j int) bool { return rep.Children[i].Name < rep.Children[j].Name })
	return rep
}

// Shutdown stops the current generation: it signals every supervisor to exit
// and kills any running child. Safe to call once.
func (m *Manager) Shutdown() {
	m.mu.Lock()
	defer m.mu.Unlock()
	if m.stopCh != nil {
		close(m.stopCh)
		m.stopCh = nil
	}
	for _, c := range m.children {
		c.kill()
	}
}

// serve accepts control-connection requests until the listener is closed. A
// closed listener ends the loop (used for graceful shutdown and in tests).
func serve(ln net.Listener, m *Manager) {
	for {
		conn, err := ln.Accept()
		if err != nil {
			var op *net.OpError
			if errors.As(err, &op) && errors.Is(op.Err, net.ErrClosed) {
				return
			}
			log.Printf("accept: %v", err)
			continue
		}
		go handleConn(conn, m)
	}
}

// runDaemon is the launchd entry point: owns the control socket and runs the
// supervisor loop until signalled.
func runDaemon() {
	_ = os.Remove(sockAddr) // stale socket from a crashed daemon
	ln, err := net.Listen("unix", sockAddr)
	if err != nil {
		log.Fatalf("listen %s: %v", sockAddr, err)
	}

	m := NewManager(binsDir(), defaultConfig())
	m.reload()
	log.Printf("startup daemon: supervising %d child(ren) in %s", m.childCount(), m.dir)

	// Graceful shutdown: remove the socket and stop children on SIGINT/SIGTERM.
	sig := make(chan os.Signal, 1)
	signal.Notify(sig, os.Interrupt, syscall.SIGTERM)
	go func() {
		<-sig
		m.Shutdown()
		_ = ln.Close()
		_ = os.Remove(sockAddr)
		os.Exit(0)
	}()

	serve(ln, m)
}

func (m *Manager) childCount() int {
	m.mu.Lock()
	defer m.mu.Unlock()
	return len(m.children)
}

func handleConn(conn net.Conn, m *Manager) {
	defer conn.Close()
	msg, err := bufio.NewReader(conn).ReadString('\n')
	if err != nil {
		return
	}
	switch strings.TrimSpace(msg) {
	case "status":
		_ = json.NewEncoder(conn).Encode(m.report())
	case "restart":
		m.reload()
		_, _ = fmt.Fprintln(conn, "ok")
	default:
		_, _ = fmt.Fprintln(conn, "unknown command")
	}
}
