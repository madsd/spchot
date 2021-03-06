Write-Host "- Installing Scenario 03"
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

Write-Host " - Creating DNS entry"

$IPAddress = "192.168.2.3"
$DnsServer = "DCSQL"
$DnsZoneName = "contoso.com"
$ARecordName = "scenario03"

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


#************************************
$CurrentDirectory = (Get-Location).Path

$HostingWebApp = "http://sp01"
$SiteUrl = "http://scenario03.contoso.com/"
$SiteTemplate = "BLANKINTERNET#0"
$SiteLcid = 1033
$SiteOwner = "CONTOSO\administrator"
$SiteName = "Contoso Intranet"

Write-Host " - Creating site collection..." -NoNewline
$NewSite = New-SPSite -Url $SiteUrl -Language $SiteLcid -Template $SiteTemplate -Name $SiteName -OwnerAlias $SiteOwner -HostHeaderWebApplication $HostingWebApp
Write-Host "Done!"

Write-Host " - Installing and deploying farm solutions..." -NoNewline
$solutionPackageName = "Scenario03.wsp"
$path = $rootPath
$solutionPath = $path + "\" + $solutionPackageName
Add-SPSolution -LiteralPath $solutionPath | Out-Null
Install-SPSolution -Identity $solutionPackageName -GACDeployment -WebApplication $HostingWebApp | Out-Null

$deployed = Get-SPSolution -Identity $solutionPackageName | SELECT Deployed

while (!$deployed.Deployed)
{
    $deployed = Get-SPSolution -Identity $solutionPackageName | SELECT Deployed
    Write-Host "." -NoNewline
    Start-Sleep -Seconds 2
}
Write-Host "Done!"

Write-Host " - Activating features..." -NoNewline
Enable-SPFeature -Identity "Scenario03_PublishingLayouts" -Url $SiteUrl | Out-Null
Enable-SPFeature -Identity "Scenario03_WebParts" -Url $SiteUrl | Out-Null
Enable-SPFeature -Identity "Scenario03_PublishingPages" -Url $SiteUrl | Out-Null
Write-Host "Done!"