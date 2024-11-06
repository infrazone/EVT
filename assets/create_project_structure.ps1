# PowerShell Script for GitHub Repository Creation and Folder Structure Setup

# Function to check if GitHub CLI is installed
function Test-GitHubCLI {
    try {
        $null = Get-Command gh -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

# Function to check if git is installed
function Test-Git {
    try {
        $null = Get-Command git -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

# Function to check GitHub CLI authentication status
function Test-GitHubAuth {
    $status = gh auth status 2>&1
    return $LASTEXITCODE -eq 0
}

# Main script execution starts here
Write-Host "🚀 Starting GitHub Repository and Folder Structure Setup..." -ForegroundColor Cyan

# Check if Git is installed
if (-not (Test-Git)) {
    Write-Host "❌ Git is not installed. Please install Git and try again." -ForegroundColor Red
    Write-Host "Download Git from: https://git-scm.com/downloads" -ForegroundColor Yellow
    exit 1
}

# Check if GitHub CLI is installed
if (-not (Test-GitHubCLI)) {
    Write-Host "❌ GitHub CLI is not installed. Please install GitHub CLI and try again." -ForegroundColor Red
    Write-Host "Download GitHub CLI from: https://cli.github.com/" -ForegroundColor Yellow
    exit 1
}

# Check if user is authenticated with GitHub CLI
if (-not (Test-GitHubAuth)) {
    Write-Host "📝 You need to authenticate with GitHub CLI" -ForegroundColor Yellow
    Write-Host "Starting GitHub CLI login process..." -ForegroundColor Cyan
    gh auth login
    if (-not (Test-GitHubAuth)) {
        Write-Host "❌ GitHub authentication failed. Please try again." -ForegroundColor Red
        exit 1
    }
}

# Get repository details from user
$repoName = "Azure-GCP-Cloud-Resource-Tagging-Remediation"
$repoVisibility = "public"

do {
    $confirmCreate = Read-Host "Do you want to create a new GitHub repository '$repoName'? (y/n)"
    if ($confirmCreate -eq 'n') {
        $repoName = Read-Host "Please enter the desired repository name"
    }
} while ($confirmCreate -eq 'n')

# Create GitHub repository
Write-Host "🔨 Creating GitHub repository: $repoName..." -ForegroundColor Cyan
$repoVisibility = Read-Host "Should the repository be public or private? (public/private)"
gh repo create $repoName --$repoVisibility --confirm

# Clone the repository
Write-Host "📥 Cloning the repository..." -ForegroundColor Cyan
git clone "https://github.com/$((gh api user).login)/$repoName.git"
Set-Location $repoName

# Create main subdirectories
$mainDirs = @(
    "Deliverables",
    "Documentation",
    "Guides",
    "Scripts",
    "Templates",
    "Reports"
)

Write-Host "📁 Creating main directory structure..." -ForegroundColor Cyan
foreach ($dir in $mainDirs) {
    New-Item -ItemType Directory -Path $dir
}

# [Rest of the directory and file creation code remains the same as before...]
# [Previous directory and file creation code goes here]

# Add README.md with project structure
$readmeContent = @"
# $repoName

## Project Structure
\`\`\`
$repoName
├── Deliverables
│   ├── Tagging_Inventory
│   ├── Tag_Remediation_Plan
│   ├── Tag_and_Policy_Implementation
│   ├── Project_Closure_Report
│   └── Backlog_Documentation
[... rest of the structure ...]
\`\`\`

## Project Overview
This repository contains the implementation of a comprehensive cloud resource tagging and remediation solution for Azure and GCP environments.

## Getting Started
[Add your getting started instructions here]

## Documentation
Detailed documentation can be found in the /Documentation directory.

## Scripts
- Azure scripts are located in /Scripts/Azure
- GCP scripts are located in /Scripts/GCP
- Automation scripts are located in /Scripts/Automation

## Templates
Standard templates for the project can be found in the /Templates directory.

## Reports
Project reports and analyses are stored in the /Reports directory.
"@

Set-Content -Path "README.md" -Value $readmeContent

# Git operations
Write-Host "📤 Committing and pushing the folder structure..." -ForegroundColor Cyan
git add .
git commit -m "Initial commit: Create project folder structure"
git push -u origin main

Write-Host "✅ Repository setup completed successfully!" -ForegroundColor Green
Write-Host "📁 Local repository path: $(Get-Location)" -ForegroundColor Cyan
Write-Host "🌐 GitHub repository: https://github.com/$((gh api user).login)/$repoName" -ForegroundColor Cyan