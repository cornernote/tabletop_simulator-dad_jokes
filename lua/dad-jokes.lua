-- Bag of Dad Jokes by CoRNeRNoTe
-- Pull a notecard to get a random dad joke.

-- Most recent script can be found on GitHub:
-- https://github.com/cornernote/tabletop_simulator-dad_jokes/blob/main/lua/dad-jokes.lua

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