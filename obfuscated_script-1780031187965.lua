-- LocalScript inside StarterPlayerScripts / StarterGui
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")

local LocalPlayer = Players.LocalPlayer
local lplr = LocalPlayer
local SERVER_JOB_ID = game.JobId ~= "" and game.JobId or "Studio_Local_Server"

-- Custom Spoofed Name State
local SpoofedDisplayName = nil

-- Script Load Timestamp (Only show messages created after this execution)
local ScriptStartTime = os.time()

-- Forward Declaration for Inputs & Globals
local MessageInput = nil
local SendChatMessage = nil

-- Anti-Spam Tracking State
local LastSentMessageText = ""
local ConsecutiveSpamCount = 0
local LastMessageSendTime = 0

-- PFP PERSISTENCE SYSTEM
local PFP_CONFIG_FILE = "Kronos_PFP_Config.json"
local DefaultPFP = "rbxassetid://110388265928893"
local CurrentPFP = DefaultPFP

local function SavePFPLocally(pfpId)
    CurrentPFP = pfpId
    if writefile then
        pcall(function()
            writefile(PFP_CONFIG_FILE, HttpService:JSONEncode({ ProfilePicture = pfpId }))
        end)
    end
end

local function LoadPFPLocally()
    if readfile and isfile and isfile(PFP_CONFIG_FILE) then
        local success, result = pcall(function()
            local data = HttpService:JSONDecode(readfile(PFP_CONFIG_FILE))
            if data and data.ProfilePicture then
                return data.ProfilePicture
            end
        end)
        if success and result then
            return result
        end
    end
    return DefaultPFP
end

CurrentPFP = LoadPFPLocally()

-- BOY PFP LIST
local BOY_PFPS = {
    "rbxassetid://110388265928893", "rbxassetid://95859643981980", "rbxassetid://130155182109980", "rbxassetid://13256391094",
    "rbxassetid://7141979877", "rbxassetid://126321955109144", "rbxassetid://105811627876448", "rbxassetid://117842977352398",
    "rbxassetid://72892670694166", "rbxassetid://83103469598025", "rbxassetid://75074160606432", "rbxassetid://102436713076194",
    "rbxassetid://73360959903200", "rbxassetid://8044287275", "rbxassetid://75575644706346", "rbxassetid://135418144122968",
    "rbxassetid://108362888723956", "rbxassetid://72208791847173", "rbxassetid://126308173151046", "rbxassetid://12589564218",
    "rbxassetid://79957717292980", "rbxassetid://9167461968", "rbxassetid://14958453101", "rbxassetid://15812656372",
    "rbxassetid://17742534348", "rbxassetid://16512222623", "rbxassetid://16512186702", "rbxassetid://15139830823",
    "rbxassetid://113690915196801", "rbxassetid://13815759727", "rbxassetid://17209732396", "rbxassetid://9465573085",
    "rbxassetid://6828147162", "rbxassetid://8798642997", "rbxassetid://6931482888", "rbxassetid://11465013207",
    "rbxassetid://6151184293", "rbxassetid://11792088810", "rbxassetid://11792051524", "rbxassetid://12129851981",
    "rbxassetid://7766253892", "rbxassetid://11810744690", "rbxassetid://12129866999", "rbxassetid://11792081695",
    "rbxassetid://9812014649", "rbxassetid://11566642562", "rbxassetid://11566643877", "rbxassetid://11566645628",
    "rbxassetid://15489228483", "rbxassetid://139913462267814", "rbxassetid://127087398265711", "rbxassetid://15741130603",
    "rbxassetid://15914059452", "rbxassetid://135351963625525", "rbxassetid://116451771061047", "rbxassetid://128665410481682",
    "rbxassetid://80274332831847", "rbxassetid://82099431184126", "rbxassetid://133311251800519", "rbxassetid://13120458633",
    "rbxassetid://115774065375902", "rbxassetid://70802874073501", "rbxassetid://13589962584", "rbxassetid://14640595544",
    "rbxassetid://13399057339", "rbxassetid://10246136967", "rbxassetid://133023108030460", "rbxassetid://119497955225507",
    "rbxassetid://16167788172", "rbxassetid://12972724276", "rbxassetid://18955458678"
}

-- GIRL PFP LIST
local GIRL_PFPS = {
    "rbxassetid://12020075855", "rbxassetid://11830086459", "rbxassetid://11511962080", "rbxassetid://7777672203",
    "rbxassetid://11830084792", "rbxassetid://7332178758", "rbxassetid://7430248978", "rbxassetid://7766251418",
    "rbxassetid://9093346004", "rbxassetid://9093348980", "rbxassetid://9093350889", "rbxassetid://6784635852",
    "rbxassetid://12557398956", "rbxassetid://11830087451", "rbxassetid://10305162859", "rbxassetid://13706350387",
    "rbxassetid://14436945404", "rbxassetid://11830083821", "rbxassetid://14436758178", "rbxassetid://13135537390",
    "rbxassetid://14428713593", "rbxassetid://14436954850", "rbxassetid://13135491186", "rbxassetid://14428738204",
    "rbxassetid://14428743609", "rbxassetid://14436960020", "rbxassetid://14758917533", "rbxassetid://14484307859",
    "rbxassetid://14437087525", "rbxassetid://14436744290", "rbxassetid://13835626125", "rbxassetid://15317009082",
    "rbxassetid://136596648757339", "rbxassetid://81108881402205", "rbxassetid://76266870536490", "rbxassetid://16348401915",
    "rbxassetid://117499002290555", "rbxassetid://123333305454544", "rbxassetid://114201242358456", "rbxassetid://14847097309",
    "rbxassetid://14688664923", "rbxassetid://16348395223", "rbxassetid://16348391354", "rbxassetid://16348399148",
    "rbxassetid://13843648183", "rbxassetid://8705803091", "rbxassetid://14549632840", "rbxassetid://14111174579",
    "rbxassetid://9052821925", "rbxassetid://18516850087", "rbxassetid://1756451716", "rbxassetid://4958082006",
    "rbxassetid://10395117329", "rbxassetid://15023167771", "rbxassetid://115457404558211", "rbxassetid://14677866904",
    "rbxassetid://106604782438383", "rbxassetid://101003324274756", "rbxassetid://99824761297039", "rbxassetid://79899054463161",
    "rbxassetid://132498447517240", "rbxassetid://14365830804", "rbxassetid://14133573570", "rbxassetid://84575585234733",
    "rbxassetid://14740456559"
}

-- Helper function to truncate DisplayName to 20 chars + "..." if over 20 chars
local function GetFormattedDisplayName(displayName, isClient)
    if isClient then
        displayName = SpoofedDisplayName or displayName or ""
    else
        displayName = displayName or ""
    end
   
    if string.len(displayName) > 20 then
        return string.sub(displayName, 1, 20) .. "..."
    end
    return displayName
end

-- Truncates string to a max character count for notification banners
local function TruncateText(text, maxChars)
    text = text or ""
    if string.len(text) > maxChars then
        return string.sub(text, 1, maxChars) .. "..."
    end
    return text
end

-- ========================================================================
-- [0] INTRO LOADING GUI (KRONOS CHAT)
-- ========================================================================
local SOUNDS = {
    "rbxassetid://8503531171",
    "rbxassetid://88058206720285",
}

local IntroScreenGui = Instance.new("ScreenGui")
IntroScreenGui.Name = "KronosIntroGui"
IntroScreenGui.ResetOnSpawn = false
IntroScreenGui.IgnoreGuiInset = true
IntroScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local IntroBackground = Instance.new("Frame")
IntroBackground.Name = "Background"
IntroBackground.Size = UDim2.new(1, 0, 1, 0)
IntroBackground.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
IntroBackground.BackgroundTransparency = 0.4
IntroBackground.BorderSizePixel = 0
IntroBackground.Parent = IntroScreenGui

local IntroMainCard = Instance.new("Frame")
IntroMainCard.Name = "MainCard"
IntroMainCard.Size = UDim2.new(0, 480, 0, 180)
IntroMainCard.Position = UDim2.new(0.5, -240, 0.5, -90)
IntroMainCard.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
IntroMainCard.BorderSizePixel = 0
IntroMainCard.Parent = IntroBackground

local CardCorner = Instance.new("UICorner")
CardCorner.CornerRadius = UDim.new(0, 12)
CardCorner.Parent = IntroMainCard

local CardStroke = Instance.new("UIStroke")
CardStroke.Thickness = 3
CardStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
CardStroke.Color = Color3.fromRGB(255, 255, 255)
CardStroke.Parent = IntroMainCard

local BorderGradientIntro = Instance.new("UIGradient")
BorderGradientIntro.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(15, 0, 0)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
})
BorderGradientIntro.Parent = CardStroke

local rotationSpeed = 120
local borderConnection
borderConnection = RunService.RenderStepped:Connect(function(deltaTime)
    if not CardStroke or not CardStroke.Parent then
        if borderConnection then borderConnection:Disconnect() end
        return
    end
    BorderGradientIntro.Rotation = (BorderGradientIntro.Rotation + (rotationSpeed * deltaTime)) % 360
end)

local IntroTitle = Instance.new("TextLabel")
IntroTitle.Name = "Title"
IntroTitle.Size = UDim2.new(1, 0, 0, 35)
IntroTitle.Position = UDim2.new(0, 0, 0, 15)
IntroTitle.BackgroundTransparency = 1
IntroTitle.Text = "  KRONOS CHAT  "
IntroTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
IntroTitle.Font = Enum.Font.GothamBold
IntroTitle.TextSize = 22
IntroTitle.Parent = IntroMainCard

local WelcomeLabel = Instance.new("TextLabel")
WelcomeLabel.Name = "WelcomeLabel"
WelcomeLabel.Size = UDim2.new(1, 0, 0, 20)
WelcomeLabel.Position = UDim2.new(0, 0, 0, 48)
WelcomeLabel.BackgroundTransparency = 1
WelcomeLabel.Text = "Welcome, " .. GetFormattedDisplayName(LocalPlayer.DisplayName, true)
WelcomeLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
WelcomeLabel.Font = Enum.Font.Gotham
WelcomeLabel.TextSize = 12
WelcomeLabel.Parent = IntroMainCard

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "StatusLabel"
StatusLabel.Size = UDim2.new(0, 320, 0, 20)
StatusLabel.Position = UDim2.new(0, 30, 0, 88)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "> Initializing core systems..."
StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Font = Enum.Font.Code
StatusLabel.TextSize = 11
StatusLabel.Parent = IntroMainCard

local SubStatusLabel = Instance.new("TextLabel")
SubStatusLabel.Name = "SubStatusLabel"
SubStatusLabel.Size = UDim2.new(0, 320, 0, 20)
SubStatusLabel.Position = UDim2.new(0, 30, 0, 106)
SubStatusLabel.BackgroundTransparency = 1
SubStatusLabel.Text = "Preparing interface..."
SubStatusLabel.TextColor3 = Color3.fromRGB(130, 130, 140)
SubStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
SubStatusLabel.Font = Enum.Font.Gotham
SubStatusLabel.TextSize = 10
SubStatusLabel.Parent = IntroMainCard

local BarBackground = Instance.new("Frame")
BarBackground.Name = "BarBackground"
BarBackground.Size = UDim2.new(0, 320, 0, 5)
BarBackground.Position = UDim2.new(0, 30, 0, 140)
BarBackground.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
BarBackground.BorderSizePixel = 0
BarBackground.Parent = IntroMainCard

local BarCorner = Instance.new("UICorner")
BarCorner.CornerRadius = UDim.new(1, 0)
BarCorner.Parent = BarBackground

local BarFill = Instance.new("Frame")
BarFill.Name = "BarFill"
BarFill.Size = UDim2.new(0, 0, 1, 0)
BarFill.BorderSizePixel = 0
BarFill.Parent = BarBackground

local FillCorner = Instance.new("UICorner")
FillCorner.CornerRadius = UDim.new(1, 0)
FillCorner.Parent = BarFill

local loadColorSequence = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 230, 0)),
    ColorSequenceKeypoint.new(0.9, Color3.fromRGB(0, 255, 0)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 0)),
})

local function getColorFromProgress(progress, sequence)
    if progress <= 0 then return sequence.Keypoints[1].Color end
    if progress >= 1 then return sequence.Keypoints[#sequence.Keypoints].Color end

    local lowerIndex = 1
    for i = 1, #sequence.Keypoints - 1 do
        if progress >= sequence.Keypoints[i].Time then
            lowerIndex = i
        end
    end

    local upperIndex = lowerIndex + 1
    local lower = sequence.Keypoints[lowerIndex]
    local upper = sequence.Keypoints[upperIndex]

    local ratio = (progress - lower.Time) / (upper.Time - lower.Time)
    return lower.Color:Lerp(upper.Color, ratio)
end

local PercentCircle = Instance.new("Frame")
PercentCircle.Name = "PercentCircle"
PercentCircle.Size = UDim2.new(0, 56, 0, 56)
PercentCircle.Position = UDim2.new(0, 385, 0, 89)
PercentCircle.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
PercentCircle.BorderSizePixel = 0
PercentCircle.Parent = IntroMainCard

local CircleCorner = Instance.new("UICorner")
CircleCorner.CornerRadius = UDim.new(1, 0)
CircleCorner.Parent = PercentCircle

local CircleStroke = Instance.new("UIStroke")
CircleStroke.Thickness = 2
CircleStroke.Color = Color3.fromRGB(40, 40, 50)
CircleStroke.Parent = PercentCircle

local PercentText = Instance.new("TextLabel")
PercentText.Name = "PercentText"
PercentText.Size = UDim2.new(1, 0, 1, 0)
PercentText.BackgroundTransparency = 1
PercentText.Text = "0%"
PercentText.TextColor3 = Color3.fromRGB(255, 255, 255)
PercentText.Font = Enum.Font.GothamBold
PercentText.TextSize = 14
PercentText.Parent = PercentCircle

local IntroSound = Instance.new("Sound")
IntroSound.Volume = 0.5
IntroSound.PlayOnRemove = false
IntroSound.Parent = IntroScreenGui
IntroSound.SoundId = SOUNDS[math.random(1, #SOUNDS)]

local loadingStages = {
    { progress = 0.15, status = "> Over 110+ Custom Stickers", sub = "Express yourself with a massive collection..." },
    { progress = 0.35, status = "> High-Priority User Privacy", sub = "Chat logs are securely cleared every 20 minutes..." },
    { progress = 0.55, status = "> Cross-Server Messaging", sub = "Connect and chat with friends across different servers..." },
    { progress = 0.75, status = "> Reliable & Secure Sharing", sub = "Seamless script and link sharing & copying..." },
    { progress = 0.85, status = "> Built-in Feedback System", sub = "Check out the About tab to share your thoughts..." },
    { progress = 0.92, status = "> Anti Spamming & Anti-Handspam", sub = "Features to prevent Trollers from ruining your experience" },
    { progress = 0.97, status = "> Exclusive Tags & Roles", sub = "Certain Tags / Roles grant Exclusive Privileges. Collect them all!" },
    { progress = 1.00, status = "> All Systems Ready!", sub = "Launching interface..." }
}

local ScreenGui = nil

local function runIntro()
    task.spawn(function()
        pcall(function()
            ContentProvider:PreloadAsync({ IntroSound })
        end)
    end)

    IntroSound:Play()

    local duration = 5.0
    local elapsed = 0
    local currentStageIndex = 1

    while elapsed < duration do
        task.wait(0.03)
        elapsed = elapsed + 0.03
        local rawPercent = math.min(elapsed / duration, 1)

        local t = rawPercent
        local progress = t * t * (3 - 2 * t)

        PercentText.Text = math.floor(progress * 100) .. "%"
        BarFill.Size = UDim2.new(progress, 0, 1, 0)

        local success, computedColor = pcall(function()
            return getColorFromProgress(progress, loadColorSequence)
        end)
        if success then
            BarFill.BackgroundColor3 = computedColor
        end

        if currentStageIndex <= #loadingStages and progress >= loadingStages[currentStageIndex].progress then
            local stage = loadingStages[currentStageIndex]
            StatusLabel.Text = stage.status
            SubStatusLabel.Text = stage.sub

            local pulseTween = TweenService:Create(
                CardStroke,
                TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true),
                { Thickness = 5 }
            )
            pulseTween:Play()

            currentStageIndex = currentStageIndex + 1
        end
    end

    task.wait(0.3)

    local fadeInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    local fadeBg = TweenService:Create(IntroBackground, fadeInfo, { BackgroundTransparency = 1 })
    local fadeCard = TweenService:Create(IntroMainCard, fadeInfo, { BackgroundTransparency = 1 })
    local fadeStroke = TweenService:Create(CardStroke, fadeInfo, { Transparency = 1 })
    local fadeTitle = TweenService:Create(IntroTitle, fadeInfo, { TextTransparency = 1 })
    local fadeWelcome = TweenService:Create(WelcomeLabel, fadeInfo, { TextTransparency = 1 })
    local fadeStatus = TweenService:Create(StatusLabel, fadeInfo, { TextTransparency = 1 })
    local fadeSubStatus = TweenService:Create(SubStatusLabel, fadeInfo, { TextTransparency = 1 })
    local fadeBarBg = TweenService:Create(BarBackground, fadeInfo, { BackgroundTransparency = 1 })
    local fadeBarFill = TweenService:Create(BarFill, fadeInfo, { BackgroundTransparency = 1 })
    local fadeCircle = TweenService:Create(PercentCircle, fadeInfo, { BackgroundTransparency = 1 })
    local fadeCircleStroke = TweenService:Create(CircleStroke, fadeInfo, { Transparency = 1 })
    local fadePercentText = TweenService:Create(PercentText, fadeInfo, { TextTransparency = 1 })

    fadeBg:Play()
    fadeCard:Play()
    fadeStroke:Play()
    fadeTitle:Play()
    fadeWelcome:Play()
    fadeStatus:Play()
    fadeSubStatus:Play()
    fadeBarBg:Play()
    fadeBarFill:Play()
    fadeCircle:Play()
    fadeCircleStroke:Play()
    fadePercentText:Play()

    fadeBg.Completed:Wait()
    IntroScreenGui:Destroy()

    if ScreenGui then
        ScreenGui.Enabled = true
    end
end

task.spawn(runIntro)

-- ========================================================================
-- [2] ROLEPLAY PROFILES LOAD MATRIX (KRONOS CHAT EDITION)
-- ========================================================================
local customRPName = " ᴋʀᴏɴᴏs ᴄʜᴀᴛ "
local customRPBio  = " ωєℓ¢σмє вα¢к, " .. GetFormattedDisplayName(lplr.DisplayName, true) .. " "

local function applyRPProfile()
    local reFolder = ReplicatedStorage:WaitForChild("RE", 10)
    if not reFolder then return end

    local rpRemote = reFolder:WaitForChild("1RPNam1eTex1t", 5)
                  or reFolder:FindFirstChild("RPNameText")
                  or reFolder:FindFirstChild("RPName")

    if rpRemote then
        if not lplr.Character or not lplr.Character:FindFirstChild("HumanoidRootPart") then
            lplr.CharacterAdded:Wait()
            task.wait(1)
        end

        task.spawn(function()
            for i = 1, 5 do
                pcall(function()
                    rpRemote:FireServer("RolePlayName", customRPName)
                    rpRemote:FireServer("RolePlayBio", customRPBio)
                end)
                task.wait(0.5)
            end
        end)
    end
end

task.spawn(applyRPProfile)
lplr.CharacterAdded:Connect(function()
    task.wait(1.5)
    applyRPProfile()
end)

-- Custom Color Loop
task.spawn(function()
    local reFolder = ReplicatedStorage:WaitForChild("RE", 10)
    if reFolder then
        local colorRemote = reFolder:WaitForChild("1RPNam1eColo1r", 5) or reFolder:FindFirstChild("RPNameColor")
        if colorRemote then
            local frequency = 0.8
            local brightRed = Color3.fromRGB(255, 0, 0)
            local pureWhite = Color3.fromRGB(255, 255, 255)
            local startTime = tick()

            while true do
                local elapsed = tick() - startTime
                local factor = (math.sin(elapsed * frequency) + 1) / 2
                local lerpedNameColor = brightRed:Lerp(pureWhite, factor)

                pcall(function()
                    colorRemote:FireServer("PickingRPNameColor", lerpedNameColor)
                    colorRemote:FireServer("PickingRPBioColor", pureWhite)
                end)
                task.wait(0.1)
            end
        end
    end
end)

-- ============================================================================
-- ENDPOINTS & AUDIO
-- ============================================================================
local GLOBAL_FIREBASE_URL = "https://grimcouncilcommunicator-default-rtdb.asia-southeast1.firebasedatabase.app/"
local GLOBAL_MESSAGES_ENDPOINT = GLOBAL_FIREBASE_URL .. "global_chat/messages.json"

local SERVER_FIREBASE_URL = "https://gcserverchat-default-rtdb.asia-southeast1.firebasedatabase.app/"
local SERVER_MESSAGES_ENDPOINT = SERVER_FIREBASE_URL .. "server_chat/" .. SERVER_JOB_ID .. ".json"

local REQUEST_FIREBASE_URL = "https://gctagreq-default-rtdb.asia-southeast1.firebasedatabase.app/"
local REQUEST_ENDPOINT = REQUEST_FIREBASE_URL .. "requests.json"

local GITHUB_ROLE_LIST_URL = "https://github.com/thedevilondiscord/GC/raw/refs/heads/main/GC_RoleList.json"
local GITHUB_RANK_STYLES_URL = "https://raw.githubusercontent.com/thedevilondiscord/GC/refs/heads/main/GC_Roles.json"

local JOIN_SOUND_ID = "rbxassetid://7460825623"

local ActiveTab = "GLOBAL"

-- ============================================================================
-- STICKER REGISTRY
-- ============================================================================
local baseStickers = {
    "rbxthumb://type=Asset&id=126155452969559&w=420&h=420",
    "rbxthumb://type=Asset&id=76528918733148&w=420&h=420",
    "rbxthumb://type=Asset&id=139746534721570&w=420&h=420",
    "rbxthumb://type=Asset&id=107882158860216&w=420&h=420",
    "rbxthumb://type=Asset&id=99467189295335&w=420&h=420",
    "rbxthumb://type=Asset&id=114738142020573&w=420&h=420",
    "rbxthumb://type=Asset&id=100644268219896&w=420&h=420",
    "rbxthumb://type=Asset&id=82732486060449&w=420&h=420",
    "rbxthumb://type=Asset&id=84345768144066&w=420&h=420",
    "rbxthumb://type=Asset&id=85611228914039&w=420&h=420",
    "rbxthumb://type=Asset&id=126857592936719&w=420&h=420",
    "rbxthumb://type=Asset&id=106945724992072&w=420&h=420",
    "rbxthumb://type=Asset&id=102454731178873&w=420&h=420",
    "rbxthumb://type=Asset&id=33230128&w=420&h=420",
    "rbxthumb://type=Asset&id=33199969&w=420&h=420",
    "rbxthumb://type=Asset&id=33200194&w=420&h=420",
    "rbxthumb://type=Asset&id=33200310&w=420&h=420",
    "rbxthumb://type=Asset&id=33200394&w=420&h=420",
    "rbxthumb://type=Asset&id=250852269&w=420&h=420",
    "rbxthumb://type=Asset&id=146447101&w=420&h=420",
    "rbxthumb://type=Asset&id=36061967&w=420&h=420",
    "rbxthumb://type=Asset&id=31325913&w=420&h=420",
    "rbxthumb://type=Asset&id=15805629980&w=420&h=420",
    "rbxthumb://type=Asset&id=16022747924&w=420&h=420",
    "rbxthumb://type=Asset&id=87693756574279&w=420&h=420",
    "rbxthumb://type=Asset&id=72793460663497&w=420&h=420",
    "rbxthumb://type=Asset&id=72687512455219&w=420&h=420",
    "rbxthumb://type=Asset&id=95112780943766&w=420&h=420",
    "rbxthumb://type=Asset&id=130819442854007&w=420&h=420",
    "rbxthumb://type=Asset&id=15995320422&w=420&h=420",
    "rbxthumb://type=Asset&id=81506012118866&w=420&h=420",
    "rbxthumb://type=Asset&id=97857646756275&w=420&h=420",
    "rbxthumb://type=Asset&id=77414899898218&w=420&h=420",
    "rbxthumb://type=Asset&id=2606484655&w=420&h=420",
    "rbxthumb://type=Asset&id=947554872&w=420&h=420",
    "rbxthumb://type=Asset&id=7077501904&w=420&h=420",
    "rbxthumb://type=Asset&id=22743612&w=420&h=420",
    "rbxthumb://type=Asset&id=90357041968118&w=420&h=420",
    "rbxthumb://type=Asset&id=97531898393056&w=420&h=420",
    "rbxthumb://type=Asset&id=125942884957668&w=420&h=420",
    "rbxthumb://type=Asset&id=131728403495824&w=420&h=420",
    "rbxthumb://type=Asset&id=213127981&w=420&h=420",
    "rbxthumb://type=Asset&id=74300261807862&w=420&h=420",
    "rbxthumb://type=Asset&id=15908931002&w=420&h=420",
    "rbxthumb://type=Asset&id=99802803824359&w=420&h=420",
    "rbxthumb://type=Asset&id=75506307767417&w=420&h=420",
    "rbxthumb://type=Asset&id=18932008974&w=420&h=420",
    "rbxthumb://type=Asset&id=126392350195389&w=420&h=420",
    "rbxthumb://type=Asset&id=1301532317&w=420&h=420",
    "rbxthumb://type=Asset&id=11773019072&w=420&h=420",
    "rbxthumb://type=Asset&id=11660423573&w=420&h=420",
    "rbxthumb://type=Asset&id=109412457381204&w=420&h=420",
    "rbxthumb://type=Asset&id=32951426&w=420&h=420",
    "rbxthumb://type=Asset&id=10285293170&w=420&h=420",
    "rbxthumb://type=Asset&id=11254436924&w=420&h=420",
    "rbxthumb://type=Asset&id=113682666817136&w=420&h=420",
    "rbxthumb://type=Asset&id=18306429198&w=420&h=420",
    "rbxthumb://type=Asset&id=83677040163363&w=420&h=420",
    "rbxthumb://type=Asset&id=92982112921274&w=420&h=420",
    "rbxthumb://type=Asset&id=75985897964190&w=420&h=420",
    "rbxthumb://type=Asset&id=100722574482118&w=420&h=420",
    "rbxthumb://type=Asset&id=77449075537615&w=420&h=420",
    "rbxthumb://type=Asset&id=91965007204396&w=420&h=420",
    "rbxthumb://type=Asset&id=87239554144904&w=420&h=420",
    "rbxthumb://type=Asset&id=108550928457595&w=420&h=420",
    "rbxthumb://type=Asset&id=112758420253845&w=420&h=420",
    "rbxthumb://type=Asset&id=135700976643537&w=420&h=420",
    "rbxthumb://type=Asset&id=124145396344946&w=420&h=420",
    "rbxthumb://type=Asset&id=105612301516352&w=420&h=420",
    "rbxthumb://type=Asset&id=71442089462191&w=420&h=420",
    "rbxthumb://type=Asset&id=116671713835756&w=420&h=420",
    "rbxthumb://type=Asset&id=86278563388796&w=420&h=420",
    "rbxthumb://type=Asset&id=134676873059671&w=420&h=420",
    "rbxthumb://type=Asset&id=107991336904158&w=420&h=420",
    "rbxthumb://type=Asset&id=90286953844894&w=420&h=420",
    "rbxthumb://type=Asset&id=124047412639555&w=420&h=420",
    "rbxthumb://type=Asset&id=95770046851932&w=420&h=420",
    "rbxthumb://type=Asset&id=85407192167743&w=420&h=420",
    "rbxthumb://type=Asset&id=108796531608917&w=420&h=420",
    "rbxthumb://type=Asset&id=129040222524985&w=420&h=420",
    "rbxthumb://type=Asset&id=107679067587993&w=420&h=420",
    "rbxthumb://type=Asset&id=75030286063678&w=420&h=420",
    "rbxthumb://type=Asset&id=106503865025496&w=420&h=420",
    "rbxthumb://type=Asset&id=107949395268622&w=420&h=420",
    "rbxthumb://type=Asset&id=127600871692693&w=420&h=420",
    "rbxthumb://type=Asset&id=102923210652647&w=420&h=420",
    "rbxthumb://type=Asset&id=76757365751988&w=420&h=420",
    "rbxthumb://type=Asset&id=81437059666138&w=420&h=420",
    "rbxthumb://type=Asset&id=83671542566237&w=420&h=420",
    "rbxthumb://type=Asset&id=74143981281416&w=420&h=420",
    "rbxthumb://type=Asset&id=136413255954959&w=420&h=420",
    "rbxthumb://type=Asset&id=115062400395026&w=420&h=420",
    "rbxthumb://type=Asset&id=96930545429149&w=420&h=420",
    "rbxthumb://type=Asset&id=128965568153551&w=420&h=420",
    "rbxthumb://type=Asset&id=86402817297314&w=420&h=420",
    "rbxthumb://type=Asset&id=113540856419753&w=420&h=420",
    "rbxthumb://type=Asset&id=111616336841381&w=420&h=420",
    "rbxthumb://type=Asset&id=98946997706325&w=420&h=420",
    "rbxthumb://type=Asset&id=108283809544243&w=420&h=420",
    "rbxthumb://type=Asset&id=6569741166&w=420&h=420",
    "rbxthumb://type=Asset&id=11607296674&w=420&h=420",
    "rbxthumb://type=Asset&id=5726383129&w=420&h=420",
    "rbxthumb://type=Asset&id=5422504072&w=420&h=420",
    "rbxthumb://type=Asset&id=1312653856&w=420&h=420",
    "rbxthumb://type=Asset&id=9181273959&w=420&h=420",
    "rbxthumb://type=Asset&id=3512459976&w=420&h=420",
    "rbxthumb://type=Asset&id=9897870796&w=420&h=420",
    "rbxthumb://type=Asset&id=19478788&w=420&h=420",
    "rbxthumb://type=Asset&id=17285946660&w=420&h=420",
    "rbxthumb://type=Asset&id=11345695781&w=420&h=420",
    "rbxthumb://type=Asset&id=6991349714&w=420&h=420",
    "rbxthumb://type=Asset&id=6615496255&w=420&h=420",
    "rbxthumb://type=Asset&id=6569739866&w=420&h=420",
    "rbxthumb://type=Asset&id=7025317915&w=420&h=420",
    "rbxthumb://type=Asset&id=8377385874&w=420&h=420",
    "rbxthumb://type=Asset&id=9075557667&w=420&h=420",
    "rbxthumb://type=Asset&id=10777735185&w=420&h=420",
    "rbxthumb://type=Asset&id=12521295024&w=420&h=420",
    "rbxthumb://type=Asset&id=9075556842&w=420&h=420",
    "rbxthumb://type=Asset&id=11236157528&w=420&h=420",
    "rbxthumb://type=Asset&id=72455921520132&w=420&h=420",
    "rbxthumb://type=Asset&id=2311956970&w=420&h=420",
    "rbxthumb://type=Asset&id=10367063084&w=420&h=420",
    "rbxthumb://type=Asset&id=75074160606432&w=420&h=420",
    "rbxthumb://type=Asset&id=132266996382315&w=420&h=420",
    "rbxthumb://type=Asset&id=11123209169&w=420&h=420",
    -- Added Stickers
    "rbxthumb://type=Asset&id=130605412870116&w=420&h=420",
    "rbxthumb://type=Asset&id=123881607288205&w=420&h=420",
    "rbxthumb://type=Asset&id=77982313163011&w=420&h=420",
    "rbxthumb://type=Asset&id=71112430314329&w=420&h=420",
    "rbxthumb://type=Asset&id=92850410471479&w=420&h=420",
    "rbxthumb://type=Asset&id=133801475498371&w=420&h=420",
    "rbxthumb://type=Asset&id=99340040246135&w=420&h=420",
    "rbxthumb://type=Asset&id=128748009633926&w=420&h=420",
    "rbxthumb://type=Asset&id=115496076924304&w=420&h=420",
    "rbxthumb://type=Asset&id=113969372822195&w=420&h=420",
    "rbxthumb://type=Asset&id=81071566386630&w=420&h=420",
    "rbxthumb://type=Asset&id=136887113512942&w=420&h=420",
    "rbxthumb://type=Asset&id=83606808239727&w=420&h=420",
    "rbxthumb://type=Asset&id=137895709516187&w=420&h=420",
    "rbxthumb://type=Asset&id=95097775871116&w=420&h=420",
    "rbxthumb://type=Asset&id=112896137773535&w=420&h=420",
    "rbxthumb://type=Asset&id=76312255766028&w=420&h=420",
    "rbxthumb://type=Asset&id=128534124653098&w=420&h=420",
    "rbxthumb://type=Asset&id=106808393141208&w=420&h=420",
    "rbxthumb://type=Asset&id=87553190789546&w=420&h=420",
    "rbxthumb://type=Asset&id=122820594186443&w=420&h=420",
    "rbxthumb://type=Asset&id=98756307893472&w=420&h=420",
    "rbxthumb://type=Asset&id=134238049027906&w=420&h=420",
    "rbxthumb://type=Asset&id=126835535148309&w=420&h=420",
    "rbxthumb://type=Asset&id=107542712869273&w=420&h=420",
    "rbxthumb://type=Asset&id=137157157388660&w=420&h=420",
    "rbxthumb://type=Asset&id=140484578433196&w=420&h=420",
    "rbxthumb://type=Asset&id=124962139890506&w=420&h=420",
    "rbxthumb://type=Asset&id=100982607210447&w=420&h=420"
}

local uniqueStickers = {}
local hash = {}
for _, v in ipairs(baseStickers) do
    if not hash[v] then
        table.insert(uniqueStickers, v)
        hash[v] = true
    end
end
baseStickers = uniqueStickers

-- ============================================================================
-- HARDCODED RANKS & DEFAULT STYLES
-- ============================================================================
local RANK_STYLES = {
["Architect"]          = { Start = Color3.fromRGB(255, 30, 30),   End = Color3.fromRGB(0, 0, 0),       Name = Color3.fromRGB(255, 30, 30),   Speed = 1.5, IsAdmin = true },
["Overseer"]           = { Start = Color3.fromRGB(255, 30, 30),   End = Color3.fromRGB(0, 0, 0),       Name = Color3.fromRGB(255, 30, 30),   Speed = 1.5, IsAdmin = true },
["Critic"]             = { Start = Color3.fromRGB(30, 144, 255),  End = Color3.fromRGB(0, 0, 139),     Name = Color3.fromRGB(30, 144, 255),  Speed = 1.5, IsAdmin = true },
["Recruit"]            = { Start = Color3.fromRGB(255, 105, 180), End = Color3.fromRGB(255, 255, 255), Name = Color3.fromRGB(255, 105, 180), Speed = 1.2 },
["Agent"]              = { Start = Color3.fromRGB(0, 191, 255),   End = Color3.fromRGB(255, 255, 255), Name = Color3.fromRGB(0, 191, 255),   Speed = 1.2 },
["Regent of Codes"]    = { Start = Color3.fromRGB(30, 255, 30),   End = Color3.fromRGB(0, 0, 0),       Name = Color3.fromRGB(30, 255, 30),   Speed = 1.2 },
["Regent of Clans"]    = { Start = Color3.fromRGB(255, 215, 0),   End = Color3.fromRGB(0, 0, 0),       Name = Color3.fromRGB(255, 215, 0),   Speed = 1.2 },
["Regent of Havoc"]    = { Start = Color3.fromRGB(186, 85, 211),  End = Color3.fromRGB(0, 0, 0),       Name = Color3.fromRGB(186, 85, 211),  Speed = 1.2 },
["VIP"]                = { Start = Color3.fromRGB(255, 215, 0),   End = Color3.fromRGB(139, 69, 19),   Name = Color3.fromRGB(255, 215, 0),   Speed = 1.5 },
["ELITE"]              = { Start = Color3.fromRGB(186, 85, 211),  End = Color3.fromRGB(75, 0, 130),    Name = Color3.fromRGB(186, 85, 211),  Speed = 1.5 },
["OG"]                 = { Start = Color3.fromRGB(255, 69, 0),    End = Color3.fromRGB(128, 0, 0),     Name = Color3.fromRGB(255, 69, 0),    Speed = 1.0 },
["Dark Passenger"]     = { Start = Color3.fromRGB(128, 0, 32),   End = Color3.fromRGB(0, 0, 0),       Name = Color3.fromRGB(128, 0, 32),   Speed = 2.0 },
["Obsession"]          = { Start = Color3.fromRGB(112, 128, 144), End = Color3.fromRGB(0, 0, 0),       Name = Color3.fromRGB(255, 255, 255), Speed = 1.5 },
["Soul Reaper"]        = { Start = Color3.fromRGB(0, 255, 255),   End = Color3.fromRGB(0, 0, 0),       Name = Color3.fromRGB(0, 255, 255),   Speed = 1.5 },
["Infinite Void"]      = { Start = Color3.fromRGB(75, 0, 130),   End = Color3.fromRGB(0, 0, 0),       Name = Color3.fromRGB(75, 0, 130),   Speed = 1.0 },
["Hunter"]             = { Start = Color3.fromRGB(255, 69, 0),   End = Color3.fromRGB(255, 255, 255), Name = Color3.fromRGB(255, 255, 255), Speed = 1.5 },
["Hokage"]             = { Start = Color3.fromRGB(135, 206, 235), End = Color3.fromRGB(0, 0, 0),       Name = Color3.fromRGB(135, 206, 235), Speed = 1.5 },
["Pirate Emperor"]     = { Start = Color3.fromRGB(64, 224, 208),  End = Color3.fromRGB(0, 0, 0),       Name = Color3.fromRGB(64, 224, 208),  Speed = 1.5 },
["KIRA"]               = { Start = Color3.fromRGB(54, 69, 79),   End = Color3.fromRGB(255, 255, 255), Name = Color3.fromRGB(255, 255, 255), Speed = 1.0 },
["Overlord"]           = { Start = Color3.fromRGB(0, 255, 255),   End = Color3.fromRGB(0, 0, 0),       Name = Color3.fromRGB(0, 255, 255),   Speed = 1.5 },
["Jobless Sage"]       = { Start = Color3.fromRGB(138, 43, 226),  End = Color3.fromRGB(255, 255, 255), Name = Color3.fromRGB(255, 255, 255), Speed = 1.0 },
["Saiyan"]             = { Start = Color3.fromRGB(0, 191, 255),   End = Color3.fromRGB(255, 255, 255), Name = Color3.fromRGB(255, 255, 255), Speed = 1.5 },
["Monarch"]            = { Start = Color3.fromRGB(0, 0, 139),    End = Color3.fromRGB(0, 0, 0),       Name = Color3.fromRGB(0, 0, 139),     Speed = 1.0 },
["Devil"]              = { Start = Color3.fromRGB(183, 65, 14),   End = Color3.fromRGB(0, 0, 0),       Name = Color3.fromRGB(183, 65, 14),   Speed = 1.5 },
["Hashira"]            = { Start = Color3.fromRGB(0, 128, 128),   End = Color3.fromRGB(0, 0, 0),       Name = Color3.fromRGB(0, 128, 128),   Speed = 1.5 },
["Heroic"]             = { Start = Color3.fromRGB(255, 140, 0),   End = Color3.fromRGB(0, 0, 0),       Name = Color3.fromRGB(255, 140, 0),   Speed = 1.5 },
["Conqueror"]          = { Start = Color3.fromRGB(255, 191, 0),   End = Color3.fromRGB(255, 255, 255), Name = Color3.fromRGB(255, 255, 255), Speed = 1.5 },
["Warlord"]            = { Start = Color3.fromRGB(205, 127, 50),  End = Color3.fromRGB(0, 0, 0),       Name = Color3.fromRGB(205, 127, 50),  Speed = 1.5 },
["Psychopath"]         = { Start = Color3.fromRGB(114, 47, 55),   End = Color3.fromRGB(54, 69, 79),   Name = Color3.fromRGB(114, 47, 55),   Speed = 2.0 },
["Manipulator"]        = { Start = Color3.fromRGB(184, 115, 51),  End = Color3.fromRGB(0, 0, 0),       Name = Color3.fromRGB(184, 115, 51),  Speed = 2.0 },
["Narcissist"]         = { Start = Color3.fromRGB(224, 17, 95),   End = Color3.fromRGB(0, 0, 0),       Name = Color3.fromRGB(224, 17, 95),   Speed = 1.5 },
["Com-God"]            = { Start = Color3.fromRGB(229, 228, 226), End = Color3.fromRGB(0, 0, 0),       Name = Color3.fromRGB(229, 228, 226), Speed = 1.0 },
["Disbander"]          = { Start = Color3.fromRGB(178, 190, 181), End = Color3.fromRGB(0, 0, 0),       Name = Color3.fromRGB(178, 190, 181), Speed = 1.5 },
["Lover"]              = { Start = Color3.fromRGB(128, 0, 32),   End = Color3.fromRGB(255, 255, 255), Name = Color3.fromRGB(255, 255, 255), Speed = 1.0 },
["Malkin"]             = { Start = Color3.fromRGB(255, 0, 255),   End = Color3.fromRGB(255, 255, 255), Name = Color3.fromRGB(255, 182, 193), Speed = 1.0 },
["Badmosh"]            = { Start = Color3.fromRGB(255, 255, 0),   End = Color3.fromRGB(0, 0, 0),       Name = Color3.fromRGB(255, 255, 0),   Speed = 1.5 },
["Badnam"]             = { Start = Color3.fromRGB(255, 219, 88),  End = Color3.fromRGB(0, 0, 0),       Name = Color3.fromRGB(255, 219, 88),  Speed = 2.0 },
["Batman"]             = { Start = Color3.fromRGB(25, 25, 112),   End = Color3.fromRGB(0, 0, 0),       Name = Color3.fromRGB(25, 25, 112),   Speed = 1.5 },
["Homelander"]         = { Start = Color3.fromRGB(0, 33, 165),    End = Color3.fromRGB(255, 255, 255), Name = Color3.fromRGB(255, 255, 255), Speed = 1.0 },
["Viltramite"]         = { Start = Color3.fromRGB(0, 71, 171),    End = Color3.fromRGB(0, 0, 0),       Name = Color3.fromRGB(0, 71, 171),    Speed = 1.5 },

-- NEWLY ADDED ROLES
["HACKER"]             = { Start = Color3.fromRGB(0, 255, 0),     End = Color3.fromRGB(0, 0, 0),       Name = Color3.fromRGB(0, 255, 0),     Speed = 2.0 },
["POOKIE🎀"]           = { Start = Color3.fromRGB(128, 0, 0),     End = Color3.fromRGB(255, 255, 255), Name = Color3.fromRGB(255, 192, 203), Speed = 1.5 },
["EMPRESS👑"]          = { Start = Color3.fromRGB(218, 165, 32),  End = Color3.fromRGB(128, 0, 128),   Name = Color3.fromRGB(255, 215, 0),   Speed = 1.5 },
["EMPERROR👑"]         = { Start = Color3.fromRGB(255, 215, 0),   End = Color3.fromRGB(75, 0, 130),    Name = Color3.fromRGB(255, 215, 0),   Speed = 1.5 },
["Boni🤏"]             = { Start = Color3.fromRGB(255, 182, 193), End = Color3.fromRGB(255, 105, 180), Name = Color3.fromRGB(255, 192, 203), Speed = 1.2 },
["FLYING DUTCHMAN🐐"]  = { Start = Color3.fromRGB(0, 255, 127),   End = Color3.fromRGB(15, 30, 15),    Name = Color3.fromRGB(0, 255, 127),   Speed = 1.8 },
["CR7🐐"]              = { Start = Color3.fromRGB(255, 215, 0),   End = Color3.fromRGB(220, 20, 60),   Name = Color3.fromRGB(255, 215, 0),   Speed = 1.8 },
["Serial Killer🔪"]     = { Start = Color3.fromRGB(255, 0, 0),     End = Color3.fromRGB(255, 255, 255), Name = Color3.fromRGB(200, 0, 0),     Speed = 4.0 },
["GOD"]                = { Start = Color3.fromRGB(255, 255, 220), End = Color3.fromRGB(255, 215, 0),   Name = Color3.fromRGB(255, 255, 255), Speed = 1.2 },
["GOAT"]               = { Start = Color3.fromRGB(255, 215, 0),   End = Color3.fromRGB(192, 192, 192), Name = Color3.fromRGB(255, 215, 0),   Speed = 1.5 },
["MUTHAL"]             = { Start = Color3.fromRGB(169, 169, 169), End = Color3.fromRGB(105, 105, 105), Name = Color3.fromRGB(211, 211, 211), Speed = 1.2 },
["DADDY"]              = { Start = Color3.fromRGB(255, 140, 0),   End = Color3.fromRGB(0, 0, 0),       Name = Color3.fromRGB(255, 140, 0),   Speed = 1.5 },
["STEPDADDY"]          = { Start = Color3.fromRGB(255, 69, 0),    End = Color3.fromRGB(47, 79, 79),    Name = Color3.fromRGB(255, 99, 71),   Speed = 1.5 },
}

local ALL_AUTOCOMPLETE_OPTIONS = { "!tag", "!role", "!spoof", "/w " }

local AssignedPlayerRoles = {}
local AvailableUserRoles = {}
local DisabledTags = {}        
local PersistentPvtPrefix = ""

local GlobalCachedMessages, GlobalUIElements = {}, {}
local ServerCachedMessages, ServerUIElements = {}, {}

local function RefreshAllRoleAutocomplete()
    local optionsMap = { ["!tag"] = true, ["!role"] = true, ["!spoof"] = true, ["/w "] = true }
   
    for rankName, _ in pairs(RANK_STYLES) do
        optionsMap[rankName] = true
    end
   
    for playerName, roles in pairs(AvailableUserRoles) do
        for _, roleName in ipairs(roles) do
            optionsMap[roleName] = true
        end
    end

    ALL_AUTOCOMPLETE_OPTIONS = {}
    for opt, _ in pairs(optionsMap) do
        table.insert(ALL_AUTOCOMPLETE_OPTIONS, opt)
    end
end
RefreshAllRoleAutocomplete()

-- ============================================================================
-- ENCODING UTILITY
-- ============================================================================
local function EncodePlayerId(userId)
    local idStr = tostring(userId)
    if string.len(idStr) >= 5 then
        local first5 = string.sub(idStr, 1, 5)
        local rest = string.sub(idStr, 6)
        return rest .. first5 .. "0"
    end
    return idStr .. "0"
end

-- ============================================================================
-- HTTP HANDLER (MULTI-EXECUTOR COMPATIBLE)
-- ============================================================================
local http_req = (syn and syn.request) or (http and http.request) or http_request or request or (Fluxus and fluxus.request)

local function HttpRequest(url, method, data)
    if not http_req then return nil end
    local success, response = pcall(function()
        return http_req({
            Url = url,
            Method = method or "GET",
            Headers = { ["Content-Type"] = "application/json" },
            Body = data and HttpService:JSONEncode(data) or nil
        })
    end)

    if success and response and response.Body then
        local decodedSuccess, decodedData = pcall(function()
            return HttpService:JSONDecode(response.Body)
        end)
        return decodedSuccess and decodedData or nil
    end
    return nil
end

-- ============================================================================
-- HARDCODED AUTHORITY & ROLE CALCULATOR
-- ============================================================================
local function GetAssignedOrCalculatedRole(username)
    if AssignedPlayerRoles[username] then
        return AssignedPlayerRoles[username]
    end

    local playerObj = Players:FindFirstChild(username)

    if username == "Kabir_Priv" then
        return "Architect"
    end

    if username == "marco3009866" or (playerObj and playerObj.UserId == 8340207122) then
        return "Overseer"
    end

    if string.len(username) % 2 == 0 then
        return "ELITE"
    else
        return "VIP"
    end
end

local function HasAdminPermission(username)
    local role = GetAssignedOrCalculatedRole(username)
    return role == "Architect" or role == "Overseer" or role == "Critic"
end

local function CanUseSpoof(username)
    local role = GetAssignedOrCalculatedRole(username)
    local allowedRoles = {
        ["ARCHITECT"] = true,
        ["OVERSEER"] = true,
        ["HACKER"] = true,
        ["SERIAL KILLER🔪"] = true,
        ["SERIAL KILLER"] = true,
        ["EMPERROR👑"] = true,
        ["EMPERROR"] = true,
        ["GOD"] = true,
        ["COM-GOD"] = true,
        ["COM GOD"] = true
    }
    return allowedRoles[string.upper(role)] == true
end

local function FetchRemoteRankStyles()
    local jsonStyles = HttpRequest(GITHUB_RANK_STYLES_URL, "GET")
    if not jsonStyles or type(jsonStyles) ~= "table" then return end

    for rankName, data in pairs(jsonStyles) do
        if rankName ~= "Overseer" and rankName ~= "Architect" and rankName ~= "Critic" then
            if data.Start and data.End and data.Name then
                RANK_STYLES[rankName] = {
                    Start = Color3.fromRGB(data.Start[1], data.Start[2], data.Start[3]),
                    End = Color3.fromRGB(data.End[1], data.End[2], data.End[3]),
                    Name = Color3.fromRGB(data.Name[1], data.Name[2], data.Name[3]),
                    Speed = data.Speed or 1.2,
                    IsAdmin = data.IsAdmin or false
                }
            end
        end
    end

    RefreshAllRoleAutocomplete()
end

local function FetchRemoteRoles()
    local jsonRoster = HttpRequest(GITHUB_ROLE_LIST_URL, "GET")
    if not jsonRoster or type(jsonRoster) ~= "table" then return end

    AvailableUserRoles = {}

    for rankName, playerList in pairs(jsonRoster) do
        if type(playerList) == "table" then
            for _, entry in ipairs(playerList) do
                local targetUsername = nil
                local targetEncodedId = nil

                if type(entry) == "table" then
                    targetUsername = entry.Username
                    targetEncodedId = tostring(entry.EncodedId or "")
                elseif type(entry) == "string" then
                    targetUsername = entry
                end

                for _, player in ipairs(Players:GetPlayers()) do
                    local encodedId = EncodePlayerId(player.UserId)
                    if (targetUsername and player.Name == targetUsername) or (targetEncodedId and targetEncodedId == encodedId) then
                        AvailableUserRoles[player.Name] = AvailableUserRoles[player.Name] or {}
                        if not table.find(AvailableUserRoles[player.Name], rankName) then
                            table.insert(AvailableUserRoles[player.Name], rankName)
                        end

                        if player.Name ~= "Kabir_Priv" and player.Name ~= "marco3009866" and player.UserId ~= 8340207122 then
                            if not AssignedPlayerRoles[player.Name] then
                                AssignedPlayerRoles[player.Name] = rankName
                            end
                        end
                    end
                end
            end
        end
    end
    RefreshAllRoleAutocomplete()
end

-- ============================================================================
-- GLASSMORPHIC UI BUILDER
-- ============================================================================
local BlurEffect = Lighting:FindFirstChild("Kronos_GlassBlur") or Instance.new("DepthOfFieldEffect")
BlurEffect.Name = "Kronos_GlassBlur"
BlurEffect.FarIntensity = 0.1
BlurEffect.FocusDistance = 0
BlurEffect.InFocusRadius = 30
BlurEffect.NearIntensity = 0.75
BlurEffect.Parent = Lighting

ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Kronos_Chat_Gui"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Enabled = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Center GUI Frame Calculation
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 450, 0, 320)
MainFrame.Position = UDim2.new(0.5, -225, 0.5, -160)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
MainFrame.BackgroundTransparency = 0.35
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = false
MainFrame.Parent = ScreenGui

-- Draggable implementation
local dragging, dragInput, dragStart, startPos
local function updateDrag(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        updateDrag(input)
    end
end)

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 16)
MainCorner.Parent = MainFrame

local GlassGloss = Instance.new("Frame")
GlassGloss.Name = "GlassGloss"
GlassGloss.Size = UDim2.new(1, 0, 0.45, 0)
GlassGloss.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
GlassGloss.BackgroundTransparency = 0.95
GlassGloss.BorderSizePixel = 0
GlassGloss.Parent = MainFrame

local GlossCorner = Instance.new("UICorner")
GlossCorner.CornerRadius = UDim.new(0, 16)
GlossCorner.Parent = GlassGloss

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 2.5
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
MainStroke.Transparency = 0.2
MainStroke.Color = Color3.fromRGB(255, 0, 0)
MainStroke.Parent = MainFrame

local BorderGradient = Instance.new("UIGradient")
BorderGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 50, 50)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(40, 40, 60)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 50, 50)),
})
BorderGradient.Parent = MainStroke

RunService.RenderStepped:Connect(function(dt)
    BorderGradient.Rotation = (BorderGradient.Rotation + (40 * dt)) % 360
end)

local HeaderBar = Instance.new("Frame")
HeaderBar.Name = "HeaderBar"
HeaderBar.Size = UDim2.new(1, 0, 0, 36)
HeaderBar.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
HeaderBar.BackgroundTransparency = 0.3
HeaderBar.BorderSizePixel = 0
HeaderBar.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 16)
HeaderCorner.Parent = HeaderBar

local GlobalTabBtn = Instance.new("TextButton")
GlobalTabBtn.Name = "GlobalTabBtn"
GlobalTabBtn.Size = UDim2.new(0, 65, 0, 26)
GlobalTabBtn.Position = UDim2.new(0, 8, 0, 5)
GlobalTabBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
GlobalTabBtn.BackgroundTransparency = 0.2
GlobalTabBtn.Font = Enum.Font.GothamBold
GlobalTabBtn.Text = "GLOBAL"
GlobalTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
GlobalTabBtn.TextSize = 9
GlobalTabBtn.Parent = HeaderBar

local GlobalTabCorner = Instance.new("UICorner")
GlobalTabCorner.CornerRadius = UDim.new(0, 8)
GlobalTabCorner.Parent = GlobalTabBtn

local ServerTabBtn = Instance.new("TextButton")
ServerTabBtn.Name = "ServerTabBtn"
ServerTabBtn.Size = UDim2.new(0, 65, 0, 26)
ServerTabBtn.Position = UDim2.new(0, 78, 0, 5)
ServerTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
ServerTabBtn.BackgroundTransparency = 0.4
ServerTabBtn.Font = Enum.Font.GothamBold
ServerTabBtn.Text = "SERVER"
ServerTabBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
ServerTabBtn.TextSize = 9
ServerTabBtn.Parent = HeaderBar

local ServerTabCorner = Instance.new("UICorner")
ServerTabCorner.CornerRadius = UDim.new(0, 8)
ServerTabCorner.Parent = ServerTabBtn

local ProfileTabBtn = Instance.new("TextButton")
ProfileTabBtn.Name = "ProfileTabBtn"
ProfileTabBtn.Size = UDim2.new(0, 65, 0, 26)
ProfileTabBtn.Position = UDim2.new(0, 148, 0, 5)
ProfileTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
ProfileTabBtn.BackgroundTransparency = 0.4
ProfileTabBtn.Font = Enum.Font.GothamBold
ProfileTabBtn.Text = "PROFILE"
ProfileTabBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
ProfileTabBtn.TextSize = 9
ProfileTabBtn.Parent = HeaderBar

local ProfileTabCorner = Instance.new("UICorner")
ProfileTabCorner.CornerRadius = UDim.new(0, 8)
ProfileTabCorner.Parent = ProfileTabBtn

local AboutTabBtn = Instance.new("TextButton")
AboutTabBtn.Name = "AboutTabBtn"
AboutTabBtn.Size = UDim2.new(0, 65, 0, 26)
AboutTabBtn.Position = UDim2.new(0, 218, 0, 5)
AboutTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
AboutTabBtn.BackgroundTransparency = 0.4
AboutTabBtn.Font = Enum.Font.GothamBold
AboutTabBtn.Text = "ABOUT"
AboutTabBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
AboutTabBtn.TextSize = 9
AboutTabBtn.Parent = HeaderBar

local AboutTabCorner = Instance.new("UICorner")
AboutTabCorner.CornerRadius = UDim.new(0, 8)
AboutTabCorner.Parent = AboutTabBtn

local KronosHeaderLabel = Instance.new("TextLabel")
KronosHeaderLabel.Name = "KronosHeaderLabel"
KronosHeaderLabel.Size = UDim2.new(0, 80, 0, 26)
KronosHeaderLabel.Position = UDim2.new(1, -88, 0, 5)
KronosHeaderLabel.BackgroundTransparency = 1
KronosHeaderLabel.Font = Enum.Font.GothamBold
KronosHeaderLabel.Text = "KRONOS"
KronosHeaderLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
KronosHeaderLabel.TextSize = 13
KronosHeaderLabel.Parent = HeaderBar

task.spawn(function()
    local blackColor = Color3.fromRGB(0, 0, 0)
    local brightRedColor = Color3.fromRGB(255, 0, 0)
    local frequency = 1.0
    while true do
        local elapsed = tick()
        local factor = (math.sin(elapsed * frequency) + 1) / 2
        KronosHeaderLabel.TextColor3 = blackColor:Lerp(brightRedColor, factor)
        task.wait(0.03)
    end
end)

local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ChatToggleButton"
ToggleButton.Size = UDim2.new(0, 110, 0, 38)
ToggleButton.Position = UDim2.new(0.02, 0, 0.5, 0)
ToggleButton.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
ToggleButton.BackgroundTransparency = 0.35
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.Text = "  KRONOS"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 12
ToggleButton.Visible = true
ToggleButton.Parent = ScreenGui

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 12)
ToggleCorner.Parent = ToggleButton

local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Thickness = 2.5
ToggleStroke.Color = Color3.fromRGB(255, 0, 0)
ToggleStroke.Parent = ToggleButton

ToggleButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

local MessageContainer = Instance.new("ScrollingFrame")
MessageContainer.Name = "MessageContainer"
MessageContainer.Size = UDim2.new(1, -16, 1, -90)
MessageContainer.Position = UDim2.new(0, 8, 0, 40)
MessageContainer.BackgroundTransparency = 1
MessageContainer.BorderSizePixel = 0
MessageContainer.ScrollBarThickness = 4
MessageContainer.ScrollBarImageColor3 = Color3.fromRGB(255, 0, 0)
MessageContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
MessageContainer.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 6)
UIListLayout.Parent = MessageContainer

UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    MessageContainer.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 12)
    MessageContainer.CanvasPosition = Vector2.new(0, MessageContainer.CanvasSize.Y.Offset)
end)

-- Notification Container Frame
local NotifContainerFrame = Instance.new("Frame")
NotifContainerFrame.Name = "NotifContainerFrame"
NotifContainerFrame.Size = UDim2.new(0, 350, 0, 40)
NotifContainerFrame.Position = UDim2.new(0.5, -175, 0, 20)
NotifContainerFrame.BackgroundTransparency = 1
NotifContainerFrame.ZIndex = 100
NotifContainerFrame.Parent = ScreenGui

local ActiveNotifBtn = nil

local function DisplayNewMessageNotif(msgData)
    if msgData.Username == LocalPlayer.Name or msgData.IsPrivate then return end

    local rawName = msgData.DisplayName or msgData.Username or "Unknown"
    local isClient = (msgData.Username == LocalPlayer.Name)
    local formattedName = TruncateText(GetFormattedDisplayName(rawName, isClient), 20)
    local rawText = msgData.Text or ""
    if string.sub(rawText, 1, 11) == "rbxthumb://" or string.sub(rawText, 1, 13) == "rbxassetid://" then
        rawText = "[Sticker]"
    end
    local formattedMsg = TruncateText(rawText, 30)

    if ActiveNotifBtn and ActiveNotifBtn.Parent then
        ActiveNotifBtn:Destroy()
        ActiveNotifBtn = nil
    end

    local notifBtn = Instance.new("TextButton")
    notifBtn.Name = "MessageNotification"
    notifBtn.Size = UDim2.new(1, 0, 1, 0)
    notifBtn.Position = UDim2.new(0, 0, -0.5, 0)
    notifBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    notifBtn.BackgroundTransparency = 0.35
    notifBtn.BorderSizePixel = 0
    notifBtn.Font = Enum.Font.GothamBold
    notifBtn.Text = string.format("💬 %s : %s", formattedName, formattedMsg)
    notifBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    notifBtn.TextSize = 12
    notifBtn.TextWrapped = true
    notifBtn.ZIndex = 101
    notifBtn.Parent = NotifContainerFrame

    local notifCorner = Instance.new("UICorner")
    notifCorner.CornerRadius = UDim.new(0, 8)
    notifCorner.Parent = notifBtn

    local notifStroke = Instance.new("UIStroke")
    notifStroke.Thickness = 1.5
    notifStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    notifStroke.Color = Color3.fromRGB(255, 255, 255)
    notifStroke.Parent = notifBtn

    local notifGradient = Instance.new("UIGradient")
    notifGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 0, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
    })
    notifGradient.Parent = notifStroke

    task.spawn(function()
        while notifBtn and notifBtn.Parent do
            local dt = RunService.RenderStepped:Wait()
            notifGradient.Rotation = (notifGradient.Rotation + (60 * dt)) % 360
        end
    end)

    ActiveNotifBtn = notifBtn

    TweenService:Create(notifBtn, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0)
    }):Play()

    task.delay(3.5, function()
        if ActiveNotifBtn == notifBtn and notifBtn and notifBtn.Parent then
            ActiveNotifBtn = nil
            local slideOut = TweenService:Create(notifBtn, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(0, 0, -1, 0)
            })
            slideOut:Play()
            slideOut.Completed:Wait()
            if notifBtn and notifBtn.Parent then
                notifBtn:Destroy()
            end
        end
    end)

    notifBtn.MouseButton1Click:Connect(function()
        if ActiveNotifBtn == notifBtn then ActiveNotifBtn = nil end
        local slideOut = TweenService:Create(notifBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(0, 0, -1, 0)
        })
        slideOut:Play()
        slideOut.Completed:Wait()
        if notifBtn and notifBtn.Parent then
            notifBtn:Destroy()
        end
    end)
end

-- Sticker Panel Initialization
local StickerPanel = Instance.new("Frame")
StickerPanel.Name = "StickerPanel"
StickerPanel.Size = UDim2.new(0, 260, 0, 200)
StickerPanel.Position = UDim2.new(1, -268, 1, -250)
StickerPanel.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
StickerPanel.BackgroundTransparency = 0.2
StickerPanel.BorderSizePixel = 0
StickerPanel.Visible = false
StickerPanel.ZIndex = 25
StickerPanel.Parent = MainFrame

local StickerPanelCorner = Instance.new("UICorner")
StickerPanelCorner.CornerRadius = UDim.new(0, 10)
StickerPanelCorner.Parent = StickerPanel

local StickerPanelStroke = Instance.new("UIStroke")
StickerPanelStroke.Thickness = 1.5
StickerPanelStroke.Color = Color3.fromRGB(220, 30, 30)
StickerPanelStroke.Transparency = 0.4
StickerPanelStroke.Parent = StickerPanel

local StickerScroller = Instance.new("ScrollingFrame")
StickerScroller.Name = "StickerScroller"
StickerScroller.Size = UDim2.new(1, -12, 1, -12)
StickerScroller.Position = UDim2.new(0, 6, 0, 6)
StickerScroller.BackgroundTransparency = 1
StickerScroller.BorderSizePixel = 0
StickerScroller.ScrollBarThickness = 4
StickerScroller.ScrollBarImageColor3 = Color3.fromRGB(220, 30, 30)
StickerScroller.ZIndex = 26
StickerScroller.Parent = StickerPanel

local StickerGrid = Instance.new("UIGridLayout")
StickerGrid.CellSize = UDim2.new(0, 70, 0, 70)
StickerGrid.CellPadding = UDim2.new(0, 6, 0, 6)
StickerGrid.SortOrder = Enum.SortOrder.LayoutOrder
StickerGrid.Parent = StickerScroller

StickerGrid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    StickerScroller.CanvasSize = UDim2.new(0, 0, 0, StickerGrid.AbsoluteContentSize.Y + 12)
end)

for _, stickerUrl in ipairs(baseStickers) do
    local stickerCard = Instance.new("ImageButton")
    stickerCard.Name = "StickerCard"
    stickerCard.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
    stickerCard.BackgroundTransparency = 0.3
    stickerCard.Image = stickerUrl
    stickerCard.ScaleType = Enum.ScaleType.Fit
    stickerCard.ZIndex = 27
    stickerCard.Parent = StickerScroller

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 8)
    cardCorner.Parent = stickerCard

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Thickness = 1
    cardStroke.Color = Color3.fromRGB(255, 255, 255)
    cardStroke.Transparency = 0.8
    cardStroke.Parent = stickerCard

    stickerCard.MouseButton1Click:Connect(function()
        StickerPanel.Visible = false
        if MessageInput then
            MessageInput.Text = stickerUrl
            if SendChatMessage then SendChatMessage() end
        end
    end)
end

-- Input Area Construction
local InputBar = Instance.new("Frame")
InputBar.Name = "InputBar"
InputBar.Size = UDim2.new(1, -16, 0, 36)
InputBar.Position = UDim2.new(0, 8, 1, -44)
InputBar.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
InputBar.BackgroundTransparency = 0.4
InputBar.BorderSizePixel = 0
InputBar.Parent = MainFrame

local InputCorner = Instance.new("UICorner")
InputCorner.CornerRadius = UDim.new(0, 10)
InputCorner.Parent = InputBar

MessageInput = Instance.new("TextBox")
MessageInput.Name = "MessageInput"
MessageInput.Size = UDim2.new(1, -80, 1, 0)
MessageInput.Position = UDim2.new(0, 10, 0, 0)
MessageInput.BackgroundTransparency = 1
MessageInput.Font = Enum.Font.Gotham
MessageInput.PlaceholderText = "Type a message..."
MessageInput.PlaceholderColor3 = Color3.fromRGB(120, 120, 135)
MessageInput.Text = ""
MessageInput.TextColor3 = Color3.fromRGB(255, 255, 255)
MessageInput.TextSize = 11
MessageInput.ClearTextOnFocus = false
MessageInput.Parent = InputBar

local StickerToggleBtn = Instance.new("TextButton")
StickerToggleBtn.Name = "StickerToggleBtn"
StickerToggleBtn.Size = UDim2.new(0, 30, 0, 26)
StickerToggleBtn.Position = UDim2.new(1, -70, 0, 5)
StickerToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
StickerToggleBtn.BackgroundTransparency = 0.3
StickerToggleBtn.Font = Enum.Font.GothamBold
StickerToggleBtn.Text = "📌"
StickerToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
StickerToggleBtn.TextSize = 12
StickerToggleBtn.Parent = InputBar

local StickerBtnCorner = Instance.new("UICorner")
StickerBtnCorner.CornerRadius = UDim.new(0, 6)
StickerBtnCorner.Parent = StickerToggleBtn

StickerToggleBtn.MouseButton1Click:Connect(function()
    StickerPanel.Visible = not StickerPanel.Visible
end)

local SendBtn = Instance.new("TextButton")
SendBtn.Name = "SendBtn"
SendBtn.Size = UDim2.new(0, 32, 0, 26)
SendBtn.Position = UDim2.new(1, -36, 0, 5)
SendBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
SendBtn.BackgroundTransparency = 0.2
SendBtn.Font = Enum.Font.GothamBold
SendBtn.Text = "➤"
SendBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SendBtn.TextSize = 12
SendBtn.Parent = InputBar

local SendBtnCorner = Instance.new("UICorner")
SendBtnCorner.CornerRadius = UDim.new(0, 6)
SendBtnCorner.Parent = SendBtn

-- ============================================================================
-- PROFILE TAB SETUP
-- ============================================================================
local ProfileFrame = Instance.new("Frame")
ProfileFrame.Name = "ProfileFrame"
ProfileFrame.Size = UDim2.new(1, -16, 1, -48)
ProfileFrame.Position = UDim2.new(0, 8, 0, 40)
ProfileFrame.BackgroundTransparency = 1
ProfileFrame.Visible = false
ProfileFrame.Parent = MainFrame

local PfpHeaderBar = Instance.new("Frame")
PfpHeaderBar.Name = "PfpHeaderBar"
PfpHeaderBar.Size = UDim2.new(1, 0, 0, 30)
PfpHeaderBar.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
PfpHeaderBar.BackgroundTransparency = 0.4
PfpHeaderBar.BorderSizePixel = 0
PfpHeaderBar.Parent = ProfileFrame

local PfpHeaderCorner = Instance.new("UICorner")
PfpHeaderCorner.CornerRadius = UDim.new(0, 8)
PfpHeaderCorner.Parent = PfpHeaderBar

local BoySectionBtn = Instance.new("TextButton")
BoySectionBtn.Name = "BoySectionBtn"
BoySectionBtn.Size = UDim2.new(0.32, -4, 1, -6)
BoySectionBtn.Position = UDim2.new(0, 3, 0, 3)
BoySectionBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
BoySectionBtn.BackgroundTransparency = 0.2
BoySectionBtn.Font = Enum.Font.GothamBold
BoySectionBtn.Text = "HIS (BOY)"
BoySectionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
BoySectionBtn.TextSize = 10
BoySectionBtn.Parent = PfpHeaderBar

local BoySectionCorner = Instance.new("UICorner")
BoySectionCorner.CornerRadius = UDim.new(0, 6)
BoySectionCorner.Parent = BoySectionBtn

local GirlSectionBtn = Instance.new("TextButton")
GirlSectionBtn.Name = "GirlSectionBtn"
GirlSectionBtn.Size = UDim2.new(0.32, -4, 1, -6)
GirlSectionBtn.Position = UDim2.new(0.34, 0, 0, 3)
GirlSectionBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
GirlSectionBtn.BackgroundTransparency = 0.4
GirlSectionBtn.Font = Enum.Font.GothamBold
GirlSectionBtn.Text = "HER (GIRL)"
GirlSectionBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
GirlSectionBtn.TextSize = 10
GirlSectionBtn.Parent = PfpHeaderBar

local GirlSectionCorner = Instance.new("UICorner")
GirlSectionCorner.CornerRadius = UDim.new(0, 6)
GirlSectionCorner.Parent = GirlSectionBtn

local CustomSectionBtn = Instance.new("TextButton")
CustomSectionBtn.Name = "CustomSectionBtn"
CustomSectionBtn.Size = UDim2.new(0.34, -4, 1, -6)
CustomSectionBtn.Position = UDim2.new(0.67, 0, 0, 3)
CustomSectionBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
CustomSectionBtn.BackgroundTransparency = 0.4
CustomSectionBtn.Font = Enum.Font.GothamBold
CustomSectionBtn.Text = "CUSTOM ID"
CustomSectionBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
CustomSectionBtn.TextSize = 10
CustomSectionBtn.Parent = PfpHeaderBar

local CustomSectionCorner = Instance.new("UICorner")
CustomSectionCorner.CornerRadius = UDim.new(0, 6)
CustomSectionCorner.Parent = CustomSectionBtn

-- Active PFP Display Card
local ActivePfpCard = Instance.new("Frame")
ActivePfpCard.Name = "ActivePfpCard"
ActivePfpCard.Size = UDim2.new(1, 0, 0, 50)
ActivePfpCard.Position = UDim2.new(0, 0, 0, 35)
ActivePfpCard.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
ActivePfpCard.BackgroundTransparency = 0.4
ActivePfpCard.BorderSizePixel = 0
ActivePfpCard.Parent = ProfileFrame

local ActiveCardCorner = Instance.new("UICorner")
ActiveCardCorner.CornerRadius = UDim.new(0, 8)
ActiveCardCorner.Parent = ActivePfpCard

local ActivePfpImg = Instance.new("ImageLabel")
ActivePfpImg.Name = "ActivePfpImg"
ActivePfpImg.Size = UDim2.new(0, 40, 0, 40)
ActivePfpImg.Position = UDim2.new(0, 6, 0, 5)
ActivePfpImg.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
ActivePfpImg.Image = CurrentPFP
ActivePfpImg.Parent = ActivePfpCard

local ActivePfpCorner = Instance.new("UICorner")
ActivePfpCorner.CornerRadius = UDim.new(1, 0)
ActivePfpCorner.Parent = ActivePfpImg

local ActivePfpStroke = Instance.new("UIStroke")
ActivePfpStroke.Thickness = 1.5
ActivePfpStroke.Color = Color3.fromRGB(255, 30, 30)
ActivePfpStroke.Parent = ActivePfpImg

local ActivePfpLabel = Instance.new("TextLabel")
ActivePfpLabel.Name = "ActivePfpLabel"
ActivePfpLabel.Size = UDim2.new(1, -60, 1, 0)
ActivePfpLabel.Position = UDim2.new(0, 52, 0, 0)
ActivePfpLabel.BackgroundTransparency = 1
ActivePfpLabel.Font = Enum.Font.GothamBold
ActivePfpLabel.Text = "Active Profile Picture\n<font color='#A0A0B0' size='10'>Saved & persistent across reloads</font>"
ActivePfpLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
ActivePfpLabel.TextSize = 11
ActivePfpLabel.TextXAlignment = Enum.TextXAlignment.Left
ActivePfpLabel.RichText = true
ActivePfpLabel.Parent = ActivePfpCard

-- Pfp Scrollers
local PfpGridScroller = Instance.new("ScrollingFrame")
PfpGridScroller.Name = "PfpGridScroller"
PfpGridScroller.Size = UDim2.new(1, 0, 1, -92)
PfpGridScroller.Position = UDim2.new(0, 0, 0, 90)
PfpGridScroller.BackgroundTransparency = 1
PfpGridScroller.BorderSizePixel = 0
PfpGridScroller.ScrollBarThickness = 3
PfpGridScroller.ScrollBarImageColor3 = Color3.fromRGB(255, 0, 0)
PfpGridScroller.Parent = ProfileFrame

local PfpGrid = Instance.new("UIGridLayout")
PfpGrid.CellSize = UDim2.new(0, 52, 0, 52)
PfpGrid.CellPadding = UDim2.new(0, 6, 0, 6)
PfpGrid.SortOrder = Enum.SortOrder.LayoutOrder
PfpGrid.Parent = PfpGridScroller

PfpGrid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    PfpGridScroller.CanvasSize = UDim2.new(0, 0, 0, PfpGrid.AbsoluteContentSize.Y + 12)
end)

-- Custom Pfp Box Frame
local CustomPfpFrame = Instance.new("Frame")
CustomPfpFrame.Name = "CustomPfpFrame"
CustomPfpFrame.Size = UDim2.new(1, 0, 1, -92)
CustomPfpFrame.Position = UDim2.new(0, 0, 0, 90)
CustomPfpFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
CustomPfpFrame.BackgroundTransparency = 0.4
CustomPfpFrame.Visible = false
CustomPfpFrame.Parent = ProfileFrame

local CustomPfpCorner = Instance.new("UICorner")
CustomPfpCorner.CornerRadius = UDim.new(0, 8)
CustomPfpCorner.Parent = CustomPfpFrame

local CustomPfpTitle = Instance.new("TextLabel")
CustomPfpTitle.Size = UDim2.new(1, -16, 0, 20)
CustomPfpTitle.Position = UDim2.new(0, 8, 0, 10)
CustomPfpTitle.BackgroundTransparency = 1
CustomPfpTitle.Font = Enum.Font.GothamBold
CustomPfpTitle.Text = "ENTER CUSTOM ASSET ID / CODE"
CustomPfpTitle.TextColor3 = Color3.fromRGB(255, 60, 60)
CustomPfpTitle.TextSize = 11
CustomPfpTitle.TextXAlignment = Enum.TextXAlignment.Left
CustomPfpTitle.Parent = CustomPfpFrame

local CustomPfpInput = Instance.new("TextBox")
CustomPfpInput.Name = "CustomPfpInput"
CustomPfpInput.Size = UDim2.new(1, -16, 0, 36)
CustomPfpInput.Position = UDim2.new(0, 8, 0, 35)
CustomPfpInput.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
CustomPfpInput.BackgroundTransparency = 0.3
CustomPfpInput.Font = Enum.Font.Gotham
CustomPfpInput.PlaceholderText = "Paste AssetId or Code e.g. 110388265928893"
CustomPfpInput.PlaceholderColor3 = Color3.fromRGB(130, 130, 140)
CustomPfpInput.Text = ""
CustomPfpInput.TextColor3 = Color3.fromRGB(240, 240, 250)
CustomPfpInput.TextSize = 11
CustomPfpInput.ClearTextOnFocus = false
CustomPfpInput.Parent = CustomPfpFrame

local CustomInputCorner = Instance.new("UICorner")
CustomInputCorner.CornerRadius = UDim.new(0, 6)
CustomInputCorner.Parent = CustomPfpInput

local ApplyCustomPfpBtn = Instance.new("TextButton")
ApplyCustomPfpBtn.Name = "ApplyCustomPfpBtn"
ApplyCustomPfpBtn.Size = UDim2.new(0, 130, 0, 28)
ApplyCustomPfpBtn.Position = UDim2.new(0, 8, 0, 80)
ApplyCustomPfpBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
ApplyCustomPfpBtn.BackgroundTransparency = 0.2
ApplyCustomPfpBtn.Font = Enum.Font.GothamBold
ApplyCustomPfpBtn.Text = "APPLY PFP"
ApplyCustomPfpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ApplyCustomPfpBtn.TextSize = 10
ApplyCustomPfpBtn.Parent = CustomPfpFrame

local ApplyCustomCorner = Instance.new("UICorner")
ApplyCustomCorner.CornerRadius = UDim.new(0, 6)
ApplyCustomCorner.Parent = ApplyCustomPfpBtn

local currentPfpSection = "BOY"

local function LoadPfpSection(section)
    currentPfpSection = section
    for _, child in ipairs(PfpGridScroller:GetChildren()) do
        if child:IsA("ImageButton") then child:Destroy() end
    end

    if section == "BOY" or section == "GIRL" then
        PfpGridScroller.Visible = true
        CustomPfpFrame.Visible = false
        local pfpList = (section == "BOY") and BOY_PFPS or GIRL_PFPS

        for _, imgUrl in ipairs(pfpList) do
            local pfpBtn = Instance.new("ImageButton")
            pfpBtn.Name = "PfpButton"
            pfpBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
            pfpBtn.BackgroundTransparency = 0.3
            pfpBtn.Image = imgUrl
            pfpBtn.Parent = PfpGridScroller

            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 8)
            btnCorner.Parent = pfpBtn

            local btnStroke = Instance.new("UIStroke")
            btnStroke.Thickness = 1
            btnStroke.Color = Color3.fromRGB(255, 255, 255)
            btnStroke.Transparency = 0.8
            btnStroke.Parent = pfpBtn

            pfpBtn.MouseButton1Click:Connect(function()
                SavePFPLocally(imgUrl)
                ActivePfpImg.Image = imgUrl
            end)
        end
    else
        PfpGridScroller.Visible = false
        CustomPfpFrame.Visible = true
    end
end

BoySectionBtn.MouseButton1Click:Connect(function()
    BoySectionBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
    BoySectionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    GirlSectionBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    GirlSectionBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
    CustomSectionBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    CustomSectionBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
    LoadPfpSection("BOY")
end)

GirlSectionBtn.MouseButton1Click:Connect(function()
    GirlSectionBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
    GirlSectionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    BoySectionBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    BoySectionBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
    CustomSectionBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    CustomSectionBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
    LoadPfpSection("GIRL")
end)

CustomSectionBtn.MouseButton1Click:Connect(function()
    CustomSectionBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
    CustomSectionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    BoySectionBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    BoySectionBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
    GirlSectionBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    GirlSectionBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
    LoadPfpSection("CUSTOM")
end)

ApplyCustomPfpBtn.MouseButton1Click:Connect(function()
    local text = CustomPfpInput.Text:gsub("%s+", "")
    if text ~= "" then
        local extractedId = text:match("%d+")
        if extractedId then
            local formattedPfp = "rbxassetid://" .. extractedId
            SavePFPLocally(formattedPfp)
            ActivePfpImg.Image = formattedPfp
            ApplyCustomPfpBtn.Text = "APPLIED ✓"
            task.delay(1.5, function()
                ApplyCustomPfpBtn.Text = "APPLY PFP"
            end)
        end
    end
end)

LoadPfpSection("BOY")

-- About Section Configuration
local AboutFrame = Instance.new("Frame")
AboutFrame.Name = "AboutFrame"
AboutFrame.Size = UDim2.new(1, -16, 1, -48)
AboutFrame.Position = UDim2.new(0, 8, 0, 40)
AboutFrame.BackgroundTransparency = 1
AboutFrame.Visible = false
AboutFrame.Parent = MainFrame

local TagScrollFrame = Instance.new("ScrollingFrame")
TagScrollFrame.Name = "TagScrollFrame"
TagScrollFrame.Size = UDim2.new(1, 0, 0, 36)
TagScrollFrame.Position = UDim2.new(0, 0, 0, 0)
TagScrollFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
TagScrollFrame.BackgroundTransparency = 0.4
TagScrollFrame.BorderSizePixel = 0
TagScrollFrame.ScrollBarThickness = 3
TagScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 0, 0)
TagScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
TagScrollFrame.HorizontalScrollBarInset = Enum.ScrollBarInset.ScrollBar
TagScrollFrame.Parent = AboutFrame

local TagScrollCorner = Instance.new("UICorner")
TagScrollCorner.CornerRadius = UDim.new(0, 8)
TagScrollCorner.Parent = TagScrollFrame

local TagListLayout = Instance.new("UIListLayout")
TagListLayout.FillDirection = Enum.FillDirection.Horizontal
TagListLayout.SortOrder = Enum.SortOrder.Name
TagListLayout.Padding = UDim.new(0, 6)
TagListLayout.Parent = TagScrollFrame

local TagPadding = Instance.new("UIPadding")
TagPadding.PaddingLeft = UDim.new(0, 6)
TagPadding.PaddingRight = UDim.new(0, 6)
TagPadding.PaddingTop = UDim.new(0, 5)
TagPadding.Parent = TagScrollFrame

TagListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    TagScrollFrame.CanvasSize = UDim2.new(0, TagListLayout.AbsoluteContentSize.X + 16, 0, 0)
end)

local function PopulateTagBar()
    for _, child in ipairs(TagScrollFrame:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") then child:Destroy() end
    end

    for roleName, style in pairs(RANK_STYLES) do
        local tagBtn = Instance.new("TextButton")
        tagBtn.Name = roleName
        tagBtn.AutomaticSize = Enum.AutomaticSize.X
        tagBtn.Size = UDim2.new(0, 0, 0, 22)
        tagBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
        tagBtn.BackgroundTransparency = 0.2
        tagBtn.Font = Enum.Font.GothamBold
        tagBtn.Text = "  " .. string.upper(roleName) .. "  "
        tagBtn.TextColor3 = style.Start
        tagBtn.TextSize = 10
        tagBtn.Parent = TagScrollFrame

        local tagCorner = Instance.new("UICorner")
        tagCorner.CornerRadius = UDim.new(0, 6)
        tagCorner.Parent = tagBtn

        local tagStroke = Instance.new("UIStroke")
        tagStroke.Thickness = 1
        tagStroke.Color = style.Start
        tagStroke.Parent = tagBtn
    end
end
PopulateTagBar()

-- About Information Card
local AboutInfoCard = Instance.new("Frame")
AboutInfoCard.Name = "AboutInfoCard"
AboutInfoCard.Size = UDim2.new(1, 0, 1, -44)
AboutInfoCard.Position = UDim2.new(0, 0, 0, 44)
AboutInfoCard.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
AboutInfoCard.BackgroundTransparency = 0.4
AboutInfoCard.BorderSizePixel = 0
AboutInfoCard.Parent = AboutFrame

local AboutInfoCorner = Instance.new("UICorner")
AboutInfoCorner.CornerRadius = UDim.new(0, 8)
AboutInfoCorner.Parent = AboutInfoCard

local AboutTextLabel = Instance.new("TextLabel")
AboutTextLabel.Size = UDim2.new(1, -20, 1, -20)
AboutTextLabel.Position = UDim2.new(0, 10, 0, 10)
AboutTextLabel.BackgroundTransparency = 1
AboutTextLabel.Font = Enum.Font.Gotham
AboutTextLabel.Text = "<font color='#FF3030'><b>KRONOS CHAT CLIENT</b></font>\n\n• Cross-Server Intercom Network\n• Fully Drag-enabled Interface\n• Custom Profile Persistence\n• Dynamic Anti-Spam Systems"
AboutTextLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
AboutTextLabel.TextSize = 11
AboutTextLabel.TextYAlignment = Enum.TextYAlignment.Top
AboutTextLabel.RichText = true
AboutTextLabel.Parent = AboutInfoCard

-- ============================================================================
-- TAB SWITCHING MECHANICS
-- ============================================================================
local function SwitchTab(newTab)
    ActiveTab = newTab

    GlobalTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    GlobalTabBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
    ServerTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    ServerTabBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
    ProfileTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    ProfileTabBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
    AboutTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    AboutTabBtn.TextColor3 = Color3.fromRGB(180, 180, 190)

    MessageContainer.Visible = false
    InputBar.Visible = false
    ProfileFrame.Visible = false
    AboutFrame.Visible = false

    if newTab == "GLOBAL" then
        GlobalTabBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
        GlobalTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        MessageContainer.Visible = true
        InputBar.Visible = true
    elseif newTab == "SERVER" then
        ServerTabBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
        ServerTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        MessageContainer.Visible = true
        InputBar.Visible = true
    elseif newTab == "PROFILE" then
        ProfileTabBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
        ProfileTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        ProfileFrame.Visible = true
    elseif newTab == "ABOUT" then
        AboutTabBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
        AboutTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        AboutFrame.Visible = true
    end
end

GlobalTabBtn.MouseButton1Click:Connect(function() SwitchTab("GLOBAL") end)
ServerTabBtn.MouseButton1Click:Connect(function() SwitchTab("SERVER") end)
ProfileTabBtn.MouseButton1Click:Connect(function() SwitchTab("PROFILE") end)
AboutTabBtn.MouseButton1Click:Connect(function() SwitchTab("ABOUT") end)

-- ============================================================================
-- NETWORKING & FIREBASE API ENGINE
-- ============================================================================
SendChatMessage = function()
    local text = MessageInput.Text
    if text == "" or not string.find(text, "%S") then return end

    local now = os.time()
    if text == LastSentMessageText and (now - LastMessageSendTime) < 5 then
        ConsecutiveSpamCount = ConsecutiveSpamCount + 1
        if ConsecutiveSpamCount >= 2 then
            MessageInput.Text = ""
            MessageInput.PlaceholderText = "Anti-Spam Block! Wait a moment..."
            task.delay(2, function()
                MessageInput.PlaceholderText = "Type a message..."
            end)
            return
        end
    else
        ConsecutiveSpamCount = 0
    end

    LastSentMessageText = text
    LastMessageSendTime = now

    local payload = {
        Username = LocalPlayer.Name,
        DisplayName = SpoofedDisplayName or LocalPlayer.DisplayName,
        Text = text,
        PFP = CurrentPFP,
        Timestamp = now,
        Role = GetAssignedOrCalculatedRole(LocalPlayer.Name)
    }

    MessageInput.Text = ""

    task.spawn(function()
        local endpoint = (ActiveTab == "GLOBAL") and GLOBAL_MESSAGES_ENDPOINT or SERVER_MESSAGES_ENDPOINT
        HttpRequest(endpoint, "POST", payload)
    end)
end

SendBtn.MouseButton1Click:Connect(SendChatMessage)
MessageInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then SendChatMessage() end
end)

-- Fetch Loop Sync Engine
task.spawn(function()
    FetchRemoteRankStyles()
    FetchRemoteRoles()
    
    while true do
        task.wait(1.5)
        local targetUrl = (ActiveTab == "GLOBAL") and GLOBAL_MESSAGES_ENDPOINT or SERVER_MESSAGES_ENDPOINT
        local rawData = HttpRequest(targetUrl, "GET")

        if rawData and type(rawData) == "table" then
            for id, msgData in pairs(rawData) do
                if msgData.Timestamp and msgData.Timestamp >= ScriptStartTime then
                    local cachedList = (ActiveTab == "GLOBAL") and GlobalCachedMessages or ServerCachedMessages
                    if not cachedList[id] then
                        cachedList[id] = msgData
                        DisplayNewMessageNotif(msgData)

                        local msgFrame = Instance.new("Frame")
                        msgFrame.Size = UDim2.new(1, 0, 0, 36)
                        msgFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
                        msgFrame.BackgroundTransparency = 0.4
                        msgFrame.Parent = MessageContainer

                        local msgCorner = Instance.new("UICorner")
                        msgCorner.CornerRadius = UDim.new(0, 6)
                        msgCorner.Parent = msgFrame

                        local pfpImg = Instance.new("ImageLabel")
                        pfpImg.Size = UDim2.new(0, 28, 0, 28)
                        pfpImg.Position = UDim2.new(0, 4, 0, 4)
                        pfpImg.Image = msgData.PFP or DefaultPFP
                        pfpImg.BackgroundTransparency = 1
                        pfpImg.Parent = msgFrame

                        local pfpCorner = Instance.new("UICorner")
                        pfpCorner.CornerRadius = UDim.new(1, 0)
                        pfpCorner.Parent = pfpImg

                        local txtLabel = Instance.new("TextLabel")
                        txtLabel.Size = UDim2.new(1, -40, 1, 0)
                        txtLabel.Position = UDim2.new(0, 36, 0, 0)
                        txtLabel.BackgroundTransparency = 1
                        txtLabel.Font = Enum.Font.Gotham
                        txtLabel.Text = string.format("<b>%s</b>: %s", GetFormattedDisplayName(msgData.DisplayName or msgData.Username), msgData.Text or "")
                        txtLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
                        txtLabel.TextSize = 11
                        txtLabel.TextXAlignment = Enum.TextXAlignment.Left
                        txtLabel.RichText = true
                        txtLabel.Parent = msgFrame
                    end
                end
            end
        end
    end
end)
