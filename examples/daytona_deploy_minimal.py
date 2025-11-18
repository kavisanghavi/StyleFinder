#!/usr/bin/env python3
"""
Minimal Daytona Deployment Example

This is the simplest way to deploy StyleFinder to Daytona using the SDK.

Usage:
    python3 daytona_deploy_minimal.py
"""

from daytona import Daytona, DaytonaConfig

# =============================================================================
# CONFIGURATION - UPDATE THESE VALUES
# =============================================================================

DAYTONA_API_KEY = "daytona_your_api_key_here"  # Get from https://app.daytona.io

# Your API credentials
ANTHROPIC_API_KEY = "sk-ant-..."
GEMINI_API_KEY = "your-gemini-key"
SUPABASE_URL = "https://xxxxx.supabase.co"
SUPABASE_KEY = "eyJhbGci..."
TIGRIS_ACCESS_KEY = "tid_..."
TIGRIS_SECRET_KEY = "tsec_..."

# =============================================================================


def main():
    print("🚀 Deploying StyleFinder to Daytona...\n")

    # 1. Initialize Daytona client
    print("🔌 Connecting to Daytona...")
    config = DaytonaConfig(api_key=DAYTONA_API_KEY)
    daytona = Daytona(config)
    print("✅ Connected\n")

    # 2. Create sandbox
    print("📦 Creating sandbox...")
    sandbox = daytona.create()
    sandbox_id = sandbox.id
    print(f"✅ Sandbox created: {sandbox_id}\n")

    # 3. Clone repository
    print("📥 Cloning repository...")
    result = sandbox.process.code_run("""
cd /workspace
git clone https://github.com/kavisanghavi/StyleFinder .
git checkout claude/daytona-bulk-image-processing-01FccCMhmkhcERQ8h8aLmJNN
""")

    if result.exit_code != 0:
        print(f"❌ Failed: {result.result}")
        sandbox.delete()
        return

    print("✅ Repository cloned\n")

    # 4. Create .env file with credentials
    print("🔧 Setting up environment variables...")

    env_content = f"""
ANTHROPIC_API_KEY={ANTHROPIC_API_KEY}
GEMINI_API_KEY={GEMINI_API_KEY}
SUPABASE_URL={SUPABASE_URL}
SUPABASE_KEY={SUPABASE_KEY}
TIGRIS_ACCESS_KEY={TIGRIS_ACCESS_KEY}
TIGRIS_SECRET_KEY={TIGRIS_SECRET_KEY}
TIGRIS_ENDPOINT=https://fly.storage.tigris.dev
TIGRIS_BUCKET=closet-scanner
""".strip()

    sandbox.filesystem.write(
        path="/workspace/backend-api/.env",
        content=env_content
    )

    print("✅ Environment configured\n")

    # 5. Install dependencies
    print("📦 Installing dependencies (this may take 2-3 minutes)...")

    result = sandbox.process.code_run("""
cd /workspace/backend-api
python3 -m venv venv
source venv/bin/activate
pip install --quiet --upgrade pip
pip install --quiet -r requirements.txt
""")

    print("✅ Dependencies installed\n")

    # 6. Start server
    print("🚀 Starting FastAPI server...")

    # Start server in background session
    sandbox.process.start_session(
        command="""
cd /workspace/backend-api
source venv/bin/activate
uvicorn app.main:app --host 0.0.0.0 --port 8000
"""
    )

    print("⏳ Waiting for server to start...")
    import time
    time.sleep(10)

    # 7. Get public URL
    public_url = f"https://8000-{sandbox_id}.daytona.app"

    print("✅ Server started!\n")

    # 8. Verify deployment
    print("🔍 Verifying deployment...")

    import requests
    try:
        response = requests.get(f"{public_url}/health", timeout=10)
        if response.status_code == 200:
            print("✅ Deployment verified!\n")
        else:
            print(f"⚠️  Health check returned status {response.status_code}\n")
    except Exception as e:
        print(f"⚠️  Could not verify: {e}\n")

    # 9. Print success message
    print("=" * 70)
    print("🎉 Deployment Complete!")
    print("=" * 70)
    print()
    print(f"📍 Your API is live at:")
    print(f"   {public_url}")
    print()
    print(f"📚 API Documentation:")
    print(f"   {public_url}/docs")
    print()
    print(f"🧪 Test bulk processing:")
    print(f'   curl -X POST "{public_url}/bulk-analyze" \\')
    print(f'     -F "user_id=test-user-123" \\')
    print(f'     -F "files=@shirt1.jpg"')
    print()
    print(f"🆔 Sandbox ID: {sandbox_id}")
    print()
    print("💡 Tip: Sandbox will stay running. To delete it:")
    print(f"   sandbox.delete()  # or use Daytona dashboard")
    print()
    print("=" * 70)

    # Keep reference to sandbox for cleanup
    return sandbox


if __name__ == "__main__":
    try:
        sandbox = main()

        # Keep script running to maintain sandbox
        print("\n⏸️  Press Ctrl+C to exit (sandbox will keep running)...")

        import time
        while True:
            time.sleep(60)

    except KeyboardInterrupt:
        print("\n\n👋 Exiting. Sandbox is still running on Daytona.")
        print("   Delete it from the Daytona dashboard when done.")

    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
