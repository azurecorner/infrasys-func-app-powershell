$hubVirtualNetworkName="vnet-infrasys-hub-shared-frace-nonprod"
$hubResourceGroupName="rg-infrasys-shared-nonprod"
$spokeVirtualNetworkName="VNET-SYSTEME-FRACE-001"
$spokeResourceGroupName="RG-SYSTEME-FRACE-001-SANDBOX"

$hubVirtualNetwork =  Get-AzVirtualNetwork -Name $hubVirtualNetworkName -ResourceGroupName $hubResourceGroupName 
$spokeVirtualNetwork =  Get-AzVirtualNetwork -Name $spokeVirtualNetworkName -ResourceGroupName $spokeResourceGroupName 

$peering = Get-AzVirtualNetworkPeering -Name "hub-to-spoke" -VirtualNetworkName $hubVirtualNetwork -ResourceGroupName $hubResourceGroupName -ErrorAction SilentlyContinue

Write-Host "peering hub  = $peering"

if($null -eq $peering ) {
    Write-Host -ForegroundColor Green "creating virtual network peering hub-to-spoke $($hubVirtualNetwork.Name) and $($spokeVirtualNetwork.Name) "
    $hubPeeringParams = @{
        'Name' = 'hub-to-spoke'
        'VirtualNetwork' = $hubVirtualNetwork
        'RemoteVirtualNetworkId' = $spokeVirtualNetwork.Id
    }
    Add-AzVirtualNetworkPeering @hubPeeringParams
} else {
    Write-Host -ForegroundColor Yellow "virtual network peering hub-to-spoke already exists"
}

$peering = Get-AzVirtualNetworkPeering -Name "spoke-to-hub" -VirtualNetworkName $spokeVirtualNetwork -ResourceGroupName $spokeResourceGroupName -ErrorAction SilentlyContinue

Write-Host "peering spoke  = $peering"

if($null -eq $peering ) {
    Write-Host -ForegroundColor Green "creating virtual network peering spoke-to-hub $($spokeVirtualNetwork.Name) and $($hubVirtualNetwork.Name) "
    $spokePeeringParams = @{
        'Name' = 'spoke-to-hub'
        'VirtualNetwork' = $spokeVirtualNetwork
        'RemoteVirtualNetworkId' = $hubVirtualNetwork.Id
    }
    Add-AzVirtualNetworkPeering @spokePeeringParams
} else {
    Write-Host -ForegroundColor Yellow "virtual network peering spoke-to-hub already exists"
}
