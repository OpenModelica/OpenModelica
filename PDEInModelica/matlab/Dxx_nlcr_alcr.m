function retVal = Dxx_nlcr_alcr(u, u_n, dx, m)
  retVal = (u_n(m+1) - 2*u_n(m) + u_n(m-1) + u(m+1) - 2*u(m) + u(m-1))/(2*dx^2);
end