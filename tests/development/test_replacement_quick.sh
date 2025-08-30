#!/bin/bash

# Quick Test Runner for Replacement Function Development
# Provides fast feedback during development and debugging

set -e

# Source path resolution utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/path-utils.sh"

# Configuration - resolve paths relative to project root
INSTALL_SCRIPT="$(resolve_project_path "install-typo3.sh")"
FUNCTIONS_FILE="$(resolve_project_path "replacement_functions_only.sh")"
QUICK_TEST_DIR="quick_test"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Setup quick test
setup_quick_test() {
    rm -rf "$QUICK_TEST_DIR"
    mkdir -p "$QUICK_TEST_DIR"/{Classes,Configuration,Resources}
    
    # Extract functions if needed
    if [ ! -f "$FUNCTIONS_FILE" ]; then
        log_info "Extracting replacement functions..."
        local extract_script="$(resolve_project_path "extract_replacement_functions.sh")"
        if [ -f "$extract_script" ]; then
            "$extract_script"
        else
            # Try the development version
            local dev_extract_script="$SCRIPT_DIR/extract_replacement_functions.sh"
            if [ -f "$dev_extract_script" ]; then
                "$dev_extract_script"
            else
                log_error "Cannot find extract_replacement_functions.sh"
                exit 1
            fi
        fi
    fi
    
    # Source the replacement functions
    source "$FUNCTIONS_FILE"
    
    log_info "Quick test environment ready"
}

# Create minimal test files
create_quick_test_files() {
    # PHP file with all patterns
    cat > "$QUICK_TEST_DIR/Classes/Test.php" << 'EOF'
<?php
namespace Skom\XxxxSitepackage\Test;
class Test {
    protected $ext = 'xxxx_sitepackage';
    protected $pkg = 'xxxx-sitepackage';
    protected $cls = 'XxxxSitepackage';
    protected $vendor = 'skom';
    protected $project = 'xxxx';
}
EOF

    # YAML config
    cat > "$QUICK_TEST_DIR/Configuration/config.yaml" << 'EOF'
name: xxxx_sitepackage
vendor: skom
project: xxxx
package: xxxx-sitepackage
class: XxxxSitepackage
EOF

    # Simple text file
    echo "Project xxxx uses xxxx_sitepackage by skom" > "$QUICK_TEST_DIR/README.txt"
}

# Run quick replacement test
run_quick_test() {
    local test_name="$1"
    local project="$2"
    local sitepackage="$3"
    local kebab="$4"
    local pascal="$5"
    local vendor="$6"
    
    log_info "Running quick test: $test_name"
    
    # Create fresh test files
    create_quick_test_files
    
    # Run replacement
    if replace_sitepackage_placeholders "$QUICK_TEST_DIR" "$project" "$sitepackage" "$kebab" "$pascal" "$vendor" "false" >/dev/null 2>&1; then
        
        # Quick verification
        local errors=""
        
        # Check that placeholders were replaced
        if grep -q "xxxx_sitepackage\|xxxx-sitepackage\|XxxxSitepackage\|\\bxxxx\\b\|\\bskom\\b" "$QUICK_TEST_DIR"/*.* "$QUICK_TEST_DIR"/*/*.* 2>/dev/null; then
            errors="$errors\n  - Some placeholders not replaced"
        fi
        
        # Check that expected values exist
        if ! grep -q "$sitepackage" "$QUICK_TEST_DIR/Classes/Test.php" 2>/dev/null; then
            errors="$errors\n  - Sitepackage name not found"
        fi
        
        if ! grep -q "$kebab" "$QUICK_TEST_DIR/Classes/Test.php" 2>/dev/null; then
            errors="$errors\n  - Kebab case not found"
        fi
        
        if ! grep -q "$pascal" "$QUICK_TEST_DIR/Classes/Test.php" 2>/dev/null; then
            errors="$errors\n  - Pascal case not found"
        fi
        
        if [ -n "$vendor" ] && ! grep -q "$vendor" "$QUICK_TEST_DIR/Classes/Test.php" 2>/dev/null; then
            errors="$errors\n  - Vendor name not found"
        fi
        
        if ! grep -q "$project" "$QUICK_TEST_DIR/Classes/Test.php" 2>/dev/null; then
            errors="$errors\n  - Project name not found"
        fi
        
        if [ -z "$errors" ]; then
            log_success "$test_name"
            return 0
        else
            log_error "$test_name - Verification failed:$errors"
            return 1
        fi
    else
        log_error "$test_name - Replacement function failed"
        return 1
    fi
}

# Run predefined quick tests
run_predefined_tests() {
    local passed=0
    local total=0
    
    # Test cases: name:project:sitepackage:kebab:pascal:vendor
    local test_cases=(
        "Basic Test:myproject:myproject_sitepackage:myproject-sitepackage:MyprojectSitepackage:myvendor"
        "Hyphenated Project:my-project:my_project_sitepackage:my-project-sitepackage:MyProjectSitepackage:my-vendor"
        "Underscored Project:my_project:my_project_sitepackage:my-project-sitepackage:MyProjectSitepackage:my_vendor"
        "Numeric Project:project123:project123_sitepackage:project123-sitepackage:Project123Sitepackage:vendor123"
        "Single Word:test:test_sitepackage:test-sitepackage:TestSitepackage:vendor"
    )
    
    for test_case in "${test_cases[@]}"; do
        IFS=':' read -r name project sitepackage kebab pascal vendor <<< "$test_case"
        total=$((total + 1))
        
        if run_quick_test "$name" "$project" "$sitepackage" "$kebab" "$pascal" "$vendor"; then
            passed=$((passed + 1))
        fi
    done
    
    echo ""
    log_info "Quick test results: $passed/$total passed"
    
    if [ "$passed" -eq "$total" ]; then
        log_success "All quick tests passed!"
        return 0
    else
        log_error "Some quick tests failed"
        return 1
    fi
}

# Interactive test mode
run_interactive_test() {
    echo -e "${BLUE}=== Interactive Quick Test ===${NC}"
    echo "Enter test parameters (or press Enter for defaults):"
    
    read -p "Project name [testproject]: " project
    project=${project:-testproject}
    
    read -p "Sitepackage name [${project}_sitepackage]: " sitepackage
    sitepackage=${sitepackage:-${project}_sitepackage}
    
    read -p "Kebab case [${project}-sitepackage]: " kebab
    kebab=${kebab:-${project}-sitepackage}
    
    # Create default pascal case (capitalize first letter)
    local default_pascal="$(echo ${project:0:1} | tr '[:lower:]' '[:upper:]')${project:1}Sitepackage"
    read -p "Pascal case [$default_pascal]: " pascal
    pascal=${pascal:-$default_pascal}
    
    read -p "Vendor name [testvendor]: " vendor
    vendor=${vendor:-testvendor}
    
    echo ""
    echo "Running test with:"
    echo "  Project: $project"
    echo "  Sitepackage: $sitepackage"
    echo "  Kebab: $kebab"
    echo "  Pascal: $pascal"
    echo "  Vendor: $vendor"
    echo ""
    
    if run_quick_test "Interactive Test" "$project" "$sitepackage" "$kebab" "$pascal" "$vendor"; then
        echo ""
        log_success "Interactive test completed successfully!"
        
        # Show sample results
        echo ""
        echo "Sample results:"
        echo "PHP file content:"
        head -10 "$QUICK_TEST_DIR/Classes/Test.php" | sed 's/^/  /'
        echo ""
        echo "YAML file content:"
        head -5 "$QUICK_TEST_DIR/Configuration/config.yaml" | sed 's/^/  /'
    else
        echo ""
        log_error "Interactive test failed!"
        
        # Show what went wrong
        echo ""
        echo "Current file contents for debugging:"
        echo "PHP file:"
        head -10 "$QUICK_TEST_DIR/Classes/Test.php" | sed 's/^/  /'
    fi
}

# Show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -i, --interactive    Run interactive test mode"
    echo "  -q, --quick         Run predefined quick tests (default)"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "This script provides quick validation of the replacement function"
    echo "for development and debugging purposes."
}

# Cleanup
cleanup_quick_test() {
    rm -rf "$QUICK_TEST_DIR"
}

# Main function
main() {
    local mode="quick"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -i|--interactive)
                mode="interactive"
                shift
                ;;
            -q|--quick)
                mode="quick"
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Check prerequisites
    if [ ! -f "$INSTALL_SCRIPT" ]; then
        log_error "Install script not found: $INSTALL_SCRIPT"
        exit 1
    fi
    
    # Ensure functions file exists
    if [ ! -f "$FUNCTIONS_FILE" ]; then
        local extract_script="$(resolve_project_path "extract_replacement_functions.sh")"
        if [ -f "$extract_script" ]; then
            log_info "Extracting replacement functions..."
            "$extract_script"
        elif [ -f "$SCRIPT_DIR/extract_replacement_functions.sh" ]; then
            log_info "Extracting replacement functions..."
            "$SCRIPT_DIR/extract_replacement_functions.sh"
        else
            log_error "Cannot find functions file or extraction script"
            exit 1
        fi
    fi
    
    # Setup
    setup_quick_test
    
    # Run tests based on mode
    case $mode in
        interactive)
            run_interactive_test
            ;;
        quick)
            run_predefined_tests
            ;;
    esac
    
    local exit_code=$?
    
    # Cleanup
    cleanup_quick_test
    
    exit $exit_code
}

# Script entry point
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi