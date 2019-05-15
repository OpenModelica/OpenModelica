include("advection.jl")
tEnd = 0.5
(X,U) = simulate(tEnd)
nX = size(X,1)
function analyticSol(x,t)
    if x >= c*t 
        initFun(1, x - c*t)
    else
        lBCFun(t - x/c)
    end
end
analyticU = Array(Float64,nX)
for i in 1:nX
    analyticU[i] = analyticSol(X[i],tEnd)
end


using Gadfly
#using Winston
plot(x = X, y = U[1,:])


D = vec(U[1,:]) - analyticU
l2err = sqrt((transpose(D)*D)[1])/nX
println(l2err)
#plot(x = X, y = D)
#plot(x = X, y = analyticU)
