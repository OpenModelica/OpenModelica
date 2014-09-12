#numerics setup
nX = 100               #number of nodes


#numerics functions

function updateU_x_LW(X,U,U_x)
    for i = 2:(size(X,1)-1)
        U_x[i] = (U[i+1] - U[i-1])/(X[i+1] - X[i-1])
    end
end

function updateU_t(X,U,U_x,U_t,t)
    for i = 1:nU
        for j = 2:nX-1 
            U_t[i,j] = utFun(X[j],U[j],U_x[j],t,i)
        end
    end
end

function updateU_LW(U,U_t,dt)
    function UUpdate(i)
        (U[i+1] + U[i-1])/2 + dt*U_t[i]
    end
    u1new = UUpdate(2)
    unew = UUpdate(3)
    for i = 4:size(U,2)-1 
        U[i-2] = u1new
        u1new = unew
        unew = UUpdate(i)
    end
    U[size(U,2)-2] = u1new
    U[size(U,2)-1] = unew
end
        

#computation
function simulate(tEnd)
    

    #numerics variables
    X = linspace(0.0,L,nX) #coordinate
    U = Array(Float64,nU,nX) #state fields u[nVar, nNode]
    U_x = Array(Float64,nU,nX) #state fields space derivatives ux[nVar, nNode]
    U_t = Array(Float64,nU,nX) #state fields time derivatives ut[nVar, nNode]
    t = 0.0                #time
    dx = L/(nX-1)          #space step
    #dt                     #time step
    cfl = 0.5


    for i = 1:nU
        for j = 1:nX 
            U[i,j] = initFun(i,X[j])
        end
    end

    while t < tEnd 
        dt = cfl*maxEigValFun()*dx
        for i = 1:nU
            U[i,1]  = BCFun(i,left,t,X,U)
            U[i,nX] = BCFun(i,right,t,X,U)
        end
        updateU_x_LW(X,U,U_x)
        updateU_t(X,U,U_x,U_t,t)
        updateU_LW(U,U_t,dt)
        t = t + dt
    end    
    (X,U)
end




