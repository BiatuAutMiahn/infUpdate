#include-once
#include "infCommon.au3"
#include "WinHttp.au3"

; Infinity Module
Global Const $__gInfinityUpdate_sModAlias="Infinity.Update"
Global Const $__gInfinityUpdate_sModId="JW39q02g2ySSh7l4"
Global Const $__gInfinityUpdate_sModBuild=0

_infRegisterMod($__gInfinityUpdate_sModAlias,$__gInfinityUpdate_sModId,$__gInfinityUpdate_sModBuild)

; Updater Variables
Global $__gInfinityUpdate_chkURI
Global $__gInfinityUpdate_chkDOM
Global $__gInfinityUpdate_bUpdate
Global $__gInfinityUpdate_iUpdProg
Global $__gInfinityUpdate_iUpdProgBytes
Global $__gInfinityUpdate_iUpdProgTot
Global $__gInfinityUpdate_iUpdStat
Global $__gInfinityUpdate_sUpdExec

Global $hWINHTTP_STATUS_CALLBACK = DllCallbackRegister("__WINHTTP_STATUS_CALLBACK", "none", "handle;dword_ptr;dword;ptr;dword")

_infSetCmdlineOptCallback($__gInfinityUpdate_sModId,"~!Update","_infUpdate")
_infSetCmdlineOptCallback($__gInfinityUpdate_sModId,"~!PostUpdate","_infUpdatePost")
_infSetCmdlineOptCallback($__gInfinityUpdate_sModId,"~!RecoverUpdate","_infUpdateRecover")
_infSetCmdlineOptCallback($__gInfinityUpdate_sModId,"~!RollbackUpdate","_infUpdateRollback")
_infSetInitCallback($__gInfinityUpdate_sModId,"_infUpdateInit")

Func _infUpdateInit()
  _infSetExitOptCallback($__gInfinityUpdate_sModId,"_infUpdateExit")
EndFunc

Func _infUpdateExit()
EndFunc

Func _infUpdate()
EndFunc

Func _infUpdateCheck()
EndFunc

Func _infUpdatePost()
EndFunc

Func _infUpdateRecover()
EndFunc

Func _Update($bPost=0)
    Local $sTitle=$sAlias&" Update"
    _UpdateLog("Current Version: "&$VERSION,"_Update")
    If $bPost Then
        _UpdateLog("################### Update Stage 2 ###################","_Update")
        ; I don't trust this, we should create a dir .\Snap\xx.xx.xx.xx.exe, then hardlink to .\Init.NAPS2.exe
        ; Get Version of main exec.
        $sBaseSnap=$sBaseDir&"\Init.NAPS2.exe"
        If Not FileExists($sBaseSnap) Then
            MsgBox(16,$sTitle,"Error: Update Failed, see log for details.")
            MsgBox(16,$sTitle,'Error: "Init.NAPS2.exe" could not be found. Update Failed.')
            Return SetError(0,15,1)
        EndIf
        Local $vCurVer=FileGetVersion($sBaseSnap)
        If @error Then
            MsgBox(16,$sTitle,"Error: Update Failed, see log for details.")
            _UpdateLog("Error: Could not retrieve FileVersion for Init.NAPS.exe","_Update")
            Return SetError(0,16,1)
        EndIf
        DirCreate($sSnapsDir)
        If Not _isDir($sSnapsDir) Then
            MsgBox(16,$sTitle,"Error: Update Failed, see log for details.")
            _UpdateLog("Error: Failed to create snaphot directory.","_Update")
            Return SetError(0,17,1)
        EndIf
        $sCurSnap=$sSnapsDir&'\WrapNAPS2_v'&$vCurVer&".exe"
        If Not FileExists($sCurSnap) Then
            FileCopy($sBaseSnap,$sCurSnap)
        EndIf
;~         Local $hToken = _WinAPI_OpenProcessToken(BitOR($TOKEN_ADJUST_PRIVILEGES, $TOKEN_QUERY))
;~         Local $aAdjust
;~         _WinAPI_AdjustTokenPrivileges($hToken, $SE_CREATE_SYMBOLIC_LINK_NAME, $SE_PRIVILEGE_ENABLED, $aAdjust)
;~         If @error Or @extended Then
;~             MsgBox(16,$sTitle,"Error: Update Failed, see log for details.")
;~             _Log("Error: Cannot grant SeCreateSymbolicLinkPrivilege.","_Update")
;~             Return SetError(0,14,1)
;~         EndIf
        FileDelete($sBaseSnap)
        If Not FileCopy($sSnapsDir&'\WrapNAPS2_v'&$VERSION&".exe",$sBaseSnap,1) Then
            MsgBox(16,$sTitle,"Error: Update Failed, see log for details.")
            _UpdateLog("Error: Cannot copy update","_Update")
             If FileCopy($sCurSnap,$sBaseSnap) Then _UpdateLog("Restored original Init.NAPS2.exe","_Update")
            _UpdateLog("Copy "&$sSnapsDir&'\WrapNAPS2_v'&$VERSION&".exe over Init.NAPS2.exe to manually update.","_Update")
            If Not FileExists($sBaseSnap) Then
                MsgBox(16,$sTitle,"Error: Cannot recover from update failure. Please contact your system administrator/developer.")
                Exit 1
            EndIf
        EndIf
        Run($sBaseSnap,$sBaseDir,@SW_SHOW)
;~         If Not _WinAPI_CreateSymbolicLink($sBaseSnap,$sSnapsDir&'\WrapNAPS2_v'&$VERSION&".exe") Then
;~             MsgBox(16,$sTitle,"Error: Update Failed, see log for details.")
;~             _Log("Error: Cannot create Symbolic Link","_Update")
;~             _Log("Restored original Init.NAPS2.exe","_Update")
;~              FileCopy($sCurSnap,$sBaseSnap)
;~             _Log("Copy "&$sSnapsDir&'\WrapNAPS2_v'&$VERSION&".exe over Init.NAPS2.exe to manually update.","_Update")
;~             Return SetError(0,15,1)
;~         EndIf
        Return SetError(0,2,1)
    EndIf
    If Not $bCheckUpdate Then
        _UpdateLog("Update check disabled","_Update")
        Return SetError(0,1,1)
    EndIf
    _UpdateLog("Checking for updates.","_Update")
    Local $iRet,$sRet
    $sRet=__Update_SecureGet("raw.githubusercontent.com","/BiatuAutMiahn/WrapNAPS/main/VERSION")
    If @error Then
        $iRet=@Extended
        Switch $iRet
            Case 1
                _UpdateLog("Error initializeing WinHttp","_Update")
            Case 2
                _UpdateLog("Error connecting to Update Server.","_Update")
            Case 3
                _UpdateLog("Error creating update request","_Update")
            Case 4
                _UpdateLog("Error sending update request","_Update")
            Case 5
                _UpdateLog("Error recieveing update request response","_Update")
            Case 6
                _UpdateLog("Error while recieving update data","_Update")
        EndSwitch
        Return SetError(1,$iRet,0)
    EndIf
    $sRet=StringStripWS(BinaryToString($sRet),7)
    _UpdateLog("Server Returned: "&$sRet,"_Update")
    If $sRet="404: Not Found" Then
        _UpdateLog("Error: Recieved HTTP Error 404 while checking for update","_Update")
        Return SetError(1,7,0)
    EndIf
    Local $vVer=_VersionCompare($VERSION,$sRet)
    If @error Then
        _UpdateLog("Error during update version comparison."&$sRet,"_Update")
        Return SetError(1,8,0)
    EndIf
    _UpdateLog("Upstream Version: "&$sRet,"_Update")
    If $vVer=0 Then
        _UpdateLog("Up to date!","_Update")
        Return SetError(0,3,1); No update available.
    EndIf
    If $vVer=1 Then
        _UpdateLog("Warning: upstream version is older than self.","_Update")
        Return SetError(1,9,0); We are newer than upstream
    EndIf
    If $vVer<>-1 Then
        _UpdateLog("Error, unexpected update variable! ("&$vVer&')',"_Update")
        Return SetError(1,10,0); _VersionCompare returned undocumented result.
    EndIf
    ; Prompt user for update.
    Local $iRet=MsgBox(32+4+65536,$sTitle,"An update is available!"&@LF&@LF&"Current version: "&$VERSION&@LF&"New version: "&$sRet&@LF&@LF&"Would you like to update now?",0,$hMain)
    If $iRet<>6 Then Return SetError(0,4,1)
    ; Download new version
    _UpdateLog("Downloading new version...","_Update")
    AdlibRegister("__UpdateProgWatch",10)
    $vUpdate=__Update_SecureGet("raw.githubusercontent.com","/BiatuAutMiahn/WrapNAPS/main/Init.NAPS2.exe","__UpdateProgCallback")
    If @error Then
        $iRet=@Extended
        Switch $iRet
            Case 1
                _UpdateLog("Error initializeing WinHttp","_Update")
            Case 2
                _UpdateLog("Error connecting to Update Server.","_Update")
            Case 3
                _UpdateLog("Error creating update request","_Update")
            Case 4
                _UpdateLog("Error sending update request","_Update")
            Case 5
                _UpdateLog("Error recieveing update request response","_Update")
            Case 6
                _UpdateLog("Error while recieving update data","_Update")
        EndSwitch
        AdlibUnregister("__UpdateProgWatch")
        MsgBox(16,$sTitle,"Error: Failed to download update. See log for details.")
        Return SetError(1,$iRet,0)
    EndIf    ; Execute new version with ~!Update
    AdlibUnregister("__UpdateProgWatch")
    DirCreate($sSnapsDir)
    If Not _isDir($sSnapsDir) Then
        MsgBox(16,$sTitle,"Error: Update Failed, see log for details.")
        _UpdateLog("Error: Failed to create snaphot directory.","_Update")
        Return SetError(0,13,1)
    EndIf
    ;If @error Then MsgBox(64,"Meh",@Error)
    $sUpdate=$sSnapsDir&'\WrapNAPS2_v'&$sRet&".exe"
    $hFile=FileOpen($sUpdate,2+8+16)
    If $hFile=-1 Then
        MsgBox(16,$sTitle,"Error: Update Failed, see log for details.")
        _UpdateLog('Error: Failed create file: "'&$sUpdate&'"',"_Update")
        Return SetError(0,14,1)
    EndIf
    If Not FileWrite($hFile,BinaryToString($vUpdate)) Then
        MsgBox(16,$sTitle,"Error: Update Failed, see log for details.")
        _UpdateLog('Error: Cannot write to file: "'&$sUpdate&'"',"_Update")
        Return SetError(0,14,1)
    EndIf
    FileClose($hFile)
    Local $vUpdVer=FileGetVersion($sUpdate)
    If @error Then
        MsgBox(16,$sTitle,"Error: Update Failed, see log for details.")
        _UpdateLog("Error: Could not retrieve FileVersion for '"&$sUpdate&"'","_Update")
        Return SetError(0,12,1)
    EndIf
    $vUpdVerCmp=_VersionCompare($vUpdVer,$sRet)
    If @error Then
        MsgBox(16,$sTitle,"Error: Update Failed, see log for details.")
        _UpdateLog("Error during update version comparison."&$sRet,"_Update")
        Return SetError(1,13,0)
    EndIf
    If $vUpdVerCmp<>0 Then
        MsgBox(16,$sTitle,"Error: Update Failed, see log for details.")
        _UpdateLog("Error: The downloaded update version does not match the version reported. ("&$vUpdVerCmp&","&$vUpdVer&"<>"&$sRet&')',"_Update")
        Return SetError(1,14,0)
    EndIf
    _UpdateLog("Upstream Version: "&$sRet)
    Run($sUpdate&" ~!Update",$sBaseDir,@SW_SHOW)
    Exit 0
EndFunc

Func _UpdateLog($sStr,$sMod="_Update")
    _infLog($sStr,$sMod,$sBaseDir&"\Update.log")
EndFunc

Func __UpdateProgCallback($iStatus,$iBytes,$iTotal)
    $g_iUpdateStat=$iStatus
    $g_iProgBytes=$iBytes
    $g_iProgTotal=$iTotal
    $g_iProgPerc=Round(($iBytes/$g_iProgTotal)*100)
EndFunc

Func __UpdateProgWatch()
    Local $sMsg="Updating: "
    Switch $g_iUpdateStat
        Case 0
            $sMsg&="Initializing"
        Case 1
            $sMsg&="Connecting"
        Case 2
            $sMsg&="Downloading ("&$g_iProgPerc&"%,"&$g_iProgBytes&'\'&$g_iProgTotal&')'
    EndSwitch
    $aPos=MouseGetPos()
    ToolTip($sMsg,$aPos[0]+16,$aPos[1]+16,$sAlias&" Update",0,4)
    _Log($sMsg,"__UpdateProgWatch")
EndFunc

Func _UpdateRecovery()
    MsgBox(16,$sTitle,"Not Yet Implemented")
    Exit 1
EndFunc

Func _DoUpdate()
    AdlibUnRegister("_DoUpdate")
    _Update(0)
EndFunc

Func __WINHTTP_STATUS_CALLBACK($hInternet, $iContext, $iInternetStatus, $pStatusInformation, $iStatusInformationLength)
    #forceref $hInternet, $iContext, $pStatusInformation, $iStatusInformationLength
    ;ConsoleWrite("!->Current status of the connection: " & $iInternetStatus & " " & @TAB & " ")
    ; Interpret the status
    Local $sStatus
    Switch $iInternetStatus
        Case $WINHTTP_CALLBACK_STATUS_INTERMEDIATE_RESPONSE
            $sStatus = "Received an intermediate (100 level) status code message from the server."
        Case $WINHTTP_CALLBACK_STATUS_REQUEST_ERROR
            $sStatus = "An error occurred while sending an HTTP request."
        Case $WINHTTP_CALLBACK_STATUS_SECURE_FAILURE
            $sStatus = "One or more errors were encountered while retrieving a Secure Sockets Layer (SSL) certificate from the server."
    EndSwitch
    ; Print it
    If $sStatus<>'' Then _UpdateLog($sStatus,"__Update_SecureGet")
EndFunc    ;==>__WINHTTP_STATUS_CALLBACK


Func __Update_SecureGet($sSrv,$sUri,$fCallback=-1)
    If $fCallback<>-1 Then Call($fCallback,0,0,0)
    Local $hOpen=_WinHttpOpen()
    If @error Then Return SetError(1,1,0)
    _WinHttpSetStatusCallback($hOpen, $hWINHTTP_STATUS_CALLBACK)
    If $fCallback<>-1 Then Call($fCallback,1,0,0)
    Local $hConnect=_WinHttpConnect($hOpen,$sSrv,$INTERNET_DEFAULT_HTTPS_PORT)
    If @error Then
        _WinHttpCloseHandle($hOpen)
        Return SetError(1,2,0)
    EndIf
    Local $hRequest=_WinHttpOpenRequest($hConnect,"GET",$sUri,Default, Default, Default, BitOR($WINHTTP_FLAG_SECURE, $WINHTTP_FLAG_ESCAPE_DISABLE))
    If @error Then
        _WinHttpCloseHandle($hConnect)
        _WinHttpCloseHandle($hOpen)
        Return SetError(1,3,0)
    EndIf
	_WinHttpSetOption($hRequest, $WINHTTP_OPTION_DECOMPRESSION, $WINHTTP_DECOMPRESSION_FLAG_ALL)
	_WinHttpSetOption($hRequest, $WINHTTP_OPTION_UNSAFE_HEADER_PARSING,1)
    _WinHttpSendRequest($hRequest)
    If @error Then
        _WinHttpCloseHandle($hRequest)
        _WinHttpCloseHandle($hConnect)
        _WinHttpCloseHandle($hOpen)
        Return SetError(1,4,0)
    EndIf
    _WinHttpReceiveResponse($hRequest)
    If @error Then
        _WinHttpCloseHandle($hRequest)
        _WinHttpCloseHandle($hConnect)
        _WinHttpCloseHandle($hOpen)
        Return SetError(1,5,0)
    EndIf
    ; See if there is data to read
    Local $sChunk, $sData, $bAvail=_WinHttpQueryDataAvailable($hRequest)
    Local $iTotal=@Extended
    If $bAvail Then
        If $fCallback<>-1 Then Call($fCallback,2,0,$iTotal)
        ; Read
        While 1
            $sChunk = _WinHttpReadData($hRequest,2)
            If @error Then ExitLoop
            $sData &= BinaryToString($sChunk)
            If $fCallback<>-1 Then Call($fCallback,2,StringLen($sData),$iTotal)
        WEnd
    Else
        _WinHttpCloseHandle($hRequest)
        _WinHttpCloseHandle($hConnect)
        _WinHttpCloseHandle($hOpen)
        Return SetError(1,6,0)
    EndIf
    _WinHttpCloseHandle($hRequest)
    _WinHttpCloseHandle($hConnect)
    _WinHttpCloseHandle($hOpen)
    Return SetError(0,0,$sData)
EndFunc


#cs
;#include "CurlMemDll.au3"
  ;cURL_initialise()
  ;cURL_cleanup()
  ;$response=cURL_easy("http://www.autoitscript.com/site/")
cURL_easy("http://web.aanet.com.au/seangriffin/content/computing/development/eBay%20Bargain%20Hunter%20setup.exe", "", 0, 1, "tmp.exe")
		$CURLOPT_PROGRESSFUNCTION = $CURLOPTTYPE_FUNCTIONPOINT + 56, _
		$CURLOPT_PROGRESSDATA = $CURLOPTTYPE_OBJECTPOINT + 57, _
$CURLOPT_XFERINFODATA
Func Curl_FileReadCallback()
	Static $Ptr = DllCallbackGetPtr(DllCallbackRegister(__Curl_FileReadCallback, (@AutoItX64 ? "uint_ptr" : "uint_ptr:cdecl"), "ptr;uint_ptr;uint_ptr;ptr"))
	Return $Ptr
EndFunc   ;==>Curl_FileReadCallback


Func __Curl_FileReadCallback($Ptr, $Size, $Nmemb, $Handle)
	Local $Length = $Size * $Nmemb
	If $Length = 0 Then Return 0

	Local $DataRead = FileRead(Int($Handle), $Length)
	If IsString($DataRead) Then
		$DataRead = BinaryMid(StringToBinary($DataRead, 4), 1, $Length)
	EndIf

#ce
