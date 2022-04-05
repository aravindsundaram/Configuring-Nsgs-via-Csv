param nsgs array

resource nsgrules 'Microsoft.Network/networkSecurityGroups@2021-05-01' = [for nsg in nsgs: {
  name: nsg.nsgName
  location: resourceGroup().location
  properties: {
     securityRules: nsg.rules
  }
}]
