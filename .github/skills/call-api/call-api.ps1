# call-api skill script — posts JSON to the echo API
param(
    [Parameter(Mandatory = $true)]
    [string]$Json
)

$ApiUrl = "https://echo.jannemattila.com/api/echo"

Write-Output "Posting to $ApiUrl..."
Write-Output "Payload: $Json"
Write-Output "---"

try {
    $response = Invoke-RestMethod -Uri $ApiUrl -Method Post -ContentType "application/json" -Body $Json
    Write-Output "Response:"
    $response | ConvertTo-Json -Depth 10
}
catch {
    Write-Error "API call failed: $_"
    exit 1
}
