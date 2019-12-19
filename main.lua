-- [[
-- Общие параметры - диаметр окружности, ширина квадрата защиты, базовое
-- расстояние.
-- ]]
local inspect = require "inspect"
local vector = require "vector"
local linesbuf = require "kons".new()
local bhupur = require "bhupur"
local lg = love.graphics

-- Возвращает истину если точка с координатами px и py находится в круге 
-- радиуса cr и координатами cx и cy
local function pointInCircle(px, py, cx, cy, cr)
  return (px - cx)^2 + (py - cy)^2 <= cr ^ 2
end

-- длина нормали со знаком от точки c к прямой, образованной p1 и p2
-- параметры - hump.vector
local function nearestDist(c, p1, p2)
  local tmp = p2 - p1
  return tmp:cross(c - p1) / tmp:len()
end

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

-- p1, p2 - начальная точка(вектор) и конечная
-- center - вектор центра окружности
-- rad - радиус окружности
-- возвращает два или одно значение точек пересечения в виде векторов или nil
function intersectionWithCircle(p1, p2, center, rad)
    local dist = nearestDist(center, p1, p2)
    if dist > rad then
        return nil
    end
end

-- эти линии должны соотноситься с центром рисунка
local line1, line2

-- на вход принимает либо пару векторов(два параметра функции) либо таблицу
-- с парой векторов по индексам 1 и 2 соответственно(один параметр функции)
function drawVecLine(p1, p2)
    if p1 and not p2 and type(p1) == "table" then
        lg.line(p1[1].x, p1[1].y, p1[2].x, p1[2].y)
    elseif p1 and p2 then
        lg.line(p1.x, p1.y, p2.x, p2.y)
    end
end

local h = lg.getHeight()
-- убрать эти переменные, слишком употребительные имена, вносящие путаницу
local cx, cy = 40, 40
local baseLineParam = 30

-- расчет координат базовых линий построения. d - параметр отвечающий за
-- расстояние между горизонталью и центром рисунка.
function setupBaseLines(d)
    local cx, cy = bhupur.center.x, bhupur.center.y
    line1 = {vector(40, cy - d), vector(560, cy - d)}
    line2 = {vector(40, cy + d), vector(560, cy + d)}
end

function love.load()
    -- вызов только для прерасчета координат центра рисунка в bhupur.center.x,
    -- bhupur.center.y
    bhupur.draw(cx, cy, h - cx * 2)
    setupBaseLines(baseLineParam)
end

function love.draw()
    bhupur.draw(cx, cy, h - cx * 2)

    lg.setColor{0.13, 0.95, 0.1}
    lg.circle("fill", bhupur.center.x, bhupur.center.y, 3)

    lg.setColor{1, 1, 1}
    -- нужно вычислить подходящий радиус окружности автоматически
    lg.circle("line", bhupur.center.x, bhupur.center.y, 255)

    drawVecLine(line1)
    drawVecLine(line2)

    linesbuf:pushi("baseLineParam = %d", baseLineParam)
    linesbuf:draw()
end

function love.update(dt)
    linesbuf:update(dt)
end

function love.keypressed(_, key)
    if key == "escape" then
        love.event.quit()
    elseif key == "up" then
        baseLineParam = baseLineParam + 1
        setupBaseLines(baseLineParam)
    elseif key == "down" then
        baseLineParam = baseLineParam - 1
        setupBaseLines(baseLineParam)
    end
end
