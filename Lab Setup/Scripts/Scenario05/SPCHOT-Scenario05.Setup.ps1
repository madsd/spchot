Write-Host "- Installing Scenario 05"
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

Write-Host " - Creating DNS entry"

$IPAddress = "192.168.2.3"
$DnsServer = "DCSQL"
$DnsZoneName = "contoso.com"
$ARecordName = "scenario05"

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
$SiteUrl = "http://scenario05.contoso.com/"
$SiteTemplate = "SRCHCEN#0"
$SiteLcid = 1033
$SiteOwner = "CONTOSO\administrator"
$SiteName = "Contoso Search Center"

Write-Host ([String]::Format("Creating new site collection at URL {0}...", $SiteUrl)) -NoNewline
$NewSite = New-SPSite -Url $SiteUrl -Language $SiteLcid -Template $SiteTemplate -Name $SiteName -OwnerAlias $SiteOwner -HostHeaderWebApplication $HostingWebApp
Write-Host "Done!"

$solutionPackageName = "Scenario05.wsp"

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

Enable-SPFeature -Identity "Scenario05_Scenario05DesignElements" -Url $SiteUrl | Out-Null

Write-Host "Done installing Scenario 05"