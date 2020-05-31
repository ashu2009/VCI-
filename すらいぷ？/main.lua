--簡略化
local STATE = vci.state
local ASSET = vci.assets
local ASHU_MESS = "ASHU_SLIPE_MESS_"
local NOT_DEBUG = true

local SLIPE_DATA = {
    --基礎アイテム名
    str = {"board", "piece", "Text", "First"},
    --盤
    str_board_num = 1,
    str_board_si = {},
    --駒
    str_piece_num = 2,
    str_piece_si = {},
    --取得距離
    dist = 0.4,
    --黒番号
    piece_bk = 1,
    --白番号
    piece_w = 2,
    --縦/横
    piece_split = 5,
    --スケール
    split_scale = 0.18,
    --盤からの高さ
    piece_hight = 0.11,
    --文字としての駒最大数
    str_piece_max = 12,
    --駒最大数
    piece_max = 10,
    --文字列
    str_text_num = 3,
    str_text_si = {},
    str_text_pos = Vector3.__new(0, 0.4, 0),
    --初期化
    str_first_num = 4,
    str_first_si = {}
}
local SLIPE_MOVE = {
    --駒の位置
    board_pos = nil,
    --手番
    turn_num = nil,
    --勝敗
    victory_num = 0
}

for i = 1, #SLIPE_DATA.str do
    --盤
    if i == SLIPE_DATA.str_board_num then
        SLIPE_DATA.str_board_si[1] = ASSET.GetSubItem(SLIPE_DATA.str[1])
    elseif i == SLIPE_DATA.str_piece_num then
        --駒
        for i2 = 1, SLIPE_DATA.str_piece_max do
            SLIPE_DATA.str_piece_si[i2] = ASSET.GetSubItem(SLIPE_DATA.str[SLIPE_DATA.str_piece_num] .. tostring(i2))
        end
    elseif i == SLIPE_DATA.str_text_num then
        --文字列
        SLIPE_DATA.str_text_si[1] = ASSET.GetSubItem(SLIPE_DATA.str[SLIPE_DATA.str_text_num])
    elseif i == SLIPE_DATA.str_first_num then
        --初期化
        SLIPE_DATA.str_first_si[1] = ASSET.GetSubItem(SLIPE_DATA.str[SLIPE_DATA.str_first_num])
    end
end

--メイン時間
local m_timer = 0
--時間間隔
local m_timer_cnt = 1 / 20
--初期化フラグ

local first_flg = true
local turn_ang = 0
function update()
    --時間管理
    if TimeManage(m_timer, m_timer_cnt) then
        if first_flg then
            --初期化
            FirstDataSet()
            first_flg = false
        end

        --基準の盤
        local board_si = SLIPE_DATA.str_board_si[1]
        --盤面の位置駒(配列)
        local board_si_pos = board_si.GetLocalPosition()
        --勝敗文字表示
        if SLIPE_MOVE.victory_num == 0 then
            ASSET._ALL_SetText(SLIPE_DATA.str[SLIPE_DATA.str_text_num], "")
        elseif SLIPE_MOVE.victory_num == SLIPE_DATA.piece_bk then
            ASSET._ALL_SetText(SLIPE_DATA.str[SLIPE_DATA.str_text_num], "黒の勝ち")
        elseif SLIPE_MOVE.victory_num == SLIPE_DATA.piece_w then
            ASSET._ALL_SetText(SLIPE_DATA.str[SLIPE_DATA.str_text_num], "白の勝ち")
        end
        local text_si = SLIPE_DATA.str_text_si[1]
        text_si.SetLocalPosition(board_si_pos + SLIPE_DATA.str_text_pos)
        Rot_LocalQuat_Euler(text_si, 0, turn_ang, 0)
        turn_ang = turn_ang + 1
    end
end

--時間処理
local timer = os.clock()
local timer_count = 1 / 15
--握ってる番号
local l_grip_num = 0
--nilにするタイマー
local nil_wait_timer = -1
--nilにする時間
local nil_wait_timer_count = 1 / 3
function updateAll()
    --時間管理
    if TimeManage(timer, timer_count) then
        if NOT_DEBUG then
            if nil_wait_timer ~= 0 and (os.clock() - nil_wait_timer) > nil_wait_timer_count then
                BoardNillSet()
                --2度はいらない
                nil_wait_timer = 0
            end
        end

        --盤面の位置駒(配列)
        local board_pos = SLIPE_MOVE.board_pos
        --nilならば読み込み
        if board_pos == nil or SLIPE_MOVE.turn_num == nil then
            --ステート処理
            BoardStateSet()
        else
            --全員用
            AllMain()
        end
    end
end

--ろーかるの掴んだ番号記録
function onGrab(target)
    --駒検索
    for i = 1, #SLIPE_DATA.str_piece_si do
        if target == SLIPE_DATA.str_piece_si[i].GetName() then
            --握った番号保持
            l_grip_num = i
        end
    end
end

--握った番号初期化
function onUngrab(target)
    --駒検索
    for i = 1, #SLIPE_DATA.str_piece_si do
        if target == SLIPE_DATA.str_piece_si[i].GetName() then
            --握った初期化
            l_grip_num = 0
        end
    end
end

--use処理
local l_use_flg = false
function onUse(use)
    --useが通る条件
    if l_grip_num > 0 then
        if nil_wait_timer == 0 and use == SLIPE_DATA.str_piece_si[l_grip_num].GetName() then
            if SLIPE_MOVE.turn_num == 0 then
                l_use_flg = true
            elseif SLIPE_MOVE.turn_num == SLIPE_DATA.piece_bk and l_grip_num <= SLIPE_DATA.piece_split then
                l_use_flg = true
            elseif SLIPE_MOVE.turn_num == SLIPE_DATA.piece_w and l_grip_num > SLIPE_DATA.piece_split then
                l_use_flg = true
            end
        end
    end

    --初期化
    if use == SLIPE_DATA.str[SLIPE_DATA.str_first_num] then
        FirstDataSet()
    end
end

--初期化セット
function FirstDataSet()
    --駒初期配置
    SLIPE_MOVE.board_pos = {}
    --縦
    for high = 1, SLIPE_DATA.piece_split do
        SLIPE_MOVE.board_pos[high] = {}
        --横
        for wide = 1, SLIPE_DATA.piece_split do
            --無し
            SLIPE_MOVE.board_pos[high][wide] = 0
            --黒
            if high == 1 then
                SLIPE_MOVE.board_pos[high][wide] = wide
                if NOT_DEBUG then
                    STATE.Set(
                        SLIPE_DATA.str[SLIPE_DATA.str_piece_num] .. tostring(wide + (high - 1) * SLIPE_DATA.piece_split),
                        wide
                    )
                end
            elseif high == SLIPE_DATA.piece_split then
                --白
                SLIPE_MOVE.board_pos[high][wide] = SLIPE_DATA.piece_split + wide

                if NOT_DEBUG then
                    STATE.Set(
                        SLIPE_DATA.str[SLIPE_DATA.str_piece_num] .. tostring(wide + (high - 1) * SLIPE_DATA.piece_split),
                        wide + SLIPE_DATA.piece_split
                    )
                end
            else
                if NOT_DEBUG then
                    STATE.Set(
                        SLIPE_DATA.str[SLIPE_DATA.str_piece_num] .. tostring(wide + (high - 1) * SLIPE_DATA.piece_split),
                        0
                    )
                end
            end
        end
    end
    --勝敗
    SLIPE_MOVE.victory_num = 0

    if NOT_DEBUG then
        STATE.Set("Victory", SLIPE_MOVE.victory_num)
    end
    --手番制御
    SLIPE_MOVE.turn_num = 0

    if NOT_DEBUG then
        STATE.Set(SLIPE_DATA.str[SLIPE_DATA.str_board_num], SLIPE_MOVE.turn_num)
        vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
    end
end

--盤面配置(1~名前が続いているサブアイテムを並べる)
function BoardLayoutPut(board_si, piece_si, hight, wideth, board_pos, grip_num, split_scale, piece_hight, add_ang)
    local board_si_pos = board_si.GetLocalPosition()
    local board_si_ang = board_si.GetLocalRotation().eulerAngles
    --盤上の駒番号取得
    local num = board_pos[hight][wideth]
    --縦マス数
    local board_high = #board_pos
    --横マス数
    local board_wide = #board_pos[1]
    --握ってるやつを除く
    if num > 0 and grip_num ~= num then
        --駒配置
        local piece = piece_si[num]
        if piece.IsMine then
            --配置位置
            local x = (hight - math.ceil(board_high / 2)) * split_scale
            local z = (wideth - math.ceil(board_wide / 2)) * split_scale
            --盤の中心から指定位置に置く
            local sub_pos = board_si_pos + RelativeToLocalCoordinates(board_si, x, piece_hight, z)
            piece.SetLocalPosition(sub_pos)
            --角度計算
            board_si_ang = board_si_ang + add_ang
            Rot_LocalQuat_Euler(piece, board_si_ang.x, board_si_ang.y, board_si_ang.z)
        end
    end
end

--全員用
function AllMain()
    --基準の盤
    local board_si = SLIPE_DATA.str_board_si[1]
    local board_si_pos = board_si.GetLocalPosition()
    --盤面の位置駒(配列)
    local board_pos = SLIPE_MOVE.board_pos
    --握ってるやつとの位置計算
    --握ってる番号
    local grip_num = l_grip_num
    --駒のサブアイテム番号
    local piece_si = SLIPE_DATA.str_piece_si
    --1マスの大きさ
    local split_scale = SLIPE_DATA.split_scale
    --配置高さ
    local piece_hight = SLIPE_DATA.piece_hight
    --合算する角度
    local add_ang = Vector3.__new(0, 0, 0)
    --縦の位置
    for high_pos = 1, #board_pos do
        --横の位置
        for wide_pos = 1, #board_pos[high_pos] do
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
    local auxiliary_num = 0
    --握っているものがある
    if grip_num > 0 then
        if SLIPE_MOVE.turn_num == 0 then
            --何処に配置するか計算
            auxiliary_num =
                PutLayout(board_pos, grip_num, board_si_pos, auxiliary_num, board_si, split_scale, piece_hight)
        elseif SLIPE_MOVE.turn_num == SLIPE_DATA.piece_bk then
            --何処に配置するか計算
            auxiliary_num =
                PutLayout(board_pos, grip_num, board_si_pos, auxiliary_num, board_si, split_scale, piece_hight)
        elseif SLIPE_MOVE.turn_num == SLIPE_DATA.piece_w then
            --何処に配置するか計算
            auxiliary_num =
                PutLayout(board_pos, grip_num, board_si_pos, auxiliary_num, board_si, split_scale, piece_hight)
        end
    end

    if auxiliary_num > 0 then
        --補助からの計算
        AuxiliaryEstimate(
            auxiliary_num,
            board_pos,
            board_si_pos,
            grip_num,
            piece_si,
            board_si,
            piece_hight,
            split_scale
        )
    else
        --盤の中心から指定位置に置く
        local sub_pos = board_si_pos + RelativeToLocalCoordinates(board_si, 0, -100000, 0)
        local ang = board_si.GetLocalRotation().eulerAngles
        if piece_si[11].IsMine then
            piece_si[11].SetLocalPosition(sub_pos)
            Rot_LocalQuat_Euler(piece_si[11], ang.x, ang.y, ang.z)
        end
        if piece_si[12].IsMine then
            piece_si[12].SetLocalPosition(sub_pos)
            Rot_LocalQuat_Euler(piece_si[12], ang.x, ang.y, ang.z)
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
    split_scale)
    --配置位置
    local x = (1 + math.floor((auxiliary_num - 1) / #board_pos[1]) - math.ceil(#board_pos / 2)) * split_scale
    local z = ((1 + (auxiliary_num - 1) % #board_pos[1]) - math.ceil(#board_pos[1] / 2)) * split_scale
    --盤の中心から指定位置に置く
    local sub_pos = board_si_pos + RelativeToLocalCoordinates(board_si, x, piece_hight, z)
    local ang = board_si.GetLocalRotation().eulerAngles
    if SLIPE_MOVE.turn_num == 0 then
        if grip_num <= SLIPE_DATA.piece_split then
            if piece_si[11].IsMine then
                piece_si[11].SetLocalPosition(sub_pos)
                Rot_LocalQuat_Euler(piece_si[11], ang.x, ang.y, ang.z)
            end
        elseif grip_num > SLIPE_DATA.piece_split then
            if piece_si[12].IsMine then
                piece_si[12].SetLocalPosition(sub_pos)
                Rot_LocalQuat_Euler(piece_si[12], ang.x, ang.y, ang.z)
            end
        end
    elseif SLIPE_MOVE.turn_num == SLIPE_DATA.piece_bk then
        if grip_num <= SLIPE_DATA.piece_split then
            if piece_si[11].IsMine then
                piece_si[11].SetLocalPosition(sub_pos)
                Rot_LocalQuat_Euler(piece_si[11], ang.x, ang.y, ang.z)
            end
        end
    elseif SLIPE_MOVE.turn_num == SLIPE_DATA.piece_w then
        if grip_num > SLIPE_DATA.piece_split then
            if piece_si[12].IsMine then
                piece_si[12].SetLocalPosition(sub_pos)
                Rot_LocalQuat_Euler(piece_si[12], ang.x, ang.y, ang.z)
            end
        end
    end

    if l_use_flg and auxiliary_num > 0 then
        local x = 1 + math.floor((auxiliary_num - 1) / #board_pos[1])
        local z = (1 + (auxiliary_num - 1) % #board_pos[1])
        local grip_pos_x = 0
        local grip_pos_z = 0
        --縦の位置
        for high_pos = 1, #board_pos do
            --横の位置
            for wide_pos = 1, #board_pos[high_pos] do
                if board_pos[high_pos][wide_pos] == grip_num then
                    grip_pos_x = high_pos
                    grip_pos_z = wide_pos
                    break
                end
            end
        end
        SLIPE_MOVE.board_pos[x][z] = grip_num
        SLIPE_MOVE.board_pos[grip_pos_x][grip_pos_z] = 0

        --縦
        for high = 1, SLIPE_DATA.piece_split do
            --横
            for wide = 1, SLIPE_DATA.piece_split do
                if NOT_DEBUG then
                    STATE.Set(
                        SLIPE_DATA.str[SLIPE_DATA.str_piece_num] .. tostring(wide + (high - 1) * 5),
                        SLIPE_MOVE.board_pos[high][wide]
                    )
                end
            end
        end
        if grip_num <= SLIPE_DATA.piece_split then
            SLIPE_MOVE.turn_num = SLIPE_DATA.piece_w
        elseif grip_num > SLIPE_DATA.piece_split then
            SLIPE_MOVE.turn_num = SLIPE_DATA.piece_bk
        end
        if NOT_DEBUG then
            STATE.Set(SLIPE_DATA.str[SLIPE_DATA.str_board_num], SLIPE_MOVE.turn_num)
        end

        local turn_num = SLIPE_MOVE.turn_num
        --勝敗表示
        VictoryShoe(auxiliary_num, grip_num, turn_num)

        if NOT_DEBUG then
            --使ったやつ
            vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
        end
        l_use_flg = false
    end
end

--勝敗表示
function VictoryShoe(auxiliary_num, grip_num, turn_num)
    --中心
    if auxiliary_num == 13 then
        print(grip_num)
        --黒
        if grip_num == 3 then
            SLIPE_MOVE.victory_num = SLIPE_DATA.piece_bk
        elseif grip_num == 8 then
            SLIPE_MOVE.victory_num = SLIPE_DATA.piece_w
        else
            SLIPE_MOVE.victory_num = turn_num
        end
    end
    --勝敗

    if NOT_DEBUG then
        STATE.Set("Victory", SLIPE_MOVE.victory_num)
    end
end

--置く場所計算
function PutLayout(board_pos, grip_num, board_si_pos, auxiliary_num, board_si, split_scale, piece_hight)
    --握っている物体がどこにあるか
    local grip_pos_x = 0
    local grip_pos_z = 0
    --握ってるアイテムの場所把握
    --縦の位置
    for high_pos = 1, #board_pos do
        --横の位置
        for wide_pos = 1, #board_pos[high_pos] do
            if board_pos[high_pos][wide_pos] == grip_num then
                grip_pos_x = high_pos
                grip_pos_z = wide_pos
                break
            end
        end
    end

    --仮の配置
    local grip_si = SLIPE_DATA.str_piece_si[grip_num]
    local grip_si_pos = grip_si.GetLocalPosition()
    local dist = SLIPE_DATA.dist
    --縦の位置
    for high_pos = 1, #board_pos do
        --横の位置
        for wide_pos = 1, #board_pos[high_pos] do
            if grip_pos_x == high_pos or grip_pos_z == wide_pos then
                if not (grip_pos_x == high_pos and grip_pos_z == wide_pos) then
                    --配置位置
                    local x = (high_pos - math.ceil(#board_pos / 2)) * split_scale
                    local z = (wide_pos - math.ceil(#board_pos[high_pos] / 2)) * split_scale
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
                    end
                end
            end
        end
    end

    --計算結果補正
    if auxiliary_num > 0 then
        local x = 1 + math.floor((auxiliary_num - 1) / #SLIPE_MOVE.board_pos[1])
        local z = 1 + (auxiliary_num - 1) % #SLIPE_MOVE.board_pos[1]
        --高さ
        if x < grip_pos_x then
            for i = grip_pos_x - 1, 1, -1 do
                if board_pos[i][grip_pos_z] ~= 0 then
                    if grip_pos_x ~= i then
                        auxiliary_num = grip_pos_z + i * #board_pos[1]

                        break
                    end
                end
                if i == 1 then
                    auxiliary_num = grip_pos_z + (i - 1) * #board_pos[1]
                end
            end
        elseif x > grip_pos_x then
            for i = grip_pos_x + 1, #SLIPE_MOVE.board_pos do
                if board_pos[i][grip_pos_z] ~= 0 then
                    if grip_pos_x ~= i then
                        auxiliary_num = grip_pos_z + (i - 2) * #board_pos[1]
                        break
                    end
                end
                if i == #SLIPE_MOVE.board_pos then
                    auxiliary_num = grip_pos_z + (i - 1) * #board_pos[1]
                end
            end
        elseif z < grip_pos_z then
            for i = grip_pos_z - 1, 1, -1 do
                if board_pos[grip_pos_x][i] ~= 0 then
                    if grip_pos_z ~= i then
                        auxiliary_num = i + 1 + (grip_pos_x - 1) * #board_pos[1]

                        break
                    end
                end
                if i == 1 then
                    auxiliary_num = i + (grip_pos_x - 1) * #board_pos[1]
                end
            end
        elseif z > grip_pos_z then
            for i = grip_pos_z + 1, #SLIPE_MOVE.board_pos do
                if board_pos[grip_pos_x][i] ~= 0 then
                    if grip_pos_z ~= i then
                        auxiliary_num = i - 1 + (grip_pos_x - 1) * #board_pos[1]
                        break
                    end
                end
                if i == #SLIPE_MOVE.board_pos then
                    auxiliary_num = i + (grip_pos_x - 1) * #board_pos[1]
                end
            end
        end

        x = 1 + math.floor((auxiliary_num - 1) / #SLIPE_MOVE.board_pos[1])
        z = 1 + (auxiliary_num - 1) % #SLIPE_MOVE.board_pos[1]
        if x == grip_pos_x and z == grip_pos_z then
            return 0
        end
    end

    return auxiliary_num
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
function Rot_Quat_Euler(subitem, x, y, z)
    subitem.SetRotation(Quaternion.Euler(x, y, z))
end

--subitemをEuler角の値に変更
function Rot_LocalQuat_Euler(subitem, x, y, z)
    subitem.SetLocalRotation(Quaternion.Euler(x, y, z))
end

--ボードの初期化メッセージ
function BoardNillMess(sender, name, message)
    nil_wait_timer = os.clock()
    print("first")
end
vci.message.On(ASHU_MESS .. "BOARD_NILL", BoardNillMess)

--ボードのnil処理
function BoardNillSet()
    SLIPE_MOVE.board_pos = nil
    SLIPE_MOVE.turn_num = nil
end

--ボードのステート処理
function BoardStateSet()
    if NOT_DEBUG then
        SLIPE_MOVE.board_pos = {}
        --縦
        for high = 1, SLIPE_DATA.piece_split do
            SLIPE_MOVE.board_pos[high] = {}
            --横
            for wide = 1, SLIPE_DATA.piece_split do
                SLIPE_MOVE.board_pos[high][wide] =
                    STATE.Get(SLIPE_DATA.str[SLIPE_DATA.str_piece_num] .. tostring(wide + (high - 1) * 5))
            end
        end
        --手番
        SLIPE_MOVE.turn_num = STATE.Get(SLIPE_DATA.str[SLIPE_DATA.str_board_num])
        SLIPE_MOVE.victory_num = STATE.Get("Victory")
    end
end
