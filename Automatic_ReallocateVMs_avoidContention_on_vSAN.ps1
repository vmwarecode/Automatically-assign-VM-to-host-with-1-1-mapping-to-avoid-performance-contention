$candidate_VMs=@('vm1','vm2','vm3','vm4')

$hostsArray=@()
[System.Collections.ArrayList]$INhostsArray=$hostsArray
$New_host_withVMs=@()
[System.Collections.ArrayList]$INNew_host_withVMs=$New_host_withVMs

Set-PowerCLIConfiguration -DefaultVIServerMode Multiple -Scope AllUsers -InvalidCertificateAction Ignore -ProxyPolicy NoProxy -Confirm:$false

$user="vc_username"
$password="vc_password"
$host1="vc_ip_address"


Connect-VIServer  -Server $host1 -User $user -Password $password

$myServerList=@()
 foreach($Cluster in Get-Cluster)
 {
  foreach ($vmhost in (Cluster |Get-VMHost))
  {
  $VMView =$vmhost |Get-View
        $VMhostName=$vmhost.Name
       $myServerList+=$VMhostName
       $INhostsArray.Add($VMhostName)
        }
}

foreach ($hostInstance in $INhostsArray){
        $vm_list_onthehost=Get-VM |select Name,VMhost|Where-Object{$_.VMHost.Name -eq $hostInstance} |select  Name 
        $itemlistofvms=$vm_list_onthehost|foreach{$_.Name}

        $tempHostArray=@()
        [System.Collections.ArrayList]$INtempHostArray=$tempHostArray
        $INtempHostArray.Add($hostInstance)
                
            foreach ($vm in $candidate_VMs){
                if ($itemlistofvms -contains $vm){
                 $INtempHostArray.Add($vm)
                        }
                 }
   $INNew_host_withVMs.Add($INtempHostArray)
}

$MigrationIdleHostArray=@()
[System.Collections.ArrayList]$INMigrationIdleHostArray=$MigrationIdleHostArray
$MigrationVMArray=@()
[System.Collections.ArrayList]$INMigrationVMArray=$MigrationVMArray

foreach ($hostwithvm in $INNew_host_withVMs){
       write-host $hostwithvm.count
       if ($hostwithvm.count -eq 1){ write-host "No member on this host, put to idle list."
       $INMigrationIdleHostArray.Add($hostwithvm[0])
       } # put to idle list
       if ($hostwithvm.count -gt 2){ write-host "This host has member(s), put the member to the migration list."
        for ($hi=$hostwithvm.count;$hi -gt 2; $hi--){
         $INMigrationVMArray.Add($hostwithvm[$hi-1])
        }
       } # put to idle list

       }

       foreach ($testi in $INMigrationVMArray) {write-host $testi}

 if ($INMigrationVMArray.count -gt $INMigrationIdleHostArray.count) 
 {write-host "The host number is not enough for vm migration, exit[1]" -ErrorAction Stop
 }
 else 
 { 
  for($mi=0; $mi -le $INMigrationVMArray.count; $mi++){

       Move-VM -VM $INMigrationVMArray[$mi] -Destination $INMigrationIdleHostArray[$mi]
 }
 }

