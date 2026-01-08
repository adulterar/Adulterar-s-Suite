--[[
Adulterar's UI Suite
v1.0 - UI Inteligente e Moderna
Criador: adulterar's

Características Principais:
1. Performance otimizada (menos efeitos pesados)
2. Sistema de caching inteligente
3. Interface responsiva e leve
4. Tema dinâmico com modo escuro/claro
5. Sistema de configurações eficiente
6. Elementos UI completos com inteligência contextual
]]

-- Serviços
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

-- Constantes de performance
local PERFORMANCE_MODE = {
    LOW = 1,
    MEDIUM = 2,
    HIGH = 3
}

local currentPerformance = PERFORMANCE_MODE.HIGH

-- Sistema de caching para elementos
local ElementCache = {
    Instances = {},
    Templates = {},
    ActiveElements = 0,
    MaxElements = 50
}

-- Tema principal (cores modernas)
local Theme = {
    Primary = Color3.fromRGB(0, 120, 215),
    Secondary = Color3.fromRGB(30, 30, 30),
    Accent = Color3.fromRGB(0, 200, 150),
    Background = Color3.fromRGB(25, 25, 28),
    Surface = Color3.fromRGB(35, 35, 40),
    Text = Color3.fromRGB(240, 240, 240),
    TextSecondary = Color3.fromRGB(180, 180, 180),
    Success = Color3.fromRGB(76, 175, 80),
    Warning = Color3.fromRGB(255, 152, 0),
    Error = Color3.fromRGB(244, 67, 54)
}

-- Sistema inteligente de ícones
local IconSystem = {
    Cache = {},
    
    GetIcon = function(iconName, iconType)
        local cacheKey = iconName .. "_" .. (iconType or "material")
        if IconSystem.Cache[cacheKey] then
            return IconSystem.Cache[cacheKey]
        end
        
        -- Sistema de fallback inteligente
        local iconMap = {
            ["material"] = {
                home = "rbxassetid://6031097225",
                settings = "rbxassetid://6031280882",
                person = "rbxassetid://6034287594",
                notification = "rbxassetid://6034308946",
                star = "rbxassetid://6031068423",
                check = "rbxassetid://6031094667",
                close = "rbxassetid://6031094678",
                menu = "rbxassetid://6031097225",
                download = "rbxassetid://6031302931",
                upload = "rbxassetid://6031302996",
                lock = "rbxassetid://6026568224",
                key = "rbxassetid://6035202034",
                palette = "rbxassetid://6034316009",
                info = "rbxassetid://6026568227",
                warning = "rbxassetid://6031071053",
                error = "rbxassetid://6031071057"
            }
        }
        
        local icon = iconMap[iconType or "material"][iconName] or iconMap.material.info
        IconSystem.Cache[cacheKey] = icon
        return icon
    end
}

-- Sistema de utilitários
local Utils = {
    Debounce = {},
    
    Create = function(className, properties)
        local obj = Instance.new(className)
        for prop, value in pairs(properties) do
            obj[prop] = value
        end
        return obj
    end,
    
    Tween = function(object, properties, duration, easingStyle, callback)
        local tweenInfo = TweenInfo.new(duration or 0.3, easingStyle or Enum.EasingStyle.Quad)
        local tween = TweenService:Create(object, tweenInfo, properties)
        
        if callback then
            tween.Completed:Connect(callback)
        end
        
        tween:Play()
        return tween
    end,
    
    DebounceCall = function(id, callback, delay)
        if not Utils.Debounce[id] then
            Utils.Debounce[id] = true
            callback()
            
            task.delay(delay or 0.5, function()
                Utils.Debounce[id] = nil
            end)
        end
    end,
    
    Round = function(num, decimalPlaces)
        decimalPlaces = decimalPlaces or 2
        local mult = 10 ^ decimalPlaces
        return math.floor(num * mult + 0.5) / mult
    end,
    
    HexToColor = function(hex)
        hex = hex:gsub("#", "")
        return Color3.fromRGB(
            tonumber("0x" .. hex:sub(1, 2)),
            tonumber("0x" .. hex:sub(3, 4)),
            tonumber("0x" .. hex:sub(5, 6))
        )
    end,
    
    ColorToHex = function(color)
        return string.format("#%02X%02X%02X",
            math.floor(color.R * 255),
            math.floor(color.G * 255),
            math.floor(color.B * 255)
        )
    end
}

-- Classe principal da UI
local AdulterarUI = {
    Windows = {},
    ActiveWindow = nil,
    Options = {},
    Config = {
        SavePath = "AdulterarUI/Configs/",
        AutoSave = true,
        AutoLoad = true
    }
}

-- Sistema de configurações otimizado
function AdulterarUI:SaveConfig(name, data)
    local config = data or {}
    
    -- Coleta automaticamente todas as opções se nenhum dado for fornecido
    if not data then
        config.options = {}
        for flag, option in pairs(self.Options) do
            if option.GetValue then
                config.options[flag] = {
                    type = option.Type,
                    value = option:GetValue()
                }
            end
        end
    end
    
    local json = HttpService:JSONEncode(config)
    
    if writefile then
        local path = self.Config.SavePath .. name .. ".json"
        writefile(path, json)
        return true
    end
    
    return false
end

function AdulterarUI:LoadConfig(name)
    if readfile then
        local path = self.Config.SavePath .. name .. ".json"
        if isfile(path) then
            local data = readfile(path)
            local config = HttpService:JSONDecode(data)
            
            -- Aplica configurações
            if config.options then
                for flag, optionData in pairs(config.options) do
                    local option = self.Options[flag]
                    if option and option.SetValue then
                        option:SetValue(optionData.value)
                    end
                end
            end
            
            return true
        end
    end
    
    return false
end

-- Sistema de notificações leves
function AdulterarUI:Notify(data)
    data = data or {}
    
    local title = data.Title or "Notificação"
    local message = data.Message or ""
    local duration = data.Duration or 5
    local type = data.Type or "info"
    
    -- Cores baseadas no tipo
    local colors = {
        info = Theme.Primary,
        success = Theme.Success,
        warning = Theme.Warning,
        error = Theme.Error
    }
    
    local color = colors[type] or Theme.Primary
    
    -- Cria notificação leve
    local notification = Instance.new("Frame")
    notification.Name = "Notification"
    notification.BackgroundColor3 = Theme.Surface
    notification.BorderSizePixel = 0
    notification.Size = UDim2.new(0, 300, 0, 0)
    notification.Position = UDim2.new(1, -320, 1, -80)
    notification.ClipsDescendants = true
    
    local uiCorner = Instance.new("UICorner", notification)
    uiCorner.CornerRadius = UDim.new(0, 8)
    
    local uiStroke = Instance.new("UIStroke", notification)
    uiStroke.Color = color
    uiStroke.Thickness = 2
    
    local titleLabel = Instance.new("TextLabel", notification)
    titleLabel.Text = title
    titleLabel.TextColor3 = color
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 14
    titleLabel.Size = UDim2.new(1, -20, 0, 20)
    titleLabel.Position = UDim2.new(0, 10, 0, 10)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local messageLabel = Instance.new("TextLabel", notification)
    messageLabel.Text = message
    messageLabel.TextColor3 = Theme.TextSecondary
    messageLabel.BackgroundTransparency = 1
    messageLabel.Font = Enum.Font.Gotham
    messageLabel.TextSize = 12
    messageLabel.Size = UDim2.new(1, -20, 0, 0)
    messageLabel.Position = UDim2.new(0, 10, 0, 35)
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.TextWrapped = true
    
    -- Calcula altura baseada no texto
    local textBounds = messageLabel.TextBounds
    local height = math.min(textBounds.Y + 55, 150)
    
    notification.Size = UDim2.new(0, 300, 0, height)
    messageLabel.Size = UDim2.new(1, -20, 0, textBounds.Y)
    
    -- Adiciona ao CoreGui
    notification.Parent = CoreGui
    
    -- Animação de entrada
    notification.Position = UDim2.new(1, 300, 1, -80)
    Utils.Tween(notification, {Position = UDim2.new(1, -320, 1, -80)}, 0.3, Enum.EasingStyle.Back)
    
    -- Remove após duração
    task.delay(duration, function()
        Utils.Tween(notification, {Position = UDim2.new(1, 300, 1, -80)}, 0.3, Enum.EasingStyle.Back, function()
            notification:Destroy()
        end)
    end)
    
    return notification
end

-- Classe Window (Otimizada)
AdulterarUI.Window = {}
AdulterarUI.Window.__index = AdulterarUI.Window

function AdulterarUI.Window:New(config)
    config = config or {}
    
    local self = setmetatable({}, AdulterarUI.Window)
    
    self.Name = config.Name or "Adulterar's UI"
    self.Size = config.Size or UDim2.new(0, 600, 0, 400)
    self.Position = config.Position or UDim2.new(0.5, -300, 0.5, -200)
    self.Theme = config.Theme or "dark"
    self.Tabs = {}
    self.ActiveTab = nil
    self.Elements = {}
    
    -- Cria a janela principal
    self.Container = Instance.new("ScreenGui")
    self.Container.Name = "AdulterarUI_" .. self.Name
    self.Container.ResetOnSpawn = false
    self.Container.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    if gethui then
        self.Container.Parent = gethui()
    elseif syn and syn.protect_gui then
        syn.protect_gui(self.Container)
        self.Container.Parent = CoreGui
    else
        self.Container.Parent = CoreGui
    end
    
    -- Main Frame
    self.MainFrame = Instance.new("Frame")
    self.MainFrame.Name = "Main"
    self.MainFrame.BackgroundColor3 = Theme.Background
    self.MainFrame.Size = self.Size
    self.MainFrame.Position = self.Position
    self.MainFrame.BorderSizePixel = 0
    self.MainFrame.ClipsDescendants = true
    
    local mainCorner = Instance.new("UICorner", self.MainFrame)
    mainCorner.CornerRadius = UDim.new(0, 12)
    
    local mainStroke = Instance.new("UIStroke", self.MainFrame)
    mainStroke.Color = Theme.Primary
    mainStroke.Thickness = 2
    
    -- Header
    self.Header = Instance.new("Frame")
    self.Header.Name = "Header"
    self.Header.BackgroundColor3 = Theme.Surface
    self.Header.Size = UDim2.new(1, 0, 0, 50)
    self.Header.BorderSizePixel = 0
    
    local headerCorner = Instance.new("UICorner", self.Header)
    headerCorner.CornerRadius = UDim.new(0, 12, 0, 0)
    
    -- Title
    self.Title = Instance.new("TextLabel")
    self.Title.Name = "Title"
    self.Title.Text = self.Name
    self.Title.TextColor3 = Theme.Primary
    self.Title.BackgroundTransparency = 1
    self.Title.Font = Enum.Font.GothamBold
    self.Title.TextSize = 18
    self.Title.Size = UDim2.new(0, 200, 1, 0)
    self.Title.Position = UDim2.new(0, 15, 0, 0)
    self.Title.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Close Button
    self.CloseButton = Instance.new("TextButton")
    self.CloseButton.Name = "Close"
    self.CloseButton.Text = "✕"
    self.CloseButton.TextColor3 = Theme.TextSecondary
    self.CloseButton.BackgroundTransparency = 1
    self.CloseButton.Font = Enum.Font.GothamBold
    self.CloseButton.TextSize = 20
    self.CloseButton.Size = UDim2.new(0, 40, 1, 0)
    self.CloseButton.Position = UDim2.new(1, -40, 0, 0)
    
    self.CloseButton.MouseButton1Click:Connect(function()
        self:Destroy()
    end)
    
    self.CloseButton.MouseEnter:Connect(function()
        self.CloseButton.TextColor3 = Theme.Error
    end)
    
    self.CloseButton.MouseLeave:Connect(function()
        self.CloseButton.TextColor3 = Theme.TextSecondary
    end)
    
    -- Tab Container
    self.TabContainer = Instance.new("Frame")
    self.TabContainer.Name = "TabContainer"
    self.TabContainer.BackgroundColor3 = Theme.Surface
    self.TabContainer.Size = UDim2.new(0, 200, 1, -50)
    self.TabContainer.Position = UDim2.new(0, 0, 0, 50)
    self.TabContainer.BorderSizePixel = 0
    
    local tabList = Instance.new("UIListLayout", self.TabContainer)
    tabList.Padding = UDim.new(0, 5)
    tabList.SortOrder = Enum.SortOrder.LayoutOrder
    
    -- Content Container
    self.ContentContainer = Instance.new("Frame")
    self.ContentContainer.Name = "Content"
    self.ContentContainer.BackgroundTransparency = 1
    self.ContentContainer.Size = UDim2.new(1, -200, 1, -50)
    self.ContentContainer.Position = UDim2.new(0, 200, 0, 50)
    
    -- Organiza os elementos
    self.Header.Parent = self.MainFrame
    self.Title.Parent = self.Header
    self.CloseButton.Parent = self.Header
    self.TabContainer.Parent = self.MainFrame
    self.ContentContainer.Parent = self.MainFrame
    self.MainFrame.Parent = self.Container
    
    -- Sistema de arrastar
    self:Draggable(self.Header)
    
    -- Adiciona à lista de janelas
    table.insert(AdulterarUI.Windows, self)
    AdulterarUI.ActiveWindow = self
    
    self:Notify({
        Title = "UI Carregada",
        Message = string.format("%s iniciado com sucesso!", self.Name),
        Type = "success"
    })
    
    return self
end

function AdulterarUI.Window:Draggable(frame)
    local dragging = false
    local dragInput, mousePos, framePos
    
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            mousePos = input.Position
            framePos = self.MainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            self.MainFrame.Position = UDim2.new(
                framePos.X.Scale,
                framePos.X.Offset + delta.X,
                framePos.Y.Scale,
                framePos.Y.Offset + delta.Y
            )
        end
    end)
end

function AdulterarUI.Window:CreateTab(config)
    config = config or {}
    
    local tab = {
        Name = config.Name or "Nova Aba",
        Icon = config.Icon or "folder",
        Window = self,
        Elements = {},
        Active = false
    }
    
    -- Botão da aba
    tab.Button = Instance.new("TextButton")
    tab.Button.Name = "Tab_" .. tab.Name
    tab.Button.Text = tab.Name
    tab.Button.BackgroundColor3 = Theme.Surface
    tab.Button.TextColor3 = Theme.TextSecondary
    tab.Button.Font = Enum.Font.Gotham
    tab.Button.TextSize = 14
    tab.Button.Size = UDim2.new(1, -10, 0, 40)
    tab.Button.LayoutOrder = #self.Tabs + 1
    tab.Button.BorderSizePixel = 0
    
    local buttonCorner = Instance.new("UICorner", tab.Button)
    buttonCorner.CornerRadius = UDim.new(0, 8)
    
    -- Conteúdo da aba
    tab.Content = Instance.new("ScrollingFrame")
    tab.Content.Name = "Content_" .. tab.Name
    tab.Content.BackgroundTransparency = 1
    tab.Content.Size = UDim2.new(1, 0, 1, 0)
    tab.Content.Position = UDim2.new(0, 0, 0, 0)
    tab.Content.ScrollBarThickness = 3
    tab.Content.ScrollBarImageColor3 = Theme.Primary
    tab.Content.Visible = false
    
    local contentList = Instance.new("UIListLayout", tab.Content)
    contentList.Padding = UDim.new(0, 10)
    contentList.SortOrder = Enum.SortOrder.LayoutOrder
    
    -- Adiciona aos containers
    tab.Button.Parent = self.TabContainer
    tab.Content.Parent = self.ContentContainer
    
    -- Eventos
    tab.Button.MouseButton1Click:Connect(function()
        self:SwitchTab(tab)
    end)
    
    tab.Button.MouseEnter:Connect(function()
        if not tab.Active then
            Utils.Tween(tab.Button, {BackgroundColor3 = Color3.fromRGB(45, 45, 50)}, 0.2)
        end
    end)
    
    tab.Button.MouseLeave:Connect(function()
        if not tab.Active then
            Utils.Tween(tab.Button, {BackgroundColor3 = Theme.Surface}, 0.2)
        end
    end)
    
    -- Funções da aba
    function tab:AddSection(name)
        local section = {
            Name = name,
            Elements = {}
        }
        
        local sectionFrame = Instance.new("Frame")
        sectionFrame.Name = "Section_" .. name
        sectionFrame.BackgroundTransparency = 1
        sectionFrame.Size = UDim2.new(1, -20, 0, 0)
        sectionFrame.LayoutOrder = #self.Elements + 1
        
        local sectionLabel = Instance.new("TextLabel")
        sectionLabel.Text = name
        sectionLabel.TextColor3 = Theme.Primary
        sectionLabel.BackgroundTransparency = 1
        sectionLabel.Font = Enum.Font.GothamBold
        sectionLabel.TextSize = 16
        sectionLabel.Size = UDim2.new(1, 0, 0, 25)
        sectionLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        local separator = Instance.new("Frame")
        separator.BackgroundColor3 = Theme.Primary
        separator.Size = UDim2.new(1, 0, 0, 1)
        separator.Position = UDim2.new(0, 0, 0, 25)
        separator.BorderSizePixel = 0
        
        local elementsContainer = Instance.new("Frame")
        elementsContainer.Name = "Elements"
        elementsContainer.BackgroundTransparency = 1
        elementsContainer.Size = UDim2.new(1, 0, 0, 0)
        elementsContainer.Position = UDim2.new(0, 0, 0, 30)
        
        local elementsList = Instance.new("UIListLayout", elementsContainer)
        elementsList.Padding = UDim.new(0, 8)
        elementsList.SortOrder = Enum.SortOrder.LayoutOrder
        
        sectionLabel.Parent = sectionFrame
        separator.Parent = sectionFrame
        elementsContainer.Parent = sectionFrame
        sectionFrame.Parent = self.Content
        
        table.insert(self.Elements, section)
        
        -- Funções da seção
        function section:AddElement(element)
            table.insert(self.Elements, element)
            
            -- Atualiza altura
            task.wait()
            local totalHeight = 30
            for _, child in ipairs(elementsContainer:GetChildren()) do
                if child:IsA("Frame") then
                    totalHeight += child.AbsoluteSize.Y + 8
                end
            end
            
            sectionFrame.Size = UDim2.new(1, -20, 0, totalHeight)
            elementsContainer.Size = UDim2.new(1, 0, 0, totalHeight - 30)
            
            return element
        end
        
        return section
    end
    
    -- Métodos de criação de elementos (serão implementados abaixo)
    function tab:CreateButton(config)
        return self:AddSection("Botões"):AddElement(self.Window:CreateButton(config))
    end
    
    function tab:CreateToggle(config)
        return self:AddSection("Toggles"):AddElement(self.Window:CreateToggle(config))
    end
    
    function tab:CreateSlider(config)
        return self:AddSection("Sliders"):AddElement(self.Window:CreateSlider(config))
    end
    
    function tab:CreateInput(config)
        return self:AddSection("Inputs"):AddElement(self.Window:CreateInput(config))
    end
    
    function tab:CreateDropdown(config)
        return self:AddSection("Dropdowns"):AddElement(self.Window:CreateDropdown(config))
    end
    
    function tab:CreateColorPicker(config)
        return self:AddSection("Color Pickers"):AddElement(self.Window:CreateColorPicker(config))
    end
    
    function tab:CreateLabel(config)
        return self:AddSection("Labels"):AddElement(self.Window:CreateLabel(config))
    end
    
    function tab:CreateKeybind(config)
        return self:AddSection("Keybinds"):AddElement(self.Window:CreateKeybind(config))
    end
    
    -- Primeira aba é ativada automaticamente
    if #self.Tabs == 0 then
        self:SwitchTab(tab)
    end
    
    table.insert(self.Tabs, tab)
    return tab
end

function AdulterarUI.Window:SwitchTab(tab)
    if self.ActiveTab then
        self.ActiveTab.Active = false
        Utils.Tween(self.ActiveTab.Button, {
            BackgroundColor3 = Theme.Surface,
            TextColor3 = Theme.TextSecondary
        }, 0.2)
        self.ActiveTab.Content.Visible = false
    end
    
    tab.Active = true
    Utils.Tween(tab.Button, {
        BackgroundColor3 = Theme.Primary,
        TextColor3 = Color3.fromRGB(255, 255, 255)
    }, 0.2)
    tab.Content.Visible = true
    
    self.ActiveTab = tab
end

function AdulterarUI.Window:CreateButton(config)
    config = config or {}
    
    local button = {
        Type = "Button",
        Name = config.Name or "Botão",
        Description = config.Description,
        Callback = config.Callback or function() end
    }
    
    local buttonFrame = Instance.new("Frame")
    buttonFrame.Name = "Button_" .. button.Name
    buttonFrame.BackgroundColor3 = Theme.Surface
    buttonFrame.Size = UDim2.new(1, 0, 0, config.Description and 60 or 40)
    buttonFrame.BorderSizePixel = 0
    
    local buttonCorner = Instance.new("UICorner", buttonFrame)
    buttonCorner.CornerRadius = UDim.new(0, 8)
    
    local buttonStroke = Instance.new("UIStroke", buttonFrame)
    buttonStroke.Color = Theme.Primary
    buttonStroke.Thickness = 1
    
    local buttonText = Instance.new("TextLabel")
    buttonText.Text = button.Name
    buttonText.TextColor3 = Theme.Text
    buttonText.BackgroundTransparency = 1
    buttonText.Font = Enum.Font.GothamBold
    buttonText.TextSize = 14
    buttonText.Size = UDim2.new(1, -20, 0, 25)
    buttonText.Position = UDim2.new(0, 10, 0, 8)
    buttonText.TextXAlignment = Enum.TextXAlignment.Left
    
    buttonFrame.Parent = self.ContentContainer
    
    if config.Description then
        local descText = Instance.new("TextLabel")
        descText.Text = config.Description
        descText.TextColor3 = Theme.TextSecondary
        descText.BackgroundTransparency = 1
        descText.Font = Enum.Font.Gotham
        descText.TextSize = 12
        descText.Size = UDim2.new(1, -20, 0, 15)
        descText.Position = UDim2.new(0, 10, 0, 33)
        descText.TextXAlignment = Enum.TextXAlignment.Left
        descText.Parent = buttonFrame
    end
    
    local clickArea = Instance.new("TextButton")
    clickArea.Text = ""
    clickArea.BackgroundTransparency = 1
    clickArea.Size = UDim2.new(1, 0, 1, 0)
    clickArea.Parent = buttonFrame
    
    -- Interação
    clickArea.MouseButton1Click:Connect(function()
        Utils.Tween(buttonFrame, {
            BackgroundColor3 = Color3.fromRGB(45, 45, 50)
        }, 0.1, Enum.EasingStyle.Linear, function()
            Utils.Tween(buttonFrame, {
                BackgroundColor3 = Theme.Surface
            }, 0.2)
        end)
        
        local success, err = pcall(button.Callback)
        if not success then
            self:Notify({
                Title = "Erro no Botão",
                Message = err,
                Type = "error"
            })
        end
    end)
    
    clickArea.MouseEnter:Connect(function()
        Utils.Tween(buttonStroke, {Thickness = 2}, 0.2)
    end)
    
    clickArea.MouseLeave:Connect(function()
        Utils.Tween(buttonStroke, {Thickness = 1}, 0.2)
    end)
    
    -- Métodos
    function button:Set(config)
        if config.Name then
            buttonText.Text = config.Name
            button.Name = config.Name
        end
        if config.Callback then
            button.Callback = config.Callback
        end
    end
    
    function button:Destroy()
        buttonFrame:Destroy()
    end
    
    return button
end

function AdulterarUI.Window:CreateToggle(config)
    config = config or {}
    
    local toggle = {
        Type = "Toggle",
        Name = config.Name or "Toggle",
        Description = config.Description,
        Value = config.Value or false,
        Callback = config.Callback or function() end,
        Flag = config.Flag
    }
    
    if toggle.Flag then
        AdulterarUI.Options[toggle.Flag] = toggle
    end
    
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Name = "Toggle_" .. toggle.Name
    toggleFrame.BackgroundColor3 = Theme.Surface
    toggleFrame.Size = UDim2.new(1, 0, 0, config.Description and 60 or 40)
    toggleFrame.BorderSizePixel = 0
    
    local toggleCorner = Instance.new("UICorner", toggleFrame)
    toggleCorner.CornerRadius = UDim.new(0, 8)
    
    local toggleText = Instance.new("TextLabel")
    toggleText.Text = toggle.Name
    toggleText.TextColor3 = Theme.Text
    toggleText.BackgroundTransparency = 1
    toggleText.Font = Enum.Font.GothamBold
    toggleText.TextSize = 14
    toggleText.Size = UDim2.new(1, -70, 0, 25)
    toggleText.Position = UDim2.new(0, 10, 0, 8)
    toggleText.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Switch
    local switchFrame = Instance.new("Frame")
    switchFrame.Name = "Switch"
    switchFrame.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    switchFrame.Size = UDim2.new(0, 50, 0, 24)
    switchFrame.Position = UDim2.new(1, -65, 0, 8)
    switchFrame.BorderSizePixel = 0
    
    local switchCorner = Instance.new("UICorner", switchFrame)
    switchCorner.CornerRadius = UDim.new(1, 0)
    
    local switchKnob = Instance.new("Frame")
    switchKnob.Name = "Knob"
    switchKnob.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
    switchKnob.Size = UDim2.new(0, 20, 0, 20)
    switchKnob.Position = UDim2.new(0, 2, 0, 2)
    switchKnob.BorderSizePixel = 0
    
    local knobCorner = Instance.new("UICorner", switchKnob)
    knobCorner.CornerRadius = UDim.new(1, 0)
    
    if config.Description then
        local descText = Instance.new("TextLabel")
        descText.Text = config.Description
        descText.TextColor3 = Theme.TextSecondary
        descText.BackgroundTransparency = 1
        descText.Font = Enum.Font.Gotham
        descText.TextSize = 12
        descText.Size = UDim2.new(1, -70, 0, 15)
        descText.Position = UDim2.new(0, 10, 0, 33)
        descText.TextXAlignment = Enum.TextXAlignment.Left
        descText.Parent = toggleFrame
    end
    
    local clickArea = Instance.new("TextButton")
    clickArea.Text = ""
    clickArea.BackgroundTransparency = 1
    clickArea.Size = UDim2.new(1, 0, 1, 0)
    
    -- Organiza os elementos
    switchKnob.Parent = switchFrame
    switchFrame.Parent = toggleFrame
    toggleText.Parent = toggleFrame
    clickArea.Parent = toggleFrame
    toggleFrame.Parent = self.ContentContainer
    
    -- Estado inicial
    local function updateState()
        if toggle.Value then
            Utils.Tween(switchFrame, {BackgroundColor3 = Theme.Primary}, 0.2)
            Utils.Tween(switchKnob, {
                Position = UDim2.new(1, -22, 0, 2),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            }, 0.2)
        else
            Utils.Tween(switchFrame, {BackgroundColor3 = Color3.fromRGB(70, 70, 70)}, 0.2)
            Utils.Tween(switchKnob, {
                Position = UDim2.new(0, 2, 0, 2),
                BackgroundColor3 = Color3.fromRGB(200, 200, 200)
            }, 0.2)
        end
    end
    
    updateState()
    
    -- Interação
    clickArea.MouseButton1Click:Connect(function()
        toggle.Value = not toggle.Value
        updateState()
        
        local success, err = pcall(toggle.Callback, toggle.Value)
        if not success then
            self:Notify({
                Title = "Erro no Toggle",
                Message = err,
                Type = "error"
            })
        end
    end)
    
    -- Métodos
    function toggle:SetValue(value)
        toggle.Value = value
        updateState()
        toggle.Callback(value)
    end
    
    function toggle:GetValue()
        return toggle.Value
    end
    
    function toggle:Set(config)
        if config.Name then
            toggleText.Text = config.Name
            toggle.Name = config.Name
        end
        if config.Value ~= nil then
            toggle:SetValue(config.Value)
        end
        if config.Callback then
            toggle.Callback = config.Callback
        end
    end
    
    function toggle:Destroy()
        toggleFrame:Destroy()
    end
    
    return toggle
end

function AdulterarUI.Window:CreateSlider(config)
    config = config or {}
    
    local slider = {
        Type = "Slider",
        Name = config.Name or "Slider",
        Min = config.Min or 0,
        Max = config.Max or 100,
        Value = config.Value or 50,
        Callback = config.Callback or function() end,
        Flag = config.Flag
    }
    
    if slider.Flag then
        AdulterarUI.Options[slider.Flag] = slider
    end
    
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Name = "Slider_" .. slider.Name
    sliderFrame.BackgroundColor3 = Theme.Surface
    sliderFrame.Size = UDim2.new(1, 0, 0, 70)
    sliderFrame.BorderSizePixel = 0
    
    local sliderCorner = Instance.new("UICorner", sliderFrame)
    sliderCorner.CornerRadius = UDim.new(0, 8)
    
    local titleText = Instance.new("TextLabel")
    titleText.Text = slider.Name
    titleText.TextColor3 = Theme.Text
    titleText.BackgroundTransparency = 1
    titleText.Font = Enum.Font.GothamBold
    titleText.TextSize = 14
    titleText.Size = UDim2.new(0.5, -10, 0, 25)
    titleText.Position = UDim2.new(0, 10, 0, 8)
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    
    local valueText = Instance.new("TextLabel")
    valueText.Text = tostring(slider.Value)
    valueText.TextColor3 = Theme.TextSecondary
    valueText.BackgroundTransparency = 1
    valueText.Font = Enum.Font.GothamBold
    valueText.TextSize = 14
    valueText.Size = UDim2.new(0.5, -10, 0, 25)
    valueText.Position = UDim2.new(0.5, 0, 0, 8)
    valueText.TextXAlignment = Enum.TextXAlignment.Right
    
    -- Track
    local trackFrame = Instance.new("Frame")
    trackFrame.Name = "Track"
    trackFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
    trackFrame.Size = UDim2.new(1, -20, 0, 8)
    trackFrame.Position = UDim2.new(0, 10, 0, 40)
    trackFrame.BorderSizePixel = 0
    
    local trackCorner = Instance.new("UICorner", trackFrame)
    trackCorner.CornerRadius = UDim.new(1, 0)
    
    local fillFrame = Instance.new("Frame")
    fillFrame.Name = "Fill"
    fillFrame.BackgroundColor3 = Theme.Primary
    fillFrame.Size = UDim2.new(0, 0, 1, 0)
    fillFrame.Position = UDim2.new(0, 0, 0, 0)
    fillFrame.BorderSizePixel = 0
    
    local fillCorner = Instance.new("UICorner", fillFrame)
    fillCorner.CornerRadius = UDim.new(1, 0)
    
    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new(0, -8, 0, -4)
    knob.BorderSizePixel = 0
    
    local knobCorner = Instance.new("UICorner", knob)
    knobCorner.CornerRadius = UDim.new(1, 0)
    
    -- Organiza
    fillFrame.Parent = trackFrame
    knob.Parent = trackFrame
    trackFrame.Parent = sliderFrame
    titleText.Parent = sliderFrame
    valueText.Parent = sliderFrame
    sliderFrame.Parent = self.ContentContainer
    
    -- Estado inicial
    local function updateSlider()
        local percentage = (slider.Value - slider.Min) / (slider.Max - slider.Min)
        local fillWidth = percentage * trackFrame.AbsoluteSize.X
        
        Utils.Tween(fillFrame, {Size = UDim2.new(0, fillWidth, 1, 0)}, 0.1)
        Utils.Tween(knob, {Position = UDim2.new(0, fillWidth - 8, 0, -4)}, 0.1)
        valueText.Text = tostring(math.floor(slider.Value))
    end
    
    updateSlider()
    
    -- Interação
    local dragging = false
    
    local function updateFromMouse()
        if not dragging then return end
        
        local mousePos = UserInputService:GetMouseLocation().X
        local trackPos = trackFrame.AbsolutePosition.X
        local trackSize = trackFrame.AbsoluteSize.X
        
        local relativePos = math.clamp(mousePos - trackPos, 0, trackSize)
        local percentage = relativePos / trackSize
        
        slider.Value = math.floor(slider.Min + percentage * (slider.Max - slider.Min))
        updateSlider()
        
        local success, err = pcall(slider.Callback, slider.Value)
        if not success then
            self:Notify({
                Title = "Erro no Slider",
                Message = err,
                Type = "error"
            })
        end
    end
    
    trackFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateFromMouse()
        end
    end)
    
    trackFrame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateFromMouse()
        end
    end)
    
    -- Métodos
    function slider:SetValue(value)
        slider.Value = math.clamp(value, slider.Min, slider.Max)
        updateSlider()
        slider.Callback(slider.Value)
    end
    
    function slider:GetValue()
        return slider.Value
    end
    
    function slider:Set(config)
        if config.Name then
            titleText.Text = config.Name
            slider.Name = config.Name
        end
        if config.Value then
            slider:SetValue(config.Value)
        end
        if config.Min then slider.Min = config.Min end
        if config.Max then slider.Max = config.Max end
        if config.Callback then
            slider.Callback = config.Callback
        end
    end
    
    function slider:Destroy()
        sliderFrame:Destroy()
    end
    
    return slider
end

function AdulterarUI.Window:Destroy()
    if self.Container then
        self.Container:Destroy()
    end
    
    -- Remove da lista
    for i, window in ipairs(AdulterarUI.Windows) do
        if window == self then
            table.remove(AdulterarUI.Windows, i)
            break
        end
    end
    
    if AdulterarUI.ActiveWindow == self then
        AdulterarUI.ActiveWindow = #AdulterarUI.Windows > 0 and AdulterarUI.Windows[1] or nil
    end
end

-- Função para criar janela principal (simplificada para exemplo)
function AdulterarUI:CreateWindow(config)
    local window = AdulterarUI.Window:New(config)
    return window
end

-- Sistema de auto-cleanup
game:GetService("Players").PlayerRemoving:Connect(function(player)
    if player == Players.LocalPlayer then
        for _, window in ipairs(AdulterarUI.Windows) do
            window:Destroy()
        end
    end
end)

-- Exporta a UI
return AdulterarUI
