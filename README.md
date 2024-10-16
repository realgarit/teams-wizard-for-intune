# Teams Wizard Intune Packaging

This repository contains a full automated script for packaging and deploying applications using **Microsoft Intune**. The solution includes a streamlined PowerShell script to package Win32 apps, manage installation arguments, and configure registry settings.

---

## Table of Contents
- [Credits](#credits)
- [Features](#features)
- [Contact Lookup Patterns Configuration](#contact-lookup-patterns-configuration)
  - [Why the Configuration?](#why-the-configuration)
- [Authentication](#authentication)
  - [Why is This Needed?](#why-is-this-needed)
  - [How to Set Up Authentication](#how-to-set-up-authentication)
    - [Step 1: Create an App Registration](#step-1-create-an-app-registration)
    - [Step 2: Configure API Permissions](#step-2-configure-api-permissions)
    - [Step 3: Configure Authentication](#step-3-configure-authentication)
    - [Step 4: Retrieve the Client ID](#step-4-retrieve-the-client-id)
    - [Step 5: Add Authentication Parameters to Your Script](#step-5-add-authentication-parameters-to-your-script)
- [Usage](#usage)
- [End User Guide](#end-user-guide)
  - [Important Note](#important-note)
  - [Step-by-Step Instructions](#step-by-step-instructions)

---

## Credits

This project is based on the excellent work from the [MSEndpointMgr/IntuneWin32App](https://github.com/MSEndpointMgr/IntuneWin32App) repository.

- Original script by: [MSEndpointMgr](https://github.com/MSEndpointMgr)
- License: [LICENSE](https://github.com/MSEndpointMgr/IntuneWin32App/blob/master/LICENSE)

This repository also includes **TeamsWizard**, a tool that extends the functionality of Microsoft Teams with additional features such as hotkey dialing, call lookup, and actions triggered by incoming calls. You can learn more about TeamsWizard from their official [website](https://www.lyncwizard.com/products.html).

TeamsWizard is developed by **E-Tel-IT GmbH**, based in Zunzgen, Switzerland, with over 30 years of experience in Microsoft environments. Special thanks to the team at E-Tel-IT for their contributions to improving Microsoft Teams functionality.

---

## Features

- 🛠 **Automated Packaging:** Automate packaging of `.exe` or `.msi` installers for deployment via Intune.
- ⚙️ **Custom Installation & Uninstallation:** Use customizable installation and uninstallation arguments.
- 📜 **Registry Modifications:** Apply specific registry configurations to ensure custom app settings are applied after deployment.
- 📝 **Logging:** Enable detailed logging for tracking installation progress.

---

## Contact Lookup Patterns Configuration

The configuration for `ContactLookupPatterns` in the registry is crucial for how phone numbers are handled within the application. 

### Why the Configuration?

In Switzerland, mobile numbers and landline numbers have distinct formats, and we want to ensure that both types of numbers are correctly processed by the Teams Wizard app.

- **Mobile Numbers**: Mobile numbers in Switzerland start with `+4175`, `+4176`, `+4177`, `+4178`, and `+4179`.
- **Landline Numbers**: Landline numbers start with other prefixes, so we need to handle them differently.

The following registry configuration allows the application to recognize and format mobile and landline numbers accordingly:

```plaintext
[HKEY_CURRENT_USER\SOFTWARE\LyncWizard.com\Teams Wizard\v1.0]
"ContactLookupPatterns"="1:\"^\\+41(7[5-9]\\d+)$\":0:\"0$1\""
"ContactLookupPatterns"="1:\"^\\+41(?!7[5-9])(\\d+)$\":3:\"0$1\""
```
---

## Authentication

### Why is This Needed?

Based on research in May 2024, Microsoft updated authentication methods for the **Graph SDK-based PowerShell module**. As a result, the global **Microsoft Intune PowerShell application (client) ID** based authentication method has been **removed**. You can read more about this change [here](https://learn.microsoft.com/en-us/samples/microsoftgraph/powershell-intune-samples/important/).

For example, the command `Connect-MSGraph` previously used the global **Intune PowerShell application ID** (`d1ddf0e4-d672-4dae-b554-9d5bdfd93547`), but this method is now deprecated. To continue using the Intune APIs with PowerShell, you need to **create your own app registration** with the required permissions and connect via that new registration app.

### How to Set Up Authentication

To successfully authenticate and use this script for Intune automation, you will need to set up an **App Registration** in Azure Active Directory (EntraID) and configure the necessary API permissions. Follow these steps:

### Step 1: Create an App Registration
1. **Go to Azure Active Directory**:
   - In the Azure portal, navigate to **Azure Active Directory (EntraID)**.
   
2. **Create a New App Registration**:
   - Click on **App registrations** from the sidebar.
   - Click **New registration**.
   - Name your app **"Intune Powershell"**.
   - Choose the **Supported account types** that match your environment (usually "Accounts in this organizational directory only").
   - Click **Register**.

### Step 2: Configure API Permissions
1. **Add API Permissions**:
   - After creating the app, go to the **API permissions** section.
   - Click **Add a permission**.
   - Select **Microsoft Graph**.
   - Choose **Delegated permissions**.
   - Search for and select **DeviceManagementApps.ReadWrite.All**.
   - Click **Add permissions**.
   
2. **Grant Admin Consent**:
   - Once the permission is added, click **Grant admin consent** for your tenant to allow the app to use these permissions on behalf of users.

### Step 3: Configure Authentication
1. **Go to Authentication Settings**:
   - In the **App registration** page, navigate to the **Authentication** section from the sidebar.

2. **Add a Platform**:
   - Click **Add a platform**.
   - Select **Mobile and desktop applications**.

3. **Add the MSAL Redirect URI**:
   - Scroll down to the **Redirect URIs** section.
   - Add **MSAL Redirect URI**,
   - Click **Configure**.
   - It should look this:
   - ![image](https://github.com/user-attachments/assets/c052161f-7109-4a37-9e6e-91285799d0c6)
     
4. **Copy the Redirect URI**:
   - The redirect URI is essential for the PowerShell script to authenticate. Copy this for use in your script.

### Step 4: Retrieve the Client ID
1. **Get the Client ID**:
   - Go to the **Overview** tab of the App Registration.
   - Copy the **Client ID** (also known as the Application ID). This will be used as a parameter in your script.

### Step 5: Add Authentication Parameters to Your Script
Once you have the **Client ID** and **Redirect URI**, add them as parameters to your PowerShell script to enable authentication.

---

## Usage

1. **Clone the Repository**:
    ```bash
    git clone https://github.com/realgarit/Teams-Wizard-for-Intune.git
    cd Teams-Wizard-for-Intune-main
    ```

2. **Update the parameters**
   
4. **Don't forget to add your API Key in the value field for tel.search.ch for contact lookups**

5. **Upload the configuration script to Intune and assignt it to your liking. You have to set the script to run using the logged on credentials, otherwise the configuration won't work**

---

## End User Guide

### Important Note:
TeamsWizard does not start automatically after installation because it must run in the same user context as **Microsoft Teams**. Therefore, you will need to manually start TeamsWizard the first time. Afterward, it will automatically start with Windows on subsequent reboots.

### Step-by-Step Instructions:

1. **Starting TeamsWizard for the First Time**:
   - After installation, manually start the **TeamsWizard** application.
   - ![Bild1](https://github.com/user-attachments/assets/d88beca3-5bdd-4a84-9ef0-b11a41b54816)
   - Once started, the app will run in the background, and you will see the TeamsWizard icon in your system tray.
   - ![Bild2](https://github.com/user-attachments/assets/487a4a2a-e98a-4b98-8f17-e47240883d1c)

2. **Checking Configuration**:
   - Right-click the TeamsWizard icon in the system tray and select **Settings**.
   - Verify that the **API Key** is correctly entered in the appropriate field.
   - ![Bild3](https://github.com/user-attachments/assets/9fe40e5a-b33d-440f-970e-99806b8a253b)
   - If the API key is filled in, the configuration has been successfully applied, and the app is ready for use.

3. **Waiting for Configuration**:
   - If the settings do not appear or the API key is missing, it means that Intune is still applying the configuration. Give it some time, and check back later.

4. **Handling Incoming Calls**:
   - When someone calls you, a pop-up will appear in the corner of your screen, displaying the caller's details.
   - ![Bild4](https://github.com/user-attachments/assets/0bad7567-c74d-4789-9c7a-e688594eef54)
   - If the pop-up does not appear, it indicates that **tel.search.ch** could not find any information about the caller.

By following these steps, TeamsWizard will be properly configured and ready to enhance your Microsoft Teams experience.

---
