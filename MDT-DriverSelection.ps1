<#
.SYNOPSIS
    Matches the model in a CSV, gets the path to oob-driver and sets enviroment variable in tasksequence.
.DESCRIPTION
    Matches the model in a CSV, gets the path to oob-driver and sets enviroment variable in tasksequence.
.EXAMPLE
    MDT-DriverSelection.ps1
.NOTES
 Instructions:
    1. You need to import powershell and dotnet into Windows PE Image and regenerate it.
    2. Create the directory DriverSelection in the Script folder.
    3. Replace the current TS-steps to select and install drivers with the following (in order):
        
        - Name: Set Architecture
            Type: Set Task Sequence Variable
            Task Sequence Variabe: DriverArchitecture
            Value: x64

        - Name: MDT-DriverSelection
            Type: Run Powershell Script
            Powershell script: %SCRIPTROOT%\DriverSelection\MDT-DriverSelection.ps1

        - Name: Inject drivers automatically
            Type: Inject Drivers
            Choose a selection profile: Nothing
            Install all drivers from the selection profile: Yes (usually)

    4. Edit $ModulePath and $CSVPath to what fits your enviroment.
    5. Create a ModelDefinition.csv from scratch or copy ModelDefinition.csv from this repository. The model name supports regex!
    6. You may need to add "DriverArchitecture" and "DriverPathFound" variable to bootstrap.ini properties
    7. You can use "DriverPathFound" when it's False to kick off a sequence to force install of other drivers if none are found.
#>

$ModulePath = '\\MDTSERVER\MDTSHARE$\Tools\Modules\ZTIUtility\ZTIUtility.psm1'
$CSVPath = '\\MDTSERVER\MDTSHARE$\Scripts\DriverSelection\ModelDefinition.csv'

Write-Verbose "Importing ZTI module"
try{

    Import-Module $ModulePath

}
catch{

    Write-Error "Could not find or import module."
    $oReturn=[System.Windows.Forms.Messagebox]::Show("ERROR LOADING MODULE")
    sleep 5

}
$Architecture = $TSENV:DriverArchitecture
# Functions
Function Get-DriverPath($Model,$Architecture,$ModelCSV) {
    Write-Verbose "Searching for driver with parameters: $Model, $Architecture, $ModelCSV"
    $Result = $ModelCSV | Where-Object {$Model -match $_.ModelExpression}
    Write-Verbose "Found $Result"
    return $Result.DriverPath

}

Write-Verbose "Selected Architecture is $Architecture"



Write-Verbose "Importing Model CSV"
$ModelCSV = Import-CSV $CSVPath

Write-Verbose "Getting computer info"
if((Get-WmiObject -Class Win32_Computersystem).Manufacturer -eq "HP") {

    $ComputerModel = (Get-WmiObject -Class Win32_Computersystem).Model

}
else{
    $ComputerModel = (Get-WmiObject -Class Win32_Computersystem).Model
}

Write-Verbose "Computer model is a $ComputerModel"
$DriverPath = Get-DriverPath -Model $ComputerModel -Architecture $Architecture -ModelCSV $ModelCSV
Write-Verbose $DriverPath
if(![string]::IsNullOrEmpty($DriverPath)) {
    $TSEnv:DriverGroup001 = $DriverPath
    $TSEnv:DriverPathFound = 'True'
    Write-Verbose "DriverGroup = $($TSEnv:DriverGroup001)"
}
else{
    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    [void] [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.VisualBasic") 
    [Microsoft.VisualBasic.Interaction]::MsgBox("Inga drivrutiner hittades för denna modell: ($Computermodel)`n Ge modellnamn, OS version samt arkitektur till ansvarig. Samt även nedladdat drivrutinspaket för den modellen.", "OKOnly,SystemModal,Exclamation", "Fel")
    $TSEnv:DriverPathFound = 'False'
}

