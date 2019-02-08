# Define some base variables
$fwHost = "<your machine name>"
$encryptedApiKey = Get-Content D:\Temp\securekey.txt | ConvertTo-SecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($encryptedApiKey)
$apiKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
$ageLimit = (Get-Date).AddDays(90)

# Configure cipher suite to avoid protocol downgrade
$protocol = [System.Net.SecurityProtocolType]'Tls12' # Valid options are 'Ssl3,Tls,Tls11,Tls12'
[System.Net.ServicePointManager]::SecurityProtocol = $protocol

# Bag the current running configuration
$apiCheck = Invoke-WebRequest -Uri "https://$fwHost/api/?type=op&cmd=<show><system><masterkey-properties></masterkey-properties></system></show>&key=$apiKey"

# Bag the master key attributes
$statResponse = New-Object System.Xml.XmlDocument
$statResponse.Load("https://$fwHost/api/?type=op&cmd=<show><system><masterkey-properties></masterkey-properties></system></show>&key=$apiKey")
$rawExpiryDate = $statResponse.response.result.'expire-at' | Out-String
[datetime]$expiryDate = Get-Date $rawExpiryDate -Format "yyy/MM/dd H:m:s"

# Compose the "OK" message body
$okmessageBody = @"
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
            Beep boop. I'm a bot. The master key of firewall host $fwHost will expire in 30 days or less, at $expiryDate.
        </p>
        <p>
			I will keep nagging you until you change it, because remember what happened when you didn't..?
        </p>
    </body>
</html>
"@

# Compose the "error" message body
$errMessageBody = @"
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
            Beep boop. I'm a bot. The script running on $env:COMPUTERNAME to check the master key lifetime on $fwHost has failed.
        </p>
        <p>
			Log on to $env:COMPUTERNAME to test the output of the script.
        </p>
    </body>
</html>
"@

# If the HTTP response is not 200 (OK), send the message
if ($apiCheck.StatusCode -ne 200)
{
	Send-MailMessage -UseSsl -BodyAsHtml -To someone@contoso.com -From noreply@contoso.com -SmtpServer smtp.contoso.com -Subject "Master Key check for $fwHost Encountered an Error!" -Body $errMessageBody -Priority High
}

# Evaluate the key expiry and send a message is it's below $ageLimit
if ($expiryDate -lt $ageLimit)
{
	Send-MailMessage -UseSsl -BodyAsHtml -To someone@contoso.com -From noreply@contoso.com -SmtpServer smtp.contoso.com -Subject "Master Key for $fwHost is reaching expiry!" -Body $okmessageBody -Priority High
}
