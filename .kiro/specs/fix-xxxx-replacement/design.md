# Design Document

## Overview

The current XXXX placeholder replacement system in the TYPO3 installation script uses a complex, error-prone one-liner that doesn't handle all placeholder patterns correctly. This design proposes a robust, maintainable replacement system that processes all placeholder types systematically with proper error handling and validation.

## Architecture

### Current Problem Analysis

The existing replacement logic has several critical issues:
- Complex one-liner that's difficult to debug and maintain
- Missing replacement patterns (standalone "xxxx", inconsistent vendor replacement)
- No file type filtering (processes binary files)
- Poor error handling and no validation
- No logging or verification of successful replacements

### Proposed Solution Architecture

Replace the current one-liner with a dedicated bash function `replace_sitepackage_placeholders()` that:
1. Processes files systematically with proper filtering
2. Handles each placeholder pattern with specific regex patterns
3. Provides comprehensive error handling and logging
4. Includes verification of successful replacements

## Components and Interfaces

### Main Replacement Function

```bash
replace_sitepackage_placeholders() {
    local source_dir="$1"           # Directory containing copied sitepackage
    local project_name="$2"         # Base project name (e.g., "test")
    local sitepackage_name="$3"     # Full sitepackage name (e.g., "test_sitepackage")
    local sitepackage_kebab="$4"    # Kebab-case version (e.g., "test-sitepackage")
    local sitepackage_pascal="$5"   # PascalCase version (e.g., "TestSitepackage")
    local vendor_name="$6"          # Vendor name (e.g., "skom")
    local verbose="${7:-false}"     # Optional verbose logging
}
```

### File Processing Strategy

#### File Type Filtering
- **Include**: Text-based files (.php, .yaml, .yml, .json, .html, .htm, .tsconfig, .typoscript, .ts, .md, .txt, .xlf, .xml, .css, .scss, .js)
- **Exclude**: Binary files, images, compiled assets, system files (.DS_Store, .git, etc.)
- **Detection Method**: Use file extension patterns and `file` command for ambiguous cases

#### Replacement Patterns
Process replacements using word-boundary regex patterns to prevent conflicts:

1. **Compound Patterns** (processed first):
   - `\bxxxx_sitepackage\b` → `$sitepackage_name`
   - `\bxxxx-sitepackage\b` → `$sitepackage_kebab`
   - `\bXxxxSitepackage\b` → `$sitepackage_pascal`

2. **Vendor Pattern**:
   - `\bskom\b` → `$vendor_name`

3. **Standalone Pattern** (processed last):
   - `\bxxxx\b` → `$project_name` (with negative lookahead to avoid already-replaced strings)

### Integration Points

#### Installation Script Integration
Replace the current complex sed command in `install-typo3.sh`:

```bash
# Current problematic code:
ddev exec sh -c 'if [ "${5+set}" = "set" ] && [ -n "$5" ]; then VENDOR_EXPR="-e \"s#skom#$5#g\""; else VENDOR_EXPR=""; fi; find "packages/$1" -type f -exec sed -i -e "s#xxxx_sitepackage#$2#g" -e "s#xxxx-sitepackage#$3#g" -e "s#XxxxSitepackage#$4#g" $VENDOR_EXPR {} +'

# New approach:
replace_sitepackage_placeholders "packages/$SITEPACKAGE_NAME" "$PROJECT_NAME" "$SITEPACKAGE_NAME" "$NEW_KEBAB" "$NEW_CAMEL" "$SITEPACKAGE_VENDOR" true
```

## Data Models

### Replacement Configuration (Bash 3.2+ Compatible)
```bash
# Use delimited strings instead of associative arrays for compatibility
REPLACEMENT_PATTERNS="xxxx_sitepackage:$sitepackage_name|xxxx-sitepackage:$sitepackage_kebab|XxxxSitepackage:$sitepackage_pascal|skom:$vendor_name|xxxx:$project_name"

# File extensions to process (space-delimited string)
PROCESSABLE_EXTENSIONS="php yaml yml json html htm tsconfig typoscript ts md txt xlf xml css scss js"
```

### Processing State Tracking (Bash 3.2+ Compatible)
```bash
# Use simple variables instead of associative arrays
files_processed=0
files_skipped=0
files_failed=0
replacements_made=0
```

## Bash Compatibility Strategy

### Cross-Platform Shell Compatibility
The replacement function must work across different bash versions and Unix systems:

#### Bash Version Support
- **Target**: Bash 3.2+ (macOS default) through Bash 5.x (modern Linux)
- **Avoid**: Bash 4+ specific features like associative arrays (`declare -A`)
- **Use**: Portable constructs available in bash 3.2

#### Data Structure Alternatives
Instead of associative arrays, use:
```bash
# Pattern: "key:value|key:value|..."
parse_replacement_patterns() {
    local patterns="$1"
    local IFS='|'
    for pattern in $patterns; do
        local key="${pattern%%:*}"
        local value="${pattern#*:}"
        # Process each key-value pair
    done
}
```

#### Shell Feature Detection
```bash
# Detect bash version for feature compatibility
if [ "${BASH_VERSION%%.*}" -ge 4 ]; then
    # Use bash 4+ features if available
    use_modern_features=true
else
    # Fall back to bash 3.2 compatible approach
    use_modern_features=false
fi
```

## Error Handling

### Input Validation (Enhanced)
- Verify source directory exists and is readable
- Validate all required parameters are provided and non-empty
- Check write permissions on target directory
- **Smart placeholder validation**: Allow identical placeholder and replacement values with warning (not error)
- **Flexible project name validation**: Accept hyphens, underscores, and alphanumeric characters
- **Vendor name flexibility**: Don't fail if vendor name matches existing placeholder (e.g., "skom")

### File Processing Errors
- Handle permission denied errors gracefully
- Skip files that cannot be read or written
- Log specific error messages with file paths
- Continue processing other files when individual files fail

### Verification and Rollback
- After processing, scan for any remaining XXXX placeholders
- Report files with unreplaced placeholders as warnings
- Provide option to abort installation if critical placeholders remain
- Log all changes for potential rollback scenarios

## Testing Strategy

### Unit Testing Approach
Create test cases for the replacement function:

1. **Basic Replacement Tests**:
   - Test each placeholder pattern individually
   - Verify correct case transformations
   - Test with various project name formats

2. **Edge Case Tests**:
   - Project names with special characters
   - Files with mixed placeholder patterns
   - Empty or malformed input files
   - Permission-restricted files

3. **Integration Tests**:
   - Full sitepackage template processing
   - Verification that generated sitepackage works in TYPO3
   - Test with different vendor names and project configurations

### Test Data Structure
```bash
# Test cases for replacement patterns
test_cases=(
    "xxxx_sitepackage|test_sitepackage"
    "xxxx-sitepackage|test-sitepackage"
    "XxxxSitepackage|TestSitepackage"
    "skom|myvendor"
    "xxxx sitepackage|test sitepackage"
)
```

### Validation Criteria
- All placeholder patterns must be replaced correctly
- No binary files should be corrupted
- File permissions and structure must be preserved
- Generated sitepackage must pass TYPO3 validation
- No performance regression in installation time