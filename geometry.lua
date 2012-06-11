function transformOffset(x,y,downdir,rightdir)
    assertValidDir(rightdir)
    assertValidDir(downdir)
    assert(downdir ~= rightdir and downdir ~= -rightdir)
   
    if(downdir == DOWN) then
        x = rightdir == RIGHT and x or 1 - x
    elseif(downdir == UP) then
        y = 1 - y
        x = rightdir == RIGHT and x or 1 - x
    elseif(downdir == RIGHT) then
        if (rightdir == UP) then
            x, y = y, 1-x
        else
            x, y = y, x
        end
    else
        assert(downdir == LEFT)
       
        if(rightdir == DOWN) then
            x, y = 1-y, x
        else
            x, y = 1 - y, 1 - x
        end
    end
    return x,y
end

function assertValidDir(dir)
    assert(dir == LEFT or dir == RIGHT or dir == UP or dir == DOWN, "Invalid direction: "..dir)
end

function dirtodxy(dir)
    assertValidDir(dir)
    if (dir == LEFT) then
        return -1,0
    elseif (dir == RIGHT) then
        return 1,0
    elseif (dir == TOP) then
        return 0,-1
    elseif (dir == BOTTOM) then
        return 0,1
    end
end

function dirToStr(dir)
    assertValidDir(dir)
    if(dir == UP) then return "UP"
    elseif(dir == DOWN) then return "DOWN"
    elseif(dir == LEFT) then return "LEFT"
    else return "RIGHT" end
end

function dirFromStr(dirstr)
    if(dirstr == "UP") then
        return UP
    elseif(dirstr == "DOWN") then
        return DOWN
    elseif(dirstr == "LEFT") then
        return LEFT
    elseif(dirstr == "RIGHT") then
        return RIGHT
    end
    
    error("dirFromStr: Invalid direction string ("..dirstr..")")
end

function dxytodir(dx,dy)
    if (dx == 1) then
        return RIGHT
    elseif (dx == -1) then
        return LEFT
    elseif (dy == 1) then
        return BOTTOM
    elseif (dy == -1) then
        return TOP
    else
        assert(false, "dxyToDir: SHITTY INPUT");
    end
end

function invertPair(dirdown,dirright)
    local downarrow
    local rightarrow
    
    if (dirdown == DOWN or dirdown == UP) then
        downarrow = dirdown
        rightarrow = dirright
    else
        downarrow  = dirright == DOWN and RIGHT or LEFT
        rightarrow = dirdown == RIGHT and DOWN  or UP
    end
    
    return downarrow, rightarrow
end

function nextdir(dir)
    assertValidDir(dir)
    if (dir == DOWN) then
        return RIGHT
    elseif(dir == RIGHT) then
        return UP
    elseif(dir == UP) then
        return LEFT
    else
        return DOWN
    end
end