# AVD-BICEP

**UPDATED 14/06/2022**

New directory contains updated BICEP files. These new BICEP files remove any compile errors and optimize the Monitoring script slightly. 

Using the BICEP scope keywork to create the MicrosoftInsights/DiagnosticSettings against an existing resource symbolic link.

Also cleaned up so unused code.

**About**
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

To build the required JSON ARM Template run:

bicep build ***MainBuild.bicep***

The ***Configuration.zip*** file contains all the DSC and scripts required for the AVD build.

View my blog post at 

https://tighetec.co.uk/2021/07/07/deploy-azure-virtual-desktop-with-project-bicep/

for full information on how this was created.

The **AVD-Dev-Variables.xlsx** file with full listing of the Static and Selectable Variables used for deployment. This is due to change dependant on deployment. This still needs amending.
