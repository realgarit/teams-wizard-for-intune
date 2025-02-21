$ClientID = "xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxx"
$RedirectURI = "msalxxxxx-xxxx-xxxx-xxxx-xxxxxx://auth"
$PackageType = "MSI"
$PackageName = "TeamsWizard"
$AppVersion = "0.6.7"
$DownloadURL = "https://github.com/realgarit/Teams-Wizard-for-Intune/raw/refs/heads/main/Apps/TeamsWizard_x64.msi"
$TenantName = "example.onmicrosoft.com"
$Assignment = "g_devices_testing_teamswizard"
$InstallArgs = "/i TeamsWizard_x64.msi ALLUSERS=1 REBOOT=ReallySuppress /qn"
$UninstallArgs  = "msiexec /x /qn {8E72BB19-BE2D-4A5A-AA39-839513CF1E11}"
$DetectionArgs = @"
Get-WmiObject -Class Win32_Product | Where {`$_.Vendor -eq 'LyncWizard.com' -and `$_.Version -eq '0.6.7'}
"@

.\TeamsWizard_packaging.ps1 -ClientID $ClientID `
                                        -RedirectURI $RedirectURI `
                                        -PackageType $PackageType `
                                        -PackageName $PackageName `
                                        -AppVersion $AppVersion `
                                        -DownloadURL $DownloadURL `
                                        -TenantName $TenantName `
                                        -Assignment $Assignment `
                                        -InstallArgs $InstallArgs `
                                        -UninstallArgs $UninstallArgs `
                                        -DetectionArgs $DetectionArgs
