#model:
#  A_t + A_x*U + A*U_x = 0
#  U_t + (2*alpha-1)*U*U_x + (alpha-1)*U*U/A*A_x + 1/rho*P_x = f/(rho*A)
#  f = -2*(zeta+2)*mu*C.pi*U
#  P = P_ext + beta/A_0*(sqrt(A) - sqrt(A_0))
#  Q = Q_heart
#  Q = P/R_out

include("incl.jl")

# - model static data
nU = 2                 #number of state fields 
#U[1,:] .. U
#U[2,:] .. A
nV = 2                 #number of algebraic fields
#V[1,:] .. P
#V[2,:] .. f


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

function initializeBoundParameters(p)
    p.zeta = (2 - p.alpha)/(p.alpha-1)
    p.beta = 4.0/3.0*sqrt(pi)*h*E
end


#model functions:

function initFun(p,i,x)
    if i == 1 #U
        p.CO/((p.MAP - p.P_ext)*p.A_0/p.beta + sqrt(p.A_0))^2
    elseif i == 2 #A
        ((p.MAP - p.P_ext)*p.A_0/p.beta + sqrt(p.A_0))^2
    else 
        error("wrong state variable index") 
    end 
end

function Q_heart(p,t)
    HR = 70/60
    Tc = 1/HR
    TcP = 1/30*Tc
    T1 = mod(t,Tc)
    SV = p.CO/HR
    Q_max = SV / (10 * TcP)
    
    if T1 < TcP T1/TcP*Q_max
    elseif T1 < 9*TcP Q_max
    elseif T1 < 10*TcP (10*TcP-t)/TcP*Q_max
    else 0.0
    end
end
else 0.0 end
end

function BCFun(t,X,U)
    Ql = Q_heart(p,t)
    Al = extrapolate(2,left,X,U)
    Ul = Ql/Al
    Ar = extrapolate(2,right,X,U)
    Ur = CO/Ar
    ([Ul;Al],[Ur,Ar])
    
end

function maxEigValFun()
    c
end

function vFun(p,x,u,U_x,t)
#TODO: implement
end

function utFun(p,x,u,ux,v,vx,t,)
    [c*ux[2]; ux[1]]
end

include("solver.jl")
