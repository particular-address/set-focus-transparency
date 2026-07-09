<#
.SYNOPSIS
    Sets transparency on the window currently in focus (The Active Window).
.DESCRIPTION
    1. Runs.
    2. Gives you a 3-second countdown.
    3. You click the window you want (Explorer, Notepad, etc.).
    4. It makes that window transparent.
#>

param (
    [int]$Opacity = 200  # 0-255
)

# --- The Windows API Bridge ---
$definition = @"
using System;
using System.Runtime.InteropServices;

public class Win32 {
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    public static extern int GetWindowLong(IntPtr hWnd, int nIndex);

    [DllImport("user32.dll")]
    public static extern int SetWindowLong(IntPtr hWnd, int nIndex, int dwNewLong);

    [DllImport("user32.dll")]
    public static extern bool SetLayeredWindowAttributes(IntPtr hWnd, uint crKey, byte bAlpha, uint dwFlags);

    [DllImport("user32.dll")]
    public static extern int GetWindowText(IntPtr hWnd, System.Text.StringBuilder lpString, int nMaxCount);
}
"@

if (-not ([System.Management.Automation.PSTypeName]'Win32').Type) {
    Add-Type -TypeDefinition $definition -Language CSharp
}

# --- The Countdown ---
Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "PREPARE TO SELECT TARGET..." -ForegroundColor Cyan
Write-Host "1. Switch to the window you want transparent."
Write-Host "2. Wait for the beep/message."
Write-Host "------------------------------------------------" 

Write-Host ">>> 3..." -ForegroundColor Yellow
Start-Sleep -Seconds 1
Write-Host ">>> 2..." -ForegroundColor Yellow
Start-Sleep -Seconds 1
Write-Host ">>> 1..." -ForegroundColor Yellow
Start-Sleep -Seconds 1

# --- The Capture ---
# Grab the handle of whatever window is currently active (Foreground)
$handle = [Win32]::GetForegroundWindow()

# Verify what we caught
$sb = New-Object System.Text.StringBuilder 256
[Win32]::GetWindowText($handle, $sb, $sb.Capacity) | Out-Null
$title = $sb.ToString()

Write-Host ">>> TARGET LOCKED: '$title'" -ForegroundColor Green

# --- The Action ---
$GWL_EXSTYLE = -20
$WS_EX_LAYERED = 0x80000
$LWA_ALPHA = 0x2

# Get current style and add the 'Layered' bit if missing
$currentStyle = [Win32]::GetWindowLong($handle, $GWL_EXSTYLE)
if (($currentStyle -band $WS_EX_LAYERED) -ne $WS_EX_LAYERED) {
    [Win32]::SetWindowLong($handle, $GWL_EXSTYLE, $currentStyle -bor $WS_EX_LAYERED) | Out-Null
}

# Set Opacity
$result = [Win32]::SetLayeredWindowAttributes($handle, 0, $Opacity, $LWA_ALPHA)

if ($result) {
    Write-Host "Transparency applied successfully." -ForegroundColor Green
} else {
    Write-Host "Failed. Ensure you are running as Admin if targeting System apps." -ForegroundColor Red
}