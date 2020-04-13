# Set-SfBClientWarnings.ps1

This script will set the necessary registry keys to either suppress all of Lync's precautionary warning messages, or - perhaps if you're about to deliver training - reset them all so they'll show.

<p>&nbsp;</p>
<p><span style="color: #ff0000; font-size: small;"><strong>This is version 2.0 - 12th March 2017. It adds 1 new registry key: "DSFTAndOthersClose".&nbsp;</strong></span></p>
<p><span style="color: #ff0000; font-size: small;"><strong>Renamed from "Set-Lync2013ClientWarnings.ps1" to "Set-SfBClientWarnings.ps1"</strong></span></p>
<p>&nbsp;</p>
<p><span style="font-size: small;">I rebuild my PC occasionally and also regularly deploy Skype for Business for new customers. With each new rebuild the client pops lots of precautionary warning messages that (as an experienced user) I can do without.</span></p>
<p><span style="font-size: small;">This script adds the registry keys to suppress them, or - perhaps if you're about to deliver training - deletes the keys to turn them all back on again.</span></p>
<p><span style="font-size: small;">There are also separate switches for a couple of 'special' messages you might not want suppressed.</span></p>
<p><span style="font-size: small;">The messages it suppresses (and the triggers to get them to pop) are all shown in detail on my blog:</span></p>
<p><span style="font-size: small;"><a href="https://greiginsydney.com/set-lync2013clientwarnings-ps1/" target="_blank">https://greiginsydney.com/set-lync2013clientwarnings-ps1/</a></span></p>
<p>&nbsp;</p>
<p><span style="font-size: small;">This is just a sample:</span></p>
<p><img id="133803" src="/site/view/file/133803/1/ClosingThisWindowWillEndTheCurrentPhoneCall2.PNG" alt="" width="348" height="232" /></p>
<p><img id="133804" src="/site/view/file/133804/1/OnceBlockedThisPersonWontSee2.PNG" alt="" width="348" height="343" /></p>
<p><img id="133805" src="/site/view/file/133805/1/DoYouWantToCloseAllTabs2.PNG" alt="" width="502" height="214" /></p>
<p>&nbsp;</p>
<p><span style="font-size: small;">The script comes with inbuilt help &amp; is code-signed (with thanks to DigiCert).</span></p>
<p>&nbsp;</p>
<p><span style="font-size: small;">The syntax is pretty simple:</span></p>
<p>&nbsp;</p>
<pre><span style="font-size: small;">PS W:\&gt; .\Set-SfBClientWarnings.ps1 expert</span></pre>
<pre><span style="font-size: small;">PS W:\&gt; .\Set-SfBClientWarnings.ps1 expert -IncludeCloseAllTabs -IncludeLocationWarning</span></pre>
<pre><span style="font-size: small;">PS W:\&gt; .\Set-SfBClientWarnings.ps1 default<br /></span></pre>
<pre><span style="font-size: small;"><br /></span></pre>
<pre><span style="font-size: small;"><br /></span></pre>
<p><span style="font-size: small;">- Greig.</span></p>
