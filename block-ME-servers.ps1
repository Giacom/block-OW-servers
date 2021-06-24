#Requires -RunAsAdministrator

param (
    [switch]$remove = $false,                                                      # Use this switch to remove the rules
    [string]$regionRegex = "(eu|me)-.+",                                           # The regex of the regions to block, e.g: me = middle east, us = united states, eu = europe
    [string]$ipRangeRequestUrl = "https://ip-ranges.amazonaws.com/ip-ranges.json", # AWS endpoint that'll give us our IP ranges to block
    [string]$ruleDisplayName = "_OW_BlockServers",                                 # The name of the firewall rule
    [string]$ruleDescription = "Rule used to block servers for OW"                 # The description of the firewall rule
)

Write-Host ""
Write-Host "You can get the latest version of this file from: https://gist.github.com/Giacom/c3bf45d644fdc75fd59552b44f8848b4"
Write-host "Created by /u/Giacomand"
Write-Host ""

if ($remove) {
    try {
        Remove-NetFirewallRule -DisplayName $ruleDisplayName -ErrorAction Stop | Out-Null
        Write-Host "Firewall rules removed, things are back to normal"
    } catch {
        Write-Host "Could not find firewalls rule. Please check Windows Defender Firewall's advanced settings"
    }
    exit
}



Write-Host "Finding Overwatch.exe location.."

$overwatch = Get-ItemProperty "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Overwatch" -ErrorAction SilentlyContinue
if ($overwatch) {
    $overwatch = $overwatch.InstallLocation + "\_retail_\Overwatch.exe"
    if (Test-Path -Path $overwatch -PathType Leaf) {
        Write-Host "Found at: $overwatch"
    } else {
        $overwatch = ""
        Write-Host "Could not find Overwatch.exe"
    }
} else {
    $overwatch = ""
    Write-Host "Could not find Overwatch.exe"
}

Write-Host ""
Write-Host "Is this the correct location to Overwatch.exe? Leave empty if yes otherwise enter a path"
$corrected = Read-Host "[$overwatch]"
$corrected = $corrected -replace "/","\" # Make sure path separators are the windows standard

if (!([string]::IsNullOrWhiteSpace($corrected))) {
    if (Test-Path -Path $corrected -PathType Leaf) {
        $overwatch = $corrected
    } else {
        Write-Host "Invalid path, please enter the full path to Overwatch.exe!"
        exit
    }
}

if (!(Test-Path -Path $overwatch -PathType Leaf)) {
    Write-Host "Empty or invalid path to Overwatch.exe!"
    exit
} else {
    Write-Host "Using Overwatch.exe location: $overwatch"
}




Write-Host ""
Write-Host "Connecting to $ipRangeRequestUrl to get latest ip ranges..."
$ipAddresses = Invoke-WebRequest -Uri $ipRangeRequestUrl | ConvertFrom-Json | select -expand prefixes | select ip_prefix, region | where {$_.region -Match $region}

Write-Host "List of ME Servers retrieved from AWS:"
Format-Wide -InputObject $ipAddresses -AutoSize

$ipAddresses = $ipAddresses | foreach { $_.ip_prefix }

if ($ipAddresses) {

    Write-Host "Deleting any pre-existing rules from before.."

    Remove-NetFirewallRule -DisplayName $ruleDisplayName -ErrorAction SilentlyContinue | Out-Null

    Write-Host ""
    Write-Host "DONE"
    Write-Host ""

    Write-Host "Adding rules with latest ip ranges.."

    New-NetFirewallRule -DisplayName $ruleDisplayName -Description $ruleDescription -RemoteAddress $ipAddresses -Program $overwatch -Action Block -Direction Inbound -ErrorAction Stop | Out-Null
    New-NetFirewallRule -DisplayName $ruleDisplayName -Description $ruleDescription -RemoteAddress $ipAddresses -Program $overwatch -Action Block -Direction Outbound -ErrorAction Stop | Out-Null

    Write-Host ""
    Write-Host "DONE"
    Write-Host ""
    Write-Host "Rule Name: $ruleDisplayName"
    Write-Host ""

    Write-Host "Firewall update successful! Test if it is working by going to a custom game and trying to connect to"
    Write-Host "the blocked region through the custom game lobby settings."
    Write-Host ""
    Write-Host "You can delete/disable these rules if you change your mind, go to advanced settings in Windows Defender Firewall and look for any"
    Write-Host "Inbound and Outbound rules that match the name: $ruleDisplayName"

} else {
    Write-Host "ERROR: Could not retrieve list of ip ranges from AWS, make sure you can connect to $ipRangeRequestUrl"
}