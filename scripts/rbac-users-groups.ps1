# Script to assign RBAC roles to our users for each environment

# First, get the user information
$devUser = Get-AzADUser -DisplayName "Dev User"
$testUser = Get-AzADUser -DisplayName "Test User" 
$prodUser = Get-AzADUser -DisplayName "Prod User"

# Display the users we'll be working with
Write-Host "Users found:" -ForegroundColor Cyan
Write-Host "Dev User: $($devUser.UserPrincipalName)"
Write-Host "Test User: $($testUser.UserPrincipalName)"
Write-Host "Prod User: $($prodUser.UserPrincipalName)"

# Get the resource groups for our environments
$resourceGroups = Get-AzResourceGroup | Where-Object { $_.ResourceGroupName -like "*-rg" -or $_.ResourceGroupName -like "*rg" }
Write-Host "`nResource Groups found:" -ForegroundColor Cyan
$resourceGroups | Format-Table ResourceGroupName, Location

# Let the user select resource groups for each environment
Write-Host "`nSelect Resource Groups for each environment:" -ForegroundColor Yellow
for ($i=0; $i -lt $resourceGroups.Count; $i++) {
    Write-Host "[$i] $($resourceGroups[$i].ResourceGroupName)"
}

$devRgIndex = Read-Host "`nSelect Dev environment resource group index"
$testRgIndex = Read-Host "Select Test environment resource group index"
$prodRgIndex = Read-Host "Select Prod environment resource group index"

$devRg = $resourceGroups[[int]$devRgIndex].ResourceGroupName
$testRg = $resourceGroups[[int]$testRgIndex].ResourceGroupName
$prodRg = $resourceGroups[[int]$prodRgIndex].ResourceGroupName

Write-Host "`nSelected Resource Groups:" -ForegroundColor Green
Write-Host "Dev: $devRg"
Write-Host "Test: $testRg"
Write-Host "Prod: $prodRg"

# Assign roles for Dev environment - more permissive
Write-Host "`nAssigning roles for Dev environment..." -ForegroundColor Cyan
try {
    New-AzRoleAssignment -ObjectId $devUser.Id -RoleDefinitionName "Contributor" -ResourceGroupName $devRg
    Write-Host "Assigned Contributor role to Dev User for $devRg" -ForegroundColor Green
} catch {
    Write-Host "Error assigning Dev role: $_" -ForegroundColor Red
}

# Assign roles for Test environment - more restrictive
Write-Host "`nAssigning roles for Test environment..." -ForegroundColor Cyan
try {
    New-AzRoleAssignment -ObjectId $testUser.Id -RoleDefinitionName "Reader" -ResourceGroupName $testRg
    Write-Host "Assigned Reader role to Test User for $testRg" -ForegroundColor Green

    # Only assign the VM Contributor role if there are VMs in the test resource group
    $hasVMs = Get-AzVM -ResourceGroupName $testRg -ErrorAction SilentlyContinue
    if ($hasVMs) {
        New-AzRoleAssignment -ObjectId $testUser.Id -RoleDefinitionName "Virtual Machine Contributor" -ResourceGroupName $testRg
        Write-Host "Assigned Virtual Machine Contributor role to Test User for $testRg" -ForegroundColor Green
    } else {
        Write-Host "No VMs found in $testRg. Skipping VM Contributor role assignment." -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error assigning Test roles: $_" -ForegroundColor Red
}

# Assign roles for Prod environment - very restrictive
Write-Host "`nAssigning roles for Prod environment..." -ForegroundColor Cyan
try {
    New-AzRoleAssignment -ObjectId $prodUser.Id -RoleDefinitionName "Reader" -ResourceGroupName $prodRg
    Write-Host "Assigned Reader role to Prod User for $prodRg" -ForegroundColor Green
} catch {
    Write-Host "Error assigning Prod role: $_" -ForegroundColor Red
}

# Create a custom role for database monitoring
Write-Host "`nCreating custom DB Monitor role..." -ForegroundColor Cyan

# Get subscription ID
$subscriptionId = (Get-AzContext).Subscription.Id
Write-Host "Using subscription: $subscriptionId" -ForegroundColor Yellow

try {
    # Check if the custom role already exists
    $existingRole = Get-AzRoleDefinition -Name "DB Monitor" -ErrorAction SilentlyContinue
    
    if ($existingRole) {
        Write-Host "DB Monitor role already exists. Skipping creation." -ForegroundColor Yellow
    } else {
        # Create a custom role based on Reader
        $role = Get-AzRoleDefinition -Name "Reader"
        $role.Id = $null
        $role.Name = "DB Monitor"
        $role.Description = "Can monitor database but not modify"
        $role.Actions.Add("Microsoft.Sql/servers/read")
        $role.Actions.Add("Microsoft.Sql/servers/databases/read")
        $role.AssignableScopes.Clear()
        $role.AssignableScopes.Add("/subscriptions/$subscriptionId")
        
        # Create the custom role
        New-AzRoleDefinition -Role $role
        Write-Host "Created custom DB Monitor role" -ForegroundColor Green
    }
    
    # Assign the DB Monitor role to the Prod User
    # First check if there are SQL servers in the production resource group
    $hasSql = Get-AzSqlServer -ResourceGroupName $prodRg -ErrorAction SilentlyContinue
    if ($hasSql) {
        New-AzRoleAssignment -ObjectId $prodUser.Id -RoleDefinitionName "DB Monitor" -ResourceGroupName $prodRg
        Write-Host "Assigned DB Monitor role to Prod User for $prodRg" -ForegroundColor Green
    } else {
        Write-Host "No SQL servers found in $prodRg. Skipping DB Monitor role assignment." -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error creating or assigning custom role: $_" -ForegroundColor Red
}

Write-Host "`nRole assignments completed!" -ForegroundColor Green