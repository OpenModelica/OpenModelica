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

type P
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

p = P(1.1, 0.0, 1000, 4e-3, 0.0, 24e-3, 0.0, 0.002, 6500000.0, 5.6/1000/60, 90*133.322387415, 0.0)
#             alpha zeta rho   mu   P_ext A_0    beta h      E          CO           MAP              R_out

function initializeBoundParameters(p)
    p.zeta = (2 - p.alpha)/(p.alpha-1)
    p.beta = 4.0/3.0*sqrt(pi)*p.h*p.E
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
#    print("t: ", t, "\n, Tc: ", Tc, "\n")
    if T1 < TcP 
        T1/TcP*Q_max
    elseif T1 < 9*TcP 
        Q_max
    elseif T1 < 10*TcP 
        (10*TcP-T1)/TcP*Q_max
    else 
        0.0
    end
end

function BCFun(p,t,X,U)
#    print("t: ", t)
    Ql = Q_heart(p,t)
    Al = extrapolate(2,left,X,U)
    Ul = Ql/Al
    Ar = extrapolate(2,right,X,U)
    Ur = p.CO/Ar
    ([Ul;Al],[Ur,Ar])
    
end

function maxEigValFun(p,U,V)
    maximum(sqrt(p.E*p.h./(2*p.rho*sqrt(U[2,:]/pi))))
end

function algebraicFun(p,x,u,u_x,t)
    #P = P_ext + beta/A_0*(sqrt(A) - sqrt(A_0)) :
    P = p.P_ext + p.beta/p.A_0*(sqrt(u[2]) - sqrt(p.A_0))
    #f = -2*(zeta+2)*mu*C.pi*U :
    f = -2*(p.zeta+2)*p.mu*pi*u[1]
    [P, f]
end

function statesDerFun(p,x,u,u_x,v,v_x,t,)
    #pder(U,time) = f/(rho*A) - (2*alpha-1)*U*pder(U,x) - (alpha-1)*U*U/A*pder(A,x) - 1/rho*pder(P,x)
    U_t = v[2]/(p.rho*u[2]) - (2*p.alpha-1)*u[1]*u_x[1] - (p.alpha-1)*u[1]*u[1]/u[2]u_x[2] - 1/p.rho*v_x[1]
    #pder(A,time) = - pder(A*U,x)
    #                  A_x*U + A*U_x
    A_t = - u_x[2]*u[1] - u_x[1]*u[2]
    [A_t, A_t]
end

include("solver.jl")
