# Hook: sessionStart — posts session event to echo API

$ApiUrl = "https://echo.jannemattila.com/api/echo"

# Read the hook input JSON from stdin
$Input = $null
if (-not [Console]::IsInputRedirected) {
    $Input = '{}'
} else {
    $Input = [Console]::In.ReadToEnd()
}

# Parse input
try {
    $Data = $Input | ConvertFrom-Json
    $Timestamp = if ($Data.timestamp) { $Data.timestamp } else { "unknown" }
    $Cwd = if ($Data.cwd) { $Data.cwd } else { "unknown" }
} catch {
    $Timestamp = "unknown"
    $Cwd = "unknown"
}

$Payload = @{
    event     = "SessionStarted"
    timestamp = "$Timestamp"
    cwd       = "$Cwd"
} | ConvertTo-Json -Compress

try {
    Invoke-RestMethod -Uri $ApiUrl -Method Post -ContentType "application/json" -Body $Payload | Out-Null
} catch {
    # Silently ignore errors — hooks should not block the session
}

exit 0
