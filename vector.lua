-- 2D vector class
vector = {}
function vector.new(x, y)
    return setmetatable({x = x, y = y}, vector)
end

function vector.__add(a, b)
    return vector.new(a.x + b.x, a.y + b.y)
end

function vector.__sub(a, b)
    return vector.new(a.x - b.x, a.y - b.y)
end

function vector.__sub(a, b)
    return vector.new(a.x - b.x, a.y - b.y)
end

function vector.__mul(a, b)
    if type(a) == "number" then
        return vector.new(a * b.x, a * b.y)
    elseif type(b) == "number" then
        return vector.new(b * a.x, b * a.y)
    else
        return a.x * b.x + a.y * b.y
    end
end

function vector.__eq(a, b)
    return a.x == b.x and a.y == b.y
end

function vector.__tostring(a)
    return "(" .. tostring(a.x) .. ", " .. tostring(a.y) .. ")"
end

function vector.__concat(a, b)
    return tostring(a) .. " " .. tostring(b)
end