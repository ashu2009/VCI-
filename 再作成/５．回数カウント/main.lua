--簡略化
local STATE = vci.state
local ASSET = vci.assets
local ASHU_MESS = "ASHU_2019COUNT_MESS_"

--タイマーボードパラメータ
local DATA = {
    --Unity名称
    str = {
        "Cube"
    },
    --本体用
    str_si = {},
    --最大数
    cube_max = 7,
    --箱用
    cube_si = {},
    --回数最大
    max_count = 10
}

local MOVE = {
    --use時間保持
    m_clock_start = 0,
    clock_start = {},
    --追加フラグ
    add_flg = false,
    --初期化フラグ
    first_count = false,
    --カウント
    count = 0
}

--サブアイテム
for i = 1, #DATA.str do
    DATA.str_si[i] = ASSET.GetSubItem(DATA.str[1])
    for i = 1, DATA.cube_max do
        DATA.cube_si[i] = ASSET.GetSubItem(DATA.str[1] .. " (" .. tostring(i) .. ")")
    end
end

--メイン時間
local m_timer = 0
--時間間隔
local m_timer_cnt = 1 / 30
--初期化フラグ
local first_flg = true
function update()
    if (os.time() - m_timer) > m_timer_cnt then
        if first_flg then
            --初期化
            FirstDataSet()
            first_flg = false
        end

        Main()
    end
end

--初期化セット
function FirstDataSet()
    ------------------------------------------------------------------------
    STATE.Set("COUNT_FIRST", MOVE.first_count)
    STATE.Set("COUNT_ADD", MOVE.add_flg)
    vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
    ------------------------------------------------------------------------
end

--メイン
function Main()
    ------------------------------------------------------------------------
    if MOVE.add_flg then
        MOVE.count = MOVE.count + 1
        MOVE.add_flg = false
        STATE.Set("COUNT_ADD", MOVE.add_flg)
        vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
    end
    if MOVE.first_count then
        MOVE.count = 0
        MOVE.first_count = false
        STATE.Set("COUNT_FIRST", MOVE.first_count)
        MOVE.add_flg = false
        STATE.Set("COUNT_ADD", MOVE.add_flg)
        vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
    end

    if MOVE.count >= DATA.max_count then
        AllPlayAudio("クイズ・ファンファーレ02 (1)")
        MOVE.count = 0
    end
    ASSET._ALL_SetText("count", tostring(MOVE.count))
    ------------------------------------------------------------------------
end

--時間処理
local timer = os.clock()
local timer_count = 1 / 30
--nilにするタイマー
local nil_wait_timer = os.clock()
--nilにする時間
local nil_wait_timer_count = 1 / 15
function updateAll()
    if (os.time() - timer) > timer_count then
        if nil_wait_timer ~= 0 and (os.clock() - nil_wait_timer) > nil_wait_timer_count then
            BoardStateSet()
            --2度はいらない
            nil_wait_timer = 0
        end

        timer = os.clock()
    end
end

--use処理
function onUse(use)
    --use判定
    if use == DATA.str[1] then
        MOVE.m_clock_start = os.clock()
    end
    for i = 1, DATA.cube_max do
        if use == DATA.cube_si[i].GetName() then
            MOVE.clock_start[i] = os.clock()
        end
    end
end

--UnUse処理
function onUnuse(use)
    --use判定
    if use == DATA.str[1] then
        --差分時間保持
        MOVE.clock_data = os.clock() - MOVE.m_clock_start
        if MOVE.clock_data > 2 then
            STATE.Set("COUNT_FIRST", true)
        else
            STATE.Set("COUNT_ADD", true)
        end
    end
    for i = 1, DATA.cube_max do
        if use == DATA.cube_si[i].GetName() then
            --差分時間保持
            MOVE.clock_data = os.clock() - MOVE.clock_start[i]
            if MOVE.clock_data > 2 then
                STATE.Set("COUNT_FIRST", true)
            else
                STATE.Set("COUNT_ADD", true)
            end
        end
    end
    vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
end

--身体コライダ名称
local BODY_CLLIDER = {
    "Head"
    --"RightArm",
    --"LeftArm",
    --"RightHand",
    -- "LeftHand",
    --"Chest",
    -- "Hips",
    --"RightThigh",
    --"LeftThigh",
    --"RightToes",
    --"LeftToes",
    -- "RightFoot",
    -- "LeftFoot",
    -- "HandPointMarker"
}

function onTriggerEnter(item, hit)
    --頭接触
    if (item == DATA.str[1] and hit == BODY_CLLIDER[1]) or (hit == DATA.str[1] and item == BODY_CLLIDER[1]) then
        STATE.Set("COUNT_ADD", true)
        vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
    end

    for i = 1, DATA.cube_max do
        if (item == DATA.str[i] and hit == BODY_CLLIDER[1]) or (hit == DATA.str[i] and item == BODY_CLLIDER[1]) then
            STATE.Set("COUNT_ADD", true)
            vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
        end
    end
end

function onCollisionEnter(item, hit)
    --頭接触
    if (item == DATA.str[1] and hit == BODY_CLLIDER[1]) or (hit == DATA.str[1] and item == BODY_CLLIDER[1]) then
        STATE.Set("COUNT_ADD", true)
    end

    for i = 1, DATA.cube_max do
        if (item == DATA.str[i] and hit == BODY_CLLIDER[1]) or (hit == DATA.str[i] and item == BODY_CLLIDER[1]) then
            STATE.Set("COUNT_ADD", true)
        end
    end
end

--指定した音を鳴らす
function AllPlayAudio(sound_name)
    ASSET._ALL_PlayAudioFromName(sound_name)
end

--ボードのステート処理
function BoardStateSet()
    MOVE.first_count = STATE.Get("COUNT_FIRST")
    MOVE.add_flg = STATE.Get("COUNT_ADD")
end

--ボードの初期化メッセージ
function BoardNillMess(sender, name, message)
    nil_wait_timer = os.clock()
end
vci.message.On(ASHU_MESS .. "BOARD_NILL", BoardNillMess)
