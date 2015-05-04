within SiemensPower.Components.Pipes.Tests;
model tubeTest "Test of tube"
    extends Modelica.Icons.Example;
  SiemensPower.Components.Pipes.TubeOwnMedia SH(
    geoPipe(L=10, Nt=100),
    considerMassAccelaration=
                false,
    considerDynamicPressure=
                 true,
    initializeInletPressure=
           false,
    m_flow_start=
            50,
    hOut_start= 2000e3,
    delayInnerHeatTransfer=
                true,
    hIn_start= 2000e3,
    metal(
      cp=540,
      lambda=44,
      rho=7850),
    pIn_start=3200000,
    pOut_start=3000000,
    numberOfNodes=3)
          annotation (Placement(transformation(extent={{40,-20},{62,-40}},
          rotation=0)));
  SiemensPower.Boundaries.WaterSink watersink_ph1(
                                                h_start=
                                                   2000e3, p_start=
                                                              3000000)
    annotation (Placement(transformation(extent={{80,-40},{100,-20}},  rotation=
           0)));
  Modelica.Blocks.Sources.RealExpression realExpression1(y=0)
    annotation (Placement(transformation(extent={{-14,-68},{6,-48}}, rotation=0)));
  SiemensPower.Boundaries.PrescribedHeatFlow prescribedHeatFlow2(
      numberOfCells=3)
    annotation (Placement(transformation(extent={{16,-70},{36,-50}}, rotation=0)));
  SiemensPower.Boundaries.WaterSourceWithSetPressure watersource_ph(
                                           h0=2000e3,
    p0=3200000,
    use_pIn=true)
    annotation (Placement(transformation(extent={{0,-40},{20,-20}},  rotation=0)));
  SiemensPower.Blocks.TimeTable timeTable2(table=[0,32e5; 200,32e5; 800,35e5; 2000,35e5])
    annotation (Placement(transformation(extent={{-20,-20},{0,0}},  rotation=0)));
equation

  connect(watersink_ph1.port,SH.portOut) annotation (Line(points={{80,-30},{72,
          -30},{62,-30}},                            color={0,127,255}));
  connect(realExpression1.y,prescribedHeatFlow2. Q_flow)
    annotation (Line(points={{7,-58},{16,-58},{16,-60}},
                                                color={0,0,127}));
  connect(prescribedHeatFlow2.portsOut,
                                   SH. gasSide) annotation (Line(points={{36,-60},
          {52,-60},{52,-36.6},{51,-36.6}},      color={191,0,0}));
  connect(watersource_ph.port,SH.portIn)  annotation (Line(points={{20,-30},{30,
          -30},{40,-30}},                            color={0,127,255}));
  connect(timeTable2.y,watersource_ph.pIn)   annotation (Line(points={{1,-10},{
          6,-10},{6,-22}},
                       color={0,0,127}));
  annotation (Documentation(info="<HTML>
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
</HTML>",
      revisions="<html>
<ul>
<li> January 2007, added by Haiko Steuer
</ul>
</HTML>"),
    Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},{
            100,100}}),
            graphics),
    experiment(
      StopTime=2000,
      NumberOfIntervals=2000,
      Tolerance=1e-005),
    Commands(file="Scripts/tests/tube_ownMedia_test.mos" "tube_ownMedia_test"));
end tubeTest;
