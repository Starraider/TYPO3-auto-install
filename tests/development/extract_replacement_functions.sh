#!/bin/bash

# Extract replacement functions from install-typo3.sh for testing
# This script creates a standalone file with just the replacement functions

# Source path resolution utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/path-utils.sh"

# Resolve paths relative to project root
INSTALL_SCRIPT="$(resolve_project_path "install-typo3.sh")"
OUTPUT_FILE="$(resolve_project_path "replacement_functions_only.sh")"

if [ ! -f "$INSTALL_SCRIPT" ]; then
    echo "Error: Install script not found: $INSTALL_SCRIPT"
    exit 1
fi

echo "Extracting replacement functions from $INSTALL_SCRIPT..."

# Create the output file with just the functions
{
    echo "#!/bin/bash"
    echo "# Extracted replacement functions for testing"
    echo "# Generated from $INSTALL_SCRIPT on $(date)"
    echo ""
    
    # Extract each function (including dependencies)
    sed -n '/^portable_sed()/,/^}$/p' "$INSTALL_SCRIPT"
    echo ""
    sed -n '/^replace_sitepackage_placeholders()/,/^}$/p' "$INSTALL_SCRIPT"
    echo ""
    sed -n '/^validate_replacement_parameters()/,/^}$/p' "$INSTALL_SCRIPT"
    echo ""
    sed -n '/^get_file_access_status()/,/^}$/p' "$INSTALL_SCRIPT"
    echo ""
    sed -n '/^should_process_file_with_reason()/,/^}$/p' "$INSTALL_SCRIPT"
    echo ""
    sed -n '/^should_process_file()/,/^}$/p' "$INSTALL_SCRIPT"
    echo ""
    sed -n '/^is_text_file()/,/^}$/p' "$INSTALL_SCRIPT"
    echo ""
    sed -n '/^find_processable_files()/,/^}$/p' "$INSTALL_SCRIPT"
    echo ""
    sed -n '/^process_file_replacements_with_stats()/,/^}$/p' "$INSTALL_SCRIPT"
    echo ""
    sed -n '/^find_remaining_placeholders()/,/^}$/p' "$INSTALL_SCRIPT"
    echo ""
    sed -n '/^verify_file_integrity()/,/^}$/p' "$INSTALL_SCRIPT"
    echo ""
    sed -n '/^verify_directory_structure_integrity()/,/^}$/p' "$INSTALL_SCRIPT"
    echo ""
    sed -n '/^perform_post_processing_verification()/,/^}$/p' "$INSTALL_SCRIPT"
    
} > "$OUTPUT_FILE"

chmod +x "$OUTPUT_FILE"

echo "Functions extracted to: $OUTPUT_FILE"
echo "You can now source this file in tests: source $OUTPUT_FILE"