# TYPO3 Sitepackage Structure Guidelines

This document defines the standard structure and organization for TYPO3 sitepackages in this project.

## Directory Structure Standards

### Core Sitepackage Structure
```
xxxx_sitepackage/
├── Classes/
│   ├── Controller/
│   ├── Domain/
│   │   ├── Model/
│   │   └── Repository/
│   └── ViewHelpers/
├── Configuration/
│   ├── RTE/
│   └── Sets/
│       └── SitePackage/
│           ├── PageTsConfig/
│           ├── config.yaml
│           ├── page.tsconfig
│           ├── settings.yaml
│           └── setup.typoscript
├── Resources/
│   ├── Private/
│   │   ├── Language/
│   │   ├── Layouts/
│   │   ├── Partials/
│   │   └── Templates/
│   └── Public/
│       ├── Css/
│       ├── Fonts/
│       ├── Icons/
│       ├── Images/
│       ├── JavaScript/
│       └── Scss/
├── composer.json
├── ext_emconf.php
├── ext_localconf.php
└── ext_tables.php
```



## File Naming Conventions
- Extension keys: `${PROJECT_NAME}_extensionname` (lowercase with underscores)
- Template files: PascalCase (e.g., `Example.html`)
- SCSS files: lowercase with hyphens (e.g., `_color-mode-toggle.scss`)
- Configuration files: Follow TYPO3 conventions (e.g., `config.yaml`, `setup.typoscript`)

## Template Organization
- Place page templates in `Resources/Private/Templates/Page/`
- Place content element templates in `Resources/Private/Templates/ContentElements/`
- Use partials for reusable template components
- Follow Fluid templating best practices

## Configuration Management
- Use TYPO3 v13 Sets for configuration organization
- Place backend layouts in `Configuration/Sets/SitePackage/PageTsConfig/BackendLayouts/`
- Keep TypoScript modular and well-commented
- Use YAML for modern configuration where possible

## Asset Compilation
- Template sitepackage structure is in `install-src/xxxx_sitepackage/` (copied to `packages/` during installation)
- Source SCSS files are located within the template at `install-src/xxxx_sitepackage/Resources/Private/Scss/`
- Compiled assets are output to the final extension's `Resources/Public/` directory in `packages/`
- Use Vite for compilation and hot reloading during development
- Follow SCSS architecture patterns (abstracts, base, components, layout)