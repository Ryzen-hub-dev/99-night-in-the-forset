--[[

	Ryzen Hub Interface Suite
	by Ryzen Team

	shlex  | Designing + Programming
	iRay   | Programming
	Max    | Programming
	Damian | Programming

]]

if debugX then
    warn('Initialising Ryzen Hub')
end

local function getService(name)
    local service = game:GetService(name)
    return if cloneref then cloneref(service) else service
end

local function loadWithTimeout(url: string, timeout: number?): ...any
    assert(type(url) == "string", "Expected string, got " .. type(url))
    timeout = timeout or 5
    local requestCompleted = false
    local success, result = false, nil

    local requestThread = task.spawn(function()
        local fetchSuccess, fetchResult = pcall(game.HttpGet, game, url)
        if not fetchSuccess or #fetchResult == 0 then
            if #fetchResult == 0 then
                fetchResult = "Empty response"
            end
            success, result = false, fetchResult
            requestCompleted = true
            return
        end
        local content = fetchResult
        local execSuccess, execResult = pcall(function()
            return loadstring(content)()
        end)
        success, result = execSuccess, execResult
        requestCompleted = true
    end)

    local timeoutThread = task.delay(timeout, function()
        if not requestCompleted then
            warn(string.format("Request for %s timed out after %d seconds", url, timeout))
            requestCompleted = true
        end
    end)

    while not requestCompleted do
        task.wait()
    end
    if coroutine.status(timeoutThread) ~= "dead" then
        task.cancel(timeoutThread)
    end
    if not success then
        warn(string.format("Failed to process %s: %s", url, result))
    end
    return if success then result else nil
end

local requestsDisabled = true
local InterfaceBuild = '3K3W'
local Release = "Build 1.68"
local RyzenHubFolder = "RyzenHub"
local ConfigurationFolder = RyzenHubFolder.."/Configurations"
local ConfigurationExtension = ".rfld"
local settingsTable = {
    General = {
        ryzenhubOpen = {Type = 'bind', Value = 'K', Name = 'Ryzen Hub Keybind'},
    },
    System = {
        usageAnalytics = {Type = 'toggle', Value = true, Name = 'Anonymised Analytics'},
    }
}

local overriddenSettings = {}

local function overrideSetting(category: string, name: string, value: any)
    overriddenSettings[`{category}.{name}`] = value
end

local function getSetting(category: string, name: string): any
    if overriddenSettings[`{category}.{name}`] ~= nil then
        return overriddenSettings[`{category}.{name}`]
    elseif settingsTable[category][name] ~= nil then
        return settingsTable[category][name].Value
    end
end

if requestsDisabled then
    overrideSetting("System", "usageAnalytics", false)
end

local HttpService = getService('HttpService')
local RunService = getService('RunService')

local useStudio = RunService:IsStudio() or false

local settingsCreated = false
local settingsInitialized = false
local cachedSettings
local prompt = useStudio and require(script.Parent.prompt) or loadWithTimeout('https://raw.githubusercontent.com/Ryzen-hub-dev/99-night-in-the-forset/refs/heads/main/propmt.lua')
local requestFunc = (syn and syn.request) or (fluxus and fluxus.request) or (http and http.request) or http_request or request

if not prompt and not useStudio then
    warn("Failed to load prompt library, using fallback")
    prompt = {create = function() end}
end

local function loadSettings()
    local file = nil

    local success, result = pcall(function()
        task.spawn(function()
            if isfolder and isfolder(RyzenHubFolder) then
                if isfile and isfile(RyzenHubFolder..'/settings'..ConfigurationExtension) then
                    file = readfile(RyzenHubFolder..'/settings'..ConfigurationExtension)
                end
            end

            if useStudio then
                file = [[
                    {"General":{"ryzenhubOpen":{"Value":"K","Type":"bind","Name":"Ryzen Hub Keybind","Element":{"HoldToInteract":false,"Ext":true,"Name":"Ryzen Hub Keybind","Set":null,"CallOnChange":true,"Callback":null,"CurrentKeybind":"K"}}},"System":{"usageAnalytics":{"Value":false,"Type":"toggle","Name":"Anonymised Analytics","Element":{"Ext":true,"Name":"Anonymised Analytics","Set":null,"CurrentValue":false,"Callback":null}}}}
                ]]
            end

            if file then
                local success, decodedFile = pcall(function() return HttpService:JSONDecode(file) end)
                if success then
                    file = decodedFile
                else
                    file = {}
                end
            else
                file = {}
            end

            if not settingsCreated then 
                cachedSettings = file
                return
            end

            if file ~= {} then
                for categoryName, settingCategory in pairs(settingsTable) do
                    if file[categoryName] then
                        for settingName, setting in pairs(settingCategory) do
                            if file[categoryName][settingName] then
                                setting.Value = file[categoryName][settingName].Value
                                if setting.Element then
                                    setting.Element:Set(getSetting(categoryName, settingName))
                                end
                            end
                        end
                    end
                end
            end
            settingsInitialized = true
        end)
    end)

    if not success then 
        if writefile then
            warn('Ryzen Hub had an issue accessing configuration saving capability.')
        end
    end
end

if debugX then
    warn('Now Loading Settings Configuration')
end

loadSettings()

if debugX then
    warn('Settings Loaded')
end

local analyticsLib
local sendReport = function(ev_n, sc_n) warn("Failed to load report function") end
if not requestsDisabled then
    if debugX then
        warn('Querying Settings for Reporter Information')
    end    
    analyticsLib = loadWithTimeout("https://analytics.ryzenhub.menu/script")
    if not analyticsLib then
        warn("Failed to load analytics reporter")
        analyticsLib = nil
    elseif analyticsLib and type(analyticsLib.load) == "function" then
        analyticsLib:load()
    else
        warn("Analytics library loaded but missing load function")
        analyticsLib = nil
    end
    sendReport = function(ev_n, sc_n)
        if not (type(analyticsLib) == "table" and type(analyticsLib.isLoaded) == "function" and analyticsLib:isLoaded()) then
            warn("Analytics library not loaded")
            return
        end
        if useStudio then
            print('Sending Analytics')
        else
            if debugX then warn('Reporting Analytics') end
            analyticsLib:report(
                {
                    ["name"] = ev_n,
                    ["script"] = {["name"] = sc_n, ["version"] = Release}
                },
                {
                    ["version"] = InterfaceBuild
                }
            )
            if debugX then warn('Finished Report') end
        end
    end
    if cachedSettings and (#cachedSettings == 0 or (cachedSettings.System and cachedSettings.System.usageAnalytics and cachedSettings.System.usageAnalytics.Value)) then
        sendReport("execution", "Ryzen Hub")
    elseif not cachedSettings then
        sendReport("execution", "Ryzen Hub")
    end
end

local promptUser = 2

if promptUser == 1 and prompt and type(prompt.create) == "function" then
    prompt.create(
        'Be cautious when running scripts',
        [[Please be careful when running scripts from unknown developers. This script has already been ran.

<font transparency='0.3'>Some scripts may steal your items or in-game goods.</font>]],
        'Okay',
        '',
        function()
        end
    )
end

if debugX then
    warn('Moving on to continue initialisation')
end

local RyzenHubLibrary = {
    Flags = {},
    Theme = {
        Default = {
            TextColor = Color3.fromRGB(240, 240, 240),
            Background = Color3.fromRGB(20, 20, 25),
            Topbar = Color3.fromRGB(25, 25, 25),
            Shadow = Color3.fromRGB(10, 10, 10),
            NotificationBackground = Color3.fromRGB(15, 15, 15),
            NotificationActionsBackground = Color3.fromRGB(230, 230, 230),
            TabBackground = Color3.fromRGB(25, 25, 25),
            TabStroke = Color3.fromRGB(35, 35, 35),
            TabBackgroundSelected = Color3.fromRGB(0, 255, 150),
            TabTextColor = Color3.fromRGB(240, 240, 240),
            SelectedTabTextColor = Color3.fromRGB(50, 55, 60),
            ElementBackground = Color3.fromRGB(35, 35, 35),
            ElementBackgroundHover = Color3.fromRGB(45, 45, 45),
            SecondaryElementBackground = Color3.fromRGB(35, 35, 35),
            ElementStroke = Color3.fromRGB(50, 50, 50),
            SecondaryElementStroke = Color3.fromRGB(40, 40, 40),
            HoverColor = Color3.fromRGB(45, 45, 45),
            SliderBackground = Color3.fromRGB(35, 35, 35),
            SliderProgress = Color3.fromRGB(0, 255, 150),
            SliderStroke = Color3.fromRGB(50, 50, 50),
            ToggleBackground = Color3.fromRGB(170, 170, 170),
            ToggleEnabled = Color3.fromRGB(0, 255, 150),
            ToggleDisabled = Color3.fromRGB(150, 150, 150),
            ToggleEnabledStroke = Color3.fromRGB(0, 255, 150),
            ToggleDisabledStroke = Color3.fromRGB(125, 125, 125),
            ToggleEnabledOuterStroke = Color3.fromRGB(100, 100, 100),
            ToggleDisabledOuterStroke = Color3.fromRGB(65, 65, 65),
            InputBackground = Color3.fromRGB(35, 35, 35),
            InputStroke = Color3.fromRGB(100, 100, 100),
            PlaceholderColor = Color3.fromRGB(178, 178, 178)
        },
    },
    Signals = {},
    Options = {},
}

local UISettings = {
    TabWidth = 160,
    ElementWidth = 385,
    ContentWidth = 360
}

local TweenService = getService('TweenService')
local HttpService = getService('HttpService')
local UserInputService = getService('UserInputService')
local RunService = getService('RunService')

local Players = getService('Players')
local LocalPlayer = Players.LocalPlayer
local CoreGui = getService('CoreGui')
local UISettingsPadding = 4

local function ResolveColor(Color)
    if Color.ClassName == "Color3" then
        return Color
    else
        return RyzenHubLibrary.Theme.Default[Color]
    end
end

local function GetMouseLocation()
    return UserInputService:GetMouseLocation()
end

local Mouse = LocalPlayer:GetMouse()

local function ThemeEnabled()
    return RyzenHubLibrary.Options.Themeable and RyzenHubLibrary.Options.Themeable.Enabled == true
end

local function ElementEnabled(Option)
    if RyzenHubLibrary.Options.Themeable[Option] == nil then
        return true
    elseif RyzenHubLibrary.Options.Themeable[Option] == true then
        return true
    end
    return false
end

local function GetOptionValue(Option)
    if ThemeEnabled() and RyzenHubLibrary.Options.Themeable[Option] ~= nil then
        return RyzenHubLibrary.Options.Themeable[Option]
    end
    return RyzenHubLibrary.Theme.Default[Option]
end

local function InValidWorkspace()
    local success, Value = pcall(function()
        local WorkspaceChildren = workspace:GetChildren()
        return WorkspaceChildren[1].Name == "RyzenHub-Main" or nil
    end)
    return success
end

local function CreateWindow(Settings)
    assert(Settings, "To create a window, Settings must be passed.")
    assert(Settings.Name, "To create a window, Settings.Name must be passed.")
    assert(Settings.LoadingTitle, "To create a window, Settings.LoadingTitle must be passed.")
    assert(Settings.LoadingSubtitle, "To create a window, Settings.LoadingSubtitle must be passed.")
    assert(Settings.ConfigurationSaving, "To create a window, Settings.ConfigurationSaving must be passed.")
    assert(Settings.ConfigurationSaving.Enabled, "To create a window, Settings.ConfigurationSaving.Enabled must be passed.")
    assert(Settings.ConfigurationSaving.FolderName, "To create a window, Settings.ConfigurationSaving.FolderName must be passed.")
    assert(Settings.ConfigurationSaving.FileName, "To create a window, Settings.ConfigurationSaving.FileName must be passed.")
    assert(Settings.Discord, "To create a window, Settings.Discord must be passed.")
    assert(Settings.KeySystem, "To create a window, Settings.KeySystem must be passed.")
    assert(Settings.KeySettings, "To create a window, Settings.KeySettings must be passed.")

    if Settings.ConfigurationSaving.FileName ~= nil and not isfile(ConfigurationFolder.."/"..Settings.ConfigurationSaving.FileName..ConfigurationExtension) then
        local decodedtable = HttpService:JSONEncode({})
        writefile(ConfigurationFolder.."/"..Settings.ConfigurationSaving.FileName..ConfigurationExtension, decodedtable)
    end

    local RyzenHub = game:GetObjects("rbxassetid://12364179275")[1]
    if not RyzenHub then
        warn("Failed to load RyzenHub GUI asset")
        return nil
    end
    RyzenHub.Enabled = false

    if gethui then
        RyzenHub.Parent = gethui()
    elseif syn and syn.protect_gui then 
        syn.protect_gui(RyzenHub)
        RyzenHub.Parent = CoreGui
    elseif not useStudio and CoreGui:FindFirstChild("RobloxGui") then
        RyzenHub.Parent = CoreGui:FindFirstChild("RobloxGui")
    else
        RyzenHub.Parent = CoreGui
    end

    if gethui and not useStudio then
        for _, Interface in ipairs(gethui():GetChildren()) do
            if Interface.Name == RyzenHub.Name and Interface ~= RyzenHub then
                Interface.Enabled = false
                Interface.Name = "RyzenHub-Old"
            end
        end
    else
        for _, Interface in ipairs(CoreGui:GetChildren()) do
            if Interface.Name == RyzenHub.Name and Interface ~= RyzenHub then
                Interface.Enabled = false
                Interface.Name = "RyzenHub-Old"
            end
        end
    end

    local Window = {}

    RyzenHub.DisplayOrder = 100

    RyzenHubLibrary.Flags[Settings.ConfigurationSaving.FileName] = {}
    RyzenHubLibrary.Options = Settings

    local WindowSettings = RyzenHubLibrary.Flags[Settings.ConfigurationSaving.FileName]

    RyzenHub.Main.WindowClass.MainFrame.UIPadding.PaddingTop = UDim.new(0,UISettingsPadding)
    RyzenHub.Main.WindowClass.MainFrame.UIPadding.PaddingLeft = UDim.new(0,UISettingsPadding)
    RyzenHub.Main.WindowClass.MainFrame.UIPadding.PaddingRight = UDim.new(0,UISettingsPadding)

    RyzenHub.Main.WindowClass.Topbar.UIPadding.PaddingTop = UDim.new(0,UISettingsPadding)
    RyzenHub.Main.WindowClass.Topbar.UIPadding.PaddingLeft = UDim.new(0,UISettingsPadding)
    RyzenHub.Main.WindowClass.Topbar.UIPadding.PaddingRight = UDim.new(0,UISettingsPadding)

    RyzenHub.Main.WindowClass.Topbar.TopbarTitle.UIPadding.PaddingLeft = UDim.new(0,UISettingsPadding)

    RyzenHub.Main.WindowClass.Topbar.TopbarTitle.Text = Settings.Name
    RyzenHub.Main.WindowClass.Size = UDim2.fromOffset(UISettings.TabWidth + (UISettingsPadding * 3) + 1, 38)

    local NotificationStoryboard = Instance.new("Frame")
    NotificationStoryboard.Name = "NotificationStoryboard"
    NotificationStoryboard.Parent = RyzenHub
    NotificationStoryboard.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    NotificationStoryboard.BackgroundTransparency = 1
    NotificationStoryboard.ClipsDescendants = true
    NotificationStoryboard.Position = UDim2.new(1, -305, 0.949000001, -500)
    NotificationStoryboard.Size = UDim2.new(0, 295, 0, 1333)
    NotificationStoryboard.Visible = true

    local NotificationStoryboardUIListLayout = Instance.new("UIListLayout")
    NotificationStoryboardUIListLayout.Name = "NotificationStoryboardUIListLayout"
    NotificationStoryboardUIListLayout.Parent = NotificationStoryboard
    NotificationStoryboardUIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    NotificationStoryboardUIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    NotificationStoryboardUIListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    NotificationStoryboardUIListLayout.Padding = UDim.new(0, 15)

    local NotificationStoryboardUIPadding = Instance.new("UIPadding")
    NotificationStoryboardUIPadding.Name = "NotificationStoryboardUIPadding"
    NotificationStoryboardUIPadding.Parent = NotificationStoryboard
    NotificationStoryboardUIPadding.PaddingBottom = UDim.new(0, 15)
    NotificationStoryboardUIPadding.PaddingRight = UDim.new(0, 15)

    RyzenHubLibrary.Load = {
        Main = RyzenHub,
        LoadingFrame = RyzenHub.LoadingFrame,
        Notifications = NotificationStoryboard
    }

    local CloseButton = RyzenHub.Main.WindowClass.Topbar:FindFirstChild("CloseButton")
    if CloseButton then
        local success, err = pcall(function()
            CloseButton.MouseButton1Click:Connect(function()
                if RyzenHub.Opened then
                    RyzenHub:Destroy()
                end
            end)
        end)
        if not success then
            warn("Error with CloseButton: ", err)
        end
    else
        warn("CloseButton not found in GUI structure")
    end

    function RyzenHubLibrary:Notify(Properties)
        local title = Properties.Title or "Notification"
        local content = Properties.Content or "Content"
        local duration = Properties.Duration or 5
        local image = Properties.Image or 4483362458

        local Notification = RyzenHubLibrary.Elements.Template.Notification:Clone()
        if not Notification then
            warn("Notification template not found")
            return
        end
        Notification.Parent = RyzenHubLibrary.Load.Notifications
        Notification.Name = title
        Notification.Enabled = true

        Notification.Title.Text = title
        Notification.Content.Text = content
        Notification.Image.Image = image

        Notification.Title.TextTransparency = 1
        Notification.Content.TextTransparency = 1
        Notification.Title.TextColor3 = Color3.fromRGB(255, 255, 255)
        Notification.Content.TextColor3 = Color3.fromRGB(200, 200, 200)
        Notification.Image.ImageColor3 = Color3.fromRGB(0, 255, 150)
        Notification.Image.ImageTransparency = 1

        Notification.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        Notification.BackgroundTransparency = 1

        Notification.Size = UDim2.new(0, 400, 0, 100)
        Notification.Position = UDim2.new(0, -400, 0, 0)

        tweenService:Create(Notification, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {Position = UDim2.new(0, 0, 0, 0)}):Play()
        task.wait(0.3)
        tweenService:Create(Notification, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.2}):Play()
        task.wait(0.1)
        tweenService:Create(Notification.Title, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
        tweenService:Create(Notification.Content, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextTransparency = 0.1}):Play()
        tweenService:Create(Notification.Image, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {ImageTransparency = 0.2}):Play()

        task.wait(duration)

        tweenService:Create(Notification.Title, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextTransparency = 0.4}):Play()
        tweenService:Create(Notification.Content, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextTransparency = 0.5}):Play()
        tweenService:Create(Notification.Image, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {ImageTransparency = 0.4}):Play()

        task.wait(0.2)

        tweenService:Create(Notification, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()

        task.wait(0.3)
        Notification:TweenPosition(UDim2.new(1, 0, Notification.Position.Y.Scale, Notification.Position.Y.Offset), Enum.EasingDirection.InOut, Enum.EasingStyle.Linear, 0.3, true)
        task.wait(0.35)
        Notification:Destroy()
    end

    function RyzenHubLibrary:LoadConfiguration()
        if Settings.ConfigurationSaving.Enabled then
            local success, encodedtable = pcall(function()
                return HttpService:JSONDecode(readfile(ConfigurationFolder.."/"..Settings.ConfigurationSaving.FileName..ConfigurationExtension))
            end)

            if success and type(encodedtable) == "table" then
                for _, Tab in ipairs(RyzenHub.Main.TabList:GetChildren()) do
                    if Tab.ClassName == "Frame" then
                        for _, Section in ipairs(Tab.SectionList:GetChildren()) do
                            if Section.ClassName == "Frame" then
                                for _, Element in ipairs(Section.Elements.Container:GetChildren()) do
                                    if Element.ClassName == "Frame" and Element:FindFirstChild("ElementFlag") then
                                        local Flag = Element.ElementFlag.Value
                                        local CanFireFlag = true
                                        if RyzenHubLibrary.Flags[Flag] then
                                            local Value = encodedtable[Flag]
                                            if RyzenHubLibrary.Flags[Flag] == Value then
                                                CanFireFlag = false
                                            end
                                            RyzenHubLibrary.Flags[Flag] = Value
                                            local Success, Error = pcall(function()
                                                Element.ElementFunction(Value, true)
                                            end)
                                            if not Success then
                                                warn("Ryzen Hub | "..Element.ElementType.." Error (Flag = '"..Flag.."'): "..Error)
                                            end
                                            if RyzenHubLibrary.Options[Flag] then
                                                if RyzenHubLibrary.Options[Flag].CurrentValue ~= Value then
                                                    RyzenHubLibrary.Options[Flag].CurrentValue = Value
                                                end
                                                if RyzenHubLibrary.Options[Flag].Callback and CanFireFlag then
                                                    local Success, Error = pcall(function()
                                                        RyzenHubLibrary.Options[Flag].Callback(Value, true)
                                                    end)
                                                    if not Success then
                                                        warn("Ryzen Hub | "..Element.ElementType.." Callback Error (Flag = '"..Flag.."'): "..Error)
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    task.delay(4, function()
        RyzenHubLibrary:LoadConfiguration()
        if RyzenHub.Main:FindFirstChild('Notice') and RyzenHub.Main.Notice.Visible then
            TweenService:Create(RyzenHub.Main.Notice, TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut), {Size = UDim2.new(0, 100, 0, 25), Position = UDim2.new(0.5, 0, 0, -100), BackgroundTransparency = 1}):Play()
            TweenService:Create(RyzenHub.Main.Notice.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()

            task.wait(0.5)
            RyzenHub.Main.Notice.Visible = false
        end
    end)

    return RyzenHubLibrary
end

local WindowSettings = {
    Name = "Ryzen Hub : 99 Night In The Forset",
    LoadingTitle = "Ryzen Hub",
    LoadingSubtitle = "by Ryzen Team",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = ConfigurationFolder,
        FileName = "RyzenHubSettings",
    },
    Discord = {
        Enabled = true,
        Invite = "https://discord.gg/QyywQ67c",
        ShowInvite = true,
    },
    KeySystem = true,
    KeySettings = {
        Title = "Ryzen Hub Key",
        Subtitle = "Key System",
        Note = "Join the discord for more information.",
        Key = "jotoro",
    }
}

local success, result = pcall(CreateWindow, WindowSettings)
if not success then
    warn("Failed to create window: ", result)
end
