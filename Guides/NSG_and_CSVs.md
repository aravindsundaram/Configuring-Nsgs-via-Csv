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

NSG preprocessing can be performed which can generate the final set of NSG rules by manipulating these CSV files. Some of the important logic needs to be built in this preprocessing script are as follows. 

- Handle Global NSG rules and Subscription level NSG rules 
- Generalising NSG rules at a Virtual Network or across all Virtual networks i.e Subnets for a chosen Subscription 
- Multi region NSG rules. Having a single NSG rule to apply for Vnets/Subnets of both regions. 

Some of the nice to haves are 
- Taking away the need to hard code Virtual Network address ranges or Subnet Address ranges, thus making the NSG ruleset environment agnostic as well. 


# Advantages:
- Limits the number of changes user had to make for company wide rules. There is just one Global CSV file to edit and maintain.  
- Ensure the NSG rules are consistent across Secondary regions and DR regions which eliminates the hassle in DR situations. 
- Easier management of NSG rules. The less you have to configure is always better and eliminates the chance for mistakes as well.



