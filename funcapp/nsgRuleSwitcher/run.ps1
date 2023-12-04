using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."
Get-AzContext
Set-AzContext -Subscription "62e77dde-5e29-4436-9ae2-515019b815a8"
Get-AzContext
# Interact with query parameters or the body of the request.

$accessRule ="Deny"
if( $Request.Query.Access -eq 'allow') {
$accessRule = "Allow"
}

Write-Host -ForegroundColor Green " *************** Applying access rule $($accessRule) ****************"

# Variables
$resourceGroupName = "RG-SYSTEME-FRACE-001-SANDBOX"
$nsgName = "nsg-stcld002-prod-001"
$ruleName = "DenyAnyCustomAnyInbound"  

# Get the NSG
$nsg = Get-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Name $nsgName


$ruleToModify = $nsg.SecurityRules | Where-Object { $_.Name -eq $ruleName }

if ($null -ne $ruleToModify) {
    $ruleToModify.Access = $accessRule 
    
    # Update the NSG
    Set-AzNetworkSecurityGroup -NetworkSecurityGroup $nsg
    Write-Host "Rule '$ruleName' action changed to $accessRule."
} else {
    Write-Host "Rule '$ruleName' not found in the NSG."
}

if ($accessRule) {
    $body = "This HTTP triggered function executed successfully with nsg accessrule = $accessRule  "
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
})
