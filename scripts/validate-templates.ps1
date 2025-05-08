param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("dev", "test", "prod")]
    [string]$Environment,
    
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName
)

Write-Host "Validating ARM templates for $Environment environment..."

$templateFile = "./arm-templates/main.json"
$parameterFile = "./arm-templates/parameters.$Environment.json"

# Ensure the resource group exists for validation
$resourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
if (!$resourceGroup) {
    Write-Host "Resource Group '$ResourceGroupName' does not exist. Creating for validation..."
    New-AzResourceGroup -Name $ResourceGroupName -Location "eastus"
}

$validation = Test-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName `
                                            -TemplateFile $templateFile `
                                            -TemplateParameterFile $parameterFile

if ($validation) {
    Write-Error "Template validation failed:`n$($validation.Message)"
    exit 1
} else {
    Write-Host "Template validation successful for $Environment environment."
}