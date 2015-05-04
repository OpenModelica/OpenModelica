within SiemensPower.Media.Common;
package MixtureGasNasa

import Modelica.Media.IdealGases.*;


  extends Modelica.Media.IdealGases.Common.MixtureGasNasa( mediumName="MoistAir",
     data={Common.SingleGasesData.H2O, Common.SingleGasesData.Air},
    fluidConstants={Common.FluidData.H2O,
      Common.FluidData.N2},
     substanceNames = {"Water","Air"},
     reference_X={0.0,1.0});


  redeclare replaceable function thermalConductivity
  "Return thermal conductivity for low pressure gas mixtures"
    extends Modelica.Icons.Function;
    input ThermodynamicState state "thermodynamic state record";
    output ThermalConductivity lambda "Thermal conductivity";
  input Integer method=2
    "method to compute single component thermal conductivity";
protected
  ThermalConductivity[nX] lambdaX "component thermal conductivities";
  DynamicViscosity[nX] eta "component thermal dynamic viscosities";
  SpecificHeatCapacity[nX] cp "component heat capacity";
  algorithm
  for i in 1:nX loop
      assert(fluidConstants[i].hasCriticalData, "Critical data for " +
        fluidConstants[i].chemicalFormula +
   " not known. Can not compute thermal conductivity.");
      eta[i] := Common.SingleGasNasa.dynamicViscosityLowPressure(
          state.T, fluidConstants[i].criticalTemperature,
                   fluidConstants[i].molarMass,
                   fluidConstants[i].criticalMolarVolume,
                   fluidConstants[i].acentricFactor,
                   fluidConstants[i].dipoleMoment);
      cp[i] := Common.SingleGasNasa.cp_T(data[i], state.T);
      lambdaX[i] := Common.SingleGasNasa.thermalConductivityEstimate(
          Cp=cp[i],
          eta=
      eta[i], method=method);
  end for;
  lambda := lowPressureThermalConductivity(massToMoleFractions(state.X,
                               fluidConstants[:].molarMass),
                       state.T,
                       fluidConstants[:].criticalTemperature,
                       fluidConstants[:].criticalPressure,
                       fluidConstants[:].molarMass,
                       lambdaX);
  annotation (smoothOrder=2);
  end thermalConductivity;


annotation (
      Documentation(
   info="<html>
<p>Extend of Modelica.Media.IdealGases.Common.MixtureGasNasa with <b> modified Eucken </b> method as default for thermalConductivity function.<br>
If this is not intended use Modelica.Media.IdealGases.Common.MixtureGasNasa as a base instead!
 <code><font style=\"color: #0000ff; \">&nbsp;</font></code></p> </br> <br> </br>
<table cellspacing=\"2\" cellpadding=\"0\" border=\"0\"><tr>
<td><p><b>Author:</b> </p></td>
<td><p><a href=\"mailto:julien.bonifay@siemens.com\">Julien Bonifay</a> </p></td>
<td><p><a href=\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\">SCD</a> </p></td>
</tr>
<tr>
<td><p><b>Checked by:        </b> </p></td>
<td><p><a href=\"mailto:kilian.link@siemens.com\">Kilian Link</a> </p></td>
<td><p><a href=\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z000PMEA\">SCD</a> </p></td>
</tr>
<tr>
<td><p><b>Protection class:</b> </p></td>
<td><b>internal</b></td>
<td></td>
</tr>
<tr>
<td><p><b>Used Dymola version:</b> </p></td>
<td></td>
<td></td>
</tr>
</table>
<p> Copyright &AMP;copy 2007 Siemens AG, PG EIP12. All rights reserved.</p>
<p>This model is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY. For details see <a href=\"../Documents/Disclaimer.html\">disclaimer</a> </p>
</html>",
      revisions="<html>
                      <ul>
                             <li> October 2011,  Julien Bonifay
                       </ul>
                        </html>"));
end MixtureGasNasa;
