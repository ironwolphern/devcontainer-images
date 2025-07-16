# Python DevContainer Image

Complete Docker image for Python development with testing, linting and security analysis tools.

## Features

- **Base**: Python 3.13 slim
- **User**: `developer` (UID 1001, non-root)
- **Working directory**: `/workspace`

## Included Tools

### Core
- Python 3.13
- pip, setuptools, wheel

### Testing
- pytest + plugins (cov, mock, xdist)
- coverage

### Code Quality
- black (formatter)
- isort (import sorting)
- flake8 (linting)
- pylint (static analysis)
- mypy (type checking)

### Security
- bandit (security linting)
- safety (dependency scanning)

### Documentation
- Sphinx + RTD theme

### Frameworks (Optional)
- FastAPI, Flask, Django
- SQLAlchemy, psycopg2
- requests, httpx

### Data Science (Optional)
- pandas, numpy, matplotlib
- Jupyter

## Usage

### Build
```bash
docker build -t python-dev .
```

### Run
```bash
docker run -it --rm \
  -v $(pwd):/workspace \
  python-dev
```

### With Docker Compose
```yaml
version: '3.8'
services:
  python:
    build: .
    volumes:
      - .:/workspace
    working_dir: /workspace
    ports:
      - "8000:8000"
```

## Environment Variables

- `PYTHONPATH=/workspace`
- `PYTHONDONTWRITEBYTECODE=1`
- `PYTHONUNBUFFERED=1`

## Useful Commands

```bash
# Format code
black .

# Linting
flake8 .
pylint src/

# Testing
pytest --cov=src tests/

# Security scan
bandit -r src/
safety check
```

## Security

- Runs as non-root user (`developer`)
- Security analysis with bandit and safety
- Version-pinned dependencies
- Health check included
