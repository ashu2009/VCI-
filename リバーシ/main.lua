--簡略化
local STATE = vci.state
local ASSET = vci.assets
local ASHU_MESS = "ASHU_REVERSE_AI_MESS_"
local NOT_DEBUG = true
local WHITE = Color.__new(1, 1, 1, 1)
local BLACK = Color.__new(0.14, 0.14, 0.14, 1)

local REVERSI_DATA = {
    --白番号
    w_num = 1,
    --黒番号
    bk_num = 2,
    --アイテム基礎名称
    str = {"盤", "戻る", "初期化", "CPU", "白黒", "自動許可", "駒集合", "駒"},
    str_si = {},
    --盤
    str_board_num = 1,
    --横分割数
    board_split = 8,
    --マス数
    board_split_max = 64,
    --戻る
    str_return_num = 2,
    --初期化
    str_first_num = 3,
    --CPU
    str_cpu_num = 4,
    --白黒
    str_w_bk_num = 5,
    --自動許可
    str_permission_num = 6,
    --駒集合
    str_piece_set_num = 7,
    str_piece_set_si = {},
    --駒
    str_board_piece_num = 8,
    str_piece_si = {},
    --駒の駒集合からの出現高さ
    piece_high = 0.2,
    --持てるやつ
    piece_w_num = 67,
    --半透明
    piece_w_sub_num = 65,
    --持てるやつ
    piece_bk_num = 68,
    --半透明
    piece_bk_sub_num = 66,
    --1マスのサイズ
    split_scale = 0.125,
    --駒の高さ
    piece_hight = 0.12,
    --反応距離
    dist = 0.3,
    --material
    str_material = {"", "戻る", "戻る", "UPU", "白黒", "自動許可"},
    --時間制御
    time_span = 4.5,
    time_span2 = 6
}

local REVERSI_MOVE = {
    --駒の配置(0:無,白,黒)
    piece_put_w_bk = nil,
    --白黒のターン
    turn_num = 0,
    --cpu状態
    cpu_mode = false,
    --許可状態
    permission = false,
    --cpuどちら
    w_bk_mode = REVERSI_DATA.w_num,
    --時間制御
    est_time = 1,
    est_time2 = 1
}

--サブアイテム関係
for i = 1, #REVERSI_DATA.str do
    --駒と駒集合以外
    if i < REVERSI_DATA.str_piece_set_num then
        REVERSI_DATA.str_si[i] = ASSET.GetSubItem(REVERSI_DATA.str[i])
    elseif i == REVERSI_DATA.str_piece_set_num then
        --駒集合
        for i2 = 1, REVERSI_DATA.bk_num do
            REVERSI_DATA.str_piece_set_si[i2] = ASSET.GetSubItem(REVERSI_DATA.str[i] .. tostring(i2))
        end
    elseif i == REVERSI_DATA.str_board_piece_num then
        --駒
        for i2 = 1, REVERSI_DATA.piece_bk_num do
            REVERSI_DATA.str_piece_si[i2] = ASSET.GetSubItem(REVERSI_DATA.str[i] .. tostring(i2))
        end
    end
end

if ASSET.IsMine then
    STATE.Set("CPU", REVERSI_MOVE.cpu_mode)
    STATE.Set("RETURN", 0)
    STATE.Set("PERMISSION", REVERSI_MOVE.permission)
    STATE.Set("W_BK", REVERSI_MOVE.w_bk_mode)
    STATE.Set("FIRST", true)
end

ASSET.SetText("Text1", "   白:0")
ASSET.SetText("Text2", "　　　   黒:0")

--メイン時間
local m_timer = 0
--時間間隔
local m_timer_cnt = 1 / 20
--初期化フラグ
local first_flg = true
function update()
    --時間管理
    if TimeManage(m_timer, m_timer_cnt) then
        if first_flg then
            --初期化
            FirstDataSet()
            first_flg = false
        end

        --配置処理
        PudBoard()

        local board_pos = REVERSI_MOVE.piece_put_w_bk
        local w_count = 0
        local bk_count = 0
        --縦の位置
        for high_pos = 1, #board_pos do
            --横の位置
            for wide_pos = 1, #board_pos[high_pos] do
                if board_pos[high_pos][wide_pos] == REVERSI_DATA.bk_num then
                    bk_count = bk_count + 1
                elseif board_pos[high_pos][wide_pos] == REVERSI_DATA.w_num then
                    w_count = w_count + 1
                end
            end
        end

        if (bk_count + w_count) == 64 then
            ASSET._ALL_SetText("Text1", "   白:" .. tostring(w_count))
            local txt = "　　　   黒:" .. tostring(bk_count)
            if bk_count > w_count then
                txt = txt .. "\n　 黒の勝利"
            elseif w_count > bk_count then
                txt = txt .. "\n　 白の勝利"
            else
                txt = txt .. "\n　 引き分け"
            end
            ASSET._ALL_SetText("Text2", txt)
        else
            ASSET._ALL_SetText("Text1", "   白:" .. tostring(w_count))
            local txt = "　　　   黒:" .. tostring(bk_count)
            if REVERSI_MOVE.turn_num == REVERSI_DATA.bk_num then
                txt = txt .. "\n　 黒の手番"
            elseif REVERSI_MOVE.turn_num == REVERSI_DATA.w_num then
                txt = txt .. "\n　 白の手番"
            else
                txt = txt .. "\n   どちらでも"
            end
            ASSET._ALL_SetText("Text2", txt)
        end
    end
end

--時間処理
local timer = os.clock()
local timer_count = 1 / 15
--nilにするタイマー
local nil_wait_timer = -1
--nilにする時間
local nil_wait_timer_count = 1 / 5
--ディープ処理フラグ
local deep_flg = false
--ノーマル処理フラグ
local normal_flg = false
--初期化許可
local permission_first = false
function updateAll()
    if NOT_DEBUG then
        if nil_wait_timer ~= 0 and (os.clock() - nil_wait_timer) > nil_wait_timer_count then
            BoardStateSet()
            --2度はいらない
            nil_wait_timer = 0
        end
    end
    --時間管理
    if TimeManage(timer, timer_count) then
        --盤面の位置駒(配列)
        local board_pos = REVERSI_MOVE.piece_put_w_bk
        --nilタイマー起動状態でない
        if nil_wait_timer == 0 and permission_first then
            --cpu
            if REVERSI_MOVE.cpu_mode then
                --print(REVERSI_MOVE.turn_num)
                --どちらも置ける
                if REVERSI_MOVE.turn_num == 0 then
                    --先手許可しない
                    if not REVERSI_MOVE.permission then
                        --cpu側置けない
                        if REVERSI_MOVE.w_bk_mode ~= REVERSI_MOVE.turn_num then
                            --全員用
                            AllMain()
                        end
                    else
                        if ASSET.IsMine and not (deep_flg or normal_flg) then
                            AllCPUMain(board_pos, REVERSI_MOVE.w_bk_mode)
                        end
                    end
                else
                    if REVERSI_MOVE.turn_num ~= REVERSI_MOVE.w_bk_mode then
                        AllMain()
                        local data = StoneChange(board_pos, REVERSI_MOVE.turn_num)
                        if data.flg then
                            REVERSI_MOVE.turn_num = REVERSI_MOVE.turn_num % 2 + 1
                            STATE.Set("TURN", REVERSI_MOVE.turn_num)
                            vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
                        end
                    elseif ASSET.IsMine and not (deep_flg or normal_flg) then
                        AllCPUMain(board_pos, REVERSI_MOVE.w_bk_mode)
                        local data = StoneChange(board_pos, REVERSI_MOVE.turn_num)
                        if data.flg then
                            REVERSI_MOVE.turn_num = REVERSI_MOVE.turn_num % 2 + 1
                            STATE.Set("TURN", REVERSI_MOVE.turn_num)
                            vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
                        end
                    end
                end
            else
                AllMain()
                local data = StoneChange(board_pos, REVERSI_MOVE.turn_num)
                if REVERSI_MOVE.turn_num ~= 0 and data.flg then
                    STATE.Set("TURN", REVERSI_MOVE.turn_num % 2 + 1)
                    vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
                end
            end
        end
    end
end

--初期化セット
function FirstDataSet()
    if NOT_DEBUG then
        STATE.Set("TURN", 0)
        STATE.Set("RETURN", 0)
        STATE.Set("FIRST", true)
    end
    --駒初期配置
    REVERSI_MOVE.piece_put_w_bk = {}
    --縦
    for high = 1, REVERSI_DATA.str_board_piece_num do
        REVERSI_MOVE.piece_put_w_bk[high] = {}
        --横
        for wide = 1, REVERSI_DATA.str_board_piece_num do
            --白黒判断
            local w_bk_num = 0
            if high == 4 then
                if wide == 4 then
                    --黒
                    w_bk_num = w_bk_num + 2
                elseif wide == 5 then
                    --白
                    w_bk_num = w_bk_num + 1
                end
            elseif high == 5 then
                if wide == 5 then
                    --黒
                    w_bk_num = w_bk_num + 2
                elseif wide == 4 then
                    --白
                    w_bk_num = w_bk_num + 1
                end
            end

            --アイテム場所
            local num = wide + (high - 1) * REVERSI_DATA.str_board_piece_num
            REVERSI_MOVE.piece_put_w_bk[high][wide] = w_bk_num
            if NOT_DEBUG then
                STATE.Set(REVERSI_DATA.str[REVERSI_DATA.str_board_piece_num] .. tostring(num), w_bk_num)
                STATE.Set("BEFORE" .. REVERSI_DATA.str[REVERSI_DATA.str_board_piece_num] .. tostring(num), w_bk_num)
            end
        end
    end
    if NOT_DEBUG then
        vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
    end
end

--握ってる番号
local l_grip_num = 0
--ろーかるの掴んだ番号記録
function onGrab(target)
    --駒検索
    if target == REVERSI_DATA.str_piece_si[REVERSI_DATA.piece_w_num].GetName() then
        --握った番号保持
        l_grip_num = REVERSI_DATA.w_num
    elseif target == REVERSI_DATA.str_piece_si[REVERSI_DATA.piece_bk_num].GetName() then
        l_grip_num = REVERSI_DATA.bk_num
    end
end

--握った番号初期化
function onUngrab(target)
    --駒検索
    if target == REVERSI_DATA.str_piece_si[REVERSI_DATA.piece_w_num].GetName() then
        --握った番号保持
        l_grip_num = 0
    elseif target == REVERSI_DATA.str_piece_si[REVERSI_DATA.piece_bk_num].GetName() then
        l_grip_num = 0
    end
end

--use処理
local l_use_flg = false
function onUse(use)
    --駒集合
    for i = 1, REVERSI_DATA.bk_num do
        if use == REVERSI_DATA.str_piece_set_si[i].GetName() then
            local piece_set_si = REVERSI_DATA.str_piece_set_si[i]
            local sub_si = REVERSI_DATA.str_piece_si[REVERSI_DATA.piece_w_num + (i - 1)]
            local pos = piece_set_si.GetLocalPosition()
            pos.y = pos.y + REVERSI_DATA.piece_high
            sub_si.SetLocalPosition(pos)
            if i == REVERSI_DATA.w_num then
                Rot_LocalQuat_Euler(sub_si, 0, 0, 0)
            else
                Rot_LocalQuat_Euler(sub_si, 180, 0, 0)
            end
        end
    end

    --駒集合
    for i = 1, REVERSI_DATA.bk_num do
        if REVERSI_MOVE.turn_num == i or REVERSI_MOVE.turn_num == 0 then
            if use == REVERSI_DATA.str_piece_si[REVERSI_DATA.piece_w_num + (i - 1)].GetName() then
                l_use_flg = i
            end
        end
    end

    --サブ動作
    for i = 1, #REVERSI_DATA.str do
        if use == REVERSI_DATA.str[i] then
            l_use_flg = false
            if i == REVERSI_DATA.str_first_num then
                if STATE.Get("FIRST") then
                    --初期化
                    FirstDataSet()
                end
                break
            elseif i == REVERSI_DATA.str_cpu_num then
                --cpuモード
                if REVERSI_MOVE.cpu_mode ~= nil then
                    STATE.Set("CPU", not REVERSI_MOVE.cpu_mode)
                end
                vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
            elseif i == REVERSI_DATA.str_permission_num then
                --先手/後手
                if REVERSI_MOVE.permission ~= nil then
                    STATE.Set("PERMISSION", not REVERSI_MOVE.permission)
                end
                vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
            elseif i == REVERSI_DATA.str_w_bk_num then
                --cpu白黒
                if REVERSI_MOVE.w_bk_mode ~= nil then
                    STATE.Set("W_BK", (REVERSI_MOVE.w_bk_mode % 2) + 1)
                end
                vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
            elseif i == REVERSI_DATA.str_return_num then
                local flg = true
                if NOT_DEBUG then
                    --縦
                    for high = 1, REVERSI_DATA.str_board_piece_num do
                        --横
                        for wide = 1, REVERSI_DATA.str_board_piece_num do
                            local num = wide + (high - 1) * REVERSI_DATA.str_board_piece_num
                            local data =
                                STATE.Get(
                                "BEFORE" .. REVERSI_DATA.str[REVERSI_DATA.str_board_piece_num] .. tostring(num)
                            )
                            if data ~= nil then
                                REVERSI_MOVE.piece_put_w_bk[high][wide] = data
                                STATE.Set(
                                    REVERSI_DATA.str[REVERSI_DATA.str_board_piece_num] .. tostring(num),
                                    REVERSI_MOVE.piece_put_w_bk[high][wide]
                                )
                            else
                                flg = false
                                high = REVERSI_DATA.str_board_piece_num
                                break
                            end
                        end
                    end
                    if flg then
                        REVERSI_MOVE.turn_num = STATE.Get("RETURN")
                        STATE.Set("TURN", REVERSI_MOVE.turn_num)
                    end
                end
                vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
            end
        end
    end
end

--置く場所計算
function PutLayout(board_pos, grip_num, board_si_pos, auxiliary_num, board_si, split_scale, piece_hight, w_bk_num)
    --仮の配置
    local grip_si = REVERSI_DATA.str_piece_si[grip_num]
    local grip_si_pos = grip_si.GetLocalPosition()
    local dist = REVERSI_DATA.dist
    local reverse_data = {}
    --縦の位置
    for high_pos = 1, #board_pos do
        --横の位置
        for wide_pos = 1, #board_pos[high_pos] do
            --置くことのできる箇所か把握
            local return_data = PermissionPut(true, board_pos, high_pos, wide_pos, w_bk_num)
            if return_data.flg then
                --配置位置
                local x = (-0.5 + high_pos - math.ceil(#board_pos / 2)) * split_scale
                local z = (-0.5 + wide_pos - math.ceil(#board_pos[high_pos] / 2)) * split_scale
                --盤の中心から指定位置に置く
                local sub_pos = board_si_pos + RelativeToLocalCoordinates(board_si, x, piece_hight, z)

                --減算処理
                local x = grip_si_pos.x - sub_pos.x
                local y = grip_si_pos.y - sub_pos.y
                local z = grip_si_pos.z - sub_pos.z
                local dist_est = math.sqrt(x * x + y * y + z * z)

                if dist_est < dist then
                    auxiliary_num = wide_pos + (high_pos - 1) * #board_pos[high_pos]
                    dist = dist_est
                    --裏返る情報保持
                    reverse_data = return_data.reverse_data
                end
            end
        end
    end

    local r = {reverse_data = reverse_data, auxiliary_num = auxiliary_num}
    return r
end

--全員用
function AllMain()
    --基準の盤
    local board_si = REVERSI_DATA.str_si[REVERSI_DATA.str_board_num]
    local board_si_pos = board_si.GetLocalPosition()
    --盤面の位置駒(配列)
    local board_pos = REVERSI_MOVE.piece_put_w_bk
    --握ってるやつとの位置計算
    --握ってる番号
    local grip_num = -1
    --駒のサブアイテム番号
    local piece_si = REVERSI_DATA.str_piece_si
    --1マスの大きさ
    local split_scale = REVERSI_DATA.split_scale
    --配置高さ
    local piece_hight = REVERSI_DATA.piece_hight
    --合算する角度
    local add_ang = Vector3.__new(0, 0, 0)
    --縦の位置
    for high_pos = 1, #board_pos do
        --横の位置
        for wide_pos = 1, #board_pos[high_pos] do
            --黒なら反転
            if board_pos[high_pos][wide_pos] == REVERSI_DATA.bk_num then
                add_ang.x = 180
                local ang = board_si.GetLocalRotation().eulerAngles
                add_ang.z = -ang.z * 2
            else
                add_ang = Vector3.__new(0, 0, 0)
            end

            --盤上配置処理
            BoardLayoutPut(
                board_si,
                piece_si,
                high_pos,
                wide_pos,
                board_pos,
                grip_num,
                split_scale,
                piece_hight,
                add_ang
            )
        end
    end

    --補助の位置
    local auxiliary_w_num = 0
    --裏返る情報
    local w_reverse = {}
    local auxiliary_bk_num = 0
    local bk_reverse = {}
    --握っているものがある(白黒)
    if REVERSI_MOVE.turn_num == 0 then
        --白
        grip_num = REVERSI_DATA.piece_w_num
        local return_data =
            PutLayout(
            board_pos,
            grip_num,
            board_si_pos,
            auxiliary_w_num,
            board_si,
            split_scale,
            piece_hight,
            REVERSI_DATA.w_num
        )
        --何処に配置するか計算
        auxiliary_w_num = return_data.auxiliary_num
        w_reverse = return_data.reverse_data

        --黒
        grip_num = REVERSI_DATA.piece_bk_num
        --何処に配置するか計算
        return_data =
            PutLayout(
            board_pos,
            grip_num,
            board_si_pos,
            auxiliary_bk_num,
            board_si,
            split_scale,
            piece_hight,
            REVERSI_DATA.bk_num
        )
        auxiliary_bk_num = return_data.auxiliary_num
        bk_reverse = return_data.reverse_data
    elseif REVERSI_MOVE.turn_num == REVERSI_DATA.w_num then
        --白
        grip_num = REVERSI_DATA.piece_w_num
        local return_data =
            PutLayout(
            board_pos,
            grip_num,
            board_si_pos,
            auxiliary_w_num,
            board_si,
            split_scale,
            piece_hight,
            REVERSI_DATA.w_num
        )
        --何処に配置するか計算
        auxiliary_w_num = return_data.auxiliary_num
        w_reverse = return_data.reverse_data
    elseif REVERSI_MOVE.turn_num == REVERSI_DATA.bk_num then
        --黒
        grip_num = REVERSI_DATA.piece_bk_num
        --何処に配置するか計算
        local return_data =
            PutLayout(
            board_pos,
            grip_num,
            board_si_pos,
            auxiliary_bk_num,
            board_si,
            split_scale,
            piece_hight,
            REVERSI_DATA.bk_num
        )
        auxiliary_bk_num = return_data.auxiliary_num
        bk_reverse = return_data.reverse_data
    end

    --白
    if auxiliary_w_num > 0 then
        grip_num = REVERSI_DATA.piece_w_num
        --補助からの計算
        AuxiliaryEstimate(
            auxiliary_w_num,
            board_pos,
            board_si_pos,
            grip_num,
            piece_si,
            board_si,
            piece_hight,
            split_scale,
            w_reverse
        )
    else
        if piece_si[REVERSI_DATA.piece_w_sub_num].IsMine then
            piece_si[REVERSI_DATA.piece_w_sub_num].SetLocalPosition(Vector3.__new(0, -100000, 0))
        end
    end
    --黒
    if auxiliary_bk_num > 0 then
        grip_num = REVERSI_DATA.piece_bk_num
        --補助からの計算
        AuxiliaryEstimate(
            auxiliary_bk_num,
            board_pos,
            board_si_pos,
            grip_num,
            piece_si,
            board_si,
            piece_hight,
            split_scale,
            bk_reverse
        )
    else
        if piece_si[REVERSI_DATA.piece_bk_sub_num].IsMine then
            piece_si[REVERSI_DATA.piece_bk_sub_num].SetLocalPosition(Vector3.__new(0, -100000, 0))
        end
    end
end

--補助からの計算
function AuxiliaryEstimate(
    auxiliary_num,
    board_pos,
    board_si_pos,
    grip_num,
    piece_si,
    board_si,
    piece_hight,
    split_scale,
    reverse)
    --配置位置
    local x = (0.5 + math.floor((auxiliary_num - 1) / #board_pos[1]) - math.ceil(#board_pos / 2)) * split_scale
    local z = ((0.5 + (auxiliary_num - 1) % #board_pos[1]) - math.ceil(#board_pos[1] / 2)) * split_scale
    --盤の中心から指定位置に置く
    local sub_pos = board_si_pos + RelativeToLocalCoordinates(board_si, x, piece_hight, z)
    local ang = board_si.GetLocalRotation().eulerAngles
    if REVERSI_MOVE.turn_num == 0 then
        if grip_num == REVERSI_DATA.piece_w_num then
            if piece_si[REVERSI_DATA.piece_w_sub_num].IsMine then
                piece_si[REVERSI_DATA.piece_w_sub_num].SetLocalPosition(sub_pos)
                Rot_LocalQuat_Euler(piece_si[REVERSI_DATA.piece_w_sub_num], ang.x, ang.y, ang.z)
            end
        elseif grip_num == REVERSI_DATA.piece_bk_num then
            if piece_si[REVERSI_DATA.piece_bk_sub_num].IsMine then
                piece_si[REVERSI_DATA.piece_bk_sub_num].SetLocalPosition(sub_pos)
                local ang = board_si.GetLocalRotation().eulerAngles
                Rot_LocalQuat_Euler(piece_si[REVERSI_DATA.piece_bk_sub_num], ang.x + 180, ang.y, ang.z - ang.z * 2)
            end
        end
    elseif REVERSI_MOVE.turn_num == REVERSI_DATA.bk_num then
        if piece_si[REVERSI_DATA.piece_bk_sub_num].IsMine then
            piece_si[REVERSI_DATA.piece_bk_sub_num].SetLocalPosition(sub_pos)
            local ang = board_si.GetLocalRotation().eulerAngles
            Rot_LocalQuat_Euler(piece_si[REVERSI_DATA.piece_bk_sub_num], ang.x + 180, ang.y, ang.z - ang.z * 2)
        end
    elseif REVERSI_MOVE.turn_num == REVERSI_DATA.w_num then
        if piece_si[REVERSI_DATA.piece_w_sub_num].IsMine then
            piece_si[REVERSI_DATA.piece_w_sub_num].SetLocalPosition(sub_pos)
            Rot_LocalQuat_Euler(piece_si[REVERSI_DATA.piece_w_sub_num], ang.x, ang.y, ang.z)
        end
    end
    --配置位置
    local x = 1 + math.floor((auxiliary_num - 1) / REVERSI_DATA.board_split)
    local z = 1 + (auxiliary_num - 1) % REVERSI_DATA.board_split
    if l_use_flg and auxiliary_num > 0 then
        if grip_num == REVERSI_DATA.piece_w_num and l_use_flg == REVERSI_DATA.w_num then
            --縦
            for high = 1, REVERSI_DATA.str_board_piece_num do
                --横
                for wide = 1, REVERSI_DATA.str_board_piece_num do
                    --アイテム場所
                    local num = wide + (high - 1) * REVERSI_DATA.str_board_piece_num
                    if NOT_DEBUG then
                        STATE.Set(
                            "BEFORE" .. REVERSI_DATA.str[REVERSI_DATA.str_board_piece_num] .. tostring(num),
                            REVERSI_MOVE.piece_put_w_bk[high][wide]
                        )
                    end
                end
            end

            STATE.Set("RETURN", REVERSI_MOVE.turn_num)
            REVERSI_MOVE.turn_num = REVERSI_DATA.bk_num
            STATE.Set("TURN", REVERSI_MOVE.turn_num)
            --リバース反映
            ReversePut(reverse, board_pos, x, z, l_use_flg)

            if NOT_DEBUG then
                --縦
                for high = 1, REVERSI_DATA.str_board_piece_num do
                    --横
                    for wide = 1, REVERSI_DATA.str_board_piece_num do
                        --アイテム場所
                        local num = wide + (high - 1) * REVERSI_DATA.str_board_piece_num
                        if NOT_DEBUG then
                            STATE.Set(
                                REVERSI_DATA.str[REVERSI_DATA.str_board_piece_num] .. tostring(num),
                                REVERSI_MOVE.piece_put_w_bk[high][wide]
                            )
                        end
                    end
                end
                vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
            end
            l_grip_num = 0
            l_use_flg = false
        elseif grip_num == REVERSI_DATA.piece_bk_num and l_use_flg == REVERSI_DATA.bk_num then
            --縦
            for high = 1, REVERSI_DATA.str_board_piece_num do
                --横
                for wide = 1, REVERSI_DATA.str_board_piece_num do
                    --アイテム場所
                    local num = wide + (high - 1) * REVERSI_DATA.str_board_piece_num
                    if NOT_DEBUG then
                        STATE.Set(
                            "BEFORE" .. REVERSI_DATA.str[REVERSI_DATA.str_board_piece_num] .. tostring(num),
                            REVERSI_MOVE.piece_put_w_bk[high][wide]
                        )
                    end
                end
            end
            STATE.Set("RETURN", REVERSI_MOVE.turn_num)
            REVERSI_MOVE.turn_num = REVERSI_DATA.w_num
            STATE.Set("TURN", REVERSI_MOVE.turn_num)
            --リバース反映
            ReversePut(reverse, board_pos, x, z, l_use_flg)

            if NOT_DEBUG then
                --縦
                for high = 1, REVERSI_DATA.str_board_piece_num do
                    --横
                    for wide = 1, REVERSI_DATA.str_board_piece_num do
                        --アイテム場所
                        local num = wide + (high - 1) * REVERSI_DATA.str_board_piece_num
                        if NOT_DEBUG then
                            STATE.Set(
                                REVERSI_DATA.str[REVERSI_DATA.str_board_piece_num] .. tostring(num),
                                REVERSI_MOVE.piece_put_w_bk[high][wide]
                            )
                        end
                    end
                end
                vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
            end
            l_grip_num = 0
            l_use_flg = false
        end
    end
end

--リバース反映
function ReversePut(reverse, board_pos, high, wide, grip_num)
    board_pos[high][wide] = grip_num
    for high_pos = 1, #reverse do
        for wide_pos = 1, #reverse[high_pos] do
            if reverse[high_pos][wide_pos] ~= 0 then
                board_pos[high_pos][wide_pos] = reverse[high_pos][wide_pos]
            end
        end
    end
end

--置くことのできる箇所把握
function PermissionPut(put_flg, board_pos, high_pos, wide_pos, w_bk_num)
    --何個裏返す
    local reverse_count = 0
    --返り値
    local return_flg = false
    --ひっくり返るデータ
    local reverse_data = {}
    for high = 1, #board_pos do
        reverse_data[high] = {}
        for wide = 1, #board_pos[high] do
            reverse_data[high][wide] = 0
        end
    end

    --裏返す情報入れる
    local r = {flg = return_flg, reverse_data = reverse_data}
    --駒ない場所か判断
    if board_pos[high_pos][wide_pos] ~= 0 then
        r = {flg = return_flg, reverse_data = reverse_data}
        return r
    end
    --右
    for i = wide_pos + 1, #board_pos[1] do
        --右が何もない
        if board_pos[high_pos][i] == 0 then
            break
        elseif board_pos[high_pos][i] ~= w_bk_num then
            --相手の色
            reverse_count = reverse_count + 1
        else
            --挟めているので
            if reverse_count > 0 then
                return_flg = true
                if put_flg then
                    --ひっくり返すやつ
                    for add = 1, reverse_count do
                        reverse_data[high_pos][wide_pos + add] = w_bk_num
                    end
                else
                    r = {flg = return_flg, reverse_data = reverse_data}
                    return r
                end
            end
            break
        end
    end
    reverse_count = 0
    --左
    for i = wide_pos - 1, 1, -1 do
        --左が何もない
        if board_pos[high_pos][i] == 0 then
            break
        elseif board_pos[high_pos][i] ~= w_bk_num then
            --相手の色
            reverse_count = reverse_count + 1
        else
            --挟めているので
            if reverse_count > 0 then
                return_flg = true
                if put_flg then
                    --ひっくり返すやつ
                    for add = 1, reverse_count do
                        reverse_data[high_pos][wide_pos - add] = w_bk_num
                    end
                else
                    r = {flg = return_flg, reverse_data = reverse_data}
                    return r
                end
            end
            break
        end
    end

    reverse_count = 0
    --下
    for i = high_pos + 1, #board_pos do
        --下が何もない
        if board_pos[i][wide_pos] == 0 then
            break
        elseif board_pos[i][wide_pos] ~= w_bk_num then
            --相手の色
            reverse_count = reverse_count + 1
        else
            --挟めているので
            if reverse_count > 0 then
                return_flg = true
                if put_flg then
                    --ひっくり返すやつ
                    for add = 1, reverse_count do
                        reverse_data[high_pos + add][wide_pos] = w_bk_num
                    end
                else
                    r = {flg = return_flg, reverse_data = reverse_data}
                    return r
                end
            end
            break
        end
    end
    reverse_count = 0
    --上
    for i = high_pos - 1, 1, -1 do
        --上が何もない
        if board_pos[i][wide_pos] == 0 then
            break
        elseif board_pos[i][wide_pos] ~= w_bk_num then
            reverse_count = reverse_count + 1
        else
            --挟めているので
            if reverse_count > 0 then
                return_flg = true
                if put_flg then
                    --ひっくり返すやつ
                    for add = 1, reverse_count do
                        reverse_data[high_pos - add][wide_pos] = w_bk_num
                    end
                else
                    r = {flg = return_flg, reverse_data = reverse_data}
                    return r
                end
            end
            break
        end
    end

    reverse_count = 0
    --右下
    for i = 1, #board_pos[1] do
        --どっちかが限界
        if high_pos + i >= #board_pos[1] or wide_pos + i >= #board_pos[1] then
            break
        end
        --何もない
        if board_pos[high_pos + i][wide_pos + i] == 0 then
            break
        elseif board_pos[high_pos + i][wide_pos + i] ~= w_bk_num then
            --相手の色
            reverse_count = reverse_count + 1
        else
            --挟めているので
            if reverse_count > 0 then
                return_flg = true
                if put_flg then
                    --ひっくり返すやつ
                    for add = 1, reverse_count do
                        reverse_data[high_pos + add][wide_pos + add] = w_bk_num
                    end
                else
                    r = {flg = return_flg, reverse_data = reverse_data}
                    return r
                end
            end
            break
        end
    end
    reverse_count = 0
    --左上
    for i = 1, #board_pos[1] do
        --どっちかが限界
        if high_pos - i < 1 or wide_pos - i < 1 then
            break
        end
        --何もない
        if board_pos[high_pos - i][wide_pos - i] == 0 then
            break
        elseif board_pos[high_pos - i][wide_pos - i] ~= w_bk_num then
            --相手の色
            reverse_count = reverse_count + 1
        else
            --挟めているので
            if reverse_count > 0 then
                return_flg = true
                if put_flg then
                    --ひっくり返すやつ
                    for add = 1, reverse_count do
                        reverse_data[high_pos - add][wide_pos - add] = w_bk_num
                    end
                else
                    r = {flg = return_flg, reverse_data = reverse_data}
                    return r
                end
            end
            break
        end
    end

    reverse_count = 0
    --右下
    for i = 1, #board_pos[1] do
        --どっちかが限界
        if high_pos + i > #board_pos[1] or wide_pos - i < 1 then
            break
        end
        --何もない
        if board_pos[high_pos + i][wide_pos - i] == 0 then
            break
        elseif board_pos[high_pos + i][wide_pos - i] ~= w_bk_num then
            --相手の色
            reverse_count = reverse_count + 1
        else
            --挟めているので
            if reverse_count > 0 then
                return_flg = true
                if put_flg then
                    --ひっくり返すやつ
                    for add = 1, reverse_count do
                        reverse_data[high_pos + add][wide_pos - add] = w_bk_num
                    end
                else
                    r = {flg = return_flg, reverse_data = reverse_data}
                    return r
                end
            end
            break
        end
    end
    reverse_count = 0
    --左下
    for i = 1, #board_pos[1] do
        --どっちかが限界
        if high_pos - i < 1 or wide_pos + i > #board_pos[1] then
            break
        end
        --何もない
        if board_pos[high_pos - i][wide_pos + i] == 0 then
            break
        elseif board_pos[high_pos - i][wide_pos + i] ~= w_bk_num then
            --相手の色
            reverse_count = reverse_count + 1
        else
            --挟めているので
            if reverse_count > 0 then
                return_flg = true
                if put_flg then
                    --ひっくり返すやつ
                    for add = 1, reverse_count do
                        reverse_data[high_pos - add][wide_pos + add] = w_bk_num
                    end
                else
                    r = {flg = return_flg, reverse_data = reverse_data}
                    return r
                end
            end
            break
        end
    end

    r = {flg = return_flg, reverse_data = reverse_data}
    return r
end

function PudBoard()
    --基準の盤
    local board_si = REVERSI_DATA.str_si[REVERSI_DATA.str_board_num]
    local board_si_pos = board_si.GetLocalPosition()
    --盤面の位置駒(配列)
    local board_pos = REVERSI_MOVE.piece_put_w_bk
    --握ってるやつとの位置計算
    --握ってる番号
    local grip_num = -1
    --駒のサブアイテム番号
    local piece_si = REVERSI_DATA.str_piece_si
    --1マスの大きさ
    local split_scale = REVERSI_DATA.split_scale
    --配置高さ
    local piece_hight = REVERSI_DATA.piece_hight
    --合算する角度
    local add_ang = Vector3.__new(0, 0, 0)
    --縦の位置
    for high_pos = 1, #board_pos do
        --横の位置
        for wide_pos = 1, #board_pos[high_pos] do
            --黒なら反転
            if board_pos[high_pos][wide_pos] == REVERSI_DATA.bk_num then
                add_ang.x = 180
                local ang = board_si.GetLocalRotation().eulerAngles
                add_ang.z = -ang.z * 2
            else
                add_ang = Vector3.__new(0, 0, 0)
            end

            --盤上配置処理
            BoardLayoutPut(
                board_si,
                piece_si,
                high_pos,
                wide_pos,
                board_pos,
                grip_num,
                split_scale,
                piece_hight,
                add_ang
            )
        end
    end
end

--盤面配置(1~名前が続いているサブアイテムを並べる)
function BoardLayoutPut(board_si, piece_si, hight, wideth, board_pos, grip_num, split_scale, piece_hight, add_ang)
    local board_si_pos = board_si.GetLocalPosition()
    local board_si_ang = board_si.GetLocalRotation().eulerAngles
    --盤上の駒番号取得
    local num = wideth + (hight - 1) * #board_pos[1]
    --board_pos[hight][wideth]
    --中身
    local inside = board_pos[hight][wideth]
    --縦マス数
    local board_high = #board_pos
    --横マス数
    local board_wide = #board_pos[1]
    --握ってるやつを除く
    if inside > 0 and grip_num ~= num then
        --駒配置
        local piece = piece_si[num]
        if piece.IsMine then
            --配置位置
            local x = (hight - math.ceil(board_high / 2) - 0.5) * split_scale
            local z = (wideth - math.ceil(board_wide / 2) - 0.5) * split_scale
            --盤の中心から指定位置に置く
            local sub_pos = board_si_pos + RelativeToLocalCoordinates(board_si, x, piece_hight, z)
            piece.SetLocalPosition(sub_pos)
            --角度計算
            board_si_ang = board_si_ang + add_ang
            Rot_LocalQuat_Euler(piece, board_si_ang.x, board_si_ang.y, board_si_ang.z)
        end
    else
        local piece = piece_si[num]
        if piece.IsMine then
            --配置位置
            local x = 0
            local z = 0
            --盤の中心から指定位置に置く
            local sub_pos = board_si_pos + RelativeToLocalCoordinates(board_si, x, -10000000, z)
            piece.SetLocalPosition(sub_pos)
        end
    end
end

--ディープに移る駒数
local change_deep_count = 8 * 8 - 20
--cpuメイン処理
function AllCPUMain(board_pos, w_bk_num)
    local stone_count = 0
    --縦の位置
    for high_pos = 1, #board_pos do
        --横の位置
        for wide_pos = 1, #board_pos[high_pos] do
            if board_pos[high_pos][wide_pos] ~= 0 then
                stone_count = stone_count + 1
            end
        end
    end
    if stone_count == 64 then
        nil_wait_timer = os.clock()
        normal_flg = false
        deep_flg = false
        return
    end

    if stone_count > change_deep_count then
        deep_flg = true
        normal_flg = false
    else
        normal_flg = true
        deep_flg = false
    end
end

vci.StartCoroutine(
    coroutine.create(
        function()
            while true do
                if deep_flg then
                    STATE.Set("FIRST", false)
                    --cpuディープコルーチン処理
                    REVERSI_MOVE.est_time2 = os.clock()

                    DeepCPUCoroutine(REVERSI_MOVE.piece_put_w_bk, REVERSI_MOVE.w_bk_mode)
                    deep_flg = false
                    normal_flg = false
                    REVERSI_MOVE.turn_num = REVERSI_MOVE.w_bk_mode % 2 + 1
                    STATE.Set("TURN", REVERSI_MOVE.turn_num)
                    STATE.Set("RETURN", REVERSI_MOVE.turn_num)
                    REVERSI_MOVE.turn_num = REVERSI_MOVE.w_bk_mode % 2 + 1
                    STATE.Set("FIRST", true)
                    vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
                end
                if normal_flg then
                    STATE.Set("FIRST", false)
                    --cpuノーマルコルーチン処理
                    REVERSI_MOVE.est_time = os.clock()
                    NormalCPUCoroutine(REVERSI_MOVE.piece_put_w_bk, REVERSI_MOVE.w_bk_mode)
                    normal_flg = false
                    deep_flg = false
                    REVERSI_MOVE.turn_num = REVERSI_MOVE.w_bk_mode % 2 + 1
                    STATE.Set("TURN", REVERSI_MOVE.turn_num)
                    STATE.Set("RETURN", REVERSI_MOVE.turn_num)
                    REVERSI_MOVE.turn_num = REVERSI_MOVE.w_bk_mode % 2 + 1
                    STATE.Set("FIRST", true)
                    vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
                end
                coroutine.yield()
            end
        end
    )
)

local cpu_count = 0
--cpuノーマルコルーチン処理
function NormalCPUCoroutine(board_pos, w_bk_num)
    cpu_count = 0
    local put_permission_count = 0
    local put_permission_high = {}
    local put_permission_wide = {}
    --縦の位置
    for high_pos = 1, #board_pos do
        --横の位置
        for wide_pos = 1, #board_pos[high_pos] do
            --置くことのできる箇所か把握
            local return_data = PermissionPut(false, board_pos, high_pos, wide_pos, w_bk_num)

            if return_data.flg then
                put_permission_count = put_permission_count + 1
                put_permission_high[put_permission_count] = high_pos
                put_permission_wide[put_permission_count] = wide_pos
            end
        end
    end

    local min = 10000000000
    local max = -10000000000
    local put_num_high = 0
    local put_num_wide = 0
    for deep = 1, 64 do
        if (os.clock() - REVERSI_MOVE.est_time) > REVERSI_DATA.time_span then
            STATE.Set("deep", deep)
            break
        end
        for i = 1, put_permission_count do
            if (os.clock() - REVERSI_MOVE.est_time) > REVERSI_DATA.time_span then
                STATE.Set("deep", deep)
                break
            end
            local data =
                CPUNormalFunc(board_pos, -max, -min, w_bk_num, put_permission_high[i], put_permission_wide[i], deep, 1)

            if data > max then
                max = data
                put_num_high = put_permission_high[i]
                put_num_wide = put_permission_wide[i]
            end
        end
        coroutine.yield()
    end
    STATE.Set("count", cpu_count)
    STATE.Set("MODE", "normal")
    if put_num_high ~= 0 then
        local reverse = PermissionPut(true, board_pos, put_num_high, put_num_wide, w_bk_num)
        --リバース反映
        ReversePut(reverse.reverse_data, board_pos, put_num_high, put_num_wide, w_bk_num)
    end
    if NOT_DEBUG then
        --縦
        for high = 1, REVERSI_DATA.str_board_piece_num do
            --横
            for wide = 1, REVERSI_DATA.str_board_piece_num do
                --アイテム場所
                local num = wide + (high - 1) * REVERSI_DATA.str_board_piece_num
                if NOT_DEBUG then
                    STATE.Set(
                        REVERSI_DATA.str[REVERSI_DATA.str_board_piece_num] .. tostring(num),
                        board_pos[high][wide]
                    )
                end
            end
        end
    end
end

--cpuノーマルコルーチン処理
function DeepCPUCoroutine(board_pos, w_bk_num)
    cpu_count = 0
    local put_permission_count = 0
    local put_permission_high = {}
    local put_permission_wide = {}
    local deep_max = 0
    --縦の位置
    for high_pos = 1, #board_pos do
        --横の位置
        for wide_pos = 1, #board_pos[high_pos] do
            --置くことのできる箇所か把握
            local return_data = PermissionPut(false, board_pos, high_pos, wide_pos, w_bk_num)

            if return_data.flg then
                put_permission_count = put_permission_count + 1
                put_permission_high[put_permission_count] = high_pos
                put_permission_wide[put_permission_count] = wide_pos
            end
            if board_pos[high_pos][wide_pos] == 0 then
                deep_max = deep_max + 1
            end
        end
    end

    local min = 10000000000
    local max = -10000000000
    local put_num_high = 0
    local put_num_wide = 0
    for deep = 1, deep_max do
        if (os.clock() - REVERSI_MOVE.est_time2) > REVERSI_DATA.time_span2 then
            STATE.Set("deep", deep)
            break
        end
        for i = 1, put_permission_count do
            if (os.clock() - REVERSI_MOVE.est_time2) > REVERSI_DATA.time_span2 then
                STATE.Set("deep", deep)
                break
            end
            local data =
                CPUDeepFunc(board_pos, -max, -min, w_bk_num, put_permission_high[i], put_permission_wide[i], deep, 1)

            if data > max then
                max = data
                put_num_high = put_permission_high[i]
                put_num_wide = put_permission_wide[i]
            end
        end
        coroutine.yield()
    end
    STATE.Set("count", cpu_count)
    STATE.Set("MODE", "deep")
    if put_num_high ~= 0 then
        local reverse = PermissionPut(true, board_pos, put_num_high, put_num_wide, w_bk_num)
        --リバース反映
        ReversePut(reverse.reverse_data, board_pos, put_num_high, put_num_wide, w_bk_num)
    end
    if NOT_DEBUG then
        --縦
        for high = 1, REVERSI_DATA.str_board_piece_num do
            --横
            for wide = 1, REVERSI_DATA.str_board_piece_num do
                --アイテム場所
                local num = wide + (high - 1) * REVERSI_DATA.str_board_piece_num
                if NOT_DEBUG then
                    STATE.Set(
                        REVERSI_DATA.str[REVERSI_DATA.str_board_piece_num] .. tostring(num),
                        board_pos[high][wide]
                    )
                end
            end
        end
    end
end

local count_timer = os.clock()
local count_timer_count = 1 / 15
--盤面、最大、最小、1:white,2:black、深さ、
function CPUNormalFunc(board_pos, max, min, w_bk_num, high, wide, fn_deep_count, nil_data)
    if (os.clock() - count_timer) > count_timer_count then
        count_timer = os.clock()
        coroutine.yield()
    end
    --配列生成
    local now_board_pos = TableCreate(board_pos)

    --探索終了
    if fn_deep_count <= 1 then
        if nil_data == 0 then
            local count_num = 0
            --縦の位置
            for high_pos = 1, #board_pos do
                --横の位置
                for wide_pos = 1, #board_pos[high_pos] do
                    if board_pos[high_pos][wide_pos] == w_bk_num then
                        count_num = count_num + 1
                    elseif board_pos[high_pos][wide_pos] ~= 0 then
                        count_num = count_num - 1
                    end
                end
            end
            cpu_count = cpu_count + 1
            return count_num * 1000000
        end
        return NormalEvaluate(board_pos, high, wide, w_bk_num)
    end

    if (os.clock() - REVERSI_MOVE.est_time) > REVERSI_DATA.time_span then
        return max
    end

    --飛ばされた
    if nil_data ~= 0 then
        local reverse = PermissionPut(true, now_board_pos, high, wide, w_bk_num).reverse_data
        --リバース反映
        ReversePut(reverse, now_board_pos, high, wide, w_bk_num)
    end
    local put_permission_count = 0
    local put_permission_high = {}
    local put_permission_wide = {}
    local put_count = 0
    --縦の位置
    for high_pos = 1, #now_board_pos do
        --横の位置
        for wide_pos = 1, #now_board_pos[high_pos] do
            if now_board_pos[high_pos][wide_pos] ~= 0 then
                put_count = put_count + 1
            end
            --置くことのできる箇所か把握
            local return_data = PermissionPut(false, now_board_pos, high_pos, wide_pos, w_bk_num % 2 + 1)
            if return_data.flg then
                put_permission_count = put_permission_count + 1
                put_permission_high[put_permission_count] = high_pos
                put_permission_wide[put_permission_count] = wide_pos
            end
        end
    end
    --置けない
    if put_count == 64 then
        return NormalEvaluate(board_pos, high, wide, w_bk_num)
    end
    --置く場所がない
    if put_permission_count == 0 then
        if (os.clock() - REVERSI_MOVE.est_time) > REVERSI_DATA.time_span then
            return max
        end
        local data = -CPUNormalFunc(now_board_pos, -min, -max, w_bk_num % 2 + 1, 0, 0, fn_deep_count - 1, 0)

        if data > max then
            max = data
            if max >= min then
                return max
            end
        end
    end

    for i = 1, put_permission_count do
        if (os.clock() - REVERSI_MOVE.est_time) > REVERSI_DATA.time_span then
            return max
        end
        local data =
            -CPUNormalFunc(
            now_board_pos,
            -min,
            -max,
            w_bk_num % 2 + 1,
            put_permission_high[i],
            put_permission_wide[i],
            fn_deep_count - 1,
            put_permission_count
        )

        if data > max then
            max = data
            if max >= min then
                return max
            end
        end
    end

    return max
end

function NormalEvaluate(board_pos, high, wide, w_bk_num)
    --配列生成
    local now_board_pos = TableCreate(board_pos)
    local reverse = PermissionPut(true, now_board_pos, high, wide, w_bk_num).reverse_data
    --リバース反映
    ReversePut(reverse, now_board_pos, high, wide, w_bk_num)

    local count_num = 0
    --縦の位置
    for high_pos = 1, #board_pos do
        --横の位置
        for wide_pos = 1, #board_pos[high_pos] do
            if now_board_pos[high_pos][wide_pos] == w_bk_num then
                count_num = count_num + 1
            elseif board_pos[high_pos][wide_pos] == (w_bk_num % 2 + 1) then
                count_num = count_num - 1
            end
        end
    end

    count_num = count_num + aaa(now_board_pos, w_bk_num) -- aaa(board_pos, w_bk_num)

    cpu_count = cpu_count + 1
    return count_num
end

function aaa(board_pos, w_bk_num)
    local count_num = 0

    if board_pos[1][1] == w_bk_num then
        count_num = count_num + 100
    elseif board_pos[1][1] == (w_bk_num % 2 + 1) then
        count_num = count_num - 130
    else
        YOKOfunc1(board_pos, w_bk_num)
        TATEfunc1(board_pos, w_bk_num)
        NANAMEfunc1(board_pos, w_bk_num)

        if board_pos[1][2] == w_bk_num then
            count_num = count_num - 31
        else
            count_num = count_num + 10000
        end
        if board_pos[2][2] == w_bk_num then
            count_num = count_num - 10
        else
            count_num = count_num + 10000
        end
        if board_pos[2][1] == w_bk_num then
            count_num = count_num - 31
        else
            count_num = count_num + 10000
        end
    end
    if board_pos[8][1] == w_bk_num then
        count_num = count_num + 100
    elseif board_pos[8][1] == (w_bk_num % 2 + 1) then
        count_num = count_num - 130
    else
        YOKOfunc3(board_pos, w_bk_num)
        TATEfunc3(board_pos, w_bk_num)
        NANAMEfunc3(board_pos, w_bk_num)

        if board_pos[7][1] == w_bk_num then
            count_num = count_num - 31
        else
            count_num = count_num + 10000
        end
        if board_pos[7][2] == w_bk_num then
            count_num = count_num - 10
        else
            count_num = count_num + 10000
        end
        if board_pos[8][1] == w_bk_num then
            count_num = count_num - 31
        else
            count_num = count_num + 10000
        end
    end
    if board_pos[1][8] == w_bk_num then
        count_num = count_num + 100
    elseif board_pos[1][8] == (w_bk_num % 2 + 1) then
        count_num = count_num - 130
    else
        YOKOfunc2(board_pos, w_bk_num)
        TATEfunc2(board_pos, w_bk_num)
        NANAMEfunc2(board_pos, w_bk_num)

        if board_pos[1][7] == w_bk_num then
            count_num = count_num - 31
        else
            count_num = count_num + 10000
        end
        if board_pos[2][7] == w_bk_num then
            count_num = count_num - 10
        else
            count_num = count_num + 10000
        end
        if board_pos[2][8] == w_bk_num then
            count_num = count_num - 31
        else
            count_num = count_num + 10000
        end
    end
    if board_pos[8][8] == w_bk_num then
        count_num = count_num + 100
    elseif board_pos[8][8] == (w_bk_num % 2 + 1) then
        count_num = count_num - 130
    else
        YOKOfunc4(board_pos, w_bk_num)
        TATEfunc4(board_pos, w_bk_num)
        NANAMEfunc4(board_pos, w_bk_num)

        if board_pos[8][7] == w_bk_num then
            count_num = count_num - 31
        else
            count_num = count_num + 10000
        end
        if board_pos[7][7] == w_bk_num then
            count_num = count_num - 30
        else
            count_num = count_num + 10000
        end
        if board_pos[7][8] == w_bk_num then
            count_num = count_num - 31
        else
            count_num = count_num + 10000
        end
    end

    --角横
    if board_pos[1][3] == w_bk_num and board_pos[1][2] == w_bk_num and board_pos[1][1] == w_bk_num then
        count_num = count_num + 150
    elseif board_pos[1][3] == w_bk_num then
        count_num = count_num + 10
    end

    if board_pos[1][6] == w_bk_num and board_pos[1][7] == w_bk_num and board_pos[1][8] == w_bk_num then
        count_num = count_num + 150
    elseif board_pos[1][6] == w_bk_num then
        count_num = count_num + 1
    end

    if board_pos[8][3] == w_bk_num and board_pos[8][2] == w_bk_num and board_pos[8][1] == w_bk_num then
        count_num = count_num + 150
    elseif board_pos[8][3] == w_bk_num then
        count_num = count_num + 1
    end

    if board_pos[8][6] == w_bk_num and board_pos[8][7] == w_bk_num and board_pos[8][8] == w_bk_num then
        count_num = count_num + 150
    elseif board_pos[8][6] == w_bk_num then
        count_num = count_num + 1
    end

    --角縦
    if board_pos[3][1] == w_bk_num and board_pos[2][1] == w_bk_num and board_pos[1][1] == w_bk_num then
        count_num = count_num + 150
    elseif board_pos[3][1] == w_bk_num then
        count_num = count_num + 1
    end

    if board_pos[3][8] == w_bk_num and board_pos[2][8] == w_bk_num and board_pos[1][8] == w_bk_num then
        count_num = count_num + 150
    elseif board_pos[3][8] == w_bk_num then
        count_num = count_num + 1
    end

    if board_pos[6][1] == w_bk_num and board_pos[7][1] == w_bk_num and board_pos[8][1] == w_bk_num then
        count_num = count_num + 150
    elseif board_pos[6][1] == w_bk_num then
        count_num = count_num + 1
    end

    if board_pos[6][8] == w_bk_num and board_pos[7][8] == w_bk_num and board_pos[8][8] == w_bk_num then
        count_num = count_num + 150
    elseif board_pos[6][8] == w_bk_num then
        count_num = count_num + 1
    end

    --角ナナメ
    if board_pos[3][3] == w_bk_num and board_pos[2][2] == w_bk_num and board_pos[1][1] == w_bk_num then
        count_num = count_num + 150
    elseif board_pos[3][3] == w_bk_num then
        count_num = count_num + 1
    end

    if board_pos[3][6] == w_bk_num and board_pos[2][7] == w_bk_num and board_pos[1][8] == w_bk_num then
        count_num = count_num + 150
    elseif board_pos[3][6] == w_bk_num then
        count_num = count_num + 1
    end

    if board_pos[6][6] == w_bk_num and board_pos[7][7] == w_bk_num and board_pos[8][8] == w_bk_num then
        count_num = count_num + 150
    elseif board_pos[6][6] == w_bk_num then
        count_num = count_num + 1
    end

    if board_pos[6][3] == w_bk_num and board_pos[7][2] == w_bk_num and board_pos[8][1] == w_bk_num then
        count_num = count_num + 150
    elseif board_pos[6][2] == w_bk_num then
        count_num = count_num + 1
    end

    return count_num
end

function YOKOfunc1(board_pos, w_bk_num)
    local count_num = 0
    local flg = false
    for i = 2, 8 do
        if board_pos[1][i] == w_bk_num then
            flg = true
        elseif board_pos[1][i] ~= w_bk_num then
            if flg then
                count_num = count_num - 50
            end
            break
        end
    end

    return count_num
end
function YOKOfunc2(board_pos, w_bk_num)
    local count_num = 0
    local flg = false
    for i = 7, 1, -1 do
        if board_pos[1][i] == w_bk_num then
            flg = true
        elseif board_pos[1][i] ~= w_bk_num then
            if flg then
                count_num = count_num - 50
            else
                count_num = count_num + 3
            end
            break
        end
    end

    return count_num
end
function YOKOfunc3(board_pos, w_bk_num)
    local count_num = 0
    local flg = false
    for i = 2, 8 do
        if board_pos[8][i] == w_bk_num then
            flg = true
        elseif board_pos[8][i] ~= w_bk_num then
            if flg then
                count_num = count_num - 50
            else
                count_num = count_num + 3
            end
        end
    end

    return count_num
end
function YOKOfunc4(board_pos, w_bk_num)
    local count_num = 0
    local flg = false
    for i = 7, 1, -1 do
        if board_pos[8][i] == w_bk_num then
            flg = true
        elseif board_pos[8][i] ~= w_bk_num then
            if flg then
                count_num = count_num - 50
            else
                count_num = count_num + 3
            end
        end
    end

    return count_num
end

function TATEfunc1(board_pos, w_bk_num)
    local count_num = 0
    local flg = false
    for i = 2, 8 do
        if board_pos[i][1] == w_bk_num then
            flg = true
        elseif board_pos[i][1] ~= w_bk_num then
            if flg then
                count_num = count_num - 50
            else
                count_num = count_num + 3
            end
        end
    end

    return count_num
end
function TATEfunc2(board_pos, w_bk_num)
    local count_num = 0
    local flg = false
    for i = 2, 8 do
        if board_pos[i][8] == w_bk_num then
            flg = true
        elseif board_pos[i][8] ~= w_bk_num then
            if flg then
                count_num = count_num - 50
            else
                count_num = count_num + 3
            end
        end
    end

    return count_num
end
function TATEfunc3(board_pos, w_bk_num)
    local count_num = 0
    local flg = false
    for i = 7, 1, -1 do
        if board_pos[i][1] == w_bk_num then
            flg = true
        elseif board_pos[i][1] ~= w_bk_num then
            if flg then
                count_num = count_num - 50
            else
                count_num = count_num + 3
            end
        end
    end

    return count_num
end
function TATEfunc4(board_pos, w_bk_num)
    local count_num = 0
    local flg = false
    for i = 7, 1, -1 do
        if board_pos[i][8] == w_bk_num then
            flg = true
        elseif board_pos[i][8] ~= w_bk_num then
            if flg then
                count_num = count_num - 50
            else
                count_num = count_num + 3
            end
        end
    end

    return count_num
end

function NANAMEfunc1(board_pos, w_bk_num)
    local count_num = 0
    local flg = false
    for i = 2, 8 do
        if board_pos[i][i] == w_bk_num then
            flg = true
        elseif board_pos[i][i] ~= w_bk_num then
            if flg then
                count_num = count_num - 50
            else
                count_num = count_num + 3
            end
        end
    end

    return count_num
end
function NANAMEfunc2(board_pos, w_bk_num)
    local count_num = 0
    local flg = false
    for i = 2, 8 do
        if board_pos[i][9 - i] == w_bk_num then
            flg = true
        elseif board_pos[i][9 - i] ~= w_bk_num then
            if flg then
                count_num = count_num - 50
            else
                count_num = count_num + 3
            end
        end
    end

    return count_num
end
function NANAMEfunc3(board_pos, w_bk_num)
    local count_num = 0
    local flg = false
    for i = 7, 1, -1 do
        if board_pos[i][9 - i] == w_bk_num then
            flg = true
        elseif board_pos[i][9 - i] ~= w_bk_num then
            if flg then
                count_num = count_num - 50
            else
                count_num = count_num + 3
            end
        end
    end

    return count_num
end
function NANAMEfunc4(board_pos, w_bk_num)
    local count_num = 0
    local flg = false
    for i = 7, 1, -1 do
        if board_pos[i][i] == w_bk_num then
            flg = true
        elseif board_pos[i][i] ~= w_bk_num then
            if flg then
                count_num = count_num - 50
            else
                count_num = count_num + 3
            end
        end
    end

    return count_num
end

--盤面、最大、最小、1:white,2:black、深さ、
function CPUDeepFunc(board_pos, max, min, w_bk_num, high, wide, fn_deep_count, nil_data)
    if (os.clock() - count_timer) > count_timer_count then
        count_timer = os.clock()
        coroutine.yield()
    end
    --配列生成
    local now_board_pos = TableCreate(board_pos)

    --探索終了
    if fn_deep_count <= 1 then
        if nil_data == 0 then
            local count_num = 0
            --縦の位置
            for high_pos = 1, #board_pos do
                --横の位置
                for wide_pos = 1, #board_pos[high_pos] do
                    if board_pos[high_pos][wide_pos] == w_bk_num then
                        count_num = count_num + 1
                    elseif board_pos[high_pos][wide_pos] ~= 0 then
                        count_num = count_num - 1
                    end
                end
            end
            cpu_count = cpu_count + 1
            return count_num * 1000000
        end
        return DeepEvaluate(board_pos, high, wide, w_bk_num)
    end

    if (os.clock() - REVERSI_MOVE.est_time2) > REVERSI_DATA.time_span2 then
        return max
    end

    --飛ばされた
    if nil_data ~= 0 then
        local reverse = PermissionPut(true, now_board_pos, high, wide, w_bk_num).reverse_data
        --リバース反映
        ReversePut(reverse, now_board_pos, high, wide, w_bk_num)
    end
    local put_permission_count = 0
    local put_permission_high = {}
    local put_permission_wide = {}
    local put_count = 0
    --縦の位置
    for high_pos = 1, #now_board_pos do
        --横の位置
        for wide_pos = 1, #now_board_pos[high_pos] do
            if now_board_pos[high_pos][wide_pos] ~= 0 then
                put_count = put_count + 1
            end
            --置くことのできる箇所か把握
            local return_data = PermissionPut(false, now_board_pos, high_pos, wide_pos, w_bk_num % 2 + 1)
            if return_data.flg then
                put_permission_count = put_permission_count + 1
                put_permission_high[put_permission_count] = high_pos
                put_permission_wide[put_permission_count] = wide_pos
            end
        end
    end
    --置けない
    if put_count == 64 then
        return DeepEvaluate(board_pos, high, wide, w_bk_num)
    end
    --置く場所がない
    if put_permission_count == 0 then
        if (os.clock() - REVERSI_MOVE.est_time2) > REVERSI_DATA.time_span2 then
        --return max
        end
        local data = -CPUDeepFunc(now_board_pos, -min, -max, w_bk_num % 2 + 1, 0, 0, fn_deep_count - 1, 0)

        if data > max then
            max = data
            if max >= min then
                return max
            end
        end
    end

    for i = 1, put_permission_count do
        if (os.clock() - REVERSI_MOVE.est_time2) > REVERSI_DATA.time_span2 then
            return max
        end
        local data =
            -CPUDeepFunc(
            now_board_pos,
            -min,
            -max,
            w_bk_num % 2 + 1,
            put_permission_high[i],
            put_permission_wide[i],
            fn_deep_count - 1,
            put_permission_count
        )

        if data > max then
            max = data
            if max >= min then
                return max
            end
        end
    end

    return max
end

function DeepEvaluate(board_pos, high, wide, w_bk_num)
    --配列生成
    local now_board_pos = TableCreate(board_pos)
    local reverse = PermissionPut(true, now_board_pos, high, wide, w_bk_num).reverse_data
    --リバース反映
    ReversePut(reverse, now_board_pos, high, wide, w_bk_num)

    local count_num = 0
    --縦の位置
    for high_pos = 1, #board_pos do
        --横の位置
        for wide_pos = 1, #board_pos[high_pos] do
            if now_board_pos[high_pos][wide_pos] == w_bk_num then
                count_num = count_num + 1
            elseif board_pos[high_pos][wide_pos] == (w_bk_num % 2 + 1) then
                count_num = count_num - 1
            end
        end
    end

    if now_board_pos[1][1] == w_bk_num then
        count_num = count_num + 100
    elseif now_board_pos[1][1] == (w_bk_num % 2 + 1) then
        count_num = count_num - 200
    end
    if now_board_pos[8][1] == w_bk_num then
        count_num = count_num + 100
    elseif now_board_pos[8][1] == (w_bk_num % 2 + 1) then
        count_num = count_num - 200
    end
    if now_board_pos[1][8] == w_bk_num then
        count_num = count_num + 100
    elseif now_board_pos[1][8] == (w_bk_num % 2 + 1) then
        count_num = count_num - 200
    end
    if now_board_pos[8][8] == w_bk_num then
        count_num = count_num + 100
    elseif now_board_pos[8][8] == (w_bk_num % 2 + 1) then
        count_num = count_num - 200
    end

    cpu_count = cpu_count + 1
    return count_num
end

--ボードのステート処理
function BoardStateSet()
    permission_first = STATE.Get("FIRST")

    if NOT_DEBUG then
        REVERSI_MOVE.piece_put_w_bk = {}
        --縦
        for high = 1, REVERSI_DATA.str_board_piece_num do
            REVERSI_MOVE.piece_put_w_bk[high] = {}
            --横
            for wide = 1, REVERSI_DATA.str_board_piece_num do
                --アイテム場所
                local num = wide + (high - 1) * REVERSI_DATA.str_board_piece_num
                REVERSI_MOVE.piece_put_w_bk[high][wide] =
                    STATE.Get(REVERSI_DATA.str[REVERSI_DATA.str_board_piece_num] .. tostring(num))
            end
        end

        REVERSI_MOVE.turn_num = STATE.Get("TURN")
        REVERSI_MOVE.cpu_mode = STATE.Get("CPU")
        if REVERSI_MOVE.cpu_mode then
            ASSET.SetMaterialColorFromName(REVERSI_DATA.str_material[REVERSI_DATA.str_cpu_num], WHITE)
        else
            ASSET.SetMaterialColorFromName(REVERSI_DATA.str_material[REVERSI_DATA.str_cpu_num], BLACK)
        end
        REVERSI_MOVE.permission = STATE.Get("PERMISSION")
        if REVERSI_MOVE.permission then
            ASSET.SetMaterialColorFromName(REVERSI_DATA.str_material[REVERSI_DATA.str_permission_num], WHITE)
        else
            ASSET.SetMaterialColorFromName(REVERSI_DATA.str_material[REVERSI_DATA.str_permission_num], BLACK)
        end
        REVERSI_MOVE.w_bk_mode = STATE.Get("W_BK")
        if REVERSI_MOVE.w_bk_mode == REVERSI_DATA.w_num then
            ASSET.SetMaterialColorFromName(REVERSI_DATA.str_material[REVERSI_DATA.str_w_bk_num], WHITE)
        else
            ASSET.SetMaterialColorFromName(REVERSI_DATA.str_material[REVERSI_DATA.str_w_bk_num], BLACK)
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

--ボードの初期化メッセージ
function BoardNillMess(sender, name, message)
    nil_wait_timer = os.clock()
end
vci.message.On(ASHU_MESS .. "BOARD_NILL", BoardNillMess)

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

--subitemをEuler角の値に変更
function Rot_LocalQuat_Euler(subitem, x, y, z)
    subitem.SetLocalRotation(Quaternion.Euler(x, y, z))
end

--石置けないとき反転
function StoneChange(board_pos, w_bk_num)
    local data = 0
    --縦の位置
    for high_pos = 1, #board_pos do
        --横の位置
        for wide_pos = 1, #board_pos[1] do
            --置くことのできる箇所か把握
            local return_data = PermissionPut(false, board_pos, high_pos, wide_pos, w_bk_num)
            if return_data.flg then
                data = data + 1
            end
        end
    end
    if data > 0 then
        local r = {flg = false, count = data}
        return r
    else
        local r = {flg = true, count = data}
        return r
    end
end

function TableCreate(table_data)
    local new = {}
    for i = 1, #table_data do
        new[i] = {}
        for i2 = 1, #table_data[i] do
            new[i][i2] = table_data[i][i2]
        end
    end
    return new
end
