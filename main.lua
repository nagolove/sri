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
local sri = require "sri"
local tween = require "tween"
local lines

local w, h = lg.getDimensions()

-- центр построения
local cx, cy
local baseLineParam = 0.1
local circleRad
local vertLine

function love.load()
    resize(w, h)
    --draw4avarana()
    draw5avarana()
end

function love.draw()

    if visible then
        lg.setColor{1, 1, 1, 1}
        lg.draw(canvas)
    end

    --linesbuf:pushi("baseLineParam = %d", baseLineParam)
    linesbuf:draw()
end

function draw5avarana()
    if not lines then
        drawSri2Canvas()
    end
    local triangles = sri.get5avarana(lines)
    print("triangles", inspect(triangles))
    lg.setCanvas(canvas)
    lg.setColor{0.8, 0, 0}
    for _, v in pairs(triangles) do
        lg.polygon("fill", v)
    end
    lg.setCanvas()
end

function draw4avarana()
    if not lines then
        drawSri2Canvas()
    end
    local triangles = sri.get4avarana(lines)
    lg.setCanvas(canvas)
    lg.setColor{0.8, 0, 0}
    for _, v in pairs(triangles) do
        lg.polygon("fill", v)
    end
    lg.setCanvas()
end

function drawSri2Canvas()
    local cx, cy = w / 2, h / 2
    local circleRad = 0.4 * h
    lines = sri.construct(cx, cy, baseLineParam * h, circleRad)
    --print("param", baseLineParam * h)
    --local lines = construct(cx, cy, baseLineParam, circleRad)
    print("cx, cy", cx, cy)
    --print("line", inspect(lines))
    lg.setCanvas(canvas)
    lg.clear()

    bhupur.draw(w / 2, h / 2, h)

    lg.setColor{1, 0, 0}
    for _, v in pairs(lines) do
        for _, l in pairs(v) do
            --print("line", inspect(v))
            lg.line(l[1].x, l[1].y, l[2].x, l[2].y)
        end
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
        baseLineParam = baseLineParam + 0.1
        drawSri2Canvas()
    elseif kb.isDown("down") then
        baseLineParam = baseLineParam - 0.1
        drawSri2Canvas()
    end
end

function resize(neww, newh)
    w, h = neww, newh
    canvas = lg.newCanvas(w, h)
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
    elseif key == "4" then
        draw4avarana()
    elseif key == "5" then
        draw5avarana()
    end
end
