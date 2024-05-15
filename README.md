# AVD-BICEP

## Updated 15/05/2025
Some major updates the the script and how it works added a number of new features.

- Support for Trusted Launch VM images (requires a suitable Azure Compute Gallery image)
- Azure Monitor support via Data Collection Rules
- Cleaned up code and added comments for better readability
- Remove the ARM template folder as this project is authored in pure BICEP

***ALL UPDATED SCRIPT IS IN THE BICEP FOLDER***
***The updatedJUN2022 is now out of date***
## UPDATED 14/06/2022
New directory contains updated BICEP files. These new BICEP files remove any compile errors and optimize the Monitoring script slightly. 

Using the BICEP scope keywork to create the MicrosoftInsights/DiagnosticSettings against an existing resource symbolic link.

Also cleaned up so unused code.

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
