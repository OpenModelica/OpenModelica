within ;
package FMUResourceTest "Test table resource"
  import Modelica.Utilities.Files.loadResource;

  partial model Test0
    Modelica.Blocks.Tables.CombiTable1D t_new
      annotation (Placement(transformation(extent={{-40,0},{-20,20}})));
    Modelica.Blocks.Continuous.Der d_t_new
      annotation (Placement(transformation(extent={{0,0},{20,20}})));
    Modelica.Blocks.Sources.Clock clock
      annotation (Placement(transformation(extent={{-80,0},{-60,20}})));
  equation
    connect(t_new.y[1], d_t_new.u) annotation (Line(
        points={{-19,10},{-2,10}},
        color={0,0,127},
        thickness=0.0625));
    connect(clock.y, t_new.u[1]) annotation (Line(
        points={{-59,10},{-42,10}}, color={0,0,127}));
  end Test0;

  model TestResource "Text file with UTF-8 BOM and comments (Ticket #2404)"
    extends Modelica.Icons.Example;
    extends Test0(t_new(
        tableOnFile=true,
        tableName="a",
        fileName=loadResource("modelica://FMUResourceTest/Resources/table_test%40utf8.txt")));
    annotation (experiment(StartTime=0, StopTime=100));
  end TestResource;
end FMUResourceTest;

