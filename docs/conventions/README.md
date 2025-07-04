# Coding Conventions for AI Agents

This document outlines coding standards optimized for AI agent collaboration. These conventions prioritize discoverability, clarity, and explicit relationships between components.

## File Naming Conventions

### General Principles
1. **Be Descriptive**: Use full, meaningful names that describe the file's purpose
   - ✅ `user_authentication_service.py`
   - ❌ `auth.py`
   
2. **Use Snake_Case**: For all file and directory names (except special files)
   - ✅ `database_connection_pool.py`
   - ❌ `DatabaseConnectionPool.py`

3. **Group by Feature**: Organize files by feature/domain, not by type
   - ✅ `features/authentication/login_handler.py`
   - ❌ `handlers/login.py`

### Specific Patterns

#### Python Files
```
# Service modules
user_authentication_service.py      # Core business logic
payment_processing_service.py       # External integrations

# Data models
user_profile_model.py              # Database/domain models
order_history_model.py             

# API endpoints
user_profile_api_endpoints.py      # REST/GraphQL endpoints
admin_dashboard_api_endpoints.py   

# Utilities
string_validation_utils.py         # Shared utilities
date_formatting_utils.py           

# Configuration
database_config.py                 # Configuration modules
security_config.py                 
```

#### Test Files
```
test_user_authentication_service.py   # Unit tests
test_payment_integration.py           # Integration tests
test_e2e_user_registration_flow.py    # End-to-end tests
```

#### Documentation Files
```
# Always use full names in docs
ARCHITECTURE_DECISIONS.md          # Not ADR.md
DATABASE_MIGRATION_GUIDE.md        # Not migrations.md
API_ENDPOINT_REFERENCE.md          # Not api.md
```

## Directory Structure

### Recommended Layout
```
project_root/
├── src/                          # Source code
│   ├── api/                      # API layer
│   │   ├── user_api_endpoints.py
│   │   └── admin_api_endpoints.py
│   ├── services/                 # Business logic
│   │   ├── user_service.py
│   │   └── notification_service.py
│   ├── models/                   # Data models
│   │   ├── user_model.py
│   │   └── order_model.py
│   ├── utils/                    # Shared utilities
│   │   ├── validation_utils.py
│   │   └── formatting_utils.py
│   └── config.py                 # Configuration
├── tests/                        # Test suite
│   ├── unit/                     # Unit tests
│   ├── integration/              # Integration tests
│   └── e2e/                      # End-to-end tests
├── docs/                         # Documentation
│   ├── architecture/             # Architecture docs
│   ├── api/                      # API documentation
│   └── guides/                   # User/dev guides
├── scripts/                      # Development scripts
├── .claude/                      # AI agent resources
│   └── commands/                 # Reusable commands
└── CLAUDE.md                     # AI agent context hub
```

## Code Organization

### Module Structure
```python
"""
Module: user_authentication_service.py
Purpose: Handles user authentication logic including login, logout, and session management

This module provides the core authentication functionality for the application,
integrating with the database and external auth providers.

Recent changes:
- 2025-01-04: Added OAuth2 support
- 2025-01-03: Improved session timeout handling

Related files:
- src/models/user_model.py - User data model
- src/api/auth_api_endpoints.py - API endpoints
- tests/test_user_authentication_service.py - Unit tests
"""

from typing import Optional, Dict, Any
import logging

from src.models.user_model import User
from src.utils.security_utils import hash_password, verify_password

logger = logging.getLogger(__name__)


class UserAuthenticationService:
    """Manages user authentication and session handling"""
    
    def __init__(self, session_timeout: int = 3600):
        """
        Initialize authentication service
        
        Args:
            session_timeout: Session timeout in seconds
        """
        self.session_timeout = session_timeout
        
    def authenticate_user(self, username: str, password: str) -> Optional[User]:
        """
        Authenticate user with username and password
        
        Args:
            username: User's username
            password: User's password (plain text)
            
        Returns:
            User object if authentication successful, None otherwise
        """
        # Implementation here
        pass
```

### Import Organization
```python
# Standard library imports
import os
import sys
from datetime import datetime
from typing import List, Optional, Dict

# Third-party imports
import requests
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

# Local imports
from src.config import Config
from src.models.user_model import User
from src.utils.validation_utils import validate_email
```

## Documentation Standards

### Docstring Format
```python
def process_payment(
    amount: float,
    currency: str,
    payment_method: Dict[str, Any],
    metadata: Optional[Dict[str, Any]] = None
) -> Dict[str, Any]:
    """
    Process a payment transaction
    
    Handles payment processing including validation, fraud checks,
    and communication with payment providers.
    
    Args:
        amount: Payment amount in the smallest currency unit
        currency: ISO 4217 currency code (e.g., 'USD', 'EUR')
        payment_method: Payment method details including:
            - type: 'card', 'bank_transfer', 'wallet'
            - details: Provider-specific payment details
        metadata: Optional transaction metadata for tracking
        
    Returns:
        Dictionary containing:
            - transaction_id: Unique transaction identifier
            - status: 'success', 'pending', or 'failed'
            - provider_response: Raw response from payment provider
            
    Raises:
        ValueError: If amount is negative or currency is invalid
        PaymentError: If payment processing fails
        
    Example:
        >>> result = process_payment(
        ...     amount=1000,  # $10.00
        ...     currency='USD',
        ...     payment_method={'type': 'card', 'details': {...}}
        ... )
        >>> print(result['transaction_id'])
    """
    pass
```

### Type Hints
Always use type hints for:
- Function parameters
- Return values
- Class attributes
- Variable declarations (when not obvious)

```python
from typing import List, Optional, Dict, Union, Callable, TypeVar

T = TypeVar('T')

def find_items(
    items: List[T],
    predicate: Callable[[T], bool],
    limit: Optional[int] = None
) -> List[T]:
    """Find items matching predicate"""
    results: List[T] = []
    for item in items:
        if predicate(item):
            results.append(item)
            if limit and len(results) >= limit:
                break
    return results
```

## Cross-Reference Standards

### File References
Always include "Related files:" section in module docstrings:
```python
"""
Related files:
- src/models/order_model.py - Order data structure
- src/services/inventory_service.py - Inventory management
- src/api/order_api_endpoints.py - REST endpoints
- tests/test_order_processing_service.py - Test coverage
"""
```

### TODO/FIXME Format
```python
# TODO(username, 2025-01-04): Implement caching for performance
# FIXME(username, 2025-01-04): Handle edge case when user has no orders
# NOTE: This algorithm is O(n²), consider optimization for large datasets
```

## Testing Conventions

### Test Naming
```python
def test_authenticate_user_with_valid_credentials():
    """Test that valid credentials return user object"""
    pass

def test_authenticate_user_with_invalid_password_returns_none():
    """Test that invalid password returns None"""
    pass

def test_process_payment_raises_error_for_negative_amount():
    """Test that negative amounts raise ValueError"""
    pass
```

### Test Organization
- One test file per module
- Group related tests in classes
- Use descriptive test names that explain the scenario

## Git Commit Conventions

### Commit Message Format
```
type(scope): brief description

Longer explanation if needed. Explain what changed and why,
not how (the code shows how).

Related: #123, #456
```

### Types
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code changes that neither fix bugs nor add features
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

### Examples
```
feat(auth): add OAuth2 authentication support

Implemented OAuth2 flow for Google and GitHub providers.
Includes token refresh and revocation handling.

Related: #234
```

## Performance Guidelines

### For AI Agents
1. **Minimize Context**: Keep files focused on single responsibilities
2. **Explicit Imports**: Always use explicit imports, no wildcards
3. **Clear Boundaries**: Define clear module interfaces
4. **Descriptive Names**: Reduce need for agents to read file contents
5. **Flat Structure**: Prefer flat over nested for discoverability

### Example of Agent-Friendly Code
```python
# File: email_notification_service.py
"""Service for sending email notifications to users"""

# Clear, explicit imports
from src.models.user_model import User
from src.models.notification_model import EmailNotification
from src.utils.email_utils import send_email
from src.config import Config

# Single, focused responsibility
class EmailNotificationService:
    """Handles sending of email notifications"""
    
    def send_welcome_email(self, user: User) -> bool:
        """Send welcome email to new user"""
        # Clear, simple implementation
        pass
```

This structure helps AI agents quickly understand:
- What the file does (from the name)
- What it depends on (from imports)
- How to use it (from docstrings)
- Where to find related code (from references)