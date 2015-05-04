within SiemensPowerOMCtest.Utilities.Functions;
function lambdaFin_der "dLambda(T)/dT for several fin materials"
    input Modelica.SIunits.Temperature T "Fin temperature";
    input String material "Fin material";
    input Real T_der "time derivative of fin temperature";
    output Real der_lambdafin "Thermal conductivity of fins";

protected
  Modelica.SIunits.Temperature TdegC;  // in degC
  Integer kennz;
  constant Real koeff[11,3] = {
  {60.476, -0.059313,  0.0},
  {60.40493, -3.1676065e-2, -1.1456087e-5},
  {57.39998, -3.5428531e-2, -2.5621113e-11},
  {49.39394, -9.3689067e-3, -2.4917634e-5},
  {44.76868, -1.6871149e-3, -2.5302164e-5},
  {35.49230, +2.0254429e-2, -4.1153893e-5},
  {18.24780, -5.5563054e-3, +1.9862635e-5},
  {25.64450, +1.1233812e-2, -6.6209222e-6},
  {23.79999, +4.0000575e-3, -8.5403705e-11},
  {23.98241, +8.2362918e-3, -5.4947890e-7},
  {17.00000, +1.0000018e-2, -2.1350926e-11}};
                                              // Standardfunktion DEFAalt
                                              // St 35.8
                                              // St 45.8
                                              // 15 Mo 3
                                              // 13 CrMo 4.4
                                              // 10 CrMo 9.10
                                              // X 8 CrNiTi 18.10
                                              // X 10 CrMoVNb 9.1
                                              // X 20 CrMoV 12.1
                                              // AISI 409
                                              // AISI 304

algorithm
 if material=="Standardfunktion DEFAalt" then
    kennz:=1;
 elseif material=="St 35.8" then
    kennz:=2;
 elseif material=="St 45.8" then
    kennz:=3;
 elseif material=="15 Mo 3" then
    kennz:=4;
 elseif material=="13 CrMo 4.4" then
    kennz:=5;
 elseif material=="10 CrMo 9.10" then
    kennz:=6;
 elseif material=="X 8 CrNiTi 18.10" then
    kennz:=7;
 elseif material=="X 10 CrMoVNb 9.1" then
    kennz:=8;
 elseif material=="X 20 CrMoV 12.1" then
    kennz:=9;
 elseif material=="AISI 409" then
    kennz:=10;
 elseif material=="AISI 304" then
    kennz:=11;
 else
    kennz:=1;
 end if;

 if (T-273.15 < 50.0) then
    TdegC :=50.0;
    der_lambdafin := 0.0;
 elseif (T-273.15 > 700) then
    TdegC :=700;
    der_lambdafin := (koeff[kennz, 2] + 2*koeff[kennz, 3]*TdegC)*T_der;
 else
    TdegC := T-273.15;
    der_lambdafin := 0.0;
 end if;

   annotation ( Documentation(
 info="<HTML>
                    <p>This function returns the time derivative of the thermal conductivity lambda(T).
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
           For details see <a href=\"./Documents/Disclaimer.html\">disclaimer</a> <br>
        </p>
</HTML>",
    revisions="<html>
                      <ul>
                             <li> November 2007 by Haiko Steuer
                       </ul>
                        </html>"));
end lambdaFin_der;
