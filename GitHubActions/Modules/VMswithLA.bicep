param artifactsLocation string

@secure()
param AzTenantID string
param AVDnumberOfInstances int
param currentInstances int

@description('Location for all standard resources to be deployed into.')
param location string
param hostPoolName string
param domainToJoin string
@description('Name of resource group containing AVD HostPool')
param resourceGroupName string

@description('OU Path were new AVD Session Hosts will be placed in Active Directory')
param ouPath string
param appGroupName string
param desktopName string

@description('Application ID for Service Principal. Used for DSC scripts.')
param appID string

@description('Application Secret for Service Principal.')
param appSecret string

@description('CSV list of default users to assign to AVD Application Group.')
param defaultUsers string
param vmPrefix string

@allowed([
  'Standard_LRS'
  'Premium_LRS'
])
param vmDiskType string
param vmSize string
param administratorAccountUserName string
param administratorAccountPassword string
param existingVNETResourceGroup string
param existingVNETName string
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

param tagParams object

param monitoringAgent bool

param ephemeral bool

param AADJoin bool

param intune bool

var subnetID = resourceId(existingVNETResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', existingVNETName, existingSubnetName)
var avSetSKU = 'Aligned'
var existingDomainUserName = first(split(administratorAccountUserName, '@'))
var networkAdapterPostfix = '-nic'

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
      adminUsername: existingDomainUserName
      adminPassword: administratorAccountPassword
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
  tags: tagParams
  dependsOn: [
    availabilitySet
    nic[i]
  ]
}]

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
