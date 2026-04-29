-- src/ui/components/LevelPanel.lua
-- Компонент: уровень и опыт

local LevelPanel = {}

local function Create(parent: Instance)
    local frame = Instance.new("Frame")
    frame.Name = "LevelPanel"
    frame.Size = UDim2.new(0, 200, 0, 50)
    frame.Position = UDim2.new(0, 15, 0, 60)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local levelText = Instance.new("TextLabel")
    levelText.Name = "LevelText"
    levelText.Size = UDim2.new(0, 60, 1, 0)
    levelText.BackgroundTransparency = 1
    levelText.Text = "Ур. 1"
    levelText.TextColor3 = Color3.fromRGB(255, 200, 100)
    levelText.TextScaled = true
    levelText.Font = Enum.Font.GothamBold
    levelText.Parent = frame
    
    local expBar = Instance.new("Frame")
    expBar.Name = "ExpBar"
    expBar.Size = UDim2.new(0.65, 0, 1, -10)
    expBar.Position = UDim2.new(0.35, 0, 0, 5)
    expBar.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    expBar.BorderSizePixel = 0
    expBar.Parent = frame
    
    local expBarCorner = Instance.new("UICorner")
    expBarCorner.CornerRadius = UDim.new(0, 4)
    expBarCorner.Parent = expBar
    
    local expFill = Instance.new("Frame")
    expFill.Name = "ExpFill"
    expFill.Size = UDim2.new(0, 0, 1, 0)
    expFill.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
    expFill.BorderSizePixel = 0
    expFill.Parent = expBar
    
    local expFillCorner = Instance.new("UICorner")
    expFillCorner.CornerRadius = UDim.new(0, 4)
    expFillCorner.Parent = expFill
    
    local expText = Instance.new("TextLabel")
    expText.Name = "ExpText"
    expText.Size = UDim2.new(1, -5, 1, 0)
    expText.Position = UDim2.new(0, 5, 0, 0)
    expText.BackgroundTransparency = 1
    expText.Text = "0/100"
    expText.TextColor3 = Color3.fromRGB(200, 200, 200)
    expText.TextSize = 12
    expText.Font = Enum.Font.Gotham
    expText.TextXAlignment = Enum.TextXAlignment.Left
    expText.Parent = expBar
    
    return {
        Frame = frame,
        LevelText = levelText,
        ExpFill = expFill,
        ExpText = expText,
    }
end

function LevelPanel.New(parent: Instance)
    local self = {}
    self.components = Create(parent)
    
    function self.Update(level: number, experience: number, nextLevelExp: number)
        self.components.LevelText.Text = `Ур. ${level}`
        local percent = experience / nextLevelExp
        self.components.ExpFill.Size = UDim2.new(percent, 0, 1, 0)
        self.components.ExpText.Text = `${experience}/${nextLevelExp}`
    end
    
    return self
end

return LevelPanel