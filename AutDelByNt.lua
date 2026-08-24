-- Auto Delivery by Nt - Optimizado para Delta Executor
-- Protegido con anti-bypass NTScripts

-- ====================== ANTI-BYPASS ======================
if not _G["NTScripts_Secret_2026"] then
    warn("[NTScripts] Acceso denegado. Ejecuta el Key System primero.")
    return
end
-- ========================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- ====================== CONFIGURACIÓN ======================
local Config = {
	Enabled = false,
	MaxItems = 4,
	WaitAfterFull = 3.5,
	JumpHeightOffset = 50,
	PickupDelay = 0.12,
	PickupTimeout = 3,
}

local jobState = nil
local isRunning = false
local isPaused = false
local noclipConnection = nil
local hasJumpedToPickup = false
local hasJumpedToDest = false
local lastItemTime = 0
local lastItemCount = 0
local deliveriesCompleted = 0
local jobStarted = false

-------------------------------------------------
-- FUNCIONES BÁSICAS
-------------------------------------------------
local function getRoot()
	local char = LocalPlayer.Character
	if not char then return nil end
	return char:FindFirstChild("HumanoidRootPart")
end

local function startNoclip()
	if noclipConnection then noclipConnection:Disconnect() end
	noclipConnection = RunService.Stepped:Connect(function()
		if not Config.Enabled then return end
		local char = LocalPlayer.Character
		if not char then return end
		for _, part in pairs(char:GetDescendants()) do
			if part:IsA("BasePart") then
				if part.Name == "HumanoidRootPart" then
					part.CanCollide = true
				else
					part.CanCollide = false
				end
			end
		end
	end)
end

local function stopNoclip()
	if noclipConnection then
		noclipConnection:Disconnect()
		noclipConnection = nil
	end
end

local function jumpTo(pos)
	local root = getRoot()
	if not root or not pos then return false end

	local target = pos + Vector3.new(0, Config.JumpHeightOffset, 0)
	root.CFrame = CFrame.new(target)
	return true
end

local function findRemote(name)
	for _, v in pairs(ReplicatedStorage:GetDescendants()) do
		if v.Name == name and (v:IsA("RemoteFunction") or v:IsA("RemoteEvent")) then
			return v
		end
	end
	return nil
end

local function invokeRemote(name)
	local rf = findRemote(name)
	if not rf then return false end
	pcall(function()
		if rf:IsA("RemoteFunction") then
			rf:InvokeServer()
		else
			rf:FireServer()
		end
	end)
end

local function pickupItem()
	invokeRemote("Pickup")
end

local function deliverItems()
	invokeRemote("Deliver")
end

-------------------------------------------------
-- GUI + ANIMACIONES
-------------------------------------------------
local function getParent()
	local success, result = pcall(function()
		return gethui()
	end)
	if success and result then return result end
	return CoreGui
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoDelivery_" .. math.random(1000, 9999)
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 999999
screenGui.IgnoreGuiInset = true

pcall(function()
	if syn and syn.protect_gui then
		syn.protect_gui(screenGui)
	end
end)
screenGui.Parent = getParent()

-- ========== INTRO "NTscripts" ==========
local introFrame = Instance.new("Frame")
introFrame.Size = UDim2.new(1, 0, 1, 0)
introFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
introFrame.BackgroundTransparency = 0.3
introFrame.BorderSizePixel = 0
introFrame.Parent = screenGui

local introText = Instance.new("TextLabel")
introText.Size = UDim2.new(0, 400, 0, 80)
introText.Position = UDim2.new(0.5, -200, 0.5, -40)
introText.BackgroundTransparency = 1
introText.Text = "NTscripts"
introText.TextColor3 = Color3.fromRGB(180, 140, 255)
introText.TextSize = 48
introText.Font = Enum.Font.GothamBold
introText.TextTransparency = 1
introText.Parent = introFrame

local introTweenInfo = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
TweenService:Create(introText, introTweenInfo, {TextTransparency = 0, TextSize = 52}):Play()

task.delay(1.6, function()
	local fadeOut = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	TweenService:Create(introText, fadeOut, {TextTransparency = 1, TextSize = 40}):Play()
	TweenService:Create(introFrame, fadeOut, {BackgroundTransparency = 1}):Play()
	task.wait(0.65)
	introFrame:Destroy()
end)

-- ========== GUI PRINCIPAL ==========
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 0, 0, 0)
mainFrame.Position = UDim2.new(0.5, 0, 0.25, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
mainFrame.BackgroundTransparency = 0.7
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Visible = false
mainFrame.Parent = screenGui

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 14)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(120, 100, 180)
stroke.Thickness = 1.8
stroke.Parent = mainFrame

-- Título
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -80, 0, 34)
title.Position = UDim2.new(0, 14, 0, 6)
title.BackgroundTransparency = 1
title.Text = "AutoDelivery by NT"
title.TextColor3 = Color3.fromRGB(230, 220, 255)
title.TextSize = 17
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = mainFrame

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 32, 0, 32)
minimizeBtn.Position = UDim2.new(1, -72, 0, 6)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(55, 50, 75)
minimizeBtn.Text = "–"
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.TextSize = 20
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.Parent = mainFrame
Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0, 8)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 32, 0, 32)
closeBtn.Position = UDim2.new(1, -36, 0, 6)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 60)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 15
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = mainFrame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

-- Botones principales
local startBtn = Instance.new("TextButton")
startBtn.Size = UDim2.new(0, 120, 0, 36)
startBtn.Position = UDim2.new(0, 16, 0, 48)
startBtn.BackgroundColor3 = Color3.fromRGB(45, 170, 90)
startBtn.Text = "Iniciar"
startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
startBtn.TextSize = 14
startBtn.Font = Enum.Font.GothamBold
startBtn.Parent = mainFrame
Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 9)

local pauseBtn = Instance.new("TextButton")
pauseBtn.Size = UDim2.new(0, 120, 0, 36)
pauseBtn.Position = UDim2.new(0, 148, 0, 48)
pauseBtn.BackgroundColor3 = Color3.fromRGB(80, 100, 180)
pauseBtn.Text = "Pausar"
pauseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
pauseBtn.TextSize = 14
pauseBtn.Font = Enum.Font.GothamBold
pauseBtn.Parent = mainFrame
Instance.new("UICorner", pauseBtn).CornerRadius = UDim.new(0, 9)

-- Cuadro de estado
local statusFrame = Instance.new("Frame")
statusFrame.Size = UDim2.new(1, -32, 0, 52)
statusFrame.Position = UDim2.new(0, 16, 0, 96)
statusFrame.BackgroundColor3 = Color3.fromRGB(30, 28, 42)
statusFrame.BackgroundTransparency = 0.3
statusFrame.BorderSizePixel = 0
statusFrame.Parent = mainFrame
Instance.new("UICorner", statusFrame).CornerRadius = UDim.new(0, 10)

local statusStroke = Instance.new("UIStroke")
statusStroke.Color = Color3.fromRGB(90, 80, 130)
statusStroke.Thickness = 1.2
statusStroke.Parent = statusFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -16, 0, 24)
statusLabel.Position = UDim2.new(0, 8, 0, 4)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Estado: Detenido"
statusLabel.TextColor3 = Color3.fromRGB(190, 185, 220)
statusLabel.TextSize = 13
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = statusFrame

local deliveriesLabel = Instance.new("TextLabel")
deliveriesLabel.Size = UDim2.new(1, -16, 0, 22)
deliveriesLabel.Position = UDim2.new(0, 8, 0, 26)
deliveriesLabel.BackgroundTransparency = 1
deliveriesLabel.Text = "Entregas: 0"
deliveriesLabel.TextColor3 = Color3.fromRGB(150, 210, 160)
deliveriesLabel.TextSize = 13
deliveriesLabel.Font = Enum.Font.Gotham
deliveriesLabel.TextXAlignment = Enum.TextXAlignment.Left
deliveriesLabel.Parent = statusFrame

-- Botón Unload
local unloadBtn = Instance.new("TextButton")
unloadBtn.Size = UDim2.new(0, 100, 0, 28)
unloadBtn.Position = UDim2.new(0.5, -50, 0, 158)
unloadBtn.BackgroundColor3 = Color3.fromRGB(140, 50, 55)
unloadBtn.Text = "Unload"
unloadBtn.TextColor3 = Color3.fromRGB(255, 220, 220)
unloadBtn.TextSize = 12
unloadBtn.Font = Enum.Font.GothamBold
unloadBtn.Parent = mainFrame
Instance.new("UICorner", unloadBtn).CornerRadius = UDim.new(0, 7)

local ntLabel = Instance.new("TextLabel")
ntLabel.Size = UDim2.new(1, 0, 0, 16)
ntLabel.Position = UDim2.new(0, 0, 1, -18)
ntLabel.BackgroundTransparency = 1
ntLabel.Text = "NT"
ntLabel.TextColor3 = Color3.fromRGB(140, 130, 170)
ntLabel.TextSize = 11
ntLabel.Font = Enum.Font.GothamBold
ntLabel.Parent = mainFrame

-- Animación de entrada del GUI
task.delay(2.3, function()
	mainFrame.Visible = true
	mainFrame.Size = UDim2.new(0, 10, 0, 10)
	mainFrame.Position = UDim2.new(0.5, -5, 0.25, 0)

	local openTween = TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	TweenService:Create(mainFrame, openTween, {
		Size = UDim2.new(0, 290, 0, 200),
		Position = UDim2.new(0.5, -145, 0.25, 0)
	}):Play()
end)

-------------------------------------------------
-- CÍRCULO FLOTANTE
-------------------------------------------------
local floatCircle = Instance.new("TextButton")
floatCircle.Size = UDim2.new(0, 56, 0, 56)
floatCircle.Position = UDim2.new(0.5, -28, 0, 18)
floatCircle.BackgroundColor3 = Color3.fromRGB(105, 80, 145)
floatCircle.Text = "💵"
floatCircle.TextColor3 = Color3.fromRGB(255, 255, 255)
floatCircle.TextSize = 24
floatCircle.Font = Enum.Font.GothamBold
floatCircle.Visible = false
floatCircle.Parent = screenGui
Instance.new("UICorner", floatCircle).CornerRadius = UDim.new(1, 0)

local fStroke = Instance.new("UIStroke")
fStroke.Color = Color3.fromRGB(190, 160, 240)
fStroke.Thickness = 2.5
fStroke.Parent = floatCircle

local fStroke2 = Instance.new("UIStroke")
fStroke2.Color = Color3.fromRGB(220, 200, 255)
fStroke2.Thickness = 1
fStroke2.Transparency = 0.6
fStroke2.Parent = floatCircle

-------------------------------------------------
-- ANIMACIÓN DEL ESTADO
-------------------------------------------------
local function animateStatus()
	local pulse = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(statusStroke, pulse, {Color = Color3.fromRGB(160, 130, 255)}):Play()
	task.delay(0.25, function()
		TweenService:Create(statusStroke, pulse, {Color = Color3.fromRGB(90, 80, 130)}):Play()
	end)
	statusLabel.TextTransparency = 0.4
	TweenService:Create(statusLabel, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
end

local function updateStatus(text)
	if statusLabel then
		statusLabel.Text = "Estado: " .. text
		animateStatus()
	end
end

local function updateDeliveries()
	if deliveriesLabel then
		deliveriesLabel.Text = "Entregas: " .. deliveriesCompleted
		deliveriesLabel.TextColor3 = Color3.fromRGB(100, 255, 140)
		task.delay(0.4, function()
			if deliveriesLabel then
				TweenService:Create(deliveriesLabel, TweenInfo.new(0.4), {
					TextColor3 = Color3.fromRGB(150, 210, 160)
				}):Play()
			end
		end)
	end
end

-------------------------------------------------
-- ARRASTRE
-------------------------------------------------
local function makeDraggable(obj)
	local dragging, dragStart, startPos
	obj.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = obj.Position
		end
	end)
	obj.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

makeDraggable(mainFrame)
makeDraggable(floatCircle)

-------------------------------------------------
-- LÓGICA DEL TRABAJO
-------------------------------------------------
local function startDeliveryJob()
	updateStatus("Iniciando trabajo...")
	local success = pcall(function()
		local remotes = ReplicatedStorage:FindFirstChild("Remotes")
		if remotes then
			local event = remotes:FindFirstChild("RequestStartJobSession")
			if event then
				event:FireServer("Delivery", "jobPad")
			end
		end
	end)
	if success then
		jobStarted = true
		updateStatus("Trabajo iniciado")
		task.wait(1.0)
		return true
	else
		updateStatus("Error al iniciar trabajo")
		return false
	end
end

local function runDeliveryLoop()
	startDeliveryJob()

	pcall(function()
		local modules = ReplicatedStorage:FindFirstChild("Modules")
		if modules then
			local client = modules:FindFirstChild("Client")
			if client then
				local jobs = client:FindFirstChild("Jobs")
				if jobs then
					local tasks = jobs:FindFirstChild("Tasks")
					if tasks then
						local delivery = tasks:FindFirstChild("DeliveryJobTask")
						if delivery then
							local jobModule = require(delivery)
							if jobModule and jobModule.OnStateChanged then
								jobModule.OnStateChanged:Connect(function(state)
									jobState = state
								end)
							end
						end
					end
				end
			end
		end
	end)

	local timeout = 0
	while not jobState and Config.Enabled and timeout < 3 do
		updateStatus("Detectando trabajo... (" .. string.format("%.1f", timeout) .. "s)")
		task.wait(0.3)
		timeout = timeout + 0.3
	end

	if not jobState then
		updateStatus("No se detectó trabajo → Reiniciando...")
		task.wait(1)
		if Config.Enabled then
			jobStarted = false
			hasJumpedToPickup = false
			hasJumpedToDest = false
			lastItemTime = 0
			lastItemCount = 0
			jobState = nil
			task.wait(0.5)
			runDeliveryLoop()
		end
		return
	end

	local items = jobState.ItemsCarried or 0
	if items >= Config.MaxItems then
		updateStatus("Fase: Entregar")
		hasJumpedToPickup = true
		hasJumpedToDest = false
	elseif items > 0 then
		updateStatus("Fase: Continuando (" .. items .. "/4)")
		hasJumpedToPickup = false
		hasJumpedToDest = false
		lastItemCount = items
		lastItemTime = tick()
	else
		updateStatus("Fase: Empezar desde cero")
		hasJumpedToPickup = false
		hasJumpedToDest = false
		lastItemCount = 0
		lastItemTime = 0
	end

	while Config.Enabled do
		if isPaused then
			updateStatus("Pausado")
			task.wait(0.3)
			continue
		end

		if not jobState then
			updateStatus("Trabajo perdido → Reiniciando...")
			task.wait(1)
			jobStarted = false
			hasJumpedToPickup = false
			hasJumpedToDest = false
			lastItemTime = 0
			lastItemCount = 0
			runDeliveryLoop()
			return
		end

		local root = getRoot()
		if not root then
			task.wait(0.3)
			continue
		end

		local itemsCarried = jobState.ItemsCarried or 0
		local pickupPos = jobState.PickupPosition
		local destPos = jobState.DestinationPosition

		if itemsCarried < Config.MaxItems and pickupPos then
			if hasJumpedToPickup and lastItemTime > 0 then
				if tick() - lastItemTime > Config.PickupTimeout then
					updateStatus("Timeout → Reiniciando recogida")
					hasJumpedToPickup = false
					lastItemTime = 0
					lastItemCount = itemsCarried
					task.wait(0.25)
				end
			end

			if not hasJumpedToPickup then
				updateStatus("buscando recoleccion...")
				jumpTo(pickupPos)
				hasJumpedToPickup = true
				hasJumpedToDest = false
				lastItemTime = tick()
				lastItemCount = itemsCarried
				task.wait(0.3)
			end

			if itemsCarried > lastItemCount then
				lastItemCount = itemsCarried
				lastItemTime = tick()
			end

			updateStatus("Recogiendo (" .. itemsCarried .. "/4)")
			pickupItem()
			task.wait(Config.PickupDelay)
		end

		if itemsCarried >= Config.MaxItems then
			if not hasJumpedToDest then
				updateStatus("Esperando punto de entrega...")
				task.wait(Config.WaitAfterFull)
			end
		end

		if itemsCarried >= Config.MaxItems and destPos then
			if not hasJumpedToDest then
				updateStatus("buscando entrega...")
				jumpTo(destPos)
				hasJumpedToDest = true
				task.wait(0.3)
			end

			updateStatus("Entregando...")
			deliverItems()
			task.wait(1.2)

			deliveriesCompleted = deliveriesCompleted + 1
			updateDeliveries()

			hasJumpedToPickup = false
			hasJumpedToDest = false
			lastItemTime = 0
			lastItemCount = 0
			updateStatus("Entrega completada")
			task.wait(0.5)
		end

		task.wait(0.05)
	end

	updateStatus("Detenido")
end

local function startProcess()
	if isRunning then return end
	isRunning = true
	isPaused = false
	Config.Enabled = true
	jobStarted = false
	hasJumpedToPickup = false
	hasJumpedToDest = false
	lastItemTime = 0
	lastItemCount = 0
	jobState = nil
	startNoclip()
	updateStatus("Iniciando...")
	task.spawn(runDeliveryLoop)
end

local function stopProcess()
	Config.Enabled = false
	isRunning = false
	isPaused = false
	stopNoclip()
	jobStarted = false
	hasJumpedToPickup = false
	hasJumpedToDest = false
	lastItemTime = 0
	lastItemCount = 0
	updateStatus("Detenido")
end

-------------------------------------------------
-- CONEXIONES
-------------------------------------------------
startBtn.MouseButton1Click:Connect(function()
	if isRunning then
		stopProcess()
		startBtn.Text = "Iniciar"
		startBtn.BackgroundColor3 = Color3.fromRGB(45, 170, 90)
		pauseBtn.Text = "Pausar"
		pauseBtn.BackgroundColor3 = Color3.fromRGB(80, 100, 180)
	else
		startProcess()
		startBtn.Text = "Detener"
		startBtn.BackgroundColor3 = Color3.fromRGB(180, 55, 55)
	end
end)

pauseBtn.MouseButton1Click:Connect(function()
	if not isRunning then return end

	isPaused = not isPaused
	if isPaused then
		pauseBtn.Text = "Continuar"
		pauseBtn.BackgroundColor3 = Color3.fromRGB(50, 160, 100)
		updateStatus("Pausado")
	else
		pauseBtn.Text = "Pausar"
		pauseBtn.BackgroundColor3 = Color3.fromRGB(80, 100, 180)
		updateStatus("Reanudando...")
	end
end)

unloadBtn.MouseButton1Click:Connect(function()
	stopProcess()
	screenGui:Destroy()
end)

closeBtn.MouseButton1Click:Connect(function()
	stopProcess()
	screenGui:Destroy()
end)

minimizeBtn.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
	floatCircle.Visible = true
	floatCircle.Position = UDim2.new(0.5, -28, 0, 18)
end)

floatCircle.MouseButton1Click:Connect(function()
	floatCircle.Visible = false
	mainFrame.Visible = true
end)

print("[Auto Delivery] GUI Mejorado | Anti-bypass activo")
