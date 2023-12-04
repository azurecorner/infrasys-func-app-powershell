Param
(
    [Parameter(Mandatory=$true, HelpMessage = "Please provide a valid resource group")]
    [string]$resourceGroupName,
    [Parameter(Mandatory=$true, HelpMessage = "Please provide a valid location")]
    [string]$resourceGroupLocation,
    [Parameter(Mandatory=$true, HelpMessage = "Please provide a valid function app name")]
    [string]$functionAppName
 )

$storageAccountName = "st$functionAppName"
$skuStorage = "Standard_LRS"
$functionsVersion = "4"
$ruleName = "restrict_rule"
$ipAddress = "163.116.242.53/32"
# Create an Azure storage account in the resource group.

$storageAcc=Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $storageAccountName -ErrorVariable notPresent -ErrorAction SilentlyContinue
if($notPresent){ 
Write-Host "Creating $storageAccountName"
$storageAcc=New-AzStorageAccount -Name $storageAccountName -Location $resourceGroupLocation -ResourceGroupName $resourceGroupName -SkuName $skuStorage
}
else {
    Write-Host -ForegroundColor Yellow "storage account already  exist"
    Write-Host  -ForegroundColor Magenta "using storage account $storageAccountName on location $resourceGroupLocation  "

}
# Create a serverless function app in the resource group.
Write-Host "Creating $functionAppName"

New-AzAppServicePlan -ResourceGroupName $resourceGroupName -Name "myAppServicePlan" -Location $resourceGroupLocation -Tier "Basic"

# Get the created App Service Plan
$appServicePlan = Get-AzAppServicePlan -ResourceGroupName $resourceGroupName -Name "myAppServicePlan"

$functionApp = Get-AzFunctionApp -ResourceGroupName $resourceGroupName -Name $functionAppName  -ErrorAction SilentlyContinue

Write-Host "notPresent = $functionApp"
 if($null -eq $functionApp){ 
    Write-Host "Creating function app $functionAppName"
    $functionApp = New-AzFunctionApp -Name $functionAppName `
                  -ResourceGroupName $resourceGroupName `
                  -Location $resourceGroupLocation `
                  -StorageAccountName $storageAcc.StorageAccountName `
                  -Runtime PowerShell `
                  -FunctionsVersion $functionsVersion `
                  -RuntimeVersion 7.2 `
                  -OSType "Windows"


                  # Associate the Function App with the App Service Plan


Update-AzFunctionApp -Name $functionAppName  -ResourceGroupName $resourceGroupName -PlanName $appServicePlan.Name -Force
    Write-Host -ForegroundColor Green "$($functionApp.Name) created succesfully at location $resourceGroupLocation"
    }
    else {
        Write-Host -ForegroundColor Yellow "function app  $($functionApp.Name) already  exist"
        Write-Host  -ForegroundColor Magenta "using function app $storageAccountName on location $resourceGroupLocation  "
    }                

    

# Define access restriction rule

# $rule =  Get-AzWebAppAccessRestrictionConfig -ResourceGroupName $resourceGroupName -Name $ruleName -ErrorVariable notPresent -ErrorAction SilentlyContinue
# Write-Host "rule =$rule and $notPresent = $notPresent"
# if ($notPresent)
# {
#     Add-AzWebAppAccessRestrictionRule -ResourceGroupName $resourceGroupName -WebAppName $functionApp.Name `
#     -Name $ruleName  -Priority 100 -Action Allow -IpAddress $ipAddress

#     Add-AzWebAppAccessRestrictionRule -ResourceGroupName $resourceGroupName -WebAppName $functionApp.Name `
#     -Name "DenyAll" -Priority 200 -Action Deny -IpAddress "0.0.0.0/0" -Description "Deny All IPs"
# }

