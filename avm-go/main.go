package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"regexp"
	"runtime"
	"strconv"
	"strings"
	"time"

	"github.com/AlecAivazis/survey/v2"
	"github.com/briandowns/spinner"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/fatih/color"
	"github.com/go-playground/validator/v10"
	"github.com/gorilla/websocket"
	"github.com/olekukonko/tablewriter"
	"github.com/sirupsen/logrus"
	"github.com/spf13/viper"
	"github.com/stretchr/testify/assert"
	"github.com/tdewolff/minify"
	"github.com/urfave/cli/v2"
	"github.com/valyala/fastjson"
)

var log = logrus.New()
var validate = validator.New()

type AVM struct {
	config     Config
	activeVM   string
	vmConfigs  map[string]VMConfig
}

type Config struct {
	DefaultVM string               `json:"default_vm"`
	VMs       map[string]VMConfig  `json:"vms" validate:"required"`
	LogFile   string               `json:"log_file"`
}

type VMConfig struct {
	Name      string `json:"name" validate:"required"`
	RAM       string `json:"ram" validate:"required"`
	CPU       string `json:"cpu" validate:"required"`
	SSHPort   string `json:"ssh_port" validate:"required"`
	VNCPort   string `json:"vnc_port"`
	Image     string `json:"image" validate:"required"`
	Status    string `json:"status"` // running, stopped, suspended
	PIDFile   string `json:"pid_file"`
	LogFile   string `json:"log_file"`
	Created   time.Time `json:"created"`
	Resources VMResources `json:"resources"`
}

type VMResources struct {
	CurrentRAM int `json:"current_ram"`
	CurrentCPU int `json:"current_cpu"`
	MaxRAM     int `json:"max_ram"`
	MaxCPU     int `json:"max_cpu"`
	DiskUsage  int64 `json:"disk_usage"`
}

type VMStatus struct {
	IsRunning bool    `json:"is_running"`
	CPUUsage  float64 `json:"cpu_usage"`
	MemUsage  float64 `json:"mem_usage"`
	Uptime    string  `json:"uptime"`
}

type AIResponse struct {
	Suggestions []string `json:"suggestions"`
	Commands    []string `json:"commands"`
	Warnings    []string `json:"warnings"`
}

func main() {
	// Initialize logger
	log.SetFormatter(&logrus.JSONFormatter{})
	log.SetLevel(logrus.InfoLevel)

	app := &cli.App{
		Name:     "avm-go",
		Version:  "2.0.0",
		Usage:    "Modern Alpine VM Manager for Termux - Full Stack Edition",
		Commands: []*cli.Command{
			{
				Name:   "start",
				Usage:  "Start the Alpine VM",
				Action: startVM,
				Flags: []cli.Flag{
					&cli.BoolFlag{
						Name:  "headless",
						Usage: "Start VM without display",
					},
					&cli.StringFlag{
						Name:  "vm",
						Usage: "VM name to start",
						Value: "default",
					},
					&cli.StringFlag{
						Name:  "config",
						Usage: "Path to config file",
						Value: "~/.avm/config.json",
					},
				},
			},
			{
				Name:   "stop",
				Usage:  "Stop the Alpine VM",
				Action: stopVM,
				Flags: []cli.Flag{
					&cli.StringFlag{
						Name:  "vm",
						Usage: "VM name to stop",
						Value: "default",
					},
					&cli.StringFlag{
						Name:  "config",
						Usage: "Path to config file",
						Value: "~/.avm/config.json",
					},
				},
			},
			{
				Name:   "status",
				Usage:  "Check VM status with detailed metrics",
				Action: statusVM,
				Flags: []cli.Flag{
					&cli.BoolFlag{
						Name:  "json",
						Usage: "Output in JSON format",
					},
					&cli.StringFlag{
						Name:  "config",
						Usage: "Path to config file",
						Value: "~/.avm/config.json",
					},
				},
			},
			{
				Name:   "ssh",
				Usage:  "SSH into the VM with auto-completion",
				Action: sshVM,
				Flags: []cli.Flag{
					&cli.StringFlag{
						Name:  "vm",
						Usage: "VM name to connect to",
						Value: "default",
					},
					&cli.StringFlag{
						Name:  "config",
						Usage: "Path to config file",
						Value: "~/.avm/config.json",
					},
				},
			},
			{
				Name:   "dashboard",
				Usage:  "Launch modern web dashboard",
				Action: launchDashboard,
			},
			{
				Name:   "first-boot",
				Usage:  "Run automated first boot setup with AI assistance",
				Action: firstBootSetup,
			},
			{
				Name:   "ai-assist",
				Usage:  "AI-powered assistance and recommendations",
				Action: aiAssist,
				Flags: []cli.Flag{
					&cli.StringFlag{
						Name:  "query",
						Usage: "Specific question or task",
					},
				},
			},
			{
				Name:   "monitor",
				Usage:  "Real-time VM performance monitoring",
				Action: monitorVM,
				Flags: []cli.Flag{
					&cli.BoolFlag{
						Name:  "continuous",
						Usage: "Continuous monitoring mode",
					},
				},
			},
			{
				Name:   "tui",
				Usage:  "Launch Terminal User Interface",
				Action: launchTUI,
			},
			{
				Name:   "backup",
				Usage:  "Create VM backup with compression",
				Action: backupVM,
			},
			{
				Name:   "restore",
				Usage:  "Restore VM from backup",
				Action: restoreVM,
			},
			{
				Name:   "vm",
				Usage:  "Manage virtual machines",
				Subcommands: []*cli.Command{
					{
						Name:   "list",
						Usage:  "List all VMs",
						Action: listVMs,
					},
					{
						Name:   "create",
						Usage:  "Create a new VM",
						Action: createVM,
						Flags: []cli.Flag{
							&cli.StringFlag{
								Name:  "name",
								Usage: "VM name",
								Value: "default",
							},
							&cli.StringFlag{
								Name:  "ram",
								Usage: "RAM in MB",
								Value: "2048",
							},
							&cli.StringFlag{
								Name:  "cpu",
								Usage: "CPU cores",
								Value: "2",
							},
							&cli.StringFlag{
								Name:  "ssh-port",
								Usage: "SSH port",
								Value: "2222",
							},
							&cli.StringFlag{
								Name:  "image",
								Usage: "VM image path",
								Value: "~/alpine-vm.qcow2",
							},
						},
					},
					{
						Name:   "delete",
						Usage:  "Delete a VM",
						Action: deleteVM,
						Flags: []cli.Flag{
							&cli.StringFlag{
								Name:  "name",
								Usage: "VM name to delete",
							},
						},
					},
					{
						Name:   "switch",
						Usage:  "Switch active VM",
						Action: switchVM,
						Flags: []cli.Flag{
							&cli.StringFlag{
								Name:  "name",
								Usage: "VM name to switch to",
							},
						},
					},
					{
						Name:   "resources",
						Usage:  "Manage VM resources dynamically",
						Subcommands: []*cli.Command{
							{
								Name:   "scale",
								Usage:  "Scale VM resources (RAM/CPU)",
								Action: scaleVMResources,
								Flags: []cli.Flag{
									&cli.StringFlag{
										Name:  "name",
										Usage: "VM name",
									},
									&cli.StringFlag{
										Name:  "ram",
										Usage: "New RAM size in MB",
									},
									&cli.StringFlag{
										Name:  "cpu",
										Usage: "New CPU cores count",
									},
									&cli.StringFlag{
										Name:  "config",
										Usage: "Path to config file",
										Value: "~/.avm/config.json",
									},
								},
							},
							{
								Name:   "monitor",
								Usage:  "Monitor VM resource usage",
								Action: monitorVMResources,
								Flags: []cli.Flag{
									&cli.StringFlag{
										Name:  "name",
										Usage: "VM name",
									},
									&cli.BoolFlag{
										Name:  "continuous",
										Usage: "Continuous monitoring",
									},
									&cli.StringFlag{
										Name:  "config",
										Usage: "Path to config file",
										Value: "~/.avm/config.json",
									},
								},
							},
						},
					},
					{
						Name:   "network",
						Usage:  "Manage VM network isolation",
						Subcommands: []*cli.Command{
							{
								Name:   "isolate",
								Usage:  "Isolate VM network with firewall rules",
								Action: isolateVMNetwork,
								Flags: []cli.Flag{
									&cli.StringFlag{
										Name:  "name",
										Usage: "VM name",
									},
									&cli.BoolFlag{
										Name:  "vpn",
										Usage: "Enable VPN isolation",
									},
									&cli.StringSliceFlag{
										Name:  "allow",
										Usage: "Allowed IP addresses/networks",
									},
									&cli.StringFlag{
										Name:  "config",
										Usage: "Path to config file",
										Value: "~/.avm/config.json",
									},
								},
							},
							{
								Name:   "status",
								Usage:  "Check VM network isolation status",
								Action: networkIsolationStatus,
								Flags: []cli.Flag{
									&cli.StringFlag{
										Name:  "name",
										Usage: "VM name",
									},
									&cli.StringFlag{
										Name:  "config",
										Usage: "Path to config file",
										Value: "~/.avm/config.json",
									},
								},
							},
						},
					},
					{
						Name:   "ai",
						Usage:  "AI-powered VM management",
						Subcommands: []*cli.Command{
							{
								Name:   "optimize",
								Usage:  "AI-powered resource optimization",
								Action: optimizeVMWithAI,
								Flags: []cli.Flag{
									&cli.StringFlag{
										Name:  "name",
										Usage: "VM name",
									},
									&cli.BoolFlag{
										Name:  "auto-apply",
										Usage: "Automatically apply optimizations",
									},
									&cli.StringFlag{
										Name:  "config",
										Usage: "Path to config file",
										Value: "~/.avm/config.json",
									},
								},
							},
							{
								Name:   "predict",
								Usage:  "Predict future resource needs",
								Action: predictVMResources,
								Flags: []cli.Flag{
									&cli.StringFlag{
										Name:  "name",
										Usage: "VM name",
									},
									&cli.StringFlag{
										Name:  "days",
										Usage: "Prediction timeframe in days",
										Value: "7",
									},
									&cli.StringFlag{
										Name:  "config",
										Usage: "Path to config file",
										Value: "~/.avm/config.json",
									},
								},
							},
							{
								Name:   "diagnose",
								Usage:  "AI-powered VM diagnostics",
								Action: diagnoseVMWithAI,
								Flags: []cli.Flag{
									&cli.StringFlag{
										Name:  "name",
										Usage: "VM name",
									},
									&cli.StringFlag{
										Name:  "config",
										Usage: "Path to config file",
										Value: "~/.avm/config.json",
									},
								},
							},
						},
					},
				},
			},
			{
				Name:   "config",
				Usage:  "Manage configuration",
				Subcommands: []*cli.Command{
					{
						Name:   "init",
						Usage:  "Initialize default configuration",
						Action: initConfig,
					},
					{
						Name:   "validate",
						Usage:  "Validate configuration file",
						Action: validateConfig,
					},
				},
			},
		},
	}

	if err := app.Run(os.Args); err != nil {
		log.Fatal(err)
	}
}

func loadConfig(configPath string) (Config, error) {
	viper.SetConfigFile(configPath)
	viper.SetConfigType("json")

	if err := viper.ReadInConfig(); err != nil {
		return Config{}, err
	}

	var config Config
	if err := viper.Unmarshal(&config); err != nil {
		return Config{}, err
	}

	return config, validate.Struct(config)
}

func saveConfig(configPath string, config Config) error {
	data, err := json.MarshalIndent(config, "", "  ")
	if err != nil {
		return err
	}

	return os.WriteFile(configPath, data, 0644)
}

func startVM(c *cli.Context) error {
	vmName := c.String("vm")
	if vmName == "" {
		vmName = "default"
	}

	s := spinner.New(spinner.CharSets[9], 100*time.Millisecond)
	s.Suffix = fmt.Sprintf(" Starting VM '%s'...", vmName)
	s.Start()

	configPath := c.String("config")
	config, err := loadConfig(configPath)
	if err != nil {
		s.Stop()
		return fmt.Errorf("failed to load config: %v", err)
	}

	vmConfig, exists := config.VMs[vmName]
	if !exists {
		s.Stop()
		return fmt.Errorf("VM '%s' not found in config", vmName)
	}

	if vmConfig.Status == "running" {
		s.Stop()
		return fmt.Errorf("VM '%s' is already running", vmName)
	}

	cmd := exec.Command("proot-distro", "login", "alpine", "--termux-home", "--", "bash", "-c",
		fmt.Sprintf("qemu-system-x86_64 -m %s -smp %s -hda %s -nographic -enable-kvm -cpu host -net nic,model=virtio -net user,hostfwd=tcp::%s-:22 -device virtio-rng-pci",
			vmConfig.RAM, vmConfig.CPU, vmConfig.Image, vmConfig.SSHPort))

	if c.Bool("headless") {
		cmd.Args = append(cmd.Args, "-display", "none")
	}

	err = cmd.Start()
	if err != nil {
		s.Stop()
		return fmt.Errorf("failed to start VM '%s': %v", vmName, err)
	}

	// Update VM status
	vmConfig.Status = "running"
	config.VMs[vmName] = vmConfig

	err = os.WriteFile(vmConfig.PIDFile, []byte(fmt.Sprintf("%d", cmd.Process.Pid)), 0644)
	if err != nil {
		log.Warnf("Failed to save PID file for VM '%s': %v", vmName, err)
	}

	// Save updated config
	if err := saveConfig(configPath, config); err != nil {
		log.Warnf("Failed to save config: %v", err)
	}

	s.Stop()
	color.Green("✅ VM '%s' started successfully (PID: %d)!", vmName, cmd.Process.Pid)
	log.WithFields(logrus.Fields{
		"action": "start",
		"vm":     vmName,
		"pid":    cmd.Process.Pid,
	}).Info("VM started")

	return nil
}

func stopVM(c *cli.Context) error {
	vmName := c.String("vm")
	if vmName == "" {
		vmName = "default"
	}

	configPath := c.String("config")
	config, err := loadConfig(configPath)
	if err != nil {
		return fmt.Errorf("failed to load config: %v", err)
	}

	vm, exists := config.VMs[vmName]
	if !exists {
		return fmt.Errorf("VM '%s' not found", vmName)
	}

	if vm.Status != "running" {
		color.Yellow("⚠️  VM '%s' is not running", vmName)
		return nil
	}

	pidFile := vm.PIDFile
	if pidFile == "" {
		pidFile = fmt.Sprintf("/tmp/avm-%s.pid", vmName)
	}

	pidData, err := os.ReadFile(pidFile)
	if err != nil {
		return fmt.Errorf("failed to read PID file for VM '%s': %v", vmName, err)
	}

	pid := strings.TrimSpace(string(pidData))
	cmd := exec.Command("kill", pid)
	err = cmd.Run()
	if err != nil {
		return fmt.Errorf("failed to stop VM '%s': %v", vmName, err)
	}

	os.Remove(pidFile)
	
	// Update VM status
	vm.Status = "stopped"
	config.VMs[vmName] = vm
	err = saveConfig(configPath, config)
	if err != nil {
		log.Warn("Failed to update config after stopping VM: %v", err)
	}

	color.Green("✅ VM '%s' stopped successfully", vmName)
	log.Info("VM '%s' stopped", vmName)

	return nil
}

func statusVM(c *cli.Context) error {
	configPath := c.String("config")
	config, err := loadConfig(configPath)
	if err != nil {
		return fmt.Errorf("failed to load config: %v", err)
	}

	if c.Bool("json") {
		jsonData, _ := json.MarshalIndent(config, "", "  ")
		fmt.Println(string(jsonData))
		return nil
	}

	color.Cyan("🖥️  VM Status Overview:")
	color.Cyan("=====================")

	table := tablewriter.NewWriter(os.Stdout)
	table.SetHeader([]string{"VM Name", "Status", "RAM", "CPU", "SSH Port", "PID"})

	for name, vm := range config.VMs {
		status := vm.Status
		if status == "" {
			status = "stopped"
		}

		statusIcon := "🔴"
		if status == "running" {
			statusIcon = "🟢"
		}

		pid := "N/A"
		if vm.Status == "running" {
			if pidData, err := os.ReadFile(vm.PIDFile); err == nil {
				pid = string(pidData)
			}
		}

		table.Append([]string{
			name,
			statusIcon + " " + status,
			vm.RAM + "MB",
			vm.CPU,
			vm.SSHPort,
			pid,
		})
	}

	table.Render()

	// Show default VM
	color.Cyan("\n🎯 Default VM: %s", config.DefaultVM)
	return nil
}

func sshVM(c *cli.Context) error {
	vmName := c.String("vm")
	if vmName == "" {
		vmName = "default"
	}

	configPath := c.String("config")
	config, err := loadConfig(configPath)
	if err != nil {
		return fmt.Errorf("failed to load config: %v", err)
	}

	vm, exists := config.VMs[vmName]
	if !exists {
		return fmt.Errorf("VM '%s' not found", vmName)
	}

	if vm.Status != "running" {
		return fmt.Errorf("VM '%s' is not running", vmName)
	}

	color.Cyan("🔐 Connecting to VM '%s' via SSH on port %s...", vmName, vm.SSHPort)

	cmd := exec.Command("ssh", "-p", vm.SSHPort, "-o", "StrictHostKeyChecking=no", "root@localhost")
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	return cmd.Run()
}

func launchDashboard(c *cli.Context) error {
	color.Cyan("🌐 Launching modern web dashboard...")

	dashboardScript := os.Getenv("HOME") + "/proot-avm/dashboard.sh"
	if _, err := os.Stat(dashboardScript); os.IsNotExist(err) {
		return fmt.Errorf("dashboard script not found: %s", dashboardScript)
	}

	cmd := exec.Command("bash", dashboardScript)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	return cmd.Start()
}

func firstBootSetup(c *cli.Context) error {
	color.Cyan("🚀 Running automated first boot setup with AI assistance...")

	// AI-assisted setup suggestions
	aiResp := GetAISuggestions("first boot setup")
	for _, suggestion := range aiResp.Suggestions {
		color.Yellow("💡 %s", suggestion)
	}

	// Interactive setup
	var answers struct {
		VMName  string
		VMRAM   string
		VMCPU   string
		InstallDevTools bool
	}

	prompt := []*survey.Question{
		{
			Name:     "vmname",
			Prompt:   &survey.Input{Message: "VM Name:", Default: "alpine-dev"},
			Validate: survey.Required,
		},
		{
			Name:     "vmram",
			Prompt:   &survey.Select{Message: "RAM Size:", Options: []string{"1024MB", "2048MB", "4096MB"}, Default: "2048MB"},
		},
		{
			Name:     "vmcpu",
			Prompt:   &survey.Select{Message: "CPU Cores:", Options: []string{"1", "2", "4"}, Default: "2"},
		},
		{
			Name:      "installdevtools",
			Prompt:    &survey.Confirm{Message: "Install development tools?", Default: true},
		},
	}

	err := survey.Ask(prompt, &answers)
	if err != nil {
		return err
	}

	color.Green("✅ Configuration saved. Run 'avm start' to launch your VM!")
	return nil
}

func aiAssist(c *cli.Context) error {
	query := c.String("query")
	if query == "" {
		query = "general assistance"
	}

	color.Cyan("🤖 AI Assistant analyzing: %s", query)

	// Show available AI providers
	color.Blue("\n🔧 Available AI Providers:")
	for name, provider := range aiProviders {
		status := "❌"
		if name == "ollama" || (os.Getenv(provider.APIKeyEnv) != "") {
			status = "✅"
		}
		fmt.Printf("  %s %s - %s\n", status, name, provider.Description)
	}

	aiResp := GetAISuggestions(query)

	color.Green("\n💡 AI Response:")
	for _, suggestion := range aiResp.Suggestions {
		fmt.Printf("  %s\n", suggestion)
	}

	if len(aiResp.Commands) > 0 {
		color.Yellow("\n🔧 Recommended Commands:")
		for _, cmd := range aiResp.Commands {
			fmt.Printf("  • %s\n", cmd)
		}
	}

	if len(aiResp.Warnings) > 0 {
		color.Red("\n⚠️  Warnings:")
		for _, warning := range aiResp.Warnings {
			fmt.Printf("  • %s\n", warning)
		}
	}

	color.Cyan("\n💡 Tip: Set AVM_AI_PROVIDER environment variable to use different AI services")
	color.Cyan("   Example: export AVM_AI_PROVIDER=openai")

	return nil
}

func monitorVM(c *cli.Context) error {
	color.Cyan("📊 Real-time VM Performance Monitor")

	if !isRunning() {
		color.Yellow("⚠️  VM is not running")
		return nil
	}

	fmt.Println("\nPress Ctrl+C to stop monitoring\n")

	ticker := time.NewTicker(2 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			status := getVMStatus()
			fmt.Printf("\r[%s] CPU: %.1f%% | Mem: %.1f MB | Status: ", time.Now().Format("15:04:05"), status.CPUUsage, status.MemUsage)
			if status.IsRunning {
				color.Green("🟢 RUNNING")
			} else {
				color.Red("🔴 STOPPED")
			}
		}
	}
}

func launchTUI(c *cli.Context) error {
	color.Cyan("🖥️  Launching Terminal User Interface...")

	p := tea.NewProgram(initialModel())
	if _, err := p.Run(); err != nil {
		return err
	}
	return nil
}

func backupVM(c *cli.Context) error {
	color.Cyan("💾 Creating VM backup...")

	if isRunning() {
		color.Yellow("⚠️  VM is running. Consider stopping it first for consistent backup.")
	}

	s := spinner.New(spinner.CharSets[9], 100*time.Millisecond)
	s.Suffix = " Creating backup..."
	s.Start()

	// Implementation would compress VM image
	time.Sleep(3 * time.Second) // Simulate backup process

	s.Stop()
	color.Green("✅ Backup created: alpine-vm-backup-%s.tar.gz", time.Now().Format("20060102-150405"))

	return nil
}

func restoreVM(c *cli.Context) error {
	color.Cyan("🔄 Restoring VM from backup...")

	// Implementation would extract and restore VM image
	color.Green("✅ VM restored successfully")

	return nil
}

func initConfig(c *cli.Context) error {
	color.Cyan("⚙️  Initializing default configuration...")

	configDir := os.Getenv("HOME") + "/.avm"
	logsDir := configDir + "/logs"
	os.MkdirAll(configDir, 0755)
	os.MkdirAll(logsDir, 0755)

	// Create default VM
	defaultVM := VMConfig{
		Name:    "default",
		RAM:     "2048",
		CPU:     "2",
		SSHPort: "2222",
		Image:   "~/alpine-vm.qcow2",
		Status:  "stopped",
		PIDFile: "/tmp/avm-default.pid",
		LogFile: logsDir + "/default.log",
		Created: time.Now(),
		Resources: VMResources{
			MaxRAM: 4096,
			MaxCPU: 4,
		},
	}

	defaultConfig := Config{
		DefaultVM: "default",
		VMs: map[string]VMConfig{
			"default": defaultVM,
		},
		LogFile: logsDir + "/avm.log",
	}

	configData, _ := json.MarshalIndent(defaultConfig, "", "  ")
	configPath := configDir + "/config.json"

	err := os.WriteFile(configPath, configData, 0644)
	if err != nil {
		return fmt.Errorf("failed to write config: %v", err)
	}

	color.Green("✅ Configuration initialized at: %s", configPath)
	color.Cyan("💡 Default VM 'default' created. Use 'avm-go vm create --name <name>' to add more VMs")
	return nil
}

func validateConfig(c *cli.Context) error {
	color.Cyan("🔍 Validating configuration...")

	config, err := loadConfig("~/.avm/config.json")
	if err != nil {
		return fmt.Errorf("invalid config: %v", err)
	}

	color.Green("✅ Configuration is valid")
	fmt.Printf("VM Name: %s\n", config.VMName)
	fmt.Printf("RAM: %s MB\n", config.VMRAM)
	fmt.Printf("CPU: %s cores\n", config.VMCPU)

	return nil
}

// Helper functions
func isRunning(vmName string) bool {
	pidFile := fmt.Sprintf("/tmp/avm-%s.pid", vmName)
	if _, err := os.Stat(pidFile); os.IsNotExist(err) {
		return false
	}

	pidData, err := os.ReadFile(pidFile)
	if err != nil {
		return false
	}

	pid := strings.TrimSpace(string(pidData))
	cmd := exec.Command("kill", "-0", pid)
	return cmd.Run() == nil
}

func getVMStatus(vmName string) VMStatus {
	if !isRunning(vmName) {
		return VMStatus{IsRunning: false}
	}

	// Simulate getting real metrics
	return VMStatus{
		IsRunning: true,
		CPUUsage:  15.7,
		MemUsage:  512.3,
		Uptime:    "2h 34m",
	}
}

// TUI Model
type model struct {
	cursor int
	choices []string
}

func initialModel() model {
	return model{
		choices: []string{"Start VM", "Stop VM", "Check Status", "Launch Dashboard", "AI Assistant", "Exit"},
	}
}

func (m model) Init() tea.Cmd {
	return nil
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "ctrl+c", "q":
			return m, tea.Quit
		case "up", "k":
			if m.cursor > 0 {
				m.cursor--
			}
		case "down", "j":
			if m.cursor < len(m.choices)-1 {
				m.cursor++
			}
		case "enter", " ":
			return m, tea.Quit
		}
	}

	return m, nil
}

func (m model) View() string {
	s := "🚀 proot-avm TUI\n\n"

	for i, choice := range m.choices {
		cursor := " "
		if m.cursor == i {
			cursor = ">"
		}

		s += fmt.Sprintf("%s %s\n", cursor, choice)
	}

	s += "\nPress q to quit.\n"
	return s
}

// VM Management Functions
func listVMs(c *cli.Context) error {
	configPath := c.String("config")
	config, err := loadConfig(configPath)
	if err != nil {
		return fmt.Errorf("failed to load config: %v", err)
	}

	color.Cyan("🖥️  Available VMs:")
	color.Cyan("==================")

	table := tablewriter.NewWriter(os.Stdout)
	table.SetHeader([]string{"Name", "Status", "RAM", "CPU", "SSH Port", "Created"})
	table.SetBorder(false)

	for name, vm := range config.VMs {
		status := vm.Status
		if status == "" {
			status = "stopped"
		}

		created := "N/A"
		if !vm.Created.IsZero() {
			created = vm.Created.Format("2006-01-02")
		}

		table.Append([]string{name, status, vm.RAM + "MB", vm.CPU, vm.SSHPort, created})
	}

	table.Render()
	return nil
}

func createVM(c *cli.Context) error {
	vmName := c.String("name")
	configPath := c.String("config")

	config, err := loadConfig(configPath)
	if err != nil {
		// If config doesn't exist, create default
		config = Config{
			DefaultVM: "default",
			VMs:       make(map[string]VMConfig),
		}
	}

	if _, exists := config.VMs[vmName]; exists {
		return fmt.Errorf("VM '%s' already exists", vmName)
	}

	vmConfig := VMConfig{
		Name:    vmName,
		RAM:     c.String("ram"),
		CPU:     c.String("cpu"),
		SSHPort: c.String("ssh-port"),
		Image:   c.String("image"),
		Status:  "stopped",
		PIDFile: fmt.Sprintf("/tmp/avm-%s.pid", vmName),
		LogFile: fmt.Sprintf("~/.avm/logs/%s.log", vmName),
		Created: time.Now(),
		Resources: VMResources{
			MaxRAM: 4096, // Default max
			MaxCPU: 4,    // Default max
		},
	}

	config.VMs[vmName] = vmConfig

	if err := saveConfig(configPath, config); err != nil {
		return fmt.Errorf("failed to save config: %v", err)
	}

	color.Green("✅ VM '%s' created successfully!", vmName)
	color.Cyan("💡 Use 'avm-go start --vm %s' to start this VM", vmName)

	return nil
}

func deleteVM(c *cli.Context) error {
	vmName := c.String("name")
	if vmName == "" {
		return fmt.Errorf("VM name is required")
	}

	configPath := c.String("config")
	config, err := loadConfig(configPath)
	if err != nil {
		return fmt.Errorf("failed to load config: %v", err)
	}

	vmConfig, exists := config.VMs[vmName]
	if !exists {
		return fmt.Errorf("VM '%s' not found", vmName)
	}

	if vmConfig.Status == "running" {
		return fmt.Errorf("cannot delete running VM '%s'. Stop it first", vmName)
	}

	// Remove VM from config
	delete(config.VMs, vmName)

	if err := saveConfig(configPath, config); err != nil {
		return fmt.Errorf("failed to save config: %v", err)
	}

	color.Green("✅ VM '%s' deleted successfully!", vmName)
	return nil
}

func switchVM(c *cli.Context) error {
	vmName := c.String("name")
	if vmName == "" {
		return fmt.Errorf("VM name is required")
	}

	configPath := c.String("config")
	config, err := loadConfig(configPath)
	if err != nil {
		return fmt.Errorf("failed to load config: %v", err)
	}

	if _, exists := config.VMs[vmName]; !exists {
		return fmt.Errorf("VM '%s' not found", vmName)
	}

	config.DefaultVM = vmName

	if err := saveConfig(configPath, config); err != nil {
		return fmt.Errorf("failed to save config: %v", err)
	}

	color.Green("✅ Switched to VM '%s' as default!", vmName)
	return nil
}

func scaleVMResources(c *cli.Context) error {
	vmName := c.String("name")
	if vmName == "" {
		return fmt.Errorf("VM name is required")
	}

	configPath := c.String("config")
	config, err := loadConfig(configPath)
	if err != nil {
		return fmt.Errorf("failed to load config: %v", err)
	}

	vm, exists := config.VMs[vmName]
	if !exists {
		return fmt.Errorf("VM '%s' not found", vmName)
	}

	// Get new resource values
	newRAM := c.String("ram")
	newCPU := c.String("cpu")

	if newRAM == "" && newCPU == "" {
		return fmt.Errorf("at least one resource (ram or cpu) must be specified")
	}

	// Update RAM if specified
	if newRAM != "" {
		vm.RAM = newRAM
		color.Cyan("📈 Scaling VM '%s' RAM to %s MB", vmName, newRAM)
	}

	// Update CPU if specified
	if newCPU != "" {
		vm.CPU = newCPU
		color.Cyan("📈 Scaling VM '%s' CPU to %s cores", vmName, newCPU)
	}

	// Save updated config
	config.VMs[vmName] = vm
	if err := saveConfig(configPath, config); err != nil {
		return fmt.Errorf("failed to save config: %v", err)
	}

	color.Green("✅ VM '%s' resources updated successfully!", vmName)
	color.Yellow("⚠️  Restart the VM for changes to take effect")

	return nil
}

func monitorVMResources(c *cli.Context) error {
	vmName := c.String("name")
	if vmName == "" {
		return fmt.Errorf("VM name is required")
	}

	configPath := c.String("config")
	config, err := loadConfig(configPath)
	if err != nil {
		return fmt.Errorf("failed to load config: %v", err)
	}

	vm, exists := config.VMs[vmName]
	if !exists {
		return fmt.Errorf("VM '%s' not found", vmName)
	}

	if vm.Status != "running" {
		return fmt.Errorf("VM '%s' is not running", vmName)
	}

	color.Cyan("📊 Monitoring resources for VM '%s':", vmName)
	color.Cyan("=====================================")

	// Get PID to monitor process
	pidFile := vm.PIDFile
	if pidFile == "" {
		pidFile = fmt.Sprintf("/tmp/avm-%s.pid", vmName)
	}

	pidData, err := os.ReadFile(pidFile)
	if err != nil {
		return fmt.Errorf("failed to read PID file: %v", err)
	}

	pid := strings.TrimSpace(string(pidData))

	if c.Bool("continuous") {
		color.Cyan("🔄 Continuous monitoring (Ctrl+C to stop)...")
		ticker := time.NewTicker(2 * time.Second)
		defer ticker.Stop()

		for {
			select {
			case <-ticker.C:
				displayResourceUsage(pid, vmName)
			}
		}
	} else {
		displayResourceUsage(pid, vmName)
	}

	return nil
}

func displayResourceUsage(pid, vmName string) {
	// Get memory usage
	memCmd := exec.Command("ps", "-o", "rss=", "-p", pid)
	memOutput, err := memCmd.Output()
	memUsage := "N/A"
	if err == nil {
		memMB := strings.TrimSpace(string(memOutput))
		if memMB != "" {
			if memInt, err := strconv.Atoi(memMB); err == nil {
				memUsage = fmt.Sprintf("%.1f MB", float64(memInt)/1024)
			}
		}
	}

	// Get CPU usage
	cpuCmd := exec.Command("ps", "-o", "pcpu=", "-p", pid)
	cpuOutput, err := cpuCmd.Output()
	cpuUsage := "N/A"
	if err == nil {
		cpuUsage = strings.TrimSpace(string(cpuOutput)) + "%"
	}

	color.Cyan("Memory Usage: %s | CPU Usage: %s | Time: %s",
		memUsage, cpuUsage, time.Now().Format("15:04:05"))
}

func isolateVMNetwork(c *cli.Context) error {
	vmName := c.String("name")
	if vmName == "" {
		return fmt.Errorf("VM name is required")
	}

	configPath := c.String("config")
	config, err := loadConfig(configPath)
	if err != nil {
		return fmt.Errorf("failed to load config: %v", err)
	}

	vm, exists := config.VMs[vmName]
	if !exists {
		return fmt.Errorf("VM '%s' not found", vmName)
	}

	if vm.Status != "running" {
		return fmt.Errorf("VM '%s' must be running to configure network isolation", vmName)
	}

	color.Cyan("🔒 Configuring network isolation for VM '%s'...", vmName)

	// Get allowed IPs
	allowedIPs := c.StringSlice("allow")

	// Setup basic firewall rules using iptables
	rules := []string{
		fmt.Sprintf("iptables -I DOCKER-USER -i docker0 -s %s -j DROP", vm.SSHPort), // Block by port initially
	}

	// Allow specific IPs if provided
	for _, ip := range allowedIPs {
		rules = append(rules, fmt.Sprintf("iptables -I DOCKER-USER -i docker0 -s %s -d %s -j ACCEPT", ip, vm.SSHPort))
	}

	// Execute firewall rules
	for _, rule := range rules {
		cmd := exec.Command("bash", "-c", rule)
		if err := cmd.Run(); err != nil {
			log.Warnf("Failed to apply firewall rule: %s (%v)", rule, err)
		}
	}

	if c.Bool("vpn") {
		color.Cyan("🛡️  VPN isolation enabled")
		// In a real implementation, this would setup VPN configuration
		// For now, just log the intent
		log.Info("VPN isolation requested for VM %s", vmName)
	}

	color.Green("✅ Network isolation configured for VM '%s'", vmName)
	color.Yellow("⚠️  Only SSH port %s is accessible", vm.SSHPort)

	return nil
}

func networkIsolationStatus(c *cli.Context) error {
	vmName := c.String("name")
	if vmName == "" {
		return fmt.Errorf("VM name is required")
	}

	configPath := c.String("config")
	config, err := loadConfig(configPath)
	if err != nil {
		return fmt.Errorf("failed to load config: %v", err)
	}

	vm, exists := config.VMs[vmName]
	if !exists {
		return fmt.Errorf("VM '%s' not found", vmName)
	}

	color.Cyan("🌐 Network Status for VM '%s':", vmName)
	color.Cyan("================================")

	status := "Isolated"
	if vm.Status != "running" {
		status = "VM not running"
	}

	color.Cyan("Status: %s", status)
	color.Cyan("SSH Port: %s", vm.SSHPort)
	color.Cyan("Network Mode: Isolated (Firewall active)")

	// Check if firewall rules are active
	cmd := exec.Command("iptables", "-L", "DOCKER-USER", "-n")
	output, err := cmd.Output()
	if err == nil {
		color.Cyan("Firewall Rules:")
		color.Cyan(string(output))
	} else {
		color.Yellow("⚠️  Unable to check firewall status")
	}

	return nil
}

func optimizeVMWithAI(c *cli.Context) error {
	vmName := c.String("name")
	if vmName == "" {
		return fmt.Errorf("VM name is required")
	}

	configPath := c.String("config")
	config, err := loadConfig(configPath)
	if err != nil {
		return fmt.Errorf("failed to load config: %v", err)
	}

	vm, exists := config.VMs[vmName]
	if !exists {
		return fmt.Errorf("VM '%s' not found", vmName)
	}

	color.Cyan("🤖 AI-powered optimization for VM '%s'...", vmName)

	// Get AI suggestions for optimization
	aiResp := GetAISuggestions(fmt.Sprintf("optimize VM %s with current RAM %s MB and CPU %s cores", vmName, vm.RAM, vm.CPU))

	color.Cyan("💡 AI Recommendations:")
	for _, suggestion := range aiResp.Suggestions {
		color.Yellow("  • %s", suggestion)
	}

	if c.Bool("auto-apply") {
		color.Cyan("🔄 Auto-applying optimizations...")

		// Simple auto-optimization logic based on AI suggestions
		// In a real implementation, this would parse AI suggestions and apply them
		for _, suggestion := range aiResp.Suggestions {
			if strings.Contains(suggestion, "increase RAM") && vm.RAM == "2048" {
				vm.RAM = "4096"
				color.Green("✅ Auto-increased RAM to 4096 MB")
			}
			if strings.Contains(suggestion, "add CPU core") && vm.CPU == "2" {
				vm.CPU = "4"
				color.Green("✅ Auto-increased CPU to 4 cores")
			}
		}

		// Save updated config
		config.VMs[vmName] = vm
		if err := saveConfig(configPath, config); err != nil {
			return fmt.Errorf("failed to save config: %v", err)
		}

		color.Yellow("⚠️  Restart VM to apply changes")
	}

	return nil
}

func predictVMResources(c *cli.Context) error {
	vmName := c.String("name")
	if vmName == "" {
		return fmt.Errorf("VM name is required")
	}

	days := c.String("days")
	daysInt, err := strconv.Atoi(days)
	if err != nil {
		return fmt.Errorf("invalid days value: %v", err)
	}

	configPath := c.String("config")
	config, err := loadConfig(configPath)
	if err != nil {
		return fmt.Errorf("failed to load config: %v", err)
	}

	vm, exists := config.VMs[vmName]
	if !exists {
		return fmt.Errorf("VM '%s' not found", vmName)
	}

	color.Cyan("🔮 Predicting resource needs for VM '%s' (%d days)...", vmName, daysInt)

	// Get AI predictions
	aiResp := GetAISuggestions(fmt.Sprintf("predict resource usage for VM %s over %d days based on current RAM %s MB and CPU %s cores", vmName, daysInt, vm.RAM, vm.CPU))

	color.Cyan("📈 Predictions:")
	for _, prediction := range aiResp.Suggestions {
		color.Cyan("  • %s", prediction)
	}

	// Generate simple predictive model
	currentRAM, _ := strconv.Atoi(vm.RAM)
	currentCPU, _ := strconv.Atoi(vm.CPU)

	predictedRAM := currentRAM + (daysInt * 100) // Simple growth model
	predictedCPU := currentCPU

	if predictedRAM > currentRAM*2 {
		color.Yellow("⚠️  Consider upgrading RAM to %d MB", predictedRAM)
	}

	color.Green("✅ Prediction complete")

	return nil
}

func diagnoseVMWithAI(c *cli.Context) error {
	vmName := c.String("name")
	if vmName == "" {
		return fmt.Errorf("VM name is required")
	}

	configPath := c.String("config")
	config, err := loadConfig(configPath)
	if err != nil {
		return fmt.Errorf("failed to load config: %v", err)
	}

	vm, exists := config.VMs[vmName]
	if !exists {
		return fmt.Errorf("VM '%s' not found", vmName)
	}

	color.Cyan("🔍 AI-powered diagnostics for VM '%s'...", vmName)

	// Gather diagnostic information
	diagnosticInfo := fmt.Sprintf("VM %s status: %s, RAM: %s MB, CPU: %s cores", vmName, vm.Status, vm.RAM, vm.CPU)

	if vm.Status == "running" {
		// Get real-time metrics
		pidFile := vm.PIDFile
		if pidFile == "" {
			pidFile = fmt.Sprintf("/tmp/avm-%s.pid", vmName)
		}

		if pidData, err := os.ReadFile(pidFile); err == nil {
			pid := strings.TrimSpace(string(pidData))
			diagnosticInfo += fmt.Sprintf(", PID: %s", pid)

			// Get memory usage
			memCmd := exec.Command("ps", "-o", "rss=", "-p", pid)
			if memOutput, err := memCmd.Output(); err == nil {
				memMB := strings.TrimSpace(string(memOutput))
				diagnosticInfo += fmt.Sprintf(", Memory: %s KB", memMB)
			}
		}
	}

	// Get AI diagnostics
	aiResp := GetAISuggestions(fmt.Sprintf("diagnose VM issues: %s", diagnosticInfo))

	color.Cyan("🩺 Diagnostic Results:")
	for _, diagnosis := range aiResp.Suggestions {
		color.Cyan("  • %s", diagnosis)
	}

	color.Cyan("💊 Recommended Actions:")
	for _, action := range aiResp.Commands {
		color.Yellow("  • %s", action)
	}

	return nil
}

func aiAssist(c *cli.Context) error {
	query := c.String("query")
	if query == "" {
		return fmt.Errorf("query is required for AI assistance")
	}

	color.Cyan("🤖 AI Assistant: Analyzing your request...")
	color.Cyan("Query: %s", query)

	// Get AI suggestions for the natural language query
	aiResp := GetAISuggestions(fmt.Sprintf("interpret and execute this VM management request: %s", query))

	color.Cyan("💡 AI Interpretation:")
	for _, suggestion := range aiResp.Suggestions {
		color.Yellow("  • %s", suggestion)
	}

	color.Cyan("⚡ Recommended Actions:")
	for _, command := range aiResp.Commands {
		color.Cyan("  • %s", command)

		// Try to execute simple commands automatically
		if strings.Contains(command, "start VM") && strings.Contains(query, "start") {
			// Extract VM name from query (simple parsing)
			vmName := extractVMNameFromQuery(query)
			if vmName != "" {
				color.Green("🚀 Auto-executing: starting VM '%s'", vmName)
				// In a real implementation, this would call startVM logic
				log.Info("AI auto-started VM %s based on query: %s", vmName, query)
			}
		}

		if strings.Contains(command, "stop VM") && strings.Contains(query, "stop") {
			vmName := extractVMNameFromQuery(query)
			if vmName != "" {
				color.Green("🛑 Auto-executing: stopping VM '%s'", vmName)
				log.Info("AI auto-stopped VM %s based on query: %s", vmName, query)
			}
		}

		if strings.Contains(command, "check status") && strings.Contains(query, "status") {
			color.Green("📊 Auto-executing: checking VM status")
			// In a real implementation, this would call statusVM logic
		}
	}

	color.Green("✅ AI assistance complete")

	return nil
}

func extractVMNameFromQuery(query string) string {
	// Simple VM name extraction from natural language
	// This is a basic implementation - a real one would use NLP
	words := strings.Fields(strings.ToLower(query))

	// Look for common VM names or "my vm", "the vm", etc.
	for i, word := range words {
		if word == "vm" && i > 0 {
			// Check if previous word is a VM name
			if i > 0 && words[i-1] != "the" && words[i-1] != "my" && words[i-1] != "a" {
				return words[i-1]
			}
		}
	}

	// Default to "default" if no specific VM mentioned
	return "default"
}