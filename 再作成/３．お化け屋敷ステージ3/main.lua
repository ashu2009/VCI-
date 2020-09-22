--簡略化
local ASSET = vci.assets
local STATE = vci.state
local WHITE = Color.__new(1, 1, 1, 1)
local BLACK = Color.__new(0.2, 0.2, 0.2, 1)
local ASHU_MESS = "ASHU_2019_OBAKESTAGE3_MESS_"

local DATA = {
    --本体
    str = {"ボロボロのタヌキ", "幻想花 (1)", "日記帳", "回る机たち", "Knife", "SchoolBag_high"},
    str_si = {},
    --狸
    str_raccoon_num = 1,
    raccoon_pos = Vector3.__new(-4.43, 0.99, -0.92),
    raccoon_rot = Vector3.__new(-90, 0, 0),
    raccoon_scale = Vector3.__new(7, 6, 6),
    --花
    str_flower_num = 2,
    flower_pos = Vector3.__new(-0.806, 0.272, -0.599),
    flower_rot = Vector3.__new(63.855, 90, 0),
    flower_scale = Vector3.__new(1, 1, 1),
    --日記
    str_diary_num = 3,
    diary_pos = Vector3.__new(-0.72, 0.05, -0.573),
    diary_rot = Vector3.__new(-90, 0, 0),
    diary_scale = Vector3.__new(100, 100, 100),
    --机
    str_desk_num = 4,
    --ナイフ
    str_knife_num = 5,
    knife_pos = Vector3.__new(-0.879, 0.789, 0.094),
    knife_rot = Vector3.__new(90, 0, 0),
    knife_scale = Vector3.__new(2, 2, 2),
    --バッグ
    str_bag_num = 6,
    bag_pos = Vector3.__new(-0.8, 0.58, 0.07),
    bag_rot = Vector3.__new(0, 0, -90),
    bag_scale = Vector3.__new(1, 1, 1),
    --ボタン
    str_button = {"狸スイッチ", "花・日記スイッチ", "バッグスイッチ", "ロッカー☆.001 (1)", "ドア.右 (1)"},
    str_button_si = {},
    --狸
    str_raccoon_button_num = 1,
    --花
    str_flower_button_num = 2,
    --バッグ
    str_bag_button_num = 3,
    --ロッカー
    str_locker_button_num = 4,
    locker_pos = Vector3.__new(0, 0, 0),
    locker_rot = Vector3.__new(-90, 0, -90),
    --扉
    str_door_button_num = 5,
    door_pos = Vector3.__new(0, 0, -5.22),
    door_rot = Vector3.__new(-90, 0, -90),
    --マテリアル関係
    str_material = {"狸", "花日記", "バッグ"},
    str_hand = "腕 (",
    str_hand_si = {},
    hand_max = 14,
    hand_scale = Vector3.__new(1, 0.8, 1.25),
    --回転速度
    add_ang = 1,
    --赤い部屋
    str_red_room = "血まみれ",
    str_red_rom_si = "",
    red_room_scale = Vector3.__new(67.48661, 50.66745, 51.18719)
}

local MOVE = {
    --狸
    raccoon_flg = 0,
    --花
    flower_flg = 0,
    --バッグ
    bag_flg = 0,
    --ロッカー
    locker_flg = 0,
    --扉
    door_flg = 0,
    door_clock = 0,
    --机
    desk_flg = 0,
    --ナイフ
    knife_flg = 0
}

--サブアイテム関連
for i = 1, #DATA.str do
    DATA.str_si[i] = ASSET.GetSubItem(DATA.str[i])
end
for i = 1, #DATA.str_button do
    DATA.str_button_si[i] = ASSET.GetSubItem(DATA.str_button[i])
end
for i = 1, DATA.hand_max do
    DATA.str_hand_si[i] = ASSET.GetSubItem(DATA.str_hand .. tostring(i) .. ")")
end
DATA.str_red_rom_si = ASSET.GetSubItem(DATA.str_red_room)

if ASSET.IsMine then
    STATE.Set(DATA.str_button[DATA.str_raccoon_button_num], MOVE.raccoon_flg)
    STATE.Set(DATA.str_button[DATA.str_flower_button_num], MOVE.flower_flg)
    STATE.Set(DATA.str_button[DATA.str_bag_button_num], MOVE.bag_flg)
    STATE.Set(DATA.str_button[DATA.str_locker_button_num], MOVE.locker_flg)
    STATE.Set(DATA.str_button[DATA.str_door_button_num], MOVE.door_flg)
    STATE.Set(DATA.str[DATA.str_desk_num], MOVE.desk_flg)
    STATE.Set(DATA.str[DATA.str_knife_num], MOVE.knife_flg)
    for i = 1, #DATA.str_material do
        ASSET._ALL_SetMaterialColorFromName(DATA.str_material[i], WHITE)
    end
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

        --nilタイマー起動後
        if nil_wait_timer == 0 then
            --全員処理用
            AllMainFunc()
        end
        timer = os.clock()
    end
end

--全員処理用
function AllMainFunc()
    --狸
    --縮小
    if MOVE.raccoon_flg == 0 then
        local raccoon = DATA.str_si[DATA.str_raccoon_num]
        if raccoon.IsMine then
            raccoon.SetLocalPosition(DATA.raccoon_pos)
            Rot_Local_Quat_Euler(raccoon, DATA.raccoon_rot.x, DATA.raccoon_rot.y, DATA.raccoon_rot.z)
            raccoon.SetLocalScale(Vector3.__new(1 / 1000, 1 / 1000, 1 / 1000))
            --待機
            STATE.Set(DATA.str_button[DATA.str_raccoon_button_num], MOVE.raccoon_flg + 1)
            vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
        end
    elseif MOVE.raccoon_flg == 2 then
        local raccoon = DATA.str_si[DATA.str_raccoon_num]
        if raccoon.IsMine then
            raccoon.SetLocalScale(DATA.raccoon_scale)
            --待機
            STATE.Set(DATA.str_button[DATA.str_raccoon_button_num], MOVE.raccoon_flg + 1)
            vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
        end
    end

    --花
    --縮小
    if MOVE.flower_flg == 0 then
        local flower = DATA.str_si[DATA.str_flower_num]
        if flower.IsMine then
            flower.SetLocalPosition(DATA.flower_pos)
            Rot_Local_Quat_Euler(flower, DATA.flower_rot.x, DATA.flower_rot.y, DATA.flower_rot.z)
            flower.SetLocalScale(Vector3.__new(1 / 1000, 1 / 1000, 1 / 1000))
            --待機
            STATE.Set(DATA.str_button[DATA.str_flower_button_num], 10)
            vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
        end
    elseif MOVE.flower_flg == 2 then
        local flower = DATA.str_si[DATA.str_flower_num]
        if flower.IsMine then
            flower.SetLocalScale(DATA.flower_scale)
            --待機
            STATE.Set(DATA.str_button[DATA.str_flower_button_num], 20)
            vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
        end
    elseif MOVE.flower_flg == 10 then
        --日記
        local diary = DATA.str_si[DATA.str_diary_num]
        if diary.IsMine then
            diary.SetLocalPosition(DATA.diary_pos)
            Rot_Local_Quat_Euler(diary, DATA.diary_rot.x, DATA.diary_rot.y, DATA.diary_rot.z)
            diary.SetLocalScale(Vector3.__new(1 / 1000, 1 / 1000, 1 / 1000))
            --待機
            STATE.Set(DATA.str_button[DATA.str_flower_button_num], 1)
            vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
        end
    elseif MOVE.flower_flg == 20 then
        --日記
        local diary = DATA.str_si[DATA.str_diary_num]
        if diary.IsMine then
            diary.SetLocalScale(DATA.diary_scale)
            --待機
            STATE.Set(DATA.str_button[DATA.str_flower_button_num], 3)
            vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
        end
    end

    --バッグ
    --縮小
    if MOVE.bag_flg == 0 then
        local bag = DATA.str_si[DATA.str_bag_num]
        local red_room = DATA.str_red_rom_si
        if bag.IsMine then
            red_room.SetLocalScale(Vector3.__new(1 / 1000, 1 / 1000, 1 / 1000))
            bag.SetLocalPosition(DATA.bag_pos)
            Rot_Local_Quat_Euler(bag, DATA.bag_rot.x, DATA.bag_rot.y, DATA.bag_rot.z)
            bag.SetLocalScale(Vector3.__new(1 / 1000, 1 / 1000, 1 / 1000))
            --待機
            STATE.Set(DATA.str_button[DATA.str_bag_button_num], MOVE.bag_flg + 1)
            vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
        end
    elseif MOVE.bag_flg == 2 then
        local bag = DATA.str_si[DATA.str_bag_num]
        if bag.IsMine then
            bag.SetLocalScale(DATA.bag_scale)
            --待機
            STATE.Set(DATA.str_button[DATA.str_bag_button_num], MOVE.bag_flg + 1)
            vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
        end
    end

    --ロッカー
    --縮小
    if MOVE.locker_flg == 0 then
        local locker = DATA.str_button_si[DATA.str_locker_button_num]
        local locker2 = ASSET.GetSubItem("ロッカー☆.001")
        if locker.IsMine then
            locker.SetLocalPosition(DATA.locker_pos)
            locker2.SetLocalPosition(Vector3.zero)
            Rot_Local_Quat_Euler(locker, DATA.locker_rot.x, DATA.locker_rot.y, DATA.locker_rot.z)
            --待機
            STATE.Set(DATA.str_button[DATA.str_locker_button_num], MOVE.locker_flg + 1)
            vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
        elseif MOVE.locker_flg == 2 then
            local locker = DATA.str_button_si[DATA.str_locker_button_num]
            if locker.IsMine then
                locker.SetLocalPosition(Vector3.__new(0, 100000, 0))
                --待機
                STATE.Set(DATA.str_button[DATA.str_locker_button_num], MOVE.locker_flg + 1)
                vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
            end
        end
    end

    --扉
    --縮小
    if MOVE.door_flg == 0 then
        local door = DATA.str_button_si[DATA.str_door_button_num]
        if door.IsMine then
            door.SetLocalPosition(DATA.door_pos)
            Rot_Local_Quat_Euler(door, DATA.door_rot.x, DATA.door_rot.y, DATA.door_rot.z)
            --待機
            STATE.Set(DATA.str_button[DATA.str_door_button_num], MOVE.door_flg + 1)
            vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
        end
    elseif MOVE.door_flg == 2 then
        local door = DATA.str_button_si[DATA.str_door_button_num]
        --3秒待機
        if door.IsMine and (os.clock() - MOVE.door_clock) > 3 then
            --待機
            STATE.Set(DATA.str_button[DATA.str_door_button_num], 0)
            vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
            PlayAnimation("ドア閉まる")
        end
    end

    --ナイフ
    --縮小
    if MOVE.knife_flg == 0 then
        local knife = DATA.str_si[DATA.str_knife_num]
        if knife.IsMine then
            knife.SetLocalPosition(DATA.knife_pos)
            Rot_Local_Quat_Euler(knife, DATA.knife_rot.x, DATA.knife_rot.y, DATA.knife_rot.z)
            knife.SetLocalScale(Vector3.__new(1 / 1000, 1 / 1000, 1 / 1000))
            --待機
            STATE.Set(DATA.str[DATA.str_knife_num], 10)
            vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
        end
    elseif MOVE.knife_flg == 2 then
        local knife = DATA.str_si[DATA.str_knife_num]
        if knife.IsMine then
            knife.SetLocalScale(DATA.knife_scale)
            --待機
            STATE.Set(DATA.str[DATA.str_knife_num], 20)
            vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
        end
    elseif MOVE.knife_flg == 10 then
        local red_room = DATA.str_red_rom_si
        if red_room.IsMine then
            red_room.SetLocalScale(Vector3.__new(1 / 1000, 1 / 1000, 1 / 1000))
            --待機
            STATE.Set(DATA.str[DATA.str_knife_num], 1)
            vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
        end
    elseif MOVE.knife_flg == 20 then
        local red_room = DATA.str_red_rom_si
        if red_room.IsMine then
            red_room.SetLocalScale(DATA.red_room_scale)
            --待機
            STATE.Set(DATA.str[DATA.str_knife_num], 21)
            vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
        end
    elseif MOVE.knife_flg == 21 then
        for i = 1, DATA.hand_max do
            local hand = DATA.str_hand_si[i]
            hand.SetLocalScale(DATA.hand_scale)
        end
        --待機
        STATE.Set(DATA.str[DATA.str_knife_num], 3)
        vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
    elseif MOVE.knife_flg == 3 then
        for i = 1, DATA.hand_max do
            local hand = DATA.str_hand_si[i]
            hand.SetLocalScale(DATA.hand_scale)
        end
    end

    --机
    --縮小
    if MOVE.desk_flg == 0 then
        local desk = DATA.str_si[DATA.str_desk_num]
        Rot_Local_Quat_Euler(desk, 0, -90, 0)
        --待機
        STATE.Set(DATA.str[DATA.str_desk_num], MOVE.desk_flg + 1)
        vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
    elseif MOVE.desk_flg == 2 then
        local desk = DATA.str_si[DATA.str_desk_num]
        if desk.IsMine then
            local desk_rot = desk.GetLocalRotation().eulerAngles
            desk_rot.y = desk_rot.y + DATA.add_ang
            Rot_Local_Quat_Euler(desk, desk_rot.x, desk_rot.y, desk_rot.z)
        end
    elseif MOVE.desk_flg == 1 then
        for i = 1, DATA.hand_max do
            local hand = DATA.str_hand_si[i]
            hand.SetLocalScale(Vector3.__new(1 / 1000, 1 / 1000, 1 / 1000))
        end
    end
end

function onUse(use)
    if use == DATA.str_button[DATA.str_raccoon_button_num] then
        --狸フラグ
        if MOVE.raccoon_flg == 3 then
            --初期化
            STATE.Set(DATA.str_button[DATA.str_raccoon_button_num], 0)
            --白
            ASSET._ALL_SetMaterialColorFromName(DATA.str_material[DATA.str_raccoon_button_num], WHITE)
        elseif MOVE.raccoon_flg == 1 then
            STATE.Set(DATA.str_button[DATA.str_raccoon_button_num], MOVE.raccoon_flg + 1)
            --黒
            ASSET._ALL_SetMaterialColorFromName(DATA.str_material[DATA.str_raccoon_button_num], BLACK)
        end
    elseif use == DATA.str_button[DATA.str_flower_button_num] then
        --花・日記フラグ
        if MOVE.flower_flg == 3 then
            --初期化
            STATE.Set(DATA.str_button[DATA.str_flower_button_num], 0)
            STATE.Set(DATA.str[DATA.str_diary_num], 0)
            STATE.Set(DATA.str[DATA.str_desk_num], 0)
            --白
            ASSET._ALL_SetMaterialColorFromName(DATA.str_material[DATA.str_flower_button_num], WHITE)
        elseif MOVE.flower_flg == 1 then
            STATE.Set(DATA.str_button[DATA.str_flower_button_num], MOVE.flower_flg + 1)
            --黒
            ASSET._ALL_SetMaterialColorFromName(DATA.str_material[DATA.str_flower_button_num], BLACK)
        end
    elseif use == DATA.str_button[DATA.str_bag_button_num] then
        --バッグフラグ
        if MOVE.bag_flg == 3 then
            --初期化
            STATE.Set(DATA.str_button[DATA.str_bag_button_num], 0)
            STATE.Set(DATA.str[DATA.str_knife_num], 0)
            --白
            ASSET._ALL_SetMaterialColorFromName(DATA.str_material[DATA.str_bag_button_num], WHITE)
        elseif MOVE.bag_flg == 1 then
            STATE.Set(DATA.str_button[DATA.str_bag_button_num], MOVE.bag_flg + 1)
            --黒
            ASSET._ALL_SetMaterialColorFromName(DATA.str_material[DATA.str_bag_button_num], BLACK)
        end
    end
    vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
end

function onGrab(use)
    --バッグ
    if use == DATA.str[DATA.str_bag_num] then
        --ナイフ出現フラグ
        if MOVE.knife_flg == 1 then
            STATE.Set(DATA.str[DATA.str_knife_num], MOVE.knife_flg + 1)
        end
    end
    --日記
    if use == DATA.str[DATA.str_diary_num] then
        --机回転フラグ
        if MOVE.desk_flg == 1 then
            STATE.Set(DATA.str[DATA.str_desk_num], MOVE.desk_flg + 1)
        end
    end
    --ナイフ
    if use == DATA.str[DATA.str_knife_num] then
        --机回転フラグ
        if MOVE.desk_flg == 2 then
            STATE.Set(DATA.str[DATA.str_desk_num], MOVE.desk_flg + 1)
        end
    end
    --ロッカー
    if use == DATA.str_button[DATA.str_locker_button_num] then
        if MOVE.door_flg == 3 then
            --初期化
            STATE.Set(DATA.str_button[DATA.str_locker_button_num], 0)
        elseif MOVE.locker_flg == 1 then
            STATE.Set(DATA.str_button[DATA.str_locker_button_num], MOVE.locker_flg + 1)
            PlayAnimation("ステージ３　ロッカー")
        end
    end
    --扉
    if use == DATA.str_button[DATA.str_door_button_num] then
        if MOVE.door_flg == 1 then
            STATE.Set(DATA.str_button[DATA.str_door_button_num], MOVE.door_flg + 1)
            vci.message.Emit(ASHU_MESS .. "DOOR", 0)
            PlayAnimation("ドアが開く")
        end
    end
    vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
end

--ボードのステート処理
function BoardStateSet()
    MOVE.raccoon_flg = STATE.Get(DATA.str_button[DATA.str_raccoon_button_num])
    MOVE.flower_flg = STATE.Get(DATA.str_button[DATA.str_flower_button_num])
    MOVE.bag_flg = STATE.Get(DATA.str_button[DATA.str_bag_button_num])
    MOVE.locker_flg = STATE.Get(DATA.str_button[DATA.str_locker_button_num])
    MOVE.door_flg = STATE.Get(DATA.str_button[DATA.str_door_button_num])
    MOVE.desk_flg = STATE.Get(DATA.str[DATA.str_desk_num])
    MOVE.knife_flg = STATE.Get(DATA.str[DATA.str_knife_num])
end

--ボードの初期化メッセージ
function DoorMess(sender, name, message)
    MOVE.door_clock = os.clock()
end
vci.message.On(ASHU_MESS .. "DOOR", DoorMess)

--ボードの初期化メッセージ
function BoardNillMess(sender, name, message)
    nil_wait_timer = os.clock()
end
vci.message.On(ASHU_MESS .. "BOARD_NILL", BoardNillMess)

--subitemをEuler角の値に変更
function Rot_Local_Quat_Euler(subitem, x, y, z)
    subitem.SetLocalRotation(Quaternion.Euler(x, y, z))
end

function PlayAnimation(key)
    StopAnimation(key)
    ASSET._ALL_PlayAnimationFromName(key, false)
end

function StopAnimation()
    --- 問答無用で全アニメーションを止める
    ASSET._ALL_StopAnimation()
end
