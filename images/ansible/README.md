# Ansible DevContainer Image

Optimized Docker image for Ansible development, including testing and linting tools.

## Features

- **Base**: Python 3.12 slim
- **User**: `ansible` (UID 1001, non-root)
- **Working directory**: `/workspace`

## Included Tools

### Core
- Ansible >= 9.0.0
- Ansible Core >= 2.16.0

### Testing and Quality
- Ansible Lint
- Molecule (with Docker driver)
- Pytest + pytest-ansible
- Yamllint

### Utilities
- Git, SSH client, curl
- Jinja2, netaddr, requests
- Cryptography

## Usage

### Build
```bash
docker build -t ansible-dev .
```

### Run
```bash
docker run -it --rm \
  -v $(pwd):/workspace \
  -v /var/run/docker.sock:/var/run/docker.sock \
  ansible-dev
```

### With Docker Compose
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

## Environment Variables

- `ANSIBLE_STDOUT_CALLBACK=yaml` - Output formatting
- `ANSIBLE_INVENTORY_UNPARSED_WARNING=False` - Suppress inventory warnings

## Configuration

For security reasons, sensitive Ansible configurations like `host_key_checking` are not set by default. 
Create an `ansible.cfg` file in your project to configure Ansible settings.

Example configuration:
```ini
[defaults]
host_key_checking = False  # Only for development/testing
stdout_callback = yaml
inventory = ./inventory

[ssh_connection]
pipelining = True
```

## Security

- Runs as non-root user (`ansible`)
- Official Python base image
- Version-pinned dependencies
- Health check included
