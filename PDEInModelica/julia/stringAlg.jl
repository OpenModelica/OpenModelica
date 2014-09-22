#model pder(u,t) + 1*pder(u,x) = 0

include("incl.jl")

# - model static data
nU = 2                 #number of state fields u[nu,nx]      u,v
nV = 1                 #number of algebraic fields v[nv,nx]  w

# - model values
L = 2.0                #length of domain

c = 2.0


#model functions:

function initFun(i,x)
    if i == 1 || i == 2 
        0.0 
    else 
        error("wrong state number in advection") 
    end 
end

function l1BCFun(t)
    if 0.0 < t < 0.5 sin(2.0*pi*t) else 0.0 end
end

function BCFun(nState,side,t,X,U)
    if nState == 1
        if side == left 
            l1BCFun(t)
        elseif side == right
            0.0
        end
    else
        extrapolate(nState,side,X,U)
    end
end

function maxEigValFun()
    c
end

function vFun(x,u,u_x,t)
    [c*u[1]]          #w = c*v;
end


function utFun(x,u,ux,v,vx,t)
    [vx[1]; ux[1]]    #pder(u,time) - pder(w,x) = 0 ;  pder(v,time) - pder(u,x) = 0
end

include("solver.jl")
