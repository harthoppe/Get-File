function Get-File {

    [CmdletBinding()]

    param (
        [Parameter(Mandatory = $true)]
        [string] $Source,

        [Parameter(Mandatory = $true)]
        [string] $Destination,

        [Parameter(Mandatory = $false)]
        [switch] $SkipUnzip,

        [Parameter(Mandatory = $false)]
        [switch] $SkipDownload
    )

    function Get-SourceType {
        if ($source.StartsWith("\\")) {
            $global:sourceType = "UNC"
            Write-Host `n"Source is a UNC path..."
        } elseif ($source.StartsWith("http")) {
            $global:sourceType = "URL"
            Write-Host `n"Source is a URL..."
        } else {
            $sourceType = "Unknown"
            Write-Host `n"Source type is unknown. Please check the source address." -BackgroundColor Red -ForegroundColor White
            exit
        }
    }
    
    function Test-Download {
        if (Test-Path -Path $downloadPath) {
            Write-Host `n"File downloaded successfully to:"
            Write-Host $downloadPath -BackgroundColor Green -ForegroundColor White
        } else {
            Write-Host `n"File download failed. File not found at $downloadPath" -BackgroundColor Red -ForegroundColor White
            exit
        }
    }

    function Install-7zip4Powershell {
        if (-not (Get-Module -ListAvailable -Name 7Zip4PowerShell)) {
            try {
                Write-Host `n"7Zip4PowerShell module not found. Installing..."
                Install-Module -Name 7Zip4PowerShell -Scope CurrentUser -Force -ErrorAction Stop
            }
            catch {
                Write-Host `n"Failed to install 7Zip4PowerShell module."
                Write-Host $_.Exception.Message -BackgroundColor Red -ForegroundColor White
                exit
            }
        }
        try {
            Import-Module 7Zip4PowerShell -ErrorAction Stop
        }
        catch {
            Write-Host `n"Failed to import 7Zip4PowerShell module."
            Write-Host $_.Exception.Message -BackgroundColor Red -ForegroundColor White
            exit
        }
    }

    function Expand-ArchiveAdvanced {
        
        param (
            [Parameter(Mandatory = $false)]
            [switch] $Zip,

            [Parameter(Mandatory = $false)]
            [switch] $SevenZip
        )
        
        Write-Host `n"Expanding archive..."
        try {
            if ($Zip) {
                $output = & { Expand-Archive -LiteralPath $downloadPath -DestinationPath $Destination -Force -Verbose 4>&1 }
                $createdPaths = @($output | ForEach-Object {
                    if ($_ -match "Created '([^']+)'") {
                        $matches[1]
                    }
                })
            } elseif ($SevenZip) {
                Install-7zip4Powershell
                $output = & { Expand-7Zip -ArchiveFileName $downloadPath -TargetPath $destination -ErrorAction Stop -Verbose 4>&1 }
                $createdPaths = @($output | ForEach-Object {
                    if ($_ -match 'Extracting file "([^"]+)"') {
                        $matches[1]
                    }
                })
            }
        } catch {
                Write-Host `n"Failed to expand archive. Error:"
                Write-Host $_.Exception.Message -BackgroundColor Red -ForegroundColor White
                exit
        }
        
        # Print the paths of the created files/folders
        Write-Host `n"Extracted:"
        foreach ($path in $createdPaths) {
                Write-Host $path -BackgroundColor Green -ForegroundColor White
        }

        # Remove the original archive file
        try {
            Remove-Item -Path $downloadPath -Force
            Write-Host `n"Removed archive file:"`n
            Write-Host $downloadPath
        } catch {
            Write-Host `n"Failed to remove archive file:"`n
            Write-Host $downloadPath
            Write-Host "Error:"
            Write-Host $_.Exception.Message -BackgroundColor Red -ForegroundColor White
        }
    }

    ###########################################################################
    ############################ MAIN SCRIPT LOGIC ############################
    ###########################################################################


    Get-SourceType

    # Extract the file name
    if ($sourceType -eq "UNC") {
        $fileName = $source.Split('\')[-1]
    } elseif ($sourceType -eq "URL") {
        $fileName = $source.Split('/')[-1]
    }
    Write-Host "`nFile name extracted:"
    Write-Host $fileName

    # Set the download path
    if (Test-Path $Destination) {
        $downloadPath = Join-Path -Path $destination -ChildPath $fileName
    } else {
        Write-Host "`nDestination path does not exist." -BackgroundColor Red -ForegroundColor White
        exit
    }
    Write-Host "`nDownload path set to:"
    Write-Host $downloadPath

    # Download
    if ($true -eq $SkipDownload) {
        Write-Host "`nDownload skipped as requested."
    } else {
        if ($sourceType -eq "UNC") {
            # Download using Start-BitsTransfer
            try {
                Write-Host "`nDownloading using 'Start-BitsTransfer'..."
                Start-BitsTransfer -Source $source -Destination $downloadPath -ErrorAction Stop
                Test-Download
            } catch {
                Write-Host "`nFailed to download file using 'Start-BitsTransfer'. Error:"
                Write-Host $_.Exception.Message -BackgroundColor Red -ForegroundColor White
            }
        } elseif ($sourceType -eq "URL") {
            # Download using Invoke-WebRequest
            try {
                Write-Host "`nDownloading using 'Invoke-WebRequest'..."
                Invoke-WebRequest -Uri $source -OutFile $downloadPath
                Test-Download
            } catch {
                Write-Host "`nFailed to download file using 'Invoke-WebRequest'. Error:"
                Write-Host $_.Exception.Message -BackgroundColor Red -ForegroundColor White
                Write-Host "Please check the source address and try again."
                exit
            }
        }
    }

    # Unzip the file
    if ($false -eq $SkipUnzip) {
        if ($fileName.EndsWith('.zip')) {
            Expand-ArchiveAdvanced -Zip
        } elseif ($fileName.EndsWith('.7z')) {
            Expand-ArchiveAdvanced -SevenZip
        } else {
            Write-Host "`nFile is not a supported archive format. No extraction performed." -BackgroundColor Yellow -ForegroundColor White
        }
    } else {
        Write-Host "`nUnzip is skipped as requested."
    }

}

# Example usage:
# Get-File -Source "\\server\share\file.zip" -Destination "C:\Temp" -SkipUnzip
# Get-File -Source "https://example.com/file.zip" -Destination "C:\Temp" -SkipDownload

# Command syntax built for NinjaOne "Get-File" script specifically, to interact with the passed in environment variables. COmment out if using outside of this conectxt.
# Get-File -Source $env:source -Destination $env:destination -SkipUnzip:$env:skipUnzip -SkipDownload:$env:skipDownload

# TESTING
# Get-File -Source "https://app.box.com/shared/static/pnukv1ny2qs2tt4tqdoltdsq3x0w8f6j.7z" -Destination "C:\Temp"
Get-File -Source "https://app.box.com/shared/static/1pl6v4gdavxvlwx13ab77uo1piuf8wbw.zip" -Destination "C:\Temp"