-- messages.lua
local Messages = {
    platonic = {
        { id = "msg_p_01", text = "Hey V, just sorted through some old braindances. Made me think of our dive. Hope you're staying out of trouble." },
        { id = "msg_p_02", text = "V! If you're around Northside, drop by Lizzie's. Drinks are on me (maybe)." },
        { id = "msg_p_03", text = "Just saw a sunset over the Badlands and thought of you. Stay safe out there, V." }
    },
    romance = {
        { id = "msg_r_01", text = "Morning, calabacita. Had a dream about you... it was a damn good one. Take care of yourself, okay?" },
        { id = "msg_r_02", text = "Hey, Jude here. Just wanted to tell you that I miss you. Come by soon." },
        { id = "msg_r_03", text = "Hey V, thinking of you. Can't wait to have you back at the apartment. Love you." }
    }
}

function Messages.GetRandomMessage(isRomanced)
    local category = isRomanced and Messages.romance or Messages.platonic
    local index = math.random(1, #category)
    return category[index]
end

return Messages