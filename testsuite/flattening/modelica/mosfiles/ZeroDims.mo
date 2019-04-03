
model ZeroDims
  model ZeroDim
    parameter Real length = 0.0;
  end ZeroDim;

  input Integer lines[:, 2, 2] = zeros(0, 2, 2);
  parameter Integer n=size(lines, 1);
  ZeroDim c[n](length = {0.0 for i in 1:n});
end ZeroDims;

