<#
as admin:
Register-PSRepository -Name DockerPS-Dev -SourceLocation https://ci.appveyor.com/nuget/docker-powershell-dev
Install-Module Docker -Repository DockerPS-Dev
#>
Import-Module Docker
Clear-Host

if ((Test-Path -Path c:\containerlogs) -eq $false) {
    New-Item c:\ContainerLogs -ItemType Directory
    Write-Verbose -Message 'Folder containerlogs created' -Verbose
} else {
    Write-Verbose -Message 'Folder containerlogs already exists' -Verbose
}

Write-Verbose -Message 'Starting container nano' -Verbose 

$hostConfig = [Docker.DotNet.Models.HostConfig]::new()
($hostConfig.Binds = [System.Collections.Generic.List[string]]::New()).Add('C:\ContainerLogs\:c:\logs\')
$pb = new-object Docker.DotNet.Models.PortBinding
$pb.HostPort = "81"
$hostConfig.PortBindings = [System.Collections.Generic.Dictionary[string, System.Collections.Generic.iList[Docker.DotNet.Models.PortBinding]]]::new()
$hostConfig.PortBindings.Add("80/tcp",[System.Collections.Generic.List[Docker.DotNet.Models.PortBinding]]::new([Docker.DotNet.Models.PortBinding[]]@($pb)))

Invoke-ContainerImage -ImageIdOrName nanoserver/iis -Name nano -Detach -Terminal -Input -HostConfiguration $hostConfig
#Enter-PSSession -ContainerId (Get-Container -Name nano).ID -RunAsAdministrator

Write-Verbose -Message 'Show IP' -Verbose
$ipaddress = docker inspect -f "{{ .NetworkSettings.Networks.nat.IPAddress }}" nano
$ipaddress
Write-Verbose -Message 'Stopping default website' -Verbose
Invoke-Command -ContainerId (Get-Container -Name nano).ID -ScriptBlock {import-module IISAdministration; Stop-IISSite $args[0] -Confirm:$false;} -ArgumentList @('Default Web Site') -RunAsAdministrator
Write-Verbose -Message 'Create new website' -Verbose
Invoke-Command -ContainerId (Get-Container -Name nano).ID -ScriptBlock {import-module IISAdministration; New-IISSite -Name TestSite -BindingInformation "*:80:" -PhysicalPath c:\logs} -RunAsAdministrator
Write-Verbose -Message 'Start default website' -Verbose
Invoke-Command -ContainerId (Get-Container -Name nano).ID -ScriptBlock {import-module IISAdministration; Start-IISSite $args[0];} -ArgumentList @('TestSite') -RunAsAdministrator
$site = Invoke-WebRequest -Uri http://$ipaddress/default.aspx
Write-Verbose -Message 'Write Website Content' -Verbose
Write-Verbose -Message 'Get computername via psremote' -Verbose
Invoke-Command -ContainerId (Get-Container -Name nano).ID -ScriptBlock { $env:computername }

Write-Verbose -Message 'Kill container' -Verbose
Stop-Container -ContainerIdOrName nano
Write-Verbose -Message 'Container stopped but still exists' -Verbose
Get-Container -ContainerIdOrName nano
Write-Verbose -Message 'Remove container' -Verbose
#docker rm nano
Remove-Container -ContainerIdOrName nano
Write-Verbose -Message 'Now the container is really gone and we can re-use the name' -Verbose
Get-Container | fl *

