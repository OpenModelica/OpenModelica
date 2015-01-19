using Gaston

#numerics setup
nX = 200               #number of nodes

type AuxData
    plotMin :: Float64
    plotMax :: Float64
end

#numerics functions

function diff_x_LF(X,Y,dx,Y_x)
    nX = size(X,1)
    Y_x[:,1] = -3/2*Y[:,1] + 2*Y[:,2] + 1/2*Y[:,3]
    for i = 2:(nX-1) #over inner grid nodes
        Y_x[:,i] = (Y[:,i+1] - Y[:,i-1])/(2*dx)
    Y_x[:,nX] = 3/2*Y[:,nX] - 2*Y[:,nX-1] - 1/2*Y[:,nX-2]
    end
end

function updateV(X,U,U_x,t,V)
    for i = 1:size(X,1) #over all grid nodes
#FIX: V[:,1] and V[:,nX] are evaluated using unassigned U_x
        V[:,i] = algebraicFun(p,X[i],U[:,i],U_x[:,i],t)
    end
end

function updateU_t(X,U,U_x,V,V_x,t,U_t)
    for i = 2:nX-1 #over inner grid nodes
        U_t[:,i] = statesDerFun(p,X[i],U[:,i],U_x[:,i],V[:,i],V_x[:,i],t)
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

function plotData(X,U,V,varIPlot,auxData)
    if varIPlot != 0
      varP =
        if varIPlot > 0
          vec(U[varIPlot,:])
        else
          vec(V[-varIPlot,:])
      end
      auxData.plotMin = minimum([auxData.plotMin;varP])
      auxData.plotMax = maximum([auxData.plotMax;varP])
      plot_str = string("set yrange [", auxData.plotMin, ":", auxData.plotMax, "]")
      gnuplot_send(plot_str)
      plot(X,Ui)
#    gnuplot_send("replot")
  end
end



#computation
function simulate(modelStr::String,tEnd,varIPlot)
# modelSTr .. name of the model file
# tEnd .. final time
# varIPlot .. index of variable to be ploted. Positive value menas state, negative algebraic and 0 no plot
    print("žiju, inkluduju: ", modelStr)
    include(modelStr)
    #model variables:
    X = linspace(0.0,L,nX)     #coordinate
    U = Array(Float64,nU,nX)   #state fields U[nVar, nNode]
    U_x = Array(Float64,nU,nX) #state fields space derivative Ux[nVar, nNode]
    U_t = Array(Float64,nU,nX) #state fields time derivative Ut[nVar, nNode]
    V = Array(Float64,nV,nX)   #algevraic fields  V[nVar, nNode]
    V_x = Array(Float64,nV,nX) #algevraic fields space derivative V[nVar, nNode]
    t :: Float64 = 0.0                    #time
    #numerics variables:
    dx = L/(nX-1)              #space step
    #dt                         #time step
    cfl = 0.2
    auxData = AuxData(Inf,-Inf)

    initializeBoundParameters(p)
     for i = 1:nU
        for j = 1:nX
            U[i,j] = initFun(p,i,X[j])
        end
    end
     while t < tEnd
        dt = cfl*maxEigValFun(p,U,V)*dx
        t = t + dt
        (U[:,1],U[:,nX]) = BCFun(p,t,X,U)
        diff_x_LF(X,U,dx,U_x)
        updateV(X,U,U_x,t,V)
        diff_x_LF(X,V,dx,V_x)
        updateU_t(X,U,U_x,V,V_x,t,U_t)
        plotData(X,U,V,varIPlot,auxData)
        updateU_LF(U_t,dt,U)
#        print("time: ", string(t))
        sleep(0.3)
     end
    plot(X,U,V,varIPlot,auxData)
    (X,U)
end




