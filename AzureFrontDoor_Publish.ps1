#First of all, we have to install the Az.FrontDoor Module
if(-not (get-module az.FrontDoor -listAvailable)){
    Install-Module -Name Az.FrontDoor -Force
}
$vaultName = "keyvaultName"
$ResourceGroupName = "RGDEMO01"
$frontDoorName = "AFDDEMO01"
$FrontendEndpointName = "AFDDEMO01"
$backendpoolUIname = "UIBACKEND01"
$backendpoolAPIname = "APIBACKEND01"
$hostName = "$FrontendEndpointName.azurefd.net"

$routingRuleName1 = "UIHTTPSRule01"
$routingRuleName2 = "UIHTTPRule02"
$routingRuleName3 = "APIRule01"

$HealthProbeSettingName = "DemoHealthProbeSetting"
$VOCQALoadbalancingSetting = "DemoLoadBalancingSetting"

# This to create two backend objects using our App services
  
$backEnd1 = New-AzFrontDoorBackendObject -Address "AppServiceUIBACKEND01.azurewebsites.net"
$backEnd2 = New-AzFrontDoorBackendObject -Address "AppServiceAPIBACKEND01.azurewebsites.net"


#This to create a new Health Probe setting object
  
$WebHostsHealthProbeSetting = New-AzFrontDoorHealthProbeSettingObject -Name $HealthProbeSettingName
 
#This to create a Load Balancing Setting object
  
$WebHostsLoadbalancingSetting = New-AzFrontDoorLoadBalancingSettingObject -Name $VOCQALoadbalancingSetting
  
#This to create a new Front Door frontend object
  
$CloudshellfrontendEndpointObject = New-AzFrontDoorFrontendEndpointObject -Name $FrontendEndpointName  -HostName $hostName
  
#This to create an Azure Front Door backend pool object, where two backend pools are required
  
$BackendPool1 = New-AzFrontDoorBackendPoolObject -Name $backendpoolUIname `
    -FrontDoorName $frontDoorName `
    -ResourceGroupName $ResourceGroupName `
    -Backend $backEnd1 `
    -HealthProbeSettingsName $HealthProbeSettingName `
    -LoadBalancingSettingsName VOCQALoadbalancingSetting

 $BackendPool2 = New-AzFrontDoorBackendPoolObject -Name $backendpoolAPIname `
    -FrontDoorName $frontDoorName `
    -ResourceGroupName $ResourceGroupName `
    -Backend $backEnd2 `
    -HealthProbeSettingsName $HealthProbeSettingName `
    -LoadBalancingSettingsName VOCQALoadbalancingSetting
     
    $backendpools = @($BackendPool1, $BackendPool2)  

    
# This to create an Azure Front Door routing object
  
$RoutingRule1 = New-AzFrontDoorRoutingRuleObject -Name $routingRuleName1 -FrontDoorName $frontDoorName -ResourceGroupName $ResourceGroupName -FrontendEndpointName $FrontendEndpointName  `
    -BackendPoolName $backendpoolUIname -PatternToMatch "/*" -AcceptedProtocol "https"  -ForwardingProtocol "HttpsOnly" -EnableCaching $false

      
 $RoutingRule2 = New-AzFrontDoorRoutingRuleObject -Name $routingRuleName3  -FrontDoorName $frontDoorName  -ResourceGroupName $ResourceGroupName  -FrontendEndpointName $FrontendEndpointName `
   -BackendPoolName $backendpoolUIname -PatternToMatch "/*"  -AcceptedProtocol "http" -ForwardingProtocol "HttpsOnly"  -EnableCaching $false 

   
 $RoutingRule3 = New-AzFrontDoorRoutingRuleObject -Name $routingRuleName2  -FrontDoorName $frontDoorName  -ResourceGroupName $ResourceGroupName  -FrontendEndpointName $FrontendEndpointName  -BackendPoolName $backendpoolAPIname `
    -PatternToMatch "/api/*"  -AcceptedProtocol "https" -ForwardingProtocol "HttpsOnly"  -EnableCaching $false

    $RoutingRules =@($RoutingRule1,$RoutingRule2,$RoutingRule3)
  
# Finally this for Creating a new Azure Front Door
  
$AzureFrontDoor = New-AzFrontDoor -Name $frontDoorName -ResourceGroupName $ResourceGroupName `
    -RoutingRule $RoutingRules `
    -BackendPool $BackendPools `
    -FrontendEndpoint $CloudshellfrontendEndpointObject  -LoadBalancingSetting $WebHostsLoadbalancingSetting  -HealthProbeSetting $WebHostsHealthProbeSetting

### CustomDomain Https
$vaultId = (Get-AzKeyVault -VaultName $vaultName).ResourceId
Enable-AzFrontDoorCustomDomainHttps -ResourceGroupName "RGDEMO01" -FrontDoorName "AFDDEMO01" -FrontendEndpointName "<Type-custom-Domain>" -Vault $vaultId -secretName $secretName -SecretVersion $secretVersion -MinimumTlsVersion "1.2"
# In case Frondoor managed certificate require
#Get-AzFrontDoorFrontendEndpoint -ResourceGroupName "resourcegroup1" -FrontDoorName "frontdoor1" -Name "frontendpointname1-custom-xyz" | Enable-AzFrontDoorCustomDomainHttps 
### CustomDomain Https END