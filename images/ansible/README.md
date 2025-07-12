# Ansible DevContainer Image

Imagen Docker optimizada para desarrollo con Ansible, incluyendo herramientas de testing y linting.

## Características

- **Base**: Python 3.12 slim
- **Usuario**: `ansible` (UID 1001, no-root)
- **Directorio de trabajo**: `/workspace`

## Herramientas Incluidas

### Core
- Ansible >= 9.0.0
- Ansible Core >= 2.16.0

### Testing y Quality
- Ansible Lint
- Molecule (con Docker driver)
- Pytest + pytest-ansible
- Yamllint

### Utilidades
- Git, SSH client, curl
- Jinja2, netaddr, requests
- Cryptography

## Uso

### Build
```bash
docker build -t ansible-dev .
```

### Ejecutar
```bash
docker run -it --rm \
  -v $(pwd):/workspace \
  -v /var/run/docker.sock:/var/run/docker.sock \
  ansible-dev
```

### Con Docker Compose
```yaml
version: '3.8'
services:
  ansible:
    build: .
    volumes:
      - .:/workspace
      - /var/run/docker.sock:/var/run/docker.sock
    working_dir: /workspace
```

## Variables de Entorno

- `ANSIBLE_HOST_KEY_CHECKING=False`
- `ANSIBLE_STDOUT_CALLBACK=yaml`
- `ANSIBLE_INVENTORY_UNPARSED_WARNING=False`

## Seguridad

- Ejecuta como usuario no-root (`ansible`)
- Imagen base oficial de Python
- Dependencias fijadas por versión
- Health check incluido
