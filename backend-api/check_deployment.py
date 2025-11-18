#!/usr/bin/env python3
"""
Check Daytona deployment status and logs
"""
import os
from dotenv import load_dotenv

load_dotenv()

def check_deployment(sandbox_id):
    """Check if the server is running and view logs."""
    from daytona import Daytona

    daytona = Daytona()
    sandbox = daytona.get_sandbox(sandbox_id)

    print(f"📦 Sandbox Status: {sandbox.id}")
    print("\n" + "="*60)

    # Check if uvicorn process is running
    print("\n🔍 Checking for running processes...")
    result = sandbox.process.code_run("ps aux | grep uvicorn")
    print(result.result)

    print("\n" + "="*60)

    # Check if port 8000 is listening
    print("\n🔍 Checking if port 8000 is listening...")
    result = sandbox.process.code_run("netstat -tlnp 2>/dev/null | grep 8000 || ss -tlnp | grep 8000")
    print(result.result)

    print("\n" + "="*60)

    # Test local connection
    print("\n🔍 Testing local connection to port 8000...")
    result = sandbox.process.code_run("curl -s http://localhost:8000/health || echo 'Connection failed'")
    print(result.result)

    print("\n" + "="*60)

    # Check Python path and installed packages
    print("\n🔍 Checking Python environment...")
    result = sandbox.process.code_run("which python3 && python3 --version")
    print(result.result)

    print("\n" + "="*60)

    # Check if fastapi/uvicorn are installed
    print("\n🔍 Checking installed packages...")
    result = sandbox.process.code_run("python3 -m pip list | grep -E 'fastapi|uvicorn'")
    print(result.result)

    print("\n" + "="*60)

    # Check if files were uploaded correctly
    print("\n🔍 Checking uploaded files...")
    result = sandbox.process.code_run("ls -la /workspace/app/")
    print(result.result)

    print("\n" + "="*60)

    # Try to manually start the server to see errors
    print("\n🔍 Testing server startup (checking for errors)...")
    result = sandbox.process.code_run(
        "cd /workspace && timeout 5 python3 -m uvicorn app.main:app --host 0.0.0.0 --port 8000 2>&1 || true"
    )
    print(result.result)

    print("\n" + "="*60)

if __name__ == "__main__":
    import sys

    if len(sys.argv) > 1:
        sandbox_id = sys.argv[1]
    else:
        # Try to read from .daytona_sandbox_id file
        sandbox_id_file = ".daytona_sandbox_id"
        if os.path.exists(sandbox_id_file):
            with open(sandbox_id_file) as f:
                sandbox_id = f.read().strip()
        else:
            print("Usage: python check_deployment.py <sandbox_id>")
            print("Or create .daytona_sandbox_id file with the sandbox ID")
            sys.exit(1)

    check_deployment(sandbox_id)
