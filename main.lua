local inspect = require "inspect"
local linebuf = require "kons".new()
local bhupur = require "bhupur"
local lg = love.graphics

-- параметры - hump.vector
-- источник: https://users.livejournal.com/-winnie/152327.html
function intersection(start1, end1, start2, end2)
    assert(vector.isvector(start1) and vector.isvector(end1) and
        vector.isvector(start2) and vector.isvector(end2))

    local dir1 = end1 - start1;
    local dir2 = end2 - start2;

    --считаем уравнения прямых проходящих через отрезки
    local a1 = -dir1.y;
    local b1 = dir1.x;
    local d1 = -(a1*start1.x + b1*start1.y);

    local a2 = -dir2.y;
    local b2 = dir2.x;
    local d2 = -(a2*start2.x + b2*start2.y);

    --подставляем концы отрезков, для выяснения в каких полуплоскотях они
    local seg1_line2_start = a2 * start1.x + b2 * start1.y + d2;
    local seg1_line2_end = a2 * end1.x + b2 * end1.y + d2;

    local seg2_line1_start = a1 * start2.x + b1 * start2.y + d1;
    local seg2_line1_end = a1 * end2.x + b1 * end2.y + d1;

    --если концы одного отрезка имеют один знак, значит он в одной полуплоскости и пересечения нет.
    if (seg1_line2_start * seg1_line2_end >= 0 or 
        seg2_line1_start * seg2_line1_end >= 0) then
        return nil
    end

    local u = seg1_line2_start / (seg1_line2_start - seg1_line2_end);

    return start1 + u*dir1;
end

function love.draw()
    local h = lg.getHeight()
    local cx, cy = 40, 40
    bhupur.draw(cx, cy, h - cx * 2)
    -- нужно посчитать координаты центра рисунка

    lg.setColor{0.13, 0.95, 0.1}
    lg.circle("fill", bhupur.center.x, bhupur.center.y, 3)
end

function love.update(dt)
end

function love.keypressed(_, key)
    if key == "escape" then
        love.event.quit()
    end
end
