# startstop.ps1
# Batch startup and shutdown for windows based computer labs.

#region About
	# Configuration #
	# At the moment the only configuration needed is to populate a file called
	# `Computers.csv` with a list of the "PODS" (groups of computers) that you
	# want to be able to start and stop. An example Computers.csv is included
	# in this repository.

	# Usage #
	# The script expects `Computers.csv` to exist in the same folder as the
	# script. 
#endregion

#region License
	#The MIT License (MIT)
	#
	#Copyright (c) 2015 Elliott Saille
	#
	#Permission is hereby granted, free of charge, to any person obtaining a copy
	#of this software and associated documentation files (the "Software"), to deal
	#in the Software without restriction, including without limitation the rights
	#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	#copies of the Software, and to permit persons to whom the Software is
	#furnished to do so, subject to the following conditions:
	#
	#The above copyright notice and this permission notice shall be included in all
	#copies or substantial portions of the Software.
	#
	#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	#SOFTWARE.
#endregion

#region TODO List
	# TODO:
	# * Add Menubar with File and Help Menus to facilitate loading different lists of computers
#endregion

# Load .net assemblies for creating windows forms
#region .NET Assemblies
Add-Type -AssemblyName mscorlib
Add-Type -AssemblyName System
Add-Type -AssemblyName System.IO
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Data
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Xml
Add-Type -AssemblyName System.DirectoryServices
Add-Type -AssemblyName System.Core
Add-Type -AssemblyName System.ServiceProcess
#endregion

#Enable Visual Styles
[System.Windows.Forms.Application]::EnableVisualStyles()

#region Control Helper Functions
function Load-ListBox {
<#
	.SYNOPSIS
		This functions helps you load items into a ListBox or CheckedListBox.

	.DESCRIPTION
		Use this function to dynamically load items into the ListBox control.

	.PARAMETER  ListBox
		The ListBox control you want to add items to.

	.PARAMETER  Items
		The object or objects you wish to load into the ListBox's Items collection.

	.PARAMETER  DisplayMember
		Indicates the property to display for the items in this control.

	.PARAMETER  Append
		Adds the item(s) to the ListBox without clearing the Items collection.

	.EXAMPLE
		Load-ListBox $ListBox1 "Red", "White", "Blue"

	.EXAMPLE
		Load-ListBox $listBox1 "Red" -Append
		Load-ListBox $listBox1 "White" -Append
		Load-ListBox $listBox1 "Blue" -Append

	.EXAMPLE
		Load-ListBox $listBox1 (Get-Process) "ProcessName"
#>
	Param (
		[ValidateNotNull()]
		[Parameter(Mandatory = $true)]
		[System.Windows.Forms.ListBox]$ListBox,
		[ValidateNotNull()]
		[Parameter(Mandatory = $true)]
		$Items,
		[Parameter(Mandatory = $false)]
		[string]$DisplayMember,
		[switch]$Append
	)

	if(-not $Append) {
		$listBox.Items.Clear()
	}

	if($Items -is [System.Windows.Forms.ListBox+ObjectCollection]) {
		$listBox.Items.AddRange($Items)
	}
	elseif($Items -is [Array]) {
		$listBox.BeginUpdate()
		foreach($obj in $Items) {$listBox.Items.Add($obj)}
		$listBox.EndUpdate()
	}
	else {$listBox.Items.Add($Items)}

	$listBox.DisplayMember = $DisplayMember
}
#endregion

#region Program Helper Functions
	function Send-WOL {
		<#
		.SYNOPSIS
			Send a WOL packet to a broadcast address
		.PARAMETER mac
		The MAC address of the device that need to wake up
		.PARAMETER ip
		The IP address where the WOL packet will be sent to
		.EXAMPLE
		Send-WOL -mac 00:11:32:21:2D:11 -ip 192.168.8.255
		#>
		param([string]$mac, [string]$ip=255.255.255.255, [int]$port=9)

		$broadcast = [Net.IPAddress]::Parse($ip)
		$mac=(($mac.replace(":","")).replace("-","")).replace(".","")
		$target=0,2,4,6,8,10 | % {[convert]::ToByte($mac.substring($_,2),16)}

		$packet = (,[byte]255 * 6) + ($target * 20)

		$UDPclient = new-Object System.Net.Sockets.UdpClient
		$UDPclient.Connect($broadcast,$port)
		[void]$UDPclient.Send($packet, $packet.Length)
	}
	function OnApplicationLoad {return $true} #Give the all clear
	function OnApplicationExit {$script:ExitCode = 0} # Exit with status 0
#endregion

#region Global Variables
	# Easy access to the .net newline character
	$newline = [Environment]::NewLine

	#Get path to script
	$path = Split-Path -Parent $script:MyInvocation.MyCommand.Path -ErrorAction 'Stop'
    
    #region Base64 Encoded Icon
            [string]$icon=@"
AAABAAEAgIAAAAEAIAAoCAEAFgAAACgAAACAAAAAAAEAAAEAIAAAAAAAAAABABILAAASCwAAAAAAAAAA
AAD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6Zzo6Oio6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8AOjo6ADo6OgA6OjoAOjo6ADo6Oko6OjryOjo6rjo6Ogk6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoA////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wA6OjoAOjo6ADo6
OgA6OjpKOjo68Do6Ov86Ojr/Ojo6qTo6Ogk6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////ADo6OgA6OjoAOjo6Sjo6OvA6Ojr/Ojo6/zo6Ov86Ojr/Ojo6qTo6
Ogk6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8AOjo6ADo6
Oko6OjrwOjo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6qTo6Ogk6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6gzo6Ol86OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoA////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wA6OjpsOjo6+Do6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6qTo6Ogk6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OoQ6Ojr/Ojo6+Do6
OlY6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////ADo6
OjU6Ojq5Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6qTo6Ogk6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjqEOjo6/zo6Ov86Ojr/Ojo69jo6OlY6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8AOjo6ADo6Og86Ojq1Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6qTo6Ogk6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6hDo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo69jo6OlY6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoA////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wA6OjoAOjo6ADo6Og86Ojq1Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6qTo6
Ogk6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OoQ6Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo69jo6OlY6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////ADo6OgA6OjoAOjo6ADo6Og86Ojq1Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6qTo6Ogk6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjqEOjo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo69jo6OlY6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8AOjo6ADo6OgA6OjoAOjo6ADo6Og86Ojq1Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6qTo6Ogk6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6hDo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo69jo6
OlY6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoA////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
Og86Ojq1Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6qTo6Ogk6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OoQ6Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo69jo6OlY6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6Og86Ojq1Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6qTo6Ogk6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjqEOjo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo69jo6OlU6OjoAOjo6DDo6OkU6Ojp7Ojo6ozo6OrY6Ojq5Ojo6tTo6OqA6Ojp4Ojo6QTo6
Ogs6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8AOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6Og86Ojq1Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6szo6
Og86OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6hDo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo68jo6Op46OjrXOjo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr+Ojo61jo6OoI6OjofOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoA////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6Og86Ojq1Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojq+Ojo6ETo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OoQ6Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6OuY6Ojp0Ojo6BDo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6Og86Ojq1Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6tTo6
Og86OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjqEOjo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojq0Ojo6HDo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8AOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
Og86Ojq1Ojo6/zo6Ov86Ojr/Ojo6/zo6OrU6OjoPOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6hDo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86OjrUOjo6Ijo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoA////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6Og86Ojq1Ojo6/zo6Ov86Ojq1Ojo6Dzo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OoQ6Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86OjrWOjo6Ijo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6Og86Ojq9Ojo6vTo6Og86OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjqEOjo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86OjrWOjo6Ijo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8AOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6Og86OjoPOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6hDo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6fDo6OqA6Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86OjrWOjo6Ijo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoA////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OoQ6Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ons6OjoAOjo6Bzo6
Oqk6Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86OjrWOjo6Ijo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjqEOjo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojp7Ojo6ADo6OgA6OjoAOjo6CTo6Oqk6Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86OjrWOjo6Ijo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8AOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6hDo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6ezo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6CTo6Oqk6Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo61jo6
OsA6OjrYOjo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86OjrWOjo6Ijo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoA////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OoQ6Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ons6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6CTo6Oqk6Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo62Do6Oks6OjoIOjo6ATo6Ogk6OjpSOjo63Do6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86OjrWOjo6Ijo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjqEOjo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojp7Ojo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6CTo6Oqk6Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6OtY6OjojOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjokOjo61jo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86OjrWOjo6Ijo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8AOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6hDo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6ezo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6CTo6
Oqk6Ojr/Ojo6/zo6Ov86OjrWOjo6Ijo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoiOjo61jo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86OjrWOjo6Ijo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoA////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OoQ6Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ons6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6CTo6Oqk6Ojr/Ojo61zo6OiI6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoiOjo61jo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86OjrWOjo6Ijo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjqEOjo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojp7Ojo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6Cjo6Oos6OjoqOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoiOjo61jo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86OjrWOjo6Ijo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8AOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6hDo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6ezo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoiOjo61jo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86OjrWOjo6Ijo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoA////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OoQ6Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ons6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoiOjo61jo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86OjrWOjo6Ijo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjqEOjo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojp7Ojo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoiOjo61jo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86OjrWOjo6Ijo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8AOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6hDo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6ezo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoiOjo61jo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86OjrWOjo6Ijo6OgA6OjoAOjo6ADo6OgA6OjoA////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OoQ6Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ons6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoiOjo61jo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86OjrWOjo6Ijo6OgA6OjoAOjo6ADo6OgD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjqEOjo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojp7Ojo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjohOjo6yzo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86OjrYOjo6Ljo6OgA6OjoAOjo6AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8AOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoGOjo6hTo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr5Ojo6ejo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjqKOjo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86OjpwOjo6ADo6OgA6OjoA////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6Ok06Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6OrI6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ezo6Ov46Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6hDo6OgE6OjoAOjo6ADo6
OgD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6Czo6OpE6Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo69Do6Om46OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6Ons6Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6OoQ6OjoAOjo6ADo6OgA6OjoAOjo6AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8AOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OpA6Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Om86OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6Ojp7Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86OjqEOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoA////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OpA6Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Om86OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ezo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6hDo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OpA6Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Om86OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6Ons6Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6OoQ6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8AOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OpA6Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Om86OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6Ojp7Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86OjqEOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoA////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OpA6Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Om86OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ezo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6hDo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OpA6Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Om86OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
Ons6Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6+To6
OoA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8AOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OpA6Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6OnY6OjoEOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6Ojp7Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86OjrfOjo6Ejo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoA////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6Oo86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo61To6Og46OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ezo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojq/Ojo6FTo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6Ujo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6OtY6OjolOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6Ons6Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86OjrBOjo6FTo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8AOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjqvOjo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86OjrWOjo6Ijo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6Ojp7Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86OjrBOjo6FTo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoA////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6Fjo6Ouo6Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo61jo6OiI6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ezo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86OjrBOjo6FTo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjpAOjo6/jo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
OuU6OjokOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6Ons6Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86OjrBOjo6FTo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8AOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6Ol46Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6dDo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6Ojp7Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86OjrBOjo6FTo6OgA6OjoAOjo6ADo6OgA6OjoA////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6bzo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ovs6OjozOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ezo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6+Do6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86OjrBOjo6FTo6OgA6OjoAOjo6ADo6
OgD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjpwOjo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6+jo6Oi06OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6Ons6Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Onw6Ojo+Ojo66jo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86OjrBOjo6FTo6OgA6OjoAOjo6AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8AOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OmQ6Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6VTo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6Ojp7Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86OjqEOjo6ADo6OgA6Ojo+Ojo66jo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86OjrBOjo6FTo6
OgA6OjoA////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6Szo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86OjrCOjo6BTo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ezo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6hDo6OgA6OjoAOjo6ADo6OgA6Ojo+Ojo66jo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86OjrAOjo6Ejo6OgD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjokOjo69Do6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86OjqUOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6Ons6Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6OoQ6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6Ojo+Ojo66jo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86OjqdOjo6EP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8AOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgM6OjrHOjo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86OjqQOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6Ojp7Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86OjqEOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6Ojo+Ojo66jo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ovw6Ojpn////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6Onk6Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86OjqQOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ezo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6hDo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6Ojo+Ojo66jo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Oqf///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6Hzo6Ou86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86OjqQOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
Ons6Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
OoQ6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6Ojo+Ojo66jo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6tv///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8AOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6hzo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86OjqQOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6Ojp7Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86OjqEOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6Ojo+Ojo66jo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86OjqY////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoSOjo62To6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86OjqQOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ezo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6hDo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6Ojo+Ojo66jo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo67Do6Okr///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6Ojo+Ojo69To6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86OjqQOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6Ons6Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6OoQ6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6Ojo+Ojo66jo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86OjpwOjo6A////wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8AOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjpeOjo6+zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86OjqQOjo6ADo6OgA6OjoAOjo6ADo6OgA6Ojp7Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ovw6Ojp8Ojo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6Ojo3Ojo60Do6Ov86Ojr/Ojo6/zo6Ov86OjrzOjo6ejo6OgA6OjoA////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjpiOjo6+zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86OjqQOjo6ADo6OgA6OjoAOjo6ezo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo69jo6OkY6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoPOjo6Xjo6
Opc6OjqgOjo6fDo6Oi46OjoAOjo6ADo6OgD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjpiOjo6+zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86OjqOOjo6Azo6Ong6Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo67zo6
Oko6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8AOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjpiOjo6+zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86OjrDOjo6/To6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo68Do6Oko6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoA////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjpiOjo6+zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo68Do6Oko6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjpiOjo6+zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo68Do6Oko6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8AOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjpiOjo6+zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo68Do6Oko6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoA////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjpiOjo6+zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo68Do6
Oko6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjpiOjo6+zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6OtQ6Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo68Do6Oko6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8AOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjpiOjo6+zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86OjqAOjo6EDo6Oqc6Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo68Do6Oko6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoA////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjpiOjo6+zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6hDo6OgA6OjoAOjo6CTo6Oqk6Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo68Do6Oko6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjpiOjo6+zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
OoQ6OjoAOjo6ADo6OgA6OjoAOjo6CTo6Oqk6Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo68Do6OkQ6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8AOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjpiOjo6+zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86OjqEOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6CTo6
Oqk6Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo63zo6
OhU6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoA////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjpiOjo6+zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6hDo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6CTo6Oqk6Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6azo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjpiOjo6+zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6OoQ6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6CTo6Oqk6Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86OjqkOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8AOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjpiOjo6+zo6Ov86Ojr/Ojo6/zo6Ov86OjqEOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6CTo6Oqk6Ojr/Ojo6/zo6
Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Oqs6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoA////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjpiOjo6+zo6Ov86Ojr/Ojo6hDo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6CTo6Oqk6Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6hDo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjpkOjo69zo6Oog6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6CTo6
Oqk6Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6Ovk6OjoxOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8AOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6Ojo2Ojo6Ajo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6CTo6Oqk6Ojr/Ojo6/zo6Ov86Ojr/Ojo6/zo6
Ov86Ojr/Ojo6ezo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoA////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6CTo6Oow6OjryOjo6/zo6Ov86Ojr/Ojo65jo6OnE6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6CDo6Olk6OjqbOjo6rTo6
OpI6OjpIOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6
OgA6OjoAOjo6ADo6OgA6OjoAOjo6ADo6OgA6OjoAOjo6AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////n////////////////////w///////////////////
/4H///////////////////8A///////////////////+AH///8///////////////AA///+H////////
//////wAH///A//////////////+AA///gH//////////////wAH//wA//////////////+AA//4AH//
////////////wAH/8AA//////////////+AA/+AAH//////////////wAH/AAAgA////////////+AA/
gAAAAD////////////wAPwAAAAAP///////////+AH4AAAAAB////////////wD8AAAAAAP/////////
//+B+AAAAAAB////////////w/AAAAAAAP///////////+fgAAAAAAB/////////////wAAgAAAAP///
/////////4AAcAAAAB////////////8AAPgAAAAP///////////+AAH8AAAAB////////////AAD/gD4
AAP///////////gAB/8B/AAB///////////wAA//g/4AAP//////////4AAf/8f/AAB//////////8AA
P////4AAP/////////+AAH/////AAB//////////AAD/////4AAP/////////gAB//////AAB///////
//wAA//////4AAP////////4AAf//////AAB////////4AAP//////4AAf///////+AAH//////8AAH/
///////gAA//////+AAH////////+AAH//////AAD/////////wAA//////gAB/////////+AAH/////
wAA//////////wAA/////4AAf/////////+AAH////8AAP//////////wAA////+AAH//////////+AA
D////AAB///////////wAA////gAAP//////////8AAf///wAAB///////////AAP///4AAAP///////
///gAH///8AAAB//////////4AD///+AAAAP/////////+AB////AAAAB//////////gAf///gAAAAP/
////////4AH///wAAAAB/////////+AB///4AAYAAP/////////gAP//8AAPAAB/////////4AD//+AA
H4AAP////////+AAf//AAD/AAD/////////wAD//gAB/4AA/////////8AAf/wAA//AAP/////////gA
D/4AAf/4AD/////////4AAf8AAP//AA//////////AAD+AAH//4AP/////////4AAfAAD///AP//////
////AADgAA///4H//////////4AAAAAH///////////////AAAAAA///////////////4AAAAAH/////
//////////AAAAAA///////////////4AAAAAH///////////////AAAAAA///////////////4AAAAA
H///////////////AAAAAA///////////////4AAMAAH///////////////AAHgAA///////////////
4AD8AAH///////////////AB/gAB///////////////4A/8AAf///////////////Af/gAH/////////
//////4P/8AB////////////////H//gAf///////////////5//8AP///////////////////gH////
///////////////8D///////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////8=
"@
            $iconStream=[System.IO.MemoryStream][System.Convert]::FromBase64String($icon)
            $iconBmp=[System.Drawing.Bitmap][System.Drawing.Image]::FromStream($iconStream)
            $iconHandle=$iconBmp.GetHicon()
            $iconObject=[System.Drawing.Icon]::FromHandle($iconHandle)
    #endregion
#endregion

function Main {
	# Create objects for window and controls
	$librarypower = New-Object 'System.Windows.Forms.Form'
	$listPods = New-Object 'System.Windows.Forms.CheckedListBox'
	$output = New-Object 'System.Windows.Forms.RichTextBox'
	$buttonShutdown = New-Object 'System.Windows.Forms.Button'
	$buttonExit = New-Object 'System.Windows.Forms.Button'
	$buttonStartup = New-Object 'System.Windows.Forms.Button'
	$InitialFormWindowState = New-Object 'System.Windows.Forms.FormWindowState'
    
    If(Test-Path "$path\Computers.csv") {
	    # Import our CSV
	    $computers = Import-CSV "$path\Computers.csv"
    } Else{
        $output.AppendText(
            "Could not load Computers.csv!" + $newline +
		    "Does it exist in the same folder as this program?" + $newline
        )
		$script:ExitCode = 1
    }

	# Get an array of the unique pod numbers in our CSV
	$availablepods = $computers | select -ExpandProperty "POD" -Unique

	$FormEvent_Load = {
		Load-ListBox $listPods $availablepods
	}

	$buttonExit_Click = {
		# Close the progam when we click exit
		$librarypower.Close()
	}

	$buttonStartup_Click = {
		$output.Clear()
		Write-Verbose("Clearing Output Textbox")
		If (-not $listPods.CheckedItems.Count -gt 0) {
			$output.AppendText(
                "Please select at least one POD from the box on the right!" +
                $newline
            )
		}
		Else {
			Write-Verbose "Pods to be executed on: $($listPods.CheckedItems)"
			ForEach ($pod in $listPods.CheckedItems) {
				$output.AppendText("Starting Up Pod #" + $pod + $newline)
				ForEach ($computer in $computers) {
					If ($computer.POD -eq $pod) {
						# If there is a MAC address send WOL packet
						If ($computer.MAC)
						{
							#Write a line saying what we are doing and to what
							$output.AppendText(
                                " * Sending Startup Command to Computer: \\" +
                                $computer.NAME + $newline
                            )

							Write-Verbose("Sending WOL Packet to {0} with MAC {1} on POD {2}" -f $computer.NAME, $computer.MAC, $computer.POD)

							# Send WOL Packet to computer
							Send-WOL -mac $computer.MAC
						}
						Else
						{
							$output.AppendText(
                                " * No MAC Address for computer \\" +
							    $computer.NAME + $newline
                            )
						}
					}
				}
				$output.AppendText($newline)
			}
		}
		$listPods.ClearSelected()
		Write-Verbose("Clearing Checked Pods")
	}

	$buttonShutdown_Click={
		$output.Clear()
		Write-Verbose("Clearing Output Textbox")

        $shutdown = {
            Param($computerName = "Localhost")
            shutdown /s /f /m "\\$($computerName)"
        }

		If (-not $listPods.CheckedItems.Count -gt 0) {
			$output.AppendText("Please select at least one POD from the box on the right!" + $newline)
		}
		Else {
			Write-Verbose "Pods to shutdown: $($listPods.CheckedItems)"
			ForEach ($pod in $listPods.CheckedItems) {
				$output.AppendText("Shutting Down Pod #" + $pod + $newline)
				ForEach ($computer in $computers) {
					If ($computer.POD -eq $pod) {
                        #Write a line saying what we are doing and to what
						$output.AppendText(" * Sending Shutdown Command to Computer: \\" + $computer.NAME + $newline)

						Write-Verbose("Sending Shutdown Command to {0} with MAC {1} on POD {2}" -f $computer.NAME, $computer.MAC, $computer.POD)

						# Shutdown the computer
                        Start-Job -ScriptBlock $shutdown -ArgumentList $computer.NAME -Name $computer.NAME
					}
				}
				$output.AppendText($newline)
			}
            # Wait for jobs to finish and alert write remaining number to output
            While(@(Get-Job | Where-Object { $_.State -eq 'Running' }).Count -gt 0){
                # Get Running Jobs
                $running = @(Get-Job | Where-Object { $_.State -eq 'Running' }).Count
                $output.AppendText(" - Still waiting on $running tasks to finish!" + $newline)
                # FIXME: Find a way to replace only the last line of the textbox that does not reset scroll
                #[System.Collections.ArrayList]$lines = $output.Lines
                #$lines.Remove($lines[$lines.Count - 1])
                #$output.Lines = $lines
                # Sleep for 1s to prevent spamming output
                Sleep -m 5000
            }
            # Remove completed jobs
            @(Get-Job | Where-Object { $_.State -eq 'Completed' }) | Remove-Job
            $output.AppendText(" - All Tasks Complete!")
		}
		$listPods.ClearSelected()
		Write-Verbose("Clearing Checked PODS")
	}

	$Form_StateCorrection_Load=
	{
		#Correct the initial state of the form to prevent the .Net maximized form issue
		$librarypower.WindowState = $InitialFormWindowState
	}

	$Form_Cleanup_FormClosed=
	{
		#Remove all event handlers from the controls
		try
		{
			$listPods.remove_SelectedIndexChanged($listPods_SelectedIndexChanged)
			$buttonShutdown.remove_Click($buttonShutdown_Click)
			$buttonExit.remove_Click($buttonExit_Click)
			$buttonStartup.remove_Click($buttonStartup_Click)
			$librarypower.remove_Load($FormEvent_Load)
			$librarypower.remove_Load($Form_StateCorrection_Load)
			$librarypower.remove_FormClosed($Form_Cleanup_FormClosed)
		}
		catch [Exception]
		{ }
	}

	# Create Form Elements
	#region Form Elements
	# Main View
	$librarypower.SuspendLayout()
	$librarypower.Controls.Add($listPods)
	$librarypower.Controls.Add($output)
	$librarypower.Controls.Add($buttonShutdown)
	$librarypower.Controls.Add($buttonExit)
	$librarypower.Controls.Add($buttonStartup)
	$librarypower.ClientSize = '598, 213'
	$librarypower.MaximumSize = '614, 252'
	$librarypower.MinimumSize = '614, 252'
	$librarypower.Name = "librarypower"
	$librarypower.StartPosition = 'CenterScreen'
	$librarypower.Text = "Startup and Shutdown Library PODS"
	$librarypower.Icon = $iconObject
	$librarypower.add_Load($FormEvent_Load)

	# List of Checkboxes for Pods
	$listPods.Anchor = 'Top, Bottom, Left'
	$listPods.BorderStyle = 'FixedSingle'
	$listPods.CheckOnClick = $True
	$listPods.FormattingEnabled = $True
	$listPods.Location = '12, 12'
	$listPods.Name = "listPods"
	$listPods.Size = '99, 152'
	$listPods.TabIndex = 7
    
    # Create Textbox for Output
	$output.Anchor = 'Top, Bottom, Left, Right'
	$output.BackColor = 'Window'
	$output.BorderStyle = 'FixedSingle'
	$output.Cursor = "Arrow"
	$output.Font = "Courier New, 8.25pt"
	$output.HideSelection = $False
	$output.Location = '117, 12'
	$output.Name = "output"
	$output.ReadOnly = $True
	$output.Size = '468, 152'
	$output.TabIndex = 6
	$output.Text = ""
	$output.WordWrap = $False

	# "Shutdown" Button
	$buttonShutdown.Anchor = 'Bottom'
	$buttonShutdown.Location = '262, 178'
	$buttonShutdown.Name = "buttonShutdown"
	$buttonShutdown.Size = '75, 23'
	$buttonShutdown.TabIndex = 3
	$buttonShutdown.Text = "&Shutdown"
	$buttonShutdown.UseVisualStyleBackColor = $True
	$buttonShutdown.add_Click($buttonShutdown_Click)

	# "Exit" Button
	$buttonExit.Anchor = 'Bottom, Right'
	$buttonExit.Location = '511, 178'
	$buttonExit.Name = "buttonExit"
	$buttonExit.Size = '75, 23'
	$buttonExit.TabIndex = 2
	$buttonExit.Text = "E&xit"
	$buttonExit.UseVisualStyleBackColor = $True
	$buttonExit.add_Click($buttonExit_Click)

	# "Startup" Button
	$buttonStartup.Anchor = 'Bottom, Left'
	$buttonStartup.Location = '12, 178'
	$buttonStartup.Name = "buttonStartup"
	$buttonStartup.Size = '75, 23'
	$buttonStartup.TabIndex = 1
	$buttonStartup.Text = "&Startup"
	$buttonStartup.UseVisualStyleBackColor = $True
	$buttonStartup.add_Click($buttonStartup_Click)
	$librarypower.ResumeLayout()
	#endregion

	# Save the initial state of the form
	$InitialFormWindowState = $librarypower.WindowState
	# Init the OnLoad event to correct the initial state of the form
	$librarypower.add_Load($Form_StateCorrection_Load)
	# Clean up the control events
	$librarypower.add_FormClosed($Form_Cleanup_FormClosed)
	# Show the Form
	return $librarypower.ShowDialog()

}

# Call OnApplicationLoad to initialize
if((OnApplicationLoad) -eq $true)
{
	#Call the form
	Main | Out-Null
	#Perform cleanup
	OnApplicationExit
}