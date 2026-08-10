local Vec2 = {}
Vec2.__index = Vec2

function Vec2.Add(v1, v2) 
    return Vec2.New(v1.x + v2.x, v1.y + v2.y)
end

function Vec2.Sub(v1, v2) 
    return Vec2.New(v1.x - v2.x, v1.y - v2.y)
end

function Vec2.Mul(v1, x2) 
    if type(x2) == "number" then
        return Vec2.New(FixedMul(v1.x, x2), FixedMul(v1.y, x2))
    end
    
    return Vec2.New(FixedMul(v1.x, x2.x), FixedMul(v1.y, x2.y))
end

function Vec2.Div(v1, x2) 
    if type(x2) == "number" then
        return Vec2.New(FixedDiv(v1.x, x2), FixedDiv(v1.y, x2))
    end
    
    return Vec2.New(FixedDiv(v1.x, x2.x), FixedDiv(v1.y, x2.y))
end

function Vec2.Dot(v1, v2) 
    return FixedMul(v1.x, v2.x) + FixedMul(v1.y, v2.y)
end

function Vec2.Cross(v1, v2)
    return Vec2.New(
        FixedMul(v1.y, v2.z) - FixedMul(v1.z, v2.y),
        FixedMul(v1.z, v2.x) - FixedMul(v1.x, v2.z)
    )
end

function Vec2.Neg(v) 
    return Vec2.New(-v.x, -v.y)
end

function Vec2.Len(v) 
	local temp = v:Dot(v)
	if temp < 0 then return 0 end
    return FixedSqrt(temp)
end

function Vec2.Normalize(v) 
    local l = v:Len()
    
    if l == 0 then
        return v
    end
    
    return v:Div(l)
end

function Vec2.ToString(v)
	return ("x = %f\ty = %f (%f)"):format(v.x, v.y, #v)
end

function Vec2.ToMobjMom(v, mo, absolute)
	if absolute then
		mo.momx = v.x
		mo.momy = v.z
	else
		mo.momx = $ + v.x
		mo.momy = $ + v.y
	end
end

-- Shortcuts
Vec2.__add = Vec2.Add
Vec2.__sub = Vec2.Sub
Vec2.__mul = Vec2.Mul
Vec2.__div = Vec2.Div
Vec2.__len = Vec2.Len
Vec2.__tostring = Vec2.ToString

registerMetatable(Vec2)

function Vec2.New(x, y) 
    return setmetatable({
        ["x"] = x,
        ["y"] = y,
    }, Vec2)
end

-- Extra misc constructors
function Vec2.SphereToCartesian(a,b)
    return Vec2.New(
        FixedMul(cos(a), cos(b)),
        FixedMul(sin(a), cos(b))
    )
end
function Vec2.MobjPosToVec(mo)
	return Vec2.New(
		mo.x, mo.y
	)
end
function Vec2.MobjMomToVec(mo)
	return Vec2.New(
		mo.momx, mo.momy
	)
end

rawset(_G, "Vec2", Vec2)