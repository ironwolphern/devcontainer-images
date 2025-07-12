# Python DevContainer Image

Imagen Docker completa para desarrollo Python con herramientas de testing, linting y análisis de seguridad.

## Características

- **Base**: Python 3.12 slim
- **Usuario**: `developer` (UID 1001, no-root)
- **Directorio de trabajo**: `/workspace`

## Herramientas Incluidas

### Core
- Python 3.12
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

### Frameworks (Opcionales)
- FastAPI, Flask, Django
- SQLAlchemy, psycopg2
- requests, httpx

### Data Science (Opcionales)
- pandas, numpy, matplotlib
- Jupyter

## Uso

### Build
```bash
docker build -t python-dev .
```

### Ejecutar
```bash
docker run -it --rm \
  -v $(pwd):/workspace \
  python-dev
```

### Con Docker Compose
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

## Variables de Entorno

- `PYTHONPATH=/workspace`
- `PYTHONDONTWRITEBYTECODE=1`
- `PYTHONUNBUFFERED=1`

## Comandos Útiles

```bash
# Formatear código
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

## Seguridad

- Ejecuta como usuario no-root (`developer`)
- Análisis de seguridad con bandit y safety
- Dependencias fijadas por versión
- Health check incluido
