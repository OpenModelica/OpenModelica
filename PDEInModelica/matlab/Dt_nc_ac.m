function retVal = Dt_nc_ac(u, u_n, dt, m)
  retVal = (u_n(m) - u(m))/dt;
end