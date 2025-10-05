#!/bin/bash

# ALTTP MSU-1 Audio Conversion Script
# This script extracts PCM files from a RAR archive and converts them to FLAC or ALAC format with metadata

set -e  # Exit on error

# Default values
FORMAT="alac"
OUTPUT_DIR=""
EXPECTED_MD5="e233042432a4693f315cd3c190c63f0a"

# Parse arguments
show_usage() {
    echo "Usage: $0 [OPTIONS] <path-to-rar-file>"
    echo ""
    echo "Options:"
    echo "  -f, --format FORMAT    Output format: 'flac' or 'alac' (default: alac)"
    echo "  -o, --output DIR       Output directory (default: ./flac_output or ./alac_output)"
    echo "  -h, --help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 soundtrack.rar                    # Convert to ALAC (default)"
    echo "  $0 -f flac soundtrack.rar            # Convert to FLAC"
    echo "  $0 -f alac -o ./music soundtrack.rar # Convert to ALAC in ./music"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--format)
            FORMAT="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            ;;
        -*)
            echo "Unknown option: $1"
            show_usage
            ;;
        *)
            RAR_FILE="$1"
            shift
            ;;
    esac
done

# Check if RAR file is provided
if [ -z "$RAR_FILE" ]; then
    echo "Error: No RAR file specified"
    show_usage
fi

# Validate format
if [ "$FORMAT" != "flac" ] && [ "$FORMAT" != "alac" ]; then
    echo "Error: Format must be 'flac' or 'alac'"
    exit 1
fi

# Set default output directory based on format if not specified
if [ -z "$OUTPUT_DIR" ]; then
    OUTPUT_DIR="./${FORMAT}_output"
fi

# Check if RAR file exists
if [ ! -f "$RAR_FILE" ]; then
    echo "Error: RAR file '$RAR_FILE' not found"
    exit 1
fi

# Verify MD5 checksum
echo "Verifying RAR file integrity..."
if command -v md5 &> /dev/null; then
    # macOS md5 command
    ACTUAL_MD5=$(md5 -q "$RAR_FILE")
elif command -v md5sum &> /dev/null; then
    # Linux md5sum command
    ACTUAL_MD5=$(md5sum "$RAR_FILE" | awk '{print $1}')
else
    echo "Warning: md5 or md5sum not found, skipping checksum verification"
    ACTUAL_MD5="$EXPECTED_MD5"
fi

if [ "$ACTUAL_MD5" != "$EXPECTED_MD5" ]; then
    echo "Error: MD5 checksum mismatch!"
    echo "  Expected: $EXPECTED_MD5"
    echo "  Got:      $ACTUAL_MD5"
    echo ""
    echo "This may not be the correct RAR file."
    echo "Please download the official file from: https://www.youtube.com/watch?v=I_jMOfoflMY&t=370s"
    exit 1
fi
echo "Checksum verified successfully"
echo ""

# Check if unrar is installed
if ! command -v unrar &> /dev/null; then
    echo "Error: unrar is not installed. Install it with: brew install unrar"
    exit 1
fi

# Check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    echo "Error: ffmpeg is not installed. Install it with: brew install ffmpeg"
    exit 1
fi

# Check if metaflac is installed (for FLAC)
if [ "$FORMAT" == "flac" ]; then
    if ! command -v metaflac &> /dev/null; then
        echo "Error: metaflac is not installed. Install it with: brew install flac"
        exit 1
    fi
fi

# Check if AtomicParsley is installed (for ALAC)
if [ "$FORMAT" == "alac" ]; then
    if ! command -v AtomicParsley &> /dev/null; then
        echo "Error: AtomicParsley is not installed. Install it with: brew install atomicparsley"
        exit 1
    fi
fi

# Create uppercase version of format for display (bash 3.2 compatible)
FORMAT_UPPER=$(echo "$FORMAT" | tr '[:lower:]' '[:upper:]')

echo "=== ALTTP MSU-1 to $FORMAT_UPPER Conversion ==="
echo "RAR File: $RAR_FILE"
echo "Output Format: $FORMAT_UPPER"
echo "Output Directory: $OUTPUT_DIR"
echo ""

# Create temporary extraction directory
TEMP_DIR=$(mktemp -d)
echo "Creating temporary directory: $TEMP_DIR"

# Extract RAR file
echo "Extracting RAR file..."
unrar x "$RAR_FILE" "$TEMP_DIR/" > /dev/null

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Find all PCM files and convert them
echo "Converting PCM files to $FORMAT_UPPER..."
PCM_COUNT=0

# Function to generate unique output filename based on path
get_output_name() {
    local pcm_file="$1"
    local temp_dir="$2"

    # Get relative path from temp directory
    local rel_path="${pcm_file#$temp_dir/}"
    local base=$(basename "$pcm_file" .pcm)

    # Check if file is in a subdirectory and generate appropriate name
    if [[ "$rel_path" == *"Bonus Tracks"* ]]; then
        echo "${base}-bonus-tracks"
    elif [[ "$rel_path" == *"No SFX"* ]]; then
        echo "${base}-no-sfx"
    else
        echo "$base"
    fi
}

# Create temporary file list
PCM_LIST=$(mktemp)
find "$TEMP_DIR" -name "*.pcm" -type f > "$PCM_LIST"

if [ "$FORMAT" == "flac" ]; then
    # Convert to FLAC
    while IFS= read -r pcm_file; do
        output_name=$(get_output_name "$pcm_file" "$TEMP_DIR")
        echo "  Converting: $output_name"

        # Convert to FLAC, skipping the 8-byte MSU1 header
        ffmpeg -f s16le -ar 44100 -ac 2 -skip_initial_bytes 8 -i "$pcm_file" \
            "$OUTPUT_DIR/$output_name.flac" -y </dev/null > /dev/null 2>&1

        PCM_COUNT=$((PCM_COUNT + 1))
    done < "$PCM_LIST"
else
    # Convert to ALAC
    while IFS= read -r pcm_file; do
        output_name=$(get_output_name "$pcm_file" "$TEMP_DIR")
        echo "  Converting: $output_name"

        # Convert to ALAC, skipping the 8-byte MSU1 header
        ffmpeg -f s16le -ar 44100 -ac 2 -skip_initial_bytes 8 -i "$pcm_file" \
            -c:a alac "$OUTPUT_DIR/$output_name.m4a" -y </dev/null > /dev/null 2>&1

        PCM_COUNT=$((PCM_COUNT + 1))
    done < "$PCM_LIST"
fi

# Clean up temp file list
/bin/rm "$PCM_LIST"

echo "Converted $PCM_COUNT files"
echo ""
echo "Applying metadata..."

# Define metadata for each track
# Format: "filename|title|track_number"
declare -a TRACKS=(
    "alttp_msu-1|Title Screen|1"
    "alttp_msu-2|Prologue|2"
    "alttp_msu-3|Menu|3"
    "alttp_msu-4|Time of the Falling Rain|4"
    "alttp_msu-5|Majestic Castle|5"
    "alttp_msu-6|Princess Zelda|6"
    "alttp_msu-7|Sanctuary|7"
    "alttp_msu-8|Hyrule Field|8"
    "alttp_msu-9|Kakariko Village|9"
    "alttp_msu-10|Fortune Teller|10"
    "alttp_msu-11|Soldiers|11"
    "alttp_msu-12|Dark Dungeons|12"
    "alttp_msu-13|Lost Ancient Ruins|13"
    "alttp_msu-14|Guardians|14"
    "alttp_msu-16|Guessing Game|16"
    "alttp_msu-17|The Silly Pink Rabbit|17"
    "alttp_msu-18|Forest of Mystery|18"
    "alttp_msu-19|The Master Sword|19"
    "alttp_msu-20|Priest of the Dark Order|20"
    "alttp_msu-21|Dark Golden Land|21"
    "alttp_msu-22|Dungeon of Shadows|22"
    "alttp_msu-23|Meeting the Maidens|23"
    "alttp_msu-24|The Goddess Appears|24"
    "alttp_msu-25|Black Mist|25"
    "alttp_msu-26|The Release of Ganon|26"
    "alttp_msu-27|Ganon's Message|27"
    "alttp_msu-28|The Prince of Darkness|28"
    "alttp_msu-29|Power of the Gods|29"
    "alttp_msu-30|Epilogue|30"
    "alttp_msu-31|Credits|31"
    "alttp_msu-32|Lost Woods (Ocarina of Time)|32"
    "alttp_msu-33|Town theme (Zelda II)|33"
    "alttp_msu-34|Eagle's Tower (Link's Awakening)|34"
    "alttp_msu-5-bonus-tracks|Majestic Castle (Bonus)|35"
    "alttp_msu-7-bonus-tracks|Sanctuary (Bonus)|36"
    "alttp_msu-21-bonus-tracks|Dark Golden Land (Bonus)|37"
    "alttp_msu-22-bonus-tracks|Dungeon of Shadows (Bonus)|38"
    "alttp_msu-10-no-sfx|Fortune Teller (No SFX)|39"
    "alttp_msu-29-no-sfx|Power of the Gods (No SFX)|40"
)

ARTIST="Zerethn"
ALBUM="A Link to the Past: Enhanced Soundtrack"

# Apply metadata to each track
if [ "$FORMAT" == "flac" ]; then
    # Tag FLAC files
    for track_info in "${TRACKS[@]}"; do
        IFS='|' read -r filename title tracknum <<< "$track_info"

        if [ -f "$OUTPUT_DIR/$filename.flac" ]; then
            echo "  Tagging: $title"
            metaflac --remove-all-tags "$OUTPUT_DIR/$filename.flac"
            metaflac --set-tag="ARTIST=$ARTIST" \
                     --set-tag="ALBUM=$ALBUM" \
                     --set-tag="TITLE=$title" \
                     --set-tag="TRACKNUMBER=$tracknum" \
                     "$OUTPUT_DIR/$filename.flac"
        fi
    done
else
    # Tag ALAC files
    for track_info in "${TRACKS[@]}"; do
        IFS='|' read -r filename title tracknum <<< "$track_info"

        if [ -f "$OUTPUT_DIR/$filename.m4a" ]; then
            echo "  Tagging: $title"
            AtomicParsley "$OUTPUT_DIR/$filename.m4a" \
                --artist "$ARTIST" \
                --album "$ALBUM" \
                --title "$title" \
                --tracknum "$tracknum" \
                --overWrite > /dev/null 2>&1
        fi
    done
fi

# Clean up temporary directory
echo ""
echo "Cleaning up temporary files..."
rm -rf "$TEMP_DIR"

echo ""
echo "=== Conversion Complete ==="
echo "$FORMAT_UPPER files with metadata are in: $OUTPUT_DIR"
echo "Total tracks: ${#TRACKS[@]}"
