---
inclusion: always
---

# TYPO3 Auto-Install Project Context

This document provides essential context about the TYPO3-auto-install project for all development tasks.

## Project Overview
This is a TYPO3 installation automation tool that creates ready-to-use TYPO3 installations with custom sitepackages. The project streamlines the setup process for TYPO3 v13.4+ projects with modern tooling.

## Key Components

### Installation Scripts
- `install-typo3.sh`: Main installation script for TYPO3 setup
- `create-sitepackage.sh`: Sitepackage generation and customization
- `install.config`: Configuration file for installation parameters

### Template Structure
- `install-src/xxxx_sitepackage/`: Complete sitepackage TEMPLATE with placeholders (gets copied to `packages/` during installation)
- Template uses `xxxx` as placeholder for project-specific naming
- Final sitepackage is installed to `packages/${PROJECT_NAME}_sitepackage/`

### Technology Stack
- **CMS**: TYPO3 v13.4+
- **Asset Compilation**: Vite with `praetorius/vite-asset-collector`
- **Styling**: Bootstrap framework
- **Development**: DDEV with PHP 8.3
- **Package Management**: Composer

### File Structure Patterns
- Extensions follow `${PROJECT_NAME}_extensionname` naming
- Template sitepackage in `install-src/xxxx_sitepackage/` (copied to `packages/` during installation)
- Final extensions installed to `packages/` directory
- Compiled assets output to extension's `Resources/Public/`
- Configuration uses TYPO3 v13 Sets architecture

## Development Workflow
1. Modify templates in `install-src/` directories (these are templates, not final extensions)
2. Update installation scripts for new features
3. Test template copying from `install-src/xxxx_sitepackage/` to `packages/` directory
4. Test with DDEV environment using generated sitepackages
5. Ensure asset compilation works with Vite in both template and final extension
6. Validate TYPO3 compatibility and best practices

## Common Tasks
- Adding new SCSS components to the sitepackage template in `install-src/xxxx_sitepackage/`
- Updating TYPO3 configuration templates
- Enhancing installation automation scripts
- Improving error handling and validation
- Adding new backend layouts or content elements

## Quality Standards
- Follow PSR-12 for PHP code
- Use Bootstrap conventions for frontend
- Maintain TYPO3 coding standards
- Ensure cross-platform compatibility for scripts
- Test installations on clean environments