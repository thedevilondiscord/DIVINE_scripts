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

-- Script Load Timestamp
local ScriptStartTime = os.time()

-- Forward Declaration for Inputs & Globals
local MessageInput = nil
local SendChatMessage = nil

-- Anti-Spam Tracking State
local LastSentMessageText = ""
local ConsecutiveSpamCount = 0
local LastMessageSendTime = 0

-- PFP DATASETS & SELECTION SYSTEM
local PFP_SAVE_FILE = "Kronos_PFP_Config.json"

local BOY_PFP_ASSETS = {
    "110388265928893", "95859643981980", "130155182109980", "13256391094", "7141979877", "126321955109144",
    "105811627876448", "117842977352398", "72892670694166", "83103469598025", "75074160606432", "102436713076194",
    "73360959903200", "8044287275", "75575644706346", "135418144122968", "108362888723956", "72208791847173",
    "126308173151046", "12589564218", "79957717292980", "9167461968", "14958453101", "15812656372",
    "17742534348", "16512222623", "16512186702", "15139830823", "113690915196801", "13815759727",
    "17209732396", "9465573085", "6828147162", "8798642997", "6931482888", "11465013207",
    "6151184293", "11792088810", "11792051524", "12129851981", "7766253892", "11810744690",
    "12129866999", "11792081695", "9812014649", "11566642562", "11566643877", "11566645628",
    "15489228483", "139913462267814", "127087398265711", "15741130603", "15914059452", "135351963625525",
    "116451771061047", "128665410481682", "80274332831847", "82099431184126", "133311251800519", "13120458633",
    "115774065375902", "70802874073501", "13589962584", "14640595544", "13399057339", "10246136967",
    "133023108030460", "119497955225507", "16167788172", "12972724276", "18955458678"
}

local GIRL_PFP_ASSETS = {
    "12020075855", "11830086459", "11511962080", "7777672203", "11830084792", "7332178758",
    "7430248978", "7766251418", "9093346004", "9093348980", "9093350889", "6784635852",
    "12557398956", "11830087451", "10305162859", "13706350387", "14436945404", "11830083821",
    "14436758178", "13135537390", "14428713593", "14436954850", "13135491186", "14428738204",
    "14428743609", "14436960020", "14758917533", "14484307859", "14437087525", "14436744290",
    "13835626125", "15317009082", "136596648757339", "81108881402205", "76266870536490", "16348401915",
    "117499002290555", "123333305454544", "114201242358456", "14847097309", "14688664923", "16348395223",
    "16348391354", "16348399148", "13843648183", "8705803091", "14549632840", "14111174579",
    "9052821925", "18516850087", "1756451716", "4958082006", "10395117329", "15023167771",
    "115457404558211", "14677866904", "106604782438383", "101003324274756", "99824761297039", "79899054463161",
    "132498447517240", "14365830804", "14133573570", "84575585234733", "14740456559"
}

local CurrentSelectedPfpID = "rbxthumb://type=AvatarHeadShot&id=" .. lplr.UserId .. "&w=150&h=150"

local function LoadSavedPFP()
    if readfile and isfile and isfile(PFP_SAVE_FILE) then
        local success, result = pcall(function()
            return HttpService:JSONDecode(readfile(PFP_SAVE_FILE))
        end)
        if success and result and result.pfpID then
            CurrentSelectedPfpID = result.pfpID
        end
    end
end

local function SavePFP(pfpID)
    CurrentSelectedPfpID = pfpID
    if writefile then
        pcall(function()
            writefile(PFP_SAVE_FILE, HttpService:JSONEncode({ pfpID = pfpID }))
        end)
    end
end

LoadSavedPFP()

-- Helper function to truncate DisplayName
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

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 450, 0, 410)
MainFrame.Position = UDim2.new(0.02, 0, 0.45, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
MainFrame.BackgroundTransparency = 0.35
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = false
MainFrame.Parent = ScreenGui

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

-- TOP CLIENT PROFILE CARD
local ProfileHeaderFrame = Instance.new("Frame")
ProfileHeaderFrame.Name = "ProfileHeaderFrame"
ProfileHeaderFrame.Size = UDim2.new(1, 0, 0, 85)
ProfileHeaderFrame.Position = UDim2.new(0, 0, 0, 0)
ProfileHeaderFrame.BackgroundTransparency = 1
ProfileHeaderFrame.Parent = MainFrame

local ProfilePFPImage = Instance.new("ImageLabel")
ProfilePFPImage.Name = "ProfilePFPImage"
ProfilePFPImage.Size = UDim2.new(0, 48, 0, 48)
ProfilePFPImage.Position = UDim2.new(0.5, -24, 0, 6)
ProfilePFPImage.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
ProfilePFPImage.Image = CurrentSelectedPfpID
ProfilePFPImage.Parent = ProfileHeaderFrame

local ProfilePFPCorner = Instance.new("UICorner")
ProfilePFPCorner.CornerRadius = UDim.new(1, 0)
ProfilePFPCorner.Parent = ProfilePFPImage

local ProfilePFPStroke = Instance.new("UIStroke")
ProfilePFPStroke.Thickness = 1.5
ProfilePFPStroke.Color = Color3.fromRGB(255, 0, 0)
ProfilePFPStroke.Parent = ProfilePFPImage

local ProfileDisplayNameLabel = Instance.new("TextLabel")
ProfileDisplayNameLabel.Name = "ProfileDisplayNameLabel"
ProfileDisplayNameLabel.Size = UDim2.new(1, 0, 0, 16)
ProfileDisplayNameLabel.Position = UDim2.new(0, 0, 0, 56)
ProfileDisplayNameLabel.BackgroundTransparency = 1
ProfileDisplayNameLabel.Font = Enum.Font.GothamBold
ProfileDisplayNameLabel.Text = GetFormattedDisplayName(LocalPlayer.DisplayName, true)
ProfileDisplayNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
ProfileDisplayNameLabel.TextSize = 13
ProfileDisplayNameLabel.Parent = ProfileHeaderFrame

local ProfileUsernameLabel = Instance.new("TextLabel")
ProfileUsernameLabel.Name = "ProfileUsernameLabel"
ProfileUsernameLabel.Size = UDim2.new(1, 0, 0, 12)
ProfileUsernameLabel.Position = UDim2.new(0, 0, 0, 71)
ProfileUsernameLabel.BackgroundTransparency = 1
ProfileUsernameLabel.Font = Enum.Font.Gotham
ProfileUsernameLabel.Text = "@" .. LocalPlayer.Name
ProfileUsernameLabel.TextColor3 = Color3.fromRGB(140, 140, 155)
ProfileUsernameLabel.TextSize = 10
ProfileUsernameLabel.Parent = ProfileHeaderFrame

local function RefreshProfileCard()
    ProfilePFPImage.Image = CurrentSelectedPfpID
    ProfileDisplayNameLabel.Text = GetFormattedDisplayName(LocalPlayer.DisplayName, true)
    ProfileUsernameLabel.Text = "@" .. LocalPlayer.Name
end

local HeaderBar = Instance.new("Frame")
HeaderBar.Name = "HeaderBar"
HeaderBar.Size = UDim2.new(1, 0, 0, 36)
HeaderBar.Position = UDim2.new(0, 0, 0, 85)
HeaderBar.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
HeaderBar.BackgroundTransparency = 0.3
HeaderBar.BorderSizePixel = 0
HeaderBar.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 16)
HeaderCorner.Parent = HeaderBar

local GlobalTabBtn = Instance.new("TextButton")
GlobalTabBtn.Name = "GlobalTabBtn"
GlobalTabBtn.Size = UDim2.new(0, 80, 0, 26)
GlobalTabBtn.Position = UDim2.new(0, 8, 0, 5)
GlobalTabBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
GlobalTabBtn.BackgroundTransparency = 0.2
GlobalTabBtn.Font = Enum.Font.GothamBold
GlobalTabBtn.Text = "GLOBAL"
GlobalTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
GlobalTabBtn.TextSize = 10
GlobalTabBtn.Parent = HeaderBar

local GlobalTabCorner = Instance.new("UICorner")
GlobalTabCorner.CornerRadius = UDim.new(0, 8)
GlobalTabCorner.Parent = GlobalTabBtn

local ServerTabBtn = Instance.new("TextButton")
ServerTabBtn.Name = "ServerTabBtn"
ServerTabBtn.Size = UDim2.new(0, 80, 0, 26)
ServerTabBtn.Position = UDim2.new(0, 93, 0, 5)
ServerTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
ServerTabBtn.BackgroundTransparency = 0.4
ServerTabBtn.Font = Enum.Font.GothamBold
ServerTabBtn.Text = "SERVER"
ServerTabBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
ServerTabBtn.TextSize = 10
ServerTabBtn.Parent = HeaderBar

local ServerTabCorner = Instance.new("UICorner")
ServerTabCorner.CornerRadius = UDim.new(0, 8)
ServerTabCorner.Parent = ServerTabBtn

local AboutTabBtn = Instance.new("TextButton")
AboutTabBtn.Name = "AboutTabBtn"
AboutTabBtn.Size = UDim2.new(0, 75, 0, 26)
AboutTabBtn.Position = UDim2.new(0, 178, 0, 5)
AboutTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
AboutTabBtn.BackgroundTransparency = 0.4
AboutTabBtn.Font = Enum.Font.GothamBold
AboutTabBtn.Text = "ABOUT"
AboutTabBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
AboutTabBtn.TextSize = 10
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
MessageContainer.Size = UDim2.new(1, -16, 1, -175)
MessageContainer.Position = UDim2.new(0, 8, 0, 125)
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

-- About Section Configuration
local AboutFrame = Instance.new("Frame")
AboutFrame.Name = "AboutFrame"
AboutFrame.Size = UDim2.new(1, -16, 1, -135)
AboutFrame.Position = UDim2.new(0, 8, 0, 125)
AboutFrame.BackgroundTransparency = 1
AboutFrame.Visible = false
AboutFrame.Parent = MainFrame

-- PFP SELECTOR SECTION IN ABOUT TAB
local PfpSelectionFrame = Instance.new("Frame")
PfpSelectionFrame.Name = "PfpSelectionFrame"
PfpSelectionFrame.Size = UDim2.new(1, 0, 0, 100)
PfpSelectionFrame.Position = UDim2.new(0, 0, 0, 0)
PfpSelectionFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
PfpSelectionFrame.BackgroundTransparency = 0.4
PfpSelectionFrame.BorderSizePixel = 0
PfpSelectionFrame.Parent = AboutFrame

local PfpSelectCorner = Instance.new("UICorner")
PfpSelectCorner.CornerRadius = UDim.new(0, 8)
PfpSelectCorner.Parent = PfpSelectionFrame

local BoyToggleBtn = Instance.new("TextButton")
BoyToggleBtn.Name = "BoyToggleBtn"
BoyToggleBtn.Size = UDim2.new(0.5, -4, 0, 22)
BoyToggleBtn.Position = UDim2.new(0, 2, 0, 4)
BoyToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
BoyToggleBtn.BackgroundTransparency = 0.2
BoyToggleBtn.Font = Enum.Font.GothamBold
BoyToggleBtn.Text = "BOY PFPs"
BoyToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
BoyToggleBtn.TextSize = 10
BoyToggleBtn.Parent = PfpSelectionFrame

local BoyToggleCorner = Instance.new("UICorner")
BoyToggleCorner.CornerRadius = UDim.new(0, 6)
BoyToggleCorner.Parent = BoyToggleBtn

local GirlToggleBtn = Instance.new("TextButton")
GirlToggleBtn.Name = "GirlToggleBtn"
GirlToggleBtn.Size = UDim2.new(0.5, -4, 0, 22)
GirlToggleBtn.Position = UDim2.new(0.5, 2, 0, 4)
GirlToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
GirlToggleBtn.BackgroundTransparency = 0.4
GirlToggleBtn.Font = Enum.Font.GothamBold
GirlToggleBtn.Text = "GIRL PFPs"
GirlToggleBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
GirlToggleBtn.TextSize = 10
GirlToggleBtn.Parent = PfpSelectionFrame

local GirlToggleCorner = Instance.new("UICorner")
GirlToggleCorner.CornerRadius = UDim.new(0, 6)
GirlToggleCorner.Parent = GirlToggleBtn

local PfpScrollContainer = Instance.new("ScrollingFrame")
PfpScrollContainer.Name = "PfpScrollContainer"
PfpScrollContainer.Size = UDim2.new(1, -8, 0, 66)
PfpScrollContainer.Position = UDim2.new(0, 4, 0, 30)
PfpScrollContainer.BackgroundTransparency = 1
PfpScrollContainer.BorderSizePixel = 0
PfpScrollContainer.ScrollBarThickness = 3
PfpScrollContainer.ScrollBarImageColor3 = Color3.fromRGB(255, 0, 0)
PfpScrollContainer.Parent = PfpSelectionFrame

local PfpGrid = Instance.new("UIGridLayout")
PfpGrid.CellSize = UDim2.new(0, 50, 0, 50)
PfpGrid.CellPadding = UDim2.new(0, 5, 0, 5)
PfpGrid.SortOrder = Enum.SortOrder.LayoutOrder
PfpGrid.Parent = PfpScrollContainer

PfpGrid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    PfpScrollContainer.CanvasSize = UDim2.new(0, 0, 0, PfpGrid.AbsoluteContentSize.Y + 8)
end)

local function LoadPfpGrid(assetList)
    for _, child in ipairs(PfpScrollContainer:GetChildren()) do
        if child:IsA("ImageButton") then child:Destroy() end
    end

    for _, assetId in ipairs(assetList) do
        local pfpUrl = "rbxthumb://type=Asset&id=" .. assetId .. "&w=420&h=420"
        local pfpCard = Instance.new("ImageButton")
        pfpCard.Name = "PfpCard"
        pfpCard.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
        pfpCard.Image = pfpUrl
        pfpCard.ScaleType = Enum.ScaleType.Fit
        pfpCard.Parent = PfpScrollContainer

        local cardCorner = Instance.new("UICorner")
        cardCorner.CornerRadius = UDim.new(1, 0)
        cardCorner.Parent = pfpCard

        local cardStroke = Instance.new("UIStroke")
        cardStroke.Thickness = 1.5
        cardStroke.Color = Color3.fromRGB(255, 255, 255)
        cardStroke.Transparency = 0.8
        cardStroke.Parent = pfpCard

        pfpCard.MouseButton1Click:Connect(function()
            SavePFP(pfpUrl)
            RefreshProfileCard()
        end)
    end
end

BoyToggleBtn.MouseButton1Click:Connect(function()
    BoyToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
    BoyToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    BoyToggleBtn.BackgroundTransparency = 0.2

    GirlToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    GirlToggleBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
    GirlToggleBtn.BackgroundTransparency = 0.4

    LoadPfpGrid(BOY_PFP_ASSETS)
end)

GirlToggleBtn.MouseButton1Click:Connect(function()
    GirlToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
    GirlToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    GirlToggleBtn.BackgroundTransparency = 0.2

    BoyToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    BoyToggleBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
    BoyToggleBtn.BackgroundTransparency = 0.4

    LoadPfpGrid(GIRL_PFP_ASSETS)
end)

LoadPfpGrid(BOY_PFP_ASSETS)

local TagScrollFrame = Instance.new("ScrollingFrame")
TagScrollFrame.Name = "TagScrollFrame"
TagScrollFrame.Size = UDim2.new(1, 0, 0, 32)
TagScrollFrame.Position = UDim2.new(0, 0, 0, 105)
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
        tagStroke.Transparency = 0.5
        tagStroke.Parent = tagBtn

        tagBtn.MouseButton1Click:Connect(function()
            if setclipboard then setclipboard(roleName) end
            if MessageInput then
                MessageInput.Text = "!tag " .. roleName
            end
        end)
    end
end

PopulateTagBar()

local AboutInfoScroll = Instance.new("ScrollingFrame")
AboutInfoScroll.Name = "AboutInfoScroll"
AboutInfoScroll.Size = UDim2.new(1, 0, 0, 80)
AboutInfoScroll.Position = UDim2.new(0, 0, 0, 142)
AboutInfoScroll.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
AboutInfoScroll.BackgroundTransparency = 0.4
AboutInfoScroll.BorderSizePixel = 0
AboutInfoScroll.ScrollBarThickness = 3
AboutInfoScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 0, 0)
AboutInfoScroll.Parent = AboutFrame

local AboutInfoCorner = Instance.new("UICorner")
AboutInfoCorner.CornerRadius = UDim.new(0, 8)
AboutInfoCorner.Parent = AboutInfoScroll

local AboutTextLabel = Instance.new("TextLabel")
AboutTextLabel.Size = UDim2.new(1, -12, 0, 0)
AboutTextLabel.Position = UDim2.new(0, 6, 0, 6)
AboutTextLabel.AutomaticSize = Enum.AutomaticSize.Y
AboutTextLabel.BackgroundTransparency = 1
AboutTextLabel.Font = Enum.Font.Gotham
AboutTextLabel.TextSize = 11
AboutTextLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
AboutTextLabel.TextXAlignment = Enum.TextXAlignment.Left
AboutTextLabel.TextYAlignment = Enum.TextYAlignment.Top
AboutTextLabel.RichText = true
AboutTextLabel.TextWrapped = true
AboutTextLabel.Text = [[<b><font color='#FF3333' size='14'>KRONOS CHAT SYSTEM</font></b>
<font color='#888899'>Version 2.5 • Developed for Cross-Server Communication</font>

<b>[ CREDITS ]</b>
• <b>Architect</b>: Kabir_Priv
• <b>Stickers and Concept</b>: <font color='#FF0000'><b>ARES</b></font> / <font color='#800080'><b>Riser</b></font> / <font color='#FFD700'><b>Mickey</b></font> / <font color='#0000FF'><b>Orion</b></font>

<b>[ ABOUT SYSTEM ]</b>
KRONOS CHAT is a real-time cross-server chat infrastructure allowing seamless global and local server messaging with custom rank badges, stickers, privacy options, and instant requests.

<b>[ COMMANDS GUIDE ]</b>
• <b>!tag</b> : Toggle your custom tag display ON or OFF.
• <b>!tag [RoleName]</b> : Switch to another tag if you are in the permitted players list for that role.
• <b>!spoof [NewName]</b> : Change your chat Display Name.
• <b>!role [User] [Role]</b> : Assign roles (Restricted Permission).
• <b>/w [User] [Message]</b> : Send direct private messages.]]
AboutTextLabel.Parent = AboutInfoScroll

AboutTextLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
    AboutInfoScroll.CanvasSize = UDim2.new(0, 0, 0, AboutTextLabel.AbsoluteSize.Y + 16)
end)

local RequestContainer = Instance.new("Frame")
RequestContainer.Name = "RequestContainer"
RequestContainer.Size = UDim2.new(1, 0, 0, 48)
RequestContainer.Position = UDim2.new(0, 0, 0, 226)
RequestContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
RequestContainer.BackgroundTransparency = 0.4
RequestContainer.BorderSizePixel = 0
RequestContainer.Parent = AboutFrame

local RequestCorner = Instance.new("UICorner")
RequestCorner.CornerRadius = UDim.new(0, 8)
RequestCorner.Parent = RequestContainer

local RequestHeader = Instance.new("TextLabel")
RequestHeader.Size = UDim2.new(1, -10, 0, 14)
RequestHeader.Position = UDim2.new(0, 8, 0, 2)
RequestHeader.BackgroundTransparency = 1
RequestHeader.Font = Enum.Font.GothamBold
RequestHeader.Text = "SUBMIT TAG REQUEST / BUG REPORT"
RequestHeader.TextColor3 = Color3.fromRGB(255, 60, 60)
RequestHeader.TextSize = 9
RequestHeader.TextXAlignment = Enum.TextXAlignment.Left
RequestHeader.Parent = RequestContainer

local RequestInput = Instance.new("TextBox")
RequestInput.Name = "RequestInput"
RequestInput.Size = UDim2.new(1, -75, 0, 24)
RequestInput.Position = UDim2.new(0, 8, 0, 18)
RequestInput.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
RequestInput.BackgroundTransparency = 0.3
RequestInput.Font = Enum.Font.Gotham
RequestInput.PlaceholderText = "Type request..."
RequestInput.PlaceholderColor3 = Color3.fromRGB(130, 130, 140)
RequestInput.Text = ""
RequestInput.TextColor3 = Color3.fromRGB(240, 240, 250)
RequestInput.TextSize = 10
RequestInput.TextXAlignment = Enum.TextXAlignment.Left
RequestInput.ClearTextOnFocus = false
RequestInput.Parent = RequestContainer

local RequestInputCorner = Instance.new("UICorner")
RequestInputCorner.CornerRadius = UDim.new(0, 6)
RequestInputCorner.Parent = RequestInput

local SubmitRequestBtn = Instance.new("TextButton")
SubmitRequestBtn.Name = "SubmitRequestBtn"
SubmitRequestBtn.Size = UDim2.new(0, 60, 0, 24)
SubmitRequestBtn.Position = UDim2.new(1, -64, 0, 18)
SubmitRequestBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
SubmitRequestBtn.BackgroundTransparency = 0.2
SubmitRequestBtn.Font = Enum.Font.GothamBold
SubmitRequestBtn.Text = "SUBMIT"
SubmitRequestBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SubmitRequestBtn.TextSize = 9
SubmitRequestBtn.Parent = RequestContainer

local SubmitCorner = Instance.new("UICorner")
SubmitCorner.CornerRadius = UDim.new(0, 6)
SubmitCorner.Parent = SubmitRequestBtn

SubmitRequestBtn.MouseButton1Click:Connect(function()
    local text = RequestInput.Text
    if text == "" or text:match("^%s*$") then return end

    SubmitRequestBtn.Text = "..."
    SubmitRequestBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)

    local payload = {
        Username = LocalPlayer.Name,
        DisplayName = GetFormattedDisplayName(LocalPlayer.DisplayName, true),
        UserId = LocalPlayer.UserId,
        RequestText = text,
        Timestamp = os.time()
    }

    task.spawn(function()
        local res = HttpRequest(REQUEST_ENDPOINT, "POST", payload)
        if res then
            SubmitRequestBtn.Text = "SENT ✓"
            SubmitRequestBtn.BackgroundColor3 = Color3.fromRGB(30, 180, 80)
            RequestInput.Text = ""
        else
            SubmitRequestBtn.Text = "FAIL ✗"
            SubmitRequestBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
        end

        task.wait(2)
        SubmitRequestBtn.Text = "SUBMIT"
        SubmitRequestBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
    end)
end)

-- Input Setup
local InputBarFrame = Instance.new("Frame")
InputBarFrame.Name = "InputBarFrame"
InputBarFrame.Size = UDim2.new(1, -16, 0, 38)
InputBarFrame.Position = UDim2.new(0, 8, 1, -44)
InputBarFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
InputBarFrame.BackgroundTransparency = 0.4
InputBarFrame.BorderSizePixel = 0
InputBarFrame.Parent = MainFrame

local InputCorner = Instance.new("UICorner")
InputCorner.CornerRadius = UDim.new(0, 12)
InputCorner.Parent = InputBarFrame

MessageInput = Instance.new("TextBox")
MessageInput.Name = "MessageInput"
MessageInput.Size = UDim2.new(1, -95, 1, -8)
MessageInput.Position = UDim2.new(0, 10, 0, 4)
MessageInput.BackgroundTransparency = 1
MessageInput.Font = Enum.Font.GothamMedium
MessageInput.PlaceholderText = "Type !tag or !tag [TagName] / Longpress a Message for Options."
MessageInput.PlaceholderColor3 = Color3.fromRGB(150, 150, 160)
MessageInput.Text = ""
MessageInput.TextColor3 = Color3.fromRGB(240, 240, 245)
MessageInput.TextSize = 13
MessageInput.TextXAlignment = Enum.TextXAlignment.Left
MessageInput.ClearTextOnFocus = false
MessageInput.Parent = InputBarFrame

local StickerToggleButton = Instance.new("TextButton")
StickerToggleButton.Name = "StickerToggleButton"
StickerToggleButton.Size = UDim2.new(0, 34, 1, -8)
StickerToggleButton.Position = UDim2.new(1, -80, 0, 4)
StickerToggleButton.BackgroundColor3 = Color3.fromRGB(220, 30, 30)
StickerToggleButton.BackgroundTransparency = 0.2
StickerToggleButton.Font = Enum.Font.GothamBold
StickerToggleButton.Text = "😁"
StickerToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
StickerToggleButton.TextSize = 14
StickerToggleButton.Parent = InputBarFrame

local StickerToggleCorner = Instance.new("UICorner")
StickerToggleCorner.CornerRadius = UDim.new(0, 8)
StickerToggleCorner.Parent = StickerToggleButton

local emojiList = {"😁","😀","😉","🥰","🤩","🤗","😎","😥","😣","🤔","😫","🤤","😭","😨","😮‍💨","🤑"}
task.spawn(function()
    local idx = 1
    while true do
        task.wait(1)
        idx = (idx % #emojiList) + 1
        StickerToggleButton.Text = emojiList[idx]
    end
end)

StickerToggleButton.MouseButton1Click:Connect(function()
    StickerPanel.Visible = not StickerPanel.Visible
end)

local SendButton = Instance.new("TextButton")
SendButton.Name = "SendButton"
SendButton.Size = UDim2.new(0, 38, 1, -8)
SendButton.Position = UDim2.new(1, -42, 0, 4)
SendButton.BackgroundColor3 = Color3.fromRGB(220, 30, 30)
SendButton.BackgroundTransparency = 0.2
SendButton.Font = Enum.Font.GothamBold
SendButton.Text = ">"
SendButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SendButton.TextSize = 14
SendButton.Parent = InputBarFrame

local SendCorner = Instance.new("UICorner")
SendCorner.CornerRadius = UDim.new(0, 8)
SendCorner.Parent = SendButton

local AutoCompleteFrame = Instance.new("ScrollingFrame")
AutoCompleteFrame.Name = "AutoCompleteFrame"
AutoCompleteFrame.Size = UDim2.new(0, 200, 0, 120)
AutoCompleteFrame.Position = UDim2.new(0, 8, 1, -170)
AutoCompleteFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
AutoCompleteFrame.BackgroundTransparency = 0.2
AutoCompleteFrame.BorderSizePixel = 0
AutoCompleteFrame.ScrollBarThickness = 3
AutoCompleteFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 0, 0)
AutoCompleteFrame.Visible = false
AutoCompleteFrame.ZIndex = 30
AutoCompleteFrame.Parent = MainFrame

local AutoCompleteCorner = Instance.new("UICorner")
AutoCompleteCorner.CornerRadius = UDim.new(0, 8)
AutoCompleteCorner.Parent = AutoCompleteFrame

local AutoCompleteLayout = Instance.new("UIListLayout")
AutoCompleteLayout.SortOrder = Enum.SortOrder.LayoutOrder
AutoCompleteLayout.Padding = UDim.new(0, 2)
AutoCompleteLayout.Parent = AutoCompleteFrame

AutoCompleteLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    AutoCompleteFrame.CanvasSize = UDim2.new(0, 0, 0, AutoCompleteLayout.AbsoluteContentSize.Y + 6)
end)

local ContextMenu = Instance.new("Frame")
ContextMenu.Name = "ContextMenu"
ContextMenu.Size = UDim2.new(0, 160, 0, 105)
ContextMenu.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
ContextMenu.BackgroundTransparency = 0.2
ContextMenu.BorderSizePixel = 0
ContextMenu.Visible = false
ContextMenu.ZIndex = 20
ContextMenu.Parent = ScreenGui

local ContextCorner = Instance.new("UICorner")
ContextCorner.CornerRadius = UDim.new(0, 10)
ContextCorner.Parent = ContextMenu

local ContextList = Instance.new("UIListLayout")
ContextList.SortOrder = Enum.SortOrder.LayoutOrder
ContextList.Parent = ContextMenu

-- Draggable Logic
local function MakeDraggable(frame, dragHandle)
    local dragging, dragInput, dragStart, startPos
    dragHandle = dragHandle or frame

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)

    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

MakeDraggable(MainFrame, HeaderBar)

-- TAB NAVIGATION CONTROLLER
GlobalTabBtn.MouseButton1Click:Connect(function()
    ActiveTab = "GLOBAL"
    GlobalTabBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
    GlobalTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    GlobalTabBtn.BackgroundTransparency = 0.2

    ServerTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    ServerTabBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
    ServerTabBtn.BackgroundTransparency = 0.4

    AboutTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    AboutTabBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
    AboutTabBtn.BackgroundTransparency = 0.4

    MessageContainer.Visible = true
    AboutFrame.Visible = false
    InputBarFrame.Visible = true

    for _, v in pairs(ServerUIElements) do v.Visible = false end
    for _, v in pairs(GlobalUIElements) do v.Visible = true end
end)

ServerTabBtn.MouseButton1Click:Connect(function()
    ActiveTab = "SERVER"
    ServerTabBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
    ServerTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ServerTabBtn.BackgroundTransparency = 0.2

    GlobalTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    GlobalTabBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
    GlobalTabBtn.BackgroundTransparency = 0.4

    AboutTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    AboutTabBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
    AboutTabBtn.BackgroundTransparency = 0.4

    MessageContainer.Visible = true
    AboutFrame.Visible = false
    InputBarFrame.Visible = true

    for _, v in pairs(GlobalUIElements) do v.Visible = false end
    for _, v in pairs(ServerUIElements) do v.Visible = true end
end)

AboutTabBtn.MouseButton1Click:Connect(function()
    ActiveTab = "ABOUT"
    AboutTabBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
    AboutTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    AboutTabBtn.BackgroundTransparency = 0.2

    GlobalTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    GlobalTabBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
    GlobalTabBtn.BackgroundTransparency = 0.4

    ServerTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    ServerTabBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
    ServerTabBtn.BackgroundTransparency = 0.4

    MessageContainer.Visible = false
    AboutFrame.Visible = true
    InputBarFrame.Visible = false
end)

-- CONTEXT MENU COMPONENT
local CurrentContextMessageData = nil

local function CreateContextButton(text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 35)
    btn.BackgroundTransparency = 0.9
    btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamMedium
    btn.Text = "  " .. text
    btn.TextColor3 = Color3.fromRGB(220, 220, 230)
    btn.TextSize = 11
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = ContextMenu

    btn.MouseButton1Click:Connect(function()
        ContextMenu.Visible = false
        callback()
    end)
end

CreateContextButton("Reply / Whisper", function()
    if CurrentContextMessageData then
        MessageInput.Text = "/w " .. CurrentContextMessageData.Username .. " "
        MessageInput:CaptureFocus()
    end
end)

CreateContextButton("Copy Message", function()
    if CurrentContextMessageData and CurrentContextMessageData.Text then
        if setclipboard then setclipboard(CurrentContextMessageData.Text) end
    end
end)

CreateContextButton("Copy Username", function()
    if CurrentContextMessageData and CurrentContextMessageData.Username then
        if setclipboard then setclipboard(CurrentContextContextMessageData.Username) end
    end
end)

UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if ContextMenu.Visible then
            local pos = input.Position
            local guiPos = ContextMenu.AbsolutePosition
            local guiSize = ContextMenu.AbsoluteSize
            if pos.X < guiPos.X or pos.X > guiPos.X + guiSize.X or pos.Y < guiPos.Y or pos.Y > guiPos.Y + guiSize.Y then
                ContextMenu.Visible = false
            end
        end
    end
end)

-- AUTOCOMPLETE SYSTEM
MessageInput:GetPropertyChangedSignal("Text"):Connect(function()
    local text = MessageInput.Text
    local cursorWord = text:match("(%S+)$") or ""

    if cursorWord == "" or string.len(cursorWord) < 2 then
        AutoCompleteFrame.Visible = false
        return
    end

    for _, child in ipairs(AutoCompleteFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end

    local matches = {}
    for _, opt in ipairs(ALL_AUTOCOMPLETE_OPTIONS) do
        if string.sub(string.lower(opt), 1, string.len(cursorWord)) == string.lower(cursorWord) then
            table.insert(matches, opt)
        end
    end

    if #matches > 0 then
        AutoCompleteFrame.Visible = true
        for _, match in ipairs(matches) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 24)
            btn.BackgroundTransparency = 0.8
            btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            btn.Font = Enum.Font.GothamMedium
            btn.Text = "  " .. match
            btn.TextColor3 = Color3.fromRGB(240, 240, 250)
            btn.TextSize = 11
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.Parent = AutoCompleteFrame

            btn.MouseButton1Click:Connect(function()
                local baseText = text:sub(1, #text - #cursorWord)
                MessageInput.Text = baseText .. match .. " "
                AutoCompleteFrame.Visible = false
                MessageInput:CaptureFocus()
            end)
        end
    else
        AutoCompleteFrame.Visible = false
    end
end)

-- ============================================================================
-- RENDER CHAT CARD WITH CIRCULAR PFP & BADGE
-- ============================================================================
local function RenderChatMessage(msgData, isGlobal)
    local msgFrame = Instance.new("Frame")
    msgFrame.Name = "MessageCard"
    msgFrame.Size = UDim2.new(1, 0, 0, 0)
    msgFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    msgFrame.BackgroundTransparency = 0.4
    msgFrame.BorderSizePixel = 0
    msgFrame.AutomaticSize = Enum.AutomaticSize.Y
    msgFrame.Visible = (isGlobal and ActiveTab == "GLOBAL") or (not isGlobal and ActiveTab == "SERVER")
    msgFrame.Parent = MessageContainer

    local msgCorner = Instance.new("UICorner")
    msgCorner.CornerRadius = UDim.new(0, 8)
    msgCorner.Parent = msgFrame

    -- CIRCULAR CHAT PFP
    local chatPfpImg = Instance.new("ImageLabel")
    chatPfpImg.Name = "ChatPFP"
    chatPfpImg.Size = UDim2.new(0, 26, 0, 26)
    chatPfpImg.Position = UDim2.new(0, 6, 0, 6)
    chatPfpImg.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
    chatPfpImg.Image = msgData.PfpID or ("rbxthumb://type=AvatarHeadShot&id=" .. (msgData.UserId or 1) .. "&w=150&h=150")
    chatPfpImg.Parent = msgFrame

    local chatPfpCorner = Instance.new("UICorner")
    chatPfpCorner.CornerRadius = UDim.new(1, 0)
    chatPfpCorner.Parent = chatPfpImg

    local chatPfpStroke = Instance.new("UIStroke")
    chatPfpStroke.Thickness = 1
    chatPfpStroke.Color = Color3.fromRGB(255, 255, 255)
    chatPfpStroke.Transparency = 0.8
    chatPfpStroke.Parent = chatPfpImg

    local userRole = msgData.Role or GetAssignedOrCalculatedRole(msgData.Username)
    local style = RANK_STYLES[userRole] or {
        Start = Color3.fromRGB(200, 200, 200),
        End = Color3.fromRGB(100, 100, 100),
        Name = Color3.fromRGB(255, 255, 255),
        Speed = 1.0
    }

    local hideTag = DisabledTags[msgData.Username] or false
    local xOffset = 38

    if not hideTag then
        local tagBadge = Instance.new("Frame")
        tagBadge.Name = "RoleBadge"
        tagBadge.Size = UDim2.new(0, 0, 0, 18)
        tagBadge.Position = UDim2.new(0, xOffset, 0, 6)
        tagBadge.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
        tagBadge.AutomaticSize = Enum.AutomaticSize.X
        tagBadge.Parent = msgFrame

        local badgeCorner = Instance.new("UICorner")
        badgeCorner.CornerRadius = UDim.new(0, 4)
        badgeCorner.Parent = tagBadge

        local badgeStroke = Instance.new("UIStroke")
        badgeStroke.Thickness = 1
        badgeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        badgeStroke.Color = style.Start
        badgeStroke.Parent = tagBadge

        local badgeGradient = Instance.new("UIGradient")
        badgeGradient.Color = ColorSequence.new(style.Start, style.End)
        badgeGradient.Parent = badgeStroke

        local badgeText = Instance.new("TextLabel")
        badgeText.Name = "BadgeText"
        badgeText.Size = UDim2.new(0, 0, 1, 0)
        badgeText.AutomaticSize = Enum.AutomaticSize.X
        badgeText.BackgroundTransparency = 1
        badgeText.Font = Enum.Font.GothamBold
        badgeText.Text = "  " .. string.upper(userRole) .. "  "
        badgeText.TextColor3 = style.Start
        badgeText.TextSize = 9
        badgeText.Parent = tagBadge

        task.spawn(function()
            while tagBadge and tagBadge.Parent do
                local dt = RunService.RenderStepped:Wait()
                badgeGradient.Rotation = (badgeGradient.Rotation + ((style.Speed or 1) * 50 * dt)) % 360
            end
        end)

        xOffset = xOffset + tagBadge.AbsoluteSize.X + 6
        tagBadge:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            xOffset = 38 + tagBadge.AbsoluteSize.X + 6
        end)
    end

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(0, 0, 0, 18)
    nameLabel.Position = UDim2.new(0, xOffset, 0, 6)
    nameLabel.AutomaticSize = Enum.AutomaticSize.X
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamBold

    local rawDisplayName = msgData.DisplayName or msgData.Username or "Unknown"
    local isClientMsg = (msgData.Username == LocalPlayer.Name)
    nameLabel.Text = GetFormattedDisplayName(rawDisplayName, isClientMsg)
    nameLabel.TextColor3 = style.Name or Color3.fromRGB(255, 255, 255)
    nameLabel.TextSize = 11
    nameLabel.Parent = msgFrame

    local textContent = msgData.Text or ""
    local isSticker = string.sub(textContent, 1, 11) == "rbxthumb://" or string.sub(textContent, 1, 13) == "rbxassetid://"

    if isSticker then
        local stickerImg = Instance.new("ImageLabel")
        stickerImg.Name = "StickerImage"
        stickerImg.Size = UDim2.new(0, 80, 0, 80)
        stickerImg.Position = UDim2.new(0, 38, 0, 28)
        stickerImg.BackgroundTransparency = 1
        stickerImg.Image = textContent
        stickerImg.ScaleType = Enum.ScaleType.Fit
        stickerImg.Parent = msgFrame

        local paddingFrame = Instance.new("Frame")
        paddingFrame.Size = UDim2.new(1, 0, 0, 112)
        paddingFrame.BackgroundTransparency = 1
        paddingFrame.Parent = msgFrame
    else
        local messageText = Instance.new("TextLabel")
        messageText.Name = "MessageText"
        messageText.Size = UDim2.new(1, -46, 0, 0)
        messageText.Position = UDim2.new(0, 38, 0, 26)
        messageText.AutomaticSize = Enum.AutomaticSize.Y
        messageText.BackgroundTransparency = 1
        messageText.Font = Enum.Font.Gotham
        messageText.Text = textContent
        messageText.TextColor3 = msgData.IsPrivate and Color3.fromRGB(255, 100, 255) or Color3.fromRGB(230, 230, 240)
        messageText.TextSize = 11
        messageText.TextXAlignment = Enum.TextXAlignment.Left
        messageText.TextWrapped = true
        messageText.RichText = true
        messageText.Parent = msgFrame

        local bottomPadding = Instance.new("Frame")
        bottomPadding.Size = UDim2.new(1, 0, 0, 6)
        bottomPadding.Position = UDim2.new(0, 0, 1, 0)
        bottomPadding.BackgroundTransparency = 1
        bottomPadding.Parent = messageText
    end

    -- Long Press / Right Click for Context Menu
    local pressStart = 0
    msgFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            pressStart = tick()
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
            CurrentContextMessageData = msgData
            ContextMenu.Position = UDim2.new(0, input.Position.X, 0, input.Position.Y)
            ContextMenu.Visible = true
        end
    end)

    msgFrame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if tick() - pressStart >= 0.5 then
                CurrentContextMessageData = msgData
                ContextMenu.Position = UDim2.new(0, input.Position.X, 0, input.Position.Y)
                ContextMenu.Visible = true
            end
        end
    end)

    if isGlobal then
        table.insert(GlobalUIElements, msgFrame)
    else
        table.insert(ServerUIElements, msgFrame)
    end

    DisplayNewMessageNotif(msgData)
end

-- ============================================================================
-- MESSAGE DISPATCH & POLLING SYSTEM
-- ============================================================================
SendChatMessage = function()
    local text = MessageInput.Text
    if text == "" or text:match("^%s*$") then return end

    local now = tick()
    if now - LastMessageSendTime < 0.8 then
        return
    end

    if text == LastSentMessageText then
        ConsecutiveSpamCount = ConsecutiveSpamCount + 1
        if ConsecutiveSpamCount >= 3 then return end
    else
        ConsecutiveSpamCount = 0
    end

    LastSentMessageText = text
    LastMessageSendTime = now
    MessageInput.Text = ""

    -- COMMAND HANDLING
    if string.sub(text, 1, 4) == "!tag" then
        local arg = string.sub(text, 6)
        if arg == "" then
            DisabledTags[LocalPlayer.Name] = not DisabledTags[LocalPlayer.Name]
        else
            local allowed = AvailableUserRoles[LocalPlayer.Name] or {}
            if table.find(allowed, arg) or HasAdminPermission(LocalPlayer.Name) then
                AssignedPlayerRoles[LocalPlayer.Name] = arg
            end
        end
        return
    end

    if string.sub(text, 1, 6) == "!spoof" then
        if CanUseSpoof(LocalPlayer.Name) then
            local newName = string.sub(text, 8)
            SpoofedDisplayName = newName ~= "" and newName or nil
            RefreshProfileCard()
        end
        return
    end

    if string.sub(text, 1, 5) == "!role" then
        if HasAdminPermission(LocalPlayer.Name) then
            local target, role = text:match("^!role%s+(%S+)%s+(.+) Architectural$")
            if not target then target, role = text:match("^!role%s+(%S+)%s+(.+)$") end
            if target and role then
                AssignedPlayerRoles[target] = role
            end
        end
        return
    end

    local endpoint = (ActiveTab == "GLOBAL") and GLOBAL_MESSAGES_ENDPOINT or SERVER_MESSAGES_ENDPOINT
    local isPrivate = string.sub(text, 1, 3) == "/w "

    local payload = {
        Username = LocalPlayer.Name,
        DisplayName = GetFormattedDisplayName(LocalPlayer.DisplayName, true),
        UserId = LocalPlayer.UserId,
        Role = GetAssignedOrCalculatedRole(LocalPlayer.Name),
        Text = text,
        PfpID = CurrentSelectedPfpID,
        Timestamp = os.time(),
        IsPrivate = isPrivate
    }

    task.spawn(function()
        HttpRequest(endpoint, "POST", payload)
    end)
end

MessageInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then SendChatMessage() end
end)

SendButton.MouseButton1Click:Connect(SendChatMessage)

-- REALTIME POLLING LOOP
task.spawn(function()
    while true do
        FetchRemoteRankStyles()
        FetchRemoteRoles()

        -- Fetch Global Messages
        local globalData = HttpRequest(GLOBAL_MESSAGES_ENDPOINT, "GET")
        if globalData and type(globalData) == "table" then
            for key, msg in pairs(globalData) do
                if not GlobalCachedMessages[key] then
                    GlobalCachedMessages[key] = true
                    if (msg.Timestamp or 0) >= ScriptStartTime then
                        if not msg.IsPrivate or (msg.Text and msg.Text:find(LocalPlayer.Name)) or msg.Username == LocalPlayer.Name then
                            RenderChatMessage(msg, true)
                        end
                    end
                end
            end
        end

        -- Fetch Server Messages
        local serverData = HttpRequest(SERVER_MESSAGES_ENDPOINT, "GET")
        if serverData and type(serverData) == "table" then
            for key, msg in pairs(serverData) do
                if not ServerCachedMessages[key] then
                    ServerCachedMessages[key] = true
                    if (msg.Timestamp or 0) >= ScriptStartTime then
                        if not msg.IsPrivate or (msg.Text and msg.Text:find(LocalPlayer.Name)) or msg.Username == LocalPlayer.Name then
                            RenderChatMessage(msg, false)
                        end
                    end
                end
            end
        end

        task.wait(1.5)
    end
end)
