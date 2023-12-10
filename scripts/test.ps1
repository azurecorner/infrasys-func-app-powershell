# Function app and storage account names must be unique.

# Variable block

$resourceGroupLocation = "francecentral"
$resourceGroupName = "RG-SYSTEME-FRACE-001-TEST"
$appServicePlan = "funcswapnsgtrafficxyzasp"
$functionApp = "funcswapnsgtrafficxyz"
$storage = "st$functionApp"
$skuStorage = "Standard_LRS"
$skuPlan = "B1"
$functionsVersion = "4"

# Create a resource group
# Write-Host "Creating $resourceGroupName in $location..."
# New-AzResourceGroup -Name $resourceGroupName -Location $location -Tag $tag

$storageAcc=Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storage -ErrorVariable notPresent -ErrorAction SilentlyContinue
if($notPresent){ 
    Write-Host "Creating $storage"
    # Create an Azure storage account in the resource group.
    Write-Host "Creating $storage"
    $storageAcc=New-AzStorageAccount -Name $storage -Location $resourceGroupLocation -ResourceGroupName $ResourceGroupName -SkuName $skuStorage

}
else {
    Write-Host -ForegroundColor Yellow "storage account already  exist"
    Write-Host  -ForegroundColor Magenta "using storage account $storageAccountName on location $resourceGroupLocation  "

}


# Create an App Service plan
Write-Host "Creating $appServicePlan"
New-AzFunctionAppPlan -Name $appServicePlan -ResourceGroupName $resourceGroupName -Location $resourceGroupLocation -Sku $skuPlan -WorkerType Windows


$function = Get-AzFunctionApp -ResourceGroupName $resourceGroupName -Name $functionApp  -ErrorAction SilentlyContinue

Write-Host "notPresent = $function"
Write-Host "Creating function app $function"
if($null -eq $function){ 
    # Create a Function App
    Write-Host "Creating $function"
    $function=New-AzFunctionApp -Name $functionApp -StorageAccountName $storage -PlanName $appServicePlan -ResourceGroupName $resourceGroupName -Runtime PowerShell -FunctionsVersion $functionsVersion

 }



$virtualNetworkName ='VNET-SYSTEME-FRACE-001' 
$privateEndpointSubnetName= 'snet-funapp-prod-frace-001' 
$ResourceId =$function.Id
$privateDnsZoneName ='privatelink.azurewebsites.net'  
$dnsLinkName ='dsnLink'  
$privateEndpointName ='pefuncswapnsgtraffic'   
$privateDnsZoneConfigName ='funcswapnsgtrafficZoneGroup'   
$groupId ='sites'

Write-Host -ForegroundColor Blue "####### creating private endpoint $privateEndpointName using resourceGroupName $resourceGroupName location $resourceGroupLocation `n" `
"virtualNetworkName $virtualNetworkName `n" `
"privateEndpointSubnetName $privateEndpointSubnetName `n" `
"ResourceId $ResourceId `n" `
"privateDnsZoneName $privateDnsZoneName `n" `
"dnsLinkName $dnsLinkName `n" `
"privateEndpointName $privateEndpointName `n" `
"privateDnsZoneConfigName $privateDnsZoneConfigName `n" `
"groupId $groupId  ########"

$pec = @{
Name = "$groupId-connection"
PrivateLinkServiceId = $ResourceId
GroupID = $groupId
}
$privateEndpointConnection = New-AzPrivateLinkServiceConnection @pec

## Place the virtual network you created previously into a variable. ##
$virtualNetwork = Get-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Name $virtualNetworkName
$subnet = Get-AzVirtualNetworkSubnetConfig -Name $privateEndpointSubnetName -VirtualNetwork $virtualNetwork
## Create the private endpoint. ##

$pe = Get-AzPrivateEndpoint -Name $privateEndpointName -ResourceGroupName $resourceGroupName  -ErrorVariable notPresent -ErrorAction SilentlyContinue
if ($notPresent)
{
Write-Host -ForegroundColor Green "creating private endpoint  $privateEndpointName at location $resourceGroupLocation"
$pe = @{
ResourceGroupName = $resourceGroupName
Name = $privateEndpointName
Location = $resourceGroupLocation 
Subnet = $subnet
PrivateLinkServiceConnection = $privateEndpointConnection
}
New-AzPrivateEndpoint @pe

Write-Host -ForegroundColor Green "private endpoint  $privateEndpointName successfully created at location $resourceGroupLocation"
}  
else {
Write-Host -ForegroundColor Yellow "private endpoint $privateEndpointName already  exist at location $resourceGroupLocation"
Write-Host  -ForegroundColor Magenta "using private endpoint  $privateEndpointName on location $resourceGroupLocation "
}

## Create the private DNS zone. ##
$zone = Get-AzPrivateDnsZone -Name $privateDnsZoneName -ResourceGroupName $resourceGroupName  -ErrorVariable notPresent -ErrorAction SilentlyContinue
if ($notPresent)
{
Write-Host -ForegroundColor Green "creating private dns zone $privateDnsZoneName  at  location  $resourceGroupLocation"
$zn = @{
ResourceGroupName = $resourceGroupName
Name = $privateDnsZoneName
}
$zone = New-AzPrivateDnsZone @zn

Write-Host -ForegroundColor Green "private dns zone $privateDnsZoneName created succesfully at location $resourceGroupLocation"
}
else {
Write-Host -ForegroundColor Yellow "private dns zone $privateDnsZoneName already  exist at location $resourceGroupLocation"
Write-Host  -ForegroundColor Magenta "using private dns zone   $privateDnsZoneName on location $resourceGroupLocation "
}

## Create a DNS network link. ##
$lk = Get-AzPrivateDnsVirtualNetworkLink -Name $dnsLinkName -ZoneName $privateDnsZoneName -ResourceGroupName $resourceGroupName   -ErrorAction SilentlyContinue
if ($null -eq $lk) 
{
Write-Host -ForegroundColor Green "Creating PrivateDnsVirtualNetworkLink  $dnsLinkName at location $resourceGroupLocation"
$lk = @{
ResourceGroupName = $resourceGroupName
ZoneName = $privateDnsZoneName
Name = $dnsLinkName
VirtualNetworkId = $virtualNetwork.Id
}

New-AzPrivateDnsVirtualNetworkLink @lk
Write-Host -ForegroundColor Green "PrivateDnsVirtualNetworkLink $dnsLinkName successfully created at location $resourceGroupLocation"
}
else {
Write-Host -ForegroundColor Yellow "PrivateDnsVirtualNetworkLink $dnsLinkName already  exist at location $resourceGroupLocation"
Write-Host  -ForegroundColor Magenta "using PrivateDnsVirtualNetworkLink   $dnsLinkName on location $resourceGroupLocation "
}

## Configure the DNS zone. ##
$cg = @{
Name = $privateDnsZoneName
PrivateDnsZoneId = $zone.ResourceId
}
$config = New-AzPrivateDnsZoneConfig @cg

## Create the DNS zone group. ##
$zg = Get-AzPrivateDnsZoneGroup -ResourceGroupName $resourceGroupName -PrivateEndpointName $privateEndpointName -name $privateDnsZoneConfigName  -ErrorAction SilentlyContinue
# Write-Host $zg
if ($null -eq $zg) 
{
Write-Host -ForegroundColor Green "PrivateDnsZoneGroup  $privateDnsZoneConfigName at location $resourceGroupLocation"
$zg = @{
ResourceGroupName = $resourceGroupName
PrivateEndpointName = $privateEndpointName
Name = $privateDnsZoneConfigName
PrivateDnsZoneConfig = $config
}
New-AzPrivateDnsZoneGroup @zg
Write-Host -ForegroundColor Green "PrivateDnsZoneGroup $privateDnsZoneConfigName successfully created at location $resourceGroupLocation"
}
else {
Write-Host -ForegroundColor Yellow "PrivateDnsZoneGroup $privateDnsZoneConfigName already exist at location $resourceGroupLocation"
Write-Host  -ForegroundColor Magenta "using PrivateDnsZoneGroup   $privateDnsZoneConfigName on location $resourceGroupLocation "
}


Write-Host -ForegroundColor Blue "####### private endpoint successfully created $privateEndpointName using resourceGroupName $resourceGroupName location $resourceGroupLocation `n" `
"virtualNetworkName $virtualNetworkName `n" `
"privateEndpointSubnetName $privateEndpointSubnetName `n" `
"ResourceId $ResourceId `n" `
"privateDnsZoneName $privateDnsZoneName `n" `
"dnsLinkName $dnsLinkName `n" `
"privateEndpointName $privateEndpointName `n" `
"privateDnsZoneConfigName $privateDnsZoneConfigName `n" `
"groupId $groupId  ########"