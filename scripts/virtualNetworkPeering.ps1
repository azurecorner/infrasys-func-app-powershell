$hubVirtualNetworkName="vnet-infrasys-hub-shared-frace-nonprod"
$hubResourceGroupName="rg-infrasys-shared-nonprod"

$spokeVirtualNetworkName="VNET-SYSTEME-FRACE-001"
$spokeResourceGroupName="RG-SYSTEME-FRACE-001-SANDBOX"

$hubVirtualNetwork =  Get-AzVirtualNetwork -Name $hubVirtualNetworkName -ResourceGroupName $hubResourceGroupName 

$spokeVirtualNetwork =  Get-AzVirtualNetwork -Name $spokeVirtualNetworkName -ResourceGroupName $spokeResourceGroupName 

Add-AzVirtualNetworkPeering `
  -Name myVirtualNetwork1-myVirtualNetwork2 `
  -VirtualNetwork $hubVirtualNetwork `
  -RemoteVirtualNetworkId $spokeVirtualNetwork.Id


  Add-AzVirtualNetworkPeering `
  -Name myVirtualNetwork2-myVirtualNetwork1 `
  -VirtualNetwork $spokeVirtualNetwork `
  -RemoteVirtualNetworkId $hubVirtualNetwork.Id


