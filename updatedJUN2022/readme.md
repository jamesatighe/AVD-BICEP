# AVD-BICEP

## Updates

**01/07/2022**

Added Azure AD Join capabilities.

New parameter AADJOIN (bool) is used to allow for Azure Active Directory Join (rather than standard Active Directory)

    resource joindomain 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = [for i in range(0, AVDnumberOfInstances): {
    name: '${vmPrefix}-${i + currentInstances}/joindomain'
    location: location
    properties: AADJoin ? {
        publisher: 'Microsoft.Azure.ActiveDirectory'
        type: 'AADLoginForWindows'
        typeHandlerVersion: '1.0'
        autoUpgradeMinorVersion: true
    } : {
        publisher: 'Microsoft.Compute'
        type: 'JsonADDomainExtension'
        typeHandlerVersion: '1.3'
        autoUpgradeMinorVersion: true
        settings: {
        name: domainToJoin
        ..

When adding to Azure AD you need to ensure your VNET is set to resolve Azure DNS records.

Also as part of the build if AADJOIN is true it will add a System Managed Identity to the VM's to allow them to join Azure AD.

    resource vm 'Microsoft.Compute/virtualMachines@2021-11-01' = [for i in range(0, AVDnumberOfInstances): {
        name: '${vmPrefix}-${i + currentInstances}'
        location: location
        identity: AADJoin ? {
        type: 'SystemAssigned'
    } : null
    ..

Also . . .

Have updated the DSC script that runs in the background. This will now install the newest RDAgent and is slightly streamlined.

**01/06/2022**

Added the ability to add AVD Session Hosts to Log Analytics workspace.

This requires 2 new variables to be set on deployment.

- **workspaceID**

- **workspaceKey**

Then set the **_monitoringAgent_** parameter to true.

This will trigger the deployment to add the session hosts automatically to the required Log Analytics workspace. I left this as an option as we were deploying via Policy so can be a personal choice.

The VM module is now called **VMswithLA.BICEP** for this purpose.

**Monitoring Change**

Previously the way the monitoring module was scripted was generating BICEP compile warnings. This was due to the way the I was defining the DiagnosticSettings via a provider segment. This causes a **_Type validation is not available for resource type using a "/providers/" segment"_**

The fix for this was to use the BICEP **scope** property to create a new child resource (monitoring extension) scoped to an parent resource.

https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/scope-extension-resources

I had to get the existing resource using the below

    resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2021-07-12' existing = {
        name: hostPoolName
    }

Then change the start of the diagnosticSettings resource to the below:

    resource hostPoolDiagName 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
        name: 'hostpool-diag'
        scope: hostPool
        ..
        ..
    }

This allowed the extension to be created under the scope of the existing Host Pool resource, and removed the compile warning.
