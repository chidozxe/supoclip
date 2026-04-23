# SupoClip - Quick Start Script for Windows (PowerShell)
# Equivalent of start.sh for Windows users
#
# Usage: .\start.ps1
# Requires: Docker Desktop running, .env file present in the repo root

$ErrorActionPreference = "Stop"

function Write-Color($text, $color) {
    Write-Host $text -ForegroundColor $color
}

Write-Host "============================================"
Write-Host "  SupoClip - AI Video Clipping Tool"
Write-Host "============================================"
Write-Host ""

# Check if .env file exists
if (-not (Test-Path ".env")) {
    Write-Color "Error: .env file not found!" "Red"
    Write-Host ""
    Write-Host "Please create a .env file with your API keys:"
    Write-Host "  1. Copy the template:"
    Write-Host "       PowerShell: Copy-Item .env.example .env"
    Write-Host "       cmd:        copy .env.example .env"
    Write-Host "  2. Edit .env and add your API keys:"
    Write-Host "     - ASSEMBLY_AI_API_KEY (required)"
    Write-Host "     - GOOGLE_API_KEY (for Gemini - recommended on Windows)"
    Write-Host "     - LLM=google-gla:gemini-3-flash-preview"
    Write-Host ""
    exit 1
}

# Load .env and check required keys
$envContent = Get-Content ".env" | Where-Object { $_ -notmatch '^\s*#' -and $_ -match '=' }
$envVars = @{}
foreach ($line in $envContent) {
    $parts = $line -split '=', 2
    if ($parts.Length -eq 2) {
        $key = $parts[0].Trim()
        $value = $parts[1].Trim().Trim('"').Trim("'")
        $envVars[$key] = $value
    }
}

if ([string]::IsNullOrWhiteSpace($envVars['ASSEMBLY_AI_API_KEY'])) {
    Write-Color "Warning: ASSEMBLY_AI_API_KEY is not set in .env" "Yellow"
    Write-Host "Video transcription will not work without this key."
    Write-Host ""
}

$hasLLMKey = (
    -not [string]::IsNullOrWhiteSpace($envVars['OPENAI_API_KEY']) -or
    -not [string]::IsNullOrWhiteSpace($envVars['GOOGLE_API_KEY']) -or
    -not [string]::IsNullOrWhiteSpace($envVars['ANTHROPIC_API_KEY'])
)
$llmValue = $envVars['LLM']
$isOllama = $llmValue -and $llmValue.StartsWith('ollama:')

if (-not $hasLLMKey -and -not $isOllama) {
    Write-Color "Warning: No AI provider API key is set in .env" "Yellow"
    Write-Host "You need at least one of: OPENAI_API_KEY, GOOGLE_API_KEY, ANTHROPIC_API_KEY, or LLM=ollama:<model>"
    Write-Host ""
}

# Check if Docker is running
try {
    $null = docker info 2>&1
    if ($LASTEXITCODE -ne 0) { throw "Docker not running" }
} catch {
    Write-Color "Error: Docker is not running!" "Red"
    Write-Host "Please start Docker Desktop and try again."
    Write-Host "  - Open Docker Desktop from the Start menu"
    Write-Host "  - Wait for the whale icon in the system tray to stop animating"
    Write-Host ""
    exit 1
}

# Determine which docker compose command to use
$dockerCompose = $null
try {
    $null = docker compose version 2>&1
    if ($LASTEXITCODE -eq 0) { $dockerCompose = "docker compose" }
} catch {}

if (-not $dockerCompose) {
    try {
        $null = docker-compose --version 2>&1
        if ($LASTEXITCODE -eq 0) { $dockerCompose = "docker-compose" }
    } catch {}
}

if (-not $dockerCompose) {
    Write-Color "Error: docker compose is not available!" "Red"
    Write-Host "Please ensure Docker Desktop is installed with Compose support."
    Write-Host ""
    exit 1
}

Write-Color "Starting SupoClip..." "Green"
Write-Host ""
Write-Host "Building and starting Docker containers..."
Write-Host "(This may take a few minutes on the first run)"
Write-Host ""

# Build and start containers
if ($dockerCompose -eq "docker compose") {
    docker compose up -d --build
} else {
    docker-compose up -d --build
}

Write-Host ""
Write-Color "SupoClip is starting up!" "Green"
Write-Host ""
Write-Host "Services will be available at:"
Write-Host "  - Frontend:  http://localhost:3000"
Write-Host "  - Backend:   http://localhost:8000"
Write-Host "  - API Docs:  http://localhost:8000/docs"
Write-Host ""
Write-Host "To view logs, run:"
Write-Host "  $dockerCompose logs -f"
Write-Host ""
Write-Host "To stop all services, run:"
Write-Host "  $dockerCompose down"
Write-Host ""
Write-Host "Waiting for services to be healthy..."

Start-Sleep -Seconds 5

# Check if services are running
$psOutput = & docker ps --format "{{.Status}}" 2>&1
if ($psOutput -match "Up") {
    Write-Color "Services are starting successfully!" "Green"
    Write-Host ""
    Write-Host "You can now:"
    Write-Host "  1. Open http://localhost:3000 in your browser"
    Write-Host "  2. View logs: $dockerCompose logs -f"
    Write-Host "  3. Stop services: $dockerCompose down"
} else {
    Write-Color "Services are starting... Check logs if you encounter issues:" "Yellow"
    Write-Host "  $dockerCompose logs -f"
}

Write-Host ""
Write-Host "============================================"
