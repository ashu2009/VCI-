--簡略化
local ASSET = vci.assets
local STATE = vci.state
local WHITE = Color.__new(1, 1, 1, 1)
local BLACK = Color.__new(0.2, 0.2, 0.2, 1)
local ASHU_MESS = "ASHU_2019_OBAKESTAGE1_MESS_"

--パラメータ
local DATA = {
    --本体
    str = {"落ちる黒板消し", "日記帳", "raccoon-dog2"},
    str_si = {},
    --黒板けし
    str_eraser_num = 1,
    eraser_pos = Vector3.__new(3.24, 2.45, 0.01),
    --日記
    str_diary_num = 2,
    diary_pos = Vector3.__new(-4, 0.4, 3.15),
    diary_rot = Vector3.__new(-90, 0, 90),
    diary_scale = Vector3.__new(100, 100, 100),
    --狸
    str_raccoon_num = 3,
    raccoon_pos = Vector3.__new(-4, 0.43, 3.2),
    raccoon_rot = Vector3.__new(-70, 0, 0),
    raccoon_scale = Vector3.__new(7, 6, 6),
    --ボタン関係
    str_button = {"黒板消しスイッチ", "日記帳スイッチ", "ぬいぐるみスイッチ"},
    str_button_si = {},
    str_eraser_button_num = 1,
    str_diary_button_num = 2,
    str_raccoon_button_num = 3,
    --マテリアル関係
    str_material = {"黒板けしB", "日記帳B", "狸B"}
}

local MOVE = {
    --黒板けし落下
    fall_flg = false,
    --エフェクト
    eff_flg = true,
    --狸
    raccoon_flg = 0,
    --日記
    diary_flg = 0
}

--サブアイテム関連
for i = 1, #DATA.str do
    DATA.str_si[i] = ASSET.GetSubItem(DATA.str[i])
end
for i = 1, #DATA.str_button do
    DATA.str_button_si[i] = ASSET.GetSubItem(DATA.str_button[i])
end

if ASSET.IsMine then
    STATE.Set(DATA.str[DATA.str_eraser_num], MOVE.fall_flg)
    STATE.Set(DATA.str[DATA.str_diary_num], MOVE.diary_flg)
    STATE.Set(DATA.str[DATA.str_raccoon_num], MOVE.raccoon_flg)
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
--エフェクトアイテム
local eff = ASSET.GetEffekseerEmitter("GameObject")
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
    --落下停止中
    if not MOVE.fall_flg then
        local eraser = DATA.str_si[DATA.str_eraser_num]
        if eraser.IsMine then
            eraser.SetLocalPosition(DATA.eraser_pos)
            eraser.SetLocalRotation(Quaternion.identity)
            Velo_Ang_Zero(eraser)
        end
    end

    --日記パターン
    --縮小
    if MOVE.diary_flg == 0 then
        local diary = DATA.str_si[DATA.str_diary_num]
        if diary.IsMine then
            diary.SetLocalPosition(DATA.diary_pos)
            Rot_Local_Quat_Euler(diary, DATA.diary_rot.x, DATA.diary_rot.y, DATA.diary_rot.z)
            diary.SetLocalScale(Vector3.__new(1 / 1000, 1 / 1000, 1 / 1000))
            --待機
            STATE.Set(DATA.str[DATA.str_diary_num], MOVE.diary_flg + 1)
            vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
        end
    elseif MOVE.diary_flg == 2 then
        local diary = DATA.str_si[DATA.str_diary_num]
        if diary.IsMine then
            diary.SetLocalScale(DATA.diary_scale)
            --待機
            STATE.Set(DATA.str[DATA.str_diary_num], MOVE.diary_flg + 1)
            vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
        end
    end

    --狸押すと
    if MOVE.raccoon_flg == 0 then
        local raccoon = DATA.str_si[DATA.str_raccoon_num]
        if raccoon.IsMine then
            raccoon.SetLocalPosition(DATA.raccoon_pos)
            Rot_Local_Quat_Euler(raccoon, DATA.raccoon_rot.x, DATA.raccoon_rot.y, DATA.raccoon_rot.z)
            raccoon.SetLocalScale(Vector3.__new(1 / 1000, 1 / 1000, 1 / 1000))
            --待機
            STATE.Set(DATA.str[DATA.str_raccoon_num], MOVE.raccoon_flg + 1)
            vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
        end
    elseif MOVE.raccoon_flg == 2 then
        local raccoon = DATA.str_si[DATA.str_raccoon_num]
        if raccoon.IsMine then
            raccoon.SetLocalScale(DATA.raccoon_scale)
            --待機
            STATE.Set(DATA.str[DATA.str_raccoon_num], MOVE.raccoon_flg + 1)
            vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
        end
    end
end

function onUse(use)
    if use == DATA.str_button[DATA.str_eraser_button_num] then
        --落下フラグ
        if MOVE.fall_flg then
            --初期化
            STATE.Set(DATA.str[DATA.str_eraser_num], false)
            --白
            ASSET._ALL_SetMaterialColorFromName(DATA.str_material[DATA.str_eraser_button_num], WHITE)
        else
            STATE.Set(DATA.str[DATA.str_eraser_num], true)
            --黒
            ASSET._ALL_SetMaterialColorFromName(DATA.str_material[DATA.str_eraser_button_num], BLACK)
        end
    elseif use == DATA.str_button[DATA.str_diary_button_num] then
        --日記帳フラグ
        if MOVE.diary_flg == 3 then
            --初期化
            STATE.Set(DATA.str[DATA.str_diary_num], 0)
            --白
            ASSET._ALL_SetMaterialColorFromName(DATA.str_material[DATA.str_diary_button_num], WHITE)
        elseif MOVE.diary_flg == 1 then
            STATE.Set(DATA.str[DATA.str_diary_num], MOVE.diary_flg + 1)
            --黒
            ASSET._ALL_SetMaterialColorFromName(DATA.str_material[DATA.str_diary_button_num], BLACK)
        end
    elseif use == DATA.str_button[DATA.str_raccoon_button_num] then
        --狸フラグ
        if MOVE.raccoon_flg == 3 then
            --初期化
            STATE.Set(DATA.str[DATA.str_raccoon_num], 0)
            --白
            ASSET._ALL_SetMaterialColorFromName(DATA.str_material[DATA.str_raccoon_button_num], WHITE)
        elseif MOVE.raccoon_flg == 1 then
            STATE.Set(DATA.str[DATA.str_raccoon_num], MOVE.raccoon_flg + 1)
            --黒
            ASSET._ALL_SetMaterialColorFromName(DATA.str_material[DATA.str_raccoon_button_num], BLACK)
        end
    end
    vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
end

--ボードのステート処理
function BoardStateSet()
    MOVE.fall_flg = STATE.Get(DATA.str[DATA.str_eraser_num])
    MOVE.diary_flg = STATE.Get(DATA.str[DATA.str_diary_num])
    MOVE.raccoon_flg = STATE.Get(DATA.str[DATA.str_raccoon_num])
end

--ボードの初期化メッセージ
function BoardNillMess(sender, name, message)
    nil_wait_timer = os.clock()
end
vci.message.On(ASHU_MESS .. "BOARD_NILL", BoardNillMess)

--サブアイテム速度/回転速度/力初期化
function Velo_Ang_Zero(item)
    if item ~= nil then
        item.SetVelocity(Vector3.zero)
        item.SetAngularVelocity(Vector3.zero)
        item.AddForce(Vector3.zero)
    end
end

--subitemをEuler角の値に変更
function Rot_Local_Quat_Euler(subitem, x, y, z)
    subitem.SetLocalRotation(Quaternion.Euler(x, y, z))
end
