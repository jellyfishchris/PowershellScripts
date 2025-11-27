function Unenroll-WindowsUpdateAssets {
    param(
        [Parameter(Mandatory)]
        [string[]] $Ids,

        [Parameter(Mandatory)]
        [ValidateSet("feature", "quality", "driver")]
        [string] $UpdateCategory
    )

    if ($Ids.Count -eq 0) {
        Write-Output "No IDs supplied — nothing to unenroll."
        return
    }

    # Graph endpoint
    $uri = "https://graph.microsoft.com/beta/admin/windows/updates/updatableAssets/unenrollAssetsById"

    # Request body
    $body = @{
        updateCategory   = $UpdateCategory
        memberEntityType = "#microsoft.graph.windowsUpdates.azureADDevice"
        ids              = $Ids
    } | ConvertTo-Json -Depth 5

    # POST call with full HTTP response
    $response = Invoke-MgGraphRequest `
        -Method POST `
        -Uri $uri `
        -Body $body `
        -ContentType "application/json" `
        -OutputType HttpResponseMessage

    Write-Output "$UpdateCategory ID removal response (NoContent is good) - " $response.StatusCode
}




Connect-MgGraph -Scopes "Device.Read.All","WindowsUpdates.ReadWrite.All" -Environment Global -NoWelcome

$azureADDevices = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/admin/windows/updates/updatableAssets/microsoft.graph.windowsUpdates.azureADDevice"
$featureIds = @()
$qualityIds = @()
$driverIds = @()

foreach ($device in $azureADDevices.value) 
{
    if ($device.enrollment.feature.enrollmentState -ne "notEnrolled") 
    {
        $featureIds += $device.id
    }
    if ($device.enrollment.quality.enrollmentState -ne "notEnrolled") 
    {
        $qualityIds += $device.id
    }
    if ($device.enrollment.driver.enrollmentState -ne "notEnrolled") 
    {
        $driverIds += $device.id
    }
}

Write-Output "List of Feature ID's"
Write-Output $featureIds
Write-Output "List of Quality ID's"
Write-Output $qualityIds
Write-Output "List of Driver ID's"
Write-Output $driverIds

Unenroll-WindowsUpdateAssets -Ids $featureIds -UpdateCategory "feature"
Unenroll-WindowsUpdateAssets -Ids $qualityIds -UpdateCategory "quality"
Unenroll-WindowsUpdateAssets -Ids $driverIds -UpdateCategory "driver"
