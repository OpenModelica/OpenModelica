#include("advection.jl")
#include("string.jl")
#include("stringAlg.jl")
#include("artery.jl")
include("solver.jl")
(X,U) = simulate("advection.jl", 2.0, 1)

function writeData(X,U)option
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
#writeData(X,U)

#using Gadfly
#plot(x = X, y = U[1,:])
#plot(x = X, y = U[2,:])
