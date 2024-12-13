<#---
title: Get KPI report data
connection: graph
api: post
tag: devicekpi
---

Synopsis

1. Extracts mails from a specific mailfolder and downloads attachments to a specific folder.
2. If the attachment is an Excel file, it will be imported into a SQL database.
3. The imported data will be transformed into a JSON file
4. The file will be uploaded to a specific folder on a blob site
5. The mail will be moved to an archive folder.
6. An mail will be send with the result of the process.

#>



# Tested with
# -----------------------------------------
# IsIntegerOrMinusOne "nosad" # returns -1
# IsIntegerOrMinusOne "    1 " # returns 1
# IsIntegerOrMinusOne " 2 " # returns 2
param (
    [Parameter(Mandatory = $false)]
    [bool]$dryrun = $false
)
function IsIntegerOrMinusOne($text) {
    # Parse the $text to see if it is an integer or -1

    $integer = -1
    try {
        $parsedInteger = [int]$text
        $integer = $parsedInteger
    }   
    catch {
        # Do nothing,  -1 is the value in case of error
    }
 
    return $integer
}


function Get-KPIValue {
    param (
        [Parameter(Mandatory = $true)]
        [array]$Data,
        [Parameter(Mandatory = $true)]
        [string]$KPI,
 
        [Parameter(Mandatory = $true)]
        [array]$Field
    )

    $result = $Data | Where-Object { $_.kpi -eq $KPI }
    if ($null -eq $result) {
        return -1
    }
    $value = $result.$Field
    if ($null -eq $value) {
        return -1
    }
    return $value
}
<#

## Extract KPIs using SQL
#>


function ExtractKPIs($data) {


  
    $kpis = @{
        "created" = (get-date).ToString("yyyy-MM-ddTHH:mm:ssZ") 
        w5        = @{
            num = Get-KPIValue $data w5 numerator
            den = Get-KPIValue $data w5 denominator
        }
        w6        = @{
            num = Get-KPIValue $data w6 numerator
            den = Get-KPIValue $data w6 denominator
        }
        w8        = @{
            num = Get-KPIValue $data w8 numerator
            den = Get-KPIValue $data w8 denominator
          
        }
        w4        = @{
            num = Get-KPIValue $data w4 numerator
            den = Get-KPIValue $data w4 denominator
          
        }
        w3        = @{
            num = Get-KPIValue $data w3 numerator
            den = Get-KPIValue $data w3 denominator
        }
        w2        = @{
            num = Get-KPIValue $data w2 numerator
            den = Get-KPIValue $data w2 denominator
          
        }
        w7a       = @{
            num = Get-KPIValue $data w7a numerator
         
        }
        w7b       = @{
            num = Get-KPIValue $data w7b numerator
        }

        cs11      = @{
            num = Get-KPIValue $data cs11 numerator
        }
    
  
    }
    $kpis | ConvertTo-Json | Out-File -FilePath (join-path $workdir "kpis.json") -Encoding utf8NoBOM


}

function Update-AzureBlobJsonRest {
    param (
        [Parameter(Mandatory = $true)]
        [string]$JsonFilePath,

        [Parameter(Mandatory = $true)]
        [string]$BlobSasUrl
    )

    # Validate the JSON file path
    if (-not (Test-Path $JsonFilePath)) {
        Write-Error "The specified JSON file does not exist: $JsonFilePath"
        return
    }

    try {
        # Read the JSON file content
        $jsonContent = Get-Content -Path $JsonFilePath -Raw

        # Parse the Blob SAS URL
        $uri = [Uri]::new($BlobSasUrl)
        $blobUri = $uri.AbsoluteUri
        $sasToken = $uri.Query

        # Set the necessary headers for the REST API request
        $headers = @{
            "x-ms-blob-type" = "BlockBlob"
            "x-ms-date"      = (Get-Date).ToString("R")
            "x-ms-version"   = "2020-04-08"
            "Content-Type"   = "application/json"
        }

        # Make the REST API request to upload the JSON file
        $response = Invoke-RestMethod -Uri $blobUri -Method Put -Headers $headers -Body $jsonContent

        Write-Output "The JSON file has been successfully updated on the Azure Blob Storage."
    }
    catch {
        Write-Error "An error occurred: $_"
    }
}

# Example usage:
# Update-AzureBlobJsonRest -JsonFilePath "C:\path\to\your\file.json" -BlobSasUrl "https://yourstorageaccount.blob.core.windows.net/yourcontainer/yourfile.json?sasToken"

<#

## Upload result to Blob
#>

function UploadBlob() {
    # Define the SAS URL and the local file path
    $sasUrl = $env:DEVICEKPIBLOB
    if ($null -eq $sasUrl) {
        throw "DEVICEKPIBLOB environment variable not set"
    }
    $localFilePath = (join-path $workdir "kpis.json")
    Update-AzureBlobJsonRest $localFilePath  $sasUrl 


}



<#

## Process Mail

Prepare mail routine which will look for mails with attachments and process them

#>
if ($null -eq $env:WORKDIR ) {
    $env:WORKDIR = join-path $psscriptroot ".." ".koksmat" "workdir"
}
$workdir = $env:WORKDIR

if (-not (Test-Path $workdir)) {
    New-Item -Path $workdir -ItemType Directory | Out-Null
}


$workdir = Resolve-Path $workdir
Set-Location $workdir
write-host "Workdir: $workdir"


$to = $env:MAILTO # "niels.johansen@nexigroup.com"
$from = $env:MAILFROM  # "valerio.moles@external.nexigroup.com"




# $mailfolders = GraphAPI $env:GRAPH_ACCESSTOKEN "GET" "https://graph.microsoft.com/v1.0/users/$to/mailFolders"

$inboxFolderId = "inbox" # $mailfolders.value | Where-Object { $_.displayName -eq "Inbox" } | Select-Object -ExpandProperty id
$archiveFolderId = "archive" # $mailfolders.value | Where-Object { $_.displayName -eq "Archive" } | Select-Object -ExpandProperty id

$url = @"
https://graph.microsoft.com/v1.0/users/$to/messages?$('$')filter=parentFolderId eq '$inboxFolderId' and from/emailAddress/address eq '$from' and hasAttachments eq true&$('$')expand = attachments
"@


write-host  "Calling Graph to get mails to $to with attachments from $from" 
$mails = GraphAPI $env:GRAPH_ACCESSTOKEN "GET" $url 
# $mails = Get-Content (join-path $workdir "mails.json") | ConvertFrom-Json

if ($null -eq $mails) {
    throw "Failed to get mails"
}

if ($mails.value.Count -eq 0) {
    write-host  "No mails found" 
    return
}

if ($mails.value.Count -gt 1) {
    throw "More than 1 mail found"

}
$foundExcelFile = $false
$mails.value | ForEach-Object {
 
    $mail = $_
    write-host  "Got mail with subject $($mail.subject)" 

    $mail.attachments | ForEach-Object {
      
        $attachment = $_
        if ($attachment.contentType -ne "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet") {
            write-host "Attachment is not an Excel file" -ForegroundColor Yellow
          
        }
        else {
            write-host  "Found Excel file $($attachment.name)" 

          
            $filename = $attachment.name

            $base64String = $attachment.contentBytes
            $fileBytes = [System.Convert]::FromBase64String($base64String)

            $excelfilename = join-path $workdir "devicekpi.xlsx"
            [System.IO.File]::WriteAllBytes($excelfilename, $fileBytes)

            Write-Host "Excel file has been successfully written to $excelfilename"
            $foundExcelFile = $true

            write-host "Converting Excel to JSON"
            magic-mix from excel to json $excelfilename devicekpi
            if ($dryrun) {
                write-host "Dryrun, skipping here"
                return
            }
            
            write-host "Deleting previous imported JSON"
            magic-mix sql exec mix "delete from importdata where name ilike 'devicekpi%'"

            write-host "Uploading JSON"
            magic-mix upload devicekpi

            write-host "Reading KPIs from database"
            [string]$json = magic-mix sql query mix  "select * from devicekpi.kpi" 
            write-host $json 
            $data = $json.Trim() | convertfrom-json
            ExtractKPIs $data
          
            write-host "Uploading KPIs to Blob"
            UploadBlob
    
            
        
        }    
    }
    if ($dryrun) {
        
        return
    }

    if ($foundExcelFile) {
        write-host "Moving mail to archive"
        $moveMessageUrl = "https://graph.microsoft.com/v1.0/users/$to/messages/$($mail.id)/move"

        $moveData = convertto-json @{
            destinationId = $archiveFolderId
        }

        $moveMessageResponse = GraphAPI $env:GRAPH_ACCESSTOKEN "POST"  $moveMessageUrl  $moveData

        if ($null -eq $moveMessageResponse) {
            throw "Failed to move message"
        }
     
    }
    write-host "Done"

}
