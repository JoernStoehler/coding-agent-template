"""
Pytest configuration and shared fixtures

This file is automatically loaded by pytest and provides
fixtures available to all tests.

Recent changes:
- 2025-01-04: Initial test configuration

Related files:
- pyproject.toml - Pytest configuration
- tests/unit/ - Unit test fixtures
- tests/integration/ - Integration test fixtures
"""

import sys
from pathlib import Path
from unittest.mock import MagicMock

import pytest

# Add src to Python path for imports
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))


@pytest.fixture(scope="session")
def test_data_dir() -> Path:
    """Directory containing test data files"""
    return Path(__file__).parent / "data"


@pytest.fixture(scope="session")
def temp_test_dir(tmp_path_factory) -> Path:
    """Session-scoped temporary directory for tests"""
    return tmp_path_factory.mktemp("test_session")


@pytest.fixture
def mock_config(monkeypatch):
    """Mock configuration for testing"""
    test_config = {
        "PROJECT_NAME": "test-project",
        "ENVIRONMENT": "test",
        "API_PORT": 8001,
        "LOG_LEVEL": "DEBUG",
        "TELEMETRY_ENABLED": False,
        "MAX_FILE_SIZE_MB": 10,
    }

    for key, value in test_config.items():
        monkeypatch.setenv(key, str(value))

    return test_config


@pytest.fixture
def mock_telemetry():
    """Mock telemetry client"""
    telemetry = MagicMock()
    telemetry.record_event = MagicMock()
    telemetry.record_metric = MagicMock()
    telemetry.create_span = MagicMock()
    return telemetry


@pytest.fixture
def sample_data():
    """Sample data for testing"""
    return {
        "users": [
            {"id": "1", "name": "Alice", "email": "alice@example.com"},
            {"id": "2", "name": "Bob", "email": "bob@example.com"},
        ],
        "projects": [
            {"id": "p1", "name": "Project Alpha", "owner_id": "1"},
            {"id": "p2", "name": "Project Beta", "owner_id": "2"},
        ],
    }


@pytest.fixture(autouse=True)
def reset_environment(monkeypatch):
    """Reset environment variables for each test"""
    # Clear any existing env vars that might interfere
    env_vars_to_clear = [
        "HONEYCOMB_API_KEY",
        "DATABASE_URL",
        "REDIS_URL",
    ]
    for var in env_vars_to_clear:
        monkeypatch.delenv(var, raising=False)


@pytest.fixture
def mock_external_api():
    """Mock external API responses"""
    mock = MagicMock()
    mock.get.return_value.json.return_value = {"status": "ok"}
    mock.post.return_value.json.return_value = {"id": "123", "created": True}
    return mock


# Markers for test categorization
def pytest_configure(config):
    """Register custom markers"""
    config.addinivalue_line(
        "markers", "slow: marks tests as slow (deselect with '-m \"not slow\"')"
    )
    config.addinivalue_line("markers", "integration: marks tests as integration tests")
    config.addinivalue_line("markers", "unit: marks tests as unit tests")
    config.addinivalue_line("markers", "e2e: marks tests as end-to-end tests")


# Pytest hooks for better output
def pytest_collection_modifyitems(config, items):
    """Automatically mark tests based on their location"""
    for item in items:
        # Add markers based on test location
        if "unit" in str(item.fspath):
            item.add_marker(pytest.mark.unit)
        elif "integration" in str(item.fspath):
            item.add_marker(pytest.mark.integration)
        elif "e2e" in str(item.fspath):
            item.add_marker(pytest.mark.e2e)


@pytest.fixture(scope="session")
def event_loop_policy():
    """Event loop policy for async tests"""
    import asyncio

    if sys.platform == "win32":
        # Windows requires ProactorEventLoop for subprocess support
        asyncio.set_event_loop_policy(asyncio.WindowsProactorEventLoopPolicy())
    return asyncio.get_event_loop_policy()


# Performance testing fixtures
@pytest.fixture
def benchmark_data():
    """Large dataset for performance testing"""
    return {
        "large_list": list(range(10000)),
        "text_data": "x" * 1000000,  # 1MB of text
        "nested_dict": {
            f"key_{i}": {"value": i, "nested": {"data": f"item_{i}"}} for i in range(1000)
        },
    }


# Helper functions for tests
class TestHelpers:
    """Common test helper methods"""

    @staticmethod
    def assert_valid_response(response, expected_status=200):
        """Assert API response is valid"""
        assert response.status_code == expected_status
        data = response.json()
        assert "error" not in data or data["error"] is None
        return data

    @staticmethod
    def create_test_file(path: Path, content: str = "test content"):
        """Create a test file with content"""
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)
        return path

    @staticmethod
    def async_return(value):
        """Helper to create async return values"""

        async def _return():
            return value

        return _return()


@pytest.fixture
def test_helpers():
    """Provide test helper methods"""
    return TestHelpers()
