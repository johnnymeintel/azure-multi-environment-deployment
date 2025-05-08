# Get your users
$devUser = Get-AzADUser -DisplayName "Dev User"
$testUser = Get-AzADUser -DisplayName "Test User"
$prodUser = Get-AzADUser -DisplayName "Prod User"

# Check role assignments for each user
Write-Host "Dev User Role Assignments:" -ForegroundColor Cyan
Get-AzRoleAssignment -ObjectId $devUser.Id | Format-Table RoleDefinitionName, Scope -AutoSize

Write-Host "Test User Role Assignments:" -ForegroundColor Cyan
Get-AzRoleAssignment -ObjectId $testUser.Id | Format-Table RoleDefinitionName, Scope -AutoSize

Write-Host "Prod User Role Assignments:" -ForegroundColor Cyan
Get-AzRoleAssignment -ObjectId $prodUser.Id | Format-Table RoleDefinitionName, Scope -AutoSize