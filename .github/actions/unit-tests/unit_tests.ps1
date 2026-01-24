<#
.SYNOPSIS
    Runs LabVIEW unit tests for a specific project using g-cli LUnit.

.DESCRIPTION
    Resolves project and report paths relative to the repo root and invokes
    the shared RunUnitTests.ps1 script. No LabVIEW.ini or VIPM settings are changed.

.PARAMETER RelativePath
    Path to the repository root.

.PARAMETER ProjectPath
    Path to the LabVIEW project (.lvproj), relative to the repo root or absolute.

.PARAMETER ReportPath
    Path for the UnitTestReport.xml output, relative to the repo root or absolute.

.PARAMETER MinimumSupportedLVVersion
    LabVIEW major version (default: 2020).

.PARAMETER SupportedBitness
    LabVIEW bitness (default: 32).
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$RelativePath,

    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,

    [string]$ReportPath = "builds\\logs\\UnitTestReport.xml",

    [string]$MinimumSupportedLVVersion = "2020",

    [ValidateSet("32", "64")]
    [string]$SupportedBitness = "32"
)

if (-not (Test-Path -Path $RelativePath)) {
    Write-Error "RelativePath does not exist: $RelativePath"
    exit 1
}

$resolvedProjectPath = $ProjectPath
if (-not [System.IO.Path]::IsPathRooted($resolvedProjectPath)) {
    $resolvedProjectPath = Join-Path -Path $RelativePath -ChildPath $resolvedProjectPath
}
$resolvedProjectPath = [System.IO.Path]::GetFullPath($resolvedProjectPath)

$resolvedReportPath = $ReportPath
if ([string]::IsNullOrWhiteSpace($resolvedReportPath)) {
    $resolvedReportPath = "builds\\logs\\UnitTestReport.xml"
}
if (-not [System.IO.Path]::IsPathRooted($resolvedReportPath)) {
    $resolvedReportPath = Join-Path -Path $RelativePath -ChildPath $resolvedReportPath
}
$resolvedReportPath = [System.IO.Path]::GetFullPath($resolvedReportPath)

$actionsPath = Split-Path -Parent $PSScriptRoot
$runUnitTests = Join-Path $actionsPath "run-unit-tests\\RunUnitTests.ps1"

if (-not (Test-Path -Path $runUnitTests)) {
    Write-Error "RunUnitTests.ps1 not found at: $runUnitTests"
    exit 1
}

Write-Host "Running unit tests using LabVIEW $MinimumSupportedLVVersion ($SupportedBitness-bit)"
Write-Host "Project Path: $resolvedProjectPath"
Write-Host "Report Path:  $resolvedReportPath"

& $runUnitTests `
    -MinimumSupportedLVVersion $MinimumSupportedLVVersion `
    -SupportedBitness $SupportedBitness `
    -ProjectPath $resolvedProjectPath `
    -ReportPath $resolvedReportPath

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
