//***********************************************************************************************************************
//Parameters - Options Azure AD Join, Intune, Ephemeral disks etc
@description('Boolean used to determine if Monitoring agent is needed')
param monitoringAgent bool = false
@description('Wheter to use emphemeral disks for VMs')
param ephemeral bool = true
@description('Declares whether Azure AD joined or not')
param AADJoin bool = false
@description('Determines if Session Hosts are auto enrolled in Intune')
param intune bool = false

//***********************************************************************************************************************
//Parameters - Host Pool Settings
@description('Name for Host Pool.')
param hostPoolName string

@description('Domain that AVD Session Hosts will be joined to.')
param domainToJoin string

@description('Name of resource group containing AVD HostPool.')
param resourceGroupName string

@description('OU Path were new AVD Session Hosts will be placed in Active Directory')
param ouPath string

@description('Friendly name of Desktop Application Group. This is shown under Remote Desktop client.')
param desktopName string


//***********************************************************************************************************************
//Parameters - DSC Parameters
@description('Artifact location for DSC scripts.')
param artifactsLocation string

@description('Azure Tenant ID. Used for DSC scripts.')
@secure()
param AzTenantID string

@description('Name of the Application Group for DSC script.')
param appGroupName string

@description('Application ID for Service Principal. Used for DSC scripts.')
param appID string

@description('Application Secret for Service Principal.')
@secure()
param appSecret string

@description('Parameter to determine if user assignment is required. If true defaultUsers will be used.')
param assignUsers string

@description('CSV list of default users to assign to AVD Application Group.')
param defaultUsers string

//***********************************************************************************************************************
//Parameters - Session Host VM Settings
@description('Azure Region to deploy VM Session Hosts into.')
param location string

@description('Prefix to use for Session Host VM build. Build will add the version details to this. E.g. AVD-PROD-11-0-x X being machine number.')
param vmPrefix string

@description('Required storage type for Session Host VM OS disk.')
@allowed([
  'Standard_LRS'
  'Premium_LRS'
])
param vmDiskType string

@description('VM Size to be used for Session Host build. E.g. Standard_D2s_v3')
param vmSize string

@description('Administrator Login Username Domain Join operation.')
param administratorAccountUserName string

@description('Administrator Login Password Domain Join operation.')
@secure()
param administratorAccountPassword string

@description('Local Administrator Login Username for Session Hosts.')
param localAdministratorAccountUserName string

@description('Administrator Login Password for Session Hosts.')
@secure()
param localAdministratorAccountPassword string

@description('Number of Session Host VMs required.')
param AVDnumberOfInstances int

@description('Current number of Session Host VMs. Populated automatically for upgrade build. Do not edit.')
param currentInstances int

@description('Resource Group containing the VNET to which to join Session Host VMs.')
param existingVNETResourceGroup string

@description('Name of the VNET that the Session Host VMs will be connected to.')
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

@description('Log Analytics Workspace ID')
param workspaceID string

@description('Log Analytics Workspace Key')
param workspaceKey string

//***********************************************************************************************************************
//Variables - All
var subnetID = resourceId(existingVNETResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', existingVNETName, existingSubnetName)
var avSetSKU = 'Aligned'
var localAdminUser = first(split(localAdministratorAccountUserName, '@'))
var networkAdapterPostfix = '-nic'


//***********************************************************************************************************************
//Resources - NICs
resource nic 'Microsoft.Network/networkInterfaces@2021-05-01' = [for i in range(0, AVDnumberOfInstances): {
  name: '${vmPrefix}-${i + currentInstances}${networkAdapterPostfix}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetID
          }
        }
      }
    ]
  }
}]

//***********************************************************************************************************************
//Resources - Availability Set
resource availabilitySet 'Microsoft.Compute/availabilitySets@2021-11-01' = {
  name: '${vmPrefix}-AV'
  location: location
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 10
  }
  sku: {
    name: avSetSKU
  }
}

//***********************************************************************************************************************
//Resources - VMs
resource vm 'Microsoft.Compute/virtualMachines@2021-11-01' = [for i in range(0, AVDnumberOfInstances): {
  name: '${vmPrefix}-${i + currentInstances}'
  location: location
  identity: AADJoin ? {
    type: 'SystemAssigned'
  } : null
  properties: {
    licenseType: 'Windows_Client'
    hardwareProfile: {
      vmSize: vmSize
    }
    availabilitySet: {
      id: resourceId('Microsoft.Compute/availabilitySets', '${vmPrefix}-AV')
    }
    osProfile: {
      computerName: '${vmPrefix}-${i + currentInstances}'
      adminUsername: localAdminUser
      adminPassword: localAdministratorAccountPassword
      windowsConfiguration: {
        enableAutomaticUpdates: false
        patchSettings: {
          patchMode: 'Manual'
        }
      }
    }
    storageProfile: {
      osDisk: {
        name: '${vmPrefix}-${i + currentInstances}-OS'
        managedDisk: {
          storageAccountType: ephemeral ? 'Standard_LRS' : vmDiskType
        }
        osType: 'Windows'
        createOption: 'FromImage'
        caching: 'ReadOnly'
        diffDiskSettings: ephemeral ? {
          option: 'Local'
          placement: 'CacheDisk'
        } : null
      }

      imageReference: {
        //id: resourceId(sharedImageGalleryResourceGroup, 'Microsoft.Compute/galleries/images/versions', sharedImageGalleryName, sharedImageGalleryDefinitionname, sharedImageGalleryVersionName)
        id: '/subscriptions/${sharedImageGallerySubscription}/resourceGroups/${sharedImageGalleryResourceGroup}/providers/Microsoft.Compute/galleries/${sharedImageGalleryName}/images/${sharedImageGalleryDefinitionname}/versions/${sharedImageGalleryVersionName}'
      }
      dataDisks: []
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${vmPrefix}-${i + currentInstances}${networkAdapterPostfix}')
        }
      ]
    }
  }
  tags: {
    Version: sharedImageGalleryVersionName
  }
  dependsOn: [
    availabilitySet
    nic[i]
  ]
}]

//***********************************************************************************************************************
//Resources - Custom Script Extension - Language Fix
resource languagefix 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = [for i in range(0, AVDnumberOfInstances): {
  name: '${vmPrefix}-${i + currentInstances}/languagefix'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        '${artifactsLocation}languagescript.ps1'
        '${artifactsLocation}UKRegion.xml'
      ]
    }
    protectedSettings: {
      commandToExecute: 'powershell.exe -ExecutionPolicy Bypass -File languagescript.ps1'
    }
  }
  dependsOn: [
    vm[i]
  ]
}]

//***********************************************************************************************************************
//Resources - Domain Join Extension
resource joindomain 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = [for i in range(0, AVDnumberOfInstances): {
  name: '${vmPrefix}-${i + currentInstances}/joindomain'
  location: location
  properties: AADJoin ? {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADLoginForWindows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: intune ? {
      mdmId: '0000000a-0000-0000-c000-000000000000'
    } : null
  } : {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      name: domainToJoin
      ouPath: ouPath
      user: administratorAccountUserName
      restart: 'true'
      options: '3'
      NumberOfRetries: '4'
      RetryIntervalInMilliseconds: '30000'
    }
    protectedSettings: {
      password: administratorAccountPassword
    }
  }
  dependsOn: [
    vm[i]
    languagefix[i]
  ]
}]

//***********************************************************************************************************************
//Resources - DSC Extension
resource dscextension 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = [for i in range(0, AVDnumberOfInstances): {
  name: '${vmPrefix}-${i + currentInstances}/dscextension'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.73'
    autoUpgradeMinorVersion: true
    settings: {
      modulesUrl: '${artifactsLocation}Configuration.zip'
      configurationFunction: 'Configuration.ps1\\AddSessionHost'
      properties: {
        HostPoolName: hostPoolName
        ResourceGroup: resourceGroupName
        ApplicationGroupName: appGroupName
        DesktopName: desktopName
        AzTenantID: AzTenantID
        AppID: appID
        AppSecret: appSecret
        AssignUsers: assignUsers
        DefaultUsers: defaultUsers
        vmPrefix: vmPrefix
      }
    }
  }
  dependsOn: [
    vm[i]
    joindomain[i]
  ]
}]

//***********************************************************************************************************************
//Resources - Log Analytics Extension
resource loganalytics 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = [for i in range(0, AVDnumberOfInstances): if (monitoringAgent == true) {
  name: '${vmPrefix}-${i + currentInstances}/loganalytics'
  location: location
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: 'MicrosoftMonitoringAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      workspaceID: workspaceID
    }
    protectedSettings: {
      workspaceKey: workspaceKey
    }
  }
  dependsOn: [
    vm[i]
    dscextension[i]
  ]
}]
