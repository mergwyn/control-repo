#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Installs Puppet Agent on a Windows machine
.DESCRIPTION
    Checks for the presence of Puppet Agent on a machine and installs it if missing. 
    Script allows you to set extra CSR attributes for silky smooth hiera lookups. 
.NOTES
    Experimental at this point.
#>
[CmdletBinding()]
param (
    # The FQDN of the Puppet master you are connecting to
    [Parameter(Mandatory = $true)]
    [string]
    $PuppetMaster,

    # The domain name you are using (might be irrelevant?)
    [Parameter(Mandatory = $true)]
    [string]
    $DomainName,

    # The method for installing Puppet
    [Parameter(Mandatory = $false)]
    [ValidateSet('Chocolatey', 'Legacy')]
    [string]
    $InstallationMethod = 'Chocolatey',

    # The specific puppet collection to use (will use PuppetAgentVersion.Major if set)
    [Parameter(Mandatory = $false)]
    [ValidatePattern('^\d$')]
    [string]
    $Collection = '7',

    # The specific puppet agent version to install (if you override it should be in a format such as: 6.15.0)
    [Parameter(Mandatory = $false)]
    [ValidatePattern('^(\d{1,2}\.)?(\d{1,2}\.)?(\d{1,2})$|^latest$')]
    [string]
    $PuppetAgentVersion = 'latest',

    # The port to connect to on the master
    [Parameter(Mandatory = $false)]
    [int]
    $MasterPort = 8140,

    # The Puppet envrionment (aka Git branch) to use
    [Parameter(Mandatory = $false)]
    [string]
    $PuppetEnvironment = "production",

    # Any extended CSR attributes you'd like to set (pp_service,pp_role,pp_envrironment etc)
    [Parameter(Mandatory = $false)]
    [hashtable]
    $CertificateExtensions,

    # Puppet agent service startup mode
    [Parameter(Mandatory = $false)]
    [ValidateSet('Automatic', 'Manual', 'Disabled')]
    [ValidateNotNullOrEmpty()] # needed so as not to mess up the puppet.conf file
    [string]
    $StartupMode = 'Automatic',

    # How long to wait between cert checks
    [Parameter(Mandatory = $false)]
    [int]
    $WaitForCertificate = 30
)
## Setting up ##
function Get-CSRAttributes 
{
    $pp_env = Read-Host "pp_environment"
    $pp_service = Read-Host "pp_service"
    $pp_role = Read-Host "pp_role"

    $hash = @{
        pp_service     = $pp_service
        pp_role        = $pp_role
        pp_environment = $pp_env
    }
    while (!$correct) 
    {
        Write-Host "pp_environment: $pp_env`npp_service: $pp_service`npp_role: $pp_role"
        $correct = Read-Host "Is this correct? [y/n]"
        switch ($correct)
        {
            'y' { Return $hash }
            'n' 
            { 
                $pp_env = Read-Host "pp_environment"
                $pp_service = Read-Host "pp_service"
                $pp_role = Read-Host "pp_role"
                $hash = @{
                    pp_service     = $pp_service
                    pp_role        = $pp_role
                    pp_environment = $pp_env
                }
                Clear-Variable correct
            }
            default { Clear-Variable correct }
        }
    }
}
function Set-CSRAttributes
{
    param 
    (
        [Parameter(Mandatory = $true)]
        [hashtable]
        $CSRAttributes
    )
    $csr_yaml_path = "$env:ProgramData\PuppetLabs\puppet\etc\csr_attributes.yaml"
    if (Test-Path $csr_yaml_path)
    {
        Remove-Item $csr_yaml_path -Confirm:$false -Force
    }
    $csr_yaml_parent = Split-Path $csr_yaml_path
    if (!(Test-Path $csr_yaml_parent))
    {
        try
        {
            New-Item $csr_yaml_parent -ItemType Directory -ErrorAction Stop | Out-Null
        }
        catch
        {
            throw "Failed to create Puppet data directory."
        }
    }
    $csr_yaml = @('extension_requests:')
    foreach ($attribute in $CSRAttributes.GetEnumerator())
    {
        $csr_yaml += "  $($attribute.Name): $($attribute.Value)"
    }
    try
    {
        Set-Content $csr_yaml_path -Value $csr_yaml -ErrorAction Stop
    }
    catch
    {
        throw "failed to set yaml."
    }
}
function Install-Chocolatey 
{
    Write-Output "Installing Chocolatey"
    if (([Enum]::GetNames([Net.SecurityProtocolType]) -contains 'Tls12') -ne $true)
    {
        throw "TLS 1.2 either not supported or cannot be enabled on your system"
    }
    if (([System.Net.ServicePointManager]::SecurityProtocol.HasFlag([Net.SecurityProtocolType]::Tls12)) -ne $true)
    {
        try 
        {
            [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        }
        catch 
        {
            throw "Failed to set TLS 1.2.`n$($_.Exception.Message)"
        }
    }
    if (([System.Net.ServicePointManager]::SecurityProtocol.HasFlag([Net.SecurityProtocolType]::Tls12)) -ne $true)
    {
        throw "Tried to set TLS 1.2 but it still isn't active."
    }
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}
## End Setup ##
## Checks ##
if (Get-Command puppet -erroraction silentlycontinue)
{
    throw "Puppet is already installed"
}
if ($InstallationMethod -eq 'Chocolatey' -and !(Get-Command 'choco' -ErrorAction SilentlyContinue))
{
    Write-Warning -Message "Chocolately does not appear to be installed on your system.`nWould you like to install it?"
    while (!$ChocoInstall) 
    {
        $ChocoInstall = Read-Host "Install Chocolatey? [y/n]"
        switch ($chocoinstall) 
        {
            'y' 
            { 
                try
                {
                    Install-Chocolatey
                }
                catch
                {
                    throw "Failed to install Chocolatey.`n$($_.Exception.Message)"
                }
            }
            'n'
            {
                Write-Host 'If you want to use the legacy installer, run this script again specifying "-InstallationMethod Legacy"'
                exit
            }
            Default 
            {
                Clear-Variable $ChocoInstall # unrecognised input, try again.
            }
        }
    }
}
if ($PuppetMaster -notmatch ".$Domainname")
{
    $PuppetMaster = "$PuppetMaster.$domainname"
}
# Quick test to make sure we can get to the PuppetMaster
Write-Host "Checking connection to $PuppetMaster"
if (!(Test-NetConnection $PuppetMaster -InformationLevel Quiet))
{
    throw "Failed to contact $PuppetMaster, please check the name and network connection."
}

if (!$CertificateExtensions)
{
    while (!$answer)
    {
        $answer = Read-Host "Do you want to set extended CSR attributes? [y/n]"
        switch ($answer.ToLower()) 
        {
            'y' 
            {
                $CertificateExtensions = Get-CSRAttributes
                Set-CSRAttributes $CertificateExtensions
            }
            'n' 
            {   
                # Do nothing
            }
            default { Clear-Variable answer } # Unrecognised input, try again
        }
    }
}
else 
{
    Set-CSRAttributes $CertificateExtensions
}
<#
    If we've got a \vagrant folder assume we're in a Vagrant box
    At the time of writing 2020-05-01, Puppet seems to be absorbing any local DNS into the FQDN for Workgroup machines.
    (eg if the machine is vagrant.local but we have a DNS server for foobar.com on our network Puppet is creating a csr for vagrant.foobar.com)
    Almost certainly not a problem in usual operation but for Vagrant it most certainly is.
    So when we detect vagrant we override the cert name.
#>
$fqdn = "$env:computername.$domainname"
if ((Test-Path "$env:SystemDrive\Vagrant") -and !($AgentCertName))
{
    $AgentCertName = $fqdn
}
## End Checks ##

# Legacy installer
if ($InstallationMethod -eq 'Legacy')
{
    # For now we're getting the Puppet agent manually but ultimately I'd like to test getting it via chocolatey - that way we can keep the package up to date.
    # Default to x86 but attempt to get x64 where we can.
    Write-Verbose "Using legacy installer"
    $arch = "x86"
    if ( [Environment]::Is64BitOperatingSystem )
    {
        Write-Verbose "x64 installation required."
        $arch = "x64"
    }
    if ($PuppetAgentVersion -ne 'latest')
    {
        $Collection = "puppet" + [version]::Parse($PuppetAgentVersion).Major
        $DownloadURL = "https://downloads.puppetlabs.com/windows/$Collection/puppet-agent-$PuppetAgentVersion-$arch.msi"
    }
    else
    {
        $Collection = "puppet" + $Collection
        $DownloadURL = "https://downloads.puppetlabs.com/windows/$Collection/puppet-agent-$arch-latest.msi"
    }
    Write-Verbose "Download URL: $DownloadURL"
    # Spin up a tempdir we can use for storing the download in
    $tempname = ( -join ((0x30..0x39) + ( 0x41..0x5A) + ( 0x61..0x7A) | Get-Random -Count 8 | ForEach-Object { [char]$_ }))
    $tempdir = "$env:TEMP\$tempname"
    Write-Verbose "Temp dir is $tempdir"
    try
    {
        New-Item $tempdir -ItemType Directory -ErrorAction Stop | Out-Null
    }
    catch
    {
        throw "Failed to create temp directory.`n$($_.Exception.Message)"
    }
    $installer = "$tempdir\puppet.msi"
    $DownloadCommand = 'Start-BitsTransfer -Source $DownloadURL -Destination $installer -ErrorAction Stop'
    $BITSCheck = Get-Service bits -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Status
    if ($BitsCheck -ne 'Running')
    {
        # use slower legacy download method
        Write-Verbose "Reverting to legacy download"
        $DownloadCommand = 'Invoke-WebRequest -Uri $DownloadURL -OutFile $installer -ErrorAction Stop'
    }
    Write-Host "Downloading Puppet installer version: $Collection"
    try
    {
        Invoke-Expression $DownloadCommand
    }
    catch
    {
        Remove-Item $tempdir -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue
        "Failed to get Puppet installer.`n$($_.Exception.Message)"
    }
    $installer_params = @(
        '/qn',
        '/norestart',
        '/i',
        "$installer",
        "PUPPET_AGENT_STARTUP_MODE=$StartupMode",
        "PUPPET_MASTER_SERVER=$($PuppetMaster.ToLower())",
        "PUPPET_AGENT_ENVIRONMENT=$PuppetEnvironment"
    )
    # do something for custom certnames here for those cases where we don't domain join a machine
    if ($AgentCertName)
    {
        Write-Verbose "Setting agent cert name"
        $installer_params += "PUPPET_AGENT_CERTNAME=$($AgentCertName.ToLower())"
    }
    Write-Debug "Installer params: $installer_params" # this has saved my bacon a couple of times in the past with weird installer args appearing.
    Write-Host "Installing Puppet Agent"
    try
    {
        Start-Process msiexec.exe -ArgumentList $installer_params -Wait -NoNewWindow -ErrorAction Stop
    }
    catch
    {
        throw "Failed to install Puppet agent.`n$($_.Exception.Message)"
    }
    finally
    {
        # Clean up our temp directory as we don't need it anymore
        Remove-Item $tempdir -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue
    }
}
else 
{
    $InstallationArguments = 'install puppet-agent -y'
    if ($PuppetAgentVersion -ne 'latest')
    {
        $InstallationArguments += " --version=$PuppetAgentVersion"
    }
    $PuppetArguments = " --install-args=`"`'PUPPET_AGENT_STARTUP_MODE=$StartupMode PUPPET_MASTER_SERVER=$($PuppetMaster.ToLower()) PUPPET_AGENT_ENVIRONMENT=$PuppetEnvironment`'`""
    if ($AgentCertName)
    {
        $PuppetArguments = " --install-args=`"`'PUPPET_AGENT_STARTUP_MODE=$StartupMode PUPPET_MASTER_SERVER=$($PuppetMaster.ToLower()) PUPPET_AGENT_ENVIRONMENT=$PuppetEnvironment PUPPET_AGENT_CERTNAME=$($AgentCertName.ToLower())`'`""
    }
    $InstallationArguments += $PuppetArguments
    Write-Verbose "Installing Puppet with:`n$InstallationArguments"
    try 
    {
        $ChocoResult = Start-Process 'choco' -ArgumentList $InstallationArguments -Wait -NoNewWindow -PassThru -ErrorAction Stop
    }
    catch 
    {
        throw "Failed to install Puppet.`n$($_.Exception.Message)"
    }
    $validexitcodes = (0, 3010, 1641)
    if ($ChocoResult.ExitCode -notin $validexitcodes)
    {
        throw "Looks like Chocolatey failed to install Puppet correctly.`nExit code: $($ChocoResult.ExitCode)"
    }
}

# Update path (need to make this x86/64 compatible)
if ($env:Path -notcontains 'C:\Program Files\Puppet Labs\Puppet\bin' ) 
{
    $env:Path += ';C:\Program Files\Puppet Labs\Puppet\bin'
    [Environment]::SetEnvironmentVariable('Path', $env:Path, 'Machine')
}
Write-Host "Performing first run of Puppet.`nIf this is a new machine then a CSR will be created which will need signing on $PuppetMaster."
puppet agent -t --waitforcert $WaitForCertificate
if ($WaitForCertificate = 0)
{
    Read-Host "Please sign the certificate on $PuppetMaster and press enter to continue"
    puppet agent -t
}

if ($MasterPort -ne 8140)
{
    puppet.bat config set masterport $MasterPort --section main
}
