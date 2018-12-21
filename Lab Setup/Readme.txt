The workshop uses the SP2013 Administration workshop lab setup and additional PowerShell scripts to modify the environment and provision the Scenarios.

How to configure the Hyper-V bridge to allow RDP connections to the machines:
- IP:			192.168.2.10
- Subnet Mask:	255.255.255.0
- DNS:			192.168.2.2
Now you can RDP to 192.168.2.3 (SP01) with login contoso\svcSPadmin and password Pass@word1.

To setup the environment, each student should copy the Scripts and Tools folders to the SP01 machine. Extract the files.
Then, from an elevated PowerShell prompt, start the SPCHOT-Lab.Setup.ps1 in the Scripts folder.
During the setup, it will be asked a domain admin account to update the DNS entries: contoso\Administrator, Pass@word1.

The Tools will be used during the Scenarios.

You can also copy the Misc folder.