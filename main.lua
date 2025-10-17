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

-- Loads and executes a function hosted on a remote URL. Cancels the request if the requested URL takes too long to respond.
-- Errors with the function are caught and logged to the output
local function loadWithTimeout(url: string, timeout: number?): ...any
	assert(type(url) == "string", "Expected string, got " .. type(url))
	timeout = timeout or 5
	local requestCompleted = false
	local success, result = false, nil

	local requestThread = task.spawn(function()
		local fetchSuccess, fetchResult = pcall(game.HttpGet, game, url) -- game:HttpGet(url)
		-- If the request fails the content can be empty, even if fetchSuccess is true
		if not fetchSuccess or #fetchResult == 0 then
			if #fetchResult == 0 then
				fetchResult = "Empty response" -- Set the error message
			end
			success, result = false, fetchResult
			requestCompleted = true
			return
		end
		local content = fetchResult -- Fetched content
		local execSuccess, execResult = pcall(function()
			return loadstring(content)()
		end)
		success, result = execSuccess, execResult
		requestCompleted = true
	end)

	local timeoutThread = task.delay(timeout, function()
		if not requestCompleted then
			warn(`Request for {url} timed out after {timeout} seconds`)
			task.cancel(requestThread)
			result = "Request timed out"
			requestCompleted = true
		end
	end)

	-- Wait for completion or timeout
	while not requestCompleted do
		task.wait()
	end
	-- Cancel timeout thread if still running when request completes
	if coroutine.status(timeoutThread) ~= "dead" then
		task.cancel(timeoutThread)
	end
	if not success then
		warn(`Failed to process {url}: {result}`)
	end
	return if success then result else nil
end

local requestsDisabled = true --getgenv and getgenv().DISABLE_RYZENHUB_REQUESTS
local InterfaceBuild = '3K3W'
local Release = "Build 1.68"
local RyzenHubFolder = "RyzenHub"
local ConfigurationFolder = RyzenHubFolder.."/Configurations"
local ConfigurationExtension = ".rfld"
local settingsTable = {
	General = {
		-- if needs be in order just make getSetting(name)
		ryzenhubOpen = {Type = 'bind', Value = 'K', Name = 'Ryzen Hub Keybind'},
		-- buildwarnings
		-- ryzenhubprompts

	},
	System = {
		usageAnalytics = {Type = 'toggle', Value = true, Name = 'Anonymised Analytics'},
	}
}

-- Settings that have been overridden by the developer. These will not be saved to the user's configuration file
-- Overridden settings always take precedence over settings in the configuration file, and are cleared if the user changes the setting in the UI
local overriddenSettings: { [string]: any } = {} -- For example, overriddenSettings["System.ryzenhubOpen"] = "J"

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

-- If requests/analytics have been disabled by developer, set the user-facing setting to false as well
if requestsDisabled then
	overrideSetting("System", "usageAnalytics", false)
end

local HttpService = getService('HttpService')
local RunService = getService('RunService')

-- Environment Check
local useStudio = RunService:IsStudio() or false

local settingsCreated = false
local settingsInitialized = false -- Whether the UI elements in the settings page have been set to the proper values
local cachedSettings
local prompt = useStudio and require(script.Parent.prompt) or loadWithTimeout('https://raw.githubusercontent.com/Ryzen-hub-dev/99-night-in-the-forset/refs/heads/main/propmt.lua')
local requestFunc = (syn and syn.request) or (fluxus and fluxus.request) or (http and http.request) or http_request or request

-- Validate prompt loaded correctly
if not prompt and not useStudio then
	warn("Failed to load prompt library, using fallback")
	prompt = {
		create = function() end -- No-op fallback
	}
end



local function loadSettings()
	local file = nil

	local success, result =	pcall(function()
		task.spawn(function()
			if isfolder and isfolder(RyzenHubFolder) then
				if isfile and isfile(RyzenHubFolder..'/settings'..ConfigurationExtension) then
					file = readfile(RyzenHubFolder..'/settings'..ConfigurationExtension)
				end
			end

			-- for debug in studio
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
								setting.Element:Set(getSetting(categoryName, settingName))
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

local InputService = getService('UserInputService')
local TweenService = getService('TweenService')
local HttpService = getService('HttpService')
local RunService = getService('RunService')
local Players = getService('Players')
local LocalPlayer = Players.LocalPlayer

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
	if ThemeEnabled and RyzenHubLibrary.Options.Themeable[Option] ~= nil then
		return RyzenHubLibrary.Options.Themeable[Option]
	end

	return RyzenHubLibrary.Theme.Default[Option]
end

local function InValidWorkspace()
	local success, Value = pcall(function()
		local WorkspaceChildren = workspace:GetChildren()
		return WorkspaceChildren[1].Name == "Rayfield-Main" or nil
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

	local Rayfield = game:GetObjects("rbxassetid://12364179275")[1]
	Rayfield.Enabled = false

	if gethui then
		Rayfield.Parent = gethui()
	elseif syn.protect_gui then 
		syn.protect_gui(Rayfield)
		Rayfield.Parent = CoreGui
	elseif not useStudio and CoreGui:FindFirstChild("RobloxGui") then
		Rayfield.Parent = CoreGui:FindFirstChild("RobloxGui")
	else
		Rayfield.Parent = CoreGui
	end

	if gethui and not useStudio then
		for _, Interface in ipairs(gethui():GetChildren()) do
			if Interface.Name == Rayfield.Name and Interface ~= Rayfield then
				Interface.Enabled = false
				Interface.Name = "Rayfield-Old"
			end
		end
	else
		for _, Interface in ipairs(CoreGui:GetChildren()) do
			if Interface.Name == Rayfield.Name and Interface ~= Rayfield then
				Interface.Enabled = false
				Interface.Name = "Rayfield-Old"
			end
		end
	end

	-- if not Settings.ConfigurationSaving.Enabled then
	-- 	warn("Configuration Saving is disabled.")
	-- end

	local Window = {}

	Rayfield.DisplayOrder = 100

	-- UI Settings
	RyzenHubLibrary.Flags[Settings.ConfigurationSaving.FileName] = {}
	RyzenHubLibrary.Options = Settings

	local WindowSettings = RyzenHubLibrary.Flags[Settings.ConfigurationSaving.FileName]

	Rayfield.Main.WindowClass.MainFrame.UIPadding.PaddingTop = UDim.new(0,UISettingsPadding)
	Rayfield.Main.WindowClass.MainFrame.UIPadding.PaddingLeft = UDim.new(0,UISettingsPadding)
	Rayfield.Main.WindowClass.MainFrame.UIPadding.PaddingRight = UDim.new(0,UISettingsPadding)

	Rayfield.Main.WindowClass.Topbar.UIPadding.PaddingTop = UDim.new(0,UISettingsPadding)
	Rayfield.Main.WindowClass.Topbar.UIPadding.PaddingLeft = UDim.new(0,UISettingsPadding)
	Rayfield.Main.WindowClass.Topbar.UIPadding.PaddingRight = UDim.new(0,UISettingsPadding)

	Rayfield.Main.WindowClass.Topbar.TopbarTitle.UIPadding.PaddingLeft = UDim.new(0,UISettingsPadding)

	Rayfield.Main.WindowClass.Topbar.TopbarTitle.Text = Settings.Name
	Rayfield.Main.WindowClass.Size = UDim2.fromOffset(UISettings.TabWidth + (UISettingsPadding * 3) + 1, 38)

	local NotificationStoryboard = Instance.new("Frame")
	NotificationStoryboard.Name = "NotificationStoryboard"
	NotificationStoryboard.Parent = Rayfield
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

	Rayfield.Main.BackgroundColor3 = ResolveColor("Background")
	Rayfield.Main.WindowClass.Topbar.BackgroundColor3 = ResolveColor("Topbar")
	Rayfield.Main.WindowClass.Shadow.Image.ImageColor3 = ResolveColor("Shadow")

	Rayfield.Main.WindowClass.Topbar.Line.BackgroundColor3 = ResolveColor("TabStroke")
	Rayfield.Main.WindowClass.Topbar.TopbarTitle.TextColor3 = ResolveColor("TextColor")

	Rayfield.Main.WindowClass.Tab.List.BackgroundColor3 = ResolveColor("TabBackground")
	Rayfield.Main.WindowClass.Tab.List.UIStroke.Color = ResolveColor("TabStroke")

	Rayfield.Main.WindowClass.Tab.ContainerHolder.BackgroundColor3 = ResolveColor("Background")


	Rayfield.Main.WindowClass.Topbar.TopbarTitle.Text = Settings.Name
	Rayfield.Main.Shadow.Image.ImageColor3 = GetOptionValue("Shadow")
	Rayfield.Main.Shadow.Image.ImageTransparency = 0.4

	Rayfield.Main.Topbar.CornerRepair.BackgroundColor3 = GetOptionValue("Topbar")
	Rayfield.Main.Topbar.Divider.BackgroundColor3 = GetOptionValue("Topbar")

	Rayfield.Main.Topbar.TopbarTitle.TextColor3 = GetOptionValue("TextColor")
	Rayfield.Main.Topbar.TopbarTitle.TextTransparency = 0

	Rayfield.Main.Topbar.Hide.ImageColor3 = GetOptionValue("TextColor")
	Rayfield.Main.Topbar.Hide.ImageTransparency = 0

	Rayfield.Main.Topbar.Minimize.ImageColor3 = GetOptionValue("TextColor")
	Rayfield.Main.Topbar.Minimize.ImageTransparency = 0

	for _, TopbarButton in ipairs(Rayfield.Main.Topbar:GetChildren()) do
		if TopbarButton.ClassName == "ImageButton" then
			TopbarButton.Size = UDim2.fromOffset(20, 20)
			TopbarButton.ImageColor3 = GetOptionValue("TextColor")
			TopbarButton.ImageTransparency = 0
		end
	end

	if Settings.Discord.Enabled and Settings.Discord.RememberJoins then -- We do funny work-arounds because the developer is nothing but a big old meanie who doesn't fit to their own style conventions!
		RyzenHubLibrary.Options.Discord.RememberJoins = false
	end

	if Settings.Discord.Enabled and Settings.Discord.InvitedUser then
		RyzenHubLibrary.Options.Discord.InvitedUser = false
	end

	if Settings.KeySystem then
		if not Settings.KeySettings then
			prompt and prompt.create(
				'Invalid Key Settings',
				'Please set KeySettings.Title, KeySettings.Subtitle, KeySettings.NoteMessage, KeySettings.MaxAttempts, KeySettings.KeyList, and KeySettings.Callback to proper values in order to use a key system.',
				'Okay',
				'',
				function() end
			)
			Rayfield:Destroy()
			return
		end

		local KeyNote = Settings.KeySettings.NoteMessage
		local KeyPlaceholder = Settings.KeySettings.Subtitle
		local KeyTitle = Settings.KeySettings.Title
		local KeySettingsCallback = Settings.KeySettings.Callback
		local KeyList = Settings.KeySettings.KeyList
		local KeyMaxAttempts = Settings.KeySettings.MaxAttempts or 3
		local KeyAttempts = 0

		local KeyUI = game:GetObjects("rbxassetid://12364179275")[1]
		KeyUI.Name = "KeyUI"
		KeyUI.Parent = Rayfield

		KeyUI.KeyboxFrame.Keybox.PlaceholderText = KeyPlaceholder
		KeyUI.Title.Text = KeyTitle
		KeyUI.NoteMessage.Text = KeyNote

		KeyUI.KeyboxFrame.Keybox.FocusLost:Connect(function()
			if #KeyUI.KeyboxFrame.Keybox.Text == 0 then
				tweenService:Create(KeyUI.KeyboxFrame.Keybox, TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {BackgroundColor3 = Color3.fromRGB(30, 30, 30)}):Play()
				tweenService:Create(KeyUI.KeyboxFrame.Keybox, TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {TextColor3 = Color3.fromRGB(64, 64, 64)}):Play()
				KeyUI.KeyboxFrame.Keybox.PlaceholderColor3 = Color3.fromRGB(64, 64, 64)
			end
		end)

		KeyUI.KeyboxFrame.Keybox:GetPropertyChangedSignal("Text"):Connect(function()
			KeyUI.KeyboxFrame.Keybox.Text = KeyUI.KeyboxFrame.Keybox.Text:sub(1, 29)
		end)

		KeyUI.KeyboxFrame.Keybox.Focused:Connect(function()
			tweenService:Create(KeyUI.KeyboxFrame.Keybox, TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {BackgroundColor3 = Color3.fromRGB(37, 37, 37)}):Play()
			tweenService:Create(KeyUI.KeyboxFrame.Keybox, TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
			KeyUI.KeyboxFrame.Keybox.PlaceholderColor3 = Color3.fromRGB(255, 255, 255)
		end)

		KeyUI.KeyboxFrame.Keybox.FocusLost:Connect(function(enterPressed)
			if enterPressed then
				local KeyFound = false
				local Key = KeyUI.KeyboxFrame.Keybox.Text
				if table.find(KeyList, Key) then
					KeyFound = true
				end

				if KeyFound then
					KeyAttempts = 0
					KeySettingsCallback(true, Key)
					KeyUI:Destroy()
				else
					KeyAttempts = KeyAttempts + 1
					if KeyAttempts >= KeyMaxAttempts then
						KeyUI:Destroy()
						KeySettingsCallback(false)
						game:Shutdown()
					else
						KeyUI.KeyboxFrame.Keybox.Text = ""
						KeyUI.KeyboxFrame.Keybox.PlaceholderText = "Invalid Key"
						task.wait(1)
						KeyUI.KeyboxFrame.Keybox.PlaceholderText = KeyPlaceholder
					end
				end
			end
		end)

		KeyUI.InputBegan:Connect(function(input)
			if input.KeyCode == Enum.KeyCode.Escape then
				KeyUI:Destroy()
				KeySettingsCallback(false)
				game:Shutdown()
			end
		end)
	else
		Rayfield.Enabled = true
	end

	-- Set Flags
	local WindowFunction = {}

	function WindowFunction:Notify(NotificationSettings)
		local ActionCompleted = true
		local Notification = Rayfield.Notification:Clone()
		Notification.Parent = NotificationStoryboard
		Notification.Name = NotificationSettings.Title or "Unknown Title"
		Notification.Enabled = true

		Notification.Title.Text = NotificationSettings.Title or "Unknown Title"
		Notification.Description.Text = NotificationSettings.Content or "Unknown Content"
		if NotificationSettings.Image then
			Notification.Icon.Image = "rbxassetid://"..tostring(NotificationSettings.Image)
		else
			Notification.Icon.Image = "rbxassetid://4483345998"
		end

		Notification.Title.TextTransparency = 1
		Notification.Description.TextTransparency = 1
		Notification.Title.TextColor3 = GetOptionValue("TextColor")
		Notification.Description.TextColor3 = GetOptionValue("TextColor")
		Notification.Icon.ImageColor3 = GetOptionValue("TextColor")
		Notification.Icon.ImageTransparency = 1

		if NotificationSettings.Actions then
			for ActionName, ActionSettings in NotificationSettings.Actions do
				local Action = Notification.Actions.Action:Clone()
				Action.Name = ActionName or "Action"
				Action.Enabled = true
				Action.Parent = Notification.Actions
				Action.Text = ActionSettings.Name or "Action"
				Action.BackgroundColor3 = GetOptionValue("Background")
				Action.TextColor3 = GetOptionValue("TextColor")
				Action.BackgroundTransparency = 1
				Action.TextTransparency = 1
				Action.BackgroundTransparency = 1

				Action.MouseButton1Click:Connect(function()
					local Success = pcall(ActionSettings.Callback)
					if not Success then
						print("Ryzen Hub | Action: "..ActionName.." Callback Error ".."Updating Ryzen Hub may fix this issue")
					else
						print("Ryzen Hub | Action: "..ActionName.." Callback Success")
					end
				end)
			end
		else
			Notification.Actions:Destroy()
		end

		Notification.BackgroundColor3 = GetOptionValue("Background")
		Notification.BackgroundTransparency = 1

		Notification.Size = UDim2.fromOffset(295, Notification.UIListLayout.AbsoluteContentSize.Y + 10)
		Notification.Position = UDim2.fromOffset(915, 80)
		Notification.Position = UDim2.fromOffset(-500, Notification.Position.Y.Offset)

		TweenService:Create(Notification, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {Position = UDim2.fromOffset(0, Notification.Position.Y.Offset)}):Play()
		task.wait(0.3)
		TweenService:Create(Notification, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.3}):Play()
		task.wait(0.1)
		TweenService:Create(Notification.Title, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
		TweenService:Create(Notification.Description, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextTransparency = 0.1}):Play()
		TweenService:Create(Notification.Icon, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {ImageTransparency = 0.2}):Play()

		for _, Action in ipairs(Notification.Actions:GetChildren()) do
			if Action:IsA("TextButton") and Action.Name ~= "Template" then
				TweenService:Create(Action, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 0.45}):Play()
				TweenService:Create(Action, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextTransparency = 0.1}):Play()
			end
		end

		task.wait(NotificationSettings.Duration or NotificationSettings.Delay or 5)

		TweenService:Create(Notification.Title, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextTransparency = 0.4}):Play()
		TweenService:Create(Notification.Description, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextTransparency = 0.5}):Play()
		TweenService:Create(Notification.Icon, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {ImageTransparency = 0.4}):Play()

		for _, Action in ipairs(Notification.Actions:GetChildren()) do
			if Action:IsA("TextButton") and Action.Name ~= "Template" then
				TweenService:Create(Action, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
				TweenService:Create(Action, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextTransparency = 0.4}):Play()
			end
		end

		task.wait(0.2)

		TweenService:Create(Notification, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()

		task.wait(0.3)
		Notification:TweenPosition(UDim2.new(2, 0, Notification.Position.Y.Scale, Notification.Position.Y.Offset), Enum.EasingDirection.InOut, Enum.EasingStyle.Linear, 0.3, true)
		task.wait(0.35)
		Notification:Destroy()
	end

	function WindowFunction:LoadConfiguration()
		if Settings.ConfigurationSaving.Enabled then
			local success, encodedtable = pcall(function()
				return HttpService:JSONDecode(readfile(ConfigurationFolder.."/"..Settings.ConfigurationSaving.FileName..ConfigurationExtension))
			end)

			if success and type(encodedtable) == "table" then
				for _, Tab in ipairs(Rayfield.Main.TabList:GetChildren()) do
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

	function WindowFunction:SaveConfiguration()
		if Settings.ConfigurationSaving.Enabled then
			local sub = ""
			if Settings.ConfigurationSaving.FolderName then
				sub = Settings.ConfigurationSaving.FolderName.."/"
			end
			local encodedtable = HttpService:JSONEncode(RyzenHubLibrary.Flags)
			writefile(ConfigurationFolder.."/"..sub..Settings.ConfigurationSaving.FileName..ConfigurationExtension, encodedtable)
		end
	end

	function WindowFunction:Unload()
		for _, unloadCallback in ipairs(RyzenHubLibrary.Signals) do
			if unloadCallback then
				local success, err = pcall(unloadCallback)
				if not success then
					pcall(function()
						warn("Ryzen Hub | Unload Error: "..err)
					end)
				end
			end
		end

		for _, Tab in ipairs(Rayfield.Main.TabList:GetChildren()) do
			if Tab.ClassName == "Frame" then
				Tab:Destroy()
			end
		end

		Rayfield:Destroy()
		WindowFunction = nil
	end

	function WindowFunction:Destroy()
		Rayfield:Destroy()
	end

	function WindowFunction:ModifyTheme(ThemeSettings)
		if not RyzenHubLibrary.Options.Themeable or (not RyzenHubLibrary.Options.Themeable.Enabled and RyzenHubLibrary.Options.Themeable.Enabled ~= nil) then
			return
		end

		local OldTheme = RyzenHubLibrary.Theme

		if RyzenHubLibrary.Options.Themeable then
			for Option, Color in ThemeSettings do -- Loop through all of the options provided, and set them
				if RyzenHubLibrary.Options.Themeable[Option] == false then
					return
				end
				if RyzenHubLibrary.Theme.Default[Option] then
					if RyzenHubLibrary.Options.Themeable[Option] ~= nil then
						RyzenHubLibrary.Options.Themeable[Option] = Color
					end

					RyzenHubLibrary.Theme.Default[Option] = Color
				end
			end
		end

		for _, Element in ipairs(RyzenHubLibrary.Elements) do
			if Element.Type ~= "Toggle" and Element.ColorConfig ~= false then
				pcall(function()
					local Name, Transparency = Element.Name, (Element.Transparency or 0)
					Element.BackgroundColor3 = ElementEnabled("ElementBackground") and GetOptionValue("ElementBackground") or OldTheme.ElementBackground
					Element.BackgroundTransparency = Transparency
					Element.UIStroke.Color = ElementEnabled("ElementStroke") and GetOptionValue("ElementStroke") or OldTheme.ElementStroke
				end)
			end
		end

		pcall(function()
			Rayfield.Main.BackgroundColor3 = GetOptionValue("Background")
			Rayfield.Main.Topbar.BackgroundColor3 = GetOptionValue("Topbar")
			Rayfield.Main.Topbar.CornerRepair.BackgroundColor3 = GetOptionValue("Topbar")
			Rayfield.Main.Shadow.Image.ImageColor3 = GetOptionValue("Shadow")

			Rayfield.Main.Topbar.Line.BackgroundColor3 = GetOptionValue("Topbar")
			Rayfield.Main.Topbar.TopbarTitle.TextColor3 = GetOptionValue("TextColor")
			Rayfield.Main.Shadow.Image.ImageTransparency = 0.4

			Rayfield.Main.Topbar.Divider.BackgroundColor3 = GetOptionValue("Topbar")

			Rayfield.Main.Topbar.TopbarTitle.TextColor3 = GetOptionValue("TextColor")
			Rayfield.Main.Topbar.TopbarTitle.TextTransparency = 0

			Rayfield.Main.Topbar.Hide.ImageColor3 = GetOptionValue("TextColor")
			Rayfield.Main.Topbar.Hide.ImageTransparency = 0

			Rayfield.Main.Topbar.Minimize.ImageColor3 = GetOptionValue("TextColor")
			Rayfield.Main.Topbar.Minimize.ImageTransparency = 0
		end)

		for _, TabButton in ipairs(Rayfield.Main.TabList:GetChildren()) do
			if TabButton.ClassName == "Frame" and TabButton.Name ~= "Placeholder" then
				pcall(function()
					if TabButton.Background.UIStroke and TabButton.Background.InputBegin then
						if not TabButton.Background.Size == UDim2.fromOffset(0, 30) then
							TabButton.Background.Size = UDim2.fromOffset(0, 30)
							TabButton.Position = Rayfield.Main.TabList.Placeholder.Position
						end
						TabButton.Visible = true
						TabButton.Background.BackgroundColor3 = GetOptionValue("TabBackground") or OldTheme.TabBackground
						TabButton.Title.TextColor3 = GetOptionValue("TabTextColor") or OldTheme.TabTextColor
						TabButton.Background.UIStroke.Color = GetOptionValue("TabStroke") or OldTheme.TabStroke
						TabButton.Background.Size = UDim2.fromOffset(120, 30)
						TabButton.Background.UIStroke.Transparency = 0
					else
						TabButton.TabButton.UIStroke.Transparency = 0
						TabButton.TabButton.Title.TextTransparency = 0
						TabButton.TabButton.Size = UDim2.fromOffset(120, 30)
						TabButton.TabButton.Position = UDim2.fromOffset(0,0)
						TabButton.TabButton.Visible = true
						TabButton.Size = UDim2.fromOffset(120, 30)
						TabButton.Position = Rayfield.Main.TabList.Placeholder.Position
						TabButton.TabButton.BackgroundColor3 = GetOptionValue("TabBackground") or OldTheme.TabBackground
						TabButton.Title.TextColor3 = GetOptionValue("TabTextColor") or OldTheme.TabTextColor
						TabButton.TabButton.UIStroke.Color = GetOptionValue("TabStroke") or OldTheme.TabStroke
					end
				end)
			end
		end
	end

	local minimizeKeybind = Settings.MinimizeKeybind or Enum.KeyCode.LeftControl
	local guiHidden = false

	UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode[minimizeKeybind.Name] then
			guiHidden = not guiHidden

			if guiHidden then
				TweenService:Create(Rayfield.Main, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Size = UDim2.fromOffset(50, 25)}):Play()
			else
				TweenService:Create(Rayfield.Main, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Size = UDim2.fromOffset(500, 444)}):Play()
			end
		end
	end)

	if Settings.MinimizeKey then
		minimizeKeybind = Settings.MinimizeKey
	end

	local Window = {}

	function Window:CreateTab(Settings)
		assert(Settings, "To create a tab, you need to pass a table.")
		assert(Settings.Name, "To create a tab, you need to pass a table with a Name field.")

		local Tab = RyzenHubLibrary.Elements.Template:Clone()
		Tab.Name = Settings.Name
		Tab.Title.Text = Settings.Name
		Tab.Visible = false

		Tab.Parent = Rayfield.Main.TabList
		Tab.TabButton.Icon.Image = "rbxassetid://"..(Settings.Icon or "4483345998")
		Tab.TabButton.Icon.ImageTransparency = 0.5

		Tab.BackgroundColor3 = RyzenHubLibrary.Theme.Default.Background

		Tab.Title.TextColor3 = RyzenHubLibrary.Theme.Default.TabTextColor

		Tab.TabButton.UIStroke.Color = RyzenHubLibrary.Theme.Default.TabStroke
		Tab.TabButton.UIStroke.Transparency = 0.5

		Tab.TabButton.Title.TextColor3 = RyzenHubLibrary.Theme.Default.TabTextColor

		local TabButtonLabel = Tab.TabButton.Title

		local TabTitle = Tab.Title

		TabButtonLabel.TextColor3 = RyzenHubLibrary.Theme.Default.TextColor
		TabButtonLabel.TextTransparency = 0
		Tab.TabButton.BackgroundColor3 = RyzenHubLibrary.Theme.Default.TabBackground

		Tab.TabButton.Icon.ImageTransparency = 0
		Tab.TabButton.Icon.ImageColor3 = RyzenHubLibrary.Theme.Default.TextColor

		Tab.TabButton.Size = UDim2.fromOffset(120, 30)
		Tab.TabButton.Visible = true

		-- We need to add 40 pixles to the current X, then we add 15 for the size of each element
		local CurrentTabPositionHorizontal = #Rayfield.Main.TabList:GetChildren() - 2 + UISettingsPadding

		Tab.TabButton.Position = UDim2.fromOffset(CurrentTabPositionHorizontal,0)
		Tab.Position = UDim2.fromOffset(Tab.TabButton.Position.X.Offset,70)

		if ElementEnabled("TabBackground") then
			Tab.TabButton.BackgroundColor3 = GetOptionValue("TabBackground")
		end

		if ElementEnabled("TabStroke") then
			Tab.TabButton.UIStroke.Color = GetOptionValue("TabStroke")
		end

		if ElementEnabled("TabTextColor") then
			Tab.TabButton.Title.TextColor3 = GetOptionValue("TabTextColor")
		end

		if Settings.CurrentTab == true then
			TweenService:Create(Tab.TabButton, TweenInfo.new(0.11, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {BackgroundTransparency = 0, UIStrokeTransparency = 0}):Play()
			TweenService:Create(Tab.TabButton.Title, TweenInfo.new(0.11, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {TextTransparency = 0}):Play()
			TweenService:Create(Tab.TabButton.Icon, TweenInfo.new(0.11, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {ImageTransparency = 0}):Play()

			Tab.Visible = true
			TabTitle.TextTransparency = 0
			RyzenHubLibrary.CurrentTab = Tab
		else
			TweenService:Create(Tab.TabButton, TweenInfo.new(0.11, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.75, UIStrokeTransparency = 0.25}):Play()
			TweenService:Create(Tab.TabButton.Title, TweenInfo.new(0.11, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {TextTransparency = 0.2}):Play()
			TweenService:Create(Tab.TabButton.Icon, TweenInfo.new(0.11, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {ImageTransparency = 0.2}):Play()

			Tab.Visible = false
			TabTitle.TextTransparency = 1
		end

		Tab.Interact.MouseEnter:Connect(function()
			if RyzenHubLibrary.CurrentTab.Name ~= Tab.Name then
				TweenService:Create(Tab.TabButton, TweenInfo.new(0.11, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.3, UIStrokeTransparency = 0.25}):Play()
				TweenService:Create(Tab.TabButton.Title, TweenInfo.new(0.11, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {TextTransparency = 0.2}):Play()
				TweenService:Create(Tab.TabButton.Icon, TweenInfo.new(0.11, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {ImageTransparency = 0.2}):Play()
			end
		end)

		Tab.Interact.MouseLeave:Connect(function()
			if RyzenHubLibrary.CurrentTab.Name ~= Tab.Name then
				TweenService:Create(Tab.TabButton, TweenInfo.new(0.11, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.75, UIStrokeTransparency = 0.25}):Play()
				TweenService:Create(Tab.TabButton.Title, TweenInfo.new(0.11, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {TextTransparency = 0.2}):Play()
				TweenService:Create(Tab.TabButton.Icon, TweenInfo.new(0.11, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {ImageTransparency = 0.2}):Play()
			end
		end)

		Tab.Interact.MouseButton1Click:Connect(function()
			if RyzenHubLibrary.CurrentTab.Name ~= Tab.Name then
				for _, OtherTab in ipairs(Rayfield.Main.TabList:GetChildren()) do
					if OtherTab.Name ~= "Template" and OtherTab.ClassName == "Frame" and OtherTab ~= Tab and OtherTab.Visible then
						OtherTab.Visible = false
						OtherTab.Title.TextTransparency = 1
						TweenService:Create(OtherTab.TabButton, TweenInfo.new(0.11, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.75, UIStrokeTransparency = 0.25}):Play()
						TweenService:Create(OtherTab.TabButton.Title, TweenInfo.new(0.11, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {TextTransparency = 0.2}):Play()
						TweenService:Create(OtherTab.TabButton.Icon, TweenInfo.new(0.11, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {ImageTransparency = 0.2}):Play()
					end
				end
				Tab.Visible = true
				TabTitle.TextTransparency = 0
				TweenService:Create(Tab.TabButton, TweenInfo.new(0.11, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {BackgroundTransparency = 0, UIStrokeTransparency = 0}):Play()
				TweenService:Create(Tab.TabButton.Title, TweenInfo.new(0.11, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {TextTransparency = 0}):Play()
				TweenService:Create(Tab.TabButton.Icon, TweenInfo.new(0.11, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {ImageTransparency = 0}):Play()
				RyzenHubLibrary.CurrentTab = Tab
			end
		end)

		local TabFunctions = {}

		function TabFunctions:CreateSection(Settings)
			assert(Settings, "To create a section, you need to pass a table.")
			assert(Settings.Name, "To create a section, you need to pass a table with a Name field.")

			local Section = RyzenHubLibrary.Elements.Template.SectionTemplate:Clone()
			Section.Visible = true
			Section.Parent = Tab.Container

			Section.SectionTitle.Text = Settings.Name

			Section.SectionTitle.TextColor3 = GetOptionValue("TextColor")
			Section.SectionTitle.TextTransparency = 0

			Section.SectionBackground.BackgroundColor3 = GetOptionValue("Background")
			Section.SectionBackground.BackgroundTransparency = 0.7

			Section.UIStroke.Color = GetOptionValue("ElementStroke")
			Section.UIStroke.Transparency = 0

			Section.Line.BackgroundColor3 = GetOptionValue("ElementStroke")
			Section.Line.Transparency = 0

			local function FitSizePadding(ListLayoutPadding)
				Section.Size = UDim2.new(1, 0, 0, Section.UIListLayout.AbsoluteContentSize.Y + ListLayoutPadding)
			end

			FitSizePadding(35)

			Section.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				FitSizePadding(35)
			end)

			local SectionFunction = {}

			for _, Element in ipairs(RyzenHubLibrary.Elements) do
				for ElementName, ElementSettings in pairs(Element) do
					local ElementModule = require(ElementSettings.Module)

					local NewElement = {}

					NewElement = ElementModule(RyzenHubLibrary, Section.Container, ElementSettings)
					RyzenHubLibrary.Elements[ElementName] = NewElement
				end
			end

			return SectionFunction
		end

		return TabFunctions
	end

	return Window
end

task.delay(4, function()
	RyzenHubLibrary.LoadConfiguration()
	if Main:FindFirstChild('Notice') and Main.Notice.Visible then
		TweenService:Create(Main.Notice, TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut), {Size = UDim2.new(0, 100, 0, 25), Position = UDim2.new(0.5, 0, 0, -100), BackgroundTransparency = 1}):Play()
		TweenService:Create(Main.Notice.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()

		task.wait(0.5)
		Main.Notice.Visible = false
	end
end)

return RyzenHubLibrary
