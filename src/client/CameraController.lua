-- src/client/CameraController.lua
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Ссылки на персонажа
local playerCharacter = nil
local playerHumanoidRootPart = nil

-- ============================================
-- Конфигурация
-- ============================================
local CONFIG = {
    CubeMode = {
        Distance = 30,
        Height = 15,
        Speed = 0.4,          -- Скорость вращения
        ZoomSpeed = 5,        -- Скорость зума
        MinDistance = 10,
        MaxDistance = 100,
        MinPitch = -10,       -- Макс. наклон вверх (в градусах)
        MaxPitch = 80,        -- Макс. наклон вниз
    },
}

-- ============================================
-- Состояние
-- ============================================
local currentMode = "Body"
local cubeRotation = 0    -- Угол влево/вправо
local cubePitch = 30       -- Угол вверх/вниз
local cubeDistance = CONFIG.CubeMode.Distance

-- ============================================
-- Логика камеры
-- ============================================

local function UpdateCubeCamera()
    if not playerHumanoidRootPart then return end
    
    local bodyPosition = playerHumanoidRootPart.Position
    local rotationRad = math.rad(cubeRotation)
    local pitchRad = math.rad(cubePitch)
    
    -- Сферические координаты для свободного вращения
    local offsetX = math.cos(pitchRad) * math.sin(rotationRad) * cubeDistance
    local offsetZ = math.cos(pitchRad) * math.cos(rotationRad) * cubeDistance
    local offsetY = math.sin(pitchRad) * cubeDistance
    
    local cameraPosition = bodyPosition + Vector3.new(offsetX, offsetY, offsetZ)
    local lookAt = bodyPosition + Vector3.new(0, 2, 0) -- Фокус чуть выше центра тела
    
    camera.CFrame = CFrame.new(cameraPosition, lookAt)
end

-- ============================================
-- Публичный модуль
-- ============================================
local CameraController = {}

function CameraController.SetMode(mode: string)
    currentMode = mode
    
    if mode == "Cube" then
        camera.CameraType = Enum.CameraType.Scriptable
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
    else
        camera.CameraType = Enum.CameraType.Custom
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    end
end

-- Настройка ввода (Зум и Персонаж)
local function SetupConnections()
    -- Зум колесиком мыши
    UserInputService.InputChanged:Connect(function(input, processed)
        if processed then return end
        if input.UserInputType == Enum.UserInputType.MouseWheel and currentMode == "Cube" then
            cubeDistance = math.clamp(
                cubeDistance - (input.Position.Z * CONFIG.CubeMode.ZoomSpeed), 
                CONFIG.CubeMode.MinDistance, 
                CONFIG.CubeMode.MaxDistance
            )
        end
    end)

    -- Обновление персонажа при спавне
    player.CharacterAdded:Connect(function(character)
        playerCharacter = character
        playerHumanoidRootPart = character:WaitForChild("HumanoidRootPart")
        if currentMode == "Cube" then
            camera.CameraType = Enum.CameraType.Scriptable
        end
    end)

    -- Первоначальный поиск персонажа
    if player.Character then
        playerCharacter = player.Character
        playerHumanoidRootPart = playerCharacter:FindFirstChild("HumanoidRootPart")
    end
end

function CameraController.Update(deltaTime: number)
    if currentMode == "Cube" then
        -- Вращение при зажатой правой кнопке (MouseButton2)
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            local delta = UserInputService:GetMouseDelta()
            
            -- Горизонтальное вращение
            cubeRotation = cubeRotation - (delta.X * CONFIG.CubeMode.Speed)
            
            -- Вертикальное вращение (вверх/вниз)
            cubePitch = cubePitch + (delta.Y * CONFIG.CubeMode.Speed)
            
            -- Ограничиваем, чтобы камера не делала "сальто"
            cubePitch = math.clamp(cubePitch, CONFIG.CubeMode.MinPitch, CONFIG.CubeMode.MaxPitch)
        end
        
        UpdateCubeCamera()
    end
end

function CameraController.Init()
    SetupConnections()

    RunService.RenderStepped:Connect(function(deltaTime)
        CameraController.Update(deltaTime)
    end)
    
    -- Сразу включаем свободную камеру
    CameraController.SetMode("Cube")
end

return CameraController
