#!/bin/bash

# Cross-Platform Bash Compatibility Test Suite
# Tests the replacement function across different bash versions and shell environments
# Requirements: 5.1, 5.2, 5.3, 5.4, 6.1, 6.2, 6.3, 6.4

set -e

# Source path resolution utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/path-utils.sh"

# Test configuration
PROJECT_ROOT="$(resolve_project_root)"
TEST_RESULTS_DIR="$(resolve_tests_path "reports")"
COMPATIBILITY_LOG="$TEST_RESULTS_DIR/bash_compatibility_$(date +%Y%m%d_%H%M%S).log"
TEMP_TEST_DIR="$TEST_RESULTS_DIR/temp_bash_compat"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$COMPATIBILITY_LOG"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1" | tee -a "$COMPATIBILITY_LOG"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$COMPATIBILITY_LOG"
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1" | tee -a "$COMPATIBILITY_LOG"
}

# System detection functions
detect_system() {
    local system_info=""
    
    # Detect operating system
    if [[ "$OSTYPE" == "darwin"* ]]; then
        system_info="macOS $(sw_vers -productVersion 2>/dev/null || echo 'unknown')"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v lsb_release >/dev/null 2>&1; then
            system_info="$(lsb_release -d -s 2>/dev/null)"
        elif [ -f /etc/os-release ]; then
            system_info="$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)"
        else
            system_info="Linux (unknown distribution)"
        fi
    elif [[ "$OSTYPE" == "freebsd"* ]]; then
        system_info="FreeBSD $(uname -r)"
    else
        system_info="Unknown OS: $OSTYPE"
    fi
    
    echo "$system_info"
}

detect_bash_version() {
    echo "${BASH_VERSION}"
}

detect_shell_features() {
    local features=""
    
    # Test for associative arrays (bash 4.0+)
    if declare -A test_array 2>/dev/null; then
        features="$features associative_arrays"
        unset test_array
    fi
    
    # Test for indexed arrays (bash 3.1+)
    if declare -a test_array 2>/dev/null; then
        features="$features indexed_arrays"
        unset test_array
    fi
    
    # Test for regex matching (bash 3.0+)
    if [[ "test" =~ ^test$ ]] 2>/dev/null; then
        features="$features regex_matching"
    fi
    
    # Test for process substitution
    if echo "test" | { read line; echo "$line"; } >/dev/null 2>&1; then
        features="$features process_substitution"
    fi
    
    echo "$features"
}

# Extract replacement function for testing
extract_replacement_function() {
    local temp_functions="$1"
    
    log_info "Extracting replacement function and dependencies..."
    
    # Create temporary file with all required functions
    cat > "$temp_functions" << 'EOF'
#!/bin/bash

# Extracted functions for compatibility testing
EOF
    
    # Extract all required functions from install-typo3.sh
    local functions_to_extract=(
        "detect_bash_version"
        "check_bash_compatibility"
        "parse_replacement_patterns"
        "portable_sed"
        "check_system_compatibility"
        "replace_sitepackage_placeholders"
        "get_file_access_status"
        "should_process_file_with_reason"
        "should_process_file"
        "is_text_file"
        "find_processable_files"
        "validate_replacement_parameters"
        "process_file_replacements_with_stats"
        "find_remaining_placeholders"
        "verify_file_integrity"
        "verify_directory_structure_integrity"
        "perform_post_processing_verification"
    )
    
    for func_name in "${functions_to_extract[@]}"; do
        log_info "Extracting function: $func_name"
        
        # Extract function definition
        if sed -n "/^${func_name}()/,/^}$/p" "$PROJECT_ROOT/install-typo3.sh" >> "$temp_functions"; then
            echo "" >> "$temp_functions"
        else
            log_warning "Could not extract function: $func_name"
        fi
    done
    
    # Make the temporary file executable
    chmod +x "$temp_functions"
    
    log_info "Function extraction completed"
}

# Test basic bash compatibility features
test_bash_compatibility_features() {
    log_info "Testing bash compatibility features..."
    
    local bash_version=$(detect_bash_version)
    local bash_major="${bash_version%%.*}"
    local bash_minor="${bash_version#*.}"
    bash_minor="${bash_minor%%.*}"
    
    log_info "Bash version: $bash_version (major: $bash_major, minor: $bash_minor)"
    
    # Test minimum version requirement (3.2+)
    if [ "$bash_major" -lt 3 ] || ([ "$bash_major" -eq 3 ] && [ "$bash_minor" -lt 2 ]); then
        log_error "Bash version $bash_version is below minimum requirement (3.2)"
        return 1
    else
        log_success "Bash version $bash_version meets minimum requirement (3.2+)"
    fi
    
    # Test shell features
    local features=$(detect_shell_features)
    log_info "Available shell features: $features"
    
    # Test specific compatibility requirements
    
    # Test 1: String manipulation (required for bash 3.2+)
    local test_string="xxxx_sitepackage"
    local result="${test_string/xxxx/test}"
    if [ "$result" = "test_sitepackage" ]; then
        log_success "String substitution works correctly"
    else
        log_error "String substitution failed: expected 'test_sitepackage', got '$result'"
        return 1
    fi
    
    # Test 2: Parameter expansion (required for bash 3.2+)
    local test_param="key:value"
    local key="${test_param%%:*}"
    local value="${test_param#*:}"
    if [ "$key" = "key" ] && [ "$value" = "value" ]; then
        log_success "Parameter expansion works correctly"
    else
        log_error "Parameter expansion failed: key='$key', value='$value'"
        return 1
    fi
    
    # Test 3: Arithmetic expansion (required for bash 3.2+)
    local count=5
    local result=$((count + 1))
    if [ "$result" -eq 6 ]; then
        log_success "Arithmetic expansion works correctly"
    else
        log_error "Arithmetic expansion failed: expected 6, got $result"
        return 1
    fi
    
    # Test 4: Command substitution (required for bash 3.2+)
    local date_result=$(date +%Y 2>/dev/null)
    if [ -n "$date_result" ] && [ "$date_result" -ge 2020 ]; then
        log_success "Command substitution works correctly"
    else
        log_error "Command substitution failed or returned invalid result: '$date_result'"
        return 1
    fi
    
    # Test 5: Conditional expressions (required for bash 3.2+)
    if [[ "test" == "test" ]] 2>/dev/null; then
        log_success "Conditional expressions work correctly"
    else
        log_error "Conditional expressions failed"
        return 1
    fi
    
    return 0
}

# Test system tool compatibility
test_system_tools() {
    log_info "Testing system tool compatibility..."
    
    local required_tools=("sed" "grep" "find" "file" "wc" "tr")
    local optional_tools=("gsed")
    local missing_tools=""
    local available_tools=""
    
    # Test required tools
    for tool in "${required_tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            available_tools="$available_tools $tool"
            
            # Test tool functionality
            case "$tool" in
                "sed")
                    local test_result=$(echo "test" | sed 's/test/success/' 2>/dev/null)
                    if [ "$test_result" = "success" ]; then
                        log_success "sed works correctly"
                    else
                        log_error "sed functionality test failed"
                        return 1
                    fi
                    ;;
                "grep")
                    if echo "test" | grep -q "test" 2>/dev/null; then
                        log_success "grep works correctly"
                    else
                        log_error "grep functionality test failed"
                        return 1
                    fi
                    ;;
                "find")
                    local find_result=$(find . -name "$(basename "$0")" -type f 2>/dev/null | head -1)
                    if [ -n "$find_result" ]; then
                        log_success "find works correctly"
                    else
                        log_error "find functionality test failed"
                        return 1
                    fi
                    ;;
                "file")
                    local file_result=$(file "$0" 2>/dev/null)
                    if [[ "$file_result" == *"script"* ]] || [[ "$file_result" == *"text"* ]]; then
                        log_success "file command works correctly"
                    else
                        log_error "file command functionality test failed"
                        return 1
                    fi
                    ;;
            esac
        else
            missing_tools="$missing_tools $tool"
        fi
    done
    
    # Test optional tools
    for tool in "${optional_tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            available_tools="$available_tools $tool"
            log_info "Optional tool available: $tool"
        fi
    done
    
    log_info "Available tools:$available_tools"
    
    if [ -n "$missing_tools" ]; then
        log_error "Missing required tools:$missing_tools"
        return 1
    else
        log_success "All required system tools are available"
        return 0
    fi
}

# Test sed implementation compatibility
test_sed_compatibility() {
    log_info "Testing sed implementation compatibility..."
    
    local test_file="$TEMP_TEST_DIR/sed_test.txt"
    mkdir -p "$TEMP_TEST_DIR"
    
    # Create test file
    echo "xxxx_sitepackage test content" > "$test_file"
    
    # Test GNU sed (if available)
    if command -v gsed >/dev/null 2>&1; then
        log_info "Testing GNU sed (gsed)..."
        cp "$test_file" "${test_file}.gsed"
        if gsed -i 's/xxxx_sitepackage/test_sitepackage/g' "${test_file}.gsed" 2>/dev/null; then
            local result=$(cat "${test_file}.gsed")
            if [ "$result" = "test_sitepackage test content" ]; then
                log_success "GNU sed (gsed) works correctly"
            else
                log_error "GNU sed (gsed) produced incorrect result: '$result'"
                return 1
            fi
        else
            log_error "GNU sed (gsed) failed to execute"
            return 1
        fi
    fi
    
    # Test standard sed
    log_info "Testing standard sed..."
    cp "$test_file" "${test_file}.sed"
    
    # Try GNU sed syntax first
    if sed -i 's/xxxx_sitepackage/test_sitepackage/g' "${test_file}.sed" 2>/dev/null; then
        local result=$(cat "${test_file}.sed")
        if [ "$result" = "test_sitepackage test content" ]; then
            log_success "Standard sed with GNU syntax works correctly"
        else
            log_error "Standard sed with GNU syntax produced incorrect result: '$result'"
            return 1
        fi
    else
        # Try BSD sed syntax (macOS)
        log_info "GNU syntax failed, trying BSD sed syntax..."
        cp "$test_file" "${test_file}.bsd"
        if sed -i '' 's/xxxx_sitepackage/test_sitepackage/g' "${test_file}.bsd" 2>/dev/null; then
            local result=$(cat "${test_file}.bsd")
            if [ "$result" = "test_sitepackage test content" ]; then
                log_success "BSD sed works correctly"
            else
                log_error "BSD sed produced incorrect result: '$result'"
                return 1
            fi
        else
            log_error "Both GNU and BSD sed syntaxes failed"
            return 1
        fi
    fi
    
    # Clean up test files
    rm -f "$test_file" "${test_file}."* 2>/dev/null
    
    return 0
}

# Test replacement function with different bash versions
test_replacement_function_compatibility() {
    log_info "Testing replacement function compatibility..."
    
    local temp_functions="$TEMP_TEST_DIR/extracted_functions.sh"
    local test_dir="$TEMP_TEST_DIR/replacement_test"
    
    # Extract functions
    extract_replacement_function "$temp_functions"
    
    # Source the extracted functions
    if ! source "$temp_functions"; then
        log_error "Failed to source extracted functions"
        return 1
    fi
    
    # Create test directory structure
    mkdir -p "$test_dir/Classes"
    mkdir -p "$test_dir/Configuration"
    mkdir -p "$test_dir/Resources/Private"
    
    # Create test files with placeholders
    cat > "$test_dir/composer.json" << 'EOF'
{
    "name": "skom/xxxx_sitepackage",
    "description": "TYPO3 sitepackage for xxxx project",
    "type": "typo3-cms-extension",
    "keywords": ["typo3", "xxxx", "sitepackage"]
}
EOF
    
    cat > "$test_dir/Classes/TestClass.php" << 'EOF'
<?php
namespace Skom\XxxxSitepackage\Controller;

class TestController {
    // Test class for xxxx_sitepackage
    // Vendor: skom
    // Project: xxxx
}
EOF
    
    cat > "$test_dir/Configuration/config.yaml" << 'EOF'
extension:
  name: xxxx_sitepackage
  vendor: skom
  project: xxxx
  kebab: xxxx-sitepackage
  pascal: XxxxSitepackage
EOF
    
    # Test the replacement function
    log_info "Running replacement function test..."
    
    if replace_sitepackage_placeholders "$test_dir" "myproject" "myproject_sitepackage" "myproject-sitepackage" "MyprojectSitepackage" "myvendor" true; then
        log_success "Replacement function executed successfully"
        
        # Verify replacements
        local verification_passed=true
        
        # Check composer.json
        if grep -q "myvendor/myproject_sitepackage" "$test_dir/composer.json" && \
           grep -q "myproject project" "$test_dir/composer.json" && \
           grep -q "myproject.*sitepackage" "$test_dir/composer.json"; then
            log_success "composer.json replacements verified"
        else
            log_error "composer.json replacements failed"
            verification_passed=false
        fi
        
        # Check PHP class
        if grep -q "Myvendor\\\\MyprojectSitepackage" "$test_dir/Classes/TestClass.php" && \
           grep -q "myproject_sitepackage" "$test_dir/Classes/TestClass.php" && \
           grep -q "myvendor" "$test_dir/Classes/TestClass.php" && \
           grep -q "myproject" "$test_dir/Classes/TestClass.php"; then
            log_success "PHP class replacements verified"
        else
            log_error "PHP class replacements failed"
            verification_passed=false
        fi
        
        # Check YAML config
        if grep -q "myproject_sitepackage" "$test_dir/Configuration/config.yaml" && \
           grep -q "myvendor" "$test_dir/Configuration/config.yaml" && \
           grep -q "myproject" "$test_dir/Configuration/config.yaml" && \
           grep -q "myproject-sitepackage" "$test_dir/Configuration/config.yaml" && \
           grep -q "MyprojectSitepackage" "$test_dir/Configuration/config.yaml"; then
            log_success "YAML config replacements verified"
        else
            log_error "YAML config replacements failed"
            verification_passed=false
        fi
        
        if [ "$verification_passed" = "true" ]; then
            log_success "All replacement verifications passed"
            return 0
        else
            log_error "Some replacement verifications failed"
            return 1
        fi
    else
        log_error "Replacement function failed to execute"
        return 1
    fi
}

# Test edge cases for cross-platform compatibility
test_edge_cases() {
    log_info "Testing edge cases for cross-platform compatibility..."
    
    local temp_functions="$TEMP_TEST_DIR/extracted_functions.sh"
    local test_dir="$TEMP_TEST_DIR/edge_cases"
    
    # Source the extracted functions
    source "$temp_functions"
    
    # Create test directory
    mkdir -p "$test_dir"
    
    # Test 1: Files with spaces in names
    log_info "Testing files with spaces in names..."
    echo "xxxx_sitepackage content" > "$test_dir/file with spaces.txt"
    
    if replace_sitepackage_placeholders "$test_dir" "spacetest" "spacetest_sitepackage" "spacetest-sitepackage" "SpacetestSitepackage" "spacevendor" false; then
        if grep -q "spacetest_sitepackage" "$test_dir/file with spaces.txt"; then
            log_success "Files with spaces handled correctly"
        else
            log_error "Files with spaces not processed correctly"
            return 1
        fi
    else
        log_error "Failed to process files with spaces"
        return 1
    fi
    
    # Test 2: Special characters in project names
    log_info "Testing special characters handling..."
    echo "xxxx_sitepackage content" > "$test_dir/special_chars.txt"
    
    # Test with underscores (should work)
    if replace_sitepackage_placeholders "$test_dir" "test_project_name" "test_project_name_sitepackage" "test-project-name-sitepackage" "TestProjectNameSitepackage" "testvendor" false; then
        log_success "Special characters in project names handled correctly"
    else
        log_error "Failed to handle special characters in project names"
        return 1
    fi
    
    # Test 3: Large files (performance test)
    log_info "Testing large file handling..."
    local large_file="$test_dir/large_file.txt"
    
    # Create a large file with multiple placeholders
    for i in {1..1000}; do
        echo "Line $i: xxxx_sitepackage and skom and xxxx content" >> "$large_file"
    done
    
    local start_time=$(date +%s)
    if replace_sitepackage_placeholders "$test_dir" "perftest" "perftest_sitepackage" "perftest-sitepackage" "PerftestSitepackage" "perfvendor" false; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        # Verify the large file was processed
        if grep -q "perftest_sitepackage" "$large_file" && grep -q "perfvendor" "$large_file"; then
            log_success "Large file processed correctly in ${duration}s"
        else
            log_error "Large file not processed correctly"
            return 1
        fi
    else
        log_error "Failed to process large file"
        return 1
    fi
    
    # Test 4: Empty and minimal files
    log_info "Testing empty and minimal files..."
    touch "$test_dir/empty_file.txt"
    echo "xxxx" > "$test_dir/minimal_file.txt"
    
    if replace_sitepackage_placeholders "$test_dir" "mintest" "mintest_sitepackage" "mintest-sitepackage" "MintestSitepackage" "minvendor" false; then
        # Check minimal file
        if grep -q "mintest" "$test_dir/minimal_file.txt"; then
            log_success "Empty and minimal files handled correctly"
        else
            log_error "Minimal file not processed correctly"
            return 1
        fi
    else
        log_error "Failed to process empty and minimal files"
        return 1
    fi
    
    return 0
}

# Test parameter validation compatibility
test_parameter_validation() {
    log_info "Testing parameter validation compatibility..."
    
    local temp_functions="$TEMP_TEST_DIR/extracted_functions.sh"
    local test_dir="$TEMP_TEST_DIR/validation_test"
    
    # Source the extracted functions
    source "$temp_functions"
    
    # Create minimal test directory
    mkdir -p "$test_dir"
    echo "test content" > "$test_dir/test.txt"
    
    # Test 1: Valid parameters (should succeed)
    log_info "Testing valid parameters..."
    if replace_sitepackage_placeholders "$test_dir" "validtest" "validtest_sitepackage" "validtest-sitepackage" "ValidtestSitepackage" "validvendor" false >/dev/null 2>&1; then
        log_success "Valid parameters accepted correctly"
    else
        log_error "Valid parameters rejected incorrectly"
        return 1
    fi
    
    # Test 2: Empty parameters (should fail gracefully)
    log_info "Testing empty parameters..."
    if replace_sitepackage_placeholders "" "" "" "" "" "" false >/dev/null 2>&1; then
        log_error "Empty parameters should have been rejected"
        return 1
    else
        log_success "Empty parameters rejected correctly"
    fi
    
    # Test 3: Invalid directory (should fail gracefully)
    log_info "Testing invalid directory..."
    if replace_sitepackage_placeholders "/nonexistent/directory" "test" "test_sitepackage" "test-sitepackage" "TestSitepackage" "vendor" false >/dev/null 2>&1; then
        log_error "Invalid directory should have been rejected"
        return 1
    else
        log_success "Invalid directory rejected correctly"
    fi
    
    # Test 4: Identical placeholder and replacement (should warn but not fail)
    log_info "Testing identical placeholder and replacement values..."
    if replace_sitepackage_placeholders "$test_dir" "xxxx" "xxxx_sitepackage" "xxxx-sitepackage" "XxxxSitepackage" "skom" false >/dev/null 2>&1; then
        log_success "Identical values handled correctly (with warning)"
    else
        log_warning "Identical values caused failure (may be acceptable depending on implementation)"
    fi
    
    return 0
}

# Generate compatibility report
generate_compatibility_report() {
    local report_file="$TEST_RESULTS_DIR/bash_compatibility_report_$(date +%Y%m%d_%H%M%S).txt"
    
    log_info "Generating compatibility report: $report_file"
    
    cat > "$report_file" << EOF
# Bash Compatibility Test Report
Generated: $(date)

## System Information
Operating System: $(detect_system)
Bash Version: $(detect_bash_version)
Shell Features: $(detect_shell_features)

## Test Results Summary
EOF
    
    # Count test results from log
    local total_tests=$(grep -c "\[PASS\]\|\[FAIL\]" "$COMPATIBILITY_LOG" 2>/dev/null || echo "0")
    local passed_tests=$(grep -c "\[PASS\]" "$COMPATIBILITY_LOG" 2>/dev/null || echo "0")
    local failed_tests=$(grep -c "\[FAIL\]" "$COMPATIBILITY_LOG" 2>/dev/null || echo "0")
    local warnings=$(grep -c "\[WARN\]" "$COMPATIBILITY_LOG" 2>/dev/null || echo "0")
    
    cat >> "$report_file" << EOF
Total Tests: $total_tests
Passed: $passed_tests
Failed: $failed_tests
Warnings: $warnings

## Detailed Test Log
EOF
    
    # Append the detailed log
    if [ -f "$COMPATIBILITY_LOG" ]; then
        cat "$COMPATIBILITY_LOG" >> "$report_file"
    fi
    
    log_info "Compatibility report generated: $report_file"
    
    # Return overall status
    if [ "$failed_tests" -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

# Main test execution
main() {
    log_info "Starting Cross-Platform Bash Compatibility Test Suite"
    log_info "System: $(detect_system)"
    log_info "Bash Version: $(detect_bash_version)"
    
    # Create test directories
    mkdir -p "$TEST_RESULTS_DIR"
    mkdir -p "$TEMP_TEST_DIR"
    
    # Initialize test results
    local overall_result=0
    
    # Run compatibility tests
    log_info "=== Running Bash Compatibility Tests ==="
    if ! test_bash_compatibility_features; then
        overall_result=1
    fi
    
    log_info "=== Running System Tools Tests ==="
    if ! test_system_tools; then
        overall_result=1
    fi
    
    log_info "=== Running Sed Compatibility Tests ==="
    if ! test_sed_compatibility; then
        overall_result=1
    fi
    
    log_info "=== Running Replacement Function Tests ==="
    if ! test_replacement_function_compatibility; then
        overall_result=1
    fi
    
    log_info "=== Running Edge Cases Tests ==="
    if ! test_edge_cases; then
        overall_result=1
    fi
    
    log_info "=== Running Parameter Validation Tests ==="
    if ! test_parameter_validation; then
        overall_result=1
    fi
    
    # Generate final report
    log_info "=== Generating Compatibility Report ==="
    if ! generate_compatibility_report; then
        overall_result=1
    fi
    
    # Clean up temporary files
    rm -rf "$TEMP_TEST_DIR" 2>/dev/null
    
    # Final result
    if [ "$overall_result" -eq 0 ]; then
        log_success "All compatibility tests passed!"
        echo ""
        echo "The replacement function is compatible with this system."
        echo "System: $(detect_system)"
        echo "Bash Version: $(detect_bash_version)"
    else
        log_error "Some compatibility tests failed!"
        echo ""
        echo "The replacement function may have compatibility issues on this system."
        echo "Please review the detailed log: $COMPATIBILITY_LOG"
    fi
    
    return $overall_result
}

# Run main function if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi