# Why should you manage NSG rules through CSV? 

Managing NSG rules through CSVs is widely recommended approach for better management. CSVs offers a grid view similar to Azure portal which is user friendly for any operations team. Unlike JSONs, CSVs are easy to edit and there is less hassle in managing it. 

Visual code editor has quite a few extensions that can be utilized to manage and edit CSV files. Microsoft Excel is always available for old schoolers out there :)

# What are the complications?

Utilizing CSV doesnt fully solve the problem though. For a complex environment with multiple networks and subnets, its quite common to have multiple Network Security groups. Zero trust approach and Defense in Depth adds to it as well leaving teams to tighten their security and eventually ending with more NSG rules. 

More the NSGs and NSG rules, it gets clumsier and challenging maintaining them. Quite often every NSG in the environment can have some basic rules such as Internet connectivity, On Premises connectivity or DMZ servers for log ingestion or monitoring etc. Any changes in these NSG rules such as adding a port or IP address had to be carried out across all NSGs. 

With more regions, the burden to keep NSG rules consistent to their counterpart regions or DR location is more. Any changes made in Primary location has to be made in Secondary region as well. 

# What are our options?

Maintaining CSVs at different level. 
- Global CSV which has company wide rules such as Connectivity to internet, OnPremises etc.
- Subscription level CSV comprising rules which are specific to all subnets in a Virtual Network(s) in the Subscription. 
- Now this Subscription level CSV file can comprise rules for multiple VNets including all regions in the Subscription. 

For every NSG deployment, We can consolidate the rules in Global CSV and the CSV from the Subscription to finalise the NSG rules required for a specific subnet in Spoke network. 

Even at a Subscription level, there can be requirements to have a common set of NSG rules to be applied for all NSGs in a Virtual network 

# How do we make this happen?

NSG preprocessing can be performed using Powershell scripts or any scripting language which can generate the final set of NSG rules by manipulating these CSV files. Some of the important logic needs to be built in this preprocessing script are as follows. 

- Handling Global NSG rules and Subscription level NSG rules 

- Generalising NSG rules at a Virtual Network or across all Virtual networks i.e Subnets for a chosen Subscription 
  - Usage of string "**allnsg**" instead of NSG name can apply NSG rules to all NSGs of Vnet
- Multi region NSG rules. Having a single NSG rule to apply for Vnets/Subnets of both regions.
  - If the NSG name has a region string in it eg: aue/aus. This can be left as **xxx** instead of region label. Preprocessing script can apply the same rule for both AUE and AUS NSGs. 
  - Same applies for Virtual Network as well. 
- Taking away the need to hard code Virtual Network address ranges or Subnet Address ranges, thus making the NSG ruleset environment agnostic as well.
  - Special strings such as "**subnetrange**" or "**vnetrange**" can be used to dynamically populate the address spaces for Vnet and subnet. 
  - Whereas "**vnetmatch**" and "**subnetmatch**" to dynamically populate the address spaces of Vnet or Subnet in Secondary region. 
  - If Subnet A needs to talk to Subnet B, instead of mentioning address spaces you can use the name of subnet prefixed and suffixed by double underscores. 
  - All these eliminates the hardcodings and makes it environment agnostic. 
- Preprocessing script can either directly update the Azure NSGs through powershell cmdlets or az cli commands 
- Alternatively, it can produce an output in forms of JSON similar to code base and this built JSON file can be fed to usual deployment pipelines. 

**Sample NSG CSV layout:**

|Column Name|Description|
|--|--|
|vnet                       | Name of Vnet. **Only in Subscription file** |
|nsg                        | Name of NSG parameter file. **Only in Subscription file**  |
|direction                  | Inbound/Outbound |
|priority                   | Rule Priority |
|rulename                   | Name of Rule |
|description                | Description of Rule |
|sourceAddressPrefix        | ServiceTag Or IP(s)/IP range(s) separated by Commas. Blanks if none |
|sourcePortRange            | Port or Ports separated by Commas. * if any |
|destinationAddressPrefix   | ServiceTag Or IP(s)/IP range(s) separated by Commas. Blanks if none.|
|destinationPortRange       | Port or Ports separated by Commas. * if any |
|sourceASG                  | Name of ASG. Blanks if none |
|destASG                    | Name of ASG. Blanks if none |
|protocol                   | Name of Protocol. Eg: TCP , * for any  |
|action                     | Allow or Deny |

**Sample Subscription NSG file**


**Expanded NSG view**


## **Note: NSG vs Vnet dependency**
 
As per deployment dependencies, the NSGs are oftent deployed first followed by Virtual Network as Subnet and NSG association is usually performed in Virtual Network deployment.
 
The special capabilities of preprocessing script to dynamically fetch IP ranges of subnet,vnet and apply rule across all NSGs with "allnsg" tag will only work if Vnet is created already and Subnet-NSG association is done
 
**Hence for a brand new creation of NSG,VNET etc, the NSGs have to be deployed again once the VNet and subnets are created for the special NSG rules with subnetrange,vnetrange, allnsg to apply.**

# Advantages:
- Limits the number of changes user had to make for company wide rules. There is just one Global CSV file to edit and maintain.  
- Ensure the NSG rules are consistent across Secondary regions and DR regions which eliminates the hassle in DR situations. 
- Easier management of NSG rules. The less you have to configure is always better and eliminates the chance for mistakes as well.



