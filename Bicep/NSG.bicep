param nsgnames array

param location string 

resource nsgs 'Microsoft.Network/networkSecurityGroups@2021-05-01' = [for nsg in nsgnames: {
  name: nsg.nsgName
  location: location
  properties: {
     securityRules: nsg.rules
  }
}]
