package Burger_Equations
  model Burger_equation_01
    function Amatrix
      input Integer N;
      input Real dx;
      input Real ni;
      output Real A[N, N];
    algorithm
      A := zeros(N, N);
      for i in 1:N loop
        for j in 1:N loop
          if i == j then
            A[i, i] := -2 * ni / dx ^ 2;
          end if;
          if i - 1 == j then
            A[i, j] := ni / dx ^ 2;
          end if;
          if i + 1 == j then
            A[i, j] := ni / dx ^ 2;
          end if;
        end for;
      end for;
    end Amatrix;

    function Cmatrix
      input Integer N;
      input Real dx;
      output Real C[N, N];
    algorithm
      C := zeros(N, N);
      for i in 1:N loop
        for j in 1:N loop
          if i - 1 == j then
            C[i, j] := -1 / dx;
          end if;
          if i + 1 == j then
            C[i, j] := 1 / dx;
          end if;
        end for;
      end for;
    end Cmatrix;

    parameter Integer N = 100;
    parameter Integer L = 25;
    parameter Real ni = 0.02;
    parameter Real dx = L / N;

    //x=[0:dx:L-dx]';
    //c0=@(x) exp(- ((x-L*0.5)/(L*0.01)).^2);
    parameter Real y0[N] = {exp(-((dx * k - L * 0.5) / (L * 0.01)) ^ 2) for k in 0:N - 1};
    Real y[N](start = y0, each fixed = true);

  protected
    parameter Real A[N, N] = Amatrix(N, dx, ni);
    parameter Real C[N, N] = Cmatrix(N, dx);
    Real sum[N];
    // der(y) = A*y +y.*(C*y)
  algorithm
    for i in 1:N loop
      sum[i] := 0;
      for j in 1:N loop
        sum[i] := sum[i] + A[i, j] * y[j] + y[i] * C[i, j] * y[j];
      end for;
    end for;
  equation
    der(y) = sum;
  end Burger_equation_01;

  model Burger_equation_02
    parameter Integer N = 600;
    parameter Integer L = 25;
    parameter Real ni = 0.02;
    parameter Real dx = L / N;
    parameter Real y0[N] = {exp(-((dx * k - L * 0.5) / (L * 0.01)) ^ 2) for k in 0:N - 1};
    Real y[N](start = y0, each fixed = true);

  protected

    parameter Real Ad[N]    = fill(-2*ni/dx^2, N);
    parameter Real Au[N-1]  = fill(   ni/dx^2, N-1);
    parameter Real Al[N-1]  = fill(   ni/dx^2, N-1);
    parameter Real Cu[N-1]  = fill( 1/dx, N-1);
    parameter Real Cl[N-1]  = fill(-1/dx, N-1);

    // der(y) = A*y +y.*(C*y)
    // A*y = Ad.*y + {Au.*y[2:N],0} + {0,Al.*y[1:N-1]}
    // y.*C*y =  y.*{Cu.*y[2:N],0} + {0,Cl.*y[1:N-1]}
  equation
    der(y) = Ad.*y + cat(1,Au.*y[2:N],{0.0}) + cat(1,{0.0},Al.*y[1:N-1]) +
             y.*cat(1,Cu.*y[2:N],{0.0}) + cat(1,{0.0},Cl.*y[1:N-1]);
  end Burger_equation_02;

  model Burger_equation_03
    parameter Integer N = 600;
    parameter Integer L = 25;
    parameter Real ni = 0.02;
    parameter Real dx = L / N;
    parameter Real y0[N] = {exp(-((dx * k - L * 0.5) / (L * 0.01)) ^ 2) for k in 0:N - 1};
    Real y[N](start = y0, each fixed = true);

  protected

    parameter Real Ad[N]    = fill(-2*ni/dx^2, N);
    parameter Real Au[N-1]  = fill(   ni/dx^2, N-1);
    parameter Real Al[N-1]  = fill(   ni/dx^2, N-1);
    parameter Real Cd[N]    = zeros(N);
    parameter Real Cu[N-1]  = fill(-1/dx, N-1);
    parameter Real Cl[N-1]  = fill( 1/dx, N-1);

    // der(y) = A*y +y.*(C*y)
    // A*y = Ad.*y + {Au.*y[2:N],0} + {0,Al.*y[1:N-1]}
    // y.*C*y =  y.*{Cu.*y[2:N],0} + {0,Cl.*y[1:N-1]}
  equation
    der(y[1]) = Ad[1]*y[1] + Au[1]*y[2] + y[1]*Cu[1]*y[2];
    for i in 2:N-1 loop
      der(y[i]) = Al[i]*y[i-1] + Ad[i]*y[i] + Au[i]*y[i+1] + y[i]*(Cl[i-1]*y[i-1] + Cu[i]*y[i+1]);
    end for;
    der(y[N]) = Al[N-1]*y[N-1] + Ad[N]*y[N] + y[N]*Cl[N-1]*y[N-1];
  annotation(
      __OpenModelica_simulationFlags(gbmeth = "dopri45", lv = "LOG_STATS", s = "gbode"));end Burger_equation_03;
end Burger_Equations;
