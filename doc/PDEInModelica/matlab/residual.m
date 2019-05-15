function res = residual(u_n)
  global M u t dt dx schemes
  [a,b] = size(u_n);
  if (a ~= 1 || b ~= M)
    error('function residual: wronk input dimension');
  end;
  res = zeros(1,M);
  res(1) = bcL_heat(u_n(1),u_n(2),t);
  for m = 2:M-1
    res(m) = F_heat(schemes.U, ...
		    schemes.Dt(u, u_n, dt, m), ...
		    schemes.Dx(u, u_n, dx, m), ...
		    schemes.Dxx(u, u_n, dx, m), ...
		    m*dx, t);
  end;
  res(M) = bcR_heat(u_n(M-1),u_n(M),t);
end
