function Move-Cursor
{
  <#
      .SYNOPSIS
      Moves the cursor off the center of the screen.  Moving the cursor away from the edge stops the loop

      .DESCRIPTION
      Moves the cursor off the center of the screen after restart and auto-login or just to move it to the side.  The cursor 'ticks' down the edge one second at a time and then starts again.
      Moving the cursor away from the edge stops the loop.

      .PARAMETER Delay
      Sets the amount of time between 'ticks'.  Default is '1'

      .PARAMETER Edge
      Sets the distance from the edge.  Default is '2'

      .PARAMETER Loops
      Sets the amount of loops to run.  Default is '0' (Infinity)

      .EXAMPLE
      Move-Cursor
      Move the cursor to the right edge of the screen and ticks it down one second at a time.

      .EXAMPLE
      Move-Cursor -Delay 2 -Loops 3 -Edge 5
      Moves the cursor to 5 px from the right edge and ticks down the edge every 2 seconds.  It does this 3 times

      .LINK
      https://github.com/KnarrStudio/ITPS.OMCS.SelfHelp/blob/9bc22605522e3ce9cd2a26166e6dbec966a5676f/Scripts/Move-Cursor.ps1

  #>
  param
  (
    [Parameter(Mandatory = $false, Position = 0)]
    [int]$Delay = 1,
    [Parameter(Mandatory = $false, Position = 1)]
    [int]$Edge = 2,
    [Parameter(Mandatory = $false, Position = 2)]
    [int]$Loops = 0
  )
  BEGIN{
    $PosXY = '{0},{1}'
    $LoopCount = 0
    $Break = $false
    Add-Type -AssemblyName System.Windows.Forms
    $screen = [Windows.Forms.SystemInformation]::VirtualScreen
    #$screen | Get-Member -MemberType Property
    [Windows.Forms.Cursor]::Position = ($PosXY -f ($screen.Width - $Edge), $screen.Height)
    $CursorStep = $screen.Height / 60
  }
  PROCESS
  {
    $null = ([Windows.Forms.Cursor]::Position).X
    $null = ([Windows.Forms.Cursor]::Position).Y
    While(($LoopCount -ne $Loops) -or ($Loops -eq 0))
    {
      for($i = 1;$i -lt $screen.Height;$i = $i+$CursorStep)
      {
        [Windows.Forms.Cursor]::Position = ($PosXY -f ($screen.Width - $Edge), $i)
        Start-Sleep -Seconds $Delay
        if(([Windows.Forms.Cursor]::Position).X -lt $($screen.Width - $Edge))
        {
          $Break = $true
          Break
        }
      }
      $LoopCount = ++$LoopCount 
      if($Break)
      {
        Break
      }
    }
  }
  END{}
}