--簡略化
local ASSET = vci.assets
local STATE = vci.state
local ASHU_MESS = "ASHU_MADAN_MESS_"

--パラメータ
local DATA = {
    --使用する名称
    str = {
        "rune",
        "NINGYOU (",
        "fire ("
    },
    --ルーン
    str_rune_si = 0,
    str_rune_num = 1,
    --弾
    str_bullet_si = {},
    str_bullet_num = 2,
    bullet_scale = Vector3.__new(30, 21, 27),
    eff_max = 3,
    --エフェクト
    eff_fire = {},
    str_fire_num = 3,
    --消える距離
    erase_dist = 10,
    --力倍率
    add_force = 6
}

local MOVE = {
    --弾が使用中かどうか
    bullet_flg = {},
    --弾が使用させる
    bullet_mess = false
}
--サブアイテム関連
for i = 1, #DATA.str do
    if i == DATA.str_rune_num then
        DATA.str_rune_si = ASSET.GetSubItem(DATA.str[i])
    elseif i == DATA.str_bullet_num then
        for i2 = 1, DATA.eff_max do
            DATA.str_bullet_si[i2] = ASSET.GetSubItem(DATA.str[i] .. tostring(i2) .. ")")
        end
    elseif i == DATA.str_fire_num then
        for i2 = 1, DATA.eff_max do
            DATA.eff_fire[i2] = ASSET.GetEffekseerEmitter(DATA.str[i] .. tostring(i2) .. ")")
        end
    end
end

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
    for i = 1, DATA.eff_max do
        MOVE.bullet_flg[i] = false
    end
    STATE.Set("BULLET_MESS", MOVE.bullet_mess)
    vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
end

--メイン処理
function Main()
    --ルーン情報
    local rune = DATA.str_rune_si
    local rune_pos = rune.GetPosition()

    for i = 1, DATA.eff_max do
        --在るならば
        if MOVE.bullet_flg[i] then
            --弾情報
            local bullet = DATA.str_bullet_si[i]
            local bullet_pos = bullet.GetPosition()
            --差分距離(ユークリッド)
            local dist = Vector3.Distance(rune_pos, bullet_pos)
            --指定距離以上で消える
            if DATA.erase_dist < dist then
                bullet.SetLocalScale(Vector3.__new(1 / 1000, 1 / 1000, 1 / 1000))
                DATA.eff_fire[i]._ALL_Stop()
                MOVE.bullet_flg[i] = false
            end
        end
    end

    --弾発射指示
    if MOVE.bullet_mess then
        for i = 1, DATA.eff_max do
            --残段ある場合
            if not MOVE.bullet_flg[i] then
                --弾情報
                Bulletfunc(i)
                break
            end

            --残弾なし
            if i == DATA.eff_max then
                local max_dist = 0
                local max_num = 0
                for i2 = 1, DATA.eff_max do
                    --弾情報
                    local bullet = DATA.str_bullet_si[i2]
                    local bullet_pos = bullet.GetPosition()
                    --差分距離(ユークリッド)
                    local dist = Vector3.Distance(rune_pos, bullet_pos)
                    --最大距離番号求める
                    if max_dist <= dist then
                        max_dist = dist
                        max_num = i2
                    end
                end
                --弾情報
                Bulletfunc(max_num)
            end
        end

        MOVE.bullet_mess = false
        STATE.Set("BULLET_MESS", MOVE.bullet_mess)
        vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
    end
end

function Bulletfunc(num)
    --ルーン情報
    local rune = DATA.str_rune_si
    local rune_pos = rune.GetLocalPosition()
    local rune_rot = rune.GetRotation()
    --弾情報
    local bullet = DATA.str_bullet_si[num]
    Velo_Ang_Zero(bullet)
    local pos = rune_pos + RelativeToLocalCoordinates(rune, 0, 0, 2)
    bullet.SetLocalPosition(pos)
    bullet.SetLocalScale(DATA.bullet_scale)
    --座標変換用
    local bullet_rot = Quaternion.Euler(-90, 0, 0)
    bullet.SetRotation(rune_rot * bullet_rot)
    MOVE.bullet_flg[num] = true
    DATA.eff_fire[num]._ALL_SetLoop(true)
    DATA.eff_fire[num]._ALL_Play()
    local force = rune.GetForward() *DATA.add_force
     bullet.AddForce(force)
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

--use処理
function onUse(use)
    --use判定
    if use == DATA.str[DATA.str_rune_num] then
        STATE.Set("BULLET_MESS", true)
        vci.message.Emit(ASHU_MESS .. "BOARD_NILL", 0)
    end
end

--subitemをEuler角の値に変更
function Rot_Quat_Euler(subitem, x, y, z)
    subitem.SetRotation(Quaternion.Euler(x, y, z))
end
--subitemをEuler角の値に変更
function Rot_Local_Quat_Euler(subitem, x, y, z)
    subitem.SetLocalRotation(Quaternion.Euler(x, y, z))
end

--サブアイテム速度/回転速度/力初期化
function Velo_Ang_Zero(item)
    if item ~= nil then
        item.SetVelocity(Vector3.zero)
        item.SetAngularVelocity(Vector3.zero)
        item.AddForce(Vector3.zero)
    end
end

--ボードのステート処理
function BoardStateSet()
    MOVE.bullet_mess = STATE.Get("BULLET_MESS")
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
