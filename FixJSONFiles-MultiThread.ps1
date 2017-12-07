# This sample scripts is not supported under any Microsoft standard support program or service. 
# The sample scripts are provided AS IS without warranty of any kind. 
# Microsoft disclaims all implied warranties including, without limitation, any implied warranties of merchantability or of fitness for a particular purpose. 
# The entire risk arising out of the use or performance of the sample scripts and documentation remains with you. 
# In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or delivery of the scripts be liable for any damages whatsoever 
# (including, without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) 
# arising out of the use of or inability to use the sample scripts or documentation, even if Microsoft has been advised of the possibility of such damages.

# This script use a third party library from Newtonsoft to parser Json files.
# You can download the file here: https://github.com/JamesNK/Newtonsoft.Json/releases
# Current versiont 11/09/2017 - https://github.com/JamesNK/Newtonsoft.Json/releases/download/10.0.3/Json100r3.zip
# After unzip the file copy the file under \Bin\net45\Newtonsoft.Json.dll to a desired location and change the path in the script.

# Loading Newtonsoft.Json library *** You may need to change the file Path
[Reflection.Assembly]::LoadFile("C:\Scripts\Newtonsoft.Json.dll")

# Variable $Jobs used to control how many threads will be executed
$Jobs = 4

# ScriptBlock that will be executed on each thread.
$ScriptBlock = {
    param([string]$Path)
    # Loading Newtonsoft.Json library *** You may need to change the file Path
    [Reflection.Assembly]::LoadFile("C:\Scripts\Newtonsoft.Json.dll")

    $filepath = $Path
    $content = Get-Content $filepath
    # Do loop that will be executed until the whole file is fixed.
    do{
        $file = $content | Out-String
        try{
            $error.Clear()
            $test = [Newtonsoft.Json.JsonConvert]::DeserializeObject($file)
        }
        catch{
            $exception = $Error[0]
            $line = (($exception -split("line "))[1] -split(","))[0] - 1
            $position = ((($exception -split("line "))[1] -split(","))[1] -split(" "))[2]
            $position = ((($exception -split("line "))[1] -split(","))[1] -split(" "))[2].Substring(0,$position.Length-2) - 2
            $content[$line] = $content[$line].Insert($position,"\")
        }
    }while($Error.count -ne 0)
    $content | Set-Content $filepath
}

# Variable with Folder Path of where the Logs are located *** You may need to change this path
$folderPath = "C:\AffectedJSONFiles"

# Collection of files that will be fixed
$childFiles = Get-ChildItem -Path $folderPath -File

# Progress Control
$Progress = 100 / $childFiles.Count
$ProgressCount = 100 / $childFiles.Count

# Looping all Json log files in the folder $folderPath
Foreach($childfile in $childFiles){
    #Writing Progress
    $PerComplete = "{0:0}" -f $Progress
    write-progress -activity "Processing file: $childfile" -status "$PerComplete% Complete:" -percentcomplete $Progress

    # Do loop to control how many threads will be executing simultaneously
    Do
    {
        $Job = (Get-Job -State Running | measure).count
        Start-Sleep -Seconds 5

    } Until ($Job -le $Jobs)

    # Creating a new Thread
    Start-Job -Name $childfile.Name -ScriptBlock $ScriptBlock -ArgumentList $childfile.FullName | Out-Null
    # Removing all fineshed Threads
    Get-Job -State Completed | Remove-Job
    # Incrementing Progress 
    $Progress = $Progress + $ProgressCount
}

# Cleaning steps
Wait-Job -State Running | Out-Null
Get-Job -State Completed | Remove-Job
Get-Job