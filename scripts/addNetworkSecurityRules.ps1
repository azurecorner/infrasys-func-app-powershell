Param
(
    [Parameter(Mandatory=$true, HelpMessage = "Please provide a valid resource group")]
    [string]$resourceGroupName,
    [Parameter(Mandatory=$true, HelpMessage = "Please provide a valid nsgName")]
    [string]$nsgName,
    [Parameter(Mandatory=$true, HelpMessage = "Please provide a valid ruleName ")]
    [string]$ruleName,
    [Parameter(Mandatory=$true, HelpMessage = "Please provide a valid priority")]
    [string]$priority,
    [Parameter(Mandatory=$true, HelpMessage = "Please provide a valid destinationIP ")]
    [string]$destinationIP
 )

# Variables
# $resourceGroupName = "RG-SYSTEME-FRACE-001"
# $nsgName = "nsg-stcld002-qua-001"
# $ruleName = "DenyAnyCustomAnyInbound"
# $priority = 100
# $destinationIP = "10.20.32.4"

# Get the NSG
$nsg = Get-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Name $nsgName


$ruleToAdd = $nsg.SecurityRules | Where-Object { $_.Name -eq $ruleName }

if ($null -eq $ruleToAdd) {
# Create the rule
$rule = New-AzNetworkSecurityRuleConfig -Name $ruleName `
    -Description "Deny traffic from any source to $destinationIP" `
    -Access Deny `
    -Protocol * `
    -Direction Inbound `
    -Priority $priority `
    -SourceAddressPrefix * `
    -SourcePortRange * `
    -DestinationAddressPrefix $destinationIP `
    -DestinationPortRange * 
# Add the rule to the NSG
$nsg.SecurityRules.Add($rule)

# Update the NSG
$nsg | Set-AzNetworkSecurityGroup
}
