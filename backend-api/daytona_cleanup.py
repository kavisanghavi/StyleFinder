#!/usr/bin/env python3
"""
Daytona Sandbox Cleanup Script
================================

Deletes a Daytona sandbox created by daytona_deploy.py

Usage:
    python daytona_cleanup.py [sandbox_id]

If no sandbox_id is provided, reads from .daytona_sandbox_id file
"""

import sys
import os
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()

def cleanup_sandbox(sandbox_id=None):
    """Delete a Daytona sandbox."""
    try:
        from daytona import Daytona
    except ImportError:
        print("❌ Daytona SDK not installed!")
        print("   Install with: pip install daytona")
        sys.exit(1)

    # Get sandbox ID
    if not sandbox_id:
        id_file = Path('.daytona_sandbox_id')
        if id_file.exists():
            sandbox_id = id_file.read_text().strip()
        else:
            print("❌ No sandbox ID provided and no .daytona_sandbox_id file found")
            print("\nUsage: python daytona_cleanup.py [sandbox_id]")
            sys.exit(1)

    print(f"🗑️  Deleting sandbox: {sandbox_id}")

    # Initialize Daytona
    daytona = Daytona()

    # Get sandbox
    try:
        sandbox = daytona.get_sandbox(sandbox_id)
        sandbox.delete()
        print(f"✅ Sandbox {sandbox_id} deleted successfully!")

        # Remove ID file if it exists
        id_file = Path('.daytona_sandbox_id')
        if id_file.exists():
            id_file.unlink()

    except Exception as e:
        print(f"❌ Failed to delete sandbox: {e}")
        sys.exit(1)

if __name__ == "__main__":
    sandbox_id = sys.argv[1] if len(sys.argv) > 1 else None
    cleanup_sandbox(sandbox_id)
