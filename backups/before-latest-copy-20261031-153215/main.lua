-- Standalone Lua game: run this folder with LÖVE (love2d.org).
-- Load the map from the filename requested for this project.
local map = love.filesystem.load("Grassland.server.lua")()

-- LÖVE calls love.load once when the game starts.
function love.load()
    love.window.setTitle("Steal A Slime")
    love.window.setMode(900, 650)
    map.load()
end

function love.update(dt)
    map.update(dt)
end

function love.wheelmoved(x, y)
    map.wheelmoved(x, y)
end

-- LÖVE calls love.draw every frame to draw the game window.
function love.draw()
    map.draw()
end
