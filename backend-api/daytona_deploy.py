#!/usr/bin/env python3
"""
Daytona SDK Deployment Script for AI Closet Scanner
====================================================

This script uses the Daytona SDK to create a sandbox environment
and deploy the AI Closet Scanner backend API.

Prerequisites:
1. Install Daytona SDK: pip install daytona
2. Get API key from: https://app.daytona.io/dashboard/keys
3. Set environment variables in .env file

Environment Variables Required:
- DAYTONA_API_KEY: Your Daytona API key
- ANTHROPIC_API_KEY: Claude API key
- ELEVENLABS_API_KEY: Voice synthesis
- GEMINI_API_KEY: Virtual try-on
- TIGRIS_ACCESS_KEY: Cloud storage
- TIGRIS_SECRET_KEY: Cloud storage
- GALILEO_API_KEY: Observability

Usage:
    python daytona_deploy.py
"""

import os
import sys
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def check_requirements():
    """Check if all required dependencies and env vars are present."""
    try:
        from daytona import Daytona, Image
    except ImportError:
        print("❌ Daytona SDK not installed!")
        print("   Install with: pip install daytona")
        sys.exit(1)

    required_vars = [
        'DAYTONA_API_KEY',
        'ANTHROPIC_API_KEY',
        'ELEVENLABS_API_KEY',
        'GEMINI_API_KEY',
    ]

    missing_vars = [var for var in required_vars if not os.getenv(var)]

    if missing_vars:
        print("❌ Missing required environment variables:")
        for var in missing_vars:
            print(f"   - {var}")
        print("\nGet DAYTONA_API_KEY from: https://app.daytona.io/dashboard/keys")
        sys.exit(1)

    print("✅ All requirements met!")

def create_sandbox():
    """Create and configure a Daytona sandbox for the backend."""
    from daytona import Daytona, Image, CreateSandboxFromImageParams

    print("\n🔧 Creating Daytona sandbox...")

    # Initialize Daytona SDK
    daytona = Daytona()

    # Build custom image with dependencies
    print("📦 Building custom image with dependencies...")
    # Note: debian_slim comes with system packages like gcc, curl already installed
    # We only need to install Python packages
    image = (
        Image.debian_slim("3.11")
        .pip_install([
            "fastapi==0.104.1",
            "uvicorn[standard]==0.24.0",
            "python-multipart==0.0.6",
            "pydantic==2.5.0",
            "pydantic-settings==2.1.0",
            "anthropic==0.7.1",
            "elevenlabs==0.2.27",
            "google-generativeai==0.3.1",
            "boto3==1.29.7",
            "python-dotenv==1.0.0",
            # galileo-observe removed due to httpx dependency conflict
            "httpx>=0.23.0",  # Compatible with anthropic
            "pillow==10.1.0",
            "python-jose[cryptography]==3.3.0",
            "starlette==0.27.0"
        ])
        .workdir("/workspace")
    )

    # Create sandbox
    print("🚀 Creating sandbox (this may take a few minutes)...")
    sandbox = daytona.create(
        CreateSandboxFromImageParams(image=image),
        on_snapshot_create_logs=lambda log: print(f"   {log}", end='')
    )

    print(f"\n✅ Sandbox created! ID: {sandbox.id}")

    return sandbox

def deploy_backend(sandbox):
    """Deploy the FastAPI backend in the sandbox."""
    print("\n📁 Uploading backend code...")

    # Get the backend directory
    backend_dir = Path(__file__).parent / "backend-api"

    if not backend_dir.exists():
        print(f"❌ Backend directory not found: {backend_dir}")
        sys.exit(1)

    # Upload application code
    print("   Uploading app/ directory...")
    sandbox.fs.upload(str(backend_dir / "app"), "/workspace/app")

    print("   Uploading requirements.txt...")
    sandbox.fs.upload(str(backend_dir / "requirements.txt"), "/workspace/requirements.txt")

    # Create .env file in sandbox
    print("   Creating .env file...")
    env_content = f"""
ANTHROPIC_API_KEY={os.getenv('ANTHROPIC_API_KEY')}
ELEVENLABS_API_KEY={os.getenv('ELEVENLABS_API_KEY')}
GEMINI_API_KEY={os.getenv('GEMINI_API_KEY')}
TIGRIS_ACCESS_KEY={os.getenv('TIGRIS_ACCESS_KEY', '')}
TIGRIS_SECRET_KEY={os.getenv('TIGRIS_SECRET_KEY', '')}
GALILEO_API_KEY={os.getenv('GALILEO_API_KEY', '')}
BREX_API_KEY={os.getenv('BREX_API_KEY', '')}
WEATHER_API_KEY={os.getenv('WEATHER_API_KEY', '')}
ENVIRONMENT=production
BACKEND_URL=https://preview-{sandbox.id}.daytona.app
""".strip()

    sandbox.fs.write("/workspace/.env", env_content)

    print("✅ Backend code uploaded!")

def start_server(sandbox):
    """Start the FastAPI server in the sandbox."""
    print("\n🚀 Starting FastAPI server...")

    # Start uvicorn in background
    result = sandbox.process.start_and_wait(
        cmd="uvicorn app.main:app --host 0.0.0.0 --port 8000",
        background=True
    )

    print("✅ Server started!")

    return result

def get_preview_url(sandbox):
    """Get the preview URL for the running service."""
    # Daytona provides preview URLs for services running on ports
    preview_url = f"https://preview-{sandbox.id}.daytona.app"
    return preview_url

def main():
    """Main deployment function."""
    print("=" * 60)
    print("  🚀 AI Closet Scanner - Daytona Deployment")
    print("=" * 60)

    # Check requirements
    check_requirements()

    # Create sandbox
    sandbox = create_sandbox()

    try:
        # Deploy backend code
        deploy_backend(sandbox)

        # Start server
        start_server(sandbox)

        # Get preview URL
        preview_url = get_preview_url(sandbox)

        # Success message
        print("\n" + "=" * 60)
        print("  ✅ Deployment Successful!")
        print("=" * 60)
        print(f"\n📡 Backend API:     {preview_url}")
        print(f"📚 API Docs:        {preview_url}/docs")
        print(f"📊 Dashboard:       {preview_url}/dashboard")
        print(f"🏥 Health Check:    {preview_url}/health")
        print(f"\n🔧 Sandbox ID:      {sandbox.id}")
        print("\nUpdate your iOS app's APIClient.swift with the Backend API URL!")
        print("\nTo delete this sandbox later, run:")
        print(f"   python daytona_cleanup.py {sandbox.id}")
        print("=" * 60)

        # Save sandbox ID to file
        with open('.daytona_sandbox_id', 'w') as f:
            f.write(sandbox.id)

    except Exception as e:
        print(f"\n❌ Deployment failed: {e}")
        print("\nCleaning up sandbox...")
        sandbox.delete()
        sys.exit(1)

if __name__ == "__main__":
    main()
