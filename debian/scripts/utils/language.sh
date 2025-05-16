#!/bin/bash

# Language utility functions for hardware-report script

# Get system language
get_system_language() {
    # Try to get language from environment variables
    local lang="${LANG:-${LC_ALL:-${LC_MESSAGES:-en}}}"
    # Extract language code (e.g., en_US.UTF-8 -> en)
    lang="${lang%%_*}"
    echo "$lang"
}

# Check if language is supported
is_language_supported() {
    local lang="$1"
    local supported_languages=(
        "ar" "bn" "cs" "da" "de" "el" "en" "es" "fa" "fi" "fr" "he" "hi" "hu" "id" "it" "ja" "jv" "ko" "krt" "mr" "ms" "nl" "no" "pa" "pl" "pt" "ro" "ru" "sk" "sr" "sv" "ta" "te" "th" "tl" "tr" "uk" "ur" "vi" "zh"
    )
    
    for supported in "${supported_languages[@]}"; do
        if [ "$lang" = "$supported" ]; then
            return 0
        fi
    done
    return 1
}

# Load language file
load_language() {
    local lang="$1"
    local lang_file="$SCRIPT_DIR/lang/$lang"
    local help_file="$SCRIPT_DIR/lang/help/$lang"
    
    # If language file doesn't exist, fall back to English
    if [ ! -f "$lang_file" ]; then
        lang_file="$SCRIPT_DIR/lang/en"
    fi
    
    # If help file doesn't exist, fall back to English
    if [ ! -f "$help_file" ]; then
        help_file="$SCRIPT_DIR/lang/help/en"
    fi
    
    # Source the language files
    if [ -f "$lang_file" ]; then
        source "$lang_file"
    else
        echo "Error: Language file not found: $lang_file" >&2
        exit 1
    fi
    
    if [ -f "$help_file" ]; then
        source "$help_file"
    else
        echo "Error: Help file not found: $help_file" >&2
        exit 1
    fi
}

# Initialize language
init_language() {
    local requested_lang="$1"
    local system_lang
    
    # If no language specified, use system language
    if [ -z "$requested_lang" ]; then
        system_lang=$(get_system_language)
        if is_language_supported "$system_lang"; then
            requested_lang="$system_lang"
        else
            requested_lang="en"
        fi
    fi
    
    # Load the language file
    load_language "$requested_lang"
} 