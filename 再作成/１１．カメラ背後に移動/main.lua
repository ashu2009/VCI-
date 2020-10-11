--簡略化
local STATE = vci.state
local ASSET = vci.assets
local STADIO = vci.studio
local ASHU_MESS = "ASHU_CAMERA_BACK_FLLOW_MESS_"

local DATA = {
    str = "Cube (",
    str_si = {},
    str_max = 8,
    --カメラ距離
    camera_dist = 1.1,
    camera_hight = -1.14,
    camera_angle = 16,
    ----------------------------------------
    --ボーン基準(ヒップ)
    def_bone = "Hips",
    --文字
    str_txt = "Text ("
}
local MOVE = {
    --カメラ番号
    camera_flg = 0
}

--壁関係サブアイテム処理
for i = 1, DATA.str_max do
    DATA.str_si[i] = ASSET.GetSubItem(DATA.str .. tostring(i) .. ")")
end

--メイン時間
local m_timer = 0
--時間間隔
local m_timer_cnt = 1 / 30
--初期化フラグ
local first_flg = true
--nilにするタイマー
local nil_wait_timer = os.clock()
--nilにする時間
local nil_wait_timer_count = 1 / 15
function update()
    if (os.clock() - m_timer) > m_timer_cnt then
        if first_flg then
            --初期化
            FirstDataSet()
            first_flg = false
        end

        --Main()
        m_timer = os.clock()
    end
    if not first_flg and nil_wait_timer == 0 then
        --ボタン処理
        ButtonFunc()
    end
end

--初期化
function FirstDataSet()
    --文字関係サブアイテム処理
    for i = 1, DATA.str_max - 1 do
        ASSET._ALL_SetText(DATA.str_txt .. tostring(i) .. ")", "")
    end

    --ゲーム状態
    MOVE.camera_flg = 0
    STATE.Set(ASHU_MESS .. "CAMERA", MOVE.camera_flg)

    vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
end

--ボタン処理
function ButtonFunc()
    --アバター
    local avater_data = STADIO.GetAvatars()
    if MOVE.camera_flg ~= DATA.str_max then
        for i = 1, #avater_data do
            if i < DATA.str_max then
                --押されているボタン
                if i == MOVE.camera_flg then
                    --腰情報
                    local player_avater = avater_data[i].GetBoneTransform(DATA.def_bone)
                    if player_avater then
                        --カメラ有無
                        local camera = STADIO.GetHandiCamera()
                        if camera then
                            local pos = player_avater.position
                            local rot = player_avater.rotation
                            rot.x = 0
                            rot.z = 0
                            pos =
                                pos + RelativeToLocalCoordinates2(player_avater, 0, DATA.camera_dist, -DATA.camera_dist)
                            camera.SetPosition(pos)
                            local bullet_rot = Quaternion.Euler(DATA.camera_angle, 0, 0)
                            camera.SetRotation(rot * bullet_rot)
                        end
                    end
                end
                ASSET._ALL_SetText(DATA.str_txt .. tostring(i) .. ")", avater_data[i].GetName())
            end
        end
    else
        --カメラ有無
        local camera = STADIO.GetHandiCamera()
        if camera then
            local si = DATA.str_si[#DATA.str_si]
            local pos = si.GetPosition()
            local loc_angle = si.GetRotation().eulerAngles
            camera.SetLocalPosition(pos)
            Rot_Quat_Euler(camera, 0, loc_angle.y - 90, 0)
        end
        STATE.Set(ASHU_MESS .. "CAMERA", 0)
        vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
    end
end

--時間処理
local timer = os.clock()
local timer_count = 1 / 30
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

--USE処理
function onUse(tar)
    --ボタン関係サブアイテム処理
    for i = 1, #DATA.str_si do
        --ボタン処理
        if tar == DATA.str_si[i].GetName() then
            STATE.Set(ASHU_MESS .. "CAMERA", i)
            vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
        end
    end
end

--ボードのステート処理
function BoardStateSet()
    MOVE.camera_flg = STATE.Get(ASHU_MESS .. "CAMERA")
end

--ボードの初期化メッセージ
function BoardNillMess(sender, name, message)
    nil_wait_timer = os.clock()
end
vci.message.On(ASHU_MESS .. "BOARD_NILL", BoardNillMess)

--位置計算(相対座標をローカル座標に)
function RelativeToLocalCoordinates2(fn_subitem, fn_put_x, fn_put_y, fn_put_z)
    local item = fn_subitem
    local item_ang = item.rotation.eulerAngles
    item_ang.x = 0
    --item_ang.x
    item_ang.y = -item_ang.y
    item_ang.z = 0
    --item_ang.z

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
