"""
Test script to verify Galileo credentials and connection.
Run this to make sure your Galileo setup works before debugging the FastAPI integration.
"""

import os
from dotenv import load_dotenv
from datetime import datetime

# Load environment variables
load_dotenv()

try:
    from galileo import galileo_context
    from galileo.config import GalileoPythonConfig

    print("🔍 Testing Galileo connection...")
    print(f"API Key: {os.getenv('GALILEO_API_KEY')[:20]}..." if os.getenv('GALILEO_API_KEY') else "API Key: NOT SET")

    # Initialize Galileo
    galileo_context.init(project="closet-scanner", log_stream="test")
    logger = galileo_context.get_logger_instance()
    logger.start_session()

    print("✅ Galileo initialized successfully!")

    # Test logging a span
    logger.start_trace(name="test_trace", input={"operation": "test"})

    start_time_ns = datetime.now().timestamp() * 1_000_000_000

    logger.add_llm_span(
        input={"test": "input"},
        output={"test": "output"},
        model="test-model",
        duration_ns=int((datetime.now().timestamp() * 1_000_000_000) - start_time_ns)
    )

    logger.conclude(output={"status": "success"})
    logger.flush()

    print("✅ Successfully logged test span to Galileo!")

    # Try to get dashboard URL (optional)
    try:
        config = GalileoPythonConfig.get()
        project_url = f"{config.console_url}project/{logger.project_id}"
        print(f"\n🔗 Galileo Dashboard: {project_url}")
    except Exception as e:
        print(f"\n🔗 Galileo Dashboard: https://console.galileo.ai/project/{logger.project_id}")
        print(f"(Note: Could not fetch exact dashboard URL due to: {e})")

    print("\n✅ All tests passed! Galileo is working correctly.")

except Exception as e:
    print(f"\n❌ Error: {e}")
    import traceback
    traceback.print_exc()
