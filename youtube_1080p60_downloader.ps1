param(
    [Parameter(Position = 0)]
    [string[]]$Urls,

    [ValidateSet("audio", "video", "both")]
    [string]$Mode,

    [string]$Extension,

    [switch]$NoSplash,

    [ValidateSet("yt", "direct")]
    [string]$Source,

    [string]$Referer,

    [string]$UserAgent
)

$ErrorActionPreference = "Stop"

function Get-YtDlpPrefix {
    $ytdlp = Get-Command yt-dlp -ErrorAction SilentlyContinue
    if ($ytdlp) {
        return @($ytdlp.Source)
    }

    $python = Get-Command python -ErrorAction SilentlyContinue
    if ($python) {
        & python -m yt_dlp --version *> $null
        if ($LASTEXITCODE -eq 0) {
            return @("python", "-m", "yt_dlp")
        }
    }

    return $null
}

function Get-FfmpegPath {
    $ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
    if ($ffmpeg) {
        return $ffmpeg.Source
    }

    $wingetPackages = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Packages"
    if (Test-Path $wingetPackages) {
        $candidate = Get-ChildItem -Path $wingetPackages -Recurse -Filter ffmpeg.exe -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -like "*Gyan.FFmpeg*" } |
            Select-Object -First 1 -ExpandProperty FullName

        if ($candidate) {
            return $candidate
        }
    }

    return $null
}

function Read-MenuChoice {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Question,

        [Parameter(Mandatory = $true)]
        [string[]]$Values,

        [string[]]$Labels
    )

    if (-not $Labels -or $Labels.Count -ne $Values.Count) {
        $Labels = $Values
    }

    while ($true) {
        Write-Host ""
        Write-Host $Question -ForegroundColor Cyan

        for ($i = 0; $i -lt $Labels.Count; $i++) {
            Write-Host ("{0}. {1}" -f ($i + 1), $Labels[$i])
        }

        $choice = Read-Host ("Choose 1-{0}" -f $Labels.Count)
        if ($choice -match '^[0-9]+$') {
            $index = [int]$choice - 1
            if ($index -ge 0 -and $index -lt $Values.Count) {
                return $Values[$index]
            }
        }

        Write-Host "Invalid choice. Try again." -ForegroundColor Yellow
    }
}

function Show-StartupSplash {
    try {
        $Host.UI.RawUI.WindowTitle = "PHANTOM-LINK // Media Ops Console"
    }
    catch {
    }

    Clear-Host

    $banner = @(
        '  ____  _   _    _    _   _ _____ ___  __  __   ',
        ' |  _ \| | | |  / \  | \ | |_   _/ _ \|  \/  |  ',
        ' | |_) | |_| | / _ \ |  \| | | || | | | |\/| |  ',
        ' |  __/|  _  |/ ___ \| |\  | | || |_| | |  | |  ',
        ' |_|   |_| |_/_/   \_\_| \_| |_| \___/|_|  |_|  ',
        '                                                  ',
        ' [ Media Ops Console ] [ 1080p60 ] [ Audio Sync ]'
    )

    $colors = @("DarkGreen", "Green", "DarkGreen", "Green", "DarkGreen", "DarkGray", "Cyan")

    for ($i = 0; $i -lt $banner.Count; $i++) {
        Write-Host $banner[$i] -ForegroundColor $colors[$i]
    }

    Write-Host ""

    $steps = @(
        "Initializing protocol layer",
        "Calibrating codec injector",
        "Routing packet stream",
        "Arming download engine"
    )

    foreach ($step in $steps) {
        Write-Host ("[+] {0,-28} " -f $step) -NoNewline -ForegroundColor DarkGreen
        Start-Sleep -Milliseconds 90
        Write-Host "OK" -ForegroundColor Green
    }

    $operations = @("BLACK-MIRROR", "NIGHT-RUNNER", "PHANTOM-LINK", "ECHO-NULL", "HEX-CASCADE")
    $operation = Get-Random -InputObject $operations
    $session = -join ((48..57 + 65..90) | Get-Random -Count 8 | ForEach-Object { [char]$_ })

    Write-Host ""
    Write-Host (" OPERATION: {0}   SESSION: {1}" -f $operation, $session) -ForegroundColor Yellow
    Write-Host ""
}

if (-not $NoSplash) {
    Show-StartupSplash
}

$ytDlpPrefix = Get-YtDlpPrefix
if (-not $ytDlpPrefix) {
    Write-Host "Missing dependency: yt-dlp" -ForegroundColor Red
    Write-Host "Install example: python -m pip install --user -U yt-dlp" -ForegroundColor Yellow
    exit 1
}

$ffmpegPath = Get-FfmpegPath
if (-not $ffmpegPath) {
    Write-Host "Missing dependency: ffmpeg" -ForegroundColor Red
    Write-Host "Install example: winget install -e --id Gyan.FFmpeg" -ForegroundColor Yellow
    exit 1
}

$ffmpegLocation = Split-Path -Path $ffmpegPath -Parent
if (-not $ffmpegLocation) {
    $ffmpegLocation = $ffmpegPath
}

if (-not $Source) {
    $Source = Read-MenuChoice `
        -Question "Choose source type" `
        -Values @("yt", "direct") `
        -Labels @("YouTube / supported sites", "Direct media link (official mp4/m3u8)")
}

$Source = $Source.ToLowerInvariant()

if (-not $Urls -or $Urls.Count -eq 0) {
    if ($Source -eq "direct") {
        $rawUrls = Read-Host "Paste direct media link(s) separated by space"
    }
    else {
        $rawUrls = Read-Host "Paste YouTube link(s) separated by space"
    }

    if ($rawUrls) {
        $Urls = $rawUrls -split '[,\s]+' | Where-Object { $_ }
    }
}

if (-not $Urls -or $Urls.Count -eq 0) {
    Write-Host "No URL provided." -ForegroundColor Red
    exit 1
}

if (-not $Mode) {
    $Mode = Read-MenuChoice `
        -Question "What do you want to download?" `
        -Values @("audio", "video", "both") `
        -Labels @("Audio only", "Video only", "Video + Audio")
}

$Mode = $Mode.ToLowerInvariant()

$allowedExtensions = @()
$extensionQuestion = ""

switch ($Mode) {
    "audio" {
        $allowedExtensions = @("mp3", "m4a", "opus", "wav", "flac")
        $extensionQuestion = "Choose audio extension"
    }
    "video" {
        $allowedExtensions = @("mp4", "webm", "mkv")
        $extensionQuestion = "Choose video extension"
    }
    "both" {
        $allowedExtensions = @("mp4", "mkv", "webm")
        $extensionQuestion = "Choose final video extension (with audio)"
    }
    default {
        Write-Host "Invalid mode." -ForegroundColor Red
        exit 1
    }
}

if ($Extension) {
    $Extension = $Extension.ToLowerInvariant()
}

if (-not $Extension -or ($allowedExtensions -notcontains $Extension)) {
    $Extension = Read-MenuChoice -Question $extensionQuestion -Values $allowedExtensions
}

if ($Source -eq "direct" -and -not $Referer) {
    $Referer = Read-Host "Optional Referer header (Enter to skip)"
}

if ($Source -eq "direct" -and -not $UserAgent) {
    $UserAgent = Read-Host "Optional User-Agent header (Enter to skip)"
}

$downloadDir = Join-Path $PSScriptRoot "Downloads"
New-Item -ItemType Directory -Path $downloadDir -Force | Out-Null
$outTemplate = Join-Path $downloadDir "%(title).200B [%(id)s].%(ext)s"

$commonArgs = @(
    "--no-playlist",
    "--ffmpeg-location", $ffmpegLocation,
    "--output", $outTemplate,
    "--windows-filenames",
    "--newline"
)

if ($Source -eq "yt") {
    $commonArgs += @("--js-runtimes", "node", "--remote-components", "ejs:github")
}

if ($Source -eq "direct" -and $Referer) {
    $commonArgs += @("--add-header", ("Referer: {0}" -f $Referer))
}

if ($Source -eq "direct" -and $UserAgent) {
    $commonArgs += @("--user-agent", $UserAgent)
}

$modeArgs = @()

if ($Source -eq "yt") {
    switch ($Mode) {
        "audio" {
            $audioFormat = "ba[ext={0}]/ba/bestaudio/best" -f $Extension
            $modeArgs = @(
                "--format", $audioFormat,
                "--extract-audio",
                "--audio-format", $Extension,
                "--audio-quality", "0"
            )
        }
        "video" {
            $videoOnlyFormat = "bv*[height=1080][fps=60][ext={0}]/bv*[height=1080][ext={0}]/bv*[height<=1080][fps<=60][ext={0}]/bv*[height<=1080][fps<=60]" -f $Extension
            $modeArgs = @(
                "--format", $videoOnlyFormat,
                "--remux-video", $Extension
            )
        }
        "both" {
            $mergeFormat = ""

            switch ($Extension) {
                "mp4" {
                    $mergeFormat = "bv*[height=1080][fps=60][ext=mp4]+ba[ext=m4a]/bv*[height=1080][ext=mp4]+ba[ext=m4a]/bv*[height<=1080][fps<=60][ext=mp4]+ba[ext=m4a]/bv*[height=1080][fps=60]+ba/bv*[height=1080]+ba/bv*[height<=1080][fps<=60]+ba/b[height<=1080]"
                }
                "webm" {
                    $mergeFormat = "bv*[height=1080][fps=60][ext=webm]+ba[ext=webm]/bv*[height=1080][ext=webm]+ba[ext=webm]/bv*[height<=1080][fps<=60][ext=webm]+ba[ext=webm]/bv*[height=1080][fps=60]+ba/bv*[height=1080]+ba/bv*[height<=1080][fps<=60]+ba/b[height<=1080]"
                }
                "mkv" {
                    $mergeFormat = "bv*[height=1080][fps=60]+ba/bv*[height=1080]+ba/bv*[height<=1080][fps<=60]+ba/b[height<=1080]"
                }
            }

            $modeArgs = @(
                "--format", $mergeFormat,
                "--merge-output-format", $Extension
            )
        }
    }
}
else {
    switch ($Mode) {
        "audio" {
            $modeArgs = @(
                "--format", "bestaudio/best",
                "--extract-audio",
                "--audio-format", $Extension,
                "--audio-quality", "0"
            )
        }
        "video" {
            $videoFormat = "bestvideo[ext={0}]/bestvideo/best[ext={0}]/best" -f $Extension
            $modeArgs = @(
                "--format", $videoFormat,
                "--remux-video", $Extension
            )
        }
        "both" {
            $modeArgs = @(
                "--format", "bestvideo+bestaudio/best",
                "--merge-output-format", $Extension
            )
        }
    }
}

$prefixArgs = @()
if ($ytDlpPrefix.Count -gt 1) {
    $prefixArgs = $ytDlpPrefix[1..($ytDlpPrefix.Count - 1)]
}

Write-Host ""
Write-Host ("Source: {0} | Mode: {1} | Extension: {2}" -f $Source, $Mode, $Extension) -ForegroundColor Green

foreach ($url in $Urls) {
    Write-Host ""
    Write-Host "Downloading: $url" -ForegroundColor Cyan

    $args = @()
    $args += $commonArgs
    $args += $modeArgs
    $args += $url

    & $ytDlpPrefix[0] @prefixArgs @args

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed for: $url" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Done. Files are saved in: $downloadDir" -ForegroundColor Green
