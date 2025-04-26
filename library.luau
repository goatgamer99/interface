--[[

	                                            $$\ $$\   $$\     $$\       
	                                            $$ |\__|  $$ |    $$ |      
	$$$$$$\$$$$\   $$$$$$\  $$$$$$$\   $$$$$$\  $$ |$$\ $$$$$$\   $$$$$$$\  
	$$  _$$  _$$\ $$  __$$\ $$  __$$\ $$  __$$\ $$ |$$ |\_$$  _|  $$  __$$\ 
	$$ / $$ / $$ |$$ /  $$ |$$ |  $$ |$$ /  $$ |$$ |$$ |  $$ |    $$ |  $$ |
	$$ | $$ | $$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |$$ |$$ |  $$ |$$\ $$ |  $$ |
	$$ | $$ | $$ |\$$$$$$  |$$ |  $$ |\$$$$$$  |$$ |$$ |  \$$$$  |$$ |  $$ |
	\__| \__| \__| \______/ \__|  \__| \______/ \__|\__|   \____/ \__|  \__|
	                                                                        
	- Made by wis_h (837050650537099346)
	- https://discord.gg/uilibrary

--]]

--[[ LIBRARY DATA ]]-------------------------------------------------
local Library = { 
	Flags = {}, 
	Selected = {},
	Opened = {},
	Connections = {},
	Theme = {
		Font = nil;
		Accent = Color3.fromRGB(170, 85, 235),
		Background = Color3.fromRGB(15, 15, 15),
		Foreground = Color3.fromRGB(13, 13, 13),

		Text = {
			Selected = Color3.fromRGB(170, 85, 235),
			Unselected = Color3.fromRGB(160, 160, 160)
		},

		Advanced = {
			["Tab Buttons"] = {
				Gradient_S = ColorSequence.new{
					ColorSequenceKeypoint.new(0, Color3.fromRGB(41,41,41)), 
					ColorSequenceKeypoint.new(1, Color3.fromRGB(25,25,25))
				},
				Gradient_US = ColorSequence.new{
					ColorSequenceKeypoint.new(0, Color3.fromRGB(41,41,41)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(16,16,16))
				},
			}
		}
	}
}; Library.__index = Library

local Interface = game:GetObjects("rbxassetid://122926268524410")[1]
local Components = game:GetObjects("rbxassetid://137759892465099")[1]

local Typeface = loadstring(game:HttpGet("https://roblo-x.com/scripts/typeface.lua"))()
Library.Theme.Font = Typeface:Register("fonts", {
	name = "font",
	link = "https://roblo-x.com/files/tahoma.ttf",
	weight = "Regular",
	style = "Normal"
})

--[[ DEPENDENCIES ]]-------------------------------------------------
local GuiService = game:GetService("GuiService")
local InputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local PlayerService = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = PlayerService.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

--[[ FUNCTIONS ]]----------------------------------------------------
function Library.Create(class : string, properties : {})
	local i
	local madeInstance, errorMessage = pcall(function()
		i = Instance.new(class)    
	end)

	if not madeInstance then
		warn("Failed to create instance of class: " .. class)
		return error(errorMessage, 99)
	end

	for property, value in pairs(properties) do
		local success, err = pcall(function()
			i[property] = value
		end)
		if not success then 
			warn("Problem adding property '" .. property .. "' to instance of class '" .. class .. "': " .. err)
		end
	end

	return i or nil
end

function Library.Overwrite(to_overwrite : {}, overwrite_with : {})
	for i, v in pairs(overwrite_with) do
		if type(v) == 'table' then
			to_overwrite[i] = Library.Overwrite(to_overwrite[i] or {}, v)
		else
			to_overwrite[i] = v
		end
	end

	return to_overwrite or nil
end

function Library.Round(number, float) 
	local multiplier = 1 / (float or 1)
	return math.floor(number * multiplier + 0.5) / multiplier
end 

function Library.Connection(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(Library.Connections, connection)
	return connection 
end

function Library.MakeDraggable(Frame)
	local isDragging = false
	local dragInput = nil
	local dragStart = nil
	local StartPosition = nil

	local function updatePosition(input)
		local delta = input.Position - dragStart
		Frame.Position = UDim2.new(
			StartPosition.X.Scale, 
			StartPosition.X.Offset + delta.X,
			StartPosition.Y.Scale, 
			StartPosition.Y.Offset + delta.Y
		)
	end

	Frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isDragging = true
			dragStart = input.Position
			StartPosition = Frame.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					isDragging = false
				end
			end)
		end
	end)

	Frame.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	InputService.InputChanged:Connect(function(input)
		if input == dragInput and isDragging then
			updatePosition(input)
		end
	end)
end

function Library.LerpColor3(colorA, colorB, alpha)
	return Color3.new(
		colorA.R + (colorB.R - colorA.R) * alpha,
		colorA.G + (colorB.G - colorA.G) * alpha,
		colorA.B + (colorB.B - colorA.B) * alpha
	)
end

function Library.TweenGradient(uiGradient, targetGradient, duration)
	local tweenValue = Instance.new("NumberValue")
	tweenValue.Value = 0

	local startGradient = uiGradient.Color
	local startKeypoints = startGradient.Keypoints
	local targetKeypoints = targetGradient.Keypoints

	local connection = tweenValue.Changed:Connect(function()
		local alpha = tweenValue.Value
		local newKeypoints = table.create(#startKeypoints)

		for i = 1, #startKeypoints do
			local startKeypoint = startKeypoints[i]
			local targetKeypoint = targetKeypoints[i]

			local lerpedColor = Library.LerpColor3(startKeypoint.Value, targetKeypoint.Value, alpha)
			newKeypoints[i] = ColorSequenceKeypoint.new(startKeypoint.Time, lerpedColor)
		end

		uiGradient.Color = ColorSequence.new(newKeypoints)
	end)

	local tween = TweenService:Create( tweenValue, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Value = 1} )
	tween:Play()

	tween.Completed:Connect(function()
		connection:Disconnect()
		tweenValue:Destroy()
	end)

	return tween
end

function Library.MakeResizable(frame, minSize)
	minSize = minSize or Vector2.new(50, 50)

	local resizeHandle = Instance.new("TextButton")
	resizeHandle.Size = UDim2.new(0, 10, 0, 10)
	resizeHandle.Position = UDim2.new(1, -10, 1, -10)
	resizeHandle.BackgroundTransparency = 1
	resizeHandle.Text = ""
	resizeHandle.Name = "handle"
	resizeHandle.ZIndex = 10
	resizeHandle.Parent = frame

	local dragging = false
	local dragStartPos
	local startSize

	local connections = {}

	table.insert(connections, resizeHandle.MouseButton1Down:Connect(function()
		dragging = true
		dragStartPos = InputService:GetMouseLocation()
		startSize = frame.Size
	end))

	table.insert(connections, InputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local mousePos = InputService:GetMouseLocation()
			local delta = mousePos - dragStartPos

			local newWidth = startSize.X.Offset + delta.X
			local newHeight = startSize.Y.Offset + delta.Y

			newWidth = math.max(minSize.X, newWidth)
			newHeight = math.max(minSize.Y, newHeight)

			frame.Size = UDim2.new(0, newWidth, 0, newHeight)
		end
	end))

	table.insert(connections, InputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end))

	local function cleanup()
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end

		if resizeHandle and resizeHandle.Parent then
			resizeHandle:Destroy()
		end
	end

	table.insert(connections, frame.AncestryChanged:Connect(function(_, newParent)
		if not newParent then
			cleanup()
		end
	end))

	return resizeHandle, cleanup
end

function Library:Toggle()
	Interface.Container.Visible = not Interface.Container.Visible
end

--[[ COMPONENT FUNCTIONS ]]----------------------------------------------------
function Library:AddKeypicker(Component)
	local Button
	
	if Component:FindFirstChild("Sub") then
		Button = Library.Create("TextButton", { Parent = Component.Sub, Name = [[Keypicker]], BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(255, 255, 255), TextSize = 12, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, BorderColor3 = Color3.fromRGB(0, 0, 0), Text = [[none]], FontFace = Library.Theme.Font, TextColor3 = Color3.fromRGB(205, 205, 205), BackgroundTransparency = 1,})
	else
		local Holder = Library.Create("Frame", { Parent = Component, Name = [[Sub]], AnchorPoint = Vector2.new(1, 0.5), BorderSizePixel = 0, Size = UDim2.new(0, 0, 1, 0), BorderColor3 = Color3.fromRGB(0, 0, 0), AutomaticSize = Enum.AutomaticSize.X, Position = UDim2.new(1, 0, 0.5, 0), BackgroundTransparency = 1, BackgroundColor3 = Color3.fromRGB(255, 255, 255),})
		Library.Create("UIListLayout", { Parent = Holder, VerticalAlignment = Enum.VerticalAlignment.Center, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Right,})
		return Library:AddKeypicker(Component)
	end

	return Button
end


--[[ CREATE UI ]]----------------------------------------------------
local Container = Interface.Container
local TabHolder = Container.Holder
local TabViewer = Container.Viewer

function Library:Window(...)
	local Window, Data = {}, {
		Title = "test",
		Size = UDim2.new(0,480,0,580),
		Position = UDim2.new(0.5,0,0.5,0),
		Anchor = Vector2.new(0,0),
	}; local cfg = Library.Overwrite(Data, ... or {})

	Interface.Parent = game:GetService("CoreGui")

	Container.TItle.FontFace = Library.Theme.Font
	Container.TItle.Text = cfg.Title

	Container.Size = cfg.Size
	Container.Position = cfg.Position
	Container.AnchorPoint = cfg.Anchor

	Library.MakeDraggable(Container)
	Library.MakeResizable(Container, Vector2.new(400, 400))

	function Window:Tab(...)
		local Tab, Data = {}, {
			Name = ""
		}; local cfg = Library.Overwrite(Data, ... or {})

		local TabButton = Components.TabButtonUnsel:Clone()
		local TabFrame = Components.Tab:Clone()

		TabFrame.Parent = TabHolder
		TabButton.Parent = TabViewer
		TabButton.Label.Text = cfg.Name
		TabButton.Label.FontFace = Library.Theme.Font

		function Tab.Select()
			if Library.Selected and Library.Selected[1] and Library.Selected[1] ~= TabButton then
				local Button = Library.Selected[1]
				if Library.Selected[2] then Library.Selected[2].Visible = false end

				TweenService:Create(
					Button.Label,
					TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{TextColor3 = Library.Theme.Text.Unselected}
				):Play()

				Library.TweenGradient(Button.Inline.UIGradient, Library.Theme.Advanced["Tab Buttons"].Gradient_US, 0.1)
			end

			Library.Selected = { TabButton, TabFrame }

			TweenService:Create(
				TabButton.Label,
				TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{TextColor3 = Library.Theme.Text.Selected}
			):Play()

			Library.TweenGradient(TabButton.Inline.UIGradient, Library.Theme.Advanced["Tab Buttons"].Gradient_S, 0.1)
			TabFrame.Visible = true
		end

		TabButton.MouseButton1Click:Connect(Tab.Select)

		function Tab:Section(...)
			local Section, Data = {}, {
				Name = "N/A",
				Side = "Left",
			}; local cfg = Library.Overwrite(Data, ... or {})

			local SectionFrame = Components.Section:Clone()
			SectionFrame.Parent = TabFrame[cfg.Side]

			SectionFrame.Title.Text = cfg.Name
			SectionFrame.Title.FontFace = Library.Theme.Font

			--[[ COMPONENTS ]]----------------------------------------------------
			do
				-- Toggle
				function Section:Toggle(Flag, ...)
					local Toggle, Data = {}, {
						Name = "N/A",
						Default = true,
						Callback = function() end
					}; local cfg = Library.Overwrite(Data, ... or {})

					local Enabled = cfg.Default
					local ToggleFrame = Components.SectionStuff.Toggle:Clone()
					ToggleFrame.Parent = SectionFrame.Container

					ToggleFrame.Title.Text = cfg.Name
					ToggleFrame.Title.FontFace = Library.Theme.Font

					function Toggle:Set(Value)
						if Value then
							TweenService:Create(ToggleFrame.Button.Inline, TweenInfo.new(0.1), {Transparency = 0}):Play()
							TweenService:Create(ToggleFrame.Title, TweenInfo.new(0.1), {TextColor3 = Color3.fromRGB(255,255,255)}):Play()
						else
							TweenService:Create(ToggleFrame.Button.Inline, TweenInfo.new(0.1), {Transparency = 1}):Play()
							TweenService:Create(ToggleFrame.Title, TweenInfo.new(0.1), {TextColor3 = Library.Theme.Text.Unselected}):Play()
						end

						Library.Flags[Flag] = Value
						local Callback = cfg.Callback
						Callback(Value)
					end

					function Toggle:Keybind(...)
						local Keybind, Data = {}, {
							Key = nil,
						}; local cfg = Library.Overwrite(Data, ... or {})

						local Button = Library:AddKeypicker(ToggleFrame)

						local Binding = false
						local CurrentKey = cfg.Key

						local function UpdateText()
							if not CurrentKey then Button.Text = "[...]" else
								local Text = (typeof(CurrentKey) == "EnumItem") and CurrentKey.Name or tostring(CurrentKey)
								Text = Text:gsub("Enum.KeyCode.", ""):gsub("Enum.UserInputType.", "")
								Button.Text = ("[%s]"):format(Text)
							end
						end

						function Keybind:Set(Input)
							if typeof(Input) == "EnumItem" then
								if Input == Enum.KeyCode.Escape then CurrentKey = nil else CurrentKey = Input end
								Library.Flags[Flag] = CurrentKey
								UpdateText()
							end
						end

						Library.Connection(Button.MouseButton1Click, function()
							if Binding then return end

							Binding = true
							Button.Text = "..."

							local Connection
							Connection = InputService.InputBegan:Connect(function(Input, Processed)
								if Processed then return end

								Connection:Disconnect()
								Binding = false

								Keybind:Set(Input.KeyCode ~= Enum.KeyCode.Unknown and Input.KeyCode or Input.UserInputType)
							end)
						end)

						Library.Connection(InputService.InputBegan, function(Input, Processed)
							if Processed or not CurrentKey then return end
							
							local InputKey = Input.KeyCode ~= Enum.KeyCode.Unknown and Input.KeyCode or Input.UserInputType
							
							if InputKey == CurrentKey then
								Enabled = not Enabled
								Toggle:Set(Enabled)
							end
						end)

						if cfg.Key then Keybind:Set(cfg.Key) end
						
						for k,v in pairs(cfg) do Keybind[k] = v end	
						return setmetatable(Keybind, {__index = Toggle})
					end

					ToggleFrame.Button.MouseButton1Click:Connect(function()
						Enabled = not Enabled
						Toggle:Set(Enabled)
					end)

					ToggleFrame.Title.MouseButton1Click:Connect(function()
						Enabled = not Enabled
						Toggle:Set(Enabled)
					end)

					Toggle:Set(cfg.Default)

					for k,v in pairs(cfg) do Toggle[k] = v end	
					return setmetatable(Toggle, {__index = Section})
				end

				-- Slider
				function Section:Slider(Flag, ...)
					local Slider, Data = {}, {
						Name = "N/A",
						Default = false,
						Callback = function() end,
						Suffix = "",

						Min = 0,
						Max = 0,
						Interval = 1
				 	}; local cfg = Library.Overwrite(Data, ... or {})

					local Dragging = false
					local Value = cfg.Default

					local SliderFrame = Components.SectionStuff.Slider:Clone()
					SliderFrame.Parent = SectionFrame.Container

					SliderFrame.Title.Text = cfg.Name
					SliderFrame.Title.FontFace = Library.Theme.Font
					SliderFrame.Holder.Inline.Amount.FontFace = Library.Theme.Font

					function Slider:Set(value)
						Value = math.clamp(Library.Round(value, cfg.Interval), cfg.Min, cfg.Max)
						
						TweenService:Create(SliderFrame.Holder.Inline, TweenInfo.new(0.05),{Size = UDim2.new((Value - cfg.Min) / (cfg.Max - cfg.Min), 0, 1, 0)}):Play()
						SliderFrame.Holder.Inline.Amount.Text = tostring(Value) .. cfg.Suffix
						
						Library.Flags[Flag] = Value
						local Callback = cfg.Callback
						Callback(Value)
					end

					Library.Connection(InputService.InputChanged, function(Input)
						if Dragging and Input.UserInputType == Enum.UserInputType.MouseMovement then
							local SizeX = (Input.Position.X - SliderFrame.Holder.AbsolutePosition.X) / SliderFrame.Holder.AbsoluteSize.X
							local Value = ((cfg.Max - cfg.Min) * SizeX) + cfg.Min
							Slider:Set(Value)
						end
					end)

					Library.Connection(InputService.InputEnded, function(Input)
						if Input.UserInputType == Enum.UserInputType.MouseButton1 then
							Dragging = false
						end 
					end)
		
					SliderFrame.Holder.MouseButton1Down:Connect(function(X, Y)
						Dragging = true
						
						local SizeX = (X - SliderFrame.Holder.AbsolutePosition.X) / SliderFrame.Holder.AbsoluteSize.X
						local Value = ((cfg.Max - cfg.Min) * SizeX) + cfg.Min

						Slider:Set(Value)
					end)

					Slider:Set(cfg.Default)
	
					for k,v in pairs(cfg) do Slider[k] = v end
					return setmetatable(Slider, {__index = Section})
				end

				-- Label
				function Section:Label(...)
					local Label, Data = {}, {
						Text = "",
					}; local cfg = Library.Overwrite(Data, ... or {})

					local LabelFrame = Components.SectionStuff.Label:Clone()
					LabelFrame.Parent = SectionFrame.Container
					LabelFrame.Title.Text = cfg.Text
					LabelFrame.Title.FontFace = Library.Theme.Font

					function Label:Keybind(...)
						local Keybind, Data = {}, {
							Key = nil,
							Callback = function() end
						}; local cfg = Library.Overwrite(Data, ... or {})

						local Button = Library:AddKeypicker(LabelFrame)

						local Binding = false
						local CurrentKey = cfg.Key

						local function UpdateText()
							if not CurrentKey then Button.Text = "[...]" else
								local Text = (typeof(CurrentKey) == "EnumItem") and CurrentKey.Name or tostring(CurrentKey)
								Text = Text:gsub("Enum.KeyCode.", ""):gsub("Enum.UserInputType.", "")
								Button.Text = ("[%s]"):format(Text)
							end
						end

						function Keybind:Set(Input)
							if typeof(Input) == "EnumItem" then
								if Input == Enum.KeyCode.Escape then CurrentKey = nil else CurrentKey = Input end
								UpdateText()
							end
						end

						Library.Connection(Button.MouseButton1Click, function()
							if Binding then return end

							Binding = true
							Button.Text = "..."

							local Connection
							Connection = InputService.InputBegan:Connect(function(Input, Processed)
								if Processed then return end

								Connection:Disconnect()
								Binding = false

								Keybind:Set(Input.KeyCode ~= Enum.KeyCode.Unknown and Input.KeyCode or Input.UserInputType)
							end)
						end)

						Library.Connection(InputService.InputBegan, function(Input, Processed)
							if Processed or not CurrentKey then return end
							
							local InputKey = Input.KeyCode ~= Enum.KeyCode.Unknown and Input.KeyCode or Input.UserInputType
							if InputKey == CurrentKey then
								cfg.Callback()
							end
						end)

						if cfg.Key then Keybind:Set(cfg.Key) end
						
						for k,v in pairs(cfg) do Keybind[k] = v end	
						return setmetatable(Keybind, {__index = Label})
					end

					for k,v in pairs(cfg) do Label[k] = v end
					return setmetatable(Label, {__index = Section})
				end

				function Section:Divider()
					local Divider = {}
					local DividerFrame = Components.SectionStuff.Divider:Clone()
					DividerFrame.Parent = SectionFrame.Container
					return Divider
				end

			end

			for k,v in pairs(cfg) do Section[k] = v end
			return setmetatable(Section, {__index = Tab})
		end

		for k, v in pairs(cfg) do Tab[k] = v end
		return setmetatable(Tab, {__index = Window})
	end

	for k, v in pairs(cfg) do Window[k] = v end
	return setmetatable(Window, {__index = Library})
end

return Library
