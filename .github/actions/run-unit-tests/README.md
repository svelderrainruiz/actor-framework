# Run Unit Tests

Invoke `RunUnitTests.ps1` to execute LabVIEW unit tests via g-cli and write a
JUnit-style XML report.

## Inputs
| Name | Required | Example | Description |
|------|----------|---------|-------------|
| `minimum_supported_lv_version` | Yes | `2020` | LabVIEW major version. |
| `supported_bitness` | Yes | `32` or `64` | Target LabVIEW bitness. |
| `project_path` | Yes | `Core\Actor Framework Core.lvproj` | Path to the LabVIEW project (.lvproj), relative to the repo root or absolute. |
| `report_path` | No | `builds\logs\UnitTestReport.xml` | Output path for the LUnit report, relative to the repo root or absolute. |

## Quick-start
```yaml
- uses: ./.github/actions/run-unit-tests
  with:
    minimum_supported_lv_version: 2020
    supported_bitness: 32
    project_path: Core\Actor Framework Core.lvproj
    report_path: builds\logs\UnitTestReport.xml
```

## Notes
- Requires `g-cli` with the LUnit command installed on the runner.
- Does not modify LabVIEW.ini or VIPM settings.

## License
This directory inherits the root repository’s license (MIT, unless otherwise noted).
