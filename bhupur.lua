local lg = love.graphics

local bhupur = {
    color = {1, 1, 1},
    foot = 0.8,
    neck = 0.5,
    height = 30,
    -- после первого вызова draw хранит координаты центра квадрата в полях x, y
    center = {} 
}

local function pack(...)
    return {...}
end

-- расчет ширины картинки по ширине квадрата
function bhupur.getWidth(w)
    return (w - bhupur.neck * w) / 2
end

-- должны задаваться координаты центра, а не левого верхнего угла
function bhupur.draw(x, y, w)
    -- width - size in pixels of square in center on bhupur
    -- neck - percentage value(0-1) of yantrawidth
    -- foot - percentage value(0-1) of yantrawidth
    -- height - size in pixels on bhupur
    local height = bhupur.height
    local foot = bhupur.foot * w
    local neck = bhupur.neck * w
    local stair = math.abs((w - neck - foot) / 2)
    local tmp = (w - neck) / 2

    lg.setColor{0, 1, 1}
    lg.rectangle("line", x, y, w, w)
    lg.rectangle("line", x, y, w + height / 1, w)

    -- с какого угла начинается рисование?
    local points = {
        x, y,
        x + tmp, y,
        x + tmp, y - height / 2,
        x + tmp - stair, y - height / 2, --
        x + tmp - stair, y - height,
        x + tmp - stair + foot, y - height, --
        x + tmp - stair + foot, y - height / 2,
        x + tmp - stair * 2 + foot, y - height / 2,
        x + tmp - stair * 2 + foot, y,
        x + w, y,
    }
    local old = pack(lg.getColor())
    lg.setColor(bhupur.color)
    lg.setLineWidth(2)

    lg.line(points)

    local xcenter = x + w / 2
    local ycenter = y + w / 2

    bhupur.center.x, bhupur.center.y = xcenter, ycenter

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

    lg.setColor(old)
    lg.setLineWidth(1)
    
    local function centralAxis()
        local scrw, scrh = lg.getDimensions()
        lg.setColor({100, 100, 100})
        lg.line(scrw / 2, 0, scrw / 2, scrh)
        lg.line(0, scrh / 2, scrw, scrh / 2)
    end

    --centralAxis()
end

function bhupur.draw2(x, y, w)
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
        x + tmp, y,
        x + tmp, y - height / 2,
        x + tmp - stair, y - height / 2, --
        x + tmp - stair, y - height,
        x + tmp - stair + foot, y - height, --
        x + tmp - stair + foot, y - height / 2,
        x + tmp - stair * 2 + foot, y - height / 2,
        x + tmp - stair * 2 + foot, y,
        x + w, y,
    }
    local old = pack(lg.getColor())
    lg.setColor(bhupur.color)
    lg.setLineWidth(2)

    lg.line(points)

    local xcenter = x + w / 2
    local ycenter = y + w / 2

    bhupur.center.x, bhupur.center.y = xcenter, ycenter

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

    lg.setColor(old)
    lg.setLineWidth(1)
    
    local function centralAxis()
        local scrw, scrh = lg.getDimensions()
        lg.setColor({100, 100, 100})
        lg.line(scrw / 2, 0, scrw / 2, scrh)
        lg.line(0, scrh / 2, scrw, scrh / 2)
    end

    --centralAxis()
end

return bhupur
