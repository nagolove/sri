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

function copy(tbl)
    local result = {}
    for k, v in pairs(tbl) do
        result[k] = v
        local mt = getmetatable(v)
        if mt then 
            setmetatable(result[k], mt) 
        end
    end
    return result
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
local w, h = lg.getDimensions()
-- убрать эти переменные, слишком употребительные имена, вносящие путаницу
local cx, cy = w / 2, h / 2
local baseLineParam = 60
local circleRad = 255
local p1, p2, p3, p4
local vertLine

function setupBaseLines(d)
    -- тут нужно поменять код, что-бы вычисления шли через точки пересечения
    -- окружности и отрезка. Порядок такой:
    -- * поднять точку на сколько нужно пикселей
    -- * пустить отрезок влево до пересечения с окружностью(кидать с запасом
    -- по пикселям)
    -- * найти точку пересечения
    -- * повторить для для правой стороны
    -- * задать линию из точек пересечения
    line1 = {vector(40, cy - d), vector(560, cy - d)}
    line2 = {vector(40, cy + d), vector(560, cy + d)}
end

function love.load()
    -- вызов только для прерасчета координат центра рисунка в bhupur.center.x,
    -- bhupur.center.y
    --bhupur.draw(cx, cy, h - cx * 2)
    calculate()
end

function calculate()
    setupBaseLines(baseLineParam)

    local circleCenter = vector(cx, cy)

    vertLine = {vector(cx, cy - circleRad), vector(cx, cy + circleRad)}

    p1, p2 = intersectionWithCircle(line1[1], line1[2], vector(cx, cy), 
        circleRad)
    p3, p4 = intersectionWithCircle(line2[1], line2[2], vector(cx, cy), 
        circleRad)

    line3 = copy{p1, vector(cx, cy + circleRad)}
    line4 = copy{p2, vector(cx, cy + circleRad)}
    line5 = copy{p3, vector(cx, cy - circleRad)}
    line6 = copy{p4, vector(cx, cy - circleRad)}

    p5 = intersection(line1[1], line1[2], line6[1], line6[2])
    p6 = intersection(line1[1], line1[2], line5[1], line5[2])

    p7 = intersection(line2[1], line2[2], vertLine[1], vertLine[2])

    local dir

    -- 250 - конец отрезка должен выходить за окружность
    dir = (p7 - p5):normalizeInplace() * 250
    line7 = copy({p5, p7 + dir})

    p8 = intersectionWithCircle(line7[1], line7[2], circleCenter, circleRad)

    -- 250 - конец отрезка должен выходить за окружность
    dir = (p7 - p6):normalizeInplace() * 250
    line8 = copy({p6, p7 + dir})

    p9 = intersectionWithCircle(line8[1], line8[2], circleCenter, circleRad)

    p10 = intersection(line1[1], line1[2], vertLine[1], vertLine[2])

    line9 = copy{p8, p9}

    line10 = copy{p8, p10}
    line11 = copy{p9, p10}

    p11 = intersection(line10[1], line10[2], line3[1], line3[2]) -- правая
    p12 = intersection(line11[1], line11[2], line4[1], line4[2]) -- левая

    dir = (circleCenter - p11):normalizeInplace() * 440
    line12 = copy{p11, p11 + dir} -- правая

    dir = (circleCenter - p12):normalizeInplace() * 440
    line13 = copy{p12, p12 + dir} -- левая

    p13 = intersectionWithCircle(line12[1], line12[2], circleCenter, circleRad)
    p14 = intersectionWithCircle(line13[1], line13[2], circleCenter, circleRad)
    
    -- горизонталь верхнего треугольника направленного вниз
    line14 = copy{p13, p14} 

    p15 = intersection(line14[1], line14[2], vertLine[1], vertLine[2])
    
    p16 = intersection(line4[1], line4[2], line2[1], line2[2])
    p17 = intersection(line3[1], line3[2], line2[1], line2[2])

    dir = (p16 - p15):normalizeInplace() * 130
    line15 = copy{p15, p16 + dir}

    dir = (p17 - p15):normalizeInplace() * 130
    line16 = copy{p15, p17 + dir}

    p18 = p11:clone()
    p19 = p12:clone()
    dir = (p19 - p18):normalizeInplace() * 100
    p19 = p19 + dir
    dir = (p18 - p19):normalizeInplace() * 100
    p18 = p18 + dir

    -- провести прямую через точки p18 и p19 взятых копией точек p11, p12
    -- вспомогательная прямая, можно не рисовать
    line17 = copy{p18, p19}

    p20 = intersection(line17[1], line17[2], line16[1], line16[2])
    p21 = intersection(line17[1], line17[2], line15[1], line15[2])

    line18 = copy{p20, p21}
end

function love.draw()
    --bhupur.draw(cx, cy, h - cx * 2)

    local w, h = lg.getDimensions()
    bhupur.draw2(w / 2, h / 2, h)

    lg.setColor{0.13, 0.95, 0.1}
    lg.circle("fill", cx, cy, 3)

    lg.setColor{1, 1, 1}
    -- нужно вычислить подходящий радиус окружности автоматически
    lg.circle("line", cx, cy, circleRad)

    lg.circle("fill", p1.x, p1.y, 3)
    lg.circle("fill", p2.x, p2.y, 3)
    lg.circle("fill", p3.x, p3.y, 3)
    lg.circle("fill", p4.x, p4.y, 3)

    drawVecLine(vertLine)
    -- горизонталь большого треугольника вершиной вниз
    drawVecLine(line1) 
    -- горизонталь большого треугольника вершиной вверх
    drawVecLine(line2) 
    -- правая сторона большого треугольника вершиной вниз
    drawVecLine(line3) 
    -- левая сторона большого треугольника вершиной вниз
    drawVecLine(line4) 
    -- правая сторона большого треугольника вершиной вверх
    drawVecLine(line5) 
    -- левая сторона большого треугольника вершиной вверх
    drawVecLine(line6) 
    -- первая вспомогательная линия до пересечения окружности справа снизу
    drawVecLine(line7) 
    -- первая вспомогательная линия до пересечения окружности слева снизу
    drawVecLine(line8) 
    -- горизонталь второгоо треугольника вершиной вверх
    drawVecLine(line9) 
    -- правая сторона второго треугольника вершиной вверх
    drawVecLine(line10) 
    -- левая сторона второго треугольника вершиной вверх
    drawVecLine(line11) 
    -- вспомогательная линия до пересечения с окружностью слева сверху
    drawVecLine(line12) 
    -- вторая вспомогательная линия до пересечения с окружностью справа сверху
    drawVecLine(line13) 
    -- горизонталь второго треугольника вершиной вниз
    drawVecLine(line14) 

    --lg.setColor{1, 0, 1}
    -- левая сторон треугольника вершиной вверх, не обрезанная
    drawVecLine(line15) 
    -- правая сторона треугольника вершиной вверх, не обрезанная
    drawVecLine(line16)
    -- основание треугольника вершиной вверх, не обрезанное
    drawVecLine(line17)  
    lg.setColor{0, 0, 1}
    drawVecLine(line18)  

    lg.setColor{1, 0, 1}
    if p5 then
        lg.circle("fill", p5.x, p5.y, 3)
    end
    if p6 then
        lg.circle("fill", p6.x, p6.y, 3)
    end
    if p7 then
        lg.circle("fill", p7.x, p7.y, 3)
    end
    if p8 then
        lg.circle("fill", p8.x, p8.y, 3)
    end
    if p9 then
        lg.circle("fill", p9.x, p9.y, 3)
    end
    if p10 then
        lg.circle("fill", p10.x, p10.y, 3)
    end
    --lg.setColor{0, 0, 1}
    if p11 then
        lg.circle("fill", p11.x, p11.y, 3)
    end
    if p12 then
        lg.circle("fill", p12.x, p12.y, 3)
    end
    --lg.setColor{1, 0, 1}
    if p13 then
        lg.circle("fill", p13.x, p14.y, 3)
    end
    if p14 then
        lg.circle("fill", p14.x, p14.y, 3)
    end
    if p15 then
        lg.circle("fill", p15.x, p15.y, 3)
    end
    if p16 then
        lg.circle("fill", p16.x, p16.y, 3)
    end
    if p17 then
        lg.circle("fill", p17.x, p17.y, 3)
    end
    if p20 then
        lg.circle("fill", p20.x, p20.y, 3)
    end
    if p21 then
        lg.circle("fill", p21.x, p21.y, 3)
    end

    linesbuf:pushi("baseLineParam = %d", baseLineParam)
    linesbuf:draw()
end

function love.update(dt)
    linesbuf:update(dt)
end

function love.resize(neww, newh)
    calculate()
end

function love.keypressed(_, key)
    -- переключение режимов экрана
    if love.keyboard.isDown("ralt", "lalt") and key == "return" then
        -- код дерьмовый, но работает
        if screenMode == "fs" then
            love.window.setMode(800, 600, {fullscreen = false})
            screenMode = "win"
            --dispatchWindowResize(love.graphics.getDimensions())
        else
            love.window.setMode(0, 0, {fullscreen = true,
                                       fullscreentype = "exclusive"})
            screenMode = "fs"
            --dispatchWindowResize(love.graphics.getDimensions())
        end
    end
    if key == "escape" then
        love.event.quit()
    elseif key == "up" then
        baseLineParam = baseLineParam + 1
        calculate()
    elseif key == "down" then
        baseLineParam = baseLineParam - 1
        calculate()
    end
end
