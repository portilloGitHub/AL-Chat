"""
Test Runner
Runs all tests in sequence
"""
import subprocess
import sys
from pathlib import Path

def run_test(script_name, description):
    """Run a test script"""
    print("\n" + "="*70)
    print(f"  {description}")
    print("="*70)
    
    script_path = Path(__file__).parent / script_name
    result = subprocess.run([sys.executable, str(script_path)], capture_output=False)
    
    return result.returncode == 0

def main():
    """Run all tests"""
    print("\n" + "="*70)
    print("  AL-Chat Backend Test Suite")
    print("="*70)
    
    tests = [
        ("test_credentials.py", "Testing Credential Manager"),
        ("test_openai_service.py", "Testing OpenAI Service (requires .env)"),
        ("test_backend.py", "Testing Backend API (requires server running)"),
    ]
    
    results = []
    
    for script, description in tests:
        success = run_test(script, description)
        results.append((description, success))
        
        if not success and "Backend API" not in description:
            print(f"\n⚠️  {description} failed. Continuing with other tests...")
    
    # Summary
    print("\n" + "="*70)
    print("  Test Summary")
    print("="*70)
    
    for description, success in results:
        status = "✅ PASSED" if success else "❌ FAILED"
        print(f"  {description:50s} {status}")
    
    total = len(results)
    passed = sum(1 for _, success in results if success)
    
    print(f"\n  Total: {passed}/{total} test suites passed")
    
    if passed == total:
        print("\n🎉 All tests passed!")
        return 0
    else:
        print(f"\n⚠️  {total - passed} test suite(s) had issues")
        return 1

if __name__ == "__main__":
    sys.exit(main())
