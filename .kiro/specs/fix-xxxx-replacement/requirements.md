# Requirements Document

## Introduction

The TYPO3 installation script has a problem with the search and replacement of XXXX placeholders in the sitepackage template. The current implementation uses a complex sed command that doesn't properly handle all the different placeholder patterns found in the template files, leading to incomplete or incorrect replacements during sitepackage generation.

## Requirements

### Requirement 1

**User Story:** As a developer running the TYPO3 installation script, I want all XXXX placeholders in the sitepackage template to be correctly replaced with my project-specific values, so that the generated sitepackage has proper naming and configuration.

#### Acceptance Criteria

1. WHEN the installation script copies the sitepackage template THEN the system SHALL replace all occurrences of "xxxx_sitepackage" with the configured sitepackage name
2. WHEN the installation script processes template files THEN the system SHALL replace all occurrences of "xxxx-sitepackage" with the kebab-case version of the sitepackage name
3. WHEN the installation script processes PHP files THEN the system SHALL replace all occurrences of "XxxxSitepackage" with the PascalCase version of the sitepackage name
4. WHEN the installation script processes configuration files THEN the system SHALL replace all occurrences of "skom" with the configured vendor name
5. WHEN the installation script processes template files THEN the system SHALL replace standalone "xxxx" occurrences with the base project name

### Requirement 2

**User Story:** As a developer, I want the replacement process to handle all file types in the sitepackage template correctly, so that no placeholder remains unreplaced regardless of file extension.

#### Acceptance Criteria

1. WHEN the replacement process runs THEN the system SHALL process all text-based files including .php, .yaml, .json, .html, .tsconfig, .typoscript, .md, and .xlf files
2. WHEN the replacement process encounters binary files THEN the system SHALL skip them to avoid corruption
3. WHEN the replacement process completes THEN the system SHALL verify that no XXXX placeholders remain in any processed files
4. IF any placeholders remain unreplaced THEN the system SHALL report an error with specific file locations

### Requirement 3

**User Story:** As a developer, I want the replacement process to be robust and handle edge cases properly, so that the installation doesn't fail due to special characters or complex file structures.

#### Acceptance Criteria

1. WHEN the replacement process encounters special characters in project names THEN the system SHALL properly escape them for sed operations
2. WHEN the replacement process runs THEN the system SHALL handle file paths with spaces or special characters correctly
3. WHEN the replacement process encounters permission issues THEN the system SHALL provide clear error messages
4. IF the replacement process fails THEN the system SHALL provide detailed logging to help diagnose the issue

### Requirement 4

**User Story:** As a developer, I want the replacement process to maintain file integrity and permissions, so that the generated sitepackage functions correctly after installation.

#### Acceptance Criteria

1. WHEN the replacement process modifies files THEN the system SHALL preserve original file permissions
2. WHEN the replacement process completes THEN the system SHALL maintain the directory structure of the template
3. WHEN the replacement process handles symbolic links THEN the system SHALL preserve link relationships correctly
4. WHEN the replacement process encounters read-only files THEN the system SHALL handle them appropriately without breaking the installation

### Requirement 5

**User Story:** As a developer running the script on different systems, I want the replacement function to be compatible with various bash versions and shell environments, so that the installation works consistently across platforms.

#### Acceptance Criteria

1. WHEN the replacement function runs THEN the system SHALL be compatible with bash version 3.2 and higher
2. WHEN the replacement function uses shell features THEN the system SHALL avoid bash 4+ specific features like associative arrays
3. WHEN the replacement function runs on macOS THEN the system SHALL work with the default bash version
4. WHEN the replacement function runs on different Unix systems THEN the system SHALL use portable shell constructs

### Requirement 6

**User Story:** As a developer, I want the parameter validation to be accurate and not overly restrictive, so that valid project configurations are accepted without false rejections.

#### Acceptance Criteria

1. WHEN the validation checks vendor names THEN the system SHALL allow the vendor name to be the same as existing placeholders if intentional
2. WHEN the validation checks project names THEN the system SHALL accept valid project name formats including hyphens and underscores
3. WHEN the validation encounters identical placeholder and replacement values THEN the system SHALL warn but not fail if this is intentional
4. WHEN the validation runs THEN the system SHALL provide clear, actionable error messages for actual validation failures