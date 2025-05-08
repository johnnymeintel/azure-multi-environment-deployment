# Basic script to create users and groups in Azure
# Connect to Azure if not already connected
try {
    $context = Get-AzContext
    if (-not $context) {
        Connect-AzAccount
    }
} catch {
    Write-Host "Error connecting to Azure. Please run Connect-AzAccount manually." -ForegroundColor Red
    exit
}

# Get the default domain from your tenant
$tenantInfo = Get-AzTenant
$domain = $tenantInfo.DefaultDomain
Write-Host "Using domain: $domain" -ForegroundColor Green

# Create a secure password
$securePassword = ConvertTo-SecureString "P@ssword123!" -AsPlainText -Force
Write-Host "Using password: P@ssword123!" -ForegroundColor Yellow
Write-Host "Important: Change this in production environments!" -ForegroundColor Red

# Create users for each environment
Write-Host "`nCreating users..." -ForegroundColor Cyan
$devUser = New-AzADUser -DisplayName "Dev User" -UserPrincipalName "devuser@$domain" -Password $securePassword -MailNickname "devuser"
$testUser = New-AzADUser -DisplayName "Test User" -UserPrincipalName "testuser@$domain" -Password $securePassword -MailNickname "testuser"
$prodUser = New-AzADUser -DisplayName "Prod User" -UserPrincipalName "produser@$domain" -Password $securePassword -MailNickname "produser"

Write-Host "Dev User created: $($devUser.DisplayName) - $($devUser.UserPrincipalName)" -ForegroundColor Green
Write-Host "Test User created: $($testUser.DisplayName) - $($testUser.UserPrincipalName)" -ForegroundColor Green
Write-Host "Prod User created: $($prodUser.DisplayName) - $($prodUser.UserPrincipalName)" -ForegroundColor Green

# Create groups
Write-Host "`nCreating groups..." -ForegroundColor Cyan
$devGroup = New-AzADGroup -DisplayName "Dev Team" -MailNickname "devteam"
$testGroup = New-AzADGroup -DisplayName "Test Team" -MailNickname "testteam"
$prodGroup = New-AzADGroup -DisplayName "Prod Team" -MailNickname "prodteam"

Write-Host "Dev Group created: $($devGroup.DisplayName)" -ForegroundColor Green
Write-Host "Test Group created: $($testGroup.DisplayName)" -ForegroundColor Green
Write-Host "Prod Group created: $($prodGroup.DisplayName)" -ForegroundColor Green

# Add users to groups
Write-Host "`nAdding users to groups..." -ForegroundColor Cyan
Add-AzADGroupMember -TargetGroupObjectId $devGroup.Id -MemberObjectId $devUser.Id
Add-AzADGroupMember -TargetGroupObjectId $testGroup.Id -MemberObjectId $testUser.Id
Add-AzADGroupMember -TargetGroupObjectId $prodGroup.Id -MemberObjectId $prodUser.Id

Write-Host "Users added to their respective groups" -ForegroundColor Green

Write-Host "`nScript completed!" -ForegroundColor Green