-- GLOBALS
lg = love.graphics
fs = love.filesystem
kb = love.keyboard
lm = love.mouse
random = math.random
noise = love.math.noise
sin = math.sin
cos = math.cos
floor = math.floor
f = string.format
insert = table.insert
remove = table.remove

colors = {
    {0.1, 0.1, 0.1, 1}, -- BG
    {0.9, 0.9, 0.9, 1}, -- Snake
    {0.1, 0.9, 0.4, 1}, -- Food
    {0.9, 0.2, 0.2, 1} -- red
}

function love.resize(w, h)
    canvas:resize() --Name this to your canvas
    post:addSetting("chromaticAberrationRadius", "position", {lg.getWidth() / 2, lg.getHeight() / 2}) --I would make a function that reloads all of it
end

function love.load()
    -- Loading the various classes
    poster = require("class.poster")
    map = require("class.map")
    snake = require("class.snake")
    smoof = require("class.smoof")
    title = require("class.title")


    -- Loading fonts
    font = {
        large = lg.newFont("font/monogram.ttf", 64),
        small = lg.newFont("font/monogram.ttf", 24)
    }

    -- Text
    text = {
        newgame = title.new("press any key to start", 0, lg.getHeight() + 100, colors[3], nil, font.large),
        shadertip = title.new("Press '1' to toggle shaders", 12, 12, colors[3], "left", font.small),

        gameover = title.new("GAME OVER", 0, -100, colors[4], nil, font.large),
        score = title.new("score", 0, lg.getHeight() * 0.87, colors[3], nil, font.large)
    }

    -- Löve setup
    lg.setBackgroundColor(0.08, 0.08, 0.08)
    useShaders = true

    -- POSTER Setup
    canvas = poster.new() -- The main canvas everything will be drawn to

    -- Bloom chain, This chain just blurs everything, and applies a bit of contrast.
    bloom = poster.newChain({"contrast", "verticalBlur", "horizontalBlur"})
    bloom:addSetting("verticalBlur", "amount", 1)
    bloom:addSetting("horizontalBlur", "amount", 1)
    bloom:addSetting("contrast", "amount", 2)
    bloom:addMacro("amount", {
        {"verticalBlur", "amount", 1},
        {"horizontalBlur", "amount", 1},
    })
    
    bloom:setMacro("amount", 2)

    -- Post chain, This is the "main" post processing chain. Everything + the kitchen sink.
    post = poster.newChain({"chromaticAberrationRadius", "barrelDistortion", "scanlines",
                            "rgbMix", "verticalBlur", "horizontalBlur", "vignette"})
    post:addSetting("chromaticAberrationRadius", "position", {lg.getWidth() / 2, lg.getHeight() / 2})
    post:addSetting("chromaticAberrationRadius", "offset", 6)
    post:addSetting("scanlines", "scale", 0.8)
    post:addSetting("scanlines", "opacity", 0.9)
    post:addSetting("barrelDistortion", "power", 1.06)
    post:addSetting("rgbMix", "rgb", {0.9, 1, 1.3})
    post:addSetting("verticalBlur", "amount", 1)
    post:addSetting("horizontalBlur", "amount", 1)
    post:addSetting("vignette", "opacity", 0.5)
    post:addSetting("vignette", "softness", 0.8)
    post:addSetting("vignette", "radius", 0.8)
    post:addSetting("vignette", "color", {0, 0, 0, 1})
    post:addMacro("blur", {
        {"verticalBlur", "amount", 1},
        {"horizontalBlur", "amount", 1},
    })

    -- This table is used to control the blur macro in the "post" chain
    -- I've set it up like this so i can use it with "smooth" easily.
    control = {blur = 2}


    newgame()
    time = 0
end

function newgame()
    -- Creating the world
    cellSize = 16
    local w = floor(lg.getWidth() / cellSize)
    local h = floor(lg.getHeight() * 0.9 / cellSize)
    world = map.new(w, h)

    -- Creating the player
    player = snake.new(floor(w / 2), floor(h / 2), world)
    world:set(player.x, player.y, 2)
    tick = 0
    score = 0
    started = false
    over = false

    text.newgame:setPosition(0, lg.getHeight() - 300)
    text.gameover:setPosition(0, -100)
    text.score:setPosition(0, lg.getHeight() * 0.87)
    text.score:set("0")


end

function start()
    started = true
    text.newgame:setPosition(0, lg.getHeight() + 100)
    text.shadertip:setPosition(-600, 12)
    smoof:new(control, {blur = 0}, 0.001)

--  function smoof:new(object, target, smoof_value, completion_threshold, bind, callback)

end

function gameover()
    over = true
    smoof:new(control, {blur = 2}, 0.001)
    text.gameover:setPosition(0, 100)
    text.score:set(score)
    text.score:setPosition(0, lg.getHeight() - 200)

end

function eat()
    score = score + 1
    text.score:set(score)
    player.length = player.length + 1
end

function love.update(dt)
    smoof:update(dt)

    post:setMacro("blur", control.blur)

    if started and not over then
        tick = tick + dt
        if tick > (1 / player.speed) then
            player:move()
            tick = 0
        end
    end
end

function love.draw()
    lg.setBlendMode("alpha")
    canvas:drawTo(function()
        world:draw(cellSize, 0)
        

        -- lg.setFont(font.large)
        -- lg.setColor(world.colors[3])
        -- lg.printf(score, 0, lg.getHeight() * 0.87, lg.getWidth(), "center")

    end, true)

    lg.setColor(1, 1, 1, 1)
    if useShaders then
        canvas:draw(post)
        
        -- Bloom pass
        lg.setColor(1, 1, 1, 0.7)
        lg.setBlendMode("add")
        canvas:draw(bloom)
    else
        canvas:draw()
    end

    for i,v in pairs(text) do
        v:draw()
    end

    

    --lg.setFont(font.small)
    --lg.setColor(1, 0, 1)
    --lg.print(love.timer.getFPS(), 12, 12)
end

function love.keypressed(key)
    if not started and key ~= "1" then
        start()
    end

    if over and key ~= "1"  then
        newgame()
    end

    if key == "escape" then love.event.push("quit") end
    if key == "1" then useShaders = not useShaders end

    if key == "left" then
        if player.direction ~= 2 and not player.directionChanged then
            player.direction = 1
            player.directionChanged = true
        end
    elseif key == "right" then
        if player.direction ~= 1 and not player.directionChanged then
            player.direction = 2
            player.directionChanged = true
        end
    elseif key == "up" then
        if player.direction ~= 4 and not player.directionChanged then
            player.direction = 3
            player.directionChanged = true
        end
    elseif key == "down" then
        if player.direction ~= 3 and not player.directionChanged then
            player.direction = 4
            player.directionChanged = true
        end
    end
end
