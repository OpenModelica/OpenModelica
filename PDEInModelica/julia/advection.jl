#model pder(u,t) + c*pder(u,x) = 0
include("incl.jl")

# - model static data
nU = 1                 #number of state fields

# - model values
L = 1.0                #length of domain

c = 1.0

#model functions:

function initFun(p,i,x)
    if i == 1 
        0.0 
    else 
        error("wrong state number in advection") 
    end
end

function lBCFun(t)
    if 0 < t < 0.1 
        sin(10.0*2.0*pi*t)
    else
        0
    end
end

function BCFun(nState,side,p,t,X,U)
    if nState == 1
        if side == left lBCFun(t)
        elseif side == right extrapolate(X,U,nState,side) 
        end
    else
        error("wrong state index in advection")
    end
end

function maxEigValFun(p)
    c
end

function vFun(p,x,u,u_x,t)
    []
end

function utFun(p,x,u,ux,t,iState)
    if iState == 1
        -c*ux
    else
        error("wrong variable index in utFun()")
    end   
end

include("solver.jl")
