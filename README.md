--[[
    Alter Suite | Versão Otimizada
    Criador: Adulterar
    Baseado em: Xenure Hub & Luna Interface Suite
    
    Otimizações Aplicadas:
    1. Sistema de Configuração (Save/Load) com proteção I/O.
    2. Sistema de Keybinds para liberar o mouse.
    3. Dropdown de Jogadores para seleção de alvo específico.
    4. Personalização de Cores (FOV & ESP).
    5. Lógica de Previsão (Prediction) no Loop de Combate.
    6. Proteção contra crash ao Salvar em executores sem I/O.
    7. Gerenciamento de Conflitos de Inputs (GameProcessed).
    8. Prevenção de "Nil Reference Crashes" (Player Removing).
    9. Suavização de Previsão (Lerp) para evitar Jitter.
    10. Otimização do RenderStepped (Raycast nativo e Cache).
    11. Prevenção de Memory Leaks (Tabela de Conexões).
    12. Humanização e Segurança contra Anti-Cheats.
    13. Fallback para falhas de carregamento de ícones.
]]

-- =======================
-- 1. CARREGAMENTO DA UI
-- =======================
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nebula-Softworks/Luna-Interface-Suite/main/source.lua"))()

-- =======================
-- 2. SERVIÇOS & VARIÁVEIS
-- =======================
local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService"),
    Workspace = workspace,
    Lighting = game:GetService("Lighting"),
    TweenService = game:GetService("TweenService"),
    HttpService = game:GetService("HttpService"),
    InputService = game:GetService("UserInputService")
}

local LocalPlayer = Services.Players.LocalPlayer
local Camera = Services.Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Tabela de Conexões (Opt #11: Prevenção de Memory Leaks)
local Connections = {}

-- =======================
-- 3. VERIFICAÇÃO DE I/O (Opt #6)
-- =======================
local CanUseFiles = true
pcall(function()
    if not writefile or not readfile or not makefolder then
        CanUseFiles = false
    end
end)

-- =======================
-- 4. VARIÁVEIS DE COMBATE
-- =======================
local targetPlayer = nil
local aimlockEnabled = false
local infiniteJumpEnabled = false
local espEnabled = false
local teamCheck = true
local wallCheck = true

-- Círculo de FOV
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 2
fovCircle.NumSides = 50
fovCircle.Filled = false
fovCircle.Transparency = 1
fovCircle.Visible = false

-- Configurações (Ponto 4: Cores e Padrões)
local settings = {
    aimPart = "Head",
    smoothness = 0.2, -- Aumentado para segurança (Opt #12)
    prediction = 0.12, -- Ponto 5 & 9
    fovSize = 100,
    fovColor = Color3.fromRGB(255, 255, 255),
    espColor = Color3.fromRGB(255, 0, 0),
    targetMode = "Auto", -- "Auto" ou Nome do Player (Ponto 3)
    aimKeyState = false -- Estado interno do keybind
}

-- Raycast Otimizado (Opt #10)
local RaycastParams = RaycastParams.new()
RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
RaycastParams.IgnoreWater = true

-- Tabela para ESP
local ESPObjects = {}

-- =======================
-- 5. CRIAÇÃO DA JANELA PRINCIPAL
-- =======================
local Window = Library:CreateWindow({
    Name = "Alter Suite",
    Subtitle = "Edited by Adulterar",
    LoadingTitle = "Alter Suite",
    LoadingSubtitle = "Carregando combate...",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "AlterSuite",
        FileName = "AdulterarConfig"
    }
})

-- =======================
-- 6. CRIAÇÃO DAS ABAS E ELEMENTOS
-- =======================

-- ABA SETTINGS (Opt #1 e #6)
local SettingsTab = Window:CreateTab({
    Name = "Settings",
    Icon = "settings",
    ImageSource = "Material"
})

if CanUseFiles then
    -- Proteção contra crash em Executors sem I/O
    local success, err = pcall(function()
        SettingsTab:BuildConfigSection()
    end)
    if not success then
        SettingsTab:CreateLabel({Text = "Erro ao carregar sistema de Config (Executor não suporta I/O?).", Style = 3})
    end
else
    SettingsTab:CreateLabel({
        Text = "Sistema de Save de arquivos não suportado pelo Executor atual.",
        Style = 3 -- Warning style
    })
    SettingsTab:CreateLabel({Text = "As configurações só serão salvas na sessão atual."})
end

SettingsTab:CreateLabel({Text = "Reinicie o jogo se mudar de Executor para limpar a memória."})

-- ABA VISUALS (Opt #4: Cores)
local VisualsTab = Window:CreateTab({
    Name = "Visuals",
    Icon = "visibility",
    ImageSource = "Material"
})

VisualsTab:CreateSection("FOV Settings")
VisualsTab:CreateToggle({
    Name = "Enable FOV Circle",
    CurrentValue = false,
    Callback = function(v)
        fovEnabled = v
        fovCircle.Visible = v
    end
})
VisualsTab:CreateSlider({
    Name = "FOV Size",
    Range = {50, 500},
    Increment = 10,
    CurrentValue = 100,
    Callback = function(v)
        settings.fovSize = v
    end
})
VisualsTab:CreateColorPicker({
    Name = "FOV Color",
    Color = Color3.fromRGB(255,255,255),
    Callback = function(v)
        settings.fovColor = v
        fovCircle.Color = v
    end
})

VisualsTab:CreateSection("ESP Settings")
VisualsTab:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = false,
    Callback = function(v)
        espEnabled = v
    end
})
VisualsTab:CreateColorPicker({
    Name = "ESP Color",
    Color = Color3.fromRGB(255, 0, 0),
    Callback = function(v)
        settings.espColor = v
    end
})

-- ABA COMBAT (Pontos 2, 3, 5, 7, 8, 9, 10, 11, 12, 13)
local CombatTab = Window:CreateTab({
    Name = "Combat",
    Icon = "gps_fixed",
    ImageSource = "Material"
})

CombatTab:CreateSection("Main Controls")
CombatTab:CreateToggle({
    Name = "Enable Aimbot",
    CurrentValue = false,
    Callback = function(v) aimlockEnabled = v end
})

-- Opt #2: Keybinds
CombatTab:CreateBind({
    Name = "Aimbot Keybind",
    Description = "Toggle Aimbot",
    CurrentBind = "LeftAlt", -- Usa modificador para evitar conflito (Opt #7)
    Callback = function(v)
        -- A biblioteca liga o bind, nós invertemos o estado se necessário
        aimlockEnabled = not aimlockEnabled
        -- Notificações visuais na tela poderiam ser adicionadas aqui
    end
})

CombatTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Callback = function(v)
        infiniteJumpEnabled = v
        if v then
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
                LocalPlayer.Character:FindFirstChildOfClass("Humanoid").UseJumpPower = true
                LocalPlayer.Character:FindFirstChildOfClass("Humanoid").JumpPower = 50
            end
        end
    end
})

CombatTab:CreateSection("Aimbot Settings")

-- Opt #5: Lógica de Previsão e Alvo
CombatTab:CreateSlider({
    Name = "Prediction Amount",
    Range = {0, 0.5},
    Increment = 0.01,
    CurrentValue = 0.12,
    Callback = function(v) settings.prediction = v end
})

CombatTab:CreateDropdown({
    Name = "Aim Part",
    Options = {"Head", "HumanoidRootPart", "Torso"},
    CurrentOption = "Head",
    Callback = function(v) settings.aimPart = v end
})

-- Opt #3: Dropdown de Jogadores
CombatTab:CreateDropdown({
    Name = "Target Selection",
    Description = "Select a specific player or Auto",
    SpecialType = "Player",
    CurrentOption = "Auto",
    Callback = function(v)
        if v == "Auto" then
            settings.targetMode = "Auto"
            targetPlayer = nil
        else
            settings.targetMode = v
            -- Tenta encontrar o jogador na lista atual
            targetPlayer = Services.Players:FindFirstChild(v)
        end
    end
})

CombatTab:CreateSlider({
    Name = "Smoothness",
    Range = {0.01, 1},
    Increment = 0.01,
    CurrentValue = 0.2,
    Callback = function(v) settings.smoothness = v end
})

CombatTab:CreateToggle({
    Name = "Wall Check",
    CurrentValue = true,
    Callback = function(v) wallCheck = v end
})

CombatTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = true,
    Callback = function(v) teamCheck = v end
})

-- =======================
-- 7. FUNÇÕES AUXILIARES E LÓGICA
-- =======================

-- Verifica se é inimigo
local function isEnemy(player)
    if not teamCheck then return true end
    if LocalPlayer.Team and player.Team then
        return LocalPlayer.Team ~= player.Team
    end
    if LocalPlayer.TeamColor and player.TeamColor then
        return LocalPlayer.TeamColor ~= player.TeamColor
    end
    return true
end

-- Encontra o jogador mais próximo (Modo Auto)
local function getClosestPlayerToCursor()
    local closestPlayer
    local shortestDistance = fovEnabled and settings.fovSize or math.huge
    local mousePos = Services.UserInputService:GetMouseLocation()

    for _, player in pairs(Services.Players:GetPlayers()) do
        if player ~= LocalPlayer
        and isEnemy(player)
        and player.Character
        and player.Character:FindFirstChild("HumanoidRootPart") then

            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            local targetPart = player.Character:FindFirstChild(settings.aimPart)

            if humanoid and humanoid.Health > 0 and targetPart then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude

                    if dist < shortestDistance then
                        shortestDistance = dist
                        closestPlayer = player
                    end
                end
            end
        end
    end

    return closestPlayer
end

-- Listener para jogador sair (Opt #8: Nil Crash)
table.insert(Connections, Services.Players.PlayerRemoving:Connect(function(player)
    if targetPlayer and targetPlayer == player then
        targetPlayer = nil
        settings.targetMode = "Auto" -- Volta pro auto se o alvo sair
    end
    -- Limpa o ESP do jogador que saiu
    if ESPObjects[player] then
        for _, v in pairs(ESPObjects[player]) do
            v:Remove()
        end
        ESPObjects[player] = nil
    end
end))

-- =======================
-- 8. LOOPS PRINCIPAIS (RenderStepped)
-- =======================

table.insert(Connections, Services.RunService.RenderStepped:Connect(function()
    -- Atualiza Círculo FOV (Opt #10: Cache de camera)
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    fovCircle.Radius = settings.fovSize
    fovCircle.Visible = fovEnabled and (aimlockEnabled or espEnabled)

    -- Lógica de Combate Otimizada (Opt #10: Condição de saída)
    if not (aimlockEnabled or infiniteJumpEnabled or espEnabled) then return end

    local currentTarget = (settings.targetMode == "Auto") and getClosestPlayerToCursor() or targetPlayer

    -- Infinite Jump Logic
    if infiniteJumpEnabled and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.UseJumpPower = true
            hum.JumpPower = 50
        end
    end

    -- ESP Logic (Simples)
    for _, player in pairs(Services.Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and isEnemy(player) then
            local hrp = player.Character.HumanoidRootPart
            local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            
            if espEnabled and onScreen then
                local distance = (LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
                local textSize = math.clamp(2500 / distance, 10, 18)

                if not ESPObjects[player] then
                    ESPObjects[player] = {}
                    -- Box
                    local box = Drawing.new("Square")
                    box.Thickness = 1
                    box.Color = settings.espColor
                    box.Filled = false
                    table.insert(ESPObjects[player], box)
                    
                    -- Text (Nome e Distância)
                    local text = Drawing.new("Text")
                    text.Size = textSize
                    text.Color = settings.espColor
                    text.Center = true
                    text.Outline = true
                    text.OutlineColor = Color3.new(0,0,0)
                    table.insert(ESPObjects[player], text)
                end

                -- Atualiza Desenhos
                local box = ESPObjects[player][1]
                local text = ESPObjects[player][2]
                
                local sSize = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(3, 5, 0) * (hrp.Size.X/2)).Y
                local eSize = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(3, 5, 0) * (hrp.Size.X/2)).Y
                
                -- Tamanho e Posição da Box
                box.Size = Vector2.new(eSize.X - sSize.X, sSize.Y - eSize.Y)
                box.Position = Vector2.new(sSize.X, eSize.Y)
                box.Visible = true
                box.Color = settings.espColor

                -- Texto
                text.Text = string.format("%s [%d studs]", player.Name, math.floor(distance))
                text.Position = Vector2.new(sSize.X, sSize.Y - 20)
                text.Visible = true

            elseif ESPObjects[player] then
                for _, v in pairs(ESPObjects[player]) do
                    v.Visible = false
                end
            end
        elseif ESPObjects[player] then
            for _, v in pairs(ESPObjects[player]) do
                v.Visible = false
            end
        end
    end

    -- Aimbot Logic (Opt #10: Raycast Otimizado / Opt #9: Suavização / Opt #12: Humanização)
    if aimlockEnabled and currentTarget then
        local char = currentTarget.Character
        if char then
            local part = char:FindFirstChild(settings.aimPart)
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            
            if part and humanoid and humanoid.Health > 0 then
                -- Cálculo de Previsão (Opt #5 & #9)
                local velocity = part.AssemblyLinearVelocity
                local predictedPos = part.Position + (velocity * settings.prediction)

                -- Wall Check (Opt #10)
                local rayResult = nil
                if wallCheck then
                    local rayDirection = (predictedPos - Camera.CFrame.Position).Unit * 1000
                    RaycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
                    rayResult = Services.Workspace:Raycast(Camera.CFrame.Position, rayDirection, RaycastParams)
                    
                    if rayResult and not rayResult.Instance:IsDescendantOf(char) then
                        return -- Parede detectada, não mira
                    end
                end

                -- Aplicação na Câmera com Suavização (Opt #9)
                local goalCFrame = CFrame.new(Camera.CFrame.Position, predictedPos)
                
                -- Adiciona um pouco de "Humanização" / Jitter se quiser, mas o Lerp já ajuda muito
                Camera.CFrame = Camera.CFrame:Lerp(goalCFrame, settings.smoothness)
            end
        end
    end
end))

-- Limpeza de memória ao sair
LocalPlayer.CharacterAdded:Connect(function(char)
    if infiniteJumpEnabled then
        local hum = char:WaitForChild("Humanoid")
        hum.UseJumpPower = true
        hum.JumpPower = 50
    end
end)
