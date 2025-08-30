# TYPO3 Development Standards

This steering document defines the development standards and best practices for TYPO3 projects in this workspace.

## TYPO3 Version Requirements
- Always use TYPO3 v13.4 or higher for all CMS features
- Check for deprecated packages before upgrades (e.g., fluid-styled-content)
- Migrate to modern alternatives when deprecated packages are found

## Asset Management
- Use Vite with `praetorius/vite-asset-collector` extension for all asset compilation
- NEVER use Grunt or Webpack for asset management
- Configure Vite properly in `vite.config.js`
- Place source assets in `Resources/Private/` directories

## Styling Framework
- Include Bootstrap for all styling needs
- Ensure all components use Bootstrap's grid system and utilities
- Follow Bootstrap conventions for responsive design
- Use Bootstrap classes consistently across templates

## Extension Architecture
- Final extensions are placed in `packages/` directory after installation
- Template extensions are developed in `install-src/xxxx_sitepackage/` (copied during installation)
- Name extensions as `${PROJECT_NAME}_extensionname`
- Follow TYPO3 sitepackage conventions:
  - `Resources/` for templates, assets, and frontend resources
  - `Configuration/` for TypoScript, TCA, and backend configuration
  - `Classes/` for PHP classes following PSR-4 autoloading

## Development Environment
- Use DDEV for local development with PHP 8.3
- Configure multi-stage Docker builds for production deployments
- Always run these commands after extension changes:
  - `ddev typo3 database:updateschema`
  - `ddev typo3 cache:flush`

## Code Quality
- Follow PSR-12 standards for PHP code
- Use camelCase for function names, snake_case for variables
- Adhere to `.editorconfig` for consistent formatting
- Add meaningful comments for complex logic