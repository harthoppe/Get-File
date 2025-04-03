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
    
    if ($expandArchive -and $fileName -match '\.zip$') {
        try {
            Expand-Archive -LiteralPath $outFile -DestinationPath $destination -Force -ErrorAction Stop
            Write-Host "Archive expanded successfully to $destination"
            Remove-Item -Path $outFile -Force
            Write-Host "Removed archive file $outFile"
        }
        catch {
            Write-Host "Failed to expand archive. Error: $_"
            exit
        }
    }

}


$env:source = "https://app.box.com/shared/static/xcuil54m9ptqs2m59t69y4y1dama4nc2.jpg"
$env:destination = "C:\Temp"

Get-File -source $env:source -destination $env:destination -expandArchive $true