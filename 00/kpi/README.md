# Integration Script

This script orchestrates a data integration workflow that involves:

- Setting up a working directory.
- Checking and ensuring required environment variables are set.
- Connecting to "Magic Mix" and Microsoft Graph APIs.
- Running a PowerShell integration script that pulls data from Excel and Postgres, then stores it as a blob.

## Prerequisites

- **PowerShell 5.x or later** (Windows) or [PowerShell Core](https://github.com/PowerShell/PowerShell) (cross-platform).
- Properly configured environment variables:

  - `DEVICEKPIBLOB`
  - `GRAPH_APPID`
  - `GRAPH_APPSECRET`
  - `GRAPH_APPDOMAIN`
  - `POSTGRES_DB`
  - `MAILTO`
  - `MAILFROM`

  These variables are checked at runtime to ensure the necessary values are present.

- Access to the `.koksmat` directory structure, which contains:
  - A `workdir` directory for temporary or intermediate files.
  - A `pwsh` directory with connector scripts (`connect.ps1`) for Magic Mix and Office Graph.
  - The `excel-postgres-blob/run.ps1` script that performs the actual integration process.

## Script Overview

1. **Parameter:**

   - `$dryrun` (optional, defaults to `false`):  
     If set to `true`, the script will run in "dry run" mode, allowing you to test the connections and setup without executing the final data integration step.

2. **Workdir Setup:**

   - The script establishes a `workdir` path within `.koksmat/workdir`.
   - If it doesn’t exist, the script creates it.
   - The `WORKDIR` environment variable is set to this path for subsequent operations.

3. **Root Directory Resolution:**

   - The script determines the repository’s root directory and sets it as `$root`.
   - This path is used to locate and run sub-scripts required for the integration process.

4. **Environment Checks:**

   - Invokes `check-env.ps1` to confirm that all necessary environment variables are set.
   - If any are missing or invalid, the script will fail with a descriptive error.

5. **Connecting to External Services:**

   - `connect.ps1` within the Magic Mix connector initializes a connection to Magic Mix.
   - `connect.ps1` in the Graph connector does the same for Microsoft Graph APIs.

6. **Running the Integration:**
   - Finally, the script runs `excel-postgres-blob/run.ps1` from the root directory.
   - If `$dryrun` is `true`, the integration script will simulate the process without performing any write operations.

## Usage

**Example:**

```powershell
# To run the script normally:
.\YourScriptName.ps1

# To run in dry run mode:
.\YourScriptName.ps1 -dryrun $true
```

## Troubleshooting

- **Missing Environment Variables:**  
  Ensure all required environment variables are set.  
  Example (Windows):
  ```powershell
  $env:GRAPH_APPID = "your-app-id"
  $env:GRAPH_APPSECRET = "your-app-secret"
  ```
- **Connectivity Issues:**
  If you experience errors connecting to Magic Mix or Office Graph, verify your network settings, credentials, and that the appropriate connector scripts are present and accessible.

- **File Paths:**
  Double-check directory structure to ensure `.koksmat/pwsh` and `.koksmat/workdir` are correctly located relative to the script. All paths are resolved at runtime.

## Contributing

If you need to modify or extend the integration process:

1. Update environment checks as necessary.
2. Adjust the connector scripts (`connect.ps1`) to include new services or endpoints.
3. Modify `excel-postgres-blob/run.ps1` if the business logic of the integration changes.

Please submit a pull request or open an issue for any fixes or enhancements.
