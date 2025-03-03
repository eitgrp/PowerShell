##################################################################################################################################################################################################
# Installing fonts through Powershell requires specific COM properties to be added to the files before moving, as well as registering them in specific parts of the registry.                    #
# Instead of spending ages working out how to do it, I've used a script I found online: https://www.powershellgallery.com/packages/PPoShTools/1.0.8/Content/Public%5CFileSystem%5CAdd-Font.ps1   #
##################################################################################################################################################################################################

 # Requires -Version 4.0

######################################################################################################################################################################
# IWR is short for Invoke-WebRequest, basically telling Powershell to request this file from our static website, and save it in Temp with the name "Roboto.zip"      #                            
# Expanding the archive in Temp, then doing a ForEach loop to go through each file that ends in .ttf or .otf, and install the font                                   #
######################################################################################################################################################################

[CmdletBinding(DefaultParameterSetName='Directory')]
Param(
  [Parameter(Mandatory=$false,
    ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
  [Parameter(ParameterSetName='Directory')]
  [System.String[]]
  $Path = "$Env:temp\Roboto",

  [Parameter(Mandatory=$false,
    ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
    [Parameter(ParameterSetName='File')]
  [ValidateScript({Test-Path $_ -PathType Leaf })]
  [System.String]
  $FontFile
)

begin {
  iwr "http://static.desktopservice.eu/downloads/Source/Clients/T00064/Roboto.zip" -OutFile $Env:temp\Roboto.zip
  Expand-Archive -Path $Env:temp\Roboto.zip -Destination $Env:temp
  Set-Variable Fonts -Value 0x14 -Option ReadOnly
  $fontRegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"

  $shell = New-Object -ComObject Shell.Application
  $folder = $shell.NameSpace($Fonts)
  $objfontFolder = $folder.self.Path
  #$copyOptions = 20
  $copyFlag = [string]::Format("{0:x}",4+16)
  $copyFlag
}

process {
  switch ($PsCmdlet.ParameterSetName) {
    "Directory" {
      ForEach ($fontsFolder in $Path){
        Write-Log -Info -Message "Processing folder {$fontsFolder}"
        $fontFiles = Get-ChildItem -Path $fontsFolder -File -Recurse -Include @("*.fon", "*.fnt", "*.ttf","*.ttc", "*.otf", "*.mmm", "*.pbf", "*.pfm")
      }
    }
    "File" {
      $fontFiles = Get-ChildItem -Path $FontFile -Include @("*.fon", "*.fnt", "*.ttf","*.ttc", "*.otf", "*.mmm", "*.pbf", "*.pfm")
    }
  }
  if ($fontFiles) {
    foreach ($item in $fontFiles) {
      Write-Log -Info -Message "Processing font file {$item}"
      if(Test-Path (Join-Path -Path $objfontFolder -ChildPath $item.Name)) {
        Write-Log -Info -Emphasize -Message "Font {$($item.Name)} already exists in {$objfontFolder}"
      }
      else {
        Write-Log -Info -Emphasize -Message "Font {$($item.Name)} does not exists in {$objfontFolder}"
        Write-Log -Info -Message "Reading font {$($item.Name)} full name"

        Add-Type -AssemblyName System.Drawing
        $objFontCollection = New-Object System.Drawing.Text.PrivateFontCollection
        $objFontCollection.AddFontFile($item.FullName)
        $FontName = $objFontCollection.Families.Name

        Write-Log -Info -Message "Font {$($item.Name)} full name is {$FontName}"
        Write-Log -Info -Emphasize -Message "Copying font file {$($item.Name)} to system Folder {$objfontFolder}"
        $folder.CopyHere($item.FullName, $copyFlag)

        $regTest = Get-ItemProperty -Path $fontRegistryPath -Name "*$FontName*" -ErrorAction SilentlyContinue
        if (-not ($regTest)) {
          New-ItemProperty -Name $FontName -Path $fontRegistryPath -PropertyType string -Value $item.Name
          Write-Log -Info -Message "Registering font {$($item.Name)} in registry with name {$FontName}"
        }
      }
    }
  }
}
end {
}
