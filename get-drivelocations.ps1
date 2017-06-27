#Justin Bias
#@vaerex 
#vaerex.github.io



function get-drivelocations{

Param(
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $vmhost
)

$esxcli2 = get-esxcli -vmhost (get-vmhost $vmhost) -v2
$arguments = $esxcli2.storage.core.device.physical.get.CreateArgs()

$esxcli2.storage.core.device.list.invoke() | where {$_.Displayname -match "Disk" -and $_.DisplayName -notmatch "iSCSI"} | foreach -Process {
$_.DisplayName -match 'naa\.\w{16}' |out-null
write-output " Disk Device: "$matches[0]
$arguments.device = $matches[0]
$esxcli2.storage.core.device.physical.get.Invoke($arguments) | ft -HideTableHeaders
}



}