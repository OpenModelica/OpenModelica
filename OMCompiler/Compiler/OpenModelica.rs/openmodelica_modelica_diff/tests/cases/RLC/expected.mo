within;
partial model PartialTwoPortRLC
equation
  R_actual = R*(M + Modelica.Units.SI.Conversions.to_degC(T_heatPort))/
    (M + Modelica.Units.SI.Conversions.to_degC(T_ref));
end PartialTwoPortRLC;
