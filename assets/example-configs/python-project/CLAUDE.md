# Example Python Project

A FastAPI application with SQLAlchemy, Pydantic, and pytest.

## Development Workflow

**Package manager:** `uv` (or `pip` if uv unavailable)

**Before committing:** Always run `uv run check`

## Commands

```bash
# Setup
uv sync                    # Install dependencies
uv run alembic upgrade head  # Run migrations

# Development
uv run dev                 # Start dev server (port 8000)
uv run test                # Run pytest
uv run test --cov          # Run with coverage

# Quality checks
uv run lint                # Ruff linter
uv run format              # Black + isort
uv run typecheck           # MyPy
uv run check               # All checks

# Database
uv run alembic revision --autogenerate -m "description"  # Create migration
uv run alembic upgrade head     # Apply migrations
uv run alembic downgrade -1     # Rollback one migration
```

## Project Structure

```
src/
├── api/              # FastAPI routes
│   ├── routes/       # Route handlers
│   └── deps.py       # Dependencies
├── core/             # Core configuration
│   ├── config.py     # Settings
│   └── security.py   # Auth utilities
├── db/               # Database
│   ├── models/       # SQLAlchemy models
│   └── session.py    # DB session
├── schemas/          # Pydantic schemas
├── services/         # Business logic
└── utils/            # Utilities
tests/
├── conftest.py       # Fixtures
├── api/              # API tests
└── services/         # Service tests
```

## Code Style

### Python

- Python 3.11+ features OK
- Type hints required for all functions
- Docstrings for public functions (Google style)
- Use `from __future__ import annotations` for forward refs

### Naming

- Files: `snake_case.py`
- Classes: `PascalCase`
- Functions/variables: `snake_case`
- Constants: `SCREAMING_SNAKE_CASE`

### Imports

```python
# Standard library
from datetime import datetime
from typing import Annotated

# Third party
from fastapi import Depends, HTTPException
from sqlalchemy.orm import Session

# Local
from src.core.config import settings
from src.db.session import get_db
```

## Testing

- Test files: `test_*.py` in `tests/`
- Use pytest fixtures from `conftest.py`
- Mock external services
- Minimum 80% coverage

## Anti-Patterns

- Don't use `print()` for logging - use `logging` module
- Don't use `requests` - use `httpx` (async support)
- Don't use `datetime.now()` - use `datetime.now(UTC)`
- Don't use bare `except:` - catch specific exceptions
- Don't use mutable default arguments
- Don't use global variables for state

## Environment Variables

| Variable | Description |
|----------|-------------|
| `DATABASE_URL` | Postgres connection string |
| `SECRET_KEY` | JWT secret key |
| `DEBUG` | Enable debug mode (default: false) |
| `CORS_ORIGINS` | Comma-separated allowed origins |

## Common Patterns

### Dependency Injection

```python
from typing import Annotated
from fastapi import Depends

def get_current_user(
    token: Annotated[str, Depends(oauth2_scheme)],
    db: Annotated[Session, Depends(get_db)],
) -> User:
    ...

@router.get("/me")
def read_current_user(
    current_user: Annotated[User, Depends(get_current_user)],
) -> UserResponse:
    return current_user
```

### Error Handling

```python
from fastapi import HTTPException, status

if not user:
    raise HTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        detail="User not found",
    )
```
