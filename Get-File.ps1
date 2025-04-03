function Get-File {
    
    [CmdletBinding()]
    
    param (
        [Parameter(Mandatory = $true)]
        [string] $source,

        [Parameter(Mandatory = $true)]
        [string] $destination,

        [Parameter(Mandatory = $false)]
        [bool] $expandArchive = $true
    )

    try {
        Invoke-WebRequest -Uri $source -PassThru -ErrorAction Stop | Tee-Object -Variable response
        $fileName = $response.headers.'Content-Disposition' -replace '.*filename="([^"]+)".*', '$1'
        $downloadPath = Join-Path -Path $destination -ChildPath $fileName
        if (Test-Path -Path $downloadedPath) {
        Write-Host "File downloaded successfully to $downloadPath"
        }
    } catch {
        Write-Host "Failed to download file. Error: $_"
        exit
    }
    
    if ($expandArchive) {
        if ($fileName.EndsWith('.zip')) {
            try {
                Expand-Archive -LiteralPath $downloadPath -DestinationPath $destination -Force -ErrorAction Stop -Force -Verbose 4>&1 | 
                Select-String -Pattern "Created '(.+)'" | 
                Get-Item -Path { $_.Matches.Groups[1].Value } | select -ExpandProperty FullName | forEach-Object {
                    $unzipPath = $_
                }
                Write-Host "Archive expanded successfully to $unzipPath"
                Remove-Item -Path $outFile -Force
                Write-Host "Removed archive file $outFile"
            }
            catch {
                Write-Host "Failed to expand archive. Error: $_"
                exit
            }
        } elseif ($fileName.EndsWith('.7z')) {
            # PLACEHOLD
        } else {
            Write-Host "File is not a supported archive format. No extraction performed."
        }

    }

}


$env:source = "https://app.box.com/shared/static/xcuil54m9ptqs2m59t69y4y1dama4nc2.jpg"
$env:destination = "C:\Temp"

Get-File -source $env:source -destination $env:destination -expandArchive $true