# Function app and storage account names must be unique.

# Variable block

$location = "francecentral"
$resourceGroup = "RG-SYSTEME-FRACE-001-TEST"
$appServicePlan = "funcswapnsgtrafficxyzasp"
$functionApp = "funcswapnsgtrafficxyz"
$storage = "st$functionApp"
$skuStorage = "Standard_LRS"
$skuPlan = "B1"
$functionsVersion = "4"

# Create a resource group
# Write-Host "Creating $resourceGroup in $location..."
# New-AzResourceGroup -Name $resourceGroup -Location $location -Tag $tag

$storageAcc=Get-AzStorageAccount -ResourceGroupName $resourceGroup -Name $storage -ErrorVariable notPresent -ErrorAction SilentlyContinue
if($notPresent){ 
    Write-Host "Creating $storage"
    # Create an Azure storage account in the resource group.
    Write-Host "Creating $storage"
    $storageAcc=New-AzStorageAccount -Name $storage -Location $location -ResourceGroupName $resourceGroup -SkuName $skuStorage

}
else {
    Write-Host -ForegroundColor Yellow "storage account already  exist"
    Write-Host  -ForegroundColor Magenta "using storage account $storageAccountName on location $location  "

}


# Create an App Service plan
Write-Host "Creating $appServicePlan"
New-AzFunctionAppPlan -Name $appServicePlan -ResourceGroupName $resourceGroup -Location $location -Sku $skuPlan -WorkerType Windows


$function = Get-AzFunctionApp -ResourceGroupName $resourceGroup -Name $functionApp  -ErrorAction SilentlyContinue

Write-Host "notPresent = $function"
Write-Host "Creating function app $function"
if($null -eq $function){ 
    # Create a Function App
    Write-Host "Creating $function"
    New-AzFunctionApp -Name $functionApp -StorageAccountName $storage -PlanName $appServicePlan -ResourceGroupName $resourceGroup -Runtime PowerShell -FunctionsVersion $functionsVersion

 }