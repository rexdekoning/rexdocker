Login-AzureRmAccount
Get-AzureRmSubscription

Get-AzureRmResourceGroup | fl *

$ResourceGroups = Get-AzureRmResourceGroup

$ResourceGroups | ForEach-Object {
    $_.ResourceGroupName
    $_.ResourceId
    $_.Location
}

$ResourcesInGroup = Get-AzureRmResource | Where-Object {$_.ResourceGroupName -eq 'rsgrdkcont'}

$ResourcesInGroup | ForEach-Object {
    $_.ResourceName + '::' + $_.Kind + '::' +  $_.ResourceType
}

Get-AzureRmResource -ResourceName 'rsgrdkcont-vnet'
Get-AzureRmResource | Where-Object {$_.ResourceName -eq 'rsgrdkcont-vnet'} | FL *

Get-AzureRmNetworkSecurityGroup

function Get-VMStatus($ResourceGroupName, $VMName)
{
            $VMDetail = Get-AzureRmVM -ResourceGroupName $RG.ResourceGroupName -Name $VM.Name -Status
        foreach ($VMStatus in $VMDetail.Statuses)
        { 
             if($VMStatus.Code -like "PowerState/*")
            {
                $VMStatusDetail = $VMStatus.DisplayStatus
            }
        }
        $strReturn = $VMStatusDetail
        return $strReturn
}

Start-VM -Name rdkcont01
Start-AzureRmVM -ResourceGroupName rsgrdkcont -Name rdkcont01
Stop-AzureRmVM -ResourceGroupName rsgrdkcont -Name rdkcont01 -Force

Get-VMStatus 'rsgrdkcont', 'rdkcont01'

$NetworkSecurityGroups = Get-AzureRmNetworkSecurityGroup -ResourceGroupName rsgrdkcont
$NetworkSecurityGroups
$temp = Get-AzureRmNetworkSecurityGroup -ResourceGroupName rsgrdkcont -Name rdkcont01-nsg
Get-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $temp


#add configrule
Get-AzureRmNetworkSecurityGroup -Name rdkcont01-nsg -ResourceGroupName rsgrdkcont | Add-AzureRmNetworkSecurityRuleConfig -Name "Testrex" -Direction Inbound -Priority 100 -Access Allow -SourceAddressPrefix '91.34.92.221/32'  -SourcePortRange '*' -DestinationAddressPrefix '*' -DestinationPortRange '*' -Protocol 'TCP' | Set-AzureRmNetworkSecurityGroup
#modify configrule
Get-AzureRMNetworkSecurityGroup -Name rdkcont01-nsg -ResourceGroupName rsgrdkcont | Set-AzureRmNetworkSecurityRuleConfig -Name "Testrex" -Direction Inbound -Priority 100 -Access Allow -SourceAddressPrefix '91.34.92.221/32'  -SourcePortRange '*' -DestinationAddressPrefix '*' -DestinationPortRange '3389' -Protocol 'TCP' | Set-AzureRmNetworkSecurityGroup
#del config rule
Get-AzureRmNetworkSecurityGroup -Name rdkcont01-nsg -ResourceGroupName rsgrdkcont | Remove-AzureRmNetworkSecurityRuleConfig -Name "Testrex" | Set-AzureRmNetworkSecurityGroup


 