"""Pytest compatibility hooks for Jac 0.34.x test collection."""


def pytest_collection_modifyitems(items):
    """Keep annexed Jac tests in a stable order across xdist workers."""
    items.sort(key=lambda item: item.nodeid)
