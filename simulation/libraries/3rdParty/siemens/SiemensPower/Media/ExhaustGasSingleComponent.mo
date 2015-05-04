within SiemensPower.Media;
package ExhaustGasSingleComponent
  "SiemensPower: Exhaust gas(single component) for HRSGs"
  extends SiemensPower.Media.Common.SingleGasNasa(
                                              mediumName="Exhaust gas(single component) for HRSGs",
data=SiemensPower.Media.IdealGasData.ExhaustGasSingleComponent,
fluidConstants={SiemensPower.Media.IdealGasData.ExhaustGasSingleComponentConstants});
annotation (
      Documentation(
   info="<HTML>
                    <p>This ideal gas flue gas is constructed such that T=0degC at h=0 and the thermodynamic behavior equals a composition of:
                        <ul>
                             <li> Argon: 0.01
                             <li> Carbon dioxide: 0.06
                             <li> Water: 0.05
                             <li> Nitrogen: 0.74
                             <li> Oxygen: 0.14
                             <li> Sulphur dioxide: 0.00
                       </ul>
                       It is computed as a <b>single component</b> ideal gas.
                    </p>
                   </HTML><HTML>
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
                             <li> January 2007 by Haiko Steuer
                       </ul>
                        </html>"));
end ExhaustGasSingleComponent;
