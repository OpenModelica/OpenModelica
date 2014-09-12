include("advection.jl")
(X,U) = simulate(0.5)
using Gadfly
plot(x = X, y = U[1,:])
#plot(x = X, y = U[2,:])
