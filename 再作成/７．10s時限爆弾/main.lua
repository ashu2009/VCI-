--簡略化
local STATE = vci.state
local ASSET = vci.assets
local ASHU_MESS = "ASHU_10sBOMB_MESS_"

--爆弾パラメータ
local DATA = {
    --Unity名称
    str = {
        "爆弾",
        "Start",
        "Cube",
        "Ring (",
        "正 (",
        "負 ("
    },
    str_si = {},
    --爆弾
    bomb_num = 1,
    --開始
    start_num = 2,
    --盤
    cube_num = 3,
    --腕輪
    ring_si = {},
    ring_num = 4,
    ring_max = 10,
    --正
    pos_si = {},
    pos_num = 5,
    code_max = 4,
    --負
    nega_si = {},
    nega_num = 6,
    --アニメーションデータ
    str_anim = {"初期化", "１段階目", "2段階目", "３段階　爆発", "爆発"},
    --音
    sound_str = "explosion3",
    sound_str1 = "時限式",
    --リング最小径
    dist_min = 0.7,
    --爆弾上空配位置
    add_bomb = 0.3
}
local MOVE = {
    --タイマー変更フラグ
    timer_change = false,
    --タイマー開始
    timer_start = false,
    --タイマー開始時の時間
    timer_clock = 0,
    --タイマー正フラグ
    timer_pos = {},
    --爆弾のリング番号
    bomb_ring = 0,
    --設定時間
    def_clock = 20,
    --見える時間
    show_clock = 0,
    --アニメーション番号
    anim_num = 1
}
--サブアイテム関連
for i = 1, #DATA.str do
    if i == DATA.bomb_num then
        DATA.str_si[i] = ASSET.GetSubItem(DATA.str[i])
    elseif i == DATA.start_num then
        DATA.str_si[i] = ASSET.GetSubItem(DATA.str[i])
    elseif i == DATA.cube_num then
        DATA.str_si[i] = ASSET.GetSubItem(DATA.str[i])
    elseif i == DATA.ring_num then
        for i2 = 1, DATA.ring_max do
            DATA.ring_si[i2] = ASSET.GetSubItem(DATA.str[i] .. tostring(i2) .. ")")
        end
    elseif i == DATA.pos_num then
        for i2 = 1, DATA.code_max do
            DATA.pos_si[i2] = ASSET.GetSubItem(DATA.str[i] .. tostring(i2) .. ")")
        end
    elseif i == DATA.nega_num then
        for i2 = 1, DATA.code_max do
            DATA.nega_si[i2] = ASSET.GetSubItem(DATA.str[i] .. tostring(i2) .. ")")
        end
    end
end

--メイン時間
local m_timer = 0
--時間間隔
local m_timer_cnt = 1 / 30
--初期化フラグ
local first_flg = true
function update()
    if (os.clock() - m_timer) > m_timer_cnt then
        if first_flg then
            --初期化
            FirstDataSet()
            first_flg = false
        end

        Main()
        m_timer = os.clock()
    end
end

--初期化
function FirstDataSet()
    for i = 1, DATA.code_max do
        MOVE.timer_pos[i] = 0
        STATE.Set("TIMER_POS" .. tostring(i), MOVE.timer_pos[i])
    end
    STATE.Set("TIMER", MOVE.timer_change)
    STATE.Set("TIMER_START", MOVE.timer_start)
    STATE.Set("BOMB_RING", MOVE.bomb_ring)
    MOVE.show_clock = MOVE.def_clock + os.clock()
    TimerFunc()
    MOVE.anim_num = 1
    vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
end

--メイン処理
function Main()
    --正負増減
    NegaPosFunc()

    --フラグあるならばon/off切替
    if MOVE.timer_change then
        --切替
        MOVE.timer_start = not MOVE.timer_start
        --onならば
        if MOVE.timer_start then
            --起動時間保存
            MOVE.timer_clock = os.clock()
            MOVE.show_clock = MOVE.def_clock + os.clock()
            local now_bomb_pos = DATA.str_si[DATA.bomb_num].GetPosition()
            local min_dist = 10000000
            local min_num = 0
            for i = 1, DATA.ring_max do
                local ring = DATA.ring_si[i]
                local ring_pos = ring.GetPosition()
                --リング間距離
                local dist = Vector3.Distance(now_bomb_pos, ring_pos)
                if dist < min_dist then
                    min_dist = dist
                    min_num = i
                end
            end
            if min_num > 0 then
                STATE.Set("BOMB_RING", min_num)
            end
        else
            MOVE.show_clock = MOVE.def_clock + os.clock()
            TimerFunc()
            STATE.Set("BOMB_RING", 0)
            AllStopAudio(DATA.sound_str1)
        end
        STATE.Set("TIMER_START", MOVE.timer_start)
        MOVE.timer_change = false
        STATE.Set("TIMER", false)
        MOVE.anim_num = 1
        vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
    end
end

--正負増減
function NegaPosFunc()
    if not MOVE.timer_start then
        --正負増減
        for i = 1, DATA.code_max do
            if MOVE.timer_pos[i] > 0 then
                if i == 4 then
                    if (MOVE.def_clock % 10) == 9 then
                        MOVE.def_clock = MOVE.def_clock - 9
                    else
                        MOVE.def_clock = MOVE.def_clock + 1
                    end
                elseif i == 3 then
                    if math.floor((MOVE.def_clock % 60) / 10) == 5 then
                        MOVE.def_clock = MOVE.def_clock - 5 * 10
                    else
                        MOVE.def_clock = MOVE.def_clock + 10
                    end
                elseif i == 2 then
                    if math.floor((MOVE.def_clock % (60 * 10)) / 60) == 9 then
                        MOVE.def_clock = MOVE.def_clock - 9 * 60
                    else
                        MOVE.def_clock = MOVE.def_clock + 60
                    end
                elseif i == 1 then
                    if math.floor((MOVE.def_clock % (60 * 10 * 10)) / (60 * 10)) == 9 then
                        MOVE.def_clock = MOVE.def_clock - 9 * 60 * 10
                    else
                        MOVE.def_clock = MOVE.def_clock + 60 * 10
                    end
                end
                MOVE.show_clock = MOVE.def_clock + os.clock()
                TimerFunc()
                MOVE.timer_pos[i] = 0
                STATE.Set("TIMER_POS" .. tostring(i), MOVE.timer_pos[i])
                vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
            elseif MOVE.timer_pos[i] < 0 then
                if i == 4 then
                    if (MOVE.def_clock % 10) == 0 then
                        MOVE.def_clock = MOVE.def_clock + 9
                    else
                        MOVE.def_clock = MOVE.def_clock - 1
                    end
                elseif i == 3 then
                    if math.floor((MOVE.def_clock % 60) / 9) == 0 then
                        MOVE.def_clock = MOVE.def_clock + 5 * 10
                    else
                        MOVE.def_clock = MOVE.def_clock - 10
                    end
                elseif i == 2 then
                    if math.floor((MOVE.def_clock % (60 * 10)) / 60) == 0 then
                        MOVE.def_clock = MOVE.def_clock + 9 * 60
                    else
                        MOVE.def_clock = MOVE.def_clock - 60
                    end
                elseif i == 1 then
                    if math.floor((MOVE.def_clock % (60 * 10 * 10)) / (60 * 10)) == 0 then
                        MOVE.def_clock = MOVE.def_clock + 9 * 60 * 10
                    else
                        MOVE.def_clock = MOVE.def_clock - 60 * 10
                    end
                end
                MOVE.show_clock = MOVE.def_clock + os.clock()
                TimerFunc()
                MOVE.timer_pos[i] = 0
                STATE.Set("TIMER_POS" .. tostring(i), MOVE.timer_pos[i])
                vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
            end
        end
    else
        TimerFunc()
        for i = 1, DATA.code_max do
            if MOVE.timer_pos[i] ~= 0 then
                MOVE.timer_pos[i] = 0
                STATE.Set("TIMER_POS" .. tostring(i), MOVE.timer_pos[i])
                vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
            end
        end
    end
end

--時間処理
function TimerFunc()
    --時間制御
    local timer = MOVE.show_clock - os.clock()

    if MOVE.timer_start and MOVE.anim_num == 1 then
        AllStopAudio(DATA.sound_str1)
        ASSET.audio._ALL_Play(DATA.sound_str1, 1, true)
    elseif not MOVE.timer_start then
        AllStopAudio(DATA.sound_str1)
    end
    if 0 >= timer then
        if MOVE.anim_num == 5 then
            PlayAnimation(DATA.str_anim[MOVE.anim_num])
            MOVE.anim_num = 6
        end
        timer = MOVE.def_clock
        MOVE.timer_start = false
        STATE.Set("TIMER_START", false)
        AllStopAudio(DATA.sound_str1)
        AllPlayAudio(DATA.sound_str)
    elseif MOVE.def_clock / 4 >= timer then
        if MOVE.anim_num == 4 then
            PlayAnimation(DATA.str_anim[MOVE.anim_num])
            MOVE.anim_num = 5
        end
    elseif MOVE.def_clock / 2 >= timer then
        if MOVE.anim_num == 3 then
            PlayAnimation(DATA.str_anim[MOVE.anim_num])
            MOVE.anim_num = 4
        end
    elseif MOVE.def_clock * 3 / 4 >= timer then
        if MOVE.anim_num == 2 then
            PlayAnimation(DATA.str_anim[MOVE.anim_num])
            MOVE.anim_num = 3
        end
    else
        if MOVE.anim_num == 1 then
            PlayAnimation(DATA.str_anim[MOVE.anim_num])
            MOVE.anim_num = 2
        end
    end

    local str = ""
    if math.floor(timer / 60) < 10 then
        str = str .. "0"
    end
    str = str .. tostring(math.floor(timer / 60)) .. ":"
    if math.floor(timer % 60) == 0 then
        str = str .. "0" .. tostring(math.floor(timer) % 60)
    elseif math.floor(timer % 60) < 10 then
        str = str .. "0" .. tostring(math.floor(timer) % 60)
    else
        str = str .. tostring(math.floor(timer) % 60)
    end
    ASSET._ALL_SetText("時間", str)
end

--時間処理
local timer = os.clock()
local timer_count = 1 / 30
--nilにするタイマー
local nil_wait_timer = os.clock()
--nilにする時間
local nil_wait_timer_count = 1 / 15
function updateAll()
    if (os.clock() - timer) > timer_count then
        if nil_wait_timer ~= 0 and (os.clock() - nil_wait_timer) > nil_wait_timer_count then
            BoardStateSet()
            --2度はいらない
            nil_wait_timer = 0
        end

        if nil_wait_timer == 0 then
            AllMain()
        end
        timer = os.clock()
    end
end

--全員用
function AllMain()
    for i = 1, DATA.code_max do
        local main = DATA.str_si[DATA.cube_num]
        local pos = main.GetLocalPosition()
        local rot = main.GetRotation().eulerAngles
        local set_pos = Vector3.__new(pos.x, pos.y, pos.z)
        local nega_si = DATA.nega_si[i]
        local add_pos_z = 0
        if i > 2 then
            add_pos_z = 0.05
        end
        if nega_si.IsMine then
            set_pos = pos + RelativeToLocalCoordinates(main, 0, -0.3, 0.2 * i - 0.52 + add_pos_z)
            nega_si.SetLocalPosition(set_pos)
            Rot_Quat_Euler(nega_si, rot.x, rot.y + 90, rot.z)
        end
        local pos_si = DATA.pos_si[i]
        if pos_si.IsMine then
            set_pos = pos + RelativeToLocalCoordinates(main, 0, 0.3, 0.2 * i - 0.52 + add_pos_z)
            pos_si.SetLocalPosition(set_pos)
            pos_si.SetRotation(main.GetRotation())
            Rot_Quat_Euler(pos_si, rot.x, rot.y + 90, rot.z)
        end
    end

    --腕輪番号あり
    if MOVE.timer_start then
        if MOVE.bomb_ring > 0 then
            local bomb = DATA.str_si[DATA.bomb_num]
            if bomb.IsMine then
                local ring = DATA.ring_si[MOVE.bomb_ring]
                local ring_pos = ring.GetPosition()
                local ring_rot = ring.GetRotation().eulerAngles
                ring_rot.x = 0
                ring_rot.z = 0
                ring_pos.y = ring_pos.y + DATA.add_bomb
                bomb.SetPosition(ring_pos)
                Rot_Quat_Euler(bomb, ring_rot.x, ring_rot.y, ring_rot.z)
            end
        end
    end
end

function onUse(use)
    --正負
    for i = 1, DATA.code_max do
        if use == DATA.nega_si[i].GetName() then
            STATE.Set("TIMER_POS" .. tostring(i), -1)
            vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
            break
        end
        if use == DATA.pos_si[i].GetName() then
            STATE.Set("TIMER_POS" .. tostring(i), 1)
            vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
            break
        end
    end
    --スタート押してフラグ逆転
    if use == DATA.str[DATA.start_num] then
        STATE.Set("TIMER", true)
        vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
    end
    --腕輪
    for i = 1, DATA.ring_max do
        if MOVE.bomb_ring == i then
            local now_ring = DATA.ring_si[i]
            local now_ring_pos = now_ring.GetPosition()
            if use == DATA.ring_si[i].GetName() then
                local min_dist = 10000
                local min_num = 0
                for i2 = 1, DATA.ring_max do
                    if i ~= i2 then
                        local ring = DATA.ring_si[i2]
                        local ring_pos = ring.GetPosition()
                        --リング間距離
                        local dist = Vector3.Distance(now_ring_pos, ring_pos)
                        if (dist < min_dist) and (dist < DATA.dist_min) then
                            min_dist = dist
                            min_num = i2
                        end
                    end
                end
                if min_num > 0 then
                    STATE.Set("BOMB_RING", min_num)
                    vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
                end
            end
        end
    end
end

--ボードのステート処理
function BoardStateSet()
    for i = 1, DATA.code_max do
        MOVE.timer_pos[i] = STATE.Get("TIMER_POS" .. tostring(i))
    end
    MOVE.timer_change = STATE.Get("TIMER")
    MOVE.timer_start = STATE.Get("TIMER_START")
    local data = STATE.Get("BOMB_RING")
    if MOVE.bomb_ring ~= data then
        MOVE.show_clock = MOVE.def_clock + os.clock()
        MOVE.anim_num = 1
    end
    MOVE.bomb_ring = data
end

--ボードの初期化メッセージ
function BoardNillMess(sender, name, message)
    nil_wait_timer = os.clock()
end
vci.message.On(ASHU_MESS .. "BOARD_NILL", BoardNillMess)

--subitemをEuler角の値に変更
function Rot_Quat_Euler(subitem, x, y, z)
    subitem.SetRotation(Quaternion.Euler(x, y, z))
end
function PlayAnimation(key)
    ASSET._ALL_PlayAnimationFromName(key, false)
end
function StopAnimation()
    --- 問答無用で全アニメーションを止める
    ASSET._ALL_StopAnimation()
end

--指定した音を鳴らす
function AllStopAudio(sound_name)
    ASSET._ALL_StopAudioFromName(sound_name)
end
--指定した音を鳴らす
function AllPlayAudio(sound_name)
    ASSET._ALL_PlayAudioFromName(sound_name)
end

--位置計算(相対座標をローカル座標に)
function RelativeToLocalCoordinates(fn_subitem, fn_put_x, fn_put_y, fn_put_z)
    local item = fn_subitem
    local item_ang = item.GetLocalRotation().eulerAngles
    item_ang.x = -item_ang.x
    item_ang.y = -item_ang.y
    item_ang.z = -item_ang.z

    local c_y = math.cos(item_ang.y / 180 * math.pi)
    local c_z = math.cos(item_ang.z / 180 * math.pi)
    local s_x = math.sin(item_ang.x / 180 * math.pi)
    local s_y = math.sin(item_ang.y / 180 * math.pi)
    local s_z = math.sin(item_ang.z / 180 * math.pi)
    local c_x = math.cos(item_ang.x / 180 * math.pi)

    local fn1 = c_y * c_z - s_x * s_y * s_z
    local fn2 = -c_x * s_z
    local fn3 = s_y * c_z + s_x * c_y * s_z

    local fn4 = c_y * s_z + s_x * s_y * c_z
    local fn5 = c_x * c_z
    local fn6 = s_y * s_z - s_x * c_y * c_z

    local fn7 = -c_x * s_y
    local fn8 = s_x
    local fn9 = c_x * c_y

    local x2 = fn_put_x * fn1 + fn_put_y * fn4 + fn_put_z * fn7
    local y2 = fn_put_x * fn2 + fn_put_y * fn5 + fn_put_z * fn8
    local z2 = fn_put_x * fn3 + fn_put_y * fn6 + fn_put_z * fn9

    return Vector3.__new(x2, y2, z2)
end
