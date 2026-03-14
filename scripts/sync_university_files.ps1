Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$universitiesRoot = Join-Path $repoRoot "data\universities"

function Get-Slug {
    param([string]$Name)

    $slug = $Name.ToLowerInvariant()
    $slug = $slug -replace "[^a-z0-9]+", "-"
    $slug = $slug.Trim("-")
    return $slug
}

function Write-CsvFile {
    param(
        [string]$Path,
        [array]$Rows
    )

    $directory = Split-Path -Parent $Path
    if (-not (Test-Path $directory)) {
        $null = New-Item -ItemType Directory -Force -Path $directory
    }

    $csv = $Rows | ConvertTo-Csv -NoTypeInformation
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllLines($Path, $csv, $utf8NoBom)
}

$overview = @(Import-Csv (Join-Path $repoRoot "data\master\universities_overview.csv"))
$deadlines = @(Import-Csv (Join-Path $repoRoot "data\master\application_deadlines.csv"))
$documents = @(Import-Csv (Join-Path $repoRoot "data\master\required_documents.csv"))
$professors = @(Import-Csv (Join-Path $repoRoot "data\master\professors_master.csv"))
$templateDir = Join-Path $universitiesRoot "_template"

foreach ($university in $overview) {
    $slug = Get-Slug $university.university_name
    $targetDir = Join-Path $universitiesRoot $slug
    $null = New-Item -ItemType Directory -Force -Path $targetDir

    Write-CsvFile -Path (Join-Path $targetDir "university_info.csv") -Rows @($university)
    Write-CsvFile -Path (Join-Path $targetDir "deadlines.csv") -Rows @($deadlines | Where-Object { $_.university_name -eq $university.university_name })
    Write-CsvFile -Path (Join-Path $targetDir "required_documents.csv") -Rows @($documents | Where-Object { $_.university_name -eq $university.university_name })

    $professorRows = @($professors | Where-Object { $_.university_name -eq $university.university_name })
    if ($professorRows.Count -eq 0) {
        $professorRows = @(Import-Csv (Join-Path $templateDir "professors.csv"))
    }
    Write-CsvFile -Path (Join-Path $targetDir "professors.csv") -Rows $professorRows
}

Write-Output "University-level CSV files synchronized from master datasets."
