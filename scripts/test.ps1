$environement="qua"
$resourceGroupLocation = "francecentral"
$resourceGroupName = "RG-CLD-$environement-FRACE-001"
$virtualNetwokResourceGroupName="RG-SYSTEME-FRACE-001
"
$appServicePlan = "asp-ctnvb-$environement-frace-001"
$functionApp = "funcctnvbquafrace001"
$storage = "stcldquafrace003"
$skuStorage = "Standard_LRS"
$skuPlan = "B1"
$functionsVersion = "4"

$hubVirtualNetworkName ='vnet-infrasys-hub-shared-frace-sandbox' 
$hubResourceGroupName = "rg-infrasys-shared-sandbox"
$virtualNetworkName ='VNET-SYSTEME-FRACE-001' 
$privateEndpointSubnetName= 'snet-cld-qua-frace-001' 

$privateDnsZoneName ='privatelink.azurewebsites.net'  
$dnsLinkName ='dsnLink'  
$privateEndpointName ='pe-func-ctnvb-qua-frace-001'   
$privateDnsZoneConfigName ='snet-cld-qua-ZoneGroup'   
$groupId ='sites'


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
    $function=New-AzFunctionApp -Name $functionApp -StorageAccountName $storageAcc.StorageAccountName  -PlanName $appServicePlan -ResourceGroupName $resourceGroupName -Runtime PowerShell -FunctionsVersion $functionsVersion -RuntimeVersion 7.2

 }

 $ResourceId =$function.Id

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
$virtualNetwork = Get-AzVirtualNetwork -ResourceGroupName $virtualNetwokResourceGroupName -Name $virtualNetworkName
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

# Crate hub link 
$hublk = Get-AzPrivateDnsVirtualNetworkLink -Name "hub$dnsLinkName" -ZoneName $privateDnsZoneName -ResourceGroupName $resourceGroupName   -ErrorAction SilentlyContinue
if ($null -eq $hublk) 
{
    $hubVirtualNetwork = Get-AzVirtualNetwork -ResourceGroupName $hubResourceGroupName -Name $hubVirtualNetworkName

    Write-Host -ForegroundColor Green "Creating PrivateDnsVirtualNetworkLink  $dnsLinkName at location $resourceGroupLocation"
    $lk = @{
    ResourceGroupName = $resourceGroupName
    ZoneName = $privateDnsZoneName
    Name = "hub$dnsLinkName"
    VirtualNetworkId = $hubVirtualNetwork.Id
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