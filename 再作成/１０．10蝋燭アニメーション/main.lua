--簡略化
local STATE = vci.state
local ASSET = vci.assets
local ASHU_MESS = "ASHU_10ANIM_MESS_"

--アニメーションパラメータ
local DATA = {
    str = "蝋燭本体",
    str_si = {},
    str_anim = "蝋燭",
    str_sub_anim = ".anim",
    anim = {},
    anim_max = 10
}
local MOVE = {
    --入力
    flg = {}
}

for i = 1, DATA.anim_max do
    if i == 1 then
        DATA.str_si[i] = ASSET.GetSubItem(DATA.str)
        DATA.anim[i] = DATA.str_anim
    else
        DATA.str_si[i] = ASSET.GetSubItem(DATA.str .. " (" .. tostring(i - 1) .. ")")
        DATA.anim[i] = DATA.str_anim .. DATA.str_sub_anim .. tostring(i - 1)
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

        --Main()

        m_timer_cnt = os.time()
    end
end

--初期化
function FirstDataSet()
    for i = 1, DATA.anim_max do
        MOVE.flg[i] = false
        STATE.Set(ASHU_MESS .. DATA.str_si[i].GetName(), MOVE.flg[i])
    end
    vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
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
    for i = 1, #DATA.str_si do
        if use == DATA.str_si[i].GetName() then
            if MOVE.flg[i] then
                ASSET._ALL_PlayAnimationFromName(DATA.anim[i])
            end
            STATE.Set(ASHU_MESS .. DATA.str_si[i].GetName(), not MOVE.flg[i])
            vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
        end
    end
end

function PlayAnimation(key)
    --- アニメーションを再生
    ASSET._ALL_PlayAnimationFromName(key, false)
end

--ボードのステート処理
function BoardStateSet()
    for i = 1, #DATA.str_si do
        MOVE.flg[i] = STATE.Get(ASHU_MESS .. DATA.str_si[i].GetName())
    end
end

--ボードの初期化メッセージ
function BoardNillMess(sender, name, message)
    nil_wait_timer = os.clock()
end
vci.message.On(ASHU_MESS .. "BOARD_NILL", BoardNillMess)
