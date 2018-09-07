package TestStreamConnectorsNoActualStreamEvaluateParams
  extends Modelica.Icons.Package;
  package Interfaces
    extends Modelica.Icons.InterfacesPackage;

    connector Flange
      Real p;
      flow Real m_flow;
      stream Real h_outflow;
  annotation(
        Icon(graphics = {Ellipse(origin = {1, 0}, fillColor = {85, 0, 255}, fillPattern = FillPattern.Solid, extent = {{-101, 100}, {99, -100}}, endAngle = 360)}));
    end Flange;

  end Interfaces;

  package Components
    extends Modelica.Icons.Package;

    model PressureSource
      parameter Real p = 1;
      parameter Real T = 20;
      parameter Real cp = 4000;
      Real h = cp * T;
      Interfaces.Flange flange annotation(
        Placement(visible = true, transformation(origin = {98, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {0, 0}, extent = {{-20, -20}, {20, 20}}, rotation = 0)));
    equation
      flange.p = p;
      flange.h_outflow = h;
      annotation(
        Icon(graphics = {Ellipse(origin = {0, -1}, fillColor = {170, 170, 255}, fillPattern = FillPattern.Solid, extent = {{-100, 99}, {100, -99}}, endAngle = 360)}));
    end PressureSource;



    model Pipe
      parameter Real Kf = 1;
      parameter Real cp = 4000;
      parameter Boolean allowFlowReversal = false annotation(Evaluate = true);
      Real dp = inlet.p - outlet.p;
      Interfaces.Flange outlet annotation(
        Placement(visible = true, transformation(origin = {98, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {100, 0}, extent = {{-20, -20}, {20, 20}}, rotation = 0)));
      Interfaces.Flange inlet(m_flow(min = if allowFlowReversal then -1e9 else 0)) annotation(
        Placement(visible = true, transformation(origin = {108, 10}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {-100, 0}, extent = {{-20, -20}, {20, 20}}, rotation = 0)));
    equation
      inlet.m_flow + outlet.m_flow = 0;
      inlet.p - outlet.p = Kf * inlet.m_flow;
      inlet.h_outflow = inStream(outlet.h_outflow);
      outlet.h_outflow = inStream(inlet.h_outflow);
      annotation(
        Icon(coordinateSystem(initialScale = 0.1), graphics = {Rectangle(origin = {1, -10}, fillColor = {170, 170, 255}, fillPattern = FillPattern.Solid, extent = {{-101, 50}, {99, -30}}), Line(origin = {8.89736, -0.111111}, points = {{-50, 0}, {50, 0}}), Line(origin = {50.3211, -10.1111}, points = {{-30, -10}, {10, 10}}), Line(origin = {89.4877, 9.28817}, points = {{-30, -10}, {-70, 10}})}));
    end Pipe;







    model PressureSensor
      Interfaces.Flange flange(m_flow(min = 0)) annotation(
        Placement(visible = true, transformation(origin = {98, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {0, -80}, extent = {{-20, -20}, {20, 20}}, rotation = 0)));
      Modelica.Blocks.Interfaces.RealOutput p annotation(
        Placement(visible = true, transformation(origin = {52, 52}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {52, 52}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    equation
      flange.p = p;
      flange.h_outflow = 0;
      flange.m_flow = 0;
      annotation(
        Icon(graphics = {Ellipse(origin = {50, -1}, fillColor = {170, 170, 255}, fillPattern = FillPattern.Solid, extent = {{-100, 101}, {0, 1}}, endAngle = 360), Line(origin = {-1, -30}, points = {{1, 30}, {1, -30}})}, coordinateSystem(initialScale = 0.1)));
    end PressureSensor;


    model Mixer
    Interfaces.Flange outlet annotation(
        Placement(visible = true, transformation(origin = {100, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {100, 3.55271e-15}, extent = {{-20, -20}, {20, 20}}, rotation = 0)));
  PressureSource source1(p = 2)  annotation(
        Placement(visible = true, transformation(origin = {2, 40}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Components.PressureSource source2(T = 40, p = 2)  annotation(
        Placement(visible = true, transformation(origin = {0, -40}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Components.Pipe pipe1 annotation(
        Placement(visible = true, transformation(origin = {50, 40}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Components.Pipe pipe2 annotation(
        Placement(visible = true, transformation(origin = {50, -40}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    equation
      connect(pipe2.outlet, outlet) annotation(
        Line(points = {{60, -40}, {80, -40}, {80, 0}, {100, 0}, {100, 0}}));
      connect(source2.flange, pipe2.inlet) annotation(
        Line(points = {{0, -40}, {40, -40}, {40, -42}, {40, -42}}));
      connect(pipe1.outlet, outlet) annotation(
        Line(points = {{60, 40}, {80, 40}, {80, 0}, {100, 0}, {100, 0}}));
      connect(source1.flange, pipe1.inlet) annotation(
        Line(points = {{2, 40}, {40, 40}, {40, 40}, {40, 40}}));
    annotation(
        Icon(graphics = {Rectangle(origin = {0, -1}, extent = {{-100, 101}, {100, -99}})}));end Mixer;

    model Pipe2
      parameter Real Kf = 1;
      parameter Real cp = 4000;
      parameter Boolean allowFlowReversal = false annotation(
        Evaluate = true);
      Real dp = inlet.p - outlet.p;
      Interfaces.Flange outlet(m_flow(max = if allowFlowReversal then 1e9 else 0)) annotation(
        Placement(visible = true, transformation(origin = {98, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {100, 0}, extent = {{-20, -20}, {20, 20}}, rotation = 0)));
      Interfaces.Flange inlet(m_flow(min = if allowFlowReversal then -1e9 else 0)) annotation(
        Placement(visible = true, transformation(origin = {108, 10}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {-100, 0}, extent = {{-20, -20}, {20, 20}}, rotation = 0)));
    equation
      inlet.m_flow + outlet.m_flow = 0;
      inlet.p - outlet.p = Kf * inlet.m_flow;
      inlet.h_outflow = inStream(outlet.h_outflow);
      outlet.h_outflow = inStream(inlet.h_outflow);
      annotation(
        Icon(coordinateSystem(initialScale = 0.1), graphics = {Rectangle(origin = {1, -10}, fillColor = {170, 170, 255}, fillPattern = FillPattern.Solid, extent = {{-101, 50}, {99, -30}}), Line(origin = {8.89736, -0.111111}, points = {{-50, 0}, {50, 0}}), Line(origin = {50.3211, -10.1111}, points = {{-30, -10}, {10, 10}}), Line(origin = {89.4877, 9.28817}, points = {{-30, -10}, {-70, 10}})}));
    end Pipe2;




  end Components;

  package TestModels
    extends Modelica.Icons.ExamplesPackage;

    model Test1
      extends Modelica.Icons.Example;
      Components.PressureSource source annotation(
        Placement(visible = true, transformation(origin = {0, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    equation
    annotation(experiment(StopTime = 1),
        Documentation(info = "<html><head></head><body><p>Unconnected stream connector source.flange</p>
</body></html>"));
    end Test1;

    model Test2
      extends Modelica.Icons.Example;
      Components.PressureSource source(p = 2)  annotation(
        Placement(visible = true, transformation(origin = {-62, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Components.Pipe pipe1 annotation(
        Placement(visible = true, transformation(origin = {-20, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Components.Pipe pipe2 annotation(
        Placement(visible = true, transformation(origin = {20, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Components.PressureSource sink(T = 0)  annotation(
        Placement(visible = true, transformation(origin = {60, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    equation
      connect(pipe2.outlet, sink.flange) annotation(
        Line(points = {{30, 0}, {60, 0}, {60, 0}, {60, 0}}));
      connect(pipe1.outlet, pipe2.inlet) annotation(
        Line(points = {{-10, 0}, {12, 0}}));
      connect(source.flange, pipe1.inlet) annotation(
        Line(points = {{-62, 0}, {-30, 0}, {-30, 0}, {-30, 0}}));
      assert(abs(pipe2.outlet.h_outflow - 80000) < 1e-10, "Error in computation of inStream(pipe2.outlet.h_outflow");
      assert(abs(pipe1.outlet.h_outflow - 80000) < 1e-10, "Error in computation of inStream(pipe1.outlet.h_outflow");
      annotation(
        experiment(StopTime = 1),
        Documentation(info = "<html><head></head><body><p>One-to-one connections.</p>
<p>pipe2.outlet.h_outflow =<br>inStream(pipe2.inlet.h_outflow) =<br> pipe1.outlet.h_outflow =<br>inStream(pipe1.inlet.h_outflow) =<br>source.flange.h_outflow =<br>80000.</p>
</body></html>"));
    end Test2;


    model Test3
      extends Modelica.Icons.Example;
      Components.PressureSource source(p = 2) annotation(
        Placement(visible = true, transformation(origin = {-62, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Components.Pipe pipe1(allowFlowReversal = true)  annotation(
        Placement(visible = true, transformation(origin = {-20, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Components.Pipe pipe2(allowFlowReversal = true)  annotation(
        Placement(visible = true, transformation(origin = {20, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Components.PressureSource sink(T = 0) annotation(
        Placement(visible = true, transformation(origin = {60, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    equation
      connect(pipe2.outlet, sink.flange) annotation(
        Line(points = {{30, 0}, {60, 0}, {60, 0}, {60, 0}}));
      connect(pipe1.outlet, pipe2.inlet) annotation(
        Line(points = {{-10, 0}, {12, 0}}));
      connect(source.flange, pipe1.inlet) annotation(
        Line(points = {{-62, 0}, {-30, 0}, {-30, 0}, {-30, 0}}));
      assert(abs(pipe2.outlet.h_outflow - 80000) < 1e-10, "Error in computation of inStream(pipe2.outlet.h_outflow");
      assert(abs(pipe1.outlet.h_outflow - 80000) < 1e-10, "Error in computation of inStream(pipe1.outlet.h_outflow");
      annotation(
        experiment(StopTime = 1),
        Documentation(info = "<html><head></head><body><p>One-to-one connections.</p>
<p>pipe2.outlet.h_outflow =<br>inStream(pipe2.inlet.h_outflow) =<br> pipe1.outlet.h_outflow =<br>inStream(pipe1.inlet.h_outflow) =<br>source.flange.h_outflow =<br>80000.</p>
</body></html>"));
    end Test3;

    model Test4
      extends Modelica.Icons.Example;
      Components.PressureSource source annotation(
        Placement(visible = true, transformation(origin = {0, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Components.Pipe pipe annotation(
        Placement(visible = true, transformation(origin = {42, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    equation
      connect(source.flange, pipe.inlet) annotation(
        Line(points = {{0, 0}, {32, 0}, {32, 0}, {32, 0}}));
      assert(abs(pipe.inlet.h_outflow - 80000) < 1e-10, "Error in computation of inStream(pipe.outlet.h_outflow");
      annotation(
        experiment(StopTime = 1),
        Documentation(info = "<html>
<p>Unconnected stream connector pipe.outlet.</p>
<p>pipe.inlet.h_outflow =<br>
inStream(pipe.outlet.h_outflow) =<br>
pipe.outlet.h_outflow = <br>
80000.</p>
</html>"));
    end Test4;

    model Test5
      extends Modelica.Icons.Example;
      Components.PressureSource source(p = 2) annotation(
        Placement(visible = true, transformation(origin = {-62, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Components.Pipe pipe1(allowFlowReversal = true)  annotation(
        Placement(visible = true, transformation(origin = {-20, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Components.Pipe pipe2(allowFlowReversal = true)  annotation(
        Placement(visible = true, transformation(origin = {20, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Components.PressureSource sink annotation(
        Placement(visible = true, transformation(origin = {60, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Components.PressureSensor sensor annotation(
        Placement(visible = true, transformation(origin = {0, 28}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    equation
      connect(sensor.flange, pipe1.outlet) annotation(
        Line(points = {{0, 20}, {0, 20}, {0, 0}, {-10, 0}, {-10, 0}}));
      connect(pipe2.outlet, sink.flange) annotation(
        Line(points = {{30, 0}, {60, 0}, {60, 0}, {60, 0}}));
      connect(pipe1.outlet, pipe2.inlet) annotation(
        Line(points = {{-10, 0}, {12, 0}}));
      connect(source.flange, pipe1.inlet) annotation(
        Line(points = {{-62, 0}, {-30, 0}, {-30, 0}, {-30, 0}}));
      assert(abs(pipe2.outlet.h_outflow - 80000) < 1e-10, "Error in computation of inStream(pipe2.outlet.h_outflow");
      assert(abs(pipe1.outlet.h_outflow - 80000) < 1e-10, "Error in computation of inStream(pipe1.outlet.h_outflow");
      annotation(
        experiment(StopTime = 1),
        Documentation(info = "<html><head></head><body><p>One-to-one connections with sensor port having m_flow(min = 0) = 0. Flow reversal allowed. The sensor enthalpy should not appear in the expressions for inStream(pipe1.outlet.h_outflow) and inStream(pipe2.inlet.h_outflow)</p>
<p>pipe2.outlet.h_outflow =<br>
inStream(pipe2.inlet.h_outflow) =<br> pipe1.outlet.h_outflow =<br> inStream(pipe1.inlet.h_outflow) =<br> source.flange.h_outflow =<br>
80000.</p>
</body></html>"));
    end Test5;

    model Test6
      extends Modelica.Icons.Example;
      Components.PressureSource sink(p = 0)  annotation(
        Placement(visible = true, transformation(origin = {70, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Components.PressureSource source1(T = 100)  annotation(
        Placement(visible = true, transformation(origin = {-70, 20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Components.PressureSource source2(T = 50)  annotation(
        Placement(visible = true, transformation(origin = {-70, -20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Components.Pipe pipe1 annotation(
        Placement(visible = true, transformation(origin = {-20, 20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Components.Pipe pipe2 annotation(
        Placement(visible = true, transformation(origin = {-20, -20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Components.Pipe pipe3 annotation(
        Placement(visible = true, transformation(origin = {26, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    equation
  connect(source2.flange, pipe2.inlet) annotation(
        Line(points = {{-70, -20}, {-30, -20}}));
  connect(pipe3.inlet, pipe2.outlet) annotation(
        Line(points = {{16, 0}, {8, 0}, {8, -18}, {-10, -18}}));
  connect(pipe3.outlet, sink.flange) annotation(
        Line(points = {{36, 0}, {70, 0}}));
  connect(pipe1.outlet, pipe3.inlet) annotation(
        Line(points = {{-10, 20}, {8, 20}, {8, 0}, {16, 0}}));
  connect(source1.flange, pipe1.inlet) annotation(
        Line(points = {{-70, 20}, {-30, 20}, {-30, 20}, {-30, 20}}));
      assert(abs(pipe3.outlet.h_outflow - 300000) < 1e-10, "Error in computation of inStream(pipe3.outlet.h_outflow");
      assert(abs(pipe1.inlet.h_outflow - 200000) < 1e-10, "Error in computation of inStream(pipe1.outlet.h_outflow");
    annotation(
        experiment(StopTime = 1),
        Documentation(info = "<html><head></head><body><p>Fan-in 2-to-one connection, flow reversal not allowed (m_flow.min=0 on all inlets).</p>
<p>Full mixing equation for pipe3.outlet.h_outflow</p><p>pipe3.outlet.h_outflow =<br>
inStream(pipe3.inlet.h_outflow)=<br>(max(-pipe1.outlet.m_flow, 1e-7)*pipe1.outlet.h_outflow + max(pipe2.outlet.m_flow,1e-7)*pipe2.outlet.h_outflow)/(max(-pipe1.outlet.m_flow, 1e-7) + max(pipe2.outlet.m_flow,1e-7)=<br>
300000.</p>
<p>No mixing for pipe1.inlet.h_outflow, due to pipe3.inlet.m_flow.min=0</p>
<p>pipe1.inlet.h_outflow =<br>
inStream(pipe1.outlet.h_outflow)=<br>
pipe2.outlet.h_outflow=<br>
inStream(pipe2.inlet.h_outflow)=<br>
source2.flange.h_outflow=<br>
source2.h=<br>
200000</p>
</body></html>"));
    end Test6;



    model Test7
      extends Modelica.Icons.Example;
      Components.PressureSource sink(p = 0) annotation(
        Placement(visible = true, transformation(origin = {70, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Components.PressureSource source1(T = 100) annotation(
        Placement(visible = true, transformation(origin = {-70, 20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Components.PressureSource source2(T = 50) annotation(
        Placement(visible = true, transformation(origin = {-70, -20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Components.Pipe pipe1(allowFlowReversal = true)  annotation(
        Placement(visible = true, transformation(origin = {-20, 20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Components.Pipe pipe2(allowFlowReversal = true)  annotation(
        Placement(visible = true, transformation(origin = {-20, -20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Components.Pipe pipe3(allowFlowReversal = true)  annotation(
        Placement(visible = true, transformation(origin = {26, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    equation
      connect(source2.flange, pipe2.inlet) annotation(
        Line(points = {{-70, -20}, {-30, -20}, {-30, -20}, {-30, -20}}));
  connect(pipe3.outlet, sink.flange) annotation(
        Line(points = {{36, 0}, {70, 0}}));
  connect(pipe3.inlet, pipe2.outlet) annotation(
        Line(points = {{16, 0}, {8, 0}, {8, -20}, {-10, -20}, {-10, -20}}));
  connect(pipe1.outlet, pipe3.inlet) annotation(
        Line(points = {{-10, 20}, {8, 20}, {8, 0}, {16, 0}}));
      connect(source1.flange, pipe1.inlet) annotation(
        Line(points = {{-70, 20}, {-30, 20}, {-30, 20}, {-30, 20}}));
      annotation(
        experiment(StopTime = 1),
        Documentation(info = "<html><head></head><body><p>Fan-in 2-to-one connection, flow reversal allowed.</p>
<p>Full mixing equation for pipe3.outlet.h_outflow</p><p>pipe3.outlet.h_outflow =<br>
inStream(pipe3.inlet.h_outflow)=<br>(max(-pipe1.outlet.m_flow, 1e-7)*pipe1.outlet.h_outflow + max(pipe2.outlet.m_flow,1e-7)*pipe2.outlet.h_outflow)/(max(-pipe1.outlet.m_flow, 1e-7) + max(pipe2.outlet.m_flow,1e-7)=<br>
300000.</p>
<p>Full mixing equation for pipe1.inlet.h_outflow, due to pipe3.inlet.m_flow.min=0</p>
<p>pipe1.inlet.h_outflow =<br>
inStream(pipe1.outlet.h_outflow)=<br>(max(-pipe2.outlet.m_flow, 1e-7)*pipe2.outlet.h_outflow + max(pipe3.outlet.m_flow,1e-7)*pipe3.outlet.h_outflow)/(max(-pipe3.outlet.m_flow, 1e-7) + max(pipe3.outlet.m_flow,1e-7)</p>
</body></html>"));
    end Test7;

    model Test8
      extends Modelica.Icons.Example;
      Components.PressureSource sink3 annotation(
        Placement(visible = true, transformation(origin = {60, -20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Components.PressureSource source(p = 2) annotation(
        Placement(visible = true, transformation(origin = {-60, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Components.Pipe pipe1 annotation(
        Placement(visible = true, transformation(origin = {-20, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Components.Pipe pipe2 annotation(
        Placement(visible = true, transformation(origin = {20, 20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Components.Pipe pipe3 annotation(
        Placement(visible = true, transformation(origin = {20, -20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  TestStreamConnectorsNoActualStreamEvaluateParams.Components.PressureSource sink2 annotation(
        Placement(visible = true, transformation(origin = {60, 20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    equation
  connect(pipe2.outlet, sink2.flange) annotation(
        Line(points = {{30, 20}, {46, 20}, {46, 22}, {60, 22}}));
  connect(source.flange, pipe1.inlet) annotation(
        Line(points = {{-60, 0}, {-30, 0}}));
  connect(pipe1.outlet, pipe2.inlet) annotation(
        Line(points = {{-10, 0}, {0, 0}, {0, 20}, {10, 20}}));
  connect(pipe1.outlet, pipe3.inlet) annotation(
        Line(points = {{-10, 0}, {0, 0}, {0, -20}, {10, -20}}));
      connect(pipe3.outlet, sink3.flange) annotation(
        Line(points = {{30, -20}, {60, -20}}));
      assert(abs(pipe2.outlet.h_outflow - 80000) < 1e-10, "Error in computation of inStream(pipe2.outlet.h_outflow");
      assert(abs(pipe1.inlet.h_outflow - 80000) < 1e-10, "Error in computation of inStream(pipe1.outlet.h_outflow");
      annotation(
        experiment(StopTime = 1),
        Documentation(info = "<html><head></head><body><p>Fan-out 2-to-one connection, flow reversal not allowed (m_flow.min=0 on other inlets).</p>
<p>No mixing equation for pipe2.outlet.h_outflow</p><p>pipe2.outlet.h_outflow =<br>
inStream(pipe2.inlet.h_outflow)=<br>pipe1.outlet.h_outflow=<br>inStream(pipe1.inlet.h_outflow)=<br>source.flange.h_outflow=<br>source.h=<br>80000.</p>
<p>Default enthalpy fo for pipe1.inlet.h_outflow, due to pipe2.inlet.m_flow.min=0 and pipe3.inlet.m_flow.min=0</p>
<p>pipe1.inlet.h_outflow =<br>pipe1.outlet.h_outflow=<br>inStream(pipe2.inlet.h_outflow)=<br>
source.flange.h_outflow=<br>
source.h=<br>
80000</p>
</body></html>"));
    end Test8;


model Test9
  extends Modelica.Icons.Example;
  Components.PressureSource sink3(T = 50, p = 1.6)  annotation(
    Placement(visible = true, transformation(origin = {60, -20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Components.PressureSource source(p = 2) annotation(
    Placement(visible = true, transformation(origin = {-60, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Components.Pipe pipe1 annotation(
    Placement(visible = true, transformation(origin = {-20, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Components.Pipe pipe2(allowFlowReversal = false)  annotation(
    Placement(visible = true, transformation(origin = {20, 20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Components.Pipe pipe3(allowFlowReversal = true)  annotation(
    Placement(visible = true, transformation(origin = {20, -20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Components.PressureSource sink2 annotation(
    Placement(visible = true, transformation(origin = {60, 20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
equation
  connect(pipe2.outlet, sink2.flange) annotation(
    Line(points = {{30, 20}, {46, 20}, {46, 18}, {60, 18}}));
  connect(source.flange, pipe1.inlet) annotation(
    Line(points = {{-60, 0}, {-30, 0}}));
  connect(pipe1.outlet, pipe2.inlet) annotation(
    Line(points = {{-10, 0}, {0, 0}, {0, 20}, {10, 20}}));
  connect(pipe1.outlet, pipe3.inlet) annotation(
    Line(points = {{-10, 0}, {0, 0}, {0, -20}, {10, -20}}));
  connect(pipe3.outlet, sink3.flange) annotation(
    Line(points = {{30, -20}, {60, -20}}));
  assert(abs(pipe3.outlet.h_outflow - 80000) < 1e-10, "Error in computation of inStream(pipe3.outlet.h_outflow");
  assert(abs(pipe2.outlet.h_outflow - 95000) < 1e-10, "Error in computation of inStream(pipe2.outlet.h_outflow");
  annotation(
    experiment(StopTime = 1),
    Documentation(info = "<html>
<p>Fan-out 2-to-one connection, flow reversal allowed ony on pipe3 (m_flow.min=0 on all other pipe inlets).</p>
<p>No mixing equation for pipe3.outlet.h_outflow</p><p>pipe3.outlet.h_outflow =<br>inStream(pipe3.inlet.h_outflow)=<br>pipe1.outlet.h_outflow=<br>inStream(pipe1.inlet.h_outflow)=<br>source.flange.h_outflow=<br>source.h=<br>80000.</p>
<p>Mixing equation for pipe2.outlet.h_outflow</p>
<p>pipe2.outlet.h_outflow =<br>inStream(pipe2.inlet.h_outflow)=<br>(max(-pipe1.outlet.m_flow,1e-7)*pipe1.outlet.h_outflow + max(-pipe3.outlet.m_flow,1e-7)*pipe3.outlet.h_outflow)/(max(-pipe1.outlet.m_flow,1e-7)+max(-pipe3.outlet.m_flow,1e-7)) =<br>
95000.</p>
</html>"));
end Test9;


    model Test10
      extends Modelica.Icons.Example;
  Components.Mixer mixer annotation(
        Placement(visible = true, transformation(origin = {-30, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Components.Pipe pipe annotation(
        Placement(visible = true, transformation(origin = {10, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Components.PressureSource sink annotation(
        Placement(visible = true, transformation(origin = {50, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    equation
      assert(abs(pipe.outlet.h_outflow - 120000) < 1e-10, "Error in computation of inStream(pipe.outlet.h_outflow)");
      assert(abs(mixer.outlet.h_outflow - 120000) < 1e-10, "Error in computation of inStream(mixer.outlet.h_outflow)");
      connect(mixer.outlet, pipe.inlet) annotation(
        Line(points = {{-20, 0}, {-2, 0}, {-2, 0}, {0, 0}, {0, 0}}));
      connect(pipe.outlet, sink.flange) annotation(
        Line(points = {{20, 0}, {50, 0}, {50, 0}, {50, 0}}));
      annotation(
        experiment(StopTime = 1),
        Documentation(info = "<html><head></head><body><p>Fan-in connection with hierarchical model, flow reversal not allowed.</p>
<p>One-to-one connection for pipe.outlet.h_outflow</p><p>pipe.outlet.h_outflow =<br>inStream(pipe3.inlet.h_outflow)=<br>mixer.outlet.h_outflow=<br>120000.</p>
<p>Mixing equation for mixer.outlet.h_outflow</p><p>mixer.outlet.h_outflow =<br>inStream(pipe2.inlet.h_outflow)=<br>(max(-mixer.pipe1.outlet.m_flow,1e-7)*mixer.pipe1.outlet.h_outflow + max(-mixer.pipe2.outlet.m_flow,1e-7)*mixer.pipe2.outlet.h_outflow)/(max(-mixer.pipe1.outlet.m_flow,1e-7)+max(-mixer.pipe2.outlet.m_flow,1e-7)) =<br>12000.</p><div><p>Mixing equation for mixer.pipe1.inlet.h_outflow (mixer.outlet does not have min = 0)</p><p>mixer.pipe1.inlet.h_outflow.h_outflow =<br>inStream(pipe1.outlet.h_outflow)=<br>(max(-mixer.pipe2.outlet.m_flow,1e-7)*mixer.pipe2.outlet.h_outflow + max(-mixer.outlet.m_flow,1e-7)*mixer.outlet.h_outflow)/(max(-mixer.pipe1.outlet.m_flow,1e-7)+max(-mixer.outlet.m_flow,1e-7)) =<br>16000.</p></div><div><br></div>
</body></html>"));
    end Test10;

    model Test11
      extends Modelica.Icons.Example;
      Components.PressureSource sink3(T = 50) annotation(
        Placement(visible = true, transformation(origin = {90, -20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Components.PressureSource source(p = 2) annotation(
        Placement(visible = true, transformation(origin = {-60, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Components.Pipe pipe1 annotation(
        Placement(visible = true, transformation(origin = {-20, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Components.Pipe pipe2(allowFlowReversal = false) annotation(
        Placement(visible = true, transformation(origin = {20, 20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Components.Pipe pipe3(Kf = 0.5, allowFlowReversal = true) annotation(
        Placement(visible = true, transformation(origin = {20, -20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Components.PressureSource sink2 annotation(
        Placement(visible = true, transformation(origin = {60, 20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    Components.Pipe pipe4(Kf = 0.5, allowFlowReversal = false) annotation(
        Placement(visible = true, transformation(origin = {56, -20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    equation
      connect(pipe2.outlet, sink2.flange) annotation(
        Line(points = {{30, 20}, {46, 20}, {46, 22}, {60, 22}}));
      connect(pipe3.outlet, pipe4.inlet) annotation(
        Line(points = {{30, -20}, {44, -20}, {44, -20}, {46, -20}}));
      connect(pipe4.outlet, sink3.flange) annotation(
        Line(points = {{66, -20}, {88, -20}, {88, -20}, {90, -20}}));
      connect(source.flange, pipe1.inlet) annotation(
        Line(points = {{-60, 0}, {-30, 0}}));
      connect(pipe1.outlet, pipe2.inlet) annotation(
        Line(points = {{-10, 0}, {0, 0}, {0, 20}, {10, 20}}));
      connect(pipe1.outlet, pipe3.inlet) annotation(
        Line(points = {{-10, 0}, {0, 0}, {0, -20}, {10, -20}}));
      assert(abs(pipe3.outlet.h_outflow - 80000) < 1e-10, "Error in computation of inStream(pipe3.outlet.h_outflow");
      assert(abs(pipe2.outlet.h_outflow - 80000) < 1e-10, "Error in computation of inStream(pipe2.outlet.h_outflow");
      annotation(
        experiment(StopTime = 1),
        Documentation(info = "<html><head></head><body><p>Fan-out 2-to-one connection, flow reversal allowed only on pipe4 (m_flow.min=0 on all other pipe inlets)..</p>
<p>No mixing equation for pipe3.outlet.h_outflow</p><p>pipe3.outlet.h_outflow =<br>inStream(pipe3.inlet.h_outflow)=<br>pipe1.outlet.h_outflow=<br>inStream(pipe1.inlet.h_outflow)=<br>source.flange.h_outflow=<br>source.h=<br>80000.</p>
<p>Since pipe4 is series connected to pipe3, good symbolic processing should determine that in fact flow reversal is not possible in pipe3 as well, even though pipe3 allows it. Therefore</p>
<p>pipe2.outlet.h_outflow =<br>
pipe1.outlet.h_outflow=<br>
inStream(pipe1.inlet.h_outflow)=<br>
source.flange.h_outflow=<br>
source.h=<br>
80000.</p>
</body></html>"));
    end Test11;

    model Test12
      extends Modelica.Icons.Example;
      Components.PressureSource sink(p = 0) annotation(
        Placement(visible = true, transformation(origin = {70, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Components.PressureSource source1(T = 100) annotation(
        Placement(visible = true, transformation(origin = {-70, 20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Components.PressureSource source2(T = 50) annotation(
        Placement(visible = true, transformation(origin = {-70, -20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Components.Pipe2 pipe1 annotation(
        Placement(visible = true, transformation(origin = {-20, 20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Components.Pipe2 pipe2 annotation(
        Placement(visible = true, transformation(origin = {-20, -20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Components.Pipe2 pipe3 annotation(
        Placement(visible = true, transformation(origin = {26, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    equation
      connect(source2.flange, pipe2.inlet) annotation(
        Line(points = {{-70, -20}, {-30, -20}}));
      connect(pipe3.inlet, pipe2.outlet) annotation(
        Line(points = {{16, 0}, {8, 0}, {8, -18}, {-10, -18}}));
      connect(pipe3.outlet, sink.flange) annotation(
        Line(points = {{36, 0}, {70, 0}}));
      connect(pipe1.outlet, pipe3.inlet) annotation(
        Line(points = {{-10, 20}, {8, 20}, {8, 0}, {16, 0}}));
      connect(source1.flange, pipe1.inlet) annotation(
        Line(points = {{-70, 20}, {-30, 20}, {-30, 20}, {-30, 20}}));
      assert(abs(pipe3.outlet.h_outflow - 300000) < 1e-10, "Error in computation of inStream(pipe3.outlet.h_outflow");
      assert(abs(pipe1.inlet.h_outflow - 200000) < 1e-10, "Error in computation of inStream(pipe1.outlet.h_outflow");
      annotation(
        experiment(StopTime = 1),
        Documentation(info = "<html><head></head><body><p>Fan-in 2-to-one connection, flow reversal not allowed (m_flow.min=0 on all inlets, m_flow.max=0 on all outlets).</p>
<p>Full mixing equation for pipe3.outlet.h_outflow; max operators can be simplified away thanks to m_flow.max = 0 on the outlet ports</p><p>pipe3.outlet.h_outflow =<br>
inStream(pipe3.inlet.h_outflow)=<br>(max(-pipe1.outlet.m_flow, 1e-7)*pipe1.outlet.h_outflow + max(pipe2.outlet.m_flow,1e-7)*pipe2.outlet.h_outflow)/(max(-pipe1.outlet.m_flow, 1e-7) + max(pipe2.outlet.m_flow,1e-7)=<br>((-pipe1.outlet.m_flow)*pipe1.outlet.h_outflow + (-pipe2.outlet.m_flow)*pipe2.outlet.h_outflow)/((-pipe1.outlet.m_flow) + (-pipe2.outlet.m_flow))=<br>300000.</p>
<p>No mixing for pipe1.inlet.h_outflow, due to pipe3.inlet.m_flow.min=0</p>
<p>pipe1.inlet.h_outflow =<br>
inStream(pipe1.outlet.h_outflow)=<br>
pipe2.outlet.h_outflow=<br>
inStream(pipe2.inlet.h_outflow)=<br>
source2.flange.h_outflow=<br>
source2.h=<br>
200000</p>
</body></html>"));
    end Test12;

    model Test13
      extends Modelica.Icons.Example;
      Components.PressureSource sink3(T = 50, p = 1.6) annotation(
        Placement(visible = true, transformation(origin = {60, -20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Components.PressureSource source(p = 2) annotation(
        Placement(visible = true, transformation(origin = {-60, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Components.Pipe2 pipe1 annotation(
        Placement(visible = true, transformation(origin = {-20, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Components.Pipe2 pipe2(allowFlowReversal = false) annotation(
        Placement(visible = true, transformation(origin = {20, 20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Components.Pipe2 pipe3(allowFlowReversal = true) annotation(
        Placement(visible = true, transformation(origin = {20, -20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      TestStreamConnectorsNoActualStreamEvaluateParams.Components.PressureSource sink2 annotation(
        Placement(visible = true, transformation(origin = {60, 20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    equation
      connect(pipe2.outlet, sink2.flange) annotation(
        Line(points = {{30, 20}, {45, 20}, {45, 22}, {60, 22}}));
      connect(source.flange, pipe1.inlet) annotation(
        Line(points = {{-60, 0}, {-30, 0}}));
      connect(pipe1.outlet, pipe2.inlet) annotation(
        Line(points = {{-10, 0}, {0, 0}, {0, 20}, {10, 20}}));
      connect(pipe1.outlet, pipe3.inlet) annotation(
        Line(points = {{-10, 0}, {0, 0}, {0, -20}, {10, -20}}));
      connect(pipe3.outlet, sink3.flange) annotation(
        Line(points = {{30, -20}, {60, -20}}));
      assert(abs(pipe3.outlet.h_outflow - 80000) < 1e-10, "Error in computation of inStream(pipe3.outlet.h_outflow");
      assert(abs(pipe2.outlet.h_outflow - 95000) < 1e-10, "Error in computation of inStream(pipe2.outlet.h_outflow");
      annotation(
        experiment(StopTime = 1),
        Documentation(info = "<html><head></head><body><p>Fan-out 2-to-one connection, flow reversal allowed ony on pipe3 (m_flow.min=0 on all other pipe inlets, m_flow.max=0 on all other pipe outlets).</p>
<p>No mixing equation for pipe3.outlet.h_outflow</p><p>pipe3.outlet.h_outflow =<br>inStream(pipe3.inlet.h_outflow)=<br>pipe1.outlet.h_outflow=<br>inStream(pipe1.inlet.h_outflow)=<br>source.flange.h_outflow=<br>source.h=<br>80000.</p>
<p>Mixing equation for pipe2.outlet.h_outflow: max(-pipe1.outlet.m_flow,1e-7) is simplified to (-pipe1.outlet.m_flow) because max(pipe1.outlet.m_flow) = 0.</p>
<p>pipe2.outlet.h_outflow =<br>inStream(pipe2.inlet.h_outflow)=<br>(max(-pipe1.outlet.m_flow,1e-7)*pipe1.outlet.h_outflow + max(-pipe3.outlet.m_flow,1e-7)*pipe3.inlet.h_outflow)/(max(-pipe1.outlet.m_flow,1e-7)+max(-pipe3.outlet.m_flow,1e-7)) =<br>((-pipe1.outlet.m_flow)*inStream(pipe1.inlet.h_outflow) + max(-pipe3.outlet.m_flow,1e-7)*inStream(pipe3.outlet.h_outflow))/((-pipe1.outlet.m_flow)+max(-pipe3.outlet.m_flow,1e-7)) =<br>((-pipe1.outlet.m_flow)*source.flange.h_outflow + max(-pipe3.outlet.m_flow,1e-7)*sink3.flange.h_outflow)/((-pipe1.outlet.m_flow)+max(-pipe3.outlet.m_flow,1e-7)) =<br>((-pipe1.outlet.m_flow)*source.h + max(-pipe3.outlet.m_flow,1e-7)*sink3.h)/((-pipe1.outlet.m_flow)+max(-pipe3.outlet.m_flow,1e-7)) =<br>(pipe1.inlet.m_flow*source.h + max(-pipe3.outlet.m_flow,1e-7)*sink3.h)/(pipe1.inlet.m_flow+max(-pipe3.outlet.m_flow,1e-7)) =<br>95000.</p>
</body></html>"));
    end Test13;


























  end TestModels;

  annotation(
    uses(Modelica(version = "3.2.2")));
end TestStreamConnectorsNoActualStreamEvaluateParams;
