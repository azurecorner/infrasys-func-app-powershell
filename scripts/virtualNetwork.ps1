Param
(
    [Parameter(Mandatory=$true, HelpMessage = "Please provide a valid resource group")]
    [string]$resourceGroupName,
    [Parameter(Mandatory=$true, HelpMessage = "Please provide a valid location")]
    [string]$resourceGroupLocation,
    [Parameter(Mandatory=$true, HelpMessage = "Please provide a valid virtualNetworkName")]
    [string]$virtualNetworkName,
    [Parameter(Mandatory=$true, HelpMessage = "Please provide a valid environment")]
    [string]$environment
 )
$nsgName = "nsg-stcld002-qua-001"
$backendSubnetName="snet-cld-qua-frace-001"
$application ='infrasysteme';
$tags = @{"application"="$application"; 
                       "environment"="$environment"}
$virtualNetworkAddressPrefix="10.20.0.0/16" 

$subnets = @(
    [pscustomobject]@{
        Name = "snet-cld-qua-frace-001"
        AddressPrefix = "10.20.1.0/24" 
    }
   )


## CREATING VIRTUAL NETWORK
$virtualNetwork =  Get-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -ErrorVariable notPresent -ErrorAction SilentlyContinue
if ($notPresent)
{
    Write-Host -ForegroundColor Green "creating virtual network $virtualNetworkName on resource group $resourceGroupName"
    $virtualNetwork = New-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName `
    -Location $resourceGroupLocation -AddressPrefix $virtualNetworkAddressPrefix #-Tag $tags
    Write-Host -ForegroundColor Green "virtual network $virtualNetworkName successfully created on resource group $resourceGroupName"
    Write-Host $virtualNetwork.Id  
}  
else {
    Write-Host -ForegroundColor Yellow "virtual network $virtualNetworkName already exist on resource group $resourceGroupName"
    Write-Host  -ForegroundColor Magenta "using virtual network $virtualNetworkName on resource group $resourceGroupName "
}

## CREATING VIRTUAL NETWORK SUBNETS

foreach ($item in $subnets) {
    $subnet= Get-AzVirtualNetworkSubnetConfig -Name $item.Name -VirtualNetwork $virtualNetwork  -ErrorVariable notPresent -ErrorAction SilentlyContinue

    if ($notPresent)
    {
        Write-Host -ForegroundColor Green "creating subnet $($item.Name) on virtual network $virtualNetworkName"
        Add-AzVirtualNetworkSubnetConfig -Name $($item.Name) -VirtualNetwork $virtualNetwork -AddressPrefix $item.AddressPrefix | Set-AzVirtualNetwork
        Write-Host -ForegroundColor Green "subnet $($item.Name) successfully created on virtual network $virtualNetworkName"
        Write-Host $subnet.Id  
    }  
    else {
        Write-Host -ForegroundColor Yellow "subnet $($item.Name) already exist on virtual network $virtualNetworkName"
        Write-Host  -ForegroundColor Magenta "using subnet $($item.Name) on virtual network $virtualNetworkName"
    }
}

#
# code creation de private endpoint
#

foreach ($serviceEndpointInfo in $serviceEndpoints) {
    $subnetName = $serviceEndpointInfo.SubnetName
    $subnet = $virtualNetwork.Subnets | Where-Object { $_.Name -eq $subnetName }

    if ($subnet) {
        # Check if Service Endpoints are already configured for the subnet
        if ($subnet.ServiceEndpoints.Count -eq 0) {
            # Add the Service Endpoint to the subnet
            $serviceEndpoint = $serviceEndpointInfo.ServiceEndpoint
           # Create a new PSServiceEndpoint object for Microsoft.Storage
            $serviceEndpoint = New-Object Microsoft.Azure.Commands.Network.Models.PSServiceEndpoint
            $serviceEndpoint.Service = "Microsoft.Storage"
            
            # Add the service endpoint to the subnet's ServiceEndpoints array
            $subnet.ServiceEndpoints = @()
            $subnet.ServiceEndpoints.Add($serviceEndpoint)

            Write-Host "Added Service Endpoint '$serviceEndpoint' to subnet '$subnetName'"
        } else {
            Write-Host "Service Endpoint(s) already exist on subnet '$subnetName'"
        }
    } else {
        Write-Host "Subnet '$subnetName' not found."
    }
}

#configure nsg


# Get the NSG
$nsg = Get-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Name $nsgName -ErrorVariable notPresent -ErrorAction SilentlyContinue
if ($notPresent)
{
    Write-Host -ForegroundColor Green "creating NetworkSecurityGroup $nsgName on resource group $resourceGroupName"
    $nsg =  New-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $resourceGroupName  -Location  $resourceGroupLocation
    Write-Host -ForegroundColor Green "NetworkSecurityGroup $nsgName successfully created on resource group $resourceGroupName"
}else {
    Write-Host -ForegroundColor Yellow "NetworkSecurityGroup $nsgName already exist "
    Write-Host  -ForegroundColor Magenta "using NetworkSecurityGroup $nsgName"
}


# Get the subnet
$backendSubnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $virtualNetwork -Name $backendSubnetName
# Associate the NSG with the subnet
$backendSubnet.NetworkSecurityGroup = $nsg

# Update the virtual network configuration
Set-AzVirtualNetwork -VirtualNetwork $virtualNetwork
