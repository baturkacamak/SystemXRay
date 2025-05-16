#!/bin/bash

# Script to generate translation files for all supported languages
# This is a placeholder script - actual translations need to be added manually

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
LANG_DIR="$SCRIPT_DIR/lang"

# List of supported languages
LANGUAGES=(
    "ar" "bn" "cs" "da" "de" "el" "en" "es" "fa" "fi" "fr" "he" "hi" "hu" "id" "it" "ja" "jv" "ko" "krt" "mr" "ms" "nl" "no" "pa" "pl" "pt" "ro" "ru" "sk" "sr" "sv" "ta" "te" "th" "tl" "tr" "uk" "ur" "vi" "zh"
)

# Create language directory if it doesn't exist
mkdir -p "$LANG_DIR"

# Copy English template to all language files
for lang in "${LANGUAGES[@]}"; do
    if [ "$lang" != "en" ]; then
        cp "$LANG_DIR/en" "$LANG_DIR/$lang"
        echo "Created $lang translation file"
    fi
done

echo "Translation files generated. Please edit each file to add proper translations." 