within SiemensPowerOMCtest.Media;
package ExhaustGas "SiemensPower: Exhaust gas (6 components) for HRSGs"
  extends SiemensPowerOMCtest.Media.Common.MixtureGasNasa(
    mediumName="Exhaust gas with Ar, CO2, H20, N2, O2, and SO2",
    data={Modelica.Media.IdealGases.Common.SingleGasesData.Ar,Modelica.Media.
        IdealGases.Common.SingleGasesData.CO2,Modelica.Media.IdealGases.Common.
        SingleGasesData.H2O,Modelica.Media.IdealGases.Common.SingleGasesData.N2,
        Modelica.Media.IdealGases.Common.SingleGasesData.O2,Modelica.Media.
        IdealGases.Common.SingleGasesData.SO2},
    fluidConstants={Modelica.Media.IdealGases.Common.FluidData.Ar,Modelica.
        Media.IdealGases.Common.FluidData.CO2,Modelica.Media.IdealGases.Common.
        FluidData.H2O,Modelica.Media.IdealGases.Common.FluidData.N2,Modelica.
        Media.IdealGases.Common.FluidData.O2,Modelica.Media.IdealGases.Common.
        FluidData.SO2},
    substanceNames={"Argon","Carbone dioxide","Water","Nitrogen","Oxygen",
        "Sulphur dioxide"},
    reference_X={0.01,0.06,0.05,0.74,0.14,0.0},
    excludeEnthalpyOfFormation=false);


annotation (
      Documentation(
   info="<HTML>
                    <p>This ideal gas is a model for a flue gas composed as an ideal mixture of the following ideal gases:
                        <ul>
                             <li> Argon
                             <li> Carbon dioxide
                             <li> Water
                             <li> Nitrogen
                             <li> Oxygen
                             <li> Sulphur dioxide
                       </ul>
                    </p>
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
           For details see <a href=\"./Documents/Disclaimer.html\">disclaimer</a> <br>
        </p>
</HTML>",
      revisions="<html>
                      <ul>
                             <li> January 2007,  Haiko Steuer
                       </ul>
                        </html>"));
end ExhaustGas;
