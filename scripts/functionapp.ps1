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

Write-Host "Creating app service plan $myAppServicePlan"
New-AzAppServicePlan -ResourceGroupName $resourceGroupName -Name "myAppServicePlan" -Location $resourceGroupLocation -Tier "Basic"

# Get the created App Service Plan
Write-Host "Getting app service plan $myAppServicePlan"
$appServicePlan = Get-AzAppServicePlan -ResourceGroupName $resourceGroupName -Name "myAppServicePlan"

$functionApp = Get-AzFunctionApp -ResourceGroupName $resourceGroupName -Name $functionAppName  -ErrorAction SilentlyContinue

Write-Host "notPresent = $functionApp"
Write-Host "Creating function app $functionApp"
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

Write-Host "Updating  app service plan $myAppServicePlan"
Update-AzFunctionApp -Name $functionAppName  -ResourceGroupName $resourceGroupName -PlanName $appServicePlan.Name -Force
    Write-Host -ForegroundColor Green "$($functionApp.Name) created succesfully at location $resourceGroupLocation"
    }
    else {
        Write-Host -ForegroundColor Yellow "function app  $($functionApp.Name) already  exist"
        Write-Host  -ForegroundColor Magenta "using function app $storageAccountName on location $resourceGroupLocation  "
    }                

    

# Define access restriction rule

$rule =  Get-AzWebAppAccessRestrictionConfig -ResourceGroupName $resourceGroupName -Name $ruleName -ErrorVariable notPresent -ErrorAction SilentlyContinue
Write-Host "rule =$rule and $notPresent = $notPresent"
if ($notPresent)
{
    Add-AzWebAppAccessRestrictionRule -ResourceGroupName $resourceGroupName -WebAppName $functionApp.Name `
    -Name $ruleName  -Priority 100 -Action Allow -IpAddress $ipAddress

    Add-AzWebAppAccessRestrictionRule -ResourceGroupName $resourceGroupName -WebAppName $functionApp.Name `
    -Name "DenyAll" -Priority 200 -Action Deny -IpAddress "0.0.0.0/0" -Description "Deny All IPs"
}



# $resourceGroupName="RG-SYSTEME-FRACE-001-SANDBOX"
# $resourceGroupLocation="francecentral"
$virtualNetworkName ='VNET-SYSTEME-FRACE-001' 
$privateEndpointSubnetName= 'snet-funapp-prod-frace-001' 
$ResourceId =$functionApp.Id
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