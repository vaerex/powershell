#Justin Bias
#@vaerex
#vaerex.github.io

#Function to get all the DRS details of a particular VM.  We'll check for any VM groups it belongs to as well as any VM to Host affinity rules and VM to VM Affinity/Anti-affinity rules.

function get-vmdrsrules{

#One parameter, which is mandatory, and that's the name of the VM in string format. Eventually I'd like to be able to accept from the pipeline in the form of a VM
Param(
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $vmname
) #endparam

    #Try to get the vm, and let's set a Stop on this if it fails so we can properly catch it and return
  try{
    $vm = get-vm $vmname -ErrorAction Stop
     }

    #Catch the error returned when the get-vm fails for the selected VM and exit because there's no sense in continuining 
  catch [VMware.VimAutomation.Sdk.Types.V1.ErrorHandling.VimException.VimException]{
    "Failed to find the VM $vmname"
    exit
    }
  
  #If we were able to find the VM, let's start checking stuff
  finally{
  #Capture the ID of the VM because we'll need it when looking for VM Affinity/Anti-Affinity rules. Not sure why VMware does it using ID when it uses straight up VM objects in VM to Host rules
  $vmid = $vm.Id

  #We'll need the cluster of the VM to use with the various DRS cmdlets
  $cluster = $vm | get-cluster
  
  #Capturing any DRS VM Groups that contain the VM in their member list
  $vmgroups = get-drsclustergroup -Type VMGroup -Cluster $cluster | where-object {$_.Member -contains $vm}

  #Capturing any VM Affinity/Anti-Affinity rules that might exist. Have to use $vmid here 
  $drsrules = get-drsrule -Cluster $cluster | where-object {$_.VMIds -contains $vmid}
  
  #Creating and filling an array with new objects representing any VM to Host DRS rules that we can then sanity check against before printing anything out. Unfortunately we can't assume
  #that a VM will be involved in any VM to Host rules even if it exists in DRS VM Groups
  $vmhostrules = @()
  foreach ($group in $vmgroups){
      $hostRuleProperties = get-drsvmhostrule | where {$_.VMGroup -like $group.Name} | select Name, Type, VMHostGroup, Enabled
      $vmhostrule = new-object PSObject -Property @{
            Name = $hostRuleProperties.Name
            Type = $hostRuleProperties.Type
            VMHostGroup = $hostRuleProperties.VMHostGroup
            Enabled = $hostRuleProperties.Enabled
            }
       $vmhostrules += $vmhostrule
      }

  #Sanity check number 1: Is the VM a member of any DRS VM groups? If it's not, say so, and also indicate that it obviously cant' be part of any VM to Host DRS rules
  if ($vmgroups -eq $null){
        write-output "$vm was not found in any DRS VM Groups and cannot be part of any VM to Host DRS rules."}
  else{  
  #But if it IS part of a DRS VM group then let's print those groups and then do a check to see if it's part of any VM to Host rules. Indicate yes or no, and if yes, print the rules
  write-output "$vm is part of the following VM DRS Groups: $vmgroups`n"
           if ( $vmhostrules.Length -lt 2){
            write-output "$vm was not found in any VM to Host DRS rules"
          }
          else{
            "$vm runs on $cluster Cluster and is part of the following VM to Host DRS rules:`n"
             $vmhostrules| ft 
             }  
  }
            

    #Sanity check number 2: Is the VM participating in any VM Affinity/Anti-Affinity rules that we looked for earlier? If not, say so, and if yes, print the rules
  if ($drsrules -eq $null){
    write-output "`n$vm was not found in any VM Affinity/Anti-Affinity DRS rules."
    }
  else{
    write-output "`n$vm is part of the following VM Affinity/Anti-Affinity DRS Rules:"
    $drsrules | ft    
    }
  
  
  }
}


