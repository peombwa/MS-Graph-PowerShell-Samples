#Import-Module F:\M\msgraph-sdk-powershell\src\Authentication\Authentication\Microsoft.Graph.Authentication.psd1
#Import-Module F:\M\msgraph-sdk-powershell\src\Beta\Users.User\Users.User\Microsoft.Graph.Users.User.psd1
Connect-Graph -TenantId $env:App_Tenant_Id -ClientId $env:App_Client_ID -CertificateThumbprint $env:App_Cert_Thumbprint
$AADAllUsers = Get-MgUser -All:$true -Property Id,UserPrincipalName
Disconnect-Graph