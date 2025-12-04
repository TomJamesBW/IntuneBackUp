# Intune Full Backup Script
$tenantId = "<TENANT ID>"
$clientId = "<CLIENT ID>"
$clientSecret = "<CLIENT SECRET>"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$baseDir = Join-Path $Home "IntuneExport-$timestamp"

# Subfolders for each Intune object type
$folders = @{
  "Configuration"     = @(
    "deviceConfigurations",
    "configurationPolicies",
    "deviceManagementScripts",
    "deviceCategories"
  )
  "Compliance"        = @(
    "deviceCompliancePolicies",
    "deviceCompliancePolicyDeviceStateSummary",
    "deviceCompliancePolicySettingStateSummaries"
  )
  "Apps"              = @()
  "Enrollment"        = @(
    "deviceEnrollmentConfigurations",
    "windowsAutopilotDeploymentProfiles"
  )
  "Devices"           = @(
    "managedDevices"
  )
  "Roles"             = @(
    "roleAssignments",
    "roleDefinitions"
  )
  "ConditionalAccess" = @()
}

# Create base and subdirectories
New-Item -ItemType Directory -Path $baseDir -Force | Out-Null
foreach ($folder in $folders.Keys) {
  $subDir = Join-Path $baseDir $folder
  New-Item -ItemType Directory -Path $subDir -Force | Out-Null
}

# Login to Azure using service principal
az login --service-principal -u $clientId -p $clientSecret --tenant $tenantId

# Helper function to export each endpoint
function Export-IntuneObject {
  param (
    [string]$endpoint,
    [string]$folder
  )
  $url = "https://graph.microsoft.com/beta/deviceManagement/$endpoint"
  $outFile = Join-Path (Join-Path $baseDir $folder) ("$endpoint.json")
  Write-Host "Exporting $endpoint to $outFile"
  az rest --method get --url $url --headers "Content-Type=application/json" | Out-File -FilePath $outFile
}

# Export all objects
foreach ($folder in $folders.Keys) {
  foreach ($endpoint in $folders[$folder]) {
    Export-IntuneObject -endpoint $endpoint -folder $folder
  }
}



# Export Mobile Apps (outside deviceManagement)
# Export all objects
foreach ($folder in $folders.Keys) {
  foreach ($endpoint in $folders[$folder]) {
    Export-IntuneObject -endpoint $endpoint -folder $folder
  }
}

# Export Managed App Statuses (outside deviceManagement)
$managedAppStatusesUrl = "https://graph.microsoft.com/beta/deviceAppManagement/managedAppStatuses"
$managedAppStatusesOutFile = Join-Path (Join-Path $baseDir "Apps") "managedAppStatuses.json"
Write-Host "Exporting Managed App Statuses to $managedAppStatusesOutFile"
az rest --method get --url $managedAppStatusesUrl --headers "Content-Type=application/json" | Out-File -FilePath $managedAppStatusesOutFile

# Export Managed App Registrations (outside deviceManagement)
$managedAppRegistrationsUrl = "https://graph.microsoft.com/beta/deviceAppManagement/managedAppRegistrations"
$managedAppRegistrationsOutFile = Join-Path (Join-Path $baseDir "Apps") "managedAppRegistrations.json"
Write-Host "Exporting Managed App Registrations to $managedAppRegistrationsOutFile"
az rest --method get --url $managedAppRegistrationsUrl --headers "Content-Type=application/json" | Out-File -FilePath $managedAppRegistrationsOutFile
$iosManagedAppProtectionsUrl = "https://graph.microsoft.com/beta/deviceAppManagement/iosManagedAppProtections"
$iosManagedAppProtectionsOutFile = Join-Path (Join-Path $baseDir "Apps") "iosManagedAppProtections.json"
Write-Host "Exporting iOS Managed App Protections to $iosManagedAppProtectionsOutFile"
az rest --method get --url $iosManagedAppProtectionsUrl --headers "Content-Type=application/json" | Out-File -FilePath $iosManagedAppProtectionsOutFile

$androidManagedAppProtectionsUrl = "https://graph.microsoft.com/beta/deviceAppManagement/androidManagedAppProtections"
$androidManagedAppProtectionsOutFile = Join-Path (Join-Path $baseDir "Apps") "androidManagedAppProtections.json"
Write-Host "Exporting Android Managed App Protections to $androidManagedAppProtectionsOutFile"
az rest --method get --url $androidManagedAppProtectionsUrl --headers "Content-Type=application/json" | Out-File -FilePath $androidManagedAppProtectionsOutFile

$managedAppPoliciesUrl = "https://graph.microsoft.com/beta/deviceAppManagement/managedAppPolicies"
$managedAppPoliciesOutFile = Join-Path (Join-Path $baseDir "Apps") "managedAppPolicies.json"
Write-Host "Exporting Managed App Policies to $managedAppPoliciesOutFile"
az rest --method get --url $managedAppPoliciesUrl --headers "Content-Type=application/json" | Out-File -FilePath $managedAppPoliciesOutFile

# Export Conditional Access Policies (outside deviceManagement)
$caUrl = "https://graph.microsoft.com/beta/identity/conditionalAccess/policies"
$caOutFile = Join-Path (Join-Path $baseDir "ConditionalAccess") "conditionalAccessPolicies.json"
Write-Host "Exporting Conditional Access Policies to $caOutFile"
az rest --method get --url $caUrl --headers "Content-Type=application/json" | Out-File -FilePath $caOutFile


Write-Host "Intune full backup complete. Files saved to $baseDir"

# Export all JSON data as HTML tables in a single HTML file
Write-Host "Exporting all JSON data to a single HTML file with tables..."

$htmlPath = Join-Path $baseDir "IntuneBackup.html"
$htmlContent = @()
$htmlContent += "<html><head><title>Intune Backup Tables</title><style>body{font-family:sans-serif;} table{border-collapse:collapse;margin-bottom:40px;} th,td{border:1px solid #ccc;padding:4px;} th{background:#eee;} h2{margin-top:40px;}</style></head><body>"
$jsonFiles = Get-ChildItem -Path $baseDir -Recurse -Filter *.json

foreach ($jsonFile in $jsonFiles) {
  $jsonContent = Get-Content $jsonFile.FullName -Raw | ConvertFrom-Json
  $baseName = $jsonFile.BaseName
  $dirName = $jsonFile.Directory.Name
  $sectionTitle = "$dirName - $baseName"
  $htmlContent += "<h2>$sectionTitle</h2>"
  if ($jsonContent.PSObject.Properties.Name -contains 'value') {
    $items = $jsonContent.value
  } else {
    $items = $jsonContent
  }
  if ($items -is [System.Collections.IEnumerable] -and $items.Count -gt 0) {
    foreach ($item in $items) {
      $tableTitle = $item.id
      if ($tableTitle) {
        $htmlContent += "<h3>Item: $tableTitle</h3>"
      }
      $htmlContent += "<table><tr>"
      foreach ($prop in $item.PSObject.Properties.Name) {
        $htmlContent += "<th>$prop</th>"
      }
      $htmlContent += "</tr><tr>"
      foreach ($prop in $item.PSObject.Properties.Name) {
        $value = $item.$prop
        if ($value -is [System.Collections.IEnumerable] -and !$value.GetType().IsPrimitive -and $value -ne $null -and $value -isnot [string]) {
          $value = ($value | ConvertTo-Json -Compress)
        }
        $htmlContent += "<td>$value</td>"
      }
      $htmlContent += "</tr></table>"
    }
  } else {
    $htmlContent += "<p>No data found in this file.</p>"
  }
}
$htmlContent += "</body></html>"
Set-Content -Path $htmlPath -Value $htmlContent -Encoding UTF8
Write-Host "HTML file created: $htmlPath"