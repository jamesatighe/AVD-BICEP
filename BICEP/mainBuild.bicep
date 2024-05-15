//***********************************************************************************************************************
//Core Deployment Parameters
targetScope = 'subscription'
param AzTenantID string
param artifactsLocation string
param AVDResourceGroup string
param workspaceLocation string

//***********************************************************************************************************************
//Core Build Options Update, NewBuild
@description('If true Host Pool, App Group and Workspace will be created. Default is to join Session Hosts to existing AVD environment')
param newBuild bool = false
@description('Combined with newBuild to ensure core AVD resources are not deployed when updating')
param update bool = false

//***********************************************************************************************************************
//Options Azure AD Join, Intune, Ephemeral disks etc
@description('Boolean used to determine if Monitoring agent is needed')
param monitoringAgent bool = false
@description('Wheter to use emphemeral disks for VMs')
param ephemeral bool = true
@description('Declares whether Azure AD joined or not')
param AADJoin bool = false
@description('Determines if Session Hosts are auto enrolled in Intune')
param intune bool = false

//***********************************************************************************************************************
//Workspace
@description('Name of the AVD Workspace to used for this deployment')
param workspaceName string = 'ABRI-AVD-PROD'
@description('List of application group resource IDs to be added to Workspace. MUST add existing ones!')
param applicationGroupReferences string

//***********************************************************************************************************************
//Application Group Settings
@description('Application Group Friendly name. This shows in Remote Desktop client.')
param appGroupFriendlyName string
@description('Friendly name of Desktop Application Group. This is shown under Remote Desktop client.')
param desktopName string

//***********************************************************************************************************************
//Host Pool Settings
@description('Name for Host Pool.')
param hostPoolName string

@description('Friendly Name of the Host Pool, this is visible via the AVD client')
param hostPoolFriendlyName string

@description('Type used for Host Pool.')
@allowed([
  'Pooled'
  'Personal'
])
param hostPoolType string = 'Pooled'

@allowed([
  'Automatic'
  'Direct'
])
param personalDesktopAssignmentType string = 'Direct'

@description('Specify the maximum session limit for the Session Hosts.')
param maxSessionLimit int = 12

@allowed([
  'BreadthFirst'
  'DepthFirst'
  'Persistent'
])
param loadBalancerType string = 'BreadthFirst'

@description('Custom RDP properties to be applied to the AVD Host Pool.')
param customRdpProperty string

@description('Expiration time for the HostPool registration token. This is only used to configure the Host Pool. The VM deployment generates a token if required.')
param tokenExpirationTime string

@description('OU Path were new AVD Session Hosts will be placed in Active Directory')
param ouPath string

@description('Domain that AVD Session Hosts will be joined to.')
param domain string

//***********************************************************************************************************************
//Session Host VM Settings
@description('Administrator Login Password for Session Hosts.')
@secure()
param administratorAccountUserName string

@description('Administrator Login Password Domain Join operation.')
@secure()
param administratorAccountPassword string

@description('Local Administrator Login Username for Session Hosts.')
param localAdministratorAccountUserName string

@description('Local Administrator Login Password for Session Hosts.')
param localAdministratorAccountPassword string

@description('Resource Group to deploy Session Host VMs into.')
param vmResourceGroup string

@description('Azure Region to deploy VM Session Hosts into.')
param vmLocation string

@description('VM Size to be used for Session Host build. E.g. Standard_D2s_v3')
param vmSize string

@description('Number of Session Host VMs required.')
param numberOfInstances int = 2

@description('Current number of Session Host VMs. Populated automatically for upgrade build. Do not edit.')
param currentInstances int = 0

@description('Prefix to use for Session Host VM build. Build will add the version details to this. E.g. AVD-PROD-11-0-x X being machine number.')
param vmPrefix string = 'ABRI-AVD-PROD'

@description('Required storage type for Session Host VM OS disk.')
@allowed([
  'Standard_LRS'
  'Premium_LRS'
])
param vmDiskType string

@description('Resource Group containing the VNET to which to join Session Host VMs.')
param existingVNETResourceGroup string

@description('Name of the VNET that the Session Host VMs will be connected to.')
param existingVNETName string

@description('The name of the relevant VNET Subnet that is to be used for deployment.')
param existingSubnetName string

//***********************************************************************************************************************
//Shared Image Parameters
@description('Is Image Trusted Launch?')
param trustedLaunch bool

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

//***********************************************************************************************************************
//DSC Parameters
@description('Parameter to determine if user assignment is required. If true defaultUsers will be used.')
param assignUsers string

@description('CSV list of default users to assign to AVD Application Group.')
param defaultUsers string

@description('Application ID for Service Principal. Used for DSC scripts.')
param appID string

@description('Application Secret for Service Principal.')
@secure()
param appSecret string

//***********************************************************************************************************************
//Used for Monitoring Module
@description('Subscription that Log Analytics Workspace is located in.')
param logworkspaceSub string

@description('Resource Group that Log Analytics Workspace is located in.')
param logworkspaceResourceGroup string

@description('Name of Log Analytics Workspace for AVD to be joined to.')
param logworkspaceName string

@description('Log Analytics Workspace ID')
param workspaceID string

@description('Log Analytics Workspace Key')
param workspaceKey string

param tagParams object

//***********************************************************************************************************************
//Variables - All
var logAnalyticsResourceId = '/subscriptions/${logworkspaceSub}/resourceGroups/${logworkspaceResourceGroup}/providers/Microsoft.OperationalInsights/workspaces/${logworkspaceName}'

//***********************************************************************************************************************
//Modules - Resource Group, DCR, AVD Backplane, VMs
module resourceGroupDeploy './modules/resourceGroup.bicep' = {
  name: 'resourceGroup'
  params: {
    AVDResourceGroup: AVDResourceGroup
    AVDlocation: workspaceLocation
    vmResourceGroup: vmResourceGroup
    VMlocation: vmLocation
  }
}

module DCR './modules/DCR.bicep' = {
  name: 'DCR'
  scope: resourceGroup('AzureMonitor-DataCollectionRules')
  params: {
      location: workspaceLocation
      monitoringAgent: monitoringAgent
      logAnalyticsResourceId: logAnalyticsResourceId
      workspaceID: workspaceID
  }
  dependsOn: [
    resourceGroupDeploy
  ]
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
    update: update
  }
  dependsOn: [
    resourceGroupDeploy
  ]
}

module VMswithLA './modules/VMs.bicep' = {
  name: '${sharedImageGalleryVersionName}-VMs'
  scope: resourceGroup(vmResourceGroup)
  params: {
    AzTenantID: AzTenantID
    location: vmLocation
    administratorAccountUserName: administratorAccountUserName
    administratorAccountPassword: administratorAccountPassword
    localAdministratorAccountUserName: localAdministratorAccountUserName
    localAdministratorAccountPassword: localAdministratorAccountPassword
    artifactsLocation: artifactsLocation
    vmDiskType: vmDiskType
    vmPrefix: vmPrefix
    vmSize: vmSize
    currentInstances: currentInstances
    AVDnumberOfInstances: numberOfInstances
    existingVNETResourceGroup: existingVNETResourceGroup
    existingVNETName: existingVNETName
    existingSubnetName: existingSubnetName
    trustedLaunch: trustedLaunch
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
    assignUsers: assignUsers
    defaultUsers: defaultUsers
    desktopName: desktopName
    resourceGroupName: AVDResourceGroup
    DCRId: DCR.outputs.DCRId
    logAnalyticsResourceId: logAnalyticsResourceId
    workspaceID: workspaceID
    workspaceKey: workspaceKey
    tagParams: tagParams
    monitoringAgent: monitoringAgent
    ephemeral: ephemeral
    AADJoin: AADJoin
    intune: intune
  }
  dependsOn: [
    backPlane
  ]
}
