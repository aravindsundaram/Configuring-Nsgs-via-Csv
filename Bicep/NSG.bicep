param nsgs array

param location string = resourceGroup().location

resource nsgrules 'Microsoft.Network/networkSecurityGroups@2021-05-01' = [for nsg in nsgs: {
  name: nsg.nsgName
  location: location
  properties: {
     securityRules: nsg.rules
  }
}]
