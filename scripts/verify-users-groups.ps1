# Verify users and groups were created successfully

# List all users you've created
Write-Host "Listing users:" -ForegroundColor Cyan
Get-AzADUser | Where-Object {$_.DisplayName -in @("Dev User", "Test User", "Prod User")} | Format-Table DisplayName, UserPrincipalName, Id

# List all groups you've created
Write-Host "`nListing groups:" -ForegroundColor Cyan  
$allGroups = Get-AzADGroup | Where-Object {$_.DisplayName -in @("Dev Team", "Test Team", "Prod Team")}
$allGroups | Format-Table DisplayName, Id

# Check group membership for each group, handling the correct ID format
Write-Host "`nChecking group memberships:" -ForegroundColor Cyan

foreach ($group in $allGroups) {
    Write-Host "`nMembers of $($group.DisplayName):" -ForegroundColor Yellow
    
    try {
        # Try the most common format
        $members = Get-AzADGroupMember -ObjectId $group.Id -ErrorAction Stop
        $members | Format-Table DisplayName, UserPrincipalName
    }
    catch {
        try {
            # Alternative format that some Az versions use
            $members = Get-AzADGroupMember -GroupObjectId $group.Id -ErrorAction Stop
            $members | Format-Table DisplayName, UserPrincipalName
        }
        catch {
            Write-Host "Unable to retrieve members using standard methods. Trying alternative approach..." -ForegroundColor Yellow
            
            # Alternative approach using Microsoft Graph if available
            if (Get-Command Get-MgGroupMember -ErrorAction SilentlyContinue) {
                try {
                    Write-Host "Using Microsoft Graph API..." -ForegroundColor Yellow
                    $members = Get-MgGroupMember -GroupId $group.Id
                    $members | Format-Table DisplayName, UserPrincipalName
                }
                catch {
                    Write-Host "Unable to retrieve group members: $_" -ForegroundColor Red
                }
            }
            else {
                Write-Host "Could not retrieve group members. Microsoft Graph module not available." -ForegroundColor Red
                Write-Host "Consider installing it with: Install-Module Microsoft.Graph" -ForegroundColor Yellow
            }
        }
    }
}