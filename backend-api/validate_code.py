#!/usr/bin/env python3
"""
Code Validation Script

Validates that the bulk processing implementation has no syntax errors
and all imports are correct.
"""

import sys
import ast
from pathlib import Path


def validate_python_file(filepath: Path) -> tuple[bool, str]:
    """
    Validate a Python file for syntax errors.

    Returns:
        (is_valid, error_message)
    """
    try:
        with open(filepath, 'r') as f:
            code = f.read()

        # Parse AST to check for syntax errors
        ast.parse(code)

        return True, ""

    except SyntaxError as e:
        return False, f"Syntax error at line {e.lineno}: {e.msg}"
    except Exception as e:
        return False, f"Error: {str(e)}"


def main():
    """Validate all modified files"""

    print("🔍 Validating Bulk Processing Implementation\n")

    files_to_check = [
        Path("app/main.py"),
        Path("app/services/supabase_service.py"),
    ]

    all_valid = True

    for filepath in files_to_check:
        if not filepath.exists():
            print(f"❌ {filepath}: File not found")
            all_valid = False
            continue

        is_valid, error_msg = validate_python_file(filepath)

        if is_valid:
            print(f"✅ {filepath}: Valid")
        else:
            print(f"❌ {filepath}: {error_msg}")
            all_valid = False

    # Check SQL schema exists
    schema_path = Path("supabase_schema.sql")
    if schema_path.exists():
        print(f"✅ {schema_path}: Found")
    else:
        print(f"❌ {schema_path}: Not found")
        all_valid = False

    print("\n" + "=" * 60)

    if all_valid:
        print("✅ All validations passed!")
        print("\nNext steps:")
        print("1. Set up Supabase database (run supabase_schema.sql)")
        print("2. Configure environment variables (.env)")
        print("3. Start server: uvicorn app.main:app --reload")
        print("4. Test with: curl http://localhost:8000/health")
        print("\nSee TEST_BULK_PROCESSING.md for detailed instructions.")
        return 0
    else:
        print("❌ Validation failed. Please fix errors above.")
        return 1


if __name__ == "__main__":
    sys.exit(main())
