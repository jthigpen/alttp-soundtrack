# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository converts Zerethn's "A Link to the Past: Enhanced Soundtrack" from MSU-1 PCM format to standard audio formats (FLAC or ALAC). The source PCM files come from a RAR archive downloaded from the YouTube video description at https://www.youtube.com/watch?v=I_jMOfoflMY&t=370s.

## Prerequisites

Install the following tools via Homebrew:
- `brew install unrar` - For extracting RAR archives
- `brew install ffmpeg` - For audio conversion
- `brew install flac` - For FLAC metadata tagging (metaflac)
- `brew install atomicparsley` - For ALAC/M4A metadata tagging

## Build Commands

Convert to ALAC (default):
```bash
./build_alttp.sh "alttp enhanced soundtrack pcm.rar"
```

Convert to FLAC:
```bash
./build_alttp.sh -f flac "alttp enhanced soundtrack pcm.rar"
```

Specify custom output directory:
```bash
./build_alttp.sh -f alac -o ./custom_output "alttp enhanced soundtrack pcm.rar"
```

Run tests:
```bash
./test-build.sh
```

## Architecture

### Audio Conversion Process

1. **Verification**: MD5 checksum is verified against expected hash `e233042432a4693f315cd3c190c63f0a` to ensure file integrity
2. **Extraction**: PCM files are extracted from RAR archive to a temporary directory
3. **Conversion**: Each PCM file is converted using ffmpeg:
   - Skips the 8-byte MSU-1 header (`-skip_initial_bytes 8`)
   - Assumes 16-bit stereo PCM at 44.1kHz (`-f s16le -ar 44100 -ac 2`)
   - Outputs to either FLAC or ALAC format
4. **Metadata**: Track metadata is applied using format-specific tools:
   - FLAC: `metaflac` with Vorbis comments and embedded album artwork
   - ALAC: `AtomicParsley` with MP4 atoms and embedded album artwork
   - Album artwork: `alttp-box.png` from the script directory
5. **Cleanup**: Temporary extraction directory is removed

### Track Metadata

Track metadata is hardcoded in the `TRACKS` array in `build_alttp.sh` (around line 210). The array contains 39 entries total:
- 33 main soundtrack tracks (alttp_msu-1 through alttp_msu-34, excluding track 15)
- 4 bonus tracks (variants of 5, 7, 21, 22 with "-bonus-tracks" suffix)
- 2 "No SFX" versions (variants of 10, 29 with "-no-sfx" suffix)

Each entry contains:
- Filename (e.g., "alttp_msu-1" or "alttp_msu-5-bonus-tracks")
- Title (e.g., "Title Screen" or "Majestic Castle (Bonus)")
- Track number (1-40)

Album metadata:
- Artist: "Zerethn"
- Album: "A Link to the Past: Enhanced Soundtrack"

**Important**: The RAR archive contains duplicate filenames in different directories (Extras/Bonus Tracks and Extras/No SFX). The script preserves all variants by appending suffixes to distinguish them.
