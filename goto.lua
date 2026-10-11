local Players, StarterGui = game:GetService("Players"), game:GetService("StarterGui")
local LP = Players.LocalPlayer
local LIFT, GRACE, SETTLE, STEP = 3, 4, 0.4, 0.1
local BAD = {
    [Enum.HumanoidStateType.Freefall] = true,
    [Enum.HumanoidStateType.FallingDown] = true,
    [Enum.HumanoidStateType.Dead] = true,
    [Enum.HumanoidStateType.Ragdoll] = true,
}

local function notify(text)
    pcall(function()
        StarterGui:SetCore("SendNotification", { Title = "Go To", Text = text, Duration = 5 })
    end)
end

local function toVector(a, b, c)
    if typeof(a) == "Vector3" then return a end
    if typeof(a) == "CFrame" then return a.Position end
    if type(a) == "string" then
        a, b, c = a:match("(-?[%d%.]+)%s*,%s*(-?[%d%.]+)%s*,%s*(-?[%d%.]+)")
    elseif type(a) == "table" then
        a, b, c = a[1] or a.x or a.X, a[2] or a.y or a.Y, a[3] or a.z or a.Z
    end
    local x, y, z = tonumber(a), tonumber(b), tonumber(c)
    if x and y and z then return Vector3.new(x, y, z) end
    return nil
end

local function alive()
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if char and hum and root and hum.Health > 0 then return char, hum, root end
    return nil
end

local function ready(timeout)
    local stop = os.clock() + timeout
    repeat
        local char, hum = alive()
        if char and not BAD[hum:GetState()] then return char end
        task.wait(STEP)
    until os.clock() > stop
    return nil
end

local rp = RaycastParams.new()
rp.FilterType = Enum.RaycastFilterType.Exclude
pcall(function() rp.RespectCanCollide = true end)

local function floorAt(point, char)
    rp.FilterDescendantsInstances = { char }
    return workspace:Raycast(point + Vector3.new(0, 6, 0), Vector3.new(0, -4000, 0), rp)
end

local function pin(cf)
    local char, _, root = alive()
    if not char then return nil end
    rp.FilterDescendantsInstances = { char }
    char:PivotTo(cf)
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    return char
end

local dest = toVector(...)
if not dest then
    notify("No coordinates passed in.")
    return false
end
if not ready(10) then
    notify("Your character never settled - try again once you are standing.")
    return false
end

local goal, ground = CFrame.new(dest), nil
local deadline = os.clock() + GRACE
repeat
    local char = pin(goal)
    if not char then break end
    task.wait(STEP)
    char = LP.Character
    if not char then break end
    local hit = floorAt(dest, char)
    if hit then ground = hit.Position end
until ground or os.clock() > deadline

if not ground then
    notify("No ground under those coordinates - dropping you there instead.")
    return false
end

goal = CFrame.new(ground + Vector3.new(0, LIFT, 0))
local hold = os.clock() + SETTLE
repeat
    if not pin(goal) then break end
    task.wait(STEP)
until os.clock() > hold

local _, hum = alive()
notify(hum and not BAD[hum:GetState()] and "You're there." or "Arrived - still finding your feet.")
return true
