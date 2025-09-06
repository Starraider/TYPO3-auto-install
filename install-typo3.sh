#!/bin/bash

# Bash version detection and compatibility functions for cross-platform support
detect_bash_version() {
    local bash_major="${BASH_VERSION%%.*}"
    local bash_minor="${BASH_VERSION#*.}"
    bash_minor="${bash_minor%%.*}"
    
    echo "${bash_major}.${bash_minor}"
}

# Check bash compatibility and set feature flags
check_bash_compatibility() {
    local bash_version=$(detect_bash_version)
    local bash_major="${bash_version%%.*}"
    local bash_minor="${bash_version#*.}"
    
    # Set global compatibility flags
    BASH_SUPPORTS_ARRAYS=false
    BASH_SUPPORTS_ASSOCIATIVE_ARRAYS=false
    BASH_SUPPORTS_REGEX=false
    
    # Bash 3.1+ supports indexed arrays
    if [ "$bash_major" -gt 3 ] || ([ "$bash_major" -eq 3 ] && [ "$bash_minor" -ge 1 ]); then
        BASH_SUPPORTS_ARRAYS=true
    fi
    
    # Bash 4.0+ supports associative arrays
    if [ "$bash_major" -ge 4 ]; then
        BASH_SUPPORTS_ASSOCIATIVE_ARRAYS=true
        BASH_SUPPORTS_REGEX=true
    fi
    
    # Return compatibility status
    if [ "$bash_major" -lt 3 ] || ([ "$bash_major" -eq 3 ] && [ "$bash_minor" -lt 2 ]); then
        echo "incompatible:Bash version $bash_version is too old (minimum required: 3.2)"
        return 1
    elif [ "$bash_major" -eq 3 ] && [ "$bash_minor" -eq 2 ]; then
        echo "minimal:Bash version $bash_version (minimal compatibility mode)"
        return 0
    else
        echo "compatible:Bash version $bash_version (full compatibility)"
        return 0
    fi
}

# Portable pattern parsing function that works with bash 3.2+
parse_replacement_patterns() {
    local patterns_data="$1"
    local callback_function="$2"
    local callback_args="$3"
    
    # Use portable string parsing instead of array expansion
    local remaining_data="$patterns_data"
    local pattern_count=0
    
    while [ -n "$remaining_data" ]; do
        # Extract first pattern (before first |)
        local pattern="${remaining_data%%|*}"
        
        # Remove pattern from remaining data
        if [ "$pattern" = "$remaining_data" ]; then
            # No more | found, this is the last item
            remaining_data=""
        else
            remaining_data="${remaining_data#*|}"
        fi
        
        # Extract replacement (before next |)
        local replacement="${remaining_data%%|*}"
        
        # Remove replacement from remaining data
        if [ "$replacement" = "$remaining_data" ]; then
            # No more | found, this is the last item
            remaining_data=""
        else
            remaining_data="${remaining_data#*|}"
        fi
        
        # Skip if we don't have both pattern and replacement
        if [ -z "$pattern" ] || [ -z "$replacement" ]; then
            break
        fi
        
        # Call the callback function with pattern and replacement
        if [ -n "$callback_function" ]; then
            "$callback_function" "$pattern" "$replacement" "$callback_args"
        fi
        
        pattern_count=$((pattern_count + 1))
    done
    
    return $pattern_count
}

# Portable sed wrapper that handles different sed implementations
portable_sed() {
    local operation="$1"
    local pattern="$2"
    local replacement="$3"
    local file="$4"
    
    case "$operation" in
        "replace_in_place")
            # Try GNU sed first (Linux)
            if command -v gsed >/dev/null 2>&1; then
                gsed -i "s/${pattern}/${replacement}/g" "$file" 2>/dev/null
                return $?
            # Try standard sed (check if it's GNU sed)
            elif sed --version >/dev/null 2>&1; then
                sed -i "s/${pattern}/${replacement}/g" "$file" 2>/dev/null
                return $?
            else
                # BSD sed (macOS default) - requires backup extension
                sed -i '' "s/${pattern}/${replacement}/g" "$file" 2>/dev/null
                return $?
            fi
            ;;
        "count_matches")
            # Count pattern occurrences
            if command -v grep >/dev/null 2>&1; then
                grep -o "$pattern" "$file" 2>/dev/null | wc -l | tr -d ' '
            else
                # Fallback using sed
                sed -n "s/${pattern}/${replacement}/gp" "$file" 2>/dev/null | wc -l | tr -d ' '
            fi
            ;;
        *)
            echo "Unknown operation: $operation" >&2
            return 1
            ;;
    esac
}

# Check system compatibility and available tools
check_system_compatibility() {
    local verbose="$1"
    local log_prefix="$2"
    
    # Check bash compatibility
    local bash_compat=$(check_bash_compatibility)
    local bash_status="${bash_compat%%:*}"
    local bash_message="${bash_compat#*:}"
    
    if [ "$verbose" = "true" ]; then
        echo "$log_prefix System compatibility check:"
        echo "$log_prefix   $bash_message"
    fi
    
    # Check for required tools
    local missing_tools=""
    local available_tools=""
    
    # Check sed implementations
    if command -v gsed >/dev/null 2>&1; then
        available_tools="$available_tools gsed"
    elif command -v sed >/dev/null 2>&1; then
        available_tools="$available_tools sed"
    else
        missing_tools="$missing_tools sed"
    fi
    
    # Check for grep
    if command -v grep >/dev/null 2>&1; then
        available_tools="$available_tools grep"
    else
        missing_tools="$missing_tools grep"
    fi
    
    # Check for find
    if command -v find >/dev/null 2>&1; then
        available_tools="$available_tools find"
    else
        missing_tools="$missing_tools find"
    fi
    
    if [ "$verbose" = "true" ]; then
        echo "$log_prefix   Available tools:$available_tools"
        if [ -n "$missing_tools" ]; then
            echo "$log_prefix   Missing tools:$missing_tools"
        fi
    fi
    
    # Return compatibility status
    if [ "$bash_status" = "incompatible" ] || [ -n "$missing_tools" ]; then
        echo "incompatible:System compatibility check failed"
        return 1
    elif [ "$bash_status" = "minimal" ]; then
        echo "minimal:System has minimal compatibility"
        return 0
    else
        echo "compatible:System is fully compatible"
        return 0
    fi
}

# Function to replace sitepackage placeholders with proper validation and error handling
replace_sitepackage_placeholders() {
    local source_dir="$1"           # Directory containing copied sitepackage
    local project_name="$2"         # Base project name (e.g., "test")
    local sitepackage_name="$3"     # Full sitepackage name (e.g., "test_sitepackage")
    local sitepackage_kebab="$4"    # Kebab-case version (e.g., "test-sitepackage")
    local sitepackage_pascal="$5"   # PascalCase version (e.g., "TestSitepackage")
    local vendor_name="$6"          # Vendor name (e.g., "skom")
    local verbose="${7:-false}"     # Optional verbose logging
    
    # Enhanced logging with timestamp and detailed information
    local log_prefix="[$(date '+%Y-%m-%d %H:%M:%S')] PLACEHOLDER_REPLACEMENT:"
    
    # Check system compatibility before proceeding
    local system_compat=$(check_system_compatibility "$verbose" "$log_prefix")
    local system_status="${system_compat%%:*}"
    local system_message="${system_compat#*:}"
    
    if [ "$system_status" = "incompatible" ]; then
        echo "$log_prefix CRITICAL: $system_message"
        echo "$log_prefix Cannot proceed with replacement due to system incompatibility"
        return 2
    elif [ "$system_status" = "minimal" ]; then
        if [ "$verbose" = "true" ]; then
            echo "$log_prefix WARNING: $system_message"
            echo "$log_prefix Proceeding with minimal compatibility mode"
        fi
    elif [ "$verbose" = "true" ]; then
        echo "$log_prefix INFO: $system_message"
    fi
    
    # Comprehensive parameter validation using dedicated validation function
    local validation_result=$(validate_replacement_parameters "$source_dir" "$project_name" "$sitepackage_name" "$sitepackage_kebab" "$sitepackage_pascal" "$vendor_name" "$verbose" "$log_prefix")
    local validation_status="${validation_result%%$'\n'*}"
    
    if [ "$validation_status" != "validation_passed" ]; then
        echo "Error: Parameter validation failed"
        echo "Usage: replace_sitepackage_placeholders <source_dir> <project_name> <sitepackage_name> <sitepackage_kebab> <sitepackage_pascal> [vendor_name] [verbose]"
        
        # Extract and display validation error details
        local validation_errors="${validation_result#*$'\n'}"
        if [ -n "$validation_errors" ] && [ "$validation_errors" != "$validation_result" ]; then
            echo "Validation errors:"
            echo -e "$validation_errors"
        fi
        
        return 1
    fi
    
    # Initialize comprehensive processing statistics tracking
    local files_processed=0
    local files_skipped=0
    local files_failed=0
    local files_permission_denied=0
    local files_read_only=0
    local files_binary_skipped=0
    local files_system_skipped=0
    local total_replacements_made=0
    local start_time=$(date +%s)
    
    if [ "$verbose" = "true" ]; then
        echo "$log_prefix Starting placeholder replacement process"
        echo "$log_prefix Target directory: $source_dir"
        echo "$log_prefix Configuration:"
        echo "$log_prefix   Project name: '$project_name'"
        echo "$log_prefix   Sitepackage name: '$sitepackage_name'"
        echo "$log_prefix   Sitepackage kebab: '$sitepackage_kebab'"
        echo "$log_prefix   Sitepackage pascal: '$sitepackage_pascal'"
        if [ -n "$vendor_name" ]; then
            echo "$log_prefix   Vendor name: '$vendor_name'"
        else
            echo "$log_prefix   Vendor name: (not specified, will skip vendor replacement)"
        fi
        echo "$log_prefix Process ID: $$"
    fi
    
    # Comprehensive error handling structure with categorized error tracking (bash 3.2+ compatible)
    # Use delimited strings instead of associative arrays for compatibility
    local permission_errors=""
    local read_only_errors=""
    local processing_errors=""
    local validation_errors=""
    local has_errors=false
    local has_warnings=false
    
    # Escape special characters for sed operations
    local escaped_project_name=$(printf '%s\n' "$project_name" | sed 's/[[\.*^$()+?{|]/\\&/g')
    local escaped_sitepackage_name=$(printf '%s\n' "$sitepackage_name" | sed 's/[[\.*^$()+?{|]/\\&/g')
    local escaped_sitepackage_kebab=$(printf '%s\n' "$sitepackage_kebab" | sed 's/[[\.*^$()+?{|]/\\&/g')
    local escaped_sitepackage_pascal=$(printf '%s\n' "$sitepackage_pascal" | sed 's/[[\.*^$()+?{|]/\\&/g')
    local escaped_vendor_name=""
    if [ -n "$vendor_name" ]; then
        escaped_vendor_name=$(printf '%s\n' "$vendor_name" | sed 's/[[\.*^$()+?{|]/\\&/g')
    fi
    
    # Define processable file extensions (comprehensive list for TYPO3 sitepackages)
    local processable_extensions=(
        "php" "yaml" "yml" "json" "html" "htm" 
        "tsconfig" "typoscript" "ts" "md" "txt" 
        "xlf" "xml" "css" "scss" "sass" "less" "js" "mjs"
        "twig" "fluid" "tmpl" "tpl"              # Template files
        "sql" "ini" "conf" "config"              # Configuration files
        "sh" "bash" "zsh" "fish"                 # Shell scripts
        "htaccess" "gitignore" "editorconfig"    # Special config files
        "rst" "textile" "wiki"                   # Documentation formats
        "csv" "tsv" "properties"                 # Data files
        "dockerfile" "makefile"                  # Build files
    )
    
    # Process files with comprehensive error handling and detailed logging
    local file_count=0
    while IFS= read -r -d '' file; do
        file_count=$((file_count + 1))
        
        if [ "$verbose" = "true" ]; then
            echo "$log_prefix Processing file #$file_count: $file"
        fi
        
        # Comprehensive file access validation with detailed error categorization
        local file_status=$(get_file_access_status "$file" "$verbose" "$log_prefix")
        case "$file_status" in
            "permission_denied")
                if [ "$verbose" = "true" ]; then
                    echo "$log_prefix   SKIPPED: Permission denied for file: $file"
                fi
                permission_errors="${permission_errors}\n  - $file (permission denied)"
                files_permission_denied=$((files_permission_denied + 1))
                files_skipped=$((files_skipped + 1))
                has_warnings=true
                continue
                ;;
            "read_only")
                if [ "$verbose" = "true" ]; then
                    echo "$log_prefix   SKIPPED: Read-only file: $file"
                fi
                read_only_errors="${read_only_errors}\n  - $file (read-only)"
                files_read_only=$((files_read_only + 1))
                files_skipped=$((files_skipped + 1))
                has_warnings=true
                continue
                ;;
            "symlink_broken")
                if [ "$verbose" = "true" ]; then
                    echo "$log_prefix   SKIPPED: Broken symbolic link: $file"
                fi
                validation_errors="${validation_errors}\n  - $file (broken symbolic link)"
                files_skipped=$((files_skipped + 1))
                has_warnings=true
                continue
                ;;
            "symlink_not_file")
                if [ "$verbose" = "true" ]; then
                    echo "$log_prefix   SKIPPED: Symbolic link does not point to regular file: $file"
                fi
                files_skipped=$((files_skipped + 1))
                continue
                ;;
            "special_file")
                if [ "$verbose" = "true" ]; then
                    echo "$log_prefix   SKIPPED: Special file type (device/pipe/socket): $file"
                fi
                files_skipped=$((files_skipped + 1))
                continue
                ;;
            "not_regular_file")
                if [ "$verbose" = "true" ]; then
                    echo "$log_prefix   SKIPPED: Not a regular file: $file"
                fi
                files_skipped=$((files_skipped + 1))
                continue
                ;;
            "not_found")
                if [ "$verbose" = "true" ]; then
                    echo "$log_prefix   SKIPPED: File not found: $file"
                fi
                validation_errors="${validation_errors}\n  - $file (file not found)"
                files_failed=$((files_failed + 1))
                has_errors=true
                continue
                ;;
            "accessible")
                # File is accessible, continue with processing
                ;;
            *)
                if [ "$verbose" = "true" ]; then
                    echo "$log_prefix   SKIPPED: Unknown access issue for file: $file"
                fi
                validation_errors="${validation_errors}\n  - $file (unknown access issue: $file_status)"
                files_failed=$((files_failed + 1))
                has_errors=true
                continue
                ;;
        esac
        
        # Check if file should be processed based on type filtering and detection
        local should_process_result=$(should_process_file_with_reason "$file" "processable_extensions" "$verbose" "$log_prefix")
        local should_process_status="${should_process_result%%:*}"
        local should_process_reason="${should_process_result#*:}"
        
        if [ "$should_process_status" != "process" ]; then
            if [ "$verbose" = "true" ]; then
                echo "$log_prefix   SKIPPED: $should_process_reason"
            fi
            
            case "$should_process_status" in
                "binary")
                    files_binary_skipped=$((files_binary_skipped + 1))
                    ;;
                "system")
                    files_system_skipped=$((files_system_skipped + 1))
                    ;;
                *)
                    # Generic skip
                    ;;
            esac
            
            files_skipped=$((files_skipped + 1))
            continue
        fi
        
        if [ "$verbose" = "true" ]; then
            echo "$log_prefix   PROCESSING: $should_process_reason"
        fi
        
        # File processing with comprehensive error handling and replacement tracking
        local replacement_result=$(process_file_replacements_with_stats "$file" "$escaped_sitepackage_name" "$escaped_sitepackage_kebab" "$escaped_sitepackage_pascal" "$escaped_project_name" "$escaped_vendor_name" "$vendor_name" "$verbose" "$log_prefix")
        local process_status="${replacement_result%%:*}"
        local replacement_count="${replacement_result#*:}"
        
        if [ "$process_status" != "success" ]; then
            processing_errors="${processing_errors}\n  - $file ($process_status)"
            has_errors=true
            files_failed=$((files_failed + 1))
            
            if [ "$verbose" = "true" ]; then
                echo "$log_prefix   FAILED: $process_status for file: $file"
            fi
        else
            files_processed=$((files_processed + 1))
            total_replacements_made=$((total_replacements_made + replacement_count))
            
            if [ "$verbose" = "true" ]; then
                echo "$log_prefix   SUCCESS: $replacement_count replacements made in file: $file"
            fi
        fi
        
    done < <(find_processable_files "$source_dir" "$verbose")
    
    # Calculate processing time and generate comprehensive report
    local end_time=$(date +%s)
    local processing_time=$((end_time - start_time))
    local total_files=$((files_processed + files_skipped + files_failed))
    
    # Always show summary report (not just in verbose mode)
    echo "$log_prefix Processing completed in ${processing_time}s"
    echo "$log_prefix Summary:"
    echo "$log_prefix   Total files found: $total_files"
    echo "$log_prefix   Files processed successfully: $files_processed"
    echo "$log_prefix   Files skipped: $files_skipped"
    echo "$log_prefix   Files failed: $files_failed"
    echo "$log_prefix   Total replacements made: $total_replacements_made"
    
    # Detailed breakdown in verbose mode
    if [ "$verbose" = "true" ]; then
        echo "$log_prefix Detailed breakdown:"
        echo "$log_prefix   Permission denied: $files_permission_denied"
        echo "$log_prefix   Read-only files: $files_read_only"
        echo "$log_prefix   Binary files skipped: $files_binary_skipped"
        echo "$log_prefix   System files skipped: $files_system_skipped"
        echo "$log_prefix   Processing time: ${processing_time} seconds"
        
        if [ $total_files -gt 0 ]; then
            local success_rate=$((files_processed * 100 / total_files))
            echo "$log_prefix   Success rate: ${success_rate}%"
        fi
    fi
    
    # Report warnings for non-critical issues
    if [ "$has_warnings" = "true" ]; then
        echo "$log_prefix Warnings encountered:"
        
        if [ -n "$permission_errors" ]; then
            echo "$log_prefix Permission denied files:"
            echo -e "$permission_errors"
        fi
        
        if [ -n "$read_only_errors" ]; then
            echo "$log_prefix Read-only files:"
            echo -e "$read_only_errors"
        fi
        
        echo "$log_prefix Note: Warnings indicate files that were skipped but don't prevent successful completion"
    fi
    
    # Handle critical errors that prevent successful completion
    if [ "$has_errors" = "true" ]; then
        echo "$log_prefix ERRORS encountered:"
        
        if [ -n "$processing_errors" ]; then
            echo "$log_prefix File processing errors:"
            echo -e "$processing_errors"
        fi
        
        if [ -n "$validation_errors" ]; then
            echo "$log_prefix Validation errors:"
            echo -e "$validation_errors"
        fi
        
        echo "$log_prefix Critical errors occurred. Some files could not be processed."
        return 2
    fi
    
    # Verify directory structure integrity before final verification
    local structure_verification_result=$(verify_directory_structure_integrity "$source_dir" "$verbose" "$log_prefix")
    local structure_exit_code=$?
    
    if [ $structure_exit_code -eq 1 ]; then
        echo "$log_prefix CRITICAL: Directory structure integrity check failed"
        return 2
    elif [ $structure_exit_code -eq 2 ]; then
        echo "$log_prefix WARNING: Directory structure integrity issues detected"
        has_warnings=true
    fi
    
    # Comprehensive post-processing verification if processing was successful
    if [ "$files_processed" -gt 0 ]; then
        local verification_result=$(perform_post_processing_verification "$source_dir" "$verbose" "$log_prefix")
        local verification_exit_code=$?
        
        case $verification_exit_code in
            0)
                # Verification passed completely
                echo "$log_prefix Completed successfully"
                return 0
                ;;
            1)
                # Verification passed with warnings
                echo "$log_prefix Completed with warnings (exit code 1)"
                return 1
                ;;
            2)
                # Verification failed with critical issues
                echo "$log_prefix Completed with critical errors (exit code 2)"
                return 2
                ;;
            *)
                # Unexpected verification result
                echo "$log_prefix Verification returned unexpected result (exit code $verification_exit_code)"
                return 2
                ;;
        esac
    else
        # No files were processed, which might indicate an issue
        echo "$log_prefix WARNING: No files were processed - this may indicate a configuration or filtering issue"
        return 1
    fi
}

# Helper function to get detailed file access status for comprehensive error handling
get_file_access_status() {
    local file="$1"
    local verbose="$2"
    local log_prefix="$3"
    
    # Check if file exists (this works for both regular files and symbolic links)
    if [ ! -e "$file" ]; then
        if [ "$verbose" = "true" ]; then
            echo "$log_prefix   File access check: File does not exist - $file" >&2
        fi
        echo "not_found"
        return 0
    fi
    
    # Handle symbolic links specially
    if [ -L "$file" ]; then
        if [ "$verbose" = "true" ]; then
            local link_target=$(readlink "$file")
            echo "$log_prefix   File access check: Symbolic link detected - $file -> $link_target" >&2
        fi
        
        # Check if the symbolic link target exists
        if [ ! -e "$file" ]; then
            if [ "$verbose" = "true" ]; then
                echo "$log_prefix   File access check: Broken symbolic link (target does not exist) - $file" >&2
            fi
            echo "symlink_broken"
            return 0
        fi
        
        # Check if the symbolic link points to a regular file
        if [ ! -f "$file" ]; then
            if [ "$verbose" = "true" ]; then
                echo "$log_prefix   File access check: Symbolic link does not point to regular file - $file" >&2
            fi
            echo "symlink_not_file"
            return 0
        fi
        
        # For symbolic links pointing to regular files, continue with normal checks
        if [ "$verbose" = "true" ]; then
            echo "$log_prefix   File access check: Valid symbolic link to regular file - $file" >&2
        fi
    else
        # Check if it's actually a regular file (not a directory, device, etc.)
        if [ ! -f "$file" ]; then
            if [ "$verbose" = "true" ]; then
                echo "$log_prefix   File access check: Not a regular file - $file" >&2
            fi
            echo "not_regular_file"
            return 0
        fi
    fi
    
    # Check if file is readable
    if [ ! -r "$file" ]; then
        if [ "$verbose" = "true" ]; then
            echo "$log_prefix   File access check: Not readable - $file" >&2
        fi
        echo "permission_denied"
        return 0
    fi
    
    # Check if file is writable (for symbolic links, this checks the target)
    if [ ! -w "$file" ]; then
        if [ "$verbose" = "true" ]; then
            echo "$log_prefix   File access check: Not writable (read-only) - $file" >&2
        fi
        echo "read_only"
        return 0
    fi
    
    # Additional check for special file types that should be skipped
    if [ -c "$file" ] || [ -b "$file" ] || [ -p "$file" ] || [ -S "$file" ]; then
        if [ "$verbose" = "true" ]; then
            echo "$log_prefix   File access check: Special file type (device/pipe/socket) - $file" >&2
        fi
        echo "special_file"
        return 0
    fi
    
    if [ "$verbose" = "true" ]; then
        echo "$log_prefix   File access check: Accessible - $file" >&2
    fi
    echo "accessible"
    return 0
}

# Enhanced helper function to determine if a file should be processed with detailed reasoning
should_process_file_with_reason() {
    local file="$1"
    local extensions_array_name="$2"
    local verbose="$3"
    local log_prefix="$4"
    
    # Get the filename and extension
    local filename=$(basename "$file")
    local extension="${filename##*.}"
    
    # Skip system files and directories that should never be processed
    case "$filename" in
        .DS_Store|.git*|.svn*|.hg*|*.tmp|*.temp|*.bak|*.backup|*.swp|*.swo|*~)
            echo "system:System file ($filename)"
            return
            ;;
    esac
    
    # Skip hidden files (starting with .) except for specific processable ones
    if [[ "$filename" == .* ]] && [[ "$filename" != ".htaccess" ]] && [[ "$filename" != ".editorconfig" ]]; then
        echo "system:Hidden file ($filename)"
        return
    fi
    
    # Skip files without extensions (likely binary or system files)
    if [ "$filename" = "$extension" ]; then
        # Exception for specific files without extensions that should be processed
        case "$filename" in
            README|LICENSE|CHANGELOG|Makefile|Dockerfile)
                # Still do binary check for these files
                if ! is_text_file "$file" "$verbose"; then
                    echo "binary:Special file detected as binary ($filename)"
                    return
                fi
                echo "process:Special text file without extension ($filename)"
                return
                ;;
            *)
                echo "system:File without extension ($filename)"
                return
                ;;
        esac
    fi
    
    # Convert extension to lowercase for comparison
    extension=$(echo "$extension" | tr '[:upper:]' '[:lower:]')
    
    # Check if extension is in the processable extensions list
    local extension_found=false
    eval "local extensions_array=(\"\${${extensions_array_name}[@]}\")"
    for processable_ext in "${extensions_array[@]}"; do
        if [ "$extension" = "$processable_ext" ]; then
            extension_found=true
            break
        fi
    done
    
    # If extension is not in the list, use file command as fallback to detect binary files
    if [ "$extension_found" = "false" ]; then
        # Use binary file detection as fallback
        if is_text_file "$file" "$verbose"; then
            echo "process:Text file detected by file command (.$extension)"
            return
        else
            echo "binary:Binary file detected by file command (.$extension)"
            return
        fi
    fi
    
    # Extension is in processable list, but do a final binary check for safety
    if ! is_text_file "$file" "$verbose"; then
        echo "binary:Binary file despite processable extension (.$extension)"
        return
    fi
    
    echo "process:Processable text file (.$extension)"
}

# Helper function to determine if a file should be processed based on type filtering
should_process_file() {
    local file="$1"
    local extensions_array_name="$2"
    local verbose="$3"
    
    # Get the filename and extension
    local filename=$(basename "$file")
    local extension="${filename##*.}"
    
    # Skip system files and directories that should never be processed
    case "$filename" in
        .DS_Store|.git*|.svn*|.hg*|*.tmp|*.temp|*.bak|*.backup|*.swp|*.swo|*~)
            if [ "$verbose" = "true" ]; then
                echo "Skipping system file: $file"
            fi
            return 1
            ;;
    esac
    
    # Skip hidden files (starting with .) except for specific processable ones
    if [[ "$filename" == .* ]] && [[ "$filename" != ".htaccess" ]] && [[ "$filename" != ".editorconfig" ]]; then
        if [ "$verbose" = "true" ]; then
            echo "Skipping hidden file: $file"
        fi
        return 1
    fi
    
    # Skip files without extensions (likely binary or system files)
    if [ "$filename" = "$extension" ]; then
        # Exception for specific files without extensions that should be processed
        case "$filename" in
            README|LICENSE|CHANGELOG|Makefile|Dockerfile)
                if [ "$verbose" = "true" ]; then
                    echo "Processing special file without extension: $file"
                fi
                # Still do binary check for these files
                if ! is_text_file "$file" "$verbose"; then
                    return 1
                fi
                return 0
                ;;
            *)
                if [ "$verbose" = "true" ]; then
                    echo "Skipping file without extension: $file"
                fi
                return 1
                ;;
        esac
    fi
    
    # Convert extension to lowercase for comparison
    extension=$(echo "$extension" | tr '[:upper:]' '[:lower:]')
    
    # Check if extension is in the processable extensions list
    local extension_found=false
    eval "local extensions_array=(\"\${${extensions_array_name}[@]}\")"
    for processable_ext in "${extensions_array[@]}"; do
        if [ "$extension" = "$processable_ext" ]; then
            extension_found=true
            break
        fi
    done
    
    # If extension is not in the list, use file command as fallback to detect binary files
    if [ "$extension_found" = "false" ]; then
        if [ "$verbose" = "true" ]; then
            echo "Extension '$extension' not in processable list, checking file type for: $file"
        fi
        
        # Use binary file detection as fallback
        if is_text_file "$file" "$verbose"; then
            if [ "$verbose" = "true" ]; then
                echo "Processing text file (detected by file command): $file"
            fi
            return 0
        else
            if [ "$verbose" = "true" ]; then
                echo "Skipping binary file (detected by file command): $file"
            fi
            return 1
        fi
    fi
    
    # Extension is in processable list, but do a final binary check for safety
    if ! is_text_file "$file" "$verbose"; then
        if [ "$verbose" = "true" ]; then
            echo "Skipping binary file despite processable extension: $file"
        fi
        return 1
    fi
    
    if [ "$verbose" = "true" ]; then
        echo "File will be processed: $file"
    fi
    return 0
}

# Helper function to detect if a file is text-based using file command
is_text_file() {
    local file="$1"
    local verbose="$2"
    
    # Check if file command is available
    if ! command -v file >/dev/null 2>&1; then
        if [ "$verbose" = "true" ]; then
            echo "Warning: 'file' command not available, assuming text file: $file"
        fi
        # If file command is not available, assume it's text (conservative approach for known extensions)
        return 0
    fi
    
    # Get file type information
    local file_type=$(file -b "$file" 2>/dev/null)
    local file_mime=$(file -b --mime-type "$file" 2>/dev/null)
    
    # Check for empty files (should be processed)
    if [ ! -s "$file" ]; then
        if [ "$verbose" = "true" ]; then
            echo "Empty file detected (will process): $file"
        fi
        return 0
    fi
    
    # Check MIME type first (more reliable)
    if [ -n "$file_mime" ]; then
        case "$file_mime" in
            text/*|application/json|application/xml|application/javascript|application/x-yaml)
                return 0
                ;;
            application/octet-stream)
                # Fall through to content-based detection for octet-stream
                ;;
            *)
                # Non-text MIME type
                return 1
                ;;
        esac
    fi
    
    # Check file type description as fallback
    if [ -n "$file_type" ]; then
        case "$file_type" in
            *text*|*ASCII*|*UTF-8*|*UTF-16*|*Unicode*|*empty*|*JSON*|*XML*|*HTML*|*script*)
                return 0
                ;;
            *binary*|*executable*|*archive*|*compressed*|*image*|*audio*|*video*|*font*|*PDF*)
                return 1
                ;;
            *data*)
                # For generic "data" files, do additional checks
                # Try to read first few bytes to see if they're printable
                if head -c 512 "$file" 2>/dev/null | LC_ALL=C grep -q '[^[:print:][:space:]]'; then
                    # Contains non-printable characters, likely binary
                    return 1
                else
                    # Only printable characters, likely text
                    return 0
                fi
                ;;
        esac
    fi
    
    # Final fallback: check if file contains mostly printable characters
    if head -c 512 "$file" 2>/dev/null | LC_ALL=C grep -q '[^[:print:][:space:]]'; then
        # Contains non-printable characters, likely binary
        return 1
    else
        # Only printable characters, likely text
        return 0
    fi
}

# Helper function to find processable files with proper directory traversal and exclusions
find_processable_files() {
    local source_dir="$1"
    local verbose="$2"
    
    # Define directories and patterns to exclude from traversal
    local exclude_dirs=(
        ".git" ".svn" ".hg" ".bzr"           # Version control
        "node_modules" "vendor" ".composer"  # Package managers
        ".cache" ".tmp" "tmp" "temp"         # Cache and temp directories
        "build" "dist" ".build"              # Build directories
        ".ddev" ".docker"                    # Development containers
        "__pycache__" ".pytest_cache"       # Python cache
        ".idea" ".vscode" ".vs"              # IDE directories
        "coverage" ".nyc_output"             # Test coverage
    )
    
    # Define file patterns to exclude
    local exclude_patterns=(
        "*.log" "*.pid" "*.lock"             # Runtime files
        "*.zip" "*.tar" "*.gz" "*.bz2"       # Archives
        "*.jpg" "*.jpeg" "*.png" "*.gif"     # Images
        "*.svg" "*.ico" "*.webp"             # Vector/web images
        "*.pdf" "*.doc" "*.docx"             # Documents
        "*.mp3" "*.mp4" "*.avi" "*.mov"      # Media files
        "*.exe" "*.dll" "*.so" "*.dylib"     # Executables/libraries
        "*.class" "*.jar" "*.war"            # Java binaries
        "*.pyc" "*.pyo" "*.pyd"              # Python binaries
        "*.o" "*.obj" "*.a" "*.lib"          # Compiled objects
        "*.min.js" "*.min.css"               # Minified assets
        "*.map" "*.d.ts"                     # Source maps and type definitions
    )
    
    # Build find command with exclusions
    local find_cmd="find \"$source_dir\" -type f"
    
    # Add directory exclusions
    for exclude_dir in "${exclude_dirs[@]}"; do
        find_cmd="$find_cmd -not -path \"*/$exclude_dir/*\""
    done
    
    # Add file pattern exclusions
    for exclude_pattern in "${exclude_patterns[@]}"; do
        find_cmd="$find_cmd -not -name \"$exclude_pattern\""
    done
    
    # Add null terminator for safe handling of filenames with spaces
    find_cmd="$find_cmd -print0"
    
    if [ "$verbose" = "true" ]; then
        echo "Directory traversal command: $find_cmd" >&2
    fi
    
    # Execute the find command
    eval "$find_cmd"
}

# Enhanced helper function to process individual file replacements with detailed statistics
process_file_replacements_with_stats() {
    local file="$1"
    local escaped_sitepackage_name="$2"
    local escaped_sitepackage_kebab="$3"
    local escaped_sitepackage_pascal="$4"
    local escaped_project_name="$5"
    local escaped_vendor_name="$6"
    local original_vendor_name="$7"
    local verbose="$8"
    local log_prefix="${9}"
    
    # Handle symbolic links - process the target, not the link itself
    if [ -L "$file" ]; then
        if [ "$verbose" = "true" ]; then
            local link_target=$(readlink "$file")
            echo "$log_prefix     Processing symbolic link: $file -> $link_target" >&2
        fi
        
        # Check if the symbolic link target exists and is accessible
        if [ ! -e "$file" ]; then
            echo "symlink_broken:Symbolic link target does not exist"
            return
        fi
        
        if [ ! -f "$file" ]; then
            echo "symlink_not_file:Symbolic link does not point to a regular file"
            return
        fi
        
        # For symbolic links, we process the target file directly
        # The link itself will remain unchanged, preserving the link structure
        if [ "$verbose" = "true" ]; then
            echo "$log_prefix     Processing symbolic link target directly" >&2
        fi
    fi
    
    # Preserve original file permissions and metadata
    local original_permissions=""
    local original_owner=""
    local original_group=""
    
    # Get original file permissions using stat command (cross-platform approach)
    if command -v stat >/dev/null 2>&1; then
        # Try GNU stat first (Linux)
        if stat --version >/dev/null 2>&1; then
            original_permissions=$(stat -c "%a" "$file" 2>/dev/null)
            original_owner=$(stat -c "%U" "$file" 2>/dev/null)
            original_group=$(stat -c "%G" "$file" 2>/dev/null)
        else
            # BSD stat (macOS)
            original_permissions=$(stat -f "%Lp" "$file" 2>/dev/null)
            original_owner=$(stat -f "%Su" "$file" 2>/dev/null)
            original_group=$(stat -f "%Sg" "$file" 2>/dev/null)
        fi
    fi
    
    if [ "$verbose" = "true" ] && [ -n "$original_permissions" ]; then
        echo "$log_prefix     Original file permissions: $original_permissions (owner: $original_owner, group: $original_group)" >&2
    fi
    
    # Create temporary file for safe processing with better error handling
    local temp_file="${file}.tmp.$$"
    local backup_file="${file}.backup.$$"
    
    # Create backup of original file for rollback capability
    if ! cp "$file" "$backup_file" 2>/dev/null; then
        echo "backup_failed:Could not create backup"
        return
    fi
    
    # Copy original file to temp file for processing, preserving permissions
    if ! cp "$file" "$temp_file" 2>/dev/null; then
        rm -f "$backup_file" 2>/dev/null
        echo "temp_file_failed:Could not create temporary file"
        return
    fi
    
    # Define replacement patterns using delimited strings for bash 3.2+ compatibility
    # Order is critical: compound patterns first, then vendor, then standalone
    # Format: "pattern1|replacement1|pattern2|replacement2|..."
    local compound_patterns_data="xxxx_sitepackage|$escaped_sitepackage_name|xxxx-sitepackage|$escaped_sitepackage_kebab|XxxxSitepackage|$escaped_sitepackage_pascal"
    
    # Track replacement statistics for this file with detailed breakdown (bash 3.2+ compatible)
    local total_file_replacements=0
    local xxxx_sitepackage_count=0
    local xxxx_sitepackage_kebab_count=0
    local XxxxSitepackage_count=0
    local skom_count=0
    local xxxx_count=0
    
    # Process compound patterns using simple, portable approach (bash 3.2+ compatible)
    # Process each pattern individually for maximum compatibility
    
    # Process xxxx_sitepackage pattern
    if [ "$verbose" = "true" ]; then
        echo "$log_prefix     Replacing pattern: 'xxxx_sitepackage' -> '$escaped_sitepackage_name'" >&2
    fi
    
    local xxxx_sitepackage_count=0
    if command -v grep >/dev/null 2>&1; then
        xxxx_sitepackage_count=$(grep -o "xxxx_sitepackage" "$temp_file" 2>/dev/null | wc -l | tr -d ' ')
    fi
    
    if ! portable_sed "replace_in_place" "xxxx_sitepackage" "$escaped_sitepackage_name" "$temp_file"; then
        rm -f "$temp_file" "$backup_file" 2>/dev/null
        echo "sed_failed:Failed to replace xxxx_sitepackage pattern"
        return
    fi
    
    total_file_replacements=$((total_file_replacements + xxxx_sitepackage_count))
    
    if [ "$verbose" = "true" ] && [ "$xxxx_sitepackage_count" -gt 0 ]; then
        echo "$log_prefix     Made $xxxx_sitepackage_count replacements for pattern 'xxxx_sitepackage'" >&2
    fi
    
    # Process xxxx-sitepackage pattern
    if [ "$verbose" = "true" ]; then
        echo "$log_prefix     Replacing pattern: 'xxxx-sitepackage' -> '$escaped_sitepackage_kebab'" >&2
    fi
    
    local xxxx_sitepackage_kebab_count=0
    if command -v grep >/dev/null 2>&1; then
        xxxx_sitepackage_kebab_count=$(grep -o "xxxx-sitepackage" "$temp_file" 2>/dev/null | wc -l | tr -d ' ')
    fi
    
    if ! portable_sed "replace_in_place" "xxxx-sitepackage" "$escaped_sitepackage_kebab" "$temp_file"; then
        rm -f "$temp_file" "$backup_file" 2>/dev/null
        echo "sed_failed:Failed to replace xxxx-sitepackage pattern"
        return
    fi
    
    total_file_replacements=$((total_file_replacements + xxxx_sitepackage_kebab_count))
    
    if [ "$verbose" = "true" ] && [ "$xxxx_sitepackage_kebab_count" -gt 0 ]; then
        echo "$log_prefix     Made $xxxx_sitepackage_kebab_count replacements for pattern 'xxxx-sitepackage'" >&2
    fi
    
    # Process XxxxSitepackage pattern
    if [ "$verbose" = "true" ]; then
        echo "$log_prefix     Replacing pattern: 'XxxxSitepackage' -> '$escaped_sitepackage_pascal'" >&2
    fi
    
    local XxxxSitepackage_count=0
    if command -v grep >/dev/null 2>&1; then
        XxxxSitepackage_count=$(grep -o "XxxxSitepackage" "$temp_file" 2>/dev/null | wc -l | tr -d ' ')
    fi
    
    if ! portable_sed "replace_in_place" "XxxxSitepackage" "$escaped_sitepackage_pascal" "$temp_file"; then
        rm -f "$temp_file" "$backup_file" 2>/dev/null
        echo "sed_failed:Failed to replace XxxxSitepackage pattern"
        return
    fi
    
    total_file_replacements=$((total_file_replacements + XxxxSitepackage_count))
    
    if [ "$verbose" = "true" ] && [ "$XxxxSitepackage_count" -gt 0 ]; then
        echo "$log_prefix     Made $XxxxSitepackage_count replacements for pattern 'XxxxSitepackage'" >&2
    fi
    
    # Process vendor pattern if provided and different from placeholder
    if [ -n "$escaped_vendor_name" ] && [ "$original_vendor_name" != "skom" ]; then
        if [ "$verbose" = "true" ]; then
            echo "$log_prefix     Replacing vendor pattern: 'skom' -> '$escaped_vendor_name'" >&2
        fi
        
        # Count vendor pattern occurrences
        local skom_count=0
        if command -v grep >/dev/null 2>&1; then
            skom_count=$(grep -o "skom" "$temp_file" 2>/dev/null | wc -l | tr -d ' ')
        fi
        
        if ! portable_sed "replace_in_place" "skom" "$escaped_vendor_name" "$temp_file"; then
            rm -f "$temp_file" "$backup_file" 2>/dev/null
            echo "sed_failed:Failed to replace skom pattern"
            return
        fi
        
        total_file_replacements=$((total_file_replacements + skom_count))
        
        if [ "$verbose" = "true" ] && [ "$skom_count" -gt 0 ]; then
            echo "$log_prefix     Made $skom_count vendor replacements" >&2
        fi
    fi
    
    # Process standalone xxxx pattern last (after compound patterns to avoid conflicts)
    if [ "$verbose" = "true" ]; then
        echo "$log_prefix     Replacing standalone pattern: 'xxxx' -> '$escaped_project_name'" >&2
    fi
    
    # Count standalone xxxx occurrences
    local xxxx_count=0
    if command -v grep >/dev/null 2>&1; then
        xxxx_count=$(grep -o "xxxx" "$temp_file" 2>/dev/null | wc -l | tr -d ' ')
    fi
    
    if ! portable_sed "replace_in_place" "xxxx" "$escaped_project_name" "$temp_file"; then
        rm -f "$temp_file" "$backup_file" 2>/dev/null
        echo "sed_failed:Failed to replace xxxx pattern"
        return
    fi
    
    total_file_replacements=$((total_file_replacements + xxxx_count))
    
    if [ "$verbose" = "true" ] && [ "$xxxx_count" -gt 0 ]; then
        echo "$log_prefix     Made $xxxx_count standalone replacements" >&2
    fi
    
    # Verify file integrity before replacing original
    if [ ! -s "$temp_file" ] && [ -s "$file" ]; then
        # Temp file is empty but original wasn't - something went wrong
        rm -f "$temp_file" "$backup_file" 2>/dev/null
        echo "integrity_failed:Processed file is empty but original was not"
        return
    fi
    
    # Replace original file with processed version
    if ! mv "$temp_file" "$file" 2>/dev/null; then
        # Restore from backup if move failed
        cp "$backup_file" "$file" 2>/dev/null
        rm -f "$temp_file" "$backup_file" 2>/dev/null
        echo "move_failed:Could not replace original file"
        return
    fi
    
    # Restore original file permissions and ownership if we captured them
    if [ -n "$original_permissions" ]; then
        if [ "$verbose" = "true" ]; then
            echo "$log_prefix     Restoring file permissions: $original_permissions" >&2
        fi
        
        # Restore permissions using chmod
        if ! chmod "$original_permissions" "$file" 2>/dev/null; then
            if [ "$verbose" = "true" ]; then
                echo "$log_prefix     Warning: Could not restore file permissions for $file" >&2
            fi
        fi
        
        # Attempt to restore ownership if we have the information and sufficient privileges
        # Note: This will typically only work if running as root or the file owner
        if [ -n "$original_owner" ] && [ -n "$original_group" ]; then
            if command -v chown >/dev/null 2>&1; then
                if chown "$original_owner:$original_group" "$file" 2>/dev/null; then
                    if [ "$verbose" = "true" ]; then
                        echo "$log_prefix     Restored file ownership: $original_owner:$original_group" >&2
                    fi
                else
                    if [ "$verbose" = "true" ]; then
                        echo "$log_prefix     Note: Could not restore file ownership (insufficient privileges or owner/group not found)" >&2
                    fi
                fi
            fi
        fi
        
        if [ "$verbose" = "true" ]; then
            echo "$log_prefix     File permissions and structure preserved" >&2
        fi
    fi
    
    # Clean up backup file
    rm -f "$backup_file" 2>/dev/null
    
    if [ "$verbose" = "true" ]; then
        echo "$log_prefix     File processing complete: $total_file_replacements total replacements" >&2
        if [ "$total_file_replacements" -gt 0 ]; then
            # Report pattern-specific statistics (bash 3.2+ compatible)
            if [ "$xxxx_sitepackage_count" -gt 0 ]; then
                echo "$log_prefix       xxxx_sitepackage: $xxxx_sitepackage_count replacements" >&2
            fi
            if [ "$xxxx_sitepackage_kebab_count" -gt 0 ]; then
                echo "$log_prefix       xxxx-sitepackage: $xxxx_sitepackage_kebab_count replacements" >&2
            fi
            if [ "$XxxxSitepackage_count" -gt 0 ]; then
                echo "$log_prefix       XxxxSitepackage: $XxxxSitepackage_count replacements" >&2
            fi
            if [ "$skom_count" -gt 0 ]; then
                echo "$log_prefix       skom: $skom_count replacements" >&2
            fi
            if [ "$xxxx_count" -gt 0 ]; then
                echo "$log_prefix       xxxx: $xxxx_count replacements" >&2
            fi
        fi
    fi
    
    echo "success:$total_file_replacements"
}

# Comprehensive validation function to check all required parameters are provided
validate_replacement_parameters() {
    local source_dir="$1"
    local project_name="$2"
    local sitepackage_name="$3"
    local sitepackage_kebab="$4"
    local sitepackage_pascal="$5"
    local vendor_name="$6"
    local verbose="$7"
    local log_prefix="$8"
    
    local validation_errors=""
    local has_errors=false
    
    if [ "$verbose" = "true" ]; then
        echo "$log_prefix Starting parameter validation..." >&2
    fi
    
    # Check required parameters
    if [ -z "$source_dir" ]; then
        validation_errors="$validation_errors\n  - Source directory parameter is missing or empty"
        has_errors=true
    fi
    
    if [ -z "$project_name" ]; then
        validation_errors="$validation_errors\n  - Project name parameter is missing or empty"
        has_errors=true
    fi
    
    if [ -z "$sitepackage_name" ]; then
        validation_errors="$validation_errors\n  - Sitepackage name parameter is missing or empty"
        has_errors=true
    fi
    
    if [ -z "$sitepackage_kebab" ]; then
        validation_errors="$validation_errors\n  - Sitepackage kebab-case parameter is missing or empty"
        has_errors=true
    fi
    
    if [ -z "$sitepackage_pascal" ]; then
        validation_errors="$validation_errors\n  - Sitepackage PascalCase parameter is missing or empty"
        has_errors=true
    fi
    
    # Validate parameter formats and constraints
    if [ -n "$project_name" ]; then
        # Improved project name validation - allow hyphens, underscores, and alphanumeric
        if [[ ! "$project_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            validation_errors="$validation_errors\n  - Project name must contain only alphanumeric characters, underscores, and hyphens: '$project_name'"
            has_errors=true
        fi
        
        # Smart placeholder conflict check - warn but don't fail if intentional
        if [[ "$project_name" == *"xxxx"* ]]; then
            if [ "$verbose" = "true" ]; then
                echo "$log_prefix WARNING: Project name contains 'xxxx' pattern - this may cause unexpected replacements: '$project_name'" >&2
            fi
            # This is a warning, not an error for flexibility
        fi
    fi
    
    if [ -n "$sitepackage_name" ]; then
        # Validate sitepackage name format
        if [[ ! "$sitepackage_name" =~ ^[a-zA-Z0-9_]+$ ]]; then
            validation_errors="$validation_errors\n  - Sitepackage name must contain only alphanumeric characters and underscores: '$sitepackage_name'"
            has_errors=true
        fi
        
        if [[ "$sitepackage_name" == *"xxxx"* ]]; then
            validation_errors="$validation_errors\n  - Sitepackage name cannot contain 'xxxx' placeholder pattern: '$sitepackage_name'"
            has_errors=true
        fi
    fi
    
    if [ -n "$sitepackage_kebab" ]; then
        # Validate kebab-case format
        if [[ ! "$sitepackage_kebab" =~ ^[a-zA-Z0-9-]+$ ]]; then
            validation_errors="$validation_errors\n  - Sitepackage kebab-case must contain only alphanumeric characters and hyphens: '$sitepackage_kebab'"
            has_errors=true
        fi
        
        if [[ "$sitepackage_kebab" == *"xxxx"* ]]; then
            validation_errors="$validation_errors\n  - Sitepackage kebab-case cannot contain 'xxxx' placeholder pattern: '$sitepackage_kebab'"
            has_errors=true
        fi
    fi
    
    if [ -n "$sitepackage_pascal" ]; then
        # Validate PascalCase format
        if [[ ! "$sitepackage_pascal" =~ ^[A-Z][a-zA-Z0-9]*$ ]]; then
            validation_errors="$validation_errors\n  - Sitepackage PascalCase must start with uppercase letter and contain only alphanumeric characters: '$sitepackage_pascal'"
            has_errors=true
        fi
        
        if [[ "$sitepackage_pascal" == *"xxxx"* ]] || [[ "$sitepackage_pascal" == *"Xxxx"* ]]; then
            validation_errors="$validation_errors\n  - Sitepackage PascalCase cannot contain 'xxxx' placeholder patterns: '$sitepackage_pascal'"
            has_errors=true
        fi
    fi
    
    if [ -n "$vendor_name" ]; then
        # Flexible vendor name validation - allow matching placeholder if intentional
        if [[ "$vendor_name" == *"skom"* ]] && [ "$vendor_name" != "skom" ]; then
            if [ "$verbose" = "true" ]; then
                echo "$log_prefix WARNING: Vendor name contains 'skom' pattern - this may cause unexpected replacements: '$vendor_name'" >&2
            fi
            # This is a warning, not an error for flexibility
        fi
        
        if [[ ! "$vendor_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            validation_errors="$validation_errors\n  - Vendor name must contain only alphanumeric characters, underscores, and hyphens: '$vendor_name'"
            has_errors=true
        fi
    fi
    
    # Smart cross-validation: warn about potential conflicts but don't fail
    if [ -n "$project_name" ] && [ -n "$sitepackage_name" ]; then
        if [[ "$sitepackage_name" == *"$project_name"* ]] && [[ "$sitepackage_name" == *"xxxx"* ]]; then
            if [ "$verbose" = "true" ]; then
                echo "$log_prefix WARNING: Sitepackage name contains both project name and placeholder patterns - verify this is intentional: '$sitepackage_name'" >&2
            fi
            # This is a warning, not an error for flexibility
        fi
    fi
    
    # Smart validation: warn about identical placeholder and replacement values but don't fail
    # Use bash 3.2+ compatible approach instead of associative arrays
    if [ -n "$project_name" ] && [ "$project_name" = "xxxx" ]; then
        if [ "$verbose" = "true" ]; then
            echo "$log_prefix WARNING: Replacement value is identical to placeholder pattern 'xxxx' - this may be intentional" >&2
        fi
        # This is a warning, not an error - continue processing
    fi
    
    if [ -n "$vendor_name" ] && [ "$vendor_name" = "skom" ]; then
        if [ "$verbose" = "true" ]; then
            echo "$log_prefix WARNING: Replacement value is identical to placeholder pattern 'skom' - this may be intentional" >&2
        fi
        # This is a warning, not an error - continue processing
    fi
    
    # Directory validation
    if [ -n "$source_dir" ]; then
        if [ ! -d "$source_dir" ]; then
            validation_errors="$validation_errors\n  - Source directory does not exist: '$source_dir'"
            has_errors=true
        elif [ ! -r "$source_dir" ]; then
            validation_errors="$validation_errors\n  - Source directory is not readable: '$source_dir'"
            has_errors=true
        elif [ ! -w "$source_dir" ]; then
            validation_errors="$validation_errors\n  - Source directory is not writable: '$source_dir'"
            has_errors=true
        fi
    fi
    
    if [ "$has_errors" = "true" ]; then
        echo "validation_failed"
        if [ -n "$validation_errors" ]; then
            echo -e "$validation_errors"
        fi
        return 1
    fi
    
    if [ "$verbose" = "true" ]; then
        echo "$log_prefix Parameter validation completed successfully" >&2
    fi
    
    echo "validation_passed"
    return 0
}

# Enhanced function to find remaining placeholders with detailed file locations and context
find_remaining_placeholders() {
    local source_dir="$1"
    local verbose="$2"
    local log_prefix="$3"
    
    if [ "$verbose" = "true" ]; then
        echo "$log_prefix Starting comprehensive placeholder verification..."
    fi
    
    # Define comprehensive patterns to search for with descriptions (bash 3.2+ compatible)
    # Format: "pattern1|description1|pattern2|description2|..."
    local search_patterns_data="xxxx_sitepackage|Compound sitepackage placeholder (underscore)|xxxx-sitepackage|Compound sitepackage placeholder (kebab-case)|XxxxSitepackage|Compound sitepackage placeholder (PascalCase)|\\bxxxx\\b|Standalone project name placeholder|\\bskom\\b|Vendor name placeholder"
    
    local remaining_found=""
    local total_remaining_files=0
    local total_remaining_occurrences=0
    
    # Get list of processable file extensions for verification
    local processable_extensions=(
        "php" "yaml" "yml" "json" "html" "htm" 
        "tsconfig" "typoscript" "ts" "md" "txt" 
        "xlf" "xml" "css" "scss" "sass" "less" "js" "mjs"
        "twig" "fluid" "tmpl" "tpl"
        "sql" "ini" "conf" "config"
        "sh" "bash" "zsh" "fish"
        "htaccess" "gitignore" "editorconfig"
        "rst" "textile" "wiki"
        "csv" "tsv" "properties"
        "dockerfile" "makefile"
    )
    
    # Build find command for processable files
    local find_extensions=""
    for ext in "${processable_extensions[@]}"; do
        if [ -n "$find_extensions" ]; then
            find_extensions="$find_extensions -o"
        fi
        find_extensions="$find_extensions -name \"*.$ext\""
    done
    
    # Add special files without extensions
    find_extensions="$find_extensions -o -name \"README\" -o -name \"LICENSE\" -o -name \"CHANGELOG\" -o -name \"Makefile\" -o -name \"Dockerfile\""
    
    # Search for each pattern in processable files (bash 3.2+ compatible)
    local IFS='|'
    local search_array=($search_patterns_data)
    local i=0
    while [ $i -lt ${#search_array[@]} ]; do
        local pattern="${search_array[$i]}"
        local pattern_description="${search_array[$((i + 1))]}"
        
        if [ "$verbose" = "true" ]; then
            echo "$log_prefix   Checking for pattern: $pattern ($pattern_description)"
        fi
        
        # Use find with grep to search only in processable files
        local pattern_matches=""
        local pattern_files=0
        local pattern_occurrences=0
        
        if command -v grep >/dev/null 2>&1; then
            # Find files containing the pattern with line numbers and context
            local find_cmd="find \"$source_dir\" -type f \\( $find_extensions \\) -exec grep -l \"$pattern\" {} \\; 2>/dev/null"
            pattern_matches=$(eval "$find_cmd")
            
            if [ -n "$pattern_matches" ]; then
                # Count files and occurrences
                pattern_files=$(echo "$pattern_matches" | wc -l | tr -d ' ')
                
                # Get detailed information for each file
                local detailed_matches=""
                while IFS= read -r file; do
                    if [ -n "$file" ]; then
                        # Count occurrences in this file and get line numbers
                        local file_occurrences=$(grep -c "$pattern" "$file" 2>/dev/null || echo "0")
                        local line_numbers=$(grep -n "$pattern" "$file" 2>/dev/null | cut -d: -f1 | tr '\n' ',' | sed 's/,$//')
                        
                        pattern_occurrences=$((pattern_occurrences + file_occurrences))
                        detailed_matches="$detailed_matches\n    $file (lines: $line_numbers, count: $file_occurrences)"
                    fi
                done <<< "$pattern_matches"
                
                remaining_found="$remaining_found\n  Pattern '$pattern' ($pattern_description):"
                remaining_found="$remaining_found\n    Files affected: $pattern_files"
                remaining_found="$remaining_found\n    Total occurrences: $pattern_occurrences"
                remaining_found="$remaining_found$detailed_matches\n"
                
                total_remaining_files=$((total_remaining_files + pattern_files))
                total_remaining_occurrences=$((total_remaining_occurrences + pattern_occurrences))
            fi
        else
            if [ "$verbose" = "true" ]; then
                echo "$log_prefix   Warning: grep command not available, skipping pattern verification"
            fi
        fi
        
        i=$((i + 2))  # Move to next pattern-description pair
    done
    
    # Generate summary report
    if [ -n "$remaining_found" ]; then
        local summary_report=""
        summary_report="$summary_report\nPLACEHOLDER VERIFICATION FAILED:"
        summary_report="$summary_report\n  Total files with remaining placeholders: $total_remaining_files"
        summary_report="$summary_report\n  Total remaining placeholder occurrences: $total_remaining_occurrences"
        summary_report="$summary_report\n\nDetailed breakdown:"
        summary_report="$summary_report$remaining_found"
        
        echo -e "$summary_report"
        return 1
    else
        if [ "$verbose" = "true" ]; then
            echo "$log_prefix Placeholder verification completed successfully - no remaining placeholders found"
        fi
        return 0
    fi
}

# File integrity verification function to ensure no corruption occurred during processing
verify_file_integrity() {
    local source_dir="$1"
    local verbose="$2"
    local log_prefix="$3"
    
    if [ "$verbose" = "true" ]; then
        echo "$log_prefix Starting file integrity verification..."
    fi
    
    local integrity_issues=""
    local files_checked=0
    local files_with_issues=0
    
    # Find all files that should have been processed
    while IFS= read -r -d '' file; do
        files_checked=$((files_checked + 1))
        
        # Check if file is a symbolic link and handle appropriately
        if [ -L "$file" ]; then
            # Check if symbolic link is valid (target exists)
            if [ ! -e "$file" ]; then
                integrity_issues="$integrity_issues\n  - Broken symbolic link (target does not exist): $file"
                files_with_issues=$((files_with_issues + 1))
                continue
            fi
            
            # For symbolic links, check if the target is readable
            if [ ! -r "$file" ]; then
                integrity_issues="$integrity_issues\n  - Symbolic link target not readable: $file"
                files_with_issues=$((files_with_issues + 1))
                continue
            fi
            
            if [ "$verbose" = "true" ]; then
                local link_target=$(readlink "$file")
                echo "$log_prefix   Verified symbolic link: $file -> $link_target"
            fi
        else
            # Check if regular file is readable
            if [ ! -r "$file" ]; then
                integrity_issues="$integrity_issues\n  - File not readable: $file"
                files_with_issues=$((files_with_issues + 1))
                continue
            fi
        fi
        
        # Check if file is empty when it shouldn't be (basic integrity check)
        if [ ! -s "$file" ]; then
            # Check if this file should be empty by examining its extension
            local filename=$(basename "$file")
            local extension="${filename##*.}"
            
            # Skip empty check for files that can legitimately be empty
            case "$extension" in
                gitkeep|gitignore|htaccess)
                    # These files can be empty
                    ;;
                *)
                    # For other files, being empty might indicate corruption
                    if [ "$verbose" = "true" ]; then
                        echo "$log_prefix   Warning: File is empty (may indicate processing issue): $file"
                    fi
                    integrity_issues="$integrity_issues\n  - File is unexpectedly empty: $file"
                    files_with_issues=$((files_with_issues + 1))
                    ;;
            esac
        fi
        
        # Check for basic file corruption indicators
        # Look for null bytes or other corruption indicators in text files
        if is_text_file "$file" "$verbose"; then
            if grep -q $'\0' "$file" 2>/dev/null; then
                integrity_issues="$integrity_issues\n  - File contains null bytes (possible corruption): $file"
                files_with_issues=$((files_with_issues + 1))
            fi
        fi
        
    done < <(find_processable_files "$source_dir" "$verbose")
    
    if [ "$verbose" = "true" ]; then
        echo "$log_prefix File integrity check completed:"
        echo "$log_prefix   Files checked: $files_checked"
        echo "$log_prefix   Files with issues: $files_with_issues"
    fi
    
    if [ "$files_with_issues" -gt 0 ]; then
        echo -e "\nFILE INTEGRITY ISSUES DETECTED:$integrity_issues"
        return 1
    fi
    
    if [ "$verbose" = "true" ]; then
        echo "$log_prefix File integrity verification passed - no issues detected"
    fi
    
    return 0
}

# Function to verify directory structure integrity during processing
verify_directory_structure_integrity() {
    local source_dir="$1"
    local verbose="$2"
    local log_prefix="$3"
    
    if [ "$verbose" = "true" ]; then
        echo "$log_prefix Verifying directory structure integrity..."
    fi
    
    # Check if the source directory still exists and is accessible
    if [ ! -d "$source_dir" ]; then
        echo "$log_prefix ERROR: Source directory no longer exists or is not accessible: $source_dir"
        return 1
    fi
    
    # Verify essential TYPO3 sitepackage directories exist
    local essential_dirs=(
        "Classes"
        "Configuration"
        "Resources"
        "Resources/Private"
        "Resources/Public"
    )
    
    local missing_dirs=""
    local dirs_checked=0
    
    for dir in "${essential_dirs[@]}"; do
        local full_path="$source_dir/$dir"
        dirs_checked=$((dirs_checked + 1))
        
        if [ ! -d "$full_path" ]; then
            missing_dirs="$missing_dirs\n  - $dir"
            if [ "$verbose" = "true" ]; then
                echo "$log_prefix   Missing essential directory: $dir"
            fi
        else
            if [ "$verbose" = "true" ]; then
                echo "$log_prefix   ✓ Essential directory exists: $dir"
            fi
        fi
    done
    
    # Check for any directories that might have been accidentally removed or corrupted
    local directory_count=$(find "$source_dir" -type d 2>/dev/null | wc -l | tr -d ' ')
    
    if [ "$directory_count" -lt 5 ]; then
        echo "$log_prefix WARNING: Unusually low directory count ($directory_count) - possible structure corruption"
        return 2
    fi
    
    # Verify directory permissions are reasonable
    if [ ! -r "$source_dir" ] || [ ! -x "$source_dir" ]; then
        echo "$log_prefix ERROR: Source directory permissions are insufficient for processing"
        return 1
    fi
    
    if [ -n "$missing_dirs" ]; then
        echo "$log_prefix WARNING: Some essential directories are missing:$missing_dirs"
        echo "$log_prefix This may indicate incomplete sitepackage structure or processing errors"
        return 2
    fi
    
    if [ "$verbose" = "true" ]; then
        echo "$log_prefix Directory structure integrity verification passed ($dirs_checked directories checked)"
    fi
    
    return 0
}

# Comprehensive post-processing verification system
perform_post_processing_verification() {
    local source_dir="$1"
    local verbose="$2"
    local log_prefix="$3"
    
    if [ "$verbose" = "true" ]; then
        echo "$log_prefix Starting comprehensive post-processing verification..."
    fi
    
    local verification_start_time=$(date +%s)
    local verification_passed=true
    local verification_warnings=false
    
    # Step 1: Validate file integrity
    if [ "$verbose" = "true" ]; then
        echo "$log_prefix Step 1: Verifying file integrity..."
    fi
    
    if ! verify_file_integrity "$source_dir" "$verbose" "$log_prefix"; then
        echo "$log_prefix ERROR: File integrity verification failed"
        verification_passed=false
    elif [ "$verbose" = "true" ]; then
        echo "$log_prefix Step 1: File integrity verification passed"
    fi
    
    # Step 2: Check for remaining placeholders
    if [ "$verbose" = "true" ]; then
        echo "$log_prefix Step 2: Checking for remaining placeholders..."
    fi
    
    if ! find_remaining_placeholders "$source_dir" "$verbose" "$log_prefix"; then
        echo "$log_prefix WARNING: Remaining placeholders detected"
        verification_warnings=true
    elif [ "$verbose" = "true" ]; then
        echo "$log_prefix Step 2: No remaining placeholders found"
    fi
    
    # Step 3: Verify directory structure integrity
    if [ "$verbose" = "true" ]; then
        echo "$log_prefix Step 3: Verifying directory structure integrity..."
    fi
    
    # Check that essential sitepackage directories exist
    local essential_dirs=(
        "Classes"
        "Configuration"
        "Resources"
        "Resources/Private"
        "Resources/Public"
    )
    
    local missing_dirs=""
    for dir in "${essential_dirs[@]}"; do
        if [ ! -d "$source_dir/$dir" ]; then
            missing_dirs="$missing_dirs\n  - Missing directory: $dir"
            verification_passed=false
        fi
    done
    
    if [ -n "$missing_dirs" ]; then
        echo -e "$log_prefix ERROR: Essential directory structure is incomplete:$missing_dirs"
    elif [ "$verbose" = "true" ]; then
        echo "$log_prefix Step 3: Directory structure verification passed"
    fi
    
    # Step 4: Verify essential files exist
    if [ "$verbose" = "true" ]; then
        echo "$log_prefix Step 4: Verifying essential files exist..."
    fi
    
    local essential_files=(
        "ext_emconf.php"
        "composer.json"
    )
    
    local missing_files=""
    for file in "${essential_files[@]}"; do
        if [ ! -f "$source_dir/$file" ]; then
            missing_files="$missing_files\n  - Missing file: $file"
            verification_passed=false
        fi
    done
    
    if [ -n "$missing_files" ]; then
        echo -e "$log_prefix ERROR: Essential files are missing:$missing_files"
    elif [ "$verbose" = "true" ]; then
        echo "$log_prefix Step 4: Essential files verification passed"
    fi
    
    # Calculate verification time
    local verification_end_time=$(date +%s)
    local verification_time=$((verification_end_time - verification_start_time))
    
    # Generate comprehensive final verification report
    echo "$log_prefix Post-processing verification completed in ${verification_time}s"
    echo "$log_prefix Verification summary:"
    echo "$log_prefix   ✓ Parameter validation: Completed"
    echo "$log_prefix   ✓ File integrity checks: Completed"
    echo "$log_prefix   ✓ Placeholder verification: Completed"
    echo "$log_prefix   ✓ Directory structure validation: Completed"
    echo "$log_prefix   ✓ Essential files validation: Completed"
    
    if [ "$verification_passed" = "true" ]; then
        if [ "$verification_warnings" = "true" ]; then
            echo "$log_prefix VERIFICATION RESULT: PASSED WITH WARNINGS"
            echo "$log_prefix The replacement process completed successfully but some placeholders may remain."
            echo "$log_prefix This may be acceptable depending on your specific requirements."
            echo "$log_prefix Review the warnings above to determine if manual intervention is needed."
            return 1  # Return 1 to indicate warnings
        else
            echo "$log_prefix VERIFICATION RESULT: PASSED"
            echo "$log_prefix All verification checks completed successfully."
            echo "$log_prefix The sitepackage template has been processed correctly and is ready for use."
            return 0
        fi
    else
        echo "$log_prefix VERIFICATION RESULT: FAILED"
        echo "$log_prefix Critical issues were detected that may prevent proper sitepackage functionality."
        echo "$log_prefix Please review the errors above and correct them before proceeding."
        return 2  # Return 2 to indicate critical failure
    fi
}

# Helper function to process individual file replacements
process_file_replacements() {
    local file="$1"
    local escaped_sitepackage_name="$2"
    local escaped_sitepackage_kebab="$3"
    local escaped_sitepackage_pascal="$4"
    local escaped_project_name="$5"
    local escaped_vendor_name="$6"
    local original_vendor_name="$7"
    local verbose="$8"
    
    # Create temporary file for safe processing
    local temp_file="${file}.tmp.$$"
    
    # Copy original file to temp file
    if ! cp "$file" "$temp_file" 2>/dev/null; then
        return 1
    fi
    
    # Define replacement patterns using delimited strings for bash 3.2+ compatibility
    # Order is critical: compound patterns first, then vendor, then standalone
    # Format: "pattern1|replacement1|pattern2|replacement2|..."
    local compound_patterns_data="xxxx_sitepackage|$escaped_sitepackage_name|xxxx-sitepackage|$escaped_sitepackage_kebab|XxxxSitepackage|$escaped_sitepackage_pascal"
    
    # Track replacement statistics for this file
    local file_replacements=0
    
    # Process compound patterns using portable pattern parsing (bash 3.2+ compatible)
    # Define callback function for processing each pattern-replacement pair
    process_simple_pattern_callback() {
        local pattern="$1"
        local replacement="$2"
        local context="$3"
        
        if [ "$verbose" = "true" ]; then
            echo "  Processing pattern: $pattern -> $replacement in $file"
        fi
        
        # Count occurrences and perform replacement using portable method
        local count_before=$(portable_sed "count_matches" "$pattern" "$replacement" "$temp_file")
        
        if ! portable_sed "replace_in_place" "$pattern" "$replacement" "$temp_file"; then
            rm -f "$temp_file" 2>/dev/null
            return 1
        fi
        
        file_replacements=$((file_replacements + count_before))
        return 0
    }
    
    # Parse and process compound patterns using portable string parsing
    if ! parse_replacement_patterns "$compound_patterns_data" "process_simple_pattern_callback" ""; then
        rm -f "$temp_file" 2>/dev/null
        return 1
    fi
    
    # Process vendor pattern if provided and different from placeholder
    if [ -n "$escaped_vendor_name" ] && [ "$original_vendor_name" != "skom" ]; then
        local vendor_pattern="\\bskom\\b"
        
        if [ "$verbose" = "true" ]; then
            echo "  Processing vendor pattern: skom -> $escaped_vendor_name in $file"
        fi
        
        if command -v gsed >/dev/null 2>&1; then
            # Use GNU sed for better word boundary support
            local count_before=$(gsed -n "s/${vendor_pattern}/${escaped_vendor_name}/gp" "$temp_file" | wc -l)
            gsed -i "s/${vendor_pattern}/${escaped_vendor_name}/g" "$temp_file" 2>/dev/null
        else
            # Fallback: use context-aware replacement for vendor pattern
            # Look for skom as a standalone word (surrounded by non-alphanumeric chars or line boundaries)
            local count_before=$(sed -n "s/\\([^a-zA-Z0-9_]\\)skom\\([^a-zA-Z0-9_]\\)/\\1${escaped_vendor_name}\\2/gp" "$temp_file" | wc -l)
            sed -i '' "s/\\([^a-zA-Z0-9_]\\)skom\\([^a-zA-Z0-9_]\\)/\\1${escaped_vendor_name}\\2/g" "$temp_file" 2>/dev/null
            
            # Also handle skom at beginning and end of lines
            sed -i '' "s/^skom\\([^a-zA-Z0-9_]\\)/${escaped_vendor_name}\\1/g" "$temp_file" 2>/dev/null
            sed -i '' "s/\\([^a-zA-Z0-9_]\\)skom$$/\\1${escaped_vendor_name}/g" "$temp_file" 2>/dev/null
            # Handle skom as entire line
            sed -i '' "s/^skom$/${escaped_vendor_name}/g" "$temp_file" 2>/dev/null
        fi
        
        if [ $? -ne 0 ]; then
            rm -f "$temp_file" 2>/dev/null
            return 1
        fi
        
        file_replacements=$((file_replacements + count_before))
    fi
    
    # Process standalone xxxx pattern last (after compound patterns to avoid conflicts)
    local standalone_pattern="\\bxxxx\\b"
    
    if [ "$verbose" = "true" ]; then
        echo "  Processing standalone pattern: xxxx -> $escaped_project_name in $file"
    fi
    
    if command -v gsed >/dev/null 2>&1; then
        # Use GNU sed with negative lookahead simulation
        # First, temporarily mark already-processed compound patterns to avoid re-processing
        gsed -i "s/${escaped_sitepackage_name}/TEMP_SITEPACKAGE_MARKER/g" "$temp_file" 2>/dev/null
        gsed -i "s/${escaped_sitepackage_kebab}/TEMP_KEBAB_MARKER/g" "$temp_file" 2>/dev/null
        gsed -i "s/${escaped_sitepackage_pascal}/TEMP_PASCAL_MARKER/g" "$temp_file" 2>/dev/null
        
        # Now replace standalone xxxx
        local count_before=$(gsed -n "s/${standalone_pattern}/${escaped_project_name}/gp" "$temp_file" | wc -l)
        gsed -i "s/${standalone_pattern}/${escaped_project_name}/g" "$temp_file" 2>/dev/null
        
        # Restore the compound patterns
        gsed -i "s/TEMP_SITEPACKAGE_MARKER/${escaped_sitepackage_name}/g" "$temp_file" 2>/dev/null
        gsed -i "s/TEMP_KEBAB_MARKER/${escaped_sitepackage_kebab}/g" "$temp_file" 2>/dev/null
        gsed -i "s/TEMP_PASCAL_MARKER/${escaped_sitepackage_pascal}/g" "$temp_file" 2>/dev/null
    else
        # Fallback: use context-aware replacement for standalone xxxx
        # Look for xxxx as a standalone word (surrounded by non-alphanumeric chars or line boundaries)
        # But avoid xxxx that's part of already-replaced compound patterns
        
        # Use a more sophisticated approach: only replace xxxx that's not followed by _ or -
        # and not preceded by uppercase letters (to avoid matching parts of CamelCase)
        local count_before=$(sed -n "s/\\([^a-zA-Z0-9_-]\\)xxxx\\([^a-zA-Z0-9_-]\\)/\\1${escaped_project_name}\\2/gp" "$temp_file" | wc -l)
        sed -i '' "s/\\([^a-zA-Z0-9_-]\\)xxxx\\([^a-zA-Z0-9_-]\\)/\\1${escaped_project_name}\\2/g" "$temp_file" 2>/dev/null
        
        # Handle xxxx at beginning and end of lines (but not followed/preceded by _ or -)
        sed -i '' "s/^xxxx\\([^a-zA-Z0-9_-]\\)/${escaped_project_name}\\1/g" "$temp_file" 2>/dev/null
        sed -i '' "s/\\([^a-zA-Z0-9_-]\\)xxxx$$/\\1${escaped_project_name}/g" "$temp_file" 2>/dev/null
        # Handle xxxx as entire line
        sed -i '' "s/^xxxx$/${escaped_project_name}/g" "$temp_file" 2>/dev/null
    fi
    
    if [ $? -ne 0 ]; then
        rm -f "$temp_file" 2>/dev/null
        return 1
    fi
    
    file_replacements=$((file_replacements + count_before))
    
    # Replace original file with processed version
    if ! mv "$temp_file" "$file" 2>/dev/null; then
        rm -f "$temp_file" 2>/dev/null
        return 1
    fi
    
    if [ "$verbose" = "true" ]; then
        echo "Processed file: $file (${file_replacements} replacements made)"
    fi
    
    return 0
}

# Check if Docker provider is running
if ! docker info >/dev/null 2>&1; then
    echo "Error: Could not connect to a Docker provider."
    echo "Please start Docker Desktop or your preferred Docker provider before running this script."
    echo "DDEV requires a running Docker provider to function correctly."
    exit 1
fi

# Check if a DDEV project already exists in current directory
if [ -d "$PROJECT_NAME/.ddev" ] || [ -f "$PROJECT_NAME/.ddev/config.yaml" ]; then
    echo "Error: A DDEV project already exists in the current directory."
    echo "Please run this script from a directory without an existing DDEV project."
    echo "You can create a new directory or remove the existing .ddev folder."
    exit 1
fi

# Read project name from .env file
if [ -f "install.config" ]; then
    PROJECT_NAME=$(grep "^project_name=" install.config | cut -d"'" -f2)
    echo "Using project name: $PROJECT_NAME"
    SITE_NAME=$(grep "^site_name=" install.config | cut -d"'" -f2)
    echo "Using site name: $SITE_NAME"
    ADMIN_USERNAME=$(grep "^admin_username=" install.config | cut -d"'" -f2)
    echo "Using admin username: $ADMIN_USERNAME"
    ADMIN_NAME=$(grep "^admin_name=" install.config | cut -d"'" -f2)
    echo "Using admin name: $ADMIN_NAME"
    ADMIN_EMAIL=$(grep "^admin_email=" install.config | cut -d"'" -f2)
    echo "Using admin email: $ADMIN_EMAIL"
    ADMIN_URL=$(grep "^admin_url=" install.config | cut -d"'" -f2)
    echo "Using admin url: $ADMIN_URL"
    SERVER_TYPE=$(grep "^server_type=" install.config | cut -d"'" -f2)
    echo "Using server type: $SERVER_TYPE"
    DB_NAME=$(grep "^db_name=" install.config | cut -d"'" -f2)
    echo "Using db name: $DB_NAME"
    DB_USER=$(grep "^db_user=" install.config | cut -d"'" -f2)
    echo "Using db user: $DB_USER"
    DB_PASSWORD=$(grep "^db_password=" install.config | cut -d"'" -f2)
    echo "Using db password: $DB_PASSWORD"
    DB_HOST=$(grep "^db_host=" install.config | cut -d"'" -f2)
    echo "Using db host: $DB_HOST"
    DB_PORT=$(grep "^db_port=" install.config | cut -d"'" -f2)
    echo "Using db port: $DB_PORT"
    DB_DRIVER=$(grep "^db_driver=" install.config | cut -d"'" -f2)
    echo "Using db driver: $DB_DRIVER"
    SITEPACKAGE_NAME=$(grep "^sitepackage_name=" install.config | cut -d"'" -f2)
    echo "Using sitepackage name: $SITEPACKAGE_NAME"
    SITEPACKAGE_VENDOR=$(grep "^sitepackage_vendor=" install.config | cut -d"'" -f2)
    echo "Using sitepackage vendor: $SITEPACKAGE_VENDOR"

else
    echo "Error: install.config file not found."
    exit 1
fi

# Check if project name is at least 3 characters long
if [ ${#PROJECT_NAME} -lt 3 ]; then
    echo "Error: Project name must be at least 3 characters long."
    exit 1
fi

while true; do
    read -sp "Enter admin password (min. 8 characters, 1 number, 1 special character and 1 upper case letter): " ADMIN_PASSWORD
    echo

    # Check password length
    if [ ${#ADMIN_PASSWORD} -lt 8 ]; then
        echo "Error: Password must be at least 8 characters long."
        continue
    fi

    # Check for at least one number
    if ! [[ "$ADMIN_PASSWORD" =~ [0-9] ]]; then
        echo "Error: Password must contain at least one number."
        continue
    fi

    # Check for at least one special character
    if ! [[ "$ADMIN_PASSWORD" =~ [^a-zA-Z0-9] ]]; then
        echo "Error: Password must contain at least one special character."
        continue
    fi

    # Check for at least one uppercase letter
    if ! [[ "$ADMIN_PASSWORD" =~ [A-Z] ]]; then
        echo "Error: Password must contain at least one uppercase letter."
        continue
    fi

    break
done
echo


# Create project directory
mkdir "$PROJECT_NAME"
cd "$PROJECT_NAME"

# Clean up any unwanted files that might interfere with composer create-project
rm -f .DS_Store

# Initialize DDEV project
ddev config --project-name="$PROJECT_NAME" --project-type=typo3 --docroot=public --php-version=8.3

# Start DDEV
ddev start

# Install TYPO3 via Composer
ddev composer create-project "typo3/cms-base-distribution:^13" --no-interaction


# Install TYPO3 setup
ddev typo3 setup --force --driver="$DB_DRIVER" --host="$DB_HOST" --port="$DB_PORT" --dbname="$DB_NAME" --username="$DB_USER" --password="$DB_PASSWORD" --admin-username="$ADMIN_USERNAME" --admin-user-password="$ADMIN_PASSWORD" --server-type="$SERVER_TYPE" --no-interaction

# Allow dotenv-connector plugin
ddev composer config allow-plugins.helhum/dotenv-connector true

# Add TYPO3 Composer Repository
ddev composer config repositories.typo3 composer https://composer.typo3.org

# Set PHP platform version to 8.3.0
ddev composer config platform.php 8.3.0

# Add author information to composer.json
ddev exec "jq '.authors = [{\"name\": \"$ADMIN_NAME\", \"email\": \"$ADMIN_EMAIL\", \"homepage\": \"$ADMIN_URL\", \"role\": \"Developer\"}]' composer.json > composer.json.tmp && mv composer.json.tmp composer.json"

# Install extensions
ddev composer req helhum/typo3-console praetorius/vite-asset-collector helhum/dotenv-connector b13/container --no-interaction

# Install additional Composer packages
ddev composer update -W --no-interaction

# Install TYPO3 database schema
ddev typo3 database:updateschema

# Install TYPO3 backend groups
echo "2" | ddev typo3 setup:begroups:default

# ddev typo3 configuration:set --key=SYS.defaultLanguage --value=de
# ddev typo3 configuration:set --key=SYS.defaultTimeZone --value=Europe/Berlin
# ddev typo3 configuration:set --key=SYS.sitename --value="$PROJECT_NAME"

# Clear cache
ddev typo3 cache:flush

# Create packages folder
mkdir packages

# Initialize npm
ddev npm init -y

# Install vite
ddev npm install --save-dev vite vite-plugin-typo3 vite-plugin-live-reload

# Install node packages
ddev npm install --save-dev sass bootstrap bootstrap-icons @popperjs/core

# Install vite-sidecar
echo "npm" | ddev get s2b/ddev-vite-sidecar

# Copy and rename sitepackage
cp -R ../install-src/xxxx_sitepackage packages/$SITEPACKAGE_NAME

# Rename contents in the sitepackage
NEW_KEBAB="${SITEPACKAGE_NAME//_/-}"
# Convert to PascalCase: split by underscore, capitalize each part, join
NEW_CAMEL=""
IFS='_' read -ra PARTS <<< "$SITEPACKAGE_NAME"
for part in "${PARTS[@]}"; do
    NEW_CAMEL="${NEW_CAMEL}$(echo "${part:0:1}" | tr '[:lower:]' '[:upper:]')${part:1}"
done

# Replace placeholders using the new robust function
if ! replace_sitepackage_placeholders "packages/$SITEPACKAGE_NAME" "$PROJECT_NAME" "$SITEPACKAGE_NAME" "$NEW_KEBAB" "$NEW_CAMEL" "$SITEPACKAGE_VENDOR" true; then
    echo "Error: Failed to replace sitepackage placeholders"
    exit 1
fi


#ddev typo3 install:setup
# impexp:export
#ddev typo3 impexp:import --file=../install-src/container.xml
# Configure vite
cp ../install-src/vite.config.js vite.config.js


#### .env ####
# Copy .env
cp ../install-src/.env .env

# Copy README.md
cp ../install-src/README.md README.md

# Copy .editorconfig
cp ../install-src/.editorconfig .editorconfig

# Copy .gitignore
cp ../install-src/.gitignore .gitignore

#### Install Rector ####
ddev composer req ssch/typo3-rector  --no-interaction
cp ../install-src/rector.php rector.php

#### Install Playwright ####
ddev exec npm i -D @playwright/test
ddev exec npx playwright install --with-deps

ddev typo3 cache:warmup

# ddev typo3 lint:yaml

# clear
echo "TYPO3 installation completed for project: $PROJECT_NAME"
