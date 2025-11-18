#!/bin/bash

# Navigate to backend-api directory
cd "$(dirname "$0")"

# Activate virtual environment
source venv/bin/activate

# Set PYTHONPATH
export PYTHONPATH="${PYTHONPATH}:$(pwd)"

# Start uvicorn
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
