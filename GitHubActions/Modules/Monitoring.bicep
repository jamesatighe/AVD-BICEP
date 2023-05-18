param logworkspaceSub string
param logworkspaceResourceGroup string
param logworkspaceName string

param hostpoolName string
param workspaceName string
param appgroupName string

var logworkspaceId = '/subscriptions/${logworkspaceSub}/resourcegroups/${logworkspaceResourceGroup}/providers/microsoft.operationalinsights/workspaces/${logworkspaceName} '

resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2021-07-12' existing = {
  name: hostpoolName
}

resource appGroup 'Microsoft.DesktopVirtualization/applicationGroups@2021-07-12' existing = {
  name: appgroupName
}

resource workspace 'Microsoft.DesktopVirtualization/workspaces@2021-07-12' existing = {
  name: workspaceName
}

resource hostpoolDiagName 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'hostpool-diag'
  scope: hostPool
  properties: {
    workspaceId: logworkspaceId
    logs: [
      {
        category: 'Checkpoint'
        enabled: true
      }
      {
        category: 'Error'
        enabled: true
      }
      {
        category: 'Management'
        enabled: true
      }
      {
        category: 'Connection'
        enabled: true
      }
      {
        category: 'HostRegistration'
        enabled: true
      }
      {
        category: 'AgentHealthStatus'
        enabled: true
      }
      {
        category: 'NetworkData'
        enabled: true
      }
      {
        category: 'SessionHostManagement'
        enabled: true
      }
    ]
  }
}

resource workspaceDiagName 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'workspacepool-diag'
  scope: workspace
  properties: {
    workspaceId: logworkspaceId
    logs: [
      {
        category: 'Checkpoint'
        enabled: true
      }
      {
        category: 'Error'
        enabled: true
      }
      {
        category: 'Management'
        enabled: true
      }
      {
        category: 'Feed'
        enabled: true
      }
    ]
  }
}

resource appGroupDiagName 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'appgroup-diag'
  scope: appGroup
  properties: {
    workspaceId: logworkspaceId
    logs: [
      {
        category: 'Checkpoint'
        enabled: true
      }
      {
        category: 'Error'
        enabled: true
      }
      {
        category: 'Management'
        enabled: true
      }
    ]
  }
}
