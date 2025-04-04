function Get-File {
    
    [CmdletBinding()]
    
    param (
        [Parameter(Mandatory = $true)]
        [string] $source,

        [Parameter(Mandatory = $true)]
        [string] $destination,

        # [Parameter(Mandatory = $true)]
        # [string] $fileName,

        [Parameter(Mandatory = $false)]
        [bool] $expandArchive = $false
    )

    $sourceFileName = $source.Split('/')[-1]
    $downloadPath = Join-Path -Path $destination -ChildPath $sourceFileName 

    # Download the file from web
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
        if ($fileName.EndsWith('.zip')) {
            try {
                $output = & { Expand-Archive -Path $downloadPath -Force -Verbose 4>&1 }
                $output | ForEach-Object {
                    if ($_ -match "Created '([^']+)'") {
                        $matches[1]
                    }
                }
                Write-Host "Archive expanded successfully to:"
                Write-Host $unzipPath -BackgroundColor Green -ForegroundColor White
                try {
                    Remove-Item -Path $downloadPath -Force
                    Write-Host "Archive file $downloadPath removed successfully."
                } catch {
                    Write-Host "Failed to remove archive file. Error:"
                    Write-Host $_.Exception.Message -BackgroundColor Red -ForegroundColor White
                }
            }
            catch {
                Write-Host "Failed to expand archive. Error:"
                Write-Host $_.Exception.Message -BackgroundColor Red -ForegroundColor White
                exit
            }
        } elseif ($fileName.EndsWith('.7z')) {
            # PLACEHOLD
        } else {
            Write-Host "File is not a supported archive format. No extraction performed." -BackgroundColor Red -ForegroundColor White
            exit
        }

    } else {
        Write-Host "Archive expansion skipped, not requested."
    }   

}


$env:source = "https://app.box.com/shared/static/n59f46wckc8yj8vi43cjgn96gfrnl0wm.zip"
$env:destination = "C:\Temp"
$env:fileName = "test.zip"
$env:expandArchive = $true

Get-File -source $env:source -destination $env:destination -fileName $env:fileName -expandArchive:$env:expandArchive