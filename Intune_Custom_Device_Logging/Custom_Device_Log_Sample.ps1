#___________________________________________
#            SETTING THE STAGE
#___________________________________________

#Workspace Data
$DcrImmutableId = "" # id available in DCR > JSON view > immutableId
$DceURI = "" # available in DCE > Logs Ingestion value
$Table = "" # Name of table in workspace

#Application Data
$tenantId = "" # the tenant ID in which the Data Collection Endpoint resides
$appId = "" # the app ID created and granted permissions
$appSecret = "" #the secret created for the above app - never store your secrets in the source code

Set-ExecutionPolicy Bypass

if (Get-Module -ListAvailable -Name pswindowsupdate) {
    Import-Module PSWindowsUpdate
} 
else {
    Install-Module -Name pswindowsupdate -allowclobber -force
}

#____________________________________________
#                 GRABBING INFO
#_____________________________________________

#Device Name
$DeviceName = Get-WmiObject -Class Win32_ComputerSystem  | Select-Object -expandproperty Name
#Device Model
$DeviceModel = Get-CimInstance -ClassName Win32_ComputerSystem | select-object -expandproperty Model
#Device Manufacturer
$Manufacturer = Get-WmiObject -Class Win32_ComputerSystem  | Select-Object -expandproperty Manufacturer
#DateLogged
$DateLogged = get-date -Format "dddd MM/dd/yyyy HH:mm K"
#Printers
$printers = Get-WMIObject -class Win32_printer | Select-object -expandproperty name
$printers = $printers -join ', ' | out-string
#UpTime
$UpTime = (get-date) - (gcim Win32_OperatingSystem).LastBootUpTime
$DaysUp = $UpTime.Days
$HoursUp = $UpTime.Hours
$FormattedUpTime = "$DaysUp Days $HoursUp Hours"
#Storage
$drive = Get-PSDrive C
$totalSizeGB = [math]::Round(($drive.Used + $drive.Free) / 1GB, 2)
$freeSpaceGB = [math]::Round($drive.Free / 1GB, 2)
#Battery Status
$batteryhealth = Get-WmiObject -class win32_battery | Select-Object -expandproperty Status
#StartUp Programs
$startupprogs = Get-WmiObject -Class Win32_StartupCommand | Select-Object -expandproperty Name
$startupprogs = $startupprogs -join ', ' | out-string
#Device Type
$DeviceTypeID = Get-WmiObject -Class Win32_ComputerSystem  | Select-Object -expandproperty PCSystemType
switch ($DeviceTypeID){
0 {
    $DeviceType = "Unspecified"
}
1 {
    $DeviceType = "Desktop"
}
2 {
    $DeviceType = "Laptop"
}
3 {
    $DeviceType = "Workstation"
}
}
#Windows Updates Pending
$winupdates = get-windowsupdate -IsAssigned
$pendingupdates = $winupdates.count
#Windows Edition
$windedition = (Get-WmiObject -class Win32_OperatingSystem).Caption
#Windows Build
$winbuild = (Get-WmiObject -class Win32_OperatingSystem).BuildNumber
#Windows Version
$winver = (Get-WmiObject -class Win32_OperatingSystem).Version
#Windows Active
$activationStatus = cscript //nologo c:\windows\system32\slmgr.vbs /xpr
if ($activationStatus -match "permanently activated") {
    $winactive = "True"
} else {
    $winactive = "False"
}
$serialNumber = Get-WmiObject win32_bios | Select-Object -expandproperty Serialnumber
#________________________________________________
#                Creating Object
#________________________________________________

$LogObject = [PSCustomObject]@{
    TimeGenerated = $DateLogged
    DeviceName = $DeviceName
    DeviceModel = $DeviceModel.replace(' ','')
    Manufacturer = $Manufacturer
    SerialNumber = $serialNumber
    UpTime = $FormattedUpTime
    Printers = $printers.Trim()
    TotalSizeGB = $totalSizeGB
    FreeSpaceGB = $freeSpaceGB
    BatteryHealth = $batteryhealth
    StartupPrograms = $startupprogs.Trim()
    DeviceType = $DeviceType
    PendingWindowsUpdates = $pendingupdates
    WindowsEdition = $windedition
    WindowsBuild = $winbuild
    WindowsVersion = $winver
    WindowsActivated = $winactive
}

#________________________________________________
#            Packaging and Shipping
#________________________________________________


#POST Request
Add-Type -AssemblyName System.Web

$scope = [System.Web.HttpUtility]::UrlEncode("https://monitor.azure.com//.default")   
$body = "client_id=$appId&scope=$scope&client_secret=$appSecret&grant_type=client_credentials";
$headers = @{"Content-Type" = "application/x-www-form-urlencoded" };
$uri = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"
$bearerToken = (Invoke-RestMethod -Uri $uri -Method "Post" -Body $body -Headers $headers).access_token

$body = ConvertTo-Json @($LogObject)

$headers = @{"Authorization" = "Bearer $bearerToken"; "Content-Type" = "application/json"};
$uri = "$DceURI/dataCollectionRules/$DcrImmutableId/streams/Custom-$Table"+"?api-version=2023-01-01";
$uploadResponse = Invoke-RestMethod -Uri $uri -Method "Post" -Body $body -Headers $headers;

write-host $uploadResponse