#Install these modules before importing if you haven't already!
#Install-Module Microsoft.Graph.Beta.Devicemanagement
#Install-Module Microsoft.Graph.Beta.Users

Import-Module Microsoft.Graph.Beta.Devicemanagement
Import-Module Microsoft.Graph.Beta.Users

Connect-MgGraph -Scopes "User.Read.All" -NoWelcome

Write-Output ""
Write-Output "This script allows you to find the last logged on user of an Intune-joined device using the device's hostname."
Write-Output ""
$deviceName = Read-Host "What is the device's hostname?"

# Queries for the device that matches the name and sets the variable equal to the Users Logged On
$device = Get-MgBetaDeviceManagementManagedDevice -Filter "contains(deviceName,'$deviceName')"

if ($device) {
    $lastUsers = $device.UsersLoggedOn

    $usersList = @()

    foreach ($user in $lastUsers) {
        $lastLogon = $user.LastLogOnDateTime
        $userObject = New-Object PSObject -Property @{
            UserId = $user.UserId
            DisplayName = (Get-MgBetaUser -UserId $user.UserId).DisplayName
            LastLoggedOnDateTime = $lastLogon
        }
        $usersList += $userObject

    }
    Write-Output ""
    $usersList | Out-Host -Paging # Display the users' list immediately

} else {
    Write-Output "Device not found."
}
read-host "Press Enter to close this window"

Disconnect-MgGraph