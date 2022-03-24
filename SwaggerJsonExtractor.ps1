param (
    [Parameter(Mandatory = $false,ValueFromPipeline=$true)]
    [string]
    $SwaggerJsonString = $null,
    [Parameter(Mandatory = $false)]
    [string]
    $InputPath = $null,
    [Parameter(Mandatory = $false)]
    [string]
    $OutputPath = $null,
    [Parameter(Mandatory = $true)]
    [array]
    $PathsToExtract,
    [Parameter(Mandatory = $false)]
    [bool]
    $CompressOutputJson = $false,
    [Parameter(Mandatory = $false)]
    [bool]
    $SuppressClipboardOutput = $false,
    [Parameter(Mandatory = $false)]
    [bool]
    $SuppressConsoleOutput = $false
)

function Main {
    
    $swaggerJsonRaw = ""
    if([string]::IsNullOrWhiteSpace($SwaggerJsonString)){
        $swaggerJsonRaw = $SwaggerJsonString
    }
    elseif ([string]::IsNullOrWhiteSpace($InputPath)) {
        Write-Output "No InputPath provided - reading from clipboard"
        $swaggerJsonRaw = Get-Clipboard
    }
    else {
        $swaggerJsonRaw = Get-Content -Path $InputPath
    }

    try {
        $swaggerJson = $swaggerJsonRaw | ConvertFrom-Json
    }
    catch {
        Write-Error "Invalid JSON provided"
        exit "Invalid JSON provided"
    }

    $resultJsonObject = [PSCustomObject]@{
        openapi    = $swaggerJson.openapi
        info       = $swaggerJson.info
        paths      = [PSCustomObject]@{}
        components = [PSCustomObject]@{schemas = [PSCustomObject]@{} }
    }

    $schemasToBeTransfered = @{}
    $schemasMentionedInPaths = @{}
    $PathsToExtract = $PathsToExtract | Get-Unique
    $schemaRegEx = ([regex]'"\$ref":[ ]*"#\/components\/schemas\/[^"]*"')

    foreach ($path in $PathsToExtract) {
        $pathInfo = $null
        $pathInfo = $swaggerJson.paths.$path
        if ($null -eq $pathInfo) {
            Write-Warning "$path not found - SKIPPING"
            continue
        }
        $resultJsonObject.paths | Add-Member -MemberType NoteProperty -Name $path -Value $pathInfo
        $schemasFromPathInfosRaw = [array] $schemaRegEx.Matches(($pathInfo | ConvertTo-Json -Depth 99 -Compress)).value
        if ($null -ne $schemasFromPathInfosRaw) {
            $schemasFromPathInfos = [array] $schemasFromPathInfosRaw | % { $_.Replace('"$ref":"#/components/schemas/', "").Replace('"', "") }
        }
        foreach ($schemasFromPathInfo in $schemasFromPathInfos) {
            if (!$schemasMentionedInPaths.ContainsKey($schemasFromPathInfo)) {
                $schemasMentionedInPaths.Add($schemasFromPathInfo, $schemasFromPathInfo)
            }
        }
    }

    foreach ($schema in $schemasMentionedInPaths.Keys) {
        if (!$schemasToBeTransfered.ContainsKey($schema)) {
            $schemasToBeTransfered.Add($schema, $schema)
        }

        $schemaBody = $null
        $schemaBody = $swaggerJson.components.schemas.$schema
        if ($null -ne $schemaBody) {
            $schemasFromSchemaBodyRaw = [array] $schemaRegEx.Matches(($schemaBody | ConvertTo-Json -Depth 99 -Compress)).value
            if ($null -ne $schemasFromSchemaBodyRaw) {
                $schemasFromSchemaBody = [array] $schemasFromSchemaBodyRaw | % { $_.Replace('"$ref":"#/components/schemas/', "").Replace('"', "") }
            }
        }

        foreach ($schemaFromSchemaBody in $schemasFromSchemaBody) {
            if (!$schemasToBeTransfered.ContainsKey($schemaFromSchemaBody)) {
                $schemasToBeTransfered.Add($schemaFromSchemaBody, $schemaFromSchemaBody)
            }
        }
    }

    foreach ($schema in $schemasToBeTransfered.Keys) {
        $schemaBody = $null
        $schemaBody = $swaggerJson.components.schemas.$schema
        if ($null -ne $schemaBody) {
            $resultJsonObject.components.schemas | Add-Member -MemberType NoteProperty -Name $schema -Value $schemaBody
        }
        else {
            Write-Warning "$schema was not found - SKIPPING"
        }
    }

    $resultJson = $resultJsonObject | ConvertTo-Json -Depth 99 -Compress:$CompressOutputJson
    if (!$SuppressClipboardOutput) {
        $resultJson | Set-Clipboard
    }
    if (!$SuppressConsoleOutput) {
        Write-Output $resultJson
    }
    if (![string]::IsNullOrWhiteSpace($OutputPath)) {
        $resultJson | Out-File -FilePath $OutputPath -NoClobber
    }

}

Main