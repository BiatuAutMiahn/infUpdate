#include-once
#include <WinAPIProc.au3>

;infCommon

; Vars
Global $__gInfinity_aCmdCallback[1][3]
Global $__gInfinity_aExitCallback[1][2]
Global $__gInfinity_bExit
Global $__gInfinity_sAppData
Global $__gInfinity_sAppLog
Global $__gInfinity_sAppMagic
Global $__gInfinity_sAppSess

; Var Init
$__gInfinity_aCmdCallback[0][0]=0
$__gInfinity_aExitCallback[0]=0

Func _infSetCmdlineOptCallback($sModId,$sParam,$sCmd)
  Local $iIdx=-1
  For $i=1 To $__gInfinity_aCmdCallback[0][0]
    If $sParam=$__gInfinity_aCmdCallback[$iIdx][0] Then
      $iIdx=$i
      ExitLoop
    EndIf
  Next
  If $iIdx<>-1 Then Return SetError(1,0,0)
  Local $iMaxY=UBound($__gInfinity_aCmdCallback,2)
  Local $iMax=UBound($__gInfinity_aCmdCallback,1)-1
  ReDim $__gInfinity_aCmdCallback[$iMax+1][$iMaxY]
  $__gInfinity_aCmdCallback[$iMax][0]=$sModId
  $__gInfinity_aCmdCallback[$iMax][1]=$sParam
  $__gInfinity_aCmdCallback[$iMax][2]=$sCmd
  $__gInfinity_aCmdCallback[0][0]=$iMax
EndFunc

Func _infSetExitOptCallback($sModId,$sParam,$sCmd)
  Local $iIdx=-1
  For $i=1 To $__gInfinity_aExitCallback[0]
    If $sCmd=$__gInfinity_aExitCallback[$iIdx] Then
      $iIdx=$i
      ExitLoop
    EndIf
  Next
  If $iIdx<>-1 Then Return SetError(1,0,0)
  Local $iMaxY=UBound($__gInfinity_aExitCallback,2)
  Local $iMax=UBound($__gInfinity_aExitCallback,1)-1
  ReDim $__gInfinity_aExitCallback[$iMax+1][$iMaxY]
  $__gInfinity_aExitCallback[$iMax][0]=$sModId
  $__gInfinity_aExitCallback[$iMax][1]=$sCmd
  $__gInfinity_aExitCallback[0]=$iMax
EndFunc

Func _infCmdProc($sModId,$sMod)
  If $CmdLine[0]=0 Then Return SetError(1,0,0)
  If Not $__gInfinity_aCmdCallback[0][0] Then Return SetError(1,1,0)
  For $i=1 To $CmdLine[0]
    For $j=1 To $__gInfinity_aCmdCallback[0][0]
      If $__gInfinity_aCmdCallback[$j][1]=$CmdLine[$i] Then
        Call($__gInfinity_aCmdCallback[$j][2])
      EndIf
    Next
  Next
EndFunc

Func _infInit()
  If $__gInfinity_bInit Then Return SetError(0,1,0)
  $__gInfinity_bInit=True
  $__gInfinity_bExit=False
  OnAutoItExitRegister("_infShutdown")
EndFunc

Func _infShutdown($sModId,$iExit=0)
  If $__gInfinity_bExit Then
    While _infTimerDelay(1000)
    WEnd
  EndIf
  $__gInfinity_bExit=True
  If $__gInfinity_aExitCallback[0] Then
      For $j=1 To $__gInfinity_aExitCallback[0][1]
        Call($__gInfinity_aExitCallback[$j])
      Next
  EndIf
  Exit $iExit
EndFunc

Func _infTimerDelay($iDelay)
  Local $hTimer=TimerInit()
  While Sleep(1)
    If TimerInit($hTimer)>=$iDelay Then Return
  WEnd
EndFunc

;$iCallbackMode
;0, Line Mode
;1, Byte Mode

Func _infCmdGetOutput($sCmd,$sWorkDir=@ScriptDir,$iRetMode=0); Implement: ,$sCallback="",$iCallbackMode=0)
    Local $iPid,$hProc
    Local $aRet[3]
    $iPid=Run($sCmd,$sWorkDir,@SW_HIDE,6)
    $hProc=_WinAPI_OpenProcess($PROCESS_QUERY_INFORMATION,0,$iPid,0)
    If @error Then Return SetError(1,1,0)
    Local $vPeek,$vChunk,$bBreak=0
    Local $vStdOut
    Local $vStdErr
    Do
        $vPeek=StdoutRead($iPid,1,1)
        If BinaryLen($vPeek) Then
            $vChunk=StdoutRead($iPid,0,1)
            If @error Then $bBreak=1
            $vStdOut&=$vChunk
            $vChunk=StdErrRead($iPid,0,1)
            If @error Then $bBreak=1
            $vStdErr&=$vChunk
        EndIf
    Until Not ProcessExists($iPid) Or Not $bBreak
    $aRet[0]=_WinAPI_GetExitCodeProcess($hProc)
    If $iRetMode=0 Then
        $aRet[1]=$vStdOut
        $aRet[2]=$vStdErr
    ElseIf $iRetMode=1 Then
        Local $aStdOut,$aStdErr[]=[0],$iMax
        $sStdOut=StringReplace(BinaryToString($vStdOut),@CRLF,@LF)
        Do
            $sStdOut=StringReplace($sStdOut,@LF&@LF,@LF)
        Until Not StringInStr($sStdOut,@LF&@LF)
        $aRet[1]=StringSplit($sStdOut,@LF)
        $sStdErr=StringReplace(BinaryToString($vStdErr),@CRLF,@LF)
        Do
            $sStdErr=StringReplace($sStdErr,@LF&@LF,@LF)
        Until Not StringInStr($sStdErr,@LF&@LF)
        $aRet[1]=StringSplit($sStdOut,@LF)
        $aRet[2]=StringSplit($sStdErr,@LF)
    EndIf
    Return SetError(0,0,$aRet)
EndFunc

_infInit()
