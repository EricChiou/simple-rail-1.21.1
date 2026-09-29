param([ValidateSet('capture','click','keys','close')][string]$Action='capture',[string]$Value='screen',[int]$X=0,[int]$Y=0)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Windows.Forms,System.Drawing
Add-Type @'
using System;
using System.Runtime.InteropServices;
public class TestWindow {
 [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
 [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
 [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
 [DllImport("user32.dll")] public static extern bool SetCursorPos(int x,int y);
 [DllImport("user32.dll")] public static extern void mouse_event(uint f,uint x,uint y,uint d,UIntPtr e);
 public struct RECT {public int Left,Top,Right,Bottom;}
}
'@
$p=Get-Process java,javaw -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -like '*Minecraft*' } | Select-Object -First 1
if(-not $p){throw 'No Minecraft window found'}
$r=New-Object TestWindow+RECT
[void][TestWindow]::GetWindowRect($p.MainWindowHandle,[ref]$r)
if($Action -eq 'close') {
 [void][TestWindow]::PostMessage($p.MainWindowHandle,0x0010,[IntPtr]::Zero,[IntPtr]::Zero)
} elseif($Action -eq 'click') {
 [void][TestWindow]::SetForegroundWindow($p.MainWindowHandle)
 [void][TestWindow]::SetCursorPos(($r.Left+$X),($r.Top+$Y))
 [TestWindow]::mouse_event(2,0,0,0,[UIntPtr]::Zero)
 [TestWindow]::mouse_event(4,0,0,0,[UIntPtr]::Zero)
} elseif($Action -eq 'keys') {
 [void][TestWindow]::SetForegroundWindow($p.MainWindowHandle)
 [Windows.Forms.SendKeys]::SendWait($Value)
} else {
 [void][TestWindow]::SetForegroundWindow($p.MainWindowHandle)
 Start-Sleep -Milliseconds 400
 $bmp=New-Object Drawing.Bitmap ($r.Right-$r.Left),($r.Bottom-$r.Top)
 $g=[Drawing.Graphics]::FromImage($bmp)
 $g.CopyFromScreen($r.Left,$r.Top,0,0,$bmp.Size)
 $path=Join-Path $PSScriptRoot ($Value+'.png')
 $bmp.Save($path,[Drawing.Imaging.ImageFormat]::Png)
 $g.Dispose();$bmp.Dispose()
 [ordered]@{timeUtc=[DateTime]::UtcNow.ToString('o');pid=$p.Id;title=$p.MainWindowTitle;left=$r.Left;top=$r.Top;width=$r.Right-$r.Left;height=$r.Bottom-$r.Top;path=$path} | ConvertTo-Json | Tee-Object -FilePath (Join-Path $PSScriptRoot ($Value+'.json'))
}
"$( [DateTime]::UtcNow.ToString('o') ) $Action $Value $X $Y" | Add-Content -Encoding UTF8 (Join-Path $PSScriptRoot 'gui-actions.log')
