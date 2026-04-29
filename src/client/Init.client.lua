--!strict
-- src/client/init.client.lua
-- ТОЧКА ВХОДА КЛИЕНТА

local line = string.rep("=", 50)

print(line)
print("🧙‍♂️ NECROMANCER GAME - КЛИЕНТ ЗАПУЩЕН")
print(line)

-- Клиентские модули (ищем внутри текущего скрипта, так как Rojo сделал Main контейнером)
local NetworkBridge = require(script:WaitForChild("NetworkBridge"))
local RemoteListener = require(script:WaitForChild("RemoteListener"))
local CameraController = require(script:WaitForChild("CameraController"))
local InputHandler = require(script:WaitForChild("InputHandler"))

-- UI модуль (находится в папке ui внутри текущего скрипта)
local uiFolder = script:WaitForChild("ui")
local UIManager = require(uiFolder:WaitForChild("UIManager"))

-- Инициализация (порядок важен!)
print("[Init] Инициализация NetworkBridge...")
NetworkBridge.Init()

print("[Init] Инициализация RemoteListener...")
RemoteListener.Init()

print("[Init] Инициализация CameraController...")
CameraController.Init()

print("[Init] Инициализация InputHandler...")
InputHandler.Init()

print("[Init] Инициализация UIManager...")
UIManager.Init()

print(line)
print("[Init] ✅ ВСЕ КЛИЕНТСКИЕ МОДУЛИ ЗАГРУЖЕНЫ")
print(line)
