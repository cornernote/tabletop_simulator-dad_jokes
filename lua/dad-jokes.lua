local AutoUpdater = {
    name = "Endless Dad Jokes",
    version = "1.0.3",
    versionUrl = "https://raw.githubusercontent.com/cornernote/tabletop_simulator-dad_jokes/refs/heads/main/lua/dad-jokes.ver",
    scriptUrl = "https://raw.githubusercontent.com/cornernote/tabletop_simulator-dad_jokes/refs/heads/main/lua/dad-jokes.lua",

    isNewerVersion = function(self, remoteVersion)
        local function split(v)
            local t = {}
            for n in v:gmatch("%d+") do
                table.insert(t, tonumber(n))
            end
            return t
        end

        local r, l = split(remoteVersion), split(self.version)
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
    end,

    fetchNewScript = function(self, newVersion)
        WebRequest.get(self.scriptUrl, function(request)
            if request.response_code ~= 200 then
                return
            end
            if request.text and #request.text > 0 then
                self.host.setLuaScript(request.text)
                print(self.name .. ": Updated to version " .. newVersion)
                Wait.condition(function()
                    if self.host then
                        self.host.reload()
                    end
                end, function()
                    return not self.host or self.host.resting
                end)
            end
        end)
    end,

    checkForUpdate = function(self)
        if not self.host then
            return
        end
        WebRequest.get(self.versionUrl, function(request)
            if request.response_code ~= 200 then
                print(self.name .. ": Failed to check version (" .. request.response_code .. ")")
                return
            end
            local remoteVersion = request.text:match("[^\r\n]+") or ""
            if remoteVersion ~= "" and self:isNewerVersion(remoteVersion) then
                self:fetchNewScript(remoteVersion)
            end
        end)
    end,
}

function onLoad()
    AutoUpdater.host = self
    AutoUpdater:checkForUpdate()
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