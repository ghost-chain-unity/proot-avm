#!/usr/bin/env bash
# proot-avm TUI Launcher
# Launches the modern Terminal User Interface using Bubbletea

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Check if Go is available
if ! command -v go &> /dev/null; then
    echo -e "${YELLOW}⚠️  Go not found. Installing...${NC}"

    if command -v pkg &> /dev/null; then
        pkg install -y golang
    elif command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y golang-go
    else
        echo -e "${RED}❌ Please install Go manually${NC}"
        exit 1
    fi
fi

# Build and run TUI
TUI_BINARY="$HOME/.local/bin/avm-tui"
if [ ! -f "$TUI_BINARY" ]; then
    echo -e "${CYAN}🔨 Building TUI...${NC}"

    TUI_DIR="$HOME/.proot-avm-tui"
    mkdir -p "$TUI_DIR"
    cd "$TUI_DIR"

    # Create go.mod
    cat > go.mod << 'EOF'
module github.com/ghost-chain-unity/proot-avm-tui

go 1.21

require (
	github.com/charmbracelet/bubbletea v0.24.1
	github.com/charmbracelet/lipgloss v0.7.1
	github.com/charmbracelet/bubbles v0.16.1
	github.com/atotto/clipboard v0.1.4
	github.com/muesli/reflow v0.3.0
	github.com/sirupsen/logrus v1.9.3
)
EOF

    # Create main.go
    cat > main.go << 'EOF'
package main

import (
	"fmt"
	"os"
	"os/exec"
	"strings"
	"time"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/charmbracelet/bubbles/spinner"
	"github.com/charmbracelet/bubbles/list"
	"github.com/charmbracelet/bubbles/textinput"
	"github.com/atotto/clipboard"
	"github.com/sirupsen/logrus"
)

var log = logrus.New()

type model struct {
	state     string
	list      list.Model
	textInput textinput.Model
	spinner   spinner.Model
	status    string
	output    string
}

type item struct {
	title, desc string
}

func (i item) Title() string       { return i.title }
func (i item) Description() string { return i.desc }
func (i item) FilterValue() string { return i.title }

func initialModel() model {
	items := []list.Item{
		item{title: "Start VM", desc: "Launch Alpine VM"},
		item{title: "Stop VM", desc: "Shutdown VM gracefully"},
		item{title: "VM Status", desc: "Check current VM status"},
		item{title: "SSH Access", desc: "Connect to VM via SSH"},
		item{title: "Web Dashboard", desc: "Launch web management interface"},
		item{title: "AI Assistant", desc: "Get AI-powered help"},
		item{title: "Performance Monitor", desc: "Real-time metrics"},
		item{title: "Backup VM", desc: "Create VM backup"},
		item{title: "First Boot Setup", desc: "Initial VM configuration"},
		item{title: "Configuration", desc: "Manage VM settings"},
		item{title: "Help", desc: "Show help information"},
		item{title: "Exit", desc: "Quit application"},
	}

	l := list.New(items, list.NewDefaultDelegate(), 0, 0)
	l.Title = "🚀 proot-avm TUI v2.0"
	l.Styles.Title = lipgloss.NewStyle().
		Foreground(lipgloss.Color("39")).
		Bold(true).
		MarginBottom(1)

	ti := textinput.New()
	ti.Placeholder = "Enter your command or question..."
	ti.CharLimit = 200
	ti.Width = 50

	s := spinner.New()
	s.Spinner = spinner.Dot
	s.Style = lipgloss.NewStyle().Foreground(lipgloss.Color("39"))

	return model{
		state:     "menu",
		list:      l,
		textInput: ti,
		spinner:   s,
		status:    "Ready",
	}
}

func (m model) Init() tea.Cmd {
	return tea.Batch(
		textinput.Blink,
		spinner.Tick,
	)
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	var cmd tea.Cmd

	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "ctrl+c", "q":
			return m, tea.Quit
		case "enter":
			if m.state == "menu" {
				selectedItem := m.list.SelectedItem()
				if selectedItem != nil {
					return m.handleMenuSelection(selectedItem.(item))
				}
			} else if m.state == "input" {
				input := m.textInput.Value()
				m.textInput.Reset()
				return m.handleInput(input)
			}
		case "esc":
			if m.state != "menu" {
				m.state = "menu"
				m.status = "Ready"
				m.output = ""
			}
		}

	case tea.WindowSizeMsg:
		h, v := lipgloss.NewStyle().GetFrameSize()
		m.list.SetSize(msg.Width-h, msg.Height-v-10)

	case spinner.TickMsg:
		m.spinner, cmd = m.spinner.Update(msg)
		return m, cmd
	}

	if m.state == "menu" {
		m.list, cmd = m.list.Update(msg)
	} else if m.state == "input" {
		m.textInput, cmd = m.textInput.Update(msg)
	}

	return m, cmd
}

func (m model) handleMenuSelection(item item) (tea.Model, tea.Cmd) {
	switch item.title {
	case "Start VM":
		m.status = "Starting VM..."
		return m, m.runCommand("avm-go start --headless")
	case "Stop VM":
		m.status = "Stopping VM..."
		return m, m.runCommand("avm-go stop")
	case "VM Status":
		m.status = "Checking status..."
		return m, m.runCommand("avm-go status")
	case "SSH Access":
		m.status = "Connecting via SSH..."
		return m, m.runCommand("avm-go ssh")
	case "Web Dashboard":
		m.status = "Launching dashboard..."
		return m, m.runCommandAsync("avm-go dashboard")
	case "AI Assistant":
		m.state = "input"
		m.status = "AI Assistant - Type your question and press Enter"
		m.textInput.Focus()
		return m, nil
	case "Performance Monitor":
		m.status = "Launching monitor..."
		return m, m.runCommandAsync("avm-go monitor --continuous")
	case "Backup VM":
		m.status = "Creating backup..."
		return m, m.runCommand("avm-go backup")
	case "First Boot Setup":
		m.status = "Running first boot setup..."
		return m, m.runCommand("avm-go first-boot")
	case "Configuration":
		m.status = "Opening config..."
		return m, m.runCommand("avm-go config init")
	case "Help":
		m.output = m.getHelpText()
		m.status = "Help displayed"
		return m, nil
	case "Exit":
		return m, tea.Quit
	}
	return m, nil
}

func (m model) handleInput(input string) (tea.Model, tea.Cmd) {
	if strings.TrimSpace(input) == "" {
		m.state = "menu"
		m.status = "Ready"
		return m, nil
	}

	m.status = "Getting AI assistance..."
	return m, m.runCommand(fmt.Sprintf("avm-go ai-assist --query %q", input))
}

func (m model) runCommand(command string) tea.Cmd {
	return func() tea.Msg {
		cmd := exec.Command("bash", "-c", command)
		output, err := cmd.CombinedOutput()
		result := string(output)
		if err != nil {
			result = fmt.Sprintf("Error: %v\n%s", err, result)
		}
		return commandResultMsg{result: result}
	}
}

func (m model) runCommandAsync(command string) tea.Cmd {
	return func() tea.Msg {
		go func() {
			cmd := exec.Command("bash", "-c", command)
			cmd.Run() // Don't wait for completion
		}()
		return commandResultMsg{result: "Command started in background"}
	}
}

type commandResultMsg struct {
	result string
}

func (m model) View() string {
	var view string

	style := lipgloss.NewStyle().
		Border(lipgloss.RoundedBorder()).
		BorderForeground(lipgloss.Color("39")).
		Padding(1, 2)

	statusStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color("39")).
		Bold(true)

	if m.state == "menu" {
		view = lipgloss.JoinVertical(
			lipgloss.Left,
			statusStyle.Render("Status: "+m.status),
			style.Render(m.list.View()),
			"\n"+lipgloss.NewStyle().Foreground(lipgloss.Color("241")).Render("↑/↓ Navigate • Enter Select • q Quit • ? Help"),
		)
	} else if m.state == "input" {
		view = lipgloss.JoinVertical(
			lipgloss.Left,
			statusStyle.Render(m.status),
			style.Render(m.textInput.View()),
			"\n"+lipgloss.NewStyle().Foreground(lipgloss.Color("241")).Render("Enter Submit • Esc Back • q Quit"),
		)
	}

	if m.output != "" {
		outputStyle := lipgloss.NewStyle().
			Border(lipgloss.RoundedBorder()).
			BorderForeground(lipgloss.Color("39")).
			Padding(1, 2).
			MarginTop(1)

		view += "\n" + outputStyle.Render(m.output)
	}

	return view
}

func (m *model) getHelpText() string {
	return `🚀 proot-avm TUI v2.0 - Help

NAVIGATION:
  ↑/↓          Navigate menu
  Enter        Select option
  Esc          Go back
  q/Ctrl+C     Quit

COMMANDS:
  Start VM     Launch Alpine VM in background
  Stop VM      Gracefully shutdown VM
  VM Status    Check current VM state
  SSH Access   Connect to VM via SSH
  Web Dashboard Launch web management interface
  AI Assistant  Get intelligent help and suggestions
  Performance  Real-time monitoring
  Backup VM    Create VM backup
  First Boot   Initial setup wizard
  Configuration Manage VM settings

AI ASSISTANT:
  Type questions like:
  • "How to install Node.js?"
  • "Setup Python environment"
  • "Optimize VM performance"

SHORTCUTS:
  ?            Show this help
  Ctrl+C       Force quit

For more information, visit: https://alpinevm.qzz.io`
}

func main() {
	log.SetLevel(logrus.InfoLevel)

	p := tea.NewProgram(initialModel(), tea.WithAltScreen())
	if _, err := p.Run(); err != nil {
		log.Fatal(err)
	}
}
EOF

    # Build the TUI
    go mod tidy
    go build -o "$TUI_BINARY" .

    echo -e "${GREEN}✅ TUI built successfully${NC}"
fi

# Launch the TUI
echo -e "${BLUE}🖥️  Launching proot-avm TUI v2.0...${NC}"
echo -e "${CYAN}Use arrow keys to navigate, Enter to select, q to quit${NC}"
exec "$TUI_BINARY"