# MDT-DriverSelection
Let powershell select what drivers MDT is going to install, in a simple way.

## Instructions:
    1. You need to import powershell and dotnet into Windows PE Image and regenerate it.
    2. Create the directory DriverSelection in the Script folder.
    3. Replace the current TS-steps to select and install drivers with the following (in order):
        
        - Name: Set Architecture
            Type: Set Task Sequence Variable
            Task Sequence Variabe: DriverArchitecture
            Value: x64

        - Name: MDT-DriverSelection
            Type: Run Powershell Script
            Powershell script: %SCRIPTROOT%\DriverSelection\Set-DriverPath.ps1

        - Name: Inject drivers automatically
            Type: Inject Drivers
            Choose a selection profile: Nothing
            Install all drivers from the selection profile: Yes (usually)

    4. Edit $ModulePath and $CSVPath to what fits your enviroment.
    5. Create a ModelDefinition.csv from scratch or copy ModelDefinition.csv from this repository. The model name supports regex!
    6. You may need to add "DriverArchitecture" and "DriverPathFound" variable to bootstrap.ini properties
    7. You can use "DriverPathFound" when it's False to kick off a sequence to force install of other drivers if none are found.
