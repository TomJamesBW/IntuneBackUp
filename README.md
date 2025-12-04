# IntuneBackUp
An Intune Backup method using Azure CLI, REST and App Registrations

# Create an App Registration with the following Graph API / Application permissions granted to your organisation
DeviceManagementApps.Read.All
DeviceManagementConfiguration.Read.All
DeviceManagementManagedDevices.Read.All
DeviceManagementRBAC.Read.All
DeviceManagementScripts.Read.All
DeviceManagementServiceConfig.Read.All
Directory.Read.All
Group.Read.All
Policy.Read.All
User.Read

# Subscriptions
Go to Subscriptions under Azure Portal, Click your subscription, select 'Iam'.
Choose Add Role, select Reader and apply it to your Application you created.

# You will need the following:
ClientID from your App Registration
Tenant ID from your App Regisration
Create a new Secret in your App Registration and not down the value
Subscription ID from Portal.Azure.com

# Running
This will cycle through Intune when you run this PS1 script from PowerShell.
Files are all stored under your $Home directory.
The HTML file can take a while to generate and is quite large (based on your org size).
