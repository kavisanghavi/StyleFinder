#!/bin/bash
# ============================================
# Post-Create Script for Dev Container
# ============================================
# This script runs after the dev container is created

set -e

echo "🔧 Setting up AI Closet Scanner development environment..."

# Navigate to backend directory
cd /workspace/backend-api

# Check if .env exists, if not copy from example
if [ ! -f .env ]; then
    echo "📝 Creating .env file from .env.example..."
    cp .env.example .env
    echo "⚠️  Remember to update .env with your API keys!"
fi

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "🐍 Creating Python virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
source venv/bin/activate

# Upgrade pip
echo "📦 Upgrading pip..."
pip install --upgrade pip

# Install requirements
echo "📦 Installing Python dependencies..."
pip install -r requirements.txt

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Update backend-api/.env with your API keys"
echo "  2. Run: cd backend-api && ./start.sh"
echo ""
