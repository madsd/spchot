Write-Host "Setting up SPCHOT Cloud Hosted Labs"


$rootSetupPath = $PSScriptRoot
if ($rootSetupPath -eq "")
{
	$rootSetupPath = (Get-Location).Path
}

if (-not $dnsCreds)
{
    $dnsCreds = Get-Credential -Message "Credentials for DNS Admin" -UserName "CONTOSO\Administrator"
}

Get-Date

Write-Host "Set keyboard language"
#Set-WinUserLanguageList -LanguageList da-dk -Confirm:$false -Force:$true

Write-Host "Add contoso.com to Intranet Zone"

if (-not (Test-Path -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\contoso.com'))
{
    $null = New-Item -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\contoso.com'
}

Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\contoso.com' -Name * -Value 1 -Type DWord

asnp *SharePoint* -EA 0

Write-Host "Disable Incremental Crawl and reset Search"
$sa = Get-SPEnterpriseSearchServiceApplication
$ca = Get-SPEnterpriseSearchCrawlContentSource -SearchApplication $sa
$ca.IncrementalCrawlSchedule = $null
$ca.Update()

Stop-Service -Name SPSearchHostController
Start-Service -Name SPSearchHostController

Write-Host "Stop services"
Get-SPServiceInstance -Server SP01 | ? TypeName -like App* | Stop-SPServiceInstance -Confirm:$false | Out-Null
Get-SPServiceInstance -Server SP01 | ? TypeName -like Access* | Stop-SPServiceInstance -Confirm:$false | Out-Null
Get-SPServiceInstance -Server SP01 | ? TypeName -like Business* | Stop-SPServiceInstance -Confirm:$false | Out-Null
Get-SPServiceInstance -Server SP01 | ? TypeName -like Secure* | Stop-SPServiceInstance -Confirm:$false | Out-Null
Get-SPServiceInstance -Server SP01 | ? TypeName -like Claims* | Stop-SPServiceInstance -Confirm:$false | Out-Null
Get-SPServiceInstance -Server SP01 | ? TypeName -like Performance* | Stop-SPServiceInstance -Confirm:$false | Out-Null
Get-SPServiceInstance -Server SP01 | ? TypeName -like SQL* | Stop-SPServiceInstance -Confirm:$false | Out-Null
Get-SPServiceInstance -Server SP01 | ? TypeName -like Visio* | Stop-SPServiceInstance -Confirm:$false | Out-Null
Get-SPServiceInstance -Server SP01 | ? TypeName -like Excel* | Stop-SPServiceInstance -Confirm:$false | Out-Null
Get-SPServiceInstance -Server SP01 | ? TypeName -like *Subscription* | Stop-SPServiceInstance -Confirm:$false | Out-Null
Get-SPServiceInstance -Server SP01 | ? TypeName -like *Incoming* | Stop-SPServiceInstance -Confirm:$false | Out-Null

iisreset

$setupPath = Join-Path $rootSetupPath "Scenario01\SPCHOT-Scenario01.Setup.ps1"
. $setupPath

$setupPath = Join-Path $rootSetupPath "Scenario02\SPCHOT-Scenario02.Setup.ps1"
. $setupPath

$setupPath = Join-Path $rootSetupPath "Scenario03\SPCHOT-Scenario03.Setup.ps1"
. $setupPath

$setupPath = Join-Path $rootSetupPath "Scenario04\SPCHOT-Scenario04.Setup.ps1"
. $setupPath

$setupPath = Join-Path $rootSetupPath "Scenario05\SPCHOT-Scenario05.Setup.ps1"
. $setupPath

Get-Date