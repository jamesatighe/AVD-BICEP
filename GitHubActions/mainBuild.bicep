targetScope = 'subscription'
param AzTenantID string
param artifactsLocation string
param AVDResourceGroup string
param workspaceLocation string

@description('Boolean used to determine if Monitoring agent is needed')
param monitoringAgent bool = false

@description('Wheter to use emphemeral disks for VMs')
param ephemeral bool = true

@description('Declares whether Azure AD joined or not')
param AADJoin bool = false

@description('Determines if Session Hosts are auto enrolled in Intune')
param intune bool = false

@description('Expiration time for the HostPool registration token. This must be up to 30 days from todays date.')
param tokenExpirationTime string

@description('OU Path were new AVD Session Hosts will be placed in Active Directory')
param ouPath string

@description('Domain that AVD Session Hosts will be joined to.')
param domain string

@description('If true Host Pool, App Group and Workspace will be created. Default is to join Session Hosts to existing AVD environment')
param newBuild bool = false
param administratorAccountUserName string

@secure()
param administratorAccountPassword string

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

@description('List of application group resource IDs to be added to Workspace. MUST add existing ones!')
param applicationGroupReferences string
param desktopName string

@description('CSV list of default users to assign to AVD Application Group.')
param defaultUsers string

@description('Application ID for Service Principal. Used for DSC scripts.')
param appID string

@description('Application Secret for Service Principal.')
param appSecret string
param vmResourceGroup string
param vmLocation string
param vmSize string
param numberOfInstances int = 2
param currentInstances int = 0
param vmPrefix string = 'ABRI-AVD-PROD'

@allowed([
  'Standard_LRS'
  'Premium_LRS'
])
param vmDiskType string
param existingVNETResourceGroup string

@description('Name of the VNET that the AVD Session Hosts will be connected to.')
param existingVNETName string

@description('The name of the relevant VNET Subnet that is to be used for deployment.')
param existingSubnetName string

@description('Subscription containing the Shared Image Gallery')
param sharedImageGallerySubscription string

@description('Resource Group containing the Shared Image Gallery.')
param sharedImageGalleryResourceGroup string

@description('Name of the existing Shared Image Gallery to be used for image.')
param sharedImageGalleryName string

@description('Name of the Shared Image Gallery Definition being used for deployment. I.e: AVDGolden')
param sharedImageGalleryDefinitionname string

@description('Version name for image to be deployed as. I.e: 1.0.0')
param sharedImageGalleryVersionName string

//Used for Monitoring Module
@description('Subscription that Log Analytics Workspace is located in.')
param logworkspaceSub string
@description('Resource Group that Log Analytics Workspace is located in.')
param logworkspaceResourceGroup string
@description('Name of Log Analytics Workspace for AVD to be joined to.')
param logworkspaceName string

//Used in VMswitLA module
@description('Log Analytics Workspace ID')
param workspaceID string
@description('Log Analytics Workspace Key')
param workspaceKey string

module resourceGroupDeploy './modules/resourceGroup.bicep' = {
  name: 'backPlane'
  params: {
    AVDResourceGroup: AVDResourceGroup
    AVDlocation: workspaceLocation
    vmResourceGroup: vmResourceGroup
    VMlocation: vmLocation
  }
}

module backPlane './modules/backPlane.bicep' = {
  name: 'backPlane'
  scope: resourceGroup(AVDResourceGroup)
  params: {
    location: workspaceLocation
    workspaceLocation: workspaceLocation
    logworkspaceSub: logworkspaceSub
    logworkspaceResourceGroup: logworkspaceResourceGroup
    logworkspaceName: logworkspaceName
    hostPoolName: hostPoolName
    hostPoolFriendlyName: hostPoolFriendlyName
    hostPoolType: hostPoolType
    appGroupFriendlyName: appGroupFriendlyName
    applicationGroupReferences: applicationGroupReferences
    loadBalancerType: loadBalancerType
    workspaceName: workspaceName
    personalDesktopAssignmentType: personalDesktopAssignmentType
    customRdpProperty: customRdpProperty
    tokenExpirationTime: tokenExpirationTime
    maxSessionLimit: maxSessionLimit
    newBuild: newBuild
  }
  dependsOn: [
    resourceGroupDeploy
  ]
}

module VMswithLA './modules/VMswithLA.bicep' = {
  name: '${sharedImageGalleryVersionName}-VMswithLA'
  scope: resourceGroup(vmResourceGroup)
  params: {
    AzTenantID: AzTenantID
    location: vmLocation
    administratorAccountUserName: administratorAccountUserName
    administratorAccountPassword: administratorAccountPassword
    artifactsLocation: artifactsLocation
    vmDiskType: vmDiskType
    vmPrefix: vmPrefix
    vmSize: vmSize
    currentInstances: currentInstances
    AVDnumberOfInstances: numberOfInstances
    existingVNETResourceGroup: existingVNETResourceGroup
    existingVNETName: existingVNETName
    existingSubnetName: existingSubnetName
    sharedImageGallerySubscription: sharedImageGallerySubscription
    sharedImageGalleryResourceGroup: sharedImageGalleryResourceGroup
    sharedImageGalleryName: sharedImageGalleryName
    sharedImageGalleryDefinitionname: sharedImageGalleryDefinitionname
    sharedImageGalleryVersionName: sharedImageGalleryVersionName
    hostPoolName: hostPoolName
    domainToJoin: domain
    ouPath: ouPath
    appGroupName: reference(extensionResourceId('/subscriptions/${subscription().subscriptionId}/resourceGroups/${AVDResourceGroup}', 'Microsoft.Resources/deployments', 'backPlane'), '2019-10-01').outputs.appGroupName.value
    appID: appID
    appSecret: appSecret
    defaultUsers: defaultUsers
    desktopName: desktopName
    resourceGroupName: AVDResourceGroup
    workspaceID: workspaceID
    workspaceKey: workspaceKey
    monitoringAgent: monitoringAgent
    ephemeral: ephemeral
    AADJoin: AADJoin
    intune: intune
  }
  dependsOn: [
    backPlane
  ]
}
