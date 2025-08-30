#!/bin/bash

# Path Resolution Utilities for Test Scripts
# Provides standardized path resolution functions for test scripts moved to subdirectories

# Global variables for caching resolved paths
_PROJECT_ROOT=""
_SCRIPT_DIR=""

# Function to resolve the project root directory from any test subdirectory
# This function works by looking for key project files that indicate the root
resolve_project_root() {
    local current_dir
    local max_depth=10
    local depth=0
    
    # If already cached, return cached value
    if [ -n "$_PROJECT_ROOT" ] && [ -d "$_PROJECT_ROOT" ]; then
        echo "$_PROJECT_ROOT"
        return 0
    fi
    
    # Start from the directory containing the calling script
    if [ -n "${BASH_SOURCE[1]}" ]; then
        current_dir="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
    else
        current_dir="$(pwd)"
    fi
    
    # Look for project root indicators by traversing up the directory tree
    while [ "$depth" -lt "$max_depth" ]; do
        # Check for key project files that indicate we're at the root
        if [ -f "$current_dir/install-typo3.sh" ] && \
           [ -f "$current_dir/create-sitepackage.sh" ] && \
           [ -f "$current_dir/install.config" ] && \
           [ -d "$current_dir/install-src" ]; then
            _PROJECT_ROOT="$current_dir"
            echo "$_PROJECT_ROOT"
            return 0
        fi
        
        # Move up one directory
        local parent_dir="$(dirname "$current_dir")"
        
        # Check if we've reached the filesystem root
        if [ "$parent_dir" = "$current_dir" ]; then
            break
        fi
        
        current_dir="$parent_dir"
        depth=$((depth + 1))
    done
    
    # If we couldn't find the project root, return error
    echo "ERROR: Could not locate project root directory" >&2
    return 1
}

# Function to get the directory containing the calling script
get_script_directory() {
    local script_path
    
    # If already cached, return cached value
    if [ -n "$_SCRIPT_DIR" ] && [ -d "$_SCRIPT_DIR" ]; then
        echo "$_SCRIPT_DIR"
        return 0
    fi
    
    # Determine script directory based on how the script was called
    if [ -n "${BASH_SOURCE[1]}" ]; then
        script_path="${BASH_SOURCE[1]}"
    elif [ -n "$0" ]; then
        script_path="$0"
    else
        echo "ERROR: Could not determine script path" >&2
        return 1
    fi
    
    _SCRIPT_DIR="$(cd "$(dirname "$script_path")" && pwd)"
    echo "$_SCRIPT_DIR"
    return 0
}

# Function to resolve paths relative to project root
resolve_project_path() {
    local relative_path="$1"
    local project_root
    
    if [ -z "$relative_path" ]; then
        echo "ERROR: No path provided to resolve_project_path" >&2
        return 1
    fi
    
    project_root="$(resolve_project_root)"
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    echo "$project_root/$relative_path"
    return 0
}

# Function to resolve paths relative to the tests directory
resolve_tests_path() {
    local relative_path="$1"
    local tests_dir
    
    if [ -z "$relative_path" ]; then
        echo "ERROR: No path provided to resolve_tests_path" >&2
        return 1
    fi
    
    tests_dir="$(resolve_project_path "tests")"
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    echo "$tests_dir/$relative_path"
    return 0
}

# Function to source files relative to project root with error handling
source_project_file() {
    local file_path="$1"
    local resolved_path
    
    if [ -z "$file_path" ]; then
        echo "ERROR: No file path provided to source_project_file" >&2
        return 1
    fi
    
    resolved_path="$(resolve_project_path "$file_path")"
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    if [ ! -f "$resolved_path" ]; then
        echo "ERROR: File not found: $resolved_path" >&2
        return 1
    fi
    
    if [ ! -r "$resolved_path" ]; then
        echo "ERROR: File not readable: $resolved_path" >&2
        return 1
    fi
    
    # shellcheck source=/dev/null
    source "$resolved_path"
    return $?
}

# Function to check if we're running from the expected test directory structure
validate_test_environment() {
    local expected_category="$1"  # Optional: unit, integration, compatibility, etc.
    local script_dir
    local project_root
    
    script_dir="$(get_script_directory)"
    if [ $? -ne 0 ]; then
        echo "ERROR: Could not determine script directory" >&2
        return 1
    fi
    
    project_root="$(resolve_project_root)"
    if [ $? -ne 0 ]; then
        echo "ERROR: Could not locate project root" >&2
        return 1
    fi
    
    # Check if we're in the tests directory structure
    if [[ "$script_dir" != "$project_root/tests"* ]]; then
        echo "WARNING: Script not running from tests directory structure" >&2
        echo "  Script directory: $script_dir" >&2
        echo "  Expected under: $project_root/tests" >&2
    fi
    
    # If a specific category is expected, validate it
    if [ -n "$expected_category" ]; then
        local expected_dir="$project_root/tests/$expected_category"
        if [[ "$script_dir" != "$expected_dir"* ]]; then
            echo "WARNING: Script not in expected category directory" >&2
            echo "  Script directory: $script_dir" >&2
            echo "  Expected directory: $expected_dir" >&2
        fi
    fi
    
    return 0
}

# Function to get relative path from project root to current script
get_relative_script_path() {
    local script_dir
    local project_root
    
    script_dir="$(get_script_directory)"
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    project_root="$(resolve_project_root)"
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    # Calculate relative path
    local relative_path="${script_dir#$project_root/}"
    
    # If the paths are the same, we're at the root
    if [ "$relative_path" = "$script_dir" ]; then
        echo "."
    else
        echo "$relative_path"
    fi
    
    return 0
}

# Function to clear cached paths (useful for testing)
clear_path_cache() {
    _PROJECT_ROOT=""
    _SCRIPT_DIR=""
}

# Function to display path resolution debug information
debug_path_resolution() {
    local verbose="${1:-false}"
    
    echo "=== Path Resolution Debug Information ==="
    echo "Current working directory: $(pwd)"
    echo "Script directory: $(get_script_directory 2>/dev/null || echo 'FAILED')"
    echo "Project root: $(resolve_project_root 2>/dev/null || echo 'FAILED')"
    echo "Relative script path: $(get_relative_script_path 2>/dev/null || echo 'FAILED')"
    
    if [ "$verbose" = "true" ]; then
        echo ""
        echo "BASH_SOURCE array:"
        local i=0
        while [ $i -lt ${#BASH_SOURCE[@]} ]; do
            echo "  [$i]: ${BASH_SOURCE[$i]:-'(empty)'}"
            i=$((i + 1))
        done
        
        echo ""
        echo "Environment variables:"
        echo "  PWD: $PWD"
        echo "  OLDPWD: ${OLDPWD:-'(not set)'}"
        echo "  \$0: $0"
    fi
    
    echo "========================================"
}

# Export functions for use in other scripts
export -f resolve_project_root
export -f get_script_directory
export -f resolve_project_path
export -f resolve_tests_path
export -f source_project_file
export -f validate_test_environment
export -f get_relative_script_path
export -f clear_path_cache
export -f debug_path_resolution