# A Link to the Past: Enhanced Soundtrack Converter

Convert Zerethn's [A Link to the Past: Enhanced Soundtrack](https://www.youtube.com/watch?v=I_jMOfoflMY&t=370s) from MSU-1 PCM format to FLAC or ALAC with full metadata tagging.

## Quick Start

1. Download the PCM RAR archive from the [YouTube video description](https://www.youtube.com/watch?v=I_jMOfoflMY&t=370s)
2. Install prerequisites (see below)
3. Run the conversion script:

```bash
./build_alac.sh "alttp enhanced soundtrack pcm.rar"
```

## Prerequisites

Install via Homebrew:

```bash
brew install unrar ffmpeg flac atomicparsley
```

- **unrar** - Extract RAR archives
- **ffmpeg** - Audio conversion
- **flac** - FLAC metadata tagging (metaflac)
- **atomicparsley** - ALAC/M4A metadata tagging

## Usage

**Convert to ALAC (default):**
```bash
./build_alac.sh "alttp enhanced soundtrack pcm.rar"
```

**Convert to FLAC:**
```bash
./build_alac.sh -f flac "alttp enhanced soundtrack pcm.rar"
```

**Custom output directory:**
```bash
./build_alac.sh -f alac -o ./my_music "alttp enhanced soundtrack pcm.rar"
```

**View all options:**
```bash
./build_alac.sh --help
```

## Output

The script will:
- Extract all PCM files from the RAR archive
- Convert to your chosen format (FLAC or ALAC)
- Apply metadata (artist, album, title, track number)
- Save files to `./flac_output` or `./alac_output` (or your custom directory)

All 33 tracks will be properly tagged with:
- **Artist:** Zerethn
- **Album:** A Link to the Past: Enhanced Soundtrack
- **Track titles and numbers**

## About the Soundtrack

Zerethn's Enhanced Soundtrack is a collection of music arrangements covering the entire A Link to the Past soundtrack. The arrangements are stylized to match the N64-GameCube era sound while retaining the original tone and feeling of the SNES classic.
