#numerics setup
nX = 400               #number of nodes


#numerics functions

function diff_x_LF(X,Y,Y_x)
    for i = 2:(size(X,1)-1) #over inner grid nodes
        Y_x[:,i] = (Y[:,i+1] - Y[:,i-1])/(X[i+1] - X[i-1])
    end
end

function updateV(X,U,U_x,t,V)
    for i = 1:size(X,1) #over all grid nodes
#FIX: V[:,1] and V[:,nX] are evaluated using unassigned U_x
        V[:,i] = vFun(X[i],U[:,i],U_x[:,i],t)
    end
end

function updateU_t(X,U,U_x,V,V_x,t,U_t)
    for i = 2:nX-1 #over inner grid nodes
        U_t[:,i] = utFun(X[i],U[:,i],U_x[:,i],V[:,i],V_x[:,i],t)
    end
end

function updateU_LF(U_t,dt,U)
    function UUpdate(i)
        (U[:,i+1] + U[:,i-1])/2 + dt*U_t[:,i]
    end
    u1new = UUpdate(2)
    unew = UUpdate(3)
    for i = 4:size(U,2)-1 #over rest of inner grid nodes
        U[:,i-2] = u1new
        u1new = unew[:,:]
        unew = UUpdate(i)
    end
    U[:,size(U,2)-2] = u1new
    U[:,size(U,2)-1] = unew
end
        

#computation
function simulate(tEnd)
    
    #model variables:
    X = linspace(0.0,L,nX)     #coordinate
    U = Array(Float64,nU,nX)   #state fields U[nVar, nNode]
    U_x = Array(Float64,nU,nX) #state fields space derivative Ux[nVar, nNode]
    U_t = Array(Float64,nU,nX) #state fields time derivative Ut[nVar, nNode]
    V = Array(Float64,nV,nX)   #algevraic fields  V[nVar, nNode]
    V_x = Array(Float64,nV,nX) #algevraic fields space derivative V[nVar, nNode]
    t = 0.0                    #time
    #numerics variables:
    dx = L/(nX-1)              #space step
    #dt                         #time step
    cfl = 0.2


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
        diff_x_LF(X,U,U_x)
        updateV(X,U,U_x,t,V)
        diff_x_LF(X,V,V_x)
        updateU_t(X,U,U_x,V,V_x,t,U_t)
        updateU_LF(U_t,dt,U)
        t = t + dt
    end    
    (X,U)
end




