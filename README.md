# Teams Wizard Intune Packaging

---

## Table of Contents
- [Credits](#credits)
- [Features](#features)
- [Contact Lookup Patterns Configuration](#contact-lookup-patterns-configuration)
  - [Why the Configuration?](#why-the-configuration)
- [Usage](#usage)
- [End User Guide](#end-user-guide)
  - [Important Note](#important-note)
  - [Step-by-Step Instructions](#step-by-step-instructions)

---

## Credits

This repository includes **TeamsWizard**, a tool that extends the functionality of Microsoft Teams with additional features such as hotkey dialing, call lookup, and actions triggered by incoming calls. You can learn more about TeamsWizard from their official [website](https://www.lyncwizard.com/products.html).

TeamsWizard is developed by **E-Tel-IT GmbH**, based in Zunzgen, Switzerland, with over 30 years of experience in Microsoft environments. Special thanks to the team at E-Tel-IT for their contributions to improving Microsoft Teams functionality.

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

## Usage

1. **Follow the insctructions in this [Repository](https://github.com/realgarit/intune-packager/blob/main/README.md#Usage)**
   
3. **Don't forget to add your API Key in the value field for tel.search.ch for contact lookups**

4. **Upload the configuration script to Intune and assignt it to your liking. You have to set the script to run using the logged on credentials, otherwise the configuration won't work**

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
