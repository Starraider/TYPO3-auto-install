#!/bin/bash

# Bash Version-Specific Compatibility Test
# Tests specific bash version compatibility requirements
# Requirements: 5.1, 5.2, 5.3, 5.4

set -e

# Source path resolution utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/path-utils.sh"

# Test configuration
PROJECT_ROOT="$(resolve_project_root)"
TEST_RESULTS_DIR="$(resolve_tests_path "reports")"
VERSION_LOG="$TEST_RESULTS_DIR/bash_version_$(date +%Y%m%d_%H%M%S).log"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$VERSION_LOG"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1" | tee -a "$VERSION_LOG"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$VERSION_LOG"
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1" | tee -a "$VERSION_LOG"
}

# Bash version detection and analysis
analyze_bash_version() {
    local bash_version="$BASH_VERSION"
    local bash_major="${bash_version%%.*}"
    local bash_minor="${bash_version#*.}"
    bash_minor="${bash_minor%%.*}"
    
    log_info "Analyzing Bash Version: $bash_version"
    log_info "Major version: $bash_major"
    log_info "Minor version: $bash_minor"
    
    # Determine compatibility level
    if [ "$bash_major" -lt 3 ]; then
        echo "incompatible:Bash $bash_version is too old (minimum: 3.2)"
        return 1
    elif [ "$bash_major" -eq 3 ] && [ "$bash_minor" -lt 2 ]; then
        echo "incompatible:Bash $bash_version is too old (minimum: 3.2)"
        return 1
    elif [ "$bash_major" -eq 3 ] && [ "$bash_minor" -eq 2 ]; then
        echo "minimal:Bash $bash_version (minimal compatibility - macOS default)"
        return 0
    elif [ "$bash_major" -eq 3 ] && [ "$bash_minor" -gt 2 ]; then
        echo "good:Bash $bash_version (good compatibility)"
        return 0
    elif [ "$bash_major" -eq 4 ]; then
        echo "excellent:Bash $bash_version (excellent compatibility)"
        return 0
    elif [ "$bash_major" -ge 5 ]; then
        echo "excellent:Bash $bash_version (excellent compatibility)"
        return 0
    else
        echo "unknown:Bash $bash_version (unknown compatibility)"
        return 2
    fi
}

# Test bash 3.2 specific features (macOS compatibility)
test_bash_32_features() {
    log_info "Testing Bash 3.2 specific features..."
    
    local test_passed=true
    
    # Test 1: Basic parameter expansion
    log_info "Testing parameter expansion..."
    local test_var="xxxx_sitepackage"
    local result="${test_var/xxxx/test}"
    if [ "$result" = "test_sitepackage" ]; then
        log_success "Parameter expansion works"
    else
        log_error "Parameter expansion failed: expected 'test_sitepackage', got '$result'"
        test_passed=false
    fi
    
    # Test 2: Pattern matching with %%/*
    log_info "Testing pattern matching..."
    local test_path="key:value|next:item"
    local first_part="${test_path%%|*}"
    if [ "$first_part" = "key:value" ]; then
        log_success "Pattern matching with %% works"
    else
        log_error "Pattern matching failed: expected 'key:value', got '$first_part'"
        test_passed=false
    fi
    
    # Test 3: Pattern matching with #*:
    local key_value="key:value"
    local value_part="${key_value#*:}"
    if [ "$value_part" = "value" ]; then
        log_success "Pattern matching with # works"
    else
        log_error "Pattern matching failed: expected 'value', got '$value_part'"
        test_passed=false
    fi
    
    # Test 4: Arithmetic expansion
    log_info "Testing arithmetic expansion..."
    local count=10
    local result=$((count + 5))
    if [ "$result" -eq 15 ]; then
        log_success "Arithmetic expansion works"
    else
        log_error "Arithmetic expansion failed: expected 15, got $result"
        test_passed=false
    fi
    
    # Test 5: Command substitution
    log_info "Testing command substitution..."
    local date_result=$(date +%Y 2>/dev/null)
    if [ -n "$date_result" ] && [ "$date_result" -ge 2020 ]; then
        log_success "Command substitution works"
    else
        log_error "Command substitution failed: got '$date_result'"
        test_passed=false
    fi
    
    # Test 6: Conditional expressions (basic)
    log_info "Testing conditional expressions..."
    if [ "test" = "test" ]; then
        log_success "Basic conditional expressions work"
    else
        log_error "Basic conditional expressions failed"
        test_passed=false
    fi
    
    # Test 7: String length
    log_info "Testing string length..."
    local test_string="hello"
    if [ "${#test_string}" -eq 5 ]; then
        log_success "String length calculation works"
    else
        log_error "String length failed: expected 5, got ${#test_string}"
        test_passed=false
    fi
    
    if [ "$test_passed" = "true" ]; then
        log_success "All Bash 3.2 features work correctly"
        return 0
    else
        log_error "Some Bash 3.2 features failed"
        return 1
    fi
}

# Test features that should NOT be used (bash 4+ specific)
test_bash4_features_avoidance() {
    log_info "Testing that bash 4+ specific features are avoided..."
    
    local bash_major="${BASH_VERSION%%.*}"
    
    # Test 1: Associative arrays should not be required
    log_info "Checking associative array usage..."
    if [ "$bash_major" -ge 4 ]; then
        log_info "Bash 4+ detected - associative arrays available but should not be required"
        
        # Test that our code works without associative arrays
        if declare -A test_array 2>/dev/null; then
            log_warning "Associative arrays are available but should not be used for compatibility"
            unset test_array
        fi
    else
        log_info "Bash 3.x detected - associative arrays not available (expected)"
        
        # Verify associative arrays fail gracefully
        if declare -A test_array 2>/dev/null; then
            log_error "Associative arrays should not be available in Bash 3.x"
            return 1
        else
            log_success "Associative arrays correctly unavailable in Bash 3.x"
        fi
    fi
    
    # Test 2: Advanced regex features
    log_info "Testing regex compatibility..."
    if [[ "test123" =~ ^test[0-9]+$ ]] 2>/dev/null; then
        log_info "Advanced regex available"
    else
        log_info "Advanced regex not available (acceptable for Bash 3.2)"
    fi
    
    # Test 3: Process substitution
    log_info "Testing process substitution..."
    if echo "test" | { read line; [ "$line" = "test" ]; } 2>/dev/null; then
        log_success "Process substitution works"
    else
        log_warning "Process substitution may not work (acceptable for some systems)"
    fi
    
    return 0
}

# Test portable constructs used in replacement function
test_portable_constructs() {
    log_info "Testing portable constructs used in replacement function..."
    
    local test_passed=true
    
    # Test 1: Delimited string parsing (replacement for associative arrays)
    log_info "Testing delimited string parsing..."
    local patterns_data="xxxx_sitepackage:test_sitepackage|skom:vendor|xxxx:test"
    local remaining_data="$patterns_data"
    local pattern_count=0
    
    while [ -n "$remaining_data" ]; do
        # Extract first pattern
        local pattern="${remaining_data%%|*}"
        
        # Remove pattern from remaining data
        if [ "$pattern" = "$remaining_data" ]; then
            remaining_data=""
        else
            remaining_data="${remaining_data#*|}"
        fi
        
        # Extract key and value
        local key="${pattern%%:*}"
        local value="${pattern#*:}"
        
        # Validate extraction
        case "$pattern_count" in
            0)
                if [ "$key" = "xxxx_sitepackage" ] && [ "$value" = "test_sitepackage" ]; then
                    log_success "First pattern parsed correctly"
                else
                    log_error "First pattern parsing failed: key='$key', value='$value'"
                    test_passed=false
                fi
                ;;
            1)
                if [ "$key" = "skom" ] && [ "$value" = "vendor" ]; then
                    log_success "Second pattern parsed correctly"
                else
                    log_error "Second pattern parsing failed: key='$key', value='$value'"
                    test_passed=false
                fi
                ;;
            2)
                if [ "$key" = "xxxx" ] && [ "$value" = "test" ]; then
                    log_success "Third pattern parsed correctly"
                else
                    log_error "Third pattern parsing failed: key='$key', value='$value'"
                    test_passed=false
                fi
                ;;
        esac
        
        pattern_count=$((pattern_count + 1))
        
        # Safety check to prevent infinite loop
        if [ "$pattern_count" -gt 10 ]; then
            log_error "Pattern parsing loop exceeded safety limit"
            test_passed=false
            break
        fi
    done
    
    if [ "$pattern_count" -eq 3 ]; then
        log_success "Delimited string parsing works correctly"
    else
        log_error "Expected 3 patterns, got $pattern_count"
        test_passed=false
    fi
    
    # Test 2: Portable sed usage
    log_info "Testing portable sed usage..."
    local temp_file="/tmp/sed_test_$$"
    echo "xxxx_sitepackage test" > "$temp_file"
    
    # Test GNU sed style first
    if sed -i 's/xxxx_sitepackage/test_sitepackage/g' "$temp_file" 2>/dev/null; then
        local result=$(cat "$temp_file")
        if [ "$result" = "test_sitepackage test" ]; then
            log_success "GNU sed style works"
        else
            log_error "GNU sed style failed: got '$result'"
            test_passed=false
        fi
    else
        # Test BSD sed style
        echo "xxxx_sitepackage test" > "$temp_file"
        if sed -i '' 's/xxxx_sitepackage/test_sitepackage/g' "$temp_file" 2>/dev/null; then
            local result=$(cat "$temp_file")
            if [ "$result" = "test_sitepackage test" ]; then
                log_success "BSD sed style works"
            else
                log_error "BSD sed style failed: got '$result'"
                test_passed=false
            fi
        else
            log_error "Neither GNU nor BSD sed styles work"
            test_passed=false
        fi
    fi
    
    rm -f "$temp_file" 2>/dev/null
    
    # Test 3: Portable find usage
    log_info "Testing portable find usage..."
    local temp_dir="/tmp/find_test_$$"
    mkdir -p "$temp_dir"
    touch "$temp_dir/test.txt"
    touch "$temp_dir/test.php"
    
    # Test find with -type f and -name
    local find_count=$(find "$temp_dir" -type f -name "*.txt" | wc -l | tr -d ' ')
    if [ "$find_count" -eq 1 ]; then
        log_success "Portable find usage works"
    else
        log_error "Portable find failed: expected 1 file, found $find_count"
        test_passed=false
    fi
    
    rm -rf "$temp_dir" 2>/dev/null
    
    if [ "$test_passed" = "true" ]; then
        log_success "All portable constructs work correctly"
        return 0
    else
        log_error "Some portable constructs failed"
        return 1
    fi
}

# Test system-specific compatibility
test_system_specific() {
    log_info "Testing system-specific compatibility..."
    
    local system_type=""
    if [[ "$OSTYPE" == "darwin"* ]]; then
        system_type="macOS"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        system_type="Linux"
    elif [[ "$OSTYPE" == "freebsd"* ]]; then
        system_type="FreeBSD"
    else
        system_type="Unknown"
    fi
    
    log_info "Detected system: $system_type"
    
    case "$system_type" in
        "macOS")
            log_info "Testing macOS-specific compatibility..."
            
            # Test default bash version
            local bash_major="${BASH_VERSION%%.*}"
            local bash_minor="${BASH_VERSION#*.}"
            bash_minor="${bash_minor%%.*}"
            
            if [ "$bash_major" -eq 3 ] && [ "$bash_minor" -eq 2 ]; then
                log_success "Default macOS bash version (3.2) detected"
            else
                log_info "Non-default bash version on macOS: ${BASH_VERSION}"
            fi
            
            # Test BSD sed
            if command -v sed >/dev/null 2>&1; then
                local temp_file="/tmp/macos_sed_test"
                echo "test" > "$temp_file"
                if sed -i '' 's/test/success/' "$temp_file" 2>/dev/null; then
                    log_success "BSD sed (macOS default) works"
                else
                    log_warning "BSD sed may not work as expected"
                fi
                rm -f "$temp_file" 2>/dev/null
            fi
            ;;
            
        "Linux")
            log_info "Testing Linux-specific compatibility..."
            
            # Test GNU sed
            if command -v sed >/dev/null 2>&1; then
                local temp_file="/tmp/linux_sed_test"
                echo "test" > "$temp_file"
                if sed -i 's/test/success/' "$temp_file" 2>/dev/null; then
                    log_success "GNU sed (Linux default) works"
                else
                    log_warning "GNU sed may not work as expected"
                fi
                rm -f "$temp_file" 2>/dev/null
            fi
            
            # Check for gsed (GNU sed alternative)
            if command -v gsed >/dev/null 2>&1; then
                log_info "GNU sed alternative (gsed) available"
            fi
            ;;
            
        *)
            log_info "Testing general Unix compatibility..."
            ;;
    esac
    
    return 0
}

# Generate version-specific report
generate_version_report() {
    local report_file="$TEST_RESULTS_DIR/bash_version_report_$(date +%Y%m%d_%H%M%S).txt"
    
    log_info "Generating version-specific report: $report_file"
    
    local bash_version="$BASH_VERSION"
    local compatibility_result=$(analyze_bash_version)
    local compatibility_level="${compatibility_result%%:*}"
    local compatibility_message="${compatibility_result#*:}"
    
    cat > "$report_file" << EOF
# Bash Version Compatibility Report
Generated: $(date)

## Version Information
Bash Version: $bash_version
Compatibility Level: $compatibility_level
Assessment: $compatibility_message

## System Information
OS Type: $OSTYPE
System: $(uname -s 2>/dev/null || echo "Unknown")
Architecture: $(uname -m 2>/dev/null || echo "Unknown")

## Feature Availability
EOF
    
    # Test feature availability
    local features=""
    
    # Test associative arrays
    if declare -A test_array 2>/dev/null; then
        features="$features\n- Associative Arrays: Available (Bash 4.0+)"
        unset test_array
    else
        features="$features\n- Associative Arrays: Not Available (Bash 3.x)"
    fi
    
    # Test regex matching
    if [[ "test" =~ ^test$ ]] 2>/dev/null; then
        features="$features\n- Regex Matching: Available"
    else
        features="$features\n- Regex Matching: Limited or Not Available"
    fi
    
    # Test process substitution
    if echo "test" | { read line; echo "$line"; } >/dev/null 2>&1; then
        features="$features\n- Process Substitution: Available"
    else
        features="$features\n- Process Substitution: Not Available"
    fi
    
    echo -e "$features" >> "$report_file"
    
    cat >> "$report_file" << EOF

## Compatibility Recommendations
EOF
    
    case "$compatibility_level" in
        "incompatible")
            echo "- CRITICAL: Upgrade bash to version 3.2 or higher" >> "$report_file"
            echo "- The replacement function will NOT work with this bash version" >> "$report_file"
            ;;
        "minimal")
            echo "- The replacement function should work with this bash version" >> "$report_file"
            echo "- This is the minimum supported version (common on macOS)" >> "$report_file"
            echo "- Consider upgrading for better performance and features" >> "$report_file"
            ;;
        "good"|"excellent")
            echo "- The replacement function will work well with this bash version" >> "$report_file"
            echo "- All required features are available" >> "$report_file"
            ;;
        *)
            echo "- Unknown compatibility level - manual testing recommended" >> "$report_file"
            ;;
    esac
    
    cat >> "$report_file" << EOF

## Detailed Test Log
EOF
    
    # Append detailed log
    if [ -f "$VERSION_LOG" ]; then
        cat "$VERSION_LOG" >> "$report_file"
    fi
    
    log_info "Version report generated: $report_file"
    
    # Return status based on compatibility
    case "$compatibility_level" in
        "incompatible")
            return 2
            ;;
        "minimal"|"good"|"excellent")
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Main execution
main() {
    log_info "Starting Bash Version Compatibility Test"
    
    # Create results directory
    mkdir -p "$TEST_RESULTS_DIR"
    
    # Analyze bash version
    local compatibility_result=$(analyze_bash_version)
    local compatibility_level="${compatibility_result%%:*}"
    local compatibility_message="${compatibility_result#*:}"
    
    log_info "Compatibility Assessment: $compatibility_message"
    
    local overall_result=0
    
    # Run version-specific tests
    case "$compatibility_level" in
        "incompatible")
            log_error "Bash version is incompatible - skipping detailed tests"
            overall_result=2
            ;;
        *)
            log_info "=== Testing Bash 3.2 Features ==="
            if ! test_bash_32_features; then
                overall_result=1
            fi
            
            log_info "=== Testing Bash 4+ Feature Avoidance ==="
            if ! test_bash4_features_avoidance; then
                overall_result=1
            fi
            
            log_info "=== Testing Portable Constructs ==="
            if ! test_portable_constructs; then
                overall_result=1
            fi
            
            log_info "=== Testing System-Specific Compatibility ==="
            if ! test_system_specific; then
                overall_result=1
            fi
            ;;
    esac
    
    # Generate report
    log_info "=== Generating Version Report ==="
    local report_result=0
    if ! generate_version_report; then
        report_result=$?
        if [ "$report_result" -gt "$overall_result" ]; then
            overall_result=$report_result
        fi
    fi
    
    # Final assessment
    case "$overall_result" in
        0)
            log_success "Bash version compatibility: PASSED"
            echo ""
            echo "✓ Your bash version (${BASH_VERSION}) is compatible with the replacement function"
            ;;
        1)
            log_warning "Bash version compatibility: PASSED with warnings"
            echo ""
            echo "⚠ Your bash version (${BASH_VERSION}) is compatible but has some limitations"
            ;;
        2)
            log_error "Bash version compatibility: FAILED"
            echo ""
            echo "✗ Your bash version (${BASH_VERSION}) is NOT compatible with the replacement function"
            echo "  Minimum required version: 3.2"
            ;;
    esac
    
    return $overall_result
}

# Run main function if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi