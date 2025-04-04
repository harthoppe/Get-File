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

    function Test-Download {
        if (Test-Path -Path $downloadPath) {
            Write-Host "File downloaded successfully to:"
            Write-Host $downloadPath -BackgroundColor Green -ForegroundColor White
        } else {
            Write-Host "File download failed. File not found at $downloadPath" -BackgroundColor Red -ForegroundColor White
            exit
        }
    }

    function Install-7zip4Powershell {
        if (-not (Get-Module -ListAvailable -Name 7Zip4PowerShell)) {
            try {
                Write-Host "7Zip4PowerShell module not found. Installing..."
                Install-Module -Name 7Zip4PowerShell -Scope CurrentUser -Force -ErrorAction Stop
            }
            catch {
                Write-Host "Failed to install 7Zip4PowerShell module."
                Write-Host $_.Exception.Message -BackgroundColor Red -ForegroundColor White
                exit
            }
        }
        try {
            Import-Module 7Zip4PowerShell -ErrorAction Stop
        }
        catch {
            Write-Host "Failed to import 7Zip4PowerShell module."
            Write-Host $_.Exception.Message -BackgroundColor Red -ForegroundColor White
            exit
        }
    }

    function Expand-ArchiveAdvanced {
        # ZIP files
        if ($fileName.EndsWith('.zip')) {
            try {
                $output = & { Expand-Archive -Path $downloadPath -Force -Verbose 4>&1 }
                $createdPaths = @($output | ForEach-Object {
                    if ($_ -match "Created '([^']+)'") {
                        $matches[1]
                    }
                })
                Write-Host "Archive expanded..."
                foreach ($path in $createdPaths) {
                    if (Test-Path -Path $path) {
                        Write-Host "Created:"
                        Write-Host $path -BackgroundColor Green -ForegroundColor White
                    } else {
                        Write-Host "Failed to find:"
                        Write-Host $path -BackgroundColor Red -ForegroundColor White
                    }
                }
                # Remove the original archive file
                try {
                    Remove-Item -Path $downloadPath -Force
                    Write-Host "Removed archive file:"
                    Write-Host $downloadPath
                } catch {
                    Write-Host "Failed to remove archive file:"
                    Write-Host $downloadPath
                    Write-Host "Error:"
                    Write-Host $_.Exception.Message -BackgroundColor Red -ForegroundColor White
                }
            } catch {
                Write-Host "Failed to expand archive. Error:"
                Write-Host $_.Exception.Message -BackgroundColor Red -ForegroundColor White
                exit
            }
       
        # 7z files            
        } elseif ($fileName.EndsWith('.7z')) {
            Install-7zip4Powershell
            # Expand the 7z archive
            try {
                $output = & { Expand-7Zip -ArchiveFileName $downloadPath -TargetPath $destination -ErrorAction Stop -Verbose 4>&1 }
                $createdPaths = @($output | ForEach-Object {
                    if ($_ -match 'Extracting file "([^"]+)"') {
                        $matches[1]
                    }
                })
                Write-Host "Archive expanded..."
                foreach ($path in $createdPaths) {
                    $fullPath = Join-Path -Path $destination -ChildPath $path
                    if (Test-Path -Path $fullPath) {
                        Write-Host "Created:"
                        Write-Host $fullPath -BackgroundColor Green -ForegroundColor White
                    } else {
                        Write-Host "Failed to find:"
                        Write-Host $fullPath -BackgroundColor Red -ForegroundColor White
                    }
                }
                # Remove the original archive file
                try {
                    Remove-Item -Path $downloadPath -Force
                    Write-Host "Removed orginal archive file:"
                    Write-Host $downloadPath -BackgroundColor Yellow -ForegroundColor White
                } catch {
                    Write-Host "Failed to remove archive file:"
                    Write-Host $downloadPath
                    Write-Host "Error:"
                    Write-Host $_.Exception.Message -BackgroundColor Red -ForegroundColor White
                }
            } catch {
                Write-Host "Failed to expand 7z archive. Error:"
                Write-Host $_.Exception.Message -BackgroundColor Red -ForegroundColor White
                exit
            }
        } else {
            Write-Host "File is not a supported archive format. No extraction performed." -BackgroundColor Yellow -ForegroundColor White
        }

    } else {
        Write-Host "Unzip skipped as requested."
    }

    # Extract the file name from the source URL or UNC and create the full download path
    if ($source.StartsWith("\\")) {
        Write-Host "Source is a UNC path..."
        $fileName = $source.Split('\')[-1]
    } else {
        Write-Host "Source is a URL..."
        $fileName = $source.Split('/')[-1]
    }
    $downloadPath = Join-Path -Path $destination -ChildPath $fileName 

    # Download using Start-BitsTransfer
    if ($false -eq $SkipDownload) {
        try {
            # Download using Start-BitsTransfer
            Start-BitsTransfer -Source $source -Destination $downloadPath -ErrorAction Stop
            Test-Download
        } catch {
            Write-Host "Failed to download file using 'Start-BitsTransfer'. Error:"
            Write-Host $_.Exception.Message -BackgroundColor Red -ForegroundColor White
        }

    } else {
        Write-Host "Download skipped as requested."
    }

    # Download using Invoke-WebRequest
    if ($false -eq $SkipDownload) {
        try {
            Write-Host "Retrying download using 'Invoke-WebRequest'..."
            Invoke-WebRequest -Uri $source -OutFile $downloadPath
            Test-Download
        } catch {
            Write-Host "Failed to download file using 'Invoke-WebRequest'. Error:"
            Write-Host $_.Exception.Message -BackgroundColor Red -ForegroundColor White
            Write-Host "Please check the source address and try again."
            exit
        }
    } else {
        Write-Host "Download skipped as requested."
    }

    # Unzip the file if not skipped
    if ($false -eq $SkipUnzip) {
        Expand-ArchiveAdvanced
    } else {
        Write-Host "Unzip skipped as requested."
    }
}

$env:source = "https://app.box.com/shared/static/ofhhniqj9qvz42jz7177poirt2mnmlm2.7z"
$env:destination = "C:\Temp"

Get-File -Source $env:source -Destination $env:destination -SkipUnzip:$false -SkipDownload:$false