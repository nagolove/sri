__DEBUG__ = true

local vector = require "vector"
local isvector = vector.isvector
local inspect = require "inspect"

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

function intersection2(line1, line2)
    return intersection(line1[1], line1[2], line2[1], line2[2])
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

-- d - расстояние от центра до горизонталей больших треугольников
function getBaseLines(cx, cy, d, circleRad)
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


if __DEBUG__ then
    testCanvas = love.graphics.newCanvas()
    stageNum = 1

    love.filesystem.createDirectory("stages")

    for _, v in pairs(love.filesystem.getDirectoryItems("stages")) do
        love.filesystem.remove("stages/" .. v)
    end

    love.graphics.setCanvas(testCanvas)
end

function stageShot(...)
    local lg = love.graphics
    local prevPoint
    local args = {...}
    local r, g, b
    for k, v in pairs(args) do
        if type(v) == "string" then

            r, g, b = v:match("%((.+),(.+),(.+)%)")

            lg.setColor{0, 0, 0}
            if prevPoint then
                lg.print(v, prevPoint[1], prevPoint[2])
            else
                lg.print(v)
            end

        elseif v[1] and v[2] then -- line
            if r and b and b then
                lg.setColor(r, g, b)
            else
                lg.setColor{0, 0, 1}
            end
            lg.line(v[1].x, v[1].y, v[2].x, v[2].y)
            prevPoint = { v[2].x, v[2].y }
        else -- point only
            if r and b and b then
                lg.setColor(r, g, b)
            else
                lg.setColor{0, 0, 1}
            end
            lg.setColor{0, 0, 0.7}
            lg.circle("fill", v.x, v.y, 3)
            prevPoint = { v.x, v.y }
        end
    end
    lg.setCanvas()
    print("stageNum", stageNum)
    testCanvas:newImageData():encode("png", "stages/" .. stageNum)
    stageNum = stageNum + 1
    lg.setCanvas(testCanvas)
end

if not __DEBUG__ then
    stageShot = function() end
end

function construct(cx, cy, baseLineParam, circleRad)
    local __stageShot = stageShot
    stageShot = function() end

    --local cx, cy = w / 2, h / 2
    baseLineParam = math.ceil(baseLineParam)
    print("construct", cx, cy, baseLineParam, circleRad)
    local line_tri1_top, line_tri2_bottom = getBaseLines(cx, cy, baseLineParam, circleRad)

    --lg.setColor{0, 0, 0}
    --lg.circle("line", cx, cy, circleRad)

    stageShot(line_tri1_top)
    stageShot(line_tri2_bottom)

    local circleCenter = vector(cx, cy)

    stageShot(circleCenter)

    local vertLine = {vector(cx, cy - circleRad), vector(cx, cy + circleRad)}

    stageShot(vertLine)

    local p1, p2 = intersectionWithCircle(line_tri1_top[1], line_tri1_top[2], vector(cx, cy), circleRad)
    local p3, p4 = intersectionWithCircle(line_tri2_bottom[1], line_tri2_bottom[2], vector(cx, cy), circleRad)

    local line_tri1_left = copy{p1, vector(cx, cy + circleRad)}
    local line_tri1_right = copy{p2, vector(cx, cy + circleRad)}
    local line_tri2_left = copy{p3, vector(cx, cy - circleRad)}
    local line_tri2_right = copy{p4, vector(cx, cy - circleRad)}

    stageShot(line_tri1_left) 
    stageShot(line_tri1_right)
    stageShot(line_tri2_left)
    stageShot(line_tri2_right)

    --local rline1, rline2, rline3, rline4, rline5, rline6 = copy(line_tri1_top), copy(line2),
        --copy(line_tri1_left), copy(line_tri1_right), copy(line_tri2_left), copy(line_tri2_right)

    local p5 = intersection(line_tri1_top[1], line_tri1_top[2], line_tri2_right[1], line_tri2_right[2])
    local p6 = intersection(line_tri1_top[1], line_tri1_top[2], line_tri2_left[1], line_tri2_left[2])
    local p7 = intersection(line_tri2_bottom[1], line_tri2_bottom[2], vertLine[1], vertLine[2])

    stageShot(p5, p6, p7)

    local dir

    -- 250 - конец отрезка должен выходить за окружность
    dir = (p7 - p5):normalizeInplace() * circleRad
    local line7 = copy({p5, p7 + dir})

    stageShot(line7, "line7") -- auxiliary_1

    local p8 = intersectionWithCircle(line7[1], line7[2], circleCenter, circleRad)

    -- 250 - конец отрезка должен выходить за окружность
    dir = (p7 - p6):normalizeInplace() * circleRad
    local line8 = copy({p6, p7 + dir})

    stageShot(line8, "line8")

    local p9 = intersectionWithCircle(line8[1], line8[2], circleCenter, circleRad)
    local p10 = intersection(line_tri1_top[1], line_tri1_top[2], vertLine[1], vertLine[2])
    local line_tri3_bottom = copy{p8, p9}

    stageShot(line_tri3_bottom, "line_tri3_bottom")

    local line_tri3_left = copy{p8, p10}
    local line_tri3_right = copy{p9, p10}

    stageShot(line_tri3_left)
    stageShot(line_tri3_right)

    local p11 = intersection(line_tri3_left[1], line_tri3_left[2], line_tri1_left[1], line_tri1_left[2]) -- правая
    local p12 = intersection(line_tri3_right[1], line_tri3_right[2], line_tri1_right[1], line_tri1_right[2]) -- левая

    dir = (circleCenter - p11):normalizeInplace() * 440
    local line12 = copy{p11, p11 + dir} -- правая

    --stageShot(line12)

    dir = (circleCenter - p12):normalizeInplace() * 440
    local line13 = copy{p12, p12 + dir} -- левая

    --stageShot(line13)

    local p13 = intersectionWithCircle(line12[1], line12[2], circleCenter, circleRad)
    local p14 = intersectionWithCircle(line13[1], line13[2], circleCenter, circleRad)

    stageShot(p13, p14)

    -- горизонталь верхнего треугольника направленного вниз
    local line_tri4_top = copy{p13, p14} 

    stageShot(line_tri4_top, "line_tri4_top")

    local p15 = intersection(line_tri4_top[1], line_tri4_top[2], vertLine[1], vertLine[2])
    local p16 = intersection(line_tri1_right[1], line_tri1_right[2], line_tri2_bottom[1], line_tri2_bottom[2])
    local p17 = intersection(line_tri1_left[1], line_tri1_left[2], line_tri2_bottom[1], line_tri2_bottom[2])

    dir = (p16 - p15):normalizeInplace() * circleRad
    local line15 = copy{p15, p16 + dir}

    --stageShot(line15, "line15")

    dir = (p17 - p15):normalizeInplace() * circleRad
    local line16 = copy{p15, p17 + dir}

    --stageShot(line16, "line16")

    local p18 = p11:clone()
    local p19 = p12:clone()
    dir = (p19 - p18):normalizeInplace() * circleRad
    local p19 = p19 + dir
    dir = (p18 - p19):normalizeInplace() * circleRad
    local p18 = p18 + dir

    --stageShot(p18)

    -- провести прямую через точки p18 и p19 взятых копией точек p11, p12
    -- вспомогательная прямая, можно не рисовать
    local line17 = copy{p18, p19}

    --stageShot(line17, "line17")

    local p20 = intersection(line17[1], line17[2], line16[1], line16[2])
    local p21 = intersection(line17[1], line17[2], line15[1], line15[2])

    local line_tri5_bottom = copy{p20, p21}
    local line_tri5_left = copy{ line16[1], line_tri5_bottom[1] }
    local line_tri5_right = copy{ line16[1], line_tri5_bottom[2] }

    stageShot("(1,0,1)", line_tri5_bottom, "line_tri5_bottom")
    stageShot("(1,0,1)", line_tri5_left, "line_tri5_left")
    stageShot("(1,0,1)", line_tri5_right, "line_tri5_right")

    local p22 = intersection(line15[1], line15[2], line_tri1_top[1], line_tri1_top[2])
    local p23 = intersection(line16[1], line16[2], line_tri1_top[1], line_tri1_top[2])

    -- вспомогательная линия
    dir = (p22 - p13):normalizeInplace() * 600
    local line19 = copy{p13, p13 + dir} -- правый отрезок

    --stageShot(line19, "line19")

    local p24 = intersection(line19[1], line19[2], vertLine[1], vertLine[2])

    stageShot(p24, "p24")

    -- вспомогательная линия
    dir = (p23 - p14):normalizeInplace() * 600
    local line20 = copy{p14, p14 + dir} -- левый отрезок

    --stageShot(line20, "line20")

    local p25 = intersection(line20[1], line20[2], vertLine[1], vertLine[2])

    stageShot("(0,1,0)", p25, "p25")

    local line_tri4_right = copy{p13, p24} -- правая
    local line_tri4_left = copy{p14, p25} -- левая

    stageShot("(0,1,0)", line_tri4_right, "line_tri4_right")
    stageShot("(0,1,0)", line_tri4_left, "line_tri4_left")

    -- левая точка
    local p26 = intersection(line_tri2_left[1], line_tri2_left[2], line_tri4_left[1], line_tri4_left[2])
    -- правая точка 
    local p27 = intersection(line_tri2_right[1], line_tri2_right[2], line_tri4_right[1], line_tri4_right[2])

    local dir1 = (p27 - p26):normalizeInplace() * 550
    local dir2 = (p26 - p27):normalizeInplace() * 550
    local line23 = copy{p26 + dir2, p27 + dir1}

    stageShot(line23, "line23")

    local p28 = intersection(line_tri3_bottom[1], line_tri3_bottom[2],
        vertLine[1], vertLine[2])

    stageShot(p28, "p28")

    local p29 = intersection(line_tri3_left[1], line_tri3_left[2],
        line_tri2_bottom[1], line_tri2_bottom[2])
    local p30 = intersection(line_tri3_right[1], line_tri3_right[2],
        line_tri2_bottom[1], line_tri2_bottom[2])

    stageShot(p29, "p29")
    stageShot(p30, "p30")

    local dir_left = (p29 - p28):normalizeInplace() * 750
    local dir_right = (p30 - p28):normalizeInplace() * 750
    local line24 = copy{p28, p28 + dir_left}
    local line25 = copy{p28, p28 + dir_right}

    stageShot(line24, "line24")
    stageShot(line25, "line25")

    local p31 = intersection(line23[1], line23[2], line24[1], line24[2])
    local p32 = intersection(line23[1], line23[2], line25[1], line25[2])

    stageShot(p31, "p31")
    stageShot(p32, "p32")

    local line_tri6_top = copy{p31, p32}
    local line_tri6_left = copy{p28, p31}
    local line_tri6_right = copy{p28, p32}

    stageShot("(0,1,0)", line_tri6_top, "line_tri6_top")
    stageShot("(0,1,0)", line_tri6_left, "line_tri6_left")
    stageShot("(0,1,0)", line_tri6_right, "line_tri6_right")

    local p33 = line_tri4_right[2]

    stageShot("(1,0,0)", p33, "p33")

    local line26 = copy{p33, vector(p33.x - 1000, p33.y)}
    local line27 = copy{p33, vector(p33.x + 1000, p33.y)}

    local p34 = intersection(line26[1], line26[2], line_tri6_left[1], line_tri6_left[2])
    local p35 = intersection(line27[1], line27[2], line_tri6_right[1], line_tri6_right[2])
    local line_tri7_bottom = copy{p34, p35}

    --stageShot(line26, "line26")
    --stageShot(line27, "line27")

    --stageShot(p34, "p34")
    --stageShot(p35, "p35")
    local p36 = intersection(vertLine[1], vertLine[2], line_tri6_top[1], line_tri6_top[2])
    
    --stageShot(line_tri7_bottom, "line_tri7_bottom")
    --stageShot(p36, "p36")

    local line_tri7_left = copy{p34, p36}
    local line_tri7_right = copy{p35, p36}

    stageShot(line_tri7_left, "line_tri7_left")
    stageShot(line_tri7_right, "line_tri7_right")

    local p37 = intersection(line_tri7_left[1], line_tri7_left[2], line_tri4_left[1], line_tri4_left[2])
    local p38 = intersection(line_tri7_right[1], line_tri7_right[2], line_tri4_right[1], line_tri4_right[2])

    stageShot(p37, "p37")
    stageShot(p38, "p38")

    local line_tri8_top = copy{p37, p38}
    local p39 = intersection(vertLine[1], vertLine[2], line_tri5_bottom[1], line_tri5_bottom[2])
    local line_tri8_left = copy{p37, p39}
    local line_tri8_right = copy{p38, p39}

    stageShot(line_tri8_top, "line_tri8_top")
    stageShot(line_tri8_left, "line_tri8_left")
    stageShot(line_tri8_right, "line_tri8_right")

    local p40 = intersection(line_tri3_left[1], line_tri3_left[2],
        line_tri4_left[1], line_tri4_left[2])
    local p41 = intersection(line_tri3_right[1], line_tri3_right[2],
        line_tri4_right[1], line_tri4_right[2])

    stageShot(p40, "p40")
    stageShot(p41, "p41")

    local dir1 = (p40 - p41):normalizeInplace() * 300
    local dir2 = (p41 - p40):normalizeInplace() * 300
    local line28 = copy{p40, p40 + dir1}
    local line29 = copy{p41, p41 + dir2}

    local p42 = intersection(line28[1], line28[2], line_tri8_left[1], line_tri8_right[2])
    local p43 = intersection(line29[1], line29[2], line_tri8_right[1], line_tri8_right[2])

    stageShot(line28, "line28")
    stageShot(line29, "line29")

    stageShot(p42, "p42")
    stageShot(p43, "p43")

    local p44 = intersection(vertLine[1], vertLine[2], line_tri2_bottom[1], line_tri2_bottom[2])

    stageShot(p44, "p44")

    local line_tri9_left = copy{p42, p44}
    local line_tri9_right = copy{p43, p44}
    local line_tri9_top = copy{p42, p43}

    stageShot(line_tri9_left, line_tri9_right, line_tri9_top)

    stageShot = __stageShot

    return {
        { line_tri1_top,    line_tri1_left, line_tri1_right },
        { line_tri2_bottom, line_tri2_left, line_tri2_right },
        { line_tri3_bottom, line_tri3_left, line_tri3_right },
        { line_tri4_top,    line_tri4_left, line_tri4_right, },
        { line_tri5_bottom, line_tri5_left, line_tri5_right, },
        { line_tri6_top,    line_tri6_left, line_tri6_right, },
        { line_tri7_bottom, line_tri7_left, line_tri7_right },
        { line_tri8_top,    line_tri8_left, line_tri8_right, },
        { line_tri9_top,    line_tri9_left, line_tri9_right },
    }
end

-- see avarana4.jpg for numerating scheme
function get4avarana(lines)
    local triangles = {}
    local p1, p2, p3

    function addTriangle(p1, p2, p3)
        local tri = {}
        table.insert(tri, p1.x)
        table.insert(tri, p1.y)
        table.insert(tri, p2.x)
        table.insert(tri, p2.y)
        table.insert(tri, p3.x)
        table.insert(tri, p3.y)
        table.insert(triangles, tri)
    end

    p1 = intersection2(lines[2][2], lines[1][2])
    p2 = intersection2(lines[2][1], lines[1][2])
    p3 = vector(lines[2][2][1].x, lines[2][2][1].y)
    addTriangle(p1, p2, p3)

    p1 = intersection2(lines[1][2], lines[5][2])
    p2 = intersection2(lines[1][2], lines[5][1])
    p3 = vector(lines[5][1][1].x, lines[5][1][1].y)
    addTriangle(p1, p2, p3)

    p1 = intersection2(lines[3][2], lines[1][2])
    p2 = intersection2(lines[3][1], lines[1][2])
    p3 = vector(lines[3][1][1].x, lines[3][1][1].y)
    addTriangle(p1, p2, p3)

    p1 = intersection2(lines[3][1], lines[1][2])
    p2 = intersection2(lines[3][1], lines[1][3])
    p3 = vector(lines[1][2][2].x, lines[1][2][2].y)
    addTriangle(p1, p2, p3)

    p1 = intersection2(lines[1][3], lines[3][1])
    p2 = intersection2(lines[1][3], lines[3][3])
    p3 = vector(lines[3][1][2].x, lines[3][1][2].y)
    addTriangle(p1, p2, p3)

    p1 = intersection2(lines[1][3], lines[5][1])
    p2 = intersection2(lines[1][3], lines[5][3])
    p3 = vector(lines[5][1][2].x, lines[5][1][2].y)
    addTriangle(p1, p2, p3)

    p1 = intersection2(lines[1][3], lines[2][1])
    p2 = intersection2(lines[1][3], lines[2][3])
    p3 = vector(lines[2][1][1].x, lines[2][1][1].y)
    addTriangle(p1, p2, p3)

    p1 = intersection2(lines[2][3], lines[1][1])
    p2 = intersection2(lines[2][3], lines[1][3])
    p3 = vector(lines[1][1][1].x, lines[1][1][1].y)
    addTriangle(p1, p2, p3)

    p1 = intersection2(lines[2][3], lines[6][1])
    p2 = intersection2(lines[2][3], lines[6][3])
    p3 = vector(lines[6][1][2].x, lines[6][1][2].y)
    addTriangle(p1, p2, p3)

    p1 = intersection2(lines[2][3], lines[4][1])
    p2 = intersection2(lines[2][3], lines[4][3])
    p3 = vector(lines[4][1][1].x, lines[4][1][1].y)
    addTriangle(p1, p2, p3)

    p1 = intersection2(lines[2][2], lines[4][1])
    p2 = intersection2(lines[2][3], lines[4][1])
    p3 = vector(lines[2][2][2].x, lines[2][2][2].y)
    addTriangle(p1, p2, p3)

    p1 = intersection2(lines[2][2], lines[4][1])
    p2 = intersection2(lines[2][2], lines[4][2])
    p3 = vector(lines[4][2][1].x, lines[4][2][1].y)
    addTriangle(p1, p2, p3)

    p1 = intersection2(lines[2][2], lines[6][1])
    p2 = intersection2(lines[2][2], lines[6][2])
    p3 = vector(lines[6][1][1].x, lines[6][1][1].y)
    addTriangle(p1, p2, p3)

    p1 = intersection2(lines[2][2], lines[1][1])
    p2 = intersection2(lines[2][2], lines[1][2])
    p3 = vector(lines[1][1][2].x, lines[1][1][2].y)
    addTriangle(p1, p2, p3)

    return triangles
end

return {
    construct = construct,
    get4avarana = get4avarana,
}
