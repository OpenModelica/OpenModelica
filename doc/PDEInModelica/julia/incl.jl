const left = false
const right = true

function extrapolate(nState,side,X,U)
    if side == left 
        extrapolate3(X[1],X[2],X[3],X[4],U[nState,2],U[nState,3],U[nState,4])
    elseif side == right
        extrapolate3(X[nX],X[nX-1],X[nX-2],X[nX-3],U[nState,nX-1],U[nState,nX-2],U[nState,nX-3])
    end
end

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
