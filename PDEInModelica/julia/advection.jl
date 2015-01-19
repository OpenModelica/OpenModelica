#model pder(u,t) + c*pder(u,x) = 0
include("incl.jl")

# - model static data
nU = 1                 #number of state fields
nV = 0

# - model values
L = 1.0                #length of domain

type P
	c
end

p = P(1.0)


#model functions:
function initializeBoundParameters(p)
end



function initFun(p,i,x)
    if i == 1 
        0.0 
    else 
        error("wrong state number in advection") 
    end
end

function BCFun(p,t,X,U)
    lbc = if 0 < t < 0.1 
             sin(10.0*2.0*pi*t)
          else
             0
          end
    ([lbc], [extrapolate(1,right,X,U)])
end

function maxEigValFun(p,U,V)
    p.c
end

function algebraicFun(p,x,u,u_x,t)
    []
end

function statesDerFun(p,x,u,u_x,v,v_x,t)
    [-p.c*u_x[1]]
end

#include("solver.jl")
