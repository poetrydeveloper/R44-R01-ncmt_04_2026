-- src/ui/components/ToggleStackButton.lua
-- Компонент: кнопка скрытия/показа стека карточек

local ToggleStackButton = {}

function ToggleStackButton.New(parent: Instance, onToggle: (visible: boolean) -> ())
    local button = Instance.new("ImageButton")
    button.Name = "ToggleStackButton"
    button.Size = UDim2.new(0, 40, 0, 40)
    button.Position = UDim2.new(1, -55, 0, 60)
    button.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    button.BorderSizePixel = 0
    button.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button
    
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(1, 0, 1, 0)
    icon.BackgroundTransparency = 1
    icon.Text = "📇"
    icon.TextColor3 = Color3.fromRGB(255, 255, 255)
    icon.TextScaled = true
    icon.Font = Enum.Font.GothamBold
    icon.Parent = button
    
    local isVisible = true
    
    button.MouseButton1Click:Connect(function()
        isVisible = not isVisible
        if onToggle then
            onToggle(isVisible)
        end
    end)
    
    return button
end

return ToggleStackButton