include("string.jl")
tEnd = 1
(X,U) = simulate(tEnd)
nX = size(X,1)
function analyticSol(x,t)
    v = sqrt(c)
    if x >= c*t 
        initFun(1, x - v*t)
    else
        l1BCFun(t - x/v)
    end
end
A = Array(Float64,nX)
for i in 1:nX
    A[i] = analyticSol(X[i],tEnd)
end


function writeData(X,A,U)
f = open("result.txt","w")
(nU,nX) = size(U)
    for iX = 1:nX
        write(f,string(X[iX])" ")            
        write(f,string(A[iX])" ")            
        for iU = 1:nU
            write(f,string(U[iU,iX])" ")
        end
        write(f,"\n")
    end
    close(f)
end

writeData(X,A,U)

#using Gadfly
#using Winston
#plot(x = X, y = U[1,:])


D = vec(U[1,:]) - A
l2err = sqrt((transpose(D)*D)[1])/nX
println(l2err)
#plot(x = X, y = D)
#plot(x = X, y = analyticU)
