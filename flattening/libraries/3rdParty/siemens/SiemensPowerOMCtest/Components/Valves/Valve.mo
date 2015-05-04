within SiemensPowerOMCtest.Components.Valves;
model Valve "Valve model with flexible behavior"

  parameter Boolean hasNoReverseFlow=true "Reverse flow stopped";
  extends
    SiemensPowerOMCtest.Utilities.BaseClasses.PartialTwoPortIsenthalpicTransport(      final
      hOut_start = hIn_start, final allowFlowReversal=
                          not hasNoReverseFlow);

  import SI = Modelica.SIunits;
  import FCT = SiemensPowerOMCtest.Utilities.Functions;

  constant Real pi = Modelica.Constants.pi;

  parameter String valveType="linear valve" "water, steam/gas or linear"
      annotation(choices(choice="steam valve" "steam or gas valve",
                         choice="water valve" "water valve",
                         choice="linear valve" "linear valve m=Y*K*delta_p"));
  parameter Boolean useExplicitGeometry= true
    "Set diameter/conductance instead of computing it according to initial values and YDefault";
  parameter SI.Length diameterDefault=0.2 "Diameter" annotation (Dialog(group="Geometry for water or steam valve",enable=valveType<>"linear valve" and useExplicitGeometry));
  parameter Modelica.Fluid.Types.HydraulicConductance Kv=0.001
    "Hydraulic conductance at full opening for simple linear valve: mflow = Kv Y dp"
          annotation (Dialog(group="Geometry for linear valve",enable=valveType=="linear valve" and useExplicitGeometry));

  parameter Real YDefault=1 "Opening Y (if not set from outide)";

  // design values
   parameter Medium.SpecificEnthalpy hIn_design=hIn_start "Enthalpy at port_a"      annotation(Dialog(group="Design values (in case of no explicit geometry)", enable= not useExplicitGeometry));
  parameter Medium.AbsolutePressure pIn_design=pIn_start "Pressure at portIn" annotation(Dialog(group="Design values (in case of no explicit geometry)", enable= not useExplicitGeometry));
  parameter Medium.AbsolutePressure pOut_design=pOut_start
    "Pressure at portOut"                                                         annotation(Dialog(group="Design values (in case of no explicit geometry)", enable= not useExplicitGeometry));
  parameter Medium.MassFlowRate m_flow_design=m_flow_start "Mass flow rate" annotation(Dialog(group="Design values (in case of no explicit geometry)", enable= not useExplicitGeometry));
  parameter Real Y_design=YDefault "Valve opening" annotation(Dialog(group="Design values (in case of no explicit geometry)", enable= not useExplicitGeometry));

  parameter Real chi=8 "Spray coefficient for water valve, m ~ sqrt(1/chi)"
      annotation (Dialog(tab="Advanced",enable=valveType=="water valve"));
  parameter Real kappa=1.35 "isentropic coefficient cp/cv for steam valve"
      annotation (Dialog(tab="Advanced",enable=valveType=="steam valve"));
  parameter Real delta=0.001
    "Regularisation factor for sqrtRegularized(x,deltareg)"                           annotation (Dialog(tab="Advanced",enable=valveType<>"linear valve"));

  final parameter Modelica.Fluid.Types.HydraulicConductance Kv_design=m_flow_design/(Y_design*(pIn_design-pOut_design))
    "hydraulic conductance due to design values";
  final parameter Modelica.Fluid.Types.HydraulicConductance KLinear = (if useExplicitGeometry then Kv else Kv_design)
    "actual hydraulic conductance";
  final parameter SI.Length diameterDesign = diameterDefault*sqrt(m_flow_design/m_flowDiameter_design)
    "diameter due to design values";
  final parameter SI.Length diameterActual = (if useExplicitGeometry then diameterDefault else diameterDesign)
    "actual diameter";
  final parameter SI.Area A = pi*0.25*diameterActual^2
    "inner cross sectional area";

  Modelica.Blocks.Interfaces.RealInput Y(start=YDefault) "Opening (if desired)"
    annotation (Placement(transformation(
        origin={0,60},
        extent={{-20,-20},{20,20}},
        rotation=270)));
  Real x(start=pOut_start/pIn_start) "Pressure ratio";
  Real flowdirection;
  Medium.Density rho;

protected
  final parameter Medium.Density rho_design =  Medium.density(Medium.setState_phX(pIn_design,hIn_design,XIn_start));
  final parameter Real criticalPressureRatio = (2/(kappa+1))^(kappa/(kappa-1));
  final parameter Real x_design = max(criticalPressureRatio,pOut_design/pIn_design);
  final parameter Real RatedPsi = FCT.sqrtRegularized(kappa/(kappa-1)*(x_design^(2/kappa)-x_design^((kappa+1)/kappa)),delta);
  final parameter Medium.MassFlowRate m_flowDiameter_design = pi*0.25*diameterDefault^2*Y_design*(if (valveType=="steam valve") then RatedPsi*FCT.sqrtRegularized(2*pIn_design*rho_design,delta*pIn_design) else FCT.sqrtRegularized(2/chi*(pIn_design-pOut_design)*rho_design,delta*pIn_design));

equation
 // opening
  if cardinality(Y) == 0 then
      Y = YDefault;
  end if;

  if (dp>=0) then
      x = max(criticalPressureRatio,portOut.p/portIn.p);
      flowdirection=1;
  elseif (hasNoReverseFlow) then
      x= max(criticalPressureRatio,portIn.p/portOut.p);
      flowdirection=0;
  else    //reverse flow
      x= max(criticalPressureRatio,portIn.p/portOut.p);
      flowdirection=-1;
  end if;

  rho =  Medium.density(stateUpstream);

  if (valveType=="steam valve") then
// old Psi = PsiCrit*sqrt(1-(x-criticalPressureRatio)^2/(1-criticalPressureRatio)^2);
          m_flow = flowdirection*A*Y*FCT.sqrtRegularized(2*stateUpstream.p*rho,delta*pIn_design)*
                 FCT.sqrtRegularized(kappa/(kappa-1)*(x^(2/kappa)-x^((kappa+1)/kappa)),delta);
  elseif (valveType=="water valve") then
      m_flow = flowdirection*A*Y*FCT.sqrtRegularized(2/chi*abs(dp)*rho,delta*pIn_design);
  else
       m_flow = flowdirection*KLinear*Y*abs(dp);
  end if;

  annotation (Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,
            -100},{100,100}}), graphics={
        Polygon(
          points={{-100,40},{-100,-40},{0,0},{-100,40}},
          lineColor={0,0,0},
          pattern=LinePattern.None,
          lineThickness=0.5,
          fillPattern=FillPattern.Sphere,
          fillColor={0,128,255}),
        Polygon(
          points={{100,40},{0,0},{100,-40},{100,40}},
          lineColor={0,0,255},
          pattern=LinePattern.None,
          fillColor={0,128,255},
          fillPattern=FillPattern.Solid),
        Line(
          points={{-38,16},{-30,28},{-22,34},{-14,38},{-6,40},{4,40},{12,38},{
              20,36},{28,32},{34,24},{38,16}},
          color={0,0,0},
          thickness=1),
        Text(
          extent={{-92,-22},{96,-82}},
          lineColor={0,0,0},
          lineThickness=1,
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid,
          textString="%name")}),
                            Documentation(info="<HTML>
Model restrictions
<p><ul>
<li> the outlet enthalpy equals inlet enthalpy (neglecting increase of kinetic energy)
</ul>
</p>
<p>
Three correlations for <b>mass flow</b> vs <b>pressure loss</b> are availabe:
<ul>
<li> steam or gas valve: For ideal gas or steam taking choked flow into account (ref: <a href=\"http://de.wikipedia.org/w/index.php?title=D%C3%BCsenstr%C3%B6mung&oldid=59686117\">Strömungsdüse</a>)
<li> water valve: according to Dynaplant model
<li> linear valve: with simple linear behavior m=Y*K*delta_p
</ul>
</p>
<p>
Further options:
<ul>
<li> Using the <b>useExplicitGeometry=false</b> option, the diameter (resp hydraulic resistance KLinear) is computed from design values.
<li>The regularization <b>reg_type</b> can be used to smooth the upstream density at flow reversal.
<li>In all three models, CHECKVALVE can be chosen to avoid reverse flow.
<p>
<table>
                <tr>
                              <td><b>Author:</b>  </td>
                              <td><p><a href=\"mailto:axel.butterlin@siemens.com\">Axel Butterlin</a> </p></td>
                       <td><p><a href=\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=ZZZZZWO1\">SCD</a> </p></td>
                       </tr>
                <tr>
                           <td><b>Checked by:</b>   </td>
                           <td><a href=\"mailto:haiko.steuer@siemens.com\">Haiko Steuer</a> </td>
                        <td><a href=\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\">SCD</a> </td>
                </tr>
                <tr>
                           <td><b>Protection class:</b>    </td>
                           <td>free </td>
                </tr>
                <tr>
                           <td><b>Used Dymola version:</b>    </td>
                           <td>7.3 </td>
                  </tr>
           </table>
                Copyright &copy  2006-2010 Siemens AG. All rights reserved.<br> <br>
               This model is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY.
           For details see <a href=\"./Documents/Disclaimer.html\">disclaimer</a> <br>
</HTML>",
      revisions="<html>
<ul>
<li> March 2010, steam valve modified to support other ideal gased (parameter kappa) by Axel Butterlin
<li> December 2006, added by Haiko Steuer
</ul>
</HTML>"));
end Valve;
