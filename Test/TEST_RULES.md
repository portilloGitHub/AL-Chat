# Test Rules

## Rule: All Test-Related Items Go Into Test Folder

**Established:** 2026-01-12

## Rule Definition

All test-related files, scripts, utilities, and documentation MUST be placed in the `Test/` folder at the project root level.

## What Goes in Test Folder

✅ **Include:**
- Test scripts (`test_*.py`)
- Test utilities and helpers
- Test configuration files
- Test data files
- Test documentation
- Test requirements (`requirements.txt`)
- Mock data and fixtures
- Integration test scripts
- Unit test files
- End-to-end test scripts
- Performance test scripts
- Test runners

❌ **Do NOT Include:**
- Production code
- Backend/Frontend source files
- Production dependencies
- Session logs (goes in `SessionLog/`)
- Documentation (goes in `Docs/`)

## Folder Structure

```
Test/
├── __init__.py              # Python package marker
├── test_*.py                # Test scripts
├── run_tests.py            # Test runners
├── requirements.txt        # Test dependencies
├── README.md               # Test documentation
├── TEST_RULES.md           # This file
├── fixtures/               # Test data fixtures (if needed)
├── mocks/                  # Mock objects (if needed)
└── utils/                  # Test utilities (if needed)
```

## Naming Conventions

- Test scripts: `test_<module_name>.py`
- Test utilities: `test_utils.py` or `utils/`
- Test data: `test_data/` or `fixtures/`
- Test runners: `run_tests.py` or `run_<test_type>.py`

## Examples

### ✅ Correct
- `Test/test_backend.py`
- `Test/test_credentials.py`
- `Test/fixtures/sample_data.json`
- `Test/utils/test_helpers.py`

### ❌ Incorrect
- `Backend/test_main.py` ❌
- `Frontend/tests/` ❌
- `test_*.py` in root ❌
- `Backend/tests/` ❌

## Integration with CI/CD

When setting up CI/CD pipelines:
- All test commands should reference `Test/` folder
- Test dependencies should be installed from `Test/requirements.txt`
- Test reports should be generated in `Test/` or `Test/reports/`

## Exceptions

None. This rule applies to ALL test-related items in the project.

## Enforcement

- Code reviews should check that tests are in `Test/` folder
- New test files outside `Test/` should be moved
- Documentation should reference `Test/` folder for all testing

## Related Rules

- Documentation goes in `Docs/`
- Session logs go in `SessionLog/`
- Code reviews go in `CodeReview/`
