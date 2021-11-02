$path = Join-Path $PSScriptRoot ".."

$replaceValues = @{
    "00000000-0000-0000-0000-000000000001" = [Guid]::NewGuid().ToString()
    "00000000-0000-0000-0000-000000000002" = [Guid]::NewGuid().ToString()
    "Default Publisher" = "My Publisher"
    "Default App Name" = "My App Name"
    "Default Test App Name" = "My Test App Name"
}

function ReplaceProperty { Param ($object, $property)
    if ($object.PSObject.Properties.name -eq $property) {
        $str = "$($object."$property")"
        if ($replaceValues.ContainsKey($str)) {
            Write-Host "- change $property from $str to $($replaceValues[$str]) "
            $object."$property" = $replaceValues[$str]
        }
    }
}

function ReplaceObject { Param($object)
    "id", "appId", "name", "publisher", "version", "appSourceCopMandatoryAffixes", "appSourceCopSupportedCountries","from","to" | ForEach-Object {
        ReplaceProperty -object $object -property $_
    }
}

Get-ChildItem -Path $path | Where-Object { $_.psIsContainer -and $_.Name -notlike ".*" } | Get-ChildItem -Recurse -filter "app.json" | ForEach-Object {
    $appJsonFile = $_.FullName
    $appJson = Get-Content $appJsonFile | ConvertFrom-Json
    Write-Host -ForegroundColor Yellow $appJsonFile
    ReplaceObject -object $appJson
    Write-Host "Check idRanges"
    $appJson.idRanges | ForEach-Object { ReplaceObject($_) }
    Write-Host "Check Dependencies"
    $appJson.dependencies | ForEach-Object { ReplaceObject($_) }
    $appJson | ConvertTo-Json -Depth 10 | Set-Content $appJsonFile
}

$settingsFile = Join-Path $PSScriptRoot "settings.json"
$settings = Get-Content $settingsFile | ConvertFrom-Json
Write-Host -ForegroundColor Yellow $settingsFile
ReplaceObject -object $settings
$settings | ConvertTo-Json -Depth 10 | Set-Content $settingsFile
