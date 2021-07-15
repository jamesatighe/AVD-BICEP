targetScope = 'subscription'

param AVDResourceGroup string
param vmResourceGroup string

resource vmResourceGroup_resource 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: vmResourceGroup
  location: 'uksouth'
}

resource AVDResourceGroup_resource 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: AVDResourceGroup
  location: 'uksouth'
}
