param nsgs array

resource nsgrules 'Microsoft.Network/networkSecurityGroups@2021-05-01' = [for nsg in nsgnames: {
  name: nsg.nsgName
  location: resourceGroup().location
  properties: {
     securityRules: nsg.rules
  }
}]
