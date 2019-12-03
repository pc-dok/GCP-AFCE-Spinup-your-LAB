#Check if GCE StartupScript is running first time otherwise it will exit
$testpath = test-path "C:\Windows\Temp\startup.txt"
if ($testpath -eq $true){

    #this is only that TS is running again after reboot - needed by Domain Controller Installation
    net use \\172.21.2.11\AFCE_Hydration$ /user:Administrator P@ssw0rd 
    #and than exit
    exit
}
else{

#Create our Administrator Logins
net user Administrator P@ssw0rd
net user Administrator /active:yes
net user ctxadmin P@ssw0rd /add
net localgroup administrators ctxadmin /add
net user ctxadmin /active:yes

##################### 
# Install Notepad++ #
#####################

Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

# NotePad ++
$Source         = "C:\Windows\temp"
$Product        = "Notepad++"
$Version        = "7.8.1"
$uri            = "https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v7.8.1/npp.7.8.1.Installer.x64.exe"
$PackageName    = $uri.Substring($uri.LastIndexOf("/") + 1)
$UnattendedArgs = '/S'

CD $Source
Invoke-WebRequest -Uri $uri -OutFile "$Source\$PackageName"
Write-Verbose "Starting Installation of $Product $Version" -Verbose
(Start-Process "$PackageName" $UnattendedArgs -Wait -Passthru).ExitCode

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose

#Enable this Section when you install over MDT Server with TS
# Run LiteTouch.vbs, replace the task sequence ID with yours
net use \\172.21.2.11\AFCE_Hydration$ /user:Administrator P@ssw0rd
\\172.21.2.11\AFCE_Hydration$\Scripts\LiteTouch.vbs "/TaskSequenceID:CTX-015" "/SkipTaskSequence:YES"
}

#Create a flag file for GCE Startup Script - so that it will execute only one time
new-item -path C:\Windows\Temp -Name startup.txt -Value "!!!Info: Let this file here, otherwise VM will after reboot always execute startup-script from GCE!" | foreach {$_.attributes = "Hidden"} 
