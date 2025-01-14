# Azure Tag Compliance Scanner
# Version: 2.0
# Description: GUI tool for scanning Azure resources for tag compliance

# Requires -Modules Az.Accounts, Az.Resources, ImportExcel

[CmdletBinding()]
param (
    [Parameter()]
    [string]$ConfigPath = ".\config.json",
    [Parameter()]
    [switch]$ShowGui = $true
)

# Import required modules
using namespace System.Windows.Forms
using namespace System.Drawing

# Function to ensure required modules are installed
function Install-RequiredModules {
    $modules = @('Az.Accounts', 'Az.Resources', 'ImportExcel')
    foreach ($module in $modules) {
        try {
            if (!(Get-Module -ListAvailable -Name $module)) {
                Write-Host "Installing required module: $module"
                Install-Module -Name $module -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
            }
            Import-Module $module -ErrorAction Stop
        }
        catch {
            throw "Failed to install/import module $module : $_"
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
        [System.Windows.Forms.MessageBox]::Show(
            "Failed to connect to Azure. Please ensure you have the right credentials and permissions.`n`nError: $_",
            "Connection Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
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
            # Validate configuration structure
            if (!$config.RequiredTags -or $config.RequiredTags.Count -eq 0) {
                throw "Invalid configuration: RequiredTags section is missing or empty"
            }
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

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Azure Tag Compliance Scanner"
    $form.Size = New-Object System.Drawing.Size(1200, 800)
    $form.StartPosition = "CenterScreen"
    $form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)

    # Create tab control
    $tabControl = New-Object System.Windows.Forms.TabControl
    $tabControl.Size = New-Object System.Drawing.Size(1160, 700)
    $tabControl.Location = New-Object System.Drawing.Point(10, 10)

    # Create tabs
    $tabConfig = New-Object System.Windows.Forms.TabPage
    $tabConfig.Text = "Tag Configuration"
    $tabScan = New-Object System.Windows.Forms.TabPage
    $tabScan.Text = "Scan Results"

    # Add tabs to control
    $tabControl.Controls.AddRange(@($tabConfig, $tabScan))

    # Add controls to form
    $form.Controls.Add($tabControl)

    # Add scan button
    $btnScan = New-Object System.Windows.Forms.Button
    $btnScan.Location = New-Object System.Drawing.Point(10, 720)
    $btnScan.Size = New-Object System.Drawing.Size(100, 30)
    $btnScan.Text = "Scan Tags"
    $btnScan.Add_Click({
        Start-TagScan -Config $Config -Form $form
    })
    $form.Controls.Add($btnScan)

    # Add results grid to scan tab
    $gridResults = New-Object System.Windows.Forms.DataGridView
    $gridResults.Location = New-Object System.Drawing.Point(10, 10)
    $gridResults.Size = New-Object System.Drawing.Size(1130, 650)
    $gridResults.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::Fill
    $gridResults.AllowUserToAddRows = $false
    $tabScan.Controls.Add($gridResults)

    return $form
}

# Add scanning functionality
function Start-TagScan {
    param (
        [object]$Config,
        [System.Windows.Forms.Form]$Form
    )
    try {
        $resources = Get-AzResource
        $results = @()
        
        foreach ($resource in $resources) {
            $compliance = @{
                ResourceName = $resource.Name
                ResourceType = $resource.ResourceType
                ResourceGroup = $resource.ResourceGroupName
                MissingTags = @()
                InvalidTags = @()
            }

            foreach ($requiredTag in $Config.RequiredTags) {
                if (!$resource.Tags -or !$resource.Tags.ContainsKey($requiredTag.Name)) {
                    $compliance.MissingTags += $requiredTag.Name
                }
                elseif ($requiredTag.AllowedValues -and $requiredTag.AllowedValues.Count -gt 0) {
                    if ($resource.Tags[$requiredTag.Name] -notin $requiredTag.AllowedValues) {
                        $compliance.InvalidTags += "$($requiredTag.Name)=$($resource.Tags[$requiredTag.Name])"
                    }
                }
            }
            
            $results += [PSCustomObject]$compliance
        }

        # Update grid with results
        $gridResults = $Form.Controls['tabControl'].TabPages['Scan Results'].Controls['gridResults']
        $gridResults.DataSource = $results
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Failed to scan resources: $_",
            "Scan Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
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
        [System.Windows.Forms.Application]::EnableVisualStyles()
        $form.ShowDialog()
    }
}
catch {
    Write-Error "An error occurred: $_"
    if ($ShowGui) {
        [System.Windows.Forms.MessageBox]::Show(
            "An unexpected error occurred: $_",
            "Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}