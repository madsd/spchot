Write-Host "- Installing Scenario 01"
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
Import-Module WebAdministration

Write-Host " - Creating DNS entry"

$IPAddress = "192.168.2.3"
$DnsServer = "DCSQL"
$DnsZoneName = "contoso.com"
$ARecordName = "scenario01"

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

#Setup the web site to host RSS Feed
$InstallDirectory = $rootPath
Write-Host " - Creating RSS web site in local IIS"
$VirtualDirectory = (New-Item -Path C:\inetpub\scenario01-rsssite -ItemType Directory).FullName
$SourcePath = $InstallDirectory + "\SharePointTeamBlog.xml"
$DestinationPath = $VirtualDirectory + "\SharePointTeamBlog.xml"
Copy-Item -LiteralPath $SourcePath -Destination $DestinationPath
New-Website -Name "Scenario 01 - RSS Site" -Port 31000 -PhysicalPath $VirtualDirectory -ApplicationPool DefaultAppPool | Out-Null

#************************************
$HostingWebApp = "http://sp01"
$SiteUrl = "http://scenario01.contoso.com/"
$SiteTemplate = "BLANKINTERNETCONTAINER#0"
$SiteLcid = 1033
$SiteOwner = "CONTOSO\administrator"
$SiteName = "Contoso Business Portal"

Write-Host ([String]::Format("Creating new site collection at URL {0}...", $SiteUrl)) -NoNewline
$NewSite = New-SPSite -Url $SiteUrl -Language $SiteLcid -Template $SiteTemplate -Name $SiteName -OwnerAlias $SiteOwner -HostHeaderWebApplication $HostingWebApp 
Write-Host "Done!"

$solutionPackageName = "Scenario01.Config.wsp"

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

$solutionPackageName = "Scenario01.WebParts.wsp"

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
Write-Host

Write-Host "Activating features..." -NoNewline
Enable-SPFeature -Identity Scenario01.Config_GlobalConfig | Out-Null
Enable-SPFeature -Identity Scenario01.WebParts_WebParts -Url $SiteUrl | Out-Null
Disable-SPFeature -Identity Scenario01.Config_GlobalConfig -Confirm:$false | Out-Null
Write-Host "Done!"

Add-Type -Path "C:\Windows\assembly\GAC_MSIL\Scenario01.WebParts\1.0.0.0__1916325c2771282a\Scenario01.WebParts.dll"

$site = Get-SPSite $SiteUrl
$web = $site.RootWeb
$pubWeb = [Microsoft.SharePoint.Publishing.PublishingWeb]::GetPublishingWeb($web);
$startPage = $pubWeb.DefaultPage;
$startPage.CheckOut();
$webPartManager = $startPage.GetLimitedWebPartManager([System.Web.UI.WebControls.WebParts.PersonalizationScope]::Shared)

$zoneName = "TopColumnZone"
$webPart = New-Object Scenario01.WebParts.WebParts.FeedWebPart.FeedWebPart
$webPart.Title = "SharePoint Team Blog";
$webPartManager.AddWebPart($webPart, $zoneName, 0);
$startPage.CheckIn("", [Microsoft.SharePoint.SPCheckInType]::MajorCheckIn);     
$startPage.Publish("");
