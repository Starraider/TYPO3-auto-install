# TYPO3 Installation Automation Guidelines

This document defines standards for automating TYPO3 installations and sitepackage generation.

## Script Organization
- Place all executable scripts in the project root
- Main installation logic belongs in `install-typo3.sh`
- Sitepackage creation logic belongs in `create-sitepackage.sh`
- NEVER place executable scripts in subdirectories

## Bash Script Standards
- **CRITICAL**: All bash scripts MUST be compatible with bash version 3.2 (macOS default)
- Use uppercase for global variables (e.g., `PROJECT_NAME`, `TYPO3_VERSION`)
- Add comments for each major step in the installation process
- Include error handling and validation for user inputs
- Use meaningful exit codes for different error conditions
- Avoid bash 4+ features like associative arrays, `**` globbing, and `readarray`
- Use POSIX-compliant syntax where possible for maximum compatibility

## Configuration Management
- Use `install.config` for storing installation parameters
- Support both interactive and non-interactive installation modes
- Validate configuration values before proceeding with installation
- Provide clear error messages for invalid configurations

## Template Processing
- Use placeholder replacement for customizing sitepackage templates
- Replace `xxxx` placeholders with actual project names
- Ensure all file paths and namespaces are updated correctly
- Maintain file permissions and directory structure during copying

## Installation Flow
1. Validate system requirements (PHP version, DDEV, etc.)
2. Read and validate configuration
3. Set up DDEV environment
4. Install TYPO3 via Composer
5. Generate and install sitepackage
6. Configure database and initial setup
7. Compile assets and flush caches

## Error Handling
- Check for required dependencies before starting installation
- Validate file permissions and directory access
- Provide rollback mechanisms for failed installations
- Log installation progress and errors for debugging

## Asset Compilation Integration
- Ensure Vite configuration is properly set up during installation
- Run initial asset compilation as part of the setup process
- Configure file watchers for development environments
- Set up production build processes for deployment

## TYPO3-Specific Setup
- Configure proper file permissions for TYPO3 directories
- Set up database connections and initial schema
- Install required extensions and dependencies
- Configure basic site settings and routing