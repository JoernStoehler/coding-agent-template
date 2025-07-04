# Command: Lint and Format Code
Purpose: Run code linting and auto-formatting with ruff
Category: development

## Usage
Use this command to check code quality and automatically fix formatting issues.

## Command
```bash
# Check for linting issues without fixing
ruff check .

# Check and auto-fix safe issues
ruff check . --fix

# Format code (similar to black)
ruff format .

# Check formatting without changing files
ruff format . --check

# Run both linting and formatting
ruff check . --fix && ruff format .

# Run with specific configuration
ruff check . --config pyproject.toml

# Exclude certain directories
ruff check . --exclude "build/,dist/,*.egg-info"

# Show detailed explanations for violations
ruff check . --show-source --show-fixes
```

## Example
```bash
$ ruff check . --fix
Found 12 errors (12 fixed, 0 remaining).

$ ruff format .
15 files reformatted, 23 files left unchanged.

$ ruff check . --show-source
src/utils/helpers.py:45:5: F401 [*] `os.path` imported but unused
   |
43 | import sys
44 | from typing import Optional
45 | import os.path
   | ^^^^^^^^^^^^^^ F401
46 | 
47 | def process_file(filename: str) -> None:
   |
   = help: Remove unused import: `os.path`
```

## Notes
- Ruff is extremely fast compared to traditional linters
- It replaces multiple tools: flake8, isort, black, and more
- Configuration goes in `pyproject.toml` or `ruff.toml`
- Use `--unsafe-fixes` carefully as it may change code behavior
- Pre-commit hooks can run these automatically
- Common ruff rules:
  - F: pyflakes (undefined names, unused imports)
  - E/W: pycodestyle (style guide)
  - I: isort (import sorting)
  - N: pep8-naming (naming conventions)
  - UP: pyupgrade (Python version upgrades)