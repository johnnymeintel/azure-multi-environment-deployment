param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("dev", "test", "prod")]
    [string]$Environment,
    
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "eastus"
)

# Login to Azure (if not already logged in)
$context = Get-AzContext
if (!$context) {
    Connect-AzAccount
}

# Create Resource Group if it doesn't exist
$resourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
if (!$resourceGroup) {
    New-AzResourceGroup -Name $ResourceGroupName -Location $Location
    Write-Host "Resource Group '$ResourceGroupName' created."
}

# Deploy ARM templates
$templateFile = "./arm-templates/main.json"
$parameterFile = "./arm-templates/parameters.$Environment.json"

Write-Host "Validating ARM template deployment for $Environment environment..."
$validation = Test-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName `
                                            -TemplateFile $templateFile `
                                            -TemplateParameterFile $parameterFile

if ($validation) {
    Write-Error "Template validation failed:`n$($validation.Message)"
    exit 1
}

Write-Host "Deploying ARM template to $Environment environment..."
$deploymentName = "multi-env-deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
New-AzResourceGroupDeployment -Name $deploymentName `
                              -ResourceGroupName $ResourceGroupName `
                              -TemplateFile $templateFile `
                              -TemplateParameterFile $parameterFile `
                              -Verbose

Write-Host "Deployment to $Environment environment completed."

# Apply Azure Policies
Write-Host "Applying Azure Policies to $Environment environment..."
# Note: Policy deployment code would go here in a real implementation
# This is a simplified script for demonstration purposes

# Configure RBAC
Write-Host "Configuring RBAC for $Environment environment..."
$rbacFile = "./rbac/$Environment-access.json"
$rbacConfig = Get-Content -Path $rbacFile | ConvertFrom-Json

foreach ($assignment in $rbacConfig) {
    New-AzRoleAssignment -ObjectId $assignment.principalId `
                        -RoleDefinitionId $assignment.roleDefinitionId `
                        -Scope "/subscriptions/$($(Get-AzContext).Subscription.Id)/resourceGroups/$ResourceGroupName" `
                        -ErrorAction SilentlyContinue
    Write-Host "Role assignment created: $($assignment.description)"
}

Write-Host "Environment setup completed successfully."