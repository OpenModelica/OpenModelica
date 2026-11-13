package convlib
  type NewReal = Real;

  annotation(
    version = "2.1.0",
    conversion(noneFromVersion = "2.0.0",
               from(version = "1.0.0", to = "2.0.0", script = "modelica://convlib/Resources/conversion_1_0_0_to_2_0_0.mos")));
end convlib;
