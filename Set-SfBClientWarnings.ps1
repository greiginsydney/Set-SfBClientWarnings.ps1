<#
.SYNOPSIS
This script sets/resets the warning messages that the Lync Client presents to the user usually when 
they're about to do something that will end a session or possibly impact their priacy settings.

.DESCRIPTION
As a power-user I find it annoying to have to reset the "yes I know what I'm doing" flags after each
PC rebuild, or at the start of each new customer deployment. This script lets you both reset to default
(which is great for when you're delivering training) and also to set them back to power-user mode.

.NOTES
Version             : 12th March 2017
Date                : 9th January 2017
Author              : Greig Sheridan
Revision History    :
			
			v2.0    : 12th March 2017
					Renamed to "Set-SfBClientWarnings". (Was previously Set-Lync2013ClientWarnings.ps1)
					Added the "DSFTAndOthersClose" key
			
			v1.5	: 9th January 2017
					Added the "DSEditOofNote" & "DsCloseRGSCall" keys
					Updated the code-signing certificate

			v1.4	: 4th October 2015
					Added more registry keys to the list: DSCloseVideo, DSMultiModeClose & DSBranchOfficeWarning
					Added Office 2016 compatibility.
					
			v1.3	: 14th February 2015
					Added more registry keys to the list.
					Provided individual switches to flexibly add the keys for E.911/Location & "close all conversations".
					Neatened the CmdletBinding. Makes for a more accurate "get-help" output & blocks unsupported "-WhatIf" and "-Confirm".
					Code-signed the script.
						
			v1.2	: 10th May 2014	
					Added new registry keys for Blocking, Unblocking, Tagging a contact, and for when you close a parked 
						call window. (I've added these images to the blog post).
			
			v1.1	: 28th April 2014	
					Thank you Stale Hansen for pointing out a flaw in my logic. If the box has previously popped and 
						you chose not to agree, the registry key is created but set to 0. Revised loop to accommodate.

			v1.0    : 18th April 2014
			
.LINK
https://greiginsydney.com/Set-Lync2013ClientWarnings-ps1

.EXAMPLE
.\Set-SfBClientWarnings.ps1
Description
-----------
With no command-line parameters, it will output this help text.

.EXAMPLE
.\Set-SfBClientWarnings.ps1 Default
Description
-----------
Deletes the existing registry container "HKCU:\Software\Microsoft\Office\15.0\Lync\<username@domain>\DS\"
This re-enables all of Lync's "are you sure you want to do that Dave?" warning messages

.EXAMPLE
.\Set-SfBClientWarnings.ps1 Expert
Description
-----------
Creates a registry container at "HKCU:\Software\Microsoft\Office\15.0\Lync\<username@domain>\DS\" 
(if it's not there already) and the properies underneath to ensure the standard warning messages are suppressed

.EXAMPLE
.\Set-SfBClientWarnings.ps1 Expert -IncludeCloseAllTabs -IncludeLocationWarning
Description
-----------
Creates a registry container at "HKCU:\Software\Microsoft\Office\15.0\Lync\<username@domain>\DS\" 
(if it's not there already) and the properies underneath to ensure the standard warning messages are suppressed,
including the optional keys "DontShowCWCloseTabQuery" and "DontShowLocationWarning"

.PARAMETER Action
There are 6 valid values (Default, Novice, Beginner, Power, Expert, Guru) but there are only two outcomes:
resetting to default (warnings on) or expert mode (warnings off).

.PARAMETER IncludeCloseAllTabs
Boolean. If present and Action is Power, Expert or Guru, it will also add the "DontShowCWCloseTabQuery" key

.PARAMETER IncludeLocationWarning
Boolean. If present and Action is Power, Expert or Guru, it will also add the "DontShowLocationWarning" key

#>

[CmdletBinding(SupportsShouldProcess = $False, DefaultParameterSetName='None')]
param(
[parameter(ParameterSetName='Default',ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Mandatory = $false, Position=1)]
[ValidateSet("Default", "Novice", "Beginner", "Power", "Expert", "Guru")]
[String]$Action="",
[Parameter(ParameterSetName='Default', Mandatory = $false)]
[alias("tabs")][switch]$IncludeCloseAllTabs,
[Parameter(ParameterSetName='Default', Mandatory = $false)]
[alias("location")][switch]$IncludeLocationWarning
)

if ($Action -eq "")
{
	get-help .\Set-SfBClientWarnings.ps1 -examples
	exit
}

switch ($Action)
{
	{($_ -eq "Default") -or ($_ -eq "Novice") -or ($_ -eq "Beginner")}
	{
		$ActionType = "Delete"
	}
	default
	{
		$ActionType = "Set"
	}
}

#Now add all of the registry keys to the list:
$PropertyList = @()
$PropertyList += "DSCLOSEVOICE"			# Exiting an audio call
$PropertyList += "DSCLOSEVOICEVIDEO"	# Exiting a video call
$PropertyList += "DSLogoutCloseConversations"	# Logging out will close conversations
$PropertyList += "DSStartAppsharingNotification" # Click to share a program, your screen, or a specific monitor. (Multiple triggers)
$PropertyList += "DSAppsharingGrantControlNotification"	# Grant control automatically
$PropertyList += "DSAppsharingGrantControlToSpecificPersonNotification" # Grant control to a specific person
$PropertyList += "DSCLOSELSCONF"		# Exiting a meeting you're hosting
$PropertyList += "DSBlock"				# Block a contact
$PropertyList += "DSUnblock"			# Unblock a contact
$PropertyList += "DSTaggingAddsContact" # Tagging someone for Status Change Alerts adds them as a contact
$PropertyList += "DsCloseCallPark"		# Park a call - close the window
$PropertyList += "DSPublishNumberTell"	# Edit a phone number in your personal contacts, or check/uncheck “Include in my contact card”.
$PropertyList += "SetDelegatesNotice"	# Edit your Delegates or Team Call list (Multiple triggers)
$PropertyList += "DSCLOSEPBX"			# Thank you Pragathi Raj: DSCLOSEPBX -> is seen when user is RCC enabled and is trying to end the call !
$PropertyList += "DSCLOSEVIDEO"			# Click "End Video" during a call
$PropertyList += "DSMultiModeClose" 	# I can't find what the trigger is for this one
$PropertyList += "DSBRANCHOFFICEWARNING"# You're in "Limited Functionality" mode
$PropertyList += "DSEditOofNote"		# You're changing the Personal Note *from* your OOF message
$PropertyList += "DsCloseRGSCall"		# ??
$PropertyList += "DSFTAndOthersClose"	# Only ever seen once, this one fired when I was engaging with a bot via IM at Microsoft.




if ($IncludeCloseAllTabs)    { $PropertyList += "DontShowCWCloseTabQuery" } # Close the conversation window with "Tabbed Conversations" checked & multiple IMs active
if ($IncludeLocationWarning) { $PropertyList += "DontShowLocationWarning" } # This will pop if you click “X” to dismiss the “Set Your Location” prompt. 

#This retrieves each of the SIP Accounts that exist under the Office 2013 Lync branch:
$Office15RegKeys = Get-ChildItem "HKCU:\Software\Microsoft\Office\15.0\Lync\"  -ea silentlycontinue | Where-Object {$_.PSChildName -match "@"}
#This retrieves each of the SIP Accounts that exist under the Office 2016 Lync branch:
$Office16RegKeys = Get-ChildItem "HKCU:\Software\Microsoft\Office\16.0\Lync\"  -ea silentlycontinue | Where-Object {$_.PSChildName -match "@"}

#Merge the two lists together
$LyncRegKeys = @($Office15RegKeys) + @($Office16RegKeys)

#Loop through each account:
foreach ($LyncRegKey in $LyncRegKeys)
{
	$DsPath = $LyncRegKey.PSPath + "\DS"
	if ($ActionType -eq "Delete")
	{
		#Here we just delete the entire "DS" container for each user.
		# (It's created by Lync the first time you OK one of the messages, so it's safe to take an axe to the entire container).
		if (test-path -path $DsPath)
		{
			Remove-Item -Path $DsPath 
		}
	}
	else
	{
		#Here we add the container (if needed) and populate the properties if they're not there already.
		if (!(test-path -path $DsPath)) {New-Item -Path $DsPath | out-null}
		
		foreach ($property in $PropertyList)
		{
			if (get-itemproperty -path $DsPath -name $property -ErrorAction SilentlyContinue)
			{
				#It exists. Make sure it's set to 1
				Set-ItemProperty -Path $DsPath -name $property -Value 1 | out-null
			}
			else
			{
				#Add it!
				New-ItemProperty -Path $DsPath -name $property -PropertyType Dword -Value 1 | out-null
			}
		}
	}
}

#Code signing certificate kindly provided by Digicert:
# SIG # Begin signature block
# MIIceAYJKoZIhvcNAQcCoIIcaTCCHGUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU4CCC36gMiQoJiW9B2k1Xbsl4
# +A+gghenMIIFMDCCBBigAwIBAgIQA1GDBusaADXxu0naTkLwYTANBgkqhkiG9w0B
# AQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
# c3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMB4XDTIwMDQxNzAwMDAwMFoXDTIxMDcw
# MTEyMDAwMFowbTELMAkGA1UEBhMCQVUxGDAWBgNVBAgTD05ldyBTb3V0aCBXYWxl
# czESMBAGA1UEBxMJUGV0ZXJzaGFtMRcwFQYDVQQKEw5HcmVpZyBTaGVyaWRhbjEX
# MBUGA1UEAxMOR3JlaWcgU2hlcmlkYW4wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAw
# ggEKAoIBAQC0PMhHbI+fkQcYFNzZHgVAuyE3BErOYAVBsCjZgWFMhqvhEq08El/W
# PNdtlcOaTPMdyEibyJY8ZZTOepPVjtHGFPI08z5F6BkAmyJ7eFpR9EyCd6JRJZ9R
# ibq3e2mfqnv2wB0rOmRjnIX6XW6dMdfs/iFaSK4pJAqejme5Lcboea4ZJDCoWOK7
# bUWkoqlY+CazC/Cb48ZguPzacF5qHoDjmpeVS4/mRB4frPj56OvKns4Nf7gOZpQS
# 956BgagHr92iy3GkExAdr9ys5cDsTA49GwSabwpwDcgobJ+cYeBc1tGElWHVOx0F
# 24wBBfcDG8KL78bpqOzXhlsyDkOXKM21AgMBAAGjggHFMIIBwTAfBgNVHSMEGDAW
# gBRaxLl7KgqjpepxA8Bg+S32ZXUOWDAdBgNVHQ4EFgQUzBwyYxT+LFH+GuVtHo2S
# mSHS/N0wDgYDVR0PAQH/BAQDAgeAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMHcGA1Ud
# HwRwMG4wNaAzoDGGL2h0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9zaGEyLWFzc3Vy
# ZWQtY3MtZzEuY3JsMDWgM6Axhi9odHRwOi8vY3JsNC5kaWdpY2VydC5jb20vc2hh
# Mi1hc3N1cmVkLWNzLWcxLmNybDBMBgNVHSAERTBDMDcGCWCGSAGG/WwDATAqMCgG
# CCsGAQUFBwIBFhxodHRwczovL3d3dy5kaWdpY2VydC5jb20vQ1BTMAgGBmeBDAEE
# ATCBhAYIKwYBBQUHAQEEeDB2MCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdp
# Y2VydC5jb20wTgYIKwYBBQUHMAKGQmh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNv
# bS9EaWdpQ2VydFNIQTJBc3N1cmVkSURDb2RlU2lnbmluZ0NBLmNydDAMBgNVHRMB
# Af8EAjAAMA0GCSqGSIb3DQEBCwUAA4IBAQCtV/Nu/2vgu+rHGFI6gssYWfYLEwXO
# eJqOYcYYjb7dk5sRTninaUpKt4WPuFo9OroNOrw6bhvPKdzYArXLCGbnvi40LaJI
# AOr9+V/+rmVrHXcYxQiWLwKI5NKnzxB2sJzM0vpSzlj1+fa5kCnpKY6qeuv7QUCZ
# 1+tHunxKW2oF+mBD1MV2S4+Qgl4pT9q2ygh9DO5TPxC91lbuT5p1/flI/3dHBJd+
# KZ9vYGdsJO5vS4MscsCYTrRXvgvj0wl+Nwumowu4O0ROqLRdxCZ+1X6a5zNdrk4w
# Dbdznv3E3s3My8Axuaea4WHulgAvPosFrB44e/VHDraIcNCx/GBKNYs8MIIFMDCC
# BBigAwIBAgIQBAkYG1/Vu2Z1U0O1b5VQCDANBgkqhkiG9w0BAQsFADBlMQswCQYD
# VQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGln
# aWNlcnQuY29tMSQwIgYDVQQDExtEaWdpQ2VydCBBc3N1cmVkIElEIFJvb3QgQ0Ew
# HhcNMTMxMDIyMTIwMDAwWhcNMjgxMDIyMTIwMDAwWjByMQswCQYDVQQGEwJVUzEV
# MBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29t
# MTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFzc3VyZWQgSUQgQ29kZSBTaWduaW5n
# IENBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA+NOzHH8OEa9ndwfT
# CzFJGc/Q+0WZsTrbRPV/5aid2zLXcep2nQUut4/6kkPApfmJ1DcZ17aq8JyGpdgl
# rA55KDp+6dFn08b7KSfH03sjlOSRI5aQd4L5oYQjZhJUM1B0sSgmuyRpwsJS8hRn
# iolF1C2ho+mILCCVrhxKhwjfDPXiTWAYvqrEsq5wMWYzcT6scKKrzn/pfMuSoeU7
# MRzP6vIK5Fe7SrXpdOYr/mzLfnQ5Ng2Q7+S1TqSp6moKq4TzrGdOtcT3jNEgJSPr
# CGQ+UpbB8g8S9MWOD8Gi6CxR93O8vYWxYoNzQYIH5DiLanMg0A9kczyen6Yzqf0Z
# 3yWT0QIDAQABo4IBzTCCAckwEgYDVR0TAQH/BAgwBgEB/wIBADAOBgNVHQ8BAf8E
# BAMCAYYwEwYDVR0lBAwwCgYIKwYBBQUHAwMweQYIKwYBBQUHAQEEbTBrMCQGCCsG
# AQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wQwYIKwYBBQUHMAKGN2h0
# dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RD
# QS5jcnQwgYEGA1UdHwR6MHgwOqA4oDaGNGh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNv
# bS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcmwwOqA4oDaGNGh0dHA6Ly9jcmwz
# LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcmwwTwYDVR0g
# BEgwRjA4BgpghkgBhv1sAAIEMCowKAYIKwYBBQUHAgEWHGh0dHBzOi8vd3d3LmRp
# Z2ljZXJ0LmNvbS9DUFMwCgYIYIZIAYb9bAMwHQYDVR0OBBYEFFrEuXsqCqOl6nED
# wGD5LfZldQ5YMB8GA1UdIwQYMBaAFEXroq/0ksuCMS1Ri6enIZ3zbcgPMA0GCSqG
# SIb3DQEBCwUAA4IBAQA+7A1aJLPzItEVyCx8JSl2qB1dHC06GsTvMGHXfgtg/cM9
# D8Svi/3vKt8gVTew4fbRknUPUbRupY5a4l4kgU4QpO4/cY5jDhNLrddfRHnzNhQG
# ivecRk5c/5CxGwcOkRX7uq+1UcKNJK4kxscnKqEpKBo6cSgCPC6Ro8AlEeKcFEeh
# emhor5unXCBc2XGxDI+7qPjFEmifz0DLQESlE/DmZAwlCEIysjaKJAL+L3J+HNdJ
# RZboWR3p+nRka7LrZkPas7CM1ekN3fYBIM6ZMWM9CBoYs4GbT8aTEAb8B4H6i9r5
# gkn3Ym6hU/oSlBiFLpKR6mhsRDKyZqHnGKSaZFHvMIIGajCCBVKgAwIBAgIQAwGa
# Ajr/WLFr1tXq5hfwZjANBgkqhkiG9w0BAQUFADBiMQswCQYDVQQGEwJVUzEVMBMG
# A1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSEw
# HwYDVQQDExhEaWdpQ2VydCBBc3N1cmVkIElEIENBLTEwHhcNMTQxMDIyMDAwMDAw
# WhcNMjQxMDIyMDAwMDAwWjBHMQswCQYDVQQGEwJVUzERMA8GA1UEChMIRGlnaUNl
# cnQxJTAjBgNVBAMTHERpZ2lDZXJ0IFRpbWVzdGFtcCBSZXNwb25kZXIwggEiMA0G
# CSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCjZF38fLPggjXg4PbGKuZJdTvMbuBT
# qZ8fZFnmfGt/a4ydVfiS457VWmNbAklQ2YPOb2bu3cuF6V+l+dSHdIhEOxnJ5fWR
# n8YUOawk6qhLLJGJzF4o9GS2ULf1ErNzlgpno75hn67z/RJ4dQ6mWxT9RSOOhkRV
# fRiGBYxVh3lIRvfKDo2n3k5f4qi2LVkCYYhhchhoubh87ubnNC8xd4EwH7s2AY3v
# J+P3mvBMMWSN4+v6GYeofs/sjAw2W3rBerh4x8kGLkYQyI3oBGDbvHN0+k7Y/qpA
# 8bLOcEaD6dpAoVk62RUJV5lWMJPzyWHM0AjMa+xiQpGsAsDvpPCJEY93AgMBAAGj
# ggM1MIIDMTAOBgNVHQ8BAf8EBAMCB4AwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8E
# DDAKBggrBgEFBQcDCDCCAb8GA1UdIASCAbYwggGyMIIBoQYJYIZIAYb9bAcBMIIB
# kjAoBggrBgEFBQcCARYcaHR0cHM6Ly93d3cuZGlnaWNlcnQuY29tL0NQUzCCAWQG
# CCsGAQUFBwICMIIBVh6CAVIAQQBuAHkAIAB1AHMAZQAgAG8AZgAgAHQAaABpAHMA
# IABDAGUAcgB0AGkAZgBpAGMAYQB0AGUAIABjAG8AbgBzAHQAaQB0AHUAdABlAHMA
# IABhAGMAYwBlAHAAdABhAG4AYwBlACAAbwBmACAAdABoAGUAIABEAGkAZwBpAEMA
# ZQByAHQAIABDAFAALwBDAFAAUwAgAGEAbgBkACAAdABoAGUAIABSAGUAbAB5AGkA
# bgBnACAAUABhAHIAdAB5ACAAQQBnAHIAZQBlAG0AZQBuAHQAIAB3AGgAaQBjAGgA
# IABsAGkAbQBpAHQAIABsAGkAYQBiAGkAbABpAHQAeQAgAGEAbgBkACAAYQByAGUA
# IABpAG4AYwBvAHIAcABvAHIAYQB0AGUAZAAgAGgAZQByAGUAaQBuACAAYgB5ACAA
# cgBlAGYAZQByAGUAbgBjAGUALjALBglghkgBhv1sAxUwHwYDVR0jBBgwFoAUFQAS
# KxOYspkH7R7for5XDStnAs0wHQYDVR0OBBYEFGFaTSS2STKdSip5GoNL9B6Jwcp9
# MH0GA1UdHwR2MHQwOKA2oDSGMmh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdp
# Q2VydEFzc3VyZWRJRENBLTEuY3JsMDigNqA0hjJodHRwOi8vY3JsNC5kaWdpY2Vy
# dC5jb20vRGlnaUNlcnRBc3N1cmVkSURDQS0xLmNybDB3BggrBgEFBQcBAQRrMGkw
# JAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBBBggrBgEFBQcw
# AoY1aHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElE
# Q0EtMS5jcnQwDQYJKoZIhvcNAQEFBQADggEBAJ0lfhszTbImgVybhs4jIA+Ah+WI
# //+x1GosMe06FxlxF82pG7xaFjkAneNshORaQPveBgGMN/qbsZ0kfv4gpFetW7ea
# sGAm6mlXIV00Lx9xsIOUGQVrNZAQoHuXx/Y/5+IRQaa9YtnwJz04HShvOlIJ8Oxw
# YtNiS7Dgc6aSwNOOMdgv420XEwbu5AO2FKvzj0OncZ0h3RTKFV2SQdr5D4HRmXQN
# JsQOfxu19aDxxncGKBXp2JPlVRbwuwqrHNtcSCdmyKOLChzlldquxC5ZoGHd2vNt
# omHpigtt7BIYvfdVVEADkitrwlHCCkivsNRu4PQUCjob4489yq9qjXvc2EQwggbN
# MIIFtaADAgECAhAG/fkDlgOt6gAK6z8nu7obMA0GCSqGSIb3DQEBBQUAMGUxCzAJ
# BgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5k
# aWdpY2VydC5jb20xJDAiBgNVBAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBD
# QTAeFw0wNjExMTAwMDAwMDBaFw0yMTExMTAwMDAwMDBaMGIxCzAJBgNVBAYTAlVT
# MRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5j
# b20xITAfBgNVBAMTGERpZ2lDZXJ0IEFzc3VyZWQgSUQgQ0EtMTCCASIwDQYJKoZI
# hvcNAQEBBQADggEPADCCAQoCggEBAOiCLZn5ysJClaWAc0Bw0p5WVFypxNJBBo/J
# M/xNRZFcgZ/tLJz4FlnfnrUkFcKYubR3SdyJxArar8tea+2tsHEx6886QAxGTZPs
# i3o2CAOrDDT+GEmC/sfHMUiAfB6iD5IOUMnGh+s2P9gww/+m9/uizW9zI/6sVgWQ
# 8DIhFonGcIj5BZd9o8dD3QLoOz3tsUGj7T++25VIxO4es/K8DCuZ0MZdEkKB4YNu
# gnM/JksUkK5ZZgrEjb7SzgaurYRvSISbT0C58Uzyr5j79s5AXVz2qPEvr+yJIvJr
# GGWxwXOt1/HYzx4KdFxCuGh+t9V3CidWfA9ipD8yFGCV/QcEogkCAwEAAaOCA3ow
# ggN2MA4GA1UdDwEB/wQEAwIBhjA7BgNVHSUENDAyBggrBgEFBQcDAQYIKwYBBQUH
# AwIGCCsGAQUFBwMDBggrBgEFBQcDBAYIKwYBBQUHAwgwggHSBgNVHSAEggHJMIIB
# xTCCAbQGCmCGSAGG/WwAAQQwggGkMDoGCCsGAQUFBwIBFi5odHRwOi8vd3d3LmRp
# Z2ljZXJ0LmNvbS9zc2wtY3BzLXJlcG9zaXRvcnkuaHRtMIIBZAYIKwYBBQUHAgIw
# ggFWHoIBUgBBAG4AeQAgAHUAcwBlACAAbwBmACAAdABoAGkAcwAgAEMAZQByAHQA
# aQBmAGkAYwBhAHQAZQAgAGMAbwBuAHMAdABpAHQAdQB0AGUAcwAgAGEAYwBjAGUA
# cAB0AGEAbgBjAGUAIABvAGYAIAB0AGgAZQAgAEQAaQBnAGkAQwBlAHIAdAAgAEMA
# UAAvAEMAUABTACAAYQBuAGQAIAB0AGgAZQAgAFIAZQBsAHkAaQBuAGcAIABQAGEA
# cgB0AHkAIABBAGcAcgBlAGUAbQBlAG4AdAAgAHcAaABpAGMAaAAgAGwAaQBtAGkA
# dAAgAGwAaQBhAGIAaQBsAGkAdAB5ACAAYQBuAGQAIABhAHIAZQAgAGkAbgBjAG8A
# cgBwAG8AcgBhAHQAZQBkACAAaABlAHIAZQBpAG4AIABiAHkAIAByAGUAZgBlAHIA
# ZQBuAGMAZQAuMAsGCWCGSAGG/WwDFTASBgNVHRMBAf8ECDAGAQH/AgEAMHkGCCsG
# AQUFBwEBBG0wazAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29t
# MEMGCCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNl
# cnRBc3N1cmVkSURSb290Q0EuY3J0MIGBBgNVHR8EejB4MDqgOKA2hjRodHRwOi8v
# Y3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsMDqg
# OKA2hjRodHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURS
# b290Q0EuY3JsMB0GA1UdDgQWBBQVABIrE5iymQftHt+ivlcNK2cCzTAfBgNVHSME
# GDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzANBgkqhkiG9w0BAQUFAAOCAQEARlA+
# ybcoJKc4HbZbKa9Sz1LpMUerVlx71Q0LQbPv7HUfdDjyslxhopyVw1Dkgrkj0bo6
# hnKtOHisdV0XFzRyR4WUVtHruzaEd8wkpfMEGVWp5+Pnq2LN+4stkMLA0rWUvV5P
# sQXSDj0aqRRbpoYxYqioM+SbOafE9c4deHaUJXPkKqvPnHZL7V/CSxbkS3BMAIke
# /MV5vEwSV/5f4R68Al2o/vsHOE8Nxl2RuQ9nRc3Wg+3nkg2NsWmMT/tZ4CMP0qqu
# AHzunEIOz5HXJ7cW7g/DvXwKoO4sCFWFIrjrGBpN/CohrUkxg0eVd3HcsRtLSxwQ
# nHcUwZ1PL1qVCCkQJjGCBDswggQ3AgEBMIGGMHIxCzAJBgNVBAYTAlVTMRUwEwYD
# VQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xMTAv
# BgNVBAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcgQ0EC
# EANRgwbrGgA18btJ2k5C8GEwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwxCjAI
# oAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIB
# CzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFLYpxL72RisDdo8ovTTS
# H4wT8ye7MA0GCSqGSIb3DQEBAQUABIIBAE8bGcAK5q1xgaw2vFcLidCTamKdLs5F
# TG20m1L0KsrVkYBSK33VwaYGx3WY718xewYtRfOu3RSGuWMn3uhVLDtDbC9YZO73
# +VKcIUxB+2b2TN03ClyyeDH4TUmFXgX9OygS00qfoEMziW3QR1k6TyH9G/smeLjM
# +tohaVz1ayMTl7dz48c/6jITXquI8+vzGfErNS/C8jlOw4xqn+J4jcjMHjhvuOCj
# Z12NRJJ6FImVNF0RUo5TZXqxzbnVaReIowmlre8EZ7OKAeAn+azn43onIazYcYkl
# IyZWv286I43a9xf4EJv09YGO6H+oNJZsVw8JKyb1eeKFtj/VW59VgjehggIPMIIC
# CwYJKoZIhvcNAQkGMYIB/DCCAfgCAQEwdjBiMQswCQYDVQQGEwJVUzEVMBMGA1UE
# ChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSEwHwYD
# VQQDExhEaWdpQ2VydCBBc3N1cmVkIElEIENBLTECEAMBmgI6/1ixa9bV6uYX8GYw
# CQYFKw4DAhoFAKBdMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcN
# AQkFMQ8XDTIwMDUwNTExMzMwNlowIwYJKoZIhvcNAQkEMRYEFKx0TX/F+4nEjyC/
# NjjZAWn8XmW8MA0GCSqGSIb3DQEBAQUABIIBAJUjVf7Pgr7XwnuOAXXxSHXyshOk
# lVLzd9Tu4HIiwfo9CRFFFY9/iVsOFsFZh+Feojzsq7UuK6MJ2Qv/EzGBrK67EH1N
# EHzv08i8L1LZVdsDpzaUYf17pReD+rxtxot7VSkUKmxzbd5I4L8fmroslvFyDeau
# lB7T0WHS1b6Vya7ECd0zl7NZjdtx5NV2qA5amsLuoBbIFp3WnhFXGtk6Kjy21Ydg
# FH4rvazjJamwabUrlhtc9usqN45fm7bWspveUEcht1NhjHIc9ponSvBSQQEU1M99
# C7CyMQMprDtAd5eZjrppvTNWZmD0Wu5IRxwTRucd5Nw9QsP3UAyP8JoXRW0=
# SIG # End signature block
