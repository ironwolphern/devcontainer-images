# Pull Request

## 📋 Description
<!-- Provide a brief description of the changes in this PR -->

## 🎯 Type of Change
<!-- Mark the type of change -->
- [ ] 🐛 Bug fix (non-breaking change which fixes an issue)
- [ ] ✨ New feature (non-breaking change which adds functionality)  
- [ ] 💥 Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] 📚 Documentation update
- [ ] 🔧 Configuration change
- [ ] 🔒 Security improvement
- [ ] ⬆️ Dependency update
- [ ] 🧹 Code cleanup/refactoring

## 🐳 Affected Images
<!-- Check all that apply -->
- [ ] Ansible
- [ ] Python
- [ ] Terraform
- [ ] Go
- [ ] DevContainer configuration
- [ ] CI/CD workflows
- [ ] Documentation

## 🧪 Testing
<!-- Describe the tests you ran to verify your changes -->
- [ ] Local build tests passed
- [ ] Image functionality tests passed
- [ ] Security scans passed
- [ ] All existing tests still pass

### Test Commands Run
```bash
# Add the commands you used to test this change
make build-all
make test-all
```

## 📸 Screenshots/Logs
<!-- If applicable, add screenshots or relevant log outputs -->

## 🔗 Related Issues
<!-- Link any related issues -->
Fixes #(issue number)
Related to #(issue number)

## 📝 Checklist
<!-- Go through all the following points -->
### Pre-submission
- [ ] I have performed a self-review of my code
- [ ] I have tested my changes locally
- [ ] I have updated documentation if needed
- [ ] My changes follow the project's coding standards
- [ ] I have checked that my changes don't break existing functionality

### Security
- [ ] I have considered security implications of my changes
- [ ] No sensitive information is exposed in the code
- [ ] Dependencies are up to date and secure

### Docker Best Practices
- [ ] Dockerfiles follow the project's best practices
- [ ] Images are optimized for size and security
- [ ] Multi-stage builds are used where appropriate
- [ ] Non-root users are used in containers

## 🔄 Versioning
<!-- For version changes -->
- [ ] This change requires a version bump
  - [ ] Patch (bug fixes)
  - [ ] Minor (new features, backwards compatible)
  - [ ] Major (breaking changes)

## 📋 Additional Notes
<!-- Add any additional information about this PR -->

---

### For Maintainers
- [ ] Code review completed
- [ ] All CI checks passed  
- [ ] Security review completed (if applicable)
- [ ] Documentation updated
- [ ] Ready to merge
