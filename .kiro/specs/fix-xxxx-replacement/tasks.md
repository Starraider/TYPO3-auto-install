# Implementation Plan

- [x] 1. Create the replacement function with core logic
  - Write the `replace_sitepackage_placeholders()` function in install-typo3.sh
  - Implement parameter validation and input sanitization
  - Add basic error handling structure
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 3.1, 3.2, 3.3, 3.4_

- [x] 2. Implement file type filtering and detection
  - Create file extension filtering logic to identify processable files
  - Add binary file detection using file command as fallback
  - Implement directory traversal with proper file type exclusions
  - _Requirements: 2.1, 2.2_

- [x] 3. Implement placeholder replacement logic
  - Create replacement pattern arrays and processing logic
  - Implement word-boundary regex patterns for each placeholder type
  - Add sequential processing of compound patterns, vendor, and standalone placeholders
  - Handle special character escaping for sed operations
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 3.1_

- [x] 4. Add comprehensive error handling and logging
  - Implement verbose logging option for debugging
  - Add file-level error handling for permission and access issues
  - Create processing statistics tracking and reporting
  - Add graceful handling of read-only and inaccessible files
  - _Requirements: 3.2, 3.3, 3.4, 4.3_

- [x] 5. Implement verification and validation system
  - Create post-processing verification to check for remaining placeholders
  - Add validation that all required parameters are provided
  - Implement file integrity checks to ensure no corruption occurred
  - Add reporting of any unreplaced placeholders with file locations
  - _Requirements: 2.3, 2.4, 4.1, 4.2_

- [x] 6. Integrate the new function into the installation script
  - Replace the existing complex sed command with function call
  - Update variable preparation and transformation logic
  - Ensure proper parameter passing from main script to function
  - Test integration with existing DDEV execution context
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [x] 7. Add file permission and structure preservation
  - Implement logic to preserve original file permissions during replacement
  - Add handling for symbolic links and special file types
  - Ensure directory structure integrity is maintained
  - Test with various file permission scenarios
  - _Requirements: 4.1, 4.2, 4.4_

- [x] 8. Create comprehensive test cases for the replacement function
  - Write test cases for each placeholder pattern replacement
  - Create tests for edge cases with special characters and complex project names
  - Add integration tests that verify complete sitepackage template processing
  - Test error handling scenarios and recovery mechanisms
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.3, 3.4_

- [x] 9. Fix bash compatibility issues in replacement function
  - Remove all associative array usage (declare -A) from the replacement function
  - Replace associative arrays with delimited string parsing for replacement patterns
  - Implement bash 3.2+ compatible data structures and processing logic
  - Test compatibility across different bash versions (3.2, 4.x, 5.x)
  - _Requirements: 5.1, 5.2, 5.3, 5.4_

- [x] 10. Improve parameter validation logic
  - Modify validation to allow identical placeholder and replacement values with warning
  - Update project name validation to accept hyphens and underscores properly
  - Fix vendor name validation to not fail when vendor matches existing placeholder
  - Implement smart validation that distinguishes between actual errors and acceptable edge cases
  - _Requirements: 6.1, 6.2, 6.3, 6.4_

- [x] 11. Update replacement pattern processing for compatibility
  - Rewrite pattern processing to use string parsing instead of associative arrays
  - Implement portable shell constructs for pattern matching and replacement
  - Add bash version detection and feature compatibility checks
  - Ensure all shell operations work consistently across Unix systems
  - _Requirements: 5.1, 5.2, 5.3, 5.4_

- [x] 12. Test and validate cross-platform compatibility
  - Test replacement function on macOS with default bash 3.2
  - Test on Linux systems with bash 4.x and 5.x
  - Verify all functionality works without bash 4+ specific features
  - Create compatibility test suite for different shell environments
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 6.1, 6.2, 6.3, 6.4_
- [x] 13. Debug and fix error handling in replacement function
  - Investigate the truncated error messages appearing as `[2025-08-28 19` in logs
  - Fix the `process_file_replacements_with_stats` function error message formatting
  - Ensure error messages are properly returned and displayed without truncation
  - Test that all error conditions are properly handled and reported
  - _Requirements: 3.2, 3.3, 3.4_