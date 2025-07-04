# Coding Conventions

Standards and patterns for code written by agents and humans in this infrastructure.

## General Principles

1. **Clarity over cleverness** - Write code that's easy to understand
2. **Explicit over implicit** - Be clear about what code does
3. **Consistent patterns** - Follow existing code style
4. **Descriptive names** - Variables and functions should explain themselves

## Git Conventions

### Branch Names
```
feat/user-authentication    # New features
fix/login-error            # Bug fixes
chore/update-deps          # Maintenance
docs/api-guide             # Documentation
test/auth-coverage         # Test improvements
```

### Commit Messages

Follow conventional commits format:
```
type(scope): brief description

Longer explanation if needed. Focus on why, not what.

Fixes #123
```

Types:
- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation only
- `style` - Code style (formatting, missing semicolons, etc)
- `refactor` - Code change that neither fixes bug nor adds feature
- `test` - Adding missing tests
- `chore` - Maintenance, dependency updates

Examples:
```bash
git commit -m "feat(auth): add OAuth2 login support"
git commit -m "fix(api): handle null user gracefully"
git commit -m "docs: update setup instructions"
```

## Python Conventions

### Style Guide
- Follow PEP 8
- Use type hints for function signatures
- Maximum line length: 88 characters (Black default)

### Imports
```python
# Standard library
import os
import sys
from datetime import datetime

# Third-party
import requests
from fastapi import FastAPI

# Local
from .models import User
from .utils import validate_email
```

### Docstrings
Use Google style:
```python
def calculate_total(items: List[Item], tax_rate: float = 0.08) -> float:
    """Calculate total price including tax.
    
    Args:
        items: List of items to price
        tax_rate: Tax rate as decimal (default: 0.08)
        
    Returns:
        Total price including tax
        
    Raises:
        ValueError: If tax_rate is negative
    """
    if tax_rate < 0:
        raise ValueError("Tax rate cannot be negative")
    
    subtotal = sum(item.price for item in items)
    return subtotal * (1 + tax_rate)
```

### File Organization
```python
"""Module description."""

# Imports
import ...

# Constants
DEFAULT_TIMEOUT = 30

# Classes
class UserService:
    """Handle user operations."""
    
# Functions
def helper_function():
    """Do something helpful."""
    
# Script execution
if __name__ == "__main__":
    main()
```

## Shell Script Conventions

### Structure
```bash
#!/bin/bash
# Script description
# Usage: ./script.sh [options] <arguments>

set -e  # Exit on error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/tmp/script.log"

# Functions
usage() {
    echo "Usage: $0 [options] <arguments>"
    exit 1
}

# Main logic
main() {
    echo "Starting process..."
    # Implementation
}

# Run
main "$@"
```

### Error Handling
```bash
# Check command success
if ! command -v docker &> /dev/null; then
    echo "Error: Docker not installed"
    exit 1
fi

# Trap errors
trap 'echo "Error on line $LINENO"' ERR
```

## File Naming

### Python Files
```
user_authentication_service.py   # Services
payment_processor.py            # Business logic
test_user_auth.py              # Tests
```

### Shell Scripts
```
setup-agent.sh                 # Kebab-case for scripts
check-system.sh
run-tests.sh
```

### Documentation
```
README.md                      # All caps
CONTRIBUTING.md
troubleshooting.md            # Lowercase for guides
```

## Testing Conventions

### Test Structure
```python
def test_function_with_valid_input():
    """Test normal operation."""
    result = function(valid_input)
    assert result == expected

def test_function_with_invalid_input_raises_error():
    """Test error handling."""
    with pytest.raises(ValueError):
        function(invalid_input)
```

### Test Organization
- Mirror source structure: `src/auth.py` → `tests/test_auth.py`
- Group related tests in classes
- Use descriptive test names
- Include edge cases

## Documentation

### Code Comments
```python
# Explain why, not what
# Bad: Increment counter
counter += 1

# Good: Track retry attempts for rate limiting
counter += 1
```

### README Structure
1. Brief description
2. Quick start
3. Detailed usage
4. Configuration
5. Troubleshooting

## Project Structure

```
project/
├── src/               # Source code
│   ├── models/       # Data models
│   ├── services/     # Business logic
│   └── utils/        # Helpers
├── tests/            # Test files
├── scripts/          # Utility scripts
├── docs/             # Documentation
└── requirements.txt  # Dependencies
```

## Agent-Specific Conventions

### Status Communication
- Send updates at major milestones
- Report blockers immediately
- Include context in messages

### Working Practices
- Commit frequently (every 30-60 minutes)
- Test before marking complete
- Update docs for new features
- Clean up temp files

### Resource Usage
- Use allocated ports only
- Keep logs under 100MB
- Clean tmp/ directory regularly
- Close unused files

## Code Review Checklist

- [ ] Follows style guide
- [ ] Has appropriate tests
- [ ] Includes documentation
- [ ] No hardcoded secrets
- [ ] Error handling present
- [ ] Performance acceptable
- [ ] Security considered

## Tools and Formatting

### Python
```bash
# Format
black .
isort .

# Lint
flake8
mypy
```

### JavaScript
```bash
# Format
prettier --write .

# Lint
eslint .
```

## Anti-Patterns to Avoid

1. **Magic numbers** - Use named constants
2. **Deep nesting** - Refactor complex logic
3. **Huge functions** - Break down into smaller pieces
4. **Unclear variable names** - Be descriptive
5. **Ignored errors** - Handle or explicitly document why ignored
6. **Commented-out code** - Delete it, git remembers
7. **Copy-paste code** - Extract common functionality

Remember: Code is read more often than written. Optimize for readability.