
param (
        [Parameter(Mandatory=$true)]
        [string]
        $ParamJsonPath,
        [Parameter(Mandatory=$true)]
        [string]
        $Paramfilename,
        [Parameter(Mandatory=$true)]
        [string]
        $GlobalNSGPath,
        [Parameter(Mandatory=$true)]
        [string]
        $SubscriptionNSGPath,
        [Parameter(Mandatory=$true)]
        [string]
        $rgname
)

function Split-StringObject ([object] $stringObject) {
    if ($stringObject -is [string] -and -not [string]::IsNullOrEmpty($stringObject)) {
        $outputArrayValue = $stringObject.Split($arrayDelimiter)
        return [array] $outputArrayValue
    }
    else {
        return @()
    }
}
 
#Find subnet range by subnet name
function findSubnetRangebyName ([string] $subnet, [string] $vnet, [string] $rg ) {
  $sbrange = ""
  $subnettrimmed = $subnet.Trim("__")
  $vnetConfig = Get-AzVirtualNetwork -Name $vnet -ResourceGroupName $rg
  foreach ( $sb in $vnetConfig.Subnets)
  {
    if ( $sb.name -eq $subnettrimmed )
    {
      $sbrange = $sb.AddressPrefix
    }
  }
  return $sbrange
}
 
#Find Matched Vnet Range 
function findVnetMatch ([string] $vnet, [string] $rg ) {
  $vnetmatchrange = ""
  $rgreplaced = ""
  $vnetreplaced = "" 
  if ($vnet.Split("-").GetValue(2) -eq 'aue')
  {
    $vnetreplaced = $vnet.Replace('aue','aus')
    $rgreplaced = $rg.Replace('aue','aus')
  }
  if ($vnet.Split("-").GetValue(2) -eq 'aus')
  {
    $vnetreplaced = $vnet.Replace('aus','aue')
    $rgreplaced = $rg.Replace('aus','aue')
  }
  $vnetConfig = Get-AzVirtualNetwork -Name $vnetreplaced -ResourceGroupName $rgreplaced
  $vnetmatchrange = $vnetConfig.AddressSpace.AddressPrefixes
  return $vnetmatchrange
}
 
#Find Matched Subnet Range 
function findSubnetMatch ([string] $vnet, [string] $rg, [string] $nsg ) {
  $subnetmatchrange = ""
  $rgreplaced = ""
  $vnetreplaced = "" 
  if ($vnet.Split("-").GetValue(2) -eq 'aue')
  {
    $vnetreplaced = $vnet.Replace('aue','aus')
    $rgreplaced = $rg.Replace('aue','aus')
    $nsgreplaced = $nsg.Replace('aue','aus')
  }
  if ($vnet.Split("-").GetValue(2) -eq 'aus')
  {
    $vnetreplaced = $vnet.Replace('aus','aue')
    $rgreplaced = $rg.Replace('aus','aue')
    $nsgreplaced = $nsg.Replace('aus','aue')
  }
  $vnetConfig = Get-AzVirtualNetwork -Name $vnetreplaced -ResourceGroupName $rgreplaced
  foreach ( $sb in $vnetConfig.Subnets)
  {
    if ($sb.NetworkSecurityGroup)
    {
     $nsgid = $sb.NetworkSecurityGroup.Id
     $nsgsplit = $nsgid.Split("/").GetValue(8)
     #Find matched subnet by matching NSG name
     if ( $nsgsplit -eq $nsgreplaced )
     {
      $subnetmatchrange = $sb.AddressPrefix
     }
    }
  }
  return $subnetmatchrange
}
 
#Populate Address fix based on rules
function addressPrefixFinder ([string] $addressstring, [string] $vnetrange, [string] $subnetrange, [string] $vnet, [string] $rg, [string] $nsg) 
{
  $result = $addressstring
  if ($addressstring -eq 'vnetrange')
  {
    $result = [string] $vnetrange
  }
  if ($addressstring -eq 'subnetrange')
  {
    $result = [string] $subnetrange
  }
  if ($addressstring -like "*__*" )
  {
   $result =  [string] (findSubnetRangebyName -subnet $addressstring -vnet $vnet -rg $rg )
  }
  if ($addressstring -eq 'vnetmatch' )
  {
   $result =  [string] (findVnetMatch -vnet $vnet -rg $rg)
  }
  if ($addressstring -eq 'subnetmatch' )
  {
   $result =  [string] (findSubnetMatch -vnet $vnet -rg $rg -nsg $nsg)
  }
  return [string] $result
}
function ProcessCSV ([object] $workNSG, [string] $rg, [string] $nsg)
{
$reshapedSecurityRulesObject = $workNSG | ForEach-Object {
 
    #initializing variables
    $sourcePortRange = ""
    $destinationPortRange = "" 
    $sourceAddressPrefix = ""
    $destinationAddressPrefix = ""
    $emptylist = @()
    $sourcePortRanges = $emptylist
    $destinationPortRanges = $emptylist
    $sourceAddressPrefixes = $emptylist
    $destinationAddressPrefixes = $emptylist
 
    # Build array values from separated strings
    $sourceAddressPrefixes = [string[]] (Split-StringObject $_.sourceAddressPrefix)
    $sourcePortRanges = [string[]] (Split-StringObject $_.sourcePortRange)
    $destinationAddressPrefixes = [string[]] (Split-StringObject $_.destinationAddressPrefix)
    $destinationPortRanges = [string[]] (Split-StringObject $_.destinationPortRange) 
    $vnet = $_.vnet
    
    if ($sourcePortRanges.Count -le 1)
    {
       $sourcePortRanges = $emptylist
       $sourcePortRange = [string] $_.sourcePortRange
    }
    elseif ($sourcePortRanges.Count -gt 1)
    {
       $sourcePortRange = ""
    }
 
    if ($destinationPortRanges.Count -le 1)
    {
       $destinationPortRanges = $emptylist
       $destinationPortRange = [string] $_.destinationPortRange
    }
    elseif ($destinationPortRanges.Count -gt 1)
    {
       $destinationPortRange = ""
    }
 
    if ($sourceAddressPrefixes.Count -le 1)
    {
       $sourceAddressPrefixes = $emptylist
       $sourceAddressPrefix = [string] $_.sourceAddressPrefix
       $sourceAddressPrefix = [string] ( addressPrefixFinder -addressstring $sourceAddressPrefix -vnetrange $vnetaddressprefix -subnetrange $subnetaddressprefix -vnet $vnet -rg $rg -nsg $nsg )
 
    }
    elseif ($sourceAddressPrefixes.Count -gt 1)
    {
       $sourceAddressPrefix = ""
    }
 
    if ($destinationAddressPrefixes.Count -le 1)
    {
       $destinationAddressPrefixes = $emptylist
       $destinationAddressPrefix = [string] $_.destinationAddressPrefix
       $destinationAddressPrefix = [string] ( addressPrefixFinder -addressstring $destinationAddressPrefix -vnetrange $vnetaddressprefix -subnetrange $subnetaddressprefix -vnet $vnet -rg $rg -nsg $nsg )
    }
    elseif ($destinationAddressPrefixes.Count -gt 1)
    {
       $destinationAddressPrefix = ""
    }
    
    if ($_.sourceASG)
    {
      [string] $sourceAsgId = (Get-AzResource -Name $_.sourceASG).ResourceId
    }
 
    if ($_.destASG)
    {
      [string] $destAsgId = (Get-AzResource -Name $_.destASG).ResourceId
    }
    
    [PSCustomObject]@{
        name                                 = [string] $_.rulename
        description                          = [string] $_.description
        priority                             = [int] $_.priority
        access                               = [string] $_.action
        direction                            = [string] $_.direction
        protocol                             = [string] $_.protocol
        sourceAddressPrefix                  = $sourceAddressPrefix
        sourceAddressPrefixes                = $sourceAddressPrefixes
        sourceApplicationSecurityGroupId     = $sourceAsgId
        sourcePortRange                      = $sourcePortRange
        sourcePortRanges                     = $sourcePortRanges
        destinationAddressPrefix             = $destinationAddressPrefix
        destinationAddressPrefixes           = $destinationAddressPrefixes
        destinationApplicationSecurityGroupId= $destAsgId
        destinationPortRange                 = $destinationPortRange 
        destinationPortRanges                = $destinationPortRanges
    }
}
 
return $reshapedSecurityRulesObject
}
 
try
{
 
if (!(Test-Path "$ParamJsonPath\pre"))
{
New-Item -itemType Directory -Path $ParamJsonPath -Name "pre"
}
else
{
write-output "Preprocessing Folder already exists"
}

write-output "Preprocesing $paramfile"
 
#$Paramfilenamesplit = $paramfile.Split(".").GetValue(0)
#$nsgname = $Paramfilenamesplit
$Nsgfile = ConvertFrom-Json -inputobject ( Get-Content -Raw -Path $ParamJsonPath\$paramfile )
 
$nsgArray = $Nsgfile.parameters.networkSecurityGroupName.value
 
#Looping from NSG array in Param file
foreach ($i in $nsgArray) 
{
$nsgname = $i  
$regionString = $nsgname.Split("-").GetValue(2)
$finalNsgParamsJson = "$ParamJsonPath\pre\$nsgname-preprocessed.parameters.json"
$CSVdelimiter = "|"
$arrayDelimiter = ","
 
#obtain Vnets from resource group
write-output "Fetching Vnets for resource group $rgname"
$vnet= Get-AzVirtualNetwork -Name '*vnt*' -ResourceGroupName $rgname
#initialize address prefixes
$subnetaddressprefix = '13181'
$vnetaddressprefix = '13181'
$vnetName = 'default'
 
#find vnet and subnet which is matching the NSG pre processing
foreach ( $vn in $vnet)
{
 write-output "Processing vnets" 
 write-output "Verifying subnet and NSG for a match"
 foreach ( $sb in $vn.Subnets)
 {
   if ($sb.NetworkSecurityGroup)
   {
    $nsgid = $sb.NetworkSecurityGroup.Id
    $nsg = $nsgid.Split("/").GetValue(8)
    if ($nsg -eq $nsgname)
    {
     write-output "Subnet and NSG match found $nsg. Fetching Address spaces"
     $subnetaddressprefix = $sb.AddressPrefix
     $vnetaddressprefix = $vn.AddressSpace.AddressPrefixes
     $vnetName = $vn.Name
     write-output "Subnet Address space: $subnetaddressprefix"
     write-output "Vnet Address space: $vnetaddressprefix"
    }
   }
 }
}
 
#Import NSG rules from Global NSG file
if (($vnetaddressprefix -eq '13181') -or ($subnetaddressprefix -eq '13181') -or ($vnetName -eq 'default'))
{ 
  write-output "Vnet and subnet ranges not found. Skipping rules with vnet and subnetranges"
  write-output "Redeploy NSG rules once the VNETs are available for rules with VNet or subnet ranges to be applied."
  $csvNsg = import-csv $GlobalNSGPath -Delimiter $CSVdelimiter | Where-object {
    ( $_.sourceAddressPrefix -ne "vnetrange" ) -and
    ( $_.sourceAddressPrefix -ne "subnetrange") -and
    ( $_.destinationAddressPrefix -ne "vnetrange" ) -and
    ( $_.destinationAddressPrefix -ne "subnetrange") 
  }
}
else {
  $csvNsg = import-csv $GlobalNSGPath -Delimiter $CSVdelimiter
}
 
write-output "Processing Global level NSG rules for NSG $nsgname"
 
if ( $csvNsg.Count -gt 0)
{
  write-output $csvNsg.Count
$ProcessedNSG1 = ProcessCsv -workNSG $csvNsg -rg $rgname -nsg $nsgname
}
else
{
  write-output "No global rules imported"
}
 
#Transform Subscription file xxx -> aue/aus 
$subNsgWorkfile = import-csv $SubscriptionNSGPath -Delimiter $CSVdelimiter | ForEach-Object {
  $_.vnet = $_.vnet -replace 'xxx', $regionString
  $_.nsg = $_.nsg -replace 'xxx', $regionString     
  $_                                   
}
 
 
 
#Import NSG rules from Transformed Subscription file filtered by Subnet i.e NSG chosen
if (($vnetaddressprefix -eq '13181') -or ($subnetaddressprefix -eq '13181') -or ($vnetName -eq 'default'))
{ 
  write-output "Vnet and subnet ranges not found. Skipping rules with vnet and subnetranges in SubscriptionNSG"
  write-output "Redeploy NSG rules once the VNETs are available for rules with VNet or subnet ranges to be applied."
  write-output "Vnet name not populated. Skipping rules with allnsg tag in SubscriptionNSG"
  write-output "Redeploy NSG rules once the VNETs are available for rules with allnsg tag to be applied."
  $csvNsg = $subNsgWorkfile | Where-object {
    ( $_.nsg -eq $nsgname ) -and (( $_.sourceAddressPrefix -ne "vnetrange" ) -and
    ( $_.sourceAddressPrefix -ne "subnetrange") -and
    ( $_.destinationAddressPrefix -ne "vnetrange" ) -and
    ( $_.destinationAddressPrefix -ne "subnetrange") -and
    ( $_.nsg -ne "allnsg"))
  }
}
else {
  $csvNsg = $subNsgWorkfile | Where-Object {
    ( $_.nsg -eq $nsgname ) -or 
    (( $_.nsg -eq "allnsg") -and ( $_.vnet -eq $vnetName))
  }
}
 
if ( $csvNsg.Count -gt 0)
{
  write-output "Processing Subnet level NSG rules for NSG $nsgname"
  $ProcessedNSG2 = ProcessCsv -workNSG $csvNsg -rg $rgname -nsg $nsgname
  #Finalise Global and Subnet NSG rules
  $FinalNSG = $ProcessedNSG1 + $ProcessedNSG2
}
else
{
  write-output "No Subnet level NSG rules found for NSG $nsgname"
  #Finalise Global and Subnet NSG rules
  $FinalNSG = $ProcessedNSG1
}
 
$Nsgfile.parameters.networkSecurityGroupSecurityRules.value = [array] $FinalNSG
#converting multi NSG to single NSG 
$Nsgfile.parameters.networkSecurityGroupName.value = [array] $nsgname 
 
$nsgParamsJson = ConvertTo-Json -InputObject $Nsgfile -Depth 10
 
write-output "Finalizing Parameters file for NSG $nsgname"
 
#Populate final Parameters json file for ARM template deployments
$nsgParamsJson | Set-Content $finalNsgParamsJson
 
write-output $nsgParamsJson
 
write-output "Pre processed NSG rules successfully for NSG $nsgname"
}
 
}
catch
{
 write-output $_
 exit 1
}
 
