# Scripts for managing Palo Alto PAN-OS Devices

These scripts are used to manage Palo Alto PAN-OS devices using their XML APi.

The following variables must be populated:

$fwHost - should be populated with the fully-qualified hostname of the appliance.

$encryptedApiKey - should be populated with the location of the encrypted text file that contains your API key. Details that explain how to generate this file can be found [here](https://social.technet.microsoft.com/wiki/contents/articles/4546.working-with-passwords-secure-strings-and-credentials-in-windows-powershell.aspx).

$ageLimit - can be edited to define the number of days old configurations should be retained for.

Also populate email addresses for failure messages.

Further reading about the PAN-OS XML API is available [here](https://www.paloaltonetworks.com/documentation/80/pan-os/xml-api.html).