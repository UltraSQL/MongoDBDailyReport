#----------------------------------------------------------------#
# MTools.PS1
# Author: UltraSQL, 09/09/2015
# 
# Comment: 1. Use Mtools Analyze MongoDB Performance
#          2. Send MongoDB Daily Report E-mail
#----------------------------------------------------------------#


$path = "D:\DBA\MTools\"
$log = Join-Path $path "MToolsLog.txt"

# Analyze MongoDB Log by MTools
$mongodblog = "\\DBXI2.SL.DX\dbbackup\Backup_Mgo13\mongod.log"

$connectionpicture = Join-Path $path "Connections.png"
$conectionsourcefile = Join-Path $path "ConnectionSource.log"
$slowqueryfile = Join-Path $path "SlowQuery.log"
$overflowfile = Join-Path $path "Overflow.log"

try
{
    # MTools
    mplotqueries $mongodblog --type connchurn --bucketsize 1800 --output-file $connectionpicture
    mloginfo $mongodblog --connections | Out-File -FilePath $conectionsourcefile
    mlogfilter --namespace PattayaMall.Product --slow 5000 $mongodblog | Out-File -FilePath $slowqueryfile
    
    # Overflow
    Select-String -Path $mongodblog -Pattern "Overflow" | Out-File -FilePath $overflowfile
}
catch
{
    $ErrorInfo = "`r`n############## $(Get-Date -uFormat '%Y-%m-%d %T') ##############`r`n"
    $ErrorInfo = $ErrorInfo + "############## Error: Analyze MongoDB Log ##############`r`n"
    $ErrorInfo = $ErrorInfo + $_.Exception.Message
    $ErrorInfo | Out-File -FilePath $log -Append
}

# Send E-Mail
$images = @{ 
    Connections = Join-Path $path "Connections.png"
}

$attachments = @(
    Get-ChildItem $path *.log | %{$_.FullName}
)
  
$body = Get-Content (Join-Path $path "Body.txt") | out-string

$pwd = Get-Content  (Join-Path $path  "Mailpwd.txt")
$pwd = ConvertTo-SecureString -String $pwd -Key (2..17)
$credential = New-Object System.Management.Automation.PSCredential("Notice@comepro.com",$pwd)
  
$params = @{ 
    InlineAttachments = $images 
    Attachments = $attachments
    Body = $body 
    BodyAsHtml = $true 
    Subject = 'MongoDB Daily Report' 
    From = 'Notice@comepro.com' 
    To = 'xucy@comepro.com' 
    Cc = 'sharmi.liu@comepro.com', '18925205210@139.com' 
    SmtpServer = 'mail.comepro.com' 
    Port = 25 
    Credential = $credential
    #UseSsl = $true 
} 

try
{
    Send-MailMessage @params
}
catch
{
    $ErrorInfo = "`r`n############## $(Get-Date -uFormat '%Y-%m-%d %T') ##############`r`n"
    $ErrorInfo = $ErrorInfo + "############## Error: Send E-Mail ##############`r`n"
    $ErrorInfo = $ErrorInfo + $_.Exception.Message
    $ErrorInfo | Out-File -FilePath $log -Append
}
