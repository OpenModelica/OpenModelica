package WaterTank
  model SingleWaterTank
    import Modelica.Constants.pi;
    import SI = Modelica.SIunits;
    // Tank
    parameter SI.Area area = 1.0 "Area of tank";
    parameter Real gravity = 9.81;
    parameter Real level_start = 0.0;
    parameter Real liquid_density = 1;
    parameter Real volume_initial = 0;
    Real volume(start = volume_initial);
    Real tank_p_f;
    Real tank_p_e;
    Real tank_p_phi;

    // Flow source
    parameter Real fs_phi = 1.0;
    Real fs_p_phi = fs_phi;
    Real fs_inflow;
    Real fs_p_p;

    // Valve
    parameter Real valve_outflow_int_initial = 0;
    Real valve_outflow_int(start = valve_outflow_int_initial);
    Real valve_puddle;
    Real valve_powerOut_e;
    Real valve_powerOut_f;
    Real valve_powerIn_phi;
    Real valve_powerIn_p;
    Real valve_outflow;
    // Drain
    Real drain_p_e;
    Real drain_p_f;
    parameter Real drain_r = 9;

    Modelica.Blocks.Interfaces.RealInput valvecontrol annotation(Placement(visible = true, transformation(origin = {-100, 0}, extent = {{-20, -20}, {20, 20}}, rotation = 0), iconTransformation(origin = {-92, -2}, extent = {{-20, -20}, {20, 20}}, rotation = 0)));
  Modelica.Blocks.Interfaces.RealOutput level annotation(Placement(visible = true, transformation(origin = {108, -2}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {108, -2}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
equation
 fs_inflow = if fs_p_phi < 0 then 0 else 0.1 * abs (fs_p_phi);

 tank_p_e = (gravity * volume) * liquid_density;
 level = volume / area;
 valve_puddle = 8 * sqrt (valve_outflow_int);
 valve_powerOut_e = if (valvecontrol <> 0.0) then tank_p_e else 0.0;
 drain_p_f = valve_powerOut_e / drain_r;
 valve_powerIn_phi = if (valvecontrol <> 0.0) then drain_p_f else 0.0;
 valve_outflow = if drain_p_f < 0.0 then 0 else 0.1 * abs (drain_p_f);
 tank_p_f = fs_p_phi - valve_powerIn_phi;
 
 der(volume) = tank_p_f;
 der(valve_outflow_int) = valve_outflow;

 tank_p_phi = fs_p_phi;
 
 fs_p_p = tank_p_e;
 valve_powerIn_p = tank_p_e;
 
 drain_p_e = valve_powerOut_e;
 valve_powerOut_f = drain_p_f;
  
  annotation(defaultComponentName = "tank", Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}, initialScale = 0.2), graphics = {Rectangle(extent = {{-100, 100}, {100, -100}}, lineColor = {255, 255, 255}, fillColor = {255, 255, 255}, fillPattern = FillPattern.VerticalCylinder), Rectangle(extent = DynamicSelect({{-100, -100}, {100, 10}}, {{-100, -100}, {100, (-100) + 200 * level / height}}), lineColor = {0, 0, 0}, fillColor = {85, 170, 255}, fillPattern = FillPattern.VerticalCylinder), Line(points = {{-100, 100}, {-100, -100}, {100, -100}, {100, 100}}, color = {0, 0, 0}), Text(extent = {{-95, 60}, {95, 40}}, lineColor = {0, 0, 0}, textString = "level ="), Text(extent = {{-95, -24}, {95, -44}}, lineColor = {0, 0, 0}, textString = DynamicSelect("%level_start", String(level_start, minimumLength = 1, significantDigits = 2)))}), uses(Modelica(version = "3.2.2")));
  end SingleWaterTank;
  
  model Control
    parameter Real minlevel = 1;
    parameter Real maxlevel = 3;
    Modelica.Blocks.Interfaces.RealInput level annotation(Placement(visible = true, transformation(origin = {-100, 44}, extent = {{-20, -20}, {20, 20}}, rotation = 0), iconTransformation(origin = {-90, 48}, extent = {{-20, -20}, {20, 20}}, rotation = 0)));
    Modelica.Blocks.Interfaces.RealOutput valve(start = 0) annotation(Placement(visible = true, transformation(origin = {106, 42}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {96, 42}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  equation
    valve = if level >= maxlevel then 1.0 elseif level < minlevel then 0.0 else pre(valve);
    annotation(uses(Modelica(version = "3.2.2")));
  end Control;

  model TestSingleWaterTank
  
    Control control1 annotation(Placement(visible = true, transformation(origin = {2, 16}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    SingleWaterTank tank annotation(Placement(visible = true, transformation(origin = {-54, -32}, extent = {{-20, -20}, {20, 20}}, rotation = 0)));
  equation
    connect(control1.valve, tank.valvecontrol) annotation(Line(points = {{12, 20}, {20, 20}, {20, 42}, {-92, 42}, {-92, -32}, {-72, -32}, {-72, -32}}, color = {0, 0, 127}));
    connect(tank.level, control1.level) annotation(Line(points = {{-32, -32}, {-20, -32}, {-20, 20}, {-6, 20}, {-6, 20}}, color = {0, 0, 127}));
  end TestSingleWaterTank;
end WaterTank;
