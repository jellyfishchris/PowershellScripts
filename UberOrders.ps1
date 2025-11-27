$uri = "https://www.ubereats.com/_p/api/getPastOrdersV1?localeCode=au"

$headers = @{
    "accept"               = "*/*"
    "content-type"         = "application/json"
    "origin"               = "https://www.ubereats.com"
    "referer"              = "https://www.ubereats.com/au/orders"
    "user-agent"           = "Mozilla/5.0"
    "x-csrf-token"         = "x"
    "x-uber-ciid"          = "xxx"
    "x-uber-client-gitref" = "xxx"
    "x-uber-request-id"    = "xxxx"
    "x-uber-session-id"    = "xxx"
}


$headers["Cookie"] = ''

$lastWorkflowUUID = "4bc5d820-453a-4822-8d96-bb6211a62a8c"
$allOrders = @()
$pageCount = 0

#last 50 page - 10 per page 
while ($pageCount -lt 50) {

    $bodyObj = if ($lastWorkflowUUID) {
        @{ lastWorkflowUUID = $lastWorkflowUUID }
    } else {
        @{}
    }

    $body = $bodyObj | ConvertTo-Json

    $response = Invoke-RestMethod -Uri $uri -Method POST -Headers $headers -Body $body

    $ordersMap = $response.data.ordersMap
    if (-not $ordersMap) { break }

    # convert map to array of full order objects (no custom projection)
    $ordersArray = @(
        $ordersMap.PSObject.Properties |
        ForEach-Object { $_.Value }
    )

    if ($ordersArray.Count -eq 0) { break }

    # accumulate all raw order objects
    $allOrders += $ordersArray

    # last key from this page = next workflow UUID
    $orderKeys = $ordersMap.PSObject.Properties.Name
    $lastWorkflowUUID = $orderKeys[-1]

    $pageCount++
}

foreach ($order in $allOrders) {
    $price = "{0:N2}" -f ($order.fareInfo.totalPrice / 100)

    Write-Output "$($order.baseEaterOrder.uuid), $($order.baseEaterOrder.completedAt), $($order.storeInfo.title), $($price)"
}

