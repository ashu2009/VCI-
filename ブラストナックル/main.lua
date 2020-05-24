--簡略化
local STATE = vci.state
local ASSET = vci.assets

--ナックルデータ
local KNUCKLE_DATA = {
    --基礎アイテム名
    str = {"nak", "nakS", "tama", "muki", "sea", "kara"},
    --メイン
    str_knuckle_si = {},
    str_knuckle_num = 1,
    --ガード接触用
    str_knuckle_sub_si = {},
    str_knuckle_sub_num = 2,
    --左右判断
    str_knuckle_r_l = {"R", "L"},
    str_knuckle_r_num = 1,
    str_knuckle_l_num = 2,
    --弾
    str_knuckle_bullet_si = {},
    str_knuckle_bullet_num = 3,
    --薬莢排出角
    str_knuckle_ang_si = {},
    str_knuckle_ang_num = 4,
    --薬莢
    str_knuckle_cartridge_si = {},
    str_knuckle_cartridge_num = 6,
    --右残弾/左残弾/弾最大数
    bullet_max = {3, 3, 3},
    --弾に加える力
    canon_force = 45000000,
    --薬莢に加わる力
    force = 2,
    --シールド
    str_knuckle_shield_si = {},
    str_knuckle_shield_num = 5,
    --シールド最大数
    shield_max = 7,
    --シールド距離
    shield_distance = 1.3,
    --シールド基準スケール
    shield_scale = Vector3.__new(1, 1, 1),
    --シールドタイマー処理用
    shield_timer = 0,
    --シールド消失時間
    shield_timer_count = 10,
    --音楽ファイル
    sound = {"nkrelo", "sesnd", "shotsnd", "noammo"},
    --リロード番号
    sound_reload = 1,
    --ガード番号
    sound_guard = 2,
    --キャノン番号
    sound_canon = 3,
    --残弾なし
    sound_noammo = 4
}

for i = 1, #KNUCKLE_DATA.str do
    if i == KNUCKLE_DATA.str_knuckle_num then
        --左右ナックル
        for i2 = 1, #KNUCKLE_DATA.str_knuckle_r_l do
            KNUCKLE_DATA.str_knuckle_si[i2] =
                ASSET.GetSubItem(KNUCKLE_DATA.str[KNUCKLE_DATA.str_knuckle_num] .. KNUCKLE_DATA.str_knuckle_r_l[i2])
        end
    elseif i == KNUCKLE_DATA.str_knuckle_sub_num then
        --左右ナックルガード用
        for i2 = 1, #KNUCKLE_DATA.str_knuckle_r_l do
            KNUCKLE_DATA.str_knuckle_sub_si[i2] =
                ASSET.GetSubItem(KNUCKLE_DATA.str[KNUCKLE_DATA.str_knuckle_sub_num] .. KNUCKLE_DATA.str_knuckle_r_l[i2])
        end
    elseif i == KNUCKLE_DATA.str_knuckle_bullet_num then
        --左右弾用
        for i2 = 1, #KNUCKLE_DATA.str_knuckle_r_l do
            for i3 = 1, KNUCKLE_DATA.bullet_max[KNUCKLE_DATA.str_knuckle_l_num + 1] do
                KNUCKLE_DATA.str_knuckle_bullet_si[
                        (i2 - 1) * KNUCKLE_DATA.bullet_max[KNUCKLE_DATA.str_knuckle_l_num + 1] + i3
                    ] =
                    ASSET.GetSubItem(
                    KNUCKLE_DATA.str[KNUCKLE_DATA.str_knuckle_bullet_num] ..
                        KNUCKLE_DATA.str_knuckle_r_l[i2] .. tostring(i3)
                )
            end
        end
    elseif i == KNUCKLE_DATA.str_knuckle_ang_num then
        --左右薬莢排出用
        for i2 = 1, #KNUCKLE_DATA.str_knuckle_r_l do
            for i3 = 1, KNUCKLE_DATA.bullet_max[KNUCKLE_DATA.str_knuckle_l_num + 1] do
                KNUCKLE_DATA.str_knuckle_ang_si[
                        (i2 - 1) * KNUCKLE_DATA.bullet_max[KNUCKLE_DATA.str_knuckle_l_num + 1] + i3
                    ] =
                    ASSET.GetSubItem(
                    KNUCKLE_DATA.str[KNUCKLE_DATA.str_knuckle_ang_num] ..
                        KNUCKLE_DATA.str_knuckle_r_l[i2] .. tostring(i3)
                )
            end
        end
    elseif i == KNUCKLE_DATA.str_knuckle_cartridge_num then
        --薬莢用
        for i2 = 1, KNUCKLE_DATA.bullet_max[KNUCKLE_DATA.str_knuckle_l_num + 1] * 2 do
            KNUCKLE_DATA.str_knuckle_cartridge_si[i2] =
                ASSET.GetSubItem(KNUCKLE_DATA.str[KNUCKLE_DATA.str_knuckle_cartridge_num] .. tostring(i2))
        end
    elseif i == KNUCKLE_DATA.str_knuckle_shield_num then
        --シールド用
        for i2 = 1, KNUCKLE_DATA.shield_max do
            KNUCKLE_DATA.str_knuckle_shield_si[i2] =
                ASSET.GetSubItem(KNUCKLE_DATA.str[KNUCKLE_DATA.str_knuckle_shield_num] .. tostring(i2))
        end
    end
end

--時間処理
local timer = 0
local timer_count = 1 / 15
function updateAll()
    --時間管理
    if TimeManage(timer, timer_count) then
        --全員同期用
        AllSync()
        --シールド消失
        ShieldDelete()
    end
end

function onUse(use)
    --ナックル使用
    KnuckleUseFunc(use)
end

function onTriggerEnter(item, hit)
    --ナックル接触
    TouchKnucle(item, hit)
    --ガード接触
    GuardKnucle(item, hit)
end

--ナックル使用したとき
function KnuckleUseFunc(use)
    --左右について
    for i = 1, #KNUCKLE_DATA.str_knuckle_r_l do
        --本体使用
        if use == KNUCKLE_DATA.str_knuckle_si[i].GetName() then
            --残弾がある
            if KNUCKLE_DATA.bullet_max[i] > 0 then
                KNUCKLE_DATA.bullet_max[i] = KNUCKLE_DATA.bullet_max[i] - 1
                AllPlayAudio(KNUCKLE_DATA.sound[KNUCKLE_DATA.sound_canon])
                --アイテム番号
                local num =
                    (i - 1) * KNUCKLE_DATA.bullet_max[KNUCKLE_DATA.str_knuckle_l_num + 1] +
                    KNUCKLE_DATA.bullet_max[KNUCKLE_DATA.str_knuckle_l_num + 1] -
                    KNUCKLE_DATA.bullet_max[i]
                local bullet_si = KNUCKLE_DATA.str_knuckle_bullet_si[num]
                if bullet_si.IsMine then
                    --本体
                    local main_si = KNUCKLE_DATA.str_knuckle_si[i]

                    --位置/角度設定/力/回転0
                    bullet_si.SetPosition(main_si.GetPosition())
                    bullet_si.SetRotation(main_si.GetRotation())
                    bullet_si.SetVelocity(Vector3.zero)
                    bullet_si.SetAngularVelocity(Vector3.zero)
                    --前方取得
                    local ang = main_si.GetForward()
                    --力設定
                    bullet_si.AddForce(KNUCKLE_DATA.canon_force * ang)
                    ASSET.HapticPulseOnTouchingController(use, 3999, 0.3)
                    ASSET.HapticPulseOnGrabbingController(use, 3999, 0.3)
                end
            else
                --残弾なし
                AllPlayAudio(KNUCKLE_DATA.sound[KNUCKLE_DATA.sound_noammo])
                ASSET.HapticPulseOnGrabbingController(use, 3999, 0.3)
                ASSET.HapticPulseOnTouchingController(use, 3999, 0.3)
            end
        end
    end
end

--ナックル接触
function TouchKnucle(item, hit)
    --ガントレット接触
    if
        (item == KNUCKLE_DATA.str_knuckle_si[KNUCKLE_DATA.str_knuckle_l_num].GetName() and
            hit == KNUCKLE_DATA.str_knuckle_si[KNUCKLE_DATA.str_knuckle_r_num].GetName()) or
            (item == KNUCKLE_DATA.str_knuckle_si[KNUCKLE_DATA.str_knuckle_r_num].GetName() and
                hit == KNUCKLE_DATA.str_knuckle_si[KNUCKLE_DATA.str_knuckle_l_num].GetName())
     then
        AllPlayAudio(KNUCKLE_DATA.sound[KNUCKLE_DATA.sound_reload])
        --残弾復活
        KNUCKLE_DATA.bullet_max[KNUCKLE_DATA.str_knuckle_r_num] =
            KNUCKLE_DATA.bullet_max[KNUCKLE_DATA.str_knuckle_l_num + 1]
        KNUCKLE_DATA.bullet_max[KNUCKLE_DATA.str_knuckle_l_num] =
            KNUCKLE_DATA.bullet_max[KNUCKLE_DATA.str_knuckle_l_num + 1]

        --薬莢戻す
        CartridgeReload()
    end
end

--薬莢戻す
function CartridgeReload()
    --薬莢戻す
    for i = 1, KNUCKLE_DATA.bullet_max[KNUCKLE_DATA.str_knuckle_l_num + 1] * 2 do
        --薬莢
        local cartridge_si = KNUCKLE_DATA.str_knuckle_cartridge_si[i]
        --射出角度用
        local ang_si = KNUCKLE_DATA.str_knuckle_ang_si[i]
        if ang_si.IsMine then
            cartridge_si.SetPosition(ang_si.GetPosition())
            cartridge_si.SetRotation(ang_si.GetRotation())
            --力/回転0
            cartridge_si.SetVelocity(Vector3.zero)
            cartridge_si.SetAngularVelocity(Vector3.zero)
            --放射
            local houkou = cartridge_si.GetForward()
            cartridge_si.AddForce(KNUCKLE_DATA.force * houkou)
        end
    end
end

--ガード接触
function GuardKnucle(item, hit)
    --ガード部接触
    if
        (item == KNUCKLE_DATA.str_knuckle_sub_si[KNUCKLE_DATA.str_knuckle_l_num].GetName() and
            hit == KNUCKLE_DATA.str_knuckle_sub_si[KNUCKLE_DATA.str_knuckle_r_num].GetName()) or
            (item == KNUCKLE_DATA.str_knuckle_sub_si[KNUCKLE_DATA.str_knuckle_r_num].GetName() and
                hit == KNUCKLE_DATA.str_knuckle_sub_si[KNUCKLE_DATA.str_knuckle_l_num].GetName())
     then
        --鳴らす
        AllPlayAudio(KNUCKLE_DATA.sound[KNUCKLE_DATA.sound_guard])
        --薬莢戻す
        CartridgeReload()
        --ガントレット位置取得
        local left = KNUCKLE_DATA.str_knuckle_si[KNUCKLE_DATA.str_knuckle_l_num]
        local right = KNUCKLE_DATA.str_knuckle_si[KNUCKLE_DATA.str_knuckle_r_num]
        local left_position = left.GetPosition()
        local right_position = right.GetPosition()
        --角度計算
        local angle =
            Vector3.Angle(
            Vector3.__new(0, 0, 1),
            Vector3.__new(left_position.x - right_position.x, 0, left_position.z - right_position.z).normalized
        )
        if left_position.x - right_position.x > 0 then
            angle = -1 * angle
        end
        --補正計算
        local position =
            Vector3.__new(
            (left_position.x + right_position.x) / 2 +
                KNUCKLE_DATA.shield_distance * math.cos(angle / 360 * 2 * math.pi),
            (left_position.y + right_position.y) / 2,
            (left_position.z + right_position.z) / 2 +
                KNUCKLE_DATA.shield_distance * math.sin(angle / 360 * 2 * math.pi)
        )
        --シールド配置
        for i = 1, KNUCKLE_DATA.shield_max do
            local shield_si = KNUCKLE_DATA.str_knuckle_shield_si[i]
            if shield_si.IsMine then
                Rot_Quat_Euler(shield_si, 90, -angle - 90, 0)
                shield_si.SetPosition(position)
                shield_si.SetVelocity(Vector3.zero)
                shield_si.SetAngularVelocity(Vector3.zero)
                shield_si.SetLocalScale(KNUCKLE_DATA.shield_scale)
                KNUCKLE_DATA.shield_timer = os.clock()
            end
        end
    end
end

--シールド消失
function ShieldDelete()
    --タイマー起動済み
    if KNUCKLE_DATA.shield_timer ~= 0 then
        --規定時間
        if TimeManage(KNUCKLE_DATA.shield_timer, KNUCKLE_DATA.shield_timer_count) then
            --消失
            for i = 1, KNUCKLE_DATA.shield_max do
                local shield_si = KNUCKLE_DATA.str_knuckle_shield_si[i]
                if shield_si.IsMine then
                    shield_si.SetLocalScale(Vector3.__new(0, 0, 0))
                end
            end
            KNUCKLE_DATA.shield_timer = 0
        end
    end
end

--全員同期用
function AllSync()
    --左右について
    for i = 1, #KNUCKLE_DATA.str_knuckle_r_l do
        --本体
        local main_si = KNUCKLE_DATA.str_knuckle_si[i]
        --固定物の同期
        local position = main_si.GetLocalPosition()
        local rotation = main_si.GetRotation()
        local fix_si = KNUCKLE_DATA.str_knuckle_sub_si[i]
        if fix_si.IsMine then
            fix_si.SetLocalPosition(position)
            fix_si.SetRotation(rotation)
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

--指定した音を鳴らす
function AllPlayAudio(sound_name)
    ASSET._ALL_PlayAudioFromName(sound_name)
end

--subitemをEuler角の値に変更
function Rot_Quat_Euler(subitem, x, y, z)
    subitem.SetRotation(Quaternion.Euler(x, y, z))
end
