param logworkspaceSub string
param logworkspaceResourceGroup string
param logworkspaceName string

param location string
param hostpoolName string
param workspaceName string

var hostpoolDiagName_var = '${hostpoolName}/Microsoft.Insights/hostpool-diag'
var workspaceDiagName_var = '${workspaceName}/Microsoft.Insights/workspacepool-diag'

var logworkspaceId = '/subscriptions/${logworkspaceSub}/resourcegroups/${logworkspaceResourceGroup}/providers/microsoft.operationalinsights/workspaces/${logworkspaceName} '

resource hostpoolDiagName 'Microsoft.DesktopVirtualization/hostpools/providers/diagnosticSettings@2017-05-01-preview' = {
  name: hostpoolDiagName_var
  location: location
  properties: {
    workspaceId: logworkspaceId
    logs: [
      {
        category: 'Checkpoint'
        enabled: 'True'
      }
      {
        category: 'Error'
        enabled: 'True'
      }
      {
        category: 'Management'
        enabled: 'True'
      }
      {
        category: 'Connection'
        enabled: 'True'
      }
      {
        category: 'HostRegistration'
        enabled: 'True'
      }
    ]
  }
}

resource workspaceDiagName 'Microsoft.DesktopVirtualization/workspaces/providers/diagnosticSettings@2017-05-01-preview' = {
  name: workspaceDiagName_var
  location: location
  properties: {
    workspaceId: logworkspaceId
    logs: [
      {
        category: 'Checkpoint'
        enabled: 'True'
      }
      {
        category: 'Error'
        enabled: 'True'
      }
      {
        category: 'Management'
        enabled: 'True'
      }
      {
        category: 'Feed'
        enabled: 'True'
      }
    ]
  }
}
