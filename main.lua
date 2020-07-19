-- [[
-- vim: set foldmethod=manual
-- Общие параметры - диаметр вписанной в квадрат защиты окружности, 
-- ширина квадрата защиты
-- ]]
require "defines"
local inspect = require "inspect"
local linesbuf = require "kons".new()
local bhupur = require "bhupur"
local lg = love.graphics

local canvas = lg.newCanvas()
local touchCanvas = lg.newCanvas()

local visible = true
local sri = require "sri"
local tween = require "tween"
local lines

local w, h = lg.getDimensions()

-- центр построения
local cx, cy
local baseLineParam = 0.1
local circleRad

local ratio = 1 / 100

function love.load()
    resize(w, h)
    --drawAvarana(5)
end

function love.draw()

    if visible then
        lg.setColor{1, 1, 1, 1}
        lg.draw(canvas)
    end

    lg.draw(touchCanvas)

    linesbuf:pushi("baseLineParam = %d", baseLineParam)
    if baseLine then
        linesbuf:pushi("baseLine = %d", baseLine)
    end
    --linesbuf:pushi("baseLineRatio = %d", baseLineRatio)
    linesbuf:draw()
end

function drawAvarana(num)
    if num == 4 or num == 5 then
        if not lines then
            drawSri2Canvas()
        end
        local funcName = "get" .. num .. "avarana"
        local triangles = sri[funcName](lines)
        lg.setCanvas(canvas)
        lg.setColor{0.8, 0, 0}
        for _, v in pairs(triangles) do
            lg.polygon("fill", v)
        end
        lg.setCanvas()
    end
end

function drawSri2Canvas()
    local cx, cy = w / 2, h / 2
    local circleRad = 0.4 * h

    --baseLineRatio = h / baseLineParam
    baseLine = h / baseLineParam * ratio
    print(baseLine)
    lines = construct(cx, cy, baseLine, circleRad)

    lg.setCanvas(canvas)
    lg.clear()

    bhupur.draw(w / 2, h / 2, h)

    lg.setColor{1, 0, 0}
    for _, v in pairs(lines) do
        for _, l in pairs(v) do
            lg.line(l[1].x, l[1].y, l[2].x, l[2].y)
        end
    end

    lg.setColor{0.13, 0.95, 0.1}
    lg.circle("fill", cx, cy, 3)

    lg.setColor{1, 1, 1}
    lg.circle("line", cx, cy, circleRad)

    lg.setCanvas()
    --canvas:newImageData():encode("png", "canva.png")
end

function love.update(dt)
    linesbuf:update(dt)
    local kb = love.keyboard
    if kb.isDown("up") then
        baseLineParam = baseLineParam + 0.1 * dt
        drawSri2Canvas()
        drawAvarana(4)
        drawAvarana(5)
    elseif kb.isDown("down") then
        baseLineParam = baseLineParam - 0.1 * dt
        drawSri2Canvas()
        drawAvarana(4)
        drawAvarana(5)
    end
end

function resize(neww, newh)
    w, h = neww, newh
    canvas = lg.newCanvas(w, h)
    drawSri2Canvas()
    drawAvarana(4)
    drawAvarana(5)
end

if love.system.getOS() ~= "Android" then

    function love.keypressed(_, key)
        -- переключение режимов экрана
        if love.system.getOS() ~= "Android" then
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
        end
        if key == "escape" then
            love.event.quit()
        end
    end

end

if love.system.getOS() == "Android" then
    function drawTouchPresses(x, y)
        lg.setCanvas(touchCanvas)
        lg.setColor{0.5, 0.5, 0.5}
        lg.circle("fill", x, y, 5)
        lg.setCanvas()
    end

    love.touchmoved = function(id, x, y, dx, dy)
        dy = dy / 10
        --print("dy", dy)
        local h = lg.getHeight()
        if baseLineParam + dy > 0 and baseLineParam + dy < h / 2 then
            baseLineParam = baseLineParam + dy
        end
        drawSri2Canvas()
        print(type(x), type(y))
        drawTouchPresses(x, y)
    end
end

