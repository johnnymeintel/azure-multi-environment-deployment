param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("dev", "test", "prod")]
    [string]$Environment,
    
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [switch]$Force
)

# Login to Azure (if not already logged in)
$context = Get-AzContext
if (!$context) {
    Connect-AzAccount
}

# Confirm deletion
if (!$Force) {
    $confirmation = Read-Host "Are you sure you want to delete all resources in the $Environment environment? (y/n)"
    if ($confirmation -ne 'y') {
        Write-Host "Operation cancelled."
        exit
    }
}

Write-Host "Removing resource group '$ResourceGroupName'..."
Remove-AzResourceGroup -Name $ResourceGroupName -Force

Write-Host "Cleanup completed. All resources in the $Environment environment have been removed."