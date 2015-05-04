within SiemensPowerOMCtest.Utilities.HeatTransfer.InnerHeatTransfer;
model SinglePhase "turbulent single phase flow ~ cp m"
  extends
    SiemensPowerOMCtest.Utilities.HeatTransfer.InnerHeatTransfer.PartialHeatTransfer;
  extends
    SiemensPowerOMCtest.Utilities.HeatTransfer.InnerHeatTransfer.PartialHeatTransferSinglePhase;

//    parameter Modelica.SIunits.CoefficientOfHeatTransfer alpha0=0.2e3
//    "Offset for heat transfer coefficient";

   final parameter Modelica.SIunits.Area A = Modelica.Constants.pi*0.25*
      diameterInner                                                       *
      diameterInner;

equation
  isSinglePhase = true;
 // alpha = alpha0 + 0.06*cp*Modelica.Fluid.Utilities.regRoot(abs(m_flow)/A);
 alpha = 0.002*cp*max(20,abs(m_flow)/A);

    // set dummy
   xdo = 0.9;

annotation (Documentation(info="<html>
  This simple inner heat transfer correlation is good for turbulent single phase flow.
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
           For details see <a href=\"./Documents/Disclaimer.html\">disclaimer</a> <br>
        </p>
</HTML>"));
end SinglePhase;
