# Command: Type Check with pyright/mypy
Purpose: Run static type checking on Python code
Category: development

## Usage
Use this command to verify type annotations and catch type-related bugs before runtime.

## Command
```bash
# Using pyright (recommended - faster and more accurate)
pyright src/

# Using mypy (traditional choice)
mypy src/

# Check specific file
pyright src/config.py
mypy src/config.py

# With stricter settings
pyright src/ --strict
mypy src/ --strict

# Ignore missing imports
pyright src/ --ignore-missing-imports
mypy src/ --ignore-missing-imports

# Generate HTML report (mypy only)
mypy src/ --html-report mypy-report

# Show error codes
mypy src/ --show-error-codes
pyright src/ --outputjson

# Check with specific Python version
mypy src/ --python-version 3.11
pyright src/ --pythonversion 3.11
```

## Example
```bash
$ pyright src/
/workspaces/project/src/services/user_service.py
  /workspaces/project/src/services/user_service.py:23:16 - error: Argument of type "str | None" cannot be assigned to parameter "user_id" of type "str" in function "get_user"
    Type "str | None" cannot be assigned to type "str"
      Type "None" cannot be assigned to type "str" (reportGeneralTypeIssues)
  
1 error, 0 warnings, 0 informations

$ mypy src/ --show-error-codes
src/services/user_service.py:23: error: Argument 1 to "get_user" has incompatible type "str | None"; expected "str"  [arg-type]
    user = get_user(user_id)  # user_id might be None
                    ^
Found 1 error in 1 file (checked 15 source files)
```

## Notes
- Pyright is generally faster and has better type inference
- Mypy has been around longer and has more configuration options
- Both tools respect `# type: ignore` comments for suppressions
- Configuration:
  - Pyright: `pyrightconfig.json` or `pyproject.toml`
  - Mypy: `mypy.ini` or `pyproject.toml`
- Common issues:
  - Missing type stubs: install `types-*` packages
  - Third-party libraries: may need `--ignore-missing-imports`
  - Gradual typing: start with less strict settings
- Use `reveal_type()` to debug type inference
- Consider using `typing.cast()` for complex type assertions