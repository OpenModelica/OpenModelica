within;
partial model PartialTwoPortRLC
equation
  R_actual = R*(M + Modelica.SIunits.Conversions.to_degC(T_heatPort))/
    (M + Modelica.SIunits.Conversions.to_degC(T_ref));
end PartialTwoPortRLC;
