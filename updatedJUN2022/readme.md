**Updates**

Added the ability to add AVD Session Hosts to Log Analytics workspace.

This requires 2 new variables to be set on deployment.

**workspaceID**

**workspaceKey**

Then set the ***monitoringAgent*** parameter to true. 

This will trigger the deployment to add the session hosts automatically to the required Log Analytics workspace. I left this as an option as we were deploying via Policy so can be a personal choice.

The VM module is now called **VMswithLA.BICEP** for this purpose.

**Monitoring Change**

Previously the way the monitoring module was scripted was generating BICEP compile warnings. This was due to the way the I was defining the DiagnosticSettings via a provider segment. This causes a ***Type validation is not available for resource type using a "/providers/" segment"***

The fix for this was to use the BICEP **scope** property to create a new child resource (monitoring extension) scoped to an parent resource.

I had to get the existing resource using the below

**resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2021-07-12' existign = {
  name: hostPoolName
}

Then change the start of the diagnosticSettings resource to the below:

**resource hostPoolDiagName 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'hostpool-diag'
  scope: hostPool
  ..
  ..
 }**

This allowed the extension to be created under the scope of the existing Host Pool resource, and removed the compile warning.

