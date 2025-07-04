"""
Configuration management for Coding Agent projects

Centralizes all configuration values with environment variable support.
Provides validation and type-safe access to configuration values.

Usage:
    from config import Config

    # Access configuration values
    port = Config.API_PORT

    # Validate configuration on startup
    Config.validate()

Related files:
- .env.example - Template for environment variables
- src/telemetry.py - Uses telemetry configurations
- scripts/run-telemetry.sh - Telemetry collector setup
"""

import logging
import os
from pathlib import Path
from typing import Any, Dict, List, Optional

logger = logging.getLogger(__name__)


class Config:
    """Application configuration with environment variable support"""

    # Project metadata
    PROJECT_NAME: str = os.environ.get("PROJECT_NAME", "coding-agent")
    ENVIRONMENT: str = os.environ.get("ENVIRONMENT", "development")

    # API Configuration
    API_HOST: str = os.environ.get("API_HOST", "0.0.0.0")
    API_PORT: int = int(os.environ.get("API_PORT", "8000"))
    API_WORKERS: int = int(os.environ.get("API_WORKERS", "4"))

    # Security
    SECRET_KEY: str = os.environ.get("SECRET_KEY", "")
    API_TOKENS: List[str] = [
        token.strip() for token in os.environ.get("API_TOKENS", "").split(",") if token.strip()
    ]
    CORS_ORIGINS: List[str] = [
        origin.strip()
        for origin in os.environ.get("CORS_ORIGINS", "*").split(",")
        if origin.strip()
    ]

    # Telemetry Configuration
    TELEMETRY_ENABLED: bool = os.environ.get("TELEMETRY_ENABLED", "true").lower() == "true"
    OTEL_ENDPOINT: str = os.environ.get("OTEL_ENDPOINT", "http://localhost:4317")
    OTEL_SERVICE_NAME: str = os.environ.get("OTEL_SERVICE_NAME", PROJECT_NAME)
    OTEL_SERVICE_NAMESPACE: str = os.environ.get("OTEL_SERVICE_NAMESPACE", "coding-agent")

    # Honeycomb Configuration (for telemetry backend)
    HONEYCOMB_API_KEY: str = os.environ.get("HONEYCOMB_API_KEY", "")
    HONEYCOMB_DATASET: str = os.environ.get("HONEYCOMB_DATASET", PROJECT_NAME)
    HONEYCOMB_API_ENDPOINT: str = os.environ.get("HONEYCOMB_API_ENDPOINT", "api.honeycomb.io")

    # Agent Configuration
    MAX_CONCURRENT_AGENTS: int = int(os.environ.get("MAX_CONCURRENT_AGENTS", "5"))
    AGENT_TIMEOUT: int = int(os.environ.get("AGENT_TIMEOUT", "3600"))  # 1 hour
    AGENT_MEMORY_LIMIT_MB: int = int(os.environ.get("AGENT_MEMORY_LIMIT_MB", "2048"))

    # File System Configuration
    MAX_FILE_SIZE_MB: int = int(os.environ.get("MAX_FILE_SIZE_MB", "100"))
    ALLOWED_FILE_EXTENSIONS: List[str] = [
        ext.strip()
        for ext in os.environ.get(
            "ALLOWED_FILE_EXTENSIONS",
            ".py,.js,.ts,.jsx,.tsx,.java,.go,.rs,.cpp,.c,.h,.hpp,.cs,.rb,.php,.swift,.kt,.scala,.r,.m,.sh,.bash,.zsh,.fish,.ps1,.yml,.yaml,.json,.xml,.toml,.ini,.cfg,.conf,.md,.txt,.rst,.adoc,.tex,.html,.css,.scss,.sass,.less,.sql,.dockerfile,.makefile,.cmake,.gradle,.maven",
        ).split(",")
        if ext.strip()
    ]

    # Logging Configuration
    LOG_LEVEL: str = os.environ.get("LOG_LEVEL", "INFO").upper()
    LOG_FORMAT: str = os.environ.get("LOG_FORMAT", "json")  # json or text
    LOG_FILE: Optional[str] = os.environ.get("LOG_FILE")  # None means stdout only

    # Database Configuration (if needed)
    DATABASE_URL: Optional[str] = os.environ.get("DATABASE_URL")
    DATABASE_POOL_SIZE: int = int(os.environ.get("DATABASE_POOL_SIZE", "10"))
    DATABASE_MAX_OVERFLOW: int = int(os.environ.get("DATABASE_MAX_OVERFLOW", "20"))

    # Cache Configuration
    CACHE_TYPE: str = os.environ.get("CACHE_TYPE", "memory")  # memory, redis, memcached
    CACHE_REDIS_URL: Optional[str] = os.environ.get("CACHE_REDIS_URL")
    CACHE_DEFAULT_TIMEOUT: int = int(os.environ.get("CACHE_DEFAULT_TIMEOUT", "300"))  # 5 minutes

    # Feature Flags
    FEATURE_AUTO_SAVE: bool = os.environ.get("FEATURE_AUTO_SAVE", "true").lower() == "true"
    FEATURE_COLLABORATIVE_EDITING: bool = (
        os.environ.get("FEATURE_COLLABORATIVE_EDITING", "false").lower() == "true"
    )
    FEATURE_ADVANCED_ANALYTICS: bool = (
        os.environ.get("FEATURE_ADVANCED_ANALYTICS", "false").lower() == "true"
    )

    @classmethod
    def validate(cls) -> None:
        """Validate configuration values and environment"""
        errors = []

        # Validate required values
        if cls.TELEMETRY_ENABLED and not cls.HONEYCOMB_API_KEY:
            logger.warning("Telemetry is enabled but HONEYCOMB_API_KEY is not set")

        # Validate port
        if cls.API_PORT < 1 or cls.API_PORT > 65535:
            errors.append(f"Invalid API_PORT: {cls.API_PORT}")

        # Validate workers
        if cls.API_WORKERS < 1:
            errors.append(f"API_WORKERS must be at least 1, got {cls.API_WORKERS}")

        # Validate environment
        valid_environments = ["development", "staging", "production", "test"]
        if cls.ENVIRONMENT not in valid_environments:
            errors.append(f"ENVIRONMENT must be one of {valid_environments}, got {cls.ENVIRONMENT}")

        # Validate log level
        valid_log_levels = ["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"]
        if cls.LOG_LEVEL not in valid_log_levels:
            errors.append(f"LOG_LEVEL must be one of {valid_log_levels}, got {cls.LOG_LEVEL}")

        # Validate file size
        if cls.MAX_FILE_SIZE_MB < 1 or cls.MAX_FILE_SIZE_MB > 1000:
            errors.append(
                f"MAX_FILE_SIZE_MB must be between 1 and 1000, got {cls.MAX_FILE_SIZE_MB}"
            )

        # Validate cache type
        valid_cache_types = ["memory", "redis", "memcached"]
        if cls.CACHE_TYPE not in valid_cache_types:
            errors.append(f"CACHE_TYPE must be one of {valid_cache_types}, got {cls.CACHE_TYPE}")

        # Validate Redis URL if using Redis cache
        if cls.CACHE_TYPE == "redis" and not cls.CACHE_REDIS_URL:
            errors.append("CACHE_REDIS_URL must be set when using Redis cache")

        # Raise all validation errors at once
        if errors:
            raise ValueError(
                "Configuration validation failed:\n" + "\n".join(f"  - {e}" for e in errors)
            )

        logger.info(f"Configuration validated successfully for {cls.ENVIRONMENT} environment")

    @classmethod
    def to_dict(cls) -> Dict[str, Any]:
        """Export configuration as dictionary (excluding sensitive values)"""
        config_dict = {}
        for key in dir(cls):
            if key.isupper() and not key.startswith("_"):
                value = getattr(cls, key)
                # Redact sensitive values
                if any(
                    sensitive in key.lower() for sensitive in ["key", "secret", "password", "token"]
                ):
                    if isinstance(value, str) and value:
                        config_dict[key] = "***REDACTED***"
                    elif isinstance(value, list) and value:
                        config_dict[key] = [f"***REDACTED{i}***" for i in range(len(value))]
                    else:
                        config_dict[key] = value
                else:
                    config_dict[key] = value
        return config_dict

    @classmethod
    def get_project_root(cls) -> Path:
        """Get the project root directory"""
        # Assuming this file is in src/config.py
        return Path(__file__).parent.parent

    @classmethod
    def get_max_file_size_bytes(cls) -> int:
        """Get maximum file size in bytes"""
        return cls.MAX_FILE_SIZE_MB * 1024 * 1024

    @classmethod
    def is_production(cls) -> bool:
        """Check if running in production environment"""
        return cls.ENVIRONMENT == "production"

    @classmethod
    def is_development(cls) -> bool:
        """Check if running in development environment"""
        return cls.ENVIRONMENT == "development"

    @classmethod
    def get_log_config(cls) -> Dict[str, Any]:
        """Get logging configuration dictionary"""
        config = {
            "version": 1,
            "disable_existing_loggers": False,
            "formatters": {
                "json": {
                    "()": "pythonjsonlogger.jsonlogger.JsonFormatter",
                    "format": "%(asctime)s %(name)s %(levelname)s %(message)s",
                },
                "text": {"format": "%(asctime)s - %(name)s - %(levelname)s - %(message)s"},
            },
            "handlers": {
                "console": {
                    "class": "logging.StreamHandler",
                    "formatter": cls.LOG_FORMAT,
                    "level": cls.LOG_LEVEL,
                }
            },
            "root": {"level": cls.LOG_LEVEL, "handlers": ["console"]},
        }

        # Add file handler if log file is specified
        if cls.LOG_FILE:
            config["handlers"]["file"] = {
                "class": "logging.handlers.RotatingFileHandler",
                "formatter": cls.LOG_FORMAT,
                "filename": cls.LOG_FILE,
                "maxBytes": 10485760,  # 10MB
                "backupCount": 5,
                "level": cls.LOG_LEVEL,
            }
            config["root"]["handlers"].append("file")

        return config
