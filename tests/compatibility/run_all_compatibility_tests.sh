#!/bin/bash

# Comprehensive Cross-Platform Compatibility Test Runner
# Executes all compatibility tests and generates final assessment
# Requirements: 5.1, 5.2, 5.3, 5.4, 6.1, 6.2, 6.3, 6.4

set -e

# Source path resolution utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/path-utils.sh"

# Test configuration
PROJECT_ROOT="$(resolve_project_root)"
TEST_RESULTS_DIR="$(resolve_tests_path "reports")"
MASTER_LOG="$TEST_RESULTS_DIR/compatibility_master_$(date +%Y%m%d_%H%M%S).log"
FINAL_REPORT="$TEST_RESULTS_DIR/final_compatibility_report_$(date +%Y%m%d_%H%M%S).txt"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$MASTER_LOG"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1" | tee -a "$MASTER_LOG"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$MASTER_LOG"
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1" | tee -a "$MASTER_LOG"
}

log_header() {
    echo -e "${CYAN}${BOLD}=== $1 ===${NC}" | tee -a "$MASTER_LOG"
}

# System information collection
collect_system_info() {
    log_header "System Information Collection"
    
    local system_info=""
    
    # Operating system
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
    else
        system_info="$OSTYPE"
    fi
    
    log_info "Operating System: $system_info"
    log_info "Architecture: $(uname -m 2>/dev/null || echo 'unknown')"
    log_info "Kernel: $(uname -r 2>/dev/null || echo 'unknown')"
    log_info "Bash Version: $BASH_VERSION"
    log_info "Bash Path: $(which bash 2>/dev/null || echo 'unknown')"
    
    # Check for alternative bash versions
    if command -v bash >/dev/null 2>&1; then
        local bash_path=$(which bash)
        local bash_version_output=$(bash --version 2>/dev/null | head -1 || echo "unknown")
        log_info "Bash Version Output: $bash_version_output"
    fi
    
    # Check for other shells
    for shell in zsh fish dash; do
        if command -v "$shell" >/dev/null 2>&1; then
            log_info "Alternative shell available: $shell"
        fi
    done
    
    # Check system tools
    local tools=("sed" "gsed" "grep" "find" "file" "wc" "tr" "awk")
    for tool in "${tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            local tool_path=$(which "$tool" 2>/dev/null)
            log_info "Tool available: $tool ($tool_path)"
        else
            log_warning "Tool missing: $tool"
        fi
    done
    
    echo "SYSTEM_INFO:$system_info" >> "$MASTER_LOG"
    echo "BASH_VERSION:$BASH_VERSION" >> "$MASTER_LOG"
    echo "OSTYPE:$OSTYPE" >> "$MASTER_LOG"
}

# Run bash version compatibility test
run_bash_version_test() {
    log_header "Bash Version Compatibility Test"
    
    local test_script="$SCRIPT_DIR/test_bash_version_compatibility.sh"
    local test_result=0
    
    if [ ! -f "$test_script" ]; then
        log_error "Bash version test script not found: $test_script"
        return 2
    fi
    
    log_info "Running bash version compatibility test..."
    
    if bash "$test_script" >> "$MASTER_LOG" 2>&1; then
        log_success "Bash version compatibility test passed"
        test_result=0
    else
        local exit_code=$?
        case $exit_code in
            1)
                log_warning "Bash version compatibility test passed with warnings"
                test_result=1
                ;;
            2)
                log_error "Bash version compatibility test failed - incompatible bash version"
                test_result=2
                ;;
            *)
                log_error "Bash version compatibility test failed with exit code $exit_code"
                test_result=2
                ;;
        esac
    fi
    
    echo "BASH_VERSION_TEST:$test_result" >> "$MASTER_LOG"
    return $test_result
}

# Run comprehensive compatibility test
run_comprehensive_test() {
    log_header "Comprehensive Compatibility Test"
    
    local test_script="$SCRIPT_DIR/test_bash_compatibility.sh"
    local test_result=0
    
    if [ ! -f "$test_script" ]; then
        log_error "Comprehensive test script not found: $test_script"
        return 2
    fi
    
    log_info "Running comprehensive compatibility test..."
    
    if bash "$test_script" >> "$MASTER_LOG" 2>&1; then
        log_success "Comprehensive compatibility test passed"
        test_result=0
    else
        local exit_code=$?
        case $exit_code in
            1)
                log_warning "Comprehensive compatibility test passed with warnings"
                test_result=1
                ;;
            *)
                log_error "Comprehensive compatibility test failed with exit code $exit_code"
                test_result=2
                ;;
        esac
    fi
    
    echo "COMPREHENSIVE_TEST:$test_result" >> "$MASTER_LOG"
    return $test_result
}

# Run existing replacement function tests
run_existing_tests() {
    log_header "Existing Replacement Function Tests"
    
    local test_result=0
    local tests_run=0
    local tests_passed=0
    
    # Test 1: Basic replacement function test (now integrated into unit tests)
    log_info "Running unit tests for replacement function validation..."
    tests_run=$((tests_run + 1))
    
    if "$PROJECT_ROOT/tests/run-tests.sh" --category unit >> "$MASTER_LOG" 2>&1; then
        log_success "Unit tests passed"
        tests_passed=$((tests_passed + 1))
    else
        log_error "Unit tests failed"
        test_result=1
    fi
    else
        log_warning "Basic replacement function test not found"
    fi
    
    # Test 2: Permission preservation test
    local permission_test_script="$(resolve_tests_path "integration/test_permission_preservation.sh")"
    if [ -f "$permission_test_script" ]; then
        log_info "Running permission preservation test..."
        tests_run=$((tests_run + 1))
        
        if bash "$permission_test_script" >> "$MASTER_LOG" 2>&1; then
            log_success "Permission preservation test passed"
            tests_passed=$((tests_passed + 1))
        else
            log_error "Permission preservation test failed"
            test_result=1
        fi
    else
        log_warning "Permission preservation test not found"
    fi
    
    # Test 3: Error handling test
    local error_test_script="$PROJECT_ROOT/test_replacement_error_handling.sh"
    if [ -f "$error_test_script" ]; then
        log_info "Running error handling test..."
        tests_run=$((tests_run + 1))
        
        if bash "$error_test_script" >> "$MASTER_LOG" 2>&1; then
            log_success "Error handling test passed"
            tests_passed=$((tests_passed + 1))
        else
            log_error "Error handling test failed"
            test_result=1
        fi
    else
        log_warning "Error handling test not found"
    fi
    
    log_info "Existing tests summary: $tests_passed/$tests_run passed"
    
    echo "EXISTING_TESTS:$test_result" >> "$MASTER_LOG"
    echo "EXISTING_TESTS_SUMMARY:$tests_passed/$tests_run" >> "$MASTER_LOG"
    
    return $test_result
}

# Test real sitepackage scenario
test_real_sitepackage() {
    log_header "Real Sitepackage Integration Test"
    
    local test_result=0
    
    # Check if real sitepackage test exists
    local real_sitepackage_test="$(resolve_tests_path "integration/test_real_sitepackage.sh")"
    if [ -f "$real_sitepackage_test" ]; then
        log_info "Running real sitepackage integration test..."
        
        if bash "$real_sitepackage_test" >> "$MASTER_LOG" 2>&1; then
            log_success "Real sitepackage integration test passed"
            test_result=0
        else
            log_error "Real sitepackage integration test failed"
            test_result=1
        fi
    else
        log_info "Creating and running real sitepackage test..."
        
        # Create a minimal real sitepackage test
        local temp_test_dir="$SCRIPT_DIR/temp_real_test"
        local source_dir="$PROJECT_ROOT/install-src/xxxx_sitepackage"
        
        if [ -d "$source_dir" ]; then
            # Copy real sitepackage template
            cp -r "$source_dir" "$temp_test_dir"
            
            # Extract and source replacement function
            local temp_functions="$temp_test_dir/functions.sh"
            echo "#!/bin/bash" > "$temp_functions"
            
            # Extract required functions
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
                if sed -n "/^${func_name}()/,/^}$/p" "$PROJECT_ROOT/install-typo3.sh" >> "$temp_functions" 2>/dev/null; then
                    echo "" >> "$temp_functions"
                fi
            done
            
            # Source functions and test
            if source "$temp_functions" 2>/dev/null; then
                log_info "Testing with real sitepackage template..."
                
                if replace_sitepackage_placeholders "$temp_test_dir" "realtest" "realtest_sitepackage" "realtest-sitepackage" "RealtestSitepackage" "realvendor" false >> "$MASTER_LOG" 2>&1; then
                    log_success "Real sitepackage test passed"
                    test_result=0
                else
                    log_error "Real sitepackage test failed"
                    test_result=1
                fi
            else
                log_error "Failed to source replacement functions"
                test_result=1
            fi
            
            # Clean up
            rm -rf "$temp_test_dir" 2>/dev/null
        else
            log_warning "Real sitepackage template not found at: $source_dir"
            test_result=0  # Not a failure, just not available
        fi
    fi
    
    echo "REAL_SITEPACKAGE_TEST:$test_result" >> "$MASTER_LOG"
    return $test_result
}

# Generate final compatibility report
generate_final_report() {
    log_header "Generating Final Compatibility Report"
    
    log_info "Creating final report: $FINAL_REPORT"
    
    # Extract test results from master log
    local bash_version_result=$(grep "BASH_VERSION_TEST:" "$MASTER_LOG" | cut -d: -f2 | tail -1)
    local comprehensive_result=$(grep "COMPREHENSIVE_TEST:" "$MASTER_LOG" | cut -d: -f2 | tail -1)
    local existing_tests_result=$(grep "EXISTING_TESTS:" "$MASTER_LOG" | cut -d: -f2 | tail -1)
    local real_sitepackage_result=$(grep "REAL_SITEPACKAGE_TEST:" "$MASTER_LOG" | cut -d: -f2 | tail -1)
    local system_info=$(grep "SYSTEM_INFO:" "$MASTER_LOG" | cut -d: -f2- | tail -1)
    local bash_version=$(grep "BASH_VERSION:" "$MASTER_LOG" | cut -d: -f2 | tail -1)
    local ostype=$(grep "OSTYPE:" "$MASTER_LOG" | cut -d: -f2 | tail -1)
    local existing_tests_summary=$(grep "EXISTING_TESTS_SUMMARY:" "$MASTER_LOG" | cut -d: -f2 | tail -1)
    
    # Calculate overall compatibility score
    local total_score=0
    local max_score=0
    local critical_failures=0
    
    # Bash version test (critical)
    max_score=$((max_score + 3))
    case "$bash_version_result" in
        "0") total_score=$((total_score + 3)) ;;
        "1") total_score=$((total_score + 2)) ;;
        "2") critical_failures=$((critical_failures + 1)) ;;
    esac
    
    # Comprehensive test (important)
    max_score=$((max_score + 2))
    case "$comprehensive_result" in
        "0") total_score=$((total_score + 2)) ;;
        "1") total_score=$((total_score + 1)) ;;
    esac
    
    # Existing tests (important)
    max_score=$((max_score + 2))
    case "$existing_tests_result" in
        "0") total_score=$((total_score + 2)) ;;
        "1") total_score=$((total_score + 1)) ;;
    esac
    
    # Real sitepackage test (nice to have)
    max_score=$((max_score + 1))
    case "$real_sitepackage_result" in
        "0") total_score=$((total_score + 1)) ;;
    esac
    
    # Calculate percentage
    local compatibility_percentage=0
    if [ "$max_score" -gt 0 ]; then
        compatibility_percentage=$((total_score * 100 / max_score))
    fi
    
    # Determine overall status
    local overall_status="UNKNOWN"
    local status_color="$NC"
    local recommendations=""
    
    if [ "$critical_failures" -gt 0 ]; then
        overall_status="INCOMPATIBLE"
        status_color="$RED"
        recommendations="Critical compatibility issues detected. The replacement function will NOT work on this system."
    elif [ "$compatibility_percentage" -ge 90 ]; then
        overall_status="FULLY COMPATIBLE"
        status_color="$GREEN"
        recommendations="Excellent compatibility. The replacement function will work perfectly on this system."
    elif [ "$compatibility_percentage" -ge 75 ]; then
        overall_status="COMPATIBLE"
        status_color="$GREEN"
        recommendations="Good compatibility. The replacement function will work well on this system."
    elif [ "$compatibility_percentage" -ge 60 ]; then
        overall_status="MOSTLY COMPATIBLE"
        status_color="$YELLOW"
        recommendations="Acceptable compatibility with some limitations. The replacement function should work but may have minor issues."
    else
        overall_status="LIMITED COMPATIBILITY"
        status_color="$YELLOW"
        recommendations="Limited compatibility detected. The replacement function may work but could have significant issues."
    fi
    
    # Create the final report
    cat > "$FINAL_REPORT" << EOF
# Cross-Platform Compatibility Assessment Report

**Generated:** $(date)
**Test Duration:** $(date -d "@$(($(date +%s) - $(stat -c %Y "$MASTER_LOG" 2>/dev/null || echo $(date +%s))))" -u +%H:%M:%S 2>/dev/null || echo "Unknown")

## Executive Summary

**Overall Status:** $overall_status
**Compatibility Score:** $total_score/$max_score ($compatibility_percentage%)
**Critical Failures:** $critical_failures

$recommendations

## System Information

- **Operating System:** $system_info
- **OS Type:** $ostype
- **Bash Version:** $bash_version
- **Architecture:** $(uname -m 2>/dev/null || echo 'unknown')
- **Test Date:** $(date)

## Test Results Summary

| Test Category | Result | Status |
|---------------|--------|--------|
| Bash Version Compatibility | $bash_version_result | $([ "$bash_version_result" = "0" ] && echo "✅ PASS" || [ "$bash_version_result" = "1" ] && echo "⚠️ WARN" || echo "❌ FAIL") |
| Comprehensive Compatibility | $comprehensive_result | $([ "$comprehensive_result" = "0" ] && echo "✅ PASS" || [ "$comprehensive_result" = "1" ] && echo "⚠️ WARN" || echo "❌ FAIL") |
| Existing Function Tests | $existing_tests_result | $([ "$existing_tests_result" = "0" ] && echo "✅ PASS" || [ "$existing_tests_result" = "1" ] && echo "⚠️ WARN" || echo "❌ FAIL") |
| Real Sitepackage Test | $real_sitepackage_result | $([ "$real_sitepackage_result" = "0" ] && echo "✅ PASS" || [ "$real_sitepackage_result" = "1" ] && echo "⚠️ WARN" || echo "❌ FAIL") |

### Existing Tests Details
$existing_tests_summary

## Compatibility Analysis

### Bash Version Assessment
EOF
    
    case "$bash_version_result" in
        "0")
            echo "✅ **EXCELLENT** - Bash version $bash_version is fully compatible" >> "$FINAL_REPORT"
            ;;
        "1")
            echo "⚠️ **ACCEPTABLE** - Bash version $bash_version is compatible with minor limitations" >> "$FINAL_REPORT"
            ;;
        "2")
            echo "❌ **CRITICAL** - Bash version $bash_version is incompatible (minimum required: 3.2)" >> "$FINAL_REPORT"
            ;;
    esac
    
    cat >> "$FINAL_REPORT" << EOF

### System Tools Assessment
EOF
    
    # Check tool availability from log
    if grep -q "Missing required tools" "$MASTER_LOG"; then
        echo "❌ **ISSUES DETECTED** - Some required system tools are missing" >> "$FINAL_REPORT"
    else
        echo "✅ **GOOD** - All required system tools are available" >> "$FINAL_REPORT"
    fi
    
    cat >> "$FINAL_REPORT" << EOF

### Feature Compatibility
- **String Manipulation:** $(grep -q "String substitution works correctly" "$MASTER_LOG" && echo "✅ Working" || echo "❌ Issues detected")
- **Parameter Expansion:** $(grep -q "Parameter expansion works correctly" "$MASTER_LOG" && echo "✅ Working" || echo "❌ Issues detected")
- **Sed Compatibility:** $(grep -q "sed works correctly" "$MASTER_LOG" && echo "✅ Working" || echo "❌ Issues detected")
- **Find Compatibility:** $(grep -q "find works correctly" "$MASTER_LOG" && echo "✅ Working" || echo "❌ Issues detected")

## Recommendations

### Immediate Actions Required
EOF
    
    case "$overall_status" in
        "INCOMPATIBLE")
            cat >> "$FINAL_REPORT" << EOF
1. **CRITICAL:** Upgrade bash to version 3.2 or higher
2. Install missing system tools if any were detected
3. Re-run compatibility tests after upgrades
4. **DO NOT** use the replacement function until compatibility is achieved
EOF
            ;;
        "LIMITED COMPATIBILITY"|"MOSTLY COMPATIBLE")
            cat >> "$FINAL_REPORT" << EOF
1. Review detailed test logs for specific issues
2. Consider upgrading bash for better compatibility
3. Test the replacement function thoroughly before production use
4. Monitor for any issues during actual usage
EOF
            ;;
        "COMPATIBLE"|"FULLY COMPATIBLE")
            cat >> "$FINAL_REPORT" << EOF
1. The replacement function is ready for use
2. No immediate actions required
3. Consider running periodic compatibility checks
4. Monitor system updates that might affect compatibility
EOF
            ;;
    esac
    
    cat >> "$FINAL_REPORT" << EOF

### Platform-Specific Notes
EOF
    
    case "$ostype" in
        "darwin"*)
            cat >> "$FINAL_REPORT" << EOF
- **macOS Detected:** Default bash 3.2 is the minimum supported version
- BSD sed is used by default (requires different syntax than GNU sed)
- Consider installing GNU tools via Homebrew for enhanced compatibility
- The replacement function is designed to work with macOS defaults
EOF
            ;;
        "linux-gnu"*)
            cat >> "$FINAL_REPORT" << EOF
- **Linux Detected:** Usually has good bash and tool compatibility
- GNU sed and other GNU tools are typically available
- Most modern Linux distributions exceed minimum requirements
- The replacement function should work excellently on this platform
EOF
            ;;
        *)
            cat >> "$FINAL_REPORT" << EOF
- **Unix-like System Detected:** Compatibility depends on available tools
- Ensure POSIX-compliant tools are available
- Test thoroughly before production use
- Consider installing GNU tools if compatibility issues arise
EOF
            ;;
    esac
    
    cat >> "$FINAL_REPORT" << EOF

## Detailed Test Logs

The complete test execution log is available in: $MASTER_LOG

### Key Log Sections
- System Information Collection
- Bash Version Compatibility Test
- Comprehensive Compatibility Test  
- Existing Function Tests
- Real Sitepackage Integration Test

## Conclusion

$recommendations

For technical support or questions about compatibility issues, refer to the detailed logs and test results above.

---
*Report generated by Cross-Platform Compatibility Test Suite*
*Test Suite Version: 1.0*
*Requirements Coverage: 5.1, 5.2, 5.3, 5.4, 6.1, 6.2, 6.3, 6.4*
EOF
    
    log_success "Final report generated: $FINAL_REPORT"
    
    # Display summary to console
    echo ""
    echo -e "${BOLD}=== COMPATIBILITY TEST SUMMARY ===${NC}"
    echo -e "Overall Status: ${status_color}${BOLD}$overall_status${NC}"
    echo -e "Compatibility Score: $total_score/$max_score ($compatibility_percentage%)"
    echo -e "System: $system_info"
    echo -e "Bash Version: $bash_version"
    echo ""
    echo -e "${BOLD}Detailed Report:${NC} $FINAL_REPORT"
    echo -e "${BOLD}Complete Log:${NC} $MASTER_LOG"
    echo ""
    
    # Return appropriate exit code
    case "$overall_status" in
        "INCOMPATIBLE")
            return 2
            ;;
        "LIMITED COMPATIBILITY")
            return 1
            ;;
        *)
            return 0
            ;;
    esac
}

# Main execution function
main() {
    echo -e "${CYAN}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║          Cross-Platform Compatibility Test Suite            ║"
    echo "║                                                              ║"
    echo "║  Testing XXXX Replacement Function Compatibility            ║"
    echo "║  Requirements: 5.1, 5.2, 5.3, 5.4, 6.1, 6.2, 6.3, 6.4     ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Create results directory
    mkdir -p "$TEST_RESULTS_DIR"
    
    # Initialize master log
    echo "# Cross-Platform Compatibility Test Suite - Master Log" > "$MASTER_LOG"
    echo "# Started: $(date)" >> "$MASTER_LOG"
    echo "" >> "$MASTER_LOG"
    
    local overall_result=0
    local start_time=$(date +%s)
    
    # Step 1: Collect system information
    collect_system_info
    
    # Step 2: Run bash version compatibility test
    if ! run_bash_version_test; then
        local exit_code=$?
        if [ "$exit_code" -gt "$overall_result" ]; then
            overall_result=$exit_code
        fi
    fi
    
    # Step 3: Run comprehensive compatibility test
    if ! run_comprehensive_test; then
        local exit_code=$?
        if [ "$exit_code" -gt "$overall_result" ]; then
            overall_result=$exit_code
        fi
    fi
    
    # Step 4: Run existing replacement function tests
    if ! run_existing_tests; then
        local exit_code=$?
        if [ "$exit_code" -gt "$overall_result" ]; then
            overall_result=$exit_code
        fi
    fi
    
    # Step 5: Test real sitepackage scenario
    if ! test_real_sitepackage; then
        local exit_code=$?
        if [ "$exit_code" -gt "$overall_result" ]; then
            overall_result=$exit_code
        fi
    fi
    
    # Step 6: Generate final report
    if ! generate_final_report; then
        local exit_code=$?
        if [ "$exit_code" -gt "$overall_result" ]; then
            overall_result=$exit_code
        fi
    fi
    
    # Calculate total execution time
    local end_time=$(date +%s)
    local total_time=$((end_time - start_time))
    
    echo "TOTAL_EXECUTION_TIME:${total_time}s" >> "$MASTER_LOG"
    log_info "Total execution time: ${total_time}s"
    
    return $overall_result
}

# Execute main function if script is run directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi