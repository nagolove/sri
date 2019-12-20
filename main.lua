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

    --если концы одного отрезка имеют один знак, значит он в одной 
    --полуплоскости и пересечения нет.
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
-- источник: http://csharphelper.com/blog/2014/09/determine-where-a-line-intersects-a-circle-in-c/
function intersectionWithCircle(p1, p2, center, rad)
    local t
    local dx = p2.x - p1.x;
    local dy = p2.y - p1.y;
    local a = dx * dx + dy * dy;
    local b = 2 * (dx * (p1.x - center.x) + dy * (p1.y - center.y));
    local c = (p1.x - center.x) * (p1.x - center.x) + 
        (p1.y - center.y) * (p1.y - center.y) - rad * rad;

    local det = b * b - 4 * a * c
    --if ((a <= 0.0000001) || (det < 0))
    if a <= 0.0001 or det < 0 then
        return nil
    elseif det == 0 then -- проверь, может быть равен нулю? Или сделать сравнение?
        t = -b / (2 * a)
        return vector(p1.x + t * dx, p1.y + t * dy)
    else
        t = (-b + math.sqrt(det)) / (2 * a)
        local res1 = vector(p1.x + t * dx, p1.y + t * dy)
        t = (-b - math.sqrt(det)) / (2 * a)
        local res2 = vector(p1.x + t * dx, p1.y + t * dy)
        return res1, res2
    end
end

-- на вход принимает либо пару векторов(два параметра функции) либо таблицу
-- с парой векторов по индексам 1 и 2 соответственно(один параметр функции)
function drawVecLine(p1, p2)
    if p1 and not p2 and type(p1) == "table" then
        lg.line(p1[1].x, p1[1].y, p1[2].x, p1[2].y)
    elseif p1 and p2 then
        lg.line(p1.x, p1.y, p2.x, p2.y)
    end
end

-- эти линии должны соотноситься с центром рисунка
local line1, line2, line3, line4, line5, line6
local h = lg.getHeight()
-- убрать эти переменные, слишком употребительные имена, вносящие путаницу
local cx, cy = 40, 40
local baseLineParam = 30
local circleRad = 255
local p1, p2, p3, p4

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

    p1, p2 = intersectionWithCircle(line1[1], line1[2],
        vector(bhupur.center.x, bhupur.center.y), circleRad)
    p3, p4 = intersectionWithCircle(line2[1], line2[2],
        vector(bhupur.center.x, bhupur.center.y), circleRad)
    line3 = {p1, vector(bhupur.center.x, bhupur.center.y + circleRad)}
    line4 = {p2, vector(bhupur.center.x, bhupur.center.y + circleRad)}
    line5 = {p3, vector(bhupur.center.x, bhupur.center.y - circleRad)}
    line6 = {p4, vector(bhupur.center.x, bhupur.center.y - circleRad)}
    print("p1", inspect(p1))
    print("p2", inspect(p2))
end

function love.draw()
    bhupur.draw(cx, cy, h - cx * 2)

    lg.setColor{0.13, 0.95, 0.1}
    lg.circle("fill", bhupur.center.x, bhupur.center.y, 3)

    lg.setColor{1, 1, 1}
    -- нужно вычислить подходящий радиус окружности автоматически
    lg.circle("line", bhupur.center.x, bhupur.center.y, circleRad)

    lg.circle("fill", p1.x, p1.y, 3)
    lg.circle("fill", p2.x, p2.y, 3)
    lg.circle("fill", p3.x, p3.y, 3)
    lg.circle("fill", p4.x, p4.y, 3)

    drawVecLine(line1)
    drawVecLine(line2)
    drawVecLine(line3)
    drawVecLine(line4)
    drawVecLine(line5)
    drawVecLine(line6)

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
