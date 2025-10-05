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
./build_alac.sh "alttp enhanced soundtrack pcm.rar"
```

Convert to FLAC:
```bash
./build_alac.sh -f flac "alttp enhanced soundtrack pcm.rar"
```

Specify custom output directory:
```bash
./build_alac.sh -f alac -o ./custom_output "alttp enhanced soundtrack pcm.rar"
```

## Architecture

### Audio Conversion Process

1. **Extraction**: PCM files are extracted from RAR archive to a temporary directory
2. **Conversion**: Each PCM file is converted using ffmpeg:
   - Skips the 8-byte MSU-1 header (`-skip_initial_bytes 8`)
   - Assumes 16-bit stereo PCM at 44.1kHz (`-f s16le -ar 44100 -ac 2`)
   - Outputs to either FLAC or ALAC format
3. **Metadata**: Track metadata is applied using format-specific tools:
   - FLAC: `metaflac` with Vorbis comments
   - ALAC: `AtomicParsley` with MP4 atoms
4. **Cleanup**: Temporary extraction directory is removed

### Track Metadata

Track metadata is hardcoded in the `TRACKS` array in `build_alac.sh:157-191`. Each entry contains:
- Filename (e.g., "alttp_msu-1")
- Title (e.g., "Title Screen")
- Track number

Album metadata:
- Artist: "Zerethn"
- Album: "A Link to the Past: Enhanced Soundtrack"

Note: The script includes 33 tracks but track 15 ("Great Victory!") is not in the PCM archive, so it's excluded from the metadata array.
