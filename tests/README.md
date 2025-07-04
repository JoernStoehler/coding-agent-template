# Testing Guide

This directory contains the test suite for the coding agent project, organized by test type for better maintainability and execution control.

## Test Structure

```
tests/
├── unit/           # Fast, isolated unit tests
├── integration/    # Tests with external dependencies
├── e2e/           # End-to-end workflow tests
├── data/          # Test fixtures and data files
└── conftest.py    # Shared pytest configuration
```

## Running Tests

### All Tests
```bash
# Run all tests with coverage
pytest tests/ -v --cov=src --cov-report=html

# Run tests in parallel for speed
pytest tests/ -v -n auto
```

### By Category
```bash
# Unit tests only (fast)
pytest tests/unit/ -v

# Integration tests
pytest tests/integration/ -v

# End-to-end tests
pytest tests/e2e/ -v

# Using markers
pytest -m unit          # Unit tests only
pytest -m "not slow"    # Skip slow tests
pytest -m integration   # Integration tests only
```

### Specific Tests
```bash
# Run specific test file
pytest tests/unit/test_config.py -v

# Run specific test function
pytest tests/unit/test_config.py::TestConfig::test_default_values -v

# Run tests matching pattern
pytest tests/ -k "config" -v
```

## Coverage Reports

```bash
# Generate coverage report
pytest tests/ --cov=src --cov-report=term-missing

# Generate HTML coverage report
pytest tests/ --cov=src --cov-report=html
# Open htmlcov/index.html in browser

# Check coverage threshold
pytest tests/ --cov=src --cov-fail-under=80
```

## Test Categories

### Unit Tests (`tests/unit/`)
- Test individual functions and classes in isolation
- Mock all external dependencies
- Should run in <1 second per test
- No network calls, file I/O, or database access

Example:
```python
def test_validate_email():
    assert validate_email("user@example.com") is True
    assert validate_email("invalid") is False
```

### Integration Tests (`tests/integration/`)
- Test interaction between components
- May use real databases, APIs, or file systems
- Use test databases/sandboxed environments
- Clean up after themselves

Example:
```python
@pytest.mark.integration
def test_database_connection(test_db):
    user = User.create(name="Test User")
    assert User.get(user.id).name == "Test User"
```

### End-to-End Tests (`tests/e2e/`)
- Test complete workflows
- Simulate real user scenarios
- May take longer to run
- Verify system behavior from user perspective

Example:
```python
@pytest.mark.e2e
def test_user_registration_flow(client):
    response = client.post("/register", json={...})
    assert response.status_code == 201
    # Verify email sent, user can login, etc.
```

## Writing Tests

### Test Naming Convention
```python
def test_should_do_something_when_condition():
    """Test that [expected behavior] when [condition]"""
    pass

def test_raises_error_on_invalid_input():
    """Test that appropriate error is raised for invalid input"""
    pass
```

### Using Fixtures
```python
def test_with_mock_config(mock_config):
    """Test using mocked configuration"""
    assert mock_config["ENVIRONMENT"] == "test"

def test_with_sample_data(sample_data):
    """Test using sample data fixture"""
    users = sample_data["users"]
    assert len(users) == 2
```

### Async Tests
```python
@pytest.mark.asyncio
async def test_async_operation():
    result = await async_function()
    assert result == expected_value
```

### Performance Tests
```python
def test_performance_benchmark(benchmark):
    result = benchmark(expensive_function, arg1, arg2)
    assert result == expected_value
    # Benchmark stats automatically collected
```

## Test Markers

Available markers (defined in `pyproject.toml`):
- `@pytest.mark.unit` - Unit tests (auto-applied based on location)
- `@pytest.mark.integration` - Integration tests
- `@pytest.mark.e2e` - End-to-end tests
- `@pytest.mark.slow` - Slow tests (>1 second)

## Debugging Tests

### Run with debugging
```bash
# Stop on first failure
pytest tests/ -x

# Drop into debugger on failure
pytest tests/ --pdb

# Show local variables on failure
pytest tests/ -l

# Increase verbosity
pytest tests/ -vv

# Show print statements
pytest tests/ -s
```

### VS Code Integration
```json
// .vscode/settings.json
{
    "python.testing.pytestEnabled": true,
    "python.testing.pytestArgs": [
        "tests",
        "-v"
    ]
}
```

## Continuous Integration

Tests are automatically run on:
- Every push to main/develop branches
- Every pull request
- Can be triggered manually

See `.github/workflows/ci.yml` for CI configuration.

## Testing Best Practices

1. **Isolation**: Each test should be independent
2. **Clarity**: Test names should describe what they test
3. **Speed**: Unit tests should be fast (<100ms)
4. **Coverage**: Aim for >80% code coverage
5. **Deterministic**: Tests should not be flaky
6. **Cleanup**: Always clean up resources

## Common Test Patterns

### Testing Exceptions
```python
def test_raises_on_invalid_input():
    with pytest.raises(ValueError, match="Invalid input"):
        function_under_test(invalid_input)
```

### Parametrized Tests
```python
@pytest.mark.parametrize("input,expected", [
    ("valid", True),
    ("", False),
    (None, False),
])
def test_validation(input, expected):
    assert validate(input) == expected
```

### Mocking External Services
```python
def test_external_api_call(mock_external_api):
    mock_external_api.get.return_value.json.return_value = {"status": "ok"}
    result = function_that_calls_api()
    assert result["status"] == "ok"
```

## Troubleshooting

### Common Issues

1. **Import errors**: Ensure `src/` is in PYTHONPATH
2. **Fixture not found**: Check fixture is in `conftest.py` or imported
3. **Slow tests**: Use markers to skip slow tests during development
4. **Flaky tests**: Add retries or fix race conditions

### Getting Help

- Check test output for detailed error messages
- Use `-vv` flag for more verbose output
- Review `conftest.py` for available fixtures
- See pytest documentation: https://docs.pytest.org/