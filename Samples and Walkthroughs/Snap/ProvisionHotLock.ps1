Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

$hostHeader = "scenario02.contoso.com"
$webAppUrl = "http://" + $hostHeader
$siteUrl = $webAppUrl
$solutionPackageName = "Pfe.Demos.HotLock.wsp"

$path = Split-Path $MyInvocation.MyCommand.Path | Get-Item
$solutionPath = $path.FullName + "\" + $solutionPackageName
Add-SPSolution -LiteralPath $solutionPath | Out-Null
Install-SPSolution -Identity $solutionPackageName -GACDeployment -CompatibilityLevel 15 -WebApplication $webAppUrl | Out-Null

$deployed = Get-SPSolution -Identity $solutionPackageName | SELECT Deployed

while (!$deployed.Deployed)
{
    $deployed = Get-SPSolution -Identity $solutionPackageName | SELECT Deployed
    Write-Host "." -NoNewline
    Start-Sleep -Seconds 2
}
Write-Host

Enable-SPFeature -Identity "Pfe.Demos.HotLock_WebParts" -Url $siteUrl | Out-Null

Add-Type -Path "C:\Windows\Microsoft.NET\assembly\GAC_MSIL\Pfe.Demos.HotLock\v4.0_1.0.0.0__4d8cfa7ffa2bb03e\Pfe.Demos.HotLock.dll"

$site = Get-SPSite $SiteUrl
$web = $site.RootWeb
$pubWeb = [Microsoft.SharePoint.Publishing.PublishingWeb]::GetPublishingWeb($web);
$startPage = $pubWeb.DefaultPage;
$startPage.CheckOut();
$webPartManager = $startPage.GetLimitedWebPartManager([System.Web.UI.WebControls.WebParts.PersonalizationScope]::Shared)

$zoneName = "TopColumnZone"
$webPart = New-Object Pfe.Demos.HotLock.HotLock.HotLock
$webPart.Title = "Hot Lock Demo";
$webPartManager.AddWebPart($webPart, $zoneName, 0);
$startPage.CheckIn("", [Microsoft.SharePoint.SPCheckInType]::MajorCheckIn);     
$startPage.Publish("");