function Get-File {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $source,

        [Parameter(Mandatory = $true)]
        [string] $destination,

        [Parameter(Mandatory = $true)]
        [string] $fileName,

        [Parameter(Mandatory = $true)]
        [bool] $expandArchive
    )

    $outFile = Join-Path -Path $destination -ChildPath $fileName

    try {
        Invoke-WebRequest -Uri $source -OutFile $outFile -ErrorAction Stop
        Write-Host "File downloaded successfully to $outFile"
    }
    catch {
        Write-Host "Failed to download file. Error: $_"
        exit
    }
    
    if ($expandArchive) {
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
$env:fileName = "test.zip"

Get-File -source $env:source -destination $env:destination -expandArchive $true -fileName $env:fileName