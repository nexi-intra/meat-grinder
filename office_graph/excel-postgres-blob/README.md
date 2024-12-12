# Get KPI Report Data

This script automates a sequence of tasks to extract KPI data from an Excel attachment in an email, transform it, and upload the results to a database and an Azure Blob Storage container. It also archives the processed email and notifies the user upon completion.

## Overview

The workflow is as follows:

1. **Fetch Email Attachments:**  
   Connects to Microsoft Graph API to retrieve emails matching specific criteria:

   - From a designated sender (`$env:MAILFROM`)
   - Located in the mailbox of a designated recipient (`$env:MAILTO`)
   - With an Excel attachment

2. **Extract and Save Attachments:**  
   The Excel attachment from the matching email is saved into a working directory (specified by `$env:WORKDIR`).

3. **Import Excel Data into SQL:**  
   The script uses `magic-mix` commands (a custom command set) to import the Excel data into a SQL database table.

4. **Transform SQL Data to JSON:**  
   Once imported, the script again uses `magic-mix` to:

   - Delete any previously imported data
   - Upload the current dataset as JSON
   - Query the KPI data from the database

5. **Extract Specific KPI Values:**  
   The script runs a custom PowerShell function `ExtractKPIs` to locate specific KPI values (e.g., w5, w6, w8, etc.) from the extracted data. If a KPI is missing, it returns `-1`.

6. **Generate a `kpis.json` File:**  
   The KPI data is written to `kpis.json` in the working directory.

7. **Upload `kpis.json` to Azure Blob Storage:**  
   Using the `Update-AzureBlobJsonRest` function, the script uploads the KPI JSON file to an Azure Blob Storage container. The SAS URL for blob upload is taken from the environment variable `$env:DEVICEKPIBLOB`.

8. **Archive the Processed Email:**  
   After successful processing, the script moves the original email from the inbox to the `archive` folder.

9. **Result Notification:**  
   (Optional step, if implemented) The script can send out a result notification email detailing the success or failure of the operation.

## Prerequisites

- PowerShell environment
- Microsoft Graph API access token (provided via `$env:GRAPH_ACCESSTOKEN`)
- Valid environment variables:
  - `MAILTO` (The mailbox address to check)
  - `MAILFROM` (The sender address whose emails with attachments we want to process)
  - `WORKDIR` (The working directory where files will be stored)
  - `DEVICEKPIBLOB` (The SAS URL for the Azure Blob upload target)
- The `magic-mix` command must be available and correctly configured for:
  - Converting Excel to JSON
  - Importing JSON data into SQL
  - Querying SQL data

## Functions

### `IsIntegerOrMinusOne($text)`

Parses a string into an integer. If parsing fails, it returns `-1`.

**Usage:**

```powershell
IsIntegerOrMinusOne "nosad"  # returns -1
IsIntegerOrMinusOne "   1 "  # returns 1
IsIntegerOrMinusOne "2"      # returns 2
```

````

### `Get-KPIValue -Data <Array> -KPI <String> -Field <Array>`

Fetches a particular KPI value from the data array based on the KPI name and field (e.g., numerator or denominator). If the KPI or field is not found, returns `-1`.

### `ExtractKPIs($data)`

Takes the structured KPI data (as an array of objects) and:

- Retrieves predefined KPI values (w5, w6, w8, etc.)
- Constructs a dictionary of the KPIs along with a timestamp
- Outputs this dictionary as `kpis.json` in the working directory.

### `Update-AzureBlobJsonRest -JsonFilePath <String> -BlobSasUrl <String>`

Uploads the specified JSON file to Azure Blob Storage using a provided SAS URL.

**Usage:**

```powershell
Update-AzureBlobJsonRest -JsonFilePath "C:\path\to\kpis.json" -BlobSasUrl "https://yourblob.blob.core.windows.net/container/kpis.json?sasToken"
```

### `UploadBlob()`

Wraps `Update-AzureBlobJsonRest` to automatically upload `kpis.json` to the blob location specified by `$env:DEVICEKPIBLOB`.

## Execution Flow

- **Environment Setup:**
  Ensure `WORKDIR` is set. If not, it defaults to `../.koksmat/workdir`.
  Create the directory if it does not exist.

- **Retrieve Mails from Graph API:**
  Searches the inbox for emails from `$env:MAILFROM` that contain attachments.
  If no matching mail is found, the script ends gracefully.
  If more than one matching mail is found, the script throws an error (currently only supports one mail at a time).

- **Process Attachments:**
  For each attachment:

  - Check if it's an Excel file (`.xlsx`).
  - If it is, write it to `devicekpi.xlsx` in `WORKDIR`.

- **Import and Transform Data:**

  - Use `magic-mix` to convert Excel to JSON.
  - Clear old data in the SQL table with `magic-mix sql exec`.
  - Upload the new JSON data into the SQL database.
  - Query the KPI data from the database.

- **Extract and Upload KPIs:**

  - Run `ExtractKPIs` to build the `kpis.json`.
  - Upload `kpis.json` to Azure Blob Storage with `UploadBlob()`.

- **Cleanup:**
  - Move the processed email to the `archive` folder.
  - Complete the script execution.

## Error Handling

- If required environment variables are missing or incorrect, the script will throw exceptions.
- If the Graph API call fails or no mails are found, the script logs the situation and ends.
- If more than one mail with attachments is found, the script aborts to avoid ambiguity.

## Example Usage

```powershell
# Set environment variables
$env:MAILTO = "user@example.com"
$env:MAILFROM = "sender@example.com"
$env:WORKDIR = "C:\KPIWorkdir"
$env:GRAPH_ACCESSTOKEN = "your-graph-api-access-token"
$env:DEVICEKPIBLOB = "https://yourstorage.blob.core.windows.net/container/kpis.json?your-sas-token"

# Run the script
.\GetKpiReportData.ps1
```

Make sure you have all prerequisites and correct environment configurations before executing.

## Notes

- This script utilizes `magic-mix`, which is a placeholder for custom import/export commands. Ensure these commands are defined or replaced with your actual data processing utilities.
- Adjust the `Get-KPIValue` and KPI extraction logic in `ExtractKPIs` if new KPIs need to be included or the source format changes.

```

```
````
