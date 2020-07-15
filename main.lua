-- [[
-- vim: set foldmethod=manual
-- Общие параметры - диаметр вписанной в квадрат защиты окружности, 
-- ширина квадрата защиты
-- ]]
local inspect = require "inspect"
local vector = require "vector"
local linesbuf = require "kons".new()
local bhupur = require "bhupur"
local lg = love.graphics
local sri_lines
local canvas = lg.newCanvas()
local visible = false

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

-- возвращает два или одно значение точек пересечения в виде векторов или nil
-- p1, p2 - начальная точка(вектор) и конечная
-- center - вектор центра окружности
-- rad - радиус окружности
-- источник: http://csharphelper.com/blog/2014/09/determine-where-a-line-intersects-a-circle-in-c/
function intersectionWithCircle(p1, p2, center, rad)
    local dx, dy = p2.x - p1.x, p2.y - p1.y
    local a = dx * dx + dy * dy;
    local b = 2 * (dx * (p1.x - center.x) + dy * (p1.y - center.y));
    local c = (p1.x - center.x) * (p1.x - center.x) + 
        (p1.y - center.y) * (p1.y - center.y) - rad * rad;

    local t
    local det = b * b - 4 * a * c

    --if ((a <= 0.0000001) || (det < 0))
    if a <= 0.0001 or det < 0 then
        return nil
    -- проверь, может быть равен нулю? Или сделать сравнение?
    elseif det == 0 then 
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
    if not p1 then return end

    if p1 and not p2 and type(p1) == "table" then
        lg.line(p1[1].x, p1[1].y, p1[2].x, p1[2].y)
    elseif p1 and p2 then
        lg.line(p1.x, p1.y, p2.x, p2.y)
    end
end

-- эти линии должны соотноситься с центром рисунка
--local line1, line2, line3, line4, line5, line6

local w, h = lg.getDimensions()

-- центр построения
local cx, cy
local baseLineParam = 60
local circleRad
local p1, p2, p3, p4
local vertLine

-- d - расстояние от центра до горизонталей больших треугольников
function setupBaseLines(cx, cy, d)
    -- тут нужно поменять код, что-бы вычисления шли через точки пересечения
    -- окружности и отрезка. Порядок такой:
    -- * поднять точку на сколько нужно пикселей
    -- * пустить отрезок влево до пересечения с окружностью(кидать с запасом
    -- по пикселям)
    -- * найти точку пересечения
    -- * повторить для для правой стороны
    -- * задать линию из точек пересечения

    local upPoint, downPoint = vector(cx, cy - d), vector(cx, cy + d)
    local leftPoint, rightPoint

    leftPoint = upPoint + vector(-1, 0) * circleRad
    rightPoint = upPoint + vector(1, 0) * circleRad

    local p1, p2 = intersectionWithCircle(leftPoint, rightPoint, 
        vector(cx, cy), circleRad)

    leftPoint = downPoint + vector(-1, 0) * circleRad
    rightPoint = downPoint + vector(1, 0) * circleRad

    local p3, p4 = intersectionWithCircle(leftPoint, rightPoint, 
        vector(cx, cy), circleRad)

    line1 = copy{p1, p2}
    line2 = copy{p3, p4}
end

-- d - расстояние от центра до горизонталей больших треугольников
-- d - расстояние от центра до горизонталей больших треугольников
function getBaseLines(cx, cy, d)
    -- тут нужно поменять код, что-бы вычисления шли через точки пересечения
    -- окружности и отрезка. Порядок такой:
    -- * поднять точку на сколько нужно пикселей
    -- * пустить отрезок влево до пересечения с окружностью(кидать с запасом
    -- по пикселям)
    -- * найти точку пересечения
    -- * повторить для для правой стороны
    -- * задать линию из точек пересечения

    local upPoint, downPoint = vector(cx, cy - d), vector(cx, cy + d)
    local leftPoint, rightPoint

    leftPoint = upPoint + vector(-1, 0) * circleRad
    rightPoint = upPoint + vector(1, 0) * circleRad

    local p1, p2 = intersectionWithCircle(leftPoint, rightPoint, 
        vector(cx, cy), circleRad)

    leftPoint = downPoint + vector(-1, 0) * circleRad
    rightPoint = downPoint + vector(1, 0) * circleRad

    local p3, p4 = intersectionWithCircle(leftPoint, rightPoint, 
        vector(cx, cy), circleRad)

    local line1 = copy{p1, p2}
    local line2 = copy{p3, p4}
    return line1, line2
end

function love.load()
    resize(w, h)
end

-- returns array with lines and array with points
function construct()
    ------------------- TESTING ONLY CODE -----------------
    local testCanvas = lg.newCanvas()
    local stageNum = 0
    love.filesystem.createDirectory("stages")

    lg.setCanvas(testCanvas)

    function stageShot(...)
        local args = {...}
        lg.setColor{0, 0, 1}
        for k, v in pairs(args) do
            if v[1] and v[2] then
                lg.line(v[1].x, v[1].y, v[2].x, v[2].y)
            else -- point only
                lg.setColor{0, 0, 0.7}
                lg.circle("fill", v.x, v.y, 3)
            end
        end
        lg.setCanvas()
        print("stageNum", stageNum)
        testCanvas:newImageData():encode("png", "stages/" .. stageNum)
        stageNum = stageNum + 1
        lg.setCanvas(testCanvas)
    end
    ------------------- END TESTING ONLY CODE -----------------

    local result = {}

    local cx, cy = w / 2, h / 2
    local line1, line2 = getBaseLines(cx, cy, baseLineParam)

    stageShot(line1, line2)

    local circleCenter = vector(cx, cy)

    stageShot(circleCenter)

    local vertLine = {vector(cx, cy - circleRad), vector(cx, cy + circleRad)}

    stageShot(vertLine)

    local p1, p2 = intersectionWithCircle(line1[1], line1[2], vector(cx, cy), circleRad)
    local p1, p2 = intersectionWithCircle(line1[1], line1[2], vector(cx, cy), circleRad)
    local p3, p4 = intersectionWithCircle(line2[1], line2[2], vector(cx, cy), circleRad)

    local line3 = copy{p1, vector(cx, cy + circleRad)}
    local line4 = copy{p2, vector(cx, cy + circleRad)}
    local line5 = copy{p3, vector(cx, cy - circleRad)}
    local line6 = copy{p4, vector(cx, cy - circleRad)}

    stageShot(line3) 
    stageShot(line4)
    stageShot(line5)
    stageShot(line6)

    local rline1, rline2, rline3, rline4, rline5, rline6 = copy(line1), copy(line2),
        copy(line3), copy(line4), copy(line5), copy(line6)

    local p5 = intersection(line1[1], line1[2], line6[1], line6[2])
    local p6 = intersection(line1[1], line1[2], line5[1], line5[2])
    local p7 = intersection(line2[1], line2[2], vertLine[1], vertLine[2])

    local dir

    -- 250 - конец отрезка должен выходить за окружность
    dir = (p7 - p5):normalizeInplace() * circleRad
    local line7 = copy({p5, p7 + dir})

    local p8 = intersectionWithCircle(line7[1], line7[2], circleCenter, circleRad)

    -- 250 - конец отрезка должен выходить за окружность
    dir = (p7 - p6):normalizeInplace() * circleRad
    local line8 = copy({p6, p7 + dir})

    local p9 = intersectionWithCircle(line8[1], line8[2], circleCenter, circleRad)
    local p10 = intersection(line1[1], line1[2], vertLine[1], vertLine[2])
    local line9 = copy{p8, p9}

    local line10 = copy{p8, p10}
    local line11 = copy{p9, p10}

    local p11 = intersection(line10[1], line10[2], line3[1], line3[2]) -- правая
    local p12 = intersection(line11[1], line11[2], line4[1], line4[2]) -- левая

    dir = (circleCenter - p11):normalizeInplace() * 440
    local line12 = copy{p11, p11 + dir} -- правая

    dir = (circleCenter - p12):normalizeInplace() * 440
    local line13 = copy{p12, p12 + dir} -- левая

    local p13 = intersectionWithCircle(line12[1], line12[2], circleCenter, circleRad)
    local p14 = intersectionWithCircle(line13[1], line13[2], circleCenter, circleRad)

    -- горизонталь верхнего треугольника направленного вниз
    local line14 = copy{p13, p14} 

    local p15 = intersection(line14[1], line14[2], vertLine[1], vertLine[2])
    local p16 = intersection(line4[1], line4[2], line2[1], line2[2])
    local p17 = intersection(line3[1], line3[2], line2[1], line2[2])

    dir = (p16 - p15):normalizeInplace() * circleRad
    local line15 = copy{p15, p16 + dir}

    dir = (p17 - p15):normalizeInplace() * circleRad
    local line16 = copy{p15, p17 + dir}

    local p18 = p11:clone()
    local p19 = p12:clone()
    dir = (p19 - p18):normalizeInplace() * circleRad
    local p19 = p19 + dir
    dir = (p18 - p19):normalizeInplace() * circleRad
    local p18 = p18 + dir

    -- провести прямую через точки p18 и p19 взятых копией точек p11, p12
    -- вспомогательная прямая, можно не рисовать
    local line17 = copy{p18, p19}

    local p20 = intersection(line17[1], line17[2], line16[1], line16[2])
    local p21 = intersection(line17[1], line17[2], line15[1], line15[2])

    local line18 = copy{p20, p21}

    local p22 = intersection(line15[1], line15[2], line1[1], line1[2])
    local p23 = intersection(line16[1], line16[2], line1[1], line1[2])

    dir = (p22 - p13):normalizeInplace() * 600
    -- вспомогательная линия
    local line19 = copy{p13, p13 + dir} -- правый отрезок

    local p24 = intersection(line19[1], line19[2], vertLine[1], vertLine[2])

    dir = (p23 - p14):normalizeInplace() * 600
    -- вспомогательная линия
    local line20 = copy{p14, p14 + dir} -- левый отрезок

    local p25 = intersection(line20[1], line20[2], vertLine[1], vertLine[2])

    local line21 = copy{p13, p24} -- правая
    local line22 = copy{p14, p25} -- левая

    -- левая точка
    local p26 = intersection(line5[1], line5[2], line22[1], line22[2])
    -- правая точка 
    local p27 = intersection(line6[1], line6[2], line21[1], line21[2])

    local dir1 = (p27 - p26):normalizeInplace() * 150
    local dir2 = (p26 - p27):normalizeInplace() * 150
    line23 = copy{p26 + dir2, p27 + dir1}

    result = {
        line1, line2, line3, line4, line5, line6, line7, line8, line9, line11,
        line12, line13, line14, line15, line16, line17, line18, line19, line20,
        line21, line22, line23,
    }
    return result
end

-- [[
-- Попробуй сделать класс sri, в котором будет метод calculate. Создай в нем
-- еще чистовой набор точек и чистовую функцию рисовки.
-- lineX - внутренняя линия, используется при построении
-- rlineX - линия для чистовой(release) рисовки
-- pX - внутренняя точка
-- rpX - чистовая точка
-- ]]
function calculate()
    cx, cy = w / 2, h / 2
    --setupBaseLines(cx, cy, baseLineParam)
    line1, line2 = getBaseLines(cx, cy, baseLineParam)

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

    rline1, rline2, rline3, rline4, rline5, rline6 = copy(line1), copy(line2),
        copy(line3), copy(line4), copy(line5), copy(line6)

    p5 = intersection(line1[1], line1[2], line6[1], line6[2])
    p6 = intersection(line1[1], line1[2], line5[1], line5[2])

    p7 = intersection(line2[1], line2[2], vertLine[1], vertLine[2])

    local dir

    -- 250 - конец отрезка должен выходить за окружность
    dir = (p7 - p5):normalizeInplace() * circleRad
    line7 = copy({p5, p7 + dir})

    p8 = intersectionWithCircle(line7[1], line7[2], circleCenter, circleRad)

    -- 250 - конец отрезка должен выходить за окружность
    dir = (p7 - p6):normalizeInplace() * circleRad
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

    dir = (p16 - p15):normalizeInplace() * circleRad
    line15 = copy{p15, p16 + dir}

    dir = (p17 - p15):normalizeInplace() * circleRad
    line16 = copy{p15, p17 + dir}

    p18 = p11:clone()
    p19 = p12:clone()
    dir = (p19 - p18):normalizeInplace() * circleRad
    p19 = p19 + dir
    dir = (p18 - p19):normalizeInplace() * circleRad
    p18 = p18 + dir

    -- провести прямую через точки p18 и p19 взятых копией точек p11, p12
    -- вспомогательная прямая, можно не рисовать
    line17 = copy{p18, p19}

    p20 = intersection(line17[1], line17[2], line16[1], line16[2])
    p21 = intersection(line17[1], line17[2], line15[1], line15[2])

    line18 = copy{p20, p21}

    p22 = intersection(line15[1], line15[2], line1[1], line1[2])
    p23 = intersection(line16[1], line16[2], line1[1], line1[2])

    dir = (p22 - p13):normalizeInplace() * 600
    -- вспомогательная линия
    line19 = copy{p13, p13 + dir} -- правый отрезок

    p24 = intersection(line19[1], line19[2], vertLine[1], vertLine[2])

    dir = (p23 - p14):normalizeInplace() * 600
    -- вспомогательная линия
    line20 = copy{p14, p14 + dir} -- левый отрезок

    p25 = intersection(line20[1], line20[2], vertLine[1], vertLine[2])

    line21 = copy{p13, p24} -- правая
    line22 = copy{p14, p25} -- левая

    -- левая точка
    p26 = intersection(line5[1], line5[2], line22[1], line22[2])
    -- правая точка 
    p27 = intersection(line6[1], line6[2], line21[1], line21[2])

    local dir1 = (p27 - p26):normalizeInplace() * 150
    local dir2 = (p26 - p27):normalizeInplace() * 150
    line23 = copy{p26 + dir2, p27 + dir1}
end

function drawPoint(point)
    if point then
        lg.circle("fill", point.x, point.y, 3)
    end
end

function draw_lines(lines)
    if lines then
        for k, line in ipairs(lines) do
            drawVecLine(line)
        end
    end
end

function drawDebug()
    drawVecLine(vertLine)
    -- горизонталь большого треугольника вершиной вниз
    drawVecLine(line1) 
    -- горизонталь большого треугольника вершиной вверх
    drawVecLine(line2) 
    -- правая сторона большого треугольника вершиной вниз
    drawVecLine(line3) 
    -- левая сторона большого треугольника вершиной вниз
    drawVecLine(line4) 
    -- левая сторона большого треугольника вершиной вверх
    drawVecLine(line5) 
    -- правая сторона большого треугольника вершиной вверх
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
    drawVecLine(line18)  

    --drawVecLine(line19)
    --drawVecLine(line20)

    -- правая строна треугольника с вершиной вниз
    drawVecLine(line21)
    -- левая сторона треугольника с вершиной вниз
    drawVecLine(line22)

    lg.setColor{0, 1, 0}
    drawVecLine(line23)
    
    lg.setColor{1, 0, 1}

    for i = 1, 27 do
        local point = _G["p" .. i]
        if point then drawPoint(point) end
    end
end

function draw()
    lg.setColor{0, 0.7, 0}
    for i = 1, 10 do
        local line = _G["rline" .. i]
        if line then
            drawVecLine(line)
        end
    end
end

local releaseMode = true
local newMode = false

function love.draw()
    local w, h = lg.getDimensions()
    bhupur.draw(w / 2, h / 2, h)

    lg.setColor{0.13, 0.95, 0.1}
    lg.circle("fill", cx, cy, 3)

    lg.setColor{1, 1, 1}
    -- нужно вычислить подходящий радиус окружности автоматически
    lg.circle("line", cx, cy, circleRad)

    if new_mode then
        draw_lines(lines)
    else
        if releaseMode then
            draw()
        else
            drawDebug()
        end
    end

    if visible then
        lg.setColor{1, 1, 1, 1}
        lg.draw(canvas)
    end

    linesbuf:pushi("baseLineParam = %d", baseLineParam)
    linesbuf:draw()
end

function love.update(dt)
    linesbuf:update(dt)
    local kb = love.keyboard
    if kb.isDown("up") then
        baseLineParam = baseLineParam + 1
        calculate()
    elseif kb.isDown("down") then
        baseLineParam = baseLineParam - 1
        calculate()
    end
end

function resize(neww, newh)
    w, h = neww, newh
    circleRad = 0.4 * h
    print("circleRad", circleRad)
    calculate()
end

function love.keypressed(_, key)
    -- переключение режимов экрана
    if love.keyboard.isDown("ralt", "lalt") and key == "return" then
        -- код дерьмовый, но работает
        if screenMode == "fs" then
            love.window.setMode(800, 600, {fullscreen = false})
            screenMode = "win"
            resize(love.graphics.getDimensions())
        else
            love.window.setMode(0, 0, {fullscreen = true,
                                       fullscreentype = "exclusive"})
            screenMode = "fs"
            resize(love.graphics.getDimensions())
        end
    end
    if key == "escape" then
        love.event.quit()
    elseif key == "r" then
        releaseMode = not releaseMode
    elseif key == "n" then
        new_mode = not new_mode
    elseif key == "q" then
        visible = not visible
        if visible then
            local lines = construct()
            lg.setCanvas(canvas)
            lg.clear()
            lg.setColor{1, 0, 0}
            for k, v in pairs(lines) do
                print("line", inspect(v))
                lg.line(v[1].x, v[1].y, v[2].x, v[2].y)
            end
            lg.setCanvas()
            canvas:newImageData():encode("png", "canva.png")
        end
    end
end
