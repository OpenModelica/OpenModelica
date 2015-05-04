within SiemensPower.Utilities.HeatTransfer;
partial model HeatTransferBaseClass
  "Base class for heat transfer correlation in terms of Nusselt number"
  import SI = Modelica.SIunits;

//  replaceable package Medium =
//      Modelica.Media.IdealGases.MixtureGases.FlueGasSixComponents
//      constrainedby Modelica.Media.Interfaces.PartialMixtureMedium annotation(Dialog(tab="Advanced", enable=false));
  parameter Integer numberOfNodes(min=1)=1 "Number of thermal port segments" annotation(Dialog(tab="Advanced", enable=false));

  parameter SI.Length lengthRe "Characteristic length for Reynolds number"                annotation(Dialog(tab="Advanced", enable=false));
  parameter SI.Length lengthNu "Characteristic length for Nusselt number"                annotation(Dialog(tab="Advanced", enable=false));
  parameter Modelica.SIunits.Area ACrossFlow "Cross flow area" annotation(Dialog(tab="Advanced", enable=false));
  parameter SI.Area AHeatTransfer "Total heat transfer area" annotation(Dialog(tab="Advanced", enable=false));

  parameter SiemensPower.Utilities.Structures.FgzGeo geoFGZ
    "Flue gas zone parameters"   annotation(Dialog(tab="No input", enable=false));
  parameter SiemensPower.Utilities.Structures.Fins geoFins "Fin parameters" annotation(Dialog(tab="No input", enable=false));
  parameter SiemensPower.Utilities.Structures.PipeGeo geoPipe "Tube parameters"
        annotation(Dialog(tab="No input", enable=false));

  parameter SI.CoefficientOfHeatTransfer alpha_start=200
    "Start/constant value of heat transfer coefficient";

 // outer input Real TWall[numberOfNodes] "Temperature of heat port";
 // input Medium.ThermodynamicState state;
 // input Medium.MassFlowRate m_flow;

//  Real Re "Reynolds number";
//  Real Pr "Prandtl number";
//  Real[numberOfNodes] Nu "Nusselt number";
//  Medium.SpecificHeatCapacity cp "Specific heat capacity";
//  Medium.DynamicViscosity eta "Dynamic viscosity";
//  Medium.ThermalConductivity lambda "Thermal conductivity";

// the following variables have to be set in derived models
 SI.CoefficientOfHeatTransfer[numberOfNodes] alpha(each start=alpha_start)
    "CoefficientOfHeatTransfer";
  Real heatingSurfaceFactor "factor for AHeatTransfer";
  Real Psi
    "crossing area shortening factor because of internals (factor for ACrossFlow)";

equation
//  cp=Medium.specificHeatCapacityCp(state);
//  eta = Medium.dynamicViscosity(state);
//  lambda = Medium.thermalConductivity(state, method=2);
//  Pr = Medium.prandtlNumber(state);
//  Re = SiemensPower.Utilities.Functions.CharacteristicNumbers.ReynoldsNumber(
//    m_flow,  lengthRe,  Psi * ACrossFlow,  eta);

 // heat transfer
 // for i in 1:numberOfNodes loop
 //     Nu[i] = SiemensPower.Utilities.Functions.CharacteristicNumbers.NusseltNumber(
 //              alpha[i], lengthNu, lambda);
 // end for;

    annotation (Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,
            -100},{100,100}}), graphics={Ellipse(
          extent={{-60,64},{60,-56}},
          lineColor={0,0,0},
          fillPattern=FillPattern.Sphere,
          fillColor={232,0,0}), Text(
          extent={{-38,26},{40,-14}},
          lineColor={0,0,0},
          fillPattern=FillPattern.Sphere,
          fillColor={232,0,0},
          textString="%name")}),
                         Documentation(info="<HTML>
<p>This is a base class for a heat transfer model usable for inner and outer heat transfer.
It is located between a vector of thermal ports on the other hand and on a (vector of) fluid flow(s) on the other hand.
In a derived class you have to specify
                    <ul>
                             <li> Nusselt numbers Nu[numberOfNodes] OR heat transfer coefficients alpha[numberOfNodes] for each thermal port
                             <li> heatingSurfaceFactor (factor for A_h because of fins or s.th.)
                             <li> Psi (factor for ACrossFlow because of internals)
                       </ul>
                    </p>
At the composing level, you have to specify the fluid flow properties:
<ul>
                             <li> fluid temperatures (input T[ns])
                             <li> fluid states [ns]
                             <li> fluid mass flow rates [ns]
                       </ul>
as well as the thermal ports [numberOfNodes].<p>
As a result, you can use the heat flow rate Q_flow[numberOfNodes], which leaves the fluid, and the thermalPort.Q_flow[numberOfNodes], which enters the fluid ports. The difference is due to the
<b>heatloss</b> to ambient.
 </HTML><HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                              <td><a href=\"mailto:kilian.link@siemens.com\">Kilian Link</a> </td>
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
<li> June 2007 by Haiko Steuer
</ul>
</HTML>"));
end HeatTransferBaseClass;
