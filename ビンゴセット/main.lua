--簡略化
local STATE = vci.state
local ASSET = vci.assets
local COL_WHITE = Color.__new(1, 1, 1)
local COL_BLACK = Color.__new(0.6, 0.6, 0.6)
local COL_REACH = Color.__new(1, 1, 0)
local COL_BINGO = Color.__new(0, 1, 0)
local ASHU_MESS = "ASHU_BINGO_MESS_"

local BINGO_DATA = {
    --基礎アイテム名
    str = {"初期化", "同期", "ビンゴマシン", "ビンゴ玉", "ビンゴ"},
    str_first_num = 1,
    str_sync_num = 2,
    str_machine_num = 3,
    str_ball_num = 4,
    str_si = {},
    str_bingo_num = 5,
    str_bingo_si = {},
    --ビンゴカード枚数
    bingo_page_max = 5,
    --Text名称
    str_txt = "Text",
    --分割数
    bingo_split = 5,
    --行ずれごとの増加数
    bingo_add = 15,
    --1枚当たりのマス数
    bingo_split_max = 25,
    --ビンゴのスケール
    bingo_scale = Vector3.__new(20, 20 * 1.3, 20),
    --マテリアル名称
    str_material = "ビンゴ",
    --セット時の名称
    str_set = "Set",
    --アニメーション
    str_anim = "ビンゴ2anim",
    --起動時間
    str_anim_timer = 0,
    --起動時間
    str_anim_timer_count = 3,
    --見るやつ
    str_show = "show",
    str_show_si = {},
    --1段サイズ
    show_size = Vector3.__new(0.68, 0.105, 0.02)
}
local BINGO_MOVE = {
    --配列としてのデータ[][5*5]
    bingo_array = {},
    --出たデータ記録
    bingo_choice_array = {}
}

--メインアイテム
for i = 1, BINGO_DATA.str_ball_num do
    BINGO_DATA.str_si[i] = ASSET.GetSubItem(BINGO_DATA.str[i])
end
--ビンゴアイテム
for i = 1, BINGO_DATA.bingo_page_max do
    BINGO_DATA.str_bingo_si[i] = ASSET.GetSubItem(BINGO_DATA.str[BINGO_DATA.str_bingo_num] .. tostring(i))
    BINGO_DATA.str_bingo_si[i].SetLocalScale(BINGO_DATA.bingo_scale)
end
BINGO_DATA.str_show_si[1] = ASSET.GetSubItem(BINGO_DATA.str_show)

--メイン時間
local m_timer = 0
--時間間隔
local m_timer_cnt = 1 / 10
--初期化フラグ
local first_flg = true
--押したかどうか
local l_use_flg = false
--押したかどうか
local l_rand_flg = false
--コルーチンフラグ
local l_rand_col_flg = false
function update()
    --間引き
    if TimeManage(m_timer, m_timer_cnt) then
        if first_flg then
            --押したとする
            l_use_flg = true
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
local nil_wait_timer_count = 1 / 3
function updateAll()
    --時間管理
    if TimeManage(timer, timer_count) then
        --盤面の位置駒(配列)
        local board_pos = BINGO_MOVE.bingo_array
        --nilならば読み込み
        if board_pos == nil then
            --ステート処理
            BoardStateSet()
        else
            if #board_pos == BINGO_DATA.bingo_page_max then
                --全員用
                --AllMain()

                if
                    BINGO_DATA.str_anim_timer ~= 0 and
                        (os.clock() - BINGO_DATA.str_anim_timer) > BINGO_DATA.str_anim_timer_count
                 then
                    ASSET._ALL_SetText(
                        BINGO_DATA.str_txt .. tostring(0),
                        BINGO_MOVE.bingo_choice_array[#BINGO_MOVE.bingo_choice_array]
                    )

                    StopAnimation()
                    BINGO_DATA.str_anim_timer = 0
                end
            else
                --ステート処理
                BoardStateSet()
            end
        end

        if nil_wait_timer ~= 0 and (os.clock() - nil_wait_timer) > nil_wait_timer_count then
            BoardNillSet()
            --2度はいらない
            nil_wait_timer = 0
        end
    end
end

function onUse(use)
    if use == BINGO_DATA.str[BINGO_DATA.str_first_num] then
        FirstDataSet()
        l_use_flg = true
    end
    if use == BINGO_DATA.str[BINGO_DATA.str_machine_num] then
        if not l_rand_col_flg and not l_rand_flg and BINGO_MOVE.bingo_choice_array ~= nil then
            l_rand_flg = true
            l_rand_col_flg = true

            ASSET._ALL_SetText(
                BINGO_DATA.str_txt .. tostring(0),
                BINGO_MOVE.bingo_choice_array[#BINGO_MOVE.bingo_choice_array]
            )
            PlayAnimation(BINGO_DATA.str_anim)
            local machine_si = BINGO_DATA.str_si[BINGO_DATA.str_machine_num]
            local pos = machine_si.GetPosition()
            pos.y = pos.y - 0.3726
            local ball_si = BINGO_DATA.str_si[BINGO_DATA.str_ball_num]
            ball_si.SetRotation(machine_si.GetRotation())
            local angle = machine_si.GetRotation().eulerAngles
            pos.z = pos.z - 0.216 * math.sin(angle.y / 180 * math.pi)
            pos.x = pos.x + 0.216 * math.cos(angle.y / 180 * math.pi)
            ball_si.SetPosition(pos)

            ball_si.SetVelocity(
                Vector3.__new(3 * math.cos(angle.y / 180 * math.pi), -1.8, -3 * math.sin(angle.y / 180 * math.pi))
            )
            BINGO_DATA.str_anim_timer = os.clock()
        end
    end
end

--初期化セット
function FirstDataSet()
    --保存するかどうか
    if l_use_flg then
        ASSET._ALL_SetText(BINGO_DATA.str_txt .. tostring(0), "")
        --5*5マス*枚数
        for page = 1, BINGO_DATA.bingo_page_max do
            BINGO_MOVE.bingo_array[page] = {}
            --横列
            for wide = 1, BINGO_DATA.bingo_split do
                --マスの値
                local rand_min = 1 + (wide - 1) * BINGO_DATA.bingo_add
                local rand_max = wide * BINGO_DATA.bingo_add
                --縦列に同一の値が出ないように調整
                local data_put_flg = {}
                for i = rand_min, rand_max do
                    data_put_flg[i] = false
                end

                --縦列
                for high = 1, BINGO_DATA.bingo_split do
                    --とり得る値
                    local rand_data = math.random(rand_min, rand_max)
                    --もし、値が出ていたならば
                    while data_put_flg[rand_data] do
                        rand_data = math.random(rand_min, rand_max)
                    end
                    --出ないように
                    data_put_flg[rand_data] = true
                    --値の保持
                    local est = high + (wide - 1) * BINGO_DATA.bingo_split
                    BINGO_MOVE.bingo_array[page][est] = rand_data
                    local num = (page - 1) * BINGO_DATA.bingo_split_max + est

                    --中心部
                    if high == 3 and wide == 3 then
                        rand_data = 0
                    end

                    if rand_data == 0 then
                        ASSET._ALL_SetText(BINGO_DATA.str_txt .. tostring(num), "★")
                    else
                        ASSET._ALL_SetText(BINGO_DATA.str_txt .. tostring(num), rand_data)
                    end
                    ASSET._ALL_SetMaterialColorFromName(BINGO_DATA.str_material .. tostring(num), COL_WHITE)
                    STATE.Set(BINGO_DATA.str_txt .. tostring(num), rand_data)
                end
            end
        end
        l_use_flg = false
    end

    --出たもの初期化
    BINGO_MOVE.bingo_choice_array = {}
    STATE.Set(BINGO_DATA.str_set, 0)

    vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
end

--ランダムデータセット
vci.StartCoroutine(
    coroutine.create(
        function()
            while true do
                local time = 0
                local time_count = 1 / 15
                while l_rand_col_flg and l_rand_flg do
                    --1～5*15
                    local rand_data = math.random(1, BINGO_DATA.bingo_split * BINGO_DATA.bingo_add)

                    local flg = true
                    while flg do
                        flg = false
                        for i = 1, #BINGO_MOVE.bingo_choice_array do
                            if (os.clock() - time) > time_count then
                                time = os.clock()
                                coroutine.yield()
                            end
                            if BINGO_MOVE.bingo_choice_array[i] == rand_data then
                                rand_data = math.random(1, BINGO_DATA.bingo_split * BINGO_DATA.bingo_add)
                                flg = true
                                break
                            end
                        end
                    end
                    BINGO_MOVE.bingo_choice_array[1 + #BINGO_MOVE.bingo_choice_array] = rand_data
                    STATE.Set(BINGO_DATA.str_set .. tostring(#BINGO_MOVE.bingo_choice_array), rand_data)
                    STATE.Set(BINGO_DATA.str_set, #BINGO_MOVE.bingo_choice_array)
                    vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
                    l_rand_col_flg = false
                end
                coroutine.yield()
            end
        end
    )
)

--時間管理用
function TimeManage(now_time, time_span)
    --指定時間超え
    if (os.clock() - now_time) > time_span then
        now_time = os.clock()
        return true
    end
    return false
end

--ボードの初期化メッセージ
function BoardNillMess(sender, name, message)
    nil_wait_timer = os.clock()
end
vci.message.On(ASHU_MESS .. "BOARD_NILL", BoardNillMess)

--ボードのnil処理
function BoardNillSet()
    BINGO_MOVE.bingo_array = nil
    l_rand_flg = false
end

--ボードのステート処理
function BoardStateSet()
    --色データ
    local col_data = {}
    BINGO_MOVE.bingo_array = {}
    --5*5マス*枚数
    for page = 1, BINGO_DATA.bingo_page_max do
        BINGO_MOVE.bingo_array[page] = {}
        --横列
        for wide = 1, BINGO_DATA.bingo_split do
            BINGO_MOVE.bingo_array[page][wide] = {}
            --縦列
            for high = 1, BINGO_DATA.bingo_split do
                local num = (page - 1) * BINGO_DATA.bingo_split_max + high + (wide - 1) * BINGO_DATA.bingo_split
                BINGO_MOVE.bingo_array[page][wide][high] = STATE.Get(BINGO_DATA.str_txt .. tostring(num))
                if BINGO_MOVE.bingo_array[page][wide][high] == 0 then
                    ASSET.SetText(BINGO_DATA.str_txt .. tostring(num), "★")
                else
                    ASSET.SetText(BINGO_DATA.str_txt .. tostring(num), BINGO_MOVE.bingo_array[page][wide][high])
                end
                col_data[num] = COL_WHITE
                ASSET.SetMaterialColorFromName(BINGO_DATA.str_material .. tostring(num), COL_WHITE)
            end
        end
    end

    --基本色
    local set_num = STATE.Get(BINGO_DATA.str_set)
    for i = 1, set_num do
        BINGO_MOVE.bingo_choice_array[i] = STATE.Get(BINGO_DATA.str_set .. tostring(i))
        --5*5マス*枚数
        for page = 1, BINGO_DATA.bingo_page_max do
            --横列
            for wide = 1, BINGO_DATA.bingo_split do
                --縦列
                for high = 1, BINGO_DATA.bingo_split do
                    local num = (page - 1) * BINGO_DATA.bingo_split_max + high + (wide - 1) * BINGO_DATA.bingo_split

                    if BINGO_MOVE.bingo_choice_array[i] == BINGO_MOVE.bingo_array[page][wide][high] then
                        ASSET.SetMaterialColorFromName(BINGO_DATA.str_material .. tostring(num), COL_BLACK)
                    end
                end
            end
        end
    end

    local txt = ""
    local high_num = 1
    for i = 1, #BINGO_MOVE.bingo_choice_array do
        if txt ~= "" then
            txt = txt .. ", "
        end
        txt = txt .. tostring(BINGO_MOVE.bingo_choice_array[i])
        if (i - 1) % 5 == 4 and i ~= #BINGO_MOVE.bingo_choice_array then
            txt = txt .. "\n"
            high_num = high_num + 1
        end
    end
    ASSET.SetText(BINGO_DATA.str_txt .. "show", txt)
    local si = BINGO_DATA.str_show_si[1]
    local size = Vector3.__new(BINGO_DATA.show_size.x, BINGO_DATA.show_size.y, BINGO_DATA.show_size.z)
    if high_num < 3 then
        high_num = 3
    end
    size.y = size.y * high_num
    si.SetLocalScale(size)

    --リーチ/ビンゴ色
    --5*5マス*枚数
    for page = 1, BINGO_DATA.bingo_page_max do
        --縦処理
        --横列
        for wide = 1, BINGO_DATA.bingo_split do
            --数値
            local num_num = {}
            --縦列
            for high = 1, BINGO_DATA.bingo_split do
                --中心部
                if BINGO_MOVE.bingo_array[page][wide][high] == 0 then
                    local num = (page - 1) * BINGO_DATA.bingo_split_max + 13
                    num_num[1 + #num_num] = num
                else
                    --出てるやつと比較
                    for i = 1, #BINGO_MOVE.bingo_choice_array do
                        if BINGO_MOVE.bingo_choice_array[i] == BINGO_MOVE.bingo_array[page][wide][high] then
                            local num =
                                (page - 1) * BINGO_DATA.bingo_split_max + high + (wide - 1) * BINGO_DATA.bingo_split
                            num_num[1 + #num_num] = num
                        end
                    end
                end
            end
            --色変え
            ColorChange(col_data, num_num)
        end

        --横処理
        --縦列
        for high = 1, BINGO_DATA.bingo_split do
            --数値
            local num_num = {}
            --横列
            for wide = 1, BINGO_DATA.bingo_split do
                --中心部
                if BINGO_MOVE.bingo_array[page][wide][high] == 0 then
                    local num = (page - 1) * BINGO_DATA.bingo_split_max + 13
                    num_num[1 + #num_num] = num
                else
                    --出てるやつと比較
                    for i = 1, #BINGO_MOVE.bingo_choice_array do
                        if BINGO_MOVE.bingo_choice_array[i] == BINGO_MOVE.bingo_array[page][wide][high] then
                            local num =
                                (page - 1) * BINGO_DATA.bingo_split_max + high + (wide - 1) * BINGO_DATA.bingo_split
                            num_num[1 + #num_num] = num
                        end
                    end
                end
            end
            --色変え
            ColorChange(col_data, num_num)
        end

        --数値
        local num_num = {}
        --左から右下処理
        for i = 1, BINGO_DATA.bingo_split do
            --中心部
            if BINGO_MOVE.bingo_array[page][i][i] == 0 then
                local num = (page - 1) * BINGO_DATA.bingo_split_max + 13
                num_num[1 + #num_num] = num
            else
                --出てるやつと比較
                for i2 = 1, #BINGO_MOVE.bingo_choice_array do
                    if BINGO_MOVE.bingo_choice_array[i2] == BINGO_MOVE.bingo_array[page][i][i] then
                        local num = (page - 1) * BINGO_DATA.bingo_split_max + (i - 1) * BINGO_DATA.bingo_split + i
                        num_num[1 + #num_num] = num
                    end
                end
            end
        end
        --色変え
        ColorChange(col_data, num_num)

        --数値
        local num_num = {}
        --右から左下処理
        for i = 1, BINGO_DATA.bingo_split do
            --中心部
            if BINGO_MOVE.bingo_array[page][i][i] == 0 then
                local num = (page - 1) * BINGO_DATA.bingo_split_max + 13
                num_num[1 + #num_num] = num
            else
                --出てるやつと比較
                for i2 = 1, #BINGO_MOVE.bingo_choice_array do
                    if
                        BINGO_MOVE.bingo_choice_array[i2] ==
                            BINGO_MOVE.bingo_array[page][i][(BINGO_DATA.bingo_split - i + 1)]
                     then
                        local num =
                            (page - 1) * BINGO_DATA.bingo_split_max + (i - 1) * BINGO_DATA.bingo_split +
                            (BINGO_DATA.bingo_split - i + 1)
                        num_num[1 + #num_num] = num
                    end
                end
            end
        end
        --色変え
        ColorChange(col_data, num_num)
    end
    --色変わる処理
    for i = 1, #col_data do
        if col_data[i] == COL_BINGO or col_data[i] == COL_REACH then
            ASSET.SetMaterialColorFromName(BINGO_DATA.str_material .. tostring(i), col_data[i])
        end
    end

    l_rand_flg = false
end

--色変え
function ColorChange(col_data, num_num)
    if #num_num == BINGO_DATA.bingo_split - 1 then
        for i = 1, #num_num do
            if col_data[num_num[i]] ~= COL_BINGO then
                col_data[num_num[i]] = COL_REACH
            end
        end
    elseif #num_num == BINGO_DATA.bingo_split then
        for i = 1, #num_num do
            col_data[num_num[i]] = COL_BINGO
        end
    end
end

function PlayAnimation(key)
    StopAnimation(key)
    ASSET._ALL_PlayAnimationFromName(key, true)
end

function StopAnimation()
    --- 問答無用で全アニメーションを止める
    ASSET._ALL_StopAnimation()
end
