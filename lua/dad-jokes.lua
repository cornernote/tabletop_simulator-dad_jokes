local AutoUpdater = {
    name = "Endless Dad Jokes",
    version = "1.0.5",
    versionUrl = "https://raw.githubusercontent.com/cornernote/tabletop_simulator-dad_jokes/refs/heads/main/lua/dad-jokes.ver",
    scriptUrl = "https://raw.githubusercontent.com/cornernote/tabletop_simulator-dad_jokes/refs/heads/main/lua/dad-jokes.lua",
    debug = false,

    run = function(self, host)
        self.host = host
        if not self.host then
            self:error("Error: host not set, ensure AutoUpdater:run(self) is in your onLoad() function")
            return
        end
        self:checkForUpdate()
    end,
    checkForUpdate = function(self)
        WebRequest.get(self.versionUrl, function(request)
            if request.response_code ~= 200 then
                self:error("Failed to check version (" .. request.response_code .. ": " .. request.error .. ")")
                return
            end
            local remoteVersion = request.text:match("[^\r\n]+") or ""
            if self:isNewerVersion(remoteVersion) then
                self:fetchNewScript(remoteVersion)
            end
        end)
    end,
    isNewerVersion = function(self, remoteVersion)
        local function split(v)
            return { v:match("^(%d+)%.?(%d*)%.?(%d*)") or 0 }
        end
        local r, l = split(remoteVersion), split(self.version)
        for i = 1, math.max(#r, #l) do
            local rv, lv = tonumber(r[i]) or 0, tonumber(l[i]) or 0
            if rv ~= lv then
                return rv > lv
            end
        end
        return false
    end,
    fetchNewScript = function(self, newVersion)
        WebRequest.get(self.scriptUrl, function(request)
            if request.response_code ~= 200 then
                self:error("Failed to fetch new script (" .. request.response_code .. ": " .. request.error .. ")")
                return
            end
            if request.text and #request.text > 0 then
                self.host.setLuaScript(request.text)
                self:print("Updated to version " .. newVersion)
                Wait.condition(function()
                    return not self.host or self.host.reload()
                end, function()
                    return not self.host or self.host.resting
                end)
            else
                self:error("New script is empty")
            end
        end)
    end,
    print = function(self, message)
        print(self.name .. ": " .. message)
    end,
    error = function(self, message)
        if self.debug then
            error(self.name .. ": " .. message)
        end
    end,
}

function onLoad()
    AutoUpdater:run(self)
end

function onObjectLeaveContainer(container, leaveObject)
    if container ~= self then
        return
    end

    leaveObject.setName("Dad Joke")
    leaveObject.setDescription("Loading...")

    WebRequest.custom("https://icanhazdadjoke.com/", "GET", true, "{}", { Accept = "application/json" }, function(request)
        if request.response_code ~= 200 then
            leaveObject.setName("Error Loading Dad Joke")
            leaveObject.setDescription(request.error)
            return
        end

        local data = JSON.decode(request.text or "{}")

        if not data.joke then
            leaveObject.setName("Error Loading Dad Joke")
            leaveObject.setDescription("No joke found.")
            return
        end

        leaveObject.setDescription(data.joke)
    end)
end