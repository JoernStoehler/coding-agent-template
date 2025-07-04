# Command: Run Tests with Coverage
Purpose: Execute the test suite with code coverage reporting
Category: testing

## Usage
Use this command to run all tests and generate a coverage report showing which lines of code are tested.

## Command
```bash
# Basic coverage run
pytest tests/ -v --cov=src --cov-report=term-missing --cov-report=html

# With specific coverage threshold
pytest tests/ -v --cov=src --cov-report=term-missing --cov-report=html --cov-fail-under=80

# Exclude certain files from coverage
pytest tests/ -v --cov=src --cov-report=term-missing --cov-report=html --cov-config=.coveragerc

# Run with parallel execution for faster results
pytest tests/ -v -n auto --cov=src --cov-report=term-missing --cov-report=html
```

## Example
```bash
$ pytest tests/ -v --cov=src --cov-report=term-missing --cov-report=html
========================= test session starts =========================
platform linux -- Python 3.11.0, pytest-7.4.0, pluggy-1.3.0
collected 42 items

tests/unit/test_config.py::test_validate_config PASSED           [  2%]
tests/unit/test_config.py::test_invalid_port PASSED              [  4%]
...

---------- coverage: platform linux, python 3.11.0 ----------
Name                      Stmts   Miss  Cover   Missing
-------------------------------------------------------
src/__init__.py               0      0   100%
src/models/user_model.py     28      0   100%
-------------------------------------------------------
TOTAL                       234     12    95%

Coverage HTML written to dir htmlcov
========================= 42 passed in 2.34s =========================
```

## Notes
- Coverage reports are generated in `htmlcov/index.html` for detailed viewing
- The `--cov-fail-under` flag will cause tests to fail if coverage is below threshold
- Use `.coveragerc` file to configure coverage settings permanently
- Missing lines are shown in the terminal output for quick reference
- Consider using `--cov-branch` for branch coverage analysis