# Compute Version

This composite action determines the semantic version for the build based on the `Library_Version` in a VIPB file, plus commit history for the build number. Prerelease suffixes are still derived from branch naming conventions.

## Inputs
- `github_token`: GitHub token with repository access.
- `vipb_path`: Path to the VIPB file used to derive `MAJOR`, `MINOR`, and `PATCH`.

## Outputs
- `VERSION`: Full version string (e.g. `v1.2.3-build4`).
- `MAJOR`, `MINOR`, `PATCH`: Numeric version components.
- `BUILD`: Commit-based build number.
- `IS_PRERELEASE`: `true` when branch naming implies prerelease.

## Example
```yaml
- id: version
  uses: ./.github/actions/compute-version
  with:
    github_token: ${{ secrets.GITHUB_TOKEN }}
    vipb_path: Core/Actor Framework 2024 for 2020.vipb
- run: echo "Version is ${{ steps.version.outputs.VERSION }}"
```
