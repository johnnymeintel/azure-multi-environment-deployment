# Delete users
$usersToDelete = Get-AzADUser | Where-Object { 
    $_.DisplayName -in @("Dev User", "Test User", "Prod User")
}

foreach ($user in $usersToDelete) {
    Write-Host "Deleting user: $($user.DisplayName)" -ForegroundColor Yellow
    Remove-AzADUser -ObjectId $user.Id
}

# Delete groups
$groupsToDelete = Get-AzADGroup | Where-Object {
    $_.DisplayName -in @("Dev Team", "Test Team", "Prod Team")
}

foreach ($group in $groupsToDelete) {
    Write-Host "Deleting group: $($group.DisplayName)" -ForegroundColor Yellow
    Remove-AzADGroup -ObjectId $group.Id
}

Write-Host "Cleanup completed!" -ForegroundColor Green