-- [[
-- vim: set foldmethod=manual
-- Общие параметры - диаметр вписанной в квадрат защиты окружности, 
-- ширина квадрата защиты
-- ]]
local inspect = require "inspect"
local linesbuf = require "kons".new()
local bhupur = require "bhupur"
local lg = love.graphics
local canvas = lg.newCanvas()
local visible = true
local construct = require "sri".construct

local w, h = lg.getDimensions()

-- центр построения
local cx, cy
local baseLineParam = 60
local circleRad
local vertLine

function love.load()
    resize(w, h)
end

function love.draw()
    local w, h = lg.getDimensions()
    bhupur.draw(w / 2, h / 2, h)

    if visible then
        lg.setColor{1, 1, 1, 1}
        lg.draw(canvas)
    end

    linesbuf:pushi("baseLineParam = %d", baseLineParam)
    linesbuf:draw()
end

function drawSri2Canvas()
    local cx, cy = w / 2, h / 2
    local circleRad = 0.4 * h
    local lines = construct(cx, cy, baseLineParam, circleRad)
    print("cx, cy", cx, cy)
    --print("line", inspect(lines))
    lg.setCanvas(canvas)
    lg.clear()
    lg.setColor{1, 0, 0}
    for k, v in pairs(lines) do
        --print("line", inspect(v))
        lg.line(v[1].x, v[1].y, v[2].x, v[2].y)
    end

    lg.setColor{0.13, 0.95, 0.1}
    lg.circle("fill", cx, cy, 3)

    lg.setColor{1, 1, 1}
    -- нужно вычислить подходящий радиус окружности автоматически
    lg.circle("line", cx, cy, circleRad)

    lg.setCanvas()
    --canvas:newImageData():encode("png", "canva.png")
end

function love.update(dt)
    linesbuf:update(dt)
    local kb = love.keyboard
    if kb.isDown("up") then
        baseLineParam = baseLineParam + 1
        drawSri2Canvas()
    elseif kb.isDown("down") then
        baseLineParam = baseLineParam - 1
        drawSri2Canvas()
    end
end

function resize(neww, newh)
    w, h = neww, newh
    drawSri2Canvas()
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
    end
end
