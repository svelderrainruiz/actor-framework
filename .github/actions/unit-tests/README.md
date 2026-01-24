# Unit Tests (LV2020 32-bit)

Runs LabVIEW unit tests for a specific project using g-cli LUnit.

## Inputs
| Name | Required | Example | Description |
|------|----------|---------|-------------|
| `relative_path` | Yes | `${{ github.workspace }}` | Repository root path. |
| `project_path` | Yes | `Core\Actor Framework Core.lvproj` | Path to the LabVIEW project (.lvproj), relative to the repo root or absolute. |
| `report_path` | No | `builds\logs\UnitTestReport.xml` | Output path for the LUnit report, relative to the repo root or absolute. |
| `minimum_supported_lv_version` | No | `2020` | LabVIEW major version (default: 2020). |
| `supported_bitness` | No | `32` | LabVIEW bitness (default: 32). |

## Quick-start
```yaml
- uses: ./.github/actions/unit-tests
  with:
    relative_path: ${{ github.workspace }}
    project_path: Core\Actor Framework Core.lvproj
    report_path: builds\logs\UnitTestReport.xml
```

## Notes
- Requires `g-cli` with the LUnit command installed on the runner.
- Does not modify LabVIEW.ini or VIPM settings.

## License
This directory inherits the root repository’s license (MIT, unless otherwise noted).
