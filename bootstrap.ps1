# bootstrap.ps1
# Script d'installation "Zero-Install" pour Windows
# Usage: irm https://raw.githubusercontent.com/nnosal/nix-dotfiles5/main/bootstrap.ps1 | iex

$ErrorActionPreference = "Stop"

# ============================================
# CONFIGURATION
# ============================================
$RepoUrl = "https://github.com/nnosal/nix-dotfiles5.git"
$DotfilesDir = "$env:USERPROFILE\dotfiles"

# ============================================
# FONCTIONS
# ============================================
function Write-Info { param($Message) Write-Host "ℹ️  $Message" -ForegroundColor Blue }
function Write-Success { param($Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Warning { param($Message) Write-Host "⚠️  $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "❌ $Message" -ForegroundColor Red }

# ============================================
# BANNIÈRE
# ============================================
Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  🚀 ULTIMATE DOTFILES - WINDOWS SETUP" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# ============================================
# VÉRIFICATION ADMIN
# ============================================
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Warning "Ce script nécessite les droits administrateur pour certaines opérations."
    Write-Info "Relancez PowerShell en tant qu'Administrateur si nécessaire."
}

# ============================================
# INSTALLATION DE WINGET (si manquant)
# ============================================
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Info "Installation de Winget..."
    # Winget est normalement pré-installé sur Windows 11
    Write-Warning "Winget non trouvé. Installez l'App Installer depuis le Microsoft Store."
    Start-Process "ms-windows-store://pdp/?productid=9NBLGGH4NNS1"
    Read-Host "Appuyez sur Entrée une fois Winget installé"
}

# ============================================
# INSTALLATION DE MISE
# ============================================
if (-not (Get-Command mise -ErrorAction SilentlyContinue)) {
    Write-Info "Installation de Mise via Winget..."
    winget install --id jdx.mise --accept-package-agreements --accept-source-agreements
    
    # Ajouter au PATH pour cette session
    $env:PATH = "$env:LOCALAPPDATA\Programs\mise;$env:PATH"
}

Write-Success "Mise installé"

# ============================================
# INSTALLATION DE GIT
# ============================================
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Info "Installation de Git via Winget..."
    winget install --id Git.Git --accept-package-agreements --accept-source-agreements
    
    # Rafraîchir le PATH
    $env:PATH = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

Write-Success "Git installé"

# ============================================
# CLONAGE DU REPO
# ============================================
if (Test-Path $DotfilesDir) {
    Write-Warning "Le dossier $DotfilesDir existe déjà"
    $update = Read-Host "Mettre à jour (git pull) ? (O/n)"
    if ($update -ne "n") {
        Set-Location $DotfilesDir
        git pull
    }
} else {
    Write-Info "Clonage du repo..."
    git clone $RepoUrl $DotfilesDir
}

Set-Location $DotfilesDir

# ============================================
# INSTALLATION DES TOOLS VIA MISE
# ============================================
Write-Info "Installation des outils via Mise..."

# Trouver le fichier windows.toml du gaming-rig ou utiliser mise.toml
$windowsConfig = "hosts\perso\gaming-rig\windows.toml"
if (Test-Path $windowsConfig) {
    Write-Info "Application de la config Windows..."
    mise install --config $windowsConfig
} else {
    mise install
}

# ============================================
# INSTALLATION WSL (optionnel)
# ============================================
$installWsl = Read-Host "Installer WSL2 pour le terminal Linux ? (O/n)"
if ($installWsl -ne "n") {
    Write-Info "Installation de WSL2..."
    wsl --install -d Ubuntu
    Write-Success "WSL2 installé. Redémarrez pour finaliser."
}

# ============================================
# FIN
# ============================================
Write-Host ""
Write-Success "Installation Windows terminée !"
Write-Host ""
Write-Host "Prochaines étapes:" -ForegroundColor Cyan
Write-Host "  1. Redémarrez si WSL a été installé"
Write-Host "  2. Ouvrez WSL et lancez le bootstrap Linux:"
Write-Host "     sh <(curl -L https://raw.githubusercontent.com/nnosal/nix-dotfiles5/main/bootstrap.sh)"
Write-Host ""
