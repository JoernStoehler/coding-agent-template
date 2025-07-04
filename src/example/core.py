"""Core functionality for example package."""


def add(a: int | float, b: int | float) -> int | float:
    """Add two numbers."""
    return a + b


def divide(a: int | float, b: int | float) -> float:
    """
    Divide a by b.
    
    Raises:
        ValueError: If b is zero.
    """
    if b == 0:
        raise ValueError("Cannot divide by zero")
    return a / b