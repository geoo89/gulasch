

function love.load()
    -- print("Test")
    isPaused = false
    
    ps = love.graphics.newParticleSystem(love.graphics.newImage("particle.png"), 32)
    ps:setEmissionRate(100)
    ps:setParticleLife(0.5,5)
    ps:setRadialAcceleration(100,500)
    ps:setTangentialAcceleration(100,400)
    ps:setSizeVariation(1)
    ps:setSpread(2*math.pi)
    ps:setSpeed(1,5)
    ps:setSpin(0,2*math.pi,1)
    ps:start()
    
    image = love.graphics.newImage("particle.png")
    objects = {}
end

function love.draw()
    love.graphics.print(love.timer.getFPS(),10,10,0,1,1)
    love.graphics.print("Hello World", 400, 300)
    love.graphics.draw(ps, 100, 100)
    
    for i in objects do
        love.graphics.draw(i, 200, 200)
    end
    
end

cnt = 0

function love.update(dt)
    if isPaused then
        return
    end
    
    ps:update(dt)
    
    --if love.keyboard.isDown("up") then
        cnt = cnt + 1
        print(cnt)
    --end
end

function love.mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
end

function love.keypressed(key, unicode)

end

function love.focus(f)
    isPaused = not f
end

function love.quit()
  print("Thanks for playing! Come back soon!")
end