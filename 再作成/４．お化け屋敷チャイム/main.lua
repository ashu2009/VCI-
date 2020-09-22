local STATE = vci.state

local SOUNDS = {
    str = {"Cube (1)", "Cube (2)", "Cube (3)", "Cube (4)"},
    sound_str = {"Chime5", "Chime6", "Chime7", "Chime8"}
}

function onUse(use)
    for i = 1, #SOUNDS.str do
        if use == SOUNDS.str[i] then
            AllPlayAudio(SOUNDS.sound_str[i])
            break
        end
    end
end

--指定した音を鳴らす
function AllPlayAudio(sound_name)
    ASSET._ALL_PlayAudioFromName(sound_name)
end
