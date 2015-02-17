function OnApplicationLoad {return $true}
function OnApplicationExit {$script:ExitCode = 0}
function Call-libstartstop_psf {
	Add-Type -AssemblyName mscorlib
    Add-Type -AssemblyName System
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Data
    Add-Type -AssemblyName System.Drawing
    Add-Type -AssemblyName System.Xml
    Add-Type -AssemblyName System.DirectoryServices
    Add-Type -AssemblyName System.Core
    Add-Type -AssemblyName System.ServiceProcess

	[System.Windows.Forms.Application]::EnableVisualStyles()
	$librarypower = New-Object 'System.Windows.Forms.Form'
	$listPods = New-Object 'System.Windows.Forms.CheckedListBox'
	$output = New-Object 'System.Windows.Forms.RichTextBox'
	$buttonShutdown = New-Object 'System.Windows.Forms.Button'
	$buttonExit = New-Object 'System.Windows.Forms.Button'
	$buttonStartup = New-Object 'System.Windows.Forms.Button'
	$InitialFormWindowState = New-Object 'System.Windows.Forms.FormWindowState'
    
	#region About
	   # This script Boots and Shuts Down Specific Sets of computers
	   # Computers are stored in a CSV File stored in the same direcory as the script
	#endregion
    
	#region License
	   #
	#endregion
    
	#region TODO List
	   # * Add MIT License
	   # * Add about section
	   # * Put on GitHub
	   # * Add Menubar with File and Help Menus to facilitate loading different lists of computers
	#endregion
	
    #region Control Helper Functions
    	function Load-ListBox
    	{
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
    		
    		if (-not $Append)
    		{
    			$listBox.Items.Clear()
    		}
    		
    		if ($Items -is [System.Windows.Forms.ListBox+ObjectCollection])
    		{
    			$listBox.Items.AddRange($Items)
    		}
    		elseif ($Items -is [Array])
    		{
    			$listBox.BeginUpdate()
    			foreach ($obj in $Items)
    			{
    				$listBox.Items.Add($obj)
    			}
    			$listBox.EndUpdate()
    		}
    		else
    		{
    			$listBox.Items.Add($Items)
    		}
    		
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

            param(
                [string]$mac,
                [string]$ip,
                [int]$port=9
            )
            $broadcast = [Net.IPAddress]::Parse($ip)
            $mac=(($mac.replace(":","")).replace("-","")).replace(".","")
            $target=0,2,4,6,8,10 | % {[convert]::ToByte($mac.substring($_,2),16)}
            
            $packet = (,[byte]255 * 6) + ($target * 20)
            
            $UDPclient = new-Object System.Net.Sockets.UdpClient
            $UDPclient.Connect($broadcast,$port)
            [void]$UDPclient.Send($packet, $packet.Length)
        }
	#endregion
	
	function OnApplicationLoad {return $true} #Give the all clear
	function OnApplicationExit {$script:ExitCode = 0} #Set the exit code for the Packager
	
	# Easy access to the .net newline character
	$newline = [Environment]::NewLine
    
	#Get path to script
	Try {$path = Split-Path -Parent $script:MyInvocation.MyCommand.Path -ErrorAction 'Stop'}
	Catch {
		$output.Text += "Could not get the path of the script!" + $newline +
		"I'm honestly impressed you managed that!" + $newline
	}

	# Import our CSV
	Try {$computers = Import-CSV "$path\Computers.csv" -ErrorAction 'Stop'}
	Catch {
		$output.Text += "Could not load Computers.csv!" + $newline +
		"Does it exist in the same folder as this program?" + $newline
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
		If (-not $listPods.CheckedItems.Count -gt 0) {
			$output.Text += "Please select at least one POD from the box on the right!" + $newline
		}
		Else {
			ForEach ($pod in $listPods.CheckedItems) {
				$output.Text += "Starting Up Pod #" + $pod + $newline
				ForEach ($computer in $computers) {
					If ($computer.POD -eq $pod) {
						# If there is a MAC address send WOL packet
						If ($computer.MAC)
						{
							#Write a line saying what we are doing and to what
							$output.Text += " * Sending Startup Command to Computer: \\" +
							$computer.NAME + $newline
							
							# Send WOL Packet to computer
							Send-WOL -mac $computer.MAC -ip 255.255.255.255
						}
						Else
						{
							$output.Text += " * No MAC Address for computer \\" +
							$computer.NAME + $newline
						}
					}
				}
				$output.Text += $newline
			}
		}
		$listPods.ClearSelected()
	}
	
	$buttonShutdown_Click={
		$output.Clear()

        $shutdown = {
            Param($computerName = "Localhost")
            shutdown /s /f /m "\\$($computerName)"
        }

		If (-not $listPods.CheckedItems.Count -gt 0) {
			$output.Text += "Please select at least one POD from the box on the right!" + $newline
		}
		Else {
			ForEach ($pod in $listPods.CheckedItems) {
				$output.Text += "Shutting Down Pod #" + $pod + $newline
				ForEach ($computer in $computers) {
					If ($computer.POD -eq $pod) {
                        #Write a line saying what we are doing and to what
						$output.Text += " * Sending Shutdown Command to Computer: \\" +
						$computer.NAME + $newline
						
						# Shutdown the computer
						#Stop-Computer -ComputerName $computer.NAME -Force #Command is blocking ans slows down script execution
                        Start-Job -ScriptBlock $shutdown -ArgumentList $computer.NAME -Name $computer.NAME
					}
				}
				$output.Text += $newline
			}
            $running = @(Get-Job | Where-Object { $_.State -eq 'Running' })
            While($running.Count -gt 0){
                $output.Text += " - Still waiting on $($running.Count) tasks to finish!"
                [System.Collections.ArrayList]$lines = $output.Lines
                $lines.Remove($lines[$lines.Count - 1])
                $output.Lines = $lines
            }
		}
		$listPods.ClearSelected()
	}
	$listPods_SelectedIndexChanged={}

	
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
    
	# librarypower
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
    $librarypower.Icon = New-Object system.drawing.icon ("$path\plug_electricity.ico")
	$librarypower.add_Load($FormEvent_Load)
    
	# listPods
	$listPods.Anchor = 'Top, Bottom, Left'
	$listPods.BorderStyle = 'FixedSingle'
	$listPods.CheckOnClick = $True
	$listPods.FormattingEnabled = $True
	$listPods.Location = '12, 12'
	$listPods.Name = "listPods"
	$listPods.Size = '99, 152'
	$listPods.TabIndex = 7
	$listPods.add_SelectedIndexChanged($listPods_SelectedIndexChanged)
	
    # output
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

	# buttonShutdown
	$buttonShutdown.Anchor = 'Bottom'
	$buttonShutdown.Location = '262, 178'
	$buttonShutdown.Name = "buttonShutdown"
	$buttonShutdown.Size = '75, 23'
	$buttonShutdown.TabIndex = 3
	$buttonShutdown.Text = "&Shutdown"
	$buttonShutdown.UseVisualStyleBackColor = $True
	$buttonShutdown.add_Click($buttonShutdown_Click)

	# buttonExit
	$buttonExit.Anchor = 'Bottom, Right'
	$buttonExit.Location = '511, 178'
	$buttonExit.Name = "buttonExit"
	$buttonExit.Size = '75, 23'
	$buttonExit.TabIndex = 2
	$buttonExit.Text = "E&xit"
	$buttonExit.UseVisualStyleBackColor = $True
	$buttonExit.add_Click($buttonExit_Click)

	# buttonStartup
	$buttonStartup.Anchor = 'Bottom, Left'
	$buttonStartup.Location = '12, 178'
	$buttonStartup.Name = "buttonStartup"
	$buttonStartup.Size = '75, 23'
	$buttonStartup.TabIndex = 1
	$buttonStartup.Text = "&Startup"
	$buttonStartup.UseVisualStyleBackColor = $True
	$buttonStartup.add_Click($buttonStartup_Click)
	$librarypower.ResumeLayout()

	#Save the initial state of the form
	$InitialFormWindowState = $librarypower.WindowState
	#Init the OnLoad event to correct the initial state of the form
	$librarypower.add_Load($Form_StateCorrection_Load)
	#Clean up the control events
	$librarypower.add_FormClosed($Form_Cleanup_FormClosed)
	#Show the Form
	return $librarypower.ShowDialog()

}

#Call OnApplicationLoad to initialize
if((OnApplicationLoad) -eq $true)
{
	#Call the form
	Call-libstartstop_psf | Out-Null
	#Perform cleanup
	OnApplicationExit
}
