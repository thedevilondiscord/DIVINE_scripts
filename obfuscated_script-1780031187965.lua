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

-- ============================================================================
-- PERSISTENT PROFILE PICTURE SYSTEM SETUP
-- ============================================================================
local PFP_SAVE_KEY = "Kronos_UserPFP_AssetId"
local DefaultPfpId = "110388265928893"

local CurrentPfpId = (function()
    if readfile and isfile and isfile(PFP_SAVE_KEY .. ".txt") then
        local success, saved = pcall(function() return readfile(PFP_SAVE_KEY .. ".txt") end)
        if success and saved and saved ~= "" then return saved end
    end
    return DefaultPfpId
end)()

local function SavePfpIdLocally(assetId)
    CurrentPfpId = tostring(assetId)
    if writefile then
        pcall(function() writefile(PFP_SAVE_KEY .. ".txt", CurrentPfpId) end)
    end
end

local BoyPfpList = {
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

local GirlPfpList = {
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
    "rbxthumb://type=Asset&id=125983689093696&w=420&h=420",
    "rbxthumb://type=Asset&id=75506307767417&w=420&h=420",
    "rbxthumb://type=Asset&id=116836682474524&w=420&h=420",
    "rbxthumb://type=Asset&id=102568342129627&w=420&h=420",
    "rbxthumb://type=Asset&id=95097775871116&w=420&h=420",
    "rbxthumb://type=Asset&id=112745447456329&w=420&h=420",
    "rbxthumb://type=Asset&id=106977485921472&w=420&h=420",
    "rbxthumb://type=Asset&id=121310984106237&w=420&h=420",
    "rbxthumb://type=Asset&id=107564048134950&w=420&h=420",
    "rbxthumb://type=Asset&id=79650418792128&w=420&h=420",
    "rbxthumb://type=Asset&id=139765908340185&w=420&h=420",
    "rbxthumb://type=Asset&id=126499608563370&w=420&h=420",
    "rbxthumb://type=Asset&id=85967915168146&w=420&h=420",
    "rbxthumb://type=Asset&id=11484353402&w=420&h=420",
    "rbxthumb://type=Asset&id=128534124653098&w=420&h=420",
    "rbxthumb://type=Asset&id=77449075537615&w=420&h=420",
    "rbxthumb://type=Asset&id=90254884478832&w=420&h=420",
    "rbxthumb://type=Asset&id=123559079959222&w=420&h=420",
    "rbxthumb://type=Asset&id=9253566749&w=420&h=420",
    "rbxthumb://type=Asset&id=127674638208277&w=420&h=420",
    "rbxthumb://type=Asset&id=107949395268622&w=420&h=420",
    "rbxthumb://type=Asset&id=134008967452916&w=420&h=420",
    "rbxthumb://type=Asset&id=137895709516187&w=420&h=420",
    "rbxthumb://type=Asset&id=109694830487207&w=420&h=420",
    "rbxthumb://type=Asset&id=108796531608917&w=420&h=420",
    "rbxthumb://type=Asset&id=80436863872204&w=420&h=420",
    "rbxthumb://type=Asset&id=72997216799063&w=420&h=420",
    "rbxthumb://type=Asset&id=112896137773535&w=420&h=420",
    "rbxthumb://type=Asset&id=11600511955&w=420&h=420",
    "rbxthumb://type=Asset&id=124145396344946&w=420&h=420",
    "rbxthumb://type=Asset&id=124306223039740&w=420&h=420",
    "rbxthumb://type=Asset&id=130026784817133&w=420&h=420",
    "rbxthumb://type=Asset&id=78581194773132&w=420&h=420",
    "rbxthumb://type=Asset&id=100722574482118&w=420&h=420",
    "rbxthumb://type=Asset&id=137640259267057&w=420&h=420",
    "rbxthumb://type=Asset&id=113969372822195&w=420&h=420",
    "rbxthumb://type=Asset&id=140367998030901&w=420&h=420",
    "rbxthumb://type=Asset&id=120378246672337&w=420&h=420",
    "rbxthumb://type=Asset&id=116132850112023&w=420&h=420",
    "rbxthumb://type=Asset&id=87553190789546&w=420&h=420",
    "rbxthumb://type=Asset&id=9724585364&w=420&h=420",
    "rbxthumb://type=Asset&id=124047412639555&w=420&h=420",
    "rbxthumb://type=Asset&id=106808393141208&w=420&h=420",
    "rbxthumb://type=Asset&id=78606018239829&w=420&h=420",
    "rbxthumb://type=Asset&id=112484785272486&w=420&h=420",
    "rbxthumb://type=Asset&id=12727213926&w=420&h=420",
    "rbxthumb://type=Asset&id=98756307893472&w=420&h=420",
    "rbxthumb://type=Asset&id=78558780997877&w=420&h=420",
    "rbxthumb://type=Asset&id=126996930963081&w=420&h=420",
    "rbxthumb://type=Asset&id=115062400395026&w=420&h=420",
    "rbxthumb://type=Asset&id=90286953844894&w=420&h=420",
    "rbxthumb://type=Asset&id=73924170108274&w=420&h=420",
    "rbxthumb://type=Asset&id=111616336841381&w=420&h=420",
    "rbxthumb://type=Asset&id=112758420253845&w=420&h=420",
    "rbxthumb://type=Asset&id=126835535148309&w=420&h=420",
    "rbxthumb://type=Asset&id=93292021532883&w=420&h=420",
    "rbxthumb://type=Asset&id=130819442854007&w=420&h=420",
    "rbxthumb://type=Asset&id=138527421116380&w=420&h=420",
    "rbxthumb://type=Asset&id=107542712869273&w=420&h=420",
    "rbxthumb://type=Asset&id=107563628196607&w=420&h=420",
    "rbxthumb://type=Asset&id=9077479347&w=420&h=420",
    "rbxthumb://type=Asset&id=108283809544243&w=420&h=420",
    "rbxthumb://type=Asset&id=125437592584677&w=420&h=420",
    "rbxthumb://type=Asset&id=88450780656334&w=420&h=420",
    "rbxthumb://type=Asset&id=76757365751988&w=420&h=420",
    "rbxthumb://type=Asset&id=128965568153551&w=420&h=420",
    "rbxthumb://type=Asset&id=81437059666138&w=420&h=420",
    "rbxthumb://type=Asset&id=134676873059671&w=420&h=420",
    "rbxthumb://type=Asset&id=16780417621&w=420&h=420",
    "rbxthumb://type=Asset&id=81071566386630&w=420&h=420",
    "rbxthumb://type=Asset&id=100703525294618&w=420&h=420",
    "rbxthumb://type=Asset&id=86278563388796&w=420&h=420",
    "rbxthumb://type=Asset&id=87239554144904&w=420&h=420",
    "rbxthumb://type=Asset&id=129607195776931&w=420&h=420",
    "rbxthumb://type=Asset&id=99467189295335&w=420&h=420",
    "rbxthumb://type=Asset&id=106503865025496&w=420&h=420",
    "rbxthumb://type=Asset&id=71112430314329&w=420&h=420",
    "rbxthumb://type=Asset&id=98946997706325&w=420&h=420",
    "rbxthumb://type=Asset&id=95770046851932&w=420&h=420",
    "rbxthumb://type=Asset&id=73107616141016&w=420&h=420",
    "rbxthumb://type=Asset&id=117686693787446&w=420&h=420",
    "rbxthumb://type=Asset&id=15613479805&w=420&h=420",
    "rbxthumb://type=Asset&id=97531898393056&w=420&h=420",
    "rbxthumb://type=Asset&id=116963906560222&w=420&h=420",
    "rbxthumb://type=Asset&id=124962139890506&w=420&h=420",
    "rbxthumb://type=Asset&id=97109606724496&w=420&h=420",
    "rbxthumb://type=Asset&id=95541335353452&w=420&h=420",
    "rbxthumb://type=Asset&id=74143981281416&w=420&h=420",
    "rbxthumb://type=Asset&id=87427671653674&w=420&h=420",
    "rbxthumb://type=Asset&id=137157157388660&w=420&h=420",
    "rbxthumb://type=Asset&id=134368064124456&w=420&h=420",
    "rbxthumb://type=Asset&id=115496076924304&w=420&h=420",
    "rbxthumb://type=Asset&id=102923210652647&w=420&h=420",
    "rbxthumb://type=Asset&id=9703752867&w=420&h=420",
    "rbxthumb://type=Asset&id=17285946660&w=420&h=420",
    "rbxthumb://type=Asset&id=115766338835906&w=420&h=420",
    "rbxthumb://type=Asset&id=71036015366121&w=420&h=420",
    "rbxthumb://type=Asset&id=87693756574279&w=420&h=420",
    "rbxthumb://type=Asset&id=107639548994590&w=420&h=420",
    "rbxthumb://type=Asset&id=123881607288205&w=420&h=420",
    "rbxthumb://type=Asset&id=105612301516352&w=420&h=420",
    "rbxthumb://type=Asset&id=117799232246450&w=420&h=420",
    "rbxthumb://type=Asset&id=137162029636088&w=420&h=420",
    "rbxthumb://type=Asset&id=96967420548620&w=420&h=420",
    "rbxthumb://type=Asset&id=119307188585682&w=420&h=420",
    "rbxthumb://type=Asset&id=109467891240625&w=420&h=420",
    "rbxthumb://type=Asset&id=126255767092322&w=420&h=420",
    "rbxthumb://type=Asset&id=12604237076&w=420&h=420",
    "rbxthumb://type=Asset&id=91059306531671&w=420&h=420",
    "rbxthumb://type=Asset&id=186505196&w=420&h=420",
    "rbxthumb://type=Asset&id=113540856419753&w=420&h=420",
    "rbxthumb://type=Asset&id=77982313163011&w=420&h=420",
    "rbxthumb://type=Asset&id=136413255954959&w=420&h=420",
    "rbxthumb://type=Asset&id=97878152712841&w=420&h=420",
    "rbxthumb://type=Asset&id=10851678031&w=420&h=420",
    "rbxthumb://type=Asset&id=107712985832036&w=420&h=420",
    "rbxthumb://type=Asset&id=89724301020249&w=420&h=420",
    "rbxthumb://type=Asset&id=15228440984&w=420&h=420",
    "rbxthumb://type=Asset&id=123774516974893&w=420&h=420",
    "rbxthumb://type=Asset&id=101322904869821&w=420&h=420",
    "rbxthumb://type=Asset&id=124967996816135&w=420&h=420",
    "rbxthumb://type=Asset&id=96486531955234&w=420&h=420",
    "rbxthumb://type=Asset&id=129040222524985&w=420&h=420",
    "rbxthumb://type=Asset&id=110742598347676&w=420&h=420",
    "rbxthumb://type=Asset&id=6892957089&w=420&h=420",
    "rbxthumb://type=Asset&id=86402817297314&w=420&h=420",
    "rbxthumb://type=Asset&id=11123209169&w=420&h=420",
    "rbxthumb://type=Asset&id=122820594186443&w=420&h=420",
    "rbxthumb://type=Asset&id=105698532231334&w=420&h=420",
    "rbxthumb://type=Asset&id=114620995901131&w=420&h=420",
    "rbxthumb://type=Asset&id=85407192167743&w=420&h=420",
    "rbxthumb://type=Asset&id=98702128731326&w=420&h=420",
    "rbxthumb://type=Asset&id=102113722816584&w=420&h=420",
    "rbxthumb://type=Asset&id=83606808239727&w=420&h=420",
    "rbxthumb://type=Asset&id=94283114531364&w=420&h=420",
    "rbxthumb://type=Asset&id=9589322578&w=420&h=420",
    "rbxthumb://type=Asset&id=76312255766028&w=420&h=420",
    "rbxthumb://type=Asset&id=83060513543110&w=420&h=420",
    "rbxthumb://type=Asset&id=136887113512942&w=420&h=420",
    "rbxthumb://type=Asset&id=135700976643537&w=420&h=420",
    "rbxthumb://type=Asset&id=106330502110486&w=420&h=420",
    "rbxthumb://type=Asset&id=75030286063678&w=420&h=420",
    "rbxthumb://type=Asset&id=14750467200&w=420&h=420",
    "rbxthumb://type=Asset&id=91965007204396&w=420&h=420",
    "rbxthumb://type=Asset&id=128748009633926&w=420&h=420",
    "rbxthumb://type=Asset&id=169900042&w=420&h=420",
    "rbxthumb://type=Asset&id=72793460663497&w=420&h=420",
    "rbxthumb://type=Asset&id=140484578433196&w=420&h=420",
    "rbxthumb://type=Asset&id=112907096812107&w=420&h=420",
    "rbxthumb://type=Asset&id=92850410471479&w=420&h=420",
    "rbxthumb://type=Asset&id=130605412870116&w=420&h=420",
    "rbxthumb://type=Asset&id=75588875972100&w=420&h=420",
    "rbxthumb://type=Asset&id=134202774319269&w=420&h=420",
    "rbxthumb://type=Asset&id=84718406053016&w=420&h=420",
    "rbxthumb://type=Asset&id=96930545429149&w=420&h=420",
    "rbxthumb://type=Asset&id=17343896730&w=420&h=420",
    "rbxthumb://type=Asset&id=71442089462191&w=420&h=420",
    "rbxthumb://type=Asset&id=99802803824359&w=420&h=420",
    "rbxthumb://type=Asset&id=100982607210447&w=420&h=420",
    "rbxthumb://type=Asset&id=6158261961&w=420&h=420",
    "rbxthumb://type=Asset&id=99340040246135&w=420&h=420",
    "rbxthumb://type=Asset&id=29347007&w=420&h=420",
    "rbxthumb://type=Asset&id=133801475498371&w=420&h=420",
    "rbxthumb://type=Asset&id=15757126814&w=420&h=420",
    "rbxthumb://type=Asset&id=129493127513840&w=420&h=420",
    "rbxthumb://type=Asset&id=134238049027906&w=420&h=420",
    "rbxthumb://type=Asset&id=90357041968118&w=420&h=420",
    "rbxthumb://type=Asset&id=116671713835756&w=420&h=420",
    "rbxthumb://type=Asset&id=360554424&w=420&h=420",
    "rbxthumb://type=Asset&id=72982331023306&w=420&h=420",
    "rbxthumb://type=Asset&id=77115548103922&w=420&h=420",
    "rbxthumb://type=Asset&id=6892957751&w=420&h=420",
    "rbxthumb://type=Asset&id=95112780943766&w=420&h=420"
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

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 450, 0, 320)
MainFrame.Position = UDim2.new(0.02, 0, 0.55, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
MainFrame.BackgroundTransparency = 0.35
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = false
MainFrame.Parent = ScreenGui

-- DRAGGABLE IMPLEMENTATION FOR MAIN FRAME
local draggingMain, dragInputMain, dragStartMain, startPosMain
local function updateMain(input)
    local delta = input.Position - dragStartMain
    MainFrame.Position = UDim2.new(startPosMain.X.Scale, startPosMain.X.Offset + delta.X, startPosMain.Y.Scale, startPosMain.Y.Offset + delta.Y)
end

MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingMain = true
        dragStartMain = input.Position
        startPosMain = MainFrame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                draggingMain = false
            end
        end)
    end
end)

MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInputMain = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInputMain and draggingMain then
        updateMain(input)
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
GlobalTabBtn.Position = UDim2.new(0, 6, 0, 5)
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
ServerTabBtn.Size = UDim2.new(0, 65, 0, 26)
ServerTabBtn.Position = UDim2.new(0, 75, 0, 5)
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

local ProfileTabBtn = Instance.new("TextButton")
ProfileTabBtn.Name = "ProfileTabBtn"
ProfileTabBtn.Size = UDim2.new(0, 65, 0, 26)
ProfileTabBtn.Position = UDim2.new(0, 144, 0, 5)
ProfileTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
ProfileTabBtn.BackgroundTransparency = 0.4
ProfileTabBtn.Font = Enum.Font.GothamBold
ProfileTabBtn.Text = "PROFILE"
ProfileTabBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
ProfileTabBtn.TextSize = 10
ProfileTabBtn.Parent = HeaderBar

local ProfileTabCorner = Instance.new("UICorner")
ProfileTabCorner.CornerRadius = UDim.new(0, 8)
ProfileTabCorner.Parent = ProfileTabBtn

local AboutTabBtn = Instance.new("TextButton")
AboutTabBtn.Name = "AboutTabBtn"
AboutTabBtn.Size = UDim2.new(0, 60, 0, 26)
AboutTabBtn.Position = UDim2.new(0, 213, 0, 5)
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

-- DRAGGABLE IMPLEMENTATION FOR TOGGLE BUTTON
local draggingToggle, dragInputToggle, dragStartToggle, startPosToggle
local function updateToggle(input)
    local delta = input.Position - dragStartToggle
    ToggleButton.Position = UDim2.new(startPosToggle.X.Scale, startPosToggle.X.Offset + delta.X, startPosToggle.Y.Scale, startPosToggle.Y.Offset + delta.Y)
end

ToggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingToggle = true
        dragStartToggle = input.Position
        startPosToggle = ToggleButton.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                draggingToggle = false
            end
        end)
    end
end)

ToggleButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInputToggle = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInputToggle and draggingToggle then
        updateToggle(input)
    end
end)

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

-- ============================================================================
-- PROFILE TAB IMPLEMENTATION
-- ============================================================================
local ProfileFrame = Instance.new("Frame")
ProfileFrame.Name = "ProfileFrame"
ProfileFrame.Size = UDim2.new(1, -16, 1, -48)
ProfileFrame.Position = UDim2.new(0, 8, 0, 40)
ProfileFrame.BackgroundTransparency = 1
ProfileFrame.Visible = false
ProfileFrame.Parent = MainFrame

local PreviewCard = Instance.new("Frame")
PreviewCard.Size = UDim2.new(1, 0, 0, 50)
PreviewCard.Position = UDim2.new(0, 0, 0, 0)
PreviewCard.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
PreviewCard.BackgroundTransparency = 0.4
PreviewCard.BorderSizePixel = 0
PreviewCard.Parent = ProfileFrame

local PreviewCorner = Instance.new("UICorner")
PreviewCorner.CornerRadius = UDim.new(0, 8)
PreviewCorner.Parent = PreviewCard

local CurrentPfpImg = Instance.new("ImageLabel")
CurrentPfpImg.Size = UDim2.new(0, 40, 0, 40)
CurrentPfpImg.Position = UDim2.new(0, 5, 0, 5)
CurrentPfpImg.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
CurrentPfpImg.Image = "rbxthumb://type=Asset&id=" .. CurrentPfpId .. "&w=150&h=150"
CurrentPfpImg.Parent = PreviewCard

local PfpCorner = Instance.new("UICorner")
PfpCorner.CornerRadius = UDim.new(1, 0)
PfpCorner.Parent = CurrentPfpImg

local PfpStroke = Instance.new("UIStroke")
PfpStroke.Thickness = 1.5
PfpStroke.Color = Color3.fromRGB(255, 0, 0)
PfpStroke.Parent = CurrentPfpImg

local PreviewText = Instance.new("TextLabel")
PreviewText.Size = UDim2.new(1, -55, 1, 0)
PreviewText.Position = UDim2.new(0, 50, 0, 0)
PreviewText.BackgroundTransparency = 1
PreviewText.Font = Enum.Font.GothamBold
PreviewText.Text = "ACTIVE PROFILE PICTURE\nID: " .. CurrentPfpId
PreviewText.TextColor3 = Color3.fromRGB(240, 240, 250)
PreviewText.TextSize = 10
PreviewText.TextXAlignment = Enum.TextXAlignment.Left
PreviewText.Parent = PreviewCard

local CustomPfpInput = Instance.new("TextBox")
CustomPfpInput.Size = UDim2.new(1, -90, 0, 24)
CustomPfpInput.Position = UDim2.new(0, 0, 0, 55)
CustomPfpInput.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
CustomPfpInput.BackgroundTransparency = 0.3
CustomPfpInput.Font = Enum.Font.Gotham
CustomPfpInput.PlaceholderText = "Paste Custom Asset ID / Code..."
CustomPfpInput.PlaceholderColor3 = Color3.fromRGB(130, 130, 140)
CustomPfpInput.Text = ""
CustomPfpInput.TextColor3 = Color3.fromRGB(255, 255, 255)
CustomPfpInput.TextSize = 10
CustomPfpInput.Parent = ProfileFrame

local CustomInputCorner = Instance.new("UICorner")
CustomInputCorner.CornerRadius = UDim.new(0, 6)
CustomInputCorner.Parent = CustomPfpInput

local ApplyCustomBtn = Instance.new("TextButton")
ApplyCustomBtn.Size = UDim2.new(0, 85, 0, 24)
ApplyCustomBtn.Position = UDim2.new(1, -85, 0, 55)
ApplyCustomBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
ApplyCustomBtn.BackgroundTransparency = 0.2
ApplyCustomBtn.Font = Enum.Font.GothamBold
ApplyCustomBtn.Text = "APPLY CODE"
ApplyCustomBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ApplyCustomBtn.TextSize = 9
ApplyCustomBtn.Parent = ProfileFrame

local ApplyCustomCorner = Instance.new("UICorner")
ApplyCustomCorner.CornerRadius = UDim.new(0, 6)
ApplyCustomCorner.Parent = ApplyCustomBtn

local PfpScroll = Instance.new("ScrollingFrame")
PfpScroll.Size = UDim2.new(1, 0, 0, 185)
PfpScroll.Position = UDim2.new(0, 0, 0, 85)
PfpScroll.BackgroundTransparency = 1
PfpScroll.BorderSizePixel = 0
PfpScroll.ScrollBarThickness = 3
PfpScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 0, 0)
PfpScroll.Parent = ProfileFrame

local PfpListLayout = Instance.new("UIListLayout")
PfpListLayout.SortOrder = Enum.SortOrder.LayoutOrder
PfpListLayout.Padding = UDim.new(0, 8)
PfpListLayout.Parent = PfpScroll

PfpListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    PfpScroll.CanvasSize = UDim2.new(0, 0, 0, PfpListLayout.AbsoluteContentSize.Y + 10)
end)

local function UpdatePfpSelection(assetId)
    SavePfpIdLocally(assetId)
    CurrentPfpImg.Image = "rbxthumb://type=Asset&id=" .. tostring(assetId) .. "&w=150&h=150"
    PreviewText.Text = "ACTIVE PROFILE PICTURE\nID: " .. tostring(assetId)
end

ApplyCustomBtn.MouseButton1Click:Connect(function()
    local text = CustomPfpInput.Text:match("%d+")
    if text then
        UpdatePfpSelection(text)
        CustomPfpInput.Text = ""
    end
end)

local function BuildPfpSection(title, list, layoutOrder)
    local SecFrame = Instance.new("Frame")
    SecFrame.Size = UDim2.new(1, 0, 0, 0)
    SecFrame.AutomaticSize = Enum.AutomaticSize.Y
    SecFrame.BackgroundTransparency = 1
    SecFrame.LayoutOrder = layoutOrder
    SecFrame.Parent = PfpScroll

    local Header = Instance.new("TextLabel")
    Header.Size = UDim2.new(1, 0, 0, 18)
    Header.BackgroundTransparency = 1
    Header.Font = Enum.Font.GothamBold
    Header.Text = title
    Header.TextColor3 = Color3.fromRGB(255, 60, 60)
    Header.TextSize = 11
    Header.TextXAlignment = Enum.TextXAlignment.Left
    Header.Parent = SecFrame

    local Grid = Instance.new("Frame")
    Grid.Size = UDim2.new(1, 0, 0, 0)
    Grid.Position = UDim2.new(0, 0, 0, 20)
    Grid.AutomaticSize = Enum.AutomaticSize.Y
    Grid.BackgroundTransparency = 1
    Grid.Parent = SecFrame

    local GridLayout = Instance.new("UIGridLayout")
    GridLayout.CellSize = UDim2.new(0, 42, 0, 42)
    GridLayout.CellPadding = UDim2.new(0, 6, 0, 6)
    GridLayout.Parent = Grid

    for _, id in ipairs(list) do
        local btn = Instance.new("ImageButton")
        btn.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
        btn.Image = "rbxthumb://type=Asset&id=" .. id .. "&w=150&h=150"
        btn.Parent = Grid

        local bCorner = Instance.new("UICorner")
        bCorner.CornerRadius = UDim.new(0, 8)
        bCorner.Parent = btn

        local bStroke = Instance.new("UIStroke")
        bStroke.Thickness = 1
        bStroke.Color = Color3.fromRGB(255, 255, 255)
        bStroke.Transparency = 0.8
        bStroke.Parent = btn

        btn.MouseButton1Click:Connect(function()
            UpdatePfpSelection(id)
        end)
    end
end

BuildPfpSection("HIS PFP CHOICES", BoyPfpList, 1)
BuildPfpSection("HER PFP CHOICES", GirlPfpList, 2)

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
AboutInfoScroll.Size = UDim2.new(1, 0, 0, 125)
AboutInfoScroll.Position = UDim2.new(0, 0, 0, 42)
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
RequestContainer.Size = UDim2.new(1, 0, 0, 98)
RequestContainer.Position = UDim2.new(0, 0, 0, 172)
RequestContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
RequestContainer.BackgroundTransparency = 0.4
RequestContainer.BorderSizePixel = 0
RequestContainer.Parent = AboutFrame

local RequestCorner = Instance.new("UICorner")
RequestCorner.CornerRadius = UDim.new(0, 8)
RequestCorner.Parent = RequestContainer

local RequestHeader = Instance.new("TextLabel")
RequestHeader.Size = UDim2.new(1, -10, 0, 18)
RequestHeader.Position = UDim2.new(0, 8, 0, 4)
RequestHeader.BackgroundTransparency = 1
RequestHeader.Font = Enum.Font.GothamBold
RequestHeader.Text = "SUBMIT TAG REQUEST / SUGGESTION"
RequestHeader.TextColor3 = Color3.fromRGB(255, 60, 60)
RequestHeader.TextSize = 10
RequestHeader.TextXAlignment = Enum.TextXAlignment.Left
RequestHeader.Parent = RequestContainer

local RequestInput = Instance.new("TextBox")
RequestInput.Name = "RequestInput"
RequestInput.Size = UDim2.new(1, -16, 0, 44)
RequestInput.Position = UDim2.new(0, 8, 0, 22)
RequestInput.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
RequestInput.BackgroundTransparency = 0.3
RequestInput.Font = Enum.Font.Gotham
RequestInput.PlaceholderText = "Enter your custom tag request or bug report..."
RequestInput.PlaceholderColor3 = Color3.fromRGB(130, 130, 140)
RequestInput.Text = ""
RequestInput.TextColor3 = Color3.fromRGB(240, 240, 250)
RequestInput.TextSize = 11
RequestInput.TextXAlignment = Enum.TextXAlignment.Left
RequestInput.TextYAlignment = Enum.TextYAlignment.Top
RequestInput.ClearTextOnFocus = false
RequestInput.TextWrapped = true
RequestInput.Parent = RequestContainer

local RequestInputCorner = Instance.new("UICorner")
RequestInputCorner.CornerRadius = UDim.new(0, 6)
RequestInputCorner.Parent = RequestInput

local SendRequestBtn = Instance.new("TextButton")
SendRequestBtn.Name = "SendRequestBtn"
SendRequestBtn.Size = UDim2.new(1, -16, 0, 22)
SendRequestBtn.Position = UDim2.new(0, 8, 0, 70)
SendRequestBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
SendRequestBtn.BackgroundTransparency = 0.2
SendRequestBtn.Font = Enum.Font.GothamBold
SendRequestBtn.Text = "SEND REQUEST"
SendRequestBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SendRequestBtn.TextSize = 10
SendRequestBtn.Parent = RequestContainer

local SendRequestCorner = Instance.new("UICorner")
SendRequestCorner.CornerRadius = UDim.new(0, 6)
SendRequestCorner.Parent = SendRequestBtn

SendRequestBtn.MouseButton1Click:Connect(function()
    local text = RequestInput.Text
    if text and text:match("%S") then
        local payload = {
            Username = LocalPlayer.Name,
            DisplayName = LocalPlayer.DisplayName,
            UserId = LocalPlayer.UserId,
            Request = text,
            Time = os.time()
        }
        task.spawn(function()
            HttpRequest(REQUEST_ENDPOINT, "POST", payload)
        end)
        RequestInput.Text = ""
        SendRequestBtn.Text = "SENT SUCCESSFULLY!"
        task.wait(1.5)
        SendRequestBtn.Text = "SEND REQUEST"
    end
end)

-- Tab Switcher Logic
local function SwitchTab(tabName)
    ActiveTab = tabName
    if tabName == "GLOBAL" then
        GlobalTabBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
        GlobalTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        ServerTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        ServerTabBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
        ProfileTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        ProfileTabBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
        AboutTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        AboutTabBtn.TextColor3 = Color3.fromRGB(180, 180, 190)

        MessageContainer.Visible = true
        ProfileFrame.Visible = false
        AboutFrame.Visible = false

        for _, el in pairs(ServerUIElements) do el.Visible = false end
        for _, el in pairs(GlobalUIElements) do el.Visible = true end
    elseif tabName == "SERVER" then
        ServerTabBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
        ServerTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        GlobalTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        GlobalTabBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
        ProfileTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        ProfileTabBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
        AboutTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        AboutTabBtn.TextColor3 = Color3.fromRGB(180, 180, 190)

        MessageContainer.Visible = true
        ProfileFrame.Visible = false
        AboutFrame.Visible = false

        for _, el in pairs(GlobalUIElements) do el.Visible = false end
        for _, el in pairs(ServerUIElements) do el.Visible = true end
    elseif tabName == "PROFILE" then
        ProfileTabBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
        ProfileTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        GlobalTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        GlobalTabBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
        ServerTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        ServerTabBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
        AboutTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        AboutTabBtn.TextColor3 = Color3.fromRGB(180, 180, 190)

        MessageContainer.Visible = false
        ProfileFrame.Visible = true
        AboutFrame.Visible = false
        StickerPanel.Visible = false
    elseif tabName == "ABOUT" then
        AboutTabBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
        AboutTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        GlobalTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        GlobalTabBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
        ServerTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        ServerTabBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
        ProfileTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        ProfileTabBtn.TextColor3 = Color3.fromRGB(180, 180, 190)

        MessageContainer.Visible = false
        ProfileFrame.Visible = false
        AboutFrame.Visible = true
        StickerPanel.Visible = false
    end
end

GlobalTabBtn.MouseButton1Click:Connect(function() SwitchTab("GLOBAL") end)
ServerTabBtn.MouseButton1Click:Connect(function() SwitchTab("SERVER") end)
ProfileTabBtn.MouseButton1Click:Connect(function() SwitchTab("PROFILE") end)
AboutTabBtn.MouseButton1Click:Connect(function() SwitchTab("ABOUT") end)

-- Input Panel Components
local FooterBar = Instance.new("Frame")
FooterBar.Name = "FooterBar"
FooterBar.Size = UDim2.new(1, -16, 0, 38)
FooterBar.Position = UDim2.new(0, 8, 1, -44)
FooterBar.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
FooterBar.BackgroundTransparency = 0.3
FooterBar.BorderSizePixel = 0
FooterBar.Parent = MainFrame

local FooterCorner = Instance.new("UICorner")
FooterCorner.CornerRadius = UDim.new(0, 10)
FooterCorner.Parent = FooterBar

local StickerToggleBtn = Instance.new("TextButton")
StickerToggleBtn.Name = "StickerToggleBtn"
StickerToggleBtn.Size = UDim2.new(0, 32, 0, 28)
StickerToggleBtn.Position = UDim2.new(0, 5, 0, 5)
StickerToggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
StickerToggleBtn.BackgroundTransparency = 0.3
StickerToggleBtn.Font = Enum.Font.GothamBold
StickerToggleBtn.Text = "📌"
StickerToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
StickerToggleBtn.TextSize = 14
StickerToggleBtn.Parent = FooterBar

local StickerToggleCorner = Instance.new("UICorner")
StickerToggleCorner.CornerRadius = UDim.new(0, 8)
StickerToggleCorner.Parent = StickerToggleBtn

StickerToggleBtn.MouseButton1Click:Connect(function()
    StickerPanel.Visible = not StickerPanel.Visible
end)

MessageInput = Instance.new("TextBox")
MessageInput.Name = "MessageInput"
MessageInput.Size = UDim2.new(1, -112, 0, 28)
MessageInput.Position = UDim2.new(0, 42, 0, 5)
MessageInput.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
MessageInput.BackgroundTransparency = 0.3
MessageInput.Font = Enum.Font.Gotham
MessageInput.PlaceholderText = "Type a message or /w Username..."
MessageInput.PlaceholderColor3 = Color3.fromRGB(120, 120, 130)
MessageInput.Text = ""
MessageInput.TextColor3 = Color3.fromRGB(255, 255, 255)
MessageInput.TextSize = 11
MessageInput.TextXAlignment = Enum.TextXAlignment.Left
MessageInput.ClearTextOnFocus = false
MessageInput.Parent = FooterBar

local InputCorner = Instance.new("UICorner")
InputCorner.CornerRadius = UDim.new(0, 8)
InputCorner.Parent = MessageInput

local InputPadding = Instance.new("UIPadding")
InputPadding.PaddingLeft = UDim.new(0, 8)
InputPadding.PaddingRight = UDim.new(0, 8)
InputPadding.Parent = MessageInput

local SendButton = Instance.new("TextButton")
SendButton.Name = "SendButton"
SendButton.Size = UDim2.new(0, 60, 0, 28)
SendButton.Position = UDim2.new(1, -65, 0, 5)
SendButton.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
SendButton.BackgroundTransparency = 0.2
SendButton.Font = Enum.Font.GothamBold
SendButton.Text = "SEND"
SendButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SendButton.TextSize = 10
SendButton.Parent = FooterBar

local SendCorner = Instance.new("UICorner")
SendCorner.CornerRadius = UDim.new(0, 8)
SendCorner.Parent = SendButton

-- Autocomplete Popup
local AutocompleteFrame = Instance.new("Frame")
AutocompleteFrame.Name = "AutocompleteFrame"
AutocompleteFrame.Size = UDim2.new(0, 180, 0, 100)
AutocompleteFrame.Position = UDim2.new(0, 42, 0, -105)
AutocompleteFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
AutocompleteFrame.BackgroundTransparency = 0.2
AutocompleteFrame.BorderSizePixel = 0
AutocompleteFrame.Visible = false
AutocompleteFrame.ZIndex = 50
AutocompleteFrame.Parent = FooterBar

local AutoCorner = Instance.new("UICorner")
AutoCorner.CornerRadius = UDim.new(0, 8)
AutoCorner.Parent = AutocompleteFrame

local AutoStroke = Instance.new("UIStroke")
AutoStroke.Thickness = 1
AutoStroke.Color = Color3.fromRGB(200, 30, 30)
AutoStroke.Parent = AutocompleteFrame

local AutoScroller = Instance.new("ScrollingFrame")
AutoScroller.Size = UDim2.new(1, -4, 1, -4)
AutoScroller.Position = UDim2.new(0, 2, 0, 2)
AutoScroller.BackgroundTransparency = 1
AutoScroller.BorderSizePixel = 0
AutoScroller.ScrollBarThickness = 3
AutoScroller.ScrollBarImageColor3 = Color3.fromRGB(200, 30, 30)
AutoScroller.ZIndex = 51
AutoScroller.Parent = AutocompleteFrame

local AutoLayout = Instance.new("UIListLayout")
AutoLayout.SortOrder = Enum.SortOrder.LayoutOrder
AutoLayout.Padding = UDim.new(0, 2)
AutoLayout.Parent = AutoScroller

AutoLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    AutoScroller.CanvasSize = UDim2.new(0, 0, 0, AutoLayout.AbsoluteContentSize.Y + 4)
end)

local function UpdateAutocomplete()
    local currentText = MessageInput.Text
    local words = string.split(currentText, " ")
    local lastWord = words[#words] or ""

    for _, child in ipairs(AutoScroller:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end

    if string.len(lastWord) > 0 then
        local matches = {}
        for _, option in ipairs(ALL_AUTOCOMPLETE_OPTIONS) do
            if string.find(string.lower(option), string.lower(lastWord), 1, true) then
                table.insert(matches, option)
            end
        end

        if #matches > 0 then
            AutocompleteFrame.Visible = true
            for _, match in ipairs(matches) do
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, 0, 0, 20)
                btn.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
                btn.BackgroundTransparency = 0.4
                btn.Font = Enum.Font.Gotham
                btn.Text = " " .. match
                btn.TextColor3 = Color3.fromRGB(220, 220, 230)
                btn.TextSize = 10
                btn.TextXAlignment = Enum.TextXAlignment.Left
                btn.ZIndex = 52
                btn.Parent = AutoScroller

                local bCorner = Instance.new("UICorner")
                bCorner.CornerRadius = UDim.new(0, 4)
                bCorner.Parent = btn

                btn.MouseButton1Click:Connect(function()
                    words[#words] = match
                    MessageInput.Text = table.concat(words, " ") .. " "
                    MessageInput.CursorPosition = string.len(MessageInput.Text) + 1
                    AutocompleteFrame.Visible = false
                end)
            end
            return
        end
    end
    AutocompleteFrame.Visible = false
end

MessageInput:GetPropertyChangedSignal("Text"):Connect(UpdateAutocomplete)

-- ============================================================================
-- RENDER MESSAGE CARD WITH ANIMATED BADGES
-- ============================================================================
local function CreateMessageCard(msgData)
    local card = Instance.new("Frame")
    card.Name = "MessageCard"
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = msgData.IsPrivate and Color3.fromRGB(35, 15, 25) or Color3.fromRGB(15, 15, 22)
    card.BackgroundTransparency = 0.4
    card.BorderSizePixel = 0
    card.LayoutOrder = msgData.Timestamp or os.time()

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 8)
    cardCorner.Parent = card

    local pfpImg = Instance.new("ImageLabel")
    pfpImg.Name = "PfpImage"
    pfpImg.Size = UDim2.new(0, 28, 0, 28)
    pfpImg.Position = UDim2.new(0, 6, 0, 6)
    pfpImg.BackgroundColor3 = Color3.fromRGB(25, 25, 35)

    local pfpAsset = msgData.PfpId or DefaultPfpId
    pfpImg.Image = "rbxthumb://type=Asset&id=" .. pfpAsset .. "&w=150&h=150"
    pfpImg.Parent = card

    local pfpCorner = Instance.new("UICorner")
    pfpCorner.CornerRadius = UDim.new(1, 0)
    pfpCorner.Parent = pfpImg

    local roleName = msgData.Role or GetAssignedOrCalculatedRole(msgData.Username)
    local rankStyle = RANK_STYLES[roleName] or RANK_STYLES["VIP"]

    local roleBadge = Instance.new("Frame")
    roleBadge.Name = "RoleBadge"
    roleBadge.AutomaticSize = Enum.AutomaticSize.X
    roleBadge.Size = UDim2.new(0, 0, 0, 16)
    roleBadge.Position = UDim2.new(0, 40, 0, 6)
    roleBadge.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    roleBadge.BackgroundTransparency = 0.2
    roleBadge.BorderSizePixel = 0
    roleBadge.Visible = not DisabledTags[msgData.Username]
    roleBadge.Parent = card

    local badgeCorner = Instance.new("UICorner")
    badgeCorner.CornerRadius = UDim.new(0, 4)
    badgeCorner.Parent = roleBadge

    local badgeStroke = Instance.new("UIStroke")
    badgeStroke.Thickness = 1.2
    badgeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    badgeStroke.Color = rankStyle.Start
    badgeStroke.Parent = roleBadge

    local badgeGradient = Instance.new("UIGradient")
    badgeGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, rankStyle.Start),
        ColorSequenceKeypoint.new(1, rankStyle.End)
    })
    badgeGradient.Parent = badgeStroke

    local badgeLabel = Instance.new("TextLabel")
    badgeLabel.Name = "BadgeLabel"
    badgeLabel.AutomaticSize = Enum.AutomaticSize.X
    badgeLabel.Size = UDim2.new(0, 0, 1, 0)
    badgeLabel.Position = UDim2.new(0, 0, 0, 0)
    badgeLabel.BackgroundTransparency = 1
    badgeLabel.Font = Enum.Font.GothamBold
    badgeLabel.Text = "  " .. string.upper(roleName) .. "  "
    badgeLabel.TextColor3 = rankStyle.Start
    badgeLabel.TextSize = 8
    badgeLabel.Parent = roleBadge

    local roleBadgeWidth = roleBadge.Visible and (badgeLabel.TextBounds.X + 8) or 0
    local nameLeftOffset = 40 + (roleBadge.Visible and (roleBadgeWidth + 6) or 0)

    local nameBtn = Instance.new("TextButton")
    nameBtn.Name = "NameButton"
    nameBtn.AutomaticSize = Enum.AutomaticSize.X
    nameBtn.Size = UDim2.new(0, 0, 0, 16)
    nameBtn.Position = UDim2.new(0, nameLeftOffset, 0, 6)
    nameBtn.BackgroundTransparency = 1
    nameBtn.Font = Enum.Font.GothamBold

    local rawDisplayName = msgData.DisplayName or msgData.Username or "Unknown"
    local isClientPlayer = (msgData.Username == LocalPlayer.Name)
    local formattedDisplayName = GetFormattedDisplayName(rawDisplayName, isClientPlayer)

    nameBtn.Text = formattedDisplayName
    nameBtn.TextColor3 = rankStyle.Name or Color3.fromRGB(220, 220, 230)
    nameBtn.TextSize = 11
    nameBtn.Parent = card

    nameBtn.MouseButton1Click:Connect(function()
        if MessageInput then
            MessageInput.Text = "/w " .. msgData.Username .. " "
            MessageInput.CursorPosition = string.len(MessageInput.Text) + 1
        end
    end)

    local isSticker = string.sub(msgData.Text, 1, 11) == "rbxthumb://" or string.sub(msgData.Text, 1, 13) == "rbxassetid://"

    if isSticker then
        local stickerImg = Instance.new("ImageLabel")
        stickerImg.Name = "StickerImage"
        stickerImg.Size = UDim2.new(0, 85, 0, 85)
        stickerImg.Position = UDim2.new(0, 40, 0, 26)
        stickerImg.BackgroundTransparency = 1
        stickerImg.Image = msgData.Text
        stickerImg.ScaleType = Enum.ScaleType.Fit
        stickerImg.Parent = card

        local padFrame = Instance.new("Frame")
        padFrame.Size = UDim2.new(1, 0, 0, 115)
        padFrame.BackgroundTransparency = 1
        padFrame.Parent = card
    else
        local contentLabel = Instance.new("TextLabel")
        contentLabel.Name = "ContentLabel"
        contentLabel.Size = UDim2.new(1, -50, 0, 0)
        contentLabel.Position = UDim2.new(0, 40, 0, 24)
        contentLabel.AutomaticSize = Enum.AutomaticSize.Y
        contentLabel.BackgroundTransparency = 1
        contentLabel.Font = Enum.Font.Gotham
        contentLabel.Text = msgData.Text
        contentLabel.TextColor3 = msgData.IsPrivate and Color3.fromRGB(255, 180, 200) or Color3.fromRGB(230, 230, 240)
        contentLabel.TextSize = 11
        contentLabel.TextXAlignment = Enum.TextXAlignment.Left
        contentLabel.TextYAlignment = Enum.TextYAlignment.Top
        contentLabel.TextWrapped = true
        contentLabel.Parent = card

        local padFrame = Instance.new("Frame")
        padFrame.Size = UDim2.new(1, 0, 0, 8)
        padFrame.Position = UDim2.new(0, 0, 1, 0)
        padFrame.BackgroundTransparency = 1
        padFrame.Parent = card
    end

    if HasAdminPermission(LocalPlayer.Name) then
        local deleteBtn = Instance.new("TextButton")
        deleteBtn.Name = "DeleteBtn"
        deleteBtn.Size = UDim2.new(0, 18, 0, 18)
        deleteBtn.Position = UDim2.new(1, -22, 0, 4)
        deleteBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        deleteBtn.BackgroundTransparency = 0.5
        deleteBtn.Font = Enum.Font.GothamBold
        deleteBtn.Text = "X"
        deleteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        deleteBtn.TextSize = 9
        deleteBtn.Parent = card

        local delCorner = Instance.new("UICorner")
        delCorner.CornerRadius = UDim.new(0, 4)
        delCorner.Parent = deleteBtn

        deleteBtn.MouseButton1Click:Connect(function()
            if msgData.Key then
                task.spawn(function()
                    local targetUrl = (ActiveTab == "GLOBAL" and GLOBAL_FIREBASE_URL or SERVER_FIREBASE_URL)
                        .. (ActiveTab == "GLOBAL" and "global_chat/messages/" or "server_chat/" .. SERVER_JOB_ID .. "/")
                        .. msgData.Key .. ".json"
                    HttpRequest(targetUrl, "DELETE")
                end)
            end
        end)
    end

    task.spawn(function()
        local speed = rankStyle.Speed or 1.2
        while card and card.Parent do
            local dt = RunService.RenderStepped:Wait()
            if roleBadge and roleBadge.Parent and badgeGradient and badgeGradient.Parent then
                badgeGradient.Rotation = (badgeGradient.Rotation + (speed * 60 * dt)) % 360
            end
        end
    end)

    return card
end

-- ============================================================================
-- MESSAGE DISPATCH & COMMANDS HANDLER
-- ============================================================================
SendChatMessage = function()
    local text = MessageInput.Text
    if not text or not string.match(text, "%S") then return end

    local now = os.time()
    if text == LastSentMessageText and (now - LastMessageSendTime) < 5 then
        ConsecutiveSpamCount = ConsecutiveSpamCount + 1
    else
        ConsecutiveSpamCount = 0
    end

    LastSentMessageText = text
    LastMessageSendTime = now

    if ConsecutiveSpamCount >= 2 then
        MessageInput.Text = ""
        MessageInput.PlaceholderText = "Spam block activated! Wait 5 sec..."
        task.wait(2)
        MessageInput.PlaceholderText = "Type a message or /w Username..."
        return
    end

    -- Command Processing: !tag
    if string.sub(text, 1, 4) == "!tag" then
        local targetRole = string.match(text, "^!tag%s+(.+)")
        if targetRole then
            targetRole = string.gsub(targetRole, "^%s*(.-)%s*$", "%1")
            local myAllowedRoles = AvailableUserRoles[LocalPlayer.Name] or {}

            local matchedRole = nil
            for _, rName in ipairs(myAllowedRoles) do
                if string.lower(rName) == string.lower(targetRole) then
                    matchedRole = rName
                    break
                end
            end

            if not matchedRole then
                for rName, _ in pairs(RANK_STYLES) do
                    if string.lower(rName) == string.lower(targetRole) then
                        matchedRole = rName
                        break
                    end
                end
            end

            if matchedRole then
                AssignedPlayerRoles[LocalPlayer.Name] = matchedRole
            end
        else
            DisabledTags[LocalPlayer.Name] = not DisabledTags[LocalPlayer.Name]
        end
        MessageInput.Text = ""
        return
    end

    -- Command Processing: !spoof
    if string.sub(text, 1, 6) == "!spoof" then
        if CanUseSpoof(LocalPlayer.Name) then
            local newSpoofName = string.match(text, "^!spoof%s+(.+)")
            if newSpoofName then
                newSpoofName = string.gsub(newSpoofName, "^%s*(.-)%s*$", "%1")
                if newSpoofName ~= "" then
                    SpoofedDisplayName = newSpoofName
                end
            else
                SpoofedDisplayName = nil
            end
        end
        MessageInput.Text = ""
        return
    end

    -- Command Processing: !role
    if string.sub(text, 1, 5) == "!role" then
        if HasAdminPermission(LocalPlayer.Name) then
            local targetUser, targetRole = string.match(text, "^!role%s+(%S+)%s+(.+)")
            if targetUser and targetRole then
                targetRole = string.gsub(targetRole, "^%s*(.-)%s*$", "%1")
                for _, p in ipairs(Players:GetPlayers()) do
                    if string.lower(p.Name) == string.lower(targetUser) or string.lower(p.DisplayName) == string.lower(targetUser) then
                        AssignedPlayerRoles[p.Name] = targetRole
                        break
                    end
                end
            end
        end
        MessageInput.Text = ""
        return
    end

    -- Whisper Parsing
    local whisperTarget, whisperBody = string.match(text, "^/w%s+(%S+)%s+(.+)")
    local isPrivate = false
    local recipient = nil

    if whisperTarget and whisperBody then
        isPrivate = true
        recipient = whisperTarget
        text = whisperBody
    end

    local payload = {
        Username = LocalPlayer.Name,
        DisplayName = SpoofedDisplayName or LocalPlayer.DisplayName,
        Role = GetAssignedOrCalculatedRole(LocalPlayer.Name),
        PfpId = CurrentPfpId,
        Text = text,
        Timestamp = os.time(),
        IsPrivate = isPrivate,
        Recipient = recipient
    }

    local targetEndpoint = (ActiveTab == "GLOBAL" and GLOBAL_MESSAGES_ENDPOINT or SERVER_MESSAGES_ENDPOINT)

    task.spawn(function()
        HttpRequest(targetEndpoint, "POST", payload)
    end)

    if PersistentPvtPrefix ~= "" then
        MessageInput.Text = PersistentPvtPrefix
    else
        MessageInput.Text = ""
    end
end

SendButton.MouseButton1Click:Connect(SendChatMessage)
MessageInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then SendChatMessage() end
end)

-- Automatic Whisper Prefix Retainer
MessageInput:GetPropertyChangedSignal("Text"):Connect(function()
    local text = MessageInput.Text
    local prefix = string.match(text, "^(/w%s+%S+%s+)")
    if prefix then
        PersistentPvtPrefix = prefix
    elseif text == "" then
        PersistentPvtPrefix = ""
    end
end)

-- ============================================================================
-- FIREBASE POLLING ENGINE & CACHE SYNCHRONIZER
-- ============================================================================
local function SyncMessagesForChannel(channelName, endpointUrl, cachedTable, uiElementsTable)
    local rawData = HttpRequest(endpointUrl, "GET")
    if not rawData or type(rawData) ~= "table" then return end

    local sortedList = {}
    for key, data in pairs(rawData) do
        if type(data) == "table" then
            data.Key = key
            table.insert(sortedList, data)
        end
    end

    table.sort(sortedList, function(a, b)
        return (a.Timestamp or 0) < (b.Timestamp or 0)
    end)

    for _, msgData in ipairs(sortedList) do
        if not cachedTable[msgData.Key] then
            cachedTable[msgData.Key] = msgData

            if (msgData.Timestamp or 0) >= ScriptStartTime then
                local isForMe = true
                if msgData.IsPrivate then
                    local isSender = (msgData.Username == LocalPlayer.Name)
                    local isRecipient = (msgData.Recipient and string.lower(msgData.Recipient) == string.lower(LocalPlayer.Name))
                    isForMe = isSender or isRecipient
                end

                if isForMe then
                    local cardUI = CreateMessageCard(msgData)
                    cardUI.Visible = (ActiveTab == channelName)
                    cardUI.Parent = MessageContainer
                    uiElementsTable[msgData.Key] = cardUI

                    if channelName == ActiveTab then
                        DisplayNewMessageNotif(msgData)
                    end
                end
            end
        end
    end

    for key, uiEl in pairs(uiElementsTable) do
        if not rawData[key] then
            uiEl:Destroy()
            uiElementsTable[key] = nil
            cachedTable[key] = nil
        end
    end
end

-- Long Polling Loop
task.spawn(function()
    while true do
        FetchRemoteRankStyles()
        FetchRemoteRoles()

        pcall(function()
            SyncMessagesForChannel("GLOBAL", GLOBAL_MESSAGES_ENDPOINT, GlobalCachedMessages, GlobalUIElements)
            SyncMessagesForChannel("SERVER", SERVER_MESSAGES_ENDPOINT, ServerCachedMessages, ServerUIElements)
        end)
        task.wait(2)
    end
end)

-- Server Cleanup Task (Runs every 20 mins)
task.spawn(function()
    while true do
        task.wait(1200)
        if HasAdminPermission(LocalPlayer.Name) then
            pcall(function()
                HttpRequest(SERVER_MESSAGES_ENDPOINT, "DELETE")
            end)
        end
    end
end)
