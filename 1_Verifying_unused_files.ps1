<#
   Author: Chandra Sekhar Jetty
   Description: This script is to check and delete unused files based on some number of retention days
#>
Param (
   # Folder to check unused filess
   [Parameter(Mandatory=$true)]
   [string] $folder,

   #Action to delete or check, default to check number of unused vectors
   [ValidateSet("delete", "check")]
   [string] $action = "check",

   # Number of days value, default to 180 days 
   [int] $numberofdays = 1,

   #Search depth defaulted to null
   [int] $depth = $null
);

#Log file name with the datetime stamp appended
$logfilename = "Unused_file_details.log";

#Log file local location defaulted to C:\Temp directory
$log = "C:\Temp\" + $logfilename;

Function Get-UnusedFilesAndDelete($action, $folder, $unuseddays, $depth)
{
   #Initialising Output of this function
   $result = @{
      mode  = $action;
	   logfile = $log;
		deleted = $false;
		msg = "";
      failed = $false;
      unusedfilescount = 0;
      unuseddays = $unuseddays;
      depth = "max";
	}
   
   $cutoffdate = (Get-Date).AddDays($unuseddays);

   if ($depth){
      $files = Get-ChildItem -Recurse -Depth $depth -Path $folder  | Where-Object {$_.LastAccessTime -le $cutoffdate};
      $result.depth = $depth
   }else{
      $files = Get-ChildItem -Path $folder -r | Where-Object {$_.LastAccessTime -le $cutoffdate};
   }
   $result.unusedfilescount = $files.Count;

   #If action is to delete the unused vectors
   if ($action -eq "delete") {
        # If log file doesn't exist, create one to be nice
        if (!(Test-Path $log)) {
            New-Item $log -ItemType File;
        }
        ForEach ($file in $files) {
            echo "Deleting $file which was last accessed on $($file.LastAccessTime) " | Out-File -Append -FilePath $log;
            #Remove-Item -Force $file.FullName;
        }
        $result.deleted = $true;
        $result.msg = "Total files deleted are $($files.Count)";
        echo  "Total files deleted are $($files.Count)" | Out-File -Append -FilePath $log;
   }
   #If action is check
   else{
        $result.msg = "Total files to be deleted are $($files.Count)";
   }
   if ($result.failed){
        $result.msg = $result.msg + "`n " + " But few errors are observed refer to log $($result.logfile) for more details";
   }
   echo $result | ConvertTo-Json;
}


$functionparams = @{
   action = $action
   folder = $folder
   unuseddays = 0 - $numberofdays
   depth = $depth
}

Get-UnusedFilesAndDelete @functionparams;

