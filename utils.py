def unwrap(value):
    """If the value is a singleton tuple, return the first element, else return as-is."""
    if isinstance(value, tuple) and len(value) == 1:
        return value[0]
    return value