# Project Rules for TYPO3 Auto-Install

This document enforces best practices, standardization, and project-specific knowledge for the TYPO3-auto-install project.

## 1. Tech Stack & Dependencies
- You MUST use TYPO3 v13.4 or higher for all CMS features.
- You MUST manage assets with Vite and the `praetorius/vite-asset-collector` extension; NEVER use Grunt or Webpack.
- You MUST include Bootstrap for styling and ensure all components use its grid system and utilities.
- You MUST check for deprecated TYPO3 packages (e.g., fluid-styled-content) and migrate to modern alternatives before upgrades.

## 2. Directory Structure & Architecture
- You MUST place all custom extensions in the `packages/` directory, naming them as `${PROJECT_NAME}_extensionname`.
- You MUST follow TYPO3 sitepackage conventions: Resources/ for templates, Configuration/ for TypoScript, etc.
- NEVER place executable scripts outside the root; all setup logic belongs in `install-typo3.sh` or similar.

## 3. Code Style & Naming
- You MUST adhere to the `.editorconfig` for indentation and formatting.
- For PHP code in extensions, use PSR-12 standards; functions MUST be named in camelCase, variables in snake_case.
- In Bash scripts, use uppercase for global variables and add comments for each major step.

## 4. DevOps & Best Practices
- You MUST use DDEV for local development with PHP 8.3; configure multi-stage Docker builds for production.
- You MUST run `ddev typo3 database:updateschema` and `ddev typo3 cache:flush` after any extension changes.
- For testing, if added, place files in `tests/` within extensions and use PHPUnit for TYPO3 integration tests.
