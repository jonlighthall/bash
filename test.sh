## BEGIN SAMPLE SCRIPT

#This function retrieves the MD5 hash for a file 
function Get-MD5([System.IO.FileInfo] $file = $(Throw 'Usage: Get-MD5 [System.IO.FileInfo]')) 
{
    $stream = $null;
    $cryptoServiceProvider = [System.Security.Cryptography.MD5CryptoServiceProvider]; 
    
    $hashAlgorithm = new-object $cryptoServiceProvider 
    $stream = $file.OpenRead(); 
    $hashByteArray = $hashAlgorithm.ComputeHash($stream); 
    $stream.Close(); 
    
    ## We have to be sure that we close the file stream if any exceptions are thrown. 
    trap 
    { 
	if ($stream -ne $null) 
	   { 
	       $stream.Close(); 
	   } 
	   break; 
    } 
    return [string]$hashByteArray; 
} 


# This filter calls the Get-MD5 hash function to retrieve the files MD5 hash, 
# then uses the AddNote function to add the hash as a note 
# called 'MD5' and finally it will return the object. 

filter AttachMD5 
{ 
    $md5hash = Get-MD5 $_; 
    return ($_ | AddNote MD5 $md5Hash); 
}


## Adds a note to the pipeline input. 

filter AddNote([string] $name, $value) 
{ 
    $mshObj = [System.Management.Automation.psObject] $_; 
    $note = new-object System.Management.AUtomation.psNoteProperty $name, $value 
    $mshObj.psObject.Members.Add($note); 
    return $mshObj 
} 

# Group the files where number of files with matching hash > 1. 
# These are probable duplicates. Note the path to the files is hard coded here. 

Get-ChildItem o:\music\temp\*.* |  

    #write the files to be deleted to a text log 
    where { $_ -is [System.IO.FileInfo] } | 
    AttachMD5 | 
    group-object Length,MD5 | 
    where { $_.Count -gt 1 }|foreach{$_.Group -join ","} > some_file.txt   

#Delete the files 
Get-Content some_file.txt|foreach{remove-item ($_.split(",")[1..($_.split(",")).count])-whatif}  

## END SAMPLE SCRIPT
