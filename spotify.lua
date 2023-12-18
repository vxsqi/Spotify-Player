local Base64 = {}

local FILLER_CHARACTER = 61

local alphabet = {}
local indexes = {}

for index = 65, 90 do table.insert(alphabet, index) end -- A-Z
for index = 97, 122 do table.insert(alphabet, index) end -- a-z
for index = 48, 57 do table.insert(alphabet, index) end -- 0-9

table.insert(alphabet, 43) -- +
table.insert(alphabet, 47) -- /

for index, character in pairs(alphabet) do
    indexes[character] = index
end

local function buildString(values)
    local output = {}

    for index = 1, #values, 4096 do
        table.insert(output, string.char(
            unpack(values, index, math.min(index + 4096 - 1, #values))
        ))
    end

    return table.concat(output, "")
end

local Base64 = {}

function Base64.encode(input)
    local output = {}

    for index = 1, #input, 3 do
        local C1, C2, C3 = string.byte(input, index, index + 2)

        local A = bit32.rshift(C1, 2)
        local B = bit32.lshift(bit32.band(C1, 3), 4) + bit32.rshift(C2 or 0, 4)
        local C = bit32.lshift(bit32.band(C2 or 0, 15), 2) + bit32.rshift(C3 or 0, 6)
        local D = bit32.band(C3 or 0, 63)

        output[#output + 1] = alphabet[A + 1]
        output[#output + 1] = alphabet[B + 1]
        output[#output + 1] = C2 and alphabet[C + 1] or FILLER_CHARACTER
        output[#output + 1] = C3 and alphabet[D + 1] or FILLER_CHARACTER
    end

    return buildString(output)
end

function Base64.decode(input)
    local output = {}

    for index = 1, #input, 4 do
        local C1, C2, C3, C4 = string.byte(input, index, index + 3)

        local I1 = indexes[C1] - 1
        local I2 = indexes[C2] - 1
        local I3 = (indexes[C3] or 1) - 1
        local I4 = (indexes[C4] or 1) - 1

        local A = bit32.lshift(I1, 2) + bit32.rshift(I2, 4)
        local B = bit32.lshift(bit32.band(I2, 15), 4) + bit32.rshift(I3, 2)
        local C = bit32.lshift(bit32.band(I3, 3), 6) + I4

        output[#output + 1] = A
        if C3 ~= FILLER_CHARACTER then output[#output + 1] = B end
        if C4 ~= FILLER_CHARACTER then output[#output + 1] = C end
    end
    
    return buildString(output)
end

local HttpService = game:GetService('HttpService')

local clientid = '727be3084350487eabf20e33776e2251'
local client_secret = '170a539314c543838a535f5e84c84499' 
HttpService:GetAsync('https://vxsqi.tk/spotifyauth')
local authorization = HttpService:GetAsync('https://vxsqi.tk/scripts/spotifyauth.txt')
print(authorization)

local response = HttpService:RequestAsync({
	Url = "https://accounts.spotify.com/api/token",
	Method = "POST",
	Headers = {
		["Content-Type"] = "application/x-www-form-urlencoded",
		['Authorization'] = 'Basic ' .. Base64.encode(clientid .. ':' .. client_secret)
	},
	Body = `grant_type=authorization_code&code={authorization}&redirect_uri=https://vxsqi.tk/spotifyauth`,
})

print(response.Body)
local access_token = response.Body:match("\"access_token\":\"([^\"]+)\"")
print(access_token)

local module = {
	getCurrentlyPlayingSong = function(player)
		local response = HttpService:RequestAsync({
			Url = "https://api.spotify.com/v1/me/player/currently-playing",
			Method = "GET",
			Headers = {
				["Content-Type"] = "application/json",
				["Authorization"] = "Bearer " .. access_token, -- added space after "Bearer"
			},
		})

		local status = response.StatusCode
		if status == 200 then
			local data = HttpService:JSONDecode(response.Body)
			return {true,data}
		else
			return {false,HttpService:JSONDecode(response.Body).error.message}
		end
	end,

	getPreviousTrack = function(player)
		local response = HttpService:RequestAsync({
			Url = "https://api.spotify.com/v1/me/player/recently-played?limit=1",
			Method = "GET",
			Headers = {
				["Content-Type"] = "application/json",
				["Authorization"] = "Bearer " .. access_token, -- added space after "Bearer"
			},
		})

		local status = response.StatusCode
		if status == 200 then
			local data = HttpService:JSONDecode(response.Body)
			return data
		else
			warn(response.Body) -- print the error message
		end
	end,

	pause = function(player)
		local response = HttpService:RequestAsync({
			Url = "https://api.spotify.com/v1/me/player/pause",
			Method = "PUT",
			Headers = {
				["Content-Type"] = "application/json",
				["Authorization"] = "Bearer " .. access_token,
			},
		})

		local status = response.StatusCode
		if status == 204 then
			return true -- success
		else
			warn(response.Body)
			return false -- error
		end
	end,

	play = function(player)
		local response = HttpService:RequestAsync({
			Url = "https://api.spotify.com/v1/me/player/play",
			Method = "PUT",
			Headers = {
				["Content-Type"] = "application/json",
				["Authorization"] = "Bearer " .. access_token,
			},
		})

		local status = response.StatusCode
		if status == 204 then
			return true -- success
		else
			warn(response.Body)
			return false -- error
		end
	end,

	getTrackAudioAnalysis = function(player, track_id)
		local response = HttpService:RequestAsync({
			Url = "https://api.spotify.com/v1/audio-analysis/" .. track_id,
			Method = "GET",
			Headers = {
				["Content-Type"] = "application/json",
				["Authorization"] = "Bearer " .. access_token,
			},
		})


		local status = response.StatusCode
		if status == 200 then
			local data = HttpService:JSONDecode(response.Body)
			return data
		else
			warn(response.Body) -- print the error message
		end
	end,

	previous = function(player)
		local body = HttpService:JSONEncode({}) -- create an empty JSON body
		local response = HttpService:RequestAsync({
			Url = "https://api.spotify.com/v1/me/player/previous",
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json",
				["Authorization"] = "Bearer " .. access_token,
			},
			Body = body,
		})

		local status = response.StatusCode
		if status == 204 then
			return true -- success
		else
			warn(response.Body)
			return false -- error
		end
	end
}

local BillboardGui = Instance.new("BillboardGui")
BillboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
BillboardGui.Active = true
BillboardGui.Size = UDim2.new(15, 0, 1.5, 0)
BillboardGui.ClipsDescendants = true
BillboardGui.MaxDistance = 200
BillboardGui.StudsOffset = Vector3.new(0, 2, 0)

local background = Instance.new("Frame")
background.Name = "background"
background.AnchorPoint = Vector2.new(0.5, 0)
background.Size = UDim2.new(1, 0, 1, 0)
background.ClipsDescendants = true
background.Position = UDim2.new(0.5, 0, 0, 0)
background.BorderSizePixel = 0
background.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
background.Parent = BillboardGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 2)
UICorner.Parent = background

local timepos = Instance.new("Frame")
timepos.Name = "timepos"
timepos.ZIndex = 2
timepos.AnchorPoint = Vector2.new(0.5, 0)
timepos.Size = UDim2.new(0.9845504, 0, 0.0909091, 0)
timepos.ClipsDescendants = true
timepos.Position = UDim2.new(0.5000002, 0, 0.9090909, 0)
timepos.BorderSizePixel = 0
timepos.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
timepos.Parent = background

local point = Instance.new("Frame")
point.Name = "point"
point.ZIndex = 2
point.Size = UDim2.new(0, 0, 1, 0)
point.BorderSizePixel = 0
point.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
point.Parent = timepos

local UIGradient = Instance.new("UIGradient")
UIGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 200, 200)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 200))})
UIGradient.Parent = point

local UICorner1 = Instance.new("UICorner")
UICorner1.CornerRadius = UDim.new(0, 5)
UICorner1.Parent = point

local UIGradient1 = Instance.new("UIGradient")
UIGradient1.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 200, 200)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 200))})
UIGradient1.Parent = timepos

local UIStroke = Instance.new("UIStroke")
UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke.Thickness = 2
UIStroke.Color = Color3.fromRGB(20, 20, 20)
UIStroke.Parent = timepos

local UIGradient2 = Instance.new("UIGradient")
UIGradient2.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 200, 200)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 200))})
UIGradient2.Parent = background

local mainframe = Instance.new("Frame")
mainframe.Name = "mainframe"
mainframe.Size = UDim2.new(1.0000001, 0, 0.9090909, 0)
mainframe.BackgroundTransparency = 1
mainframe.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
mainframe.Parent = background

local control = Instance.new("Frame")
control.Name = "control"
control.AnchorPoint = Vector2.new(0.9850000143051147, 0.5)
control.Size = UDim2.new(0.485, 0, 0.9, 0)
control.Position = UDim2.new(0.985, 0, 0.386, 0)
control.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
control.Parent = mainframe

local UICorner3 = Instance.new("UICorner")
UICorner3.CornerRadius = UDim.new(0, 1)
UICorner3.Parent = control

local UIStroke4 = Instance.new("UIStroke")
UIStroke4.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke4.Thickness = 2
UIStroke4.Color = Color3.fromRGB(20, 20, 20)
UIStroke4.Parent = control

local duration = Instance.new("TextLabel")
duration.Name = "duration"
duration.AnchorPoint = Vector2.new(0, 1)
duration.Size = UDim2.new(1, 0, 0.3, 0)
duration.Position = UDim2.new(0, 0, 1, 0)
duration.BorderSizePixel = 0
duration.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
duration.FontSize = Enum.FontSize.Size14
duration.TextSize = 14
duration.TextColor3 = Color3.fromRGB(255, 255, 255)
duration.Text = "<b>0:00</b>"
duration.TextWrapped = true
duration.Font = Enum.Font.Ubuntu
duration.TextWrap = true
duration.RichText = true
duration.TextScaled = true
duration.Parent = control

local UICorner7 = Instance.new("UICorner")
UICorner7.CornerRadius = UDim.new(0, 1)
UICorner7.Parent = info

local UITextSizeConstraint = Instance.new("UITextSizeConstraint")
UITextSizeConstraint.MaxTextSize = 10
UITextSizeConstraint.Parent = duration

local play = Instance.new("ImageButton")
play.Name = "play"
play.AnchorPoint = Vector2.new(0.5, 0)
play.Size = UDim2.new(0.0544641, 0, 0.325, 0)
play.BackgroundTransparency = 0.95
play.Position = UDim2.new(0.5000001, 0, 0.3, 0)
play.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
play.ImageColor3 = Color3.fromRGB(142, 142, 142)
play.ImageRectOffset = Vector2.new(100, 150)
play.Image = "rbxassetid://6764432408"
play.ImageRectSize = Vector2.new(50, 50)
play.Parent = control

local UICorner4 = Instance.new("UICorner")
UICorner4.CornerRadius = UDim.new(0, 100)
UICorner4.Parent = play

local forward = Instance.new("ImageButton")
forward.Name = "forward"
forward.AnchorPoint = Vector2.new(0.5, 0)
forward.Size = UDim2.new(0.0544641, 0, 0.325, 0)
forward.BackgroundTransparency = 0.95
forward.Position = UDim2.new(0.6, 0, 0.3, 0)
forward.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
forward.ImageColor3 = Color3.fromRGB(142, 142, 142)
forward.ImageRectOffset = Vector2.new(100, 650)
forward.Image = "rbxassetid://6764432408"
forward.ImageRectSize = Vector2.new(50, 50)
forward.Parent = control

local UICorner5 = Instance.new("UICorner")
UICorner5.CornerRadius = UDim.new(0, 100)
UICorner5.Parent = forward

local backward = Instance.new("ImageButton")
backward.Name = "backward"
backward.AnchorPoint = Vector2.new(0.5, 0)
backward.Size = UDim2.new(0.0544641, 0, 0.325, 0)
backward.BackgroundTransparency = 0.95
backward.Position = UDim2.new(0.4, 0, 0.3, 0)
backward.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
backward.ImageColor3 = Color3.fromRGB(142, 142, 142)
backward.ImageRectOffset = Vector2.new(100, 350)
backward.Image = "rbxassetid://6764432408"
backward.ImageRectSize = Vector2.new(50, 50)
backward.Parent = control

local UICorner6 = Instance.new("UICorner")
UICorner6.CornerRadius = UDim.new(0, 100)
UICorner6.Parent = backward

local UIStroke1 = Instance.new("UIStroke")
UIStroke1.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke1.Thickness = 1
UIStroke1.Color = Color3.fromRGB(20, 20, 20)
UIStroke1.Parent = control

local info = Instance.new("Frame")
info.Name = "info"
info.AnchorPoint = Vector2.new(0.014999999664723873, 0.5)
info.Size = UDim2.new(0.485, 0, 0.9, 0)
info.Position = UDim2.new(0.015, 0, 0.386, 0)
info.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
info.Parent = mainframe

local UICorner7 = Instance.new("UICorner")
UICorner7.CornerRadius = UDim.new(0, 1)
UICorner7.Parent = info

local songname = Instance.new("TextLabel")
songname.Name = "songname"
songname.AnchorPoint = Vector2.new(1, 0.5)
songname.Size = UDim2.new(0.6, 0, 0.7, 0)
songname.BackgroundTransparency = 1
songname.Position = UDim2.new(0.9, 0, 0.55, 0)
songname.BorderSizePixel = 0
songname.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
songname.TextColor3 = Color3.fromRGB(255, 255, 255)
songname.Text = "Waiting for response..."
songname.TextWrapped = true
songname.Font = Enum.Font.GothamBold
songname.TextWrap = true
songname.TextScaled = true
songname.Parent = info

local imageframe = Instance.new("Frame")
imageframe.Name = "imageframe"
imageframe.AnchorPoint = Vector2.new(0, 0)
imageframe.Size = UDim2.new(0.16, 0, 1, 0)
imageframe.Position = UDim2.new(0, 0, 0, 0)
imageframe.BorderSizePixel = 0
imageframe.BackgroundColor3 = Color3.fromRGB(255,255,255)
imageframe.BackgroundTransparency = 1
imageframe.Parent = info

local UITextSizeConstraint1 = Instance.new("UITextSizeConstraint")
UITextSizeConstraint1.MaxTextSize = 17
UITextSizeConstraint1.Parent = songname

local UIStroke2 = Instance.new("UIStroke")
UIStroke2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke2.Thickness = 2
UIStroke2.Color = Color3.fromRGB(20, 20, 20)
UIStroke2.Parent = info

local UIStroke3 = Instance.new("UIStroke")
UIStroke3.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke3.Thickness = 5
UIStroke3.Color = Color3.fromRGB(20, 20, 20)
UIStroke3.Parent = background

BillboardGui.Brightness = 2
BillboardGui.Parent = owner.Character.Head

local tweenservice = game:GetService('TweenService')
local rep = module

local gui = BillboardGui
local background = gui.background
local mainframe = background.mainframe

local timepos = background.timepos
local timepoint = timepos.point

local isrunning = false
local timeposition = nil

local loadingText = "Waiting for response"
local textlength = loadingText:len()

local function Map(m1,n1,m2,n2,x)
    return (x-m1)/(n1-m1)*(n2-m2) + m2
end

task.spawn(function()
	while task.wait(0.5) do
		if access_token == '' or access_token == nil or access_token:find('<font color="rgb(255,100,100">') then
			if loadingText:find('Waiting for response') then
				loadingText ..= '.'

				if loadingText:len() > textlength+3 then
					loadingText = "Waiting for response"
				end

				mainframe.info.songname.Text = loadingText
			end
		end
	end
end)


function SecondsToMMSS(milliseconds)
	local seconds = math.floor(milliseconds / 1000)
	local minutes = math.floor(seconds / 60)
	seconds = seconds % 60
	return string.format("%d:%02d", minutes, seconds)
end

local function lerp(a, b, t)
	return a + (b-a)*t
end

local function update(result)
	mainframe.control.duration.Text = '<b>'..SecondsToMMSS(result["progress_ms"]).."/"..SecondsToMMSS(result["item"]["duration_ms"])..'</b>'
	mainframe.info.songname.Text = result.item.artists[1].name.." - "..result["item"]["name"]

	if rep.getCurrentlyPlayingSong(owner)[2]["progress_ms"] ~= timeposition then
		mainframe.control.play.ImageRectOffset = Vector2.new(100,550)
	else
		mainframe.control.play.ImageRectOffset = Vector2.new(100,150)
	end

	local completionDecimal = math.floor(result["progress_ms"])/math.floor(result["item"]["duration_ms"])

	local barLength = lerp(0, timepos.Size.X.Scale, completionDecimal)

	timepoint:TweenSize(UDim2.fromScale(barLength,1),Enum.EasingDirection.In,Enum.EasingStyle.Linear,0.1)
end

local response = rep.getCurrentlyPlayingSong(owner)

if response[1] then
	isrunning = true

	local id = nil
	local result
	local isrendering = false
	
	task.spawn(function()
		while task.wait(0.5) do
			result = rep.getCurrentlyPlayingSong(owner)

			if result then			
				pcall(function()
					if id ~= result[2]['item']['id'] then
						task.spawn(function()
							print('new song')

							if isrendering then
								isrendering = false
								return
							end

							isrendering = true

							print(result[2]['item']['album']['images'][2])
							local v = result[2]['item']['album']['images'][2]
							local imagedata = HttpService:JSONDecode(HttpService:RequestAsync({
								Url = 'https://vxsqi.tk/image',
								Method = 'POST',
								Headers = {
									['Content-Type'] = 'application/json'
								},
								Body = HttpService:JSONEncode({
									xres = 64,
									yres = 64,
									url = v.url
								})
							}).Body)

							print(#imagedata)
							imageframe:ClearAllChildren()

							for i,v in ipairs(imagedata) do
								local pixel = Instance.new('Frame')
								pixel.BackgroundColor3 = Color3.fromRGB(v.r,v.g,v.b)
								pixel.Size = UDim2.fromScale(1/64,1/64)
								pixel.Position = UDim2.fromScale(v.xpos/64,v.ypos/64)
								pixel.BorderSizePixel = 0
								pixel.Parent = imageframe
							end
							isrendering = false
						end)
					end
	
					update(result[2])
					timeposition = result[2]['progress_ms']
					id = result[2]['item']['id']
				end)
			else
				warn(result)
			end
		end
	end)
end

local function lerp(a, b, t)
	return a + (b-a)*t
end

function inverseLerp(a, b, x)
	return math.clamp((x-a)/(b-a), 0, 1)
end

local lastT = 0

local Color1 = Color3.fromRGB(15,15,15)
local Color2 = Color3.fromRGB(31, 223, 100)
-- [0 -> 1]. if 0, the beat won't go down, if 1, it will follow it without smoothing
local beatDownAggressiveness = 0.1
-- [0 -> 1]. if 0, the beat won't go up, if 1, it will follow it without smoothing
local beatUpAggressiveness = 0.9

local function lerp(a, b, t)
	return a + (b-a)*t
end

function inverseLerp(a, b, x)
	return math.clamp((x-a)/(b-a), 0, 1)
end

-- local lastT = 0
-- local loudness = 0
-- task.spawn(function()
-- 	while task.wait() do
-- 		local response
-- 		pcall(function()
-- 			response = tonumber(HttpService:GetAsync('https://vxsqi.tk/scripts/loudness.txt'))
-- 		end)
		
-- 		if response == nil or response <= 1 then
-- 			continue
-- 		end
		
-- 		loudness = Map(0,32767,0,1000,tonumber(response))
-- 	end
-- end)

-- game:GetService'RunService'.Stepped:Connect(function()
-- 	local t = inverseLerp(0, 500, loudness)

-- 	if t >= lastT then
-- 		t = lerp(lastT, t, beatUpAggressiveness)
-- 		local change = Color1:Lerp(Color2, t)

-- 		background.BackgroundColor3 = change
-- 	else
-- 		t = lerp(lastT, t, beatDownAggressiveness)
-- 		local change = Color1:Lerp(Color2, t)

-- 		background.BackgroundColor3 = change
-- 	end

-- 	lastT = t
-- end)