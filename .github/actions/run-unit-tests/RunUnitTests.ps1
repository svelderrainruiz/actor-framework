<#
.SYNOPSIS
    Run LabVIEW unit tests using g-cli and output a color-coded table of results.

.DESCRIPTION
    Executes LUnit against a specific LabVIEW project and writes a JUnit-style
    report XML to a configurable path. No LabVIEW.ini or VIPM settings are changed.

.PARAMETER MinimumSupportedLVVersion
    LabVIEW minimum supported version (e.g., "2020").

.PARAMETER SupportedBitness
    Bitness for LabVIEW ("32" or "64").

.PARAMETER ProjectPath
    Path to the LabVIEW project (.lvproj), relative to the repo root or absolute.

.PARAMETER ReportPath
    Path for the UnitTestReport.xml output, relative to the repo root or absolute.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$MinimumSupportedLVVersion,

    [Parameter(Mandatory = $true)]
    [ValidateSet("32", "64")]
    [string]$SupportedBitness,

    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,

    [string]$ReportPath
)

if (-not (Get-Command g-cli -ErrorAction SilentlyContinue)) {
    Write-Error "g-cli.exe not found in PATH."
    exit 1
}

$workspaceRoot = (Get-Location).Path

if (-not [System.IO.Path]::IsPathRooted($ProjectPath)) {
    $ProjectPath = Join-Path -Path $workspaceRoot -ChildPath $ProjectPath
}
$ProjectPath = [System.IO.Path]::GetFullPath($ProjectPath)

if (-not (Test-Path -Path $ProjectPath)) {
    Write-Error "LabVIEW project not found at: $ProjectPath"
    exit 1
}

if ([string]::IsNullOrWhiteSpace($ReportPath)) {
    $ReportPath = Join-Path -Path $workspaceRoot -ChildPath "builds\\logs\\UnitTestReport.xml"
}
elseif (-not [System.IO.Path]::IsPathRooted($ReportPath)) {
    $ReportPath = Join-Path -Path $workspaceRoot -ChildPath $ReportPath
}
$ReportPath = [System.IO.Path]::GetFullPath($ReportPath)

$reportDir = Split-Path -Parent $ReportPath
if (-not (Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
}

Write-Host "Running unit tests for LabVIEW $MinimumSupportedLVVersion ($SupportedBitness-bit)"
Write-Host "Project Path: $ProjectPath"
Write-Host "Report Path:  $ReportPath"

$Script:OriginalExitCode = 0
$Script:TestsHadFailures = $false

function Setup {
    if (Test-Path $ReportPath) {
        try {
            Remove-Item $ReportPath -Force -ErrorAction Stop
            Write-Host "Deleted existing UnitTestReport.xml."
        }
        catch {
            Write-Warning "Could not remove UnitTestReport.xml: $($_.Exception.Message)"
        }
    }
}

function MainSequence {
    Write-Host "`n=== MainSequence ==="
    Write-Host "Executing g-cli command..."
    & g-cli --lv-ver $MinimumSupportedLVVersion --arch $SupportedBitness lunit -- -r "$ReportPath" "$ProjectPath"

    $script:OriginalExitCode = $LASTEXITCODE
    if ($script:OriginalExitCode -ne 0) {
        Write-Error "g-cli test execution failed (exit code $script:OriginalExitCode)."
    }

    if ($script:OriginalExitCode -ne 0 -and -not (Test-Path $ReportPath)) {
        $script:TestsHadFailures = $true
        Write-Warning "No test report found, and g-cli returned an error."
        return
    }

    if (-not (Test-Path $ReportPath)) {
        Write-Error "UnitTestReport.xml not found; cannot parse results."
        $script:TestsHadFailures = $true
        return
    }

    try {
        [xml]$xmlDoc = Get-Content $ReportPath -ErrorAction Stop
    }
    catch {
        Write-Error "UnitTestReport.xml is invalid or malformed: $($_.Exception.Message)"
        $script:TestsHadFailures = $true
        return
    }

    $testCases = $xmlDoc.SelectNodes("//testcase")
    if (!$testCases -or $testCases.Count -eq 0) {
        Write-Error "No <testcase> entries found in UnitTestReport.xml."
        $script:TestsHadFailures = $true
        return
    }

    $col1 = "TestCaseName"; $col2 = "ClassName"; $col3 = "Status"; $col4 = "Time(s)"; $col5 = "Assertions"
    $maxName   = $col1.Length
    $maxClass  = $col2.Length
    $maxStatus = $col3.Length
    $maxTime   = $col4.Length
    $maxAssert = $col5.Length

    $results = @()
    foreach ($case in $testCases) {
        $name       = [string]$case.GetAttribute("name")
        $className  = [string]$case.GetAttribute("classname")
        $status     = [string]$case.GetAttribute("status")
        $time       = [string]$case.GetAttribute("time")
        $assertions = [string]$case.GetAttribute("assertions")

        if ([string]::IsNullOrWhiteSpace($status)) {
            $status = "Skipped"
        }

        if ($name.Length       -gt $maxName)   { $maxName   = $name.Length }
        if ($className.Length  -gt $maxClass)  { $maxClass  = $className.Length }
        if ($status.Length     -gt $maxStatus) { $maxStatus = $status.Length }
        if ($time.Length       -gt $maxTime)   { $maxTime   = $time.Length }
        if ($assertions.Length -gt $maxAssert) { $maxAssert = $assertions.Length }

        $results += [PSCustomObject]@{
            TestCaseName = $name
            ClassName    = $className
            Status       = $status
            Time         = $time
            Assertions   = $assertions
        }

        if ($status -notmatch "^Passed$" -and $status -notmatch "^Skipped$") {
            $script:TestsHadFailures = $true
        }
    }

    $header = ($col1.PadRight($maxName) + "  " +
               $col2.PadRight($maxClass) + "  " +
               $col3.PadRight($maxStatus) + "  " +
               $col4.PadRight($maxTime) + "  " +
               $col5.PadRight($maxAssert))
    Write-Host $header

    foreach ($res in $results) {
        $line = ($res.TestCaseName.PadRight($maxName) + "  " +
                 $res.ClassName.PadRight($maxClass)   + "  " +
                 $res.Status.PadRight($maxStatus)     + "  " +
                 $res.Time.PadRight($maxTime)         + "  " +
                 $res.Assertions.PadRight($maxAssert))

        if ($res.Status -eq "Passed") {
            Write-Host $line -ForegroundColor Green
        }
        elseif ($res.Status -eq "Skipped") {
            Write-Host $line -ForegroundColor Yellow
        }
        else {
            Write-Host $line -ForegroundColor Red
        }
    }
}

try {
    Setup
    MainSequence
}
catch {
    if ($Script:OriginalExitCode -eq 0) {
        $Script:OriginalExitCode = 1
    }
    $Script:TestsHadFailures = $true
    Write-Warning ("Unhandled exception during test run: {0}" -f $_.Exception.Message)
}

if ($Script:OriginalExitCode -ne 0) {
    exit $Script:OriginalExitCode
}
elseif ($Script:TestsHadFailures) {
    exit 2
}
else {
    exit 0
}
