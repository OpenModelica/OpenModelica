function retVal = Dx_nlr_alr(u, u_n, dx, m)
  retVal = (u_n(m+1) - u_n(m-1) + u(m+1) - u(m-1))/(4*dx);
end