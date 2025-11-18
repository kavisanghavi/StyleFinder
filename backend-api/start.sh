#!/bin/bash
# ============================================
# AI Closet Scanner - Backend Startup Script
# ============================================
# Quick start script for the FastAPI backend

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Print banner
echo -e "${CYAN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║          🚀 AI Closet Scanner Backend API                      ║
║          Powered by Claude, Gemini, and ElevenLabs             ║
╚═══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Function to check if running in Daytona
check_daytona() {
    if [ -n "$DAYTONA_WORKSPACE_ID" ]; then
        echo -e "${GREEN}✅ Running in Daytona workspace: $DAYTONA_WORKSPACE_ID${NC}"
        return 0
    else
        echo -e "${BLUE}ℹ️  Running locally${NC}"
        return 1
    fi
}

# Function to check environment variables
check_env() {
    echo -e "${BLUE}🔍 Checking environment configuration...${NC}"

    if [ ! -f .env ]; then
        echo -e "${YELLOW}⚠️  No .env file found. Creating from .env.example...${NC}"
        if [ -f .env.example ]; then
            cp .env.example .env
            echo -e "${GREEN}✅ Created .env file${NC}"
            echo -e "${YELLOW}⚠️  Please update .env with your API keys before continuing!${NC}"
            exit 1
        else
            echo -e "${RED}❌ No .env.example found!${NC}"
            exit 1
        fi
    fi

    # Check for required API keys
    source .env 2>/dev/null || true

    local missing_keys=()

    if [ -z "$ANTHROPIC_API_KEY" ] || [ "$ANTHROPIC_API_KEY" = "sk-ant-api03-your-key-here" ]; then
        missing_keys+=("ANTHROPIC_API_KEY")
    fi

    if [ -z "$ELEVENLABS_API_KEY" ] || [ "$ELEVENLABS_API_KEY" = "your_elevenlabs_key_here" ]; then
        missing_keys+=("ELEVENLABS_API_KEY")
    fi

    if [ -z "$GEMINI_API_KEY" ] || [ "$GEMINI_API_KEY" = "your_gemini_key_here" ]; then
        missing_keys+=("GEMINI_API_KEY")
    fi

    if [ ${#missing_keys[@]} -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Missing or placeholder API keys detected:${NC}"
        for key in "${missing_keys[@]}"; do
            echo -e "   ${YELLOW}- $key${NC}"
        done
        echo -e "${YELLOW}⚠️  Some features may not work without valid API keys${NC}"
        echo ""
    else
        echo -e "${GREEN}✅ All required API keys configured${NC}"
    fi
}

# Function to check Python version
check_python() {
    echo -e "${BLUE}🐍 Checking Python version...${NC}"

    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}❌ Python 3 is not installed!${NC}"
        exit 1
    fi

    PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
    PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d'.' -f1)
    PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d'.' -f2)

    if [ "$PYTHON_MAJOR" -lt 3 ] || ([ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -lt 11 ]); then
        echo -e "${RED}❌ Python 3.11+ is required. You have Python $PYTHON_VERSION${NC}"
        exit 1
    fi

    echo -e "${GREEN}✅ Python $PYTHON_VERSION detected${NC}"
}

# Function to setup virtual environment
setup_venv() {
    if [ ! -d "venv" ]; then
        echo -e "${BLUE}📦 Creating virtual environment...${NC}"
        python3 -m venv venv
        echo -e "${GREEN}✅ Virtual environment created${NC}"
    fi

    echo -e "${BLUE}🔌 Activating virtual environment...${NC}"
    source venv/bin/activate
}

# Function to install dependencies
install_deps() {
    echo -e "${BLUE}📦 Installing dependencies...${NC}"

    # Upgrade pip first
    pip install --upgrade pip setuptools wheel -q

    # Install requirements
    if [ -f requirements.txt ]; then
        pip install -r requirements.txt -q
        echo -e "${GREEN}✅ Dependencies installed${NC}"
    else
        echo -e "${RED}❌ requirements.txt not found!${NC}"
        exit 1
    fi
}

# Function to check if port is available
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Port $port is already in use${NC}"
        echo -e "${YELLOW}   Attempting to kill existing process...${NC}"
        lsof -ti:$port | xargs kill -9 2>/dev/null || true
        sleep 2
    fi
}

# Function to display service URLs
show_urls() {
    echo ""
    echo -e "${PURPLE}════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}  🌐 Service URLs${NC}"
    echo -e "${PURPLE}════════════════════════════════════════════════════${NC}"

    if check_daytona; then
        echo -e "${CYAN}📡 Backend API:${NC}     $DAYTONA_WORKSPACE_URL"
        echo -e "${CYAN}📚 API Docs:${NC}        $DAYTONA_WORKSPACE_URL/docs"
        echo -e "${CYAN}📊 Dashboard:${NC}       $DAYTONA_WORKSPACE_URL/dashboard"
        echo -e "${CYAN}🏥 Health Check:${NC}    $DAYTONA_WORKSPACE_URL/health"
    else
        echo -e "${CYAN}📡 Backend API:${NC}     http://localhost:8000"
        echo -e "${CYAN}📚 API Docs:${NC}        http://localhost:8000/docs"
        echo -e "${CYAN}📊 Dashboard:${NC}       http://localhost:8000/dashboard"
        echo -e "${CYAN}🏥 Health Check:${NC}    http://localhost:8000/health"
    fi

    echo -e "${PURPLE}════════════════════════════════════════════════════${NC}"
    echo ""
}

# Function to start the server
start_server() {
    echo -e "${GREEN}🚀 Starting FastAPI server...${NC}"
    echo ""

    # Check port availability
    check_port 8000

    # Set PYTHONPATH
    export PYTHONPATH="${PYTHONPATH}:$(pwd)"

    # Start uvicorn
    if check_daytona; then
        # Production mode in Daytona
        uvicorn app.main:app --host 0.0.0.0 --port 8000 --log-level info
    else
        # Development mode locally
        uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
    fi
}

# Main execution
main() {
    # Navigate to script directory
    cd "$(dirname "$0")"

    # Run checks
    check_daytona
    check_python
    check_env

    # Setup environment (skip venv in Daytona)
    if ! check_daytona; then
        setup_venv
        install_deps
    else
        echo -e "${GREEN}✅ Dependencies already managed by Daytona${NC}"
    fi

    # Show service URLs
    show_urls

    # Start server
    start_server
}

# Run main function
main
