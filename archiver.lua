function export(filename)
    local f = assert(io.open(filename,"w"))
    
    function writeProp(name,value)
        f:write(name, " ", value, "\n")
    end
    
    writeProp("mapWidth",field.width)
    writeProp("mapHeight", field.height)
    
    -- print list of non-walls
    for y = 1,field.height do
        f:write("    ")
        for x = 1,field.width do
            if(field:hasWall(x,y,TOP)) then
                f:write(x, " ", y, " ", dirToStr(TOP), " ")
            end
            
            if(field:hasWall(x,y,LEFT)) then
                f:write(x, " ", y, " ", dirToStr(LEFT), " ")
            end
        end
        
        f:write("\n")
    end
    
    f:write(-1, " ", -1, " ", "END_OF_WALLS\n\n")
    
    f:write("SPECIAL_BACKGROUNDS\n")
    for y = 1,field.height do
        for x = 1,field.width do
            local background = field:get(x,y).background
            if background ~= DEFAULT_BACKGROUND then
                f:write(x, " ", y, " ", background, "\n")
            end
        end
    end
        
    f:write(-1, " ", -1, " ", "END_OF_BACKGROUNDS\n\n")    
    
    f:write("PORTALS\n")
    for y = 1,field.height do
        for x = 1,field.width do
            local cell = field:get(x,y)
            for _,e in pairs(DIRS) do
                if(cell.portals[e]) then
                    local portal = cell.portals[e]
                    
                    if  portal.yout > y
                    or (portal.yout == y and portal.xout > x)
                    or (portal.yout == y and portal.xout == x and portal.sideout >= e) then
                        f:write("    PORTAL "..x.." "..y.." "..portal.xout.." "..portal.yout.." "..e.." "..portal.upin.." "..portal.sideout.." "..portal.upout.."\n")
                    end
                end
            end
        end
    end
    
    f:write("END_OF_PORTALS\n\n")
    
    for k,o in pairs(objects) do
        f:write(o.typ, "\n")
        
        for key,value in pairs(o) do
            if (type(value) ~= "function") then
                f:write("    "..key.." "..type(value).." "..tostring(value).."\n")
            end
        end
        
        f:write("END_OF_OBJECT\n")
    end
    
    f:write("END_OF_MAP\n")
    f:close()
end

function import(filename)
    local f = io.open(filename, "r")
    
    if not f then
        field = DefaultField()
        return
    end

    function readString()
        local str
        repeat
            str = f:read(1)
        until str ~= " " and str ~= "\n"
        
        repeat
            next = f:read(1)
            
            if(next ~= " " and next ~= "\n") then
                str = str..next
            else
                break
            end
        until false
        
        return str
    end

    function expect(name)
        local str = readString()
        
        if (str ~= name) then
            error("Expected '"..name.."', but found '"..str.."'.")
        end
    end

    function readProp(name)
        expect(name)
        return f:read("*number")
    end

    local w = readProp("mapWidth")
    local h = readProp("mapHeight")
    
    field = DefaultField(w,h)
    objects = {}
    
    local x
    local y
    local dir
    repeat
        x = f:read("*number")
        y = f:read("*number")
        dir = readString()
        
        if(dir ~= "END_OF_WALLS") then
            field:toggleWall(x,y,dirFromStr(dir))
        else
            break;
        end
    until false
    
    local x
    local y
    local background
    expect("SPECIAL_BACKGROUNDS")
    repeat
        x = f:read("*number")
        y = f:read("*number")
        background = readString()
        
        if(background ~= "END_OF_BACKGROUNDS") then
            field:get(x,y).background = background
        else
            break;
        end
    until false
    
    expect("PORTALS")
    str = readString()
    while(str == "PORTAL") do
        local x = f:read("*n")
        local y = f:read("*n")
        local xout = f:read("*n")
        local yout = f:read("*n")
        local dir = f:read("*n")
        local up = f:read("*n")
        local dirout = f:read("*n")
        local upout = f:read("*n")
        
        field:openPortal(x,y,xout,yout,dir,up,dirout,upout)
        str = readString()
    end
    
    if (str ~= "END_OF_PORTALS") then
        error("Expected 'END_OF_PORTALS' but found '"..str.."'")
    end
    
    local constructor = readString()
    
    while(constructor ~= "END_OF_MAP") do
        local o  = _G[constructor]()
        local prop = readString()
        
        while(prop ~= "END_OF_OBJECT") do
            local typname = readString()
            if(typname == "string") then
                o[prop] = readString()
            elseif(typname == "boolean") then
                o[prop] = readString() == "true"
            elseif(typname =="number") then
                o[prop] = f:read("*number")
            else
                error("I dont know that type: "..typname)
            end
            
            prop = readString()
        end
        
        objects[#objects+1] = o
        
        if(constructor == "makeplayer") then
            player = o
        end
        
        constructor = readString()
    end
    
    io.close()
end