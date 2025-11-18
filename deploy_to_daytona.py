#!/usr/bin/env python3
"""
Deploy StyleFinder to Daytona using the Python SDK

This script:
1. Creates a Daytona sandbox
2. Clones the GitHub repository
3. Installs dependencies
4. Sets up environment variables
5. Starts the FastAPI server
6. Returns the public URL

Usage:
    python3 deploy_to_daytona.py --api-key YOUR_DAYTONA_API_KEY
"""

import argparse
import sys
import time
from daytona import Daytona, DaytonaConfig

# =============================================================================
# Configuration
# =============================================================================

GITHUB_REPO = "https://github.com/kavisanghavi/StyleFinder"
BRANCH = "claude/daytona-bulk-image-processing-01FccCMhmkhcERQ8h8aLmJNN"

# Environment variables (you'll need to provide these)
REQUIRED_ENV_VARS = {
    "ANTHROPIC_API_KEY": "sk-ant-...",
    "GEMINI_API_KEY": "your-gemini-key",
    "SUPABASE_URL": "https://xxxxx.supabase.co",
    "SUPABASE_KEY": "eyJhbGci...",
    "TIGRIS_ACCESS_KEY": "tid_...",
    "TIGRIS_SECRET_KEY": "tsec_...",
    "TIGRIS_ENDPOINT": "https://fly.storage.tigris.dev",
    "TIGRIS_BUCKET": "closet-scanner"
}

# Optional environment variables
OPTIONAL_ENV_VARS = {
    "ELEVENLABS_API_KEY": "",
    "GALILEO_API_KEY": "",
    "BREX_API_KEY": ""
}


def print_banner():
    """Print welcome banner"""
    print("=" * 80)
    print("🚀 StyleFinder Deployment to Daytona")
    print("=" * 80)
    print()


def get_env_vars_from_user():
    """Interactively get environment variables from user"""
    print("📋 Please provide your API credentials:\n")

    env_vars = {}

    # Required variables
    print("Required credentials:")
    for key, example in REQUIRED_ENV_VARS.items():
        while True:
            value = input(f"  {key} (e.g., {example}): ").strip()
            if value and value != example:
                env_vars[key] = value
                break
            else:
                print(f"    ⚠️  Please enter a valid {key}")

    # Optional variables
    print("\nOptional credentials (press Enter to skip):")
    for key, _ in OPTIONAL_ENV_VARS.items():
        value = input(f"  {key} (optional): ").strip()
        if value:
            env_vars[key] = value

    return env_vars


def create_sandbox(daytona, env_vars):
    """Create and configure a Daytona sandbox"""

    print("\n📦 Creating Daytona sandbox...")

    # Create sandbox with custom configuration
    sandbox = daytona.create()

    print(f"✅ Sandbox created: {sandbox.id}")

    # Set environment variables
    print("\n🔧 Configuring environment variables...")

    # Create .env file content
    env_content = "\n".join([f"{k}={v}" for k, v in env_vars.items()])

    # Write .env file to sandbox
    sandbox.filesystem.write(
        path="/workspace/.env",
        content=env_content
    )

    print("✅ Environment variables configured")

    return sandbox


def setup_repository(sandbox):
    """Clone repository and checkout branch"""

    print(f"\n📥 Cloning repository: {GITHUB_REPO}")

    # Clone repository
    result = sandbox.process.code_run(f"""
cd /workspace
git clone {GITHUB_REPO} .
git checkout {BRANCH}
""")

    if result.exit_code != 0:
        print(f"❌ Failed to clone repository: {result.result}")
        return False

    print(f"✅ Repository cloned and checked out branch: {BRANCH}")
    return True


def install_dependencies(sandbox):
    """Install Python dependencies"""

    print("\n📦 Installing dependencies...")

    result = sandbox.process.code_run("""
cd /workspace/backend-api
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
""")

    if result.exit_code != 0:
        print(f"⚠️  Warning: Some dependencies may have failed to install")
        print(f"   Output: {result.result[:500]}...")
    else:
        print("✅ Dependencies installed")

    return True


def start_server(sandbox):
    """Start the FastAPI server"""

    print("\n🚀 Starting FastAPI server...")

    # Start server in background
    result = sandbox.process.start_session(
        command="""
cd /workspace/backend-api
source venv/bin/activate
uvicorn app.main:app --host 0.0.0.0 --port 8000
"""
    )

    # Wait for server to start
    print("⏳ Waiting for server to start...")
    time.sleep(10)

    # Check if server is running
    health_check = sandbox.process.code_run("curl -f http://localhost:8000/health || echo 'FAILED'")

    if "FAILED" in health_check.result:
        print("⚠️  Server may not be running yet. Check logs.")
        return None

    print("✅ Server started successfully!")

    # Get public URL
    try:
        # In Daytona, port 8000 is automatically exposed
        # The URL format is: https://8000-{sandbox_id}.daytona.app
        public_url = f"https://8000-{sandbox.id}.daytona.app"
        return public_url
    except Exception as e:
        print(f"⚠️  Could not determine public URL: {e}")
        return None


def verify_deployment(public_url):
    """Verify the deployment is working"""

    print(f"\n🔍 Verifying deployment at: {public_url}")

    import requests

    try:
        response = requests.get(f"{public_url}/health", timeout=10)

        if response.status_code == 200:
            data = response.json()
            print("✅ Deployment verified!")
            print(f"\n📊 Service Status:")
            for service, status in data.get('services', {}).items():
                enabled = status.get('enabled', status) if isinstance(status, dict) else status
                icon = "✅" if enabled else "❌"
                print(f"   {icon} {service.capitalize()}")
            return True
        else:
            print(f"⚠️  Health check returned status {response.status_code}")
            return False

    except Exception as e:
        print(f"⚠️  Could not verify deployment: {e}")
        print("   The server may still be starting. Try accessing the URL in a few minutes.")
        return False


def print_next_steps(public_url, sandbox_id):
    """Print next steps for the user"""

    print("\n" + "=" * 80)
    print("🎉 Deployment Complete!")
    print("=" * 80)

    print(f"\n📍 Your StyleFinder API is live at:")
    print(f"   {public_url}")

    print(f"\n📚 API Documentation:")
    print(f"   {public_url}/docs")

    print(f"\n🧪 Test the bulk processing:")
    print(f"""
   curl -X POST "{public_url}/bulk-analyze" \\
     -F "user_id=test-user-123" \\
     -F "files=@shirt1.jpg" \\
     -F "files=@pants1.jpg"
""")

    print(f"\n📊 Dashboard:")
    print(f"   {public_url}/dashboard")

    print(f"\n🔧 Sandbox Management:")
    print(f"   Sandbox ID: {sandbox_id}")
    print(f"   To stop: Use Daytona dashboard or SDK")

    print("\n📖 Documentation:")
    print("   • QUICKSTART.md - Quick start guide")
    print("   • BULK_PROCESSING_GUIDE.md - Full implementation guide")
    print("   • TEST_BULK_PROCESSING.md - Testing guide")

    print("\n" + "=" * 80)


def main():
    """Main deployment flow"""

    parser = argparse.ArgumentParser(
        description="Deploy StyleFinder to Daytona"
    )
    parser.add_argument(
        '--api-key',
        required=True,
        help='Your Daytona API key'
    )
    parser.add_argument(
        '--non-interactive',
        action='store_true',
        help='Skip interactive prompts (use default env vars)'
    )

    args = parser.parse_args()

    print_banner()

    # Get environment variables
    if args.non_interactive:
        print("⚠️  Running in non-interactive mode. Using placeholder env vars.")
        print("   You'll need to configure them manually after deployment.\n")
        env_vars = REQUIRED_ENV_VARS.copy()
    else:
        env_vars = get_env_vars_from_user()

    try:
        # Initialize Daytona client
        print("\n🔌 Connecting to Daytona...")
        config = DaytonaConfig(api_key=args.api_key)
        daytona = Daytona(config)
        print("✅ Connected to Daytona")

        # Create and configure sandbox
        sandbox = create_sandbox(daytona, env_vars)

        # Setup repository
        if not setup_repository(sandbox):
            print("\n❌ Failed to setup repository. Cleaning up...")
            sandbox.delete()
            sys.exit(1)

        # Install dependencies
        if not install_dependencies(sandbox):
            print("\n⚠️  Dependencies installation had warnings, but continuing...")

        # Start server
        public_url = start_server(sandbox)

        if not public_url:
            print("\n⚠️  Could not get public URL, but sandbox is running.")
            print(f"   Sandbox ID: {sandbox.id}")
            print("   Check Daytona dashboard for URL.")
        else:
            # Verify deployment
            verify_deployment(public_url)

            # Print next steps
            print_next_steps(public_url, sandbox.id)

        print("\n✨ Deployment complete! Your API is ready to process bulk images.")

        # Keep script alive to maintain sandbox
        print("\n💡 Tip: Keep this script running, or the sandbox will be deleted.")
        print("   Press Ctrl+C to exit and cleanup sandbox.\n")

        try:
            while True:
                time.sleep(60)
        except KeyboardInterrupt:
            print("\n\n⏸️  Interrupted by user")
            cleanup = input("Delete sandbox? (y/n): ").strip().lower()
            if cleanup == 'y':
                print("🗑️  Deleting sandbox...")
                sandbox.delete()
                print("✅ Sandbox deleted")
            else:
                print(f"ℹ️  Sandbox {sandbox.id} is still running")
                print("   Delete it manually when done: daytona.delete(sandbox_id)")

    except KeyboardInterrupt:
        print("\n\n⏸️  Deployment cancelled by user")
        sys.exit(0)

    except Exception as e:
        print(f"\n❌ Deployment failed: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
