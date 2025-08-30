#!/bin/bash

# Cross-Directory Validation Script
# Tests path resolution utilities from different execution contexts

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test results
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

log_test() {
    echo -e "\n${BLUE}[TEST]${NC} $1"
    TESTS_RUN=$((TESTS_RUN + 1))
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

# Get the expected project root (from current context)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/path-utils.sh"
EXPECTED_ROOT="$(resolve_project_root)"

echo -e "${BLUE}=== Cross-Directory Path Resolution Validation ===${NC}"
echo "Expected project root: $EXPECTED_ROOT"

# Test 1: From tests/ directory
log_test "Path resolution from tests/ directory"
RESULT=$(bash -c 'cd tests && source lib/path-utils.sh && resolve_project_root')
if [ "$RESULT" = "$EXPECTED_ROOT" ]; then
    log_pass "Correct resolution from tests/ directory"
else
    log_fail "Incorrect resolution from tests/: $RESULT"
fi

# Test 2: From install-src/ directory
log_test "Path resolution from install-src/ directory"
RESULT=$(bash -c 'cd install-src && source ../tests/lib/path-utils.sh && resolve_project_root')
if [ "$RESULT" = "$EXPECTED_ROOT" ]; then
    log_pass "Correct resolution from install-src/ directory"
else
    log_fail "Incorrect resolution from install-src/: $RESULT"
fi

# Test 3: From project root
log_test "Path resolution from project root"
RESULT=$(bash -c 'source tests/lib/path-utils.sh && resolve_project_root')
if [ "$RESULT" = "$EXPECTED_ROOT" ]; then
    log_pass "Correct resolution from project root"
else
    log_fail "Incorrect resolution from project root: $RESULT"
fi

# Test 4: Sourcing project files from different directories
log_test "Sourcing project files from different directories"
RESULT=$(bash -c 'cd tests && source lib/path-utils.sh && source_project_file "replacement_functions_only.sh" >/dev/null 2>&1 && echo "success"')
if [ "$RESULT" = "success" ]; then
    log_pass "Successfully sourced project file from tests/ directory"
else
    log_fail "Failed to source project file from tests/ directory"
fi

# Test 5: Resolving test paths from different locations
log_test "Resolving test paths from different locations"
RESULT=$(bash -c 'cd install-src && source ../tests/lib/path-utils.sh && resolve_tests_path "lib/path-utils.sh"')
EXPECTED_PATH="$EXPECTED_ROOT/tests/lib/path-utils.sh"
if [ "$RESULT" = "$EXPECTED_PATH" ]; then
    log_pass "Correct test path resolution from install-src/"
else
    log_fail "Incorrect test path resolution: $RESULT (expected: $EXPECTED_PATH)"
fi

# Test 6: Environment validation from different directories
log_test "Environment validation from different directories"
# This should show warnings when not in tests/ structure
RESULT=$(bash -c 'cd install-src && source ../tests/lib/path-utils.sh && validate_test_environment 2>&1 | grep -q "WARNING" && echo "warning_shown"')
if [ "$RESULT" = "warning_shown" ]; then
    log_pass "Environment validation correctly shows warnings outside tests/"
else
    log_fail "Environment validation did not show expected warnings"
fi

# Test 7: Path caching across different contexts
log_test "Path caching consistency across contexts"
RESULT1=$(bash -c 'cd tests && source lib/path-utils.sh && resolve_project_root')
RESULT2=$(bash -c 'cd install-src && source ../tests/lib/path-utils.sh && resolve_project_root')
if [ "$RESULT1" = "$RESULT2" ] && [ "$RESULT1" = "$EXPECTED_ROOT" ]; then
    log_pass "Path caching consistent across different contexts"
else
    log_fail "Path caching inconsistent: tests/=$RESULT1, install-src/=$RESULT2"
fi

# Test 8: Relative path calculation from different directories
log_test "Relative path calculation from different directories"
RESULT=$(bash -c 'cd tests/lib && source path-utils.sh && get_relative_script_path')
if [ "$RESULT" = "tests/lib" ]; then
    log_pass "Correct relative path calculation: $RESULT"
else
    log_fail "Incorrect relative path calculation: $RESULT"
fi

# Summary
echo ""
echo -e "${BLUE}=== VALIDATION SUMMARY ===${NC}"
echo "Tests run: $TESTS_RUN"
echo -e "${GREEN}Tests passed: $TESTS_PASSED${NC}"
echo -e "${RED}Tests failed: $TESTS_FAILED${NC}"

if [ "$TESTS_RUN" -gt 0 ]; then
    SUCCESS_RATE=$((TESTS_PASSED * 100 / TESTS_RUN))
    echo "Success rate: ${SUCCESS_RATE}%"
fi

echo ""
if [ "$TESTS_FAILED" -eq 0 ]; then
    echo -e "${GREEN}✓ All cross-directory validation tests passed!${NC}"
    echo "Path resolution utilities are ready for use in moved test scripts."
    exit 0
else
    echo -e "${RED}✗ Some validation tests failed.${NC}"
    echo "Path resolution utilities need fixes before use."
    exit 1
fi