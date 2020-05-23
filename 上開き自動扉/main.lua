--簡略化
local STATE = vci.state
local ASSET = vci.assets

--身体コライダ名称
local BODY_CLLIDER = {
    "Head",
    "RightArm",
    "LeftArm",
    "RightHand",
    "LeftHand",
    "Chest",
    "Hips",
    "RightThigh",
    "LeftThigh",
    "RightToes",
    "LeftToes",
    "RightFoot",
    "LeftFoot",
    "HandPointMarker"
}

--データ
local DOOR_DATA = {
    --アイテム名
    str_door = {"フレーム", "右扉", "左扉", "センサー"},
    str_door_si = {},
    --枠
    str_door_frame = 1,
    --右扉
    str_door_r_door = 2,
    --左扉
    str_door_l_door = 3,
    --センサー
    str_door_sensor = 4,
    --基本扉移動幅(片側)
    door_def_moverange = 1.7 / 2,
    --基本センサー範囲
    sensor_def_range = 2.1 * 2,
    --基本扉スケール幅(上側)
    door_def_scalerange = 2.1
}
--動き
local DOOR_MOVE = {
    --コライダ検索
    collider_flg = false,
    --開フラグ
    open_flg = false,
    --前のフラグ保持
    open_before_flg = false,
    --開いた時間保持
    now_open_clock = 0,
    --閉じた時間保持
    now_close_clock = 0,
    --開ききるまでの時間
    open_clock_max = 5,
    --閉まりきるまでの時間
    close_clock_max = 8,
    --センサー時間保存
    now_sensor_clock = 0,
    --閉じるまでの時間
    sensor_clock_max = 0.3
}
--自分のみ
if ASSET.IsMine then
    for i = 1, #DOOR_DATA.str_door do
        DOOR_DATA.str_door_si[i] = ASSET.GetSubItem(DOOR_DATA.str_door[i])
    end
end

--メイン時間
local m_timer = 0
--時間間隔
local m_timer_cnt = 1 / 10
function update()
    --間引き
    if TimeManage(m_timer, m_timer_cnt) then
        --扉設置
        DoorPut()
    end
end

--扉設置
function DoorPut()
    --枠
    local flame_si = DOOR_DATA.str_door_si[DOOR_DATA.str_door_frame]
    local flame_si_pos = flame_si.GetLocalPosition()
    local flame_si_rot = flame_si.GetRotation()
    local flame_si_scale = flame_si.GetLocalScale()

    --当たったならば
    if DOOR_MOVE.collider_flg then
        --当たり初期化
        DOOR_MOVE.collider_flg = false
        DOOR_MOVE.now_sensor_clock = os.clock()
        --記録用
        DOOR_MOVE.open_before_flg = true
        --センサー時間内に当たり判定がない場合
        if not DOOR_MOVE.open_before_flg then
            --時間保持
            DOOR_MOVE.now_open_clock = os.clock()
            --判断用
            DOOR_MOVE.open_flg = true
        end
    end

    --センサー
    local clock_est2
    if DOOR_MOVE.now_sensor_clock ~= 0 then
        clock_est2 = (os.clock() - DOOR_MOVE.now_sensor_clock) / DOOR_MOVE.sensor_clock_max
        --最大値超えないように
        if clock_est2 > 1 then
            clock_est2 = 1
            --開いていたならば
            if DOOR_MOVE.open_before_flg then
                --閉じ始め
                DOOR_MOVE.now_close_clock = os.clock()
                --時間差分
                local time_est = os.clock() - DOOR_MOVE.now_open_clock
                --規定値以下ならば
                if time_est < DOOR_MOVE.open_clock_max then
                    DOOR_MOVE.now_close_clock =
                        DOOR_MOVE.now_close_clock -
                        (DOOR_MOVE.open_clock_max - time_est) * DOOR_MOVE.close_clock_max / DOOR_MOVE.open_clock_max
                end
            end
            DOOR_MOVE.now_sensor_clock = os.clock()
            --記録用
            DOOR_MOVE.open_before_flg = false
            --判断用
            DOOR_MOVE.open_flg = false
        end
    else
        DOOR_MOVE.now_sensor_clock = os.clock()
        clock_est2 = 0
    end
    local sen_door_si = DOOR_DATA.str_door_si[DOOR_DATA.str_door_sensor]
    sen_door_si.SetLocalPosition(flame_si_pos)
    sen_door_si.SetLocalScale(flame_si_scale * DOOR_DATA.sensor_def_range * clock_est2)

    --当たり判定があった
    if DOOR_MOVE.open_before_flg then
        --前が閉じる判定
        if not DOOR_MOVE.open_flg then
            --開き始め
            DOOR_MOVE.now_open_clock = os.clock()
            --時間差分
            local time_est = os.clock() - DOOR_MOVE.now_close_clock
            --規定値以下ならば
            if DOOR_MOVE.now_close_clock ~= 0 and time_est < DOOR_MOVE.close_clock_max then
                DOOR_MOVE.now_open_clock =
                    DOOR_MOVE.now_open_clock -
                    (DOOR_MOVE.close_clock_max - time_est) * DOOR_MOVE.open_clock_max / DOOR_MOVE.close_clock_max
            end
        end
        --開ける
        DOOR_MOVE.open_flg = true
        if (os.clock() - DOOR_MOVE.now_sensor_clock) > DOOR_MOVE.sensor_clock_max then
            DOOR_MOVE.open_flg = false
        end
    end

    --時間での移動量計算下処理
    local clock_est
    --開状態
    if DOOR_MOVE.open_flg then
        --スケール1基準
        clock_est = (DOOR_MOVE.open_clock_max - (os.clock() - DOOR_MOVE.now_open_clock)) / DOOR_MOVE.open_clock_max
        --最大値行かないように
        if clock_est <= 0 then
            clock_est = 0
        end
    else
        --スケール0基準
        clock_est = (os.clock() - DOOR_MOVE.now_close_clock) / DOOR_MOVE.close_clock_max
        --最大値行かないように
        if clock_est >= 1 then
            clock_est = 1
        end
    end

    --相対移動量計算
    local door_move_amount = DOOR_DATA.door_def_scalerange * (1 - clock_est) * flame_si_scale.y
    --ローカル移動量計算
    local loc_move_amount = RelativeToLocalCoordinates(flame_si, 0, door_move_amount, 0)

    --右
    local r_door_si = DOOR_DATA.str_door_si[DOOR_DATA.str_door_r_door]
    r_door_si.SetLocalPosition(flame_si_pos + loc_move_amount)
    r_door_si.SetRotation(flame_si_rot)
    flame_si_scale.y = flame_si_scale.y * clock_est
    r_door_si.SetLocalScale(flame_si_scale)
    --左
    local l_door_si = DOOR_DATA.str_door_si[DOOR_DATA.str_door_l_door]
    l_door_si.SetLocalPosition(flame_si_pos + loc_move_amount)
    l_door_si.SetRotation(flame_si_rot)
    l_door_si.SetLocalScale(flame_si_scale)
end

function BodyCollisionEnterCheck(item, hit)
    --センサー接触
    if item == DOOR_DATA.str_door[DOOR_DATA.str_door_sensor] then
        --体との判定
        for i = 1, #BODY_CLLIDER do
            if BODY_CLLIDER[i] == hit then
                return true
            end
        end
    end
    return false
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

function onTriggerEnter(item, hit)
    --開くかどうか
    if BodyCollisionEnterCheck(item, hit) then
        --開ける
        DOOR_MOVE.collider_flg = true
    end
end
