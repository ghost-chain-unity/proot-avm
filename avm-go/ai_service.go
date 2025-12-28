package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/fatih/color"
	"github.com/urfave/cli/v2"
)

// AIService represents different AI service providers
type AIService struct {
	Provider string
	APIKey   string
	BaseURL  string
}

// AIMessage represents a chat message
type AIMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

// AIRequest represents the request to AI service
type AIRequest struct {
	Model    string      `json:"model,omitempty"`
	Messages []AIMessage `json:"messages"`
	MaxTokens int        `json:"max_tokens,omitempty"`
	Temperature float64  `json:"temperature,omitempty"`
}

// AIResponse represents the response from AI service
type AIResponse struct {
	Choices []struct {
		Message AIMessage `json:"message"`
	} `json:"choices,omitempty"`
	Error struct {
		Message string `json:"message"`
		Type    string `json:"type"`
	} `json:"error,omitempty"`
}

// AIProvider represents available AI providers
type AIProvider struct {
	Name        string
	BaseURL     string
	Models      []string
	APIKeyEnv   string
	Description string
}

// Available AI providers
var aiProviders = map[string]AIProvider{
	"openai": {
		Name:        "OpenAI",
		BaseURL:     "https://api.openai.com/v1",
		Models:      []string{"gpt-4", "gpt-3.5-turbo"},
		APIKeyEnv:   "OPENAI_API_KEY",
		Description: "OpenAI GPT models (requires API key)",
	},
	"claude": {
		Name:        "Anthropic Claude",
		BaseURL:     "https://api.anthropic.com/v1",
		Models:      []string{"claude-3-opus", "claude-3-sonnet", "claude-3-haiku"},
		APIKeyEnv:   "ANTHROPIC_API_KEY",
		Description: "Anthropic Claude models (requires API key)",
	},
	"ollama": {
		Name:        "Ollama (Local)",
		BaseURL:     "http://localhost:11434",
		Models:      []string{"llama2", "codellama", "mistral"},
		APIKeyEnv:   "",
		Description: "Local Ollama models (no API key needed)",
	},
	"openhands": {
		Name:        "OpenHands",
		BaseURL:     "http://localhost:3000",
		Models:      []string{"openhands"},
		APIKeyEnv:   "",
		Description: "OpenHands AI assistant (local)",
	},
}

// getAIService initializes AI service based on configuration
func getAIService() (*AIService, error) {
	// Check for configured provider
	provider := os.Getenv("AVM_AI_PROVIDER")
	if provider == "" {
		provider = "ollama" // Default to local Ollama
	}

	prov, exists := aiProviders[provider]
	if !exists {
		return nil, fmt.Errorf("unsupported AI provider: %s", provider)
	}

	service := &AIService{
		Provider: provider,
		BaseURL:  prov.BaseURL,
	}

	// Set API key if required
	if prov.APIKeyEnv != "" {
		service.APIKey = os.Getenv(prov.APIKeyEnv)
		if service.APIKey == "" {
			color.Yellow("⚠️  %s API key not found in environment variable %s", prov.Name, prov.APIKeyEnv)
			color.Yellow("   Falling back to local AI or mock responses")
		}
	}

	return service, nil
}

// callAI makes a request to the AI service
func (ai *AIService) callAI(messages []AIMessage, model string) (*AIResponse, error) {
	var response *AIResponse

	switch ai.Provider {
	case "openai":
		return ai.callOpenAI(messages, model)
	case "claude":
		return ai.callClaude(messages, model)
	case "ollama":
		return ai.callOllama(messages, model)
	case "openhands":
		return ai.callOpenHands(messages, model)
	default:
		return ai.getMockResponse(messages)
	}

	return response, nil
}

// callOpenAI calls OpenAI API
func (ai *AIService) callOpenAI(messages []AIMessage, model string) (*AIResponse, error) {
	if ai.APIKey == "" {
		return ai.getMockResponse(messages)
	}

	if model == "" {
		model = "gpt-3.5-turbo"
	}

	req := AIRequest{
		Model:       model,
		Messages:    messages,
		MaxTokens:   1000,
		Temperature: 0.7,
	}

	reqBody, _ := json.Marshal(req)

	httpReq, err := http.NewRequest("POST", ai.BaseURL+"/chat/completions", bytes.NewBuffer(reqBody))
	if err != nil {
		return nil, err
	}

	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("Authorization", "Bearer "+ai.APIKey)

	client := &http.Client{Timeout: 30 * time.Second}
	resp, err := client.Do(httpReq)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	var aiResp AIResponse
	if err := json.Unmarshal(body, &aiResp); err != nil {
		return nil, err
	}

	if aiResp.Error.Message != "" {
		return nil, fmt.Errorf("AI API error: %s", aiResp.Error.Message)
	}

	return &aiResp, nil
}

// callClaude calls Anthropic Claude API
func (ai *AIService) callClaude(messages []AIMessage, model string) (*AIResponse, error) {
	if ai.APIKey == "" {
		return ai.getMockResponse(messages)
	}

	if model == "" {
		model = "claude-3-haiku"
	}

	// Convert messages to Claude format
	var prompt string
	for _, msg := range messages {
		role := msg.Role
		if role == "user" {
			prompt += "\n\nHuman: " + msg.Content
		} else {
			prompt += "\n\nAssistant: " + msg.Content
		}
	}
	prompt += "\n\nAssistant:"

	req := map[string]interface{}{
		"prompt":               prompt,
		"model":               model,
		"max_tokens_to_sample": 1000,
		"temperature":         0.7,
	}

	reqBody, _ := json.Marshal(req)

	httpReq, err := http.NewRequest("POST", ai.BaseURL+"/complete", bytes.NewBuffer(reqBody))
	if err != nil {
		return nil, err
	}

	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("X-API-Key", ai.APIKey)
	httpReq.Header.Set("anthropic-version", "2023-06-01")

	client := &http.Client{Timeout: 30 * time.Second}
	resp, err := client.Do(httpReq)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	var claudeResp struct {
		Completion string `json:"completion"`
		Error      struct {
			Message string `json:"message"`
		} `json:"error"`
	}

	if err := json.Unmarshal(body, &claudeResp); err != nil {
		return nil, err
	}

	if claudeResp.Error.Message != "" {
		return nil, fmt.Errorf("Claude API error: %s", claudeResp.Error.Message)
	}

	return &AIResponse{
		Choices: []struct {
			Message AIMessage `json:"message"`
		}{
			{
				Message: AIMessage{
					Role:    "assistant",
					Content: claudeResp.Completion,
				},
			},
		},
	}, nil
}

// callOllama calls local Ollama API
func (ai *AIService) callOllama(messages []AIMessage, model string) (*AIResponse, error) {
	if model == "" {
		model = "llama2"
	}

	// Convert to Ollama format
	var prompt string
	for _, msg := range messages {
		if msg.Role == "system" {
			prompt += msg.Content + "\n"
		} else if msg.Role == "user" {
			prompt += "User: " + msg.Content + "\n"
		} else {
			prompt += "Assistant: " + msg.Content + "\n"
		}
	}

	req := map[string]interface{}{
		"model":  model,
		"prompt": prompt,
		"stream": false,
	}

	reqBody, _ := json.Marshal(req)

	httpReq, err := http.NewRequest("POST", ai.BaseURL+"/api/generate", bytes.NewBuffer(reqBody))
	if err != nil {
		return nil, err
	}

	httpReq.Header.Set("Content-Type", "application/json")

	client := &http.Client{Timeout: 60 * time.Second}
	resp, err := client.Do(httpReq)
	if err != nil {
		color.Yellow("⚠️  Ollama not available, using mock response")
		return ai.getMockResponse(messages)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	var ollamaResp struct {
		Response string `json:"response"`
		Error    string `json:"error"`
	}

	if err := json.Unmarshal(body, &ollamaResp); err != nil {
		return nil, err
	}

	if ollamaResp.Error != "" {
		color.Yellow("⚠️  Ollama error: %s", ollamaResp.Error)
		return ai.getMockResponse(messages)
	}

	return &AIResponse{
		Choices: []struct {
			Message AIMessage `json:"message"`
		}{
			{
				Message: AIMessage{
					Role:    "assistant",
					Content: ollamaResp.Response,
				},
			},
		},
	}, nil
}

// callOpenHands calls OpenHands API
func (ai *AIService) callOpenHands(messages []AIMessage, model string) (*AIResponse, error) {
	// OpenHands integration - for now return mock response
	// In real implementation, this would call OpenHands API
	color.Cyan("🤖 OpenHands AI Assistant")
	color.Yellow("💡 Tip: Use 'openhands' command directly in terminal for full AI experience")

	return ai.getMockResponse(messages)
}

// getMockResponse provides fallback responses when AI services are unavailable
func (ai *AIService) getMockResponse(messages []AIMessage) (*AIResponse, error) {
	query := ""
	if len(messages) > 0 {
		query = strings.ToLower(messages[len(messages)-1].Content)
	}

	responses := map[string]string{
		"help": "Here are some helpful commands:\n• avm start - Start the VM\n• avm status - Check VM status\n• avm dashboard - Launch web interface\n• avm ssh - Connect via SSH",
		"docker": "To work with Docker:\n1. Start VM: avm start\n2. SSH in: avm ssh\n3. Check Docker: docker ps\n4. Pull images: docker pull <image>\n5. Run containers: docker run <options> <image>",
		"install": "Installation options:\n• One-liner: curl -fsSL https://raw.githubusercontent.com/ghost-chain-unity/proot-avm/main/install-one-liner.sh | bash\n• Manual: git clone repo && ./install.sh --agent\n• Binary: Download from releases",
		"troubleshoot": "Common troubleshooting:\n• VM won't start: Check QEMU installation\n• SSH fails: Wait for VM boot (2-3 min)\n• Docker issues: service docker start\n• Permission errors: chmod +x scripts",
	}

	var response string
	for key, resp := range responses {
		if strings.Contains(query, key) {
			response = resp
			break
		}
	}

	if response == "" {
		response = "I'm here to help with proot-avm! Try asking about:\n• VM management (start, stop, status)\n• Docker setup and usage\n• Installation and troubleshooting\n• Development environment setup"
	}

	return &AIResponse{
		Choices: []struct {
			Message AIMessage `json:"message"`
		}{
			{
				Message: AIMessage{
					Role:    "assistant",
					Content: response,
				},
			},
		},
	}, nil
}

// getAISuggestions provides intelligent suggestions based on query
func GetAISuggestions(query string) AIResponse {
	ai, err := getAIService()
	if err != nil {
		color.Red("❌ AI service error: %v", err)
		return getFallbackSuggestions(query)
	}

	messages := []AIMessage{
		{
			Role:    "system",
			Content: "You are an AI assistant for proot-avm, a modern Alpine Linux VM manager. Provide helpful, accurate suggestions for VM management, Docker, development environments, and troubleshooting. Keep responses concise and actionable.",
		},
		{
			Role:    "user",
			Content: query,
		},
	}

	response, err := ai.callAI(messages, "")
	if err != nil {
		color.Yellow("⚠️  AI call failed, using fallback: %v", err)
		return getFallbackSuggestions(query)
	}

	if len(response.Choices) > 0 {
		return AIResponse{
			Suggestions: []string{response.Choices[0].Message.Content},
			Commands:    extractCommands(response.Choices[0].Message.Content),
		}
	}

	return getFallbackSuggestions(query)
}

// extractCommands extracts command suggestions from AI response
func extractCommands(response string) []string {
	var commands []string
	lines := strings.Split(response, "\n")

	for _, line := range lines {
		line = strings.TrimSpace(line)
		if strings.HasPrefix(line, "avm") ||
		   strings.HasPrefix(line, "docker") ||
		   strings.HasPrefix(line, "git") ||
		   strings.HasPrefix(line, "./") {
			commands = append(commands, line)
		}
	}

	return commands
}

// getFallbackSuggestions provides basic suggestions when AI is unavailable
func getFallbackSuggestions(query string) AIResponse {
	suggestions := map[string]AIResponse{
		"first boot setup": {
			Suggestions: []string{
				"Use at least 2GB RAM for development workloads",
				"Enable KVM for better performance on supported devices",
				"Install essential dev tools during first boot",
			},
			Commands: []string{
				"avm first-boot",
				"avm start --headless",
				"avm dashboard",
			},
			Warnings: []string{
				"First boot may take several minutes",
				"Ensure stable internet connection for package downloads",
			},
		},
		"docker": {
			Suggestions: []string{
				"Start VM first: avm start",
				"SSH into VM: avm ssh",
				"Check Docker status: docker ps",
				"Pull images: docker pull <image>",
			},
			Commands: []string{
				"avm start",
				"avm ssh",
				"docker ps",
			},
		},
		"troubleshooting": {
			Suggestions: []string{
				"Check VM status: avm status",
				"View logs: tail -f ~/qemu-vm/alpine-vm.log",
				"Restart terminal and try again",
				"Check QEMU installation",
			},
			Commands: []string{
				"avm status",
				"avm restart",
			},
		},
	}

	// Find matching suggestions
	for key, resp := range suggestions {
		if strings.Contains(strings.ToLower(query), key) {
			return resp
		}
	}

	// Default response
	return AIResponse{
		Suggestions: []string{
			"Use 'avm help' for available commands",
			"Check 'avm status' for VM state",
			"Launch dashboard with 'avm dashboard'",
		},
		Commands: []string{
			"avm help",
			"avm status",
			"avm dashboard",
		},
	}
}