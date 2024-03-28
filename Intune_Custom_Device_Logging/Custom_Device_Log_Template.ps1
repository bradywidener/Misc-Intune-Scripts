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

#I would also import any needed modules in this section of the code.

#____________________________________________
#                 GRABBING INFO
#_____________________________________________

#Gather device info and set equal to a variable. Below I have left a variable for getting the Device Name as an example.

#Device Name
$DeviceName = Get-WmiObject -Class Win32_ComputerSystem  | Select-Object -expandproperty Name

#________________________________________________
#                Creating Object
#________________________________________________

#Create your object by assigning your variables from the last step in the object, and give them a label.
#Below I have taken the variable $DeviceName and added it to our object with the label, DeviceName.

$LogObject = [PSCustomObject]@{
    DeviceName = $DeviceName
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