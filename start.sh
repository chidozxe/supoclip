#!/bin/bash

# SupoClip - Quick Start Script
# This script helps you start SupoClip with a single command

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo "============================================"
echo "  SupoClip - AI Video Clipping Tool"
echo "============================================"
echo ""

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${RED}Error: .env file not found!${NC}"
    echo ""
    echo "Create one from the template, then fill in your API keys:"
    echo ""
    echo "  cp .env.example .env"
    echo "  \$EDITOR .env"
    echo ""
    echo "Minimum required variables:"
    echo "  ASSEMBLY_AI_API_KEY   — get one free at https://www.assemblyai.com/"
    echo "  LLM                   — e.g. google-gla:gemini-3-flash-preview"
    echo "  GOOGLE_API_KEY        — required when LLM starts with google-gla:"
    echo "  OPENAI_API_KEY        — required when LLM starts with openai:"
    echo "  ANTHROPIC_API_KEY     — required when LLM starts with anthropic:"
    echo "  (no key needed)       — when LLM starts with ollama: (local Ollama)"
    echo ""
    exit 1
fi

# Load environment variables
# shellcheck source=/dev/null
source .env

# ---------------------------------------------------------------------------
# Preflight: ASSEMBLY_AI_API_KEY
# ---------------------------------------------------------------------------
if [ -z "${ASSEMBLY_AI_API_KEY:-}" ]; then
    echo -e "${RED}Error: ASSEMBLY_AI_API_KEY is not set in .env${NC}"
    echo ""
    echo "Video transcription requires an AssemblyAI API key."
    echo "  1. Sign up for free at https://www.assemblyai.com/"
    echo "  2. Copy your key and add it to .env:"
    echo "       ASSEMBLY_AI_API_KEY=your_key_here"
    echo "  3. Re-run: ./start.sh"
    echo ""
    exit 1
fi

# ---------------------------------------------------------------------------
# Preflight: LLM provider key must match the configured LLM= value
# ---------------------------------------------------------------------------
LLM_VALUE="${LLM:-google-gla:gemini-3-flash-preview}"
LLM_PROVIDER="${LLM_VALUE%%:*}"   # extract prefix before the first ':'

case "$LLM_PROVIDER" in
    openai)
        if [ -z "${OPENAI_API_KEY:-}" ]; then
            echo -e "${RED}Error: LLM is set to '${LLM_VALUE}' but OPENAI_API_KEY is not set.${NC}"
            echo ""
            echo "Either:"
            echo "  a) Set OPENAI_API_KEY in .env  (get a key at https://platform.openai.com/api-keys)"
            echo "  b) Switch to a different provider, for example:"
            echo "       LLM=google-gla:gemini-3-flash-preview"
            echo "       GOOGLE_API_KEY=your_google_key"
            echo ""
            exit 1
        fi
        ;;
    google-gla|google)
        if [ -z "${GOOGLE_API_KEY:-}" ]; then
            echo -e "${RED}Error: LLM is set to '${LLM_VALUE}' but GOOGLE_API_KEY is not set.${NC}"
            echo ""
            echo "Either:"
            echo "  a) Set GOOGLE_API_KEY in .env  (get a key at https://aistudio.google.com/app/apikey)"
            echo "  b) Switch to a different provider, for example:"
            echo "       LLM=openai:gpt-4"
            echo "       OPENAI_API_KEY=your_openai_key"
            echo ""
            exit 1
        fi
        ;;
    anthropic)
        if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
            echo -e "${RED}Error: LLM is set to '${LLM_VALUE}' but ANTHROPIC_API_KEY is not set.${NC}"
            echo ""
            echo "Either:"
            echo "  a) Set ANTHROPIC_API_KEY in .env  (get a key at https://console.anthropic.com/)"
            echo "  b) Switch to a different provider, for example:"
            echo "       LLM=google-gla:gemini-3-flash-preview"
            echo "       GOOGLE_API_KEY=your_google_key"
            echo ""
            exit 1
        fi
        ;;
    ollama)
        # No cloud API key required for local Ollama.
        # OLLAMA_BASE_URL is optional (defaults to http://localhost:11434/v1).
        echo -e "${CYAN}Info: Using Ollama as the LLM provider.${NC}"
        echo "Make sure your Ollama server is running before processing videos."
        OLLAMA_URL="${OLLAMA_BASE_URL:-http://localhost:11434/v1}"
        echo "  Ollama endpoint: ${OLLAMA_URL}"
        echo ""
        ;;
    *)
        # Unknown / custom provider — warn but don't block startup
        if [ -z "${OPENAI_API_KEY:-}" ] && [ -z "${GOOGLE_API_KEY:-}" ] && [ -z "${ANTHROPIC_API_KEY:-}" ]; then
            echo -e "${YELLOW}Warning: LLM provider '${LLM_PROVIDER}' is not recognized and no provider key is set.${NC}"
            echo "If this is a custom provider, make sure the required credentials are present in .env."
            echo ""
        fi
        ;;
esac

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Error: Docker is not running!${NC}"
    echo "Please start Docker Desktop and try again."
    echo ""
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}Error: docker-compose is not installed!${NC}"
    echo "Please install Docker Compose and try again."
    echo ""
    exit 1
fi

# Determine which docker compose command to use
if docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
else
    DOCKER_COMPOSE="docker-compose"
fi

echo -e "${GREEN}Starting SupoClip...${NC}"
echo ""

# Build and start containers
echo "Building and starting Docker containers..."
echo "(This may take a few minutes on the first run)"
echo ""

$DOCKER_COMPOSE up -d --build

echo ""
echo -e "${GREEN}SupoClip is starting up!${NC}"
echo ""
echo "Services will be available at:"
echo "  - Frontend:  http://localhost:3000"
echo "  - Backend:   http://localhost:8000"
echo "  - API Docs:  http://localhost:8000/docs"
echo ""
echo "To view logs, run:"
echo "  $DOCKER_COMPOSE logs -f"
echo ""
echo "To stop all services, run:"
echo "  $DOCKER_COMPOSE down"
echo ""
echo "Waiting for services to be healthy..."

# Wait for services to be healthy
sleep 5

# Check if services are running
if $DOCKER_COMPOSE ps | grep -q "Up"; then
    echo -e "${GREEN}Services are starting successfully!${NC}"
    echo ""
    echo "You can now:"
    echo "  1. Open http://localhost:3000 in your browser"
    echo "  2. View logs: $DOCKER_COMPOSE logs -f"
    echo "  3. Stop services: $DOCKER_COMPOSE down"
else
    echo -e "${YELLOW}Services are starting... Check logs if you encounter issues:${NC}"
    echo "  $DOCKER_COMPOSE logs -f"
fi

echo ""
echo "============================================"
