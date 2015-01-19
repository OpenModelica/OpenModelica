#  pder(u,time) - c*pder(v,x) = 0
#  pder(v,time) - pder(u,x) = 0

include("incl.jl")

# - model static data
nU = 2                 #number of state fields u[1,:]
nV = 0

# - model values
L = 2.0                #length of domain

type P
	c
end

p = P(2.0)


#model functions:

function initFun(p,i,x)
    if i == 1 || i == 2 
        0.0 
    else 
        error("wrong state number in advection") 
    end 
end

function BCFun(p,t,X,U)
    lbc1 = if 0.0 < t < 0.5 sin(2.0*pi*t) else 0.0 end
    ([lbc1,extrapolate(2,left,X,U)],[0.0,extrapolate(2,right,X,U)])
end

function maxEigValFun(p,U,V)
    p.c
end

function algebraicFun(p,x,u,u_x,t)
[]
end

function statesDerFun(p,x,u,u_x,v,v_x,t)
    [p.c*u_x[2]; u_x[1]]
end

include("solver.jl")
