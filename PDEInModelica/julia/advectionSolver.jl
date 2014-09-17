#model pder(u,t) + 1*pder(u,x) = 0
# - model static data
nU = 1                 #number of state fields


#numerics setup
nX = 100              #number of nodes

# - model values
L = 1.0                #length of domain
tEnd = 0.5

#model functions:

function initModelFun(x,u)
    for i = 1:size(u,2)
        u[1,i] = 0.0
    end
end

function evalBoundariesFun(u,t)
    nX = size(u,2)
    u[1] = if 0 < t < 0.1 
        sin(10.0*2.0*pi*t)
    else
        0
    end
    u[nX] = extrapolate3(x[nX],x[nX-1],x[nX-2],x[nX-3],u[nX-1],u[nX-2],u[nX-3])
end

function maxEigValFun()
    1
end

function utFun(x,u,ux,t)
    -1*ux
end


#numerics variables
x = linspace(0.0,L,nX) #coordinate
u = Array(Float64,nU,nX) #state fields u[nVar, nNode]
ux = Array(Float64,nU,nX) #state fields space derivatives ux[nVar, nNode]
ut = Array(Float64,nU,nX) #state fields time derivatives ut[nVar, nNode]
t = 0.0                #time
dx = L/(nX-1)          #space step
#dt                     #time step
cfl = 0.5

#numerics functions
function extrapolate3(x,x1,x2,x3,u1,u2,u3)
    #lagrange polinomial extrapolation
#    q1 = u1 / ( (x1-x2)*(x1-x3) )
#    q2 = u2 / ( (x2-x1)*(x2-x3) )
#    q3 = u3 / ( (x3-x1)*(x3-x2) )
#    x^2*(q1+q2+q3) + x*( q1*(x2+x3) + q2*(x1+x3) + q3*(x1+x2) ) + q1*x2*x3 + q2*x1*x3 + q3*x1*x2
    u1*(x-x2)*(x-x3)/((x1-x2)*(x1-x3)) +     
    u2*((x-x1)*(x-x3))/((x2-x1)*(x2-x3)) +     
    u3*((x-x1)*(x-x2))/((x3-x1)*(x3-x2))
end

function updateUxLW(x,u,ux)
    for i = 2:(size(x,1)-1)
        ux[i] = (u[i+1] - u[i-1])/(x[i+1] - x[i-1])
    end
end

function updateUt(x,u,ux,ut,t)
    for i = 2:size(x,1)-1 
        ut[i] = utFun(x[i],u[i],ux[i],t)
    end
end

function updateULW(u,ut,dt)
    uNew = similar(u)
    for i = 2:size(u,2)-1
        uNew[i] = (u[i+1] + u[i-1])/2.0 + dt*ut[i]
    end
    for i = 2:size(u,2)-1
        u[i] = uNew[i]
    end
    
end

#function updateULW(u,ut,dt)
#    function UUpdate(i)
#        (u[i+1] + u[i-1])/2 + dt*ut[i]
#    end
#    u1new = UUpdate(2)
#    unew = UUpdate(3)
#    for i = 4:size(u,2)-1 
#        u[i-2] = u1new
#        u1new = unew
#        unew = UUpdate(i)
#    end
#    u[size(u,2)-2] = u1new
#    u[size(u,2)-1] = unew
#end



    

#computation
using Gadfly
initModelFun(x,u)
while t < tEnd 
    dt = cfl*maxEigValFun()*dx
    evalBoundariesFun(u,t)
    updateUxLW(x,u,ux)
    updateUt(x,u,ux,ut,t)
    updateULW(u,ut,dt)
    t = t + dt
#    println(t)
end    
plot(x = x, y = u[1,:])




