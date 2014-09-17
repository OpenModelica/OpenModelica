#include("advection.jl")
include("string.jl")
(X,U) = simulate(0.5)

function writeData(X,U)
f = open("result.txt","w")
(nU,nX) = size(U)
    for iX = 1:nX
        write(f,string(X[iX])" ")            
        for iU = 1:nU
            write(f,string(U[iU,iX])" ")
        end
        write(f,"\n")
    end
    close(f)
end

writeData(X,U)

#using Gadfly
#plot(x = X, y = U[1,:])
#plot(x = X, y = U[2,:])
