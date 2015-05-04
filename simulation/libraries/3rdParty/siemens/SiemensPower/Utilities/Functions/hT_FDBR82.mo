within SiemensPower.Utilities.Functions;
function hT_FDBR82
  "Specific enthalpy of a gas composition according to FDBR82 (6 component flue gas)"
  // calculating h(TGas,XGas) by integrating the function cp_FDBR82(TGas,XGas)
  // the values of TGas are considered in Grad Celsius!!
  import SI = Modelica.SIunits;
  extends Modelica.Icons.Function;

input SiemensPower.Units.Temperature TGas "Gas temp";
input Real XGas[6]={0.058436, 0.0, 0.734822, 0.053609, 0.140839, 0.012294}
    "Gas composition: CO2, SO2, N2, H2O, O2, Ar [kg/kg]";
//input Real gas[6]={0, 0, 0.7, 0, 0.3, 0}
output SiemensPower.Units.SpecificEnthalpy h "Gas specific enthalpy";

//coefficients for T<1000 degC

protected
constant Real T_0 = 273.15;

constant Real cpKoeff_1[5] = {0.188921785*0.2171539E+1,
 0.188921785*0.1038499E-1,
 -0.188921785*0.1074106E-4,
 0.188921785*0.6350127E-8,
 -0.188921785*0.1629149E-11};
constant Real cpKoeff_2[5] = {0.129793003*0.3227853E+1,
 0.129793003*0.5658868E-2,
 -0.129793003*0.2498677E-6,
 -0.129793003*0.4223474E-8,
 0.129793003*0.2140692E-11};
constant Real cpKoeff_3[5] = {0.296801173*0.3694063E+1,
 -0.296801173*0.1334139E-2,
 +0.296801173*0.2652067E-5,
 -0.296801173*0.9775312E-9,
 -0.296801173*0.9983837E-13};
constant Real cpKoeff_4[5] = {+0.461521937*0.4159259E+1,
 -0.461521937*0.1725577E-2,
 +0.461521937*0.5702012E-5,
 -0.461521937*0.4596049E-8,
 +0.461521937*0.1424309E-11};
constant Real cpKoeff_5[5] = {+0.259835056*0.3721461E+1,
 -0.259835056*0.2518398E-2,
 +0.259835056*0.8589429E-5,
 -0.259835056*0.8305377E-8,
 +0.259835056*0.2710013E-11};
constant Real cpKoeff_6 = 0.20813082*0.2501658E+1;

//coefficients for T>1000 degC

constant Real cpKoeff_1h[5] = {0.188921785*0.4415854E+1,
 + 0.188921785*0.3194408E-2,
 - 0.188921785*0.1298684E-5,
 + 0.188921785*0.2416346E-9,
 - 0.188921785*0.1675410E-13};
constant Real cpKoeff_2h[5] = {0.129793003*0.5201693E+1,
 +0.129793003*0.2060875E-2,
 -0.129793003*0.8631167E-6,
 +0.129793003*0.1664756E-9,
 -0.129793003*0.1185570E-13};
constant Real cpKoeff_3h[5] = {0.296801173*0.2856469E+1,
 +0.296801173*0.1598692E-2,
 -0.296801173*0.6260775E-6,
 +0.296801173*0.1132336E-9,
 -0.296801173*0.7694805E-14};
constant Real cpKoeff_4h[5] = {+0.461521937*0.2672525E+1,
 +0.461521937*0.3033723E-2,
 -0.461521937*0.8540818E-6,
 +0.461521937*0.1179867E-9,
 -0.461521937*0.6201465E-14};
constant Real cpKoeff_5h[5] = {+0.259835056*0.3600001E+1,
 +0.259835056*0.7819742E-3,
 -0.259835056*0.2240152E-6,
 +0.259835056*0.4251833E-10,
 -0.259835056*0.3348240E-14};
constant Real cpKoeff_6h = 0.20813082*0.2501658E+1;
Real summe;
Real error;

algorithm
summe:=sum(XGas);
error:=abs(summe - 1);
assert(error<0.01, "cp_SimitFlueGas: Illegal gas composition");   // control: in total 100%

         h :=  if (TGas<1000) then ((cpKoeff_1[5] * (TGas^5)/5
                   + cpKoeff_1[4] * (TGas^4)/4
                   + cpKoeff_1[3] * (TGas^3)/3
                     + cpKoeff_1[2] * (TGas^2)/2
                     + cpKoeff_1[1]*TGas) * XGas[1]
        +       (cpKoeff_2[5] * (TGas^5)/5
                   + cpKoeff_2[4] * (TGas^4)/4
                   + cpKoeff_2[3] * (TGas^3)/3
                     + cpKoeff_2[2] * (TGas^2)/2
                     + cpKoeff_2[1]*TGas) * XGas[2]
        +       (cpKoeff_3[5] * (TGas^5)/5
                   + cpKoeff_3[4] * (TGas^4)/4
                   + cpKoeff_3[3] * (TGas^3)/3
                     + cpKoeff_3[2] * (TGas^2)/2
                     + cpKoeff_3[1]*TGas) * XGas[3]
        +       (cpKoeff_4[5] * (TGas^5)/5
                   + cpKoeff_4[4] * (TGas^4)/4
                   + cpKoeff_4[3] * (TGas^3)/3
                     + cpKoeff_4[2] * (TGas^2)/2
                     + cpKoeff_4[1]*TGas) * XGas[4]
        +       (cpKoeff_5[5] * (TGas^5)/5
                   + cpKoeff_5[4] * (TGas^4)/4
                   + cpKoeff_5[3] * (TGas^3)/3
                     + cpKoeff_5[2] * (TGas^2)/2
                     + cpKoeff_5[1]*TGas) * XGas[5]
        + cpKoeff_6 * XGas[6]*TGas)
 else    ( (cpKoeff_1h[5] * (TGas^5)/5
                   + cpKoeff_1h[4] * (TGas^4)/4
                   + cpKoeff_1h[3] * (TGas^3)/3
                     + cpKoeff_1h[2] * (TGas^2)/2
                     + cpKoeff_1h[1]*TGas) * XGas[1]
        +       (cpKoeff_2h[5] * (TGas^5)/5
                   + cpKoeff_2h[4] * (TGas^4)/4
                   + cpKoeff_2h[3] * (TGas^3)/3
                     + cpKoeff_2h[2] * (TGas^2)/2
                     + cpKoeff_2h[1]*TGas) * XGas[2]
        +       (cpKoeff_3h[5] * (TGas^5)/5
                   + cpKoeff_3h[4] * (TGas^4)/4
                   + cpKoeff_3h[3] * (TGas^3)/3
                     + cpKoeff_3h[2] * (TGas^2)/2
                     + cpKoeff_3h[1]*TGas) * XGas[3]
        +       (cpKoeff_4h[5] * (TGas^5)/5
                   + cpKoeff_4h[4] * (TGas^4)/4
                   + cpKoeff_4h[3] * (TGas^3)/3
                     + cpKoeff_4h[2] * (TGas^2)/2
                     + cpKoeff_4h[1]*TGas) * XGas[4]
        +       (cpKoeff_5h[5] * (TGas^5)/5
                   + cpKoeff_5h[4] * (TGas^4)/4
                   + cpKoeff_5h[3] * (TGas^3)/3
                     + cpKoeff_5h[2] * (TGas^2)/2
                     + cpKoeff_5h[1]*TGas) * XGas[5]
        + cpKoeff_6h * XGas[6]*TGas);
                                   /*  -
        (
        (cpKoeff_1[5] * (T_0^5)/5
                   + cpKoeff_1[4] * (T_0^4)/4
                   + cpKoeff_1[3] * (T_0^3)/3
                     + cpKoeff_1[2] * (T_0^2)/2
                     + cpKoeff_1[1]*T_0) * XGas[1]
        +       (cpKoeff_2[5] * (T_0^5)/5
                   + cpKoeff_2[4] * (T_0^4)/4
                   + cpKoeff_2[3] * (T_0^3)/3
                     + cpKoeff_2[2] * (T_0^2)/2
                     + cpKoeff_2[1]*T_0) * XGas[2]
        +       (cpKoeff_3[5] * (T_0^5)/5
                   + cpKoeff_3[4] * (T_0^4)/4
                   + cpKoeff_3[3] * (T_0^3)/3
                     + cpKoeff_3[2] * (T_0^2)/2
                     + cpKoeff_3[1]*T_0) * XGas[3]
        +       (cpKoeff_4[5] * (T_0^5)/5
                   + cpKoeff_4[4] * (T_0^4)/4
                   + cpKoeff_4[3] * (T_0^3)/3
                     + cpKoeff_4[2] * (T_0^2)/2
                     + cpKoeff_4[1]*T_0) * XGas[4]
        +       (cpKoeff_5[5] * (T_0^5)/5
                   + cpKoeff_5[4] * (T_0^4)/4
                   + cpKoeff_5[3] * (T_0^3)/3
                     + cpKoeff_5[2] * (T_0^2)/2
                     + cpKoeff_5[1]*T_0) * XGas[5]
        + cpKoeff_6 * XGas[6]*T_0)   */
                                      /*  -
       ( (cpKoeff_1h[5] * (T_0^5)/5
                   + cpKoeff_1h[4] * (T_0^4)/4
                   + cpKoeff_1h[3] * (T_0^3)/3
                     + cpKoeff_1h[2] * (T_0^2)/2
                     + cpKoeff_1h[1]*T_0) * XGas[1]
        +       (cpKoeff_2h[5] * (T_0^5)/5
                   + cpKoeff_2h[4] * (T_0^4)/4
                   + cpKoeff_2h[3] * (T_0^3)/3
                     + cpKoeff_2h[2] * (T_0^2)/2
                     + cpKoeff_2h[1]*T_0) * XGas[2]
        +       (cpKoeff_3h[5] * (T_0^5)/5
                   + cpKoeff_3h[4] * (T_0^4)/4
                   + cpKoeff_3h[3] * (T_0^3)/3
                     + cpKoeff_3h[2] * (T_0^2)/2
                     + cpKoeff_3h[1]*T_0) * XGas[3]
        +       (cpKoeff_4h[5] * (T_0^5)/5
                   + cpKoeff_4h[4] * (T_0^4)/4
                   + cpKoeff_4h[3] * (T_0^3)/3
                     + cpKoeff_4h[2] * (T_0^2)/2
                     + cpKoeff_4h[1]*T_0) * XGas[4]
        +       (cpKoeff_5h[5] * (T_0^5)/5
                   + cpKoeff_5h[4] * (T_0^4)/4
                   + cpKoeff_5h[3] * (T_0^3)/3
                     + cpKoeff_5h[2] * (T_0^2)/2
                     + cpKoeff_5h[1]*T_0) * XGas[5]
        + cpKoeff_6h * XGas[6]*T_0)*/

/*
if (h < 1e3) then
  h :=1e3;
elseif (h > 10e6) then
  h :=10e6;
end if;
*/
//h := h;   // conversion from kJ to J

annotation (
      Documentation(
   info="<HTML>
                    <p>This function returns the specific heat capacity of an ideal composition of the following ideal gases according to the FDBR82 cpGasVon_t function
                          <br> The heat capacity depends on the TGas via a 4th order polynomial.
                        <ul>
                             <li> Carbon dioxide
                             <li> Sulphur dioxide
                             <li> Nitrogen
                             <li> Water
                             <li> Oxygen
                             <li> Argon
                       </ul>
                    </p>
                      The default gas composition matches to the reference composition of the FlueGas model.<br>
                      This cp is also implenented in Krawal modular and DynaplantII.
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
           </table>
                Copyright &copy  2007 Siemens AG, PG EIP12. All rights reserved.<br> <br>
               This model is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY.
           For details see <a href=\"../Documents/Disclaimer.html\">disclaimer</a> <br>
        </p>
</HTML>",
      revisions="<html>
                      <ul>
                             <li> December 2006, added to SiemensPower by Haiko Steuer
                             <li> original by Stefan Bennoit
                       </ul>
                        </html>"));
end hT_FDBR82;
