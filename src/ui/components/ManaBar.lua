-- src/ui/components/ManaBar.lua
-- Компонент: панель маны

local ManaBar = {}

local function Create(parent: Instance)
    local frame = Instance.new("Frame")
    frame.Name = "ManaBar"
    frame.Size = UDim2.new(0, 280, 0, 35)
    frame.Position = UDim2.new(0, 15, 0, 15)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
    frame.BorderSizePixel = 0
    frame.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(1, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 100, 255)
    fill.BorderSizePixel = 0
    fill.Parent = frame
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 8)
    fillCorner.Parent = fill
    
    local icon = Instance.new("TextLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 30, 1, 0)
    icon.BackgroundTransparency = 1
    icon.Text = "💙"
    icon.TextColor3 = Color3.fromRGB(255, 255, 255)
    icon.TextScaled = true
    icon.Font = Enum.Font.GothamBold
    icon.Parent = frame
    
    local text = Instance.new("TextLabel")
    text.Name = "Text"
    text.Size = UDim2.new(1, -35, 1, 0)
    text.Position = UDim2.new(0, 35, 0, 0)
    text.BackgroundTransparency = 1
    text.Text = "50/50 маны"
    text.TextColor3 = Color3.fromRGB(255, 255, 255)
    text.TextScaled = true
    text.Font = Enum.Font.GothamBold
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.Parent = frame
    
    return {
        Frame = frame,
        Fill = fill,
        Text = text,
    }
end

function ManaBar.New(parent: Instance)
    local self = {}
    self.components = Create(parent)
    
    function self.Update(current: number, max: number)
        local percent = current / max
        self.components.Fill.Size = UDim2.new(percent, 0, 1, 0)
        
        if percent < 0.2 then
            self.components.Fill.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        elseif percent < 0.5 then
            self.components.Fill.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
        else
            self.components.Fill.BackgroundColor3 = Color3.fromRGB(0, 100, 255)
        end
        
        self.components.Text.Text = `${math.floor(current)}/${max} маны`
    end
    
    return self
end

return ManaBar