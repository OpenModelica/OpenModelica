within SiemensPower.Utilities.PressureLoss;
model RoughnessFlow "Roughness friction independent from Re"
  extends SiemensPower.Utilities.PressureLoss.PartialFriction;
  extends SiemensPower.Utilities.PressureLoss.PartialFrictionSinglePhase;

   parameter Modelica.SIunits.MassFlowRate m_flowLaminar=0.001
    "nominal mass flow for laminar limit";
   final parameter Modelica.SIunits.Length diameterInner = geoPipe.d_out-2*geoPipe.s;
   final parameter Modelica.SIunits.Area A = Modelica.Constants.pi*0.25*diameterInner*diameterInner;
   final parameter Real zeta = (1.14-2*Modelica.Math.log10(geoPipe.r/diameterInner))^(-2)+geoPipe.zeta_add*diameterInner/geoPipe.L;

equation
  isSinglePhase = true;
 dp/dz = zeta*m_flow*(abs(m_flow)+m_flowLaminar)/(2*rho*A^2*diameterInner);

  annotation (Documentation(info="<html>
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
</HTML>"));
end RoughnessFlow;
