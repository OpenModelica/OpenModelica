#model:
#  A_t + A_x*U + A*U_x = 0
#  U_t + (2*alpha-1)*U*U_x + (alpha-1)*U*U/A*A_x + 1/rho*P_x = f/(rho*A)
#  f = -2*(zeta+2)*mu*C.pi*U
#  P = P_ext + beta/A_0*(sqrt(A) - sqrt(A_0))
#  Q = Q_heart
#  Q = P/R_out

include("incl.jl")

# - model static data
nU = 2                 #number of state fields u[1,:]
nV = 2                 #number of algebraic fields

# - model values

L = 2.0                #length of domain

type Parameters
    alpha
    zeta
    rho
    mu
    P_ext
    A_0
    beta
    h
    E
    CO
    MAP
    R_out
end

p = Parameters(1.1, 0.0, 1000, 4e-3, 0.0, 24e-3, 0.0, 0.002, 6500000.0, 5.6/1000/6, 90*133.322387415, 0.0)

function initializeBoundParameters()
    p.zeta = (2 - p.alpha)/(p.alpha-1)
    p.beta = 4.0/3.0*sqrt(pi)*h*E
end


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

function utFun(x,u,ux,t,)
    [c*ux[2]; ux[1]]
end

include("solver.jl")
