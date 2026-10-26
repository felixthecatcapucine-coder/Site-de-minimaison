# Recompile le site web de Mini Maisons et prépare le paquet pour Vercel :
#   vercel\site\                    le site prêt à mettre en ligne
#   vercel\MiniMaisons-vercel.zip   le même site, en un seul fichier
#
# Utilisation (depuis le dossier du projet, avec Flutter dans le PATH) :
#   powershell -ExecutionPolicy Bypass -File vercel\preparer_vercel.ps1
#   (ajoute -SansCompiler pour réutiliser le dernier build\web)

param([switch]$SansCompiler)

$ErrorActionPreference = 'Stop'
$projet = Split-Path -Parent $PSScriptRoot
$dossier = Join-Path $projet 'vercel'
$site = Join-Path $dossier 'site'
$zip = Join-Path $dossier 'MiniMaisons-vercel.zip'

Set-Location $projet
if (-not $SansCompiler) {
    # Le site est servi à la racine de l'adresse Vercel.
    flutter build web --release --base-href /
    if ($LASTEXITCODE -ne 0) { throw 'La compilation du site a échoué.' }
}

# Le site compilé, plus les réglages Vercel et le mode d'emploi.
if (Test-Path $site) { Remove-Item $site -Recurse -Force }
Copy-Item (Join-Path $projet 'build\web') $site -Recurse
Copy-Item (Join-Path $dossier 'vercel.json') $site
Copy-Item (Join-Path $dossier 'LISEZ-MOI-VERCEL.txt') $site
# Fichier interne de Flutter, inutile en ligne.
Remove-Item (Join-Path $site '.last_build_id') -ErrorAction SilentlyContinue

# Le zip est écrit avec des « / » dans les chemins (Compress-Archive met des
# « \ », que les Mac et Linux ne comprennent pas).
if (Test-Path $zip) { Remove-Item $zip -Force }
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::Open($zip, 'Create')
try {
    $racine = (Resolve-Path $site).Path
    Get-ChildItem $racine -Recurse -File | ForEach-Object {
        $nom = $_.FullName.Substring($racine.Length + 1).Replace('\', '/')
        [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
            $archive, $_.FullName, $nom, 'Optimal')
    }
} finally {
    $archive.Dispose()
}
$taille = [math]::Round((Get-Item $zip).Length / 1MB, 1)
Write-Host "Paquet Vercel prêt : $zip ($taille Mo)"
