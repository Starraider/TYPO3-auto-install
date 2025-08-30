# TYPO3 Auto-Install

An automated TYPO3 v13.4+ installation tool that creates production-ready TYPO3 installations with custom sitepackages, modern asset compilation, and Bootstrap integration.

## Overview

This project streamlines the setup process for TYPO3 projects by automating:
- TYPO3 v13.4+ installation with DDEV
- Custom sitepackage generation with Bootstrap
- Vite-based asset compilation setup
- Database configuration and admin account creation
- Modern development environment configuration

## Features

- **Automated Installation**: Complete TYPO3 setup with a single command
- **Modern Asset Pipeline**: Vite integration with hot reloading and SCSS compilation
- **Bootstrap Integration**: Pre-configured Bootstrap framework with icons
- **Sitepackage Template**: Customizable sitepackage structure following TYPO3 v13 standards
- **Cross-Platform Compatibility**: Works on macOS and Linux with bash 3.2+
- **DDEV Integration**: Optimized for DDEV development environments

## Requirements

- **DDEV**: Latest version for local development
- **PHP**: 8.3 (managed by DDEV)
- **Bash**: 3.2+ (macOS/Linux compatible)
- **Composer**: For TYPO3 and extension management
- **Node.js**: For asset compilation (managed by DDEV)

## Quick Start

1. **Configure your project** by editing `install.config`:
   ```bash
   project_name='your_project'
   project_title='Your Project Title'
   admin_username='admin'
   admin_name='Your Name'
   admin_email='your@email.com'
   sitepackage_vendor='yourvendor'
   ```

2. **Run the installation**:
   ```bash
   ./install-typo3.sh
   ```

3. **Access your TYPO3 installation**:
   - Frontend: `https://your_project.ddev.site`
   - Backend: `https://your_project.ddev.site/typo3`

## Configuration

The `install.config` file contains all project settings:

### Project Settings
- `project_name`: Used for DDEV project name and sitepackage naming
- `project_title`: Human-readable project title
- `sitepackage_vendor`: Composer vendor name for the sitepackage

### Admin Account
- `admin_username`: Backend admin username
- `admin_name`: Full name for the admin user
- `admin_email`: Admin email address
- `admin_url`: Optional homepage URL

### Database Settings
- `server_type`: Web server type (apache/nginx)
- `db_driver`: Database driver (mysqli)
- Database connection parameters (host, port, credentials)

## Project Structure

```
typo3-auto-install/
├── install-typo3.sh              # Main installation script
├── create-sitepackage.sh          # Sitepackage generation script
├── install.config                 # Project configuration
├── install-src/                   # Template files
│   └── xxxx_sitepackage/          # Sitepackage template
│       ├── Classes/               # PHP classes
│       ├── Configuration/         # TYPO3 configuration
│       │   └── Sets/              # TYPO3 v13 Sets
│       ├── Resources/             # Templates and assets
│       │   ├── Private/           # Fluid templates, SCSS
│       │   └── Public/            # Compiled assets
│       └── composer.json          # Extension configuration
└── tests/                         # Test suite
```

## Technology Stack

### Core Technologies
- **TYPO3 v13.4+**: Latest LTS version with modern features
- **PHP 8.3**: Latest stable PHP version
- **Bootstrap 5**: Modern CSS framework with utilities
- **Vite**: Fast build tool with hot module replacement

### Key Extensions
- `praetorius/vite-asset-collector`: Vite integration for TYPO3
- `helhum/typo3-console`: Command-line tools for TYPO3
- `helhum/dotenv-connector`: Environment configuration
- `bk2k/bootstrap-package`: Bootstrap integration (optional)

### Development Tools
- **DDEV**: Local development environment
- **Vite Sidecar**: DDEV add-on for Vite integration
- **SCSS**: CSS preprocessing with Bootstrap variables
- **Bootstrap Icons**: Comprehensive icon library

## Asset Development

The project uses Vite for modern asset compilation:

### Development Workflow
1. **Source files** are located in `install-src/xxxx_sitepackage/Resources/Private/`
2. **SCSS files** use Bootstrap variables and mixins
3. **Vite compiles** assets to `Resources/Public/` in the final sitepackage
4. **Hot reloading** is available during development

### Asset Structure
```
Resources/Private/
├── Scss/
│   ├── _variables.scss           # Custom Bootstrap variables
│   ├── _components.scss          # Custom components
│   └── main.scss                 # Main SCSS entry point
├── JavaScript/
│   └── main.js                   # Main JavaScript entry point
└── Templates/                    # Fluid templates
```

## Sitepackage Features

The generated sitepackage includes:

### TYPO3 v13 Compatibility
- **Sets-based configuration**: Modern configuration architecture
- **Content Security Policy**: Security headers configuration
- **Performance optimizations**: Caching and compression settings

### Frontend Features
- **Responsive design**: Bootstrap grid system and utilities
- **Modern CSS**: SCSS compilation with custom variables
- **Icon system**: Bootstrap Icons integration
- **JavaScript modules**: ES6+ support with Vite

### Backend Features
- **Backend layouts**: Flexible page layouts
- **Content elements**: Custom content types
- **RTE configuration**: Rich text editor setup
- **Page TSconfig**: Backend customizations

## Development Commands

### TYPO3 Management
```bash
# Update database schema
ddev typo3 database:updateschema

# Flush all caches
ddev typo3 cache:flush

# Create admin user
ddev typo3 backend:createadmin username password

# Install extensions
ddev composer req vendor/extension-name
```

### Asset Development
```bash
# Start development server with hot reloading
ddev npm run dev

# Build assets for production
ddev npm run build

# Watch for changes
ddev npm run watch
```

### DDEV Management
```bash
# Start project
ddev start

# Stop project
ddev stop

# Restart project
ddev restart

# View project info
ddev describe
```

## Testing

The project includes a comprehensive test suite:

```bash
# Run all tests
./tests/run-tests.sh

# Generate test report
./tests/generate-report.sh

# Run specific test category
./tests/run-tests.sh unit
./tests/run-tests.sh integration
```

## Troubleshooting

### Common Issues

**Installation fails with bash errors**:
- Ensure you're using bash 3.2+ (check with `bash --version`)
- The scripts are compatible with macOS default bash

**DDEV project conflicts**:
- Delete existing project: `ddev delete project_name --omit-snapshot`
- Check for port conflicts: `ddev describe`

**Asset compilation issues**:
- Restart Vite sidecar: `ddev restart`
- Clear node modules: `ddev npm install`
- Check Vite configuration in `vite.config.js`

**TYPO3 backend access issues**:
- Verify admin account creation in installation logs
- Reset admin password: `ddev typo3 backend:createadmin username newpassword`

### Performance Optimization

**Development Environment**:
- Use `ddev npm run dev` for hot reloading
- Enable TYPO3 development context
- Disable caching during development

**Production Deployment**:
- Run `ddev npm run build` for optimized assets
- Enable TYPO3 production context
- Configure proper caching strategies

## Contributing

1. Fork the repository
2. Create a feature branch
3. Follow the coding standards defined in `.editorconfig`
4. Add tests for new functionality
5. Submit a pull request

## Removing a Test Project

To completely remove a DDEV test project:

```bash
ddev delete project_name --omit-snapshot
```

This command removes the DDEV configuration and containers without creating a database snapshot, which is ideal for test projects.

## License

This project is open source. Please check the license file for details.

## Support

For issues and questions:
- Check the troubleshooting section above
- Review the test suite for examples
- Create an issue in the project repository