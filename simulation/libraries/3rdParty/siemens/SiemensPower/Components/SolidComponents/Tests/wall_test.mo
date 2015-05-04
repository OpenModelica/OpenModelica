within SiemensPower.Components.SolidComponents.Tests;
model wall_test "Test of wall"
// extends Modelica.Icons.Example;

  Wall wall(
    considerAxialHeatTransfer=
                          false,
    numberOfNodes=
      5,
    T_start={500,510,520,590,600})
            annotation (Placement(transformation(extent={{-14,-10},{6,10}},
          rotation=0)));
  SiemensPower.Boundaries.Reservoir reservoir(N=5, reservoirType=SiemensPower.Boundaries.Types.reservoir.temperature)
    annotation (Placement(transformation(extent={{-20,-18},{12,-40}}, rotation=
            0)));
  SiemensPower.Boundaries.PrescribedHeatFlow prescribedHeatFlow(numberOfCells=
                                                     5)
    annotation (Placement(transformation(extent={{-46,20},{-26,40}}, rotation=0)));
  SiemensPower.Blocks.TimeTable heatInput(table=[0,0; 5,0; 10,100e3; 15,100e3])
    annotation (Placement(transformation(extent={{-88,20},{-68,40}}, rotation=0)));
equation

  connect(wall.port_int,reservoir.ports)   annotation (Line(points={{-4.1,-4.6},
          {-4.1,-11.3},{-4,-11.3},{-4,-21.19}}, color={191,0,0}));

  connect(prescribedHeatFlow.portsOut,
                                   wall.port_ext) annotation (Line(points={{-26,
          30},{-4,30},{-4,4.9}}, color={191,0,0}));
  connect(heatInput.y, prescribedHeatFlow.Q_flow)
    annotation (
Documentation(info="<HTML>
<p>This is a simple test of the wall aggregate.
<p>
</HTML>",
      revisions="<html>
<ul>
<li> December 2006, added by Haiko Steuer
</ul>
</HTML>"),
    Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},{
            100,100}}), graphics),
    experiment(StopTime=25),
    Line(points={{-67,30},{-46,30}}, color={0,0,127}));

  annotation (Commands(file="Scripts/tests/wall_test.mos" "wall_test"),
      Documentation(info="<HTML>
<p>This is a simple test of the wall aggregate.
<p>
</HTML>
<HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                        <td><a href=\"mailto:haiko.steuer@siemens.com\">Haiko Steuer</a> </td>
                        <td><a href=\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\">SCD</a> </td>
                       </tr>
                <tr>
                           <td><b>Checked by:</b>   </td>
                           <td>            </td>
                </tr>
                <tr>
                           <td><b>Protection class:</b>    </td>
                           <td> </td>
                </tr>
                <tr>
                           <td><b>Used Dymola version:</b>    </td>
                           <td> </td>
                  </tr>
           </table>
                Copyright &copy  2007 Siemens AG, PG EIP12. All rights reserved.<br> <br>
               This model is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY.
           For details see <a href=\"../Documents/Disclaimer.html\">disclaimer</a> <br>
        </p>
</HTML>"),
    experiment(
      StopTime=25,
      NumberOfIntervals=500));
end wall_test;
