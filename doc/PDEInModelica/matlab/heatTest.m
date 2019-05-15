global M dx dt t u schemes
M = 50;
dx = 0.1;
dt = 1;
t = 0;
u = [ones(1,M/2) zeros(1,M/2)];
schemes.U = @U_nc_ac;
schemes.Dt = @Dt_nc_ac;
schemes.Dx = @Dx_nlr;
schemes.Dxx = @Dxx_nlcr;
%schemes.Dx = @Dx_nlr_alr;
%schemes.Dxx = @Dxx_nlcr_alcr;
un = zeros(1,M);
n = 0;
t_end = 10;
plot(u);

tic;
while (t < t_end) 
  pause(0.1);
  u_n = fsolve(@residual,u);
  res = residual(u_n);
  t = t + dt;
  u = u_n;
  plot(u);
  axis([1 M 0 1]);
  n = n + 1;
end
disp(['steps done ' n]);
disp(['time ' toc]);





