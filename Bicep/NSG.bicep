param nsgnames array
param nsgrules array

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-05-01' = [for nsgname in nsgnames: {
  name: nsgname
  location: resourceGroup().location
  properties: {
    securityRules: nsgrules
  }
}]

output nsgIds array = [for (nsgname, index) in nsgnames: {
  name: nsg[index].name
  resourceId: nsg[index].id
}]
