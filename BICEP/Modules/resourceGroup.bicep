//***********************************************************************************************************************
//Parameters
param VMlocation string
param AVDlocation string

targetScope = 'subscription'

param AVDResourceGroup string
param vmResourceGroup string

//***********************************************************************************************************************
//Resources - Resource Groups (AVD Core, AVD VMs, DCR Rules)
resource vmResourceGroup_resource 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: vmResourceGroup
  location: VMlocation
}

resource AVDResourceGroup_resource 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: AVDResourceGroup
  location: AVDlocation
}

resource AVD_DCR_resource 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: 'AzureMonitor-DataCollectionRules'
  location: AVDlocation
}

//***********************************************************************************************************************
//Output - All
output DCRRGId string = AVD_DCR_resource.id