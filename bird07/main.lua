-- virtual resolution handling library
push = require 'push'

-- class OOP class library
Class = require 'class'

-- bird class we've written
require 'Bird'

-- pipe class we've written
require 'Pipe'

-- class representing pair of pipes together
require 'PipePair'

-- physical screen dimensions
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

-- virtual resolution dimensions
VIRTUAL_WIDTH = 512
VIRTUAL_HEIGHT = 288

-- background image and starting scroll location (X axis)
local background = love.graphics.newImage('background.png')
local backgroundScroll = 0

-- ground iimage and starting scroll location (X axis)
local ground = love.graphics.newImage('ground.png')
local groundScroll = 0

-- spped at which we should scroll our images, scaled by dt
local BACKGROUND_SCROLL_SPEED = 30
local GROUND_SCROLL_SPEED = 60

-- point at which we should loop our background back to X 0
local BAKCGROUND_LOOPING_POINT = 413

-- our bird sprite
local bird = Bird()

-- our table of spawning PipePairs
local pipePairs = {}

-- our timer fow spawining pipes
local spawnTimer = 0

-- initialize our last recorded Y value for a gap placement to base other gaps
local lastY = -PIPE_HEIGHT + math.random(80) + 20

-- scrolling variable to pause the game when we collide with a pipe
local scrolling = true

function love.load()
    -- initialize our nearest-neighbour filter
    love.graphics.setDefaultFilter('nearest', 'nearest')

    -- seed the RNG
    math.randomseed(os.time())

    -- app window title
    love.window.setTitle('Fifty Bird')

    -- initialize our virtual resolution
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        vsync = true,
        fullscreen = false,
        resizable = true
    })

    -- initialize input table
    love.keyboard.keysPressed = {}
end

function love.resize(w, h)
    push:resize(w, h)
end

function love.keypressed(key)

    -- add to our table of keys pressed this frame
    love.keyboard.keysPressed[key] = true

    if key == 'escape' then
        love.event.quit()
    end
end

--[[
    New function used to check our global input table for keys we activated during this frame, looked up their string value.
]]
function love.keyboard.wasPressed(key)
    if love.keyboard.keysPressed[key] then
        return true
    else
        return false
    end
end

function love.update(dt)
    if scrolling then
        -- scroll background to preset speed * dt, looping back to 0 after the looping point
        backgroundScroll = (backgroundScroll + BACKGROUND_SCROLL_SPEED * dt)
            % BAKCGROUND_LOOPING_POINT

        -- scroll ground by preset speed * dt, looping back to 0 after the screen width passes
        groundScroll = (groundScroll + GROUND_SCROLL_SPEED * dt)
            % VIRTUAL_WIDTH

        spawnTimer = spawnTimer + dt

        -- spawn a new Pipe if the timer is past 2 seconds
        if spawnTimer > 2 then
            -- modify the last Y coordinate we placed so pipe gaps aren't too far apart no higher than 10 pixels below the top edge of the screen, and no lower than a gap length (90 pixels) from the bottom.
            local y = math.max(-PIPE_HEIGHT + 10, math.min(lastY + math.random(-20, 20), VIRTUAL_HEIGHT - 90 - PIPE_HEIGHT))
            lastY = y
            table.insert(pipePairs, PipePair(y))
            spawnTimer = 0
        end

        -- update the bird for input and gravity
        bird:update(dt)

        -- for every pipe in the scene...
        for k, pair in pairs(pipePairs) do
            pair:update(dt)

            -- check to see if bird collided with pipe
            for l, pipe in pairs(pair.pipes) do
                if bird:collides(pipe) then
                    -- pause the game to show collision
                    scrolling = false
                end
            end
        end

        -- remove any flagged pipes
        -- we need this second loop, ranther than deleting in the previous loop, because modifying the table in-place without explicity keys will result in skipping the next pipe, since all implicit keys (numerical indices) are automatically shifted down after a table removal
        for k, pair in pairs(pipePairs) do
            if pair.remove then
                table.remove(pipePairs, k)
            end
        end
    end

    -- reset input table
    love.keyboard.keysPressed = {}
end

function love.draw()
    push:start()

    --[[
        here, we draw our images shifted to the left by their looping point; eventually, they will revert bakc to 0 once a certain distance has elapsed, which will make it seem as if they are infinitely scrolling.
        Choosing a looping point that is seamless is key, so as to provide the illusion of looping.
    ]]

    -- draw the background at the negetive looping point
    love.graphics.draw(background, -backgroundScroll, 0)

    -- render all the pipe pairs in our scene
    for k, pair in pairs(pipePairs) do
        pair:render()
    end

    -- draw the ground on top of the background, toward the bottom of the screen at its negetive looping point
    love.graphics.draw(ground, -groundScroll, VIRTUAL_HEIGHT - 16)

    -- render our bird to the screen using its own render logic
    bird:render()

    push:finish()
end