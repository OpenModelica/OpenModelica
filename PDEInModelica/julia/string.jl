#model pder(u,t) + 1*pder(u,x) = 0

include("incl.jl")

# - model static data
nU = 2                 #number of state fields u[1,:]

# - model values
L = 1.0                #length of domain


#model functions:

function initFun(i,x)
    if i == 1 || i == 2 
        0.0 
    else 
        error("wrong state number in advection") 
    end 
end

function l1BCFun(t)
    if 0.0 < t < 1.0 sin(2.0*pi*t) else 0.0 end
end

function BCFun(nState,side,t,X,U)
    if nState == 1
        if side == left 
            l1BCFun(t)
        elseif side == right
            0.0
        end
    else
        extrapolate(X,U,nState,side)
    end
end

function maxEigValFun()
    2
end

function utFun(x,u,ux,t,iState)
    if iState == 1 #u
        2*ux[2] 
    elseif iState == 2 #v
        ux[1]
    else
        error("wrong variable index in utFun()")
    end
end

include("solver.jl")
