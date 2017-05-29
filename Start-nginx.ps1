Import-Module Docker
Clear-Host

function Start-Containers
{
    Write-Verbose -Message 'Make sure local folder containerlogs exists' -Verbose
    if ((Test-Path -Path c:\containerlogs) -eq $false) {
        New-Item c:\ContainerLogs -ItemType Directory
        Write-Verbose -Message 'Folder containerlogs created' -Verbose
    } else {
        Write-Verbose -Message 'Folder containerlogs already exists' -Verbose
    }

    Write-Verbose -Message 'Read template file NGINX config files' -Verbose
    $ConfigString = Get-Content -Path C:\ContainerLogs\nginx\template.conf -Raw

    Write-Verbose -Message 'Starting Nodejs1 image' -Verbose
    Invoke-ContainerImage -ImageIdOrName webserver -Name nodejs1 -Detach -Terminal -Input
    $ipaddress = docker inspect -f "{{ .NetworkSettings.Networks.nat.IPAddress }}" nodejs1
    $server = $ConfigString.Replace("[servername]", "nodejs1.foorbar.net")
    Write-Verbose -Message "IPAddress node1" -Verbose
    $ipaddress
    $server = $server.Replace("[ipaddress]", $ipaddress)
    $server | Out-File -FilePath C:\ContainerLogs\nginx\conf\nodejs1.conf -Encoding ascii
    
    Write-Verbose -Message 'Starting Nodejs2 image' -Verbose
    Invoke-ContainerImage -ImageIdOrName webserver -Name nodejs2 -Detach -Terminal -Input
    $ipaddress = docker inspect -f "{{ .NetworkSettings.Networks.nat.IPAddress }}" nodejs2
    $server = $ConfigString.Replace("[servername]", "nodejs2.foorbar.net")
    Write-Verbose -Message "IPAddress node2" -Verbose
    $ipaddress
    $server = $server.Replace("[ipaddress]", $ipaddress)
    $server | Out-File -FilePath C:\ContainerLogs\nginx\conf\nodejs2.conf -Encoding ascii

    Write-Verbose -Message 'Setting default config for NGINX image' -Verbose
    $config = [Docker.DotNet.Models.Config]::new()
    ($config.ExposedPorts  = [System.Collections.Generic.Dictionary[string,object]]::new()).Add("80/tcp", $null)
    $hostConfig = [Docker.DotNet.Models.HostConfig]::new()
    ($hostConfig.Binds = [System.Collections.Generic.List[string]]::New()).Add('C:\ContainerLogs\:c:\local\')
    $pb = new-object Docker.DotNet.Models.PortBinding
    $pb.HostPort = "80"
    $hostConfig.PortBindings = [System.Collections.Generic.Dictionary[string, System.Collections.Generic.iList[Docker.DotNet.Models.PortBinding]]]::new()
    $hostConfig.PortBindings.Add("80/tcp",[System.Collections.Generic.List[Docker.DotNet.Models.PortBinding]]::new([Docker.DotNet.Models.PortBinding[]]@($pb)))

    Write-Verbose -Message 'Starting NGINX image' -Verbose
    Invoke-ContainerImage -ImageIdOrName nginx-nanoserver -Configuration $config -Name nginx -Detach -Terminal -Input -HostConfiguration $hostConfig
    $ipaddress = docker inspect -f "{{ .NetworkSettings.Networks.nat.IPAddress }}" nginx
    Write-Verbose -Message "IPAddress nginx" -Verbose
    $ipaddress
}

function Enter-AdminSession([string]$ContainerName)
{
    Enter-PSSession -ContainerId (Get-Container -Name $ContainerName).ID -RunAsAdministrator
}

function Stop-Containers 
{
    Write-Verbose -Message 'Stop containers' -Verbose
    Get-Container | Stop-Container
    Write-Verbose -Message 'Remove container' -Verbose
    Get-Container | Remove-Container
    Write-Verbose -Message 'Remove generated nginx config files' -Verbose
    Remove-Item -Path C:\ContainerLogs\nginx\conf\nodejs1.conf
    Remove-Item -Path C:\ContainerLogs\nginx\conf\nodejs2.conf
}

Start-Containers
<#
Enter-AdminSession 'nodejs1'
Enter-AdminSession 'nodejs2'
Enter-AdminSession 'nginx'
Get-Container # List Running Containers
Stop-Containers
#>