--簡略化
local ASSET = vci.assets
local STATE = vci.state
local WHITE = Color.__new(1, 1, 1, 1)
local BLACK = Color.__new(0.2, 0.2, 0.2, 1)
local ASHU_MESS = "ASHU_2019_OBAKESTAGE2_MESS_"

--パラメータ
local DATA = {
    --本体
    str = {"輪ゴム", "パッチンガム 1", "とーあん", "氷", "筆箱", "窓割れる"},
    str_si = {},
    --ボタン
    str_button = {"輪ゴム出現", "ガム出現", "紙出現", "氷出現", "筆箱出現", "ガラス割れる"},
    str_button_si = {},
    --輪ゴム
    str_rubber_num = 1,
    --パッチンガム
    str_gum_num = 2,
    --答案
    str_answer_num = 3,
    --氷
    str_ice_num = 4,
    --筆箱
    str_case_num = 5,
    --窓
    str_window_num = 6,
    all_scale = {
        Vector3.__new(5, 5, 5),
        Vector3.__new(1, 1, 1),
        Vector3.__new(10, 10, 10),
        Vector3.__new(1, 1, 1),
        Vector3.__new(100, 100, 100)
    },
    all_pos = {
        Vector3.__new(2.668, 0.991, -0.525),
        Vector3.__new(2.616, 0.939, -0.126),
        Vector3.__new(2.301, 0.94, -0.537),
        Vector3.__new(2.296, 1.006, 0.434),
        Vector3.__new(2.705, 0.936, 0.428)
    },
    all_rot = {
        Vector3.__new(0, 37, 0),
        Vector3.__new(0, 0, 0),
        Vector3.__new(-90, 0, 90),
        Vector3.__new(-90, 0, 0),
        Vector3.__new(-90, 0, 0)
    },
    sound_str = {"お皿割れる01"},
    --マテリアル関係
    str_material = {"輪ゴム出現", "ガム　出現", "城　出現", "氷　出現", "筆箱出現"}
}

local MOVE = {
    --輪ゴム
    rubber_flg = 0,
    --パッチンガム
    gum_flg = 0,
    --答案
    answer_flg = 0,
    --氷
    ice_flg = 0,
    --筆箱
    case_flg = 0
}

--サブアイテム関連
for i = 1, #DATA.str do
    DATA.str_si[i] = ASSET.GetSubItem(DATA.str[i])
end
for i = 1, #DATA.str_button do
    DATA.str_button_si[i] = ASSET.GetSubItem(DATA.str_button[i])
end

if ASSET.IsMine then
    STATE.Set(DATA.str[DATA.str_rubber_num], MOVE.rubber_flg)
    STATE.Set(DATA.str[DATA.str_gum_num], MOVE.gum_flg)
    STATE.Set(DATA.str[DATA.str_answer_num], MOVE.answer_flg)
    STATE.Set(DATA.str[DATA.str_ice_num], MOVE.ice_flg)
    STATE.Set(DATA.str[DATA.str_case_num], MOVE.case_flg)
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
    --輪ゴム
    --縮小
    if MOVE.rubber_flg == 0 then
        local rubber = DATA.str_si[DATA.str_rubber_num]
        if rubber.IsMine then
            rubber.SetLocalPosition(DATA.all_pos[DATA.str_rubber_num])
            Rot_Local_Quat_Euler(
                rubber,
                DATA.all_rot[DATA.str_rubber_num].x,
                DATA.all_rot[DATA.str_rubber_num].y,
                DATA.all_rot[DATA.str_rubber_num].z
            )
            rubber.SetLocalScale(Vector3.__new(1 / 1000, 1 / 1000, 1 / 1000))
            --待機
            STATE.Set(DATA.str[DATA.str_rubber_num], MOVE.rubber_flg + 1)
            vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
        end
    elseif MOVE.rubber_flg == 2 then
        local rubber = DATA.str_si[DATA.str_rubber_num]
        if rubber.IsMine then
            rubber.SetLocalScale(DATA.all_scale[DATA.str_rubber_num])
            --待機
            STATE.Set(DATA.str[DATA.str_rubber_num], MOVE.rubber_flg + 1)
            vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
        end
    end

    --パッチンガム
    --縮小
    if MOVE.gum_flg == 0 then
        local gum = DATA.str_si[DATA.str_gum_num]
        if gum.IsMine then
            gum.SetLocalPosition(DATA.all_pos[DATA.str_gum_num])
            Rot_Local_Quat_Euler(
                gum,
                DATA.all_rot[DATA.str_gum_num].x,
                DATA.all_rot[DATA.str_gum_num].y,
                DATA.all_rot[DATA.str_gum_num].z
            )
            gum.SetLocalScale(Vector3.__new(1 / 1000, 1 / 1000, 1 / 1000))
            --待機
            STATE.Set(DATA.str[DATA.str_gum_num], MOVE.gum_flg + 1)
            vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
        end
    elseif MOVE.gum_flg == 2 then
        local gum = DATA.str_si[DATA.str_gum_num]
        if gum.IsMine then
            gum.SetLocalScale(DATA.all_scale[DATA.str_gum_num])
            --待機
            STATE.Set(DATA.str[DATA.str_gum_num], MOVE.gum_flg + 1)
            vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
        end
    end

    --答案
    --縮小
    if MOVE.answer_flg == 0 then
        local answer = DATA.str_si[DATA.str_answer_num]
        if answer.IsMine then
            answer.SetLocalPosition(DATA.all_pos[DATA.str_answer_num])
            Rot_Local_Quat_Euler(
                answer,
                DATA.all_rot[DATA.str_answer_num].x,
                DATA.all_rot[DATA.str_answer_num].y,
                DATA.all_rot[DATA.str_answer_num].z
            )
            answer.SetLocalScale(Vector3.__new(1 / 1000, 1 / 1000, 1 / 1000))
            --待機
            STATE.Set(DATA.str[DATA.str_answer_num], MOVE.answer_flg + 1)
            vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
        end
    elseif MOVE.answer_flg == 2 then
        local answer = DATA.str_si[DATA.str_answer_num]
        if answer.IsMine then
            answer.SetLocalScale(DATA.all_scale[DATA.str_answer_num])
            --待機
            STATE.Set(DATA.str[DATA.str_answer_num], MOVE.answer_flg + 1)
            vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
        end
    end

    --氷
    --縮小
    if MOVE.ice_flg == 0 then
        local ice = DATA.str_si[DATA.str_ice_num]
        if ice.IsMine then
            ice.SetLocalPosition(DATA.all_pos[DATA.str_ice_num])
            Rot_Local_Quat_Euler(
                ice,
                DATA.all_rot[DATA.str_ice_num].x,
                DATA.all_rot[DATA.str_ice_num].y,
                DATA.all_rot[DATA.str_ice_num].z
            )
            ice.SetLocalScale(Vector3.__new(1 / 1000, 1 / 1000, 1 / 1000))
            --待機
            STATE.Set(DATA.str[DATA.str_ice_num], MOVE.ice_flg + 1)
            vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
        end
    elseif MOVE.ice_flg == 2 then
        local ice = DATA.str_si[DATA.str_ice_num]
        if ice.IsMine then
            ice.SetLocalScale(DATA.all_scale[DATA.str_ice_num])
            --待機
            STATE.Set(DATA.str[DATA.str_ice_num], MOVE.ice_flg + 1)
            vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
        end
    end

    --輪ゴム
    --縮小
    if MOVE.case_flg == 0 then
        local case = DATA.str_si[DATA.str_case_num]
        if case.IsMine then
            case.SetLocalPosition(DATA.all_pos[DATA.str_case_num])
            Rot_Local_Quat_Euler(
                case,
                DATA.all_rot[DATA.str_case_num].x,
                DATA.all_rot[DATA.str_case_num].y,
                DATA.all_rot[DATA.str_case_num].z
            )
            case.SetLocalScale(Vector3.__new(1 / 1000, 1 / 1000, 1 / 1000))
            --待機
            STATE.Set(DATA.str[DATA.str_case_num], MOVE.case_flg + 1)
            vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
        end
    elseif MOVE.case_flg == 2 then
        local case = DATA.str_si[DATA.str_case_num]
        if case.IsMine then
            case.SetLocalScale(DATA.all_scale[DATA.str_case_num])
            --待機
            STATE.Set(DATA.str[DATA.str_case_num], MOVE.case_flg + 1)
            vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
        end
    end
end

function onUse(use)
    if use == DATA.str_button[DATA.str_rubber_num] then
        --輪ゴムフラグ
        if MOVE.rubber_flg == 3 then
            --初期化
            STATE.Set(DATA.str[DATA.str_rubber_num], 0)
            --白
            ASSET._ALL_SetMaterialColorFromName(DATA.str_material[DATA.str_rubber_num], WHITE)
        elseif MOVE.rubber_flg == 1 then
            STATE.Set(DATA.str[DATA.str_rubber_num], MOVE.rubber_flg + 1)
            --黒
            ASSET._ALL_SetMaterialColorFromName(DATA.str_material[DATA.str_rubber_num], BLACK)
        end
    elseif use == DATA.str_button[DATA.str_gum_num] then
        --パッチンガムフラグ
        if MOVE.gum_flg == 3 then
            --初期化
            STATE.Set(DATA.str[DATA.str_gum_num], 0)
            --白
            ASSET._ALL_SetMaterialColorFromName(DATA.str_material[DATA.str_gum_num], WHITE)
        elseif MOVE.gum_flg == 1 then
            STATE.Set(DATA.str[DATA.str_gum_num], MOVE.gum_flg + 1)
            --黒
            ASSET._ALL_SetMaterialColorFromName(DATA.str_material[DATA.str_gum_num], BLACK)
        end
    elseif use == DATA.str_button[DATA.str_answer_num] then
        --答案フラグ
        if MOVE.answer_flg == 3 then
            --初期化
            STATE.Set(DATA.str[DATA.str_answer_num], 0)
            --白
            ASSET._ALL_SetMaterialColorFromName(DATA.str_material[DATA.str_answer_num], WHITE)
        elseif MOVE.answer_flg == 1 then
            STATE.Set(DATA.str[DATA.str_answer_num], MOVE.answer_flg + 1)
            --黒
            ASSET._ALL_SetMaterialColorFromName(DATA.str_material[DATA.str_answer_num], BLACK)
        end
    elseif use == DATA.str_button[DATA.str_ice_num] then
        --氷フラグ
        if MOVE.ice_flg == 3 then
            --初期化
            STATE.Set(DATA.str[DATA.str_ice_num], 0)
            --白
            ASSET._ALL_SetMaterialColorFromName(DATA.str_material[DATA.str_ice_num], WHITE)
        elseif MOVE.ice_flg == 1 then
            STATE.Set(DATA.str[DATA.str_ice_num], MOVE.ice_flg + 1)
            --黒
            ASSET._ALL_SetMaterialColorFromName(DATA.str_material[DATA.str_ice_num], BLACK)
        end
    elseif use == DATA.str_button[DATA.str_case_num] then
        --筆箱フラグ
        if MOVE.case_flg == 3 then
            --初期化
            STATE.Set(DATA.str[DATA.str_case_num], 0)
            --白
            ASSET._ALL_SetMaterialColorFromName(DATA.str_material[DATA.str_case_num], WHITE)
        elseif MOVE.case_flg == 1 then
            STATE.Set(DATA.str[DATA.str_case_num], MOVE.case_flg + 1)
            --黒
            ASSET._ALL_SetMaterialColorFromName(DATA.str_material[DATA.str_case_num], BLACK)
        end
    elseif use == DATA.str_button[DATA.str_window_num] then
        PlayAnimation(DATA.str[DATA.str_window_num])
        AllPlayAudio(DATA.sound_str[1])
    end
    vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
end

--ボードのステート処理
function BoardStateSet()
    MOVE.rubber_flg = STATE.Get(DATA.str[DATA.str_rubber_num])
    MOVE.gum_flg = STATE.Get(DATA.str[DATA.str_gum_num])
    MOVE.answer_flg = STATE.Get(DATA.str[DATA.str_answer_num])
    MOVE.ice_flg = STATE.Get(DATA.str[DATA.str_ice_num])
    MOVE.case_flg = STATE.Get(DATA.str[DATA.str_case_num])
end

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

--指定した音を鳴らす
function AllPlayAudio(sound_name)
    ASSET._ALL_PlayAudioFromName(sound_name)
end
