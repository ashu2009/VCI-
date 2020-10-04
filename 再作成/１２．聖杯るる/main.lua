local STATE = vci.state
local ASSET = vci.assets
local ASHU_MESS = "ASHU_SEIHAIRURU_MESS_"

local DATA = {
    str = "GameObject (1)",
    str_si = 0,
    str_sound = "テレフォンショッピング"
}
local MOVE = {
    --要請
    flg = false,
    --on/off
    on_flg = false,
    --初めて?
    first = true
}
DATA.str_si = ASSET.GetSubItem(DATA.str)

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
    MOVE.flg = false
    STATE.Set("FLG", MOVE.flg)
    vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
end

--初期化
function Main()
    if MOVE.flg then
        print(MOVE.on_flg)
        if MOVE.on_flg then
            ASSET.audio._ALL_Pause(DATA.str_sound, true)
            MOVE.on_flg = false
        else
            if MOVE.first then
                ASSET.audio._ALL_Play(DATA.str_sound, 1.0, true)
                MOVE.first = false
            else
                ASSET.audio._ALL_Pause(DATA.str_sound, false)
            end
            MOVE.on_flg = true
        end
        MOVE.flg = false
        STATE.Set("FLG", MOVE.flg)
        vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
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

        if nil_wait_timer == 0 then
        --AllMainFunc()
        end
        timer = os.clock()
    end
end

function onUse(use)
    if DATA.str == use then
        STATE.Set("FLG", true)
        vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
    end
end

--ボードのステート処理
function BoardStateSet()
    MOVE.flg = STATE.Get("FLG")
end

--ボードの初期化メッセージ
function BoardNillMess(sender, name, message)
    nil_wait_timer = os.clock()
end
vci.message.On(ASHU_MESS .. "BOARD_NILL", BoardNillMess)
