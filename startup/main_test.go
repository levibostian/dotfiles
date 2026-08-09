package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestPlistTemplatePlaceholders(t *testing.T) {
	for _, want := range []string{
		"{{BIN}}",
		"<string>daemon</string>",
		"RunAtLoad",
		"KeepAlive",
		"com.startup",
	} {
		if !strings.Contains(plistTemplate, want) {
			t.Fatalf("plistTemplate missing %q", want)
		}
	}
	if n := strings.Count(plistTemplate, "{{BIN}}"); n != 1 {
		t.Fatalf("plistTemplate should have exactly one {{BIN}} placeholder, got %d", n)
	}
}

func TestPlistContentRendersBinaryPath(t *testing.T) {
	want := "/some/absolute/path/startup"
	content := plistContent(want)
	if !strings.Contains(content, want) {
		t.Fatalf("rendered plist should embed the binary path %q", want)
	}
	if strings.Contains(content, "{{BIN}}") {
		t.Fatal("rendered plist should not retain the placeholder")
	}
}

func TestPlistPath(t *testing.T) {
	got := plistPath()
	wantSuffix := filepath.Join("Library", "LaunchAgents", "com.startup.plist")
	if !strings.HasSuffix(got, wantSuffix) {
		t.Fatalf("plistPath() = %q, want suffix %q", got, wantSuffix)
	}
}

// overridePlistKnobs points the install/uninstall seams at a throwaway dir and a
// recorded launchctl, restoring the originals when the test finishes.
func overridePlistKnobs(t *testing.T) (string, *[]string) {
	t.Helper()
	oldDir, oldFn := plistDirOverride, launchctl
	calls := &[]string{}
	plistDirOverride = t.TempDir()
	launchctl = func(args ...string) error { *calls = append(*calls, strings.Join(args, " ")); return nil }
	t.Cleanup(func() {
		plistDirOverride = oldDir
		launchctl = oldFn
	})
	return plistDirOverride, calls
}

func TestDoInstallWritesPlistAndLoads(t *testing.T) {
	dir, calls := overridePlistKnobs(t)
	doInstall()

	path := filepath.Join(dir, "com.startup.plist")
	data, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("plist not written: %v", err)
	}
	exe, _ := os.Executable()
	if !strings.Contains(string(data), exe) {
		t.Fatalf("installed plist should embed binary path %q", exe)
	}
	want := "load " + path
	if len(*calls) != 1 || (*calls)[0] != want {
		t.Fatalf("launchctl calls = %v, want [%q]", *calls, want)
	}
}

func TestDoUninstallRemovesPlist(t *testing.T) {
	dir, calls := overridePlistKnobs(t)
	path := filepath.Join(dir, "com.startup.plist")
	if err := os.WriteFile(path, []byte("x"), 0o644); err != nil {
		t.Fatal(err)
	}

	doUninstall()
	if _, err := os.Stat(path); !os.IsNotExist(err) {
		t.Fatalf("plist should be removed after uninstall: %v", err)
	}
	if len(*calls) != 1 || (*calls)[0] != "unload "+path {
		t.Fatalf("launchctl calls = %v, want [unload %s]", *calls, path)
	}
}
