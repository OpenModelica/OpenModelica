within ;
package nonlinear_system
  model nonlinear
    constant Integer size = 2;
    constant Integer elements[size] = {1,2};
    parameter Real e[size, size] = fill(0.0, size, size);
    Real a[size];
    Real b[size];
    Real c[size, size];
    Real d[size];
  equation
    a = {if b[i] < 0.5 then -1 else 0 for i in elements};
    b = {if sum(c[i,:]) < 0.5 then 1 else 0 for i in elements};
    c = { { if e[i,j]  > 0.5 and d[j] < 0.5 then 1 else 0 for j in elements} for i in elements};
    d = {(if a[i] >= 0.9999 then 1 else 0) for i in elements};
  end nonlinear;
end nonlinear_system;
