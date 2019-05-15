# pder(u,time) - pder(w,x) = 0
#  pder(v,time) - pder(u,x) = 0
#  w = c*v;

include("incl.jl")

# - model static data
nU = 2                 #number of state fields u[nu,nx]      u,v
nV = 1                 #number of algebraic fields v[nv,nx]  w

# - model values
L = 2.0                #length of domain

type Parameters
    c
end

p = Parameters(2.0)


#model functions:

function initializeBoundParameters(p)
end

function initFun(p,i,x)
    if i == 1 || i == 2 
        0.0 
    else 
        error("wrong state number in advection") 
    end 
end

function l1BCFun(t)
    if 0.0 < t < 0.5 sin(2.0*pi*t) else 0.0 end
end

function BCFun(p,t,X,U)
    ([l1BCFun(t); extrapolate(2,left,X,U)],[0.0; extrapolate(2,right,X,U)])
end

function maxEigValFun(p,U,V)
    p.c
end

function algebraicFun(p,x,u,u_x,t)
    [p.c*u[2]]          #w = c*v;
end


function statesDerFun(p,x,u,u_x,v,v_x,t)
    [v_x[1]; u_x[1]]    #pder(u,time) - pder(w,x) = 0 ;  pder(v,time) - pder(u,x) = 0
end

include("solver.jl")
