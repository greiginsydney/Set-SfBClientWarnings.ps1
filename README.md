# Set-SfBClientWarnings.ps1

This script will set the necessary registry keys to either suppress all of Lync's precautionary warning messages, or - perhaps if you're about to deliver training - reset them all so they'll show.


<span style="color: #ff0000; font-size: small;">**This is version 2.0 - 12th March 2017. It adds 1 new registry key: "DSFTAndOthersClose".&nbsp;**

<span style="color: #ff0000; font-size: small;">**Renamed from "Set-Lync2013ClientWarnings.ps1" to "Set-SfBClientWarnings.ps1"**


I rebuild my PC occasionally and also regularly deploy Skype for Business for new customers. With each new rebuild the client pops lots of precautionary warning messages that (as an experienced user) I can do without.

This script adds the registry keys to suppress them, or - perhaps if you're about to deliver training - deletes the keys to turn them all back on again.

There are also separate switches for a couple of 'special' messages you might not want suppressed.

The messages it suppresses (and the triggers to get them to pop) are all shown in detail on my blog:

<a href="https://greiginsydney.com/set-lync2013clientwarnings-ps1/" target="_blank">https://greiginsydney.com/set-lync2013clientwarnings-ps1/</a>


This is just a sample:

<img src="https://user-images.githubusercontent.com/11004787/81054080-7c3be880-8f09-11ea-813c-28cb3798c240.png" alt="" width="400" />

<img src="https://user-images.githubusercontent.com/11004787/81054144-9bd31100-8f09-11ea-93d6-73bfb4f6211d.png" alt="" width="400" />

<img src="https://user-images.githubusercontent.com/11004787/81054185-ad1c1d80-8f09-11ea-95ff-e66185b59d84.png" alt="" width="400" />


The script comes with inbuilt help & is code-signed (with thanks to DigiCert).

The syntax is pretty simple:

```powershell 
PS W:\> .\Set-SfBClientWarnings.ps1 expert
```

```powershell 
PS W:\> .\Set-SfBClientWarnings.ps1 expert -IncludeCloseAllTabs -IncludeLocationWarning
```

```powershell 
PS W:\> .\Set-SfBClientWarnings.ps1 default
```


\- G.

<br>

This script was originally published at https://greiginsydney.com/set-lync2013clientwarnings-ps1/](https://greiginsydney.com/set-lync2013clientwarnings-ps1/).

