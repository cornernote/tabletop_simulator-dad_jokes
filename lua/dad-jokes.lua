--[[
=======================================================================
== Endless Dad Jokes by CoRNeRNoTe
== Pull a notecard to get a random dad joke.
=======================================================================
]]--

-----------------------------------------------------------------------
-- AutoUpdater - downloads the latest version
-----------------------------------------------------------------------

local AutoUpdater = {
    name = "Endless Dad Jokes",
    version = "1.0.0",
    versionUrl = "https://raw.githubusercontent.com/cornernote/tabletop_simulator-dad_jokes/refs/heads/main/lua/dad-jokes.ver",
    scriptUrl = "https://raw.githubusercontent.com/cornernote/tabletop_simulator-dad_jokes/refs/heads/main/lua/dad-jokes.lua",
}

AutoUpdater.isNewerVersion = function(remoteVersion)
    local function split(v)
        local t = {}
        for n in v:gmatch("%d+") do
            table.insert(t, tonumber(n))
        end
        return t
    end

    local r, l = split(remoteVersion), split(AutoUpdater.version)
    for i = 1, math.max(#r, #l) do
        local rv, lv = r[i] or 0, l[i] or 0
        if rv > lv then
            return true
        end
        if rv < lv then
            return false
        end
    end
    return false
end

AutoUpdater.checkForUpdate = function()
    WebRequest.get(AutoUpdater.versionUrl, function(request)
        if request.response_code ~= 200 then
            return
        end
        local remoteVersion = request.text:match("[^\r\n]+") or ""
        if remoteVersion ~= "" and AutoUpdater.isNewerVersion(remoteVersion) then
            AutoUpdater.fetchNewScript(remoteVersion)
        end
    end)
end

AutoUpdater.fetchNewScript = function(newVersion)
    WebRequest.get(AutoUpdater.scriptUrl, function(request)
        if request.response_code ~= 200 then
            return
        end
        if request.text and #request.text > 0 then
            self.setLuaScript(request.text)
            self.reload()
            print(AutoUpdater.name .. ": Updated script to version " .. newVersion)
        end
    end)
end

-----------------------------------------------------------------------
-- Main script
-----------------------------------------------------------------------

local apiUrl = "https://icanhazdadjoke.com/"
local apiHeaders = { Accept = "application/json" }

function onObjectLeaveContainer(container, leave_object)
    if container ~= self then
        return
    end

    leave_object.setName("Dad Joke")
    leave_object.setDescription("Loading...")

    WebRequest.custom(apiUrl, "GET", true, "{}", apiHeaders, function(request)
        if request.is_error then
            leave_object.setName("Error Loading Dad Joke")
            leave_object.setDescription(request.error)
            return
        end

        local data = JSON.decode(request.text or "{}")

        if not data.joke then
            leave_object.setName("Error Loading Dad Joke")
            leave_object.setDescription("No joke found.")
            return
        end

        leave_object.setDescription(data.joke)
    end)
end