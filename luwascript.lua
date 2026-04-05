local Players          = game:GetService("Players")
local LocalPlayer      = Players.LocalPlayer
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- -- Notification system
-- Stacking notifications: each new one slides in at the bottom-right and
-- pushes existing ones upward. They all live simultaneously and auto-dismiss.
-- Tags: "notification" (white), "warning" (yellow), "error" (bright red)
local notifSg = Instance.new("ScreenGui")
notifSg.Name            = "LuwaNotif"
notifSg.ResetOnSpawn    = false
notifSg.IgnoreGuiInset  = true
notifSg.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
notifSg.DisplayOrder    = 50
notifSg.Parent          = LocalPlayer.PlayerGui

local activeNotifs = {}   -- list of live card frames, newest = last

local NOTIF_H      = 52
local NOTIF_W      = 230
local NOTIF_GAP    = 8
local NOTIF_X      = -12
local NOTIF_BASE_Y = -12

local NOTIF_TAG_COLORS = {
    notification = Color3.fromRGB(255, 255, 255),   -- white
    warning      = Color3.fromRGB(255, 210, 50),    -- yellow
    error        = Color3.fromRGB(255, 90, 90),     -- bright red (readable)
}
local NOTIF_TAG_LABELS = {
    notification = "Notification",
    warning      = "Warning",
    error        = "Error",
}

local function notifSlotY(slot)
    return NOTIF_BASE_Y - slot * (NOTIF_H + NOTIF_GAP)
end

local function repositionNotifs(animated)
    for slot, card in ipairs(activeNotifs) do
        local targetY = notifSlotY(slot - 1)
        if animated then
            TweenService:Create(card,
                TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                {Position = UDim2.new(1, NOTIF_X, 1, targetY)}
            ):Play()
        else
            card.Position = UDim2.new(1, NOTIF_X, 1, targetY)
        end
    end
end

local function showNotify(tag, msg)
    local tagColor = NOTIF_TAG_COLORS[tag] or NOTIF_TAG_COLORS.notification
    local tagLabel = NOTIF_TAG_LABELS[tag]  or NOTIF_TAG_LABELS.notification

    local card = Instance.new("Frame")
    card.AnchorPoint            = Vector2.new(1, 1)
    card.Position               = UDim2.new(1, NOTIF_X, 1, NOTIF_H + 20)
    card.Size                   = UDim2.new(0, NOTIF_W, 0, NOTIF_H)
    card.BackgroundColor3       = Color3.fromRGB(10, 10, 12)
    card.BackgroundTransparency = 1
    card.BorderSizePixel        = 0
    card.Parent                 = notifSg
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke")
    stroke.Color        = Color3.fromRGB(255, 255, 255)
    stroke.Thickness    = 1
    stroke.Transparency = 0.7
    stroke.Parent       = card

    -- Tag label - top row, colored
    local tagLbl = Instance.new("TextLabel")
    tagLbl.Size                   = UDim2.new(1, -40, 0, 18)
    tagLbl.Position               = UDim2.new(0, 8, 0, 5)
    tagLbl.BackgroundTransparency = 1
    tagLbl.Text                   = tagLabel
    tagLbl.TextColor3             = tagColor
    tagLbl.TextTransparency       = 1
    tagLbl.TextSize               = 10
    tagLbl.Font                   = Enum.Font.GothamBold
    tagLbl.TextXAlignment         = Enum.TextXAlignment.Left
    tagLbl.Parent                 = card

    -- Message label - bottom row, white
    local msgLbl = Instance.new("TextLabel")
    msgLbl.Size                   = UDim2.new(1, -40, 0, 20)
    msgLbl.Position               = UDim2.new(0, 8, 0, 26)
    msgLbl.BackgroundTransparency = 1
    msgLbl.Text                   = msg
    msgLbl.TextColor3             = Color3.fromRGB(255, 255, 255)
    msgLbl.TextTransparency       = 1
    msgLbl.TextSize               = 11
    msgLbl.Font                   = Enum.Font.Gotham
    msgLbl.TextXAlignment         = Enum.TextXAlignment.Left
    msgLbl.TextTruncate           = Enum.TextTruncate.AtEnd
    msgLbl.Parent                 = card

    -- Close button - top-right
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size                   = UDim2.new(0, 20, 0, 20)
    closeBtn.Position               = UDim2.new(1, -26, 0, 6)
    closeBtn.BackgroundTransparency = 1
    closeBtn.BorderSizePixel        = 0
    closeBtn.Text                   = "X"
    closeBtn.TextColor3             = Color3.fromRGB(180, 180, 190)
    closeBtn.TextTransparency       = 1
    closeBtn.TextSize               = 10
    closeBtn.Font                   = Enum.Font.GothamBold
    closeBtn.AutoButtonColor        = false
    closeBtn.ZIndex                 = 2
    closeBtn.Parent                 = card

    activeNotifs[#activeNotifs + 1] = card
    repositionNotifs(true)

    local dismissed = false
    local function dismiss()
        if dismissed then return end
        dismissed = true
        TweenService:Create(card,
            TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {BackgroundTransparency = 1,
             Position = UDim2.new(1, NOTIF_X + 30, 1, card.Position.Y.Offset)}):Play()
        TweenService:Create(tagLbl,
            TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {TextTransparency = 1}):Play()
        TweenService:Create(msgLbl,
            TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {TextTransparency = 1}):Play()
        TweenService:Create(closeBtn,
            TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {TextTransparency = 1}):Play()
        task.delay(0.2, function()
            for i, c in ipairs(activeNotifs) do
                if c == card then table.remove(activeNotifs, i) break end
            end
            repositionNotifs(true)
            pcall(function() card:Destroy() end)
        end)
    end

    closeBtn.MouseButton1Click:Connect(dismiss)
    closeBtn.TouchTap:Connect(dismiss)

    -- Fade in
    TweenService:Create(card,
        TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        {BackgroundTransparency = 0.45}):Play()
    TweenService:Create(tagLbl,
        TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {TextTransparency = 0}):Play()
    TweenService:Create(msgLbl,
        TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {TextTransparency = 0}):Play()
    TweenService:Create(closeBtn,
        TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {TextTransparency = 0.3}):Play()

    -- Auto-dismiss after 2.5s
    task.delay(2.5, dismiss)
end
--


local uiVisible       = false
local activeFrame     = nil
local activeScreenGui = nil
local isClosing       = false

local DEFAULT_SIZE = UDim2.new(0, 280, 0, 248)

local savedFrameSize    = nil
local savedPosition     = nil
local savedLauncherSize         = 44
local savedLauncherOutlineColor = Color3.fromRGB(255,255,255)
local savedCustomOutlineColor   = nil
local savedLauncherLocked       = false
local savedLauncherPos          = nil
local savedPickerPos            = nil  -- {xs,xo,ys,yo} for player selector window
local savedProfilePos           = nil  -- {xs,xo,ys,yo} for profile card window
local srvSortAsc                = true  -- servers sort: true=low->high, false=high->low
local savedPickerScale          = nil  -- {w,h} for player selector window size
local savedProfileScale         = nil  -- {w,h} for profile card window size
local saveWinPositions          = true   -- always on; positions are always saved
local saveWinSizes              = false
local launcherBtn               = nil
local launcherOutline           = nil

local activeResizeConn1  = nil
local activeResizeConn2  = nil
local activeSaveGui      = nil
local activeResizeHandle = nil
local rescaleForceOff    = nil
local SETTINGS_TAB_INDEX = 4
local activeAccentLine   = nil

local tabScrollPos = {}
local tabBuilt     = {}
local tabEverBuilt = {}
local uiGeneration = 0

local noclipActive  = false
local suggestFrame   = nil
local hideSuggestFn  = nil
local syncSuggestPos = nil
local waypointBox      = nil
local waypointBoxStroke= nil
local rebuildWpBox   = nil
local wpBoxOpen      = false
local suggestWasOpen = false
local updateSuggestions = nil
local adminCmdBox    = nil
local activeTabRef   = 1
local noclipConn    = nil
local noclipCollMap = nil
local fogSnapshot   = nil

local function cleanupResize()
    if activeResizeConn1  then activeResizeConn1:Disconnect();  activeResizeConn1  = nil end
    if activeResizeConn2  then activeResizeConn2:Disconnect();  activeResizeConn2  = nil end
    if activeSaveGui      then activeSaveGui:Destroy();         activeSaveGui      = nil end
    if activeResizeHandle then activeResizeHandle:Destroy();    activeResizeHandle = nil end
end

local TI = {
    fast       = TweenInfo.new(0.15, Enum.EasingStyle.Quad,    Enum.EasingDirection.Out),
    med        = TweenInfo.new(0.2,  Enum.EasingStyle.Quad,    Enum.EasingDirection.Out),
    slow       = TweenInfo.new(0.3,  Enum.EasingStyle.Back,    Enum.EasingDirection.Out),
    open       = TweenInfo.new(0.3,  Enum.EasingStyle.Quint,   Enum.EasingDirection.Out),
    line       = TweenInfo.new(0.35, Enum.EasingStyle.Quad,    Enum.EasingDirection.Out),
    squish1    = TweenInfo.new(0.07, Enum.EasingStyle.Quad,    Enum.EasingDirection.Out),
    squish2    = TweenInfo.new(0.18, Enum.EasingStyle.Back,    Enum.EasingDirection.Out),
    close      = TweenInfo.new(0.18, Enum.EasingStyle.Quint,   Enum.EasingDirection.In),
    lineRet    = TweenInfo.new(0.12, Enum.EasingStyle.Quad,    Enum.EasingDirection.In),
    flash      = TweenInfo.new(0.1,  Enum.EasingStyle.Quad,    Enum.EasingDirection.Out),
    unflash    = TweenInfo.new(0.3,  Enum.EasingStyle.Quad,    Enum.EasingDirection.Out),
    dot        = TweenInfo.new(0.08, Enum.EasingStyle.Quad,    Enum.EasingDirection.Out),
    dotBack    = TweenInfo.new(0.2,  Enum.EasingStyle.Back,    Enum.EasingDirection.Out),
    elastic    = TweenInfo.new(0.5,  Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
    pillBounce = TweenInfo.new(0.3,  Enum.EasingStyle.Back,    Enum.EasingDirection.Out),
    tabIn      = TweenInfo.new(0.18, Enum.EasingStyle.Quint,   Enum.EasingDirection.Out),
    tabOut     = TweenInfo.new(0.13, Enum.EasingStyle.Quad,    Enum.EasingDirection.In),
    tabInd     = TweenInfo.new(0.38, Enum.EasingStyle.Back,    Enum.EasingDirection.Out),
    strokeIn   = TweenInfo.new(0.12, Enum.EasingStyle.Quad,    Enum.EasingDirection.Out),
    themeFade  = TweenInfo.new(0.28, Enum.EasingStyle.Quad,    Enum.EasingDirection.Out),
}

local function rgb(r,g,b) return Color3.fromRGB(r,g,b) end

local T = {
    frameBg    = rgb(10, 10, 12),    frameTrans = 0.35,
    titleBg    = rgb(10, 10, 12),
    tabBg      = rgb(10, 10, 12),
    tabOn      = rgb(255, 255, 255), tabOff     = rgb(10, 10, 12),
    tabTxtOn   = rgb(10, 10, 12),    tabTxtOff  = rgb(255, 255, 255),
    accent     = rgb(255, 255, 255),
    titleTxt   = rgb(255, 255, 255),
    scrollBar  = rgb(55, 55, 60),
    secLbl     = rgb(255, 255, 255), secLine    = rgb(30, 30, 34),
    togOnBg    = rgb(30, 30, 34),    togOffBg   = rgb(20, 20, 24),
    togTrans   = 0,
    togOnStrip  = rgb(50, 200, 100), togOffStrip = rgb(255, 255, 255),
    togOnLbl   = rgb(255, 255, 255), togOffLbl  = rgb(255, 255, 255),
    togOnPill  = rgb(50, 200, 100),  togOffPill = rgb(255, 255, 255),
    togHovOn   = rgb(35, 35, 42),    togHovOff  = rgb(28, 28, 34),
    togHovOnSt = rgb(80, 225, 130),  togHovOffSt = rgb(200, 200, 200),
    togHint    = rgb(160, 160, 175),
    btnBg      = rgb(0, 0, 0),       btnHov     = rgb(25, 25, 28),
    btnPrs     = rgb(35, 35, 40),    btnTrans   = 0,
    btnStrip   = rgb(255, 255, 255), btnStripHov = rgb(255, 255, 255),
    btnLbl     = rgb(255, 255, 255), btnArrow   = rgb(255, 255, 255),
    btnHint    = rgb(255, 255, 255),
    rowBg      = rgb(0, 0, 0),       rowTrans   = 0,
    rowLbl     = rgb(255, 255, 255),
    inputBg    = rgb(0, 0, 0),       inputPh    = rgb(75, 75, 82),
    inputTxt   = rgb(255, 255, 255),
    strokeIdle = rgb(40, 40, 45),    strokeFocus = rgb(255, 255, 255),
    defBg      = rgb(0, 0, 0),       defHov     = rgb(25, 25, 28),
    defStroke  = rgb(40, 40, 45),    defTxt     = rgb(255, 255, 255),
    rstBg      = rgb(0, 0, 0),       rstHov     = rgb(160, 35, 35),
    saveBg     = rgb(0, 0, 0),       saveHov    = rgb(25, 25, 28),
    handleBg   = rgb(25, 25, 28),
}

local FOLDER_PATH  = "/storage/emulated/0/Delta/Workspace/furScripts"
local INFO_PATH    = FOLDER_PATH .. "/info.txt"
local DELETE = {}

local function parseInfo(raw)
    local t = {}
    for line in (raw .. "\n"):gmatch("([^\n]*)\n") do
        local k, v = line:match("^([^=]+)=(.+)$")
        if k and v then t[k:match("^%s*(.-)%s*$")] = v:match("^%s*(.-)%s*$") end
    end
    return t
end

local function serialiseInfo(t)
    local lines = {}
    for k, v in pairs(t) do
        lines[#lines+1] = k .. "=" .. (type(v)=="number" and string.format("%.7f",v) or tostring(v))
    end
    table.sort(lines)
    return table.concat(lines, "\n")
end

local function patchInfo(patch)
    pcall(function()
        if not isfolder(FOLDER_PATH) then makefolder(FOLDER_PATH) end
        local cur = isfile(INFO_PATH) and parseInfo(readfile(INFO_PATH)) or {}
        for k, v in pairs(patch) do cur[k] = (v == DELETE) and nil or v end
        writefile(INFO_PATH, serialiseInfo(cur))
    end)
end

local function loadSavedInfo()
    pcall(function()
        if not isfile(INFO_PATH) then return end
        local t = parseInfo(readfile(INFO_PATH))
        local sw, sh = tonumber(t["scale_w"]), tonumber(t["scale_h"])
        if sw and sh and sw >= 140 and sh >= 120 then
            savedFrameSize = UDim2.new(0, sw, 0, sh)
        end
        local pxs,pxo,pys,pyo = tonumber(t["pos_xs"]),tonumber(t["pos_xo"]),tonumber(t["pos_ys"]),tonumber(t["pos_yo"])
        if pxs and pxo and pys and pyo then
            savedPosition = { xs=pxs, xo=pxo, ys=pys, yo=pyo }
        end
        local ls = tonumber(t["launcher_size"])
        if ls and ls >= 24 and ls <= 100 then
            savedLauncherSize = ls
        end
        local lr = tonumber(t["outline_r"])
        local lg = tonumber(t["outline_g"])
        local lb = tonumber(t["outline_b"])
        if lr and lg and lb then
            savedLauncherOutlineColor = Color3.fromRGB(
                math.clamp(lr,0,255), math.clamp(lg,0,255), math.clamp(lb,0,255))
        end
        local cr = tonumber(t["custom_r"])
        local cg = tonumber(t["custom_g"])
        local cb = tonumber(t["custom_b"])
        if cr and cg and cb then
            savedCustomOutlineColor = Color3.fromRGB(
                math.clamp(cr,0,255), math.clamp(cg,0,255), math.clamp(cb,0,255))
        end
        if t["launcher_locked"] == "true" then
            savedLauncherLocked = true
        end
        local lxs,lxo,lys,lyo = tonumber(t["lcn_xs"]),tonumber(t["lcn_xo"]),tonumber(t["lcn_ys"]),tonumber(t["lcn_yo"])
        if lxs and lxo and lys and lyo then
            savedLauncherPos = { xs=lxs, xo=lxo, ys=lys, yo=lyo }
        end
        if t["save_win_sizes"] == "true" then
            saveWinSizes = true
        end
        local pkxs,pkxo,pkys,pkyo = tonumber(t["picker_xs"]),tonumber(t["picker_xo"]),tonumber(t["picker_ys"]),tonumber(t["picker_yo"])
        if pkxs and pkxo and pkys and pkyo then
            savedPickerPos = { xs=pkxs, xo=pkxo, ys=pkys, yo=pkyo }
        end
        local pfxs,pfxo,pfys,pfyo = tonumber(t["profile_xs"]),tonumber(t["profile_xo"]),tonumber(t["profile_ys"]),tonumber(t["profile_yo"])
        if pfxs and pfxo and pfys and pfyo then
            savedProfilePos = { xs=pfxs, xo=pfxo, ys=pfys, yo=pfyo }
        end
        local pkw, pkh = tonumber(t["picker_sw"]), tonumber(t["picker_sh"])
        if pkw and pkh and pkw >= 160 and pkh >= 120 then
            savedPickerScale = { w=pkw, h=pkh }
        end
        local pfw, pfh = tonumber(t["profile_sw"]), tonumber(t["profile_sh"])
        if pfw and pfh and pfw >= 140 and pfh >= 80 then
            savedProfileScale = { w=pfw, h=pfh }
        end
        if t["save_win_sizes"] == "true" then
            saveWinSizes = true
        end
        if t["srv_sort"] == "desc" then
            srvSortAsc = false
        end
    end)
end
loadSavedInfo()

pcall(function()
    local rrs = game:GetService("RobloxReplicatedStorage")
    local voiceConn
    voiceConn = RunService.Heartbeat:Connect(function()
        local re = rrs:FindFirstChild("SendLikelySpeakingUsers")
        if re and re:IsA("RemoteEvent") then
            re.OnClientEvent:Connect(function() end)
            voiceConn:Disconnect()
        end
    end)
end)

local function buildLauncherCircle()
    local sg = Instance.new("ScreenGui")
    sg.Name = "LuwaLauncher"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder = 10
    sg.Parent = LocalPlayer.PlayerGui

    local sz  = savedLauncherSize
    local btn = Instance.new("TextButton")
    btn.Size                   = UDim2.new(0, sz, 0, sz)
    if savedLauncherPos then
        btn.Position = UDim2.new(savedLauncherPos.xs, savedLauncherPos.xo,
                                  savedLauncherPos.ys, savedLauncherPos.yo)
    else
        btn.Position = UDim2.new(1, -sz - 14, 0.5, -sz/2)
    end
    btn.BackgroundColor3       = Color3.fromRGB(12, 12, 14)
    btn.BackgroundTransparency = 0.45
    btn.BorderSizePixel        = 0
    btn.Text                   = ""
    btn.AutoButtonColor        = false
    btn.Active                 = true
    btn.Draggable              = not savedLauncherLocked
    btn.Parent                 = sg
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

    local outline = Instance.new("UIStroke")
    outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    outline.Color            = savedLauncherOutlineColor
    outline.Thickness        = 2.5
    outline.Transparency     = 0
    outline.Parent           = btn

    launcherBtn     = btn
    launcherOutline = outline
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TI.fast, {BackgroundTransparency = 0.2}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TI.fast, {BackgroundTransparency = 0.45}):Play()
    end)

    local DRAG_PX = 1

    local pressInput    = nil
    local pressBtnPos   = nil
    local iconWasMoved  = false
    local moveConn      = nil

    local function doToggle()
        if not uiVisible then
            if type(createUI) ~= "function" then return end
            uiVisible = true
            createUI()
        elseif activeFrame and not isClosing then
            isClosing = true
            cleanupResize()
            rescaleForceOff = nil
            if activeAccentLine then
                TweenService:Create(activeAccentLine, TI.lineRet, {Size=UDim2.new(0,0,0,2)}):Play()
            end
            if hideSuggestFn then
                suggestWasOpen = suggestFrame ~= nil and suggestFrame.Visible
                hideSuggestFn()
            end
            if waypointBox and waypointBox.Visible then
                    TweenService:Create(waypointBox, TI.close, {BackgroundTransparency = 1}):Play()
                    task.delay(0.2, function()
                        if waypointBox then
                            waypointBox.Visible = false
                            waypointBox.Active  = false
                            waypointBox.BackgroundTransparency = 0.3
                        end
                    end)
                end
            TweenService:Create(activeFrame, TI.close, {BackgroundTransparency = 1}):Play()
            task.delay(0.2, function()
                uiVisible = false; isClosing = false
                if activeFrame then activeFrame.Visible = false end
            end)
        end
    end

    local function onRelease(inp)
        if inp ~= pressInput then return end
        pressInput = nil
        if moveConn then moveConn:Disconnect(); moveConn = nil end
        TweenService:Create(btn,     TI.fast, {BackgroundTransparency = 0.45}):Play()
        TweenService:Create(outline, TI.fast, {Thickness = 2.5}):Play()

        local shouldOpen
        if savedLauncherLocked then
            local ap  = btn.AbsolutePosition
            local as  = btn.AbsoluteSize
            local rx  = inp.Position.X
            local ry  = inp.Position.Y
            shouldOpen = rx >= ap.X and rx <= ap.X + as.X
                     and ry >= ap.Y and ry <= ap.Y + as.Y
        else
            shouldOpen = not iconWasMoved
        end

        iconWasMoved = false
        if shouldOpen then doToggle() end
    end

    btn.InputBegan:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1
        and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        pressInput   = inp
        iconWasMoved = false
        local ap     = btn.AbsolutePosition
        pressBtnPos  = Vector2.new(ap.X, ap.Y)
        TweenService:Create(btn,     TI.fast, {BackgroundTransparency = 0.0}):Play()
        TweenService:Create(outline, TI.fast, {Thickness = 3.5}):Play()
        if moveConn then moveConn:Disconnect() end
        moveConn = UserInputService.InputChanged:Connect(function(changed)
            if changed ~= pressInput then return end
            if iconWasMoved then return end
            local cur = btn.AbsolutePosition
            local delta = (Vector2.new(cur.X, cur.Y) - pressBtnPos).Magnitude
            if delta > DRAG_PX then
                iconWasMoved = true
            end
        end)
    end)

    btn.InputEnded:Connect(onRelease)
end

buildLauncherCircle()

local function resizeLauncher(newSz)
    newSz = math.clamp(math.floor(newSz + 0.5), 24, 100)
    savedLauncherSize = newSz
    patchInfo({ launcher_size = newSz })
    if launcherBtn and launcherBtn.Parent then
        TweenService:Create(launcherBtn, TI.slow, {Size = UDim2.new(0, newSz, 0, newSz)}):Play()
    end
end

local function recolorOutline(col)
    savedLauncherOutlineColor = col
    local r, g, b = math.round(col.R*255), math.round(col.G*255), math.round(col.B*255)
    patchInfo({ outline_r = r, outline_g = g, outline_b = b })
    if launcherOutline and launcherOutline.Parent then
        TweenService:Create(launcherOutline, TI.fast, {Color = col}):Play()
    end
end

local function lockLauncher()
    savedLauncherLocked = true
    patchInfo({ launcher_locked = "true" })
    if launcherBtn and launcherBtn.Parent then
        launcherBtn.Draggable = false
    end
end
local function unlockLauncher()
    savedLauncherLocked = false
    patchInfo({ launcher_locked = "false" })
    if launcherBtn and launcherBtn.Parent then
        launcherBtn.Draggable = true
    end
end

local function saveLauncherPosition()
    if not (launcherBtn and launcherBtn.Parent) then return end
    local p = launcherBtn.Position
    savedLauncherPos = { xs=p.X.Scale, xo=p.X.Offset, ys=p.Y.Scale, yo=p.Y.Offset }
    patchInfo({ lcn_xs=p.X.Scale, lcn_xo=p.X.Offset, lcn_ys=p.Y.Scale, lcn_yo=p.Y.Offset })
end
local antiFlingActive    = false
local afHeartbeatConn    = nil
local flingTargets       = {}

-- Per-frame velocity delta above this = fling spike (not natural falling)
-- Jumping causes ~50-80 studs/s delta, so must be well above that
local AF_SPIKE_PER_FRAME = 890
-- Velocity magnitude above this while rising gradually = natural falling, pause
local AF_PAUSE_VEL       = 60

local function stopAntiFling()
    antiFlingActive = false
    if afHeartbeatConn then
        afHeartbeatConn:Disconnect()
        afHeartbeatConn = nil
    end
end

-- (Notification system moved to the top of the script)

local AF_SPEED_THRESHOLD = 80
local AF_JUMP_THRESHOLD  = 80
local afSpeedWatcher     = nil

local function watchHumanoidSpeed()
    if afSpeedWatcher then afSpeedWatcher:Disconnect(); afSpeedWatcher = nil end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local _beatCount = 0
    afSpeedWatcher = RunService.Heartbeat:Connect(function()
        _beatCount = _beatCount + 1
        if _beatCount < 3 then return end
        _beatCount = 0
        if not antiFlingActive then return end
        if hum.WalkSpeed > AF_SPEED_THRESHOLD or hum.JumpPower > AF_JUMP_THRESHOLD then
            stopAntiFling()
            showNotify("warning", "Anti-Fling turned off: speed/jump too high")
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(function(char)
    if noclipActive then
        noclipActive = false
        if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
        noclipCollMap = nil
    end
    if antiFlingActive then
        task.defer(watchHumanoidSpeed)
    end
end)

local function startAntiFling()
    stopAntiFling()
    antiFlingActive = true

    local lastSafePos  = nil
    local prevVel      = 0
    local paused       = false
    local pauseTimer   = 0
    local notifSent    = false
    -- Throttle expensive other-player checks to every 6 frames
    local otherCheckN  = 0

    pcall(function()
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then lastSafePos = hrp.Position end
    end)

    afHeartbeatConn = RunService.Heartbeat:Connect(function(dt)
        if not antiFlingActive then return end
        pcall(function()
            local char = LocalPlayer.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not (hrp and hum and hum.Health > 0) then return end

            local vel   = hrp.AssemblyLinearVelocity.Magnitude
            local delta = vel - prevVel

            -- Tick down falling pause
            if paused then
                pauseTimer = pauseTimer - dt
                if pauseTimer <= 0 or vel < 20 then
                    paused     = false
                    pauseTimer = 0
                    notifSent  = false
                end
                if vel < 20 then lastSafePos = hrp.Position end
                prevVel = vel
                return
            end

            -- SPIKE: velocity jumped more than AF_SPIKE_PER_FRAME in one frame = fling
            if delta > AF_SPIKE_PER_FRAME then
                if lastSafePos then
                    hrp.CFrame = CFrame.new(lastSafePos)
                end
                hrp.AssemblyLinearVelocity  = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                prevVel = 0
                return
            end

            -- GRADUAL RISE to high velocity = natural falling, pause
            if vel >= AF_PAUSE_VEL and delta >= 0 and delta <= AF_SPIKE_PER_FRAME then
                if not notifSent then
                    notifSent = true
                    showNotify("notification", "Anti-Fling paused: falling")
                end
                paused     = true
                pauseTimer = 3
                prevVel    = vel
                return
            end

            -- Safe: update last safe position when barely moving
            if vel < 20 then
                lastSafePos = hrp.Position
            end

            -- Throttled: only check other players every 6 frames to avoid lag
            otherCheckN = otherCheckN + 1
            if otherCheckN >= 6 then
                otherCheckN = 0
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and not flingTargets[plr.Name] then
                        local c = plr.Character
                        if c then
                            -- Only check HRP, avoids expensive GetDescendants
                            local otherHrp = c:FindFirstChild("HumanoidRootPart")
                            if otherHrp then
                                local ov = otherHrp.AssemblyLinearVelocity.Magnitude
                                if ov > 500 then
                                    pcall(function()
                                        otherHrp.AssemblyLinearVelocity  = Vector3.zero
                                        otherHrp.AssemblyAngularVelocity = Vector3.zero
                                    end)
                                end
                                -- Zero out dangerous angular velocity (spin flings)
                                if otherHrp.AssemblyAngularVelocity.Magnitude > 50 then
                                    pcall(function()
                                        otherHrp.AssemblyAngularVelocity = Vector3.zero
                                    end)
                                end
                            end
                            -- Destroy BodyVelocity/BodyForce only every 6 frames, on HRP only
                            local bv = c:FindFirstChildWhichIsA("BodyVelocity", true)
                            if bv then pcall(function() bv:Destroy() end) end
                            local bav = c:FindFirstChildWhichIsA("BodyAngularVelocity", true)
                            if bav then pcall(function() bav:Destroy() end) end
                        end
                    end
                end
            end

            prevVel = vel
        end)
    end)
end


-- Declare here so the override closures below capture the correct local upvalue.
-- (Previously declared after line 1056, causing the closures to silently capture
--  the global antiFlingOpt which is always nil -> syncFn never fired -> visual bug.)
local antiFlingOpt    = nil
local showWpOpt       = nil

-- Override startAntiFling
local _origStartAntiFling = startAntiFling
startAntiFling = function()
    -- Gate: block if WalkSpeed > 80 OR JumpPower > 80
    local _gateChar = LocalPlayer.Character
    local _gateHum  = _gateChar and _gateChar:FindFirstChildOfClass("Humanoid")
    if _gateHum then
        if _gateHum.WalkSpeed > AF_SPEED_THRESHOLD then
            showNotify("warning", "Set WalkSpeed below 80 to enable Anti-Fling")
            if antiFlingOpt then
                antiFlingOpt.state = false
                if antiFlingOpt.syncFn then antiFlingOpt.syncFn() end
            end
            return
        end
        if _gateHum.JumpPower > AF_JUMP_THRESHOLD then
            showNotify("warning", "Set JumpPower below 80 to enable Anti-Fling")
            if antiFlingOpt then
                antiFlingOpt.state = false
                if antiFlingOpt.syncFn then antiFlingOpt.syncFn() end
            end
            return
        end
    end
    _origStartAntiFling()
    if antiFlingOpt then
        antiFlingOpt.state = true
        if antiFlingOpt.syncFn then antiFlingOpt.syncFn() end
    end
    task.defer(watchHumanoidSpeed)
end

-- overrides stop anti fling
local _origStopAntiFling2 = stopAntiFling
stopAntiFling = function()
    _origStopAntiFling2()
    if afSpeedWatcher then
        afSpeedWatcher:Disconnect()
        afSpeedWatcher = nil
    end
    if antiFlingOpt then
        antiFlingOpt.state = false
        if antiFlingOpt.syncFn then antiFlingOpt.syncFn() end
    end
end







local flingRunning         = false
local onceActive           = false
local currentBV            = nil
local flingPausedAntiFling = false
local onceVelWatcher       = nil
local onceAbortRef         = nil
local loopAbortRef         = nil
local flingLoopStates    = {}
local rebuildFlingPicker = nil

_G.__LuwaOldPos = nil
_G.__LuwaOldVel = nil
_G.__LuwaFPDH   = nil

RunService.Heartbeat:Connect(function()
    pcall(function()
        local myChar = LocalPlayer.Character
        local myHum  = myChar and myChar:FindFirstChildOfClass("Humanoid")
        local myRoot = myHum  and myHum.RootPart
        if not (myChar and myHum and myRoot) then return end
        if flingRunning or onceActive then return end
        local isGrounded = myHum.FloorMaterial ~= Enum.Material.Air
        local isMoving   = myRoot.AssemblyLinearVelocity.Magnitude < 20
        if isGrounded and isMoving then
            _G.__LuwaOldPos = myRoot.CFrame
            _G.__LuwaOldVel = myRoot.AssemblyLinearVelocity
        end
    end)
end)

local function SkidFling(TargetPlayer, abortRef, wasLoop)
    local myChar = LocalPlayer.Character
    local myHum  = myChar and myChar:FindFirstChildOfClass("Humanoid")
    local myRoot = myHum  and myHum.RootPart
    if not (myChar and myHum and myRoot) then return end

    local TChar = TargetPlayer.Character
    if not TChar then return end

    local THum    = TChar:FindFirstChildOfClass("Humanoid")
    local TRoot   = THum and THum.RootPart
    local THead   = TChar:FindFirstChild("Head")
    local THandle = nil
    local acc     = TChar:FindFirstChildOfClass("Accessory")
    if acc then THandle = acc:FindFirstChild("Handle") end

    if THum and THum.Sit then return end

    if THead then
        workspace.CurrentCamera.CameraSubject = THead
    elseif THandle then
        workspace.CurrentCamera.CameraSubject = THandle
    elseif THum and TRoot then
        workspace.CurrentCamera.CameraSubject = THum
    end

    if not TChar:FindFirstChildWhichIsA("BasePart") then return end

    if not _G.__LuwaOldPos or myRoot.AssemblyLinearVelocity.Magnitude < 50 then
        _G.__LuwaOldPos = myRoot.CFrame
    end

    local function FPos(BasePart, Pos, Ang)
        if not abortRef.active then return end
        if not BasePart.Parent then return end
        local cf = CFrame.new(BasePart.Position) * Pos * Ang
        myRoot.CFrame = cf
        pcall(function() myChar:PivotTo(cf) end)
        myRoot.AssemblyLinearVelocity  = Vector3.new(9e7, 9e7 * 10, 9e7)
        myRoot.AssemblyAngularVelocity = Vector3.new(9e8, 9e8, 9e8)
    end

    local function SFBasePart(BasePart)
        local timeLimit = 1.2
        local startTime = tick()
        local angle = 0

        repeat
            if not (myRoot and THum) then break end
            if not abortRef.active then break end
            if not BasePart.Parent then break end
            if THum.Health <= 0 then break end

            if BasePart.AssemblyLinearVelocity.Magnitude < 50 then
                angle = angle + 100
                FPos(BasePart, CFrame.new(0,  1.5, 0) + THum.MoveDirection * BasePart.AssemblyLinearVelocity.Magnitude / 1.25, CFrame.Angles(math.rad(angle), 0, 0))
                task.wait(); if not abortRef.active or not BasePart.Parent then break end
                FPos(BasePart, CFrame.new(0, -1.5, 0) + THum.MoveDirection * BasePart.AssemblyLinearVelocity.Magnitude / 1.25, CFrame.Angles(math.rad(angle), 0, 0))
                task.wait(); if not abortRef.active or not BasePart.Parent then break end
                FPos(BasePart, CFrame.new( 2.25, 1.5, -2.25) + THum.MoveDirection * BasePart.AssemblyLinearVelocity.Magnitude / 1.25, CFrame.Angles(math.rad(angle), 0, 0))
                task.wait(); if not abortRef.active or not BasePart.Parent then break end
                FPos(BasePart, CFrame.new(-2.25, -1.5, 2.25) + THum.MoveDirection * BasePart.AssemblyLinearVelocity.Magnitude / 1.25, CFrame.Angles(math.rad(angle), 0, 0))
                task.wait(); if not abortRef.active or not BasePart.Parent then break end
                FPos(BasePart, CFrame.new(0,  1.5, 0) + THum.MoveDirection, CFrame.Angles(math.rad(angle), 0, 0))
                task.wait(); if not abortRef.active or not BasePart.Parent then break end
                FPos(BasePart, CFrame.new(0, -1.5, 0) + THum.MoveDirection, CFrame.Angles(math.rad(angle), 0, 0))
                task.wait(); if not abortRef.active or not BasePart.Parent then break end
            else
                local vel = TRoot and TRoot.AssemblyLinearVelocity.Magnitude or THum.WalkSpeed
                FPos(BasePart, CFrame.new(0,  1.5,  THum.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                task.wait(); if not abortRef.active or not BasePart.Parent then break end
                FPos(BasePart, CFrame.new(0, -1.5, -THum.WalkSpeed), CFrame.Angles(0, 0, 0))
                task.wait(); if not abortRef.active or not BasePart.Parent then break end
                FPos(BasePart, CFrame.new(0,  1.5,  THum.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                task.wait(); if not abortRef.active or not BasePart.Parent then break end
                FPos(BasePart, CFrame.new(0,  1.5,  vel / 1.25), CFrame.Angles(math.rad(90), 0, 0))
                task.wait(); if not abortRef.active or not BasePart.Parent then break end
                FPos(BasePart, CFrame.new(0, -1.5, -vel / 1.25), CFrame.Angles(0, 0, 0))
                task.wait(); if not abortRef.active or not BasePart.Parent then break end
                FPos(BasePart, CFrame.new(0,  1.5,  vel / 1.25), CFrame.Angles(math.rad(90), 0, 0))
                task.wait(); if not abortRef.active or not BasePart.Parent then break end
                FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                task.wait(); if not abortRef.active or not BasePart.Parent then break end
                FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                task.wait(); if not abortRef.active or not BasePart.Parent then break end
                FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(-90), 0, 0))
                task.wait(); if not abortRef.active or not BasePart.Parent then break end
                FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                task.wait(); if not abortRef.active or not BasePart.Parent then break end
            end
        until not BasePart.Parent
            or BasePart.AssemblyLinearVelocity.Magnitude > 500
            or not abortRef.active
            or BasePart.Parent ~= TargetPlayer.Character
            or TargetPlayer.Parent ~= Players
            or (THum and THum.Health <= 0)
            or (THum and THum.Sit)
            or myHum.Health <= 0
            or tick() > startTime + timeLimit
    end

    _G.__LuwaFPDH               = workspace.FallenPartsDestroyHeight
    workspace.FallenPartsDestroyHeight = 0/0

    local bv  = Instance.new("BodyVelocity")
    bv.Parent = myRoot
    bv.Velocity  = Vector3.new(9e8, 9e8, 9e8)
    bv.MaxForce  = Vector3.new(math.huge, math.huge, math.huge)
    currentBV = bv

    local bav = Instance.new("BodyAngularVelocity")
    bav.AngularVelocity = Vector3.new(0, 999999, 0)
    bav.MaxTorque = Vector3.new(999999, 999999, 999999)
    bav.P = 10000
    bav.Parent = myRoot

    myHum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

    if TRoot and THead and (TRoot.CFrame.p - THead.CFrame.p).Magnitude > 5 then
        SFBasePart(THead)
    elseif TRoot then
        SFBasePart(TRoot)
    elseif THead then
        SFBasePart(THead)
    elseif THandle then
        SFBasePart(THandle)
    end

    currentBV = nil
    bv:Destroy()
    pcall(function() bav:Destroy() end)
    myHum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    workspace.CurrentCamera.CameraSubject = myHum

    if wasLoop and _G.__LuwaOldPos then
        local snapCF   = _G.__LuwaOldPos * CFrame.new(0, 0.5, 0)
        local snapPos  = _G.__LuwaOldPos.p
        local snapStart = tick()
        repeat
            if not myRoot.Parent then break end
            pcall(function()
                myRoot.CFrame = snapCF
                myChar:PivotTo(snapCF)
                myHum:ChangeState(Enum.HumanoidStateType.GettingUp)
                for _, part in ipairs(myChar:GetChildren()) do
                    if part:IsA("BasePart") then
                        pcall(function()
                            part.AssemblyLinearVelocity  = Vector3.zero
                            part.AssemblyAngularVelocity = Vector3.zero
                        end)
                    end
                end
            end)
            task.wait()
        until not myRoot.Parent
            or (myRoot.Position - snapPos).Magnitude < 25
            or not myChar:IsDescendantOf(workspace)
            or tick() > snapStart + 3
        workspace.FallenPartsDestroyHeight = _G.__LuwaFPDH or workspace.FallenPartsDestroyHeight
    end
end

local function doSnapBack()
    if not _G.__LuwaOldPos then return end
    local myChar = LocalPlayer.Character
    local myHum  = myChar and myChar:FindFirstChildOfClass("Humanoid")
    local myRoot = myHum  and myHum.RootPart
    if not (myChar and myHum and myRoot) then return end
    local snapCF   = _G.__LuwaOldPos * CFrame.new(0, 0.5, 0)
    local snapPos  = _G.__LuwaOldPos.p
    local snapStart = tick()
    _G.__LuwaOldPos = nil
    _G.__LuwaOldVel = nil
    repeat
        if not myRoot.Parent then break end
        pcall(function()
            myRoot.CFrame = snapCF
            myChar:PivotTo(snapCF)
            myHum:ChangeState(Enum.HumanoidStateType.GettingUp)
            for _, part in ipairs(myChar:GetChildren()) do
                if part:IsA("BasePart") then
                    pcall(function()
                        part.AssemblyLinearVelocity  = Vector3.zero
                        part.AssemblyAngularVelocity = Vector3.zero
                    end)
                end
            end
        end)
        task.wait()
    until not myRoot.Parent
        or (myRoot.Position - snapPos).Magnitude < 25
        or not myChar:IsDescendantOf(workspace)
        or tick() > snapStart + 3
    workspace.FallenPartsDestroyHeight = _G.__LuwaFPDH or workspace.FallenPartsDestroyHeight
end

local loopProtect = nil

local function destroyLoopProtect()
    if loopProtect then
        pcall(function() loopProtect:Destroy() end)
        loopProtect = nil
    end
end

local function createLoopProtect()
    destroyLoopProtect()
    local myChar = LocalPlayer.Character
    local myHum  = myChar and myChar:FindFirstChildOfClass("Humanoid")
    local myRoot = myHum and myHum.RootPart
    if not myRoot then return end
    local p = Instance.new("Part")
    p.Size = Vector3.new(1, 1, 1)
    p.Transparency = 1
    p.CanCollide = false
    p.Anchored = false
    p.Parent = workspace.CurrentCamera
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = myRoot
    weld.Part1 = p
    weld.Parent = p
    local gyro = Instance.new("BodyGyro")
    gyro.MaxTorque = Vector3.new(400000, 400000, 400000)
    gyro.D = 1000
    gyro.P = 2000
    gyro.Parent = p
    loopProtect = p
end

local function stopAllFlings()
    local wasOnce = onceActive

    flingRunning = false
    onceActive   = false
    flingTargets = {}

    if onceVelWatcher then
        onceVelWatcher:Disconnect()
        onceVelWatcher = nil
    end
    if onceAbortRef then
        onceAbortRef.active = false
        onceAbortRef = nil
    end
    if loopAbortRef then
        loopAbortRef.active = false
    end
    if currentBV then
        pcall(function() currentBV:Destroy() end)
        currentBV = nil
    end

    destroyLoopProtect()

    if wasOnce then
        task.spawn(doSnapBack)
    end

    for k in pairs(flingLoopStates) do flingLoopStates[k] = nil end
    if rebuildFlingPicker then
        task.defer(rebuildFlingPicker)
    end
end

local function stopFlingPlayer(uname)
    flingTargets[uname] = nil
    if next(flingTargets) == nil then
        stopAllFlings()
    end
end

local function startFlingLoop()
    if flingRunning then return end
    if antiFlingActive then
        flingPausedAntiFling = true
        stopAntiFling()
    else
        flingPausedAntiFling = false
    end

    flingRunning = true
    task.spawn(function()
        local loopRef = { active = true }
        loopAbortRef = loopRef
        while flingRunning do
            local flingedAny = false
            for uname in pairs(flingTargets) do
                if not flingRunning then break end
                local plr = Players:FindFirstChild(uname)
                if not plr then
                    flingTargets[uname] = nil
                else
                    local char = plr.Character
                    local hum  = char and char:FindFirstChildOfClass("Humanoid")
                    local root = hum and hum.RootPart
                    if char and hum and root and hum.Health > 0
                    and root.AssemblyLinearVelocity.Magnitude < 9e6 then
                        createLoopProtect()
                        pcall(SkidFling, plr, loopRef, true)
                        destroyLoopProtect()
                        flingedAny = true
                    end
                end
            end
            if next(flingTargets) == nil then
                flingRunning = false
            end
            if not flingedAny then task.wait(0.5) end
        end

        destroyLoopProtect()
        loopAbortRef = nil
        if flingPausedAntiFling then
            flingPausedAntiFling = false
            startAntiFling()
        end
    end)
end

local function startFlingPlayer(uname)
    flingTargets[uname] = true
    startFlingLoop()
end

local function startFlingOnce(uname)
    if flingRunning or onceActive then return end
    local plr = Players:FindFirstChild(uname)
    if not plr then return end

    if antiFlingActive then
        flingPausedAntiFling = true
        stopAntiFling()
    else
        flingPausedAntiFling = false
    end

    onceActive = true

    local onceRef = { active = true }
    onceAbortRef  = onceRef

    onceVelWatcher = RunService.Heartbeat:Connect(function()
        pcall(function()
            if not onceActive then return end
            local tChar = plr.Character
            local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
            if tRoot and tRoot.AssemblyLinearVelocity.Magnitude > 500 then
                onceRef.active = false
            end
        end)
    end)

    task.spawn(function()
        pcall(SkidFling, plr, onceRef, false)

        if onceVelWatcher then
            onceVelWatcher:Disconnect()
            onceVelWatcher = nil
        end
        onceAbortRef = nil
        onceActive   = false

        doSnapBack()

        if _G.__LuwaFPDH then
            pcall(function() workspace.FallenPartsDestroyHeight = _G.__LuwaFPDH end)
            _G.__LuwaFPDH = nil
        end
        if flingPausedAntiFling and not flingRunning then
            flingPausedAntiFling = false
            startAntiFling()
        end
    end)
end

local proximityAddedConn    = nil
local proximityActive       = false
local originalHoldDurations = {}

local function applyToPrompt(obj)
    if not obj:IsA("ProximityPrompt") then return end
    if not proximityActive then return end
    pcall(function()
        if originalHoldDurations[obj] == nil then
            originalHoldDurations[obj] = obj.HoldDuration
        end
        obj.HoldDuration = 0
    end)
end

local function startInstantProximity()
    proximityActive = true
    if proximityAddedConn then proximityAddedConn:Disconnect() end
    task.defer(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            applyToPrompt(obj)
        end
    end)
    proximityAddedConn = workspace.DescendantAdded:Connect(function(obj)
        task.defer(function() applyToPrompt(obj) end)
    end)
end

local function stopInstantProximity()
    proximityActive = false
    if proximityAddedConn then proximityAddedConn:Disconnect(); proximityAddedConn = nil end
    for obj, dur in pairs(originalHoldDurations) do
        pcall(function()
            if obj and obj.Parent then
                local origDist = obj.MaxActivationDistance
                obj.MaxActivationDistance = 0
                obj.HoldDuration = dur
                task.delay(0.08, function()
                    pcall(function()
                        if obj and obj.Parent then
                            obj.MaxActivationDistance = origDist
                        end
                    end)
                end)
            end
        end)
    end
    originalHoldDurations = {}
end

local OPTIONS = {}
-- antiFlingOpt and showWpOpt are declared earlier (before the overrides) so the
-- override closures close over the correct local upvalue. Do NOT redeclare them here.

local function addSection(name)
    OPTIONS[#OPTIONS+1] = { type="section", name=name }
end
local function addToggle(name, hint, defaultOn, enableFn, disableFn)
    OPTIONS[#OPTIONS+1] = {
        type="toggle", name=name, hint=hint,
        default=defaultOn, state=defaultOn,
        enable=enableFn, disable=disableFn
    }
end
local function addButton(name, hint, actionFn)
    OPTIONS[#OPTIONS+1] = { type="button", name=name, hint=hint, action=actionFn }
end

addSection("Protection")
local _afOpt = { type="toggle", name="Anti Fling", hint="Blocks velocity transfer. Walkfling and fling can't launch you",
    default=false, state=false, enable=startAntiFling, disable=stopAntiFling }
OPTIONS[#OPTIONS+1] = _afOpt
antiFlingOpt = _afOpt


addSection("Interaction")
addToggle("Instant Proximity", "Remove hold time on prompts", true,
    startInstantProximity, stopInstantProximity)

for _, opt in ipairs(OPTIONS) do
    if opt.type == "toggle" then
        opt.state = opt.default
        if opt.state and type(opt.enable) == "function" then pcall(opt.enable) end
    end
end

local function connectBtn(btn, onPress, onRelease)
    local activeInp = nil
    btn.InputBegan:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1
        and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        activeInp = inp
        if onPress then onPress(inp) end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp ~= activeInp then return end
        activeInp = nil
        if onRelease then onRelease(inp) end
    end)
end

local function tapConnect(gutt, action)
    local pressInp  = nil
    local pressPos  = nil
    local cancelled = false
    local moveConn  = nil

    local function inHitbox(x, y)
        local ap = gutt.AbsolutePosition
        local as = gutt.AbsoluteSize
        return x >= ap.X and x <= ap.X + as.X
           and y >= ap.Y and y <= ap.Y + as.Y
    end

    gutt.InputBegan:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1
        and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        pressInp  = inp
        pressPos  = Vector2.new(inp.Position.X, inp.Position.Y)
        cancelled = false
        if moveConn then moveConn:Disconnect(); moveConn = nil end
        moveConn = UserInputService.InputChanged:Connect(function(ch)
            if ch ~= pressInp then return end
            if cancelled then return end
            local cx, cy = ch.Position.X, ch.Position.Y
            if not inHitbox(cx, cy) then cancelled = true; return end
            if (Vector2.new(cx, cy) - pressPos).Magnitude > 2 then cancelled = true end
        end)
    end)

    UserInputService.InputEnded:Connect(function(inp)
        pcall(function()
        if inp ~= pressInp then return end
        pressInp = nil
        if moveConn then moveConn:Disconnect(); moveConn = nil end
        if cancelled then return end
        local ex, ey = inp.Position.X, inp.Position.Y
        if not inHitbox(ex, ey) then return end
        if type(action) == "function" then pcall(action) end
        end)
    end)
end

local function makeScrollList(parent)
    local sf = Instance.new("ScrollingFrame")
    sf.Size = UDim2.new(1, 0, 1, 0)
    sf.BackgroundTransparency = 1
    sf.BorderSizePixel = 0
    sf.ScrollBarThickness = 3
    sf.ScrollBarImageColor3 = T.scrollBar
    sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sf.CanvasSize = UDim2.new(0, 0, 0, 0)
    sf.Parent = parent
    local ll = Instance.new("UIListLayout")
    ll.SortOrder = Enum.SortOrder.LayoutOrder
    ll.Padding = UDim.new(0, 6)
    ll.Parent = sf
    local pad = Instance.new("UIPadding")
    pad.PaddingTop    = UDim.new(0, 4)
    pad.PaddingBottom = UDim.new(0, 4)
    pad.PaddingLeft   = UDim.new(0, 4)
    pad.PaddingRight  = UDim.new(0, 4)
    pad.Parent = sf
    return sf
end

local function makeSection(parent, labelText)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -8, 0, 22)
    f.BackgroundTransparency = 1
    f.Parent = parent
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -8, 1, 0)
    lbl.Position = UDim2.new(0, 8, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = T.secLbl
    lbl.TextSize = 11
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    lbl.TextStrokeTransparency = 1
    lbl.Parent = f
    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, 0, 0, 1)
    line.Position = UDim2.new(0, 0, 1, -1)
    line.BackgroundColor3 = T.secLine
    line.BorderSizePixel = 0
    line.Parent = f
end

local function makeToggle(parent, opt)
    local startsOn = opt.state
    local hasHint  = opt.hint ~= nil
    local h = hasHint and 60 or 42

    local CON_BG     = T.togOnBg
    local COF_BG     = T.togOffBg
    local CON_STRIP  = T.togOnStrip
    local COF_STRIP  = T.togOffStrip
    local CON_LBL    = T.togOnLbl
    local COF_LBL    = T.togOffLbl
    local CON_PILL   = T.togOnPill
    local COF_PILL   = T.togOffPill
    local HOV_ON     = T.togHovOn
    local HOV_OFF    = T.togHovOff
    local HOV_ON_ST  = T.togHovOnSt
    local HOV_OFF_ST = T.togHovOffSt
    local TRANS      = T.togTrans
    local DOT_ON     = UDim2.new(0, 21, 0.5, -6)
    local DOT_OFF    = UDim2.new(0, 3,  0.5, -6)
    local SZ_SQ      = UDim2.new(1, -16, 0, h - 5)
    local SZ_NRM     = UDim2.new(1, -8,  0, h)

    local cntr = Instance.new("Frame")
    cntr.Size = SZ_NRM
    cntr.BackgroundTransparency = 1
    cntr.Parent = parent

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundColor3 = startsOn and CON_BG or COF_BG
    btn.BackgroundTransparency = TRANS
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = cntr
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

    local strip = Instance.new("Frame")
    strip.Size = UDim2.new(0, 4, 1, -10)
    strip.Position = UDim2.new(0, 8, 0, 5)
    strip.BackgroundColor3 = startsOn and CON_STRIP or COF_STRIP
    strip.BorderSizePixel = 0
    strip.Parent = btn
    Instance.new("UICorner", strip).CornerRadius = UDim.new(1, 0)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -60, 0, 18)
    lbl.Position = UDim2.new(0, 20, 0, hasHint and 6 or 12)
    lbl.BackgroundTransparency = 1
    lbl.Text = opt.name
    lbl.TextColor3 = startsOn and CON_LBL or COF_LBL
    lbl.TextSize = 13
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    lbl.TextStrokeTransparency = 1
    lbl.Parent = btn

    local pillBg = Instance.new("Frame")
    pillBg.Size = UDim2.new(0, 36, 0, 18)
    pillBg.Position = UDim2.new(1, -46, 0, hasHint and 7 or 12)
    pillBg.BackgroundColor3 = startsOn and CON_PILL or COF_PILL
    pillBg.BorderSizePixel = 0
    pillBg.Parent = btn
    Instance.new("UICorner", pillBg).CornerRadius = UDim.new(1, 0)

    local pillDot = Instance.new("Frame")
    pillDot.Size = UDim2.new(0, 12, 0, 12)
    pillDot.Position = startsOn and DOT_ON or DOT_OFF
    pillDot.BackgroundColor3 = startsOn and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(30, 30, 34)
    pillDot.BorderSizePixel = 0
    pillDot.Parent = pillBg
    Instance.new("UICorner", pillDot).CornerRadius = UDim.new(1, 0)

    local toggled = startsOn
    local hintLbl = nil

    if hasHint then
        local hint = Instance.new("TextLabel")
        hintLbl = hint
        hint.Size = UDim2.new(1, -20, 0, 18)
        hint.Position = UDim2.new(0, 20, 0, 36)
        hint.BackgroundTransparency = 1
        hint.Text = opt.hint
        hint.TextColor3 = startsOn and CON_LBL or T.togHint
        hint.TextScaled = true
        hint.Font = Enum.Font.Gotham
        hint.TextXAlignment = Enum.TextXAlignment.Left
        hint.TextWrapped = true
        hint.Parent = btn
        local sc = Instance.new("UITextSizeConstraint")
        sc.MaxTextSize = 11
        sc.MinTextSize = 5
        sc.Parent = hint
    end

    local function applyVisual()
        if toggled then
            TweenService:Create(btn,     TI.med, {BackgroundColor3=CON_BG,   BackgroundTransparency=TRANS}):Play()
            TweenService:Create(strip,   TI.med, {BackgroundColor3=CON_STRIP}):Play()
            TweenService:Create(lbl,     TI.med, {TextColor3=CON_LBL}):Play()
            TweenService:Create(pillBg,  TI.med, {BackgroundColor3=CON_PILL}):Play()
            TweenService:Create(pillDot, TI.pillBounce, {Position=DOT_ON, BackgroundColor3=Color3.fromRGB(255,255,255)}):Play()
            if hintLbl then TweenService:Create(hintLbl, TI.med, {TextColor3=CON_LBL}):Play() end
        else
            TweenService:Create(btn,     TI.med, {BackgroundColor3=COF_BG,   BackgroundTransparency=TRANS}):Play()
            TweenService:Create(strip,   TI.med, {BackgroundColor3=COF_STRIP}):Play()
            TweenService:Create(lbl,     TI.med, {TextColor3=COF_LBL}):Play()
            TweenService:Create(pillBg,  TI.med, {BackgroundColor3=COF_PILL}):Play()
            TweenService:Create(pillDot, TI.pillBounce, {Position=DOT_OFF, BackgroundColor3=Color3.fromRGB(30,30,34)}):Play()
            if hintLbl then TweenService:Create(hintLbl, TI.med, {TextColor3=T.togHint}):Play() end
        end
    end

    local togPressInp  = nil
    local togPressPos  = nil
    local togCancelled = false
    local togMoveConn  = nil

    local function pillInHitbox(x, y)
        local ap = pillBg.AbsolutePosition
        local as = pillBg.AbsoluteSize
        -- expand hit area slightly for easier tapping
        local PAD = 8
        return x >= ap.X - PAD and x <= ap.X + as.X + PAD
           and y >= ap.Y - PAD and y <= ap.Y + as.Y + PAD
    end

    pillBg.InputBegan:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1
        and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        togPressInp  = inp
        togPressPos  = Vector2.new(inp.Position.X, inp.Position.Y)
        togCancelled = false
        if togMoveConn then togMoveConn:Disconnect(); togMoveConn = nil end
        togMoveConn = UserInputService.InputChanged:Connect(function(ch)
            if ch ~= togPressInp then return end
            if togCancelled then return end
            if (Vector2.new(ch.Position.X, ch.Position.Y) - togPressPos).Magnitude > 6 then
                togCancelled = true
            end
        end)
    end)
    UserInputService.InputEnded:Connect(function(inp)
        pcall(function()
        if inp ~= togPressInp then return end
        togPressInp = nil
        if togMoveConn then togMoveConn:Disconnect(); togMoveConn = nil end
        if togCancelled then return end
        local ex, ey = inp.Position.X, inp.Position.Y
        if not pillInHitbox(ex, ey) then return end
        toggled   = not toggled
        opt.state = toggled
        applyVisual()
        if toggled then
            if type(opt.enable)  == "function" then pcall(opt.enable)  end
        else
            if type(opt.disable) == "function" then pcall(opt.disable) end
        end
        end)
    end)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn,   TI.fast, {BackgroundColor3 = toggled and HOV_ON    or HOV_OFF}):Play()
        TweenService:Create(strip, TI.fast, {BackgroundColor3 = toggled and HOV_ON_ST or HOV_OFF_ST}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn,   TI.fast, {BackgroundColor3 = toggled and CON_BG    or COF_BG}):Play()
        TweenService:Create(strip, TI.fast, {BackgroundColor3 = toggled and CON_STRIP or COF_STRIP}):Play()
    end)

    local handle = {
        forceOff = function()
            if not toggled then return end
            toggled   = false
            opt.state = false
            applyVisual()
            if type(opt.disable) == "function" then pcall(opt.disable) end
        end,
        set = function(val)
            val = val and true or false
            if toggled == val then return end
            toggled   = val
            opt.state = val
            applyVisual()
        end,
    }
    opt._handle = handle
    -- direct sync fn: called externally, reads opt.state and applies visual
    opt.syncFn = function()
        toggled = opt.state and true or false
        applyVisual()
    end
    -- forceVisualOff: called by external code (e.g. stopAntiFling auto-off).
    -- 1) directly sets every property to the OFF values this frame (no tween delay)
    -- 2) then also calls applyVisual() so TweenService cancels any competing "on" tweens
    opt.forceVisualOff = function()
        if not toggled then return end   -- already visually off, nothing to do
        toggled = false
        -- immediate property set - bypasses TweenService so it shows this frame
        pcall(function()
            btn.BackgroundColor3        = COF_BG
            btn.BackgroundTransparency  = TRANS
            strip.BackgroundColor3      = COF_STRIP
            lbl.TextColor3              = COF_LBL
            pillBg.BackgroundColor3     = COF_PILL
            pillDot.Position            = DOT_OFF
            if hintLbl then hintLbl.TextColor3 = T.togHint end
        end)
        -- also play tweens so the engine cancels any still-running "on" tweens
        applyVisual()
    end
    return handle
end

local function makeButton(parent, opt)
    local hasHint = opt.hint ~= nil
    local h = hasHint and 60 or 42

    local COL_BG       = T.btnBg
    local COL_HOV      = T.btnHov
    local COL_PRS      = T.btnPrs
    local COL_STRIP    = T.btnStrip
    local COL_STRIP_HOV= T.btnStripHov
    local TRANS        = T.btnTrans
    local SZ_SQ        = UDim2.new(1, -16, 0, h - 5)
    local SZ_NRM       = UDim2.new(1, -8,  0, h)

    local cntr = Instance.new("Frame")
    cntr.Size = SZ_NRM
    cntr.BackgroundTransparency = 1
    cntr.Parent = parent

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundColor3 = COL_BG
    btn.BackgroundTransparency = TRANS
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = cntr
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

    local strip = Instance.new("Frame")
    strip.Size = UDim2.new(0, 4, 1, -10)
    strip.Position = UDim2.new(0, 8, 0, 5)
    strip.BackgroundColor3 = COL_STRIP
    strip.BorderSizePixel = 0
    strip.Parent = btn
    Instance.new("UICorner", strip).CornerRadius = UDim.new(1, 0)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -60, 0, 18)
    lbl.Position = UDim2.new(0, 20, 0, hasHint and 6 or 12)
    lbl.BackgroundTransparency = 1
    lbl.Text = opt.name
    lbl.TextColor3 = T.btnLbl
    lbl.TextSize = 13
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    lbl.TextStrokeTransparency = 1
    lbl.Parent = btn

    if hasHint then
        local hint = Instance.new("TextLabel")
        hint.Size = UDim2.new(1, -20, 0, 18)
        hint.Position = UDim2.new(0, 20, 0, 36)
        hint.BackgroundTransparency = 1
        hint.Text = opt.hint
        hint.TextColor3 = T.btnHint
        hint.TextScaled = true
        hint.Font = Enum.Font.Gotham
        hint.TextXAlignment = Enum.TextXAlignment.Left
        hint.TextWrapped = true
        hint.Parent = btn
        local sc = Instance.new("UITextSizeConstraint")
        sc.MaxTextSize = 11; sc.MinTextSize = 5
        sc.Parent = hint
    end

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 20, 1, 0)
    arrow.Position = UDim2.new(1, -28, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = ">"
    arrow.TextColor3 = T.btnArrow
    arrow.TextSize = 16
    arrow.Font = Enum.Font.GothamBold
    arrow.Parent = btn

    local ARROW_NRM = UDim2.new(1, -28, 0, 0)
    local ARROW_HOV = UDim2.new(1, -22, 0, 0)

    local btnPressInp  = nil
    local btnPressPos  = nil
    local btnCancelled = false
    local btnMoveConn  = nil

    local function btnInHitbox(x, y)
        local ap = btn.AbsolutePosition
        local as = btn.AbsoluteSize
        return x >= ap.X and x <= ap.X + as.X
           and y >= ap.Y and y <= ap.Y + as.Y
    end

    btn.InputBegan:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1
        and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        btnPressInp  = inp
        btnPressPos  = Vector2.new(inp.Position.X, inp.Position.Y)
        btnCancelled = false
        TweenService:Create(btn,   TI.squish1, {BackgroundColor3=COL_PRS}):Play()
        TweenService:Create(strip, TI.squish1, {BackgroundColor3=COL_STRIP_HOV}):Play()
        TweenService:Create(cntr,  TI.squish1, {Size=SZ_SQ}):Play()
        TweenService:Create(arrow, TI.squish1, {Position=ARROW_NRM}):Play()
        if btnMoveConn then btnMoveConn:Disconnect(); btnMoveConn = nil end
        btnMoveConn = UserInputService.InputChanged:Connect(function(ch)
            if ch ~= btnPressInp then return end
            if btnCancelled then return end
            local cx, cy = ch.Position.X, ch.Position.Y
            if not btnInHitbox(cx, cy) then btnCancelled = true; return end
            if (Vector2.new(cx, cy) - btnPressPos).Magnitude > 2 then btnCancelled = true end
        end)
    end)
    UserInputService.InputEnded:Connect(function(inp)
        pcall(function()
        if inp ~= btnPressInp then return end
        btnPressInp = nil
        if btnMoveConn then btnMoveConn:Disconnect(); btnMoveConn = nil end
        TweenService:Create(btn,   TI.med,     {BackgroundColor3=COL_BG}):Play()
        TweenService:Create(strip, TI.med,     {BackgroundColor3=COL_STRIP}):Play()
        TweenService:Create(cntr,  TI.squish2, {Size=SZ_NRM}):Play()
        if btnCancelled then return end
        local ex, ey = inp.Position.X, inp.Position.Y
        if not btnInHitbox(ex, ey) then return end
        if type(opt.action) == "function" then pcall(opt.action) end
        end)
    end)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn,   TI.fast, {BackgroundColor3=COL_HOV}):Play()
        TweenService:Create(strip, TI.fast, {BackgroundColor3=COL_STRIP_HOV}):Play()
        TweenService:Create(arrow, TI.fast, {Position=ARROW_HOV}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn,   TI.fast, {BackgroundColor3=COL_BG}):Play()
        TweenService:Create(strip, TI.fast, {BackgroundColor3=COL_STRIP}):Play()
        TweenService:Create(arrow, TI.fast, {Position=ARROW_NRM}):Play()
    end)
end

local function makeStatInput(parent, labelText, placeholder, defaultVal, onApply, getValue)
    local hasDefault = defaultVal ~= nil
    local rowH = hasDefault and 85 or 52

    local COL_IDLE  = T.strokeIdle
    local COL_FOCUS = T.strokeFocus
    local COL_OK    = Color3.fromRGB(50, 200, 100)

    local rowBg = Instance.new("Frame")
    rowBg.Size = UDim2.new(1, -8, 0, rowH)
    rowBg.BackgroundColor3 = T.rowBg
    rowBg.BackgroundTransparency = T.rowTrans
    rowBg.BorderSizePixel = 0
    rowBg.Parent = parent
    Instance.new("UICorner", rowBg).CornerRadius = UDim.new(0, 10)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -10, 0, 18)
    lbl.Position = UDim2.new(0, 10, 0, 7)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = T.rowLbl
    lbl.TextSize = 12
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    lbl.TextStrokeTransparency = 1
    lbl.Parent = rowBg

    local inputBg = Instance.new("Frame")
    inputBg.Size = UDim2.new(1, -20, 0, 22)
    inputBg.Position = UDim2.new(0, 10, 0, 28)
    inputBg.BackgroundColor3 = T.inputBg
    inputBg.BorderSizePixel = 0
    inputBg.Parent = rowBg
    Instance.new("UICorner", inputBg).CornerRadius = UDim.new(0, 6)

    local stroke = Instance.new("UIStroke")
    stroke.Color = COL_IDLE
    stroke.Thickness = 1
    stroke.Parent = inputBg

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -10, 1, 0)
    box.Position = UDim2.new(0, 8, 0, 0)
    box.BackgroundTransparency = 1
    box.PlaceholderText = placeholder
    box.PlaceholderColor3 = T.inputPh
    box.Text = ""
    box.TextColor3 = T.inputTxt
    box.TextSize = 12
    box.Font = Enum.Font.Gotham
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.ClearTextOnFocus = false
    box.Parent = inputBg

    local function refreshValue()
        if getValue then
            local v = getValue()
            if v ~= nil then
                box.Text = tostring(math.round(v * 100) / 100)
            end
        end
    end
    refreshValue()

    local lastVal = nil
    local liveConn = RunService.Heartbeat:Connect(function()
        if box:IsFocused() then return end
        if not getValue then return end
        local v = getValue()
        if v == nil then return end
        local rounded = math.round(v * 100) / 100
        if rounded ~= lastVal then
            lastVal = rounded
            box.Text = tostring(rounded)
        end
    end)
    rowBg.AncestryChanged:Connect(function()
        if not rowBg.Parent then
            liveConn:Disconnect()
        end
    end)

    box.Focused:Connect(function()
        TweenService:Create(stroke, TI.strokeIn, {Color=COL_FOCUS, Thickness=1.5}):Play()
        refreshValue()
    end)
    box.FocusLost:Connect(function()
        TweenService:Create(stroke, TI.fast, {Color=COL_IDLE, Thickness=1}):Play()
        local val = tonumber(box.Text)
        if val then
            onApply(val)
            TweenService:Create(stroke, TI.flash,   {Color=COL_OK}):Play()
            task.delay(0.4, function()
                TweenService:Create(stroke, TI.unflash, {Color=COL_IDLE}):Play()
            end)
        else
            box.Text = ""
        end
    end)

    if hasDefault then
        local COL_DEF     = T.defBg
        local COL_DEF_HOV = T.defHov
        local COL_DEF_OK  = Color3.fromRGB(40, 160, 85)
        local COL_STR     = T.defStroke
        local COL_STR_OK  = Color3.fromRGB(50, 200, 100)

        local defBtn = Instance.new("TextButton")
        defBtn.Size = UDim2.new(1, -20, 0, 24)
        defBtn.Position = UDim2.new(0, 10, 0, 56)
        defBtn.BackgroundColor3 = COL_DEF
        defBtn.BorderSizePixel = 0
        defBtn.Text = "Default"
        defBtn.TextColor3 = T.defTxt
        defBtn.TextSize = 11
        defBtn.Font = Enum.Font.GothamSemibold
        defBtn.AutoButtonColor = false
        defBtn.Parent = rowBg
        Instance.new("UICorner", defBtn).CornerRadius = UDim.new(0, 6)

        tapConnect(defBtn, function()
            onApply(defaultVal)
            box.Text = ""
            TweenService:Create(defBtn, TI.flash,   {BackgroundColor3=COL_DEF_OK}):Play()
            task.delay(0.5, function()
                TweenService:Create(defBtn, TI.unflash, {BackgroundColor3=COL_DEF}):Play()
            end)
        end)
        defBtn.MouseEnter:Connect(function() TweenService:Create(defBtn, TI.fast, {BackgroundColor3=COL_DEF_HOV}):Play() end)
        defBtn.MouseLeave:Connect(function() TweenService:Create(defBtn, TI.fast, {BackgroundColor3=COL_DEF}):Play()     end)
        connectBtn(defBtn,
            function() TweenService:Create(defBtn, TI.fast, {BackgroundColor3=COL_DEF_HOV}):Play() end,
            function() TweenService:Create(defBtn, TI.fast, {BackgroundColor3=COL_DEF}):Play()     end
        )
    end
end

local function resetScale(save)
    if rescaleForceOff then pcall(rescaleForceOff); rescaleForceOff = nil end
    savedFrameSize = nil
    if activeFrame then
        TweenService:Create(activeFrame, TI.elastic, {Size=DEFAULT_SIZE}):Play()
    end
    if save then
        patchInfo({ scale_w=DEFAULT_SIZE.X.Offset, scale_h=DEFAULT_SIZE.Y.Offset })
    end
end

local flingBoxText = ""
local waypoints = {}

RunService.RenderStepped:Connect(function()
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local pos = root.Position
        for _, wp in ipairs(waypoints) do
            local dist = (wp.pos - pos).Magnitude
            local txt = string.format("%.1f studs", dist)
            if wp.distLbl and wp.distLbl.Parent then
                wp.distLbl.Text = txt
            end
            if wp.bbDistLbl and wp.bbDistLbl.Parent then
                wp.bbDistLbl.Text = txt
            end
        end
    end)
end)

local TABS = {
    {
        name = "Admin",
        iconType = "admin",
        build = function(content)
            local sf = makeScrollList(content)

            makeSection(sf, "Admin")

            local inputRow = Instance.new("Frame")
            inputRow.Size = UDim2.new(1, -8, 0, 34)
            inputRow.BackgroundTransparency = 1
            inputRow.BorderSizePixel = 0
            inputRow.Parent = sf

            local cmdBox = Instance.new("TextBox")
            cmdBox.Size = UDim2.new(1, -46, 1, 0)
            cmdBox.Position = UDim2.new(0, 0, 0, 0)
            cmdBox.BackgroundColor3 = T.inputBg
            cmdBox.BackgroundTransparency = 0.6
            cmdBox.BorderSizePixel = 0
            cmdBox.PlaceholderText = "type a command..."
            cmdBox.PlaceholderColor3 = T.inputPh
            cmdBox.Text = ""
            cmdBox.TextColor3 = T.inputTxt
            cmdBox.TextSize = 11
            cmdBox.Font = Enum.Font.Code
            cmdBox.ClearTextOnFocus = false
            cmdBox.Parent = inputRow
            Instance.new("UICorner", cmdBox).CornerRadius = UDim.new(0, 7)
            local cmdStroke = Instance.new("UIStroke")
            cmdStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            cmdStroke.Color = T.strokeIdle
            cmdStroke.Thickness = 1
            cmdStroke.Parent = cmdBox
            local cmdPad = Instance.new("UIPadding")
            cmdPad.PaddingLeft = UDim.new(0, 8)
            cmdPad.Parent = cmdBox

            local runBtn = Instance.new("TextButton")
            runBtn.Size = UDim2.new(0, 38, 1, 0)
            runBtn.Position = UDim2.new(1, -38, 0, 0)
            runBtn.BackgroundColor3 = T.btnBg
            runBtn.BackgroundTransparency = T.btnTrans
            runBtn.BorderSizePixel = 0
            runBtn.Text = ">"
            runBtn.TextColor3 = T.accent
            runBtn.TextSize = 13
            runBtn.Font = Enum.Font.GothamBold
            runBtn.AutoButtonColor = false
            runBtn.Parent = inputRow
            Instance.new("UICorner", runBtn).CornerRadius = UDim.new(0, 7)

            -- -- Browse Commands button
            local browseCommandsBtn = Instance.new("TextButton")
            browseCommandsBtn.Size = UDim2.new(1, -8, 0, 32)
            browseCommandsBtn.BackgroundColor3 = T.btnBg
            browseCommandsBtn.BackgroundTransparency = T.btnTrans
            browseCommandsBtn.BorderSizePixel = 0
            browseCommandsBtn.Text = "Browse Commands"
            browseCommandsBtn.TextColor3 = T.btnLbl
            browseCommandsBtn.TextSize = 11
            browseCommandsBtn.Font = Enum.Font.GothamSemibold
            browseCommandsBtn.AutoButtonColor = false
            browseCommandsBtn.Parent = sf
            Instance.new("UICorner", browseCommandsBtn).CornerRadius = UDim.new(0, 8)
            local bcBtnStroke = Instance.new("UIStroke")
            bcBtnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            bcBtnStroke.Color = T.strokeIdle
            bcBtnStroke.Thickness = 0.8
            bcBtnStroke.Transparency = 0.6
            bcBtnStroke.Parent = browseCommandsBtn
            local bcArrow = Instance.new("TextLabel")
            bcArrow.Size = UDim2.new(0, 20, 1, 0)
            bcArrow.Position = UDim2.new(1, -26, 0, 0)
            bcArrow.BackgroundTransparency = 1
            bcArrow.Text = ">"
            bcArrow.TextColor3 = T.btnArrow
            bcArrow.TextSize = 14
            bcArrow.Font = Enum.Font.GothamBold
            bcArrow.Parent = browseCommandsBtn
            connectBtn(browseCommandsBtn,
                function() TweenService:Create(browseCommandsBtn, TI.fast, {BackgroundTransparency = 0.2}):Play() end,
                function() TweenService:Create(browseCommandsBtn, TI.fast, {BackgroundTransparency = T.btnTrans}):Play() end
            )

            -- -- Commands window (separate draggable ScreenGui)
            local cmdWinSg = nil
            local cmdWinVisible = false
            local cwFrameRef = nil  -- holds the cwFrame for animations

            local TI_CMD_IN  = TweenInfo.new(0.32, Enum.EasingStyle.Back,  Enum.EasingDirection.Out)
            local TI_CMD_OUT = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In)

            local function closeCmdWin()
                if not (cwFrameRef and cwFrameRef.Parent) then return end
                cmdWinVisible = false
                local sc = cwFrameRef:FindFirstChildOfClass("UIScale")
                if sc then TweenService:Create(sc, TI_CMD_OUT, {Scale = 0.9}):Play() end
                TweenService:Create(cwFrameRef, TI_CMD_OUT, {BackgroundTransparency = 1}):Play()
                task.delay(0.2, function()
                    if cmdWinSg then cmdWinSg.Enabled = false end
                    if cwFrameRef then cwFrameRef.BackgroundTransparency = T.frameTrans end
                    local sc2 = cwFrameRef and cwFrameRef:FindFirstChildOfClass("UIScale")
                    if sc2 then sc2.Scale = 0.88 end
                end)
            end

            local function openCmdWin()
                if not (cwFrameRef and cwFrameRef.Parent) then return end
                cmdWinVisible = true
                cmdWinSg.Enabled = true
                local sc = cwFrameRef:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", cwFrameRef)
                sc.Scale = 0.88
                cwFrameRef.BackgroundTransparency = 1
                TweenService:Create(cwFrameRef, TI_CMD_IN, {BackgroundTransparency = T.frameTrans}):Play()
                TweenService:Create(sc,         TI_CMD_IN, {Scale = 1}):Play()
            end

            local function buildCommandsWindow()
                if cmdWinSg and cmdWinSg.Parent then
                    if cmdWinVisible then
                        closeCmdWin()
                    else
                        openCmdWin()
                    end
                    return
                end
                cmdWinSg = Instance.new("ScreenGui")
                cmdWinSg.Name = "LuwaCmdBrowser"
                cmdWinSg.ResetOnSpawn = false
                cmdWinSg.IgnoreGuiInset = true
                cmdWinSg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
                cmdWinSg.DisplayOrder = 22
                cmdWinSg.Parent = LocalPlayer.PlayerGui

                local CW_W = 260
                local CW_H = 310
                local cwFrame = Instance.new("Frame")
                cwFrame.Size = UDim2.new(0, CW_W, 0, CW_H)
                cwFrame.Position = UDim2.new(0.5, -CW_W/2, 0.5, -CW_H/2)
                cwFrame.BackgroundColor3 = T.frameBg
                cwFrame.BackgroundTransparency = 1   -- starts invisible; openCmdWin() animates it in
                cwFrame.BorderSizePixel = 0
                cwFrame.Active = true
                cwFrame.ZIndex = 2
                cwFrame.Parent = cmdWinSg
                cwFrameRef = cwFrame
                Instance.new("UICorner", cwFrame).CornerRadius = UDim.new(0, 20)
                local cwStroke = Instance.new("UIStroke")
                cwStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                cwStroke.Color = Color3.fromRGB(255, 255, 255)
                cwStroke.Thickness = 0.5
                cwStroke.Transparency = 0.35
                cwStroke.Parent = cwFrame

                -- Top glint (matches main frame style)
                local cwGlint = Instance.new("Frame")
                cwGlint.Size                   = UDim2.new(1, -28, 0, 10)
                cwGlint.Position               = UDim2.new(0, 14, 0, 5)
                cwGlint.BackgroundColor3       = Color3.fromRGB(255, 255, 255)
                cwGlint.BackgroundTransparency = 1
                cwGlint.BorderSizePixel        = 0
                cwGlint.ZIndex                 = 10
                cwGlint.Parent                 = cwFrame
                Instance.new("UICorner", cwGlint).CornerRadius = UDim.new(0, 6)
                local cwGlintGrad = Instance.new("UIGradient")
                cwGlintGrad.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0,    1   ),
                    NumberSequenceKeypoint.new(0.15, 0.86),
                    NumberSequenceKeypoint.new(0.5,  0.80),
                    NumberSequenceKeypoint.new(0.85, 0.86),
                    NumberSequenceKeypoint.new(1,    1   ),
                })
                cwGlintGrad.Parent = cwGlint

                -- Header (drag bar) - transparent bg, matches main frame title area
                local cwHeader = Instance.new("Frame")
                cwHeader.Size = UDim2.new(1, 0, 0, 46)
                cwHeader.BackgroundTransparency = 1
                cwHeader.BorderSizePixel = 0
                cwHeader.ZIndex = 3
                cwHeader.Active = true
                cwHeader.Parent = cwFrame

                -- Accent line below header (matches main frame separator)
                local cwAccentLine = Instance.new("Frame")
                cwAccentLine.Size             = UDim2.new(1, -20, 0, 2)
                cwAccentLine.Position         = UDim2.new(0, 10, 0, 44)
                cwAccentLine.BackgroundColor3 = T.accent
                cwAccentLine.BorderSizePixel  = 0
                cwAccentLine.ZIndex           = 4
                cwAccentLine.Parent           = cwFrame
                Instance.new("UICorner", cwAccentLine).CornerRadius = UDim.new(1, 0)

                -- Drag handle
                local cwDragIcon = Instance.new("TextLabel")
                cwDragIcon.Size = UDim2.new(0, 14, 1, 0)
                cwDragIcon.Position = UDim2.new(0, 10, 0, 0)
                cwDragIcon.BackgroundTransparency = 1
                cwDragIcon.Text = "::"
                cwDragIcon.TextColor3 = Color3.fromRGB(70, 70, 82)
                cwDragIcon.TextSize = 13
                cwDragIcon.Font = Enum.Font.GothamBold
                cwDragIcon.ZIndex = 4
                cwDragIcon.Parent = cwHeader

                local cwTitle = Instance.new("TextLabel")
                cwTitle.Size = UDim2.new(1, -60, 0, 18)
                cwTitle.Position = UDim2.new(0, 28, 0, 8)
                cwTitle.BackgroundTransparency = 1
                cwTitle.Text = "Commands"
                cwTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
                cwTitle.TextSize = 13
                cwTitle.Font = Enum.Font.GothamBold
                cwTitle.TextXAlignment = Enum.TextXAlignment.Left
                cwTitle.ZIndex = 4
                cwTitle.Parent = cwHeader

                local cwSub = Instance.new("TextLabel")
                cwSub.Size = UDim2.new(1, -60, 0, 12)
                cwSub.Position = UDim2.new(0, 28, 0, 28)
                cwSub.BackgroundTransparency = 1
                cwSub.Text = "Tap to paste into command box"
                cwSub.TextColor3 = Color3.fromRGB(90, 90, 105)
                cwSub.TextSize = 9
                cwSub.Font = Enum.Font.Gotham
                cwSub.TextXAlignment = Enum.TextXAlignment.Left
                cwSub.ZIndex = 4
                cwSub.Parent = cwHeader

                -- Close button
                local cwCloseBtn = Instance.new("TextButton")
                cwCloseBtn.Size = UDim2.new(0, 24, 0, 24)
                cwCloseBtn.Position = UDim2.new(1, -32, 0, 11)
                cwCloseBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                cwCloseBtn.BackgroundTransparency = 0.55
                cwCloseBtn.BorderSizePixel = 0
                cwCloseBtn.Text = "X"
                cwCloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                cwCloseBtn.TextSize = 10
                cwCloseBtn.Font = Enum.Font.GothamBold
                cwCloseBtn.AutoButtonColor = false
                cwCloseBtn.ZIndex = 4
                cwCloseBtn.Parent = cwHeader
                Instance.new("UICorner", cwCloseBtn).CornerRadius = UDim.new(1, 0)
                local cwCloseStroke = Instance.new("UIStroke")
                cwCloseStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                cwCloseStroke.Color           = Color3.fromRGB(255, 255, 255)
                cwCloseStroke.Thickness       = 0.9
                cwCloseStroke.Transparency    = 0.55
                cwCloseStroke.Parent          = cwCloseBtn
                tapConnect(cwCloseBtn, function()
                    closeCmdWin()
                end)
                connectBtn(cwCloseBtn,
                    function() TweenService:Create(cwCloseBtn, TI.fast, {BackgroundTransparency = 0.3}):Play() end,
                    function() TweenService:Create(cwCloseBtn, TI.fast, {BackgroundTransparency = 0.55}):Play() end
                )

                -- Divider (accent line already placed above, this one removed to avoid duplicate)
                -- Search box
                local cwSearchBg = Instance.new("Frame")
                cwSearchBg.Size             = UDim2.new(1, -16, 0, 28)
                cwSearchBg.Position         = UDim2.new(0, 8, 0, 50)
                cwSearchBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                cwSearchBg.BackgroundTransparency = 0
                cwSearchBg.BorderSizePixel  = 0
                cwSearchBg.ZIndex           = 4
                cwSearchBg.Parent           = cwFrame
                Instance.new("UICorner", cwSearchBg).CornerRadius = UDim.new(0, 7)
                local cwSearchStroke = Instance.new("UIStroke")
                cwSearchStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                cwSearchStroke.Color           = Color3.fromRGB(60, 60, 70)
                cwSearchStroke.Thickness       = 1
                cwSearchStroke.Transparency    = 0.4
                cwSearchStroke.Parent          = cwSearchBg

                local cwSearchBox = Instance.new("TextBox")
                cwSearchBox.Size                = UDim2.new(1, -22, 1, 0)
                cwSearchBox.Position            = UDim2.new(0, 22, 0, 0)
                cwSearchBox.BackgroundTransparency = 1
                cwSearchBox.PlaceholderText     = "Search..."
                cwSearchBox.PlaceholderColor3   = Color3.fromRGB(80, 80, 95)
                cwSearchBox.Text                = ""
                cwSearchBox.TextColor3          = Color3.fromRGB(255, 255, 255)
                cwSearchBox.TextSize            = 11
                cwSearchBox.Font                = Enum.Font.Gotham
                cwSearchBox.TextXAlignment      = Enum.TextXAlignment.Left
                cwSearchBox.ClearTextOnFocus    = false
                cwSearchBox.ZIndex              = 5
                cwSearchBox.Parent              = cwSearchBg

                local cwSearchIcon = Instance.new("TextLabel")
                cwSearchIcon.Size               = UDim2.new(0, 18, 1, 0)
                cwSearchIcon.Position           = UDim2.new(0, 4, 0, 0)
                cwSearchIcon.BackgroundTransparency = 1
                cwSearchIcon.Text               = "?"
                cwSearchIcon.TextColor3         = Color3.fromRGB(80, 80, 95)
                cwSearchIcon.TextSize           = 12
                cwSearchIcon.Font               = Enum.Font.GothamBold
                cwSearchIcon.ZIndex             = 5
                cwSearchIcon.Parent             = cwSearchBg

                cwSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                    TweenService:Create(cwSearchStroke, TI.fast,
                        {Color = cwSearchBox.Text ~= "" and Color3.fromRGB(255,255,255) or Color3.fromRGB(60,60,70)}):Play()
                end)

                -- Scroll list (pushed down to make room for search)
                local cwSf = Instance.new("ScrollingFrame")
                cwSf.Size = UDim2.new(1, -10, 1, -86)
                cwSf.Position = UDim2.new(0, 5, 0, 84)
                cwSf.BackgroundTransparency = 1
                cwSf.BorderSizePixel = 0
                cwSf.ScrollBarThickness = 3
                cwSf.ScrollBarImageColor3 = T.scrollBar
                cwSf.AutomaticCanvasSize = Enum.AutomaticSize.Y
                cwSf.CanvasSize = UDim2.new(0, 0, 0, 0)
                cwSf.ZIndex = 3
                cwSf.Parent = cwFrame
                local cwLayout = Instance.new("UIListLayout")
                cwLayout.SortOrder = Enum.SortOrder.LayoutOrder
                cwLayout.Padding = UDim.new(0, 4)
                cwLayout.Parent = cwSf
                local cwPad = Instance.new("UIPadding")
                cwPad.PaddingTop    = UDim.new(0, 4)
                cwPad.PaddingBottom = UDim.new(0, 6)
                cwPad.PaddingLeft   = UDim.new(0, 4)
                cwPad.PaddingRight  = UDim.new(0, 4)
                cwPad.Parent = cwSf

                -- Command definitions in clean order
                local CMD_LIST = {
                    { cmd="noclip",      desc="Phase through walls and players" },
                    { cmd="clip",        desc="Restore collision / check if inside wall" },
                    { cmd="rejoin",      desc="Rejoin the current server" },
                    { cmd="nofog",       desc="Remove all fog from the game" },
                    { cmd="unfog",       desc="Restore fog to original state" },
                    { cmd="view",        desc="Spectate a player  (usage: view [name])" },
                    { cmd="unview",      desc="Stop spectating" },
                    { cmd="tp",          desc="Teleport to a player  (usage: tp [name])" },
                    { cmd="servers",     desc="Browse other servers for this game" },
                    { cmd="esp",         desc="Enable player ESP overlays" },
                    { cmd="unesp",       desc="Disable all ESP overlays" },
                    { cmd="settingsesp", desc="Toggle the ESP settings panel" },
                    { cmd="walkfling",   desc="Fling players by walking into them" },
                    { cmd="walkflingnc", desc="Walkfling + noclip combined" },
                    { cmd="unwalkfling", desc="Stop walkfling" },
                }

                local function makeSection(label, order)
                    local secF = Instance.new("Frame")
                    secF.Size = UDim2.new(1, 0, 0, 18)
                    secF.BackgroundTransparency = 1
                    secF.LayoutOrder = order
                    secF.ZIndex = 4
                    secF.Parent = cwSf
                    local secLbl = Instance.new("TextLabel")
                    secLbl.Size = UDim2.new(1, -4, 1, 0)
                    secLbl.Position = UDim2.new(0, 4, 0, 0)
                    secLbl.BackgroundTransparency = 1
                    secLbl.Text = label
                    secLbl.TextColor3 = Color3.fromRGB(130, 130, 148)
                    secLbl.TextSize = 9
                    secLbl.Font = Enum.Font.GothamBold
                    secLbl.TextXAlignment = Enum.TextXAlignment.Left
                    secLbl.ZIndex = 4
                    secLbl.Parent = secF
                    local secLine = Instance.new("Frame")
                    secLine.Size = UDim2.new(1, 0, 0, 1)
                    secLine.Position = UDim2.new(0, 0, 1, -1)
                    secLine.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
                    secLine.BorderSizePixel = 0
                    secLine.ZIndex = 4
                    secLine.Parent = secF
                end

                local order = 0
                local cwRows = {}  -- { row=frame, cmd=string, desc=string }

                for idx, entry in ipairs(CMD_LIST) do
                    order = order + 1
                    local row = Instance.new("TextButton")
                    row.Size = UDim2.new(1, 0, 0, 46)
                    row.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
                    row.BackgroundTransparency = 0.08
                    row.BorderSizePixel = 0
                    row.Text = ""
                    row.AutoButtonColor = false
                    row.LayoutOrder = order
                    row.ZIndex = 4
                    row.Parent = cwSf
                    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
                    local rowStroke = Instance.new("UIStroke")
                    rowStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    rowStroke.Color = Color3.fromRGB(40, 40, 48)
                    rowStroke.Thickness = 0.5
                    rowStroke.Transparency = 0.6
                    rowStroke.Parent = row

                    -- Accent strip
                    local rowStrip = Instance.new("Frame")
                    rowStrip.Size = UDim2.new(0, 3, 1, -12)
                    rowStrip.Position = UDim2.new(0, 7, 0, 6)
                    rowStrip.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
                    rowStrip.BorderSizePixel = 0
                    rowStrip.ZIndex = 5
                    rowStrip.Parent = row
                    Instance.new("UICorner", rowStrip).CornerRadius = UDim.new(1, 0)

                    local cmdLbl = Instance.new("TextLabel")
                    cmdLbl.Size = UDim2.new(1, -22, 0, 17)
                    cmdLbl.Position = UDim2.new(0, 18, 0, 7)
                    cmdLbl.BackgroundTransparency = 1
                    cmdLbl.Text = entry.cmd
                    cmdLbl.TextColor3 = Color3.fromRGB(220, 220, 235)
                    cmdLbl.TextSize = 12
                    cmdLbl.Font = Enum.Font.GothamBold
                    cmdLbl.TextXAlignment = Enum.TextXAlignment.Left
                    cmdLbl.ZIndex = 5
                    cmdLbl.Parent = row

                    local descLbl = Instance.new("TextLabel")
                    descLbl.Size = UDim2.new(1, -22, 0, 16)
                    descLbl.Position = UDim2.new(0, 18, 0, 25)
                    descLbl.BackgroundTransparency = 1
                    descLbl.Text = entry.desc
                    descLbl.TextColor3 = Color3.fromRGB(105, 105, 120)
                    descLbl.TextSize = 9
                    descLbl.Font = Enum.Font.Gotham
                    descLbl.TextXAlignment = Enum.TextXAlignment.Left
                    descLbl.TextTruncate = Enum.TextTruncate.AtEnd
                    descLbl.ZIndex = 5
                    descLbl.Parent = row

                    cwRows[#cwRows + 1] = { row = row, cmd = entry.cmd, desc = entry.desc }

                    local cmdRef = entry.cmd
                    tapConnect(row, function()
                        -- Paste command name into the admin command box
                        if adminCmdBox and adminCmdBox.Parent then
                            adminCmdBox.Text = cmdRef
                        end
                        TweenService:Create(row, TI.flash,   {BackgroundColor3 = Color3.fromRGB(35, 55, 35)}):Play()
                        task.delay(0.3, function()
                            TweenService:Create(row, TI.unflash, {BackgroundColor3 = Color3.fromRGB(16, 16, 20)}):Play()
                        end)
                    end)
                    connectBtn(row,
                        function() TweenService:Create(row, TI.fast, {BackgroundTransparency = 0.3}):Play() end,
                        function() TweenService:Create(row, TI.fast, {BackgroundTransparency = 0.08}):Play() end
                    )
                end

                -- Wire search filter
                cwSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                    local q = cwSearchBox.Text:lower():match("^%s*(.-)%s*$")
                    for _, r in ipairs(cwRows) do
                        local match = q == "" or r.cmd:find(q, 1, true) or r.desc:lower():find(q, 1, true)
                        r.row.Visible = match and true or false
                    end
                end)

                -- Resize handle (bottom-right)
                local cwResizeHandle = Instance.new("TextButton")
                cwResizeHandle.Size = UDim2.new(0, 18, 0, 18)
                cwResizeHandle.Position = UDim2.new(1, -18, 1, -18)
                cwResizeHandle.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
                cwResizeHandle.BackgroundTransparency = 0.4
                cwResizeHandle.BorderSizePixel = 0
                cwResizeHandle.Text = "//"
                cwResizeHandle.TextColor3 = Color3.fromRGB(150, 150, 165)
                cwResizeHandle.TextSize = 9
                cwResizeHandle.Font = Enum.Font.GothamBold
                cwResizeHandle.AutoButtonColor = false
                cwResizeHandle.ZIndex = 5
                cwResizeHandle.Parent = cwFrame
                Instance.new("UICorner", cwResizeHandle).CornerRadius = UDim.new(0, 4)
                connectBtn(cwResizeHandle,
                    function() TweenService:Create(cwResizeHandle, TI.fast, {BackgroundTransparency = 0.1}):Play() end,
                    function() TweenService:Create(cwResizeHandle, TI.fast, {BackgroundTransparency = 0.4}):Play() end
                )
                do
                    local _cwRDrag, _cwRStart, _cwRSz = nil, nil, nil
                    cwResizeHandle.InputBegan:Connect(function(inp)
                        if inp.UserInputType ~= Enum.UserInputType.MouseButton1
                        and inp.UserInputType ~= Enum.UserInputType.Touch then return end
                        _cwRDrag = inp; _cwRStart = inp.Position; _cwRSz = cwFrame.Size
                    end)
                    UserInputService.InputChanged:Connect(function(inp)
                        if inp ~= _cwRDrag then return end
                        local d = inp.Position - _cwRStart
                        cwFrame.Size = UDim2.new(0, math.max(200, _cwRSz.X.Offset + d.X),
                                                    0, math.max(180, _cwRSz.Y.Offset + d.Y))
                    end)
                    UserInputService.InputEnded:Connect(function(inp)
                        if inp == _cwRDrag then _cwRDrag = nil end
                    end)
                end

                -- Drag logic
                do
                    local _cwDragInp, _cwDragStart, _cwFrameStart = nil, nil, nil
                    cwHeader.InputBegan:Connect(function(inp)
                        if inp.UserInputType ~= Enum.UserInputType.MouseButton1
                        and inp.UserInputType ~= Enum.UserInputType.Touch then return end
                        _cwDragInp   = inp
                        _cwDragStart = inp.Position
                        _cwFrameStart = cwFrame.Position
                    end)
                    UserInputService.InputChanged:Connect(function(inp)
                        if inp ~= _cwDragInp then return end
                        local d = inp.Position - _cwDragStart
                        cwFrame.Position = UDim2.new(_cwFrameStart.X.Scale, _cwFrameStart.X.Offset + d.X,
                                                     _cwFrameStart.Y.Scale, _cwFrameStart.Y.Offset + d.Y)
                    end)
                    UserInputService.InputEnded:Connect(function(inp)
                        if inp == _cwDragInp then _cwDragInp = nil end
                    end)
                end

                cmdWinVisible = true
                -- Animate the window in like the profile card
                openCmdWin()
            end

            tapConnect(browseCommandsBtn, function()
                buildCommandsWindow()
            end)

            local logFrame = Instance.new("Frame")
            logFrame.Size = UDim2.new(1, -8, 0, 160)
            logFrame.BackgroundColor3 = T.inputBg
            logFrame.BackgroundTransparency = 0.55
            logFrame.BorderSizePixel = 0
            logFrame.ClipsDescendants = true
            logFrame.Parent = sf
            Instance.new("UICorner", logFrame).CornerRadius = UDim.new(0, 8)
            local logStroke = Instance.new("UIStroke")
            logStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            logStroke.Color = T.strokeIdle
            logStroke.Thickness = 1
            logStroke.Parent = logFrame

            local logSf = Instance.new("ScrollingFrame")
            logSf.Size = UDim2.new(1, 0, 1, 0)
            logSf.BackgroundTransparency = 1
            logSf.BorderSizePixel = 0
            logSf.ScrollBarThickness = 3
            logSf.ScrollBarImageColor3 = T.scrollBar
            logSf.CanvasSize = UDim2.new(0, 0, 0, 0)
            logSf.AutomaticCanvasSize = Enum.AutomaticSize.Y
            logSf.Parent = logFrame
            local logLayout = Instance.new("UIListLayout")
            logLayout.FillDirection = Enum.FillDirection.Vertical
            logLayout.SortOrder = Enum.SortOrder.LayoutOrder
            logLayout.Padding = UDim.new(0, 2)
            logLayout.Parent = logSf
            local logPad = Instance.new("UIPadding")
            logPad.PaddingLeft   = UDim.new(0, 8)
            logPad.PaddingRight  = UDim.new(0, 4)
            logPad.PaddingTop    = UDim.new(0, 6)
            logPad.PaddingBottom = UDim.new(0, 6)
            logPad.Parent = logSf

            local logOrder = 0
            local function logLine(msg, color)
                logOrder = logOrder + 1
                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1, 0, 0, 16)
                lbl.BackgroundTransparency = 1
                lbl.Text = msg
                lbl.TextColor3 = color or T.inputTxt
                lbl.TextSize = 10
                lbl.Font = Enum.Font.Code
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.TextWrapped = true
                lbl.AutomaticSize = Enum.AutomaticSize.Y
                lbl.LayoutOrder = logOrder
                lbl.Parent = logSf
                task.defer(function()
                    if logSf and logSf.Parent then
                        logSf.CanvasPosition = Vector2.new(0, math.max(0, logSf.AbsoluteCanvasSize.Y - logSf.AbsoluteSize.Y))
                    end
                end)
            end

            logLine("> outputs", rgb(80, 80, 92))

            local COMMANDS = {}
            local DESCRIPTIONS = {
                ["noclip"]      = "phase through walls and players",
                ["clip"]        = "restore collision / check if inside wall",
                ["rejoin"]      = "rejoin the current server",
                ["walkfling"]   = "fling players by walking into them",
                ["walkflingnc"] = "walkfling + noclip combined",
                ["unwalkfling"] = "stop walkfling",
                ["nofog"]       = "remove all fog from the game",
                ["unfog"]       = "restore fog to original state",
                ["view"]        = "spectate a player (name, username or nickname)",
                ["unview"]      = "stop spectating",
                ["esp"]         = "enable player ESP overlays",
                ["unesp"]       = "disable all ESP overlays",
                ["settingsesp"] = "toggle the ESP settings panel",
            }

            COMMANDS["noclip"] = function()
                if noclipActive then
                    logLine("> already noclipping", rgb(255, 200, 60))
                    return
                end
                noclipActive = true
                local collMap = {}
                -- Only disable collision on the LOCAL player's own parts.
                -- Touching other players' CanCollide here is wrong and causes
                -- unintended side-effects (they walk through walls too).
                noclipConn = RunService.Stepped:Connect(function()
                    if not noclipActive then
                        noclipConn:Disconnect()
                        noclipConn = nil
                        return
                    end
                    local myChar = LocalPlayer.Character
                    if not myChar then return end
                    for _, v in pairs(myChar:GetDescendants()) do
                        if v:IsA("BasePart") then
                            if collMap[v] == nil then collMap[v] = v.CanCollide end
                            v.CanCollide = false
                        end
                    end
                end)
                noclipCollMap = collMap
                logLine("> noclip on", rgb(50, 210, 100))
            end

            -- Performance-friendly clip detection:
            -- Samples once per 0.5s using GetPartsInPart to check if the HRP
            -- is physically overlapping a solid world part (= phasing through walls).
            local clipCheckConn    = nil
            local lastClipCheckVal = nil
            local function startClipCheck()
                if clipCheckConn then return end
                local OP = OverlapParams.new()
                OP.FilterType = Enum.RaycastFilterType.Exclude
                OP.MaxParts   = 4
                local nextCheck = 0
                clipCheckConn = RunService.Heartbeat:Connect(function()
                    if tick() < nextCheck then return end
                    nextCheck = tick() + 0.5
                    pcall(function()
                        local char = LocalPlayer.Character
                        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                        if not hrp then return end
                        local ignore = {}
                        for _, v in ipairs(char:GetDescendants()) do
                            if v:IsA("BasePart") then ignore[#ignore+1] = v end
                        end
                        OP:AddToFilter(ignore)
                        local parts = workspace:GetPartsInPart(hrp, OP)
                        local inside = false
                        for _, p in ipairs(parts) do
                            if p.CanCollide and not p:IsA("Terrain") then
                                inside = true; break
                            end
                        end
                        OP:AddToFilter({})  -- reset filter for next call
                        if inside ~= lastClipCheckVal then
                            lastClipCheckVal = inside
                            if inside and not noclipActive then
                                logLine("> clip: inside solid object", rgb(255, 200, 60))
                            end
                        end
                    end)
                end)
            end
            local function stopClipCheck()
                if clipCheckConn then clipCheckConn:Disconnect(); clipCheckConn = nil end
                lastClipCheckVal = nil
            end

            COMMANDS["clip"] = function()
                if flinging then
                    logLine("> turn off walkflingnc first", rgb(255, 200, 60))
                    return
                end
                if not noclipActive then
                    -- Run a one-shot physical check before reporting
                    local phasing = false
                    pcall(function()
                        local char = LocalPlayer.Character
                        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                        if not hrp then return end
                        local op = OverlapParams.new()
                        op.FilterType = Enum.RaycastFilterType.Exclude
                        local ignore = {}
                        for _, v in ipairs(char:GetDescendants()) do
                            if v:IsA("BasePart") then ignore[#ignore+1] = v end
                        end
                        op:AddToFilter(ignore)
                        op.MaxParts = 4
                        local parts = workspace:GetPartsInPart(hrp, op)
                        for _, p in ipairs(parts) do
                            if p.CanCollide then phasing = true; break end
                        end
                    end)
                    if phasing then
                        logLine("> not noclipping (but inside wall!)", rgb(255, 200, 60))
                    else
                        logLine("> not noclipping", rgb(255, 200, 60))
                    end
                    return
                end
                stopClipCheck()
                noclipActive = false
                if noclipConn then
                    noclipConn:Disconnect()
                    noclipConn = nil
                end
                if noclipCollMap then
                    for part, original in pairs(noclipCollMap) do
                        if part and part.Parent then
                            part.CanCollide = original
                        end
                    end
                    noclipCollMap = nil
                end
                logLine("> clip on", rgb(255, 80, 80))
            end

            COMMANDS["rejoin"] = function()
                local tp = game:GetService("TeleportService")
                local placeId = game.PlaceId
                local jobId = game.JobId
                logLine("> rejoining...", rgb(160, 160, 175))
                pcall(function()
                    if jobId ~= "" then
                        tp:TeleportToPlaceInstance(placeId, jobId, LocalPlayer)
                    else
                        tp:Teleport(placeId, LocalPlayer)
                    end
                end)
            end

            local flinging = false

            local function getValidRoot()
                local chr = LocalPlayer.Character
                local hrp = chr and chr:FindFirstChild("HumanoidRootPart")
                return (chr and chr.Parent and hrp and hrp.Parent) and hrp or nil
            end

            local function startWalkfling()
                flinging = true
                local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if h then h.Died:Connect(function() if flinging then COMMANDS["unwalkfling"]() end end) end
                task.spawn(function()
                    local flip = 0.1
                    repeat
                        RunService.Heartbeat:Wait()
                        local root = getValidRoot()
                        while not root do
                            RunService.Heartbeat:Wait()
                            root = getValidRoot()
                        end
                        local old = root.Velocity
                        root.Velocity = old * 10000 + Vector3.new(0, 10000, 0)
                        RunService.RenderStepped:Wait()
                        if getValidRoot() then root.Velocity = old end
                        RunService.Stepped:Wait()
                        if getValidRoot() then
                            root.Velocity = old + Vector3.new(0, flip, 0)
                            flip = -flip
                        end
                    until not flinging
                end)
            end

            COMMANDS["walkfling"] = function()
                if flinging then logLine("> already on", rgb(255, 200, 60)) return end
                startWalkfling()
                logLine("> walkfling on", rgb(50, 210, 100))
            end

            COMMANDS["walkflingnc"] = function()
                if flinging then logLine("> already on", rgb(255, 200, 60)) return end
                if noclipActive then logLine("> disable noclip first", rgb(255, 200, 60)) return end
                COMMANDS["noclip"]()
                startWalkfling()
                logLine("> walkfling + noclip on", rgb(50, 210, 100))
            end

            COMMANDS["unwalkfling"] = function()
                if not flinging then logLine("> not on", rgb(255, 200, 60)) return end
                flinging = false
                if noclipActive then COMMANDS["clip"]() end
                logLine("> walkfling off", rgb(255, 80, 80))
            end

            COMMANDS["nofog"] = function()
                local Lighting = game:GetService("Lighting")
                fogSnapshot = {
                    FogEnd        = Lighting.FogEnd,
                    FogStart      = Lighting.FogStart,
                    FogColor      = Lighting.FogColor,
                }
                local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
                if atmo then
                    fogSnapshot.atmo = {
                        Density = atmo.Density,
                        Haze    = atmo.Haze,
                        Glare   = atmo.Glare,
                    }
                    atmo.Density = 0
                    atmo.Haze    = 0
                    atmo.Glare   = 0
                end
                Lighting.FogEnd   = 1e6
                Lighting.FogStart = 0
                logLine("> fog removed", rgb(50, 210, 100))
            end

            COMMANDS["unfog"] = function()
                if not fogSnapshot then
                    logLine("> no fog snapshot. Run nofog first", rgb(255, 200, 60))
                    return
                end
                local Lighting = game:GetService("Lighting")
                Lighting.FogEnd   = fogSnapshot.FogEnd
                Lighting.FogStart = fogSnapshot.FogStart
                Lighting.FogColor = fogSnapshot.FogColor
                local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
                if atmo and fogSnapshot.atmo then
                    atmo.Density = fogSnapshot.atmo.Density
                    atmo.Haze    = fogSnapshot.atmo.Haze
                    atmo.Glare   = fogSnapshot.atmo.Glare
                end
                fogSnapshot = nil
                logLine("> fog restored", rgb(255, 80, 80))
            end

            -- view / unview: spectate a player by any prefix of name or displayname
            local viewOrigSubject  = nil
            local viewLeavingConn = nil   -- fires when the viewed player leaves

            local function doUnview(silent)
                if viewLeavingConn then
                    viewLeavingConn:Disconnect()
                    viewLeavingConn = nil
                end
                local cam = workspace.CurrentCamera
                pcall(function()
                    local myChar = LocalPlayer.Character
                    local myHum  = myChar and myChar:FindFirstChildOfClass("Humanoid")
                    cam.CameraSubject = myHum or viewOrigSubject
                end)
                viewOrigSubject = nil
                if not silent then
                    logLine("> unviewed", rgb(255, 80, 80))
                end
            end

            local function findPlayer(query)
                query = query:lower()
                local exact = nil
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr == LocalPlayer then
                        -- skip self
                    else
                        local uname = plr.Name:lower()
                        local dname = plr.DisplayName:lower()
                        if uname == query or dname == query then
                            return plr
                        end
                        if not exact then
                            if uname:sub(1, #query) == query or dname:sub(1, #query) == query then
                                exact = plr
                            end
                        end
                    end
                end
                return exact
            end

            COMMANDS["view"] = function(args)
                local query = (args or ""):match("^%s*(.-)%s*$")
                if query == "" then
                    logLine("> usage: view [name]", rgb(255, 200, 60))
                    return
                end
                local plr = findPlayer(query)
                if not plr then
                    logLine("> player not found: " .. query, rgb(255, 80, 80))
                    return
                end
                local char = plr.Character
                local hum  = char and char:FindFirstChildOfClass("Humanoid")
                if not (char and hum) then
                    logLine("> " .. plr.Name .. " has no character", rgb(255, 200, 60))
                    return
                end
                local cam = workspace.CurrentCamera
                if not viewOrigSubject then
                    viewOrigSubject = cam.CameraSubject
                end
                -- Disconnect any previous leaving watcher
                if viewLeavingConn then viewLeavingConn:Disconnect() end
                -- Auto-unview if the viewed player leaves the game
                viewLeavingConn = Players.PlayerRemoving:Connect(function(leaving)
                    if leaving == plr then
                        logLine("> " .. plr.Name .. " left, unviewed", rgb(255, 200, 60))
                        doUnview(true)
                    end
                end)
                cam.CameraSubject = hum
                logLine("> spectating " .. plr.DisplayName .. " (@" .. plr.Name .. ")", rgb(50, 210, 100))
            end

            COMMANDS["unview"] = function()
                if not viewOrigSubject then
                    logLine("> not spectating anyone", rgb(255, 200, 60))
                    return
                end
                doUnview(false)
            end

            COMMANDS["tp"] = function(args)
                local query = (args or ""):match("^%s*(.-)%s*$")
                if query == "" then
                    logLine("> usage: tp [name]", rgb(255, 200, 60))
                    return
                end
                local plr = findPlayer(query)
                if not plr then
                    logLine("> player not found: " .. query, rgb(255, 80, 80))
                    return
                end
                local myChar  = LocalPlayer.Character
                local myRoot  = myChar and myChar:FindFirstChild("HumanoidRootPart")
                local tgtChar = plr.Character
                local tgtRoot = tgtChar and tgtChar:FindFirstChild("HumanoidRootPart")
                if not (myRoot and tgtRoot) then
                    logLine("> cannot teleport: character not loaded", rgb(255, 200, 60))
                    return
                end
                myRoot.CFrame = tgtRoot.CFrame + Vector3.new(2, 0, 0)
                logLine("> teleported to " .. plr.DisplayName .. " (@" .. plr.Name .. ")", rgb(50, 210, 100))
            end
            --
            local espActive   = false
            local espObjects  = {}   -- [player] = { boxFrames, highlight, bbGui, conns, ... }
            local espSettings = {
                showName     = true,
                showHealth   = true,
                showDistance = true,
                showSpeed    = false,
                showState    = false,
                showBox      = true,
                showParts    = false,
            }

            -- ScreenGui for 2D screen-space box frames (one per player, updated each RenderStepped)
            local espBoxSg = Instance.new("ScreenGui")
            espBoxSg.Name            = "LuwaEspBox"
            espBoxSg.ResetOnSpawn    = false
            espBoxSg.IgnoreGuiInset  = true
            espBoxSg.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
            espBoxSg.DisplayOrder    = 5
            espBoxSg.Parent          = LocalPlayer.PlayerGui

            -- ScreenGui for BillboardGuis (parenting to PlayerGui ensures they render
            -- correctly in all executor environments when an Adornee is set)
            local espBbSg = Instance.new("ScreenGui")
            espBbSg.Name            = "LuwaEspBb"
            espBbSg.ResetOnSpawn    = false
            espBbSg.IgnoreGuiInset  = true
            espBbSg.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
            espBbSg.DisplayOrder    = 5
            espBbSg.Parent          = LocalPlayer.PlayerGui

            -- Physics-based state derivation: reliable across all games,
            -- avoids GetState() returning stale/incorrect transitional states.
            local function derivePlayerState(hum, hrp)
                if not (hum and hum.Parent and hrp and hrp.Parent) then return "?" end
                if hum.Health <= 0 then return "Dead" end
                if hum.Sit then return "Seated" end
                -- Swimming and Climbing are hard to detect from physics alone
                local rawState = hum:GetState()
                if rawState == Enum.HumanoidStateType.Swimming  then return "Swimming"  end
                if rawState == Enum.HumanoidStateType.Climbing  then return "Climbing"  end
                local onGround = hum.FloorMaterial ~= Enum.Material.Air
                if not onGround then
                    return hrp.AssemblyLinearVelocity.Y > 1 and "Jumping" or "Falling"
                end
                return hum.MoveDirection.Magnitude > 0.1 and "Running" or "Idle"
            end

            -- ESP settings panel (outside main frame, bottom-right, draggable by title)
            local espPanelSg    = nil
            local espPanelOpen  = false
            local espPanelFrame = nil

            local function buildEspSettingsPanel()
                if espPanelSg and espPanelSg.Parent then return end
                espPanelSg = Instance.new("ScreenGui")
                espPanelSg.Name            = "LuwaEspSettings"
                espPanelSg.ResetOnSpawn    = false
                espPanelSg.IgnoreGuiInset  = true
                espPanelSg.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
                espPanelSg.DisplayOrder    = 30
                espPanelSg.Parent          = LocalPlayer.PlayerGui

                local panel = Instance.new("Frame")
                panel.AnchorPoint           = Vector2.new(1, 1)
                panel.Position              = UDim2.new(1, -12, 1, -60)
                panel.Size                  = UDim2.new(0, 190, 0, 0)
                panel.AutomaticSize         = Enum.AutomaticSize.Y
                panel.BackgroundColor3      = T.frameBg
                panel.BackgroundTransparency = T.frameTrans
                panel.BorderSizePixel       = 0
                panel.Visible               = false
                panel.ClipsDescendants      = false
                panel.Active                = true
                panel.Parent                = espPanelSg
                Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 20)
                local panelStroke = Instance.new("UIStroke")
                panelStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                panelStroke.Color       = Color3.fromRGB(255, 255, 255)
                panelStroke.Thickness   = 0.5
                panelStroke.Transparency = 0.35
                panelStroke.Parent      = panel

                -- Top glint (matches main frame style)
                local espGlint = Instance.new("Frame")
                espGlint.Size                   = UDim2.new(1, -28, 0, 10)
                espGlint.Position               = UDim2.new(0, 14, 0, 5)
                espGlint.BackgroundColor3       = Color3.fromRGB(255, 255, 255)
                espGlint.BackgroundTransparency = 1
                espGlint.BorderSizePixel        = 0
                espGlint.ZIndex                 = 10
                espGlint.Parent                 = panel
                Instance.new("UICorner", espGlint).CornerRadius = UDim.new(0, 6)
                local espGlintGrad = Instance.new("UIGradient")
                espGlintGrad.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0,    1   ),
                    NumberSequenceKeypoint.new(0.15, 0.86),
                    NumberSequenceKeypoint.new(0.5,  0.80),
                    NumberSequenceKeypoint.new(0.85, 0.86),
                    NumberSequenceKeypoint.new(1,    1   ),
                })
                espGlintGrad.Parent = espGlint

                local panelLayout = Instance.new("UIListLayout")
                panelLayout.SortOrder = Enum.SortOrder.LayoutOrder
                panelLayout.Padding   = UDim.new(0, 0)
                panelLayout.Parent    = panel
                local panelPad = Instance.new("UIPadding")
                panelPad.PaddingTop    = UDim.new(0, 0)
                panelPad.PaddingBottom = UDim.new(0, 8)
                panelPad.PaddingLeft   = UDim.new(0, 10)
                panelPad.PaddingRight  = UDim.new(0, 10)
                panelPad.Parent        = panel
                espPanelFrame = panel

                -- -- Title / drag bar
                local titleBar = Instance.new("Frame")
                titleBar.Size                   = UDim2.new(1, -20, 0, 40)
                titleBar.BackgroundTransparency = 1
                titleBar.LayoutOrder            = 0
                titleBar.Parent                 = panel

                -- Accent line below title (matches main frame separator)
                local espAccentLine = Instance.new("Frame")
                espAccentLine.Size             = UDim2.new(1, 0, 0, 2)
                espAccentLine.Position         = UDim2.new(0, 0, 1, -2)
                espAccentLine.BackgroundColor3 = T.accent
                espAccentLine.BorderSizePixel  = 0
                espAccentLine.ZIndex           = 4
                espAccentLine.Parent           = titleBar
                Instance.new("UICorner", espAccentLine).CornerRadius = UDim.new(1, 0)

                local titleLbl = Instance.new("TextLabel")
                titleLbl.Size                = UDim2.new(1, -60, 1, 0)
                titleLbl.Position            = UDim2.new(0, 0, 0, 0)
                titleLbl.BackgroundTransparency = 1
                titleLbl.Text                = "ESP Settings"
                titleLbl.TextColor3          = Color3.fromRGB(255, 255, 255)
                titleLbl.TextSize            = 11
                titleLbl.Font                = Enum.Font.GothamBold
                titleLbl.TextXAlignment      = Enum.TextXAlignment.Left
                titleLbl.Parent              = titleBar

                -- Close button (X) - pill style matching main frame
                local closePanelBtn = Instance.new("TextButton")
                closePanelBtn.Size                  = UDim2.new(0, 22, 0, 22)
                closePanelBtn.Position              = UDim2.new(1, -22, 0.5, -11)
                closePanelBtn.BackgroundColor3      = Color3.fromRGB(0, 0, 0)
                closePanelBtn.BackgroundTransparency = 0.55
                closePanelBtn.BorderSizePixel       = 0
                closePanelBtn.Text                  = "X"
                closePanelBtn.TextColor3            = Color3.fromRGB(255, 255, 255)
                closePanelBtn.TextSize              = 10
                closePanelBtn.Font                  = Enum.Font.GothamBold
                closePanelBtn.AutoButtonColor       = false
                closePanelBtn.Parent                = titleBar
                Instance.new("UICorner", closePanelBtn).CornerRadius = UDim.new(1, 0)
                local espCloseStroke = Instance.new("UIStroke")
                espCloseStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                espCloseStroke.Color           = Color3.fromRGB(255, 255, 255)
                espCloseStroke.Thickness       = 0.9
                espCloseStroke.Transparency    = 0.55
                espCloseStroke.Parent          = closePanelBtn
                tapConnect(closePanelBtn, function()
                    espPanelOpen = false
                    TweenService:Create(panel, TI.fast, {BackgroundTransparency = 1}):Play()
                    task.delay(0.18, function()
                        if not espPanelOpen and panel and panel.Parent then
                            panel.Visible = false
                            panel.BackgroundTransparency = T.frameTrans
                        end
                    end)
                end)
                connectBtn(closePanelBtn,
                    function() TweenService:Create(closePanelBtn, TI.fast, {BackgroundTransparency = 0.3}):Play() end,
                    function() TweenService:Create(closePanelBtn, TI.fast, {BackgroundTransparency = 0.55}):Play() end
                )

                -- -- Drag logic: drag the panel by holding the title bar
                do
                    local dragInp   = nil
                    local dragStart = nil
                    local panStart  = nil

                    titleBar.InputBegan:Connect(function(inp)
                        if inp.UserInputType ~= Enum.UserInputType.MouseButton1
                        and inp.UserInputType ~= Enum.UserInputType.Touch then return end
                        dragInp   = inp
                        dragStart = inp.Position
                        panStart  = panel.Position
                    end)
                    UserInputService.InputChanged:Connect(function(inp)
                        if inp ~= dragInp then return end
                        local delta = inp.Position - dragStart
                        panel.Position = UDim2.new(
                            panStart.X.Scale, panStart.X.Offset + delta.X,
                            panStart.Y.Scale, panStart.Y.Offset + delta.Y
                        )
                    end)
                    UserInputService.InputEnded:Connect(function(inp)
                        if inp == dragInp then dragInp = nil end
                    end)
                end

                -- -- Divider
                local div = Instance.new("Frame")
                div.Size            = UDim2.new(1, 0, 0, 1)
                div.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
                div.BorderSizePixel = 0
                div.LayoutOrder     = 1
                div.Parent          = panel

                -- -- Setting rows
                local settingDefs = {
                    { key="showBox",      label="Box outline",    order=2 },
                    { key="showName",     label="Name",           order=3 },
                    { key="showHealth",   label="Health",         order=4 },
                    { key="showDistance", label="Distance",       order=5 },
                    { key="showSpeed",    label="Speed",          order=6 },
                    { key="showState",    label="State",          order=7 },
                    { key="showParts",    label="Body parts ESP", order=8 },
                }

                local function refreshEspAll()
                    for _, data in pairs(espObjects) do
                        -- 2D box visibility is controlled by the RenderStepped loop;
                        -- we just toggle the Visible flag here and the loop respects it.
                        if data.boxFrame then
                            data.boxFrame.Visible = espSettings.showBox
                        end
                        if data.partHighlights then
                            for _, ph in ipairs(data.partHighlights) do
                                ph.Enabled = espSettings.showParts
                            end
                        end
                        if data.nameLbl   then data.nameLbl.Visible   = espSettings.showName     end
                        if data.hpLbl     then data.hpLbl.Visible     = espSettings.showHealth   end
                        if data.distLbl   then data.distLbl.Visible   = espSettings.showDistance end
                        if data.speedLbl  then data.speedLbl.Visible  = espSettings.showSpeed    end
                        if data.stateLbl  then data.stateLbl.Visible  = espSettings.showState    end
                    end
                end

                for _, def in ipairs(settingDefs) do
                    local row = Instance.new("Frame")
                    row.Size                  = UDim2.new(1, 0, 0, 28)
                    row.BackgroundTransparency = 1
                    row.LayoutOrder           = def.order
                    row.Parent                = panel

                    local rowLbl = Instance.new("TextLabel")
                    rowLbl.Size                  = UDim2.new(1, -36, 1, 0)
                    rowLbl.BackgroundTransparency = 1
                    rowLbl.Text                  = def.label
                    rowLbl.TextColor3            = Color3.fromRGB(220, 220, 220)
                    rowLbl.TextSize              = 10
                    rowLbl.Font                  = Enum.Font.Gotham
                    rowLbl.TextXAlignment        = Enum.TextXAlignment.Left
                    rowLbl.Parent                = row

                    local pill = Instance.new("Frame")
                    pill.Size            = UDim2.new(0, 28, 0, 14)
                    pill.Position        = UDim2.new(1, -28, 0.5, -7)
                    pill.BackgroundColor3 = espSettings[def.key]
                        and Color3.fromRGB(40, 185, 90) or Color3.fromRGB(45, 45, 50)
                    pill.BorderSizePixel = 0
                    pill.Parent          = row
                    Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)

                    local dot = Instance.new("Frame")
                    dot.Size             = UDim2.new(0, 10, 0, 10)
                    dot.Position         = espSettings[def.key]
                        and UDim2.new(0, 16, 0.5, -5) or UDim2.new(0, 2, 0.5, -5)
                    dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    dot.BorderSizePixel  = 0
                    dot.Parent           = pill
                    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

                    local hitBtn = Instance.new("TextButton")
                    hitBtn.Size                  = UDim2.new(1, 0, 1, 0)
                    hitBtn.BackgroundTransparency = 1
                    hitBtn.Text                  = ""
                    hitBtn.Parent                = row

                    local k = def.key
                    tapConnect(hitBtn, function()
                        espSettings[k] = not espSettings[k]
                        local on = espSettings[k]
                        TweenService:Create(pill, TI.med,
                            {BackgroundColor3 = on and Color3.fromRGB(40,185,90) or Color3.fromRGB(45,45,50)}):Play()
                        TweenService:Create(dot, TI.pillBounce,
                            {Position = on and UDim2.new(0,16,0.5,-5) or UDim2.new(0,2,0.5,-5)}):Play()
                        refreshEspAll()
                    end)
                end
            end

            local function removeEspForPlayer(plr)
                local data = espObjects[plr]
                if not data then return end
                pcall(function()
                    if data.boxFrame      then data.boxFrame:Destroy()      end
                    if data.partHighlights then
                        for _, ph in ipairs(data.partHighlights) do ph:Destroy() end
                    end
                    if data.bbGui         then data.bbGui:Destroy()         end
                    for _, c in ipairs(data.conns or {}) do c:Disconnect() end
                end)
                espObjects[plr] = nil
            end

            local function addEspForPlayer(plr)
                if plr == LocalPlayer then return end
                if espObjects[plr] then return end
                local char = plr.Character
                if not char then return end
                local hrp = char:FindFirstChild("HumanoidRootPart")
                local hum = char:FindFirstChildOfClass("Humanoid")
                if not (hrp and hum) then return end

                local data = { conns = {} }
                espObjects[plr] = data

                -- -- 2D screen-space box (only direct BasePart children = body, no accessories)
                -- This draws a proper rectangle outline around the player on screen.
                -- A separate RenderStepped loop updates position/size each frame.
                local boxFrame = Instance.new("Frame")
                boxFrame.BackgroundTransparency = 1
                boxFrame.BorderSizePixel        = 0
                boxFrame.Visible                = espSettings.showBox
                boxFrame.Parent                 = espBoxSg
                local boxStroke = Instance.new("UIStroke")
                boxStroke.Color     = Color3.fromRGB(255, 55, 55)
                boxStroke.Thickness = 1.5
                boxStroke.Parent    = boxFrame
                data.boxFrame = boxFrame

                -- -- Per-body-part Highlight (outlines the player's mesh shape)
                -- Applied to each direct BasePart child so accessories/hats are excluded.
                local partHighlights = {}
                for _, part in ipairs(char:GetChildren()) do
                    if part:IsA("BasePart") then
                        local ph = Instance.new("Highlight")
                        ph.Adornee             = part
                        ph.FillTransparency    = 1     -- outline only
                        ph.OutlineTransparency = 0
                        ph.OutlineColor        = Color3.fromRGB(255, 160, 60)
                        ph.Enabled             = espSettings.showParts
                        ph.Parent              = workspace
                        partHighlights[#partHighlights+1] = ph
                    end
                end
                data.partHighlights = partHighlights

                -- -- BillboardGui (parented to PlayerGui ScreenGui for reliable rendering)
                local bb = Instance.new("BillboardGui")
                bb.Adornee      = hrp
                bb.Size         = UDim2.new(0, 130, 0, 72)
                bb.StudsOffset  = Vector3.new(0, 3.2, 0)
                bb.AlwaysOnTop  = true
                bb.MaxDistance  = 500
                bb.ResetOnSpawn = false
                bb.Parent       = espBbSg
                data.bbGui = bb

                local bbLayout = Instance.new("UIListLayout")
                bbLayout.FillDirection       = Enum.FillDirection.Vertical
                bbLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                bbLayout.SortOrder           = Enum.SortOrder.LayoutOrder
                bbLayout.Padding             = UDim.new(0, 1)
                bbLayout.Parent              = bb

                local function mkLbl(order, size, col)
                    local l = Instance.new("TextLabel")
                    l.Size                   = UDim2.new(1, 0, 0, size + 2)
                    l.BackgroundTransparency = 1
                    l.TextColor3             = col or Color3.fromRGB(255, 255, 255)
                    l.TextSize               = size
                    l.Font                   = Enum.Font.GothamBold
                    l.TextStrokeTransparency = 0.4
                    l.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
                    l.TextXAlignment         = Enum.TextXAlignment.Center
                    l.LayoutOrder            = order
                    l.Parent                 = bb
                    return l
                end

                local nameLbl  = mkLbl(1, 11, Color3.fromRGB(255, 255, 255))
                nameLbl.Text   = plr.DisplayName
                nameLbl.Visible = espSettings.showName
                data.nameLbl   = nameLbl

                local hpLbl    = mkLbl(2, 9, Color3.fromRGB(80, 220, 80))
                hpLbl.Text     = "? HP"
                hpLbl.Visible  = espSettings.showHealth
                data.hpLbl     = hpLbl

                local distLbl  = mkLbl(3, 9, Color3.fromRGB(180, 180, 255))
                distLbl.Text   = "? studs"
                distLbl.Visible = espSettings.showDistance
                data.distLbl   = distLbl

                local speedLbl = mkLbl(4, 9, Color3.fromRGB(255, 200, 80))
                speedLbl.Text  = "0 stud/s"
                speedLbl.Visible = espSettings.showSpeed
                data.speedLbl  = speedLbl

                local stateLbl = mkLbl(5, 9, Color3.fromRGB(200, 160, 255))
                stateLbl.Text  = "Idle"
                stateLbl.Visible = espSettings.showState
                data.stateLbl  = stateLbl

                -- Update text labels every heartbeat.
                -- State is derived from physics (not GetState) to avoid stale values.
                local upConn = RunService.Heartbeat:Connect(function()
                    pcall(function()
                        if not char.Parent then return end
                        if espSettings.showName then
                            nameLbl.Text = plr.DisplayName
                        end
                        if espSettings.showHealth then
                            local hp  = math.floor(hum.Health)
                            local mhp = math.floor(hum.MaxHealth)
                            local ratio = hum.Health / math.max(1, hum.MaxHealth)
                            hpLbl.TextColor3 = Color3.fromRGB(
                                math.floor(255*(1-ratio)), math.floor(220*ratio), 0)
                            hpLbl.Text = hp .. " / " .. mhp .. " HP"
                        end
                        if espSettings.showDistance then
                            local myC = LocalPlayer.Character
                            local myH = myC and myC:FindFirstChild("HumanoidRootPart")
                            distLbl.Text = (myH and math.floor((hrp.Position - myH.Position).Magnitude) or 0) .. " studs"
                        end
                        if espSettings.showSpeed then
                            speedLbl.Text = math.floor(hrp.AssemblyLinearVelocity.Magnitude) .. " stud/s"
                        end
                        if espSettings.showState then
                            stateLbl.Text = derivePlayerState(hum, hrp)
                        end
                    end)
                end)
                data.conns[#data.conns+1] = upConn

                -- Auto-cleanup when character is removed
                local acConn = char.AncestryChanged:Connect(function()
                    if not char.Parent then removeEspForPlayer(plr) end
                end)
                data.conns[#data.conns+1] = acConn
            end

            local espPlayerAddedConn    = nil
            local espPlayerRemovingConn = nil
            local espCharAddedConns     = {}
            local espBoxConn            = nil   -- RenderStepped loop for 2D box updates

            local function enableEsp()
                espActive = true
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer then
                        addEspForPlayer(plr)
                        if not espCharAddedConns[plr] then
                            espCharAddedConns[plr] = plr.CharacterAdded:Connect(function()
                                task.defer(function() addEspForPlayer(plr) end)
                            end)
                        end
                    end
                end
                espPlayerAddedConn = Players.PlayerAdded:Connect(function(plr)
                    task.defer(function() addEspForPlayer(plr) end)
                    espCharAddedConns[plr] = plr.CharacterAdded:Connect(function()
                        task.defer(function() addEspForPlayer(plr) end)
                    end)
                end)
                espPlayerRemovingConn = Players.PlayerRemoving:Connect(function(plr)
                    removeEspForPlayer(plr)
                    if espCharAddedConns[plr] then
                        espCharAddedConns[plr]:Disconnect()
                        espCharAddedConns[plr] = nil
                    end
                end)

                -- RenderStepped: project each player's body-part bounding box to screen
                -- and update their boxFrame position/size each frame.
                if not espBoxConn then
                    espBoxConn = RunService.RenderStepped:Connect(function()
                        local cam = workspace.CurrentCamera
                        for _, data in pairs(espObjects) do
                            if data.boxFrame then
                            pcall(function()
                                local char = data.bbGui and data.bbGui.Adornee
                                    and data.bbGui.Adornee.Parent
                                if not char then data.boxFrame.Visible = false; return end
                                if not espSettings.showBox then data.boxFrame.Visible = false; return end

                                local minX, minY = math.huge, math.huge
                                local maxX, maxY = -math.huge, -math.huge
                                local any = false

                                for _, part in ipairs(char:GetChildren()) do
                                    if part:IsA("BasePart") then
                                        local sz = part.Size
                                        local cf = part.CFrame
                                        local hx = sz.X * 0.5
                                        local hy = sz.Y * 0.5
                                        local hz = sz.Z * 0.5
                                        local corners = {
                                            cf * Vector3.new( hx, hy, hz), cf * Vector3.new( hx, hy,-hz),
                                            cf * Vector3.new( hx,-hy, hz), cf * Vector3.new( hx,-hy,-hz),
                                            cf * Vector3.new(-hx, hy, hz), cf * Vector3.new(-hx, hy,-hz),
                                            cf * Vector3.new(-hx,-hy, hz), cf * Vector3.new(-hx,-hy,-hz),
                                        }
                                        for _, wp in ipairs(corners) do
                                            local sp, inView = cam:WorldToViewportPoint(wp)
                                            if inView then
                                                any = true
                                                if sp.X < minX then minX = sp.X end
                                                if sp.X > maxX then maxX = sp.X end
                                                if sp.Y < minY then minY = sp.Y end
                                                if sp.Y > maxY then maxY = sp.Y end
                                            end
                                        end
                                    end
                                end

                                if any then
                                    data.boxFrame.Visible  = true
                                    data.boxFrame.Position = UDim2.new(0, minX - 2, 0, minY - 2)
                                    data.boxFrame.Size     = UDim2.new(0, maxX - minX + 4, 0, maxY - minY + 4)
                                else
                                    data.boxFrame.Visible = false
                                end
                            end)
                            end  -- if data.boxFrame
                        end
                    end)
                end
            end

            local function disableEsp()
                espActive = false
                if espBoxConn            then espBoxConn:Disconnect();            espBoxConn            = nil end
                if espPlayerAddedConn    then espPlayerAddedConn:Disconnect();    espPlayerAddedConn    = nil end
                if espPlayerRemovingConn then espPlayerRemovingConn:Disconnect(); espPlayerRemovingConn = nil end
                for _, conn in pairs(espCharAddedConns) do conn:Disconnect() end
                espCharAddedConns = {}
                for plr in pairs(espObjects) do removeEspForPlayer(plr) end
                espObjects = {}
            end

            COMMANDS["esp"] = function()
                if espActive then
                    logLine("> ESP already on", rgb(255, 200, 60))
                    return
                end
                buildEspSettingsPanel()
                enableEsp()
                logLine("> ESP on", rgb(50, 210, 100))
            end

            COMMANDS["unesp"] = function()
                if not espActive then
                    logLine("> ESP not on", rgb(255, 200, 60))
                    return
                end
                disableEsp()
                logLine("> ESP off", rgb(255, 80, 80))
            end

            COMMANDS["settingsesp"] = function()
                buildEspSettingsPanel()
                if not espPanelFrame then return end
                espPanelOpen = not espPanelOpen
                if espPanelOpen then
                    espPanelFrame.BackgroundTransparency = 1
                    espPanelFrame.Visible = true
                    TweenService:Create(espPanelFrame, TI.med, {BackgroundTransparency = T.frameTrans}):Play()
                    logLine("> ESP settings open", rgb(160, 160, 175))
                else
                    TweenService:Create(espPanelFrame, TI.fast, {BackgroundTransparency = 1}):Play()
                    task.delay(0.2, function()
                        if not espPanelOpen and espPanelFrame and espPanelFrame.Parent then
                            espPanelFrame.Visible = false
                            espPanelFrame.BackgroundTransparency = T.frameTrans
                        end
                    end)
                    logLine("> ESP settings closed", rgb(160, 160, 175))
                end
            end

            -- Servers browser window
            local serversSg       = nil
            local serversVisible  = false
            local serversFrameRef = nil

            local TI_SRV_IN  = TweenInfo.new(0.32, Enum.EasingStyle.Back,  Enum.EasingDirection.Out)
            local TI_SRV_OUT = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In)

            local function closeServersWin()
                if not (serversFrameRef and serversFrameRef.Parent) then return end
                serversVisible = false
                local sc = serversFrameRef:FindFirstChildOfClass("UIScale")
                if sc then TweenService:Create(sc, TI_SRV_OUT, {Scale = 0.9}):Play() end
                TweenService:Create(serversFrameRef, TI_SRV_OUT, {BackgroundTransparency = 1}):Play()
                task.delay(0.2, function()
                    if serversSg then serversSg.Enabled = false end
                    if serversFrameRef then serversFrameRef.BackgroundTransparency = T.frameTrans end
                    local sc2 = serversFrameRef and serversFrameRef:FindFirstChildOfClass("UIScale")
                    if sc2 then sc2.Scale = 0.88 end
                end)
            end

            local function openServersWin()
                if not (serversFrameRef and serversFrameRef.Parent) then return end
                serversVisible = true
                serversSg.Enabled = true
                local sc = serversFrameRef:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", serversFrameRef)
                sc.Scale = 0.88
                serversFrameRef.BackgroundTransparency = 1
                TweenService:Create(serversFrameRef, TI_SRV_IN, {BackgroundTransparency = T.frameTrans}):Play()
                TweenService:Create(sc, TI_SRV_IN, {Scale = 1}):Play()
            end

            local function buildServersWin()
                if serversSg and serversSg.Parent then
                    if serversVisible then closeServersWin() else openServersWin() end
                    return
                end

                serversSg = Instance.new("ScreenGui")
                serversSg.Name           = "LuwaServers"
                serversSg.ResetOnSpawn   = false
                serversSg.IgnoreGuiInset = true
                serversSg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
                serversSg.DisplayOrder   = 23
                serversSg.Parent         = LocalPlayer.PlayerGui

                local SW_W, SW_H = 290, 360
                local srvFrame = Instance.new("Frame")
                srvFrame.Size = UDim2.new(0, SW_W, 0, SW_H)
                srvFrame.Position = UDim2.new(0.5, -SW_W/2, 0.5, -SW_H/2)
                srvFrame.BackgroundColor3 = T.frameBg
                srvFrame.BackgroundTransparency = 1
                srvFrame.BorderSizePixel = 0
                srvFrame.Active = true
                srvFrame.ZIndex = 2
                srvFrame.Parent = serversSg
                Instance.new("UICorner", srvFrame).CornerRadius = UDim.new(0, 20)
                serversFrameRef = srvFrame
                local srvStroke = Instance.new("UIStroke")
                srvStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                srvStroke.Color = Color3.fromRGB(255, 255, 255)
                srvStroke.Thickness = 0.5
                srvStroke.Transparency = 0.35
                srvStroke.Parent = srvFrame

                -- Glint
                local sg = Instance.new("Frame")
                sg.Size = UDim2.new(1, -28, 0, 10)
                sg.Position = UDim2.new(0, 14, 0, 5)
                sg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                sg.BackgroundTransparency = 1
                sg.BorderSizePixel = 0
                sg.ZIndex = 10
                sg.Parent = srvFrame
                Instance.new("UICorner", sg).CornerRadius = UDim.new(0, 6)
                local sgg = Instance.new("UIGradient")
                sgg.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.15, 0.86),
                    NumberSequenceKeypoint.new(0.5, 0.80), NumberSequenceKeypoint.new(0.85, 0.86),
                    NumberSequenceKeypoint.new(1, 1),
                })
                sgg.Parent = sg

                -- Header
                local srvHeader = Instance.new("Frame")
                srvHeader.Size = UDim2.new(1, 0, 0, 46)
                srvHeader.BackgroundTransparency = 1
                srvHeader.ZIndex = 3
                srvHeader.Active = true
                srvHeader.Parent = srvFrame

                local srvAccent = Instance.new("Frame")
                srvAccent.Size = UDim2.new(1, -20, 0, 2)
                srvAccent.Position = UDim2.new(0, 10, 0, 44)
                srvAccent.BackgroundColor3 = T.accent
                srvAccent.BorderSizePixel = 0
                srvAccent.ZIndex = 4
                srvAccent.Parent = srvFrame
                Instance.new("UICorner", srvAccent).CornerRadius = UDim.new(1, 0)

                local srvTitle = Instance.new("TextLabel")
                srvTitle.Size = UDim2.new(0.5, 0, 0, 18)
                srvTitle.Position = UDim2.new(0, 14, 0, 8)
                srvTitle.BackgroundTransparency = 1
                srvTitle.Text = "Servers"
                srvTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
                srvTitle.TextSize = 14
                srvTitle.Font = Enum.Font.GothamBold
                srvTitle.TextXAlignment = Enum.TextXAlignment.Left
                srvTitle.ZIndex = 4
                srvTitle.Parent = srvHeader

                -- Total servers label
                local srvTotalLbl = Instance.new("TextLabel")
                srvTotalLbl.Size = UDim2.new(1, -14, 0, 13)
                srvTotalLbl.Position = UDim2.new(0, 14, 0, 27)
                srvTotalLbl.BackgroundTransparency = 1
                srvTotalLbl.Text = "Loading..."
                srvTotalLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
                srvTotalLbl.TextSize = 9
                srvTotalLbl.Font = Enum.Font.Gotham
                srvTotalLbl.TextXAlignment = Enum.TextXAlignment.Left
                srvTotalLbl.ZIndex = 4
                srvTotalLbl.Parent = srvHeader

                -- Sort button (top-right area)
                local sortBtn = Instance.new("TextButton")
                sortBtn.Size = UDim2.new(0, 72, 0, 22)
                sortBtn.Position = UDim2.new(1, -112, 0, 12)
                sortBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
                sortBtn.BackgroundTransparency = 0
                sortBtn.BorderSizePixel = 0
                sortBtn.Text = srvSortAsc and "Low -> High" or "High -> Low"
                sortBtn.TextColor3 = Color3.fromRGB(200, 200, 215)
                sortBtn.TextSize = 8
                sortBtn.Font = Enum.Font.GothamSemibold
                sortBtn.AutoButtonColor = false
                sortBtn.ZIndex = 4
                sortBtn.Parent = srvHeader
                Instance.new("UICorner", sortBtn).CornerRadius = UDim.new(0, 6)
                local sortStroke = Instance.new("UIStroke")
                sortStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                sortStroke.Color = Color3.fromRGB(60, 60, 75)
                sortStroke.Thickness = 1
                sortStroke.Transparency = 0.3
                sortStroke.Parent = sortBtn

                -- Close button
                local srvClose = Instance.new("TextButton")
                srvClose.Size = UDim2.new(0, 24, 0, 24)
                srvClose.Position = UDim2.new(1, -32, 0, 11)
                srvClose.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                srvClose.BackgroundTransparency = 0.55
                srvClose.BorderSizePixel = 0
                srvClose.Text = "X"
                srvClose.TextColor3 = Color3.fromRGB(255, 255, 255)
                srvClose.TextSize = 10
                srvClose.Font = Enum.Font.GothamBold
                srvClose.AutoButtonColor = false
                srvClose.ZIndex = 4
                srvClose.Parent = srvHeader
                Instance.new("UICorner", srvClose).CornerRadius = UDim.new(1, 0)
                local srvCloseStroke = Instance.new("UIStroke")
                srvCloseStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                srvCloseStroke.Color = Color3.fromRGB(255, 255, 255)
                srvCloseStroke.Thickness = 0.9
                srvCloseStroke.Transparency = 0.55
                srvCloseStroke.Parent = srvClose
                tapConnect(srvClose, closeServersWin)
                connectBtn(srvClose,
                    function() TweenService:Create(srvClose, TI.fast, {BackgroundTransparency = 0.3}):Play() end,
                    function() TweenService:Create(srvClose, TI.fast, {BackgroundTransparency = 0.55}):Play() end
                )

                -- Drag by header
                do
                    local _dInp, _dStart, _dFrm = nil, nil, nil
                    srvHeader.InputBegan:Connect(function(inp)
                        if inp.UserInputType ~= Enum.UserInputType.MouseButton1
                        and inp.UserInputType ~= Enum.UserInputType.Touch then return end
                        _dInp = inp; _dStart = inp.Position; _dFrm = srvFrame.Position
                    end)
                    UserInputService.InputChanged:Connect(function(inp)
                        if inp ~= _dInp then return end
                        local d = inp.Position - _dStart
                        srvFrame.Position = UDim2.new(_dFrm.X.Scale, _dFrm.X.Offset + d.X,
                                                      _dFrm.Y.Scale, _dFrm.Y.Offset + d.Y)
                    end)
                    UserInputService.InputEnded:Connect(function(inp)
                        if inp == _dInp then _dInp = nil end
                    end)
                end

                -- Scroll list
                local srvSf = Instance.new("ScrollingFrame")
                srvSf.Size = UDim2.new(1, -12, 1, -104)
                srvSf.Position = UDim2.new(0, 6, 0, 52)
                srvSf.BackgroundTransparency = 1
                srvSf.BorderSizePixel = 0
                srvSf.ScrollBarThickness = 3
                srvSf.ScrollBarImageColor3 = T.scrollBar
                srvSf.AutomaticCanvasSize = Enum.AutomaticSize.Y
                srvSf.CanvasSize = UDim2.new(0, 0, 0, 0)
                srvSf.ZIndex = 3
                srvSf.Parent = srvFrame
                local srvLayout = Instance.new("UIListLayout")
                srvLayout.SortOrder = Enum.SortOrder.LayoutOrder
                srvLayout.Padding = UDim.new(0, 4)
                srvLayout.Parent = srvSf
                local srvPad = Instance.new("UIPadding")
                srvPad.PaddingTop    = UDim.new(0, 4)
                srvPad.PaddingBottom = UDim.new(0, 4)
                srvPad.PaddingLeft   = UDim.new(0, 2)
                srvPad.PaddingRight  = UDim.new(0, 2)
                srvPad.Parent = srvSf

                -- Load More / All Loaded button
                local srvMoreBtn = Instance.new("TextButton")
                srvMoreBtn.Size = UDim2.new(1, -20, 0, 30)
                srvMoreBtn.Position = UDim2.new(0, 10, 1, -36)
                srvMoreBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
                srvMoreBtn.BackgroundTransparency = 0
                srvMoreBtn.BorderSizePixel = 0
                srvMoreBtn.Text = "Load More"
                srvMoreBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
                srvMoreBtn.TextSize = 11
                srvMoreBtn.Font = Enum.Font.GothamSemibold
                srvMoreBtn.AutoButtonColor = false
                srvMoreBtn.ZIndex = 3
                srvMoreBtn.Visible = false
                srvMoreBtn.Parent = srvFrame
                Instance.new("UICorner", srvMoreBtn).CornerRadius = UDim.new(0, 8)
                connectBtn(srvMoreBtn,
                    function() TweenService:Create(srvMoreBtn, TI.fast, {BackgroundColor3 = Color3.fromRGB(40, 40, 48)}):Play() end,
                    function() TweenService:Create(srvMoreBtn, TI.fast, {BackgroundColor3 = Color3.fromRGB(25, 25, 30)}):Play() end
                )

                -- State
                local serversList    = {}  -- {jobId, playing, max, card, countLbl, isCurrent}
                local serversCursor  = nil
                local allLoaded      = false
                local serversLoading = false
                local updateConn     = nil
                local myJobId        = tostring(game.JobId)
                local liveData       = {}  -- jobId -> playing count

                -- Player panel overlay (shown when a card is tapped)
                local playerPanel = Instance.new("Frame")
                playerPanel.Size = UDim2.new(1, -20, 1, -60)
                playerPanel.Position = UDim2.new(0, 10, 0, 52)
                playerPanel.BackgroundColor3 = T.frameBg
                playerPanel.BackgroundTransparency = 0
                playerPanel.BorderSizePixel = 0
                playerPanel.ZIndex = 10
                playerPanel.Visible = false
                playerPanel.Parent = srvFrame
                Instance.new("UICorner", playerPanel).CornerRadius = UDim.new(0, 12)
                local ppStroke = Instance.new("UIStroke")
                ppStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                ppStroke.Color = Color3.fromRGB(255, 255, 255)
                ppStroke.Thickness = 0.5
                ppStroke.Transparency = 0.4
                ppStroke.Parent = playerPanel

                local ppHeader = Instance.new("Frame")
                ppHeader.Size = UDim2.new(1, 0, 0, 34)
                ppHeader.BackgroundTransparency = 1
                ppHeader.ZIndex = 11
                ppHeader.Parent = playerPanel

                local ppTitle = Instance.new("TextLabel")
                ppTitle.Size = UDim2.new(1, -40, 1, 0)
                ppTitle.Position = UDim2.new(0, 10, 0, 0)
                ppTitle.BackgroundTransparency = 1
                ppTitle.Text = "Players in Server"
                ppTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
                ppTitle.TextSize = 13
                ppTitle.Font = Enum.Font.GothamBold
                ppTitle.TextXAlignment = Enum.TextXAlignment.Left
                ppTitle.ZIndex = 11
                ppTitle.Parent = ppHeader

                local ppBack = Instance.new("TextButton")
                ppBack.Size = UDim2.new(0, 28, 0, 28)
                ppBack.Position = UDim2.new(1, -32, 0, 3)
                ppBack.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                ppBack.BackgroundTransparency = 0.55
                ppBack.BorderSizePixel = 0
                ppBack.Text = "X"
                ppBack.TextColor3 = Color3.fromRGB(255, 255, 255)
                ppBack.TextSize = 10
                ppBack.Font = Enum.Font.GothamBold
                ppBack.AutoButtonColor = false
                ppBack.ZIndex = 11
                ppBack.Parent = ppHeader
                Instance.new("UICorner", ppBack).CornerRadius = UDim.new(1, 0)
                tapConnect(ppBack, function() playerPanel.Visible = false end)

                local ppScroll = Instance.new("ScrollingFrame")
                ppScroll.Size = UDim2.new(1, -8, 1, -38)
                ppScroll.Position = UDim2.new(0, 4, 0, 36)
                ppScroll.BackgroundTransparency = 1
                ppScroll.BorderSizePixel = 0
                ppScroll.ScrollBarThickness = 3
                ppScroll.ScrollBarImageColor3 = T.scrollBar
                ppScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
                ppScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
                ppScroll.ZIndex = 11
                ppScroll.Parent = playerPanel
                local ppLayout = Instance.new("UIListLayout")
                ppLayout.SortOrder = Enum.SortOrder.LayoutOrder
                ppLayout.Padding = UDim.new(0, 3)
                ppLayout.Parent = ppScroll
                local ppPad = Instance.new("UIPadding")
                ppPad.PaddingTop    = UDim.new(0, 4)
                ppPad.PaddingBottom = UDim.new(0, 4)
                ppPad.PaddingLeft   = UDim.new(0, 2)
                ppPad.PaddingRight  = UDim.new(0, 2)
                ppPad.Parent = ppScroll

                local function showPlayerPanel(jobId)
                    for _, c in ipairs(ppScroll:GetChildren()) do
                        if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end
                    end
                    ppTitle.Text = "Loading players..."
                    playerPanel.Visible = true
                    task.spawn(function()
                        local ok, err = pcall(function()
                            local HttpService = game:GetService("HttpService")
                            -- The servers endpoint returns playerTokens (opaque tokens, not userIds)
                            -- and also a thumbnails array directly in newer API versions
                            local url = "https://games.roblox.com/v1/games/" .. tostring(game.PlaceId)
                                     .. "/servers/Public?limit=100"
                            -- Find the specific server entry to get its playerTokens
                            local playerTokens = {}
                            local maxCap = 0
                            -- Search across pages to find the target server
                            local searchCursor = nil
                            local found = false
                            for _ = 1, 20 do
                                local surl = "https://games.roblox.com/v1/games/" .. tostring(game.PlaceId)
                                          .. "/servers/Public?limit=100"
                                          .. (searchCursor and ("&cursor=" .. searchCursor) or "")
                                local sraw = game:HttpGet(surl)
                                local sdata = HttpService:JSONDecode(sraw)
                                for _, srv in ipairs(sdata.data or {}) do
                                    if srv.id == jobId then
                                        playerTokens = srv.playerTokens or {}
                                        maxCap = srv.maxPlayers or srv.capacity or 0
                                        found = true
                                        break
                                    end
                                end
                                if found then break end
                                searchCursor = sdata.nextPageCursor
                                if not searchCursor or searchCursor == "" then break end
                            end

                            if not found or #playerTokens == 0 then
                                ppTitle.Text = "No player data available"
                                return
                            end

                            ppTitle.Text = "Players (" .. #playerTokens .. " / " .. maxCap .. ")"

                            -- Batch resolve thumbnails
                            local tokenArr = {}
                            for _, tok in ipairs(playerTokens) do
                                tokenArr[#tokenArr+1] = {
                                    requestId = tok,
                                    token     = tok,
                                    type      = "AvatarHeadShot",
                                    size      = "48x48",
                                    format    = "png",
                                }
                            end
                            local thumbMap = {}
                            pcall(function()
                                local thumbRaw = HttpService:PostAsync(
                                    "https://thumbnails.roblox.com/v1/batch",
                                    HttpService:JSONEncode(tokenArr),
                                    Enum.HttpContentType.ApplicationJson, false)
                                local td = HttpService:JSONDecode(thumbRaw)
                                for _, entry in ipairs(td.data or {}) do
                                    if entry.requestId then
                                        thumbMap[entry.requestId] = entry.imageUrl or ""
                                    end
                                end
                            end)

                            local order = 0
                            for i, tok in ipairs(playerTokens) do
                                order = order + 1
                                local imgUrl = thumbMap[tok] or ""

                                local row = Instance.new("Frame")
                                row.Size = UDim2.new(1, 0, 0, 36)
                                row.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
                                row.BackgroundTransparency = 0
                                row.BorderSizePixel = 0
                                row.LayoutOrder = order
                                row.ZIndex = 12
                                row.Parent = ppScroll
                                Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

                                local av = Instance.new("ImageLabel")
                                av.Size = UDim2.new(0, 28, 0, 28)
                                av.Position = UDim2.new(0, 4, 0.5, -14)
                                av.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
                                av.BackgroundTransparency = 0
                                av.BorderSizePixel = 0
                                av.Image = imgUrl
                                av.ZIndex = 13
                                av.Parent = row
                                Instance.new("UICorner", av).CornerRadius = UDim.new(1, 0)

                                local nameLbl = Instance.new("TextLabel")
                                nameLbl.Size = UDim2.new(1, -42, 1, 0)
                                nameLbl.Position = UDim2.new(0, 38, 0, 0)
                                nameLbl.BackgroundTransparency = 1
                                nameLbl.Text = "Player " .. tostring(i)
                                nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
                                nameLbl.TextSize = 11
                                nameLbl.Font = Enum.Font.GothamSemibold
                                nameLbl.TextXAlignment = Enum.TextXAlignment.Left
                                nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
                                nameLbl.ZIndex = 13
                                nameLbl.Parent = row
                            end
                        end)
                        if not ok then
                            ppTitle.Text = "Failed to load players"
                        end
                    end)
                end

                local function updateVisibleCards()
                    if not (srvFrame and srvFrame.Parent) then
                        if updateConn then updateConn:Disconnect(); updateConn = nil end
                        return
                    end
                    for _, entry in ipairs(serversList) do
                        if entry.card and entry.card.Parent and entry.card.Visible then
                            local liveCount = liveData[entry.jobId]
                            if liveCount ~= nil then
                                entry.playing = liveCount
                                if entry.countLbl then
                                    entry.countLbl.Text = liveCount .. " / " .. entry.max .. " players"
                                    entry.countLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
                                end
                            end
                        end
                    end
                end

                local function refreshLiveCounts()
                    if #serversList == 0 then return end
                    task.spawn(function()
                        pcall(function()
                            local HttpService = game:GetService("HttpService")
                            -- Re-fetch ALL pages that cover our loaded servers to get accurate counts.
                            -- Use a larger limit to minimise requests.
                            local sortParam = srvSortAsc and "Asc" or "Desc"
                            local cursor = nil
                            local maxPages = math.ceil(#serversList / 100) + 1
                            local fetched = 0
                            repeat
                                local url = "https://games.roblox.com/v1/games/" .. tostring(game.PlaceId)
                                         .. "/servers/Public?sortOrder=" .. sortParam .. "&limit=100"
                                         .. (cursor and ("&cursor=" .. cursor) or "")
                                local ok2, raw = pcall(function() return game:HttpGet(url) end)
                                if not ok2 then break end
                                local ok3, data = pcall(function() return HttpService:JSONDecode(raw) end)
                                if not ok3 then break end
                                for _, srv in ipairs(data.data or {}) do
                                    if srv.id then
                                        liveData[srv.id] = srv.playing or 0
                                    end
                                end
                                cursor = data.nextPageCursor
                                fetched = fetched + 1
                            until (not cursor or cursor == "" or fetched >= maxPages)
                            updateVisibleCards()
                        end)
                    end)
                end

                local function startUpdateLoop()
                    if updateConn then updateConn:Disconnect(); updateConn = nil end
                    local t = 0
                    updateConn = RunService.Heartbeat:Connect(function(dt)
                        if not serversVisible then return end
                        t = t + dt
                        if t >= 0.5 then
                            t = 0
                            refreshLiveCounts()
                        end
                    end)
                end

                -- Build a server row card
                local function addServerRow(jobId, playing, maxPlayers, order, isCurrent)
                    local cardH = isCurrent and 48 or 44
                    local card = Instance.new("TextButton")
                    card.Size = UDim2.new(1, 0, 0, cardH)
                    card.BackgroundColor3 = isCurrent and Color3.fromRGB(20, 35, 20) or Color3.fromRGB(16, 16, 20)
                    card.BackgroundTransparency = 0
                    card.BorderSizePixel = 0
                    card.Text = ""
                    card.AutoButtonColor = false
                    card.LayoutOrder = order
                    card.ZIndex = 4
                    card.Parent = srvSf
                    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
                    if isCurrent then
                        local cs = Instance.new("UIStroke")
                        cs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                        cs.Color = Color3.fromRGB(50, 200, 100)
                        cs.Thickness = 1
                        cs.Transparency = 0.4
                        cs.Parent = card
                    end
                    connectBtn(card,
                        function() TweenService:Create(card, TI.fast, {BackgroundColor3 = isCurrent and Color3.fromRGB(28,44,28) or Color3.fromRGB(28,28,34)}):Play() end,
                        function() TweenService:Create(card, TI.fast, {BackgroundColor3 = isCurrent and Color3.fromRGB(20,35,20) or Color3.fromRGB(16,16,20)}):Play() end
                    )

                    local yOff = 0
                    if isCurrent then
                        local curLbl = Instance.new("TextLabel")
                        curLbl.Size = UDim2.new(0.5, 0, 0, 11)
                        curLbl.Position = UDim2.new(0, 8, 0, 4)
                        curLbl.BackgroundTransparency = 1
                        curLbl.Text = "You are here"
                        curLbl.TextColor3 = Color3.fromRGB(50, 200, 100)
                        curLbl.TextSize = 8
                        curLbl.Font = Enum.Font.GothamBold
                        curLbl.TextXAlignment = Enum.TextXAlignment.Left
                        curLbl.ZIndex = 5
                        curLbl.Parent = card
                        yOff = 12
                    end

                    -- Player count label (white)
                    local countLbl = Instance.new("TextLabel")
                    countLbl.Size = UDim2.new(0.55, 0, 0, 16)
                    countLbl.Position = UDim2.new(0, 8, 0, yOff + 6)
                    countLbl.BackgroundTransparency = 1
                    countLbl.Text = playing .. " / " .. maxPlayers .. " players"
                    countLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
                    countLbl.TextSize = 12
                    countLbl.Font = Enum.Font.GothamSemibold
                    countLbl.TextXAlignment = Enum.TextXAlignment.Left
                    countLbl.ZIndex = 5
                    countLbl.Parent = card

                    -- Job ID copy button (white)
                    local idBtn = Instance.new("TextButton")
                    idBtn.Size = UDim2.new(1, -16, 0, 13)
                    idBtn.Position = UDim2.new(0, 8, 0, yOff + 24)
                    idBtn.BackgroundTransparency = 1
                    idBtn.BorderSizePixel = 0
                    idBtn.Text = jobId:sub(1, 24) .. (jobId:len() > 24 and ".." or "") .. "  [copy]"
                    idBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                    idBtn.TextSize = 8
                    idBtn.Font = Enum.Font.Code
                    idBtn.TextXAlignment = Enum.TextXAlignment.Left
                    idBtn.AutoButtonColor = false
                    idBtn.ZIndex = 6
                    idBtn.Parent = card
                    tapConnect(idBtn, function()
                        pcall(function() setclipboard(jobId) end)
                        idBtn.TextColor3 = Color3.fromRGB(50, 220, 110)
                        idBtn.Text = "Copied!"
                        task.delay(1.2, function()
                            if idBtn and idBtn.Parent then
                                idBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                                idBtn.Text = jobId:sub(1, 24) .. (jobId:len() > 24 and ".." or "") .. "  [copy]"
                            end
                        end)
                    end)

                    -- Join button (hidden for current server)
                    if not isCurrent then
                        local joinBtn = Instance.new("TextButton")
                        joinBtn.Size = UDim2.new(0, 46, 0, 20)
                        joinBtn.Position = UDim2.new(1, -54, 0, yOff + 12)
                        joinBtn.BackgroundColor3 = Color3.fromRGB(40, 170, 80)
                        joinBtn.BackgroundTransparency = 0
                        joinBtn.BorderSizePixel = 0
                        joinBtn.Text = "Join"
                        joinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                        joinBtn.TextSize = 10
                        joinBtn.Font = Enum.Font.GothamBold
                        joinBtn.AutoButtonColor = false
                        joinBtn.ZIndex = 6
                        joinBtn.Parent = card
                        Instance.new("UICorner", joinBtn).CornerRadius = UDim.new(0, 6)
                        tapConnect(joinBtn, function()
                            pcall(function()
                                local TS = game:GetService("TeleportService")
                                TS:TeleportToPlaceInstance(game.PlaceId, jobId, LocalPlayer)
                            end)
                            logLine("> joining server " .. jobId:sub(1, 12) .. "...", rgb(50, 210, 100))
                        end)
                        connectBtn(joinBtn,
                            function() TweenService:Create(joinBtn, TI.fast, {BackgroundColor3 = Color3.fromRGB(55, 210, 100)}):Play() end,
                            function() TweenService:Create(joinBtn, TI.fast, {BackgroundColor3 = Color3.fromRGB(40, 170, 80)}):Play() end
                        )
                    end

                    -- Tap card to show players (only on the card background, not copy/join)
                    tapConnect(card, function()
                        showPlayerPanel(jobId)
                    end)

                    serversList[#serversList + 1] = {
                        jobId    = jobId,
                        playing  = playing,
                        max      = maxPlayers,
                        card     = card,
                        countLbl = countLbl,
                        isCurrent = isCurrent,
                    }
                    liveData[jobId] = playing
                end

                -- Fetch next page of servers
                local function fetchServers(cursor)
                    if serversLoading then return end
                    serversLoading = true
                    srvTotalLbl.Text = "Fetching..."
                    srvMoreBtn.Visible = false
                    task.spawn(function()
                        pcall(function()
                            local HttpService = game:GetService("HttpService")
                            local sortParam = srvSortAsc and "Asc" or "Desc"
                            local url = "https://games.roblox.com/v1/games/" .. tostring(game.PlaceId)
                                     .. "/servers/Public?sortOrder=" .. sortParam .. "&limit=100"
                                     .. (cursor and ("&cursor=" .. tostring(cursor)) or "")
                            local raw = game:HttpGet(url)
                            local data = HttpService:JSONDecode(raw)
                            local servers = data.data or {}
                            serversCursor = data.nextPageCursor
                            allLoaded = not (serversCursor and serversCursor ~= "")

                            -- Total players from game stats
                            local total = nil
                            pcall(function()
                                local statsRaw = game:HttpGet(
                                    "https://games.roblox.com/v1/games?universeIds=" .. tostring(game.GameId or 0))
                                local statsData = HttpService:JSONDecode(statsRaw)
                                if statsData.data and statsData.data[1] then
                                    total = statsData.data[1].playing
                                end
                            end)

                            local order = #serversList
                            for _, srv in ipairs(servers) do
                                order = order + 1
                                local jobId = srv.id or "unknown"
                                addServerRow(jobId, srv.playing or 0, srv.maxPlayers or srv.capacity or 0, order, jobId == myJobId)
                            end

                            local totalStr = total and ("Total: " .. tostring(total) .. " players  |  ") or ""
                            if #serversList == 0 then
                                srvTotalLbl.Text = totalStr .. "No servers found"
                            else
                                srvTotalLbl.Text = totalStr .. tostring(#serversList) .. " servers loaded" .. (allLoaded and "" or "  (more available)")
                            end
                            srvTotalLbl.TextColor3 = Color3.fromRGB(255, 255, 255)

                            if allLoaded then
                                srvMoreBtn.Text = "All servers loaded"
                                srvMoreBtn.TextColor3 = Color3.fromRGB(140, 140, 155)
                            else
                                srvMoreBtn.Text = "Load More  (more available)"
                                srvMoreBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                            end
                            srvMoreBtn.Visible = true
                        end)
                        serversLoading = false
                    end)
                end

                -- Sort button
                tapConnect(sortBtn, function()
                    srvSortAsc = not srvSortAsc
                    sortBtn.Text = srvSortAsc and "Low -> High" or "High -> Low"
                    patchInfo({ srv_sort = srvSortAsc and "asc" or "desc" })
                    -- Force reset state so fetch is never blocked by a stale lock
                    serversLoading = false
                    serversList = {}
                    liveData = {}
                    serversCursor = nil
                    allLoaded = false
                    for _, c in ipairs(srvSf:GetChildren()) do
                        if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end
                    end
                    fetchServers(nil)
                end)
                connectBtn(sortBtn,
                    function() TweenService:Create(sortBtn, TI.fast, {BackgroundColor3 = Color3.fromRGB(40, 40, 50)}):Play() end,
                    function() TweenService:Create(sortBtn, TI.fast, {BackgroundColor3 = Color3.fromRGB(25, 25, 32)}):Play() end
                )

                -- Load More
                tapConnect(srvMoreBtn, function()
                    if allLoaded or serversLoading then return end
                    if serversCursor then fetchServers(serversCursor) end
                end)

                fetchServers(nil)
                startUpdateLoop()

                local _origClose = closeServersWin
                closeServersWin = function()
                    if updateConn then updateConn:Disconnect(); updateConn = nil end
                    _origClose()
                end

                openServersWin()
            end

            COMMANDS["servers"] = function()
                buildServersWin()
            end

            local SUGGEST_W      = 160
            local SUGGEST_ROW_H  = 36
            local SUGGEST_MAX_H  = SUGGEST_ROW_H * 3 + 8
            local suggestBtns    = {}
            local suggestTips    = {}

            local sf = Instance.new("Frame")
            suggestFrame = sf
            sf.Size = UDim2.new(0, SUGGEST_W, 0, 0)
            suggestFrame.BackgroundColor3 = T.inputBg
            suggestFrame.BackgroundTransparency = 0.3
            suggestFrame.BorderSizePixel = 0
            suggestFrame.ClipsDescendants = true
            suggestFrame.Visible = false
            suggestFrame.Active = false
            suggestFrame.ZIndex = 20
            suggestFrame.Parent = activeScreenGui
            Instance.new("UICorner", suggestFrame).CornerRadius = UDim.new(0, 7)
            local suggestStroke = Instance.new("UIStroke")
            suggestStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            suggestStroke.Color = T.strokeIdle
            suggestStroke.Thickness = 1
            suggestStroke.Parent = suggestFrame

            local sgSpringX, sgSpringY = 0, 0
            local sgVelX,   sgVelY   = 0, 0
            local SG_SPRING_S = 280
            local SG_SPRING_D = 22

            local function getSgTarget()
                if not activeFrame or not activeFrame.Parent then return nil, nil end
                local ap = activeFrame.AbsolutePosition
                local as = activeFrame.AbsoluteSize
                return ap.X + as.X + 6, ap.Y + 8
            end

            local function _syncPos()
                local tx, ty = getSgTarget()
                if not tx then return end
                suggestFrame.Position = UDim2.new(0, tx, 0, ty)
                sgSpringX, sgSpringY = tx, ty
                sgVelX, sgVelY = 0, 0
            end
            syncSuggestPos = _syncPos

            RunService.RenderStepped:Connect(function(dt)
                if not (suggestFrame and suggestFrame.Parent) then return end
                local tx, ty = getSgTarget()
                if not tx then return end
                local ax = SG_SPRING_S * (tx - sgSpringX) - SG_SPRING_D * sgVelX
                local ay = SG_SPRING_S * (ty - sgSpringY) - SG_SPRING_D * sgVelY
                sgVelX = sgVelX + ax * dt
                sgVelY = sgVelY + ay * dt
                sgSpringX = sgSpringX + sgVelX * dt
                sgSpringY = sgSpringY + sgVelY * dt
                suggestFrame.Position = UDim2.new(0, sgSpringX, 0, sgSpringY)
            end)

            task.spawn(function()
                RunService.RenderStepped:Wait()
                _syncPos()
            end)

            local hideToken = 0

            local function hideSuggest()
                hideToken = hideToken + 1
                local token = hideToken
                for _, t in ipairs(suggestTips) do
                    if t and t.Parent then t.Visible = false end
                end
                TweenService:Create(suggestFrame, TI.fast, {BackgroundTransparency = 1}):Play()
                task.delay(0.15, function()
                    if hideToken ~= token then return end
                    suggestFrame.Visible = false
                    suggestFrame.Active  = false
                    suggestFrame.BackgroundTransparency = 0.3
                    if waypointBox and waypointBox.Visible and rebuildWpBox then rebuildWpBox() end
                end)
            end
            hideSuggestFn = hideSuggest

            local function showSuggest(h)
                hideToken = hideToken + 1
                syncSuggestPos()
                suggestFrame.Size                   = UDim2.new(0, SUGGEST_W, 0, h)
                suggestFrame.BackgroundTransparency = 1
                suggestFrame.Visible = true
                suggestFrame.Active  = true
                TweenService:Create(suggestFrame, TI.med, {BackgroundTransparency = 0.3}):Play()
                if waypointBox and waypointBox.Visible and rebuildWpBox then rebuildWpBox() end
            end

            local closeBtn = Instance.new("TextButton")
            closeBtn.Size = UDim2.new(0, 24, 0, 24)
            closeBtn.Position = UDim2.new(1, -26, 0, 2)
            closeBtn.BackgroundTransparency = 1
            closeBtn.BorderSizePixel = 0
            closeBtn.Text = "X"
            closeBtn.TextColor3 = T.inputPh
            closeBtn.TextSize = 16
            closeBtn.Font = Enum.Font.GothamBold
            closeBtn.AutoButtonColor = false
            closeBtn.ZIndex = 22
            closeBtn.Parent = suggestFrame
            tapConnect(closeBtn, hideSuggest)
            connectBtn(closeBtn,
                function() TweenService:Create(closeBtn, TI.fast, {TextColor3 = T.accent}):Play() end,
                function() TweenService:Create(closeBtn, TI.fast, {TextColor3 = T.inputPh}):Play() end
            )

            local suggestScroll = Instance.new("ScrollingFrame")
            suggestScroll.Size = UDim2.new(1, 0, 1, 0)
            suggestScroll.BackgroundTransparency = 1
            suggestScroll.BorderSizePixel = 0
            suggestScroll.ScrollBarThickness = 2
            suggestScroll.ScrollBarImageColor3 = T.scrollBar
            suggestScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
            suggestScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
            suggestScroll.ZIndex = 20
            suggestScroll.Parent = suggestFrame

            local suggestLayout = Instance.new("UIListLayout")
            suggestLayout.SortOrder = Enum.SortOrder.LayoutOrder
            suggestLayout.Padding = UDim.new(0, 0)
            suggestLayout.Parent = suggestScroll

            local suggestPad = Instance.new("UIPadding")
            suggestPad.PaddingLeft   = UDim.new(0, 18)
            suggestPad.PaddingRight  = UDim.new(0, 18)
            suggestPad.PaddingTop    = UDim.new(0, 4)
            suggestPad.PaddingBottom = UDim.new(0, 4)
            suggestPad.Parent = suggestScroll

            local function updateSuggestions(text)
                local query = text:match("^%s*(.-)%s*$"):lower()

                local all = {}
                for k in pairs(COMMANDS) do all[#all+1] = k end
                table.sort(all)

                local matches = {}
                if query ~= "" then
                    for _, k in ipairs(all) do
                        if k:sub(1, #query) == query and k ~= query then
                            matches[#matches+1] = k
                        end
                    end
                end

                for _, b in ipairs(suggestBtns) do b:Destroy() end
                suggestBtns = {}
                for _, t in ipairs(suggestTips) do pcall(function() t:Destroy() end) end
                suggestTips = {}

                if #matches == 0 then
                    hideSuggest()
                    return
                end

                for i, cmd in ipairs(matches) do
                    local btn = Instance.new("TextButton")
                    btn.Size = UDim2.new(1, 0, 0, SUGGEST_ROW_H)
                    btn.BackgroundTransparency = 1
                    btn.BorderSizePixel = 0
                    btn.Text = cmd
                    btn.TextColor3 = T.inputTxt
                    btn.TextSize = 10
                    btn.Font = Enum.Font.Code
                    btn.TextXAlignment = Enum.TextXAlignment.Center
                    btn.AutoButtonColor = false
                    btn.LayoutOrder = i
                    btn.ZIndex = 11
                    btn.TextTransparency = 1
                    btn.BackgroundColor3 = rgb(0, 0, 0)
                    btn.Parent = suggestScroll
                    suggestBtns[#suggestBtns+1] = btn
                    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

                    local desc = DESCRIPTIONS[cmd]
                    if desc then
                        local tip = Instance.new("TextLabel")
                        tip.Size = UDim2.new(0, SUGGEST_W - 8, 0, 18)
                        tip.BackgroundColor3 = rgb(15, 15, 18)
                        tip.BackgroundTransparency = 0.1
                        tip.BorderSizePixel = 0
                        tip.Text = desc
                        tip.TextColor3 = T.inputPh
                        tip.TextSize = 9
                        tip.Font = Enum.Font.Gotham
                        tip.TextXAlignment = Enum.TextXAlignment.Center
                        tip.TextTruncate = Enum.TextTruncate.AtEnd
                        tip.ZIndex = 25
                        tip.Visible = false
                        tip.Parent = activeScreenGui
                        suggestTips[#suggestTips+1] = tip
                        Instance.new("UICorner", tip).CornerRadius = UDim.new(0, 4)

                        btn.MouseEnter:Connect(function()
                            if not btn.Parent or not suggestFrame.Visible then return end
                            local ap = btn.AbsolutePosition
                            local as = btn.AbsoluteSize
                            tip.Position = UDim2.new(0, ap.X + 4, 0, ap.Y + as.Y + 4)
                            tip.Visible = true
                        end)
                        btn.MouseLeave:Connect(function()
                            tip.Visible = false
                        end)
                        btn.AncestryChanged:Connect(function()
                            if not btn.Parent then
                                tip.Visible = false
                                tip:Destroy()
                            end
                        end)
                    end
                    task.delay(i * 0.03, function()
                        if btn and btn.Parent then
                            TweenService:Create(btn, TI.fast, {TextTransparency = 0}):Play()
                        end
                    end)

                    tapConnect(btn, function()
                        cmdBox.Text = cmd
                        hideSuggest()
                    end)
                    btn.InputBegan:Connect(function(inp)
                        if inp.UserInputType ~= Enum.UserInputType.MouseButton1
                        and inp.UserInputType ~= Enum.UserInputType.Touch then return end
                        for _, b in ipairs(suggestBtns) do
                            if b ~= btn then
                                TweenService:Create(b, TI.fast, {BackgroundTransparency = 1}):Play()
                            end
                        end
                        TweenService:Create(btn, TI.fast, {BackgroundTransparency = 0.5}):Play()
                    end)
                    btn.InputEnded:Connect(function(inp)
                        if inp.UserInputType ~= Enum.UserInputType.MouseButton1
                        and inp.UserInputType ~= Enum.UserInputType.Touch then return end
                        TweenService:Create(btn, TI.fast, {BackgroundTransparency = 1}):Play()
                    end)
                end

                local h = math.min(#matches * SUGGEST_ROW_H, SUGGEST_MAX_H) + 8
                showSuggest(h)
            end

            cmdBox:GetPropertyChangedSignal("Text"):Connect(function()
                updateSuggestions(cmdBox.Text)
            end)
            adminCmdBox = cmdBox
            _G.__luwaUpdateSuggestions = updateSuggestions

            cmdBox.Focused:Connect(function()
                updateSuggestions(cmdBox.Text)
            end)

            local function runCommand(raw)
                local trimmed = raw:match("^%s*(.-)%s*$")
                if trimmed == "" then return end
                local cmd, arg = trimmed:match("^(%S+)%s*(.*)$")
                cmd = cmd:lower()
                arg = (arg ~= "" and arg) or nil
                logLine("> " .. trimmed, rgb(160, 160, 175))
                local fn = COMMANDS[cmd]
                if fn then
                    fn(arg)
                else
                    logLine("  unknown command: " .. cmd, rgb(220, 80, 80))
                end
                cmdBox.Text = ""
                hideSuggest()
            end

            runBtn.Activated:Connect(function()
                runCommand(cmdBox.Text)
            end)

            cmdBox.FocusLost:Connect(function(enterPressed)
                if enterPressed then
                    runCommand(cmdBox.Text)
                end
            end)

            cmdBox.Focused:Connect(function()
                TweenService:Create(cmdStroke, TI.strokeIn, {Color = T.strokeFocus}):Play()
            end)
            cmdBox.FocusLost:Connect(function()
                TweenService:Create(cmdStroke, TI.strokeIn, {Color = T.strokeIdle}):Play()
            end)

            connectBtn(runBtn,
                function() TweenService:Create(runBtn, TI.fast, {BackgroundTransparency = 0.4}):Play() end,
                function() TweenService:Create(runBtn, TI.fast, {BackgroundTransparency = T.btnTrans}):Play() end
            )
        end,
    },
    {
        name = "Scripts",
        iconType = "scripts",
        build = function(content)
            local sf = makeScrollList(content)

            makeSection(sf, "Waypoints")

            local function create3DMarker(position, name, color)
                local part = Instance.new("Part")
                part.Anchored    = true
                part.CanCollide  = false
                part.Size        = Vector3.new(0.1, 0.1, 0.1)
                part.Transparency = 1
                part.Position    = position
                part.Name        = "LuwaWP_" .. name
                part.Parent      = workspace
                local bb = Instance.new("BillboardGui", part)
                bb.Size        = UDim2.new(0, 160, 0, 44)
                bb.AlwaysOnTop = true
                bb.StudsOffset = Vector3.new(0, 3, 0)
                local lbl = Instance.new("TextLabel", bb)
                lbl.Size = UDim2.new(1, 0, 0.6, 0)
                lbl.Position = UDim2.new(0, 0, 0, 0)
                lbl.BackgroundTransparency = 1
                lbl.Text = name
                lbl.TextColor3 = color
                lbl.TextScaled = true
                lbl.Font = Enum.Font.GothamBold
                lbl.TextStrokeTransparency = 0.4
                local distBb = Instance.new("TextLabel", bb)
                distBb.Size = UDim2.new(1, 0, 0.4, 0)
                distBb.Position = UDim2.new(0, 0, 0.6, 0)
                distBb.BackgroundTransparency = 1
                distBb.Text = ""
                distBb.TextColor3 = Color3.fromRGB(200, 200, 210)
                distBb.TextScaled = true
                distBb.Font = Enum.Font.Gotham
                distBb.TextStrokeTransparency = 0.5
                return part, distBb
            end

            local function updateScrollCanvas(wpSf, wpLayout)
                wpSf.CanvasSize = UDim2.new(0, 0, 0, wpLayout.AbsoluteContentSize.Y + 8)
            end

            local wpInputBg = Instance.new("Frame")
            wpInputBg.Size = UDim2.new(1, -8, 0, 32)
            wpInputBg.BackgroundColor3 = T.rowBg
            wpInputBg.BackgroundTransparency = T.rowTrans
            wpInputBg.BorderSizePixel = 0
            wpInputBg.Parent = sf
            Instance.new("UICorner", wpInputBg).CornerRadius = UDim.new(0, 10)

            local wpStroke = Instance.new("UIStroke")
            wpStroke.Color = T.strokeIdle
            wpStroke.Thickness = 1
            wpStroke.Parent = wpInputBg

            local wpBox = Instance.new("TextBox")
            wpBox.Size = UDim2.new(1, -80, 1, 0)
            wpBox.Position = UDim2.new(0, 8, 0, 0)
            wpBox.BackgroundTransparency = 1
            wpBox.PlaceholderText = "Waypoint name..."
            wpBox.PlaceholderColor3 = T.inputPh
            wpBox.Text = ""
            wpBox.TextColor3 = T.inputTxt
            wpBox.TextSize = 11
            wpBox.Font = Enum.Font.Gotham
            wpBox.TextXAlignment = Enum.TextXAlignment.Left
            wpBox.ClearTextOnFocus = false
            wpBox.Parent = wpInputBg

            wpBox.Focused:Connect(function()
                TweenService:Create(wpStroke, TI.strokeIn, {Color = T.strokeFocus, Thickness = 1.5}):Play()
            end)
            wpBox.FocusLost:Connect(function()
                TweenService:Create(wpStroke, TI.fast, {Color = T.strokeIdle, Thickness = 1}):Play()
            end)

            local wpSaveBtn = Instance.new("TextButton")
            wpSaveBtn.Size = UDim2.new(0, 64, 1, -6)
            wpSaveBtn.Position = UDim2.new(1, -68, 0, 3)
            wpSaveBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 85)
            wpSaveBtn.BackgroundTransparency = 0.15
            wpSaveBtn.BorderSizePixel = 0
            wpSaveBtn.Text = "Save"
            wpSaveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            wpSaveBtn.TextSize = 11
            wpSaveBtn.Font = Enum.Font.GothamBold
            wpSaveBtn.AutoButtonColor = false
            wpSaveBtn.Parent = wpInputBg
            Instance.new("UICorner", wpSaveBtn).CornerRadius = UDim.new(0, 6)
            local wpSaveStroke = Instance.new("UIStroke")
            wpSaveStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            wpSaveStroke.Color = Color3.fromRGB(255, 255, 255)
            wpSaveStroke.Thickness = 0.5
            wpSaveStroke.Transparency = 0.6
            wpSaveStroke.Parent = wpSaveBtn



            local WP_BOX_W = 185
            local WP_ROW_H = 32

            waypointBox = Instance.new("Frame")
            waypointBox.Size = UDim2.new(0, WP_BOX_W, 0, 0)
            waypointBox.BackgroundColor3 = T.inputBg
            waypointBox.BackgroundTransparency = 0.3
            waypointBox.BorderSizePixel = 0
            waypointBox.ClipsDescendants = true
            waypointBox.Visible = false
            waypointBox.Active = false
            waypointBox.ZIndex = 20
            waypointBox.Parent = activeScreenGui
            Instance.new("UICorner", waypointBox).CornerRadius = UDim.new(0, 7)
            local wpBoxStroke = Instance.new("UIStroke")
            wpBoxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            wpBoxStroke.Color = T.strokeIdle
            wpBoxStroke.Thickness = 1.5
            wpBoxStroke.Parent = waypointBox
            waypointBoxStroke = wpBoxStroke

            local wpBoxLabel = Instance.new("TextLabel")
            wpBoxLabel.Size = UDim2.new(1, -36, 0, 20)
            wpBoxLabel.Position = UDim2.new(0, 8, 0, 4)
            wpBoxLabel.BackgroundTransparency = 1
            wpBoxLabel.Text = "Waypoints"
            wpBoxLabel.TextColor3 = T.accent
            wpBoxLabel.TextSize = 10
            wpBoxLabel.Font = Enum.Font.GothamBold
            wpBoxLabel.TextXAlignment = Enum.TextXAlignment.Left
            wpBoxLabel.ZIndex = 21
            wpBoxLabel.Parent = waypointBox

            local wpBoxClose = Instance.new("TextButton")
            wpBoxClose.Size = UDim2.new(0, 24, 0, 24)
            wpBoxClose.Position = UDim2.new(1, -26, 0, 2)
            wpBoxClose.BackgroundTransparency = 1
            wpBoxClose.BorderSizePixel = 0
            wpBoxClose.Text = "X"
            wpBoxClose.TextColor3 = T.inputPh
            wpBoxClose.TextSize = 16
            wpBoxClose.Font = Enum.Font.GothamBold
            wpBoxClose.AutoButtonColor = false
            wpBoxClose.ZIndex = 22
            wpBoxClose.Parent = waypointBox
            tapConnect(wpBoxClose, function()
                wpBoxOpen = false
                if showWpOpt then
                    showWpOpt.state = false
                    if showWpOpt.syncFn then showWpOpt.syncFn() end
                end
                TweenService:Create(waypointBox, TI.fast, {BackgroundTransparency = 1}):Play()
                task.delay(0.15, function()
                    if waypointBox then
                        waypointBox.Visible = false
                        waypointBox.Active  = false
                        waypointBox.BackgroundTransparency = 0.3
                    end
                end)
            end)
            connectBtn(wpBoxClose,
                function() TweenService:Create(wpBoxClose, TI.fast, {TextColor3 = T.accent}):Play() end,
                function() TweenService:Create(wpBoxClose, TI.fast, {TextColor3 = T.inputPh}):Play() end
            )

            local wpBoxScroll = Instance.new("ScrollingFrame")
            wpBoxScroll.Size = UDim2.new(1, 0, 1, -26)
            wpBoxScroll.Position = UDim2.new(0, 0, 0, 26)
            wpBoxScroll.BackgroundTransparency = 1
            wpBoxScroll.BorderSizePixel = 0
            wpBoxScroll.ScrollBarThickness = 2
            wpBoxScroll.ScrollBarImageColor3 = T.scrollBar
            wpBoxScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
            wpBoxScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
            wpBoxScroll.ZIndex = 20
            wpBoxScroll.Parent = waypointBox
            local wpBoxLayout = Instance.new("UIListLayout")
            wpBoxLayout.SortOrder = Enum.SortOrder.LayoutOrder
            wpBoxLayout.Padding = UDim.new(0, 3)
            wpBoxLayout.Parent = wpBoxScroll
            local wpBoxPad = Instance.new("UIPadding")
            wpBoxPad.PaddingLeft   = UDim.new(0, 5)
            wpBoxPad.PaddingRight  = UDim.new(0, 5)
            wpBoxPad.PaddingTop    = UDim.new(0, 3)
            wpBoxPad.PaddingBottom = UDim.new(0, 3)
            wpBoxPad.Parent = wpBoxScroll

            local wpSpringX, wpSpringY = 0, 0
            local wpVelX,   wpVelY   = 0, 0
            local wpSpringConn = nil

            local function getWpTarget()
                if not activeFrame or not activeFrame.Parent then return nil, nil end
                local ap = activeFrame.AbsolutePosition
                local as = activeFrame.AbsoluteSize
                local tx = ap.X + as.X + 6
                local ty = ap.Y + as.Y * 0.55
                return tx, ty
            end

            local function syncWpBoxPos()
                local tx, ty = getWpTarget()
                if not tx then return end
                waypointBox.Position = UDim2.new(0, tx, 0, ty)
                wpSpringX, wpSpringY = tx, ty
                wpVelX, wpVelY = 0, 0
            end

            local SPRING_S = 280
            local SPRING_D = 22

            if wpSpringConn then wpSpringConn:Disconnect() end
            wpSpringConn = RunService.RenderStepped:Connect(function(dt)
                if not (waypointBox and waypointBox.Parent) then return end
                local tx, ty = getWpTarget()
                if not tx then return end
                local ax = SPRING_S * (tx - wpSpringX) - SPRING_D * wpVelX
                local ay = SPRING_S * (ty - wpSpringY) - SPRING_D * wpVelY
                wpVelX = wpVelX + ax * dt
                wpVelY = wpVelY + ay * dt
                wpSpringX = wpSpringX + wpVelX * dt
                wpSpringY = wpSpringY + wpVelY * dt
                waypointBox.Position = UDim2.new(0, wpSpringX, 0, wpSpringY)
            end)

            task.spawn(function()
                RunService.RenderStepped:Wait()
                syncWpBoxPos()
            end)

            local WP_MAX_VISIBLE = 3

            rebuildWpBox = function()
                for _, c in ipairs(wpBoxScroll:GetChildren()) do
                    if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then
                        c:Destroy()
                    end
                end
                if #waypoints == 0 then
                    waypointBox.Visible = false
                    waypointBox.Active  = false
                    return
                end
                for idx, wp in ipairs(waypoints) do
                    local row = Instance.new("Frame")
                    row.Size = UDim2.new(1, 0, 0, WP_ROW_H)
                    row.BackgroundColor3 = rgb(0, 0, 0)
                    row.BackgroundTransparency = 0.6
                    row.BorderSizePixel = 0
                    row.LayoutOrder = idx
                    row.ZIndex = 21
                    row.Parent = wpBoxScroll
                    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
                    local rowStroke = Instance.new("UIStroke")
                    rowStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    rowStroke.Color = wp.color
                    rowStroke.Thickness = 0.6
                    rowStroke.Transparency = 0.5
                    rowStroke.Parent = row

                    local nameLbl = Instance.new("TextLabel")
                    nameLbl.Size = UDim2.new(1, -58, 1, 0)
                    nameLbl.Position = UDim2.new(0, 6, 0, 0)
                    nameLbl.BackgroundTransparency = 1
                    nameLbl.Text = wp.name
                    nameLbl.TextColor3 = wp.color
                    nameLbl.TextSize = 10
                    nameLbl.Font = Enum.Font.GothamSemibold
                    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
                    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
                    nameLbl.ZIndex = 22
                    nameLbl.Parent = row

                    local tpBtn = Instance.new("TextButton")
                    tpBtn.Size = UDim2.new(0, 24, 0, 20)
                    tpBtn.Position = UDim2.new(1, -52, 0.5, -10)
                    tpBtn.BackgroundColor3 = Color3.fromRGB(60, 130, 220)
                    tpBtn.BackgroundTransparency = 0.2
                    tpBtn.BorderSizePixel = 0
                    tpBtn.Text = "TP"
                    tpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                    tpBtn.TextSize = 8
                    tpBtn.Font = Enum.Font.GothamBold
                    tpBtn.AutoButtonColor = false
                    tpBtn.ZIndex = 22
                    tpBtn.Parent = row
                    Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 4)
                    tapConnect(tpBtn, function()
                        local char = LocalPlayer.Character
                        local root = char and char:FindFirstChild("HumanoidRootPart")
                        if not root then return end
                        local wasActive = antiFlingActive
                        if wasActive then stopAntiFling() end
                        root.CFrame = CFrame.new(wp.pos + Vector3.new(0, 3, 0))
                        task.delay(0.3, function()
                            if wasActive then startAntiFling() end
                        end)
                        TweenService:Create(tpBtn, TI.flash,   {BackgroundColor3 = Color3.fromRGB(50, 200, 100)}):Play()
                        task.delay(0.4, function()
                            TweenService:Create(tpBtn, TI.unflash, {BackgroundColor3 = Color3.fromRGB(60, 130, 220)}):Play()
                        end)
                    end)
                    connectBtn(tpBtn,
                        function() TweenService:Create(tpBtn, TI.fast, {BackgroundTransparency = 0.05}):Play() end,
                        function() TweenService:Create(tpBtn, TI.fast, {BackgroundTransparency = 0.2}):Play()  end
                    )

                    local delBtn = Instance.new("TextButton")
                    delBtn.Size = UDim2.new(0, 20, 0, 20)
                    delBtn.Position = UDim2.new(1, -24, 0.5, -10)
                    delBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
                    delBtn.BackgroundTransparency = 0.2
                    delBtn.BorderSizePixel = 0
                    delBtn.Text = "X"
                    delBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                    delBtn.TextSize = 8
                    delBtn.Font = Enum.Font.GothamBold
                    delBtn.AutoButtonColor = false
                    delBtn.ZIndex = 22
                    delBtn.Parent = row
                    Instance.new("UICorner", delBtn).CornerRadius = UDim.new(0, 4)
                    tapConnect(delBtn, function()
                        for i, w in ipairs(waypoints) do
                            if w == wp then table.remove(waypoints, i) break end
                        end
                        if wp.marker and wp.marker.Parent then wp.marker:Destroy() end
                        rebuildWpBox()
                    end)
                    connectBtn(delBtn,
                        function() TweenService:Create(delBtn, TI.fast, {BackgroundTransparency = 0.05}):Play() end,
                        function() TweenService:Create(delBtn, TI.fast, {BackgroundTransparency = 0.2}):Play()  end
                    )
                end

                local visRows = math.min(#waypoints, WP_MAX_VISIBLE)
                local newH    = visRows * (WP_ROW_H + 3) + 26 + 8
                waypointBox.Size = UDim2.new(0, WP_BOX_W, 0, newH)
                syncWpBoxPos()
                if wpBoxOpen then
                    waypointBox.BackgroundTransparency = 1
                    waypointBox.Visible = true
                    waypointBox.Active  = true
                    TweenService:Create(waypointBox, TI.med, {BackgroundTransparency = 0.3}):Play()
                end
            end

            rebuildWpBox()

            tapConnect(wpSaveBtn, function()
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if not root then return end
                local rawName = wpBox.Text:match("^%s*(.-)%s*$")
                local wpName = rawName ~= "" and rawName or ("WP #" .. tostring(#waypoints + 1))
                wpBox.Text = ""
                local color = Color3.fromRGB(255, 255, 255)
                local marker, bbDistLbl = create3DMarker(root.Position, wpName, color)
                local wp = { name = wpName, pos = root.Position, color = color, marker = marker, bbDistLbl = bbDistLbl }
                table.insert(waypoints, wp)
                rebuildWpBox()
                TweenService:Create(wpSaveBtn, TI.flash,   {BackgroundColor3 = Color3.fromRGB(50, 200, 100)}):Play()
                task.delay(0.5, function()
                    TweenService:Create(wpSaveBtn, TI.unflash, {BackgroundColor3 = Color3.fromRGB(40, 160, 85)}):Play()
                end)
            end)
            connectBtn(wpSaveBtn,
                function() TweenService:Create(wpSaveBtn, TI.fast, {BackgroundTransparency = 0.05}):Play() end,
                function() TweenService:Create(wpSaveBtn, TI.fast, {BackgroundTransparency = 0.15}):Play() end
            )

            local showWpToggleOpt = { type="toggle", name="Show Waypoints", state=false,
                enable = function()
                    wpBoxOpen = true
                    if waypointBox and #waypoints > 0 then
                        waypointBox.BackgroundTransparency = 1
                        waypointBox.Visible = true
                        waypointBox.Active  = true
                        TweenService:Create(waypointBox, TI.med, {BackgroundTransparency = 0.3}):Play()
                    end
                end,
                disable = function()
                    wpBoxOpen = false
                    if waypointBox and waypointBox.Visible then
                        TweenService:Create(waypointBox, TI.fast, {BackgroundTransparency = 1}):Play()
                        task.delay(0.15, function()
                            if not wpBoxOpen and waypointBox then
                                waypointBox.Visible = false
                                waypointBox.Active  = false
                                waypointBox.BackgroundTransparency = 0.3
                            end
                        end)
                    end
                end,
            }
            showWpOpt = showWpToggleOpt
            makeToggle(sf, showWpToggleOpt)

            for _, opt in ipairs(OPTIONS) do
                if     opt.type == "section" then makeSection(sf, opt.name)
                elseif opt.type == "toggle"  then makeToggle(sf, opt)
                elseif opt.type == "button"  then makeButton(sf, opt)
                end
            end

            makeSection(sf, "Fling")

            local flingCard = Instance.new("Frame")
            flingCard.Size = UDim2.new(1, -8, 0, 126)
            flingCard.BackgroundColor3 = T.rowBg
            flingCard.BackgroundTransparency = T.rowTrans
            flingCard.BorderSizePixel = 0
            flingCard.Parent = sf
            Instance.new("UICorner", flingCard).CornerRadius = UDim.new(0, 10)

            local flingStrip = Instance.new("Frame")
            flingStrip.Size = UDim2.new(0, 4, 1, -10)
            flingStrip.Position = UDim2.new(0, 8, 0, 5)
            flingStrip.BackgroundColor3 = T.accent
            flingStrip.BorderSizePixel = 0; flingStrip.Parent = flingCard
            Instance.new("UICorner", flingStrip).CornerRadius = UDim.new(1, 0)

            local flingLbl = Instance.new("TextLabel")
            flingLbl.Size = UDim2.new(1, -24, 0, 16)
            flingLbl.Position = UDim2.new(0, 20, 0, 8)
            flingLbl.BackgroundTransparency = 1
            flingLbl.Text = "Target Username"
            flingLbl.TextColor3 = T.rowLbl
            flingLbl.TextSize = 11; flingLbl.Font = Enum.Font.GothamSemibold
            flingLbl.TextXAlignment = Enum.TextXAlignment.Left
            flingLbl.Parent = flingCard

            local flingInputBg = Instance.new("Frame")
            flingInputBg.Size = UDim2.new(1, -24, 0, 26)
            flingInputBg.Position = UDim2.new(0, 20, 0, 27)
            flingInputBg.BackgroundColor3 = T.inputBg
            flingInputBg.BorderSizePixel = 0; flingInputBg.Parent = flingCard
            Instance.new("UICorner", flingInputBg).CornerRadius = UDim.new(0, 6)
            local flingStroke = Instance.new("UIStroke")
            flingStroke.Color = T.strokeIdle; flingStroke.Thickness = 1
            flingStroke.Parent = flingInputBg

            local flingBox = Instance.new("TextBox")
            flingBox.Size = UDim2.new(1, -10, 1, 0)
            flingBox.Position = UDim2.new(0, 8, 0, 0)
            flingBox.BackgroundTransparency = 1
            flingBox.PlaceholderText = "Type player name..."
            flingBox.PlaceholderColor3 = T.inputPh
            flingBox.Text = flingBoxText
            flingBox.TextColor3 = T.inputTxt
            flingBox.TextSize = 12; flingBox.Font = Enum.Font.Gotham
            flingBox.TextXAlignment = Enum.TextXAlignment.Left
            flingBox.ClearTextOnFocus = false
            flingBox.Parent = flingInputBg

            flingBox.Focused:Connect(function()
                TweenService:Create(flingStroke, TI.strokeIn, {Color=T.strokeFocus, Thickness=1.5}):Play()
            end)
            flingBox.FocusLost:Connect(function()
                flingBoxText = flingBox.Text
                TweenService:Create(flingStroke, TI.fast, {Color=T.strokeIdle, Thickness=1}):Play()
            end)

            local flingBtn = Instance.new("TextButton")
            flingBtn.Size = UDim2.new(1, -24, 0, 28)
            flingBtn.Position = UDim2.new(0, 20, 0, 60)
            flingBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            flingBtn.BackgroundTransparency = 0.75
            flingBtn.BorderSizePixel = 0
            flingBtn.Text = "FLING"
            flingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            flingBtn.TextStrokeColor3 = Color3.fromRGB(0,0,0)
            flingBtn.TextStrokeTransparency = 1
            flingBtn.TextSize = 13; flingBtn.Font = Enum.Font.GothamBold
            flingBtn.AutoButtonColor = false
            flingBtn.Parent = flingCard
            Instance.new("UICorner", flingBtn).CornerRadius = UDim.new(0, 8)

            tapConnect(flingBtn, function()
                local name = flingBox.Text:match("^%s*(.-)%s*$")
                if name == "" then return end
                local target = nil
                for _, p in ipairs(Players:GetPlayers()) do
                    if p.Name:lower() == name:lower() then target = p; break end
                end
                if not target then
                    TweenService:Create(flingStroke, TI.flash, {Color=Color3.fromRGB(220,60,60), Thickness=1.5}):Play()
                    task.delay(0.5, function()
                        TweenService:Create(flingStroke, TI.unflash, {Color=T.strokeIdle, Thickness=1}):Play()
                    end)
                    return
                end
                TweenService:Create(flingStroke, TI.flash, {Color=Color3.fromRGB(50,200,100), Thickness=1.5}):Play()
                task.delay(0.5, function()
                    TweenService:Create(flingStroke, TI.unflash, {Color=T.strokeIdle, Thickness=1}):Play()
                end)
                startFlingOnce(target.Name)
            end)
            connectBtn(flingBtn,
                function() TweenService:Create(flingBtn, TI.fast, {BackgroundTransparency=0.55}):Play() end,
                function() TweenService:Create(flingBtn, TI.fast, {BackgroundTransparency=0.75}):Play() end
            )

            local stopBtn = Instance.new("TextButton")
            stopBtn.Size = UDim2.new(1, -24, 0, 24)
            stopBtn.Position = UDim2.new(0, 20, 0, 95)
            stopBtn.BackgroundColor3 = T.rstBg
            stopBtn.BackgroundTransparency = 0.75
            stopBtn.Text = "Stop All Flings"
            stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            stopBtn.TextSize = 11; stopBtn.Font = Enum.Font.GothamSemibold
            stopBtn.AutoButtonColor = false
            stopBtn.Parent = flingCard
            Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0, 7)

            tapConnect(stopBtn, function()
                stopAllFlings()
                TweenService:Create(stopBtn, TI.flash,   {BackgroundColor3=Color3.fromRGB(80,80,80)}):Play()
                task.delay(0.4, function()
                    TweenService:Create(stopBtn, TI.unflash, {BackgroundColor3=T.rstBg}):Play()
                end)
            end)
            connectBtn(stopBtn,
                function() TweenService:Create(stopBtn, TI.fast, {BackgroundColor3=T.rstHov}):Play() end,
                function() TweenService:Create(stopBtn, TI.fast, {BackgroundColor3=T.rstBg}):Play()  end
            )

            local browseBtn = Instance.new("TextButton")
            browseBtn.Size = UDim2.new(1, -8, 0, 34)
            browseBtn.BackgroundColor3 = T.btnBg
            browseBtn.BackgroundTransparency = T.btnTrans
            browseBtn.BorderSizePixel = 0
            browseBtn.Text = "Browse Players"
            browseBtn.TextColor3 = T.btnLbl
            browseBtn.TextSize = 12; browseBtn.Font = Enum.Font.GothamSemibold
            browseBtn.AutoButtonColor = false
            browseBtn.Parent = sf
            Instance.new("UICorner", browseBtn).CornerRadius = UDim.new(0, 10)
            local browseMark = Instance.new("TextLabel")
            browseMark.Size = UDim2.new(0, 20, 1, 0)
            browseMark.Position = UDim2.new(1, -28, 0, 0)
            browseMark.BackgroundTransparency = 1
            browseMark.Text = ">"
            browseMark.TextColor3 = T.btnArrow
            browseMark.TextSize = 16; browseMark.Font = Enum.Font.GothamBold
            browseMark.Parent = browseBtn
            connectBtn(browseBtn,
                function() TweenService:Create(browseBtn, TI.fast, {BackgroundTransparency=0.2}):Play() end,
                function() TweenService:Create(browseBtn, TI.fast, {BackgroundTransparency=T.btnTrans}):Play() end
            )

            local _oldPicker = LocalPlayer.PlayerGui:FindFirstChild("LuwaFlingPicker")
            if _oldPicker then _oldPicker:Destroy() end

            local pickerGui = Instance.new("ScreenGui")
            pickerGui.Name = "LuwaFlingPicker"
            pickerGui.ResetOnSpawn = false
            pickerGui.IgnoreGuiInset = true
            pickerGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            pickerGui.DisplayOrder = 20
            pickerGui.Parent = LocalPlayer.PlayerGui

            -- NO backdrop: persistent window, stays open when loop fling toggled
            local SHEET_H = 320
            local SHEET_W = 240
            local sheet = Instance.new("Frame")
            sheet.Size     = UDim2.new(0, SHEET_W, 0, SHEET_H)
            sheet.Position = UDim2.new(0.5, -SHEET_W/2, 0.5, -SHEET_H/2)
            sheet.Active   = true
            sheet.BackgroundColor3 = T.frameBg
            sheet.BackgroundTransparency = T.frameTrans
            sheet.BorderSizePixel = 0
            sheet.ZIndex = 2
            sheet.Parent = pickerGui
            Instance.new("UICorner", sheet).CornerRadius = UDim.new(0, 20)
            local sheetStroke = Instance.new("UIStroke")
            sheetStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            sheetStroke.Color = Color3.fromRGB(255, 255, 255)
            sheetStroke.Thickness = 0.5
            sheetStroke.Transparency = 0.35
            sheetStroke.Parent = sheet

            -- Top glint (matches main frame style)
            local pickerGlint = Instance.new("Frame")
            pickerGlint.Size                   = UDim2.new(1, -28, 0, 10)
            pickerGlint.Position               = UDim2.new(0, 14, 0, 5)
            pickerGlint.BackgroundColor3       = Color3.fromRGB(255, 255, 255)
            pickerGlint.BackgroundTransparency = 1
            pickerGlint.BorderSizePixel        = 0
            pickerGlint.ZIndex                 = 10
            pickerGlint.Parent                 = sheet
            Instance.new("UICorner", pickerGlint).CornerRadius = UDim.new(0, 6)
            local pickerGlintGrad = Instance.new("UIGradient")
            pickerGlintGrad.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0,    1   ),
                NumberSequenceKeypoint.new(0.15, 0.86),
                NumberSequenceKeypoint.new(0.5,  0.80),
                NumberSequenceKeypoint.new(0.85, 0.86),
                NumberSequenceKeypoint.new(1,    1   ),
            })
            pickerGlintGrad.Parent = pickerGlint

            local header = Instance.new("Frame")
            header.Size = UDim2.new(1, 0, 0, 52)
            header.BackgroundTransparency = 1
            header.BorderSizePixel = 0
            header.ZIndex = 3
            header.Active = true
            header.Parent = sheet

            -- Accent line below header (matches main frame separator)
            local pickerAccentLine = Instance.new("Frame")
            pickerAccentLine.Size             = UDim2.new(1, -20, 0, 2)
            pickerAccentLine.Position         = UDim2.new(0, 10, 0, 50)
            pickerAccentLine.BackgroundColor3 = T.accent
            pickerAccentLine.BorderSizePixel  = 0
            pickerAccentLine.ZIndex           = 4
            pickerAccentLine.Parent           = sheet
            Instance.new("UICorner", pickerAccentLine).CornerRadius = UDim.new(1, 0)

            -- Drag by header
            do
                local _dragInp, _dragStart, _sheetStart = nil, nil, nil
                header.InputBegan:Connect(function(inp)
                    if inp.UserInputType ~= Enum.UserInputType.MouseButton1
                    and inp.UserInputType ~= Enum.UserInputType.Touch then return end
                    _dragInp   = inp
                    _dragStart  = inp.Position
                    _sheetStart = sheet.Position
                end)
                UserInputService.InputChanged:Connect(function(inp)
                    if inp ~= _dragInp then return end
                    local d = inp.Position - _dragStart
                    sheet.Position = UDim2.new(_sheetStart.X.Scale, _sheetStart.X.Offset + d.X,
                                               _sheetStart.Y.Scale, _sheetStart.Y.Offset + d.Y)
                end)
                UserInputService.InputEnded:Connect(function(inp)
                    if inp == _dragInp then _dragInp = nil end
                end)
            end

            -- Drag handle dots
            local dragIcon = Instance.new("TextLabel")
            dragIcon.Size = UDim2.new(0, 14, 1, 0)
            dragIcon.Position = UDim2.new(0, 10, 0, 0)
            dragIcon.BackgroundTransparency = 1
            dragIcon.Text = "::"
            dragIcon.TextColor3 = Color3.fromRGB(70, 70, 82)
            dragIcon.TextSize = 13
            dragIcon.Font = Enum.Font.GothamBold
            dragIcon.ZIndex = 4
            dragIcon.Parent = header

            local sheetTitle = Instance.new("TextLabel")
            sheetTitle.Size = UDim2.new(1, -60, 0, 20)
            sheetTitle.Position = UDim2.new(0, 28, 0, 9)
            sheetTitle.BackgroundTransparency = 1
            sheetTitle.Text = "Player Selector"
            sheetTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
            sheetTitle.TextSize = 14
            sheetTitle.Font = Enum.Font.GothamBold
            sheetTitle.TextXAlignment = Enum.TextXAlignment.Left
            sheetTitle.ZIndex = 4
            sheetTitle.Parent = header

            local sheetSub = Instance.new("TextLabel")
            sheetSub.Size = UDim2.new(1, -60, 0, 13)
            sheetSub.Position = UDim2.new(0, 28, 0, 30)
            sheetSub.BackgroundTransparency = 1
            sheetSub.Text = "Click to select  |  Toggle loop fling"
            sheetSub.TextColor3 = Color3.fromRGB(100, 100, 110)
            sheetSub.TextSize = 9
            sheetSub.Font = Enum.Font.Gotham
            sheetSub.TextXAlignment = Enum.TextXAlignment.Left
            sheetSub.ZIndex = 4
            sheetSub.Parent = header

            local sheetClose = Instance.new("TextButton")
            sheetClose.Size = UDim2.new(0, 26, 0, 26)
            sheetClose.Position = UDim2.new(1, -34, 0, 13)
            sheetClose.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            sheetClose.BackgroundTransparency = 0.55
            sheetClose.BorderSizePixel = 0
            sheetClose.Text = "X"
            sheetClose.TextColor3 = Color3.fromRGB(255, 255, 255)
            sheetClose.TextSize = 11
            sheetClose.Font = Enum.Font.GothamBold
            sheetClose.AutoButtonColor = false
            sheetClose.ZIndex = 4
            sheetClose.Parent = header
            Instance.new("UICorner", sheetClose).CornerRadius = UDim.new(1, 0)
            local closeStroke = Instance.new("UIStroke")
            closeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            closeStroke.Color = Color3.fromRGB(255, 255, 255)
            closeStroke.Thickness = 0.9
            closeStroke.Transparency = 0.55
            closeStroke.Parent = sheetClose
            connectBtn(sheetClose,
                function() TweenService:Create(sheetClose, TI.fast, {BackgroundTransparency = 0.3}):Play() end,
                function() TweenService:Create(sheetClose, TI.fast, {BackgroundTransparency = 0.55}):Play() end
            )

            local popupSf = Instance.new("ScrollingFrame")
            popupSf.Size = UDim2.new(1, -12, 1, -58)
            popupSf.Position = UDim2.new(0, 6, 0, 55)
            popupSf.BackgroundTransparency = 1
            popupSf.BorderSizePixel = 0
            popupSf.ScrollBarThickness = 2
            popupSf.ScrollBarImageColor3 = Color3.fromRGB(55, 55, 60)
            popupSf.AutomaticCanvasSize = Enum.AutomaticSize.Y
            popupSf.CanvasSize = UDim2.new(0,0,0,0)
            popupSf.ZIndex = 2
            popupSf.Parent = sheet
            local popupLayout = Instance.new("UIListLayout")
            popupLayout.SortOrder = Enum.SortOrder.LayoutOrder
            popupLayout.Padding = UDim.new(0, 5)
            popupLayout.Parent = popupSf
            local popupPad = Instance.new("UIPadding")
            popupPad.PaddingTop    = UDim.new(0, 4)
            popupPad.PaddingBottom = UDim.new(0, 8)
            popupPad.PaddingLeft   = UDim.new(0, 2)
            popupPad.PaddingRight  = UDim.new(0, 2)
            popupPad.Parent = popupSf

            local loopStates = flingLoopStates

            local function buildPickerCards()
                for _, c in ipairs(popupSf:GetChildren()) do
                    if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end
                end

                local others = {}
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer then others[#others+1] = p end
                end

                if #others == 0 then
                    local none = Instance.new("TextLabel")
                    none.Size = UDim2.new(1, 0, 0, 80)
                    none.BackgroundTransparency = 1
                    none.Text = "No other players"
                    none.TextColor3 = Color3.fromRGB(120, 120, 130)
                    none.TextSize = 12
                    none.Font = Enum.Font.Gotham
                    none.TextXAlignment = Enum.TextXAlignment.Center
                    none.ZIndex = 3
                    none.Parent = popupSf
                    return
                end

                for _, plr in ipairs(others) do
                    local uname  = plr.Name
                    local loopOn = loopStates[uname] == true

                    local card = Instance.new("Frame")
                    card.Size = UDim2.new(1, 0, 0, 52)
                    card.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
                    card.BackgroundTransparency = 0.08
                    card.BorderSizePixel = 0
                    card.ZIndex = 3
                    card.Parent = popupSf
                    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
                    local cardStroke = Instance.new("UIStroke")
                    cardStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    cardStroke.Color = Color3.fromRGB(40, 40, 45)
                    cardStroke.Thickness = 0.5
                    cardStroke.Transparency = 0.6
                    cardStroke.Parent = card

                    local cardHit = Instance.new("TextButton")
                    cardHit.Size = UDim2.new(1, -58, 1, 0)
                    cardHit.BackgroundTransparency = 1
                    cardHit.Text = ""
                    cardHit.AutoButtonColor = false
                    cardHit.ZIndex = 4
                    cardHit.Parent = card

                    local avatarImg = Instance.new("ImageLabel")
                    avatarImg.Size = UDim2.new(0, 32, 0, 32)
                    avatarImg.Position = UDim2.new(0, 9, 0.5, -16)
                    avatarImg.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
                    avatarImg.BorderSizePixel = 0
                    avatarImg.ZIndex = 4
                    avatarImg.Parent = card
                    Instance.new("UICorner", avatarImg).CornerRadius = UDim.new(1, 0)
                    local avStroke = Instance.new("UIStroke")
                    avStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    avStroke.Color = Color3.fromRGB(80, 80, 90)
                    avStroke.Thickness = 0.8
                    avStroke.Transparency = 0.5
                    avStroke.Parent = avatarImg
                    task.spawn(function()
                        local ok, img = pcall(function()
                            return Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size60x60)
                        end)
                        if ok and avatarImg.Parent then avatarImg.Image = img end
                    end)

                    local nLbl = Instance.new("TextLabel")
                    nLbl.Size = UDim2.new(1, -120, 0, 17)
                    nLbl.Position = UDim2.new(0, 50, 0, 9)
                    nLbl.BackgroundTransparency = 1
                    nLbl.Text = plr.DisplayName
                    nLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
                    nLbl.TextSize = 12
                    nLbl.Font = Enum.Font.GothamSemibold
                    nLbl.TextXAlignment = Enum.TextXAlignment.Left
                    nLbl.TextTruncate = Enum.TextTruncate.AtEnd
                    nLbl.ZIndex = 4
                    nLbl.Parent = card

                    local unLbl = Instance.new("TextLabel")
                    unLbl.Size = UDim2.new(1, -120, 0, 13)
                    unLbl.Position = UDim2.new(0, 50, 0, 28)
                    unLbl.BackgroundTransparency = 1
                    unLbl.Text = "@" .. uname
                    unLbl.TextColor3 = Color3.fromRGB(120, 120, 130)
                    unLbl.TextSize = 9
                    unLbl.Font = Enum.Font.Gotham
                    unLbl.TextXAlignment = Enum.TextXAlignment.Left
                    unLbl.TextTruncate = Enum.TextTruncate.AtEnd
                    unLbl.ZIndex = 4
                    unLbl.Parent = card

                    tapConnect(cardHit, function()
                        flingBox.Text = uname
                        flingBoxText  = uname
                        TweenService:Create(card, TI.flash,   {BackgroundColor3 = Color3.fromRGB(30, 90, 55)}):Play()
                        task.delay(0.35, function()
                            TweenService:Create(card, TI.unflash, {BackgroundColor3 = Color3.fromRGB(16, 16, 20)}):Play()
                        end)
                    end)
                    connectBtn(cardHit,
                        function() TweenService:Create(card, TI.fast, {BackgroundTransparency = 0.3}):Play() end,
                        function() TweenService:Create(card, TI.fast, {BackgroundTransparency = 0.08}):Play() end
                    )

                    local loopPill = Instance.new("Frame")
                    loopPill.Size = UDim2.new(0, 46, 0, 22)
                    loopPill.Position = UDim2.new(1, -54, 0.5, -11)
                    loopPill.BackgroundColor3 = loopOn and Color3.fromRGB(40, 185, 90) or Color3.fromRGB(45, 45, 50)
                    loopPill.BorderSizePixel = 0
                    loopPill.ZIndex = 5
                    loopPill.Parent = card
                    Instance.new("UICorner", loopPill).CornerRadius = UDim.new(1, 0)
                    local pillStroke = Instance.new("UIStroke")
                    pillStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    pillStroke.Color = loopOn and Color3.fromRGB(60, 210, 110) or Color3.fromRGB(80, 80, 90)
                    pillStroke.Thickness = 0.5
                    pillStroke.Transparency = 0.5
                    pillStroke.Parent = loopPill

                    local loopDot = Instance.new("Frame")
                    loopDot.Size = UDim2.new(0, 15, 0, 15)
                    loopDot.Position = loopOn and UDim2.new(0, 28, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
                    loopDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    loopDot.BorderSizePixel = 0
                    loopDot.ZIndex = 6
                    loopDot.Parent = loopPill
                    Instance.new("UICorner", loopDot).CornerRadius = UDim.new(1, 0)

                    local loopLbl = Instance.new("TextLabel")
                    loopLbl.Size = UDim2.new(1, 0, 1, 0)
                    loopLbl.BackgroundTransparency = 1
                    loopLbl.Text = loopOn and "ON" or "OFF"
                    loopLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
                    loopLbl.TextSize = 8
                    loopLbl.Font = Enum.Font.GothamBold
                    loopLbl.TextXAlignment = loopOn and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right
                    loopLbl.ZIndex = 6
                    loopLbl.Parent = loopPill
                    local loopLblPad = Instance.new("UIPadding")
                    loopLblPad.PaddingLeft  = UDim.new(0, 5)
                    loopLblPad.PaddingRight = UDim.new(0, 5)
                    loopLblPad.Parent = loopLbl

                    local loopHitbox = Instance.new("TextButton")
                    loopHitbox.Size = UDim2.new(1, 0, 1, 0)
                    loopHitbox.BackgroundTransparency = 1
                    loopHitbox.Text = ""
                    loopHitbox.ZIndex = 7
                    loopHitbox.Parent = loopPill

                    tapConnect(loopHitbox, function()
                        loopOn = not loopOn
                        loopStates[uname] = loopOn
                        TweenService:Create(loopPill, TI.med, {
                            BackgroundColor3 = loopOn and Color3.fromRGB(40, 185, 90) or Color3.fromRGB(45, 45, 50)
                        }):Play()
                        TweenService:Create(pillStroke, TI.med, {
                            Color = loopOn and Color3.fromRGB(60, 210, 110) or Color3.fromRGB(80, 80, 90)
                        }):Play()
                        TweenService:Create(loopDot, TI.pillBounce, {
                            Position = loopOn and UDim2.new(0, 28, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
                        }):Play()
                        loopLbl.Text = loopOn and "ON" or "OFF"
                        loopLbl.TextXAlignment = loopOn and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right
                        if loopOn then startFlingPlayer(uname) else stopFlingPlayer(uname) end
                    end)
                end
            end

            buildPickerCards()
            rebuildFlingPicker = buildPickerCards

            Players.PlayerAdded:Connect(function()   task.defer(buildPickerCards) end)
            Players.PlayerRemoving:Connect(function(leftPlr)
                loopStates[leftPlr.Name] = nil
                task.defer(buildPickerCards)
            end)

            local pickerVisible = false
            local TI_SHEET_IN  = TweenInfo.new(0.38, Enum.EasingStyle.Back,  Enum.EasingDirection.Out)
            local TI_SHEET_OUT = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In)

            local function closePicker()
                if not pickerVisible then return end
                pickerVisible = false
                -- Always save position
                local p = sheet.Position
                savedPickerPos = { xs=p.X.Scale, xo=p.X.Offset, ys=p.Y.Scale, yo=p.Y.Offset }
                patchInfo({ picker_xs=p.X.Scale, picker_xo=p.X.Offset, picker_ys=p.Y.Scale, picker_yo=p.Y.Offset })
                -- Save size if saveWinSizes is on
                if saveWinSizes then
                    local sz = sheet.Size
                    savedPickerScale = { w=sz.X.Offset, h=sz.Y.Offset }
                    patchInfo({ picker_sw=sz.X.Offset, picker_sh=sz.Y.Offset })
                end
                TweenService:Create(sheet, TI_SHEET_OUT, {BackgroundTransparency = 1}):Play()
                task.delay(0.24, function()
                    pickerGui.Enabled = false
                    sheet.BackgroundTransparency = T.frameTrans
                end)
            end

            local function showPicker()
                if pickerVisible then return end
                pickerVisible = true
                pickerGui.Enabled = true
                buildPickerCards()
                -- Restore saved position if toggle on, otherwise center
                -- Restore saved size if toggle on
                if saveWinSizes and savedPickerScale then
                    sheet.Size = UDim2.new(0, savedPickerScale.w, 0, savedPickerScale.h)
                else
                    sheet.Size = UDim2.new(0, SHEET_W, 0, SHEET_H)
                end
                if savedPickerPos then
                    sheet.Position = UDim2.new(savedPickerPos.xs, savedPickerPos.xo, savedPickerPos.ys, savedPickerPos.yo)
                else
                    sheet.Position = UDim2.new(0.5, -sheet.Size.X.Offset/2, 0.5, -sheet.Size.Y.Offset/2)
                end
                sheet.BackgroundTransparency = 1
                TweenService:Create(sheet, TI_SHEET_IN, {BackgroundTransparency = T.frameTrans}):Play()
            end

            pickerGui.Enabled = false

            -- Browse Players button toggles the picker window
            tapConnect(browseBtn, function()
                if pickerVisible then
                    closePicker()
                else
                    showPicker()
                end
            end)
            tapConnect(sheetClose, closePicker)

            -- -- Resize handle (bottom-right corner of picker)
            local resizeHandle = Instance.new("TextButton")
            resizeHandle.Size                   = UDim2.new(0, 20, 0, 20)
            resizeHandle.Position               = UDim2.new(1, -20, 1, -20)
            resizeHandle.BackgroundColor3       = Color3.fromRGB(35, 35, 42)
            resizeHandle.BackgroundTransparency = 0.3
            resizeHandle.BorderSizePixel        = 0
            resizeHandle.Text                   = "//"
            resizeHandle.TextColor3             = Color3.fromRGB(180, 180, 190)
            resizeHandle.TextSize               = 10
            resizeHandle.Font                   = Enum.Font.GothamBold
            resizeHandle.AutoButtonColor        = false
            resizeHandle.ZIndex                 = 8
            resizeHandle.Parent                 = sheet
            Instance.new("UICorner", resizeHandle).CornerRadius = UDim.new(0, 5)
            connectBtn(resizeHandle,
                function() TweenService:Create(resizeHandle, TI.fast, {BackgroundTransparency = 0.05}):Play() end,
                function() TweenService:Create(resizeHandle, TI.fast, {BackgroundTransparency = 0.3}):Play() end
            )

            do
                local _rDragInp, _rStart, _rSzStart = nil, nil, nil
                resizeHandle.InputBegan:Connect(function(inp)
                    if inp.UserInputType ~= Enum.UserInputType.MouseButton1
                    and inp.UserInputType ~= Enum.UserInputType.Touch then return end
                    _rDragInp = inp
                    _rStart   = inp.Position
                    _rSzStart = sheet.Size
                end)
                UserInputService.InputChanged:Connect(function(inp)
                    if inp ~= _rDragInp then return end
                    local d = inp.Position - _rStart
                    local newW = math.max(200, _rSzStart.X.Offset + d.X)
                    local newH = math.max(180, _rSzStart.Y.Offset + d.Y)
                    sheet.Size = UDim2.new(0, newW, 0, newH)
                end)
                UserInputService.InputEnded:Connect(function(inp)
                    if inp ~= _rDragInp then return end
                    _rDragInp = nil
                    -- Auto-save size on resize if saveWinSizes is enabled
                    if saveWinSizes then
                        local sz = sheet.Size
                        savedPickerScale = { w=sz.X.Offset, h=sz.Y.Offset }
                        patchInfo({ picker_sw=sz.X.Offset, picker_sh=sz.Y.Offset })
                    end
                end)
            end
        end,
    },

    {
        name = "Player",
        iconType = "player",
        build = function(content)
            local sf = makeScrollList(content)
            makeStatInput(sf, "Walk Speed", "current: 16", 16, function(val)
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = val end
            end, function()
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                return hum and hum.WalkSpeed
            end)
            makeStatInput(sf, "JumpPower", "current: 50", 50, function(val)
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    if hum.UseJumpPower then
                        hum.JumpPower = val
                    else
                        hum.JumpHeight = val
                    end
                end
            end, function()
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if not hum then return nil end
                return hum.UseJumpPower and hum.JumpPower or hum.JumpHeight
            end)
        end,
    },
    {
        name = "Settings",
        iconType = "settings",
        build = function(content)
            local sf = makeScrollList(content)

            makeSection(sf, "Launcher")

            makeStatInput(sf, "Circle Size", "current: 44", 44, function(val)
                resizeLauncher(val)
            end, function()
                return savedLauncherSize
            end)

            makeToggle(sf, {
                name="Lock Position", hint="Prevents the icon from being dragged",
                default=savedLauncherLocked, state=savedLauncherLocked,
                enable=lockLauncher, disable=unlockLauncher,
            })

            makeButton(sf, {
                name="Save Position", hint="Saves current icon spot to info.txt",
                action=saveLauncherPosition,
            })

            local colorPresets = {
                { name="White",  col=Color3.fromRGB(255,255,255) },
                { name="Black",  col=Color3.fromRGB(30, 30, 30)  },
                { name="Purple", col=Color3.fromRGB(148,80,255)  },
                { name="Blue",   col=Color3.fromRGB(60, 140,255) },
                { name="Green",  col=Color3.fromRGB(60, 210,110) },
                { name="Red",    col=Color3.fromRGB(255,70, 70)  },
            }

            local swatchConns = {}
            local customRing  = nil
            local pickerOpen  = false

            local function colMatch(a, b)
                return math.abs(a.R-b.R)<0.01 and math.abs(a.G-b.G)<0.01 and math.abs(a.B-b.B)<0.01
            end
            local function isCustomColor()
                for _, p in ipairs(colorPresets) do
                    if colMatch(savedLauncherOutlineColor, p.col) then return false end
                end
                return true
            end

            makeSection(sf, "Outline")

            local colorRow = Instance.new("Frame")
            colorRow.Size = UDim2.new(1, -8, 0, 36)
            colorRow.BackgroundTransparency = 1
            colorRow.Parent = sf

            local colorLayout = Instance.new("UIListLayout")
            colorLayout.FillDirection = Enum.FillDirection.Horizontal
            colorLayout.SortOrder = Enum.SortOrder.LayoutOrder
            colorLayout.Padding = UDim.new(0, 4)
            colorLayout.VerticalAlignment = Enum.VerticalAlignment.Center
            colorLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
            colorLayout.Parent = colorRow

            local nPresets = #colorPresets
            local nAll     = nPresets + 1
            local swatchW = UDim2.new(1/nAll, -4, 1, -6)

            local PAD     = 8
            local PW      = 150
            local SH      = 108
            local HH      = 14
            local RW      = 44
            local PANEL_H = PAD + SH + 6 + HH + PAD

            local pickerRow = Instance.new("Frame")
            pickerRow.Size = UDim2.new(1, -8, 0, PANEL_H)
            pickerRow.BackgroundColor3 = T.rowBg
            pickerRow.BackgroundTransparency = T.rowTrans
            pickerRow.BorderSizePixel = 0
            pickerRow.Visible = false
            pickerRow.ClipsDescendants = false
            pickerRow.Parent = sf
            Instance.new("UICorner", pickerRow).CornerRadius = UDim.new(0, 10)

            local curH, curS, curV = savedLauncherOutlineColor:ToHSV()

            local svFrame = Instance.new("Frame")
            svFrame.Size = UDim2.new(0, PW, 0, SH)
            svFrame.Position = UDim2.new(0, PAD, 0, PAD)
            svFrame.BackgroundColor3 = Color3.fromHSV(curH, 1, 1)
            svFrame.BorderSizePixel = 0
            svFrame.ClipsDescendants = true
            svFrame.Parent = pickerRow
            Instance.new("UICorner", svFrame).CornerRadius = UDim.new(0, 6)

            local svWhite = Instance.new("Frame")
            svWhite.Size = UDim2.new(1, 0, 1, 0)
            svWhite.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            svWhite.BorderSizePixel = 0
            svWhite.Parent = svFrame
            local svWhiteGrad = Instance.new("UIGradient")
            svWhiteGrad.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(1, 1),
            })
            svWhiteGrad.Rotation = 0
            svWhiteGrad.Parent = svWhite

            local svBlack = Instance.new("Frame")
            svBlack.Size = UDim2.new(1, 0, 1, 0)
            svBlack.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            svBlack.BorderSizePixel = 0
            svBlack.Parent = svFrame
            local svBlackGrad = Instance.new("UIGradient")
            svBlackGrad.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(1, 0),
            })
            svBlackGrad.Rotation = 90
            svBlackGrad.Parent = svBlack

            local svDot = Instance.new("Frame")
            svDot.Size = UDim2.new(0, 12, 0, 12)
            svDot.AnchorPoint = Vector2.new(0.5, 0.5)
            svDot.Position = UDim2.new(0, PAD + curS * PW, 0, PAD + (1 - curV) * SH)
            svDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            svDot.BorderSizePixel = 0
            svDot.ZIndex = 4
            svDot.Parent = pickerRow
            Instance.new("UICorner", svDot).CornerRadius = UDim.new(1, 0)
            local svDotStroke = Instance.new("UIStroke")
            svDotStroke.Color = Color3.fromRGB(0, 0, 0)
            svDotStroke.Thickness = 1.5
            svDotStroke.Parent = svDot

            local hueBar = Instance.new("Frame")
            hueBar.Size = UDim2.new(0, PW, 0, HH)
            hueBar.Position = UDim2.new(0, PAD, 0, PAD + SH + 6)
            hueBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            hueBar.BorderSizePixel = 0
            hueBar.Parent = pickerRow
            Instance.new("UICorner", hueBar).CornerRadius = UDim.new(0, 4)

            local hueGrad = Instance.new("UIGradient")
            hueGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0,      Color3.fromRGB(255, 0,   0)),
                ColorSequenceKeypoint.new(1/6,    Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(2/6,    Color3.fromRGB(0,   255, 0)),
                ColorSequenceKeypoint.new(0.5,    Color3.fromRGB(0,   255, 255)),
                ColorSequenceKeypoint.new(4/6,    Color3.fromRGB(0,   0,   255)),
                ColorSequenceKeypoint.new(5/6,    Color3.fromRGB(255, 0,   255)),
                ColorSequenceKeypoint.new(1,      Color3.fromRGB(255, 0,   0)),
            })
            hueGrad.Parent = hueBar

            local hueInd = Instance.new("Frame")
            hueInd.Size = UDim2.new(0, 4, 0, HH + 4)
            hueInd.AnchorPoint = Vector2.new(0.5, 0.5)
            hueInd.Position = UDim2.new(0, PAD + curH * PW, 0, PAD + SH + 6 + HH / 2)
            hueInd.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            hueInd.BorderSizePixel = 0
            hueInd.ZIndex = 4
            hueInd.Parent = pickerRow
            Instance.new("UICorner", hueInd).CornerRadius = UDim.new(0, 2)
            local hueIndStroke = Instance.new("UIStroke")
            hueIndStroke.Color = Color3.fromRGB(0, 0, 0)
            hueIndStroke.Thickness = 1
            hueIndStroke.Parent = hueInd

            local prevCircle = Instance.new("Frame")
            prevCircle.Size = UDim2.new(0, RW, 0, RW)
            prevCircle.Position = UDim2.new(1, -(PAD + RW), 0, PAD)
            prevCircle.BackgroundColor3 = savedLauncherOutlineColor
            prevCircle.BorderSizePixel = 0
            prevCircle.Parent = pickerRow
            Instance.new("UICorner", prevCircle).CornerRadius = UDim.new(1, 0)

            local applyBtn = Instance.new("TextButton")
            applyBtn.Size = UDim2.new(0, RW, 0, 28)
            applyBtn.Position = UDim2.new(1, -(PAD + RW), 0, PAD + RW + 6)
            applyBtn.BackgroundColor3 = T.saveBg
            applyBtn.BorderSizePixel = 0
            applyBtn.Text = "Apply"
            applyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            applyBtn.TextSize = 10
            applyBtn.Font = Enum.Font.GothamBold
            applyBtn.AutoButtonColor = false
            applyBtn.Parent = pickerRow
            Instance.new("UICorner", applyBtn).CornerRadius = UDim.new(0, 7)

            local function syncPickerUI()
                svFrame.BackgroundColor3 = Color3.fromHSV(curH, 1, 1)
                svDot.Position  = UDim2.new(0, PAD + curS * PW, 0, PAD + (1 - curV) * SH)
                hueInd.Position = UDim2.new(0, PAD + curH * PW, 0, PAD + SH + 6 + HH / 2)
                prevCircle.BackgroundColor3 = Color3.fromHSV(curH, curS, curV)
            end

            local svDragInp  = nil
            local hueDragInp = nil

            svFrame.InputBegan:Connect(function(inp)
                if inp.UserInputType ~= Enum.UserInputType.MouseButton1
                and inp.UserInputType ~= Enum.UserInputType.Touch then return end
                if hueDragInp then return end
                svDragInp = inp
                sf.ScrollingEnabled = false
                local ap = svFrame.AbsolutePosition
                local as = svFrame.AbsoluteSize
                curS = math.clamp((inp.Position.X - ap.X) / as.X, 0, 1)
                curV = math.clamp(1 - (inp.Position.Y - ap.Y) / as.Y, 0, 1)
                syncPickerUI()
            end)
            local svMoveConn = UserInputService.InputChanged:Connect(function(inp)
                pcall(function()
                if inp ~= svDragInp then return end
                local ap = svFrame.AbsolutePosition
                local as = svFrame.AbsoluteSize
                curS = math.clamp((inp.Position.X - ap.X) / as.X, 0, 1)
                curV = math.clamp(1 - (inp.Position.Y - ap.Y) / as.Y, 0, 1)
                syncPickerUI()
                end)
            end)
            local svEndConn = UserInputService.InputEnded:Connect(function(inp)
                pcall(function()
                if inp ~= svDragInp then return end
                svDragInp = nil
                if not hueDragInp then sf.ScrollingEnabled = true end
                end)
            end)
            swatchConns[#swatchConns+1] = svMoveConn
            swatchConns[#swatchConns+1] = svEndConn

            hueBar.InputBegan:Connect(function(inp)
                if inp.UserInputType ~= Enum.UserInputType.MouseButton1
                and inp.UserInputType ~= Enum.UserInputType.Touch then return end
                if svDragInp then return end
                hueDragInp = inp
                sf.ScrollingEnabled = false
                local ap = hueBar.AbsolutePosition
                local as = hueBar.AbsoluteSize
                curH = math.clamp((inp.Position.X - ap.X) / as.X, 0, 1)
                syncPickerUI()
            end)
            local hueMoveConn = UserInputService.InputChanged:Connect(function(inp)
                pcall(function()
                if inp ~= hueDragInp then return end
                local ap = hueBar.AbsolutePosition
                local as = hueBar.AbsoluteSize
                curH = math.clamp((inp.Position.X - ap.X) / as.X, 0, 1)
                syncPickerUI()
                end)
            end)
            local hueEndConn = UserInputService.InputEnded:Connect(function(inp)
                pcall(function()
                if inp ~= hueDragInp then return end
                hueDragInp = nil
                if not svDragInp then sf.ScrollingEnabled = true end
                end)
            end)
            swatchConns[#swatchConns+1] = hueMoveConn
            swatchConns[#swatchConns+1] = hueEndConn

            local COL_APL_OK = Color3.fromRGB(50, 200, 100)
            tapConnect(applyBtn, function()
                local newCol = Color3.fromHSV(curH, curS, curV)
                savedCustomOutlineColor = newCol
                local r, g, b = math.round(newCol.R*255), math.round(newCol.G*255), math.round(newCol.B*255)
                patchInfo({ custom_r = r, custom_g = g, custom_b = b })
                plusSwatch.BackgroundColor3 = newCol
                recolorOutline(newCol)
                if customRing then customRing.Transparency = 0 end
                TweenService:Create(applyBtn, TI.flash,   {BackgroundColor3 = COL_APL_OK}):Play()
                task.delay(0.5, function()
                    TweenService:Create(applyBtn, TI.unflash, {BackgroundColor3 = T.saveBg}):Play()
                end)
            end)
            applyBtn.MouseEnter:Connect(function() TweenService:Create(applyBtn, TI.fast, {BackgroundColor3=T.saveHov}):Play() end)
            applyBtn.MouseLeave:Connect(function() TweenService:Create(applyBtn, TI.fast, {BackgroundColor3=T.saveBg}):Play()  end)
            connectBtn(applyBtn,
                function() TweenService:Create(applyBtn, TI.fast, {BackgroundColor3=T.saveHov}):Play() end,
                function() TweenService:Create(applyBtn, TI.fast, {BackgroundColor3=T.saveBg}):Play()  end
            )

            local swatchActiveInp = nil

            for _, preset in ipairs(colorPresets) do
                local swatch = Instance.new("TextButton")
                swatch.Size = swatchW
                swatch.BackgroundColor3 = preset.col
                swatch.BorderSizePixel = 0
                swatch.Text = ""
                swatch.AutoButtonColor = false
                swatch.Parent = colorRow
                Instance.new("UICorner", swatch).CornerRadius = UDim.new(1, 0)

                local uiScale = Instance.new("UIScale")
                uiScale.Scale = 1
                uiScale.Parent = swatch

                local pCol         = preset.col
                local downInp      = nil
                local pressPos2    = nil
                local didScroll2   = false
                local moveConn2    = nil

                swatch.InputBegan:Connect(function(inp)
                    if inp.UserInputType ~= Enum.UserInputType.MouseButton1
                    and inp.UserInputType ~= Enum.UserInputType.Touch then return end
                    if svDragInp or hueDragInp then return end
                    if swatchActiveInp then return end
                    swatchActiveInp = inp
                    downInp     = inp
                    pressPos2   = Vector2.new(inp.Position.X, inp.Position.Y)
                    didScroll2  = false
                    if moveConn2 then moveConn2:Disconnect() end
                    moveConn2 = UserInputService.InputChanged:Connect(function(ch)
                        if ch ~= downInp then return end
                        if (Vector2.new(ch.Position.X, ch.Position.Y) - pressPos2).Magnitude > 10 then
                            didScroll2 = true
                        end
                    end)
                    TweenService:Create(uiScale, TI.dot, {Scale = 0.72}):Play()
                end)
                local upConn = UserInputService.InputEnded:Connect(function(inp)
                    if inp ~= downInp then return end
                    downInp = nil
                    if swatchActiveInp == inp then swatchActiveInp = nil end
                    if moveConn2 then moveConn2:Disconnect(); moveConn2 = nil end
                    TweenService:Create(uiScale, TI.dotBack, {Scale = 1}):Play()
                    if didScroll2 then return end
                    recolorOutline(pCol)
                    if pickerOpen then pickerOpen = false; pickerRow.Visible = false end
                    if customRing then customRing.Transparency = 1 end
                end)
                swatchConns[#swatchConns+1] = upConn
            end

            local plusSwatch = Instance.new("TextButton")
            plusSwatch.Size = swatchW
            plusSwatch.BackgroundColor3 = savedCustomOutlineColor or T.tabBg
            plusSwatch.BorderSizePixel = 0
            plusSwatch.Text = savedCustomOutlineColor and "" or "+"
            plusSwatch.TextColor3 = T.rowLbl
            plusSwatch.TextSize = 14
            plusSwatch.Font = Enum.Font.GothamBold
            plusSwatch.AutoButtonColor = false
            plusSwatch.Parent = colorRow
            Instance.new("UICorner", plusSwatch).CornerRadius = UDim.new(1, 0)

            local plusScale = Instance.new("UIScale")
            plusScale.Scale = 1
            plusScale.Parent = plusSwatch

            customRing = Instance.new("UIStroke")
            customRing.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            customRing.Thickness    = 2.5
            customRing.Color        = Color3.fromRGB(255, 255, 255)
            customRing.Transparency = isCustomColor() and 0 or 1
            customRing.Parent       = plusSwatch

            local plusDownInp   = nil
            local plusPressPos  = nil
            local plusDidScroll = false
            local plusMoveConn  = nil
            plusSwatch.InputBegan:Connect(function(inp)
                if inp.UserInputType ~= Enum.UserInputType.MouseButton1
                and inp.UserInputType ~= Enum.UserInputType.Touch then return end
                if svDragInp or hueDragInp then return end
                if swatchActiveInp then return end
                swatchActiveInp = inp
                plusDownInp   = inp
                plusPressPos  = Vector2.new(inp.Position.X, inp.Position.Y)
                plusDidScroll = false
                if plusMoveConn then plusMoveConn:Disconnect() end
                plusMoveConn = UserInputService.InputChanged:Connect(function(ch)
                    if ch ~= plusDownInp then return end
                    if (Vector2.new(ch.Position.X, ch.Position.Y) - plusPressPos).Magnitude > 10 then
                        plusDidScroll = true
                    end
                end)
                TweenService:Create(plusScale, TI.dot, {Scale = 0.72}):Play()
            end)
            local plusUpConn = UserInputService.InputEnded:Connect(function(inp)
                if inp ~= plusDownInp then return end
                plusDownInp = nil
                if swatchActiveInp == inp then swatchActiveInp = nil end
                if plusMoveConn then plusMoveConn:Disconnect(); plusMoveConn = nil end
                TweenService:Create(plusScale, TI.dotBack, {Scale = 1}):Play()
                if plusDidScroll then return end
                pickerOpen = not pickerOpen
                pickerRow.Visible = pickerOpen
                if pickerOpen then
                    curH, curS, curV = savedLauncherOutlineColor:ToHSV()
                    syncPickerUI()
                end
            end)
            swatchConns[#swatchConns+1] = plusUpConn

            colorRow.AncestryChanged:Connect(function()
                if not colorRow.Parent then
                    for _, c in ipairs(swatchConns) do c:Disconnect() end
                    pcall(function() sf.ScrollingEnabled = true end)
                end
            end)

            makeSection(sf, "Display")

            local function enableRescale()
                local handle = Instance.new("TextButton")
                handle.Size = UDim2.new(0, 24, 0, 24)
                handle.Position = UDim2.new(1, -24, 1, -24)
                handle.BackgroundColor3 = T.handleBg
                handle.BackgroundTransparency = 0.25
                handle.Text = "//"
                handle.TextColor3 = Color3.fromRGB(255, 255, 255)
                handle.TextSize = 11
                handle.Font = Enum.Font.GothamBold
                handle.AutoButtonColor = false
                handle.ZIndex = 10
                handle.Parent = activeFrame
                Instance.new("UICorner", handle).CornerRadius = UDim.new(0, 6)
                activeResizeHandle = handle

                local dragging, dragStartPos, dragStartSz = false, nil, nil

                handle.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        dragStartPos = input.Position
                        dragStartSz  = activeFrame.Size
                    end
                end)
                activeResizeConn1 = UserInputService.InputChanged:Connect(function(input)
                    if not dragging then return end
                    if input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch then
                        local delta = input.Position - dragStartPos
                        activeFrame.Size = UDim2.new(0, math.max(240, dragStartSz.X.Offset+delta.X),
                                                        0, math.max(200, dragStartSz.Y.Offset+delta.Y))
                    end
                end)
                activeResizeConn2 = UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                    end
                end)

                activeSaveGui = Instance.new("ScreenGui")
                activeSaveGui.Name = "LuwaScriptSaveBtn"
                activeSaveGui.ResetOnSpawn = false
                activeSaveGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
                activeSaveGui.Parent = LocalPlayer.PlayerGui

                local COL_SAVE     = T.saveBg
                local COL_SAVE_HOV = T.saveHov
                local COL_SAVE_OK  = Color3.fromRGB(50, 200, 100)

                local saveBtn = Instance.new("TextButton")
                saveBtn.AnchorPoint = Vector2.new(1, 0)
                saveBtn.Position = UDim2.new(1, -14, 0, 14)
                saveBtn.Size = UDim2.new(0.08, 0, 0.06, 0)
                saveBtn.BackgroundColor3 = COL_SAVE
                saveBtn.BorderSizePixel = 0
                saveBtn.Text = "Save"
                saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                saveBtn.TextSize = 16
                saveBtn.Font = Enum.Font.GothamBold
                saveBtn.AutoButtonColor = false
                saveBtn.Parent = activeSaveGui
                Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 12)
                local sc = Instance.new("UISizeConstraint")
                sc.MinSize = Vector2.new(72, 38); sc.MaxSize = Vector2.new(110, 54)
                sc.Parent = saveBtn

                tapConnect(saveBtn, function()
                    local sz = activeFrame.Size
                    savedFrameSize = sz
                    patchInfo({ scale_w=sz.X.Offset, scale_h=sz.Y.Offset })
                    TweenService:Create(saveBtn, TI.flash,   {BackgroundColor3=COL_SAVE_OK}):Play()
                    task.delay(0.6, function()
                        if saveBtn and saveBtn.Parent then
                            TweenService:Create(saveBtn, TI.unflash, {BackgroundColor3=COL_SAVE}):Play()
                        end
                    end)
                end)
                saveBtn.MouseEnter:Connect(function() TweenService:Create(saveBtn, TI.fast, {BackgroundColor3=COL_SAVE_HOV}):Play() end)
                saveBtn.MouseLeave:Connect(function() TweenService:Create(saveBtn, TI.fast, {BackgroundColor3=COL_SAVE}):Play()     end)
                connectBtn(saveBtn,
                    function() TweenService:Create(saveBtn, TI.fast, {BackgroundColor3=COL_SAVE_HOV}):Play() end,
                    function() TweenService:Create(saveBtn, TI.fast, {BackgroundColor3=COL_SAVE}):Play()     end
                )
            end

            local function disableRescale()
                cleanupResize()
                if activeFrame then
                    TweenService:Create(activeFrame, TI.slow, {Size=savedFrameSize or DEFAULT_SIZE}):Play()
                end
            end

            local toggleHandle = makeToggle(sf, {
                name="UI Rescale", hint="Drag corner handle to resize, tap Save to keep",
                default=false, state=false, enable=enableRescale, disable=disableRescale,
            })
            rescaleForceOff = toggleHandle.forceOff

            local resetCntr = Instance.new("Frame")
            resetCntr.Size = UDim2.new(1, -8, 0, 38)
            resetCntr.BackgroundTransparency = 1
            resetCntr.Parent = sf

            local COL_RST     = T.rstBg
            local COL_RST_HOV = T.rstHov
            local COL_RST_OK  = Color3.fromRGB(50, 185, 85)
            local RST_SZ_SQ   = UDim2.new(1, -14, 0, 32)
            local RST_SZ_NRM  = UDim2.new(1, -8,  0, 38)

            local resetBtn = Instance.new("TextButton")
            resetBtn.Size = UDim2.new(1, 0, 1, 0)
            resetBtn.BackgroundColor3 = COL_RST
            resetBtn.BorderSizePixel = 0
            resetBtn.Text = "Reset Scale"
            resetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            resetBtn.TextSize = 12
            resetBtn.Font = Enum.Font.GothamSemibold
            resetBtn.AutoButtonColor = false
            resetBtn.Parent = resetCntr
            Instance.new("UICorner", resetBtn).CornerRadius = UDim.new(0, 10)

            tapConnect(resetBtn, function()
                TweenService:Create(resetCntr, TI.squish1, {Size=RST_SZ_SQ}):Play()
                task.delay(0.08, function() TweenService:Create(resetCntr, TI.squish2, {Size=RST_SZ_NRM}):Play() end)
                resetScale(true)
                TweenService:Create(resetBtn, TI.flash,   {BackgroundColor3=COL_RST_OK}):Play()
                task.delay(0.5, function() TweenService:Create(resetBtn, TI.unflash, {BackgroundColor3=COL_RST}):Play() end)
            end)
            resetBtn.MouseEnter:Connect(function() TweenService:Create(resetBtn, TI.fast, {BackgroundColor3=COL_RST_HOV}):Play() end)
            resetBtn.MouseLeave:Connect(function() TweenService:Create(resetBtn, TI.fast, {BackgroundColor3=COL_RST}):Play()     end)
            connectBtn(resetBtn,
                function() TweenService:Create(resetBtn, TI.fast, {BackgroundColor3=COL_RST_HOV}):Play() end,
                function() TweenService:Create(resetBtn, TI.fast, {BackgroundColor3=COL_RST}):Play()     end
            )

            makeToggle(sf, {
                name  = "Save Window Sizes",
                hint  = "Remembers sizes of resizable windows",
                default = saveWinSizes,
                state   = saveWinSizes,
                enable  = function()
                    saveWinSizes = true
                    patchInfo({ save_win_sizes = "true" })
                end,
                disable = function()
                    saveWinSizes = false
                    savedPickerScale  = nil
                    savedProfileScale = nil
                    patchInfo({ save_win_sizes = "false", picker_sw=DELETE, picker_sh=DELETE, profile_sw=DELETE, profile_sh=DELETE })
                end,
            })

        end,
    },
    {
        name = "Console",
        iconType = "console",
        build = function(content)
            local logConn  = nil
            local allLogs  = {}

            local TYPES = {
                { key="Output", mt=Enum.MessageType.MessageOutput,  col=Color3.fromRGB(210,210,215), tag="OUT"  },
                { key="Info",   mt=Enum.MessageType.MessageInfo,    col=Color3.fromRGB(100,180,255), tag="INF"  },
                { key="Warn",   mt=Enum.MessageType.MessageWarning, col=Color3.fromRGB(255,200, 60), tag="WRN"  },
                { key="Error",  mt=Enum.MessageType.MessageError,   col=Color3.fromRGB(255, 80, 80), tag="ERR"  },
            }
            local typeMap = {}
            for _, t in ipairs(TYPES) do typeMap[t.mt] = t end

            local filters = { Output=true, Info=true, Warn=true, Error=true }

            local filterBar = Instance.new("Frame")
            filterBar.Size = UDim2.new(1, 0, 0, 20)
            filterBar.BackgroundTransparency = 1
            filterBar.BorderSizePixel = 0
            filterBar.Parent = content
            local fbl = Instance.new("UIListLayout")
            fbl.FillDirection = Enum.FillDirection.Horizontal
            fbl.Padding = UDim.new(0, 3)
            fbl.SortOrder = Enum.SortOrder.LayoutOrder
            fbl.Parent = filterBar
            local fbPad = Instance.new("UIPadding")
            fbPad.PaddingLeft = UDim.new(0, 2)
            fbPad.Parent = filterBar

            local sf = Instance.new("ScrollingFrame")
            sf.Size = UDim2.new(1, 0, 1, -46)
            sf.Position = UDim2.new(0, 0, 0, 22)
            sf.BackgroundTransparency = 1
            sf.BorderSizePixel = 0
            sf.ScrollBarThickness = 2
            sf.ScrollBarImageColor3 = T.scrollBar
            sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
            sf.CanvasSize = UDim2.new(0, 0, 0, 0)
            sf.Parent = content
            local ll = Instance.new("UIListLayout")
            ll.SortOrder = Enum.SortOrder.LayoutOrder
            ll.Padding = UDim.new(0, 1)
            ll.Parent = sf
            local pad = Instance.new("UIPadding")
            pad.PaddingLeft   = UDim.new(0, 2)
            pad.PaddingRight  = UDim.new(0, 2)
            pad.PaddingBottom = UDim.new(0, 2)
            pad.Parent = sf

            local function timestamp()
                local ok, s = pcall(function()
                    return DateTime.now():FormatLocalTime("HH:mm:ss", "en-us")
                end)
                if ok then return s end
                if os.date then return os.date("%H:%M:%S") end
                local t = os.time()
                return string.format("%02d:%02d:%02d", math.floor(t/3600)%24, math.floor(t/60)%60, t%60)
            end

            local function scrollToBottom()
                task.defer(function()
                    if sf and sf.Parent then
                        sf.CanvasPosition = Vector2.new(0, sf.AbsoluteCanvasSize.Y)
                    end
                end)
            end

            local popupActive = false
            local function showCopyPopup(fullLine)
                if popupActive then return end
                popupActive = true

                local mainFrame = content.Parent

                local dim = Instance.new("Frame")
                dim.Size = UDim2.new(1, 0, 1, 0)
                dim.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                dim.BackgroundTransparency = 1
                dim.BorderSizePixel = 0
                dim.ZIndex = 40
                dim.Parent = mainFrame
                Instance.new("UICorner", dim).CornerRadius = UDim.new(0, 20)
                TweenService:Create(dim, TI.med, {BackgroundTransparency = 0.55}):Play()

                local panel = Instance.new("Frame")
                panel.Size = UDim2.new(0.82, 0, 0, 110)
                panel.Position = UDim2.new(0.09, 0, 0.5, -35)
                panel.BackgroundColor3 = Color3.fromRGB(14, 14, 17)
                panel.BackgroundTransparency = 1
                panel.BorderSizePixel = 0
                panel.ZIndex = 41
                panel.Parent = mainFrame
                Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)
                local panelStroke = Instance.new("UIStroke")
                panelStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                panelStroke.Color = Color3.fromRGB(255, 255, 255)
                panelStroke.Thickness = 0.6
                panelStroke.Transparency = 1
                panelStroke.Parent = panel
                local panelScale = Instance.new("UIScale")
                panelScale.Scale = 0.82
                panelScale.Parent = panel

                TweenService:Create(panel, TI.slow, {BackgroundTransparency = 0.05, Position = UDim2.new(0.09, 0, 0.5, -55)}):Play()
                TweenService:Create(panelScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
                TweenService:Create(panelStroke, TI.slow, {Transparency = 0.6}):Play()

                local headLbl = Instance.new("TextLabel")
                headLbl.Size = UDim2.new(1, -16, 0, 16)
                headLbl.Position = UDim2.new(0, 8, 0, 10)
                headLbl.BackgroundTransparency = 1
                headLbl.Text = "Copy this line?"
                headLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
                headLbl.TextTransparency = 1
                headLbl.TextSize = 11
                headLbl.Font = Enum.Font.GothamBold
                headLbl.TextXAlignment = Enum.TextXAlignment.Left
                headLbl.ZIndex = 42
                headLbl.Parent = panel
                TweenService:Create(headLbl, TI.slow, {TextTransparency = 0}):Play()

                local previewBox = Instance.new("Frame")
                previewBox.Size = UDim2.new(1, -16, 0, 38)
                previewBox.Position = UDim2.new(0, 8, 0, 32)
                previewBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                previewBox.BackgroundTransparency = 1
                previewBox.BorderSizePixel = 0
                previewBox.ZIndex = 42
                previewBox.Parent = panel
                Instance.new("UICorner", previewBox).CornerRadius = UDim.new(0, 6)
                local previewStroke = Instance.new("UIStroke")
                previewStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                previewStroke.Color = Color3.fromRGB(255, 255, 255)
                previewStroke.Thickness = 0.5
                previewStroke.Transparency = 1
                previewStroke.Parent = previewBox
                TweenService:Create(previewBox,    TI.slow, {BackgroundTransparency = 0.55}):Play()
                TweenService:Create(previewStroke, TI.slow, {Transparency = 0.75}):Play()

                local previewLbl = Instance.new("TextLabel")
                previewLbl.Size = UDim2.new(1, -10, 1, -4)
                previewLbl.Position = UDim2.new(0, 5, 0, 2)
                previewLbl.BackgroundTransparency = 1
                previewLbl.Text = fullLine
                previewLbl.TextColor3 = Color3.fromRGB(180, 180, 190)
                previewLbl.TextTransparency = 1
                previewLbl.TextSize = 9
                previewLbl.Font = Enum.Font.Code
                previewLbl.TextXAlignment = Enum.TextXAlignment.Left
                previewLbl.TextWrapped = true
                previewLbl.ZIndex = 43
                previewLbl.Parent = previewBox
                TweenService:Create(previewLbl, TI.slow, {TextTransparency = 0}):Play()

                local function makePopBtn(txt, xScale, xOff, bgCol)
                    local b = Instance.new("TextButton")
                    b.Size = UDim2.new(0.44, 0, 0, 24)
                    b.Position = UDim2.new(xScale, xOff, 0, 80)
                    b.BackgroundColor3 = bgCol
                    b.BackgroundTransparency = 1
                    b.BorderSizePixel = 0
                    b.Text = txt
                    b.TextColor3 = Color3.fromRGB(255, 255, 255)
                    b.TextTransparency = 1
                    b.TextSize = 10
                    b.Font = Enum.Font.GothamSemibold
                    b.AutoButtonColor = false
                    b.ZIndex = 42
                    b.Parent = panel
                    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
                    local bs = Instance.new("UIStroke")
                    bs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    bs.Color = Color3.fromRGB(255, 255, 255)
                    bs.Thickness = 0.5
                    bs.Transparency = 1
                    bs.Parent = b
                    TweenService:Create(b,  TI.slow, {BackgroundTransparency = 0.15, TextTransparency = 0}):Play()
                    TweenService:Create(bs, TI.slow, {Transparency = 0.7}):Play()
                    return b, bs
                end

                local cancelBtn,  cancelStroke  = makePopBtn("Cancel", 0.05, 0, Color3.fromRGB(40, 40, 45))
                local confirmBtn, confirmStroke = makePopBtn("Copy",   0.51, 0, Color3.fromRGB(30, 110, 60))

                local function closePopup()
                    local di = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
                    TweenService:Create(dim,           di, {BackgroundTransparency = 1}):Play()
                    TweenService:Create(panel,         di, {BackgroundTransparency = 1, Position = UDim2.new(0.09, 0, 0.5, -45)}):Play()
                    TweenService:Create(panelScale,    di, {Scale = 0.88}):Play()
                    TweenService:Create(panelStroke,   di, {Transparency = 1}):Play()
                    TweenService:Create(headLbl,       di, {TextTransparency = 1}):Play()
                    TweenService:Create(previewBox,    di, {BackgroundTransparency = 1}):Play()
                    TweenService:Create(previewStroke, di, {Transparency = 1}):Play()
                    TweenService:Create(previewLbl,    di, {TextTransparency = 1}):Play()
                    TweenService:Create(cancelBtn,     di, {BackgroundTransparency = 1, TextTransparency = 1}):Play()
                    TweenService:Create(cancelStroke,  di, {Transparency = 1}):Play()
                    TweenService:Create(confirmBtn,    di, {BackgroundTransparency = 1, TextTransparency = 1}):Play()
                    TweenService:Create(confirmStroke, di, {Transparency = 1}):Play()
                    task.delay(0.2, function()
                        pcall(function() dim:Destroy() end)
                        pcall(function() panel:Destroy() end)
                        popupActive = false
                    end)
                end

                local function wireBtn(btn, action)
                    local active = nil
                    btn.InputBegan:Connect(function(inp)
                        if inp.UserInputType ~= Enum.UserInputType.MouseButton1
                        and inp.UserInputType ~= Enum.UserInputType.Touch then return end
                        active = inp
                        TweenService:Create(btn, TI.fast, {BackgroundTransparency = 0.4}):Play()
                    end)
                    UserInputService.InputEnded:Connect(function(inp)
                        if inp ~= active then return end
                        active = nil
                        TweenService:Create(btn, TI.fast, {BackgroundTransparency = 0.15}):Play()
                        pcall(action)
                    end)
                end

                wireBtn(cancelBtn,  function() closePopup() end)
                wireBtn(confirmBtn, function()
                    pcall(function() setclipboard(fullLine) end)
                    closePopup()
                end)
            end

            local function makeRow(entry, info)
                local fullLine = "[" .. info.tag .. "] " .. entry.time .. "  " .. entry.msg

                local row = Instance.new("TextButton")
                row.Size = UDim2.new(1, 0, 0, 0)
                row.AutomaticSize = Enum.AutomaticSize.Y
                row.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                row.BackgroundTransparency = 1
                row.BorderSizePixel = 0
                row.Text = ""
                row.AutoButtonColor = false
                row.Parent = sf

                local tagLbl = Instance.new("TextLabel")
                tagLbl.Size = UDim2.new(0, 72, 0, 14)
                tagLbl.BackgroundTransparency = 1
                tagLbl.Text = "[" .. info.tag .. "] " .. entry.time
                tagLbl.TextColor3 = info.col
                tagLbl.TextSize = 9
                tagLbl.Font = Enum.Font.Code
                tagLbl.TextXAlignment = Enum.TextXAlignment.Left
                tagLbl.ZIndex = row.ZIndex + 1
                tagLbl.Parent = row

                local msgLbl = Instance.new("TextLabel")
                msgLbl.Size = UDim2.new(1, -74, 0, 0)
                msgLbl.Position = UDim2.new(0, 74, 0, 0)
                msgLbl.AutomaticSize = Enum.AutomaticSize.Y
                msgLbl.BackgroundTransparency = 1
                msgLbl.Text = entry.msg
                msgLbl.TextColor3 = info.col
                msgLbl.TextSize = 10
                msgLbl.Font = Enum.Font.Code
                msgLbl.TextXAlignment = Enum.TextXAlignment.Left
                msgLbl.TextWrapped = true
                msgLbl.ZIndex = row.ZIndex + 1
                msgLbl.Parent = row

                local rowActive = nil
                local rowPressPos = nil
                local rowMoved = false
                local rowMoveConn = nil

                row.InputBegan:Connect(function(inp)
                    if inp.UserInputType ~= Enum.UserInputType.MouseButton1
                    and inp.UserInputType ~= Enum.UserInputType.Touch then return end
                    rowActive = inp
                    rowPressPos = Vector2.new(inp.Position.X, inp.Position.Y)
                    rowMoved = false
                    if rowMoveConn then rowMoveConn:Disconnect() end
                    rowMoveConn = UserInputService.InputChanged:Connect(function(ch)
                        if ch ~= rowActive then return end
                        if rowMoved then return end
                        if (Vector2.new(ch.Position.X, ch.Position.Y) - rowPressPos).Magnitude > 8 then
                            rowMoved = true
                            TweenService:Create(row, TI.unflash, {BackgroundTransparency = 1}):Play()
                        end
                    end)
                    if not rowMoved then
                        TweenService:Create(row, TI.flash, {BackgroundTransparency = 0.88}):Play()
                    end
                end)

                UserInputService.InputEnded:Connect(function(inp)
                    if inp ~= rowActive then return end
                    rowActive = nil
                    if rowMoveConn then rowMoveConn:Disconnect(); rowMoveConn = nil end
                    TweenService:Create(row, TI.unflash, {BackgroundTransparency = 1}):Play()
                    if not rowMoved then
                        showCopyPopup(fullLine)
                    end
                    rowMoved = false
                end)

                return row
            end

            local function rebuildVisible()
                for _, c in ipairs(sf:GetChildren()) do
                    if c:IsA("TextButton") or c:IsA("Frame") then c:Destroy() end
                end
                for _, entry in ipairs(allLogs) do
                    local info = typeMap[entry.mt]
                    if info and filters[info.key] then
                        makeRow(entry, info)
                    end
                end
            end

            for _, t in ipairs(TYPES) do
                local fb = Instance.new("TextButton")
                fb.Size = UDim2.new(0, 40, 0, 16)
                fb.BackgroundColor3 = t.col
                fb.BackgroundTransparency = 0.0
                fb.BorderSizePixel = 0
                fb.Text = t.key
                fb.TextColor3 = Color3.fromRGB(10, 10, 12)
                fb.TextSize = 8
                fb.Font = Enum.Font.GothamBold
                fb.AutoButtonColor = false
                fb.Parent = filterBar
                Instance.new("UICorner", fb).CornerRadius = UDim.new(0, 4)

                tapConnect(fb, function()
                    filters[t.key] = not filters[t.key]
                    fb.BackgroundTransparency = filters[t.key] and 0.0 or 0.75
                    fb.TextColor3 = filters[t.key] and Color3.fromRGB(10,10,12) or t.col
                    rebuildVisible()
                end)
            end

            local function addEntry(msg, mt)
                local ts = timestamp()
                local entry = { msg=tostring(msg), mt=mt, time=ts }
                allLogs[#allLogs+1] = entry
                local info = typeMap[mt]
                if not info then return end
                if filters[info.key] then
                    makeRow(entry, info)
                    scrollToBottom()
                end
            end

            pcall(function()
                local LogService = game:GetService("LogService")
                for _, entry in ipairs(LogService:GetLogHistory()) do
                    addEntry(entry.message, entry.messageType)
                end
                logConn = LogService.MessageOut:Connect(function(msg, mt)
                    if content and content.Parent then addEntry(msg, mt) end
                end)
            end)

            local BTN_SZ = 20

            local function makeNavBtn(icon, xPos)
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(0, BTN_SZ, 0, BTN_SZ)
                btn.Position = UDim2.new(1, xPos, 1, -BTN_SZ - 3)
                btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                btn.BackgroundTransparency = 0.6
                btn.BorderSizePixel = 0
                btn.Text = icon
                btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                btn.TextSize = 10
                btn.Font = Enum.Font.GothamBold
                btn.AutoButtonColor = false
                btn.ZIndex = 5
                btn.Parent = content
                Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
                local stroke = Instance.new("UIStroke")
                stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                stroke.Color = Color3.fromRGB(255, 255, 255)
                stroke.Thickness = 0.6
                stroke.Transparency = 0.4
                stroke.Parent = btn
                return btn
            end

            local upBtn   = makeNavBtn("^", -BTN_SZ*2 - 8)
            local downBtn = makeNavBtn("v", -BTN_SZ - 4)

            tapConnect(upBtn, function()
                TweenService:Create(sf, TI.fast, {CanvasPosition = Vector2.new(0, 0)}):Play()
            end)
            tapConnect(downBtn, function()
                TweenService:Create(sf, TI.fast, {CanvasPosition = Vector2.new(0, sf.AbsoluteCanvasSize.Y)}):Play()
            end)

            local clearBtn = Instance.new("TextButton")
            clearBtn.Size = UDim2.new(0, 60, 0, BTN_SZ)
            clearBtn.Position = UDim2.new(0, 2, 1, -BTN_SZ - 3)
            clearBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            clearBtn.BackgroundTransparency = 0.72
            clearBtn.BorderSizePixel = 0
            clearBtn.Text = "Clear"
            clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            clearBtn.TextSize = 10
            clearBtn.Font = Enum.Font.GothamSemibold
            clearBtn.AutoButtonColor = false
            clearBtn.ZIndex = 5
            clearBtn.Parent = content
            Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(0, 4)

            local clearConfirmActive = false

            local function doClear()
                allLogs = {}
                local rows = {}
                for _, c in ipairs(sf:GetChildren()) do
                    if c:IsA("TextButton") or c:IsA("Frame") then rows[#rows+1] = c end
                end
                local fadeInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                for i, row in ipairs(rows) do
                    task.delay((i - 1) * 0.012, function()
                        if row and row.Parent then
                            TweenService:Create(row, fadeInfo, {BackgroundTransparency = 1}):Play()
                            for _, child in ipairs(row:GetChildren()) do
                                if child:IsA("TextLabel") then
                                    TweenService:Create(child, fadeInfo, {TextTransparency = 1}):Play()
                                end
                            end
                            task.delay(0.12, function() pcall(function() row:Destroy() end) end)
                        end
                    end)
                end
            end

            local function showClearPopup()
                if clearConfirmActive then return end
                clearConfirmActive = true

                local mainFrame = content.Parent

                local dim = Instance.new("Frame")
                dim.Size = UDim2.new(1, 0, 1, 0)
                dim.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                dim.BackgroundTransparency = 1
                dim.BorderSizePixel = 0
                dim.ZIndex = 40
                dim.Parent = mainFrame
                Instance.new("UICorner", dim).CornerRadius = UDim.new(0, 20)
                TweenService:Create(dim, TI.med, {BackgroundTransparency = 0.6}):Play()

                local panel = Instance.new("Frame")
                panel.Size = UDim2.new(0.76, 0, 0, 96)
                panel.Position = UDim2.new(0.12, 0, 0.5, -25)
                panel.BackgroundColor3 = Color3.fromRGB(14, 14, 17)
                panel.BackgroundTransparency = 1
                panel.BorderSizePixel = 0
                panel.ZIndex = 41
                panel.Parent = mainFrame
                Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)
                local ps = Instance.new("UIStroke")
                ps.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                ps.Color = Color3.fromRGB(255, 100, 100)
                ps.Thickness = 0.6
                ps.Transparency = 1
                ps.Parent = panel

                local pScale = Instance.new("UIScale")
                pScale.Scale = 0.82
                pScale.Parent = panel

                TweenService:Create(panel,  TI.slow, {BackgroundTransparency = 0.05, Position = UDim2.new(0.12, 0, 0.5, -48)}):Play()
                TweenService:Create(pScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
                TweenService:Create(ps,     TI.slow, {Transparency = 0.5}):Play()

                local headLbl = Instance.new("TextLabel")
                headLbl.Size = UDim2.new(1, -16, 0, 16)
                headLbl.Position = UDim2.new(0, 8, 0, 10)
                headLbl.BackgroundTransparency = 1
                headLbl.Text = "Clear all logs?"
                headLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
                headLbl.TextTransparency = 1
                headLbl.TextSize = 11
                headLbl.Font = Enum.Font.GothamBold
                headLbl.TextXAlignment = Enum.TextXAlignment.Left
                headLbl.ZIndex = 42
                headLbl.Parent = panel
                TweenService:Create(headLbl, TI.slow, {TextTransparency = 0}):Play()

                local countLbl = Instance.new("TextLabel")
                countLbl.Size = UDim2.new(1, -16, 0, 14)
                countLbl.Position = UDim2.new(0, 8, 0, 28)
                countLbl.BackgroundTransparency = 1
                countLbl.Text = #allLogs .. " log" .. (#allLogs == 1 and "" or "s") .. " will be removed"
                countLbl.TextColor3 = Color3.fromRGB(140, 120, 160)
                countLbl.TextTransparency = 1
                countLbl.TextSize = 9
                countLbl.Font = Enum.Font.Gotham
                countLbl.TextXAlignment = Enum.TextXAlignment.Left
                countLbl.ZIndex = 42
                countLbl.Parent = panel
                TweenService:Create(countLbl, TI.slow, {TextTransparency = 0}):Play()

                local function makePopBtn(txt, xScale, bgCol)
                    local b = Instance.new("TextButton")
                    b.Size = UDim2.new(0.44, 0, 0, 24)
                    b.Position = UDim2.new(xScale, 0, 0, 62)
                    b.BackgroundColor3 = bgCol
                    b.BackgroundTransparency = 1
                    b.BorderSizePixel = 0
                    b.Text = txt
                    b.TextColor3 = Color3.fromRGB(255, 255, 255)
                    b.TextTransparency = 1
                    b.TextSize = 10
                    b.Font = Enum.Font.GothamSemibold
                    b.AutoButtonColor = false
                    b.ZIndex = 42
                    b.Parent = panel
                    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
                    local bs = Instance.new("UIStroke")
                    bs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    bs.Color = Color3.fromRGB(255, 255, 255)
                    bs.Thickness = 0.5
                    bs.Transparency = 1
                    bs.Parent = b
                    TweenService:Create(b,  TI.slow, {BackgroundTransparency = 0.15, TextTransparency = 0}):Play()
                    TweenService:Create(bs, TI.slow, {Transparency = 0.7}):Play()
                    return b, bs
                end

                local cancelBtn,  cancelStroke  = makePopBtn("Cancel", 0.05, Color3.fromRGB(40, 40, 45))
                local confirmBtn, confirmStroke = makePopBtn("Clear",  0.51, Color3.fromRGB(140, 30, 30))

                local function closeConfirm()
                    local di = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
                    TweenService:Create(dim,        di, {BackgroundTransparency = 1}):Play()
                    TweenService:Create(panel,      di, {BackgroundTransparency = 1, Position = UDim2.new(0.12, 0, 0.5, -38)}):Play()
                    TweenService:Create(pScale,     di, {Scale = 0.88}):Play()
                    TweenService:Create(ps,         di, {Transparency = 1}):Play()
                    TweenService:Create(headLbl,    di, {TextTransparency = 1}):Play()
                    TweenService:Create(countLbl,   di, {TextTransparency = 1}):Play()
                    TweenService:Create(cancelBtn,  di, {BackgroundTransparency = 1, TextTransparency = 1}):Play()
                    TweenService:Create(cancelStroke, di, {Transparency = 1}):Play()
                    TweenService:Create(confirmBtn, di, {BackgroundTransparency = 1, TextTransparency = 1}):Play()
                    TweenService:Create(confirmStroke, di, {Transparency = 1}):Play()
                    task.delay(0.2, function()
                        pcall(function() dim:Destroy() end)
                        pcall(function() panel:Destroy() end)
                        clearConfirmActive = false
                    end)
                end

                local function wireBtn(btn, action)
                    local active = nil
                    btn.InputBegan:Connect(function(inp)
                        if inp.UserInputType ~= Enum.UserInputType.MouseButton1
                        and inp.UserInputType ~= Enum.UserInputType.Touch then return end
                        active = inp
                        TweenService:Create(btn, TI.fast, {BackgroundTransparency = 0.4}):Play()
                    end)
                    UserInputService.InputEnded:Connect(function(inp)
                        if inp ~= active then return end
                        active = nil
                        TweenService:Create(btn, TI.fast, {BackgroundTransparency = 0.15}):Play()
                        pcall(action)
                    end)
                end

                wireBtn(cancelBtn,  function() closeConfirm() end)
                wireBtn(confirmBtn, function()
                    closeConfirm()
                    task.delay(0.1, doClear)
                end)
            end

            local clearActive = nil
            clearBtn.InputBegan:Connect(function(inp)
                if inp.UserInputType ~= Enum.UserInputType.MouseButton1
                and inp.UserInputType ~= Enum.UserInputType.Touch then return end
                clearActive = inp
                TweenService:Create(clearBtn, TI.fast, {BackgroundTransparency = 0.4}):Play()
            end)
            UserInputService.InputEnded:Connect(function(inp)
                if inp ~= clearActive then return end
                clearActive = nil
                TweenService:Create(clearBtn, TI.fast, {BackgroundTransparency = 0.72}):Play()
                showClearPopup()
            end)

            content.AncestryChanged:Connect(function()
                if not content.Parent then
                    if logConn then logConn:Disconnect(); logConn = nil end
                end
            end)
        end,
    },
}

local function makeTabIcon(parent, iconType, initColor)
    local c = Instance.new("Frame")
    c.Name            = "TabIcon"
    c.Size            = UDim2.new(0, 16, 0, 16)
    c.Position        = UDim2.new(0.5, -8, 0.5, -8)
    c.BackgroundTransparency = 1
    c.Parent          = parent

    local colored = {}

    local function blk(x, y, w, h, rad)
        local f = Instance.new("Frame")
        f.Position         = UDim2.new(0, x, 0, y)
        f.Size             = UDim2.new(0, w, 0, h)
        f.BackgroundColor3 = initColor
        f.BorderSizePixel  = 0
        f.Parent           = c
        if rad and rad > 0 then
            Instance.new("UICorner", f).CornerRadius = UDim.new(0, rad)
        end
        colored[#colored+1] = f
        return f
    end

    -- Helper: draw a line between two points using a rotated Frame.
    -- Uses AnchorPoint(0.5,0.5) at the midpoint so rotation is correct.
    local function line(x1, y1, x2, y2, thickness)
        thickness = thickness or 2
        local dx = x2 - x1
        local dy = y2 - y1
        local length = math.sqrt(dx*dx + dy*dy)
        local angle  = math.deg(math.atan2(dy, dx))
        local cx = (x1 + x2) / 2
        local cy = (y1 + y2) / 2
        local f = Instance.new("Frame")
        f.AnchorPoint      = Vector2.new(0.5, 0.5)
        f.Position         = UDim2.new(0, cx, 0, cy)
        f.Size             = UDim2.new(0, length, 0, thickness)
        f.Rotation         = angle
        f.BackgroundColor3 = initColor
        f.BorderSizePixel  = 0
        f.Parent           = c
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 1)
        colored[#colored+1] = f
        return f
    end

    -- Admin: `>_` using two real rotated diagonal lines for `>` and one horizontal `_`
    -- Shrunk > so it doesn't overlap with the _ cursor below.
    if iconType == "admin" then
        line(2, 3,  10, 8, 2)   -- upper arm of >
        line(10, 8,  2, 13, 2)  -- lower arm of >
        line(2, 15, 14, 15, 2)  -- _ cursor (longer)

    -- Console: clean monitor outline + stand, no prompt inside
    elseif iconType == "console" then
        blk(0,  0, 16, 2, 1)  -- top edge
        blk(0,  0,  2, 10, 1) -- left edge
        blk(14, 0,  2, 10, 1) -- right edge
        blk(0,  8, 16,  2, 1) -- bottom screen edge
        blk(6, 10,  4,  2, 1) -- stand neck
        blk(3, 12, 10,  2, 1) -- stand base

    -- Scripts: house silhouette - stepped roof + two side walls + door
    -- All built from 2px-thick lines so it reads as an outline, not blocks.
    elseif iconType == "scripts" then
        blk(7,  0,  2, 2, 1)  -- roof peak
        blk(5,  2,  6, 2, 1)  -- roof level 2
        blk(3,  4, 10, 2, 1)  -- roof level 3
        blk(1,  6, 14, 2, 1)  -- eave (widest roof line)
        blk(1,  8,  2, 8, 1)  -- left wall (2px wide x 8px tall)
        blk(13, 8,  2, 8, 1)  -- right wall
        blk(5, 10,  6, 6, 1)  -- door (filled rect, bottom-center)

    -- Player: round head + rounded shoulder bar
    elseif iconType == "player" then
        local head = blk(4, 0, 8, 8, 4)
        head:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(1, 0)
        blk(1, 10, 14, 6, 4)

    -- Settings: three slider tracks with offset round knobs
    elseif iconType == "settings" then
        blk(0,  1, 16, 2, 1)
        blk(10, 0,  4, 4, 2)
        blk(0,  7, 16, 2, 1)
        blk(2,  6,  4, 4, 2)
        blk(0, 13, 16, 2, 1)
        blk(7, 12,  4, 4, 2)
    end

    return colored
end

function createUI()
    if activeFrame and activeFrame.Parent then
        local sz = savedFrameSize or DEFAULT_SIZE
        local finalPos
        if savedPosition then
            finalPos = UDim2.new(savedPosition.xs, savedPosition.xo, savedPosition.ys, savedPosition.yo)
        else
            finalPos = UDim2.new(0.5, -(sz.X.Offset/2), 0.5, -(sz.Y.Offset/2))
        end
        activeFrame.AnchorPoint = Vector2.new(0, 0)
        activeFrame.Position    = finalPos
        activeFrame.Size        = sz
        activeFrame.BackgroundTransparency = 1
        activeFrame.Visible     = true
        TweenService:Create(activeFrame, TI.open, {BackgroundTransparency = T.frameTrans}):Play()
        task.spawn(function()
            RunService.RenderStepped:Wait()
            if activeTabRef == 1 then
                local fn = _G.__luwaUpdateSuggestions
                if fn and adminCmdBox and adminCmdBox.Text ~= "" then
                    fn(adminCmdBox.Text)
                end
            end
            if waypointBox and rebuildWpBox and #waypoints > 0 then
                rebuildWpBox()
            end
        end)
        if activeAccentLine then
            TweenService:Create(activeAccentLine, TI.line, {Size = UDim2.new(1, -48, 0, 2)}):Play()
        end
        return
    end

    uiGeneration = uiGeneration + 1
    local myGeneration = uiGeneration

    tabBuilt = {}
    rescaleForceOff = nil

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "LuwaScript"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = LocalPlayer.PlayerGui

    local initSize = savedFrameSize or DEFAULT_SIZE
    local Frame = Instance.new("Frame")
    Frame.Size = initSize
    Frame.Position = UDim2.new(0.5, -(initSize.X.Offset/2), 0.5, -(initSize.Y.Offset/2) - 20)
    Frame.BackgroundColor3 = T.frameBg
    Frame.BackgroundTransparency = T.frameTrans
    Frame.BorderSizePixel = 0
    Frame.ClipsDescendants = true
    Frame.Active = true
    Frame.Draggable = false
    Frame.Parent = ScreenGui

    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 12)

    local frameOutline = Instance.new("UIStroke")
    frameOutline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    frameOutline.Color           = Color3.fromRGB(255, 255, 255)
    frameOutline.Thickness       = 1.2
    frameOutline.Transparency    = 0.25
    frameOutline.Parent          = Frame

    local glint = Instance.new("Frame")
    glint.Size                   = UDim2.new(1, -28, 0, 10)
    glint.Position               = UDim2.new(0, 14, 0, 5)
    glint.BackgroundColor3       = Color3.fromRGB(255, 255, 255)
    glint.BackgroundTransparency = 1
    glint.BorderSizePixel        = 0
    glint.ZIndex                 = 10
    glint.Parent                 = Frame
    Instance.new("UICorner", glint).CornerRadius = UDim.new(0, 6)
    local glintGrad = Instance.new("UIGradient")
    glintGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0,    1   ),
        NumberSequenceKeypoint.new(0.15, 0.86),
        NumberSequenceKeypoint.new(0.5,  0.80),
        NumberSequenceKeypoint.new(0.85, 0.86),
        NumberSequenceKeypoint.new(1,    1   ),
    })
    glintGrad.Rotation = 0
    glintGrad.Parent   = glint

    local TITLE_H  = 42
    local SIDE_W   = 28
    local CHROME_W = SIDE_W + 20

    local accentLine = Instance.new("Frame")
    accentLine.Size             = UDim2.new(0, 0, 0, 2)
    accentLine.Position         = UDim2.new(0, CHROME_W, 0, TITLE_H - 2)
    accentLine.BackgroundColor3 = T.accent
    accentLine.BorderSizePixel  = 0
    accentLine.ZIndex           = 5
    accentLine.Parent = Frame
    activeAccentLine = accentLine

    -- -- Close pill: hollow rounded rect containing avatar + X button
    local COL_PILL_HOV = Color3.fromRGB(255, 255, 255)
    local PILL_H = 28
    local PILL_W = 66

    local closePill = Instance.new("Frame")
    closePill.Size                  = UDim2.new(0, PILL_W, 0, PILL_H)
    closePill.Position              = UDim2.new(1, -(PILL_W + 8), 0, TITLE_H/2 - PILL_H/2)
    closePill.BackgroundColor3      = Color3.fromRGB(0, 0, 0)
    closePill.BackgroundTransparency = 0.55   -- subtle dark fill inside
    closePill.BorderSizePixel       = 0
    closePill.ZIndex                = 5
    closePill.Parent                = Frame
    Instance.new("UICorner", closePill).CornerRadius = UDim.new(0, 8)

    local pillStroke = Instance.new("UIStroke")
    pillStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    pillStroke.Color           = Color3.fromRGB(255, 255, 255)
    pillStroke.Thickness       = 0.9
    pillStroke.Transparency    = 0.55
    pillStroke.Parent          = closePill

    local pillScale = Instance.new("UIScale")
    pillScale.Scale  = 1
    pillScale.Parent = closePill

    -- Avatar on the left side of the pill (clickable - opens profile card)
    local titleAvatar = Instance.new("ImageLabel")
    titleAvatar.Size                   = UDim2.new(0, 20, 0, 20)
    titleAvatar.Position               = UDim2.new(0, 4, 0.5, -10)
    titleAvatar.BackgroundColor3       = Color3.fromRGB(180, 180, 185)
    titleAvatar.BackgroundTransparency = 0.4
    titleAvatar.BorderSizePixel        = 0
    titleAvatar.Image                  = ""
    titleAvatar.ZIndex                 = 6
    titleAvatar.Parent                 = closePill
    Instance.new("UICorner", titleAvatar).CornerRadius = UDim.new(1, 0)

    local _avatarImg = ""
    task.spawn(function()
        local ok, img = pcall(function()
            return Players:GetUserThumbnailAsync(
                LocalPlayer.UserId,
                Enum.ThumbnailType.HeadShot,
                Enum.ThumbnailSize.Size48x48)
        end)
        if ok then
            _avatarImg = img
            if titleAvatar.Parent then titleAvatar.Image = img end
        end
    end)

    -- Invisible button on top of the avatar pfp only
    local avatarBtn = Instance.new("TextButton")
    avatarBtn.Size                   = UDim2.new(1, 0, 1, 0)
    avatarBtn.BackgroundTransparency = 1
    avatarBtn.BorderSizePixel        = 0
    avatarBtn.Text                   = ""
    avatarBtn.AutoButtonColor        = false
    avatarBtn.ZIndex                 = 8
    avatarBtn.Parent                 = titleAvatar

    -- -- Profile card (separate draggable ScreenGui)
    local profileSg = Instance.new("ScreenGui")
    profileSg.Name           = "LuwaProfile"
    profileSg.ResetOnSpawn   = false
    profileSg.IgnoreGuiInset = true
    profileSg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    profileSg.DisplayOrder   = 25
    profileSg.Enabled        = false
    profileSg.Parent         = LocalPlayer.PlayerGui

    local PCARD_W = 180
    local PCARD_H = 175
    local pCard = Instance.new("Frame")
    pCard.Size                   = UDim2.new(0, PCARD_W, 0, PCARD_H)
    pCard.Position               = UDim2.new(0.5, -PCARD_W/2, 0.5, -PCARD_H/2)
    pCard.BackgroundColor3       = T.frameBg
    pCard.BackgroundTransparency = T.frameTrans
    pCard.BorderSizePixel        = 0
    pCard.Active                 = true
    pCard.ZIndex                 = 2
    pCard.Parent                 = profileSg
    Instance.new("UICorner", pCard).CornerRadius = UDim.new(0, 20)
    local pCardStroke = Instance.new("UIStroke")
    pCardStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    pCardStroke.Color           = Color3.fromRGB(255, 255, 255)
    pCardStroke.Thickness       = 0.5
    pCardStroke.Transparency    = 0.35
    pCardStroke.Parent          = pCard

    -- Top glint (matches main frame style)
    local profileGlint = Instance.new("Frame")
    profileGlint.Size                   = UDim2.new(1, -28, 0, 10)
    profileGlint.Position               = UDim2.new(0, 14, 0, 5)
    profileGlint.BackgroundColor3       = Color3.fromRGB(255, 255, 255)
    profileGlint.BackgroundTransparency = 1
    profileGlint.BorderSizePixel        = 0
    profileGlint.ZIndex                 = 10
    profileGlint.Parent                 = pCard
    Instance.new("UICorner", profileGlint).CornerRadius = UDim.new(0, 6)
    local profileGlintGrad = Instance.new("UIGradient")
    profileGlintGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0,    1   ),
        NumberSequenceKeypoint.new(0.15, 0.86),
        NumberSequenceKeypoint.new(0.5,  0.80),
        NumberSequenceKeypoint.new(0.85, 0.86),
        NumberSequenceKeypoint.new(1,    1   ),
    })
    profileGlintGrad.Parent = profileGlint

    -- Topbar accent (transparent, matches main frame title area)
    local pCardAccent = Instance.new("Frame")
    pCardAccent.Size             = UDim2.new(1, 0, 0, 38)
    pCardAccent.BackgroundTransparency = 1
    pCardAccent.BorderSizePixel  = 0
    pCardAccent.ZIndex           = 3
    pCardAccent.Parent           = pCard

    -- Accent line below title bar (matches main frame separator)
    local profileAccentLine = Instance.new("Frame")
    profileAccentLine.Size             = UDim2.new(1, -20, 0, 2)
    profileAccentLine.Position         = UDim2.new(0, 10, 1, -2)
    profileAccentLine.BackgroundColor3 = T.accent
    profileAccentLine.BorderSizePixel  = 0
    profileAccentLine.ZIndex           = 4
    profileAccentLine.Parent           = pCardAccent
    Instance.new("UICorner", profileAccentLine).CornerRadius = UDim.new(1, 0)

    -- Drag by topbar
    do
        local _pDragInp, _pDragStart, _pCardStart = nil, nil, nil
        pCardAccent.InputBegan:Connect(function(inp)
            if inp.UserInputType ~= Enum.UserInputType.MouseButton1
            and inp.UserInputType ~= Enum.UserInputType.Touch then return end
            _pDragInp   = inp
            _pDragStart  = inp.Position
            _pCardStart  = pCard.Position
        end)
        UserInputService.InputChanged:Connect(function(inp)
            if inp ~= _pDragInp then return end
            local d = inp.Position - _pDragStart
            pCard.Position = UDim2.new(_pCardStart.X.Scale, _pCardStart.X.Offset + d.X,
                                       _pCardStart.Y.Scale, _pCardStart.Y.Offset + d.Y)
        end)
        UserInputService.InputEnded:Connect(function(inp)
            if inp == _pDragInp then _pDragInp = nil end
        end)
    end

    -- Drag handle hint
    local pDragHint = Instance.new("TextLabel")
    pDragHint.Size                = UDim2.new(0, 14, 1, 0)
    pDragHint.Position            = UDim2.new(0, 8, 0, 0)
    pDragHint.BackgroundTransparency = 1
    pDragHint.Text                = "::"
    pDragHint.TextColor3          = Color3.fromRGB(60, 60, 72)
    pDragHint.TextSize            = 12
    pDragHint.Font                = Enum.Font.GothamBold
    pDragHint.ZIndex              = 4
    pDragHint.Parent              = pCardAccent

    -- Close button (X) in top-right of card - pill style matching main frame
    local pCloseBtn = Instance.new("TextButton")
    pCloseBtn.Size                   = UDim2.new(0, 22, 0, 22)
    pCloseBtn.Position               = UDim2.new(1, -28, 0.5, -11)
    pCloseBtn.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
    pCloseBtn.BackgroundTransparency = 0.55
    pCloseBtn.BorderSizePixel        = 0
    pCloseBtn.Text                   = "X"
    pCloseBtn.TextColor3             = Color3.fromRGB(255, 255, 255)
    pCloseBtn.TextSize               = 10
    pCloseBtn.Font                   = Enum.Font.GothamBold
    pCloseBtn.AutoButtonColor        = false
    pCloseBtn.ZIndex                 = 5
    pCloseBtn.Parent                 = pCardAccent
    Instance.new("UICorner", pCloseBtn).CornerRadius = UDim.new(1, 0)
    local pCloseBtnStroke = Instance.new("UIStroke")
    pCloseBtnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    pCloseBtnStroke.Color           = Color3.fromRGB(255, 255, 255)
    pCloseBtnStroke.Thickness       = 0.9
    pCloseBtnStroke.Transparency    = 0.55
    pCloseBtnStroke.Parent          = pCloseBtn

    -- Avatar image (top, centered)
    local pBigAvatar = Instance.new("ImageLabel")
    pBigAvatar.Size                   = UDim2.new(0, 64, 0, 64)
    pBigAvatar.Position               = UDim2.new(0.5, -32, 0, 46)
    pBigAvatar.BackgroundColor3       = Color3.fromRGB(25, 25, 32)
    pBigAvatar.BackgroundTransparency = 0.1
    pBigAvatar.BorderSizePixel        = 0
    pBigAvatar.Image                  = ""
    pBigAvatar.ZIndex                 = 3
    pBigAvatar.Parent                 = pCard
    Instance.new("UICorner", pBigAvatar).CornerRadius = UDim.new(1, 0)
    local pAvatarRing = Instance.new("UIStroke")
    pAvatarRing.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    pAvatarRing.Color           = Color3.fromRGB(255, 255, 255)
    pAvatarRing.Thickness       = 1.5
    pAvatarRing.Transparency    = 0.5
    pAvatarRing.Parent          = pBigAvatar

    -- Display name (centered, below avatar)
    local pDisplayName = Instance.new("TextLabel")
    pDisplayName.Size                = UDim2.new(1, -16, 0, 20)
    pDisplayName.Position            = UDim2.new(0, 8, 0, 116)
    pDisplayName.BackgroundTransparency = 1
    pDisplayName.Text                = LocalPlayer.DisplayName
    pDisplayName.TextColor3          = Color3.fromRGB(255, 255, 255)
    pDisplayName.TextSize            = 14
    pDisplayName.Font                = Enum.Font.GothamBold
    pDisplayName.TextXAlignment      = Enum.TextXAlignment.Center
    pDisplayName.TextTruncate        = Enum.TextTruncate.AtEnd
    pDisplayName.ZIndex              = 3
    pDisplayName.Parent              = pCard

    -- Username (centered)
    local pUsername = Instance.new("TextLabel")
    pUsername.Size                = UDim2.new(1, -16, 0, 14)
    pUsername.Position            = UDim2.new(0, 8, 0, 136)
    pUsername.BackgroundTransparency = 1
    pUsername.Text                = "@" .. LocalPlayer.Name
    pUsername.TextColor3          = Color3.fromRGB(200, 200, 210)
    pUsername.TextSize            = 10
    pUsername.Font                = Enum.Font.Gotham
    pUsername.TextXAlignment      = Enum.TextXAlignment.Center
    pUsername.TextTruncate        = Enum.TextTruncate.AtEnd
    pUsername.ZIndex              = 3
    pUsername.Parent              = pCard

    -- User ID - tappable to copy (centered)
    local pIdBtn = Instance.new("TextButton")
    pIdBtn.Size                   = UDim2.new(1, -16, 0, 16)
    pIdBtn.Position               = UDim2.new(0, 8, 0, 152)
    pIdBtn.BackgroundTransparency = 1
    pIdBtn.BorderSizePixel        = 0
    pIdBtn.Text                   = "ID: " .. tostring(LocalPlayer.UserId) .. "  [copy]"
    pIdBtn.TextColor3             = Color3.fromRGB(160, 160, 175)
    pIdBtn.TextSize               = 9
    pIdBtn.Font                   = Enum.Font.Code
    pIdBtn.TextXAlignment         = Enum.TextXAlignment.Center
    pIdBtn.AutoButtonColor        = false
    pIdBtn.ZIndex                 = 4
    pIdBtn.Parent                 = pCard
    tapConnect(pIdBtn, function()
        pcall(function() setclipboard(tostring(LocalPlayer.UserId)) end)
        pIdBtn.TextColor3 = Color3.fromRGB(50, 220, 110)
        pIdBtn.Text = "Copied!"
        task.delay(1.2, function()
            if pIdBtn and pIdBtn.Parent then
                pIdBtn.TextColor3 = Color3.fromRGB(160, 160, 175)
                pIdBtn.Text = "ID: " .. tostring(LocalPlayer.UserId) .. "  [copy]"
            end
        end)
    end)
    connectBtn(pIdBtn,
        function() pIdBtn.TextColor3 = Color3.fromRGB(255, 255, 255) end,
        function() pIdBtn.TextColor3 = Color3.fromRGB(160, 160, 175) end
    )

    -- Divider line below header
    local pDiv = Instance.new("Frame")
    pDiv.Size             = UDim2.new(1, -20, 0, 1)
    pDiv.Position         = UDim2.new(0, 10, 0, 40)
    pDiv.BackgroundColor3 = T.secLine
    pDiv.BackgroundTransparency = 0.5
    pDiv.BorderSizePixel  = 0
    pDiv.ZIndex           = 3
    pDiv.Parent           = pCard

    local profileOpen = false
    local TI_PROFILE_IN  = TweenInfo.new(0.32, Enum.EasingStyle.Back,  Enum.EasingDirection.Out)
    local TI_PROFILE_OUT = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In)

    local function openProfile()
        if profileOpen then return end
        profileOpen = true
        if _avatarImg ~= "" then pBigAvatar.Image = _avatarImg end
        pCard.Size = UDim2.new(0, PCARD_W, 0, PCARD_H)
        profileSg.Enabled = true
        local sc = pCard:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", pCard)
        sc.Scale = 0.88
        TweenService:Create(pCard,  TI_PROFILE_IN, {BackgroundTransparency = T.frameTrans}):Play()
        TweenService:Create(sc,     TI_PROFILE_IN, {Scale = 1}):Play()
        TweenService:Create(pCardStroke, TI_PROFILE_IN, {Transparency = 0.35}):Play()
    end

    local function closeProfile()
        if not profileOpen then return end
        profileOpen = false
        -- Always save position
        local p = pCard.Position
        savedProfilePos = { xs=p.X.Scale, xo=p.X.Offset, ys=p.Y.Scale, yo=p.Y.Offset }
        patchInfo({ profile_xs=p.X.Scale, profile_xo=p.X.Offset, profile_ys=p.Y.Scale, profile_yo=p.Y.Offset })
        local sc = pCard:FindFirstChildOfClass("UIScale")
        if sc then TweenService:Create(sc, TI_PROFILE_OUT, {Scale = 0.9}):Play() end
        TweenService:Create(pCard, TI_PROFILE_OUT, {BackgroundTransparency = 1}):Play()
        task.delay(0.2, function()
            profileSg.Enabled = false
            pCard.BackgroundTransparency = T.frameTrans
        end)
    end

    -- Avatar pfp toggles the profile card; always restores last position if saved
    tapConnect(avatarBtn, function()
        if profileOpen then
            closeProfile()
        else
            if savedProfilePos then
                pCard.Position = UDim2.new(savedProfilePos.xs, savedProfilePos.xo, savedProfilePos.ys, savedProfilePos.yo)
            else
                pCard.Position = UDim2.new(0.5, -PCARD_W/2, 0.5, -PCARD_H/2)
            end
            openProfile()
        end
    end)
    tapConnect(pCloseBtn, closeProfile)
    connectBtn(avatarBtn,
        function()
            TweenService:Create(titleAvatar, TI.dot, {BackgroundTransparency = 0.0}):Play()
        end,
        function()
            TweenService:Create(titleAvatar, TI.dotBack, {BackgroundTransparency = 0.4}):Play()
        end
    )
    connectBtn(pCloseBtn,
        function() TweenService:Create(pCloseBtn, TI.fast, {BackgroundTransparency = 0.05}):Play() end,
        function() TweenService:Create(pCloseBtn, TI.fast, {BackgroundTransparency = 0.25}):Play() end
    )

    -- X label (white text, no background - pill is hollow so white reads well)
    local redDot = Instance.new("TextButton")
    redDot.Size                   = UDim2.new(0, 32, 1, 0)
    redDot.Position               = UDim2.new(1, -32, 0, 0)
    redDot.BackgroundTransparency = 1
    redDot.BorderSizePixel        = 0
    redDot.Text                   = "X"
    redDot.TextColor3             = Color3.fromRGB(255, 255, 255)
    redDot.TextSize               = 12
    redDot.Font                   = Enum.Font.GothamBold
    redDot.AutoButtonColor        = false
    redDot.ZIndex                 = 6
    redDot.Parent                 = closePill

    -- Particle system: small white dots that fly outward from the pill when hovered.
    -- Each particle is a tiny Frame that spawns at a random edge position, moves
    -- outward, fades, and is destroyed. A Heartbeat loop spawns them while hovered.
    local pillHovered      = false
    local pillParticleConn = nil
    -- Particles are parented directly to ScreenGui (sibling of Frame, not inside it)
    -- so Frame.ClipsDescendants doesn't clip them, AND coordinates match closePill.AbsolutePosition
    -- (both live in the same ScreenGui coordinate space - no IgnoreGuiInset mismatch).

    local function spawnParticle()
        if not (closePill and closePill.Parent) then return end
        if not (ScreenGui and ScreenGui.Parent) then return end

        local pillAbs = closePill.AbsolutePosition
        local pillSz  = closePill.AbsoluteSize
        if pillSz.X <= 0 then return end  -- not yet laid out

        local cx = pillAbs.X + pillSz.X * 0.5
        local cy = pillAbs.Y + pillSz.Y * 0.5

        -- Spawn at perimeter using ellipse formula
        local angle = math.random() * math.pi * 2
        local sx = cx + math.cos(angle) * (pillSz.X * 0.5)
        local sy = cy + math.sin(angle) * (pillSz.Y * 0.5)

        local sz = math.random(2, 4)
        local dot = Instance.new("Frame")
        dot.Size                   = UDim2.new(0, sz, 0, sz)
        dot.Position               = UDim2.new(0, sx - sz/2, 0, sy - sz/2)
        dot.BackgroundColor3       = Color3.fromRGB(255, 255, 255)
        dot.BackgroundTransparency = 0.15
        dot.BorderSizePixel        = 0
        dot.ZIndex                 = 12
        dot.Parent                 = ScreenGui   -- same ScreenGui, sibling of Frame
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

        local speed  = math.random(8, 20)
        local spread = (math.random() - 0.5) * 0.5
        local vx = math.cos(angle + spread) * speed
        local vy = math.sin(angle + spread) * speed

        local dur = math.random(200, 350) / 100
        TweenService:Create(dot,
            TweenInfo.new(dur, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
            {
                Position               = UDim2.new(0, sx + vx - 1, 0, sy + vy - 1),
                BackgroundTransparency = 1,
                Size                   = UDim2.new(0, 1, 0, 1),
            }
        ):Play()
        task.delay(dur + 0.02, function()
            pcall(function() dot:Destroy() end)
        end)
    end

    local function startParticles()
        for _ = 1, 12 do pcall(spawnParticle) end   -- big burst on enter
        local spawnTimer = 0
        pillParticleConn = RunService.Heartbeat:Connect(function(dt)
            if not pillHovered then
                pillParticleConn:Disconnect(); pillParticleConn = nil
                return
            end
            spawnTimer = spawnTimer + dt
            while spawnTimer >= 0.012 do   -- ~80 particles/sec
                spawnTimer = spawnTimer - 0.012
                pcall(spawnParticle)
            end
        end)
    end

    -- Hover / press on the whole pill (particles + stroke)
    closePill.MouseEnter:Connect(function()
        pillHovered = true
        TweenService:Create(pillStroke, TI.fast, {Transparency = 0, Thickness = 1.4}):Play()
        TweenService:Create(pillScale,  TI.fast, {Scale = 1.04}):Play()
        if pillParticleConn then pillParticleConn:Disconnect(); pillParticleConn = nil end
        startParticles()
    end)
    closePill.MouseLeave:Connect(function()
        pillHovered = false
        TweenService:Create(pillStroke, TI.fast, {Transparency = 0.55, Thickness = 0.9}):Play()
        TweenService:Create(pillScale,  TI.fast, {Scale = 1}):Play()
    end)
    connectBtn(redDot,
        function()
            TweenService:Create(pillStroke, TI.dot, {Transparency = 0, Thickness = 1.6}):Play()
            TweenService:Create(pillScale,  TI.dot, {Scale = 0.96}):Play()
        end,
        function()
            TweenService:Create(pillStroke, TI.dotBack, {Transparency = pillHovered and 0 or 0.55, Thickness = pillHovered and 1.4 or 0.9}):Play()
            TweenService:Create(pillScale,  TI.dotBack, {Scale = 1}):Play()
        end
    )

    local function closeUI()
        if isClosing then return end
        isClosing = true
        cleanupResize()
        rescaleForceOff = nil
        if activeAccentLine then
            TweenService:Create(activeAccentLine, TI.lineRet, {Size=UDim2.new(0,0,0,2)}):Play()
        end
        if hideSuggestFn then
            suggestWasOpen = suggestFrame ~= nil and suggestFrame.Visible
            hideSuggestFn()
        end
        if waypointBox and waypointBox.Visible then
            TweenService:Create(waypointBox, TI.close, {BackgroundTransparency = 1}):Play()
            task.delay(0.2, function()
                if waypointBox then
                    waypointBox.Visible = false
                    waypointBox.Active  = false
                    waypointBox.BackgroundTransparency = 0.3
                end
            end)
        end
        TweenService:Create(Frame, TI.close, {BackgroundTransparency = 1}):Play()
        task.delay(0.2, function()
            uiVisible = false; isClosing = false
            Frame.Visible = false
        end)
    end
    tapConnect(redDot, closeUI)

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -CHROME_W - 10, 0, TITLE_H)
    Title.Position = UDim2.new(0, CHROME_W + 30, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "LuwaScript"
    Title.TextColor3 = T.titleTxt
    Title.TextScaled = true
    Title.Font = Enum.Font.GothamBold
    Title.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    Title.TextStrokeTransparency = 1
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Frame
    local titleSC = Instance.new("UITextSizeConstraint")
    titleSC.MaxTextSize = 14; titleSC.MinTextSize = 7
    titleSC.Parent = Title

    do
        local dragInput  = nil
        local dragStart  = nil
        local frameStart = nil

        Frame.InputBegan:Connect(function(inp)
            if inp.UserInputType ~= Enum.UserInputType.MouseButton1
            and inp.UserInputType ~= Enum.UserInputType.Touch then return end
            if dragInput then return end
            local ap = Frame.AbsolutePosition
            local px, py = inp.Position.X, inp.Position.Y
            if px < ap.X + CHROME_W then return end
            if py < ap.Y or py > ap.Y + TITLE_H then return end
            dragInput  = inp
            dragStart  = inp.Position
            frameStart = Frame.Position
        end)

        UserInputService.InputChanged:Connect(function(inp)
            if inp ~= dragInput then return end
            if not Frame or not Frame.Parent then dragInput = nil; return end
            local delta = inp.Position - dragStart
            Frame.Position = UDim2.new(
                frameStart.X.Scale, frameStart.X.Offset + delta.X,
                frameStart.Y.Scale, frameStart.Y.Offset + delta.Y
            )
        end)

        UserInputService.InputEnded:Connect(function(inp)
            if inp ~= dragInput then return end
            dragInput = nil
            -- Auto-save position whenever drag ends
            if Frame and Frame.Parent then
                local pos = Frame.Position
                savedPosition = { xs=pos.X.Scale, xo=pos.X.Offset, ys=pos.Y.Scale, yo=pos.Y.Offset }
                patchInfo({ pos_xs=pos.X.Scale, pos_xo=pos.X.Offset, pos_ys=pos.Y.Scale, pos_yo=pos.Y.Offset })
            end
        end)
    end

    local pillH = 18
    local initPillY = TITLE_H + 4 + math.floor((SIDE_W-4)/2) - math.floor(pillH/2)
    local tabSlidePill = Instance.new("Frame")
    tabSlidePill.Size             = UDim2.new(0, 3, 0, pillH)
    tabSlidePill.Position         = UDim2.new(0, CHROME_W - 3, 0, initPillY)
    tabSlidePill.BackgroundColor3 = T.accent
    tabSlidePill.BackgroundTransparency = 0
    tabSlidePill.BorderSizePixel  = 0
    tabSlidePill.ZIndex           = 5
    tabSlidePill.Parent = Frame
    Instance.new("UICorner", tabSlidePill).CornerRadius = UDim.new(1, 0)

    local tooltip = Instance.new("Frame")
    tooltip.Size             = UDim2.new(0, 70, 0, 22)
    tooltip.BackgroundColor3 = T.tabOn
    tooltip.BackgroundTransparency = 0.05
    tooltip.BorderSizePixel  = 0
    tooltip.Visible          = false
    tooltip.ZIndex           = 30
    tooltip.Parent           = ScreenGui
    Instance.new("UICorner", tooltip).CornerRadius = UDim.new(0, 6)
    local ttLbl = Instance.new("TextLabel")
    ttLbl.Size               = UDim2.new(1, -6, 1, 0)
    ttLbl.Position           = UDim2.new(0, 3, 0, 0)
    ttLbl.BackgroundTransparency = 1
    ttLbl.TextColor3         = T.tabTxtOn
    ttLbl.TextScaled         = true
    ttLbl.Font               = Enum.Font.GothamSemibold
    ttLbl.ZIndex             = 31
    ttLbl.Parent             = tooltip
    local ttSC = Instance.new("UITextSizeConstraint")
    ttSC.MaxTextSize = 11; ttSC.MinTextSize = 5
    ttSC.Parent = ttLbl

    local ttTimer = nil
    local function showTooltip(name, btn)
        if ttTimer then task.cancel(ttTimer); ttTimer = nil end
        ttLbl.Text = name
        local ap = btn.AbsolutePosition
        local as = btn.AbsoluteSize
        tooltip.Position = UDim2.new(0, ap.X + as.X + 6, 0, ap.Y + (as.Y - 22)/2)
        tooltip.Visible  = true
    end
    local function hideTooltip()
        if ttTimer then task.cancel(ttTimer); ttTimer = nil end
        tooltip.Visible = false
    end

    local tabBtns          = {}
    local tabContents      = {}
    local tabIconFramesList= {}
    local activeTab        = 1

    local CX = SIDE_W + 22
    local CY = TITLE_H + 2
    local CW = -(SIDE_W + 26)
    local CH = -(TITLE_H + 4)

    local switching = false

    local function switchTab(index)
        if index == activeTab or switching then return end
        if activeTab == SETTINGS_TAB_INDEX and rescaleForceOff then
            cleanupResize()
            if activeFrame then
                TweenService:Create(activeFrame, TI.slow, {Size=savedFrameSize or DEFAULT_SIZE}):Play()
            end
            pcall(rescaleForceOff)
            rescaleForceOff = nil
        end

        switching = true
        local prevIndex = activeTab

        local oldContent = tabContents[prevIndex]
        if oldContent then
            oldContent.Visible = false
        end

        activeTab    = index
        activeTabRef = index

        local newContent = tabContents[index]
        if newContent then
            local fullW = newContent.Size.X.Offset
            local fullH = newContent.Size.Y.Offset
            local popOffX, popOffY = 8, 6
            newContent.Size     = UDim2.new(newContent.Size.X.Scale, fullW - popOffX*2,
                                            newContent.Size.Y.Scale, fullH - popOffY*2)
            newContent.Position = UDim2.new(0, CX + popOffX, 0, CY + popOffY)
            newContent.Visible  = true
            TweenService:Create(newContent, TI.tabIn, {
                Size     = UDim2.new(newContent.Size.X.Scale, fullW,
                                     newContent.Size.Y.Scale, fullH),
                Position = UDim2.new(0, CX, 0, CY),
            }):Play()
        end

        do
            local pillH = 18
            local targetY = TITLE_H + 4 + (index-1)*(SIDE_W + 2) + math.floor((SIDE_W-4)/2) - math.floor(pillH/2)
            TweenService:Create(tabSlidePill, TI.tabInd, {
                Position = UDim2.new(0, CHROME_W - 3, 0, targetY),
            }):Play()
        end

        for i = 1, #TABS do
            local on = (i == index)
            TweenService:Create(tabBtns[i], TI.fast, {
                BackgroundColor3       = on and T.tabOn or T.tabBg,
                BackgroundTransparency = on and 0 or 0.8,
            }):Play()
            local iconCol = on and T.tabTxtOn or T.tabTxtOff
            for _, f in ipairs(tabIconFramesList[i] or {}) do
                TweenService:Create(f, TI.fast, {BackgroundColor3 = iconCol}):Play()
            end
            if on then
                TweenService:Create(tabBtns[i], TI.squish1,
                    {Size = UDim2.new(0, SIDE_W - 4, 0, SIDE_W - 4 - 3)}):Play()
                task.delay(0.07, function()
                    TweenService:Create(tabBtns[i], TI.squish2,
                        {Size = UDim2.new(0, SIDE_W - 4, 0, SIDE_W - 4)}):Play()
                end)
            end
        end

        task.delay(0.18, function() switching = false end)
    end

    activeFrame     = Frame
    activeScreenGui = ScreenGui

    for i, tab in ipairs(TABS) do
        local on  = (i == 1)
        local idx = i

        local iconBtn = Instance.new("TextButton")
        iconBtn.Size             = UDim2.new(0, SIDE_W - 4, 0, SIDE_W - 4)
        iconBtn.Position         = UDim2.new(0, (CHROME_W - (SIDE_W - 4)) / 2, 0, TITLE_H + 4 + (i-1)*(SIDE_W + 2))
        iconBtn.BackgroundColor3 = on and T.tabOn or T.tabBg
        iconBtn.BackgroundTransparency = on and 0 or 0.8
        iconBtn.BorderSizePixel  = 0
        iconBtn.Text             = ""
        iconBtn.AutoButtonColor  = false
        iconBtn.Parent = Frame
        Instance.new("UICorner", iconBtn).CornerRadius = UDim.new(0, 7)
        tabBtns[i] = iconBtn

        local initCol = on and T.tabTxtOn or T.tabTxtOff
        tabIconFramesList[i] = makeTabIcon(iconBtn, tab.iconType, initCol)

        iconBtn.MouseEnter:Connect(function()
            if i ~= activeTab then
                TweenService:Create(iconBtn, TI.fast, {BackgroundTransparency = 0.5}):Play()
            end
            if ttTimer then task.cancel(ttTimer) end
            ttTimer = task.delay(1, function()
                ttTimer = nil
                showTooltip(tab.name, iconBtn)
            end)
        end)
        iconBtn.MouseLeave:Connect(function()
            if i ~= activeTab then
                TweenService:Create(iconBtn, TI.fast, {BackgroundTransparency = 0.8}):Play()
            end
            hideTooltip()
        end)

        local holdInp = nil
        iconBtn.InputBegan:Connect(function(inp)
            if inp.UserInputType ~= Enum.UserInputType.Touch then return end
            holdInp = inp
            if ttTimer then task.cancel(ttTimer) end
            ttTimer = task.delay(1, function()
                ttTimer = nil
                if holdInp == inp then showTooltip(tab.name, iconBtn) end
            end)
        end)
        UserInputService.InputEnded:Connect(function(inp)
            if inp ~= holdInp then return end
            holdInp = nil
            hideTooltip()
        end)

        tapConnect(iconBtn, function()
            hideTooltip()
            switchTab(idx)
        end)

        local content = Instance.new("Frame")
        content.Size             = UDim2.new(1, CW, 1, CH)
        content.Position         = UDim2.new(0, CX, 0, CY)
        content.BackgroundTransparency = 1
        content.BorderSizePixel  = 0
        content.ClipsDescendants = true
        content.Visible          = on
        content.Parent           = Frame
        tabContents[i] = content

        if not tabBuilt[i] then
            content:SetAttribute("LazyBuildIdx", i)
        end
    end

    local _origSwitchTab = switchTab
    switchTab = function(index)
        if uiGeneration ~= myGeneration then return end
        local c = tabContents[index]
        if c and c:GetAttribute("LazyBuildIdx") and not tabBuilt[index] then
            local idx = c:GetAttribute("LazyBuildIdx")
            tabBuilt[idx] = true
            tabEverBuilt[idx] = true
            c:SetAttribute("LazyBuildIdx", nil)
            local ok, err = pcall(TABS[idx].build, c)
            if not ok then
                warn("[LuwaScript] Tab build error (" .. tostring(TABS[idx].name) .. "): " .. tostring(err))
            else
                local sf = c:FindFirstChildOfClass("ScrollingFrame")
                if sf then
                    task.defer(function()
                        if sf and sf.Parent then
                            local saved = tabScrollPos[idx]
                            if saved then sf.CanvasPosition = saved end
                        end
                    end)
                    sf:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
                        tabScrollPos[idx] = sf.CanvasPosition
                    end)
                end
            end
        end
        if Frame and Frame.Parent then
            if index == 1 and activeTabRef ~= 1 then
                task.defer(function()
                    local fn = _G.__luwaUpdateSuggestions
                    if fn and adminCmdBox and adminCmdBox.Text ~= "" then
                        fn(adminCmdBox.Text)
                    end
                end)
            elseif index ~= 1 and activeTabRef == 1 then
                if hideSuggestFn then hideSuggestFn() end
            end
            -- show/hide waypointBox (built in Scripts tab = index 2)
            if index == 2 then
                if wpBoxOpen and waypointBox and #waypoints > 0 then
                    waypointBox.BackgroundTransparency = 1
                    waypointBox.Visible = true
                    waypointBox.Active  = true
                    TweenService:Create(waypointBox, TI.med, {BackgroundTransparency = 0.3}):Play()
                end
            elseif activeTabRef == 2 then
                if waypointBox and waypointBox.Visible then
                    TweenService:Create(waypointBox, TI.fast, {BackgroundTransparency = 1}):Play()
                    task.delay(0.15, function()
                        if waypointBox and activeTabRef ~= 2 then
                            waypointBox.Visible = false
                            waypointBox.Active  = false
                            waypointBox.BackgroundTransparency = 0.3
                        end
                    end)
                end
            end
            pcall(_origSwitchTab, index)
        end
    end

    local loader = Instance.new("Frame")
    loader.Size                   = UDim2.new(1, 0, 1, 0)
    loader.BackgroundColor3       = Color3.fromRGB(10, 10, 12)
    loader.BackgroundTransparency = 1
    loader.BorderSizePixel        = 0
    loader.ZIndex                 = 20
    loader.Parent                 = Frame
    Instance.new("UICorner", loader).CornerRadius = UDim.new(0, 20)
    TweenService:Create(loader, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()

    local loaderGrad = Instance.new("UIGradient")
    loaderGrad.Color    = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(16, 16, 20)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(8,  8,  10)),
    })
    loaderGrad.Rotation = 90
    loaderGrad.Parent   = loader

    local spinRing = Instance.new("Frame")
    spinRing.Size                   = UDim2.new(0, 36, 0, 36)
    spinRing.Position               = UDim2.new(0.5, -18, 0.5, -56)
    spinRing.BackgroundTransparency = 1
    spinRing.BorderSizePixel        = 0
    spinRing.ZIndex                 = 22
    spinRing.Parent                 = loader
    Instance.new("UICorner", spinRing).CornerRadius = UDim.new(1, 0)
    local spinStroke = Instance.new("UIStroke")
    spinStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    spinStroke.Color           = Color3.fromRGB(255, 255, 255)
    spinStroke.Thickness       = 2
    spinStroke.Transparency    = 1
    spinStroke.Parent          = spinRing

    local spinDot = Instance.new("Frame")
    spinDot.Size             = UDim2.new(0, 5, 0, 5)
    spinDot.Position         = UDim2.new(0.5, -2, 0, 5)
    spinDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    spinDot.BorderSizePixel  = 0
    spinDot.ZIndex           = 23
    spinDot.Parent           = spinRing
    Instance.new("UICorner", spinDot).CornerRadius = UDim.new(1, 0)

    local spinAngle = 0
    local spinConn = RunService.Heartbeat:Connect(function(dt)
        if not (spinRing and spinRing.Parent) then return end
        spinAngle = spinAngle + dt * 280
        spinRing.Rotation = spinAngle
    end)

    local loaderLbl = Instance.new("TextLabel")
    loaderLbl.Size                = UDim2.new(1, -40, 0, 22)
    loaderLbl.Position            = UDim2.new(0, 20, 0.5, -8)
    loaderLbl.BackgroundTransparency = 1
    loaderLbl.Text                = "LuwaScript"
    loaderLbl.TextColor3          = Color3.fromRGB(255, 255, 255)
    loaderLbl.TextTransparency    = 1
    loaderLbl.TextSize            = 15
    loaderLbl.Font                = Enum.Font.GothamBold
    loaderLbl.TextXAlignment      = Enum.TextXAlignment.Center
    loaderLbl.ZIndex              = 21
    loaderLbl.Parent              = loader

    local loaderSub = Instance.new("TextLabel")
    loaderSub.Size                = UDim2.new(1, -40, 0, 14)
    loaderSub.Position            = UDim2.new(0, 20, 0.5, 18)
    loaderSub.BackgroundTransparency = 1
    loaderSub.Text                = "Loading..."
    loaderSub.TextColor3          = Color3.fromRGB(100, 100, 112)
    loaderSub.TextTransparency    = 1
    loaderSub.TextSize            = 10
    loaderSub.Font                = Enum.Font.Gotham
    loaderSub.TextXAlignment      = Enum.TextXAlignment.Center
    loaderSub.ZIndex              = 21
    loaderSub.Parent              = loader

    local barBg = Instance.new("Frame")
    barBg.Size             = UDim2.new(0.55, 0, 0, 2)
    barBg.Position         = UDim2.new(0.225, 0, 0.5, 40)
    barBg.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
    barBg.BackgroundTransparency = 1
    barBg.BorderSizePixel  = 0
    barBg.ZIndex           = 21
    barBg.Parent           = loader
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

    local bar = Instance.new("Frame")
    bar.Size             = UDim2.new(0, 0, 1, 0)
    bar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    bar.BorderSizePixel  = 0
    bar.ZIndex           = 22
    bar.Parent           = barBg
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

    local barGlow = Instance.new("UIGradient")
    barGlow.Color    = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(200, 200, 200)),
        ColorSequenceKeypoint.new(0.6, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(255, 255, 255)),
    })
    barGlow.Parent = bar

    local pctLbl = Instance.new("TextLabel")
    pctLbl.Size                = UDim2.new(1, 0, 0, 12)
    pctLbl.Position            = UDim2.new(0, 0, 0.5, 50)
    pctLbl.BackgroundTransparency = 1
    pctLbl.Text                = "0%"
    pctLbl.TextColor3          = Color3.fromRGB(70, 70, 80)
    pctLbl.TextTransparency    = 1
    pctLbl.TextSize            = 9
    pctLbl.Font                = Enum.Font.GothamBold
    pctLbl.TextXAlignment      = Enum.TextXAlignment.Center
    pctLbl.ZIndex              = 21
    pctLbl.Parent              = loader

    -- fade in loader contents shortly after bg
    local spinStrokeRef = spinStroke
    task.delay(0.05, function()
        if not (loader and loader.Parent) then return end
        local fi = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(loaderLbl,     fi, {TextTransparency = 0}):Play()
        TweenService:Create(loaderSub,     fi, {TextTransparency = 0}):Play()
        TweenService:Create(pctLbl,        fi, {TextTransparency = 0}):Play()
        TweenService:Create(barBg,         fi, {BackgroundTransparency = 0}):Play()
        TweenService:Create(spinStrokeRef, fi, {Transparency = 0.3}):Play()
    end)

    local fullSz = Frame.Size
    local finalPos = savedPosition
        and UDim2.new(savedPosition.xs, savedPosition.xo, savedPosition.ys, savedPosition.yo)
        or  UDim2.new(0.5, -(fullSz.X.Offset/2), 0.5, -(fullSz.Y.Offset/2))
    Frame.AnchorPoint          = Vector2.new(0, 0)
    Frame.Position             = finalPos
    Frame.Size                 = fullSz
    Frame.BackgroundTransparency = 1
    TweenService:Create(Frame, TI.open, {BackgroundTransparency = T.frameTrans}):Play()
    TweenService:Create(accentLine, TI.line, {Size=UDim2.new(1, -CHROME_W, 0, 2)}):Play()

    task.spawn(function()
        task.wait()

        local lazyTabs = {}
        for i, c in ipairs(tabContents) do
            if c:GetAttribute("LazyBuildIdx") then
                lazyTabs[#lazyTabs+1] = i
            end
        end

        local function dismissLoader()
            if not (loader and loader.Parent) then return end
            spinConn:Disconnect()
            local di = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            TweenService:Create(loader,    di, {BackgroundTransparency = 1}):Play()
            TweenService:Create(loaderLbl, di, {TextTransparency = 1}):Play()
            TweenService:Create(loaderSub, di, {TextTransparency = 1}):Play()
            TweenService:Create(pctLbl,    di, {TextTransparency = 1}):Play()
            TweenService:Create(barBg,     di, {BackgroundTransparency = 1}):Play()
            TweenService:Create(bar,       di, {BackgroundTransparency = 1}):Play()
            TweenService:Create(spinStroke,di, {Transparency = 1}):Play()
            TweenService:Create(spinDot,   di, {BackgroundTransparency = 1}):Play()
            task.delay(0.22, function() pcall(function() loader:Destroy() end) end)
        end

        local function buildTab(i)
            local c = tabContents[i]
            if not (c and c:GetAttribute("LazyBuildIdx") and not tabBuilt[i]) then return end
            tabBuilt[i]     = true
            tabEverBuilt[i] = true
            c:SetAttribute("LazyBuildIdx", nil)
            local ok, err = pcall(TABS[i].build, c)
            if not ok then
                if not tostring(err):find("NumberSequence") then
                    warn("[LuwaScript] Tab build error (" .. tostring(TABS[i].name) .. "): " .. tostring(err))
                end
            else
                local sf = c:FindFirstChildOfClass("ScrollingFrame")
                if sf then
                    local tidx = i
                    task.defer(function()
                        if sf and sf.Parent then
                            local saved = tabScrollPos[tidx]
                            if saved then sf.CanvasPosition = saved end
                        end
                    end)
                    sf:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
                        tabScrollPos[tidx] = sf.CanvasPosition
                    end)
                end
            end
        end

        if #lazyTabs == 0 then
            dismissLoader()
            return
        end

        local total = #lazyTabs + 1
        local done  = 1
        TweenService:Create(bar, TweenInfo.new(0.1), {Size = UDim2.new(done/total, 0, 1, 0)}):Play()
        pctLbl.Text = math.floor((done/total)*100) .. "%"

        for _, i in ipairs(lazyTabs) do
            task.wait()
            if uiGeneration ~= myGeneration then return end
            loaderSub.Text = TABS[i].name .. "..."
            buildTab(i)
            done = done + 1
            TweenService:Create(bar, TweenInfo.new(0.1), {Size = UDim2.new(done/total, 0, 1, 0)}):Play()
            pctLbl.Text = math.floor((done/total)*100) .. "%"
        end

        dismissLoader()
    end)
end

print("[LuwaScript] Loaded. Tap the circle to open.")
