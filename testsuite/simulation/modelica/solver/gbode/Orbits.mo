package Orbits
  model Circular
    type Length = Real(unit = "m", nominal = 1e10);
    type Velocity = Real(unit = "m/s", nominal = 10e3);
    type Force = Real(unit = "Pa");
    type Mass = Real(unit = "kg");
    parameter Length x_e_start[2] = {150e9, 0};
    parameter Length x_a_start[2] = x_e_start + {6600e3, 0};
    parameter Velocity v_e_start[2] = {0, 29.78e3};
    parameter Velocity v_a_start[2] = v_e_start + {0, 7.6e3};
    Length x_e[2](start = x_e_start, each fixed = true);
    Length x_a[2](start = x_a_start, each fixed = true);
    Length x_e_a[2]= x_a - x_e;
    Velocity v_e[2](start = v_e_start, each fixed = true);
    Velocity v_a[2](start = v_a_start, each fixed = true);
    Mass M_s =  1.989e30;
    Mass M_e = 5.9722e24;
    Mass M_a = 1000;
    Force F_s_e[2];
    Force F_s_a[2];
    Force F_e_a[2];
    constant Real G = 6.674e-11;
  equation
    der(x_e) = v_e;
    der(x_a) = v_a;
    M_e*der(v_e) = F_s_e - F_e_a;
    M_a*der(v_a) = F_s_a + F_e_a;
    F_s_e = -G*M_s*M_e/(x_e*x_e)*x_e/sqrt(x_e*x_e);
    F_s_a = -G*M_s*M_a/(x_a*x_a)*x_a/sqrt(x_a*x_a);
    F_e_a = -G*M_e*M_a/(x_e_a*x_e_a)*(x_e_a/sqrt(x_e_a*x_e_a));
  annotation(
      experiment(StartTime = 0, StopTime = 1.6e7, Tolerance = 1e-6, Interval = 200),
      __OpenModelica_simulationFlags(lv = "LOG_STATS", s = "dassl"));
  end Circular;

  model HighElliptical
    extends Circular(v_a_start = v_e_start + {0, 10.5e3});
  annotation(
      experiment(StartTime = 0, StopTime = 1.6e7, Tolerance = 1e-6, Interval = 200),
      __OpenModelica_simulationFlags(lv = "LOG_STATS", s = "dassl"));
  end HighElliptical;
end Orbits;
