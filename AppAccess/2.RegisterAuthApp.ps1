[CmdletBinding()]
param(
    [Parameter(Mandatory=$False, HelpMessage='Name of the app to create.')]
    [string] $appName = "Powershell-Daemon-App",
    [Parameter(Mandatory=$False, HelpMessage='Tenant ID (This is a GUID which represents the "Directory ID" of the AzureAD tenant into which you want to create the apps')]
    [string] $tenantId = $env:App_Tenant_Id
)
# Login as an admin of a tenant.
$scopes = "Application.ReadWrite.All", "DeviceManagementServiceConfig.Read.All"
if($tenantId){
    Connect-Graph -Tenant $tenantId -Scopes $scopes
} else {
    Connect-Graph -$scopes
}

$credentials = Get-MgContext
$tenantId = $credentials.TenantId

# Get tenant details.
$tenantName = Get-MgOrganization -Select VerifiedDomains |`
          Select-Object -ExpandProperty VerifiedDomains |`
          Where-Object { $_.IsDefault } |`
          Select-Object -ExpandProperty Name

# Create new app.
$clientApp = New-MgApplication -DisplayName $appName`
                               -WebRedirectUris "https://daemon"`
                               -IdentifierUris "https://$tenantName/daemon-console" `
                               -isFallbackPublicClient $False
# Create new certificate.
$certificateName = "CN=" + $appName.Replace(" ", "")
$certificateLocation = "Cert:\CurrentUser\My"
$certificate = New-SelfSignedCertificate -Subject $certificateName`
                                        -CertStoreLocation $certificateLocation`
                                        -KeyExportPolicy Exportable`
                                        -KeySpec Signature

$certKeyId = [Guid]::NewGuid()
$certBase64Value = [System.Convert]::ToBase64String($certificate.GetRawCertData())
$certBase64Thumbprint = [System.Convert]::ToBase64String($certificate.GetCertHash())

# Add a Azure Key Credentials from the certificate for the daemon application
$clientKeyCredentials = Add-MgApplicationKey -ApplicationId $clientApp.Id`
                                             -KeyCredentialType "AsymmetricX509Cert"`
                                             -KeyCredentialUsage "Verify"`
                                             -KeyCredentialStartDateTime $certificate.NotAfter`
                                             -KeyCredentialEndDateTime $certificate.NotBefore`
                                             -KeyCredentialKeyInputFile $certBase64Thumbprint`
                                             -KeyCredentialCustomKeyIdentifierInputFile $certificateName`

