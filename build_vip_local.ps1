#Requires -Version 5.1

[CmdletBinding()]
param(
    [string]$VipbPath = "Core/Actor Framework 2024 for 2020.vipb",
    [int]$MinimumSupportedLVVersion = 2020,
    [ValidateSet("32","64")]
    [string]$SupportedBitness = "32",
    [ValidateSet("0","3")]
    [string]$LabVIEWMinorRevision = "0",
    [int]$Major,
    [int]$Minor,
    [int]$Patch,
    [int]$Build,
    [string]$ReleaseNotesFile = "builds/release_notes.md",
    [int]$VipmTimeoutSeconds = 900,
    [switch]$KillLabVIEW,
    [switch]$SkipClean,
    [string]$GcliExe
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-RepoRoot {
    return (Resolve-Path -Path $PSScriptRoot).ProviderPath
}

function Get-VipbVersion {
    param([string]$VipbFile)

    [xml]$vipbXml = Get-Content -Raw -LiteralPath $VipbFile
    $version = $vipbXml.VI_Package_Builder_Settings.Library_General_Settings.Library_Version
    if ([string]::IsNullOrWhiteSpace($version)) {
        throw "Library_Version not found in VIPB file: $VipbFile"
    }

    $parts = $version.Split('.')
    if ($parts.Length -lt 3) {
        throw "Unexpected Library_Version format '$version' in $VipbFile"
    }

    [pscustomobject]@{
        Major = [int]$parts[0]
        Minor = [int]$parts[1]
        Patch = [int]$parts[2]
        Build = if ($parts.Length -ge 4) { [int]$parts[3] } else { 0 }
    }
}

function Get-GitBuildNumber {
    param([string]$RepoRoot)
    try {
        $count = & git -C $RepoRoot rev-list --count HEAD 2>$null
        if ($LASTEXITCODE -eq 0 -and $count) {
            return [int]$count
        }
    }
    catch {
    }
    return $null
}

function Remove-ExistingVip {
    param([string]$Dir)

    if (-not (Test-Path -LiteralPath $Dir)) {
        New-Item -ItemType Directory -Path $Dir -Force | Out-Null
        return
    }

    $existingVip = Get-ChildItem -Path $Dir -Filter *.vip -File -Recurse
    if (-not $existingVip) {
        return
    }

    foreach ($file in $existingVip) {
        Remove-Item -LiteralPath $file.FullName -Force -ErrorAction Stop
    }
}

$repoRoot = Resolve-RepoRoot
$vipbFullPath = Resolve-Path -Path (Join-Path $repoRoot $VipbPath) -ErrorAction Stop

$vipbVersion = Get-VipbVersion -VipbFile $vipbFullPath
if (-not $Major) { $Major = $vipbVersion.Major }
if (-not $Minor) { $Minor = $vipbVersion.Minor }
if (-not $Patch) { $Patch = $vipbVersion.Patch }
if (-not $Build) {
    $gitBuild = Get-GitBuildNumber -RepoRoot $repoRoot
    $Build = if ($gitBuild) { $gitBuild } else { $vipbVersion.Build }
}

Write-Host ("Using version: {0}.{1}.{2}.{3}" -f $Major, $Minor, $Patch, $Build)

if (-not $SkipClean) {
    $vipDir = Join-Path -Path $repoRoot -ChildPath "Builds"
    Remove-ExistingVip -Dir $vipDir
}

if ($GcliExe) {
    $Env:GCLI_EXE = $GcliExe
}

& (Join-Path $repoRoot ".github\\actions\\generate-release-notes\\GenerateReleaseNotes.ps1") `
    -OutputPath $ReleaseNotesFile

$displayInfo = @{ "Package Version" = @{ major = $Major; minor = $Minor; patch = $Patch; build = $Build } } |
    ConvertTo-Json -Depth 5 -Compress
$commit = & git -C $repoRoot rev-parse HEAD

$buildScript = Join-Path $repoRoot ".github\\actions\\build-vip\\build_vip.ps1"
if (-not (Test-Path -LiteralPath $buildScript)) {
    throw "build_vip.ps1 not found at $buildScript"
}

    & $buildScript `
        -SupportedBitness $SupportedBitness `
        -RelativePath $repoRoot `
        -VIPBPath $VipbPath `
        -MinimumSupportedLVVersion $MinimumSupportedLVVersion `
        -LabVIEWMinorRevision $LabVIEWMinorRevision `
        -Major $Major `
        -Minor $Minor `
        -Patch $Patch `
        -Build $Build `
        -Commit $commit `
        -ReleaseNotesFile (Join-Path $repoRoot $ReleaseNotesFile) `
        -VipmTimeoutSeconds $VipmTimeoutSeconds `
        -KillLabVIEW:$KillLabVIEW `
        -DisplayInformationJSON $displayInfo
