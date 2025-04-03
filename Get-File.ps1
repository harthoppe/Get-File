function Get-File {
    
    [CmdletBinding()]
    
    param (
        [Parameter(Mandatory = $true)]
        [string] $source,

        [Parameter(Mandatory = $true)]
        [string] $destination,

        [Parameter(Mandatory = $true)]
        [string] $fileName,

        [Parameter(Mandatory = $false)]
        [bool] $expandArchive = $true
    )

    try {
        $downloadPath = Join-Path -Path $destination -ChildPath $fileName
        Invoke-WebRequest -Uri $source -OutFile $downloadPath -ErrorAction Stop
        if (Test-Path -Path $downloadPath) {
        Write-Host "File downloaded successfully to $downloadPath"
        }
    } catch {
        Write-Host "Failed to download file. Error: $_"
        exit
    }
    
    if ($expandArchive) {
        if ($fileName.EndsWith('.zip')) {
            try {
                Expand-Archive -LiteralPath $downloadPath -DestinationPath $destination -ErrorAction Stop -Force -Verbose 4>&1 | 
                Select-String -Pattern "Created '(.+)'" | 
                Get-Item -Path { $_.Matches.Groups[1].Value } | select -ExpandProperty FullName | forEach-Object {
                    $unzipPath = $_
                }
                Write-Host "Archive expanded successfully to $unzipPath"
                Remove-Item -Path $downloadPath -Force
                Write-Host "Removed archive file $downloadPath"
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


$env:source = "https://app.box.com/s/ywhkw8q9b1quqzbqn08k5z59miolrzz0"
$env:destination = "C:\Temp"
$env:fileName = "test.zip"

Get-File -source $env:source -destination $env:destination -fileName $env:fileName -expandArchive $true