# Contributing to DevContainer Images

Thank you for your interest in contributing to this project! We welcome contributions from the community and are pleased to have you join us.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How to Contribute](#how-to-contribute)
- [Development Setup](#development-setup)
- [Testing](#testing)
- [Submitting Changes](#submitting-changes)
- [Style Guide](#style-guide)

## Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/devcontainer-images.git`
3. Add the upstream repository: `git remote add upstream https://github.com/ironwolphern/devcontainer-images.git`
4. Create a new branch for your changes: `git checkout -b feature/your-feature-name`

## How to Contribute

### Reporting Bugs

- Use the GitHub issue tracker to report bugs
- Include as much detail as possible:
  - Operating system and version
  - Docker version
  - Steps to reproduce the issue
  - Expected vs actual behavior
  - Any error messages or logs

### Suggesting Features

- Open an issue with the label "enhancement"
- Clearly describe the feature and its use case
- Explain why this feature would be beneficial

### Adding New Images

When adding a new DevContainer image:

1. Create a new directory under `images/` with a descriptive name
2. Include a `Dockerfile` with proper documentation
3. Add a `README.md` explaining the image purpose and usage
4. Include any necessary configuration files
5. Test the image thoroughly
6. Update the main README.md if needed

## Development Setup

### Prerequisites

- Docker Desktop or Docker Engine
- Git
- VS Code with Dev Containers extension (recommended)

### Building Images

```bash
# Build a specific image
cd images/python
docker build -t devcontainer-python .

# Build all images
make build-all
```

### Testing Images

```bash
# Test a specific image
make test IMAGE=python

# Test all images
make test-all
```

## Testing

- All Docker images must build successfully
- Images should be tested with their intended use cases
- Include any relevant tests in your pull request
- Ensure documentation is accurate and up-to-date

## Submitting Changes

1. Ensure your changes follow the style guide
2. Test your changes thoroughly
3. Update documentation as needed
4. Commit your changes with a clear commit message
5. Push to your fork: `git push origin feature/your-feature-name`
6. Open a pull request against the `develop` branch

### Pull Request Guidelines

- Use a clear and descriptive title
- Include a detailed description of changes
- Reference any related issues
- Ensure all checks pass
- Be responsive to feedback during review

### Commit Message Format

Use clear and descriptive commit messages:

```
type(scope): description

Longer description if needed

Fixes #issue-number
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Formatting changes
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

## Style Guide

### Dockerfile Guidelines

- Use multi-stage builds when appropriate
- Minimize the number of layers
- Use specific version tags, avoid `latest`
- Include proper labels and metadata
- Follow security best practices
- Add comments for complex operations

### Documentation

- Use clear and concise language
- Include examples where helpful
- Keep README files up to date
- Use proper Markdown formatting

## Questions?

If you have questions about contributing, feel free to:

- Open an issue with the question label
- Contact the maintainers
- Check existing documentation

Thank you for contributing!
