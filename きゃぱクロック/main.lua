local STATE = vci.state
local ASSET = vci.assets
local STUDIO = vci.studio
local ASHU_MESS = "ASHU_NEWS_PAPER_MESS_"
local NOT_DEBUG = false
--各々の時間表示するならばfalse
local MINE_DATE_ONLY = true

local CAPA_CLOCK_DATA = {
    --マテリアル基礎名称
    str_material = "n",
    --個数
    str_material_num = 4,
    --マテリアル名称保存
    material = {},
    --時間関係
    str_date = {"hour", "min"}
}
local COMENT_VIEWER = {
    --コメビュ部分
    str_text = "Text",
    --何文字並ぶか
    text_str_max = 14,
    --何行表示
    text_line_max = 9,
    --コメント保持
    save_coment_str = {},
    --凸者保持
    save_convex_str = ""
}
--遷移マテリアル名称
for i = 1, CAPA_CLOCK_DATA.str_material_num do
    CAPA_CLOCK_DATA.material[i] = CAPA_CLOCK_DATA.str_material .. tostring(i)
end
ASSET.SetText(COMENT_VIEWER.str_text, "")

--時間処理
local timer = os.clock()
local timer_count = 1 / 10
function updateAll()
    --時間管理
    if TimeManage(timer, timer_count) then
        --自分の強制表示
        if MINE_DATE_ONLY then
            --出した人のみ
            if ASSET.IsMine then
                --時間関連
                local date = os.date("*t")
                --時間表示
                local offset = Vector2.zero
                for i = 1, #CAPA_CLOCK_DATA.str_date do
                    local num = date[CAPA_CLOCK_DATA.str_date[i]]
                    if num < 10 then
                        --0.6は0基準-0.1すると1...
                        offset.x = 0.6
                        ASSET._ALL_SetMaterialTextureOffsetFromName(CAPA_CLOCK_DATA.material[(i - 1) * 2 + 1], offset)
                        offset.x = 0.6 - num * 0.1
                        ASSET._ALL_SetMaterialTextureOffsetFromName(CAPA_CLOCK_DATA.material[i * 2], offset)
                    else
                        --2桁目
                        offset.x = 0.6 - math.floor(num / 10) * 0.1
                        ASSET._ALL_SetMaterialTextureOffsetFromName(CAPA_CLOCK_DATA.material[(i - 1) * 2 + 1], offset)
                        --1桁目
                        offset.x = 0.6 - (num % 10) * 0.1
                        ASSET._ALL_SetMaterialTextureOffsetFromName(CAPA_CLOCK_DATA.material[i * 2], offset)
                    end
                end
            end
        else
            --時間関連
            local date = os.date("*t")
            --時間表示
            local offset = Vector2.zero
            for i = 1, #CAPA_CLOCK_DATA.str_date do
                local num = date[CAPA_CLOCK_DATA.str_date[i]]
                if num < 10 then
                    --0.6は0基準-0.1すると1...
                    offset.x = 0.6
                    ASSET.SetMaterialTextureOffsetFromName(CAPA_CLOCK_DATA.material[(i - 1) * 2 + 1], offset)
                    offset.x = 0.6 - num * 0.1
                    ASSET.SetMaterialTextureOffsetFromName(CAPA_CLOCK_DATA.material[i * 2], offset)
                else
                    --2桁目
                    offset.x = 0.6 - math.floor(num / 10) * 0.1
                    ASSET.SetMaterialTextureOffsetFromName(CAPA_CLOCK_DATA.material[(i - 1) * 2 + 1], offset)
                    --1桁目
                    offset.x = 0.6 - (num % 10) * 0.1
                    ASSET.SetMaterialTextureOffsetFromName(CAPA_CLOCK_DATA.material[i * 2], offset)
                end
            end
        end
    end
end

--時間管理用
function TimeManage(now_time, time_span)
    --指定時間超え
    if (os.clock() - now_time) > time_span then
        now_time = os.clock()
        return true
    end
    return false
end

local count = 1
function onUse(use)
    if count % 2 == 0 then
        ComentStrShow(0, 0, 0)
        count = count + 1
    else
        --ConvexStrShow()
        count = count + 1
    end
end

--コメント
function onMessage(sender, name, message)
    ComentStrShow(sender, name, message)
end
vci.message.On("comment", onMessage)

function ComentStrShow(sender, name, message)
    if ASSET.IsMine then
        if message ~= 0 then
            --名前
            local name = sender["name"]
            if name == "" then
                name = "184:"
            else
                name = name .. ":"
            end
            --コメント保持数
            local coment_count = #COMENT_VIEWER.save_coment_str + 1

            --名前追加
            COMENT_VIEWER.save_coment_str[coment_count] = name

            --コメント部追加
            COMENT_VIEWER.save_coment_str[coment_count] = COMENT_VIEWER.save_coment_str[coment_count] .. message
        end
        --行数カウント
        local line = 0
        --表示コメント
        local show_str = ""
        for i = #COMENT_VIEWER.save_coment_str, 1, -1 do
            --文字数
            local str_count = string.len(COMENT_VIEWER.save_coment_str[i])
            str_count = ReturnStrfunc(COMENT_VIEWER.save_coment_str[i])
            --繰り上げ
            local before_line = math.ceil((str_count - 1) / (COMENT_VIEWER.text_str_max * 2))
            line = line + before_line

            --行数超えた
            if line > COMENT_VIEWER.text_line_max then
                --行数確認
                local line_count = 1
                --差分
                local set_line = line - COMENT_VIEWER.text_line_max
                --追加行数
                local data =
                    math.ceil((ReturnStrfunc(COMENT_VIEWER.save_coment_str[i]) - 1) / (COMENT_VIEWER.text_str_max * 2))
                --保持長さ
                local save_length = 1
                --文字長さ取得
                for length = 1, string.len(COMENT_VIEWER.save_coment_str[i]) do
                    --指定文字数コメント取得
                    local coment_data = string.sub(COMENT_VIEWER.save_coment_str[i], save_length, length)
                    local str_data = ReturnStrfunc(coment_data)
                    --小文字込み横の限界
                    if str_data > COMENT_VIEWER.text_str_max * 2 then
                        save_length = length + 1
                        --行数と追加したいぎょうずう
                        if data - set_line < line_count - 1 then
                            if show_str ~= "" then
                                show_str = show_str .. "\n"
                            end
                            show_str = show_str .. coment_data
                        end
                        line_count = line_count + 1
                    elseif length == string.len(COMENT_VIEWER.save_coment_str[i]) then
                        show_str = show_str .. coment_data
                        break
                    end
                end

                --1つ新しいのから保存
                for add = i + 1, #COMENT_VIEWER.save_coment_str do
                    --保持長さ
                    local save_length = 1
                    --文字長さ取得
                    for length = 1, string.len(COMENT_VIEWER.save_coment_str[add]) do
                        --指定文字数コメント取得
                        local coment_data = string.sub(COMENT_VIEWER.save_coment_str[add], save_length, length)
                        local str_data = ReturnStrfunc(coment_data)
                        --小文字込み横の限界
                        if str_data > COMENT_VIEWER.text_str_max * 2 then
                            save_length = length + 1

                            if show_str ~= "" then
                                show_str = show_str .. "\n"
                            end
                            show_str = show_str .. coment_data
                        elseif length == string.len(COMENT_VIEWER.save_coment_str[add]) then
                            if show_str ~= "" then
                                show_str = show_str .. "\n"
                            end
                            show_str = show_str .. coment_data
                            break
                        end
                    end
                end

                break
            elseif line == COMENT_VIEWER.text_line_max then
                --保存
                for add = i, #COMENT_VIEWER.save_coment_str do
                    --保持長さ
                    local save_length = 1
                    --文字長さ取得
                    for length = 1, string.len(COMENT_VIEWER.save_coment_str[add]) do
                        --指定文字数コメント取得
                        local coment_data = string.sub(COMENT_VIEWER.save_coment_str[add], save_length, length)
                        local str_data = ReturnStrfunc(coment_data)
                        --小文字込み横の限界
                        if str_data > COMENT_VIEWER.text_str_max * 2 then
                            save_length = length + 1

                            if show_str ~= "" then
                                show_str = show_str .. "\n"
                            end
                            show_str = show_str .. coment_data
                        elseif length == string.len(COMENT_VIEWER.save_coment_str[add]) then
                            if show_str ~= "" then
                                show_str = show_str .. "\n"
                            end
                            show_str = show_str .. coment_data
                        end
                    end
                end
                break
            elseif i == 1 then
                --保存
                for add = i, #COMENT_VIEWER.save_coment_str do
                    --保持長さ
                    local save_length = 1
                    --文字長さ取得
                    for length = 1, string.len(COMENT_VIEWER.save_coment_str[add]) do
                        --指定文字数コメント取得
                        local coment_data = string.sub(COMENT_VIEWER.save_coment_str[add], save_length, length)
                        local str_data = ReturnStrfunc(coment_data)
                        --小文字込み横の限界
                        if str_data > COMENT_VIEWER.text_str_max * 2 then
                            save_length = length + 1

                            if show_str ~= "" then
                                show_str = show_str .. "\n"
                            end
                            show_str = show_str .. coment_data
                        elseif length == string.len(COMENT_VIEWER.save_coment_str[add]) then
                            if show_str ~= "" then
                                show_str = show_str .. "\n"
                            end
                            show_str = show_str .. coment_data
                        end
                    end
                end
            end
        end

        if count % 2 == 1 or name == 0 then
            ASSET._ALL_SetText(COMENT_VIEWER.str_text, show_str)
        end

        if #COMENT_VIEWER.save_coment_str > 15 then
            local save_str = {}
            local save_count = 0
            for i = #COMENT_VIEWER.save_coment_str - 14, #COMENT_VIEWER.save_coment_str do
                local str = COMENT_VIEWER.save_coment_str[i]
                save_str[15 - save_count] = str
                save_count = save_count + 1
            end
            COMENT_VIEWER.save_coment_str = {}
            for i = 1, #save_str do
                COMENT_VIEWER.save_coment_str[i] = save_str[i]
            end
        end
    end
end

--凸者
function onConvexMessage(sender, name, message)
    --凸者
    if message == "joined" or message == "left" then
        ConvexStrShow()
    end
end
vci.message.On("notification", onConvexMessage)

function ConvexStrShow()
    if ASSET.IsMine then
        --アバターデータ取得
        local aveter_data = STUDIO.GetAvatars()
        --前置き
        COMENT_VIEWER.save_convex_str = "　　　　　　  凸者一覧\n"
        --横に並ぶ文字数
        local put_char = 0
        for i = 1, #aveter_data do
            --名前
            local name = aveter_data[i].GetName()
            local len = ReturnStrfunc(name)
            if put_char + len > (1 + ((i - 1) % 2)) * COMENT_VIEWER.text_str_max * 2 then
                COMENT_VIEWER.save_convex_str = COMENT_VIEWER.save_convex_str .. "\n"
                put_char = 0
            end
            COMENT_VIEWER.save_convex_str = COMENT_VIEWER.save_convex_str .. aveter_data[i].GetName()
            for i = 1, (COMENT_VIEWER.text_str_max * 2 - len - 2) do
                COMENT_VIEWER.save_convex_str = COMENT_VIEWER.save_convex_str .. " "
                put_char = put_char + 1
            end
        end
        ASSET._ALL_SetText(COMENT_VIEWER.str_text, COMENT_VIEWER.save_convex_str)
    end
end

--文字何文字分かを返す
function ReturnStrfunc(str)
    --文字数
    local return_len = 0
    --文字数で回す
    for i = 1, string.len(str) do
        --文字取得
        local char = string.sub(str, i, i)
        --大文字小文字変化しない(英数字以外)
        if (char == string.upper(char)) or (char ~= string.lower(char)) then
            return_len = return_len + 2
        else
            return_len = return_len + 1
        end
    end
    return return_len
end
