# Hello skill script — prints a greeting
param(
    [string]$Name = "World"
)
Write-Output "Hello, $Name!"
