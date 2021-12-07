package testlib
  type NotReal = Integer;

  annotation(
    version = "2.0.0",
    conversion(from(version="1.0.0", to="1.0.1", script="modelica://testlib/Resources/conversion_1_0_0_to_1_0_1.mos"),
               from(version="1.0.1", to="1.0.2", script="modelica://testlib/Resources/conversion_1_0_1_to_1_0_2.mos"),
               from(version="1.0.2", script="modelica://testlib/Resources/conversion_1_0_2_to_2_0_0.mos")));
end testlib;
