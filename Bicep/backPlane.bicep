param location string

@allowed([
  'eastus'
  'westus'
  'westeurope'
  'northeurope'
  'uksouth'
])
param workspaceLocation string

@description('If true Host Pool, App Group and Workspace will be created. Default is to join Session Hosts to existing AVD environment')
param newBuild bool = false

@description('Expiration time for the HostPool registration token. This must be up to 30 days from todays date.')
param tokenExpirationTime string

@allowed([
  'Personal'
  'Pooled'
])
param hostPoolType string = 'Pooled'
param hostPoolName string

@allowed([
  'Automatic'
  'Direct'
])
param personalDesktopAssignmentType string = 'Direct'
param maxSessionLimit int = 12

@allowed([
  'BreadthFirst'
  'DepthFirst'
  'Persistent'
])
param loadBalancerType string = 'BreadthFirst'

@description('Custom RDP properties to be applied to the AVD Host Pool.')
param customRdpProperty string

@description('Friendly Name of the Host Pool, this is visible via the AVD client')
param hostPoolFriendlyName string

@description('Name of the AVD Workspace to used for this deployment')
param workspaceName string = 'ABRI-AVD-PROD'
param appGroupFriendlyName string

// @description('Log Analytics workspace ID to join AVD to.')
// param logworkspaceID string
param logworkspaceSub string
param logworkspaceResourceGroup string
param logworkspaceName string

@description('List of application group resource IDs to be added to Workspace. MUST add existing ones!')
param applicationGroupReferences string

var appGroupName = '${hostPoolName}-DAG'
var appGroupResourceID = array(resourceId('Microsoft.DesktopVirtualization/applicationgroups/', appGroupName))
var applicationGroupReferencesArr = applicationGroupReferences == '' ? appGroupResourceID : concat(split(applicationGroupReferences, ','), appGroupResourceID)

resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2019-12-10-preview' = if (newBuild) {
  name: hostPoolName
  location: location
  properties: {
    friendlyName: hostPoolFriendlyName
    hostPoolType: hostPoolType
    loadBalancerType: loadBalancerType
    customRdpProperty: customRdpProperty
    preferredAppGroupType: 'Desktop'
    personalDesktopAssignmentType: personalDesktopAssignmentType
    maxSessionLimit: maxSessionLimit
    validationEnvironment: false
    registrationInfo: {
      expirationTime: tokenExpirationTime
      token: null
      registrationTokenOperation: 'Update'
    }
  }
}

resource applicationGroup 'Microsoft.DesktopVirtualization/applicationGroups@2019-12-10-preview' = if (newBuild) {
  name: appGroupName
  location: location
  properties: {
    friendlyName: appGroupFriendlyName
    applicationGroupType: 'Desktop'
    description: 'Deskop Application Group created through Abri Deploy process.'
    hostPoolArmPath: resourceId('Microsoft.DesktopVirtualization/hostpools', hostPoolName)
  }
  dependsOn: [
    hostPool
  ]
}

resource workspace 'Microsoft.DesktopVirtualization/workspaces@2019-12-10-preview' = if (newBuild) {
  name: workspaceName
  location: workspaceLocation
  properties: {
    applicationGroupReferences: applicationGroupReferencesArr
  }
  dependsOn: [
    applicationGroup
  ]
}

module Monitoring './Monitoring.bicep' = {
  name: 'Monitoring'
  params: {
    location: location
    hostpoolName: hostPoolName
    workspaceName: workspaceName
    logworkspaceSub: logworkspaceSub
    logworkspaceResourceGroup: logworkspaceResourceGroup
    logworkspaceName: logworkspaceName
  }
  dependsOn: [
    workspace
    hostPool
  ]
}

output appGroupName string = appGroupName
