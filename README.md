# AVD-BICEP

## Updated 15/05/2025
Some major updates the the script and how it works added a number of new features.

- Support for Trusted Launch VM images (requires a suitable Azure Compute Gallery image)
- Azure Monitor support via Data Collection Rules
- Cleaned up code and added comments for better readability
- Remove the ARM template folder as this project is authored in pure BICEP

***ALL UPDATED SCRIPT IS IN THE BICEP FOLDER***
***The updatedJUN2022 is now out of date***

## Updated 04/07/2022
Added intune parameter to mainBuild.bicep and VMswithLA.bicep to allow autoenrolment into Intune for AAD joined session hosts.

    resource joindomain 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = [for i in range(0, AVDnumberOfInstances): {
    name: '${vmPrefix}-${i + currentInstances}/joindomain'
    location: location
    properties: AADJoin ? {
        publisher: 'Microsoft.Azure.ActiveDirectory'
        type: 'AADLoginForWindows'
        typeHandlerVersion: '1.0'
        autoUpgradeMinorVersion: true
        settings: intune ? {
            mdmId: '0000000a-0000-0000-c000-000000000000’
        } : null
    } : {
    ..

## Updated 01/07/2022

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


## About
A full Azure Virtual Desktop Deployment authored in BICEP

This code was designed to deploy a fully functioning AVD environment. This environment consists of:

- Workspace
- Host Pool
- Desktop Application Group
- Specified number of Session Hosts VMs

The deployment also used Custom Script Extensions and DSC to configure the environment. This scripting performs the following actions.

- Set default language and region to EN-GB
- (If new deployment) Rename Desktop Application Group Friendly Name
- (If new deployment) Assign default users to Application Group
- Register Session Host VMs with Host Pool

This deployment script can be used for either new environments or to add Session Host VMs to an existing deployment.

All BICEP files are included in the BICEP folder.

## Deploying
You can either convert the BICEP into JSON ARM template files, or run the Azure deployment using the native BICEP files.

If you wish to convert to JSON format ensure BICEP is install on your machine and then run:

bicep build ***MainBuild.bicep*** 

You can run the standard PowerShell ***New-AzResourceGroupDeployment*** or ***New command to intitate the deployment via:

New-AzSubscriptionDeployment -Location <location> -TemplateFile <path-to-file>

It is important to note the deployment scope for this deployment is ***Subscription*** not ResourceGroup. 

###Deploy via DevOps
I have numerous blog posts around AVD and particularly deployment at the my blog site:

https://tighetec.co.uk

The following link is to the main BICEP deployment blog detailing how this was orignally created:

https://tighetec.co.uk/2021/07/07/deploy-azure-virtual-desktop-with-project-bicep/

The ***Configuration.zip*** file contains all the DSC and scripts required for the AVD build. This may need updates as required with newer versions of the RD Agent.

The **AVD-Dev-Variables.xlsx** file with full listing of the Static and Selectable Variables used for deployment. 
This is due to change dependant on deployment. This still needs amending.

for full information on how this was created.

The **AVD-Dev-Variables.xlsx** file with full listing of the Static and Selectable Variables used for deployment. This is due to change dependant on deployment. This still needs amending.
