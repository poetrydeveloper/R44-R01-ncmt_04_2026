-- src/client/CameraController.lua
-- Управление камерой: режим тела и режим куба

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ============================================
-- Конфигурация
-- ============================================

local CONFIG = {
    -- Режим тела (слежка за персонажем)
    BodyMode = {
        Offset = Vector3.new(0, 5, 15),  -- Сзади-сверху
        Smoothness = 0.1,
    },
    -- Режим куба (свободная камера)
    CubeMode = {
        Distance = 30,      -- Расстояние от центра
        Height = 15,        -- Высота
        Speed = 0.5,        -- Скорость вращения
        ZoomSpeed = 2,      -- Скорость зума
        MinDistance = 10,
        MaxDistance = 60,
    },
}

-- ============================================
-- Состояние
-- ============================================

local currentMode = "Body"  -- "Body" или "Cube"
local cubeRotation = 0      -- Угол поворота камеры в кубе
local cubeDistance = CONFIG.CubeMode.Distance
local cubeHeight = CONFIG.CubeMode.Height

local playerCharacter = nil
local playerHumanoidRootPart = nil

-- ============================================
-- Режим тела (обычная камера за персонажем)
-- ============================================

local function UpdateBodyCamera()
    if not playerCharacter or not playerHumanoidRootPart then
        playerCharacter = player.Character
        if playerCharacter then
            playerHumanoidRootPart = playerCharacter:FindFirstChild("HumanoidRootPart")
        end
        return
    end
    
    local targetPosition = playerHumanoidRootPart.Position + CONFIG.BodyMode.Offset
    camera.CFrame = camera.CFrame:Lerp(CFrame.new(targetPosition, playerHumanoidRootPart.Position), CONFIG.BodyMode.Smoothness)
end

-- ============================================
-- Режим куба (свободная камера, управление мышью)
-- ============================================

local function UpdateCubeCamera()
    -- Получаем позицию тела игрока (оно стоит в кубе)
    local bodyPosition = Vector3.zero
    if playerCharacter and playerHumanoidRootPart then
        bodyPosition = playerHumanoidRootPart.Position
    end
    
    -- Вычисляем позицию камеры
    local angleRad = math.rad(cubeRotation)
    local offsetX = math.sin(angleRad) * cubeDistance
    local offsetZ = math.cos(angleRad) * cubeDistance
    
    local cameraPosition = bodyPosition + Vector3.new(offsetX, cubeHeight, offsetZ)
    local lookAt = bodyPosition + Vector3.new(0, cubeHeight * 0.5, 0)
    
    camera.CFrame = CFrame.new(cameraPosition, lookAt)
end

-- ============================================
-- Обработка ввода в режиме куба
-- ============================================

local function HandleCubeInput()
    -- Вращение камеры (правой кнопкой мыши + движение)
    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local delta = UserInputService:GetMouseDelta()
        cubeRotation = cubeRotation - delta.X * CONFIG.CubeMode.Speed
    end
    
    -- Зум (колесико мыши)
    local zoomDelta = UserInputService:GetMouseDelta().Z
    if zoomDelta ~= 0 then
        cubeDistance = cubeDistance - zoomDelta * CONFIG.CubeMode.ZoomSpeed
        cubeDistance = math.clamp(cubeDistance, CONFIG.CubeMode.MinDistance, CONFIG.CubeMode.MaxDistance)
    end
end

-- ============================================
-- Публичные функции
-- ============================================

local CameraController = {}

-- Переключить режим камеры
function CameraController.SetMode(mode: string)
    currentMode = mode
    print(`[CameraController] 🎥 Режим камеры: ${mode}`)
    
    if mode == "Cube" then
        -- Сохраняем текущее положение камеры относительно тела
        if playerCharacter and playerHumanoidRootPart then
            local bodyPos = playerHumanoidRootPart.Position
            local camOffset = camera.CFrame.Position - bodyPos
            cubeDistance = math.sqrt(camOffset.X^2 + camOffset.Z^2)
            cubeHeight = camOffset.Y
            cubeRotation = math.atan2(camOffset.X, camOffset.Z)
        end
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
    else
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    end
end

-- Получить текущий режим
function CameraController.GetMode(): string
    return currentMode
}

-- Обновление камеры (вызывается каждый кадр)
function CameraController.Update(deltaTime: number)
    if currentMode == "Cube" then
        HandleCubeInput()
        UpdateCubeCamera()
    else
        UpdateBodyCamera()
    end
end

-- Инициализация
function CameraController.Init()
    print("[CameraController] 🎥 Инициализация камеры")
    
    -- Ждем появления персонажа
    player.CharacterAdded:Connect(function(character)
        playerCharacter = character
        playerHumanoidRootPart = character:WaitForChild("HumanoidRootPart")
        print("[CameraController] Персонаж загружен")
    end)
    
    if player.Character then
        playerCharacter = player.Character
        playerHumanoidRootPart = playerCharacter:FindFirstChild("HumanoidRootPart")
    end
    
    -- Запускаем цикл обновления
    RunService.RenderStepped:Connect(function(deltaTime)
        CameraController.Update(deltaTime)
    end)
    
    print("[CameraController] ✅ Готов")
end

return CameraController