# YouTube Downloader

Windows-friendly PowerShell downloader for YouTube and direct media links, built around `yt-dlp` and `ffmpeg`.

## What It Does

- Downloads from YouTube and other `yt-dlp`-supported sites
- Supports direct media links such as `mp4` or `m3u8`
- Downloads:
  - audio only
  - video only
  - video + audio
- Lets you choose the final output extension
- Saves files into the local `Downloads` folder next to the script
- Offers an interactive menu when arguments are not provided

## Files

- `youtube_1080p60_downloader.bat`
  - Simple launcher for double-click usage on Windows
- `youtube_1080p60_downloader.ps1`
  - Main PowerShell script
- `Downloads/`
  - Generated output folder for downloaded media

## Requirements

Required:

- `yt-dlp`
- `ffmpeg`

Recommended:

- `Node.js`
  - The script requests a Node-based JS runtime for YouTube and supported sites when needed

## Install Notes

### Install dependencies

Examples:

```powershell
python -m pip install --user -U yt-dlp
winget install -e --id Gyan.FFmpeg
winget install -e --id OpenJS.NodeJS.LTS
```

### Verify installation

```powershell
yt-dlp --version
ffmpeg -version
node -v
```

If `yt-dlp` is not directly in `PATH`, the script also tries:

```powershell
python -m yt_dlp --version
```

`ffmpeg` detection behavior:
- first checks `ffmpeg` in `PATH`
- then searches common WinGet install paths for `Gyan.FFmpeg`

## Usage

### Easiest Windows usage

Double-click:

```text
youtube_1080p60_downloader.bat
```

The script will ask for:
- source type
- URL or URLs
- mode
- extension
- optional headers for direct links

### Run from PowerShell

Interactive without splash:

```powershell
powershell -ExecutionPolicy Bypass -File .\youtube_1080p60_downloader.ps1 -NoSplash
```

### CLI Examples

YouTube or supported site, merged video + audio:

```powershell
powershell -ExecutionPolicy Bypass -File .\youtube_1080p60_downloader.ps1 `
  -Source yt `
  -Urls "https://www.youtube.com/watch?v=VIDEO_ID" `
  -Mode both `
  -Extension mp4
```

Audio only:

```powershell
powershell -ExecutionPolicy Bypass -File .\youtube_1080p60_downloader.ps1 `
  -Source yt `
  -Urls "https://www.youtube.com/watch?v=VIDEO_ID" `
  -Mode audio `
  -Extension mp3
```

Video only:

```powershell
powershell -ExecutionPolicy Bypass -File .\youtube_1080p60_downloader.ps1 `
  -Source yt `
  -Urls "https://www.youtube.com/watch?v=VIDEO_ID" `
  -Mode video `
  -Extension mp4
```

Multiple URLs in one run:

```powershell
powershell -ExecutionPolicy Bypass -File .\youtube_1080p60_downloader.ps1 `
  -Source yt `
  -Urls "https://www.youtube.com/watch?v=AAA","https://www.youtube.com/watch?v=BBB" `
  -Mode both `
  -Extension mkv
```

Direct media link with optional headers:

```powershell
powershell -ExecutionPolicy Bypass -File .\youtube_1080p60_downloader.ps1 `
  -Source direct `
  -Urls "https://example.com/video.m3u8" `
  -Mode both `
  -Extension mp4 `
  -Referer "https://example.com/" `
  -UserAgent "Mozilla/5.0"
```

## Output

Downloaded files are saved in:

```text
.\Downloads\
```

Filename template:

```text
%(title).200B [%(id)s].%(ext)s
```

## Current Behavior

- YouTube mode prefers high-quality video, including `1080p60` when available
- Audio mode extracts audio and converts it to the selected audio format
- Video mode downloads video-only output
- Both mode merges video and audio into the selected container
- Direct-link mode supports optional `Referer` and `User-Agent` headers

## Troubleshooting

- `Missing dependency: yt-dlp`
  - Install `yt-dlp` or make sure `python -m yt_dlp` works
- `Missing dependency: ffmpeg`
  - Install `ffmpeg` and make sure it is in `PATH` or installed through WinGet in a detectable location
- direct links fail
  - try adding the correct `Referer` and `User-Agent`
- YouTube extraction behaves inconsistently
  - update `yt-dlp` and make sure `Node.js` is installed

## Known Limitations

- Depends on external tools: `yt-dlp`, `ffmpeg`, and sometimes `Node.js`
- Site-specific behavior may change as YouTube and other platforms update their delivery methods
- Some direct media links require the correct headers to work
- This project currently has no automated test suite

## Legal Note

Use this tool only for content you have the right to download. Platform terms, copyright rules, and local laws still apply.

## GitHub Notes

Files in `Downloads/` are generated output and should not be committed.
