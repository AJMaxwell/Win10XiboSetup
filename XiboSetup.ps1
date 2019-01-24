# PowerShell does not define HKCR by default, so it's up to us...
New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT

# Running PowerShell scripts "as Administrator" is annoying...
# So let's just ask for Admin privileges from the start!
Function Check-Elevation {
	# Get the ID and security principal of the current user account
	$myWindowsID = [System.Security.Principal.WindowsIdentity]::GetCurrent()
	$myWindowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal($myWindowsID)

	# Get the security principal for the Administrator role
	$adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator

	# Check to see if we are currently running "as Administrator"
	if ($myWindowsPrincipal.IsInRole($adminRole)) {
		# We are running "as Administrator"
		# change the title and background color to indicate this
		$Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + "(Elevated)"
		$Host.UI.RawUI.BackgroundColor = "Black"
		clear-host
	} else {
		# We're not running "as Administrator" - relaunch as administrator
		Write-Host "Elevating Script..."

		# Create a new process object that starts PowerShell
		$newProcess = New-Object System.Diagnostics.ProcessStartInfo "PowerShell"

		# Specify the current script path and name as a parameter
		$newProcess.Arguments = "-noexit", $myInvocation.MyCommand.Definition, "$(Get-Location)";

		# Indicate that the process should be elevated
		$newProcess.Verb = "runas"

		# Start the new process
		[System.Diagnostics.Process]::Start($newProcess)

		# Exit from the current, unelevated process
		exit
	}
}


# Add "Take Ownership" to right-click context menus
Function Take-Ownership {
	Write-Host -NoNewline "Adding 'Take Ownership' to right-click context menus"

	$toContextTitle = "Take Ownership"
	$toFileCommand = 'cmd.exe /c takeown /f \"%1\" && icacls \"%1\" /grant administrators:F'
	$toDirCommand = 'cmd.exe /c takeown /f \"%1\" /r /d y && icacls \"%1\" /grant administrators:F /t'

	# New-Item does not accept -LiteralPath, so double backticks (``) are used to escape the *
	New-Item -Path "HKCR:\``*\shell" -Name "runas" -Value $toContextTitle -Force | Out-Null; Write-Host -NoNewline "."
	New-ItemProperty -LiteralPath  "HKCR:\*\shell\runas" -Name "NoWorkingDirectory" -Value "" -PropertyType STRING -Force | Out-Null; Write-Host -NoNewline "."

	New-Item -Path "HKCR:\``*\shell\runas" -Name "command" -Value $toFileCommand -Force | Out-Null; Write-Host -NoNewline "."
	New-ItemProperty -LiteralPath "HKCR:\*\shell\runas\command" -Name "IsolatedCommand" -Value $toFileCommand -Force | Out-Null; Write-Host -NoNewline "."


	New-Item -Path "HKCR:\Directory\shell" -Name "runas" -Value $toContextTitle -Force | Out-Null; Write-Host -NoNewline "."
	New-ItemProperty -Path "HKCR:\Directory\shell\runas" -Name "NoWorkingDirectory" -Value "" -PropertyType STRING -Force | Out-Null; Write-Host -NoNewline "."

	New-Item -Path "HKCR:\Directory\shell\runas" -Name "command" -Value $toDirCommand -Force | Out-Null; Write-Host -NoNewline "."
	New-ItemProperty -Path "HKCR:\Directory\shell\runas\command" -Name "IsolatedCommand" -Value $toDirCommand -Force | Out-Null; Write-Host -NoNewline "."

	"DONE!"
}


# Set Default Screen Resolution
#
# This will set a default resolution of 1920x1080, even when the screen is off.
#
# WARNING: This will reset the default resolution of ALL monitors/screens that
# have ever been connected to this machine. It probably won't be a problem, but
# you should be aware of what's happening.
Function Default-ScreenRes {
	Write-Host -NoNewline "Setting default screen resolution"

	$defaultWidth = "1920"
	$defaultHeight = "1080"

	$DefaultSettingsLoc = "HKLM:\SYSTEM\ControlSet001\Hardware Profiles\UnitedVideo\CONTROL\VIDEO\*\0000", "HKLM:\SYSTEM\ControlSet001\Hardware Profiles\UnitedVideo\SERVICES\BASICDISPLAY", "HKLM:\SYSTEM\CurrentControlSet\Hardware Profiles\UnitedVideo\CONTROL\VIDEO\*\0000"

	$PrimSurfSizeLoc = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Configuration\*\00", "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Configuration\*\00\00"

	$ActiveSizeLoc = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Configuration\*\00\00"

	ForEach ($loc in $DefaultSettingsLoc) {
		IF(Test-Path $loc) {
			New-ItemProperty -Path $loc -Name "DefaultSettings.XResolution" -Value $defaultWidth -PropertyType DWORD -Force | Out-Null; Write-Host -NoNewline "."
			New-ItemProperty -Path $loc -Name "DefaultSettings.YResolution" -Value $defaultHeight -PropertyType DWORD -Force | Out-Null; Write-Host -NoNewline "."
		}
	}

	ForEach ($loc in $PrimSurfSizeLoc) {
		IF(Test-Path $loc) {
			New-ItemProperty -Path $loc -Name "PrimSurfSize.cx" -Value $defaultWidth -PropertyType DWORD -Force | Out-Null; Write-Host -NoNewline "."
			New-ItemProperty -Path $loc -Name "PrimSurfSize.cy" -Value $defaultHeight -PropertyType DWORD -Force | Out-Null; Write-Host -NoNewline "."
		}
	}

	ForEach ($loc in $ActiveSizeLoc) {
		IF(Test-Path $loc) {
			New-ItemProperty -Path $loc -Name "ActiveSize.cx" -Value $defaultWidth -PropertyType DWORD -Force | Out-Null; Write-Host -NoNewline "."
			New-ItemProperty -Path $loc -Name "ActiveSize.cy" -Value $defaultHeight -PropertyType DWORD -Force | Out-Null; Write-Host -NoNewline "."
		}
	}

	"DONE!"
}


# Enabled HTML5 in Xibo
#
# This is supposed to be done when by the Xibo player installer, but it doesn't seem
# to happen. This gives you the ability to use a different version of IE within Xibo.
#
# Values: https://msdn.microsoft.com/en-us/library/ee330730(VS.85).aspx#browser_emulation
Function Xibo-Html5 {

	Write-Host -NoNewline "Enabling HTML5 in Xibo"

	New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_BROWSER_EMULATION" -Name "XiboClient.exe" -Value "11000" -PropertyType DWORD -Force | Out-Null; Write-Host -NoNewline "  "

	"DONE!"
}

# Disable Cortana
Function Disable-Cortana {
	Write-Host -NoNewline "Disabling Cortana"

	New-Item -Path "HKLM:\Software\Policies\Microsoft" -Name "Windows Search" -Force | Out-Null; Write-Host -NoNewline "."
	New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows Search" -Name "AllowCortana" -Value 0 -PropertyType DWORD -Force | Out-Null; Write-Host -NoNewline "."

	"DONE! (make super sure that it's disabled)"
	# If that doesn't work....
	# https://superuser.com/a/949641/767285
	#
	# 1. Navigate to: C:\Windows
	# 2. Create new folder "SystemApps.bak"
	# 3. Take ownership of: C:\Windows\SystemApps\Microsoft.Windows.Cortana_cw5n1h2txyewy
	#	3.1 Take ownership of anything else you wish to move
	# 4. Cut/Paste the folder(s) from SystemApps to SystemApps.bak
	# 5. When the "Permissions" pop-up appears, switch to Task Manager
	# 6. Kill SearchUI.exe process
	# 7. Switch back and give permission to move the folder
	#
	# Simply move the folder back into SystemApps to re-enable Cortana (or whatever you disabled)
}

Check-Elevation
Take-Ownership
Default-ScreenRes
Xibo-Html5
Disable-Cortana
Write-Host "All Tasks Completed."

#"Press any key to continue..."
#$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
#[void](Read-Host 'Press Enter to exit ')
