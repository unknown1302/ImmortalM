#Requires AutoHotkey v2.0
;#SingleInstance Force
#NoTrayIcon

#Include Lib\CLR.ahk
#Include Lib\GuiEnhancerKit.ahk
#Include Lib\ColorButton.ahk

global backend := ""

CLR_Start()

asm := CLR_LoadLibrary(
    A_ScriptDir "\dll\ImmortalM.dll"
)

backend := asm.CreateInstance(
    "CabalBackend.Backend"
)

if !IsObject(backend)
{
    MsgBox "Failed to load C# backend."
    ExitApp
}

; =========================================================
; IMMORTAL PREMIUM MACRO
; =========================================================

if !A_IsAdmin
{
    try {
        Run '*RunAs "' A_ScriptFullPath '"'
        ExitApp
    }
    catch {
        MsgBox "Run this script as Administrator."
        ExitApp
    }
}

; =========================================================
; GLOBALS
; =========================================================

global VERSION := "v2.1"
global AUTHOR := "Developed by Yunha"

global Actions := []
global Playing := false
global CurrentAction := 1

global TargetWindow := ""

global ProfilesDir := A_ScriptDir "\Profiles"

global MainGui
global lvActions
global txtWindow
global btnStartStop
global ddlProfiles
global ddlMouse
global editDelay
global statusText
global ddlPID
global btnRefreshPID
global btnBypass
global LauncherPath := ""
global txtLauncher
global btnBrowseLauncher
global btnLaunchCabal
global CabalCounter := 0
global ClientMap := Map()
global LaunchCooldown := 10
global LaunchCountdown := 0
global SettingsFile := A_ScriptDir "\settings.ini"

global VERSION := "1.0.0"

global VersionURL :=
"https://raw.githubusercontent.com/unknown1302/ImmortalM/main/version.json"

global ScriptURL :=
"https://raw.githubusercontent.com/unknown1302/ImmortalM/main/Macro.ahk"

if !DirExist(ProfilesDir)
    DirCreate(ProfilesDir)

CoordMode "Mouse", "Screen"
DetectHiddenWindows true
SetTitleMatchMode 2
SetControlDelay -1


; =========================================================
; MAIN GUI
; =========================================================

MainGui := Gui("+MinimizeBox -MaximizeBox", "Immortal Premium Macro")

MainGui.BackColor := 0x1E1E1E
MainGui.SetFont("s9 cWhite", "Segoe UI")
MainGui.SetDarkTitle()

WinWidth := 330

; =========================================================
; HEADER
; =========================================================

MainGui.AddText(
    "x12 y10 w250 h22 +0x200",
    "IMMORTAL PREMIUM MACRO"
)

MainGui.AddText(
    "x10 y38 w310 h1 Background404040"
)

; =========================================================
; TABS
; =========================================================

tabNames := ["Skills", "Start", "Guide"]
tabButtons := []

tabMargin := 10
tabW := Floor((WinWidth - 2 * tabMargin) / tabNames.Length)

Loop tabNames.Length
{
    name := tabNames[A_Index]

    x := tabMargin + ((A_Index - 1) * tabW)

    btn := MainGui.AddButton(
        Format("x{} y48 w{} h26", x, tabW),
        name
    )

    btn.SetBackColor(0x2E2E2E,,9)
    btn.TextColor := 0xFFFFFF

    btn.OnEvent("Click", ShowTab.Bind(name))

    tabButtons.Push(btn)
}

highlight := MainGui.AddText(
    Format("x{} y76 w{} h2 Background0x00C853", tabMargin, tabW)
)

; =========================================================
; TAB STORAGE
; =========================================================

global tabContent := Map()

; =========================================================
; SKILLS TAB
; =========================================================

skillsControls := []

gb1 := MainGui.AddGroupBox(
    "x10 y88 w310 h275 cFFFFFF",
    "Skills Recorder"
)

skillsControls.Push(gb1)

txtWindow := MainGui.AddEdit(
    "x20 y112 w210 h23 ReadOnly Background303030 cFFFFFF"
)

skillsControls.Push(txtWindow)

btnSet := MainGui.AddButton(
    "x240 y112 w70 h23",
    "SET"
)

btnSet.SetBackColor(0x1C98DA,,9)
btnSet.TextColor := 0xFFFFFF
btnSet.OnEvent("Click", SetWindow)

skillsControls.Push(btnSet)

lblClick := MainGui.AddText(
    "x20 y145",
    "Click:"
)

skillsControls.Push(lblClick)

ddlMouse := MainGui.AddDropDownList(
    "x65 y143 w85 Background303030 cFFFFFF Choose1",
    ["Left", "Right", "Middle"]
)

skillsControls.Push(ddlMouse)

lblDelay := MainGui.AddText(
    "x175 y145",
    "Delay:"
)

skillsControls.Push(lblDelay)

editDelay := MainGui.AddEdit(
    "x220 y143 w60 h22 Number Background303030 cFFFFFF",
    "100"
)

skillsControls.Push(editDelay)

lvActions := MainGui.AddListView(
    "x20 y175 w290 h115 Grid -Multi Background202020 cFFFFFF",
    ["Click", "Coords", "Delay"]
)

lvActions.ModifyCol(1, 70)
lvActions.ModifyCol(2, 120)
lvActions.ModifyCol(3, 70)

lvActions.OnEvent("DoubleClick", EditAction)

skillsControls.Push(lvActions)

btnRecord := MainGui.AddButton(
    "x20 y305 w85 h28",
    "F2 RECORD"
)

btnRecord.SetBackColor(0x00B86B,,9)
btnRecord.TextColor := 0xFFFFFF
btnRecord.OnEvent("Click", RecordAction)

skillsControls.Push(btnRecord)

btnDelete := MainGui.AddButton(
    "x115 y305 w85 h28",
    "DELETE"
)

btnDelete.SetBackColor(0xFF8800,,9)
btnDelete.TextColor := 0xFFFFFF
btnDelete.OnEvent("Click", DeleteAction)

skillsControls.Push(btnDelete)

btnClear := MainGui.AddButton(
    "x210 y305 w100 h28",
    "CLEAR ALL"
)

btnClear.SetBackColor(0xD62828,,9)
btnClear.TextColor := 0xFFFFFF
btnClear.OnEvent("Click", ClearActions)

skillsControls.Push(btnClear)

tabContent["Skills"] := skillsControls

; =========================================================
; START TAB
; =========================================================

startControls := []

gb2 := MainGui.AddGroupBox(
    "x10 y88 w310 h275 cFFFFFF",
    "Playback"
)

startControls.Push(gb2)

btnStartStop := MainGui.AddButton(
    "x95 y125 w140 h34",
    "START"
)

btnStartStop.SetBackColor(0x00B86B,,9)
btnStartStop.TextColor := 0xFFFFFF
btnStartStop.OnEvent("Click", TogglePlayback)

startControls.Push(btnStartStop)

btnHide := MainGui.AddButton(
    "x95 y175 w140 h30",
    "HIDE WINDOW"
)

btnHide.SetBackColor(0x7B2CBF,,9)
btnHide.TextColor := 0xFFFFFF
btnHide.OnEvent("Click", ToggleHide)

startControls.Push(btnHide)

lblProfile := MainGui.AddText(
    "x20 y235",
    "Profile:"
)

startControls.Push(lblProfile)

profileList := GetProfiles()

ddlProfiles := MainGui.AddDropDownList(
    "x75 y232 w170 Background303030 cFFFFFF",
    profileList
)

startControls.Push(ddlProfiles)

btnSave := MainGui.AddButton(
    "x20 y275 w130 h32",
    "SAVE"
)

btnSave.SetBackColor(0x1C98DA,,9)
btnSave.TextColor := 0xFFFFFF
btnSave.OnEvent("Click", SaveProfile)

startControls.Push(btnSave)

btnLoad := MainGui.AddButton(
    "x175 y275 w130 h32",
    "LOAD"
)

btnLoad.SetBackColor(0x555555,,9)
btnLoad.TextColor := 0xFFFFFF
btnLoad.OnEvent("Click", LoadSelectedProfile)

startControls.Push(btnLoad)

tabContent["Start"] := startControls

; =========================================================
; GUIDE TAB
; =========================================================

guideControls := []

gb3 := MainGui.AddGroupBox(
    "x10 y88 w310 h275 cFFFFFF",
    "Guide"
)

guideControls.Push(gb3)

guideBox := MainGui.AddEdit(
    "x20 y110 w290 h220 ReadOnly -Wrap Background202020 cFFFFFF"
)

guideBox.Value :=
(
"SHORTCUT KEYS`r`n`r`n"

"F2  → Record Mouse Position`r`n"
"F3  → Start / Stop Macro`r`n"
"F4  → Emergency Stop`r`n`r`n"

"HOW TO USE`r`n`r`n"

"1. Click SET button.`r`n"
"2. Right click target game window.`r`n"
"3. Move mouse inside target window.`r`n"
"4. Press F2 to record position.`r`n"
"5. Repeat for additional clicks.`r`n"
"6. Save your profile.`r`n"
"7. Load your profile.`r`n"
"8. Press START.`r`n"
)

guideControls.Push(guideBox)

tabContent["Guide"] := guideControls

; =========================================================
; FOOTER
; =========================================================

MainGui.AddText(
    "x10 y372 w80 h18 c888888",
    VERSION
)

MainGui.AddText(
    "x180 y372 w140 h18 Right c888888",
    AUTHOR
)

statusText := MainGui.AddText(
    "x10 y390 w310 h18 Center cAAAAAA",
    "Macro stopped."
)
; =========================================================
; CABAL BYPASS PANEL
; =========================================================

MainGui.AddGroupBox(
    "x10 y415 w310 h100 cFFFFFF",
    "Cabal Bypass"
)

ddlPID := MainGui.AddDropDownList(
    "x20 y440 w180 Background303030 cFFFFFF",
    []
)

btnRefreshPID := MainGui.AddButton(
    "x210 y438 w90 h26",
    "REFRESH"
)

btnRefreshPID.SetBackColor(0x1C98DA,,9)
btnRefreshPID.TextColor := 0xFFFFFF
btnRefreshPID.OnEvent("Click", RefreshPIDList)

btnBypass := MainGui.AddButton(
    "x20 y475 w280 h28",
    "BYPASS"
)

btnBypass.SetBackColor(0x00B86B,,9)
btnBypass.TextColor := 0xFFFFFF
btnBypass.OnEvent("Click", RunBypass)

; =========================================================
; LAUNCHER PANEL
; =========================================================

MainGui.AddGroupBox(
    "x10 y520 w310 h110 cFFFFFF",
    "Launcher"
)

txtLauncher := MainGui.AddEdit(
    "x20 y545 w190 h23 ReadOnly Background303030 cFFFFFF"
)

btnBrowseLauncher := MainGui.AddButton(
    "x220 y543 w80 h25",
    "BROWSE"
)

btnBrowseLauncher.SetBackColor(0x1C98DA,,9)
btnBrowseLauncher.TextColor := 0xFFFFFF
btnBrowseLauncher.OnEvent("Click", BrowseLauncher)

btnLaunchCabal := MainGui.AddButton(
    "x20 y580 w280 h30",
    "LAUNCH CABAL"
)

btnLaunchCabal.SetBackColor(0x00B86B,,9)
btnLaunchCabal.TextColor := 0xFFFFFF
btnLaunchCabal.OnEvent("Click", LaunchCabal)

; =========================================================
; HOTKEYS
; =========================================================

Hotkey("F2", RecordAction)
Hotkey("F3", TogglePlayback)
Hotkey("F4", StopPlayback)

; =========================================================
; INITIAL TAB
; =========================================================

ShowTab("Skills")

MainGui.OnEvent("Close", (*) => ExitApp())

MainGui.Show("w330 h645")
LoadSettings()
CheckForUpdates()

CheckForUpdates()
{
    global VersionURL

    json := DownloadText(VersionURL)

    if RegExMatch(json, '"download"\s*:\s*"([^"]+)"', &d)
    {
        tempFile := A_ScriptDir "\Macro.new"

        DownloadFile(d[1], tempFile)

        if FileExist(tempFile)
        {
            MsgBox "Downloaded successfully:`n" tempFile
        }
        else
        {
            MsgBox "Download failed"
        }
    }
}
DownloadText(url)
{
    whr := ComObject("WinHttp.WinHttpRequest.5.1")

    whr.Open("GET", url, false)
    whr.Send()

    return whr.ResponseText
}
DownloadFile(url, savePath)
{
    whr := ComObject("WinHttp.WinHttpRequest.5.1")

    whr.Open("GET", url, false)
    whr.Send()

    file := FileOpen(savePath, "w", "UTF-8-RAW")
    file.Write(whr.ResponseText)
    file.Close()
}

; =========================================================
; TAB SWITCHING
; =========================================================

ShowTab(tabName, *)
{
    global tabContent
    global tabNames
    global highlight
    global tabW
    global tabMargin

    for name, controls in tabContent
    {
        for ctrl in controls
            ctrl.Visible := false
    }

    for ctrl in tabContent[tabName]
        ctrl.Visible := true

    Loop tabNames.Length
    {
        if (tabNames[A_Index] = tabName)
        {
            highlight.Move(
                tabMargin + ((A_Index - 1) * tabW),
                76,
                tabW,
                2
            )
            break
        }
    }
}

; =========================================================
; SET TARGET WINDOW
; =========================================================

SetWindow(*)
{
    global TargetWindow
    global txtWindow
    global statusText

    ToolTip "Right click target window"

    KeyWait "RButton", "D"

    MouseGetPos ,, &hwnd

    title := WinGetTitle(hwnd)

    TargetWindow := "ahk_id " hwnd

    txtWindow.Value := title

    statusText.Text := "Window selected."

    ToolTip
}

; =========================================================
; RECORD ACTION
; =========================================================

RecordAction(*)
{
    global TargetWindow
    global Actions
    global ddlMouse
    global editDelay
    global statusText

    if (TargetWindow = "")
    {
        MsgBox "Set target window first."
        return
    }

    MouseGetPos &sx, &sy, &hwnd

    if ("ahk_id " hwnd != TargetWindow)
    {
        MsgBox "Mouse must be inside target window."
        return
    }

    ; ==========================================
    ; TRUE CLIENT COORDS (LIKE YOUR V1)
    ; ==========================================

    pt := Buffer(8)

    NumPut("Int", sx, pt, 0)
    NumPut("Int", sy, pt, 4)

    targetHwnd := Integer(StrReplace(TargetWindow, "ahk_id "))

    DllCall(
        "ScreenToClient",
        "Ptr", targetHwnd,
        "Ptr", pt
    )

    cx := NumGet(pt, 0, "Int")
    cy := NumGet(pt, 4, "Int")

    ; ==========================================
    ; SAVE ACTION
    ; ==========================================

    action := Map()

    action["button"] := ddlMouse.Text
    action["x"] := cx
    action["y"] := cy
    action["delay"] := Integer(editDelay.Value)

    Actions.Push(action)

    ReloadList()

    statusText.Text := "Action recorded."
}

; =========================================================
; RELOAD LIST
; =========================================================

ReloadList()
{
    global lvActions
    global Actions

    lvActions.Delete()

    for action in Actions
    {
        lvActions.Add(
            ,
            action["button"],
            action["x"] "," action["y"],
            action["delay"] "ms"
        )
    }
}

; =========================================================
; DELETE ACTION
; =========================================================

DeleteAction(*)
{
    global lvActions
    global Actions

    row := lvActions.GetNext()

    if row
    {
        Actions.RemoveAt(row)
        ReloadList()
    }
}

; =========================================================
; CLEAR ACTIONS
; =========================================================

ClearActions(*)
{
    global Actions

    if MsgBox(
        "Clear all actions?",
        "Confirm",
        "YesNo"
    ) = "Yes"
    {
        Actions := []
        ReloadList()
    }
}

; =========================================================
; EDIT ACTION
; =========================================================

EditAction(lv, row)
{
    global Actions

    if !row
        return

    action := Actions[row]

    editGui := Gui("-MinimizeBox -MaximizeBox", "Edit Delay")

    editGui.BackColor := 0x1E1E1E
    editGui.SetFont("s9 cWhite", "Segoe UI")
    editGui.SetDarkTitle()

    editGui.AddText(
        "x18 y20",
        "Delay:"
    )

    delayEdit := editGui.AddEdit(
        "x70 y18 w100 h24 Number Background303030 cFFFFFF",
        action["delay"]
    )

    saveBtn := editGui.AddButton(
        "x55 y65 w100 h30",
        "SAVE"
    )

    saveBtn.SetBackColor(0x00B86B,,9)
    saveBtn.TextColor := 0xFFFFFF

    saveBtn.OnEvent("Click", SaveEdit)

    SaveEdit(*)
    {
        action["delay"] := Integer(delayEdit.Value)

        ReloadList()

        editGui.Destroy()
    }

    editGui.Show("w220 h120")
}

; =========================================================
; START / STOP
; =========================================================

TogglePlayback(*)
{
    global Playing
    global btnStartStop
    global Actions

    if (!Playing && Actions.Length = 0)
    {
        MsgBox "No recorded actions."
        return
    }

    if !Playing
    {
        StartPlayback()

        btnStartStop.Text := "STOP"
        btnStartStop.SetBackColor(0xD62828,,9)
    }
    else
    {
        StopPlayback()
    }
}

StartPlayback()
{
    global Playing
    global Actions
    global CurrentAction
    global statusText

    if (Actions.Length = 0)
        return

    Playing := true
    CurrentAction := 1

    statusText.Text := "Macro running."

    RunNext()
}

; =========================================================
; MMORPG CLICK ENGINE
; =========================================================

RunNext()
{
    global Playing
    global Actions
    global CurrentAction
    global TargetWindow

    if !Playing
        return

    if (CurrentAction > Actions.Length)
        CurrentAction := 1

    action := Actions[CurrentAction]

    btn := action["button"]

    ; BUTTON DOWN
    ControlClick(
        "x" action["x"] " y" action["y"],
        TargetWindow,
        ,
        btn,
        ,
        "D NA"
    )

    ; MMORPG stability delay
    Sleep 25

    ; BUTTON UP
    ControlClick(
        "x" action["x"] " y" action["y"],
        TargetWindow,
        ,
        btn,
        ,
        "U NA"
    )

    delay := action["delay"]

    CurrentAction++

    SetTimer(RunNext, -delay)
}

; =========================================================
; STOP
; =========================================================

StopPlayback(*)
{
    global Playing
    global statusText
    global btnStartStop

    Playing := false

    SetTimer(RunNext, 0)

    btnStartStop.Text := "START"
    btnStartStop.SetBackColor(0x00B86B,,9)

    statusText.Text := "Macro stopped."
}

; =========================================================
; HIDE WINDOW
; =========================================================

ToggleHide(*)
{
    global TargetWindow

    if (TargetWindow = "")
        return

    if WinExist(TargetWindow)
    {
        style := WinGetStyle(TargetWindow)

        if (style & 0x10000000)
            WinHide(TargetWindow)
        else
            WinShow(TargetWindow)
    }
}

; =========================================================
; SAVE PROFILE
; =========================================================

SaveProfile(*)
{
    global Actions
    global ProfilesDir
    global ddlProfiles
    global statusText
    global txtWindow

    saveGui := Gui("-MinimizeBox -MaximizeBox", "Save Profile")

    saveGui.BackColor := 0x1E1E1E
    saveGui.SetFont("s9 cWhite", "Segoe UI")
    saveGui.SetDarkTitle()

    saveGui.AddText(
        "x18 y20",
        "Profile Name:"
    )

    editName := saveGui.AddEdit(
        "x18 y45 w190 h25 Background303030 cFFFFFF"
    )

    btnSave2 := saveGui.AddButton(
        "x65 y85 w95 h30",
        "SAVE"
    )

    btnSave2.SetBackColor(0x1C98DA,,9)
    btnSave2.TextColor := 0xFFFFFF

    btnSave2.OnEvent("Click", DoSave)

    DoSave(*)
    {
        name := Trim(editName.Value)

        if (name = "")
            return

        path := ProfilesDir "\" name ".json"

        json := "{`n"
        json .= '"window":"' txtWindow.Value '",'
        json .= '`n'
        json .= '"actions":['

        for index, action in Actions
        {
            json .= "{"
            json .= '"button":"' action["button"] '",'
            json .= '"x":' action["x"] ','
            json .= '"y":' action["y"] ','
            json .= '"delay":' action["delay"]
            json .= "}"

            if (index < Actions.Length)
                json .= ","
        }

        json .= "]`n}"

        if FileExist(path)
            FileDelete(path)

        FileAppend(json, path)

        RefreshProfiles()

        ddlProfiles.Text := name

        statusText.Text := "Profile saved."

        saveGui.Destroy()
    }

    saveGui.Show("w230 h135")
}

; =========================================================
; LOAD PROFILE
; =========================================================

LoadSelectedProfile(*)
{
    global ddlProfiles
    global ProfilesDir
    global Actions
    global statusText
    global txtWindow
    global TargetWindow

    profile := ddlProfiles.Text

    if (profile = "")
        return

    path := ProfilesDir "\" profile ".json"

    if !FileExist(path)
    {
        MsgBox "Profile not found."
        return
    }

    json := FileRead(path)

    if RegExMatch(json, '"window":"([^"]+)"', &w)
    {
        txtWindow.Value := w[1]
        TargetWindow := w[1]
    }

    Actions := []

    pattern :=
    '\{"button":"([^"]+)","x":(\d+),"y":(\d+),"delay":(\d+)\}'

    pos := 1

    while pos := RegExMatch(json, pattern, &m, pos)
    {
        action := Map()

        action["button"] := m[1]
        action["x"] := Integer(m[2])
        action["y"] := Integer(m[3])
        action["delay"] := Integer(m[4])

        Actions.Push(action)

        pos += StrLen(m[0])
    }

    ReloadList()

    statusText.Text := "Profile loaded."
}

; =========================================================
; PROFILE LIST
; =========================================================

GetProfiles()
{
    global ProfilesDir

    list := []

    Loop Files, ProfilesDir "\*.json"
    {
        SplitPath A_LoopFileName,,, , &name
        list.Push(name)
    }

    return list
}

RefreshProfiles()
{
    global ddlProfiles

    ddlProfiles.Delete()

    profiles := GetProfiles()

    for item in profiles
        ddlProfiles.Add([item])
}

; =========================================================
; REFRESH PID LIST
; =========================================================

RefreshPIDList(*)
{
    global ddlPID
    global statusText

    ddlPID.Delete()

    RunWait(
        A_ComSpec ' /c tasklist /FI "IMAGENAME eq cabalmain.exe" /FO CSV /NH > "' A_Temp '\cabalpid.txt"',
        ,
        "Hide"
    )

    output := FileRead(A_Temp "\cabalpid.txt")

    lines := StrSplit(output, "`n")

    latestPID := ""

    for line in lines
    {
        line := Trim(line)

        if (line = "")
            continue

        cols := StrSplit(StrReplace(line, '"'), ",")

        if (cols.Length >= 2)
        {
            pid := cols[2]

            ddlPID.Add([pid])

            latestPID := pid
        }
    }

    if (latestPID != "")
    {
        ddlPID.Text := latestPID


        statusText.Text := "Successfully Attached to PID " latestPID " (cabalmain.exe)"
    }
    else
    {
        statusText.Text := "cabalmain.exe not found."
    }
}

; =========================================================
; RUN BYPASS
; =========================================================

RunBypass(*)
{
    global ddlPID
    global statusText
    global backend

    pid := ddlPID.Text

    if (pid = "")
    {
        MsgBox "No PID selected."
        return
    }

    result := backend.Bypass(pid)

    statusText.Text := result
}

; =========================================================
; BROWSE LAUNCHER
; =========================================================

BrowseLauncher(*)
{
    global LauncherPath
    global txtLauncher
    global statusText

    selected := FileSelect(
        1,
        ,
        "Select Cabal Launcher",
        "Executable (*.exe)"
    )

    if (selected = "")
        return

    LauncherPath := selected

    txtLauncher.Value := selected
    IniWrite(LauncherPath, SettingsFile, "Launcher", "Path")

    statusText.Text := "Launcher selected successfully."
}

; =========================================================
; LAUNCH CABAL
; =========================================================

LaunchCabal(*)
{
    global backend
    global LauncherPath
    global statusText
    global btnLaunchCabal
    global LaunchCountdown

    if (LaunchCountdown > 0)
        return

    result := backend.LaunchCabal(LauncherPath)

    statusText.Text := result

    LaunchCountdown := 10

    btnLaunchCabal.Enabled := false

    UpdateLaunchButton()

    SetTimer(UpdateLaunchButton, 1000)
}
UpdateLaunchButton()
{
    global btnLaunchCabal
    global LaunchCountdown

    if (LaunchCountdown <= 0)
    {
        btnLaunchCabal.Text := "LAUNCH CABAL"
        btnLaunchCabal.Enabled := true

        SetTimer(UpdateLaunchButton, 0)
        return
    }

    btnLaunchCabal.Text :=
        "LAUNCH CABAL (" LaunchCountdown ")"

    LaunchCountdown--
}

EnableBypassButton()
{
    global btnBypass
    global statusText

    btnBypass.Enabled := true

    statusText.Text := "[" CurrentTime() "] Client ready for bypass."
}
; =========================================================
; TIME HELPER
; =========================================================

CurrentTime()
{
    return FormatTime(, "HH:mm:ss")
}
RenameClientWindow(pid)
{
    global ClientMap
    global CabalCounter

    hwndList := WinGetList("ahk_pid " pid)

    for hwnd in hwndList
    {
        title := WinGetTitle(hwnd)

        if (title = "")
            continue

        if ClientMap.Has(pid)
            return ClientMap[pid]

        CabalCounter++

        newTitle := "Cabal " CabalCounter

        WinSetTitle(newTitle, "ahk_id " hwnd)

        Sleep 100

        ClientMap[pid] := newTitle

        return newTitle
    }

    return ""
}

LoadSettings()
{
    global SettingsFile
    global LauncherPath
    global txtLauncher

    if FileExist(SettingsFile)
    {
        LauncherPath := IniRead(
            SettingsFile,
            "Launcher",
            "Path",
            ""
        )

        txtLauncher.Value := LauncherPath
    }
}