Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Escape-Xml {
    param([string]$Value)

    if ($null -eq $Value) {
        return ""
    }

    return [System.Security.SecurityElement]::Escape([string]$Value)
}

function Get-ColumnName {
    param([int]$Index)

    $name = ""
    while ($Index -gt 0) {
        $Index--
        $name = [char](65 + ($Index % 26)) + $name
        $Index = [math]::Floor($Index / 26)
    }
    return $name
}

function Get-SheetXml {
    param(
        [string]$CsvPath,
        [string]$SheetName
    )

    $rows = @(Import-Csv -Path $CsvPath)
    $headers = @()

    if ($rows.Count -gt 0) {
        $headers = @($rows[0].PSObject.Properties.Name)
    } else {
        $firstLine = Get-Content -Path $CsvPath -TotalCount 1
        if ($firstLine) {
            $headers = @($firstLine -split ",")
        }
    }

    $allRows = @()
    if ($headers.Count -gt 0) {
        $allRows += ,$headers
    }

    foreach ($row in $rows) {
        $values = @()
        foreach ($header in $headers) {
            $values += [string]$row.$header
        }
        $allRows += ,$values
    }

    $sheetData = New-Object System.Text.StringBuilder
    for ($r = 0; $r -lt $allRows.Count; $r++) {
        $rowNumber = $r + 1
        [void]$sheetData.Append("<row r=`"$rowNumber`">")

        $currentRow = $allRows[$r]
        for ($c = 0; $c -lt $currentRow.Count; $c++) {
            $cellRef = "$(Get-ColumnName ($c + 1))$rowNumber"
            $value = Escape-Xml $currentRow[$c]
            [void]$sheetData.Append("<c r=`"$cellRef`" t=`"inlineStr`"><is><t xml:space=`"preserve`">$value</t></is></c>")
        }

        [void]$sheetData.Append("</row>")
    }

    $dimensionEndColumn = if ($headers.Count -gt 0) { Get-ColumnName $headers.Count } else { "A" }
    $dimensionEndRow = if ($allRows.Count -gt 0) { $allRows.Count } else { 1 }
    $dimension = "A1:$dimensionEndColumn$dimensionEndRow"
    $safeSheetName = Escape-Xml $SheetName

    return @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <dimension ref="$dimension"/>
  <sheetViews>
    <sheetView workbookViewId="0"/>
  </sheetViews>
  <sheetFormatPr defaultRowHeight="15"/>
  <sheetData>$sheetData</sheetData>
  <pageMargins left="0.7" right="0.7" top="0.75" bottom="0.75" header="0.3" footer="0.3"/>
</worksheet>
"@
}

function Write-Utf8File {
    param(
        [string]$Path,
        [string]$Content
    )

    $directory = Split-Path -Parent $Path
    if ($directory -and -not (Test-Path $directory)) {
        $null = New-Item -ItemType Directory -Force -Path $directory
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

function New-XlsxFromCsvSet {
    param(
        [string]$OutputPath,
        [array]$Sheets
    )

    $tempRoot = Join-Path $env:TEMP ([System.Guid]::NewGuid().ToString())
    $null = New-Item -ItemType Directory -Path $tempRoot
    $null = New-Item -ItemType Directory -Path (Join-Path $tempRoot "_rels")
    $null = New-Item -ItemType Directory -Path (Join-Path $tempRoot "docProps")
    $null = New-Item -ItemType Directory -Path (Join-Path $tempRoot "xl")
    $null = New-Item -ItemType Directory -Path (Join-Path $tempRoot "xl\_rels")
    $null = New-Item -ItemType Directory -Path (Join-Path $tempRoot "xl\worksheets")

    $sheetEntries = New-Object System.Text.StringBuilder
    $workbookRels = New-Object System.Text.StringBuilder
    $contentTypes = New-Object System.Text.StringBuilder

    [void]$contentTypes.Append(@"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
  <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
"@)

    for ($i = 0; $i -lt $Sheets.Count; $i++) {
        $sheetId = $i + 1
        $sheetName = $Sheets[$i].Name
        $csvPath = $Sheets[$i].CsvPath
        $worksheetXml = Get-SheetXml -CsvPath $csvPath -SheetName $sheetName
        Write-Utf8File -Path (Join-Path $tempRoot "xl\worksheets\sheet$sheetId.xml") -Content $worksheetXml
        [void]$sheetEntries.Append("<sheet name=`"$(Escape-Xml $sheetName)`" sheetId=`"$sheetId`" r:id=`"rId$sheetId`"/>")
        [void]$workbookRels.Append("<Relationship Id=`"rId$sheetId`" Type=`"http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet`" Target=`"worksheets/sheet$sheetId.xml`"/>")
        [void]$contentTypes.Append("<Override PartName=`"/xl/worksheets/sheet$sheetId.xml`" ContentType=`"application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml`"/>")
    }

    [void]$contentTypes.Append("</Types>")
    Write-Utf8File -Path (Join-Path $tempRoot "[Content_Types].xml") -Content $contentTypes.ToString()

    Write-Utf8File -Path (Join-Path $tempRoot "_rels\.rels") -Content @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>
"@

    Write-Utf8File -Path (Join-Path $tempRoot "docProps\core.xml") -Content @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <dc:creator>Codex</dc:creator>
  <cp:lastModifiedBy>Codex</cp:lastModifiedBy>
  <dcterms:created xsi:type="dcterms:W3CDTF">2026-03-14T00:00:00Z</dcterms:created>
  <dcterms:modified xsi:type="dcterms:W3CDTF">2026-03-14T00:00:00Z</dcterms:modified>
</cp:coreProperties>
"@

    Write-Utf8File -Path (Join-Path $tempRoot "docProps\app.xml") -Content @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">
  <Application>Codex</Application>
</Properties>
"@

    Write-Utf8File -Path (Join-Path $tempRoot "xl\workbook.xml") -Content @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheets>$sheetEntries</sheets>
</workbook>
"@

    Write-Utf8File -Path (Join-Path $tempRoot "xl\_rels\workbook.xml.rels") -Content @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  $workbookRels
</Relationships>
"@

    if (Test-Path $OutputPath) {
        Remove-Item -Path $OutputPath -Force
    }

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory($tempRoot, $OutputPath)
    Remove-Item -Path $tempRoot -Recurse -Force
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$excelRoot = Join-Path $repoRoot "excel"
$universityExcelRoot = Join-Path $excelRoot "universities"

$null = New-Item -ItemType Directory -Force -Path $excelRoot
$null = New-Item -ItemType Directory -Force -Path $universityExcelRoot

$masterSheets = @(
    @{ Name = "Overview"; CsvPath = (Join-Path $repoRoot "data\master\universities_overview.csv") },
    @{ Name = "Deadlines"; CsvPath = (Join-Path $repoRoot "data\master\application_deadlines.csv") },
    @{ Name = "Documents"; CsvPath = (Join-Path $repoRoot "data\master\required_documents.csv") },
    @{ Name = "Professors"; CsvPath = (Join-Path $repoRoot "data\master\professors_master.csv") }
)

New-XlsxFromCsvSet -OutputPath (Join-Path $excelRoot "finland_universities_master.xlsx") -Sheets $masterSheets

$universityDirs = Get-ChildItem -Path (Join-Path $repoRoot "data\universities") -Directory |
    Where-Object { $_.Name -ne "_template" } |
    Sort-Object Name

foreach ($dir in $universityDirs) {
    $sheets = @(
        @{ Name = "UniversityInfo"; CsvPath = (Join-Path $dir.FullName "university_info.csv") },
        @{ Name = "Deadlines"; CsvPath = (Join-Path $dir.FullName "deadlines.csv") },
        @{ Name = "Documents"; CsvPath = (Join-Path $dir.FullName "required_documents.csv") },
        @{ Name = "Professors"; CsvPath = (Join-Path $dir.FullName "professors.csv") }
    )

    New-XlsxFromCsvSet -OutputPath (Join-Path $universityExcelRoot "$($dir.Name).xlsx") -Sheets $sheets
}

Write-Output "Generated Excel workbooks in $excelRoot"
