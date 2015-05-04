within SiemensPower.Boundaries;
model Reservoir "Thermal reservoir for discretized aggregate"
  parameter Integer N=2 "Number of cells";
  import SiemensPower.Boundaries.Types.reservoir;

 // parameter String reservoir="heat" "Kind of reservoir"
 //        annotation(choices(choice="heat" "Heat reservoir",
  //                       choice="temperature" "Temperature reservoir"));
  parameter SiemensPower.Boundaries.Types.reservoir reservoirType = reservoir.heat;
  Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_b ports[N]
    "Heat output distribution"
    annotation (Placement(transformation(extent={{-20,-92},{20,-50}}, rotation=
            0)));
  parameter Real T_set=500 "Fixed temperature"
      annotation (Dialog(enable=reservoir=="temperature"));
  parameter SiemensPower.Units.HeatFlowRate Q_flow_set=0
    "Fixed heat flow rate(overall)"
      annotation (Dialog(enable=reservoir=="heat"));
  SiemensPower.Units.Temperature T[N](each start=T_set);
  SiemensPower.Units.HeatFlowRate Q_flow[N](each start=Q_flow_set);

equation
if (reservoirType == reservoir.temperature) then
        T = ones(N)*T_set;
else
        Q_flow=ones(N)*Q_flow_set/N;
end if;

 ports.T = T;
 ports.Q_flow + Q_flow = zeros(N);

  annotation (Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,
            -100},{100,100}}), graphics={Rectangle(
          extent={{-100,22},{98,-50}},
          lineColor={255,255,255},
          fillColor={195,0,0},
          fillPattern=FillPattern.Solid), Text(
          extent={{-96,18},{96,-42}},
          lineColor={255,255,255},
          fillColor={190,0,0},
          fillPattern=FillPattern.Backward,
          textString="%reservoir")}),
Documentation(info="<html>
<p>
This model allows a specified amount of heat flow rate to be \"injected\"
into a thermal system or specify a certain <b>temperature reservoir</b>.<br>
In case of a <b>heat reservoir</b>, the amount of heat at each cell is given by Q0/N. <br>
The heat flows <b>into</b> the component to which the component PrescribedHeatFlow is connected,
if the input signal is positive.
</p>
</html><HTML>
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
<li> December 2006, added by Haiko Steuer
</ul>
</html>"),
    Diagram(graphics));
end Reservoir;
