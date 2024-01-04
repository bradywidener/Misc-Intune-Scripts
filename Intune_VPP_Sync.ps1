Connect-MgGraph -NoWelcome
#Install this module if you haven't already with install-module
Import-Module Microsoft.Graph.Beta.Devices.CorporateManagement

#Creates an Object containing your VPP tokens
$VPPTokenList = Get-MgBetaDeviceAppManagementVppToken

#Loop that will cycle through each token and request a sync.
ForEach ($Token in $VPPTokenList){
    Sync-MgBetaDeviceAppManagementVppTokenLicense -VppTokenId $Token.Id
}

#Clean up
Disconnect-MgGraph
Remove-Module Microsoft.Graph.Beta.Devices.CorporateManagement