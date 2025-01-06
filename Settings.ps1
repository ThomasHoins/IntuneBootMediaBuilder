# To connect to Intune, you need an App Registration with a secret for third party to identify. Then add the IDs and Secret below.
# Needs the following permissions:
#   Microsoft Graph -> Application Permissions ->
#     DeviceManagementConfiguration.ReadWrite.All
#     DeviceManagementManagedDevices.ReadWrite.All 
#     DeviceManagementServiceConfig.ReadWrite.All
[string]$TenantId = "XXXXX"
[string]$AppId = "XXXXX"
[string]$AppSecret = "XXXXX"


# Assign the Group Tag to device.
[String]$GroupTag = "Default"

# Wait for the Group Tag to be assigned before continuing, default is $true. ($true|$false)
[String]$Assign = $false

# Assign a User to a device. Type the full UPN.
[String]$AssignedUser = ""

# To connect to Wifi, you need to export a profile and save it on the USB.
# Run this command to export the profile: netsh wlan export profile name="YourWiFi" folder="C:\path\to\save\profile"
# Make sure this profile xml file has the same name as your SSID.
# Then just type the SSID here.
[string]$Wifi = ""

# If you want to output the hardware hash somewhere, put a path here.
[String]$OutputFile = ""