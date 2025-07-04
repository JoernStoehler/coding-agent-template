"""
Unit tests for configuration module

Tests configuration loading, validation, and access patterns.

Related files:
- src/config.py - Configuration implementation
- .env.example - Configuration template
"""

import pytest

from src.config import Config


class TestConfig:
    """Test configuration management"""

    def test_default_values(self):
        """Test that default configuration values are set correctly"""
        assert Config.PROJECT_NAME == "coding-agent"
        assert Config.ENVIRONMENT == "development"
        assert Config.API_PORT == 8000
        assert Config.API_HOST == "0.0.0.0"
        assert Config.TELEMETRY_ENABLED is True
        assert Config.MAX_FILE_SIZE_MB == 100

    def test_environment_override(self, monkeypatch):
        """Test that environment variables override defaults"""
        monkeypatch.setenv("PROJECT_NAME", "test-project")
        monkeypatch.setenv("API_PORT", "9000")
        monkeypatch.setenv("TELEMETRY_ENABLED", "false")

        # Reload config module to pick up env changes
        import importlib

        import src.config

        importlib.reload(src.config)
        from src.config import Config as ReloadedConfig

        assert ReloadedConfig.PROJECT_NAME == "test-project"
        assert ReloadedConfig.API_PORT == 9000
        assert ReloadedConfig.TELEMETRY_ENABLED is False

    def test_validate_success(self):
        """Test successful configuration validation"""
        # Should not raise any exceptions
        Config.validate()

    def test_validate_invalid_port(self, monkeypatch):
        """Test validation with invalid port number"""
        monkeypatch.setattr(Config, "API_PORT", 70000)

        with pytest.raises(ValueError, match="Invalid API_PORT"):
            Config.validate()

    def test_validate_invalid_environment(self, monkeypatch):
        """Test validation with invalid environment"""
        monkeypatch.setattr(Config, "ENVIRONMENT", "invalid")

        with pytest.raises(ValueError, match="ENVIRONMENT must be one of"):
            Config.validate()

    def test_validate_invalid_log_level(self, monkeypatch):
        """Test validation with invalid log level"""
        monkeypatch.setattr(Config, "LOG_LEVEL", "INVALID")

        with pytest.raises(ValueError, match="LOG_LEVEL must be one of"):
            Config.validate()

    def test_validate_redis_cache_without_url(self, monkeypatch):
        """Test validation when using Redis cache without URL"""
        monkeypatch.setattr(Config, "CACHE_TYPE", "redis")
        monkeypatch.setattr(Config, "CACHE_REDIS_URL", None)

        with pytest.raises(ValueError, match="CACHE_REDIS_URL must be set"):
            Config.validate()

    def test_to_dict_redacts_sensitive_values(self):
        """Test that sensitive values are redacted in dict export"""
        # Set some sensitive values
        Config.SECRET_KEY = "super-secret-key"
        Config.API_TOKENS = ["token1", "token2"]
        Config.HONEYCOMB_API_KEY = "hcxxx"

        config_dict = Config.to_dict()

        # Check sensitive values are redacted
        assert config_dict["SECRET_KEY"] == "***REDACTED***"
        assert config_dict["API_TOKENS"] == ["***REDACTED0***", "***REDACTED1***"]
        assert config_dict["HONEYCOMB_API_KEY"] == "***REDACTED***"

        # Check non-sensitive values are preserved
        assert config_dict["PROJECT_NAME"] == Config.PROJECT_NAME
        assert config_dict["API_PORT"] == Config.API_PORT

    def test_get_project_root(self):
        """Test project root directory detection"""
        root = Config.get_project_root()
        assert root.exists()
        assert (root / "src").exists()
        assert (root / "tests").exists()

    def test_get_max_file_size_bytes(self):
        """Test file size conversion to bytes"""
        Config.MAX_FILE_SIZE_MB = 10
        assert Config.get_max_file_size_bytes() == 10 * 1024 * 1024

    def test_environment_helpers(self):
        """Test environment detection helpers"""
        Config.ENVIRONMENT = "production"
        assert Config.is_production() is True
        assert Config.is_development() is False

        Config.ENVIRONMENT = "development"
        assert Config.is_production() is False
        assert Config.is_development() is True

    def test_get_log_config(self):
        """Test logging configuration generation"""
        Config.LOG_LEVEL = "INFO"
        Config.LOG_FORMAT = "json"
        Config.LOG_FILE = None

        log_config = Config.get_log_config()

        assert log_config["version"] == 1
        assert log_config["disable_existing_loggers"] is False
        assert "json" in log_config["formatters"]
        assert "console" in log_config["handlers"]
        assert log_config["root"]["level"] == "INFO"

    def test_get_log_config_with_file(self):
        """Test logging configuration with file output"""
        Config.LOG_FILE = "/tmp/test.log"

        log_config = Config.get_log_config()

        assert "file" in log_config["handlers"]
        assert log_config["handlers"]["file"]["filename"] == "/tmp/test.log"
        assert "file" in log_config["root"]["handlers"]

    def test_api_tokens_parsing(self, monkeypatch):
        """Test API tokens are parsed correctly from comma-separated string"""
        monkeypatch.setenv("API_TOKENS", "token1,token2, token3 ")

        import importlib

        import src.config

        importlib.reload(src.config)
        from src.config import Config as ReloadedConfig

        assert ReloadedConfig.API_TOKENS == ["token1", "token2", "token3"]

    def test_allowed_file_extensions_parsing(self, monkeypatch):
        """Test file extensions are parsed correctly"""
        monkeypatch.setenv("ALLOWED_FILE_EXTENSIONS", ".py, .js, .ts ")

        import importlib

        import src.config

        importlib.reload(src.config)
        from src.config import Config as ReloadedConfig

        assert ReloadedConfig.ALLOWED_FILE_EXTENSIONS == [".py", ".js", ".ts"]


class TestConfigEdgeCases:
    """Test edge cases and error conditions"""

    def test_empty_api_tokens(self, monkeypatch):
        """Test empty API tokens string results in empty list"""
        monkeypatch.setenv("API_TOKENS", "")

        import importlib

        import src.config

        importlib.reload(src.config)
        from src.config import Config as ReloadedConfig

        assert ReloadedConfig.API_TOKENS == []

    def test_validate_multiple_errors(self, monkeypatch):
        """Test validation collects multiple errors"""
        monkeypatch.setattr(Config, "API_PORT", 70000)
        monkeypatch.setattr(Config, "ENVIRONMENT", "invalid")
        monkeypatch.setattr(Config, "API_WORKERS", 0)

        with pytest.raises(ValueError) as exc_info:
            Config.validate()

        error_message = str(exc_info.value)
        assert "Invalid API_PORT" in error_message
        assert "ENVIRONMENT must be one of" in error_message
        assert "API_WORKERS must be at least 1" in error_message
