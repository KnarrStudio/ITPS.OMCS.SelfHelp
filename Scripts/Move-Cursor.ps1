#requires -Version 3.0
function Move-Cursor
{
  <#
    .SYNOPSIS
    Moves the cursor off the center of the screen.


    .DESCRIPTION
    Moves the cursor off the center of the screen after restart and auto-login or just to move it to the side.  The cursor 'ticks' down the edge one second at a time and then starts again.

    .PARAMETER Delay
    Sets the amount of time between 'ticks'.  Default is '1'

    .PARAMETER Edge
    Sets the distance from the edge.  Default is '2'

    .EXAMPLE
    Move-Cursor
    Move the cursor to the right edge of the screen and ticks it down one second at a time.

    .EXAMPLE


    .LINK
    URLs to related sites
    The first link is opened by Get-Help -Online Move-Cursor

    .INPUTS
    List of input types that are accepted by this function.

    .OUTPUTS
    List of output types produced by this function.
  #>


  param
  (
    [Parameter(Mandatory = $false, Position = 0)]
    [int]$Delay = 1,
    [Parameter(Mandatory = $false, Position = 1)]
    [int]$Edge = 2
      )
  BEGIN{
    $PosXY = '{0},{1}'
$null =0
    Add-Type -AssemblyName System.Windows.Forms
    $screen = [Windows.Forms.SystemInformation]::VirtualScreen
    #$screen | Get-Member -MemberType Property
    [Windows.Forms.Cursor]::Position = ($PosXY -f ($screen.Width - $Edge), $screen.Height)
    $CursorStep = $screen.Height / $Delay
  }
  PROCESS
  {
    $null = ([Windows.Forms.Cursor]::Position).X
    $null = ([Windows.Forms.Cursor]::Position).Y
    for($i = 1;$i -lt $screen.Height;++$i)
    {
      [Windows.Forms.Cursor]::Position = ($PosXY -f ($screen.Width - $Edge), $i)
      Start-Sleep -Seconds $Delay
    
      if(([Windows.Forms.Cursor]::Position).X -lt $($screen.Width - $Edge))
      {
        Break
      }
    }
  }
  END{}
}
Move-Cursor