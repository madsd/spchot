Write-Host "- Installing Scenario 04"
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

Write-Host " - Creating DNS entry"

$IPAddress = "192.168.2.3"
$DnsServer = "DCSQL"
$DnsZoneName = "contoso.com"
$ARecordName = "scenario04"

if (-not $dnsCreds)
{
    $dnsCreds = Get-Credential -Message "Credentials for DNS Admin" -UserName "CONTOSO\Administrator"
}

$record = Invoke-Command -ComputerName $DnsServer -Credential $dnsCreds -ScriptBlock {Get-DnsServerResourceRecord -ZoneName $args[1] -RRType A | ? HostName -eq $args[0]} -ArgumentList $ARecordName, $DnsZoneName
if ($record -eq $null)
{
    Write-Host " - Adding DNS Record" 
    Invoke-Command -ComputerName $DnsServer -Credential $dnsCreds -ScriptBlock {Add-DnsServerResourceRecordA -Name $args[0] -ZoneName $args[1] -IPv4Address $args[2]} -ArgumentList $ARecordName, $DnsZoneName, $IPAddress
}
else
{
    Write-Host " - Existing DNS Record found" 
}

$rootPath = $PSScriptRoot
if ($rootPath -eq "")
{
	$rootPath = (Get-Location).Path
}

$HostingWebApp = "http://sp01"
$SiteUrl = "http://scenario04.contoso.com/"
$SiteTemplate = "STS#0"
$SiteLcid = 1033
$SiteOwner = "CONTOSO\administrator"
$SiteName = "Contoso Team Site"

Write-Host ([String]::Format("Creating new site collection at URL {0}...", $SiteUrl)) -NoNewline
$NewSite = New-SPSite -Url $SiteUrl -Language $SiteLcid -Template $SiteTemplate -Name $SiteName -OwnerAlias $SiteOwner -HostHeaderWebApplication $HostingWebApp
Write-Host "Done!"

$solutionPackageName = "Scenario04.wsp"

$path = $rootPath
$solutionPath = $path + "\" + $solutionPackageName
Add-SPSolution -LiteralPath $solutionPath | Out-Null
Install-SPSolution -Identity $solutionPackageName -GACDeployment | Out-Null

$deployed = Get-SPSolution -Identity $solutionPackageName | SELECT Deployed

while (!$deployed.Deployed)
{
    $deployed = Get-SPSolution -Identity $solutionPackageName | SELECT Deployed
    Write-Host "." -NoNewline
    Start-Sleep -Seconds 2
}
Write-Host
Write-Host "Finished Installing solution"

[Microsoft.SharePoint.Administration.SPWebService] $service =[Microsoft.SharePoint.Administration.SPWebService]::ContentService

$configMod = New-Object Microsoft.SharePoint.Administration.SPWebConfigModification
$configMod.Path = "configuration/system.webServer/modules"
$configMod.Name = "add[@name='Scenario04']"
$configMod.Sequence = 0
$configMod.Owner = "Scenario04"
$configMod.Type = 0 # EnsureNode
$configMod.Value = "<add name='Scenario04' type='Scenario04.BrowserOptimizer, Scenario04, Version=1.0.0.0, Culture=neutral, PublicKeyToken=24c39aff80c1b745' />"

# Apply to Individual Web Application
$webApp = Get-SPWebApplication $HostingWebApp
$webApp.WebConfigModifications.Add($configMod)
$webApp.Update()

$service.ApplyWebConfigModifications()

Write-Host "Done installing Scenario 04"