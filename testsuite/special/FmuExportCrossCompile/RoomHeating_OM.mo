package RoomHeating_OM
  model Room
    //
    //	Room Model - modelling the thermal model for a room
    //	Input Arguments:
    //		Tisurf - wall internal surface temperature in [C]
    //		valveopen - heating/cooling coil valve opening position that varies from 0 to 1
    //		fanspeed - fan spend that varies from 0 to 1
    //
    //	Output Arguments:
    //		RAT - indoor room air temperature [C]
    //
    //	files required: None
    //
    //	Author:         UTRC Ireland
    //
    //	Created:        07.08.2015
    //	Last revision:  07.08.2015
    //
    //--------------------------------------------------------------
    // UTC PROPRIETARY – Created at UTRC-I – Contains E.U. data only
    //--------------------------------------------------------------
    //
    //FCU coil parameters
    parameter Real mdotwt = 0.1 "total water flow rate availbale from the heat pump";
    parameter Real LWT = 40.0 "leaving water temperature";
    parameter Real eps = 0.4 "coil effectiveness";
    parameter Real cWater = 4181.0 "specific heat of water";
    parameter Real Awall = 60.0 "wall surface area";
    parameter Real hAir = 4.0 "heat transfer coefficient";
    Real mdotw "water flow rate leaving the valve";
    Real EWT "entering water temperature";
    Real Qin "heat transferred to the air in the coil";
    Real Qout "heat lost through room walls";
    //FCU fan parameters
    parameter Real mdotat = 0.5 "total air flow rate availbale from the fan";
    Real mdota "air flow rate leaving the fan";
    Real SAT "supply air temperature";
    //Room parameters
    //parameter Real R = 0.05 "thermal resistance of the wall";
    parameter Real rohAir = 1.204 "density of air";
    parameter Real vAir = 300.0 "room air volume";
    parameter Real cAir = 1012.0 "specific heat of air";
    parameter Real RATinit = 16.0 "initial room air temperature";
    Real vo(start = 0.0001);
    Real fs(start = 0.0001);
    Real DT(start = 0);
    Modelica.Blocks.Interfaces.RealInput Tisurf "wall internal surface temperature" annotation(Placement(visible = true, transformation(origin = {-98, 60}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {-98, 60}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    Modelica.Blocks.Interfaces.RealInput valveopen annotation(Placement(visible = true, transformation(origin = {-96, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {-96, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    Modelica.Blocks.Interfaces.RealInput fanspeed annotation(Placement(visible = true, transformation(origin = {-98, -58}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {-100, -56}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    Modelica.Blocks.Interfaces.RealOutput RAT(start = RATinit) annotation(Placement(visible = true, transformation(origin = {104, -2}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {104, -2}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    Modelica.Blocks.Interfaces.RealOutput energy(start = 0) annotation(Placement(visible = true, transformation(origin = {106, -60}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {102, -60}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  equation
    vo = if valveopen > 0 then valveopen else 0.0001;
    fs = if fanspeed > 0 then fanspeed else 0.0001;
//coil equations
    Qin = vo * mdotwt * cWater * (LWT - EWT);
    Qin = eps * mdotat * fs * cAir * (LWT - RAT);
    Qin = mdota * cAir * (SAT - RAT);
    mdotw = vo * mdotwt;
//Fan equations
    mdota = fs * mdotat;
//Room equations
    Qout = hAir * Awall * (RAT - Tisurf);
    der(RAT) = DT / (rohAir * cAir * vAir);
    DT = Qin - Qout;
    der(energy) = Qin;
//Requirments Check
    assert(fanspeed >= 0.01, "UTRC-FCU-002: FCU air damper should be opened at least 0.10.", AssertionLevel.warning);
    assert(EWT - LWT <= 5, "UTRC-FCU-001: Difference between EWT and LWT for HP should be less than 5 C", AssertionLevel.warning);
    annotation(Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2})), Diagram(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2})), uses(Modelica(version = "3.2.2")));
  end Room;

  model Wall
    //
    //	Wall Model - modelling the thermal model for the walls inside the room
    //	Input Arguments:
    //		RAT - indoor room air temperature in [C]
    //		OAT - outside air temperature in [C]
    //
    //	Output Arguments:
    //		Tisurf - wall internal surface temperature in [C]
    //
    //	files required: None
    //
    //	Author:         UTRC Ireland
    //
    //	Created:        07.08.2015
    //	Last revision:  07.08.2015
    //
    //--------------------------------------------------------------
    // UTC PROPRIETARY – Created at UTRC-I – Contains E.U. data only
    //--------------------------------------------------------------
    //
    // wall paramters
    parameter Real rhoWall = 1312.0;
    parameter Real cWall = 1360.71;
    parameter Real lambda_Wall = 0.1192;
    parameter Real lWall = 0.03 "wall thickness";
    parameter Real aWall = 60.0 "wall area";
    parameter Real hi = 8.33 "indoor heat transfer coefficient";
    parameter Real ho = 33.33 "outdoor heat transfer coefficient";
    parameter Real TisurfInit = 16.0 "initial internal surface temperature of the wall";
    parameter Real TosurfInit = 10.0 "initial external surface temperature of the wall";
    Real Tosurf(start = TosurfInit) "external surface temperature of the wall";
    Real R "wall resistance";
    Real C "thermal capacity of the wall";
    // model function
    Modelica.Blocks.Interfaces.RealOutput Tisurf(start = TisurfInit) "internal surface temperature of the wall" annotation(Placement(visible = true, transformation(origin = {106, 8}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {104, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    Modelica.Blocks.Interfaces.RealInput OAT annotation(Placement(visible = true, transformation(origin = {-102, 86}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {-100, 50}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    Modelica.Blocks.Interfaces.RealInput RAT annotation(Placement(visible = true, transformation(origin = {-100, -8}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {-102, -46}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    Modelica.Blocks.Interfaces.RealOutput lambdaOut annotation(Placement(visible = true, transformation(origin = {108, -54}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {108, -54}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  equation
// wall heat dissipation equations
    R = lWall / (lambda_Wall * aWall);
    C = rhoWall * cWall * lWall * aWall / 2.0;
    der(Tisurf) = (hi * aWall * (RAT - Tisurf) + (Tosurf - Tisurf) / R) / C;
    der(Tosurf) = (ho * aWall * (OAT - Tosurf) + (Tisurf - Tosurf) / R) / C;
    lambdaOut = lambda_Wall;
    annotation(Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2})), Diagram(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2})), uses(Modelica(version = "3.2.2")));
  end Wall;

  model RH
    RoomHeating_OM.Wall wall annotation(Placement(visible = true, transformation(origin = {-16, 56}, extent = {{-18, -18}, {18, 18}}, rotation = 0)));
    RoomHeating_OM.Room room annotation(Placement(visible = true, transformation(origin = {45, 5}, extent = {{-23, -23}, {23, 23}}, rotation = 0)));
    Modelica.Blocks.Interfaces.RealInput OAT annotation(Placement(visible = true, transformation(origin = {-100, 56}, extent = {{-20, -20}, {20, 20}}, rotation = 0), iconTransformation(origin = {-88, 58}, extent = {{-20, -20}, {20, 20}}, rotation = 0)));
    Modelica.Blocks.Interfaces.RealInput valveopen annotation(Placement(visible = true, transformation(origin = {-100, -32}, extent = {{-20, -20}, {20, 20}}, rotation = 0), iconTransformation(origin = {-88, -32}, extent = {{-20, -20}, {20, 20}}, rotation = 0)));
    Modelica.Blocks.Interfaces.RealInput fanspeed annotation(Placement(visible = true, transformation(origin = {-100, -78}, extent = {{-20, -20}, {20, 20}}, rotation = 0), iconTransformation(origin = {-90, -76}, extent = {{-20, -20}, {20, 20}}, rotation = 0)));
    Modelica.Blocks.Interfaces.RealOutput RAT annotation(Placement(visible = true, transformation(origin = {108, 4}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {108, -2}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  equation
    connect(room.RAT, RAT) annotation(Line(points = {{68, 4}, {108, 4}}, color = {0, 0, 127}));
    connect(wall.Tisurf, room.Tisurf) annotation(Line(points = {{3, 56}, {12.4, 56}, {12.4, 18}, {24.4, 18}}, color = {0, 0, 127}));
    connect(OAT, wall.OAT) annotation(Line(points = {{-100, 56}, {-34, 56}, {-34, 65}}, color = {0, 0, 127}));
    connect(room.RAT, wall.RAT) annotation(Line(points = {{68.92, 4.54}, {79.92, 4.54}, {79.92, 33.54}, {-38.08, 33.54}, {-38.08, 48}, {-34, 48}}, color = {0, 0, 127}));
    connect(fanspeed, room.fanspeed) annotation(Line(points = {{-100, -78}, {0, -78}, {0, -8}, {22, -8}, {22, -8}}, color = {0, 0, 127}));
    connect(valveopen, room.valveopen) annotation(Line(points = {{-100, -32}, {-20, -32}, {-20, 6}, {22, 6}, {22, 6}}, color = {0, 0, 127}));
    annotation(Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2})), Diagram(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2})), uses(Modelica(version = "3.2.2")));
  end RH;
  annotation(Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2})), Diagram(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2})));
end RoomHeating_OM;
