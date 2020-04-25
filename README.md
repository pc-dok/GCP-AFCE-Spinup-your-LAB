##### Goal of this LAB: 
- Demonstrate how easy you can use IAC and AFCE to spinup your LAB in every Cloud without needing the GUI.
- I will not show or explain you what terraform or visual studio code is. You can google here everything.
- For me terraform is the ideal way -to make Infrastructure as Code in a way what also a not code tekkie is
- understanding, because terraform files (.tf) are human readable --Code. So it is easy for normal Guys as me :)

`````
-- In our first Demo i will spinup a LAB Environment in the Google Cloud.
-- I will create there a MDT Server, and than for demostrating a -- DomainController,
-- what is taking from the MDT Server the Tasqsequence. The big different in Cloud is,
-- that you have no PXE Environment, so you only need MDT Features but without PXE or
-- Importing OS over ISO Files etc. In this example i will create a low cost Environment,
-- so no External IP Addresses will be used what generate Costs. I have in this Demo also
-- a VPN Tunnel to my pfsense@home. (You can spinup all your Servers also with a External
-- IP Address and without NAT. It depends than on how many Server you will host. For 2-5 Servers
-- i think you can take also External Addresses. When you want i can share also this example than.)
`````
##### What you must edit:
`````
- variables.tf file must be edit with your variable names etc...
- Passwords in the cloud.ps1 and dc1.ps1
`````
