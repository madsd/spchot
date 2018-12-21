Write-Host "- Installing Scenario 02"
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
Import-Module WebAdministration

Write-Host " - Creating DNS entry"

$IPAddress = "192.168.2.3"
$DnsServer = "DCSQL"
$DnsZoneName = "contoso.com"
$ARecordName = "scenario02"

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
$SiteUrl = "http://scenario02.contoso.com/"
$SiteTemplate = "BLANKINTERNETCONTAINER#0"
$SiteLcid = 1033
$SiteOwner = "CONTOSO\administrator"
$SiteName = "Contoso Business Portal"

Write-Host ([String]::Format("Creating new site collection at URL {0}...", $SiteUrl)) -NoNewline
$NewSite = New-SPSite -Url $SiteUrl -Language $SiteLcid -Template $SiteTemplate -Name $SiteName -OwnerAlias $SiteOwner -HostHeaderWebApplication $HostingWebApp
Write-Host "Done!"

$solutionPackageName = "Scenario02.wsp"

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

$page1FileName = "About.aspx"
$page2FileName = "Company.aspx"

Enable-SPFeature -Identity "Scenario02_News" -Url $SiteUrl

$site = Get-SPSite -Identity $SiteUrl
if($site -ne $null) 
{
  $web = $site.RootWeb
  $pubWeb = [Microsoft.SharePoint.Publishing.PublishingWeb]::GetPublishingWeb($web)
  $pageLayout = $pubWeb.GetAvailablePageLayouts() | Where-Object {$_.Title -eq "News Article Left"}
  
  $page = $pubWeb.GetPublishingPages().Add($page1FileName, $pageLayout)
  $page.Title = "About"
  $pageItem = $page.ListItem
  $pageItem["Comments"] = "New page description"
  $pageItem["PublishingContactName"] = "User SP1"
  $pageItem["PublishingContactEmail"] = "usersp1@contoso.com"
  $pageItem["PublishingPageContent"] = "Video provides a powerful way to help you prove your point. When you click Online Video, you can paste in the embed code for the video you want to add. You can also type a keyword to search online for the video that best fits your document. To make your document look professionally produced, Word provides header, footer, cover page, and text box designs that complement each other. For example, you can add a matching cover page, header, and sidebar. Click Insert and then choose the elements you want from the different galleries. Themes and styles also help keep your document coordinated. When you click Design and choose a new Theme, the pictures, charts, and SmartArt graphics change to match your new theme. When you apply styles, your headings change to match the new theme. Save time in Word with new buttons that show up where you need them. To change the way a picture fits in your document, click it and a button for layout options appears next to it."
  $page.Update()
  $page.CheckIn("Checked in by PowerShell script")
  $page.listItem.File.Publish("Published by PowerShell script")
  #$page.listItem.File.Approve("Approved by PowerShell script")

  $page = $pubWeb.GetPublishingPages().Add($page2FileName, $pageLayout)
  $page.Title = "Company"
  $pageItem = $page.ListItem
  $pageItem["Comments"]="New page description"
  $pageItem["PublishingContactName"]="User SP1"
  $pageItem["PublishingContactEmail"]="usersp1@contoso.com"
  $pageItem["PublishingPageContent"] = "When you work on a table, click where you want to add a row or a column, and then click the plus sign. Reading is easier, too, in the new Reading view. You can collapse parts of the document and focus on the text you want. If you need to stop reading before you reach the end, Word remembers where you left off - even on another device. Video provides a powerful way to help you prove your point. When you click Online Video, you can paste in the embed code for the video you want to add. You can also type a keyword to search online for the video that best fits your document. To make your document look professionally produced, Word provides header, footer, cover page, and text box designs that complement each other."
  $page.Update()
  $page.CheckIn("Checked in by PowerShell script")
  $page.listItem.File.Publish("Published by PowerShell script")
  #$page.listItem.File.Approve("Approved by PowerShell script")
}

$SqlServerName = "DCSQL"
$SqlPortNumber = 1433

Function CreateSqlAlias
{
    Param (
    [string]$SqlAlias, 
    [string]$SqlServer, 
    [int]$PortNumber)

    #These are the two Registry locations for the SQL Alias locations
    $x64 = "HKLM:\Software\Microsoft\MSSQLServer\Client\ConnectTo"
    $x86 = "HKLM:\Software\Wow6432Node\Microsoft\MSSQLServer\Client\ConnectTo"
    $TCPAlias = "DBMSSOCN," + $SqlServer + "," + $PortNumber

    if ((Test-Path -path $x64) -ne $true)
    {        
        New-Item $x64 | Out-Null
    }

    New-ItemProperty -Path $x64 -Name $SqlAlias -PropertyType String -Value $TCPAlias | Out-Null
}

# Set Alias
$SqlAliasName = "SPContent"
CreateSqlAlias $SqlAliasName $SqlServerName $SqlPortNumber

Write-Host "Create SQL Artifacts"
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null

# Get Database
$srv = New-Object Microsoft.SqlServer.Management.Smo.Server("DCSQL")

$db = $srv.Databases["AdventureWorks2012"];
$db.SetOwner("Contoso\svcSPAdmin", $true)

# Create stored procedure 
if (-not $db.StoredProcedures.Contains("uspGetTransactionHistory"))
{
    $sp = New-Object -TypeName Microsoft.SqlServer.Management.SMO.StoredProcedure -ArgumentList $db, "uspGetTransactionHistory"
    $sp.TextMode = $false
    $type = [Microsoft.SqlServer.Management.SMO.DataType]::Int
    $param = New-Object -TypeName Microsoft.SqlServer.Management.SMO.StoredProcedureParameter -ArgumentList $sp, "@TopRows", $type
    $param.DefaultValue = 5
    $sp.Parameters.Add($param)
    $sp.TextBody = @"
BEGIN
    --ThirdParty Developer: This should be removed once we are in production - for testing only...
    DECLARE @DelayTime datetime; 
    SET @DelayTime = DATEADD(SECOND, @TopRows, '00:00:00') 
    WaitFor Delay @DelayTime
END
"@ 
    $sp.Create()
}
else
{
    $sp = $db.StoredProcedures.Item("uspGetTransactionHistory")
}


# Verify Login and Apply Execute permissions
if (-not $srv.Logins.Contains("CONTOSO\svcSPAccess"))
{
    $login = New-Object('Microsoft.SqlServer.Management.Smo.Login') $srv, "CONTOSO\svcSPAccess"
    $login.LoginType = [Microsoft.SqlServer.Management.Smo.LoginType]::WindowsUser; 
    $login.Create()    
}
else
{
    $login = $srv.Logins.Item("CONTOSO\svcSPAccess")
}


if (-not $db.Users.Contains("CONTOSO\svcSPAccess"))
{
    $user = New-Object('Microsoft.SqlServer.Management.Smo.User') $db, $login.Name
    $user.Login = $login.Name
    $user.Create();
}

$perm = New-Object("Microsoft.SqlServer.Management.Smo.ObjectPermissionSet")
$perm.Execute = $true;
$sp.Grant($perm, $login.Name);    