# Define some base variables
$fwHost = "<your machine name>"
$encryptedApiKey = Get-Content D:\Temp\securekey.txt | ConvertTo-SecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($encryptedApiKey)
$apiKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
$ageLimit = (Get-Date).AddDays(-90)

# Configure cipher suite to avoid protocol downgrade
$protocol = [System.Net.SecurityProtocolType]'Tls12' # Valid options are 'Ssl3,Tls,Tls11,Tls12'
[System.Net.ServicePointManager]::SecurityProtocol = $protocol

# Bag the current running configuration
$configExport = Invoke-WebRequest -Uri "https://$fwHost/api/?type=export&category=configuration&key=$apiKey"

# Generate time stamp
$timeStamp = Get-Date -UFormat "%Y%m%d-%H%M"

# Send en error if the export was unsuccessful
# Compose the message body
$messageBody = @"
<!DOCTYPE html>
<html>
    <style type="text/css"> 
        body {
            font-family: sans-serif;
            font-size: 14px;
        }
    </style>
    <body>
        <p>
            Beep boop. I'm a bot. The script running on $env:COMPUTERNAME to export the config of $fwHost has failed.
        </p>
        <p>
			Log on to $env:COMPUTERNAME to test the output of the script.
        </p>
    </body>
</html>
"@

# If the HTTP response is not 200 (OK), send the message
if ($configExport.StatusCode -ne 200)
{
	Send-MailMessage -UseSsl -BodyAsHtml -To someone@contoso.com -From noreply@contoso.com -SmtpServer smtp.contoso.com -Subject "Config Export for $fwHost Encountered an Error!" -Body $messageBody -Priority High
}
else
{
	$configExport.Content | Out-File -FilePath "D:\Temp\config-$timeStamp.xml"
}

# Delete configs older than the defined number of days
Get-ChildItem -Path "D:\Temp" -Exclude *.txt | Where-Object {$_.CreationTime -lt $ageLimit} | Remove-Item -Force