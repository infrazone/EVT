using namespace System.Windows.Forms
using namespace System.Drawing

# Azure Tag Compliance Scanner
# Version: 2.0
# Description: GUI tool for scanning Azure resources for tag compliance

#Requires -Modules Az.Accounts, Az.Resources, ImportExcel

[CmdletBinding()]
param (
    [Parameter()]
    [string]$ConfigPath = ".\config.json",
    [Parameter()]
    [switch]$ShowGui = $true
)

# Function to ensure required modules are installed
function Install-RequiredModules {
    $modules = @('Az.Accounts', 'Az.Resources', 'ImportExcel')
    foreach ($module in $modules) {
        if (!(Get-Module -ListAvailable -Name $module)) {
            Write-Host "Installing required module: $module"
            Install-Module -Name $module -Scope CurrentUser -Force -AllowClobber
        }
    }
}

# Function to test Azure connection
function Test-AzureConnection {
    try {
        $context = Get-AzContext
        if (!$context) {
            Write-Host "No Azure context found. Attempting to connect..."
            Connect-AzAccount
            $context = Get-AzContext
            if (!$context) {
                throw "Failed to establish Azure connection"
            }
        }
        return $true
    }
    catch {
        $msgBox = [MessageBox]::Show(
            "Failed to connect to Azure. Please ensure you have the right credentials and permissions.`n`nError: $_",
            "Connection Error",
            [MessageBoxButtons]::OK,
            [MessageBoxIcon]::Error
        )
        return $false
    }
}

# Function to load configuration
function Get-TagConfiguration {
    param (
        [string]$ConfigPath
    )
    try {
        if (Test-Path $ConfigPath) {
            $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
        }
        else {
            # Default configuration
            $config = @{
                RequiredTags = @(
                    @{
                        Name = "core-cost-center"
                        Required = $true
                        AllowedValues = @()
                    },
                    @{
                        Name = "core-financial-bu"
                        Required = $true
                        AllowedValues = @()
                    },
                    @{
                        Name = "core-financial-sub-bu"
                        Required = $true
                        AllowedValues = @()
                    },
                    @{
                        Name = "core-snow-as-number"
                        Required = $true
                        AllowedValues = @()
                    },
                    @{
                        Name = "core-snow-ba-number"
                        Required = $true
                        AllowedValues = @()
                    },
                    @{
                        Name = "core-subscription-owner"
                        Required = $true
                        AllowedValues = @()
                    },
                    @{
                        Name = "snow-application-name"
                        Required = $true
                        AllowedValues = @()
                    },
                    @{
                        Name = "snow-application-owner"
                        Required = $true
                        AllowedValues = @()
                    },
                    @{
                        Name = "snow-business-criticality"
                        Required = $true
                        AllowedValues = @("High", "Medium", "Low")
                    },
                    @{
                        Name = "snow-data-classification"
                        Required = $true
                        AllowedValues = @("Public", "Internal", "Confidential", "Restricted")
                    },
                    @{
                        Name = "snow-environment"
                        Required = $true
                        AllowedValues = @("Production", "Development", "Staging", "Test")
                    },
                    @{
                        Name = "snow-service-owner"
                        Required = $true
                        AllowedValues = @()
                    }
                )
            }
            # Save default configuration
            $config | ConvertTo-Json -Depth 10 | Out-File $ConfigPath
        }
        return $config
    }
    catch {
        Write-Error "Failed to load configuration: $_"
        return $null
    }
}

# Function to create the main form
function New-TagScannerForm {
    param (
        [object]$Config
    )

    $form = New-Object Form
    $form.Text = "Azure Tag Compliance Scanner"
    $form.Size = New-Object Size(1200, 800)
    $form.StartPosition = "CenterScreen"
    $form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)

    # Create tab control
    $tabControl = New-Object TabControl
    $tabControl.Size = New-Object Size(1160, 700)
    $tabControl.Location = New-Object Point(10, 10)

    # Create tabs
    $tabConfig = New-Object TabPage
    $tabConfig.Text = "Tag Configuration"
    $tabScan = New-Object TabPage
    $tabScan.Text = "Scan Results"

    # Add tabs to control
    $tabControl.Controls.AddRange(@($tabConfig, $tabScan))

    # Add controls to form
    $form.Controls.Add($tabControl)

    return $form
}

# Main script execution
try {
    # Ensure required modules are installed
    Install-RequiredModules

    # Test Azure connection
    if (!(Test-AzureConnection)) {
        exit
    }

    # Load configuration
    $config = Get-TagConfiguration -ConfigPath $ConfigPath
    if (!$config) {
        exit
    }

    # Create and show the form if GUI mode is enabled
    if ($ShowGui) {
        $form = New-TagScannerForm -Config $config
        [Application]::EnableVisualStyles()
        $form.ShowDialog()
    }
}
catch {
    Write-Error "An error occurred: $_"
    if ($ShowGui) {
        [MessageBox]::Show(
            "An unexpected error occurred: $_",
            "Error",
            [MessageBoxButtons]::OK,
            [MessageBoxIcon]::Error
        )
    }
}