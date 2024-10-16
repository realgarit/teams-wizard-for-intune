[CmdletBinding()]
param (
    [Parameter()]
    [String]
    $PackageType,
    [Parameter()]
    [String]
    $RedirectURI,
    [Parameter()]
    [String]
    $PackageName,
    [Parameter()]
    [String]
    $AppVersion,
    [Parameter()]
    [String]
    $DownloadURL,
    [Parameter()]
    [String]
    $TenantName,
    [Parameter()]
    [String]
    $Assignment,
    [Parameter()]
    [String]
    $InstallArgs,
    [Parameter()]
    [String]
    $UninstallArgs,
    [Parameter()]
    [String]
    $DetectionArgs,
    [Parameter()]
    [bool]
    $AuthTypeSPN = $False,
    [Parameter()]
    [string]
    $TenantID,
    [Parameter()]
    [string]
    $ClientID,
    [Parameter()]
    [string]
    $ClientSecret,
    [Parameter()]
    [string]
    $Thumbprint,   
    [Parameter()]
    [string]
    $ModuleLocation,
    [Parameter()]
    [bool]
    $Upload = $False,
    [Parameter()]
    [string]
    $RGName,
    [Parameter()]
    [string]
    $StorageAccountName,
    [Parameter()]
    [string]
    $ContainerName
)

## Create Folders
if (!(Test-Path C:\Packaging)) {
    Write-Host 'Creating new folder C:\Packaging'
    New-Item -Path C:\Packaging -ItemType Directory
}
if (!(Test-Path C:\Packaging\$PackageName)) {
    Write-Host "Creating new folder C:\Packaging\$($PackageName)"
    New-Item -Path C:\Packaging\$PackageName -ItemType Directory
}
else {
    Write-Host "Folder Already exists, removing it first."
    Remove-Item -Path C:\Packaging\$PackageName -Recurse -Force
    Write-Host "Creating new folder C:\Packaging\$($PackageName)"
    New-Item -Path C:\Packaging\$PackageName -ItemType Directory
}
if (!(Test-Path C:\Packaging\$PackageName\Input)) {
    Write-Host "Creating new folder C:\Packaging\$($PackageName)\Input"
    New-Item -Path C:\Packaging\$PackageName\Input -ItemType Directory
}
if (!(Test-Path C:\Packaging\$PackageName\Output)) {
    Write-Host "Creating new folder C:\Packaging\$($PackageName)\Output"
    New-Item -Path C:\Packaging\$PackageName\Output -ItemType Directory
}

## Detecting Modules installing them if missing

$InstalledModules = Get-InstalledModule
if ($InstalledModules.Name -notcontains "AzureAD") {
    Write-Host("Install powershell module Azure AD")
    Install-Module AzureAD -Force -AllowClobber
}
Else {
    Write-Host "Powershell module for Azure AD is already installed"
}
$InstalledModules = Get-InstalledModule
if ($InstalledModules.Name -notcontains "MSAL.PS") {
    Write-Host("Install powershell module MSAL.PS")
    Install-Module MSAL.PS -Force -AllowClobber
}
Else {
    Write-Host "Powershell module for MSAL.PS is already installed"
}
if ($AuthTypeSPN -eq $False) {
    if ($InstalledModules.Name -notcontains "IntuneWin32App") {
        Write-Host("Install powershell module IntuneWin32App")
        Install-Module IntuneWin32App -Force -AllowClobber
    }
    Else {
        Write-Host "Powershell module for IntuneWin32App is already installed"
    }
}
if ($AuthTypeSPN -eq $True) {
    If ($PSVersionTable.PSVersion.Major -eq 7){
        Write-Host "Using Powershell 7, import IntuneWin32App Module as Powershell 5"
        Import-Module $ModuleLocation -UseWindowsPowershell
    }
    If ($PSVersionTable.PSVersion.Major -eq 5){
        Write-Host "Using Powershell 5, import IntuneWin32App Module normally"
        Import-Module $ModuleLocation
    } 
}


##############

##If type is MSI

##############
if ($PackageType -eq "MSI") {
    

    ### Download PackageFile
    $PackageInstaller = [System.IO.Path]::GetFileName($DownloadURL)

    Invoke-WebRequest -Uri $DownloadURL -OutFile C:\Packaging\$PackageName\Input\$PackageInstaller

    ## Create Installation Powershell File
    Set-Content C:\Packaging\$PackageName\Input\$PackageName'-Install'.ps1 "Start-Process msiexec.exe -Argumentlist '$($InstallArgs)' -Wait"

    # Package MSI as .intunewin file
    $SourceFolder = "C:\Packaging\$($PackageName)\Input"
    $SetupFile = $PackageInstaller
    $OutputFolder = "C:\Packaging\$($PackageName)\Output"
    New-IntuneWin32AppPackage -SourceFolder $SourceFolder -SetupFile $SetupFile -OutputFolder $OutputFolder -Verbose

    ### Connect to MS Graph - Default is authentication prompt set parameter $AuthTypeSPN to True to use Service Principal
    if ($AuthTypeSPN -eq $False) {
        
        Connect-MSIntuneGraph -TenantID $TenantName -ClientID $ClientID -RedirectURI $RedirectURI

    }
    if ($AuthTypeSPN -eq $True) {
        
        Connect-MSIntuneGraph -TenantID $TenantID -ClientID $ClientID -ClientSecret $ClientSecret

    }
    
    ###

    $IntuneWinFile = Get-ChildItem -Path  "C:\Packaging\$($PackageName)\Output"
    $IntuneWinMetaData = Get-IntuneWin32AppMetaData -FilePath $IntuneWinFile.FullName

    # Create custom display name like 'Name' and 'Version'
    $Displayname = $PackageName
    #old $DisplayName = $IntuneWinMetaData.ApplicationInfo.Name + " " + $IntuneWinMetaData.ApplicationInfo.MsiInfo.MsiProductVersion
    $Publisher = $IntuneWinMetaData.ApplicationInfo.MsiInfo.MsiPublisher

    # Create MSI detection rule
    $DetectionRule = New-IntuneWin32AppDetectionRuleMSI -ProductCode $IntuneWinMetaData.ApplicationInfo.MsiInfo.MsiProductCode -ProductVersionOperator "greaterThanOrEqual" -ProductVersion $IntuneWinMetaData.ApplicationInfo.MsiInfo.MsiProductVersion

    # Add new MSI Win32 app
    $InstallationScriptFile = Get-ChildItem -Path "C:\Packaging\$($PackageName)\Input" | Where-Object Name -Like "*-Install.ps1"
    $InstallCommandLine = "powershell.exe -ExecutionPolicy Bypass -File .\$($InstallationScriptFile.Name)"
    $UninstallCommandLine = $UninstallArgs
    Add-IntuneWin32App -FilePath $IntuneWinFile.Fullname -DisplayName $DisplayName -Description $PackageName -AppVersion $AppVersion -Publisher $Publisher -InstallCommandLine $InstallCommandLine -UninstallCommandLine $UninstallCommandLine -InstallExperience "system" -RestartBehavior "suppress" -DetectionRule $DetectionRule -Verbose

    ## Assigment
    If ($Assignment -eq "All Users"){

        #### Assignment
        Write-Host "Sleeping for 30 seconds until the Win32 app gets registered in the background until the Win32 app gets registered in the background"
        Start-Sleep -Seconds 30
        $Win32App = Get-IntuneWin32App -DisplayName $PackageName -Verbose

        # Add assignment for all users
        Add-IntuneWin32AppAssignmentAllUsers -ID $Win32App.id -Intent "available" -Notification "showAll" -Verbose
    }
    
    If ($Assignment -eq "All Devices"){

        #### Assignment
        Write-Host "Sleeping for 30 seconds until the Win32 app gets registered in the background"
        Start-Sleep -Seconds 30
        $Win32App = Get-IntuneWin32App -DisplayName $PackageName -Verbose

        # Add assignment for all devices
        Add-IntuneWin32AppAssignmentAllDevices -ID $Win32App.id -Intent "available" -Notification "showAll" -Verbose
    }

    If ($Assignment -ne "All Devices" -or $Assignment -ne "All Users"){

        #Creating Group if it does not exist

        If ($PSVersionTable.PSVersion.Major -eq 7){
            Write-Host "Using Powershell 7, import Azure AD Module as Powershell 5"
            Import-Module AzureAD -UseWindowsPowershell
        }
        If ($PSVersionTable.PSVersion.Major -eq 5){
            Write-Host "Using Powershell 5, import Azure AD Module normally"
            Import-Module AzureAD
        }      
        ### Connect to Azure AD - Default is authentication prompt set parameter $AuthTypeSPN to True to use Service Principal
        if ($AuthTypeSPN -eq $False) {
            
            Connect-AzureAD

        }
        if ($AuthTypeSPN -eq $True) {
            
            Connect-AzureAD -TenantId $TenantId -ApplicationId $ClientID -CertificateThumbprint $Thumbprint

        }
        

        $ExistingAzureADGroups = Get-AzureADGroup -All:$true

        If ($ExistingAzureADGroups.DisplayName -notcontains $Assignment){
            Write-Host "Creating new Azure AD Group"
            New-AzureADGroup -DisplayName $Assignment -MailEnabled $False -SecurityEnabled $true -MailNickName "NotSet"
        }
        Else {
            Write-Host "Group already exists, grabbing object ID"
        }
        $GroupID = Get-AzureADGroup -SearchString $Assignment
        
        # Get a specific Win32 app by it's display name
        Write-Host "Sleeping for 30 seconds until the Win32 app gets registered in the background"
        Start-Sleep -Seconds 30
        $Win32App = Get-IntuneWin32App -DisplayName $PackageName -Verbose

        #Add an include assignment for a specific Azure AD group
        Add-IntuneWin32AppAssignmentGroup -Include -ID $Win32App.id -GroupID $GroupID.ObjectID -Intent "required" -Notification "showAll" -Verbose

    }
    #CleanUp or upload
    if ($Upload -eq $False) {
        if (Test-Path C:\Packaging\$PackageName) {
            Write-Host "Cleaning Up folder C:\Packaging\$($PackageName)"
            Remove-Item -Path C:\Packaging\$PackageName -Recurse -Force
         }
    }
    else {

        $SourcePath = "C:\Packaging\$($PackageName)"

        Write-Host "Upload is requested"

        $GetKey = az storage account keys list --resource-group $RGName --account-name $StorageAccountName
        $StorageAccountKey = $GetKey | ConvertFrom-Json

        az storage blob upload-batch --destination $ContainerName `
                                    --account-name $StorageAccountName `
                                    --account-key $StorageAccountKey.Value[0] `
                                    --destination-path $PackageName `
                                    --source $SourcePath
    }

    }

##############

##IF type is EXE

##############

if ($PackageType -eq "EXE") {
    
    ### Download PackageFile
    $PackageInstaller = [System.IO.Path]::GetFileName($DownloadURL)

    Invoke-WebRequest -Uri $DownloadURL -OutFile C:\Packaging\$PackageName\Input\$PackageInstaller


    ## Create Installation Powershell File
    Set-Content C:\Packaging\$PackageName\Input\$PackageName'-Install'.ps1 "Start-Process $($PackageInstaller) -Argumentlist '$($InstallArgs)' -Wait"

    ## Create Detection Powershell File
    Set-Content C:\Packaging\$PackageName\Input\$PackageName'-Detection'.ps1 $DetectionArgs

    # Package MSI as .intunewin file
    $SourceFolder = "C:\Packaging\$($PackageName)\Input"
    $SetupFile = $PackageInstaller
    $OutputFolder = "C:\Packaging\$($PackageName)\Output"
    New-IntuneWin32AppPackage -SourceFolder $SourceFolder -SetupFile $SetupFile -OutputFolder $OutputFolder -Verbose

    
    
    ### Connect to MS Graph

    if ($AuthTypeSPN -eq $False) {
        
        Connect-MSIntuneGraph -TenantID $TenantName -ClientID 61c9ddea-d334-418a-bde3-b064e4f7dac6 -RedirectURI msal61c9ddea-d334-418a-bde3-b064e4f7dac6://auth

    }
    if ($AuthTypeSPN -eq $True) {
        
        Connect-MSIntuneGraph -TenantID $TenantID -ClientID $ClientID -ClientSecret $ClientSecret

    }
    ###
    # Get MSI meta data from .intunewin file
    $IntuneWinFile = Get-ChildItem -Path  "C:\Packaging\$($PackageName)\Output" 
    $IntuneWinFile.Name

    # Create custom display name like 'Name' and 'Version'
    $DisplayName = $PackageName

    # Create PowerShell script detection rule
    $DetectionScriptFile = Get-ChildItem -Path "C:\Packaging\$($PackageName)\Input" | Where-Object Name -Like "*-Detection.ps1"
    $DetectionRule = New-IntuneWin32AppDetectionRuleScript -ScriptFile $DetectionScriptFile.FullName -EnforceSignatureCheck $false -RunAs32Bit $false

    # Add new EXE Win32 app
    $InstallationScriptFile = Get-ChildItem -Path "C:\Packaging\$($PackageName)\Input" | Where-Object Name -Like "*-Install.ps1"
    $InstallCommandLine = "powershell.exe -ExecutionPolicy Bypass -File .\$($InstallationScriptFile.Name)"
    $UninstallCommandLine = $UninstallArgs
    Add-IntuneWin32App -FilePath $IntuneWinFile.FullName -DisplayName $DisplayName -Description $PackageName -AppVersion $AppVersion -Publisher $Publisher -InstallExperience "system" -RestartBehavior "suppress" -DetectionRule $DetectionRule -InstallCommandLine $InstallCommandLine -UninstallCommandLine $UninstallCommandLine -Verbose
    
    ## Assigment
    If ($Assignment -eq "All Users"){

        #### Assignment
        Write-Host "Sleeping for 30 seconds until the Win32 app gets registered in the background"
        Start-Sleep -Seconds 30
        $Win32App = Get-IntuneWin32App -DisplayName $PackageName -Verbose

        # Add assignment for all users
        Add-IntuneWin32AppAssignmentAllUsers -ID $Win32App.id -Intent "available" -Notification "showAll" -Verbose
    }
    
    If ($Assignment -eq "All Devices"){

        #### Assignment
        Write-Host "Sleeping for 30 seconds until the Win32 app gets registered in the background"
        Start-Sleep -Seconds 30
        $Win32App = Get-IntuneWin32App -DisplayName $PackageName -Verbose

        # Add assignment for all devices
        Add-IntuneWin32AppAssignmentAllDevices -ID $Win32App.id -Intent "available" -Notification "showAll" -Verbose
    }

    If ($Assignment -ne "All Devices" -or $Assignment -ne "All Users"){

        #Creating Group if it does not exist

        If ($PSVersionTable.PSVersion.Major -eq 7){
            Write-Host "Using Powershell 7, import Azure AD Module as Powershell 5"
            Import-Module AzureAD -UseWindowsPowershell
        }
        If ($PSVersionTable.PSVersion.Major -eq 5){
            Write-Host "Using Powershell 5, import Azure AD Module normally"
            Import-Module AzureAD
        }      
        
        if ($AuthTypeSPN -eq $False) {
            
            Connect-AzureAD

        }
        if ($AuthTypeSPN -eq $True) {
            
            Connect-AzureAD -TenantId $TenantId -ApplicationId $ClientID -CertificateThumbprint $Thumbprint

        }

        $ExistingAzureADGroups = Get-AzureADGroup -All:$true

        If ($ExistingAzureADGroups.DisplayName -notcontains $Assignment){
            Write-Host "Creating new Azure AD Group"
            New-AzureADGroup -DisplayName $Assignment -MailEnabled $False -SecurityEnabled $true -MailNickName "NotSet"
        }
        Else {
            Write-Host "Group already exists, grabbing object ID"
        }
        $GroupID = Get-AzureADGroup -SearchString $Assignment
        
        # Get a specific Win32 app by it's display name
        Write-Host "Sleeping for 30 seconds until the Win32 app gets registered in the background"
        Start-Sleep -Seconds 30
        $Win32App = Get-IntuneWin32App -DisplayName $PackageName -Verbose

        #Add an include assignment for a specific Azure AD group
        Add-IntuneWin32AppAssignmentGroup -Include -ID $Win32App.id -GroupID $GroupID.ObjectID -Intent "required" -Notification "showAll" -Verbose

    }
    #CleanUp or upload
    if ($Upload -eq $False) {
        if (Test-Path C:\Packaging\$PackageName) {
            Write-Host "Cleaning Up folder C:\Packaging\$($PackageName)"
            Remove-Item -Path C:\Packaging\$PackageName -Recurse -Force
         }
    }
    else {

        $SourcePath = "C:\Packaging\$($PackageName)"

        Write-Host "Upload is requested"

        $GetKey = az storage account keys list --resource-group $RGName --account-name $StorageAccountName
        $StorageAccountKey = $GetKey | ConvertFrom-Json

        az storage blob upload-batch --destination $ContainerName `
                                    --account-name $StorageAccountName `
                                    --account-key $StorageAccountKey.Value[0] `
                                    --destination-path $PackageName `
                                    --source $SourcePath
    }
}    
