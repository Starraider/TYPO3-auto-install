---
inclusion: always
---

# Project Rules Integration

This document integrates the existing project rules from `.trae/rules/project_rules.md` with Kiro development workflows.

## Reference to Existing Rules
All development work MUST follow the rules defined in:
#[[file:.trae/rules/project_rules.md]]

## Additional Development Guidelines

### Extension Directory Clarification
- The project rules mention `packages/` directory for extensions - this is the final destination
- The `install-src/xxxx_sitepackage/` is a TEMPLATE that gets copied to `packages/` during installation
- When developing templates, work in the `install-src/` directory structure
- During installation, the template is copied to `packages/${PROJECT_NAME}_sitepackage/`
- Generated sitepackages should follow the `${PROJECT_NAME}_extensionname` naming convention

### Asset Development Workflow
1. Update sitepackage template files in `install-src/xxxx_sitepackage/` as needed
2. Use Vite for compilation and hot reloading during development
3. Ensure compiled assets are properly integrated into the sitepackage template
4. Test that template copying to `packages/` directory works correctly during installation
5. Test asset compilation as part of the installation process

### Script Development Standards
- All bash scripts MUST include error handling
- Use the existing `install.config` pattern for configuration management
- Validate all user inputs before processing
- Provide clear progress indicators during installation
- Follow the uppercase variable naming for global configuration

### TYPO3 Integration Requirements
- Always test with TYPO3 v13.4+ compatibility
- Ensure deprecated package detection works correctly
- Validate that `praetorius/vite-asset-collector` integration functions properly
- Test Bootstrap integration in generated sitepackages

### Testing and Validation
- Test installation scripts on clean DDEV environments
- Validate sitepackage generation with different project names
- Ensure asset compilation works in both development and production modes
- Verify TYPO3 database schema updates complete successfully

### Code Quality Enforcement
- Run `.editorconfig` validation on all modified files
- Ensure PSR-12 compliance for any PHP code additions
- Validate bash script syntax and error handling
- Test cross-platform compatibility (macOS, Linux)

## Development Priorities
1. Maintain compatibility with existing installation workflow
2. Ensure all changes work with DDEV + PHP 8.3 environment
3. Preserve Bootstrap integration in sitepackage templates
4. Keep Vite asset compilation functional
5. Maintain TYPO3 v13.4+ compatibility standards