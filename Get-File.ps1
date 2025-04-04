function Get-File {

    [CmdletBinding()]

    param (
        [Parameter(Mandatory = $true)]
        [string] $source,

        [Parameter(Mandatory = $true)]
        [string] $destination,

        [Parameter(Mandatory = $false)]
        [switch] $expandArchive
    )

    $sourceFileName = $source.Split('/')[-1]
    $downloadPath = Join-Path -Path $destination -ChildPath $sourceFileName 

    # Download using Invoke-WebRequest
    try {
        Invoke-WebRequest -Uri $source -OutFile $downloadPath
    } catch {
        Write-Host "Failed to download file. Error:"
        Write-Host $_.Exception.Message -BackgroundColor Red -ForegroundColor White
        exit
    }

    if (Test-Path -Path $downloadPath) {
        Write-Host "File downloaded successfully to:"
        Write-Host $downloadPath -BackgroundColor Green -ForegroundColor White
    } else {
        Write-Host "File download failed. File not found at $downloadPath" -BackgroundColor Red -ForegroundColor White
        exit
    }

    # Expand the archive if requested
    if ($expandArchive) {
        
        # ZIP files
        if ($sourceFileName.EndsWith('.zip')) {
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
        } elseif ($sourceFileName.EndsWith('.7z')) {

            # Install 7Zip4PowerShell module if not already installed
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
            # Import the module explicitly.
            try {
                Import-Module 7Zip4PowerShell -ErrorAction Stop
            }
            catch {
                Write-Host "Failed to import 7Zip4PowerShell module."
                Write-Host $_.Exception.Message -BackgroundColor Red -ForegroundColor White
                exit
            }
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
            Write-Host "File is not a supported archive format. No extraction performed." -BackgroundColor Red -ForegroundColor White
        }

    } else {
        Write-Host "Archive expansion skipped, not requested."
    }

}


$env:source = "https://app.box.com/shared/static/ofhhniqj9qvz42jz7177poirt2mnmlm2.7z"
$env:destination = "C:\Temp"
[bool] $env:expandArchive = $true

Get-File -source $env:source -destination $env:destination -expandArchive:([bool]$env:expandArchive)