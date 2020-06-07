local STATE = vci.state
local ASSET = vci.assets
local ASHU_MESS = "ASHU_NEWS_PAPER_MESS_"
local NOT_DEBUG = true

local NEWS_PAPER_DATA = {
    --ページ纏め
    str = "まとめ",
    str_si = nil,
    --ページ
    str_page = "ページ",
    str_page_si = {},
    --枚数
    str_page_max_num = 4,
    --遷移時間
    next_time = 1.2
}
local NEWS_PAPER_MOVE = {
    --現在ページ
    now_page = nil
}
--纏め
NEWS_PAPER_DATA.str_si = ASSET.GetSubItem(NEWS_PAPER_DATA.str)
--ページ
for i = 1, NEWS_PAPER_DATA.str_page_max_num do
    NEWS_PAPER_DATA.str_page_si[i] = ASSET.GetSubItem(NEWS_PAPER_DATA.str_page .. tostring(i))
end

--メイン時間
local m_timer = 0
--時間間隔
local m_timer_cnt = 1 / 10
--初期化フラグ
local first_flg = true
--押したかどうか
local l_use_flg = false
function update()
    --間引き
    if TimeManage(m_timer, m_timer_cnt) then
        if first_flg then
            --初期化
            FirstDataSet()
            first_flg = false
        end
    end
end

--時間処理
local timer = os.clock()
local timer_count = 1 / 15
--nilにするタイマー
local nil_wait_timer = 0
--nilにする時間
local nil_wait_timer_count = 1 / 5
function updateAll()
    --時間管理
    if TimeManage(timer, timer_count) then
        --現在ページ
        local now_page = NEWS_PAPER_MOVE.now_page
        --nilならば読み込み
        if now_page == nil then
            --ステート処理
            BoardStateSet()
        else
            --全員用
            AllMain()
        end

        if nil_wait_timer ~= 0 and (os.clock() - nil_wait_timer) > nil_wait_timer_count then
            BoardNillSet()
            --2度はいらない
            nil_wait_timer = 0
        end
    end
end

--ページ保持用
local save_page = 0
local save_clock = 0
--全員用
function AllMain()
    --現在ページ
    local now_page = NEWS_PAPER_MOVE.now_page
    --ページ更新
    if save_page ~= now_page then
        save_page = now_page
        save_clock = os.clock()
    end
    --アイテム制御
    for i = 1, NEWS_PAPER_DATA.str_page_max_num do
        --制御するアイテム
        local si = NEWS_PAPER_DATA.str_page_si[i]
        --2p前(一番右基準)
        if now_page - 2 == i then
            si.SetLocalScale(Vector3.__new(100, 100, 100))
            Rot_LocalQuat_Euler(si, 90, 0, 0)
            si.SetLocalPosition(Vector3.__new(0, 0, 0))
        elseif now_page - 1 == i then
            --1p前(一番右基準)
            si.SetLocalScale(Vector3.__new(100, 100, 100))
            local add_ang = 0
            if now_page ~= 1 then
                add_ang = 180 * (os.clock() - save_clock) / NEWS_PAPER_DATA.next_time
                if add_ang > 180 then
                    add_ang = 180
                    if now_page > 2 then
                        local si_2 = NEWS_PAPER_DATA.str_page_si[i - 1]
                        si_2.SetLocalScale(Vector3.__new(0, 0, 0))
                    end
                end
            end
            Rot_LocalQuat_Euler(si, 90, 180 + add_ang, 0)
            si.SetLocalPosition(Vector3.__new(0, 0, 0))
        elseif now_page == i then
            si.SetLocalScale(Vector3.__new(100, 100, 100))
            Rot_LocalQuat_Euler(si, 90, 180, 0)
            si.SetLocalPosition(Vector3.__new(0, 0, 0))
        else
            --Rot_LocalQuat_Euler(si, 90, 180, 0)
            si.SetLocalScale(Vector3.__new(0, 0, 0))
        end

        if now_page > 0 then
            local p_max_si = NEWS_PAPER_DATA.str_page_si[#NEWS_PAPER_DATA.str_page_si]
            p_max_si.SetLocalScale(Vector3.__new(100, 100, 100))
            p_max_si.SetLocalPosition(Vector3.__new(0, 0, 0.0001))
            if now_page < #NEWS_PAPER_DATA.str_page_si + 1 then
                Rot_LocalQuat_Euler(p_max_si, 90, 180, 0)
            else
                p_max_si.SetLocalPosition(Vector3.__new(0, 0, -0.0001))
            end
            if now_page > 1 then
                local p1_si = NEWS_PAPER_DATA.str_page_si[1]
                --Rot_LocalQuat_Euler(p1_si, 90, 0, 0)
                p1_si.SetLocalScale(Vector3.__new(100, 100, 100))
                p1_si.SetLocalPosition(Vector3.__new(0, 0, 0.0001))
            end
        end
    end
end

function onUse(use)
    if use == NEWS_PAPER_DATA.str then
        if NEWS_PAPER_MOVE.now_page ~= nil then
            --ページ足す
            local set_page = NEWS_PAPER_MOVE.now_page + 1
            if set_page > NEWS_PAPER_DATA.str_page_max_num + 1 then
                set_page = 1
            end
            STATE.Set(NEWS_PAPER_DATA.str, set_page)
            vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
        end
    end
end

--初期化セット
function FirstDataSet()
    STATE.Set(NEWS_PAPER_DATA.str, 1)
    vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
end

--ボードのnil処理
function BoardNillSet()
    NEWS_PAPER_MOVE.now_page = nil
end

--ボードの初期化メッセージ
function BoardNillMess(sender, name, message)
    nil_wait_timer = os.clock()
end
vci.message.On(ASHU_MESS .. "BOARD_NILL", BoardNillMess)

--ボードのステート処理
function BoardStateSet()
    NEWS_PAPER_MOVE.now_page = STATE.Get(NEWS_PAPER_DATA.str)
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

--subitemをEuler角の値に変更
function Rot_LocalQuat_Euler(subitem, x, y, z)
    subitem.SetLocalRotation(Quaternion.Euler(x, y, z))
end
