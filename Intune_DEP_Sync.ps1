Connect-MgGraph -NoWelcome
#Install these modules if you haven't already with install-module
import-module Microsoft.Graph.Beta.DeviceManagement.Enrollment
Import-Module Microsoft.Graph.Beta.DeviceManagement.Actions

#creating an object with DEP info
$DEPTokenList = Get-MgBetaDeviceManagementDepOnboardingSetting

#Request to sync DEP using the ID from the object above
ForEach ($Token in $DEPTokenList){
    Sync-MgBetaDeviceManagementDepOnboardingSettingWithAppleDeviceEnrollmentProgram -DepOnboardingSettingId $Token.Id
}

#Clean up
Disconnect-MgGraph
Remove-module Microsoft.Graph.Beta.DeviceManagement.Enrollment
Remove-Module Microsoft.Graph.Beta.DeviceManagement.Actions