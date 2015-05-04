within SiemensPower.Components.Pipes;
model Tube
  "Tube (incl wall) with detailed energy, integrated momentum and mass balance"

  import SI = Modelica.SIunits;
extends SiemensPower.Components.Pipes.TubeWithoutWall;

  // heat transfer parameters
  replaceable model heattransfer =
      SiemensPower.Utilities.HeatTransfer.InnerHeatTransfer.SinglePhaseOverall;
  //constrainedby
  //  SiemensPower.Utilities.HeatTransfer.InnerHeatTransfer.PartialHeatTransferSinglePhase
  //  "Inner heat transfer correlation" annotation (Dialog(group="Geometry and correlations"),
  //    choicesAllMatching=true);
  parameter SI.CoefficientOfHeatTransfer alpha_start = 10000
    "Heat transfer coefficient (not too small for valid wall temperature)"                                                        annotation(Dialog(tab="Initialization"));

  // Wall
  parameter Integer numberOfWallLayers(min=1)=3 "Number of wall layers" annotation(Dialog(group="Wall"),choices(choice=1, choice=2, choice=3, choice=4, choice=5, choice=6));
  parameter Medium.Temperature TWall_start[numberOfNodes]=T_start+q_start/alpha_start*ones(numberOfNodes)
    "start values for wall temperatures"
                                       annotation (Dialog(tab="Initialization",group="Wall"));
  parameter SiemensPower.Utilities.Structures.PropertiesMetal metal
    "Wall metal properties"                                                      annotation (Dialog(group="Wall"));
  parameter SI.Length diameterBranch = geoPipe.d_out-2*geoPipe.s
    "Average aperture of branch"                                                              annotation (Dialog(tab="Advanced", group="Branch geometry (for stress calculation)"));
  parameter SI.Length wallThicknessBranch = geoPipe.s
    "Wall thickness of branch"                                                    annotation (Dialog(tab="Advanced", group="Branch geometry (for stress calculation)"));

  Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a heatPort[numberOfNodes](T(
        start=TWall_start), Q_flow(start=geoPipe.Nt*Q_flow_start))
    "Outer wall heat port"
  annotation (Placement(transformation(extent={{-14,54},{14,78}}, rotation=0),
        iconTransformation(extent={{-14,54},{14,78}})));

 SiemensPower.Components.SolidComponents.Wall wall(
    numberOfNodes=numberOfNodes,
    numberOfWallLayers=numberOfWallLayers,
    metal=metal,
    length =   geoPipe.L,
    wallThickness=geoPipe.s,
    T_start =   TWall_start,
    numberOfParallelTubes=geoPipe.Nt,
    diameterInner =   geoPipe.d_out - 2*geoPipe.s) "Metal wall of the tube"
                 annotation (Placement(transformation(extent={{-10,34},{10,54}},
          rotation=0)));

  SiemensPower.Interfaces.portHeat heatport(
                               numberOfNodes=numberOfNodes)
    "inner wall (masked) heat port "                                            annotation (Placement(
        transformation(extent={{-10,-8},{10,12}}, rotation=0)));

  SI.CoefficientOfHeatTransfer alpha[numberOfNodes];

protected
  heattransfer HT[numberOfNodes](each geoPipe=geoPipe, m_flow=m_flows, rho=d, p=fluid.p, h=fluid.h, eta=eta, cp=cp, lambda=lambda, each
      steamQuality = 1.5, dT=TWall-fluid.T);
  SI.HeatFlux qMetalFluid[numberOfNodes]( each start=q_start);
  inner Medium.Temperature TWall[numberOfNodes](start=TWall_start);

equation
 // portIn.p = wall.p_in;
 // alpha[1] = wall.heatTransferCoeff;

  // metal-fluid heat transfer
  for j in 1:numberOfNodes loop
     alpha[j] = HT[j].alpha;
     qMetalFluid[j] = alpha[j] * (TWall[j]-fluid[j].T);
  end for;
  heatport.Q_flow = heatedArea/numberOfNodes*qMetalFluid;

  connect(heatPort, wall.port_ext)
                                  annotation (Line(points={{1.77636e-015,66},{
          1.77636e-016,66},{1.77636e-016,48.9}}, color={191,0,0}));
  connect(wall.port_int, heatport.port) annotation (Line(points={{-0.1,39.4},{
          -0.1,32.7},{0,32.7},{0,5.4}}, color={191,0,0}));

  annotation (Documentation(info="<HTML>
<p>This tube model comes with a detailed energy, but integrated momentum and mass balance.
See <a href=\"../Documents/tube_integration.pdf\"> pdf documentation </a>for details of the integration of the hydrodynamic equations.
Both heat transfer and friction pressure drop can be selected from a set of correlations.
 </p>
<h3>Model restrictions</h3>
<ul>
<li>Mass accelaration pressure drop is not considered</li>
<li>dynamic mass balance has no effect if medium is incompressible </li>
</ul>
</p>
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
                           <td>internal </td>
                </tr>
          </table>
          <p><b><font style=\"font-size: 10pt; \">License, Copyright and Disclaimer</font></b> </p>
<p>
<blockquote><br/>Licensed by Siemens AG under the Siemens Modelica License 2</blockquote>
<blockquote><br/>Copyright  2007-2012 Siemens AG. All rights reserved.</blockquote>
<blockquote><br/>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Siemens Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"../Documents/SiemensModelicaLicense2.html\">Siemens Modelica License 2 </a>.</blockquote>
        </p>

</HTML>",
      revisions="<html>
<ul>
<li> December 2006, added by Haiko Steuer
</ul>
</HTML>"), Diagram(coordinateSystem(preserveAspectRatio=true,  extent={{-100,-100},
            {100,100}}),
                   graphics),
    Icon(coordinateSystem(preserveAspectRatio=true,  extent={{-100,-100},{100,100}}),
                    graphics={Rectangle(
          extent={{-90,40},{92,54}},
          lineColor={0,0,255},
          pattern=LinePattern.None,
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid), Rectangle(
          extent={{-90,-54},{92,-40}},
          lineColor={0,0,255},
          pattern=LinePattern.None,
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid)}));
end Tube;
