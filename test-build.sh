#!/bin/bash

# Test script for ALTTP audio conversion
# Tests both FLAC and ALAC conversion, file counts, and metadata

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test results tracking
TESTS_PASSED=0
TESTS_FAILED=0

# Print test result
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}: $2"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: $2"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Find the RAR file
RAR_FILE=$(find . -maxdepth 1 -name "*.rar" -type f | head -1)

if [ -z "$RAR_FILE" ]; then
    echo -e "${RED}Error: No RAR file found in current directory${NC}"
    exit 1
fi

echo "=== ALTTP Build Test Suite ==="
echo "RAR File: $RAR_FILE"
echo ""

# Create temporary test directories
TEST_DIR=$(mktemp -d)
FLAC_OUTPUT="$TEST_DIR/flac_test"
ALAC_OUTPUT="$TEST_DIR/alac_test"

echo "Test directory: $TEST_DIR"
echo ""

# Cleanup function
cleanup() {
    echo ""
    echo "Cleaning up test directories..."
    rm -rf "$TEST_DIR"
}

# Register cleanup on exit
trap cleanup EXIT

# Count PCM files in RAR
echo "Counting PCM tracks in RAR archive..."
EXPECTED_PCM_COUNT=$(unrar lb "$RAR_FILE" | grep -c "\.pcm$" || true)
echo "Expected PCM files: $EXPECTED_PCM_COUNT"
echo ""

# Test 1: FLAC Conversion
echo -e "${YELLOW}=== Testing FLAC Conversion ===${NC}"
./build_alttp.sh -f flac -o "$FLAC_OUTPUT" "$RAR_FILE"
echo ""

# Test 1a: FLAC file count
FLAC_FILE_COUNT=$(find "$FLAC_OUTPUT" -name "*.flac" -type f | wc -l | tr -d ' ')
if [ "$FLAC_FILE_COUNT" -eq "$EXPECTED_PCM_COUNT" ]; then
    print_result 0 "FLAC file count matches PCM count ($FLAC_FILE_COUNT files)"
else
    print_result 1 "FLAC file count mismatch (expected $EXPECTED_PCM_COUNT, got $FLAC_FILE_COUNT)"
fi

# Test 1b: FLAC metadata
echo "Checking FLAC metadata..."
FLAC_NO_METADATA=0
FLAC_FILES_CHECKED=0

find "$FLAC_OUTPUT" -name "*.flac" -type f | while read -r flac_file; do
    FLAC_FILES_CHECKED=$((FLAC_FILES_CHECKED + 1))

    # Check for required tags
    ARTIST=$(metaflac --show-tag=ARTIST "$flac_file" | cut -d= -f2)
    ALBUM=$(metaflac --show-tag=ALBUM "$flac_file" | cut -d= -f2)
    TITLE=$(metaflac --show-tag=TITLE "$flac_file" | cut -d= -f2)
    TRACKNUM=$(metaflac --show-tag=TRACKNUMBER "$flac_file" | cut -d= -f2)

    if [ -z "$ARTIST" ] || [ -z "$ALBUM" ] || [ -z "$TITLE" ] || [ -z "$TRACKNUM" ]; then
        FLAC_NO_METADATA=$((FLAC_NO_METADATA + 1))
        echo "  Missing metadata in: $(basename "$flac_file")"
    fi
done

if [ "$FLAC_NO_METADATA" -eq 0 ]; then
    print_result 0 "All FLAC files have metadata"
else
    print_result 1 "$FLAC_NO_METADATA FLAC files missing metadata"
fi

# Test 1c: FLAC album artwork
echo "Checking FLAC album artwork..."
FLAC_NO_ARTWORK=0

find "$FLAC_OUTPUT" -name "*.flac" -type f | while read -r flac_file; do
    # Check for PICTURE metadata block
    if ! metaflac --list --block-type=PICTURE "$flac_file" | grep -q "type: 6 (PICTURE)"; then
        FLAC_NO_ARTWORK=$((FLAC_NO_ARTWORK + 1))
        echo "  Missing artwork in: $(basename "$flac_file")"
    fi
done

if [ "$FLAC_NO_ARTWORK" -eq 0 ]; then
    print_result 0 "All FLAC files have album artwork"
else
    print_result 1 "$FLAC_NO_ARTWORK FLAC files missing artwork"
fi

echo ""

# Test 2: ALAC Conversion
echo -e "${YELLOW}=== Testing ALAC Conversion ===${NC}"
./build_alttp.sh -f alac -o "$ALAC_OUTPUT" "$RAR_FILE"
echo ""

# Test 2a: ALAC file count
ALAC_FILE_COUNT=$(find "$ALAC_OUTPUT" -name "*.m4a" -type f | wc -l | tr -d ' ')
if [ "$ALAC_FILE_COUNT" -eq "$EXPECTED_PCM_COUNT" ]; then
    print_result 0 "ALAC file count matches PCM count ($ALAC_FILE_COUNT files)"
else
    print_result 1 "ALAC file count mismatch (expected $EXPECTED_PCM_COUNT, got $ALAC_FILE_COUNT)"
fi

# Test 2b: ALAC metadata
echo "Checking ALAC metadata..."
ALAC_NO_METADATA=0
ALAC_FILES_CHECKED=0

find "$ALAC_OUTPUT" -name "*.m4a" -type f | while read -r alac_file; do
    ALAC_FILES_CHECKED=$((ALAC_FILES_CHECKED + 1))

    # AtomicParsley returns metadata in format: Atom "©nam" contains: Title
    ARTIST=$(AtomicParsley "$alac_file" -t 2>/dev/null | grep "Atom \"©ART\"" | cut -d: -f2- | xargs || true)
    ALBUM=$(AtomicParsley "$alac_file" -t 2>/dev/null | grep "Atom \"©alb\"" | cut -d: -f2- | xargs || true)
    TITLE=$(AtomicParsley "$alac_file" -t 2>/dev/null | grep "Atom \"©nam\"" | cut -d: -f2- | xargs || true)
    TRACKNUM=$(AtomicParsley "$alac_file" -t 2>/dev/null | grep "Atom \"trkn\"" | cut -d: -f2- | xargs || true)

    if [ -z "$ARTIST" ] || [ -z "$ALBUM" ] || [ -z "$TITLE" ] || [ -z "$TRACKNUM" ]; then
        ALAC_NO_METADATA=$((ALAC_NO_METADATA + 1))
        echo "  Missing metadata in: $(basename "$alac_file")"
    fi
done

if [ "$ALAC_NO_METADATA" -eq 0 ]; then
    print_result 0 "All ALAC files have metadata"
else
    print_result 1 "$ALAC_NO_METADATA ALAC files missing metadata"
fi

# Test 2c: ALAC album artwork
echo "Checking ALAC album artwork..."
ALAC_NO_ARTWORK=0

find "$ALAC_OUTPUT" -name "*.m4a" -type f | while read -r alac_file; do
    # Check for album artwork (covr atom)
    if ! AtomicParsley "$alac_file" -t 2>/dev/null | grep -q "Atom \"covr\""; then
        ALAC_NO_ARTWORK=$((ALAC_NO_ARTWORK + 1))
        echo "  Missing artwork in: $(basename "$alac_file")"
    fi
done

if [ "$ALAC_NO_ARTWORK" -eq 0 ]; then
    print_result 0 "All ALAC files have album artwork"
else
    print_result 1 "$ALAC_NO_ARTWORK ALAC files missing artwork"
fi

# Test 3: File count equality
echo ""
if [ "$FLAC_FILE_COUNT" -eq "$ALAC_FILE_COUNT" ]; then
    print_result 0 "FLAC and ALAC file counts are equal ($FLAC_FILE_COUNT files each)"
else
    print_result 1 "FLAC and ALAC file counts differ (FLAC: $FLAC_FILE_COUNT, ALAC: $ALAC_FILE_COUNT)"
fi

# Summary
echo ""
echo "=== Test Summary ==="
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ "$TESTS_FAILED" -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi
