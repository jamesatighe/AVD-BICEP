Param(
    [Parameter(Mandatory = $true)]
    [String]$SharedImageGalleryResourceGroup,
    [Parameter(Mandatory = $true)]
    [String]$SharedImageGalleryName,
    [Parameter(Mandatory = $true)]
    [String]$SharedImageGalleryDefinitionName,
    [Parameter(Mandatory = $true)]
    [String]$SharedImageGalleryVersionName,
    [Parameter(Mandatory = $true)]
    [String]$vmNamePrefix,
    [Parameter(Mandatory = $true)]
    [String]$resourceGroup,
    [Parameter(Mandatory = $true)]
    [String]$hostPoolName,
    [Parameter(Mandatory = $true)]
    [string]$update,
    [Parameter(Mandatory = $true)]
    [string]$newBuild
)

#Check if update. If true build from new version, if false build from libray specified version
if ($update -eq "true") {
    Write-Host "Parameters set to update current Host Pool"
    $sigversions = Get-AzGalleryImageVersion -ResourceGroupName $SharedImageGalleryResourceGroup -GalleryName $SharedImageGalleryName -GalleryImageDefinitionName $SharedImageGalleryDefinitionName
    $sigversions = $sigversions | select name, @{n="publishedDate";e={$_.publishingprofile.publisheddate}} | Sort-Object -Property publisheddate
    $latestversion = $sigversions[$sigversions.count - 1].Name
} else {
    Write-Host "Parameters set to scale out Host Pool"
    $latestversion = $SharedImageGalleryVersionName
}

$minor = $latestversion.split(".")[1]
$patch = [int]$latestversion.split(".")[2]

#Create VM Prefix for update machines
$prefix = "$($vmNamePrefix)-$($minor)-$($patch)"

#Check if New Build
if ($newbuild -eq "true") {
    Write-Host "New Build sop numbering to start from 0"    
    $currentNoHosts = "0"
} else {
    Write-Host "Scale out of existing pool. Numbering to continue."
    $currentNoHosts = (Get-AzWVDSessionHost -ResourceGroup $resourceGroup -HostPool $hostpoolName).count
}
Write-Host "Current number of hosts: $currentNoHosts"

#Create Tags
$stringtag = @{Version = "$latestversion"; Purpose = "AVD"; Owner = "Infrastructure" }
$json = $stringtag | ConvertTo-Json -Compress

#Create Token for Host Pool Registration
$token = (get-date).AddHours(+2).ToString('yyyy-MM-ddTHH:mm:ssZ')

#DevOps Outputs
Write-Host "##vso[task.setvariable variable=json;isOutput=true;]$json"
Write-Host "##vso[task.setvariable variable=token;isOutput=true;]$token"
Write-Host "##vso[task.setvariable variable=prefix;isOutput=true;]$prefix"
Write-Host "##vso[task.setvariable variable=version;isOutput=true;]$latestversion"
Write-Host "##vso[task.setvariable variable=currentNoHosts;isOutput=true;]$currentNoHosts"

#GitHubActions Outputs
echo "TOKEN=$token" >> "$GITHUB_OUTPUT"
