local STATE = vci.state
local ASSET = vci.assets
local ASHU_MESS = "ASHU_NEWS_PAPER_MESS_"
local NOT_DEBUG = true
--各々の時間表示するならばfalse
local MINE_DATE_ONLY = true

local CAPA_CLOCK_DATA = {
    str_material = "n",
    str_material_num = 4,
    material = {},
    str_date = {"hour", "min"}
}
--遷移マテリアル名称
for i = 1, CAPA_CLOCK_DATA.str_material_num do
    CAPA_CLOCK_DATA.material[i] = CAPA_CLOCK_DATA.str_material .. tostring(i)
end

--時間処理
local timer = os.clock()
local timer_count = 1 / 10
function updateAll()
    --時間管理
    if TimeManage(timer, timer_count) then
        --自分の強制表示
        if MINE_DATE_ONLY then
            --出した人のみ
            if ASSET.IsMine then
                --時間関連
                local date = os.date("*t")
                --時間表示
                local offset = Vector2.zero
                for i = 1, #CAPA_CLOCK_DATA.str_date do
                    local num = date[CAPA_CLOCK_DATA.str_date[i]]
                    if num < 10 then
                        --0.6は0基準-0.1すると1...
                        offset.x = 0.6
                        ASSET._ALL_SetMaterialTextureOffsetFromName(CAPA_CLOCK_DATA.material[(i - 1) * 2 + 1], offset)
                        offset.x = 0.6 - num * 0.1
                        ASSET._ALL_SetMaterialTextureOffsetFromName(CAPA_CLOCK_DATA.material[i * 2], offset)
                    else
                        --2桁目
                        offset.x = 0.6 - math.floor(num / 10) * 0.1
                        ASSET._ALL_SetMaterialTextureOffsetFromName(CAPA_CLOCK_DATA.material[(i - 1) * 2 + 1], offset)
                        --1桁目
                        offset.x = 0.6 - (num % 10) * 0.1
                        ASSET._ALL_SetMaterialTextureOffsetFromName(CAPA_CLOCK_DATA.material[i * 2], offset)
                    end
                end
            end
        else
            --時間関連
            local date = os.date("*t")
            --時間表示
            local offset = Vector2.zero
            for i = 1, #CAPA_CLOCK_DATA.str_date do
                local num = date[CAPA_CLOCK_DATA.str_date[i]]
                if num < 10 then
                    --0.6は0基準-0.1すると1...
                    offset.x = 0.6
                    ASSET.SetMaterialTextureOffsetFromName(CAPA_CLOCK_DATA.material[(i - 1) * 2 + 1], offset)
                    offset.x = 0.6 - num * 0.1
                    ASSET.SetMaterialTextureOffsetFromName(CAPA_CLOCK_DATA.material[i * 2], offset)
                else
                    --2桁目
                    offset.x = 0.6 - math.floor(num / 10) * 0.1
                    ASSET.SetMaterialTextureOffsetFromName(CAPA_CLOCK_DATA.material[(i - 1) * 2 + 1], offset)
                    --1桁目
                    offset.x = 0.6 - (num % 10) * 0.1
                    ASSET.SetMaterialTextureOffsetFromName(CAPA_CLOCK_DATA.material[i * 2], offset)
                end
            end
        end

        --時間関連
        local date = os.date("*t")
        --時間表示
        local offset = Vector2.zero
        for i = 1, #CAPA_CLOCK_DATA.str_date do
            local num = date[CAPA_CLOCK_DATA.str_date[i]]

            if num < 10 then
                --0.6は0基準-0.1すると1...
                offset.x = 0.6
                ASSET.SetMaterialTextureOffsetFromIndex((i - 1) * 2 + 1, offset)
                offset.x = 0.6 - num * 0.1
                ASSET.SetMaterialTextureOffsetFromIndex(i * 2, offset)
            else
                --2桁目
                offset.x = 0.6 - math.floor(num / 10) * 0.1
                ASSET.SetMaterialTextureOffsetFromIndex((i - 1) * 2 + 1, offset)
                --1桁目
                offset.x = 0.6 - (num % 10) * 0.1
                ASSET.SetMaterialTextureOffsetFromIndex(i * 2, offset)
            end
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
