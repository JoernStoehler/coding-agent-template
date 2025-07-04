"""Tests for example.core module."""

import pytest

from example.core import add, divide


class TestAdd:
    """Test add function."""
    
    def test_add_integers(self) -> None:
        """Test adding two integers."""
        assert add(2, 3) == 5
    
    def test_add_floats(self) -> None:
        """Test adding floats."""
        assert add(2.5, 3.5) == 6.0


class TestDivide:
    """Test divide function."""
    
    def test_divide_integers(self) -> None:
        """Test dividing integers."""
        assert divide(10, 2) == 5.0
    
    def test_divide_by_zero_raises(self) -> None:
        """Test that dividing by zero raises ValueError."""
        with pytest.raises(ValueError, match="Cannot divide by zero"):
            divide(10, 0)