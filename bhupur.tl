local lg = love.graphics

require "common"

local bhupur = {
    color = {1, 1, 1},
    foot = 0.8,
    neck = 0.5,
    height = 30,
}

--local function pack(...)
    --return {...}
--end

--function copy(t)
    --local result = {}
    --for k, v in pairs(t) do
        --result[k] = v
    --end
    --return result
--end

-- расчет ширины картинки по ширине квадрата
function bhupur.getWidth(w)
    return (w - bhupur.neck * w) / 2
end

function scalePoints(points)
    points[1] = points[1] + 1
    points[2] = points[2] + 1

    points[3] = points[3] + 1 --+ 1
    points[4] = points[4] + 1

    points[5] = points[5] + 1 --+ 1
    points[6] = points[6] - 1

    points[7] = points[7] + 1
    points[8] = points[8] - 1

    points[9] = points[9] + 1
    points[10] = points[10] + 1

    points[11] = points[11] - 1
    points[12] = points[12] + 1

    points[13] = points[13] - 1
    points[14] = points[14] - 1

    points[15] = points[15] - 1
    points[16] = points[16] - 1

    points[17] = points[17] - 1
    points[18] = points[18] + 1

    points[19] = points[19] - 1
    points[20] = points[20] + 1
end

function drawParts(points, xcenter, ycenter, w, y)
    lg.line(points)

    lg.translate(xcenter, y)
    lg.rotate(math.pi / 1)
    lg.translate(-xcenter, -y - w)
    lg.line(points)
    lg.origin()
    
    lg.translate(xcenter, y)
    lg.rotate(math.pi + math.pi / 2)
    lg.translate(-xcenter - w / 2, -y - w / 2)
    lg.line(points)
    lg.origin()
    
    lg.translate(xcenter, y / 1)
    lg.rotate(math.pi - math.pi / 2)
    lg.translate(-xcenter + w / 2, -y - w / 2)
    lg.line(points)
    lg.origin()
end

function bhupur.draw(x, y, w)
    local height = bhupur.height
    w = w - height * 2
    x = x - w / 2
    y = y - w / 2

    -- width - size in pixels of square in center on bhupur
    -- neck - percentage value(0-1) of yantrawidth
    -- foot - percentage value(0-1) of yantrawidth
    -- height - size in pixels on bhupur
    local foot = bhupur.foot * w
    local neck = bhupur.neck * w
    local stair = math.abs((w - neck - foot) / 2)
    local tmp = (w - neck) / 2

    -- с какого угла начинается рисование?
    local points = {
        x, y,
        x + tmp, y,                                 -- направо
        x + tmp, y - height / 2,                    -- вверх
        x + tmp - stair, y - height / 2,            -- налево
        x + tmp - stair, y - height,                -- вверх
        x + tmp - stair + foot, y - height,         -- направо
        x + tmp - stair + foot, y - height / 2,     -- вниз
        x + tmp - stair * 2 + foot, y - height / 2, -- налево
        x + tmp - stair * 2 + foot, y,              -- вниз
        x + w, y,                                   -- направо
    }
    local points2 = shallowCopy(points)

    scalePoints(points2)
    scalePoints(points2)
    scalePoints(points2)

    local points3 = shallowCopy(points2)

    scalePoints(points3)
    scalePoints(points3)
    scalePoints(points3)

    local old = pack(lg.getColor())

    local xcenter = x + w / 2
    local ycenter = y + w / 2

    lg.setColor{0, 0, 0}
    drawParts(points, xcenter, ycenter, w, y)

    lg.setColor{1, 0, 0}
    drawParts(points2, xcenter, ycenter, w, y)

    lg.setColor{1, 1, 1}
    drawParts(points3, xcenter, ycenter, w, y)

    lg.setColor(old)
    lg.setLineWidth(1)
end

return bhupur
