# Set registry path
$RegPath = "HKCU:\SOFTWARE\LyncWizard.com\Teams Wizard\v1.0"

# Create the registry key if it doesn't exist
if (-not (Test-Path $RegPath)) {
    New-Item -Path $RegPath -Force
}

# Set the registry values

# Multi-string value (REG_MULTI_SZ) for ContactLookupPatterns
$ContactLookupPatterns = @(
    '1:"^\+41(7[5-9]\d+)$":0:"0$1"',
    '1:"^\+41(?!7[5-9])(\d+)$":3:"0$1"'
)
Set-ItemProperty -Path $RegPath -Name "ContactLookupPatterns" -Value $ContactLookupPatterns

# String values (REG_SZ)
Set-ItemProperty -Path $RegPath -Name "CultureInfo" -Value "de-DE"
Set-ItemProperty -Path $RegPath -Name "APIKey" -Value ""

# DWORD values (REG_DWORD)
Set-ItemProperty -Path $RegPath -Name "ContactLookupCopyToClipboard" -Value 1
Set-ItemProperty -Path $RegPath -Name "CustomBalloon" -Value 0
Set-ItemProperty -Path $RegPath -Name "CustomBalloonDisplayTime" -Value 8000
Set-ItemProperty -Path $RegPath -Name "CustomBalloonOffsetX" -Value 0
Set-ItemProperty -Path $RegPath -Name "CustomBalloonOffsetY" -Value 0
Set-ItemProperty -Path $RegPath -Name "DebugLogging" -Value 1
Set-ItemProperty -Path $RegPath -Name "EnableContactLookup" -Value 1
Set-ItemProperty -Path $RegPath -Name "EnableHotkeyDialer" -Value 1
Set-ItemProperty -Path $RegPath -Name "EnableRunCmd" -Value 0
Set-ItemProperty -Path $RegPath -Name "HotKeyDialKey" -Value 119
Set-ItemProperty -Path $RegPath -Name "HotKeyDialModifier" -Value 0
Set-ItemProperty -Path $RegPath -Name "HotKeyDialNormalization" -Value 1
Set-ItemProperty -Path $RegPath -Name "HotKeyDialPrompt" -Value 1
Set-ItemProperty -Path $RegPath -Name "HotkeyDialLegacyMethod" -Value 0
Set-ItemProperty -Path $RegPath -Name "SearchKnownContact" -Value 1

# Empty multi-string (REG_MULTI_SZ) for RunCmdItems
Set-ItemProperty -Path $RegPath -Name "RunCmdItems" -Value @("")
