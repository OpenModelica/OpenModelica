within SiemensPower.Media.Common;
package SingleGasNasa

import Modelica.Media.IdealGases.*;


  extends Modelica.Media.IdealGases.Common.SingleGasNasa;


  redeclare replaceable function thermalConductivity
  "thermal conductivity of gas"
  extends Modelica.Icons.Function;
  input ThermodynamicState state "thermodynamic state record";
  output ThermalConductivity lambda "Thermal conductivity";
  input Integer method=2 "1: Eucken Method, 2: Modified Eucken Method";
  algorithm
  assert(fluidConstants[1].hasCriticalData,
  "Failed to compute thermalConductivity: For the species \"" + mediumName + "\" no critical data is available.");
  lambda := thermalConductivityEstimate(specificHeatCapacityCp(state),
    dynamicViscosity(state), method=method);
  annotation (smoothOrder=2);
  end thermalConductivity;


annotation (
      Documentation(
   info="<html>
<p>Extend of Modelica.Media.IdealGases.Common.SingleGasNasa with modified Eucken method as default for thermal conductivity function.</p>
<table cellspacing=\"2\" cellpadding=\"0\" border=\"0\"><tr>
<td><p><b>Author:</b> </p></td>
<td><p><a href=\"mailto:julien.bonifay@siemens.com\">Julien Bonifay</a> </p></td>
<td><p><a href=\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\">SCD</a> </p></td>
</tr>
<tr>
<td><p><b>Checked by:</b> </p></td>
<td></td>
<td></td>
</tr>
<tr>
<td><p><br/><br/><br/><br/><br/><br/><br/><br/><b>Protection class:</b> </p></td>
<td></td>
<td></td>
</tr>
<tr>
<td><p><br/><br/><br/><br/><br/><br/><br/><br/><b>Used Dymola version:</b> </p></td>
<td></td>
<td></td>
</tr>
</table>
<p><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/>Copyright &AMP;copy 2007 Siemens AG, PG EIP12. All rights reserved.</p>
<p><br/><br/><br/><br/>This model is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY. For details see <a href=\"../Documents/Disclaimer.html\">disclaimer</a> </p>
</html>",
      revisions="<html>
                      <ul>
                             <li> October 2011,  Julien Bonifay
                       </ul>
                        </html>"));
end SingleGasNasa;
