package main

import (
	"testing"
	"os"
	"os/exec"
	"strings"
)

func TestIsRunning(t *testing.T) {
	// Test when VM is not running
	if isRunning() {
		t.Error("Expected VM to not be running")
	}

	// Create fake PID file
	os.WriteFile("/tmp/avm-vm.pid", []byte("99999"), 0644)
	defer os.Remove("/tmp/avm-vm.pid")

	// Test when PID file exists but process doesn't
	if isRunning() {
		t.Error("Expected VM to not be running with fake PID")
	}
}

func TestGetVMStatus(t *testing.T) {
	status := getVMStatus()

	if status.IsRunning {
		t.Error("Expected VM to not be running in test")
	}

	if status.CPUUsage < 0 {
		t.Error("CPU usage should not be negative")
	}
}

func TestLoadConfig(t *testing.T) {
	// Create temporary config file
	configData := `{
		"vm_name": "test-vm",
		"vm_ram": "1024",
		"vm_cpu": "1",
		"ssh_port": "2222",
		"vm_image": "test.img",
		"log_file": "/tmp/test.log",
		"pid_file": "/tmp/test.pid"
	}`

	tempFile := "/tmp/test-config.json"
	os.WriteFile(tempFile, []byte(configData), 0644)
	defer os.Remove(tempFile)

	config, err := loadConfig(tempFile)
	if err != nil {
		t.Fatalf("Failed to load config: %v", err)
	}

	if config.VMName != "test-vm" {
		t.Errorf("Expected VM name 'test-vm', got '%s'", config.VMName)
	}
}

func TestAIAssist(t *testing.T) {
	resp := getAISuggestions("first boot setup")

	if len(resp.Suggestions) == 0 {
		t.Error("Expected suggestions for first boot setup")
	}

	if len(resp.Commands) == 0 {
		t.Error("Expected commands for first boot setup")
	}
}

func TestValidateConfig(t *testing.T) {
	// Test valid config
	validConfig := Config{
		VMName:  "test",
		VMRAM:   "1024",
		VMCPU:   "1",
		SSHPort: "2222",
		VMImage: "test.img",
	}

	err := validate.Struct(validConfig)
	if err != nil {
		t.Errorf("Valid config should pass validation: %v", err)
	}

	// Test invalid config
	invalidConfig := Config{
		VMRAM:   "1024",
		VMCPU:   "1",
		SSHPort: "2222",
		VMImage: "test.img",
		// Missing VMName
	}

	err = validate.Struct(invalidConfig)
	if err == nil {
		t.Error("Invalid config should fail validation")
	}
}

func BenchmarkVMStatus(b *testing.B) {
	for i := 0; i < b.N; i++ {
		getVMStatus()
	}
}

func BenchmarkAISuggestions(b *testing.B) {
	for i := 0; i < b.N; i++ {
		getAISuggestions("test query")
	}
}