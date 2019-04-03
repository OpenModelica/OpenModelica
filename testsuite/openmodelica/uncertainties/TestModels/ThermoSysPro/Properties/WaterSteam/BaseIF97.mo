within ThermoSysPro.Properties.WaterSteam;
package BaseIF97 "Modelica Physical Property Model: the new industrial formulation IAPWS-IF97"
  extends Modelica.Icons.Library;
  import SI = Modelica.SIunits;
  record IterationData "constants for iterations internal to some functions"
    extends Modelica.Icons.Record;
    constant Integer IMAX=50 "maximum number of iterations for inverse functions";
    constant Real DELP=1e-06 "maximum iteration error in pressure, Pa";
    constant Real DELS=1e-08 "maximum iteration error in specific entropy, J/{kg.K}";
    constant Real DELH=1e-08 "maximum iteration error in specific entthalpy, J/kg";
    constant Real DELD=1e-08 "maximum iteration error in density, kg/m^3";
  end IterationData;

  record data "constant IF97 data and region limits"
    extends Modelica.Icons.Record;
    constant Modelica.SIunits.SpecificHeatCapacity RH2O=461.526 "specific gas constant of water vapour";
    constant Modelica.SIunits.MolarMass MH2O=0.01801528 "molar weight of water";
    constant Modelica.SIunits.Temperature TSTAR1=1386.0 "normalization temperature for region 1 IF97";
    constant Modelica.SIunits.Pressure PSTAR1=16530000.0 "normalization pressure for region 1 IF97";
    constant Modelica.SIunits.Temperature TSTAR2=540.0 "normalization temperature for region 2 IF97";
    constant Modelica.SIunits.Pressure PSTAR2=1000000.0 "normalization pressure for region 2 IF97";
    constant Modelica.SIunits.Temperature TSTAR5=1000.0 "normalization temperature for region 5 IF97";
    constant Modelica.SIunits.Pressure PSTAR5=1000000.0 "normalization pressure for region 5 IF97";
    constant Modelica.SIunits.SpecificEnthalpy HSTAR1=2500000.0 "normalization specific enthalpy for region 1 IF97";
    constant Real IPSTAR=1e-06 "normalization pressure for inverse function in region 2 IF97";
    constant Real IHSTAR=5e-07 "normalization specific enthalpy for inverse function in region 2 IF97";
    constant Modelica.SIunits.Temperature TLIMIT1=623.15 "temperature limit between regions 1 and 3";
    constant Modelica.SIunits.Temperature TLIMIT2=1073.15 "temperature limit between regions 2 and 5";
    constant Modelica.SIunits.Temperature TLIMIT5=2273.15 "upper temperature limit of 5";
    constant Modelica.SIunits.Pressure PLIMIT1=100000000.0 "upper pressure limit for regions 1, 2 and 3";
    constant Modelica.SIunits.Pressure PLIMIT4A=16529200.0 "pressure limit between regions 1 and 2, important for for two-phase (region 4)";
    constant Modelica.SIunits.Pressure PLIMIT5=10000000.0 "upper limit of valid pressure in region 5";
    constant Modelica.SIunits.Pressure PCRIT=22064000.0 "the critical pressure";
    constant Modelica.SIunits.Temperature TCRIT=647.096 "the critical temperature";
    constant Modelica.SIunits.Density DCRIT=322.0 "the critical density";
    constant Modelica.SIunits.SpecificEntropy SCRIT=4412.02148223476 "the calculated specific entropy at the critical point";
    constant Modelica.SIunits.SpecificEnthalpy HCRIT=2087546.84511715 "the calculated specific enthalpy at the critical point";
    constant Real[5] n=array(348.05185628969, -1.1671859879975, 0.0010192970039326, 572.54459862746, 13.91883977887) "polynomial coefficients for boundary between regions 2 and 3";
    annotation(Documentation(info="<HTML>
 <h4>Record description</h4>
                           <p>Constants needed in the international steam properties IF97.
                           SCRIT and HCRIT are calculated from Helmholtz function for region 3.</p>
<h4>Version Info and Revision history
</h4>
<ul>
<li>First implemented: <i>July, 2000</i>
       by Hubertus Tummescheit
       </li>
</ul>
 <address>Author: Hubertus Tummescheit, <br>
      Modelon AB<br>
      Ideon Science Park<br>
      SE-22370 Lund, Sweden<br>
      email: hubertus@modelon.se
 </address>
<ul>
 <li>Initial version: July 2000</li>
 <li>Documentation added: December 2002</li>
</ul>
</HTML>
"));
  end data;

  record critical "critical point data"
    extends Modelica.Icons.Record;
    constant Modelica.SIunits.Pressure PCRIT=22064000.0 "the critical pressure";
    constant Modelica.SIunits.Temperature TCRIT=647.096 "the critical temperature";
    constant Modelica.SIunits.Density DCRIT=322.0 "the critical density";
    constant Modelica.SIunits.SpecificEnthalpy HCRIT=2087546.84511715 "the calculated specific enthalpy at the critical point";
    constant Modelica.SIunits.SpecificEntropy SCRIT=4412.02148223476 "the calculated specific entropy at the critical point";
    annotation(Documentation(info="<HTML>
 <h4>Record description</h4>
 <p>Critical point data for IF97 steam properties. SCRIT and HCRIT are calculated from helmholtz function for region 3 </p>
<h4>Version Info and Revision history
</h4>
<ul>
<li>First implemented: <i>July, 2000</i>
       by <a href=\"http://www.control.lth.se/~hubertus/\">Hubertus Tummescheit</a>
       </li>
</ul>
 <address>Author: Hubertus Tummescheit, <br>
      Modelon AB<br>
      Ideon Science Park<br>
      SE-22370 Lund, Sweden<br>
      email: hubertus@modelon.se
 </address>
<ul>
 <li>Initial version: July 2000</li>
 <li>Documentation added: December 2002</li>
</ul>
</HTML>
"));
  end critical;

  record triple "triple point data"
    extends Modelica.Icons.Record;
    constant Modelica.SIunits.Temperature Ttriple=273.16 "the triple point temperature";
    constant Modelica.SIunits.Pressure ptriple=611.657 "the triple point temperature";
    constant Modelica.SIunits.Density dltriple=999.792520031618 "the triple point liquid density";
    constant Modelica.SIunits.Density dvtriple=0.00485457572477861 "the triple point vapour density";
    annotation(Documentation(info="<HTML>
 <h4>Record description</h4>
 <p>Vapour/liquid/ice triple point data for IF97 steam properties.</p>
<h4>Version Info and Revision history
</h4>
<ul>
<li>First implemented: <i>July, 2000</i>
       by <a href=\"http://www.control.lth.se/~hubertus/\">Hubertus Tummescheit</a>
       </li>
</ul>
 <address>Author: Hubertus Tummescheit, <br>
      Modelon AB<br>
      Ideon Science Park<br>
      SE-22370 Lund, Sweden<br>
      email: hubertus@modelon.se
 </address>
<ul>
 <li>Initial version: July 2000</li>
 <li>Documentation added: December 2002</li>
</ul>
</HTML>
"));
  end triple;

  package Regions "functions to find the current region for given pairs of input variables"
    extends Modelica.Icons.Library;
    function boundary23ofT "boundary function for region boundary between regions 2 and 3 (input temperature)"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Temperature t "temperature (K)";
      output Modelica.SIunits.Pressure p "pressure";
    protected
      constant Real[5] n=data.n;
    algorithm
      p:=1000000.0*(n[1] + t*(n[2] + t*n[3]));
    end boundary23ofT;

    function boundary23ofp "boundary function for region boundary between regions 2 and 3 (input pressure)"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      output Modelica.SIunits.Temperature t "temperature (K)";
    protected
      constant Real[5] n=data.n;
      Real pi "dimensionless pressure";
    algorithm
      pi:=p/1000000.0;
      assert(p > triple.ptriple, "IF97 medium function boundary23ofp called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
      t:=n[4] + ((pi - n[5])/n[3])^0.5;
    end boundary23ofp;

    function hlowerofp5 "explicit lower specific enthalpy limit of region 5 as function of pressure"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
    protected
      Real pi "dimensionless pressure";
    algorithm
      pi:=p/data.PSTAR5;
      assert(p > triple.ptriple, "IF97 medium function hlowerofp5 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
      h:=461526.0*(9.01505286876203 + pi*(-0.00979043490246092 + (-2.03245575263501e-05 + 3.36540214679088e-07*pi)*pi));
    end hlowerofp5;

    function hupperofp5 "explicit upper specific enthalpy limit of region 5 as function of pressure"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
    protected
      Real pi "dimensionless pressure";
    algorithm
      pi:=p/data.PSTAR5;
      assert(p > triple.ptriple, "IF97 medium function hupperofp5 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
      h:=461526.0*(15.9838891400332 + pi*(-0.000489898813722568 + (-5.01510211858761e-08 + 7.5006972718273e-08*pi)*pi));
    end hupperofp5;

    function slowerofp5 "explicit lower specific entropy limit of region 5 as function of pressure"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      output Modelica.SIunits.SpecificEntropy s "specific entropy";
    protected
      Real pi "dimensionless pressure";
    algorithm
      pi:=p/data.PSTAR5;
      assert(p > triple.ptriple, "IF97 medium function slowerofp5 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
      s:=461.526*(18.4296209980112 + pi*(-0.00730911805860036 + (-1.68348072093888e-05 + 2.09066899426354e-07*pi)*pi) - Modelica.Math.log(pi));
    end slowerofp5;

    function supperofp5 "explicit upper specific entropy limit of region 5 as function of pressure"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      output Modelica.SIunits.SpecificEntropy s "specific entropy";
    protected
      Real pi "dimensionless pressure";
    algorithm
      pi:=p/data.PSTAR5;
      assert(p > triple.ptriple, "IF97 medium function supperofp5 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
      s:=461.526*(22.7281531474243 + pi*(-0.000656650220627603 + (-1.96109739782049e-08 + 2.19979537113031e-08*pi)*pi) - Modelica.Math.log(pi));
    end supperofp5;

    function hlowerofp1 "explicit lower specific enthalpy limit of region 1 as function of pressure"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
    protected
      Real pi1 "dimensionless pressure";
      Real[3] o "vector of auxiliary variables";
    algorithm
      pi1:=7.1 - p/data.PSTAR1;
      assert(p > triple.ptriple, "IF97 medium function hlowerofp1 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
      o[1]:=pi1*pi1;
      o[2]:=o[1]*o[1];
      o[3]:=o[2]*o[2];
      h:=639675.036*(0.173379420894777 + pi1*(-0.022914084306349 + pi1*(-0.00017146768241932 + pi1*(-4.18695814670391e-06 + pi1*(-2.41630417490008e-07 + pi1*(1.73545618580828e-11 + o[1]*pi1*(8.43755552264362e-14 + o[2]*o[3]*pi1*(5.35429206228374e-35 + o[1]*(-8.12140581014818e-38 + o[1]*o[2]*(-1.43870236842915e-44 + pi1*(1.73894459122923e-45 + (-7.06381628462585e-47 + 9.64504638626269e-49*pi1)*pi1)))))))))));
    end hlowerofp1;

    function hupperofp1 "explicit upper specific enthalpy limit of region 1 as function of pressure (meets region 4 saturation pressure curve at 623.15 K)"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
    protected
      Real pi1 "dimensionless pressure";
      Real[3] o "vector of auxiliary variables";
    algorithm
      pi1:=7.1 - p/data.PSTAR1;
      assert(p > triple.ptriple, "IF97 medium function hupperofp1 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
      o[1]:=pi1*pi1;
      o[2]:=o[1]*o[1];
      o[3]:=o[2]*o[2];
      h:=639675.036*(2.42896927729349 + pi1*(-0.00141131225285294 + pi1*(0.00143759406818289 + pi1*(0.000125338925082983 + pi1*(1.23617764767172e-05 + pi1*(3.17834967400818e-06 + o[1]*pi1*(1.46754947271665e-08 + o[2]*o[3]*pi1*(1.86779322717506e-17 + o[1]*(-4.18568363667416e-19 + o[1]*o[2]*(-9.19148577641497e-22 + pi1*(4.27026404402408e-22 + (-6.66749357417962e-23 + 3.49930466305574e-24*pi1)*pi1)))))))))));
    end hupperofp1;

    function slowerofp1 "explicit lower specific entropy limit of region 1 as function of pressure"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      output Modelica.SIunits.SpecificEntropy s "specific entropy";
    protected
      Real pi1 "dimensionless pressure";
      Real[3] o "vector of auxiliary variables";
    algorithm
      pi1:=7.1 - p/data.PSTAR1;
      assert(p > triple.ptriple, "IF97 medium function slowerofp1 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
      o[1]:=pi1*pi1;
      o[2]:=o[1]*o[1];
      o[3]:=o[2]*o[2];
      s:=461.526*(-0.0268080988194267 + pi1*(0.00834795890110168 + pi1*(-0.000486470924668433 + pi1*(-1.54902045012264e-05 + pi1*(-1.07631751351358e-06 + pi1*(9.64159058957115e-11 + o[1]*pi1*(4.81921078863103e-13 + o[2]*o[3]*pi1*(2.7879623870968e-34 + o[1]*(-4.22182957646226e-37 + o[1]*o[2]*(-7.44601427465175e-44 + pi1*(8.99540001407168e-45 + (-3.65230274480299e-46 + 4.98464639687285e-48*pi1)*pi1)))))))))));
    end slowerofp1;

    function supperofp1 "explicit upper specific entropy limit of region 1 as function of pressure (meets region 4 saturation pressure curve at 623.15 K)"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      output Modelica.SIunits.SpecificEntropy s "specific entropy";
    protected
      Real pi1 "dimensionless pressure";
      Real[3] o "vector of auxiliary variables";
    algorithm
      pi1:=7.1 - p/data.PSTAR1;
      assert(p > triple.ptriple, "IF97 medium function supperofp1 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
      o[1]:=pi1*pi1;
      o[2]:=o[1]*o[1];
      o[3]:=o[2]*o[2];
      s:=461.526*(7.28316418503422 + pi1*(0.070602197808399 + pi1*(0.0039229343647356 + pi1*(0.000313009170788845 + pi1*(3.03619398631619e-05 + pi1*(7.46739440045781e-06 + o[1]*pi1*(3.40562176858676e-08 + o[2]*o[3]*pi1*(4.21886233340801e-17 + o[1]*(-9.44504571473549e-19 + o[1]*o[2]*(-2.06859611434475e-21 + pi1*(9.60758422254987e-22 + (-1.49967810652241e-22 + 7.86863124555783e-24*pi1)*pi1)))))))))));
    end supperofp1;

    function hlowerofp2 "explicit lower specific enthalpy limit of region 2 as function of pressure (meets region 4 saturation pressure curve at 623.15 K)"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
    protected
      Real pi "dimensionless pressure";
      Real q1 "auxiliary variable";
      Real q2 "auxiliary variable";
      Real[18] o "vector of auxiliary variables";
    algorithm
      pi:=p/data.PSTAR2;
      assert(p > triple.ptriple, "IF97 medium function hlowerofp2 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
      q1:=572.54459862746 + 31.3220101646784*(-13.91883977887 + pi)^0.5;
      q2:=-0.5 + 540.0/q1;
      o[1]:=q1*q1;
      o[2]:=o[1]*o[1];
      o[3]:=o[2]*o[2];
      o[4]:=pi*pi;
      o[5]:=o[4]*o[4];
      o[6]:=q2*q2;
      o[7]:=o[6]*o[6];
      o[8]:=o[6]*o[7];
      o[9]:=o[5]*o[5];
      o[10]:=o[7]*o[7];
      o[11]:=o[9]*o[9];
      o[12]:=o[10]*o[10];
      o[13]:=o[12]*o[12];
      o[14]:=o[7]*q2;
      o[15]:=o[6]*q2;
      o[16]:=o[10]*o[6];
      o[17]:=o[13]*o[6];
      o[18]:=o[13]*o[6]*q2;
      h:=(4636975733.03507 + 3.74686560065793*o[2] + 3.57966647812489e-06*o[1]*o[2] + 2.81881548488163e-13*o[3] - 76465233.2452145*q1 - 0.00450789338787835*o[2]*q1 - 1.55131504410292e-09*o[1]*o[2]*q1 + o[1]*(2513837.07870341 - 4781981.98764471*o[10]*o[11]*o[12]*o[13]*o[4] + 49.9651389369988*o[11]*o[12]*o[13]*o[4]*o[5]*o[7] + o[15]*o[4]*(1.03746636552761e-13 - 0.00349547959376899*o[16] - 2.55074501962569e-07*o[8])*o[9] + (-242662.235426958*o[10]*o[12] - 3.46022402653609*o[16])*o[4]*o[5]*pi + o[4]*(0.109336249381227 - 2248.08924686956*o[14] - 354742.725841972*o[17] - 24.1331193696374*o[6])*pi - 3.09081828396912e-19*o[11]*o[12]*o[5]*o[7]*pi - 1.24107527851371e-08*o[11]*o[13]*o[4]*o[5]*o[6]*o[7]*pi + 3.99891272904219*o[5]*o[8]*pi + 0.0641817365250892*o[10]*o[7]*o[9]*pi + pi*(-4444.87643334512 - 75253.6156722047*o[14] - 43051.9020511789*o[6] - 22926.6247146068*q2) + o[4]*(-8.23252840892034 - 3927.0508365636*o[15] - 239.325789467604*o[18] - 76407.3727417716*o[8] - 94.4508644545118*q2) + 0.360567666582363*o[5]*(-0.0161221195808321 + q2)*(0.0338039844460968 + q2) + o[11]*(-0.000584580992538624*o[10]*o[12]*o[7] + 1332480.30241755*o[12]*o[13]*q2) + o[9]*(-73850273.6990986*o[18] + 2.24425477627799e-05*o[6]*o[7]*q2) + o[4]*o[5]*(-208438767.026518*o[17] - 1.24971648677697e-05*o[6] - 8442.30378348203*o[10]*o[6]*o[7]*q2) + o[11]*o[9]*(4.73594929247646e-22*o[10]*o[12]*q2 - 13.6411358215175*o[10]*o[12]*o[13]*q2 + 5.52427169406836e-10*o[13]*o[6]*o[7]*q2) + o[11]*o[5]*(2.67174673301715e-06*o[17] + 4.44545133805865e-18*o[12]*o[6]*q2 - 50.2465185106411*o[10]*o[13]*o[6]*o[7]*q2)))/o[1];
    end hlowerofp2;

    function hupperofp2 "explicit upper specific enthalpy limit of region 2 as function of pressure"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
    protected
      Real pi "dimensionless pressure";
      Real[2] o "vector of auxiliary variables";
    algorithm
      pi:=p/data.PSTAR2;
      assert(p > triple.ptriple, "IF97 medium function hupperofp2 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
      o[1]:=pi*pi;
      o[2]:=o[1]*o[1]*o[1];
      h:=4160663.37647071 + pi*(-4518.48617188327 + pi*(-8.53409968320258 + pi*(0.109090430596056 + pi*(-0.000172486052272327 + pi*(4.2261295097284e-15 + pi*(-1.27295130636232e-10 + pi*(-3.79407294691742e-25 + pi*(7.56960433802525e-23 + pi*(7.16825117265975e-32 + pi*(3.37267475986401e-21 + (-7.5656940729795e-74 + o[1]*(-8.00969737237617e-134 + (1.6746290980312e-65 + pi*(-3.71600586812966e-69 + pi*(8.06630589170884e-129 + (-1.76117969553159e-103 + 1.88543121025106e-84*pi)*pi)))*o[1]))*o[2]))))))))));
    end hupperofp2;

    function slowerofp2 "explicit lower specific entropy limit of region 2 as function of pressure (meets region 4 saturation pressure curve at 623.15 K)"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      output Modelica.SIunits.SpecificEntropy s "specific entropy";
    protected
      Real pi "dimensionless pressure";
      Real q1 "auxiliary variable";
      Real q2 "auxiliary variable";
      Real[40] o "vector of auxiliary variables";
    algorithm
      pi:=p/data.PSTAR2;
      assert(p > triple.ptriple, "IF97 medium function slowerofp2 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
      q1:=572.54459862746 + 31.3220101646784*(-13.91883977887 + pi)^0.5;
      q2:=-0.5 + 540.0/q1;
      o[1]:=pi*pi;
      o[2]:=o[1]*pi;
      o[3]:=o[1]*o[1];
      o[4]:=o[1]*o[3]*pi;
      o[5]:=q1*q1;
      o[6]:=o[5]*q1;
      o[7]:=1/o[5];
      o[8]:=1/q1;
      o[9]:=o[5]*o[5];
      o[10]:=o[9]*q1;
      o[11]:=q2*q2;
      o[12]:=o[11]*q2;
      o[13]:=o[1]*o[3];
      o[14]:=o[11]*o[11];
      o[15]:=o[3]*o[3];
      o[16]:=o[1]*o[15];
      o[17]:=o[11]*o[14];
      o[18]:=o[11]*o[14]*q2;
      o[19]:=o[3]*pi;
      o[20]:=o[14]*o[14];
      o[21]:=o[11]*o[20];
      o[22]:=o[15]*pi;
      o[23]:=o[14]*o[20]*q2;
      o[24]:=o[20]*o[20];
      o[25]:=o[15]*o[15];
      o[26]:=o[25]*o[3];
      o[27]:=o[14]*o[24];
      o[28]:=o[25]*o[3]*pi;
      o[29]:=o[20]*o[24]*q2;
      o[30]:=o[15]*o[25];
      o[31]:=o[24]*o[24];
      o[32]:=o[11]*o[31]*q2;
      o[33]:=o[14]*o[31];
      o[34]:=o[1]*o[25]*o[3]*pi;
      o[35]:=o[11]*o[14]*o[31]*q2;
      o[36]:=o[1]*o[25]*o[3];
      o[37]:=o[1]*o[25];
      o[38]:=o[20]*o[24]*o[31]*q2;
      o[39]:=o[14]*q2;
      o[40]:=o[11]*o[31];
      s:=461.526*(9.692768600217 + 1.22151969114703e-16*o[10] + 0.00018948987516315*o[1]*o[11] + 1.6714766451061e-11*o[12]*o[13] + 0.0039392777243355*o[1]*o[14] - 1.0406965210174e-19*o[14]*o[16] + 0.043797295650573*o[1]*o[18] - 2.2922076337661e-06*o[18]*o[19] - 2.0481737692309e-08*o[2] + 3.227767723857e-05*o[12]*o[2] + 0.0015033924542148*o[17]*o[2] - 1.1256211360459e-11*o[15]*o[20] + 1.0018179379511e-09*o[11]*o[14]*o[16]*o[20] + 1.0234747095929e-13*o[16]*o[21] - 1.9809712802088e-08*o[22]*o[23] + 0.0021171472321355*o[13]*o[24] - 8.9185845355421e-25*o[26]*o[27] - 1.2790717852285e-08*o[11]*o[3] - 4.8225372718507e-07*o[12]*o[3] - 7.3087610595061e-29*o[11]*o[20]*o[24]*o[30] - 0.10693031879409*o[11]*o[24]*o[25]*o[31] + 4.2002467698208e-06*o[24]*o[26]*o[31] - 5.5414715350778e-17*o[20]*o[30]*o[31] + 9.436970724121e-07*o[11]*o[20]*o[24]*o[30]*o[31] + 23.895741934104*o[13]*o[32] + 0.040668253562649*o[2]*o[32] - 3.0629316876232e-13*o[26]*o[32] + 2.6674547914087e-05*o[1]*o[33] + 8.2311340897998*o[15]*o[33] + 1.2768608934681e-15*o[34]*o[35] + 0.33662250574171*o[37]*o[38] + 5.905956432427e-18*o[4] + 0.038946842435739*o[29]*o[4] - 4.88368302964335e-06*o[5] - 3349017.34177133/o[6] + 2.58538448402683e-09*o[6] + 82839.5726841115*o[7] - 5446.7940672972*o[8] - 8.40318337484194e-13*o[9] + 0.0017731742473213*pi + 0.045996013696365*o[11]*pi + 0.057581259083432*o[12]*pi + 0.05032527872793*o[17]*pi + o[8]*pi*(9.63082563787332 - 0.008917431146179*q1) + 0.00811842799898148*q1 + 3.3032641670203e-05*o[1]*q2 - 4.3870667284435e-07*o[2]*q2 + 8.0882908646985e-11*o[14]*o[20]*o[24]*o[25]*q2 + 5.9056029685639e-26*o[14]*o[24]*o[28]*q2 + 7.8847309559367e-10*o[3]*q2 - 3.7826947613457e-06*o[14]*o[24]*o[31]*o[36]*q2 + 1.2621808899101e-06*o[11]*o[20]*o[4]*q2 + 540.0*o[8]*(10.08665568018 - 3.3032641670203e-05*o[1] - 6.2245802776607e-15*o[10] - 0.015757110897342*o[1]*o[12] - 5.0144299353183e-11*o[11]*o[13] + 4.1627860840696e-19*o[12]*o[16] - 0.306581069554011*o[1]*o[17] + 9.0049690883672e-11*o[15]*o[18] + 1.60454534363627e-05*o[17]*o[19] + 4.3870667284435e-07*o[2] - 9.683303171571e-05*o[11]*o[2] + 2.57526266427144e-07*o[14]*o[20]*o[22] - 1.40254511313154e-08*o[16]*o[23] - 2.34560435076256e-09*o[14]*o[20]*o[24]*o[25] - 1.24017662339842e-24*o[27]*o[28] - 7.8847309559367e-10*o[3] + 1.44676118155521e-06*o[11]*o[3] + 1.90027787547159e-27*o[29]*o[30] - 0.000960283724907132*o[1]*o[32] - 296.320827232793*o[15]*o[32] - 4.97975748452559e-14*o[11]*o[14]*o[31]*o[34] + 2.21658861403112e-15*o[30]*o[35] + 0.000200482822351322*o[14]*o[24]*o[31]*o[36] - 19.1874828272775*o[20]*o[24]*o[31]*o[37] - 5.47344301999018e-05*o[30]*o[38] - 0.0090203547252888*o[2]*o[39] - 1.38839897890111e-05*o[21]*o[4] - 0.973671060893475*o[20]*o[24]*o[4] - 836.35096769364*o[13]*o[40] - 1.42338887469272*o[2]*o[40] + 1.07202609066812e-11*o[26]*o[40] + 1.50341259240398e-05*o[5] - 1.8087714924605e-08*o[6] + 18605.6518987296*o[7] - 306.813232163376*o[8] + 1.43632471334824e-11*o[9] + 1.13103675106207e-18*o[5]*o[9] - 0.017834862292358*pi - 0.172743777250296*o[11]*pi - 0.30195167236758*o[39]*pi + o[8]*pi*(-49.6756947920742 + 0.045996013696365*q1) - 0.0003789797503263*o[1]*q2 - 0.033874355714168*o[11]*o[13]*o[14]*o[20]*q2 - 1.0234747095929e-12*o[16]*o[20]*q2 + 1.78371690710842e-23*o[11]*o[24]*o[26]*q2 + 2.558143570457e-08*o[3]*q2 + 5.3465159397045*o[24]*o[25]*o[31]*q2 - 0.000201611844951398*o[11]*o[14]*o[20]*o[26]*o[31]*q2) - Modelica.Math.log(pi));
    end slowerofp2;

    function supperofp2 "explicit upper specific entropy limit of region 2 as function of pressure"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      output Modelica.SIunits.SpecificEntropy s "specific entropy";
    protected
      Real pi "dimensionless pressure";
      Real[2] o "vector of auxiliary variables";
    algorithm
      pi:=p/data.PSTAR2;
      assert(p > triple.ptriple, "IF97 medium function supperofp2 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
      o[1]:=pi*pi;
      o[2]:=o[1]*o[1]*o[1];
      s:=8505.73409708683 - 461.526*Modelica.Math.log(pi) + pi*(-3.36563543302584 + pi*(-0.00790283552165338 + pi*(9.15558349202221e-05 + pi*(-1.59634706513e-07 + pi*(3.93449217595397e-18 + pi*(-1.18367426347994e-13 + pi*(2.72575244843195e-15 + pi*(7.04803892603536e-26 + pi*(6.67637687381772e-35 + pi*(3.1377970315132e-24 + (-7.04844558482265e-77 + o[1]*(-7.46289531275314e-137 + (1.55998511254305e-68 + pi*(-3.46166288915497e-72 + pi*(7.51557618628583e-132 + (-1.64086406733212e-106 + 1.75648443097063e-87*pi)*pi)))*o[1]))*o[2]*o[2]))))))))));
    end supperofp2;

    function d1n "density in region 1 as function of p and T"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature (K)";
      output Modelica.SIunits.Density d "density";
    protected
      Real pi "dimensionless pressure";
      Real pi1 "dimensionless pressure";
      Real tau "dimensionless temperature";
      Real tau1 "dimensionless temperature";
      Real gpi "dimensionless Gibbs-derivative w.r.t. pi";
      Real[11] o "auxiliary variables";
    algorithm
      pi:=p/data.PSTAR1;
      tau:=data.TSTAR1/T;
      pi1:=7.1 - pi;
      tau1:=tau - 1.222;
      o[1]:=tau1*tau1;
      o[2]:=o[1]*o[1];
      o[3]:=o[2]*o[2];
      o[4]:=o[1]*o[2];
      o[5]:=o[1]*tau1;
      o[6]:=o[2]*tau1;
      o[7]:=pi1*pi1;
      o[8]:=o[7]*o[7];
      o[9]:=o[8]*o[8];
      o[10]:=o[3]*o[3];
      o[11]:=o[10]*o[10];
      gpi:=pi1*(pi1*((9.5038934535162e-05 + o[2]*(8.4812393955936e-06 + 2.55615384360309e-09*o[4]))/o[2] + pi1*((8.9701127632e-06 + (2.60684891582404e-06 + 5.7366919751696e-13*o[2]*o[3])*o[5])/o[6] + pi1*(2.02584984300585e-06/o[3] + o[7]*pi1*(o[8]*o[9]*pi1*(o[7]*(o[7]*o[8]*(-7.63737668221055e-22/(o[1]*o[11]*o[2]) + pi1*(pi1*(-5.65070932023524e-23/(o[11]*o[3]) + 2.99318679335866e-24*pi1/(o[11]*o[3]*tau1)) + 3.5842867920213e-22/(o[1]*o[11]*o[2]*tau1))) - 3.33001080055983e-19/(o[1]*o[10]*o[2]*o[3]*tau1)) + 1.44400475720615e-17/(o[10]*o[2]*o[3]*tau1)) + (1.01874413933128e-08 + 1.39398969845072e-09*o[6])/(o[1]*o[3]*tau1))))) + (0.00094368642146534 + o[5]*(0.00060003561586052 + (-9.5322787813974e-05 + o[1]*(8.8283690661692e-06 + 1.45389992595188e-15*o[1]*o[2]*o[3]))*tau1))/o[5]) + (-0.00028319080123804 + o[1]*(0.00060706301565874 + o[4]*(0.018990068218419 + tau1*(0.032529748770505 + (0.021841717175414 + 5.283835796993e-05*o[1])*tau1))))/(o[3]*tau1);
      d:=p/(data.RH2O*T*pi*gpi);
    end d1n;

    function d2n "density in region 2  as function of p and T"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature (K)";
      output Modelica.SIunits.Density d "density";
    protected
      Real pi "dimensionless pressure";
      Real tau "dimensionless temperature";
      Real tau2 "dimensionless temperature";
      Real gpi "dimensionless Gibbs-derivative w.r.t. pi";
      Real[12] o "auxiliary variables";
    algorithm
      pi:=p/data.PSTAR2;
      tau:=data.TSTAR2/T;
      tau2:=tau - 0.5;
      o[1]:=tau2*tau2;
      o[2]:=o[1]*tau2;
      o[3]:=o[1]*o[1];
      o[4]:=o[3]*o[3];
      o[5]:=o[4]*o[4];
      o[6]:=o[3]*o[4]*o[5]*tau2;
      o[7]:=o[3]*o[4]*tau2;
      o[8]:=o[1]*o[3]*o[4];
      o[9]:=pi*pi;
      o[10]:=o[9]*o[9];
      o[11]:=o[3]*o[5]*tau2;
      o[12]:=o[5]*o[5];
      gpi:=(1.0 + pi*(-0.0017731742473213 + tau2*(-0.017834862292358 + tau2*(-0.045996013696365 + (-0.057581259083432 - 0.05032527872793*o[2])*tau2)) + pi*(tau2*(-6.6065283340406e-05 + (-0.0003789797503263 + o[1]*(-0.007878555448671 + o[2]*(-0.087594591301146 - 5.3349095828174e-05*o[6])))*tau2) + pi*(6.1445213076927e-08 + (1.31612001853305e-06 + o[1]*(-9.683303171571e-05 + o[2]*(-0.0045101773626444 - 0.122004760687947*o[6])))*tau2 + pi*(tau2*(-3.15389238237468e-09 + (5.116287140914e-08 + 1.92901490874028e-06*tau2)*tau2) + pi*(1.14610381688305e-05*o[1]*o[3]*tau2 + pi*(o[2]*(-1.00288598706366e-10 + o[7]*(-0.012702883392813 - 143.374451604624*o[1]*o[5]*tau2)) + pi*(-4.1341695026989e-17 + o[1]*o[4]*(-8.8352662293707e-06 - 0.272627897050173*o[8])*tau2 + pi*(o[4]*(9.0049690883672e-11 - 65.8490727183984*o[3]*o[4]*o[5]) + pi*(1.78287415218792e-07*o[7] + pi*(o[3]*(1.0406965210174e-18 + o[1]*(-1.0234747095929e-12 - 1.0018179379511e-08*o[3])*o[3]) + o[10]*o[9]*((-1.29412653835176e-09 + 1.71088510070544*o[11])*o[6] + o[9]*(-6.05920510335078*o[12]*o[4]*o[5]*tau2 + o[9]*(o[3]*o[5]*(1.78371690710842e-23 + o[1]*o[3]*o[4]*(6.1258633752464e-12 - 8.4004935396416e-05*o[7])*tau2) + pi*(-1.24017662339842e-24*o[11] + pi*(8.32192847496054e-05*o[12]*o[3]*o[5]*tau2 + pi*(o[1]*o[4]*o[5]*(1.75410265428146e-27 + (1.32995316841867e-15 - 2.26487297378904e-05*o[1]*o[5])*o[8])*pi - 2.93678005497663e-14*o[1]*o[12]*o[3]*tau2)))))))))))))))))/pi;
      d:=p/(data.RH2O*T*pi*gpi);
    end d2n;

    function dhot1ofp "density at upper temperature limit of region 1"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      output Modelica.SIunits.Density d "density";
    protected
      Real pi "dimensionless pressure";
      Real pi1 "dimensionless pressure";
      Real[4] o "auxiliary variables";
    algorithm
      pi:=p/data.PSTAR1;
      pi1:=7.1 - pi;
      o[1]:=pi1*pi1;
      o[2]:=o[1]*o[1];
      o[3]:=o[2]*o[2];
      o[4]:=o[3]*o[3];
      d:=57.4756752485113/(0.0737412153522555 + 0.000102697173772229*o[1] + 1.99080616601101e-06*o[2] + 1.35549330686006e-17*o[2]*o[4] - 3.11228834832975e-19*o[1]*o[2]*o[4] - 7.02987180039442e-22*o[2]*o[3]*o[4] - 5.17859076694812e-23*o[1]*o[2]*o[3]*o[4] + 0.00145092247736023*pi1 + 1.14683182476084e-05*o[1]*pi1 + 1.13217858826367e-08*o[1]*o[2]*pi1 + 3.29199117056433e-22*o[2]*o[3]*o[4]*pi1 + 2.73712834080283e-24*o[1]*o[2]*o[3]*o[4]*pi1);
    end dhot1ofp;

    function dupper1ofT "density at upper pressure limit of region 1"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Temperature T "temperature (K)";
      output Modelica.SIunits.Density d "density";
    protected
      Real tau "dimensionless temperature";
      Real[4] o "auxiliary variables";
    algorithm
      tau:=1386.0/T;
      o[1]:=tau*tau;
      o[2]:=o[1]*o[1];
      o[3]:=o[2]*o[2];
      o[4]:=o[3]*o[3];
      d:=57.4756752485113/(2.24144616859917 + 40.9288231166229*o[1] + 106.47246463213*o[2] + 88.4481480270751*o[1]*o[2] + 31.3207272417546*o[3] + 5.47811738891798*o[1]*o[3] + 0.515626225030717*o[2]*o[3] + 0.0274905057899089*o[1]*o[2]*o[3] + 0.000853742979250503*o[4] + 1.55932210492199e-05*o[1]*o[4] + 1.6621051480279e-07*o[2]*o[4] + 1.00606771839976e-09*o[1]*o[2]*o[4] + 3.27598951831994e-12*o[3]*o[4] + 5.20162317530099e-15*o[1]*o[3]*o[4] + 3.33501889800275e-18*o[2]*o[3]*o[4] + 5.50656040141221e-22*o[1]*o[2]*o[3]*o[4] - 13.5354267762204*tau - 78.3629702507642*o[1]*tau - 109.374479648652*o[2]*tau - 57.9035658513312*o[1]*o[2]*tau - 14.215347150565*o[3]*tau - 1.80906759985501*o[1]*o[3]*tau - 0.127542214693871*o[2]*o[3]*tau - 0.0051779458313163*o[1]*o[2]*o[3]*tau - 0.000123304142684848*o[4]*tau - 1.72405791469972e-06*o[1]*o[4]*tau - 1.39155695911655e-08*o[2]*o[4]*tau - 6.23333356847138e-11*o[1]*o[2]*o[4]*tau - 1.44056015732082e-13*o[3]*o[4]*tau - 1.50201626932938e-16*o[1]*o[3]*o[4]*tau - 5.34588682252967e-20*o[2]*o[3]*o[4]*tau - 2.73712834080283e-24*o[1]*o[2]*o[3]*o[4]*tau);
    end dupper1ofT;

    function hl_p_R4b "explicit approximation of liquid specific enthalpy on the boundary between regions 4 and 3"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
    protected
      Real x "auxiliary variable";
    algorithm
      x:=Modelica.Math.acos(p/data.PCRIT);
      h:=(1 + x*(-0.494558695817518 + x*(1.3468000165649 + x*(-3.88938815320975 + x*(6.67938547288793 + x*(-6.75820241066552 + x*(3.5589197446565 + (-0.717981855497894 - 0.000115203294561782*x)*x)))))))*data.HCRIT;
      annotation(smoothOrder=5);
    end hl_p_R4b;

    function hv_p_R4b "explicit approximation of vapour specific enthalpy on the boundary between regions 4 and 3"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
    protected
      Real x "auxiliary variable";
    algorithm
      x:=Modelica.Math.acos(p/data.PCRIT);
      h:=(1 + x*(0.488015371865569 + x*(0.207967074625069 + x*(-6.08412269842162 + x*(25.0888760229353 + x*(-48.3821518026952 + x*(45.6648916483321 + (-16.9855544296155 + 0.000661693646005769*x)*x)))))))*data.HCRIT;
      annotation(smoothOrder=5);
    end hv_p_R4b;

    function sl_p_R4b "explicit approximation of liquid specific entropy on the boundary between regions 4 and 3"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      output Modelica.SIunits.SpecificEntropy s "specific entropy";
    protected
      Real x "auxiliary variable";
    algorithm
      x:=Modelica.Math.acos(p/data.PCRIT);
      s:=(1 + x*(-0.361606922456481 + x*(0.996277863048665 + x*(-2.85955481441711 + x*(4.90630115955533 + x*(-4.97409230961421 + x*(2.62496516992045 + (-0.531995437529902 - 8.06449743188064e-05*x)*x)))))))*data.SCRIT;
      annotation(smoothOrder=5);
    end sl_p_R4b;

    function sv_p_R4b "explicit approximation of vapour specific entropy on the boundary between regions 4 and 3"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      output Modelica.SIunits.SpecificEntropy s;
    protected
      Real x "auxiliary variable";
    algorithm
      x:=Modelica.Math.acos(p/data.PCRIT);
      s:=(1 + x*(0.356826418266743 + x*(0.164245702781549 + x*(-4.42535037742245 + x*(18.3244778599831 + x*(-35.3386316259487 + x*(33.3618102581628 + (-12.4087114905858 + 0.000481004983410923*x)*x)))))))*data.SCRIT;
      annotation(smoothOrder=5);
    end sv_p_R4b;

    function rhol_p_R4b "explicit approximation of liquid density on the boundary between regions 4 and 3"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      output Modelica.SIunits.Density dl "liquid density";
    protected
      Real x "auxiliary variable";
    algorithm
      if p < data.PCRIT then
        x:=Modelica.Math.acos(p/data.PCRIT);
        dl:=(1 + x*(1.90322407909482 + x*(-2.53148618024011 + x*(-8.19144932384355 + x*(94.3419611677839 + x*(-369.367683362338 + x*(796.662791059829 + x*(-994.53853836007 + x*(673.25811770216 + (-191.430773364052 + 0.00052536560808895*x)*x)))))))))*data.DCRIT;
      else
        dl:=data.DCRIT;
      end if;
      annotation(smoothOrder=5);
    end rhol_p_R4b;

    function rhov_p_R4b "explicit approximation of vapour density on the boundary between regions 4 and 2"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      output Modelica.SIunits.Density dv "vapour density";
    protected
      Real x "auxiliary variable";
    algorithm
      if p < data.PCRIT then
        x:=Modelica.Math.acos(p/data.PCRIT);
        dv:=(1 + x*(-1.84638508033626 + x*(-1.14478727188785 + x*(59.1870220307656 + x*(-403.539143181161 + x*(1437.20072453324 + x*(-3015.85354030752 + x*(3740.57903486701 + x*(-2537.3758172539 + (725.876197580378 - 0.00111511116583323*x)*x)))))))))*data.DCRIT;
      else
        dv:=data.DCRIT;
      end if;
      annotation(smoothOrder=5);
    end rhov_p_R4b;

    function boilingcurve_p "properties on the boiling curve"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      output ThermoSysPro.Properties.WaterSteam.Common.IF97PhaseBoundaryProperties bpro "property record";
    protected
      ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs g "dimensionless Gibbs funcion and dervatives";
      ThermoSysPro.Properties.WaterSteam.Common.HelmholtzDerivs f "dimensionless Helmholtz function and dervatives";
      Modelica.SIunits.Pressure plim=min(p, data.PCRIT - 1e-07) "pressure limited to critical pressure - epsilon";
      Boolean region3boundary "true if boundary between 2-phase and region 3";
      Real pv "partial derivative of p w.r.t v";
    algorithm
      bpro.R:=data.RH2O;
      bpro.T:=Basic.tsat(plim);
      bpro.dpT:=Basic.dptofT(bpro.T);
      region3boundary:=bpro.T > data.TLIMIT1;
      if not region3boundary then
        g:=Basic.g1(p, bpro.T);
        bpro.d:=p/(bpro.R*bpro.T*g.pi*g.gpi);
        bpro.h:=if p > plim then data.HCRIT else bpro.R*bpro.T*g.tau*g.gtau;
        bpro.s:=g.R*(g.tau*g.gtau - g.g);
        bpro.cp:=-bpro.R*g.tau*g.tau*g.gtautau;
        bpro.vt:=bpro.R/p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
        bpro.vp:=bpro.R*bpro.T/(p*p)*g.pi*g.pi*g.gpipi;
        bpro.pt:=-p/bpro.T*(g.gpi - g.tau*g.gtaupi)/(g.gpipi*g.pi);
        bpro.pd:=-bpro.R*bpro.T*g.gpi*g.gpi/g.gpipi;
      else
        bpro.d:=rhol_p_R4b(plim);
        f:=Basic.f3(bpro.d, bpro.T);
        bpro.h:=hl_p_R4b(plim);
        bpro.s:=f.R*(f.tau*f.ftau - f.f);
        bpro.cv:=bpro.R*(-f.tau*f.tau*f.ftautau);
        bpro.pt:=bpro.R*bpro.d*f.delta*(f.fdelta - f.tau*f.fdeltatau);
        bpro.pd:=bpro.R*bpro.T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
        pv:=-f.d*f.d*bpro.pd;
        bpro.vp:=1/pv;
        bpro.vt:=-bpro.pt/pv;
      end if;
    end boilingcurve_p;

    function dewcurve_p "properties on the dew curve"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      output ThermoSysPro.Properties.WaterSteam.Common.IF97PhaseBoundaryProperties bpro "property record";
    protected
      ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs g "dimensionless Gibbs funcion and dervatives";
      ThermoSysPro.Properties.WaterSteam.Common.HelmholtzDerivs f "dimensionless Helmholtz function and dervatives";
      Modelica.SIunits.Pressure plim=min(p, data.PCRIT - 1e-07) "pressure limited to critical pressure - epsilon";
      Boolean region3boundary "true if boundary between 2-phase and region 3";
      Real pv "partial derivative of p w.r.t v";
    algorithm
      bpro.R:=data.RH2O;
      bpro.T:=Basic.tsat(plim);
      bpro.dpT:=Basic.dptofT(bpro.T);
      region3boundary:=bpro.T > data.TLIMIT1;
      if not region3boundary then
        g:=Basic.g2(p, bpro.T);
        bpro.d:=p/(bpro.R*bpro.T*g.pi*g.gpi);
        bpro.h:=if p > plim then data.HCRIT else bpro.R*bpro.T*g.tau*g.gtau;
        bpro.s:=g.R*(g.tau*g.gtau - g.g);
        bpro.cp:=-bpro.R*g.tau*g.tau*g.gtautau;
        bpro.vt:=bpro.R/p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
        bpro.vp:=bpro.R*bpro.T/(p*p)*g.pi*g.pi*g.gpipi;
        bpro.pt:=-p/bpro.T*(g.gpi - g.tau*g.gtaupi)/(g.gpipi*g.pi);
        bpro.pd:=-bpro.R*bpro.T*g.gpi*g.gpi/g.gpipi;
      else
        bpro.d:=rhov_p_R4b(plim);
        f:=Basic.f3(bpro.d, bpro.T);
        bpro.h:=hv_p_R4b(plim);
        bpro.s:=f.R*(f.tau*f.ftau - f.f);
        bpro.cv:=bpro.R*(-f.tau*f.tau*f.ftautau);
        bpro.pt:=bpro.R*bpro.d*f.delta*(f.fdelta - f.tau*f.fdeltatau);
        bpro.pd:=bpro.R*bpro.T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
        pv:=-f.d*f.d*bpro.pd;
        bpro.vp:=1/pv;
        bpro.vt:=-bpro.pt/pv;
      end if;
    end dewcurve_p;

    function hvl_p
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97PhaseBoundaryProperties bpro "property record";
      output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
    algorithm
      h:=bpro.h;
      annotation(derivative(noDerivative=bpro)=hvl_p_der, Inline=false, LateInline=true);
    end hvl_p;

    function hl_p "liquid specific enthalpy on the boundary between regions 4 and 3 or 1"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
    algorithm
      h:=hvl_p(p, boilingcurve_p(p));
    end hl_p;

    function hv_p "vapour specific enthalpy on the boundary between regions 4 and 3 or 2"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
    algorithm
      h:=hvl_p(p, dewcurve_p(p));
    end hv_p;

    function hvl_p_der "derivative function for the specific enthalpy along the phase boundary"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97PhaseBoundaryProperties bpro "property record";
      input Real p_der "derivative of pressure";
      output Real h_der "time derivative of specific enthalpy along the phase boundary";
    algorithm
      h_der:=(1/bpro.d - bpro.T*bpro.vt)*p_der + bpro.cp/bpro.dpT*p_der;
    end hvl_p_der;

    function rhovl_p
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97PhaseBoundaryProperties bpro "property record";
      output Modelica.SIunits.Density rho "density";
    algorithm
      rho:=bpro.d;
      annotation(derivative(noDerivative=bpro)=rhovl_p_der, Inline=false, LateInline=true);
    end rhovl_p;

    function rhol_p "density of saturated water"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "saturation pressure";
      output Modelica.SIunits.Density rho "density of steam at the condensation point";
    algorithm
      rho:=rhovl_p(p, boilingcurve_p(p));
    end rhol_p;

    function rhov_p "density of saturated vapour"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "saturation pressure";
      output Modelica.SIunits.Density rho "density of steam at the condensation point";
    algorithm
      rho:=rhovl_p(p, dewcurve_p(p));
    end rhov_p;

    function rhovl_p_der
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "saturation pressure";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97PhaseBoundaryProperties bpro "property record";
      input Real p_der "derivative of pressure";
      output Real d_der "time derivative of density along the phase boundary";
    algorithm
      d_der:=-bpro.d*bpro.d*(bpro.vp + bpro.vt/bpro.dpT)*p_der;
    end rhovl_p_der;

    function sl_p "liquid specific entropy on the boundary between regions 4 and 3 or 1"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      output Modelica.SIunits.SpecificEntropy s "specific entropy";
    protected
      Modelica.SIunits.Temperature Tsat "saturation temperature";
      Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
    algorithm
      if p < data.PLIMIT4A then
        Tsat:=Basic.tsat(p);
        (h,s):=Isentropic.handsofpT1(p, Tsat);
      elseif p < data.PCRIT then
        s:=sl_p_R4b(p);
      else
        s:=data.SCRIT;
      end if;
    end sl_p;

    function sv_p "vapour specific entropy on the boundary between regions 4 and 3 or 2"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      output Modelica.SIunits.SpecificEntropy s "specific entropy";
    protected
      Modelica.SIunits.Temperature Tsat "saturation temperature";
      Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
    algorithm
      if p < data.PLIMIT4A then
        Tsat:=Basic.tsat(p);
        (h,s):=Isentropic.handsofpT2(p, Tsat);
      elseif p < data.PCRIT then
        s:=sv_p_R4b(p);
      else
        s:=data.SCRIT;
      end if;
    end sv_p;

    function rhol_T "density of saturated water"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Temperature T "temperature";
      output Modelica.SIunits.Density d "density of water at the boiling point";
    protected
      Modelica.SIunits.Pressure p "saturation pressure";
    algorithm
      p:=Basic.psat(T);
      if T < data.TLIMIT1 then
        d:=d1n(p, T);
      elseif T < data.TCRIT then
        d:=rhol_p_R4b(p);
      else
        d:=data.DCRIT;
      end if;
    end rhol_T;

    function rhov_T "density of saturated vapour"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Temperature T "temperature";
      output Modelica.SIunits.Density d "density of steam at the condensation point";
    protected
      Modelica.SIunits.Pressure p "saturation pressure";
    algorithm
      p:=Basic.psat(T);
      if T < data.TLIMIT1 then
        d:=d2n(p, T);
      elseif T < data.TCRIT then
        d:=rhov_p_R4b(p);
      else
        d:=data.DCRIT;
      end if;
    end rhov_T;

    function region_ph "return the current region (valid values: 1,2,3,4,5) in IF97 for given pressure and specific enthalpy"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input Integer phase=0 "phase: 2 for two-phase, 1 for one phase, 0 if not known";
      input Integer mode=0 "mode: 0 means check, otherwise assume region=mode";
      output Integer region "region (valid values: 1,2,3,4,5) in IF97";
    protected
      Boolean hsubcrit;
      Modelica.SIunits.Temperature Ttest;
      constant Real[5] n=data.n;
      Modelica.SIunits.SpecificEnthalpy hl "bubble enthalpy";
      Modelica.SIunits.SpecificEnthalpy hv "dew enthalpy";
    algorithm
      if mode <> 0 then
        region:=mode;
      else
        hl:=hl_p(p);
        hv:=hv_p(p);
        if phase == 2 then
          region:=4;
        else
          if p < triple.ptriple or p > data.PLIMIT1 or h < hlowerofp1(p) or p < 10000000.0 and h > hupperofp5(p) or p >= 10000000.0 and h > hupperofp2(p) then
            region:=-1;
          else
            hsubcrit:=h < data.HCRIT;
            if p < data.PLIMIT4A then
              if hsubcrit then
                if phase == 1 then
                  region:=1;
                else
                  if h < Isentropic.hofpT1(p, Basic.tsat(p)) then
                    region:=1;
                  else
                    region:=4;
                  end if;
                end if;
              else
                if h > hlowerofp5(p) then
                  if p < data.PLIMIT5 and h < hupperofp5(p) then
                    region:=5;
                  else
                    region:=-2;
                  end if;
                else
                  if phase == 1 then
                    region:=2;
                  else
                    if h > Isentropic.hofpT2(p, Basic.tsat(p)) then
                      region:=2;
                    else
                      region:=4;
                    end if;
                  end if;
                end if;
              end if;
            else
              if hsubcrit then
                if h < hupperofp1(p) then
                  region:=1;
                else
                  if h < hl or p > data.PCRIT then
                    region:=3;
                  else
                    region:=4;
                  end if;
                end if;
              else
                if h > hlowerofp2(p) then
                  region:=2;
                else
                  if h > hv or p > data.PCRIT then
                    region:=3;
                  else
                    region:=4;
                  end if;
                end if;
              end if;
            end if;
          end if;
        end if;
      end if;
    end region_ph;

    function region_ps "return the current region (valid values: 1,2,3,4,5) in IF97 for given pressure and specific entropy"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEntropy s "specific entropy";
      input Integer phase=0 "phase: 2 for two-phase, 1 for one phase, 0 if unknown";
      input Integer mode=0 "mode: 0 means check, otherwise assume region=mode";
      output Integer region "region (valid values: 1,2,3,4,5) in IF97";
    protected
      Boolean ssubcrit;
      Modelica.SIunits.Temperature Ttest;
      constant Real[5] n=data.n;
      Modelica.SIunits.SpecificEntropy sl "bubble entropy";
      Modelica.SIunits.SpecificEntropy sv "dew entropy";
    algorithm
      if mode <> 0 then
        region:=mode;
      else
        sl:=sl_p(p);
        sv:=sv_p(p);
        if phase == 2 or phase == 0 and s > sl and s < sv and p < data.PCRIT then
          region:=4;
        else
          region:=0;
          if p < triple.ptriple then
            region:=-2;
          end if;
          if p > data.PLIMIT1 then
            region:=-3;
          end if;
          if p < 10000000.0 and s > supperofp5(p) then
            region:=-5;
          end if;
          if p >= 10000000.0 and s > supperofp2(p) then
            region:=-6;
          end if;
          if region < 0 then
            assert(false, "region computation from p and s failed: function called outside the legal region");
          else
            ssubcrit:=s < data.SCRIT;
            if p < data.PLIMIT4A then
              if ssubcrit then
                region:=1;
              else
                if s > slowerofp5(p) then
                  if p < data.PLIMIT5 and s < supperofp5(p) then
                    region:=5;
                  else
                    region:=-1;
                  end if;
                else
                  region:=2;
                end if;
              end if;
            else
              if ssubcrit then
                if s < supperofp1(p) then
                  region:=1;
                else
                  if s < sl or p > data.PCRIT then
                    region:=3;
                  else
                    region:=4;
                  end if;
                end if;
              else
                if s > slowerofp2(p) then
                  region:=2;
                else
                  if s > sv or p > data.PCRIT then
                    region:=3;
                  else
                    region:=4;
                  end if;
                end if;
              end if;
            end if;
          end if;
        end if;
      end if;
    end region_ps;

    function region_pT "return the current region (valid values: 1,2,3,5) in IF97, given pressure and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature (K)";
      input Integer mode=0 "mode: 0 means check, otherwise assume region=mode";
      output Integer region "region (valid values: 1,2,3,5) in IF97, region 4 is impossible!";
    algorithm
      if mode <> 0 then
        region:=mode;
      else
        if p < data.PLIMIT4A then
          if T > data.TLIMIT2 then
            region:=5;
          elseif T > Basic.tsat(p) then
            region:=2;
          else
            region:=1;
          end if;
        else
          if T < data.TLIMIT1 then
            region:=1;
          elseif T < boundary23ofp(p) then
            region:=3;
          else
            region:=2;
          end if;
        end if;
      end if;
    end region_pT;

    function region_dT "return the current region (valid values: 1,2,3,4,5) in IF97, given density and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "temperature (K)";
      input Integer phase=0 "phase: 2 for two-phase, 1 for one phase, 0 if not known";
      input Integer mode=0 "mode: 0 means check, otherwise assume region=mode";
      output Integer region "(valid values: 1,2,3,4,5) in IF97";
    protected
      Boolean Tovercrit "flag if overcritical temperature";
      Modelica.SIunits.Pressure p23 "pressure needed to know if region 2 or 3";
    algorithm
      Tovercrit:=T > data.TCRIT;
      if mode <> 0 then
        region:=mode;
      else
        p23:=boundary23ofT(T);
        if T > data.TLIMIT2 then
          if d < 20.5655874106483 then
            region:=5;
          else
            assert(false, "out of valid region for IF97, pressure above region 5!");
          end if;
        elseif Tovercrit then
          if d > d2n(p23, T) and T > data.TLIMIT1 then
            region:=3;
          elseif T < data.TLIMIT1 then
            region:=1;
          else
            region:=2;
          end if;

        elseif d > rhol_T(T) then
          if T < data.TLIMIT1 then
            region:=1;
          else
            region:=3;
          end if;

        elseif d < rhov_T(T) then
          if d > d2n(p23, T) and T > data.TLIMIT1 then
            region:=3;
          else
            region:=2;
          end if;
        else
          region:=4;
        end if;
      end if;
    end region_dT;

    annotation(Documentation(info="<HTML><h4>Package description</h4>
 <p>Package <b>Regions</b> contains a large number of auxiliary functions which are neede to compute the current region
 of the IAPWS/IF97 for a given pair of input variables as quickly as possible. The focus of this implementation was on
 computational efficiency, not on compact code. Many of the function values calulated in these functions could be obtained
 using the fundamental functions of IAPWS/IF97, but with considerable overhead. If the region of IAPWS/IF97 is known in advance,
 the input variable mode can be set to the region, then the somewhat costly region checks are omitted.
 The checking for the phase has to be done outside the region functions because many properties are not
 differentiable at the region boundary. If the input phase is 2, the output region will be set to 4 immediately.</p>
 <h4>Package contents</h4>
 <p> The main 4 functions in this package are the functions returning the appropriate region for two input variables.
 <ul>
 <li>Function <b>region_ph</b> compute the region of IAPWS/IF97 for input pair pressure and specific enthalpy.</li>
 <li>Function <b>region_ps</b> compute the region of IAPWS/IF97 for input pair pressure and specific entropy</li>
 <li>Function <b>region_dT</b> compute the region of IAPWS/IF97 for input pair density and temperature.</li>
 <li>Function <b>region_pT</b> compute the region of IAPWS/IF97 for input pair pressure and temperature (only ine phase region).</li>
 </ul>
 <p>In addition, functions of the boiling and condensation curves compute the specific enthalpy, specific entropy, or density on these
 curves. The functions for the saturation pressure and temperature are included in the package <b>Basic</b> because they are part of
 the original <a href=\"IF97documentation/IF97.pdf\">IAPWS/IF97 standards document</a>. These functions are also aliased to
 be used directly from package <b>Water</b>.
 </p>
 <ul>
 <li>Function <b>hl_p</b> computes the liquid specific enthalpy as a function of pressure. For overcritical pressures,
 the critical specific enthalpy is returned. An approximation is used for temperatures > 623.15 K.</li>
 <li>Function <b>hv_p</b> computes the vapour specific enthalpy as a function of pressure. For overcritical pressures,
 the critical specific enthalpy is returned. An approximation is used for temperatures > 623.15 K.</li>
 <li>Function <b>sl_p</b> computes the liquid specific entropy as a function of pressure. For overcritical pressures,
 the critical  specific entropy is returned. An approximation is used for temperatures > 623.15 K.</li>
 <li>Function <b>sv_p</b> computes the vapour  specific entropy as a function of pressure. For overcritical pressures,
 the critical  specific entropyis returned. An approximation is used for temperatures > 623.15 K.</li>
 <li>Function <b>rhol_T</b> computes the liquid density as a function of temperature. For overcritical temperatures,
 the critical density is returned. An approximation is used for temperatures > 623.15 K.</li>
 <li>Function <b>rhol_T</b> computes the vapour density as a function of temperature. For overcritical temperatures,
 the critical density is returned. An approximation is used for temperatures > 623.15 K.</li>
 </ul>
 </p>
 <p>All other functions are auxiliary functions called from the region functions to check a specific boundary.</p>
 <ul>
 <li>Function <b>boundary23ofT</b> computes the boundary pressure between regions 2 and 3 (input temperature)</li>
 <li>Function <b>boundary23ofp</b> computes the boundary temperature between regions 2 and 3 (input pressure)</li>
 <li>Function <b>hlowerofp5</b> computes the lower specific enthalpy limit of region 5 (input p, T=1073.15 K)</li>
 <li>Function <b>hupperofp5</b> computes the upper specific enthalpy limit of region 5 (input p, T=2273.15 K)</li>
 <li>Function <b>slowerofp5</b> computes the lower specific entropy limit of region 5 (input p, T=1073.15 K)</li>
 <li>Function <b>supperofp5</b> computes the upper specific entropy limit of region 5 (input p, T=2273.15 K)</li>
 <li>Function <b>hlowerofp1</b> computes the lower specific enthalpy limit of region 1 (input p, T=273.15 K)</li>
 <li>Function <b>hupperofp1</b> computes the upper specific enthalpy limit of region 1 (input p, T=623.15 K)</li>
 <li>Function <b>slowerofp1</b> computes the lower specific entropy limit of region 1 (input p, T=273.15 K)</li>
 <li>Function <b>supperofp1</b> computes the upper specific entropy limit of region 1 (input p, T=623.15 K)</li>
 <li>Function <b>hlowerofp2</b> computes the lower specific enthalpy limit of region 2 (input p, T=623.15 K)</li>
 <li>Function <b>hupperofp2</b> computes the upper specific enthalpy limit of region 2 (input p, T=1073.15 K)</li>
 <li>Function <b>slowerofp2</b> computes the lower specific entropy limit of region 2 (input p, T=623.15 K)</li>
 <li>Function <b>supperofp2</b> computes the upper specific entropy limit of region 2 (input p, T=1073.15 K)</li>
 <li>Function <b>d1n</b> computes the density in region 1 as function of pressure and temperature</li>
 <li>Function <b>d2n</b> computes the density in region 2 as function of pressure and temperature</li>
 <li>Function <b>dhot1ofp</b> computes the hot density limit of region 1 (input p, T=623.15 K)</li>
 <li>Function <b>dupper1ofT</b>computes the high pressure density limit of region 1 (input T, p=100MPa)</li>
 <li>Function <b>hl_p_R4b</b> computes a high accuracy approximation to the liquid enthalpy for temperatures > 623.15 K (input p)</li>
 <li>Function <b>hv_p_R4b</b> computes a high accuracy approximation to the vapour enthalpy for temperatures > 623.15 K (input p)</li>
 <li>Function <b>sl_p_R4b</b> computes a high accuracy approximation to the liquid entropy for temperatures > 623.15 K (input p)</li>
 <li>Function <b>sv_p_R4b</b> computes a high accuracy approximation to the vapour entropy for temperatures > 623.15 K (input p)</li>
 <li>Function <b>rhol_p_R4b</b> computes a high accuracy approximation to the liquid density for temperatures > 623.15 K (input p)</li>
 <li>Function <b>rhov_p_R4b</b> computes a high accuracy approximation to the vapour density for temperatures > 623.15 K (input p)</li>
 </ul>
 </p>
<h4>Version Info and Revision history
</h4>
 <ul>
<li>First implemented: <i>July, 2000</i>
       by <a href=\"http://www.control.lth.se/~hubertus/\">Hubertus Tummescheit</a>
       </li>
</ul>
<address>Authors: Hubertus Tummescheit, Jonas Eborn and Falko Jens Wagner<br>
      Modelon AB<br>
      Ideon Science Park<br>
      SE-22370 Lund, Sweden<br>
      email: hubertus@modelon.se
 </address>
 <ul>
 <li>Initial version: July 2000</li>
 <li>Revised and extended for inclusion in Modelica.Thermal: December 2002</li>
</ul>
</HTML>
"));
  end Regions;

  package Basic "Base functions as described in IAWPS/IF97"
    extends Modelica.Icons.Library;
    function g1 "Gibbs function for region 1: g(p,T)"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature (K)";
      output ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs g "dimensionless Gibbs funcion and dervatives wrt pi and tau";
    protected
      Real pi1 "dimensionless pressure";
      Real tau1 "dimensionless temperature";
      Real[45] o "vector of auxiliary variables";
    algorithm
      g.p:=p;
      g.T:=T;
      g.R:=data.RH2O;
      g.pi:=max(p, triple.ptriple)/data.PSTAR1;
      g.tau:=data.TSTAR1/max(T, triple.Ttriple);
      pi1:=7.1 - g.pi;
      tau1:=-1.222 + g.tau;
      o[1]:=tau1*tau1;
      o[2]:=o[1]*o[1];
      o[3]:=o[2]*o[2];
      o[4]:=o[3]*tau1;
      o[5]:=1/o[4];
      o[6]:=o[1]*o[2];
      o[7]:=o[1]*tau1;
      o[8]:=1/o[7];
      o[9]:=o[1]*o[2]*o[3];
      o[10]:=1/o[2];
      o[11]:=o[2]*tau1;
      o[12]:=1/o[11];
      o[13]:=o[2]*o[3];
      o[14]:=1/o[3];
      o[15]:=pi1*pi1;
      o[16]:=o[15]*pi1;
      o[17]:=o[15]*o[15];
      o[18]:=o[17]*o[17];
      o[19]:=o[17]*o[18]*pi1;
      o[20]:=o[15]*o[17];
      o[21]:=o[3]*o[3];
      o[22]:=o[21]*o[21];
      o[23]:=o[22]*o[3]*tau1;
      o[24]:=1/o[23];
      o[25]:=o[22]*o[3];
      o[26]:=1/o[25];
      o[27]:=o[1]*o[2]*o[22]*tau1;
      o[28]:=1/o[27];
      o[29]:=o[1]*o[2]*o[22];
      o[30]:=1/o[29];
      o[31]:=o[1]*o[2]*o[21]*o[3]*tau1;
      o[32]:=1/o[31];
      o[33]:=o[2]*o[21]*o[3]*tau1;
      o[34]:=1/o[33];
      o[35]:=o[1]*o[3]*tau1;
      o[36]:=1/o[35];
      o[37]:=o[1]*o[3];
      o[38]:=1/o[37];
      o[39]:=1/o[6];
      o[40]:=o[1]*o[22]*o[3];
      o[41]:=1/o[40];
      o[42]:=1/o[22];
      o[43]:=o[1]*o[2]*o[21]*o[3];
      o[44]:=1/o[43];
      o[45]:=1/o[13];
      g.g:=pi1*(pi1*(pi1*(o[10]*(-3.1679644845054e-05 + o[2]*(-2.8270797985312e-06 - 8.5205128120103e-10*o[6])) + pi1*(o[12]*(-2.2425281908e-06 + (-6.5171222895601e-07 - 1.4341729937924e-13*o[13])*o[7]) + pi1*(-4.0516996860117e-07*o[14] + o[16]*((-1.2734301741641e-09 - 1.7424871230634e-10*o[11])*o[36] + o[19]*(-6.8762131295531e-19*o[34] + o[15]*(1.4478307828521e-20*o[32] + o[20]*(2.6335781662795e-23*o[30] + pi1*(-1.1947622640071e-23*o[28] + pi1*(1.8228094581404e-24*o[26] - 9.3537087292458e-26*o[24]*pi1))))))))) + o[8]*(-0.00047184321073267 + o[7]*(-0.00030001780793026 + (4.7661393906987e-05 + o[1]*(-4.4141845330846e-06 - 7.2694996297594e-16*o[9]))*tau1))) + o[5]*(0.00028319080123804 + o[1]*(-0.00060706301565874 + o[6]*(-0.018990068218419 + tau1*(-0.032529748770505 + (-0.021841717175414 - 5.283835796993e-05*o[1])*tau1))))) + (0.14632971213167 + tau1*(-0.84548187169114 + tau1*(-3.756360367204 + tau1*(3.3855169168385 + tau1*(-0.95791963387872 + tau1*(0.15772038513228 + (-0.016616417199501 + 0.00081214629983568*tau1)*tau1))))))/o[1];
      g.gpi:=pi1*(pi1*(o[10]*(9.5038934535162e-05 + o[2]*(8.4812393955936e-06 + 2.55615384360309e-09*o[6])) + pi1*(o[12]*(8.9701127632e-06 + (2.60684891582404e-06 + 5.7366919751696e-13*o[13])*o[7]) + pi1*(2.02584984300585e-06*o[14] + o[16]*((1.01874413933128e-08 + 1.39398969845072e-09*o[11])*o[36] + o[19]*(1.44400475720615e-17*o[34] + o[15]*(-3.3300108005598e-19*o[32] + o[20]*(-7.6373766822106e-22*o[30] + pi1*(3.5842867920213e-22*o[28] + pi1*(-5.6507093202352e-23*o[26] + 2.99318679335866e-24*o[24]*pi1))))))))) + o[8]*(0.00094368642146534 + o[7]*(0.00060003561586052 + (-9.5322787813974e-05 + o[1]*(8.8283690661692e-06 + 1.45389992595188e-15*o[9]))*tau1))) + o[5]*(-0.00028319080123804 + o[1]*(0.00060706301565874 + o[6]*(0.018990068218419 + tau1*(0.032529748770505 + (0.021841717175414 + 5.283835796993e-05*o[1])*tau1))));
      g.gpipi:=pi1*(o[10]*(-0.000190077869070324 + o[2]*(-1.69624787911872e-05 - 5.1123076872062e-09*o[6])) + pi1*(o[12]*(-2.69103382896e-05 + (-7.8205467474721e-06 - 1.72100759255088e-12*o[13])*o[7]) + pi1*(-8.1033993720234e-06*o[14] + o[16]*((-7.131208975319e-08 - 9.757927889155e-09*o[11])*o[36] + o[19]*(-2.8880095144123e-16*o[34] + o[15]*(7.3260237612316e-18*o[32] + o[20]*(2.13846547101895e-20*o[30] + pi1*(-1.03944316968618e-20*o[28] + pi1*(1.69521279607057e-21*o[26] - 9.2788790594118e-23*o[24]*pi1))))))))) + o[8]*(-0.00094368642146534 + o[7]*(-0.00060003561586052 + (9.5322787813974e-05 + o[1]*(-8.8283690661692e-06 - 1.45389992595188e-15*o[9]))*tau1));
      g.gtau:=pi1*(o[38]*(-0.00254871721114236 + o[1]*(0.0042494411096112 + (0.018990068218419 + (-0.021841717175414 - 0.00015851507390979*o[1])*o[1])*o[6])) + pi1*(o[10]*(0.00141552963219801 + o[2]*(4.7661393906987e-05 + o[1]*(-1.32425535992538e-05 - 1.2358149370591e-14*o[9]))) + pi1*(o[12]*(0.000126718579380216 - 5.1123076872062e-09*o[37]) + pi1*(o[39]*(1.1212640954e-05 + (1.30342445791202e-06 - 1.4341729937924e-12*o[13])*o[7]) + pi1*(3.2413597488094e-06*o[5] + o[16]*((1.40077319158051e-08 + 1.04549227383804e-09*o[11])*o[45] + o[19]*(1.9941018075704e-17*o[44] + o[15]*(-4.4882754268415e-19*o[42] + o[20]*(-1.00075970318621e-21*o[28] + pi1*(4.6595728296277e-22*o[26] + pi1*(-7.2912378325616e-23*o[24] + 3.8350205789908e-24*o[41]*pi1))))))))))) + o[8]*(-0.29265942426334 + tau1*(0.84548187169114 + o[1]*(3.3855169168385 + tau1*(-1.91583926775744 + tau1*(0.47316115539684 + (-0.066465668798004 + 0.0040607314991784*tau1)*tau1)))));
      g.gtautau:=pi1*(o[36]*(0.0254871721114236 + o[1]*(-0.033995528876889 + (-0.037980136436838 - 0.00031703014781958*o[2])*o[6])) + pi1*(o[12]*(-0.005662118528792 + o[6]*(-2.64851071985076e-05 - 1.97730389929456e-13*o[9])) + pi1*((-0.00063359289690108 - 2.55615384360309e-08*o[37])*o[39] + pi1*(pi1*(-2.91722377392842e-05*o[38] + o[16]*(o[19]*(-5.9823054227112e-16*o[32] + o[15]*(o[20]*(3.9029628424262e-20*o[26] + pi1*(-1.86382913185108e-20*o[24] + pi1*(2.98940751135026e-21*o[41] - 1.61070864317613e-22*pi1/(o[1]*o[22]*o[3]*tau1)))) + 1.43624813658928e-17/(o[22]*tau1))) + (-1.68092782989661e-07 - 7.3184459168663e-09*o[11])/(o[2]*o[3]*tau1))) + (-6.7275845724e-05 + (-3.9102733737361e-06 - 1.29075569441316e-11*o[13])*o[7])/(o[1]*o[2]*tau1))))) + o[10]*(0.87797827279002 + tau1*(-1.69096374338228 + o[7]*(-1.91583926775744 + tau1*(0.94632231079368 + (-0.199397006394012 + 0.0162429259967136*tau1)*tau1))));
      g.gtaupi:=o[38]*(0.00254871721114236 + o[1]*(-0.0042494411096112 + (-0.018990068218419 + (0.021841717175414 + 0.00015851507390979*o[1])*o[1])*o[6])) + pi1*(o[10]*(-0.00283105926439602 + o[2]*(-9.5322787813974e-05 + o[1]*(2.64851071985076e-05 + 2.4716298741182e-14*o[9]))) + pi1*(o[12]*(-0.00038015573814065 + 1.53369230616185e-08*o[37]) + pi1*(o[39]*(-4.4850563816e-05 + (-5.2136978316481e-06 + 5.7366919751696e-12*o[13])*o[7]) + pi1*(-1.62067987440468e-05*o[5] + o[16]*((-1.12061855326441e-07 - 8.3639381907043e-09*o[11])*o[45] + o[19]*(-4.1876137958978e-16*o[44] + o[15]*(1.03230334817355e-17*o[42] + o[20]*(2.90220313924001e-20*o[28] + pi1*(-1.39787184888831e-20*o[26] + pi1*(2.2602837280941e-21*o[24] - 1.22720658527705e-22*o[41]*pi1))))))))));
    end g1;

    function g2 "Gibbs function for region 2: g(p,T)"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature (K)";
      output ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs g "dimensionless Gibbs funcion and dervatives wrt pi and tau";
    protected
      Real tau2 "dimensionless temperature";
      Real[55] o "vector of auxiliary variables";
    algorithm
      g.p:=p;
      g.T:=T;
      g.R:=data.RH2O;
      g.pi:=max(p, triple.ptriple)/data.PSTAR2;
      g.tau:=data.TSTAR2/max(T, triple.Ttriple);
      tau2:=-0.5 + g.tau;
      o[1]:=tau2*tau2;
      o[2]:=o[1]*tau2;
      o[3]:=-0.05032527872793*o[2];
      o[4]:=-0.057581259083432 + o[3];
      o[5]:=o[4]*tau2;
      o[6]:=-0.045996013696365 + o[5];
      o[7]:=o[6]*tau2;
      o[8]:=-0.017834862292358 + o[7];
      o[9]:=o[8]*tau2;
      o[10]:=o[1]*o[1];
      o[11]:=o[10]*o[10];
      o[12]:=o[11]*o[11];
      o[13]:=o[10]*o[11]*o[12]*tau2;
      o[14]:=o[1]*o[10]*tau2;
      o[15]:=o[10]*o[11]*tau2;
      o[16]:=o[1]*o[12]*tau2;
      o[17]:=o[1]*o[11]*tau2;
      o[18]:=o[1]*o[10]*o[11];
      o[19]:=o[10]*o[11]*o[12];
      o[20]:=o[1]*o[10];
      o[21]:=g.pi*g.pi;
      o[22]:=o[21]*o[21];
      o[23]:=o[21]*o[22];
      o[24]:=o[10]*o[12]*tau2;
      o[25]:=o[12]*o[12];
      o[26]:=o[11]*o[12]*o[25]*tau2;
      o[27]:=o[10]*o[12];
      o[28]:=o[1]*o[10]*o[11]*tau2;
      o[29]:=o[10]*o[12]*o[25]*tau2;
      o[30]:=o[1]*o[10]*o[25]*tau2;
      o[31]:=o[1]*o[11]*o[12];
      o[32]:=o[1]*o[12];
      o[33]:=g.tau*g.tau;
      o[34]:=o[33]*o[33];
      o[35]:=-5.3349095828174e-05*o[13];
      o[36]:=-0.087594591301146 + o[35];
      o[37]:=o[2]*o[36];
      o[38]:=-0.007878555448671 + o[37];
      o[39]:=o[1]*o[38];
      o[40]:=-0.0003789797503263 + o[39];
      o[41]:=o[40]*tau2;
      o[42]:=-6.6065283340406e-05 + o[41];
      o[43]:=o[42]*tau2;
      o[44]:=5.7870447262208e-06*tau2;
      o[45]:=-0.30195167236758*o[2];
      o[46]:=-0.172743777250296 + o[45];
      o[47]:=o[46]*tau2;
      o[48]:=-0.09199202739273 + o[47];
      o[49]:=o[48]*tau2;
      o[50]:=o[1]*o[11];
      o[51]:=o[10]*o[11];
      o[52]:=o[11]*o[12]*o[25];
      o[53]:=o[10]*o[12]*o[25];
      o[54]:=o[1]*o[10]*o[25];
      o[55]:=o[11]*o[12]*tau2;
      g.g:=g.pi*(-0.0017731742473213 + o[9] + g.pi*(tau2*(-3.3032641670203e-05 + (-0.00018948987516315 + o[1]*(-0.0039392777243355 + (-0.043797295650573 - 2.6674547914087e-05*o[13])*o[2]))*tau2) + g.pi*(2.0481737692309e-08 + (4.3870667284435e-07 + o[1]*(-3.227767723857e-05 + (-0.0015033924542148 - 0.040668253562649*o[13])*o[2]))*tau2 + g.pi*(g.pi*(2.2922076337661e-06*o[14] + g.pi*((-1.6714766451061e-11 + o[15]*(-0.0021171472321355 - 23.895741934104*o[16]))*o[2] + g.pi*(-5.905956432427e-18 + o[17]*(-1.2621808899101e-06 - 0.038946842435739*o[18]) + g.pi*(o[11]*(1.1256211360459e-11 - 8.2311340897998*o[19]) + g.pi*(1.9809712802088e-08*o[15] + g.pi*(o[10]*(1.0406965210174e-19 + (-1.0234747095929e-13 - 1.0018179379511e-09*o[10])*o[20]) + o[23]*(o[13]*(-8.0882908646985e-11 + 0.10693031879409*o[24]) + o[21]*(-0.33662250574171*o[26] + o[21]*(o[27]*(8.9185845355421e-25 + (3.0629316876232e-13 - 4.2002467698208e-06*o[15])*o[28]) + g.pi*(-5.9056029685639e-26*o[24] + g.pi*(3.7826947613457e-06*o[29] + g.pi*(-1.2768608934681e-15*o[30] + o[31]*(7.3087610595061e-29 + o[18]*(5.5414715350778e-17 - 9.436970724121e-07*o[32]))*g.pi)))))))))))) + tau2*(-7.8847309559367e-10 + (1.2790717852285e-08 + 4.8225372718507e-07*tau2)*tau2))))) + (-0.00560879118302 + g.tau*(0.07145273881455 + g.tau*(-0.4071049823928 + g.tau*(1.424081971444 + g.tau*(-4.38395111945 + g.tau*(-9.692768600217 + g.tau*(10.08665568018 + (-0.2840863260772 + 0.02126846353307*g.tau)*g.tau) + Modelica.Math.log(g.pi)))))))/(o[34]*g.tau);
      g.gpi:=(1.0 + g.pi*(-0.0017731742473213 + o[9] + g.pi*(o[43] + g.pi*(6.1445213076927e-08 + (1.31612001853305e-06 + o[1]*(-9.683303171571e-05 + (-0.0045101773626444 - 0.122004760687947*o[13])*o[2]))*tau2 + g.pi*(g.pi*(1.14610381688305e-05*o[14] + g.pi*((-1.00288598706366e-10 + o[15]*(-0.012702883392813 - 143.374451604624*o[16]))*o[2] + g.pi*(-4.1341695026989e-17 + o[17]*(-8.8352662293707e-06 - 0.272627897050173*o[18]) + g.pi*(o[11]*(9.0049690883672e-11 - 65.849072718398*o[19]) + g.pi*(1.78287415218792e-07*o[15] + g.pi*(o[10]*(1.0406965210174e-18 + (-1.0234747095929e-12 - 1.0018179379511e-08*o[10])*o[20]) + o[23]*(o[13]*(-1.29412653835176e-09 + 1.71088510070544*o[24]) + o[21]*(-6.0592051033508*o[26] + o[21]*(o[27]*(1.78371690710842e-23 + (6.1258633752464e-12 - 8.4004935396416e-05*o[15])*o[28]) + g.pi*(-1.24017662339842e-24*o[24] + g.pi*(8.3219284749605e-05*o[29] + g.pi*(-2.93678005497663e-14*o[30] + o[31]*(1.75410265428146e-27 + o[18]*(1.32995316841867e-15 - 2.26487297378904e-05*o[32]))*g.pi)))))))))))) + tau2*(-3.15389238237468e-09 + (5.116287140914e-08 + 1.92901490874028e-06*tau2)*tau2))))))/g.pi;
      g.gpipi:=(-1.0 + o[21]*(o[43] + g.pi*(1.22890426153854e-07 + (2.6322400370661e-06 + o[1]*(-0.00019366606343142 + (-0.0090203547252888 - 0.244009521375894*o[13])*o[2]))*tau2 + g.pi*(g.pi*(4.5844152675322e-05*o[14] + g.pi*((-5.0144299353183e-10 + o[15]*(-0.063514416964065 - 716.87225802312*o[16]))*o[2] + g.pi*(-2.48050170161934e-16 + o[17]*(-5.3011597376224e-05 - 1.63576738230104*o[18]) + g.pi*(o[11]*(6.303478361857e-10 - 460.94350902879*o[19]) + g.pi*(1.42629932175034e-06*o[15] + g.pi*(o[10]*(9.3662686891566e-18 + (-9.2112723863361e-12 - 9.0163614415599e-08*o[10])*o[20]) + o[23]*(o[13]*(-1.94118980752764e-08 + 25.6632765105816*o[24]) + o[21]*(-103.006486756963*o[26] + o[21]*(o[27]*(3.389062123506e-22 + (1.16391404129682e-10 - 0.0015960937725319*o[15])*o[28]) + g.pi*(-2.48035324679684e-23*o[24] + g.pi*(0.00174760497974171*o[29] + g.pi*(-6.4609161209486e-13*o[30] + o[31]*(4.0344361048474e-26 + o[18]*(3.05889228736295e-14 - 0.00052092078397148*o[32]))*g.pi)))))))))))) + tau2*(-9.461677147124e-09 + (1.5348861422742e-07 + o[44])*tau2)))))/o[21];
      g.gtau:=(0.0280439559151 + g.tau*(-0.2858109552582 + g.tau*(1.2213149471784 + g.tau*(-2.848163942888 + g.tau*(4.38395111945 + o[33]*(10.08665568018 + (-0.5681726521544 + 0.06380539059921*g.tau)*g.tau))))))/(o[33]*o[34]) + g.pi*(-0.017834862292358 + o[49] + g.pi*(-3.3032641670203e-05 + (-0.0003789797503263 + o[1]*(-0.015757110897342 + (-0.306581069554011 - 0.00096028372490713*o[13])*o[2]))*tau2 + g.pi*(4.3870667284435e-07 + o[1]*(-9.683303171571e-05 + (-0.0090203547252888 - 1.42338887469272*o[13])*o[2]) + g.pi*(-7.8847309559367e-10 + g.pi*(1.60454534363627e-05*o[20] + g.pi*(o[1]*(-5.0144299353183e-11 + o[15]*(-0.033874355714168 - 836.35096769364*o[16])) + g.pi*((-1.38839897890111e-05 - 0.97367106089347*o[18])*o[50] + g.pi*(o[14]*(9.0049690883672e-11 - 296.320827232793*o[19]) + g.pi*(2.57526266427144e-07*o[51] + g.pi*(o[2]*(4.1627860840696e-19 + (-1.0234747095929e-12 - 1.40254511313154e-08*o[10])*o[20]) + o[23]*(o[19]*(-2.34560435076256e-09 + 5.3465159397045*o[24]) + o[21]*(-19.1874828272775*o[52] + o[21]*(o[16]*(1.78371690710842e-23 + (1.07202609066812e-11 - 0.000201611844951398*o[15])*o[28]) + g.pi*(-1.24017662339842e-24*o[27] + g.pi*(0.000200482822351322*o[53] + g.pi*(-4.9797574845256e-14*o[54] + (1.90027787547159e-27 + o[18]*(2.21658861403112e-15 - 5.4734430199902e-05*o[32]))*o[55]*g.pi)))))))))))) + (2.558143570457e-08 + 1.44676118155521e-06*tau2)*tau2))));
      g.gtautau:=(-0.1682637354906 + g.tau*(1.429054776291 + g.tau*(-4.8852597887136 + g.tau*(8.544491828664 + g.tau*(-8.7679022389 + o[33]*(-0.5681726521544 + 0.12761078119842*g.tau)*g.tau)))))/(o[33]*o[34]*g.tau) + g.pi*(-0.09199202739273 + (-0.34548755450059 - 1.5097583618379*o[2])*tau2 + g.pi*(-0.0003789797503263 + o[1]*(-0.047271332692026 + (-1.83948641732407 - 0.03360993037175*o[13])*o[2]) + g.pi*((-0.00019366606343142 + (-0.045101773626444 - 48.395221739552*o[13])*o[2])*tau2 + g.pi*(2.558143570457e-08 + 2.89352236311042e-06*tau2 + g.pi*(9.6272720618176e-05*o[10]*tau2 + g.pi*((-1.00288598706366e-10 + o[15]*(-0.50811533571252 - 28435.9329015838*o[16]))*tau2 + g.pi*(o[11]*(-0.000138839897890111 - 23.3681054614434*o[18])*tau2 + g.pi*((6.303478361857e-10 - 10371.2289531477*o[19])*o[20] + g.pi*(3.09031519712573e-06*o[17] + g.pi*(o[1]*(1.24883582522088e-18 + (-9.2112723863361e-12 - 1.823308647071e-07*o[10])*o[20]) + o[23]*(o[1]*o[11]*o[12]*(-6.5676921821352e-08 + 261.979281045521*o[24])*tau2 + o[21]*(-1074.49903832754*o[1]*o[10]*o[12]*o[25]*tau2 + o[21]*((3.389062123506e-22 + (3.6448887082716e-10 - 0.0094757567127157*o[15])*o[28])*o[32] + g.pi*(-2.48035324679684e-23*o[16] + g.pi*(0.0104251067622687*o[1]*o[12]*o[25]*tau2 + g.pi*(o[11]*o[12]*(4.750694688679e-26 + o[18]*(8.6446955947214e-14 - 0.0031198625213944*o[32]))*g.pi - 1.89230784411972e-12*o[10]*o[25]*tau2))))))))))))))));
      g.gtaupi:=-0.017834862292358 + o[49] + g.pi*(-6.6065283340406e-05 + (-0.0007579595006526 + o[1]*(-0.031514221794684 + (-0.61316213910802 - 0.00192056744981426*o[13])*o[2]))*tau2 + g.pi*(1.31612001853305e-06 + o[1]*(-0.00029049909514713 + (-0.0270610641758664 - 4.2701666240781*o[13])*o[2]) + g.pi*(-3.15389238237468e-09 + g.pi*(8.0227267181813e-05*o[20] + g.pi*(o[1]*(-3.00865796119098e-10 + o[15]*(-0.203246134285008 - 5018.1058061618*o[16])) + g.pi*((-9.7187928523078e-05 - 6.8156974262543*o[18])*o[50] + g.pi*(o[14]*(7.2039752706938e-10 - 2370.56661786234*o[19]) + g.pi*(2.3177363978443e-06*o[51] + g.pi*(o[2]*(4.1627860840696e-18 + (-1.0234747095929e-11 - 1.40254511313154e-07*o[10])*o[20]) + o[23]*(o[19]*(-3.7529669612201e-08 + 85.544255035272*o[24]) + o[21]*(-345.37469089099*o[52] + o[21]*(o[16]*(3.5674338142168e-22 + (2.14405218133624e-10 - 0.004032236899028*o[15])*o[28]) + g.pi*(-2.60437090913668e-23*o[27] + g.pi*(0.0044106220917291*o[53] + g.pi*(-1.14534422144089e-12*o[54] + (4.5606669011318e-26 + o[18]*(5.3198126736747e-14 - 0.00131362632479764*o[32]))*o[55]*g.pi)))))))))))) + (1.0232574281828e-07 + o[44])*tau2)));
    end g2;

    function g2metastable "Gibbs function for metastable part of region 2: g(p,T)"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature (K)";
      output ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs g "dimensionless Gibbs funcion and dervatives wrt pi and tau";
    protected
      Real pi "dimensionless pressure";
      Real tau "dimensionless temperature";
      Real tau2 "dimensionless temperature";
      Real[27] o "vector of auxiliary variables";
    algorithm
      assert(p > triple.ptriple, "IF97 medium function g2metastable called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
      assert(p <= 100000000.0, "IF97 medium function g2metastable: the input pressure (= " + String(p) + " Pa) is higher than 100 Mpa");
      assert(T >= 273.15, "IF97 medium function g2metastable: the temperature (= " + String(T) + " K) is lower than 273.15 K!");
      assert(T <= 1073.15, "IF97 medium function g2metastable: the input temperature (= " + String(T) + " K) is higher than the limit of 1073.15 K");
      g.p:=p;
      g.T:=T;
      g.R:=data.RH2O;
      g.pi:=p/data.PSTAR2;
      g.tau:=data.TSTAR2/T;
      tau2:=-0.5 + g.tau;
      o[1]:=tau2*tau2;
      o[2]:=o[1]*tau2;
      o[3]:=o[1]*o[1];
      o[4]:=o[1]*o[3];
      o[5]:=-0.0040813178534455*o[4];
      o[6]:=-0.072334555213245 + o[5];
      o[7]:=o[2]*o[6];
      o[8]:=-0.088223831943146 + o[7];
      o[9]:=o[1]*o[8];
      o[10]:=o[3]*o[3];
      o[11]:=o[10]*tau2;
      o[12]:=o[10]*o[3];
      o[13]:=o[1]*o[3]*tau2;
      o[14]:=g.tau*g.tau;
      o[15]:=o[14]*o[14];
      o[16]:=-0.015238081817394*o[11];
      o[17]:=-0.106091843797284 + o[16];
      o[18]:=o[17]*o[4];
      o[19]:=0.0040195606760414 + o[18];
      o[20]:=o[19]*tau2;
      o[21]:=g.pi*g.pi;
      o[22]:=-0.0448944963879005*o[4];
      o[23]:=-0.361672776066225 + o[22];
      o[24]:=o[2]*o[23];
      o[25]:=-0.176447663886292 + o[24];
      o[26]:=o[25]*tau2;
      o[27]:=o[3]*tau2;
      g.g:=g.pi*(-0.0073362260186506 + o[9] + g.pi*(g.pi*((-0.0063498037657313 - 0.086043093028588*o[12])*o[3] + g.pi*(o[13]*(0.007532158152277 - 0.0079238375446139*o[2]) + o[11]*g.pi*(-0.00022888160778447 - 0.002645650148281*tau2))) + (0.0020097803380207 + (-0.053045921898642 - 0.007619040908697*o[11])*o[4])*tau2)) + (-0.00560879118302 + g.tau*(0.07145273881455 + g.tau*(-0.4071049823928 + g.tau*(1.424081971444 + g.tau*(-4.38395111945 + g.tau*(-9.6937268393049 + g.tau*(10.087275970006 + (-0.2840863260772 + 0.02126846353307*g.tau)*g.tau) + Modelica.Math.log(g.pi)))))))/(o[15]*g.tau);
      g.gpi:=(1.0 + g.pi*(-0.0073362260186506 + o[9] + g.pi*(o[20] + g.pi*((-0.0190494112971939 - 0.258129279085764*o[12])*o[3] + g.pi*(o[13]*(0.030128632609108 - 0.0316953501784556*o[2]) + o[11]*g.pi*(-0.00114440803892235 - 0.013228250741405*tau2))))))/g.pi;
      g.gpipi:=(-1.0 + o[21]*(o[20] + g.pi*((-0.0380988225943878 - 0.516258558171528*o[12])*o[3] + g.pi*(o[13]*(0.090385897827324 - 0.0950860505353668*o[2]) + o[11]*g.pi*(-0.0045776321556894 - 0.05291300296562*tau2)))))/o[21];
      g.gtau:=(0.0280439559151 + g.tau*(-0.2858109552582 + g.tau*(1.2213149471784 + g.tau*(-2.848163942888 + g.tau*(4.38395111945 + o[14]*(10.087275970006 + (-0.5681726521544 + 0.06380539059921*g.tau)*g.tau))))))/(o[14]*o[15]) + g.pi*(o[26] + g.pi*(0.0020097803380207 + (-0.371321453290494 - 0.121904654539152*o[11])*o[4] + g.pi*((-0.0253992150629252 - 1.37668948845741*o[12])*o[2] + g.pi*((0.052725107065939 - 0.079238375446139*o[2])*o[4] + o[10]*g.pi*(-0.00205993447006023 - 0.02645650148281*tau2)))));
      g.gtautau:=(-0.1682637354906 + g.tau*(1.429054776291 + g.tau*(-4.8852597887136 + g.tau*(8.544491828664 + g.tau*(-8.7679022389 + o[14]*(-0.5681726521544 + 0.12761078119842*g.tau)*g.tau)))))/(o[14]*o[15]*g.tau) + g.pi*(-0.176447663886292 + o[2]*(-1.4466911042649 - 0.448944963879005*o[4]) + g.pi*((-2.22792871974296 - 1.82856981808728*o[11])*o[27] + g.pi*(o[1]*(-0.0761976451887756 - 20.6503423268611*o[12]) + g.pi*((0.316350642395634 - 0.713145379015251*o[2])*o[27] + o[13]*g.pi*(-0.0164794757604818 - 0.23810851334529*tau2)))));
      g.gtaupi:=o[26] + g.pi*(0.0040195606760414 + (-0.742642906580988 - 0.243809309078304*o[11])*o[4] + g.pi*((-0.0761976451887756 - 4.13006846537222*o[12])*o[2] + g.pi*((0.210900428263756 - 0.316953501784556*o[2])*o[4] + o[10]*g.pi*(-0.0102996723503012 - 0.13228250741405*tau2))));
    end g2metastable;

    function f3 "Helmholtz function for region 3: f(d,T)"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "temperature (K)";
      output ThermoSysPro.Properties.WaterSteam.Common.HelmholtzDerivs f "dimensionless Helmholtz function and dervatives wrt delta and tau";
    protected
      Real[40] o "vector of auxiliary variables";
    algorithm
      f.T:=T;
      f.d:=d;
      f.R:=data.RH2O;
      f.tau:=data.TCRIT/T;
      f.delta:=if d == data.DCRIT and T == data.TCRIT then 1 - Modelica.Constants.eps else abs(d/data.DCRIT);
      o[1]:=f.tau*f.tau;
      o[2]:=o[1]*o[1];
      o[3]:=o[2]*f.tau;
      o[4]:=o[1]*f.tau;
      o[5]:=o[2]*o[2];
      o[6]:=o[1]*o[5]*f.tau;
      o[7]:=o[5]*f.tau;
      o[8]:=-0.64207765181607*o[1];
      o[9]:=0.88521043984318 + o[8];
      o[10]:=o[7]*o[9];
      o[11]:=-1.1524407806681 + o[10];
      o[12]:=o[11]*o[2];
      o[13]:=-1.2654315477714 + o[12];
      o[14]:=o[1]*o[13];
      o[15]:=o[1]*o[2]*o[5]*f.tau;
      o[16]:=o[2]*o[5];
      o[17]:=o[1]*o[5];
      o[18]:=o[5]*o[5];
      o[19]:=o[1]*o[18]*o[2];
      o[20]:=o[1]*o[18]*o[2]*f.tau;
      o[21]:=o[18]*o[5];
      o[22]:=o[1]*o[18]*o[5];
      o[23]:=0.25116816848616*o[2];
      o[24]:=0.078841073758308 + o[23];
      o[25]:=o[15]*o[24];
      o[26]:=-6.100523451393 + o[25];
      o[27]:=o[26]*f.tau;
      o[28]:=9.7944563083754 + o[27];
      o[29]:=o[2]*o[28];
      o[30]:=-1.70429417648412 + o[29];
      o[31]:=o[1]*o[30];
      o[32]:=f.delta*f.delta;
      o[33]:=-10.9153200808732*o[1];
      o[34]:=13.2781565976477 + o[33];
      o[35]:=o[34]*o[7];
      o[36]:=-6.9146446840086 + o[35];
      o[37]:=o[2]*o[36];
      o[38]:=-2.5308630955428 + o[37];
      o[39]:=o[38]*f.tau;
      o[40]:=o[18]*o[5]*f.tau;
      f.f:=-15.732845290239 + f.tau*(20.944396974307 + (-7.6867707878716 + o[3]*(2.6185947787954 + o[4]*(-2.808078114862 + o[1]*(1.2053369696517 - 0.0084566812812502*o[6]))))*f.tau) + f.delta*(o[14] + f.delta*(0.38493460186671 + o[1]*(-0.85214708824206 + o[2]*(4.8972281541877 + (-3.0502617256965 + o[15]*(0.039420536879154 + 0.12558408424308*o[2]))*f.tau)) + f.delta*(-0.2799932969871 + o[1]*(1.389979956946 + o[1]*(-2.018991502357 + o[16]*(-0.0082147637173963 - 0.47596035734923*o[17]))) + f.delta*(0.0439840744735 + o[1]*(-0.44476435428739 + o[1]*(0.90572070719733 + 0.70522450087967*o[19])) + f.delta*(f.delta*(-0.022175400873096 + o[1]*(0.094260751665092 + 0.16436278447961*o[21]) + f.delta*(-0.013503372241348*o[1] + f.delta*(-0.014834345352472*o[22] + f.delta*(o[1]*(0.00057922953628084 + 0.0032308904703711*o[21]) + f.delta*(8.0964802996215e-05 - 4.4923899061815e-05*f.delta*o[22] - 0.00016557679795037*f.tau))))) + (0.10770512626332 + o[1]*(-0.32913623258954 - 0.50871062041158*o[20]))*f.tau))))) + 1.0658070028513*Modelica.Math.log(f.delta);
      f.fdelta:=(1.0658070028513 + f.delta*(o[14] + f.delta*(0.76986920373342 + o[31] + f.delta*(-0.8399798909613 + o[1]*(4.169939870838 + o[1]*(-6.056974507071 + o[16]*(-0.0246442911521889 - 1.42788107204769*o[17]))) + f.delta*(0.175936297894 + o[1]*(-1.77905741714956 + o[1]*(3.6228828287893 + 2.82089800351868*o[19])) + f.delta*(f.delta*(-0.133052405238576 + o[1]*(0.56556450999055 + 0.98617670687766*o[21]) + f.delta*(-0.094523605689436*o[1] + f.delta*(-0.118674762819776*o[22] + f.delta*(o[1]*(0.0052130658265276 + 0.0290780142333399*o[21]) + f.delta*(0.00080964802996215 - 0.00049416288967996*f.delta*o[22] - 0.0016557679795037*f.tau))))) + (0.5385256313166 + o[1]*(-1.6456811629477 - 2.5435531020579*o[20]))*f.tau))))))/f.delta;
      f.fdeltadelta:=(-1.0658070028513 + o[32]*(0.76986920373342 + o[31] + f.delta*(-1.6799597819226 + o[1]*(8.339879741676 + o[1]*(-12.113949014142 + o[16]*(-0.049288582304378 - 2.85576214409538*o[17]))) + f.delta*(0.527808893682 + o[1]*(-5.3371722514487 + o[1]*(10.868648486368 + 8.462694010556*o[19])) + f.delta*(f.delta*(-0.66526202619288 + o[1]*(2.82782254995276 + 4.9308835343883*o[21]) + f.delta*(-0.56714163413662*o[1] + f.delta*(-0.83072333973843*o[22] + f.delta*(o[1]*(0.04170452661222 + 0.232624113866719*o[21]) + f.delta*(0.0072868322696594 - 0.0049416288967996*f.delta*o[22] - 0.0149019118155333*f.tau))))) + (2.1541025252664 + o[1]*(-6.5827246517908 - 10.1742124082316*o[20]))*f.tau)))))/o[32];
      f.ftau:=20.944396974307 + (-15.3735415757432 + o[3]*(18.3301634515678 + o[4]*(-28.08078114862 + o[1]*(14.4640436358204 - 0.194503669468755*o[6]))))*f.tau + f.delta*(o[39] + f.delta*(f.tau*(-1.70429417648412 + o[2]*(29.3833689251262 + (-21.3518320798755 + o[15]*(0.86725181134139 + 3.2651861903201*o[2]))*f.tau)) + f.delta*((2.779959913892 + o[1]*(-8.075966009428 + o[16]*(-0.131436219478341 - 12.37496929108*o[17])))*f.tau + f.delta*((-0.88952870857478 + o[1]*(3.6228828287893 + 18.3358370228714*o[19]))*f.tau + f.delta*(0.10770512626332 + o[1]*(-0.98740869776862 - 13.2264761307011*o[20]) + f.delta*((0.188521503330184 + 4.2734323964699*o[21])*f.tau + f.delta*(-0.027006744482696*f.tau + f.delta*(-0.38569297916427*o[40] + f.delta*(f.delta*(-0.00016557679795037 - 0.00116802137560719*f.delta*o[40]) + (0.00115845907256168 + 0.084003152229649*o[21])*f.tau)))))))));
      f.ftautau:=-15.3735415757432 + o[3]*(109.980980709407 + o[4]*(-252.72703033758 + o[1]*(159.104479994024 - 4.2790807283126*o[6]))) + f.delta*(-2.5308630955428 + o[2]*(-34.573223420043 + (185.894192367068 - 174.645121293971*o[1])*o[7]) + f.delta*(-1.70429417648412 + o[2]*(146.916844625631 + (-128.110992479253 + o[15]*(18.2122880381691 + 81.629654758002*o[2]))*f.tau) + f.delta*(2.779959913892 + o[1]*(-24.227898028284 + o[16]*(-1.97154329217511 - 309.374232277*o[17])) + f.delta*(-0.88952870857478 + o[1]*(10.868648486368 + 458.39592557179*o[19]) + f.delta*(f.delta*(0.188521503330184 + 106.835809911747*o[21] + f.delta*(-0.027006744482696 + f.delta*(-9.6423244791068*o[21] + f.delta*(0.00115845907256168 + 2.10007880574121*o[21] - 0.0292005343901797*o[21]*o[32])))) + (-1.97481739553724 - 330.66190326753*o[20])*f.tau)))));
      f.fdeltatau:=o[39] + f.delta*(f.tau*(-3.4085883529682 + o[2]*(58.766737850252 + (-42.703664159751 + o[15]*(1.73450362268278 + 6.5303723806402*o[2]))*f.tau)) + f.delta*((8.339879741676 + o[1]*(-24.227898028284 + o[16]*(-0.39430865843502 - 37.12490787324*o[17])))*f.tau + f.delta*((-3.5581148342991 + o[1]*(14.4915313151573 + 73.343348091486*o[19]))*f.tau + f.delta*(0.5385256313166 + o[1]*(-4.9370434888431 - 66.132380653505*o[20]) + f.delta*((1.1311290199811 + 25.6405943788192*o[21])*f.tau + f.delta*(-0.189047211378872*f.tau + f.delta*(-3.08554383331418*o[40] + f.delta*(f.delta*(-0.0016557679795037 - 0.0128482351316791*f.delta*o[40]) + (0.0104261316530551 + 0.75602837006684*o[21])*f.tau))))))));
    end f3;

    function g5 "base function for region 5: g(p,T)"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature (K)";
      output Modelica.Media.Common.GibbsDerivs g "dimensionless Gibbs funcion and dervatives wrt pi and tau";
    protected
      Real[11] o "vector of auxiliary variables";
    algorithm
      g.p:=p;
      g.T:=T;
      g.R:=data.RH2O;
      g.pi:=max(p, triple.ptriple)/data.PSTAR5;
      g.tau:=data.TSTAR5/max(T, triple.Ttriple);
      o[1]:=g.tau*g.tau;
      o[2]:=-0.004594282089991*o[1];
      o[3]:=0.0021774678714571 + o[2];
      o[4]:=o[3]*g.tau;
      o[5]:=o[1]*g.tau;
      o[6]:=o[1]*o[1];
      o[7]:=o[6]*o[6];
      o[8]:=o[7]*g.tau;
      o[9]:=-7.9449656719138e-06*o[8];
      o[10]:=g.pi*g.pi;
      o[11]:=-0.013782846269973*o[1];
      g.g:=g.pi*(-0.00012563183589592 + o[4] + g.pi*(-3.9724828359569e-06*o[8] + 1.2919228289784e-07*o[5]*g.pi)) + (-0.024805148933466 + g.tau*(0.36901534980333 + g.tau*(-3.1161318213925 + g.tau*(-13.179983674201 + (6.8540841634434 - 0.32961626538917*g.tau)*g.tau + Modelica.Math.log(g.pi)))))/o[5];
      g.gpi:=(1.0 + g.pi*(-0.00012563183589592 + o[4] + g.pi*(o[9] + 3.8757684869352e-07*o[5]*g.pi)))/g.pi;
      g.gpipi:=(-1.0 + o[10]*(o[9] + 7.7515369738704e-07*o[5]*g.pi))/o[10];
      g.gtau:=g.pi*(0.0021774678714571 + o[11] + g.pi*(-3.5752345523612e-05*o[7] + 3.8757684869352e-07*o[1]*g.pi)) + (0.074415446800398 + g.tau*(-0.73803069960666 + (3.1161318213925 + o[1]*(6.8540841634434 - 0.65923253077834*g.tau))*g.tau))/o[6];
      g.gtautau:=(-0.297661787201592 + g.tau*(2.21409209881998 + (-6.232263642785 - 0.65923253077834*o[5])*g.tau))/(o[6]*g.tau) + g.pi*(-0.027565692539946*g.tau + g.pi*(-0.000286018764188897*o[1]*o[6]*g.tau + 7.7515369738704e-07*g.pi*g.tau));
      g.gtaupi:=0.0021774678714571 + o[11] + g.pi*(-7.1504691047224e-05*o[7] + 1.16273054608056e-06*o[1]*g.pi);
    end g5;

    function gibbs "Gibbs function for region 1, 2 or 5: g(p,T,region)"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature (K)";
      input Integer region "IF97 region, 1, 2 or 5";
      output Real g "dimensionless Gibbs funcion";
    protected
      Modelica.Media.Common.GibbsDerivs gibbs "dimensionless Gibbs funcion and dervatives wrt pi and tau";
    algorithm
      assert(region == 1 or region == 2 or region == 5, "IF97 medium function gibbs called with wrong region (= " + String(region) + ").\n" + "Only regions 1, 2 or 5 are possible");
      if region == 1 then
        gibbs:=g1(p, T);
      elseif region == 2 then
        gibbs:=g2(p, T);
      else
        gibbs:=g5(p, T);
      end if;
      g:=gibbs.g;
    end gibbs;

    function g1pitau "derivative of g wrt pi and tau"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature (K)";
      output Real pi "dimensionless pressure";
      output Real tau "dimensionless temperature";
      output Real gpi "dimensionless dervative of Gibbs function wrt pi";
      output Real gtau "dimensionless dervative of Gibbs function wrt tau";
    protected
      Real pi1 "dimensionless pressure";
      Real tau1 "dimensionless temperature";
      Real[28] o "vector of auxiliary variables";
    algorithm
      assert(p > triple.ptriple, "IF97 medium function g1pitau called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
      assert(p <= 100000000.0, "IF97 medium function g1pitau: the input pressure (= " + String(p) + " Pa) is higher than 100 Mpa");
      assert(T >= 273.15, "IF97 medium function g1pitau: the temperature (= " + String(T) + " K) is lower than 273.15 K!");
      pi:=p/data.PSTAR1;
      tau:=data.TSTAR1/T;
      pi1:=7.1 - pi;
      tau1:=-1.222 + tau;
      o[1]:=tau1*tau1;
      o[2]:=o[1]*tau1;
      o[3]:=1/o[2];
      o[4]:=o[1]*o[1];
      o[5]:=o[4]*o[4];
      o[6]:=o[1]*o[5];
      o[7]:=o[1]*o[4];
      o[8]:=1/o[4];
      o[9]:=o[1]*o[4]*o[5];
      o[10]:=o[4]*tau1;
      o[11]:=1/o[10];
      o[12]:=o[4]*o[5];
      o[13]:=o[5]*tau1;
      o[14]:=1/o[13];
      o[15]:=pi1*pi1;
      o[16]:=o[15]*pi1;
      o[17]:=o[15]*o[15];
      o[18]:=o[17]*o[17];
      o[19]:=o[17]*o[18]*pi1;
      o[20]:=o[15]*o[17];
      o[21]:=o[5]*o[5];
      o[22]:=o[21]*o[21];
      o[23]:=o[22]*o[5]*tau1;
      o[24]:=1/o[23];
      o[25]:=o[22]*o[5];
      o[26]:=1/o[25];
      o[27]:=o[1]*o[22]*o[4]*tau1;
      o[28]:=1/o[27];
      gtau:=pi1*((-0.00254871721114236 + o[1]*(0.00424944110961118 + (0.018990068218419 + (-0.021841717175414 - 0.00015851507390979*o[1])*o[1])*o[7]))/o[6] + pi1*(o[8]*(0.00141552963219801 + o[4]*(4.7661393906987e-05 + o[1]*(-1.32425535992538e-05 - 1.2358149370591e-14*o[9]))) + pi1*(o[11]*(0.000126718579380216 - 5.11230768720618e-09*o[6]) + pi1*((1.1212640954e-05 + (1.30342445791202e-06 - 1.4341729937924e-12*o[12])*o[2])/o[7] + pi1*(3.24135974880936e-06*o[14] + o[16]*((1.40077319158051e-08 + 1.04549227383804e-09*o[10])/o[12] + o[19]*(1.9941018075704e-17/(o[1]*o[21]*o[4]*o[5]) + o[15]*(-4.48827542684151e-19/o[22] + o[20]*(-1.00075970318621e-21*o[28] + pi1*(4.65957282962769e-22*o[26] + pi1*(-7.2912378325616e-23*o[24] + 3.83502057899078e-24*pi1/(o[1]*o[22]*o[5])))))))))))) + o[3]*(-0.29265942426334 + tau1*(0.84548187169114 + o[1]*(3.3855169168385 + tau1*(-1.91583926775744 + tau1*(0.47316115539684 + (-0.066465668798004 + 0.0040607314991784*tau1)*tau1)))));
      gpi:=pi1*(pi1*((9.5038934535162e-05 + o[4]*(8.4812393955936e-06 + 2.55615384360309e-09*o[7]))*o[8] + pi1*(o[11]*(8.9701127632e-06 + (2.60684891582404e-06 + 5.7366919751696e-13*o[12])*o[2]) + pi1*(2.02584984300585e-06/o[5] + o[16]*(o[19]*(o[15]*(o[20]*(-7.63737668221055e-22/(o[1]*o[22]*o[4]) + pi1*(3.5842867920213e-22*o[28] + pi1*(-5.65070932023524e-23*o[26] + 2.99318679335866e-24*o[24]*pi1))) - 3.33001080055983e-19/(o[1]*o[21]*o[4]*o[5]*tau1)) + 1.44400475720615e-17/(o[21]*o[4]*o[5]*tau1)) + (1.01874413933128e-08 + 1.39398969845072e-09*o[10])/(o[1]*o[5]*tau1))))) + o[3]*(0.00094368642146534 + o[2]*(0.00060003561586052 + (-9.5322787813974e-05 + o[1]*(8.8283690661692e-06 + 1.45389992595188e-15*o[9]))*tau1))) + o[14]*(-0.00028319080123804 + o[1]*(0.00060706301565874 + o[7]*(0.018990068218419 + tau1*(0.032529748770505 + (0.021841717175414 + 5.283835796993e-05*o[1])*tau1))));
    end g1pitau;

    function g2pitau "derivative of g wrt pi and tau"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature (K)";
      output Real pi "dimensionless pressure";
      output Real tau "dimensionless temperature";
      output Real gpi "dimensionless dervative of Gibbs function wrt pi";
      output Real gtau "dimensionless dervative of Gibbs function wrt tau";
    protected
      Real tau2 "dimensionless temperature";
      Real[22] o "vector of auxiliary variables";
    algorithm
      assert(p > triple.ptriple, "IF97 medium function g2pitau called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
      assert(p <= 100000000.0, "IF97 medium function g2pitau: the input pressure (= " + String(p) + " Pa) is higher than 100 Mpa");
      assert(T >= 273.15, "IF97 medium function g2pitau: the temperature (= " + String(T) + " K) is lower than 273.15 K!");
      assert(T <= 1073.15, "IF97 medium function g2pitau: the input temperature (= " + String(T) + " K) is higher than the limit of 1073.15 K");
      pi:=p/data.PSTAR2;
      tau:=data.TSTAR2/T;
      tau2:=-0.5 + tau;
      o[1]:=tau*tau;
      o[2]:=o[1]*o[1];
      o[3]:=tau2*tau2;
      o[4]:=o[3]*tau2;
      o[5]:=o[3]*o[3];
      o[6]:=o[5]*o[5];
      o[7]:=o[6]*o[6];
      o[8]:=o[5]*o[6]*o[7]*tau2;
      o[9]:=o[3]*o[5];
      o[10]:=o[5]*o[6]*tau2;
      o[11]:=o[3]*o[7]*tau2;
      o[12]:=o[3]*o[5]*o[6];
      o[13]:=o[3]*o[5]*tau2;
      o[14]:=o[5]*o[6]*o[7];
      o[15]:=pi*pi;
      o[16]:=o[15]*o[15];
      o[17]:=o[15]*o[16];
      o[18]:=o[5]*o[7]*tau2;
      o[19]:=o[7]*o[7];
      o[20]:=o[3]*o[5]*o[6]*tau2;
      o[21]:=o[5]*o[7];
      o[22]:=o[3]*o[7];
      gtau:=(0.0280439559151 + tau*(-0.2858109552582 + tau*(1.2213149471784 + tau*(-2.848163942888 + tau*(4.38395111945 + o[1]*(10.08665568018 + (-0.5681726521544 + 0.06380539059921*tau)*tau))))))/(o[1]*o[2]) + pi*(-0.017834862292358 + tau2*(-0.09199202739273 + (-0.172743777250296 - 0.30195167236758*o[4])*tau2) + pi*(-3.3032641670203e-05 + (-0.0003789797503263 + o[3]*(-0.015757110897342 + o[4]*(-0.306581069554011 - 0.000960283724907132*o[8])))*tau2 + pi*(4.3870667284435e-07 + o[3]*(-9.683303171571e-05 + o[4]*(-0.0090203547252888 - 1.42338887469272*o[8])) + pi*(-7.8847309559367e-10 + (2.558143570457e-08 + 1.44676118155521e-06*tau2)*tau2 + pi*(1.60454534363627e-05*o[9] + pi*((-5.0144299353183e-11 + o[10]*(-0.033874355714168 - 836.35096769364*o[11]))*o[3] + pi*((-1.38839897890111e-05 - 0.973671060893475*o[12])*o[3]*o[6] + pi*(o[13]*(9.0049690883672e-11 - 296.320827232793*o[14]) + pi*(2.57526266427144e-07*o[5]*o[6] + pi*(o[4]*(4.1627860840696e-19 + (-1.0234747095929e-12 - 1.40254511313154e-08*o[5])*o[9]) + o[17]*(o[14]*(-2.34560435076256e-09 + 5.3465159397045*o[18]) + o[15]*(-19.1874828272775*o[19]*o[6]*o[7] + o[15]*(o[11]*(1.78371690710842e-23 + (1.07202609066812e-11 - 0.000201611844951398*o[10])*o[20]) + pi*(-1.24017662339842e-24*o[21] + pi*(0.000200482822351322*o[19]*o[5]*o[7] + pi*(-4.97975748452559e-14*o[19]*o[3]*o[5] + (1.90027787547159e-27 + o[12]*(2.21658861403112e-15 - 5.47344301999018e-05*o[22]))*o[6]*o[7]*pi*tau2))))))))))))))));
      gpi:=(1.0 + pi*(-0.0017731742473213 + tau2*(-0.017834862292358 + tau2*(-0.045996013696365 + (-0.057581259083432 - 0.05032527872793*o[4])*tau2)) + pi*(tau2*(-6.6065283340406e-05 + (-0.0003789797503263 + o[3]*(-0.007878555448671 + o[4]*(-0.087594591301146 - 5.3349095828174e-05*o[8])))*tau2) + pi*(6.1445213076927e-08 + (1.31612001853305e-06 + o[3]*(-9.683303171571e-05 + o[4]*(-0.0045101773626444 - 0.122004760687947*o[8])))*tau2 + pi*(tau2*(-3.15389238237468e-09 + (5.116287140914e-08 + 1.92901490874028e-06*tau2)*tau2) + pi*(1.14610381688305e-05*o[13] + pi*((-1.00288598706366e-10 + o[10]*(-0.012702883392813 - 143.374451604624*o[11]))*o[4] + pi*(-4.1341695026989e-17 + (-8.8352662293707e-06 - 0.272627897050173*o[12])*o[3]*o[6]*tau2 + pi*((9.0049690883672e-11 - 65.8490727183984*o[14])*o[6] + pi*(1.78287415218792e-07*o[10] + pi*(o[5]*(1.0406965210174e-18 + (-1.0234747095929e-12 - 1.0018179379511e-08*o[5])*o[9]) + o[17]*((-1.29412653835176e-09 + 1.71088510070544*o[18])*o[8] + o[15]*(-6.05920510335078*o[19]*o[6]*o[7]*tau2 + o[15]*((1.78371690710842e-23 + (6.1258633752464e-12 - 8.4004935396416e-05*o[10])*o[20])*o[21] + pi*(-1.24017662339842e-24*o[18] + pi*(8.32192847496054e-05*o[19]*o[5]*o[7]*tau2 + pi*((1.75410265428146e-27 + o[12]*(1.32995316841867e-15 - 2.26487297378904e-05*o[22]))*o[3]*o[6]*o[7]*pi - 2.93678005497663e-14*o[19]*o[3]*o[5]*tau2)))))))))))))))))/pi;
    end g2pitau;

    function g5pitau "derivative of g wrt pi and tau"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature (K)";
      output Real pi "dimensionless pressure";
      output Real tau "dimensionless temperature";
      output Real gpi "dimensionless dervative of Gibbs function wrt pi";
      output Real gtau "dimensionless dervative of Gibbs function wrt tau";
    protected
      Real[3] o "vector of auxiliary variables";
    algorithm
      assert(p > triple.ptriple, "IF97 medium function g5pitau called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
      assert(p <= data.PLIMIT5, "IF97 medium function g5pitau: input pressure (= " + String(p) + " Pa) is higher than 10 Mpa in region 5");
      assert(T <= 2273.15, "IF97 medium function g5pitau: input temperature (= " + String(T) + " K) is higher than limit of 2273.15 K in region 5");
      pi:=p/data.PSTAR5;
      tau:=data.TSTAR5/T;
      o[1]:=tau*tau;
      o[2]:=o[1]*o[1];
      o[3]:=o[2]*o[2];
      gtau:=pi*(0.0021774678714571 - 0.013782846269973*o[1] + pi*(-3.57523455236121e-05*o[3] + 3.8757684869352e-07*o[1]*pi)) + (0.074415446800398 + tau*(-0.73803069960666 + (3.1161318213925 + o[1]*(6.8540841634434 - 0.65923253077834*tau))*tau))/o[2];
      gpi:=(1.0 + pi*(-0.00012563183589592 + (0.0021774678714571 - 0.004594282089991*o[1])*tau + pi*(-7.9449656719138e-06*o[3]*tau + 3.8757684869352e-07*o[1]*pi*tau)))/pi;
    end g5pitau;

    function f3deltatau "1st derivatives of f wrt delta and tau"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "temperature (K)";
      output Real delta "dimensionless density";
      output Real tau "dimensionless temperature";
      output Real fdelta "dimensionless dervative of Helmholtz function wrt delta";
      output Real ftau "dimensionless dervative of Helmholtz function wrt tau";
    protected
      Real[13] o "vector of auxiliary variables";
    algorithm
      tau:=data.TCRIT/T;
      delta:=if d == data.DCRIT and T == data.TCRIT then 1 + Modelica.Constants.eps else d/data.DCRIT;
      o[1]:=tau*tau;
      o[2]:=o[1]*o[1];
      o[3]:=o[2]*o[2];
      o[4]:=o[3]*tau;
      o[5]:=o[1]*o[2]*o[3]*tau;
      o[6]:=o[2]*o[3];
      o[7]:=o[1]*o[3];
      o[8]:=o[3]*o[3];
      o[9]:=o[1]*o[2]*o[8];
      o[10]:=o[1]*o[2]*o[8]*tau;
      o[11]:=o[3]*o[8];
      o[12]:=o[1]*o[3]*o[8];
      o[13]:=o[3]*o[8]*tau;
      fdelta:=(1.0658070028513 + delta*(o[1]*(-1.2654315477714 + o[2]*(-1.1524407806681 + (0.88521043984318 - 0.64207765181607*o[1])*o[4])) + delta*(0.76986920373342 + o[1]*(-1.70429417648412 + o[2]*(9.7944563083754 + (-6.100523451393 + (0.078841073758308 + 0.25116816848616*o[2])*o[5])*tau)) + delta*(-0.8399798909613 + o[1]*(4.169939870838 + o[1]*(-6.056974507071 + o[6]*(-0.0246442911521889 - 1.42788107204769*o[7]))) + delta*(0.175936297894 + o[1]*(-1.77905741714956 + o[1]*(3.62288282878932 + 2.82089800351868*o[9])) + delta*(delta*(-0.133052405238576 + o[1]*(0.565564509990552 + 0.98617670687766*o[11]) + delta*(-0.094523605689436*o[1] + delta*(-0.118674762819776*o[12] + delta*(o[1]*(0.00521306582652756 + 0.0290780142333399*o[11]) + delta*(0.00080964802996215 - 0.000494162889679965*delta*o[12] - 0.0016557679795037*tau))))) + (0.5385256313166 + o[1]*(-1.6456811629477 - 2.5435531020579*o[10]))*tau))))))/delta;
      ftau:=20.944396974307 + tau*(-15.3735415757432 + o[2]*tau*(18.3301634515678 + o[1]*tau*(-28.08078114862 + o[1]*(14.4640436358204 - 0.194503669468755*o[1]*o[3]*tau)))) + delta*((-2.5308630955428 + o[2]*(-6.9146446840086 + (13.2781565976477 - 10.9153200808732*o[1])*o[4]))*tau + delta*(tau*(-1.70429417648412 + o[2]*(29.3833689251262 + (-21.3518320798755 + (0.867251811341388 + 3.26518619032008*o[2])*o[5])*tau)) + delta*((2.779959913892 + o[1]*(-8.075966009428 + o[6]*(-0.131436219478341 - 12.37496929108*o[7])))*tau + delta*((-0.88952870857478 + o[1]*(3.62288282878932 + 18.3358370228714*o[9]))*tau + delta*(0.10770512626332 + o[1]*(-0.98740869776862 - 13.2264761307011*o[10]) + delta*((0.188521503330184 + 4.27343239646986*o[11])*tau + delta*(-0.027006744482696*tau + delta*(-0.385692979164272*o[13] + delta*(delta*(-0.00016557679795037 - 0.00116802137560719*delta*o[13]) + (0.00115845907256168 + 0.0840031522296486*o[11])*tau)))))))));
    end f3deltatau;

    function tph1 "inverse function for region 1: T(p,h)"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      output Modelica.SIunits.Temperature T "temperature (K)";
    protected
      Real pi "dimensionless pressure";
      Real eta1 "dimensionless specific enthalpy";
      Real[3] o "vector of auxiliary variables";
    algorithm
      assert(p > triple.ptriple, "IF97 medium function tph1 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
      pi:=p/data.PSTAR2;
      eta1:=h/data.HSTAR1 + 1.0;
      o[1]:=eta1*eta1;
      o[2]:=o[1]*o[1];
      o[3]:=o[2]*o[2];
      T:=-238.72489924521 - 13.391744872602*pi + eta1*(404.21188637945 + 43.211039183559*pi + eta1*(113.49746881718 - 54.010067170506*pi + eta1*(30.535892203916*pi + eta1*(-6.5964749423638*pi + o[1]*(-5.8457616048039 + o[2]*(pi*(0.0093965400878363 + (-2.5858641282073e-05 + 6.6456186191635e-08*pi)*pi) + o[2]*o[3]*(-0.0001528548241314 + o[1]*o[3]*(-1.0866707695377e-06 + pi*(1.157364750534e-07 + pi*(-4.0644363084799e-09 + pi*(8.0670734103027e-11 + pi*(-9.3477771213947e-13 + (5.8265442020601e-15 - 1.5020185953503e-17*pi)*pi))))))))))));
    end tph1;

    function tps1 "inverse function for region 1: T(p,s)"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEntropy s "specific entropy";
      output Modelica.SIunits.Temperature T "temperature (K)";
    protected
      constant Modelica.SIunits.Pressure pstar=1000000.0;
      constant Modelica.SIunits.SpecificEntropy sstar=1000.0;
      Real pi "dimensionless pressure";
      Real sigma1 "dimensionless specific entropy";
      Real[6] o "vector of auxiliary variables";
    algorithm
      pi:=p/pstar;
      assert(p > triple.ptriple, "IF97 medium function tps1 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
      sigma1:=s/sstar + 2.0;
      o[1]:=sigma1*sigma1;
      o[2]:=o[1]*o[1];
      o[3]:=o[2]*o[2];
      o[4]:=o[3]*o[3];
      o[5]:=o[4]*o[4];
      o[6]:=o[1]*o[2]*o[4];
      T:=174.78268058307 + sigma1*(34.806930892873 + sigma1*(6.5292584978455 + (0.33039981775489 + o[3]*(-1.9281382923196e-07 - 2.4909197244573e-23*o[2]*o[4]))*sigma1)) + pi*(-0.26107636489332 + pi*(0.00056608900654837 + pi*(o[1]*o[3]*(2.6400441360689e-13 + 7.8124600459723e-29*o[6]) - 3.0732199903668e-31*o[5]*pi) + sigma1*(-0.00032635483139717 + sigma1*(4.4778286690632e-05 + o[1]*o[2]*(-5.1322156908507e-10 - 4.2522657042207e-26*o[6])*sigma1))) + sigma1*(0.22592965981586 + sigma1*(-0.064256463395226 + sigma1*(0.0078876289270526 + o[3]*sigma1*(3.5672110607366e-10 + 1.7332496994895e-24*o[1]*o[4]*sigma1)))));
    end tps1;

    function tph2 "reverse function for region 2: T(p,h)"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      output Modelica.SIunits.Temperature T "temperature (K)";
    protected
      Real pi "dimensionless pressure";
      Real pi2b "dimensionless pressure";
      Real pi2c "dimensionless pressure";
      Real eta "dimensionless specific enthalpy";
      Real etabc "dimensionless specific enthalpy";
      Real eta2a "dimensionless specific enthalpy";
      Real eta2b "dimensionless specific enthalpy";
      Real eta2c "dimensionless specific enthalpy";
      Real[8] o "vector of auxiliary variables";
    algorithm
      pi:=p*data.IPSTAR;
      eta:=h*data.IHSTAR;
      etabc:=h*0.001;
      if pi < 4.0 then
        eta2a:=eta - 2.1;
        o[1]:=eta2a*eta2a;
        o[2]:=o[1]*o[1];
        o[3]:=pi*pi;
        o[4]:=o[3]*o[3];
        o[5]:=o[3]*pi;
        T:=1089.8952318288 + (1.844574935579 - 0.0061707422868339*pi)*pi + eta2a*(849.51654495535 - 4.1792700549624*pi + eta2a*(-107.81748091826 + (6.2478196935812 - 0.31078046629583*pi)*pi + eta2a*(33.153654801263 - 17.344563108114*pi + o[2]*(-7.4232016790248 + pi*(-200.58176862096 + 11.670873077107*pi) + o[1]*(271.96065473796*pi + o[1]*(-455.11318285818*pi + eta2a*(1.3865724283226*o[4] + o[1]*o[2]*(3091.9688604755*pi + o[1]*(11.765048724356 + o[2]*(-13551.334240775*o[5] + o[2]*(-62.459855192507*o[3]*o[4]*pi + o[2]*(o[4]*(235988.32556514 + 7399.9835474766*pi) + o[1]*(19127.72923966*o[3]*o[4] + o[1]*(o[3]*(128127984.04046 - 551966.9703006*o[5]) + o[1]*(-985549096.23276*o[3] + o[1]*(2822454697.3002*o[3] + o[1]*(o[3]*(-3594897141.0703 + 3715408.5996233*o[5]) + o[1]*pi*(252266.40357872 + pi*(1722734991.3197 + pi*(12848734.66465 + (-13105236.545054 - 415351.64835634*o[3])*pi))))))))))))))))))));
      elseif pi < (0.00012809002730136*etabc - 0.67955786399241)*etabc + 905.84278514723 then
        eta2b:=eta - 2.6;
        pi2b:=pi - 2.0;
        o[1]:=pi2b*pi2b;
        o[2]:=o[1]*pi2b;
        o[3]:=o[1]*o[1];
        o[4]:=eta2b*eta2b;
        o[5]:=o[4]*o[4];
        o[6]:=o[4]*o[5];
        o[7]:=o[5]*o[5];
        T:=1489.5041079516 + 0.93747147377932*pi2b + eta2b*(743.07798314034 + o[2]*(0.00011032831789999 - 1.7565233969407e-18*o[1]*o[3]) + eta2b*(-97.708318797837 + pi2b*(3.3593118604916 + pi2b*(-0.021810755324761 + pi2b*(0.00018955248387902 + (2.8640237477456e-07 - 8.1456365207833e-14*o[2])*pi2b))) + o[5]*(3.3809355601454*pi2b + o[4]*(-0.10829784403677*o[1] + o[5]*(2.4742464705674 + (0.16844539671904 + o[1]*(0.0030891541160537 - 1.0779857357512e-05*pi2b))*pi2b + o[6]*(-0.63281320016026 + pi2b*(0.73875745236695 + (-0.046333324635812 + o[1]*(-7.6462712454814e-05 + 2.821728163504e-07*pi2b))*pi2b) + o[6]*(1.1385952129658 + pi2b*(-0.47128737436186 + o[1]*(0.0013555504554949 + (1.4052392818316e-05 + 1.2704902271945e-06*pi2b)*pi2b)) + o[5]*(-0.47811863648625 + (0.15020273139707 + o[2]*(-3.1083814331434e-05 + o[1]*(-1.1030139238909e-08 - 2.5180545682962e-11*pi2b)))*pi2b + o[5]*o[7]*(0.0085208123431544 + pi2b*(-0.002176411421975 + pi2b*(7.1280351959551e-05 + o[1]*(-1.0302738212103e-06 + (7.3803353468292e-08 + 8.6934156344163e-15*o[3])*pi2b))))))))))));
      else
        eta2c:=eta - 1.8;
        pi2c:=pi + 25.0;
        o[1]:=pi2c*pi2c;
        o[2]:=o[1]*o[1];
        o[3]:=o[1]*o[2]*pi2c;
        o[4]:=1/o[3];
        o[5]:=o[1]*o[2];
        o[6]:=eta2c*eta2c;
        o[7]:=o[2]*o[2];
        o[8]:=o[6]*o[6];
        T:=eta2c*((859777.2253558 + o[1]*(482.19755109255 + 1.126159740723e-12*o[5]))/o[1] + eta2c*((-583401318515.9 + (20825544563.171 + 31081.088422714*o[2])*pi2c)/o[5] + o[6]*(o[8]*(o[6]*(1.2324579690832e-07*o[5] + o[6]*(-1.1606921130984e-06*o[5] + o[8]*(2.7846367088554e-05*o[5] + (-0.00059270038474176*o[5] + 0.0012918582991878*o[5]*o[6])*o[8]))) - 10.842984880077*pi2c) + o[4]*(7326335090218.1 + o[7]*(3.7966001272486 + (-0.04536417267666 - 1.7804982240686e-11*o[2])*pi2c))))) + o[4]*(-3236839855524.2 + pi2c*(358250899454.47 + pi2c*(-10783068217.47 + o[1]*pi2c*(610747.83564516 + pi2c*(-25745.72360417 + (1208.2315865936 + 1.4559115658698e-13*o[5])*pi2c)))));
      end if;
    end tph2;

    function tps2a "reverse function for region 2a: T(p,s)"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEntropy s "specific entropy";
      output Modelica.SIunits.Temperature T "temperature (K)";
    protected
      Real[12] o "vector of auxiliary variables";
      constant Real IPSTAR=1e-06 "scaling variable";
      constant Real ISSTAR2A=1/2000.0 "scaling variable";
      Real pi "dimensionless pressure";
      Real sigma2a "dimensionless specific entropy";
    algorithm
      pi:=p*IPSTAR;
      sigma2a:=s*ISSTAR2A - 2.0;
      o[1]:=pi^0.5;
      o[2]:=sigma2a*sigma2a;
      o[3]:=o[2]*o[2];
      o[4]:=o[3]*o[3];
      o[5]:=o[4]*o[4];
      o[6]:=pi^0.25;
      o[7]:=o[2]*o[4]*o[5];
      o[8]:=1/o[7];
      o[9]:=o[3]*sigma2a;
      o[10]:=o[2]*o[3]*sigma2a;
      o[11]:=o[3]*o[4]*sigma2a;
      o[12]:=o[2]*sigma2a;
      T:=((-392359.83861984 + (515265.7382727 + o[3]*(40482.443161048 + o[2]*o[3]*(-321.93790923902 + o[2]*(96.961424218694 - 22.867846371773*sigma2a))))*sigma2a)/(o[4]*o[5]) + o[6]*((-449429.14124357 + o[3]*(-5011.8336020166 + 0.35684463560015*o[4]*sigma2a))/(o[2]*o[5]*sigma2a) + o[6]*(o[8]*(44235.33584819 + o[9]*(-13673.388811708 + o[3]*(421632.60207864 + (22516.925837475 + o[10]*(474.42144865646 - 149.31130797647*sigma2a))*sigma2a))) + o[6]*((-197811.26320452 - 23554.39947076*sigma2a)/(o[2]*o[3]*o[4]*sigma2a) + o[6]*((-19070.616302076 + o[11]*(55375.669883164 + (3829.3691437363 - 603.91860580567*o[2])*o[3]))*o[8] + o[6]*((1936.3102620331 + o[2]*(4266.064369861 + o[2]*o[3]*o[4]*(-5978.0638872718 - 704.01463926862*o[9])))/(o[2]*o[4]*o[5]*sigma2a) + o[1]*((338.36784107553 + o[12]*(20.862786635187 + (0.033834172656196 - 4.3124428414893e-05*o[12])*o[3]))*sigma2a + o[6]*(166.53791356412 + sigma2a*(-139.86292055898 + o[3]*(-0.78849547999872 + (0.072132411753872 + o[3]*(-0.0059754839398283 + (-1.2141358953904e-05 + 2.3227096733871e-07*o[2])*o[3]))*sigma2a)) + o[6]*(-10.538463566194 + o[3]*(2.0718925496502 + (-0.072193155260427 + 2.074988708112e-07*o[4])*o[9]) + o[6]*(o[6]*(o[12]*(0.21037527893619 + 0.00025681239729999*o[3]*o[4]) + (-0.012799002933781 - 8.2198102652018e-06*o[11])*o[6]*o[9]) + o[10]*(-0.018340657911379 + 2.9036272348696e-07*o[2]*o[4]*sigma2a)))))))))))/(o[1]*pi);
    end tps2a;

    function tps2b "reverse function for region 2b: T(p,s)"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEntropy s "specific entropy";
      output Modelica.SIunits.Temperature T "temperature (K)";
    protected
      Real[8] o "vector of auxiliary variables";
      constant Real IPSTAR=1e-06 "scaling variable";
      constant Real ISSTAR2B=1/785.3 "scaling variable";
      Real pi "dimensionless pressure";
      Real sigma2b "dimensionless specific entropy";
    algorithm
      pi:=p*IPSTAR;
      sigma2b:=10.0 - s*ISSTAR2B;
      o[1]:=pi*pi;
      o[2]:=o[1]*o[1];
      o[3]:=sigma2b*sigma2b;
      o[4]:=o[3]*o[3];
      o[5]:=o[4]*o[4];
      o[6]:=o[3]*o[5]*sigma2b;
      o[7]:=o[3]*o[5];
      o[8]:=o[3]*sigma2b;
      T:=(316876.65083497 + 20.864175881858*o[6] + pi*(-398593.99803599 - 21.816058518877*o[6] + pi*(223697.85194242 + (-2784.1703445817 + 9.920743607148*o[7])*sigma2b + pi*(-75197.512299157 + (2970.8605951158 + o[7]*(-3.4406878548526 + 0.38815564249115*sigma2b))*sigma2b + pi*(17511.29508575 + sigma2b*(-1423.7112854449 + (1.0943803364167 + 0.89971619308495*o[4])*o[4]*sigma2b) + pi*(-3375.9740098958 + (471.62885818355 + o[4]*(-1.9188241993679 + o[8]*(0.41078580492196 - 0.33465378172097*sigma2b)))*sigma2b + pi*(1387.0034777505 + sigma2b*(-406.63326195838 + sigma2b*(41.72734715961 + o[3]*(2.1932549434532 + sigma2b*(-1.0320050009077 + (0.35882943516703 + 0.0052511453726066*o[8])*sigma2b)))) + pi*(12.838916450705 + sigma2b*(-2.8642437219381 + sigma2b*(0.56912683664855 + (-0.099962954584931 + o[4]*(-0.0032632037778459 + 0.00023320922576723*sigma2b))*sigma2b)) + pi*(-0.1533480985745 + (0.029072288239902 + 0.00037534702741167*o[4])*sigma2b + pi*(0.0017296691702411 + (-0.00038556050844504 - 3.5017712292608e-05*o[3])*sigma2b + pi*(-1.4566393631492e-05 + 5.6420857267269e-06*sigma2b + pi*(4.1286150074605e-08 + (-2.0684671118824e-08 + 1.6409393674725e-09*sigma2b)*sigma2b))))))))))))/(o[1]*o[2]);
    end tps2b;

    function tps2c "reverse function for region 2c: T(p,s)"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEntropy s "specific entropy";
      output Modelica.SIunits.Temperature T "temperature (K)";
    protected
      constant Real IPSTAR=1e-06 "scaling variable";
      constant Real ISSTAR2C=1/2925.1 "scaling variable";
      Real pi "dimensionless pressure";
      Real sigma2c "dimensionless specific entropy";
      Real[3] o "vector of auxiliary variables";
    algorithm
      pi:=p*IPSTAR;
      sigma2c:=2.0 - s*ISSTAR2C;
      o[1]:=pi*pi;
      o[2]:=sigma2c*sigma2c;
      o[3]:=o[2]*o[2];
      T:=(909.68501005365 + 2404.566708842*sigma2c + pi*(-591.6232638713 + pi*(541.45404128074 + sigma2c*(-270.98308411192 + (979.76525097926 - 469.66772959435*sigma2c)*sigma2c) + pi*(14.399274604723 + (-19.104204230429 + o[2]*(5.3299167111971 - 21.252975375934*sigma2c))*sigma2c + pi*(-0.3114733441376 + (0.60334840894623 - 0.042764839702509*sigma2c)*sigma2c + pi*(0.0058185597255259 + (-0.014597008284753 + 0.0056631175631027*o[3])*sigma2c + pi*(-7.6155864584577e-05 + sigma2c*(0.00022440342919332 - 1.2561095013413e-05*o[2]*sigma2c) + pi*(6.3323132660934e-07 + (-2.0541989675375e-06 + 3.6405370390082e-08*sigma2c)*sigma2c + pi*(-2.9759897789215e-09 + 1.0136618529763e-08*sigma2c + pi*(5.9925719692351e-12 + sigma2c*(-2.0677870105164e-11 + o[2]*(-2.0874278181886e-11 + (1.0162166825089e-10 - 1.6429828281347e-10*sigma2c)*sigma2c))))))))))))/o[1];
    end tps2c;

    function tps2 "reverse function for region 2: T(p,s)"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEntropy s "specific entropy";
      output Modelica.SIunits.Temperature T "temperature (K)";
    protected
      Real pi "dimensionless pressure";
      constant Modelica.SIunits.SpecificEntropy SLIMIT=5850.0 "subregion boundary specific entropy between regions 2a and 2b";
    algorithm
      if p < 4000000.0 then
        T:=tps2a(p, s);
      elseif s > SLIMIT then
        T:=tps2b(p, s);
      else
        T:=tps2c(p, s);
      end if;
    end tps2;

    function tsat "region 4 saturation temperature as a function of pressure"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      output Modelica.SIunits.Temperature t_sat "temperature";
    protected
      Real pi "dimensionless pressure";
      Real[20] o "vector of auxiliary variables";
    algorithm
      pi:=max(min(p, data.PCRIT), triple.ptriple)*data.IPSTAR;
      o[1]:=pi^0.25;
      o[2]:=-3232555.0322333*o[1];
      o[3]:=pi^0.5;
      o[4]:=-724213.16703206*o[3];
      o[5]:=405113.40542057 + o[2] + o[4];
      o[6]:=-17.073846940092*o[1];
      o[7]:=14.91510861353 + o[3] + o[6];
      o[8]:=-4.0*o[5]*o[7];
      o[9]:=12020.82470247*o[1];
      o[10]:=1167.0521452767*o[3];
      o[11]:=-4823.2657361591 + o[10] + o[9];
      o[12]:=o[11]*o[11];
      o[13]:=o[12] + o[8];
      o[14]:=o[13]^0.5;
      o[15]:=-o[14];
      o[16]:=-12020.82470247*o[1];
      o[17]:=-1167.0521452767*o[3];
      o[18]:=4823.2657361591 + o[15] + o[16] + o[17];
      o[19]:=1/o[18];
      o[20]:=2.0*o[19]*o[5];
      t_sat:=0.5*(650.17534844798 + o[20] - (-4.0*(-0.23855557567849 + 1300.35069689596*o[19]*o[5]) + (650.17534844798 + o[20])^2.0)^0.5);
      annotation(derivative=tsat_der);
    end tsat;

    function dtsatofp "derivative of saturation temperature w.r.t. pressure"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      output Real dtsat(unit="K/Pa") "derivative of T w.r.t. p";
    protected
      Real pi "dimensionless pressure";
      Real[49] o "vector of auxiliary variables";
    algorithm
      pi:=p*data.IPSTAR;
      o[1]:=pi^0.75;
      o[2]:=1/o[1];
      o[3]:=-4.268461735023*o[2];
      o[4]:=sqrt(pi);
      o[5]:=1/o[4];
      o[6]:=0.5*o[5];
      o[7]:=o[3] + o[6];
      o[8]:=pi^0.25;
      o[9]:=-3232555.0322333*o[8];
      o[10]:=-724213.16703206*o[4];
      o[11]:=405113.40542057 + o[10] + o[9];
      o[12]:=-4*o[11]*o[7];
      o[13]:=-808138.758058325*o[2];
      o[14]:=-362106.58351603*o[5];
      o[15]:=o[13] + o[14];
      o[16]:=-17.073846940092*o[8];
      o[17]:=14.91510861353 + o[16] + o[4];
      o[18]:=-4*o[15]*o[17];
      o[19]:=3005.2061756175*o[2];
      o[20]:=583.52607263835*o[5];
      o[21]:=o[19] + o[20];
      o[22]:=12020.82470247*o[8];
      o[23]:=1167.0521452767*o[4];
      o[24]:=-4823.2657361591 + o[22] + o[23];
      o[25]:=2.0*o[21]*o[24];
      o[26]:=o[12] + o[18] + o[25];
      o[27]:=-4.0*o[11]*o[17];
      o[28]:=o[24]*o[24];
      o[29]:=o[27] + o[28];
      o[30]:=sqrt(o[29]);
      o[31]:=1/o[30];
      o[32]:=-o[30];
      o[33]:=-12020.82470247*o[8];
      o[34]:=-1167.0521452767*o[4];
      o[35]:=4823.2657361591 + o[32] + o[33] + o[34];
      o[36]:=o[30];
      o[37]:=-4823.2657361591 + o[22] + o[23] + o[36];
      o[38]:=o[37]*o[37];
      o[39]:=1/o[38];
      o[40]:=-1.72207339365771*o[30];
      o[41]:=21592.2055343628*o[8];
      o[42]:=o[30]*o[8];
      o[43]:=-8192.87114842946*o[4];
      o[44]:=-0.510632954559659*o[30]*o[4];
      o[45]:=-3100.02526152368*o[1];
      o[46]:=pi;
      o[47]:=1295.95640782102*o[46];
      o[48]:=2862.09212505088 + o[40] + o[41] + o[42] + o[43] + o[44] + o[45] + o[47];
      o[49]:=1/(o[35]*o[35]);
      dtsat:=data.IPSTAR*0.5*(2.0*o[15]/o[35] - 2.0*o[11]*(-3005.2061756175*o[2] - 0.5*o[26]*o[31] - 583.52607263835*o[5])*o[49] - 20953.4635664399*(o[39]*(1295.95640782102 + 5398.05138359071*o[2] + 0.25*o[2]*o[30] - 0.861036696828853*o[26]*o[31] - 0.255316477279829*o[26]*o[31]*o[4] - 4096.43557421473*o[5] - 0.255316477279829*o[30]*o[5] - 2325.01894614276/o[8] + 0.5*o[26]*o[31]*o[8]) - 2.0*(o[19] + o[20] + 0.5*o[26]*o[31])*o[48]*o[37]^(-3))/sqrt(o[39]*o[48]));
    end dtsatofp;

    function tsat_der "derivative function for tsat"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Real der_p(unit="Pa/s") "pressure derivatrive";
      output Real der_tsat(unit="K/s") "temperature derivative";
    protected
      Real dtp;
    algorithm
      dtp:=dtsatofp(p);
      der_tsat:=dtp*der_p;
    end tsat_der;

    function psat "region 4 saturation pressure as a functionx of temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Temperature T "temperature (K)";
      output Modelica.SIunits.Pressure p_sat "pressure";
    protected
      Real[7] o "vector of auxiliary variables";
      Real C "auxiliary variable";
      Real B "auxiliary variable";
      Real A "auxiliary variable";
      Real Tlim=min(T, data.TCRIT);
    algorithm
      assert(T >= 273.16, "IF97 medium function psat: input temperature (= " + String(triple.ptriple) + " K).\n" + "lower than the triple point temperature 273.16 K");
      o[1]:=-650.17534844798 + Tlim;
      o[2]:=1/o[1];
      o[3]:=-0.23855557567849*o[2];
      o[4]:=o[3] + Tlim "theta";
      LogVariable(o[4]);
      o[5]:=-4823.2657361591*o[4] "n7*theta";
      o[6]:=o[4]*o[4] "theta^2";
      o[7]:=14.91510861353*o[6] "n6*theta^2";
      C:=405113.40542057 + o[5] + o[7] "C";
      B:=-3232555.0322333 + 12020.82470247*o[4] - 17.073846940092*o[6];
      A:=-724213.16703206 + 1167.0521452767*o[4] + o[6];
      LogVariable(A);
      p_sat:=16000000.0*C*C*C*C*1/(-B + (-4.0*A*C + B*B)^0.5)^4.0;
      annotation(derivative=psat_der);
    end psat;

    function dptofT "derivative of pressure wrt temperature along the saturation pressure curve"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Temperature T "temperature (K)";
      output Real dpt(unit="Pa/K") "temperature derivative of pressure";
    protected
      Real[31] o "vector of auxiliary variables";
      Real Tlim "temperature limited to TCRIT";
    algorithm
      Tlim:=min(T, data.TCRIT);
      o[1]:=-650.17534844798 + Tlim;
      o[2]:=1/o[1];
      o[3]:=-0.23855557567849*o[2];
      o[4]:=o[3] + Tlim "theta";
      o[5]:=-4823.2657361591*o[4];
      o[6]:=o[4]*o[4] "theta^2";
      o[7]:=14.91510861353*o[6];
      o[8]:=405113.40542057 + o[5] + o[7];
      o[9]:=o[8]*o[8];
      o[10]:=o[9]*o[9];
      o[11]:=o[1]*o[1];
      o[12]:=1/o[11];
      o[13]:=0.23855557567849*o[12];
      o[14]:=1.0 + o[13] "dtheta";
      o[15]:=12020.82470247*o[4];
      o[16]:=-17.073846940092*o[6];
      o[17]:=-3232555.0322333 + o[15] + o[16];
      o[18]:=-4823.2657361591*o[14];
      o[19]:=29.83021722706*o[14]*o[4];
      o[20]:=o[18] + o[19];
      o[21]:=1167.0521452767*o[4];
      o[22]:=-724213.16703206 + o[21] + o[6];
      o[23]:=o[17]*o[17];
      o[24]:=-4.0*o[22]*o[8];
      o[25]:=o[23] + o[24];
      o[26]:=sqrt(o[25]);
      o[27]:=-12020.82470247*o[4];
      o[28]:=17.073846940092*o[6];
      o[29]:=3232555.0322333 + o[26] + o[27] + o[28];
      o[30]:=o[29]*o[29];
      o[31]:=o[30]*o[30];
      dpt:=1000000.0*((-64.0*o[10]*(-12020.82470247*o[14] + 34.147693880184*o[14]*o[4] + 0.5*(-4.0*o[20]*o[22] + 2.0*o[17]*(12020.82470247*o[14] - 34.147693880184*o[14]*o[4]) - 4.0*(1167.0521452767*o[14] + 2.0*o[14]*o[4])*o[8])/o[26]))/(o[29]*o[31]) + 64.0*o[20]*o[8]*o[9]/o[31]);
    end dptofT;

    function d2ptofT "Second derivative of pressure wrt temperature along the saturation pressure curve"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Temperature T "temperature (K)";
      output Real dpT(unit="Pa/K") "Temperature derivative of pressure";
      output Real dpTT(unit="Pa/(K.K)") "Second temperature derivative of pressure";
    protected
      Real A "Auxiliary variable";
      Real Ad "Auxiliary variable";
      Real A1 "Auxiliary variable";
      Real A2 "Auxiliary variable";
      Real B "Auxiliary variable";
      Real Bd "Auxiliary variable";
      Real B1 "Auxiliary variable";
      Real B2 "Auxiliary variable";
      Real C "Auxiliary variable";
      Real Cd "Auxiliary variable";
      Real C1 "Auxiliary variable";
      Real C2 "Auxiliary variable";
      Real D "Auxiliary variable";
      Real D1 "Auxiliary variable";
      Real Dd "Auxiliary variable";
      Real D2 "Auxiliary variable";
      Real th "Auxiliary variable";
      Real thd "Auxiliary variable";
      Real thdd "Auxiliary variable";
      Real v "Auxiliary variable";
      Real v2 "Auxiliary variable";
      Real v4 "Auxiliary variable";
      Real v5 "Auxiliary variable";
      Real v6 "Auxiliary variable";
      Real[16] o "vector of auxiliary variables";
      Real Tlim "temperature limited to TCRIT";
      parameter Real[10] n={1167.0521452767,-724213.16703206,-17.073846940092,12020.82470247,-3232555.0322333,14.91510861353,-4823.2657361591,405113.40542057,-0.23855557567849,650.17534844798};
    algorithm
      Tlim:=min(T, data.TCRIT);
      o[1]:=Tlim - n[10];
      th:=Tlim + n[9]/o[1];
      o[2]:=th*th "theta^2";
      A:=o[2] + n[1]*th + n[2];
      B:=n[3]*o[2] + n[4]*th + n[5];
      C:=n[6]*o[2] + n[7]*th + n[8];
      o[3]:=o[1]*o[1];
      o[4]:=o[3]*o[3];
      D:=B*B - 4.0*A*C;
      o[5]:=sqrt(D);
      v:=1/(o[5] - B);
      v2:=v*v;
      v4:=v2*v2;
      v5:=v4*v;
      v6:=v4*v2;
      o[6]:=2.0*C*v;
      o[7]:=o[6]*o[6];
      thd:=1.0 - n[9]/o[3];
      thdd:=2.0*n[9]/(o[3]*o[1]);
      Ad:=2.0*th + n[1];
      Bd:=2.0*n[3]*th + n[4];
      Cd:=2.0*n[6]*th + n[7];
      Dd:=2*B*Bd - 4*(Ad*C + Cd*A);
      A1:=Ad*thd;
      B1:=Bd*thd;
      C1:=Cd*thd;
      D1:=Dd*thd;
      o[8]:=C*C "C^2";
      o[9]:=o[8]*C "C^3";
      o[10]:=o[9]*C "C^4";
      o[11]:=1/o[5] "1/sqrt(D)";
      o[12]:=-B1 + 0.5*D1*o[11] "-B1 + 1/2*D1/sqrt(D)";
      o[13]:=o[12]*o[12];
      o[14]:=C1*C1 "C1^2";
      o[15]:=B1*B1 "B1^2";
      o[16]:=D*o[5] "D^3/2";
      dpT:=64.0*(C1*o[9]*v4 - o[10]*o[12]*v5)*1000000.0 "dpsat";
      A2:=Ad*thdd + thd*thd*2.0;
      B2:=Bd*thdd + thd*thd*2.0*n[3];
      C2:=Cd*thdd + thd*thd*2.0*n[6];
      D2:=2.0*(B*B2 + o[15]) - 4.0*(A2*C + 2.0*A1*C1 + A*C2);
      dpTT:=((192.0*o[8]*o[14] + 64.0*o[9]*C2)*v4 + (-512.0*C1*o[9]*o[12] - 64.0*o[10]*(-B2 - 0.25*D1*D1/o[16] + 0.5*D2*o[11]))*v5 + 320.0*o[10]*o[13]*v6)*1000000.0;
    end d2ptofT;

    function psat_der "derivative function for psat"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Temperature T "temperature (K)";
      input Real der_T(unit="K/s") "temperature derivative";
      output Real der_psat(unit="Pa/s") "pressure";
    protected
      Real dpt;
    algorithm
      dpt:=dptofT(T);
      der_psat:=dpt*der_T;
    end psat_der;

    function p1_hs "pressure as a function of ehtnalpy and entropy in region 1"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input Modelica.SIunits.SpecificEntropy s "specific entropy";
      output Modelica.SIunits.Pressure p "Pressure";
      constant Real[:] n={-0.691997014660582,-18.361254878756,-9.28332409297335,65.9639569909906,-16.2060388912024,450.620017338667,854.68067822417,6075.23214001162,32.6487682621856,-26.9408844582931,-319.9478483343,-928.35430704332,30.3634537455249,-65.0540422444146,-4309.9131651613,-747.512324096068,730.000345529245,1142.84032569021,-436.407041874559};
      constant Real[:] I={0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,3,4,4,5};
      constant Real[:] J={0,1,2,4,5,6,8,14,0,1,4,6,0,1,10,4,1,4,0};
      constant Modelica.SIunits.SpecificEnthalpy hstar=3400000.0 "normalization enthalpy";
      constant Modelica.SIunits.Pressure pstar=100000000.0 "normalization pressure";
      constant Modelica.SIunits.SpecificEntropy sstar=7600.0 "normalization entropy";
    protected
      Real eta=h/hstar "normalized specific enthalpy";
      Real sigma=s/sstar "normalized specific entropy";
    algorithm
      p:=sum(n[i]*(eta + 0.05)^I[i]*(sigma + 0.05)^J[i] for i in 1:19)*pstar;
      annotation(Documentation(info="<html>
<p>
  Equation number 1 from:<br>
  The International Association for the Properties of Water and Steam<br>
  Gaithersburg, Maryland, USA<br>
  September 2001<br>
  Supplementary Release on&nbsp; Backward Equations for Pressure as a
  Function of Enthalpy and Entropy p(h,s) to the IAPWS Industrial
  Formulation 1997 for the Thermodynamic Properties of Water and Steam<br>
  </p>
  </html>
  "));
    end p1_hs;

    function h2ab_s "boundary between regions 2a and 2b"
      extends Modelica.Icons.Function;
      output Modelica.SIunits.SpecificEnthalpy h "Enthalpy";
      input Modelica.SIunits.SpecificEntropy s "Entropy";
    protected
      constant Real[:] n={-3498.98083432139,2575.60716905876,-421.073558227969,27.6349063799944};
      constant Modelica.SIunits.SpecificEnthalpy hstar=1000.0 "normalization enthalpy";
      constant Modelica.SIunits.SpecificEntropy sstar=1000.0 "normalization entropy";
      Real sigma=s/sstar "normalized specific entropy";
    algorithm
      h:=(n[1] + n[2]*sigma + n[3]*sigma^2 + n[4]*sigma^3)*hstar;
      annotation(Documentation(info="<html>
  <p>
  Equation number 2 from:<br>
  The International Association for the Properties of Water and Steam<br>
  Gaithersburg, Maryland, USA<br>
  September 2001<br>
  Supplementary Release on&nbsp; Backward Equations for Pressure as a
  Function of Enthalpy and Entropy p(h,s) to the IAPWS Industrial
  Formulation 1997 for the Thermodynamic Properties of Water and Steam<br>
  </p>
  </html>
  "));
    end h2ab_s;

    function p2a_hs "pressure as a function of enthalpy and entropy in subregion 2a"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input Modelica.SIunits.SpecificEntropy s "specific entropy";
      output Modelica.SIunits.Pressure p "Pressure";
      constant Real[:] n={-0.0182575361923032,-0.125229548799536,0.592290437320145,6.04769706185122,238.624965444474,-298.639090222922,0.051225081304075,-0.437266515606486,0.413336902999504,-5.16468254574773,-5.57014838445711,12.8555037824478,11.414410895329,-119.504225652714,-2847.7798596156,4317.57846408006,1.1289404080265,1974.09186206319,1516.12444706087,0.0141324451421235,0.585501282219601,-2.97258075863012,5.94567314847319,-6236.56565798905,9659.86235133332,6.81500934948134,-6332.07286824489,-5.5891922446576,0.0400645798472063};
      constant Real[:] I={0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,2,2,2,3,3,3,3,3,4,5,5,6,7};
      constant Real[:] J={1,3,6,16,20,22,0,1,2,3,5,6,10,16,20,22,3,16,20,0,2,3,6,16,16,3,16,3,1};
      constant Modelica.SIunits.SpecificEnthalpy hstar=4200000.0 "normalization enthalpy";
      constant Modelica.SIunits.Pressure pstar=4000000.0 "normalization pressure";
      constant Modelica.SIunits.SpecificEntropy sstar=12000.0 "normalization entropy";
    protected
      Real eta=h/hstar "normalized specific enthalpy";
      Real sigma=s/sstar "normalized specific entropy";
    algorithm
      p:=sum(n[i]*(eta - 0.5)^I[i]*(sigma - 1.2)^J[i] for i in 1:29)^4*pstar;
      annotation(Documentation(info="<html>
  <p>
  Equation number 3 from:<br>
  The International Association for the Properties of Water and Steam<br>
  Gaithersburg, Maryland, USA<br>
  September 2001<br>
  Supplementary Release on&nbsp; Backward Equations for Pressure as a
  Function of Enthalpy and Entropy p(h,s) to the IAPWS Industrial
  Formulation 1997 for the Thermodynamic Properties of Water and Steam<br>
  </p>
  </html>
  "));
    end p2a_hs;

    function p2b_hs "pressure as a function of enthalpy and entropy in subregion 2a"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input Modelica.SIunits.SpecificEntropy s "specific entropy";
      output Modelica.SIunits.Pressure p "Pressure";
      constant Real[:] n={0.0801496989929495,-0.543862807146111,0.337455597421283,8.9055545115745,313.840736431485,0.797367065977789,-1.2161697355624,8.72803386937477,-16.9769781757602,-186.552827328416,95115.9274344237,-18.9168510120494,-4334.0703719484,543212633.012715,0.144793408386013,128.024559637516,-67230.9534071268,33697238.0095287,-586.63419676272,-22140322476.9889,1716.06668708389,-570817595.806302,-3121.09693178482,-2078413.8463301,3056059461577.86,3221.57004314333,326810259797.295,-1441.04158934487,410.694867802691,109077066873.024,-24796465425889.3,1888019068.65134,-123651009018773.0};
      constant Real[:] I={0,0,0,0,0,1,1,1,1,1,1,2,2,2,3,3,3,3,4,4,5,5,6,6,6,7,7,8,8,8,8,12,14};
      constant Real[:] J={0,1,2,4,8,0,1,2,3,5,12,1,6,18,0,1,7,12,1,16,1,12,1,8,18,1,16,1,3,14,18,10,16};
      constant Modelica.SIunits.SpecificEnthalpy hstar=4100000.0 "normalization enthalpy";
      constant Modelica.SIunits.Pressure pstar=100000000.0 "normalization pressure";
      constant Modelica.SIunits.SpecificEntropy sstar=7900.0 "normalization entropy";
    protected
      Real eta=h/hstar "normalized specific enthalpy";
      Real sigma=s/sstar "normalized specific entropy";
    algorithm
      p:=sum(n[i]*(eta - 0.6)^I[i]*(sigma - 1.01)^J[i] for i in 1:33)^4*pstar;
      annotation(Documentation(info="<html>
<p>
Equation number 4 from:<br>
The International Association for the Properties of Water and Steam<br>
Gaithersburg, Maryland, USA<br>
September 2001<br>
Supplementary Release on&nbsp; Backward Equations for Pressure as a
Function of Enthalpy and Entropy p(h,s) to the IAPWS Industrial
Formulation 1997 for the Thermodynamic Properties of Water and Steam<br>
</p>
      </html>
"));
    end p2b_hs;

    function p2c_hs "pressure as a function of enthalpy and entropy in subregion 2c"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input Modelica.SIunits.SpecificEntropy s "specific entropy";
      output Modelica.SIunits.Pressure p "Pressure";
      constant Real[:] n={0.112225607199012,-3.39005953606712,-32.0503911730094,-197.5973051049,-407.693861553446,13294.3775222331,1.70846839774007,37.3694198142245,3581.44365815434,423014.446424664,-751071025.760063,52.3446127607898,-228.351290812417,-960652.417056937,-80705929.2526074,1626980172256.69,0.772465073604171,46392.9973837746,-13731788.5134128,1704703926305.12,-25110462818730.8,31774883083552.0,53.8685623675312,-55308.9094625169,-1028615.22421405,2042494187562.34,273918446.626977,-2.63963146312685e+15,-1078908541.08088,-29649262098.0124,-1.11754907323424e+15};
      constant Real[:] I={0,0,0,0,0,0,1,1,1,1,1,2,2,2,2,2,3,3,3,3,3,4,5,5,5,5,6,6,10,12,16};
      constant Real[:] J={0,1,2,3,4,8,0,2,5,8,14,2,3,7,10,18,0,5,8,16,18,18,1,4,6,14,8,18,7,7,10};
      constant Modelica.SIunits.SpecificEnthalpy hstar=3500000.0 "normalization enthalpy";
      constant Modelica.SIunits.Pressure pstar=100000000.0 "normalization pressure";
      constant Modelica.SIunits.SpecificEntropy sstar=5900.0 "normalization entropy";
    protected
      Real eta=h/hstar "normalized specific enthalpy";
      Real sigma=s/sstar "normalized specific entropy";
    algorithm
      p:=sum(n[i]*(eta - 0.7)^I[i]*(sigma - 1.1)^J[i] for i in 1:31)^4*pstar;
      annotation(Documentation(info="<html>
      <p>
      Equation number 5 from:<br>
      The International Association for the Properties of Water and Steam<br>
      Gaithersburg, Maryland, USA<br>
      September 2001<br>
      Supplementary Release on&nbsp; Backward Equations for Pressure as a
      Function of Enthalpy and Entropy p(h,s) to the IAPWS Industrial
      Formulation 1997 for the Thermodynamic Properties of Water and Steam<br>
      </p>
      </html>
      "));
    end p2c_hs;

    function h3ab_p "ergion 3 a b boundary for pressure/enthalpy"
      extends Modelica.Icons.Function;
      output Modelica.SIunits.SpecificEnthalpy h "Enthalpy";
      input Modelica.SIunits.Pressure p "Pressure";
    protected
      constant Real[:] n={2014.64004206875,3.74696550136983,-0.0219921901054187,8.7513168600995e-05};
      constant Modelica.SIunits.SpecificEnthalpy hstar=1000 "normalization enthalpy";
      constant Modelica.SIunits.Pressure pstar=1000000.0 "normalization pressure";
      Real pi=p/pstar "normalized specific pressure";
    algorithm
      h:=(n[1] + n[2]*pi + n[3]*pi^2 + n[4]*pi^3)*hstar;
      annotation(Documentation(info="<html>
      <p>
      &nbsp;Equation number 1 from:<br>
      <div style=\"text-align: center;\">&nbsp;[1] The international Association
      for the Properties of Water and Steam<br>
      &nbsp;Vejle, Denmark<br>
      &nbsp;August 2003<br>
      &nbsp;Supplementary Release on Backward Equations for the Fucnctions
      T(p,h), v(p,h) and T(p,s), <br>
      &nbsp;v(p,s) for Region 3 of the IAPWS Industrial Formulation 1997 for
      the Thermodynamic Properties of<br>
      &nbsp;Water and Steam</div>
      </p>
      </html>"));
    end h3ab_p;

    function T3a_ph "Region 3 a: inverse function T(p,h)"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "Pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      output Modelica.SIunits.Temp_K T "Temperature";
    protected
      constant Real[:] n={-1.33645667811215e-07,4.55912656802978e-06,-1.46294640700979e-05,0.0063934131297008,372.783927268847,-7186.54377460447,573494.7521034,-2675693.29111439,-3.34066283302614e-05,-0.0245479214069597,47.8087847764996,7.64664131818904e-06,0.00128350627676972,0.0171219081377331,-8.51007304583213,-0.0136513461629781,-3.84460997596657e-06,0.00337423807911655,-0.551624873066791,0.72920227710747,-0.00992522757376041,-0.119308831407288,0.793929190615421,0.454270731799386,0.20999859125991,-0.00642109823904738,-0.023515586860454,0.00252233108341612,-0.00764885133368119,0.0136176427574291,-0.0133027883575669};
      constant Real[:] I={-12,-12,-12,-12,-12,-12,-12,-12,-10,-10,-10,-8,-8,-8,-8,-5,-3,-2,-2,-2,-1,-1,0,0,1,3,3,4,4,10,12};
      constant Real[:] J={0,1,2,6,14,16,20,22,1,5,12,0,2,4,10,2,0,1,3,4,0,2,0,1,1,0,1,0,3,4,5};
      constant Modelica.SIunits.SpecificEnthalpy hstar=2300000.0 "normalization enthalpy";
      constant Modelica.SIunits.Pressure pstar=100000000.0 "normalization pressure";
      constant Modelica.SIunits.Temp_K Tstar=760 "normalization temperature";
      Real pi=p/pstar "normalized specific pressure";
      Real eta=h/hstar "normalized specific enthalpy";
    algorithm
      T:=sum(n[i]*(pi + 0.24)^I[i]*(eta - 0.615)^J[i] for i in 1:31)*Tstar;
      annotation(Documentation(info="<html>
 <p>
 &nbsp;Equation number 2 from:<br>
 <div style=\"text-align: center;\">&nbsp;[1] The international Association
 for the Properties of Water and Steam<br>
 &nbsp;Vejle, Denmark<br>
 &nbsp;August 2003<br>
 &nbsp;Supplementary Release on Backward Equations for the Fucnctions
 T(p,h), v(p,h) and T(p,s), <br>
 &nbsp;v(p,s) for Region 3 of the IAPWS Industrial Formulation 1997 for
 the Thermodynamic Properties of<br>
 &nbsp;Water and Steam</div>
 </p>
 </html>"));
    end T3a_ph;

    function T3b_ph "Region 3 b: inverse function T(p,h)"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "Pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      output Modelica.SIunits.Temp_K T "Temperature";
    protected
      constant Real[:] n={3.2325457364492e-05,-0.000127575556587181,-0.000475851877356068,0.00156183014181602,0.105724860113781,-85.8514221132534,724.140095480911,0.00296475810273257,-0.00592721983365988,-0.0126305422818666,-0.115716196364853,84.9000969739595,-0.0108602260086615,0.0154304475328851,0.0750455441524466,0.0252520973612982,-0.0602507901232996,-3.07622221350501,-0.0574011959864879,5.03471360939849,-0.925081888584834,3.91733882917546,-77.314600713019,9493.08762098587,-1410437.19679409,8491662.30819026,0.861095729446704,0.32334644281172,0.873281936020439,-0.436653048526683,0.286596714529479,-0.131778331276228,0.00676682064330275};
      constant Real[:] I={-12,-12,-10,-10,-10,-10,-10,-8,-8,-8,-8,-8,-6,-6,-6,-4,-4,-3,-2,-2,-1,-1,-1,-1,-1,-1,0,0,1,3,5,6,8};
      constant Real[:] J={0,1,0,1,5,10,12,0,1,2,4,10,0,1,2,0,1,5,0,4,2,4,6,10,14,16,0,2,1,1,1,1,1};
      constant Modelica.SIunits.Temp_K Tstar=860 "normalization temperature";
      constant Modelica.SIunits.Pressure pstar=100000000.0 "normalization pressure";
      constant Modelica.SIunits.SpecificEnthalpy hstar=2800000.0 "normalization enthalpy";
      Real pi=p/pstar "normalized specific pressure";
      Real eta=h/hstar "normalized specific enthalpy";
    algorithm
      T:=sum(n[i]*(pi + 0.298)^I[i]*(eta - 0.72)^J[i] for i in 1:33)*Tstar;
      annotation(Documentation(info="<html>
 <p>
 &nbsp;Equation number 3 from:<br>
 <div style=\"text-align: center;\">&nbsp;[1] The international Association
 for the Properties of Water and Steam<br>
 &nbsp;Vejle, Denmark<br>
 &nbsp;August 2003<br>
 &nbsp;Supplementary Release on Backward Equations for the Fucnctions
 T(p,h), v(p,h) and T(p,s), <br>
 &nbsp;v(p,s) for Region 3 of the IAPWS Industrial Formulation 1997 for
 the Thermodynamic Properties of<br>
 &nbsp;Water and Steam</div>
 </p>
 </html>"));
    end T3b_ph;

    function v3a_ph "Region 3 a: inverse function v(p,h)"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "Pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      output Modelica.SIunits.SpecificVolume v "specific volume";
    protected
      constant Real[:] n={0.00529944062966028,-0.170099690234461,11.1323814312927,-2178.98123145125,-0.000506061827980875,0.556495239685324,-9.43672726094016,-0.297856807561527,93.9353943717186,0.0192944939465981,0.421740664704763,-3689141.2628233,-0.00737566847600639,-0.354753242424366,-1.99768169338727,1.15456297059049,5683.6687581596,0.00808169540124668,0.172416341519307,1.04270175292927,-0.297691372792847,0.560394465163593,0.275234661176914,-0.148347894866012,-0.0651142513478515,-2.92468715386302,0.0664876096952665,3.52335014263844,-0.0146340792313332,-2.24503486668184,1.10533464706142,-0.0408757344495612};
      constant Real[:] I={-12,-12,-12,-12,-10,-10,-10,-8,-8,-6,-6,-6,-4,-4,-3,-2,-2,-1,-1,-1,-1,0,0,1,1,1,2,2,3,4,5,8};
      constant Real[:] J={6,8,12,18,4,7,10,5,12,3,4,22,2,3,7,3,16,0,1,2,3,0,1,0,1,2,0,2,0,2,2,2};
      constant Modelica.SIunits.Volume vstar=0.0028 "normalization temperature";
      constant Modelica.SIunits.Pressure pstar=100000000.0 "normalization pressure";
      constant Modelica.SIunits.SpecificEnthalpy hstar=2100000.0 "normalization enthalpy";
      Real pi=p/pstar "normalized specific pressure";
      Real eta=h/hstar "normalized specific enthalpy";
    algorithm
      v:=sum(n[i]*(pi + 0.128)^I[i]*(eta - 0.727)^J[i] for i in 1:32)*vstar;
      annotation(Documentation(info="<html>
 <p>
 &nbsp;Equation number 4 from:<br>
 <div style=\"text-align: center;\">&nbsp;[1] The international Association
 for the Properties of Water and Steam<br>
 &nbsp;Vejle, Denmark<br>
 &nbsp;August 2003<br>
 &nbsp;Supplementary Release on Backward Equations for the Fucnctions
 T(p,h), v(p,h) and T(p,s), <br>
 &nbsp;v(p,s) for Region 3 of the IAPWS Industrial Formulation 1997 for
 the Thermodynamic Properties of<br>
 &nbsp;Water and Steam</div>
 </p>
 </html>"));
    end v3a_ph;

    function v3b_ph "Region 3 b: inverse function v(p,h)"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "Pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      output Modelica.SIunits.SpecificVolume v "specific volume";
    protected
      constant Real[:] n={-2.25196934336318e-09,1.40674363313486e-08,2.3378408528056e-06,-3.31833715229001e-05,0.00107956778514318,-0.271382067378863,1.07202262490333,-0.853821329075382,-2.15214194340526e-05,0.00076965608822273,-0.00431136580433864,0.453342167309331,-0.507749535873652,-100.475154528389,-0.219201924648793,-3.21087965668917,607.567815637771,0.000557686450685932,0.18749904002955,0.00905368030448107,0.285417173048685,0.0329924030996098,0.239897419685483,4.82754995951394,-11.8035753702231,0.169490044091791,-0.0179967222507787,0.0371810116332674,-0.0536288335065096,1.6069710109252};
      constant Real[:] I={-12,-12,-8,-8,-8,-8,-8,-8,-6,-6,-6,-6,-6,-6,-4,-4,-4,-3,-3,-2,-2,-1,-1,-1,-1,0,1,1,2,2};
      constant Real[:] J={0,1,0,1,3,6,7,8,0,1,2,5,6,10,3,6,10,0,2,1,2,0,1,4,5,0,0,1,2,6};
      constant Modelica.SIunits.Volume vstar=0.0088 "normalization temperature";
      constant Modelica.SIunits.Pressure pstar=100000000.0 "normalization pressure";
      constant Modelica.SIunits.SpecificEnthalpy hstar=2800000.0 "normalization enthalpy";
      Real pi=p/pstar "normalized specific pressure";
      Real eta=h/hstar "normalized specific enthalpy";
    algorithm
      v:=sum(n[i]*(pi + 0.0661)^I[i]*(eta - 0.72)^J[i] for i in 1:30)*vstar;
      annotation(Documentation(info="<html>
 <p>
 &nbsp;Equation number 5 from:<br>
 <div style=\"text-align: center;\">&nbsp;[1] The international Association
 for the Properties of Water and Steam<br>
 &nbsp;Vejle, Denmark<br>
 &nbsp;August 2003<br>
 &nbsp;Supplementary Release on Backward Equations for the Fucnctions
 T(p,h), v(p,h) and T(p,s), <br>
 &nbsp;v(p,s) for Region 3 of the IAPWS Industrial Formulation 1997 for
 the Thermodynamic Properties of<br>
 &nbsp;Water and Steam</div>
 </p>
 </html>"));
    end v3b_ph;

    function T3a_ps "Region 3 a: inverse function T(p,s)"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "Pressure";
      input Modelica.SIunits.SpecificEntropy s "specific entropy";
      output Modelica.SIunits.Temp_K T "Temperature";
    protected
      constant Real[:] n={1500420082.63875,-159397258480.424,0.000502181140217975,-67.2057767855466,1450.58545404456,-8238.8953488889,-0.154852214233853,11.2305046746695,-29.7000213482822,43856513263.5495,0.00137837838635464,-2.97478527157462,9717779473494.13,-5.71527767052398e-05,28830.794977842,-74442828926270.3,12.8017324848921,-368.275545889071,6.64768904779177e+15,0.044935925195888,-4.22897836099655,-0.240614376434179,-4.74341365254924,0.72409399912611,0.923874349695897,3.99043655281015,0.0384066651868009,-0.00359344365571848,-0.735196448821653,0.188367048396131,0.000141064266818704,-0.00257418501496337,0.00123220024851555};
      constant Real[:] I={-12,-12,-10,-10,-10,-10,-8,-8,-8,-8,-6,-6,-6,-5,-5,-5,-4,-4,-4,-2,-2,-1,-1,0,0,0,1,2,2,3,8,8,10};
      constant Real[:] J={28,32,4,10,12,14,5,7,8,28,2,6,32,0,14,32,6,10,36,1,4,1,6,0,1,4,0,0,3,2,0,1,2};
      constant Modelica.SIunits.Temp_K Tstar=760 "normalization temperature";
      constant Modelica.SIunits.Pressure pstar=100000000.0 "normalization pressure";
      constant Modelica.SIunits.SpecificEntropy sstar=4400.0 "normalization entropy";
      Real pi=p/pstar "normalized specific pressure";
      Real sigma=s/sstar "normalized specific entropy";
    algorithm
      T:=sum(n[i]*(pi + 0.24)^I[i]*(sigma - 0.703)^J[i] for i in 1:33)*Tstar;
      annotation(Documentation(info="<html>
 <p>
 &nbsp;Equation number 6 from:<br>
 <div style=\"text-align: center;\">&nbsp;[1] The international Association
 for the Properties of Water and Steam<br>
 &nbsp;Vejle, Denmark<br>
 &nbsp;August 2003<br>
 &nbsp;Supplementary Release on Backward Equations for the Fucnctions
 T(p,h), v(p,h) and T(p,s), <br>
 &nbsp;v(p,s) for Region 3 of the IAPWS Industrial Formulation 1997 for
 the Thermodynamic Properties of<br>
 &nbsp;Water and Steam</div>
 </p>
 </html>"));
    end T3a_ps;

    function T3b_ps "Region 3 b: inverse function T(p,s)"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "Pressure";
      input Modelica.SIunits.SpecificEntropy s "specific entropy";
      output Modelica.SIunits.Temp_K T "Temperature";
    protected
      constant Real[:] n={0.52711170160166,-40.1317830052742,153.020073134484,-2247.99398218827,-0.193993484669048,-1.40467557893768,42.6799878114024,0.752810643416743,22.6657238616417,-622.873556909932,-0.660823667935396,0.841267087271658,-25.3717501764397,485.708963532948,880.531517490555,2650155.92794626,-0.359287150025783,-656.991567673753,2.41768149185367,0.856873461222588,0.655143675313458,-0.213535213206406,0.00562974957606348,-316955725450471.0,-0.000699997000152457,0.0119845803210767,1.93848122022095e-05,-2.15095749182309e-05};
      constant Real[:] I={-12,-12,-12,-12,-8,-8,-8,-6,-6,-6,-5,-5,-5,-5,-5,-4,-3,-3,-2,0,2,3,4,5,6,8,12,14};
      constant Real[:] J={1,3,4,7,0,1,3,0,2,4,0,1,2,4,6,12,1,6,2,0,1,1,0,24,0,3,1,2};
      constant Modelica.SIunits.Temp_K Tstar=860 "normalization temperature";
      constant Modelica.SIunits.Pressure pstar=100000000.0 "normalization pressure";
      constant Modelica.SIunits.SpecificEntropy sstar=5300.0 "normalization entropy";
      Real pi=p/pstar "normalized specific pressure";
      Real sigma=s/sstar "normalized specific entropy";
    algorithm
      T:=sum(n[i]*(pi + 0.76)^I[i]*(sigma - 0.818)^J[i] for i in 1:28)*Tstar;
      annotation(Documentation(info="<html>
 <p>
 &nbsp;Equation number 7 from:<br>
 <div style=\"text-align: center;\">&nbsp;[1] The international Association
 for the Properties of Water and Steam<br>
 &nbsp;Vejle, Denmark<br>
 &nbsp;August 2003<br>
 &nbsp;Supplementary Release on Backward Equations for the Fucnctions
 T(p,h), v(p,h) and T(p,s), <br>
 &nbsp;v(p,s) for Region 3 of the IAPWS Industrial Formulation 1997 for
 the Thermodynamic Properties of<br>
 &nbsp;Water and Steam</div>
 </p>
 </html>"));
    end T3b_ps;

    function v3a_ps "Region 3 a: inverse function v(p,s)"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "Pressure";
      input Modelica.SIunits.SpecificEntropy s "specific entropy";
      output Modelica.SIunits.SpecificVolume v "specific volume";
    protected
      constant Real[:] n={79.5544074093975,-2382.6124298459,17681.3100617787,-0.00110524727080379,-15.3213833655326,297.544599376982,-35031520.6871242,0.277513761062119,-0.523964271036888,-148011.182995403,1600148.99374266,1708023226634.27,0.000246866996006494,1.6532608479798,-0.118008384666987,2.537986423559,0.965127704669424,-28.2172420532826,0.203224612353823,1.10648186063513,0.52612794845128,0.277000018736321,1.08153340501132,-0.0744127885357893,0.0164094443541384,-0.0680468275301065,0.025798857610164,-0.000145749861944416};
      constant Real[:] I={-12,-12,-12,-10,-10,-10,-10,-8,-8,-8,-8,-6,-5,-4,-3,-3,-2,-2,-1,-1,0,0,0,1,2,4,5,6};
      constant Real[:] J={10,12,14,4,8,10,20,5,6,14,16,28,1,5,2,4,3,8,1,2,0,1,3,0,0,2,2,0};
      constant Modelica.SIunits.Volume vstar=0.0028 "normalization temperature";
      constant Modelica.SIunits.Pressure pstar=100000000.0 "normalization pressure";
      constant Modelica.SIunits.SpecificEntropy sstar=4400.0 "normalization entropy";
      Real pi=p/pstar "normalized specific pressure";
      Real sigma=s/sstar "normalized specific entropy";
    algorithm
      v:=sum(n[i]*(pi + 0.187)^I[i]*(sigma - 0.755)^J[i] for i in 1:28)*vstar;
      annotation(Documentation(info="<html>
 <p>
 &nbsp;Equation number 8 from:<br>
 <div style=\"text-align: center;\">&nbsp;[1] The international Association
 for the Properties of Water and Steam<br>
 &nbsp;Vejle, Denmark<br>
 &nbsp;August 2003<br>
 &nbsp;Supplementary Release on Backward Equations for the Fucnctions
 T(p,h), v(p,h) and T(p,s), <br>
 &nbsp;v(p,s) for Region 3 of the IAPWS Industrial Formulation 1997 for
 the Thermodynamic Properties of<br>
 &nbsp;Water and Steam</div>
 </p>
 </html>"));
    end v3a_ps;

    function v3b_ps "Region 3 b: inverse function v(p,s)"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "Pressure";
      input Modelica.SIunits.SpecificEntropy s "specific entropy";
      output Modelica.SIunits.SpecificVolume v "specific volume";
    protected
      constant Real[:] n={5.91599780322238e-05,-0.00185465997137856,0.0104190510480013,0.0059864730203859,-0.771391189901699,1.72549765557036,-0.000467076079846526,0.0134533823384439,-0.0808094336805495,0.508139374365767,0.00128584643361683,-1.63899353915435,5.86938199318063,-2.92466667918613,-0.00614076301499537,5.76199014049172,-12.1613320606788,1.67637540957944,-7.44135838773463,0.0378168091437659,4.01432203027688,16.0279837479185,3.17848779347728,-3.58362310304853,-1159952.60446827,0.199256573577909,-0.122270624794624,-19.1449143716586,-0.0150448002905284,14.6407900162154,-3.2747778718823};
      constant Real[:] I={-12,-12,-12,-12,-12,-12,-10,-10,-10,-10,-8,-5,-5,-5,-4,-4,-4,-4,-3,-2,-2,-2,-2,-2,-2,0,0,0,1,1,2};
      constant Real[:] J={0,1,2,3,5,6,0,1,2,4,0,1,2,3,0,1,2,3,1,0,1,2,3,4,12,0,1,2,0,2,2};
      constant Modelica.SIunits.Volume vstar=0.0088 "normalization temperature";
      constant Modelica.SIunits.Pressure pstar=100000000.0 "normalization pressure";
      constant Modelica.SIunits.SpecificEntropy sstar=5300.0 "normalization entropy";
      Real pi=p/pstar "normalized specific pressure";
      Real sigma=s/sstar "normalized specific entropy";
    algorithm
      v:=sum(n[i]*(pi + 0.298)^I[i]*(sigma - 0.816)^J[i] for i in 1:31)*vstar;
      annotation(Documentation(info="<html>
 <p>
 &nbsp;Equation number 9 from:<br>
 <div style=\"text-align: center;\">&nbsp;[1] The international Association
 for the Properties of Water and Steam<br>
 &nbsp;Vejle, Denmark<br>
 &nbsp;August 2003<br>
 &nbsp;Supplementary Release on Backward Equations for the Fucnctions
 T(p,h), v(p,h) and T(p,s), <br>
 &nbsp;v(p,s) for Region 3 of the IAPWS Industrial Formulation 1997 for
 the Thermodynamic Properties of<br>
 &nbsp;Water and Steam</div>
 </p>
 </html>"));
    end v3b_ps;

    annotation(Documentation(info="<HTML><h4>Package description</h4>
          <p>Package BaseIF97/Basic computes the the fundamental functions for the 5 regions of the steam tables
          as described in the standards document <a href=\"Documentation/IF97documentation/IF97.pdf\">IF97.pdf</a>. The code of these
          functions has been generated using <b><i>Mathematica</i></b> and the add-on packages \"Format\" and \"Optimize\"
          to generate highly efficient, expression-optimized C-code from a symbolic representation of the thermodynamic
          functions. The C-code has than been transformed into Modelica code. An important feature of this optimization was to
          simultaneously optimize the functions and the directional derivatives because they share many common subexpressions.</p>
          <h4>Package contents</h4>
          <p>
          <ul>
          <li>Function <b>g1</b> computes the dimensionless Gibbs function for region 1 and all derivatives up
          to order 2 w.r.t pi and tau. Inputs: p and T.</li>
          <li>Function <b>g2</b> computes the dimensionless Gibbs function  for region 2 and all derivatives up
          to order 2 w.r.t pi and tau. Inputs: p and T.</li>
          <li>Function <b>g2metastable</b> computes the dimensionless Gibbs function for metastable vapour
          (adjacent to region 2 but 2-phase at equilibrium) and all derivatives up
          to order 2 w.r.t pi and tau. Inputs: p and T.</li>
          <li>Function <b>f3</b> computes the dimensionless Helmholtz function  for region 3 and all derivatives up
          to order 2 w.r.t delta and tau. Inputs: d and T.</li>
          <li>Function <b>g5</b>computes the dimensionless Gibbs function for region 5 and all derivatives up
          to order 2 w.r.t pi and tau. Inputs: p and T.</li>
          <li>Function <b>tph1</b> computes the inverse function T(p,h) in region 1.</li>
          <li>Function <b>tph2</b> computes the inverse function T(p,h) in region 2.</li>
          <li>Function <b>tps2a</b> computes the inverse function T(p,s) in region 2a.</li>
          <li>Function <b>tps2b</b> computes the inverse function T(p,s) in region 2b.</li>
          <li>Function <b>tps2c</b> computes the inverse function T(p,s) in region 2c.</li>
          <li>Function <b>tps2</b> computes the inverse function T(p,s) in region 2.</li>
          <li>Function <b>tsat</b> computes the saturation temperature as a function of pressure.</li>
          <li>Function <b>dtsatofp</b> computes the derivative of the saturation temperature w.r.t. pressure as
          a function of pressure.</li>
          <li>Function <b>tsat_der</b> computes the Modelica derivative function of tsat.</li>
          <li>Function <b>psat</b> computes the saturation pressure as a function of temperature.</li>
          <li>Function <b>dptofT</b>  computes the derivative of the saturation pressure w.r.t. temperature as
          a function of temperature.</li>
          <li>Function <b>psat_der</b> computes the Modelica derivative function of psat.</li>
          </ul>
          </p>
          <h4>Version Info and Revision history
          </h4>
          <ul>
          <li>First implemented: <i>July, 2000</i>
          by <a href=\"http://www.control.lth.se/~hubertus/\">Hubertus Tummescheit</a>
          </li>
          </ul>
          <address>Author: Hubertus Tummescheit, <br>
      Modelon AB<br>
      Ideon Science Park<br>
      SE-22370 Lund, Sweden<br>
      email: hubertus@modelon.se
          </address>
          <ul>
          <li>Initial version: July 2000</li>
          <li>Documentation added: December 2002</li>
          </ul>
          </HTML>
          "), Documentation(info="<html>
       <p>
       &nbsp;Equation from:<br>
       <div style=\"text-align: center;\">&nbsp;[1] The international Association
       for the Properties of Water and Steam<br>
       &nbsp;Vejle, Denmark<br>
       &nbsp;August 2003<br>
       &nbsp;Supplementary Release on Backward Equations for the Fucnctions
       T(p,h), v(p,h) and T(p,s), <br>
       &nbsp;v(p,s) for Region 3 of the IAPWS Industrial Formulation 1997 for
       the Thermodynamic Properties of<br>
       &nbsp;Water and Steam</div>
       </p>
       </html>"));
    function g1L3 "base function for region 1 with 3rd derivatives for sensitivities: g(p,T)"
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature (K)";
      output ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs3rd g "dimensionless Gibbs function and derivatives up to 3rd derivatives";
    protected
      Real pi1;
      Real tau1;
      Real[55] o;
    algorithm
      assert(p > ThermoSysPro.Properties.WaterSteam.BaseIF97.triple.ptriple, "IF97 medium function g1 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(ThermoSysPro.Properties.WaterSteam.BaseIF97.triple.ptriple) + " Pa (triple point pressure)");
      assert(p <= 100000000.0, "IF97 medium function g1: the input pressure (= " + String(p) + " Pa) is higher than 100 Mpa");
      assert(T >= 273.15, "IF97 medium function g1: the temperature (= " + String(T) + " K)  is lower than 273.15 K!");
      g.p:=p;
      g.T:=T;
      g.R:=ThermoSysPro.Properties.WaterSteam.BaseIF97.data.RH2O;
      g.pi:=p/ThermoSysPro.Properties.WaterSteam.BaseIF97.data.PSTAR1;
      g.tau:=ThermoSysPro.Properties.WaterSteam.BaseIF97.data.TSTAR1/T;
      pi1:=7.1 - g.pi;
      tau1:=-1.222 + g.tau;
      o[1]:=tau1*tau1;
      o[2]:=o[1]*o[1];
      o[3]:=o[2]*o[2];
      o[4]:=o[3]*tau1;
      o[5]:=1/o[4];
      o[6]:=o[1]*o[2];
      o[7]:=o[1]*tau1;
      o[8]:=1/o[7];
      o[9]:=o[1]*o[2]*o[3];
      o[10]:=1/o[2];
      o[11]:=o[2]*tau1;
      o[12]:=1/o[11];
      o[13]:=o[2]*o[3];
      o[14]:=1/o[3];
      o[15]:=pi1*pi1;
      o[16]:=o[15]*pi1;
      o[17]:=o[15]*o[15];
      o[18]:=o[17]*o[17];
      o[19]:=o[17]*o[18]*pi1;
      o[20]:=o[15]*o[17];
      o[21]:=o[3]*o[3];
      o[22]:=o[21]*o[21];
      o[23]:=o[22]*o[3]*tau1;
      o[24]:=1/o[23];
      o[25]:=o[22]*o[3];
      o[26]:=1/o[25];
      o[27]:=o[1]*o[2]*o[22]*tau1;
      o[28]:=1/o[27];
      o[29]:=o[1]*o[2]*o[22];
      o[30]:=1/o[29];
      o[31]:=o[1]*o[2]*o[21]*o[3]*tau1;
      o[32]:=1/o[31];
      o[33]:=o[2]*o[21]*o[3]*tau1;
      o[34]:=1/o[33];
      o[35]:=o[1]*o[3]*tau1;
      o[36]:=1/o[35];
      o[37]:=5.85475673349302e-08*o[11];
      o[38]:=o[1]*o[3];
      o[39]:=1/o[38];
      o[40]:=1/o[6];
      o[41]:=o[1]*o[22]*o[3];
      o[42]:=1/o[41];
      o[43]:=1/o[22];
      o[44]:=o[1]*o[2]*o[21]*o[3];
      o[45]:=1/o[44];
      o[46]:=1/o[13];
      o[47]:=-0.00031703014781958*o[2];
      o[48]:=o[1]*o[2]*tau1;
      o[49]:=1/o[48];
      o[50]:=o[1]*o[22]*o[3]*tau1;
      o[51]:=1/o[50];
      o[52]:=o[22]*tau1;
      o[53]:=1/o[52];
      o[54]:=o[2]*o[3]*tau1;
      o[55]:=1/o[54];
      g.g:=pi1*(pi1*(pi1*(o[10]*(-3.1679644845054e-05 + o[2]*(-2.8270797985312e-06 - 8.5205128120103e-10*o[6])) + pi1*(o[12]*(-2.2425281908e-06 + (-6.5171222895601e-07 - 1.4341729937924e-13*o[13])*o[7]) + pi1*(-4.0516996860117e-07*o[14] + o[16]*((-1.2734301741641e-09 - 1.7424871230634e-10*o[11])*o[36] + o[19]*(-6.8762131295531e-19*o[34] + o[15]*(1.4478307828521e-20*o[32] + o[20]*(2.6335781662795e-23*o[30] + pi1*(-1.1947622640071e-23*o[28] + pi1*(1.8228094581404e-24*o[26] - 9.3537087292458e-26*o[24]*pi1))))))))) + o[8]*(-0.00047184321073267 + o[7]*(-0.00030001780793026 + (4.7661393906987e-05 + o[1]*(-4.4141845330846e-06 - 7.2694996297594e-16*o[9]))*tau1))) + o[5]*(0.00028319080123804 + o[1]*(-0.00060706301565874 + o[6]*(-0.018990068218419 + tau1*(-0.032529748770505 + (-0.021841717175414 - 5.283835796993e-05*o[1])*tau1))))) + (0.14632971213167 + tau1*(-0.84548187169114 + tau1*(-3.756360367204 + tau1*(3.3855169168385 + tau1*(-0.95791963387872 + tau1*(0.15772038513228 + (-0.016616417199501 + 0.00081214629983568*tau1)*tau1))))))/o[1];
      g.gpi:=pi1*(pi1*(o[10]*(9.5038934535162e-05 + o[2]*(8.4812393955936e-06 + 2.55615384360309e-09*o[6])) + pi1*(o[12]*(8.9701127632e-06 + (2.60684891582404e-06 + 5.7366919751696e-13*o[13])*o[7]) + pi1*(2.02584984300585e-06*o[14] + o[16]*((1.01874413933128e-08 + 1.39398969845072e-09*o[11])*o[36] + o[19]*(1.44400475720615e-17*o[34] + o[15]*(-3.33001080055983e-19*o[32] + o[20]*(-7.63737668221055e-22*o[30] + pi1*(3.5842867920213e-22*o[28] + pi1*(-5.65070932023524e-23*o[26] + 2.99318679335866e-24*o[24]*pi1))))))))) + o[8]*(0.00094368642146534 + o[7]*(0.00060003561586052 + (-9.5322787813974e-05 + o[1]*(8.8283690661692e-06 + 1.45389992595188e-15*o[9]))*tau1))) + o[5]*(-0.00028319080123804 + o[1]*(0.00060706301565874 + o[6]*(0.018990068218419 + tau1*(0.032529748770505 + (0.021841717175414 + 5.283835796993e-05*o[1])*tau1))));
      g.gpipi:=pi1*(o[10]*(-0.000190077869070324 + o[2]*(-1.69624787911872e-05 - 5.11230768720618e-09*o[6])) + pi1*(o[12]*(-2.69103382896e-05 + (-7.82054674747212e-06 - 1.72100759255088e-12*o[13])*o[7]) + pi1*(-8.1033993720234e-06*o[14] + o[16]*((-7.13120897531896e-08 - 9.75792788915504e-09*o[11])*o[36] + o[19]*(-2.8880095144123e-16*o[34] + o[15]*(7.32602376123163e-18*o[32] + o[20]*(2.13846547101895e-20*o[30] + pi1*(-1.03944316968618e-20*o[28] + pi1*(1.69521279607057e-21*o[26] - 9.27887905941183e-23*o[24]*pi1))))))))) + o[8]*(-0.00094368642146534 + o[7]*(-0.00060003561586052 + (9.5322787813974e-05 + o[1]*(-8.8283690661692e-06 - 1.45389992595188e-15*o[9]))*tau1));
      g.gpipipi:=o[10]*(0.000190077869070324 + o[2]*(1.69624787911872e-05 + 5.11230768720618e-09*o[6])) + pi1*(o[12]*(5.38206765792e-05 + (1.56410934949442e-05 + 3.44201518510176e-12*o[13])*o[7]) + pi1*(2.43101981160702e-05*o[14] + o[16]*(o[36]*(4.27872538519138e-07 + o[37]) + o[19]*(5.48721807738337e-15*o[34] + o[15]*(-1.53846498985864e-16*o[32] + o[20]*(-5.77385677175118e-19*o[30] + pi1*(2.9104408751213e-19*o[28] + pi1*(-4.91611710860466e-20*o[26] + 2.78366371782355e-21*o[24]*pi1))))))));
      g.gtau:=pi1*(o[39]*(-0.00254871721114236 + o[1]*(0.00424944110961118 + (0.018990068218419 + (-0.021841717175414 - 0.00015851507390979*o[1])*o[1])*o[6])) + pi1*(o[10]*(0.00141552963219801 + o[2]*(4.7661393906987e-05 + o[1]*(-1.32425535992538e-05 - 1.2358149370591e-14*o[9]))) + pi1*(o[12]*(0.000126718579380216 - 5.11230768720618e-09*o[38]) + pi1*(o[40]*(1.1212640954e-05 + (1.30342445791202e-06 - 1.4341729937924e-12*o[13])*o[7]) + pi1*(3.24135974880936e-06*o[5] + o[16]*((1.40077319158051e-08 + 1.04549227383804e-09*o[11])*o[46] + o[19]*(1.9941018075704e-17*o[45] + o[15]*(-4.48827542684151e-19*o[43] + o[20]*(-1.00075970318621e-21*o[28] + pi1*(4.65957282962769e-22*o[26] + pi1*(-7.2912378325616e-23*o[24] + 3.83502057899078e-24*o[42]*pi1))))))))))) + o[8]*(-0.29265942426334 + tau1*(0.84548187169114 + o[1]*(3.3855169168385 + tau1*(-1.91583926775744 + tau1*(0.47316115539684 + (-0.066465668798004 + 0.0040607314991784*tau1)*tau1)))));
      g.gtautau:=pi1*(o[36]*(0.0254871721114236 + o[1]*(-0.0339955288768894 + (-0.037980136436838 + o[47])*o[6])) + pi1*(o[12]*(-0.00566211852879204 + o[6]*(-2.64851071985076e-05 - 1.97730389929456e-13*o[9])) + pi1*((-0.00063359289690108 - 2.55615384360309e-08*o[38])*o[40] + pi1*(o[49]*(-6.7275845724e-05 + (-3.91027337373606e-06 - 1.29075569441316e-11*o[13])*o[7]) + pi1*(-2.91722377392842e-05*o[39] + o[16]*((-1.68092782989661e-07 - 7.31844591686628e-09*o[11])*o[55] + o[19]*(-5.9823054227112e-16*o[32] + o[15]*(1.43624813658928e-17*o[53] + o[20]*(3.90296284242622e-20*o[26] + pi1*(-1.86382913185108e-20*o[24] + pi1*(2.98940751135026e-21*o[42] - 1.61070864317613e-22*o[51]*pi1))))))))))) + o[10]*(0.87797827279002 + tau1*(-1.69096374338228 + o[7]*(-1.91583926775744 + tau1*(0.94632231079368 + (-0.199397006394012 + 0.0162429259967136*tau1)*tau1))));
      g.gtautautau:=pi1*(o[46]*(-0.28035889322566 + o[1]*(0.305959759892005 + (0.113940409310514 + o[47])*o[6])) + pi1*(o[40]*(0.0283105926439602 + o[6]*(-2.64851071985076e-05 - 2.96595584894183e-12*o[9])) + pi1*((0.00380155738140648 - 1.02246153744124e-07*o[38])*o[49] + pi1*(o[14]*(0.000470930920068 + (1.56410934949442e-05 - 1.03260455553053e-10*o[13])*o[7]) + pi1*(0.000291722377392842*o[36] + o[16]*((2.1852061788656e-06 + o[37])/o[9] + o[19]*(1.85451468104047e-14*o[43] + o[15]*(-4.73961885074464e-16/(o[1]*o[22]) + o[20]*(-1.56118513697049e-18*o[24] + pi1*(7.64169944058941e-19*o[42] + pi1*(-1.25555115476711e-19*o[51] + 6.92604716565734e-21*pi1/(o[2]*o[22]*o[3])))))))))))) + o[12]*(-3.51191309116008 + tau1*(5.07289123014684 + o[2]*(0.94632231079368 + (-0.398794012788024 + 0.0487287779901408*tau1)*tau1)));
      g.gpitau:=o[39]*(0.00254871721114236 + o[1]*(-0.00424944110961118 + (-0.018990068218419 + (0.021841717175414 + 0.00015851507390979*o[1])*o[1])*o[6])) + pi1*(o[10]*(-0.00283105926439602 + o[2]*(-9.5322787813974e-05 + o[1]*(2.64851071985076e-05 + 2.4716298741182e-14*o[9]))) + pi1*(o[12]*(-0.000380155738140648 + 1.53369230616185e-08*o[38]) + pi1*(o[40]*(-4.4850563816e-05 + (-5.21369783164808e-06 + 5.7366919751696e-12*o[13])*o[7]) + pi1*(-1.62067987440468e-05*o[5] + o[16]*((-1.12061855326441e-07 - 8.36393819070432e-09*o[11])*o[46] + o[19]*(-4.18761379589784e-16*o[45] + o[15]*(1.03230334817355e-17*o[43] + o[20]*(2.90220313924001e-20*o[28] + pi1*(-1.39787184888831e-20*o[26] + pi1*(2.2602837280941e-21*o[24] - 1.22720658527705e-22*o[42]*pi1))))))))));
      g.gpipitau:=o[10]*(0.00283105926439602 + o[2]*(9.5322787813974e-05 + o[1]*(-2.64851071985076e-05 - 2.4716298741182e-14*o[9]))) + pi1*(o[12]*(0.000760311476281296 - 3.06738461232371e-08*o[38]) + pi1*(o[40]*(0.000134551691448 + (1.56410934949442e-05 - 1.72100759255088e-11*o[13])*o[7]) + pi1*(6.48271949761872e-05*o[5] + o[16]*((7.84432987285086e-07 + o[37])*o[46] + o[19]*(8.37522759179568e-15*o[45] + o[15]*(-2.2710673659818e-16*o[43] + o[20]*(-8.12616878987203e-19*o[28] + pi1*(4.05382836177609e-19*o[26] + pi1*(-6.78085118428229e-20*o[24] + 3.80434041435885e-21*o[42]*pi1)))))))));
      g.gpitautau:=o[36]*(-0.0254871721114236 + o[1]*(0.0339955288768894 + (0.037980136436838 + 0.00031703014781958*o[2])*o[6])) + pi1*(o[12]*(0.0113242370575841 + o[6]*(5.29702143970152e-05 + 3.95460779858911e-13*o[9])) + pi1*((0.00190077869070324 + 7.66846153080927e-08*o[38])*o[40] + pi1*(o[49]*(0.000269103382896 + (1.56410934949442e-05 + 5.16302277765264e-11*o[13])*o[7]) + pi1*(0.000145861188696421*o[39] + o[16]*((1.34474226391729e-06 + o[37])*o[55] + o[19]*(1.25628413876935e-14*o[32] + o[15]*(-3.30337071415535e-16*o[53] + o[20]*(-1.1318592243036e-18*o[26] + pi1*(5.59148739555323e-19*o[24] + pi1*(-9.26716328518579e-20*o[42] + 5.1542676581636e-21*o[51]*pi1))))))))));
    end g1L3;

    function g2L3 "base function for region 2 with 3rd derivatives for sensitivities: g(p,T)"
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature (K)";
      output ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs3rd g "dimensionless Gibbs function and derivatives up to 3rd derivatives";
    protected
      Real pi2;
      Real tau2;
      Real[82] o;
    algorithm
      assert(p > ThermoSysPro.Properties.WaterSteam.BaseIF97.triple.ptriple, "IF97 medium function g2 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(ThermoSysPro.Properties.WaterSteam.BaseIF97.triple.ptriple) + " Pa (triple point pressure)");
      assert(p <= 100000000.0, "IF97 medium function g2: the input pressure (= " + String(p) + " Pa) is higher than 100 Mpa");
      assert(T >= 273.15, "IF97 medium function g2: the temperature (= " + String(T) + " K) is lower than 273.15 K!");
      assert(T <= 1073.15, "IF97 medium function g2: the input temperature (= " + String(T) + " K) is higher than the limit of 1073.15 K");
      g.p:=p;
      g.T:=T;
      g.R:=ThermoSysPro.Properties.WaterSteam.BaseIF97.data.RH2O;
      g.pi:=p/ThermoSysPro.Properties.WaterSteam.BaseIF97.data.PSTAR2;
      g.tau:=ThermoSysPro.Properties.WaterSteam.BaseIF97.data.TSTAR2/T;
      tau2:=-0.5 + g.tau;
      o[1]:=tau2*tau2;
      o[2]:=o[1]*tau2;
      o[3]:=-0.05032527872793*o[2];
      o[4]:=-0.057581259083432 + o[3];
      o[5]:=o[4]*tau2;
      o[6]:=-0.045996013696365 + o[5];
      o[7]:=o[6]*tau2;
      o[8]:=-0.017834862292358 + o[7];
      o[9]:=o[8]*tau2;
      o[10]:=o[1]*o[1];
      o[11]:=o[10]*o[10];
      o[12]:=o[11]*o[11];
      o[13]:=o[10]*o[11]*o[12]*tau2;
      o[14]:=o[1]*o[10]*tau2;
      o[15]:=o[10]*o[11]*tau2;
      o[16]:=o[1]*o[12]*tau2;
      o[17]:=o[1]*o[11]*tau2;
      o[18]:=o[1]*o[10]*o[11];
      o[19]:=o[10]*o[11]*o[12];
      o[20]:=o[1]*o[10];
      o[21]:=g.pi*g.pi;
      o[22]:=o[21]*o[21];
      o[23]:=o[21]*o[22];
      o[24]:=o[10]*o[12]*tau2;
      o[25]:=o[12]*o[12];
      o[26]:=o[11]*o[12]*o[25]*tau2;
      o[27]:=o[10]*o[12];
      o[28]:=o[1]*o[10]*o[11]*tau2;
      o[29]:=o[10]*o[12]*o[25]*tau2;
      o[30]:=o[1]*o[10]*o[25]*tau2;
      o[31]:=o[1]*o[11]*o[12];
      o[32]:=o[1]*o[12];
      o[33]:=g.tau*g.tau;
      o[34]:=o[33]*o[33];
      o[35]:=-5.3349095828174e-05*o[13];
      o[36]:=-0.087594591301146 + o[35];
      o[37]:=o[2]*o[36];
      o[38]:=-0.007878555448671 + o[37];
      o[39]:=o[1]*o[38];
      o[40]:=-0.0003789797503263 + o[39];
      o[41]:=o[40]*tau2;
      o[42]:=-6.6065283340406e-05 + o[41];
      o[43]:=o[42]*tau2;
      o[44]:=-0.244009521375894*o[13];
      o[45]:=-0.0090203547252888 + o[44];
      o[46]:=o[2]*o[45];
      o[47]:=-0.00019366606343142 + o[46];
      o[48]:=o[1]*o[47];
      o[49]:=2.6322400370661e-06 + o[48];
      o[50]:=o[49]*tau2;
      o[51]:=5.78704472622084e-06*tau2;
      o[52]:=o[21]*g.pi;
      o[53]:=1.15740894524417e-05*tau2;
      o[54]:=-0.30195167236758*o[2];
      o[55]:=-0.172743777250296 + o[54];
      o[56]:=o[55]*tau2;
      o[57]:=-0.09199202739273 + o[56];
      o[58]:=o[57]*tau2;
      o[59]:=o[1]*o[11];
      o[60]:=o[10]*o[11];
      o[61]:=o[11]*o[12]*o[25];
      o[62]:=o[10]*o[12]*o[25];
      o[63]:=o[1]*o[10]*o[25];
      o[64]:=o[11]*o[12]*tau2;
      o[65]:=-1.5097583618379*o[2];
      o[66]:=-0.345487554500592 + o[65];
      o[67]:=o[66]*tau2;
      o[68]:=o[10]*tau2;
      o[69]:=o[11]*tau2;
      o[70]:=o[1]*o[11]*o[12]*tau2;
      o[71]:=o[1]*o[10]*o[12]*o[25]*tau2;
      o[72]:=o[1]*o[12]*o[25]*tau2;
      o[73]:=o[10]*o[25]*tau2;
      o[74]:=o[11]*o[12];
      o[75]:=o[34]*o[34];
      o[76]:=-0.00192056744981426*o[13];
      o[77]:=-0.613162139108022 + o[76];
      o[78]:=o[2]*o[77];
      o[79]:=-0.031514221794684 + o[78];
      o[80]:=o[1]*o[79];
      o[81]:=-0.0007579595006526 + o[80];
      o[82]:=o[81]*tau2;
      g.g:=g.pi*(-0.0017731742473213 + o[9] + g.pi*(tau2*(-3.3032641670203e-05 + (-0.00018948987516315 + o[1]*(-0.0039392777243355 + (-0.043797295650573 - 2.6674547914087e-05*o[13])*o[2]))*tau2) + g.pi*(2.0481737692309e-08 + (4.3870667284435e-07 + o[1]*(-3.227767723857e-05 + (-0.0015033924542148 - 0.040668253562649*o[13])*o[2]))*tau2 + g.pi*(g.pi*(2.2922076337661e-06*o[14] + g.pi*((-1.6714766451061e-11 + o[15]*(-0.0021171472321355 - 23.895741934104*o[16]))*o[2] + g.pi*(-5.905956432427e-18 + o[17]*(-1.2621808899101e-06 - 0.038946842435739*o[18]) + g.pi*(o[11]*(1.1256211360459e-11 - 8.2311340897998*o[19]) + g.pi*(1.9809712802088e-08*o[15] + g.pi*(o[10]*(1.0406965210174e-19 + (-1.0234747095929e-13 - 1.0018179379511e-09*o[10])*o[20]) + o[23]*(o[13]*(-8.0882908646985e-11 + 0.10693031879409*o[24]) + o[21]*(-0.33662250574171*o[26] + o[21]*(o[27]*(8.9185845355421e-25 + (3.0629316876232e-13 - 4.2002467698208e-06*o[15])*o[28]) + g.pi*(-5.9056029685639e-26*o[24] + g.pi*(3.7826947613457e-06*o[29] + g.pi*(-1.2768608934681e-15*o[30] + o[31]*(7.3087610595061e-29 + o[18]*(5.5414715350778e-17 - 9.436970724121e-07*o[32]))*g.pi)))))))))))) + tau2*(-7.8847309559367e-10 + (1.2790717852285e-08 + 4.8225372718507e-07*tau2)*tau2))))) + (-0.00560879118302 + g.tau*(0.07145273881455 + g.tau*(-0.4071049823928 + g.tau*(1.424081971444 + g.tau*(-4.38395111945 + g.tau*(-9.692768600217 + g.tau*(10.08665568018 + (-0.2840863260772 + 0.02126846353307*g.tau)*g.tau) + Modelica.Math.log(g.pi)))))))/(o[34]*g.tau);
      g.gpi:=(1.0 + g.pi*(-0.0017731742473213 + o[9] + g.pi*(o[43] + g.pi*(6.1445213076927e-08 + (1.31612001853305e-06 + o[1]*(-9.683303171571e-05 + (-0.0045101773626444 - 0.122004760687947*o[13])*o[2]))*tau2 + g.pi*(g.pi*(1.14610381688305e-05*o[14] + g.pi*((-1.00288598706366e-10 + o[15]*(-0.012702883392813 - 143.374451604624*o[16]))*o[2] + g.pi*(-4.1341695026989e-17 + o[17]*(-8.8352662293707e-06 - 0.272627897050173*o[18]) + g.pi*(o[11]*(9.0049690883672e-11 - 65.8490727183984*o[19]) + g.pi*(1.78287415218792e-07*o[15] + g.pi*(o[10]*(1.0406965210174e-18 + (-1.0234747095929e-12 - 1.0018179379511e-08*o[10])*o[20]) + o[23]*(o[13]*(-1.29412653835176e-09 + 1.71088510070544*o[24]) + o[21]*(-6.05920510335078*o[26] + o[21]*(o[27]*(1.78371690710842e-23 + (6.1258633752464e-12 - 8.4004935396416e-05*o[15])*o[28]) + g.pi*(-1.24017662339842e-24*o[24] + g.pi*(8.32192847496054e-05*o[29] + g.pi*(-2.93678005497663e-14*o[30] + o[31]*(1.75410265428146e-27 + o[18]*(1.32995316841867e-15 - 2.26487297378904e-05*o[32]))*g.pi)))))))))))) + tau2*(-3.15389238237468e-09 + (5.116287140914e-08 + 1.92901490874028e-06*tau2)*tau2))))))/g.pi;
      g.gpipi:=(-1.0 + o[21]*(o[43] + g.pi*(1.22890426153854e-07 + o[50] + g.pi*(g.pi*(4.5844152675322e-05*o[14] + g.pi*((-5.0144299353183e-10 + o[15]*(-0.063514416964065 - 716.87225802312*o[16]))*o[2] + g.pi*(-2.48050170161934e-16 + o[17]*(-5.30115973762242e-05 - 1.63576738230104*o[18]) + g.pi*(o[11]*(6.30347836185704e-10 - 460.943509028789*o[19]) + g.pi*(1.42629932175034e-06*o[15] + g.pi*(o[10]*(9.3662686891566e-18 + (-9.2112723863361e-12 - 9.0163614415599e-08*o[10])*o[20]) + o[23]*(o[13]*(-1.94118980752764e-08 + 25.6632765105816*o[24]) + o[21]*(-103.006486756963*o[26] + o[21]*(o[27]*(3.389062123506e-22 + (1.16391404129682e-10 - 0.0015960937725319*o[15])*o[28]) + g.pi*(-2.48035324679684e-23*o[24] + g.pi*(0.00174760497974171*o[29] + g.pi*(-6.46091612094859e-13*o[30] + o[31]*(4.03443610484737e-26 + o[18]*(3.05889228736295e-14 - 0.000520920783971479*o[32]))*g.pi)))))))))))) + tau2*(-9.46167714712404e-09 + (1.5348861422742e-07 + o[51])*tau2)))))/o[21];
      g.gpipipi:=(2.0 + o[52]*(1.22890426153854e-07 + o[50] + g.pi*(g.pi*(0.000137532458025966*o[14] + g.pi*((-2.00577197412732e-09 + o[15]*(-0.25405766785626 - 2867.48903209248*o[16]))*o[2] + g.pi*(-1.24025085080967e-15 + o[17]*(-0.000265057986881121 - 8.17883691150519*o[18]) + g.pi*(o[11]*(3.78208701711422e-09 - 2765.66105417273*o[19]) + g.pi*(9.98409525225235e-06*o[15] + g.pi*(o[10]*(7.49301495132528e-17 + (-7.36901790906888e-11 - 7.21308915324792e-07*o[10])*o[20]) + o[23]*(o[13]*(-2.7176657305387e-07 + 359.285871148142*o[24]) + o[21]*(-1648.10378811141*o[26] + o[21]*(o[27]*(6.1003118223108e-21 + (2.09504527433427e-09 - 0.0287296879055743*o[15])*o[28]) + g.pi*(-4.71267116891399e-22*o[24] + g.pi*(0.0349520995948343*o[29] + g.pi*(-1.3567923853992e-11*o[30] + o[31]*(8.87575943066421e-25 + o[18]*(6.72956303219848e-13 - 0.0114602572473725*o[32]))*g.pi)))))))))))) + tau2*(-1.89233542942481e-08 + (3.0697722845484e-07 + o[53])*tau2))))/o[52];
      g.gtau:=(0.0280439559151 + g.tau*(-0.2858109552582 + g.tau*(1.2213149471784 + g.tau*(-2.848163942888 + g.tau*(4.38395111945 + o[33]*(10.08665568018 + (-0.5681726521544 + 0.06380539059921*g.tau)*g.tau))))))/(o[33]*o[34]) + g.pi*(-0.017834862292358 + o[58] + g.pi*(-3.3032641670203e-05 + (-0.0003789797503263 + o[1]*(-0.015757110897342 + (-0.306581069554011 - 0.000960283724907132*o[13])*o[2]))*tau2 + g.pi*(4.3870667284435e-07 + o[1]*(-9.683303171571e-05 + (-0.0090203547252888 - 1.42338887469272*o[13])*o[2]) + g.pi*(-7.8847309559367e-10 + g.pi*(1.60454534363627e-05*o[20] + g.pi*(o[1]*(-5.0144299353183e-11 + o[15]*(-0.033874355714168 - 836.35096769364*o[16])) + g.pi*((-1.38839897890111e-05 - 0.973671060893475*o[18])*o[59] + g.pi*(o[14]*(9.0049690883672e-11 - 296.320827232793*o[19]) + g.pi*(2.57526266427144e-07*o[60] + g.pi*(o[2]*(4.1627860840696e-19 + (-1.0234747095929e-12 - 1.40254511313154e-08*o[10])*o[20]) + o[23]*(o[19]*(-2.34560435076256e-09 + 5.3465159397045*o[24]) + o[21]*(-19.1874828272775*o[61] + o[21]*(o[16]*(1.78371690710842e-23 + (1.07202609066812e-11 - 0.000201611844951398*o[15])*o[28]) + g.pi*(-1.24017662339842e-24*o[27] + g.pi*(0.000200482822351322*o[62] + g.pi*(-4.97975748452559e-14*o[63] + (1.90027787547159e-27 + o[18]*(2.21658861403112e-15 - 5.47344301999018e-05*o[32]))*o[64]*g.pi)))))))))))) + (2.558143570457e-08 + 1.44676118155521e-06*tau2)*tau2))));
      g.gtautau:=(-0.1682637354906 + g.tau*(1.429054776291 + g.tau*(-4.8852597887136 + g.tau*(8.544491828664 + g.tau*(-8.7679022389 + o[33]*(-0.5681726521544 + 0.12761078119842*g.tau)*g.tau)))))/(o[33]*o[34]*g.tau) + g.pi*(-0.09199202739273 + o[67] + g.pi*(-0.0003789797503263 + o[1]*(-0.047271332692026 + (-1.83948641732407 - 0.0336099303717496*o[13])*o[2]) + g.pi*((-0.00019366606343142 + (-0.045101773626444 - 48.3952217395523*o[13])*o[2])*tau2 + g.pi*(2.558143570457e-08 + 2.89352236311042e-06*tau2 + g.pi*(9.62727206181762e-05*o[68] + g.pi*(g.pi*((-0.000138839897890111 - 23.3681054614434*o[18])*o[69] + g.pi*((6.30347836185704e-10 - 10371.2289531477*o[19])*o[20] + g.pi*(3.09031519712573e-06*o[17] + g.pi*(o[1]*(1.24883582522088e-18 + (-9.2112723863361e-12 - 1.823308647071e-07*o[10])*o[20]) + o[23]*((-6.56769218213518e-08 + 261.979281045521*o[24])*o[70] + o[21]*(-1074.49903832754*o[71] + o[21]*((3.389062123506e-22 + (3.64488870827161e-10 - 0.00947575671271573*o[15])*o[28])*o[32] + g.pi*(-2.48035324679684e-23*o[16] + g.pi*(0.0104251067622687*o[72] + g.pi*(-1.89230784411972e-12*o[73] + (4.75069468867897e-26 + o[18]*(8.64469559472137e-14 - 0.0031198625213944*o[32]))*o[74]*g.pi)))))))))) + (-1.00288598706366e-10 + o[15]*(-0.50811533571252 - 28435.9329015838*o[16]))*tau2))))));
      g.gtautautau:=(1.1778461484342 + g.tau*(-8.574328657746 + g.tau*(24.426298943568 + g.tau*(-34.177967314656 + (26.3037067167 + 0.12761078119842*o[34])*g.tau))))/o[75] + g.pi*(-0.345487554500592 - 6.0390334473516*o[2] + g.pi*((-0.094542665384052 + (-9.19743208662033 - 1.14273763263949*o[13])*o[2])*tau2 + g.pi*(-0.00019366606343142 + (-0.180407094505776 - 1597.04231740523*o[13])*o[2] + g.pi*(2.89352236311042e-06 + g.pi*(0.000481363603090881*o[10] + g.pi*(-1.00288598706366e-10 + o[15]*(-7.11361469997528 - 938385.785752264*o[16]) + g.pi*(o[11]*(-0.001249559081011 - 537.466425613198*o[18]) + g.pi*((3.78208701711422e-09 - 352621.784407023*o[19])*o[68] + g.pi*(3.3993467168383e-05*o[59] + g.pi*((2.49767165044176e-18 + (-7.36901790906888e-11 - 2.1879703764852e-06*o[10])*o[20])*tau2 + o[23]*((-1.7732768891765e-06 + 12575.005490185*o[24])*o[31] + o[21]*(-59097.4471080146*o[1]*o[10]*o[12]*o[25] + o[21]*(o[12]*(6.1003118223108e-21 + (1.20281327372963e-08 - 0.435884808784923*o[15])*o[28])*tau2 + g.pi*(-4.71267116891399e-22*o[32] + g.pi*(0.531680444875706*o[1]*o[12]*o[25] + g.pi*(-7.00153902324298e-11*o[10]*o[25] + o[1]*o[10]*o[12]*(1.14016672528295e-24 + o[18]*(3.28498432599412e-12 - 0.174712301198087*o[32]))*g.pi*tau2))))))))))))))));
      g.gpitau:=-0.017834862292358 + o[58] + g.pi*(-6.6065283340406e-05 + o[82] + g.pi*(1.31612001853305e-06 + o[1]*(-0.00029049909514713 + (-0.0270610641758664 - 4.27016662407815*o[13])*o[2]) + g.pi*(-3.15389238237468e-09 + g.pi*(8.02272671818135e-05*o[20] + g.pi*(o[1]*(-3.00865796119098e-10 + o[15]*(-0.203246134285008 - 5018.10580616184*o[16])) + g.pi*((-9.71879285230777e-05 - 6.81569742625432*o[18])*o[59] + g.pi*(o[14]*(7.20397527069376e-10 - 2370.56661786234*o[19]) + g.pi*(2.3177363978443e-06*o[60] + g.pi*(o[2]*(4.1627860840696e-18 + (-1.0234747095929e-11 - 1.40254511313154e-07*o[10])*o[20]) + o[23]*(o[19]*(-3.7529669612201e-08 + 85.544255035272*o[24]) + o[21]*(-345.374690890994*o[61] + o[21]*(o[16]*(3.56743381421684e-22 + (2.14405218133624e-10 - 0.00403223689902797*o[15])*o[28]) + g.pi*(-2.60437090913668e-23*o[27] + g.pi*(0.00441062209172909*o[62] + g.pi*(-1.14534422144089e-12*o[63] + (4.56066690113181e-26 + o[18]*(5.31981267367469e-14 - 0.00131362632479764*o[32]))*o[64]*g.pi)))))))))))) + (1.0232574281828e-07 + o[51])*tau2)));
      g.gpipitau:=-6.6065283340406e-05 + o[82] + g.pi*(2.6322400370661e-06 + o[1]*(-0.00058099819029426 + (-0.0541221283517328 - 8.54033324815629*o[13])*o[2]) + g.pi*(-9.46167714712404e-09 + g.pi*(0.000320909068727254*o[20] + g.pi*(o[1]*(-1.50432898059549e-09 + o[15]*(-1.01623067142504 - 25090.5290308092*o[16])) + g.pi*((-0.000583127571138466 - 40.8941845575259*o[18])*o[59] + g.pi*(o[14]*(5.04278268948563e-09 - 16593.9663250364*o[19]) + g.pi*(1.85418911827544e-05*o[60] + g.pi*(o[2]*(3.74650747566264e-17 + (-9.2112723863361e-11 - 1.26229060181839e-06*o[10])*o[20]) + o[23]*(o[19]*(-5.62945044183016e-07 + 1283.16382552908*o[24]) + o[21]*(-5871.36974514691*o[61] + o[21]*(o[16]*(6.778124247012e-21 + (4.07369914453886e-09 - 0.0766125010815314*o[15])*o[28]) + g.pi*(-5.20874181827336e-22*o[27] + g.pi*(0.0926230639263108*o[62] + g.pi*(-2.51975728716995e-11*o[63] + (1.04895338726032e-24 + o[18]*(1.22355691494518e-12 - 0.0302134054703458*o[32]))*o[64]*g.pi)))))))))))) + (3.0697722845484e-07 + 1.73611341786625e-05*tau2)*tau2));
      g.gpitautau:=-0.09199202739273 + o[67] + g.pi*(-0.0007579595006526 + o[1]*(-0.094542665384052 + (-3.67897283464813 - 0.0672198607434992*o[13])*o[2]) + g.pi*((-0.00058099819029426 + (-0.135305320879332 - 145.185665218657*o[13])*o[2])*tau2 + g.pi*(1.0232574281828e-07 + o[53] + g.pi*(0.000481363603090881*o[68] + g.pi*(g.pi*((-0.000971879285230777 - 163.576738230104*o[18])*o[69] + g.pi*((5.04278268948563e-09 - 82969.831625182*o[19])*o[20] + g.pi*(2.78128367741315e-05*o[17] + g.pi*(o[1]*(1.24883582522088e-17 + (-9.2112723863361e-11 - 1.823308647071e-06*o[10])*o[20]) + o[23]*((-1.05083074914163e-06 + 4191.66849672833*o[24])*o[70] + o[21]*(-19340.9826898957*o[71] + o[21]*((6.778124247012e-21 + (7.28977741654322e-09 - 0.189515134254314*o[15])*o[28])*o[32] + g.pi*(-5.20874181827336e-22*o[16] + g.pi*(0.229352348769913*o[72] + g.pi*(-4.35230804147537e-11*o[73] + (1.14016672528295e-24 + o[18]*(2.07472694273313e-12 - 0.0748767005134657*o[32]))*o[74]*g.pi)))))))))) + (-6.01731592238196e-10 + o[15]*(-3.04869201427512 - 170615.597409503*o[16]))*tau2)))));
    end g2L3;

    function f3L3 "Helmholtz function for region 3: f(d,T), including 3rd derivatives"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "temperature (K)";
      output ThermoSysPro.Properties.WaterSteam.Common.HelmholtzDerivs3rd f "dimensionless Helmholtz function and dervatives wrt delta and tau";
    protected
      Real tau "dimensionless temperature";
      Real del "dimensionless density";
      Real[62] o "vector of auxiliary variables";
    algorithm
      f.T:=T;
      f.d:=d;
      f.R:=ThermoSysPro.Properties.WaterSteam.BaseIF97.data.RH2O;
      tau:=ThermoSysPro.Properties.WaterSteam.BaseIF97.data.TCRIT/T;
      del:=if d == ThermoSysPro.Properties.WaterSteam.BaseIF97.data.DCRIT and T == ThermoSysPro.Properties.WaterSteam.BaseIF97.data.TCRIT then 1 - Modelica.Constants.eps else abs(d/ThermoSysPro.Properties.WaterSteam.BaseIF97.data.DCRIT);
      f.tau:=tau;
      f.delta:=del;
      o[1]:=tau*tau;
      o[2]:=o[1]*o[1];
      o[3]:=o[2]*tau;
      o[4]:=o[1]*tau;
      o[5]:=o[2]*o[2];
      o[6]:=o[1]*o[5]*tau;
      o[7]:=o[5]*tau;
      o[8]:=-0.64207765181607*o[1];
      o[9]:=0.88521043984318 + o[8];
      o[10]:=o[7]*o[9];
      o[11]:=-1.1524407806681 + o[10];
      o[12]:=o[11]*o[2];
      o[13]:=-1.2654315477714 + o[12];
      o[14]:=o[1]*o[13];
      o[15]:=o[1]*o[2]*o[5]*tau;
      o[16]:=o[2]*o[5];
      o[17]:=o[1]*o[5];
      o[18]:=o[5]*o[5];
      o[19]:=o[1]*o[18]*o[2];
      o[20]:=o[1]*o[18]*o[2]*tau;
      o[21]:=o[18]*o[5];
      o[22]:=o[1]*o[18]*o[5];
      o[23]:=0.25116816848616*o[2];
      o[24]:=0.078841073758308 + o[23];
      o[25]:=o[15]*o[24];
      o[26]:=-6.100523451393 + o[25];
      o[27]:=o[26]*tau;
      o[28]:=9.7944563083754 + o[27];
      o[29]:=o[2]*o[28];
      o[30]:=-1.70429417648412 + o[29];
      o[31]:=o[1]*o[30];
      o[32]:=del*del;
      o[33]:=-2.85576214409538*o[17];
      o[34]:=-0.0492885823043778 + o[33];
      o[35]:=o[16]*o[34];
      o[36]:=-12.113949014142 + o[35];
      o[37]:=o[1]*o[36];
      o[38]:=8.339879741676 + o[37];
      o[39]:=o[1]*o[38];
      o[40]:=del*o[32];
      o[41]:=-10.9153200808732*o[1];
      o[42]:=13.2781565976477 + o[41];
      o[43]:=o[42]*o[7];
      o[44]:=-6.9146446840086 + o[43];
      o[45]:=o[2]*o[44];
      o[46]:=-2.5308630955428 + o[45];
      o[47]:=o[46]*tau;
      o[48]:=o[18]*o[5]*tau;
      o[49]:=-174.645121293971*o[1];
      o[50]:=185.894192367068 + o[49];
      o[51]:=o[50]*o[7];
      o[52]:=-34.573223420043 + o[51];
      o[53]:=o[2]*o[52];
      o[54]:=6.53037238064016*o[2];
      o[55]:=1.73450362268278 + o[54];
      o[56]:=o[15]*o[55];
      o[57]:=-42.703664159751 + o[56];
      o[58]:=o[57]*tau;
      o[59]:=58.7667378502524 + o[58];
      o[60]:=o[2]*o[59];
      o[61]:=-3.40858835296824 + o[60];
      o[62]:=o[61]*tau;
      f.f:=-15.732845290239 + tau*(20.944396974307 + (-7.6867707878716 + o[3]*(2.6185947787954 + o[4]*(-2.808078114862 + o[1]*(1.2053369696517 - 0.0084566812812502*o[6]))))*tau) + del*(o[14] + del*(0.38493460186671 + o[1]*(-0.85214708824206 + o[2]*(4.8972281541877 + (-3.0502617256965 + o[15]*(0.039420536879154 + 0.12558408424308*o[2]))*tau)) + del*(-0.2799932969871 + o[1]*(1.389979956946 + o[1]*(-2.018991502357 + o[16]*(-0.0082147637173963 - 0.47596035734923*o[17]))) + del*(0.0439840744735 + o[1]*(-0.44476435428739 + o[1]*(0.90572070719733 + 0.70522450087967*o[19])) + del*(del*(-0.022175400873096 + o[1]*(0.094260751665092 + 0.16436278447961*o[21]) + del*(-0.013503372241348*o[1] + del*(-0.014834345352472*o[22] + del*(o[1]*(0.00057922953628084 + 0.0032308904703711*o[21]) + del*(8.0964802996215e-05 - 4.4923899061815e-05*del*o[22] - 0.00016557679795037*tau))))) + (0.10770512626332 + o[1]*(-0.32913623258954 - 0.50871062041158*o[20]))*tau))))) + 1.0658070028513*Modelica.Math.log(del);
      f.fdelta:=(1.0658070028513 + del*(o[14] + del*(0.76986920373342 + o[31] + del*(-0.8399798909613 + o[1]*(4.169939870838 + o[1]*(-6.056974507071 + o[16]*(-0.0246442911521889 - 1.42788107204769*o[17]))) + del*(0.175936297894 + o[1]*(-1.77905741714956 + o[1]*(3.62288282878932 + 2.82089800351868*o[19])) + del*(del*(-0.133052405238576 + o[1]*(0.565564509990552 + 0.98617670687766*o[21]) + del*(-0.094523605689436*o[1] + del*(-0.118674762819776*o[22] + del*(o[1]*(0.00521306582652756 + 0.0290780142333399*o[21]) + del*(0.00080964802996215 - 0.000494162889679965*del*o[22] - 0.0016557679795037*tau))))) + (0.5385256313166 + o[1]*(-1.6456811629477 - 2.5435531020579*o[20]))*tau))))))/del;
      f.fdeltadelta:=(-1.0658070028513 + o[32]*(0.76986920373342 + o[31] + del*(-1.6799597819226 + o[39] + del*(0.527808893682 + o[1]*(-5.33717225144868 + o[1]*(10.868648486368 + 8.46269401055604*o[19])) + del*(del*(-0.66526202619288 + o[1]*(2.82782254995276 + 4.9308835343883*o[21]) + del*(-0.567141634136616*o[1] + del*(-0.830723339738432*o[22] + del*(o[1]*(0.0417045266122205 + 0.232624113866719*o[21]) + del*(0.00728683226965935 - 0.00494162889679965*del*o[22] - 0.0149019118155333*tau))))) + (2.1541025252664 + o[1]*(-6.5827246517908 - 10.1742124082316*o[20]))*tau)))))/o[32];
      f.fdeltadeltadelta:=(2.1316140057026 + o[40]*(-1.6799597819226 + o[39] + del*(1.055617787364 + o[1]*(-10.6743445028974 + o[1]*(21.7372969727359 + 16.9253880211121*o[19])) + del*(del*(-2.66104810477152 + o[1]*(11.311290199811 + 19.7235341375532*o[21]) + del*(-2.83570817068308*o[1] + del*(-4.98434003843059*o[22] + del*(o[1]*(0.291931686285543 + 1.62836879706703*o[21]) + del*(0.0582946581572748 - 0.0444746600711968*del*o[22] - 0.119215294524266*tau))))) + (6.4623075757992 + o[1]*(-19.7481739553724 - 30.5226372246948*o[20]))*tau))))/o[40];
      f.ftau:=20.944396974307 + (-15.3735415757432 + o[3]*(18.3301634515678 + o[4]*(-28.08078114862 + o[1]*(14.4640436358204 - 0.194503669468755*o[6]))))*tau + del*(o[47] + del*(tau*(-1.70429417648412 + o[2]*(29.3833689251262 + (-21.3518320798755 + o[15]*(0.867251811341388 + 3.26518619032008*o[2]))*tau)) + del*((2.779959913892 + o[1]*(-8.075966009428 + o[16]*(-0.131436219478341 - 12.37496929108*o[17])))*tau + del*((-0.88952870857478 + o[1]*(3.62288282878932 + 18.3358370228714*o[19]))*tau + del*(0.10770512626332 + o[1]*(-0.98740869776862 - 13.2264761307011*o[20]) + del*((0.188521503330184 + 4.27343239646986*o[21])*tau + del*(-0.027006744482696*tau + del*(-0.385692979164272*o[48] + del*(del*(-0.00016557679795037 - 0.00116802137560719*del*o[48]) + (0.00115845907256168 + 0.0840031522296486*o[21])*tau)))))))));
      f.ftautau:=-15.3735415757432 + o[3]*(109.980980709407 + o[4]*(-252.72703033758 + o[1]*(159.104479994024 - 4.2790807283126*o[6]))) + del*(-2.5308630955428 + o[53] + del*(-1.70429417648412 + o[2]*(146.916844625631 + (-128.110992479253 + o[15]*(18.2122880381691 + 81.629654758002*o[2]))*tau) + del*(2.779959913892 + o[1]*(-24.227898028284 + o[16]*(-1.97154329217511 - 309.374232277*o[17])) + del*(-0.88952870857478 + o[1]*(10.868648486368 + 458.395925571786*o[19]) + del*(del*(0.188521503330184 + 106.835809911746*o[21] + del*(-0.027006744482696 + del*(-9.6423244791068*o[21] + del*(0.00115845907256168 + 2.10007880574121*o[21] - 0.0292005343901797*o[21]*o[32])))) + (-1.97481739553724 - 330.661903267527*o[20])*tau)))));
      f.ftautautau:=o[2]*(549.904903547034 + o[4]*(-2021.81624270064 + o[1]*(1591.04479994024 - 89.8606952945646*o[6]))) + del*(o[4]*(-138.292893680172 + (2416.62450077188 - 2619.67681940957*o[1])*o[7]) + del*(o[4]*(587.667378502524 + (-640.554962396265 + o[15]*(364.245760763383 + 1959.11171419205*o[2]))*tau) + del*((-48.455796056568 + o[16]*(-27.6016060904516 - 7424.98157464799*o[17]))*tau + del*(del*(-1.97481739553724 - 7935.88567842065*o[20] + del*(2564.05943788192*o[20] + o[32]*(-231.415787498563*o[20] + del*(50.4018913377892*o[20] - 0.700812825364314*o[20]*o[32])))) + (21.7372969727359 + 11001.5022137229*o[19])*tau))));
      f.fdeltatau:=o[47] + del*(o[62] + del*((8.339879741676 + o[1]*(-24.227898028284 + o[16]*(-0.394308658435022 - 37.1249078732399*o[17])))*tau + del*((-3.55811483429912 + o[1]*(14.4915313151573 + 73.3433480914857*o[19]))*tau + del*(0.5385256313166 + o[1]*(-4.9370434888431 - 66.1323806535054*o[20]) + del*((1.1311290199811 + 25.6405943788192*o[21])*tau + del*(-0.189047211378872*tau + del*(-3.08554383331418*o[48] + del*(del*(-0.0016557679795037 - 0.0128482351316791*del*o[48]) + (0.0104261316530551 + 0.756028370066837*o[21])*tau))))))));
      f.fdeltatautau:=-2.5308630955428 + o[53] + del*(-3.40858835296824 + o[2]*(293.833689251262 + (-256.221984958506 + o[15]*(36.4245760763383 + 163.259309516004*o[2]))*tau) + del*(8.339879741676 + o[1]*(-72.683694084852 + o[16]*(-5.91462987652534 - 928.122696830999*o[17])) + del*(-3.55811483429912 + o[1]*(43.4745939454718 + 1833.58370228714*o[19]) + del*(del*(1.1311290199811 + 641.014859470479*o[21] + del*(-0.189047211378872 + del*(-77.1385958328544*o[21] + del*(0.0104261316530551 + 18.9007092516709*o[21] - 0.321205878291977*o[21]*o[32])))) + (-9.8740869776862 - 1653.30951633764*o[20])*tau))));
      f.fdeltadeltatau:=o[62] + del*((16.679759483352 + o[1]*(-48.455796056568 + o[16]*(-0.788617316870045 - 74.2498157464799*o[17])))*tau + del*((-10.6743445028974 + o[1]*(43.4745939454718 + 220.030044274457*o[19]))*tau + del*(2.1541025252664 + o[1]*(-19.7481739553724 - 264.529522614022*o[20]) + del*((5.65564509990552 + 128.202971894096*o[21])*tau + del*(-1.13428326827323*tau + del*(-21.5988068331992*o[48] + del*(del*(-0.0149019118155333 - 0.128482351316791*del*o[48]) + (0.0834090532244409 + 6.0482269605347*o[21])*tau)))))));
    end f3L3;

    function g5L3 "base function for region 5: g(p,T), including 3rd derivatives"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature (K)";
      output ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs3rd g "dimensionless Gibbs funcion and dervatives wrt pi and tau";
    protected
      Real tau "dimensionless temperature";
      Real pi "dimensionless pressure";
      Real[16] o "vector of auxiliary variables";
    algorithm
      assert(p > ThermoSysPro.Properties.WaterSteam.BaseIF97.triple.ptriple, "IF97 medium function g5 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(ThermoSysPro.Properties.WaterSteam.BaseIF97.triple.ptriple) + " Pa (triple point pressure)");
      assert(p <= ThermoSysPro.Properties.WaterSteam.BaseIF97.data.PLIMIT5, "IF97 medium function g5: input pressure (= " + String(p) + " Pa) is higher than 10 Mpa in region 5");
      assert(T <= 2273.15, "IF97 medium function g5: input temperature (= " + String(T) + " K) is higher than limit of 2273.15K in region 5");
      g.p:=p;
      g.T:=T;
      g.R:=ThermoSysPro.Properties.WaterSteam.BaseIF97.data.RH2O;
      pi:=p/ThermoSysPro.Properties.WaterSteam.BaseIF97.data.PSTAR5;
      tau:=ThermoSysPro.Properties.WaterSteam.BaseIF97.data.TSTAR5/T;
      g.pi:=pi;
      g.tau:=tau;
      o[1]:=tau*tau;
      o[2]:=-0.004594282089991*o[1];
      o[3]:=0.0021774678714571 + o[2];
      o[4]:=o[3]*tau;
      o[5]:=o[1]*tau;
      o[6]:=o[1]*o[1];
      o[7]:=o[6]*o[6];
      o[8]:=o[7]*tau;
      o[9]:=-7.9449656719138e-06*o[8];
      o[10]:=pi*pi;
      o[11]:=o[10]*pi;
      o[12]:=-0.013782846269973*o[1];
      o[13]:=-0.027565692539946*tau;
      o[14]:=o[1]*o[6]*tau;
      o[15]:=o[1]*o[6];
      o[16]:=-7.15046910472242e-05*o[7];
      g.g:=pi*(-0.00012563183589592 + o[4] + pi*(-3.9724828359569e-06*o[8] + 1.2919228289784e-07*o[5]*pi)) + (-0.024805148933466 + tau*(0.36901534980333 + tau*(-3.1161318213925 + tau*(-13.179983674201 + (6.8540841634434 - 0.32961626538917*tau)*tau + Modelica.Math.log(pi)))))/o[5];
      g.gpi:=(1.0 + pi*(-0.00012563183589592 + o[4] + pi*(o[9] + 3.8757684869352e-07*o[5]*pi)))/pi;
      g.gpipi:=(-1.0 + o[10]*(o[9] + 7.7515369738704e-07*o[5]*pi))/o[10];
      g.gpipipi:=(2.0 + 7.7515369738704e-07*o[11]*o[5])/o[11];
      g.gtau:=pi*(0.0021774678714571 + o[12] + pi*(-3.57523455236121e-05*o[7] + 3.8757684869352e-07*o[1]*pi)) + (0.074415446800398 + tau*(-0.73803069960666 + (3.1161318213925 + o[1]*(6.8540841634434 - 0.65923253077834*tau))*tau))/o[6];
      g.gtautau:=(-0.297661787201592 + tau*(2.21409209881998 + (-6.232263642785 - 0.65923253077834*o[5])*tau))/(o[6]*tau) + pi*(o[13] + pi*(-0.000286018764188897*o[14] + 7.7515369738704e-07*pi*tau));
      g.gtautautau:=pi*(-0.027565692539946 + (-0.00200213134932228*o[15] + 7.7515369738704e-07*pi)*pi) + (1.48830893600796 + tau*(-8.85636839527992 + 18.696790928355*tau))/o[15];
      g.gpitau:=0.0021774678714571 + o[12] + pi*(o[16] + 1.16273054608056e-06*o[1]*pi);
      g.gpipitau:=o[16] + 2.32546109216112e-06*o[1]*pi;
      g.gpitautau:=o[13] + pi*(-0.000572037528377794*o[14] + 2.32546109216112e-06*pi*tau);
    end g5L3;

  end Basic;

  package Transport "transport properties for water according to IAPWS/IF97"
    extends Modelica.Icons.Library;
    function visc_dT "dynamic viscosity eta(d,T), industrial formulation"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "temperature (K)";
      output Modelica.SIunits.DynamicViscosity eta "dynamic viscosity";
    protected
      constant Real n0=1.0 "viscosity coefficient";
      constant Real n1=0.978197 "viscosity coefficient";
      constant Real n2=0.579829 "viscosity coefficient";
      constant Real n3=-0.202354 "viscosity coefficient";
      constant Real[42] nn=array(0.5132047, 0.3205656, 0.0, 0.0, -0.7782567, 0.1885447, 0.2151778, 0.7317883, 1.241044, 1.476783, 0.0, 0.0, -0.2818107, -1.070786, -1.263184, 0.0, 0.0, 0.0, 0.1778064, 0.460504, 0.2340379, -0.4924179, 0.0, 0.0, -0.0417661, 0.0, 0.0, 0.1600435, 0.0, 0.0, 0.0, -0.01578386, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -0.003629481, 0.0, 0.0) "viscosity coefficients";
      constant Modelica.SIunits.Density rhostar=317.763 "scaling density";
      constant Modelica.SIunits.DynamicViscosity etastar=5.5071e-05 "scaling viscosity";
      constant Modelica.SIunits.Temperature tstar=647.226 "scaling temperature";
      Integer i "auxiliary variable";
      Integer j "auxiliary variable";
      Real delta "dimensionless density";
      Real deltam1 "dimensionless density";
      Real tau "dimensionless temperature";
      Real taum1 "dimensionless temperature";
      Real Psi0 "auxiliary variable";
      Real Psi1 "auxiliary variable";
      Real tfun "auxiliary variable";
      Real rhofun "auxiliary variable";
      Real Tc=T - 273.15 "Celsius temperature for region check";
    algorithm
      delta:=max(d, triple.dvtriple)/rhostar;
      deltam1:=delta - 1.0;
      tau:=tstar/T;
      taum1:=tau - 1.0;
      Psi0:=1/(n0 + (n1 + (n2 + n3*tau)*tau)*tau)/tau^0.5;
      Psi1:=0.0;
      tfun:=1.0;
      for i in 1:6 loop
        if i <> 1 then
          tfun:=tfun*taum1;
        end if;
        rhofun:=1.0;
        for j in 0:6 loop
          if j <> 0 then
            rhofun:=rhofun*deltam1;
          end if;
          Psi1:=Psi1 + nn[i + j*6]*tfun*rhofun;
        end for;
      end for;
      eta:=etastar*Psi0*Modelica.Math.exp(delta*Psi1);
      annotation(smoothOrder=5);
    end visc_dT;

    function cond_dTp "Thermal conductivity lam(d,T,p) (industrial use version) only in one-phase region"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "temperature (K)";
      input Modelica.SIunits.Pressure p "pressure";
      input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
      input Boolean industrialMethod=true "if true, the industrial method is used, otherwise the scientific one";
      output Modelica.SIunits.ThermalConductivity lambda "thermal conductivity";
    protected
      Integer region(min=1, max=5) "IF97 region, valid values:1,2,3, and 5";
      constant Real n0=1.0 "conductivity coefficient";
      constant Real n1=6.978267 "conductivity coefficient";
      constant Real n2=2.599096 "conductivity coefficient";
      constant Real n3=-0.998254 "conductivity coefficient";
      constant Real[30] nn=array(1.3293046, 1.7018363, 5.2246158, 8.7127675, -1.8525999, -0.40452437, -2.2156845, -10.124111, -9.5000611, 0.9340469, 0.2440949, 1.6511057, 4.9874687, 4.3786606, 0.0, 0.018660751, -0.76736002, -0.27297694, -0.91783782, 0.0, -0.12961068, 0.37283344, -0.43083393, 0.0, 0.0, 0.044809953, -0.1120316, 0.13333849, 0.0, 0.0) "conductivity coefficient";
      constant Modelica.SIunits.ThermalConductivity lamstar=0.4945 "scaling conductivity";
      constant Modelica.SIunits.Density rhostar=317.763 "scaling density";
      constant Modelica.SIunits.Temperature tstar=647.226 "scaling temperature";
      constant Modelica.SIunits.Pressure pstar=22115000.0 "scaling pressure";
      constant Modelica.SIunits.DynamicViscosity etastar=5.5071e-05 "scaling viscosity";
      Integer i "auxiliary variable";
      Integer j "auxiliary variable";
      Real delta "dimensionless density";
      Real tau "dimensionless temperature";
      Real deltam1 "dimensionless density";
      Real taum1 "dimensionless temperature";
      Real Lam0 "part of thermal conductivity";
      Real Lam1 "part of thermal conductivity";
      Real Lam2 "part of thermal conductivity";
      Real tfun "auxiliary variable";
      Real rhofun "auxiliary variable";
      Real dpitau "auxiliary variable";
      Real ddelpi "auxiliary variable";
      Real d2 "auxiliary variable";
      Modelica.Media.Common.GibbsDerivs g "dimensionless Gibbs funcion and dervatives wrt pi and tau";
      Modelica.Media.Common.HelmholtzDerivs f "dimensionless Helmholtz function and dervatives wrt delta and tau";
      Real Tc=T - 273.15 "Celsius temperature for region check";
      Real Chi "symmetrized compressibility";
      constant Modelica.SIunits.Density rhostar2=317.7 "Reference density";
      constant Modelica.SIunits.Temperature Tstar2=647.25 "Reference temperature";
      constant Modelica.SIunits.ThermalConductivity lambdastar=1 "Reference thermal conductivity";
      parameter Real TREL=T/Tstar2 "Relative temperature";
      parameter Real rhoREL=d/rhostar2 "Relative density";
      Real lambdaREL "Relative thermal conductivity";
      Real deltaTREL "Relative temperature increment";
      constant Real[:] C={0.642857,-4.11717,-6.17937,0.00308976,0.0822994,10.0932};
      constant Real[:] dpar={0.0701309,0.011852,0.00169937,-1.02};
      constant Real[:] b={-0.39707,0.400302,1.06};
      constant Real[:] B={-0.171587,2.39219};
      constant Real[:] a={0.0102811,0.0299621,0.0156146,-0.00422464};
      Real Q;
      Real S;
      Real lambdaREL2 "function, part of the interpolating equation of the thermal conductivity";
      Real lambdaREL1 "function, part of the interpolating equation of the thermal conductivity";
      Real lambdaREL0 "function, part of the interpolating equation of the thermal conductivity";
    algorithm
      assert(d > triple.dvtriple, "IF97 medium function cond_dTp called with too low density\n" + "d = " + String(d) + " <= " + String(triple.dvtriple) + " (triple point density)");
      assert(p <= 100000000.0 and (Tc >= 0.0 and Tc <= 500) or p <= 70000000.0 and (Tc > 500.0 and Tc <= 650) or p <= 40000000.0 and (Tc > 650.0 and Tc <= 800), "IF97 medium function cond_dTp: thermal conductivity computed outside the range\n" + "of validity of the IF97 formulation: p = " + String(p) + " Pa, Tc = " + String(Tc) + " K");
      if industrialMethod == true then
        deltaTREL:=abs(TREL - 1) + C[4];
        Q:=2 + C[5]/deltaTREL^(3/5);
        if TREL >= 1 then
          S:=1/deltaTREL;
        else
          S:=C[6]/deltaTREL^(3/5);
        end if;
        lambdaREL2:=(dpar[1]/TREL^10 + dpar[2])*rhoREL^(9/5)*Modelica.Math.exp(C[1]*(1 - rhoREL^(14/5))) + dpar[3]*S*rhoREL^Q*Modelica.Math.exp(Q/(1 + Q)*(1 - rhoREL^(1 + Q))) + dpar[4]*Modelica.Math.exp(C[2]*TREL^(3/2) + C[3]/rhoREL^5);
        lambdaREL1:=b[1] + b[2]*rhoREL + b[3]*Modelica.Math.exp(B[1]*(rhoREL + B[2])^2);
        lambdaREL0:=TREL^(1/2)*sum(a[i]*TREL^(i - 1) for i in 1:4);
        lambdaREL:=lambdaREL0 + lambdaREL1 + lambdaREL2;
        lambda:=lambdaREL*lambdastar;
      else
        if p < data.PLIMIT4A then
          if d > data.DCRIT then
            region:=1;
          else
            region:=2;
          end if;
        else
          assert(false, "the scientific method works only for temperatures up to 623.15 K");
        end if;
        tau:=tstar/T;
        delta:=d/rhostar;
        deltam1:=delta - 1.0;
        taum1:=tau - 1.0;
        Lam0:=1/(n0 + (n1 + (n2 + n3*tau)*tau)*tau)/tau^0.5;
        Lam1:=0.0;
        tfun:=1.0;
        for i in 1:5 loop
          if i <> 1 then
            tfun:=tfun*taum1;
          end if;
          rhofun:=1.0;
          for j in 0:5 loop
            if j <> 0 then
              rhofun:=rhofun*deltam1;
            end if;
            Lam1:=Lam1 + nn[i + j*5]*tfun*rhofun;
          end for;
        end for;
        if region == 1 then
          g:=Basic.g1(p, T);
          dpitau:=-tstar/pstar*(data.PSTAR1*(g.gpi - data.TSTAR1/T*g.gtaupi)/g.gpipi/T);
          ddelpi:=-pstar/rhostar*data.RH2O/data.PSTAR1/data.PSTAR1*T*d*d*g.gpipi;
          Chi:=delta*ddelpi;
        elseif region == 2 then
          g:=Basic.g2(p, T);
          dpitau:=-tstar/pstar*(data.PSTAR2*(g.gpi - data.TSTAR2/T*g.gtaupi)/g.gpipi/T);
          ddelpi:=-pstar/rhostar*data.RH2O/data.PSTAR2/data.PSTAR2*T*d*d*g.gpipi;
          Chi:=delta*ddelpi;
        else
          assert(false, "thermal conductivity can only be called in the one-phase regions below 623.15 K\n" + "(p = " + String(p) + " Pa, T = " + String(T) + " K, region = " + String(region) + ")");
        end if;
        taum1:=1/tau - 1;
        d2:=deltam1*deltam1;
        Lam2:=0.0013848*etastar/visc_dT(d, T)/(tau*tau*delta*delta)*dpitau*dpitau*max(Chi, Modelica.Constants.small)^0.4678*delta^0.5*Modelica.Math.exp(-18.66*taum1*taum1 - d2*d2);
        lambda:=lamstar*(Lam0*Modelica.Math.exp(delta*Lam1) + Lam2);
      end if;
      annotation(smoothOrder=5);
    end cond_dTp;

    function surfaceTension "surface tension in region 4 between steam and water"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Temperature T "temperature (K)";
      output Modelica.SIunits.SurfaceTension sigma "surface tension in SI units";
    protected
      Real Theta "dimensionless temperature";
    algorithm
      Theta:=min(1.0, T/data.TCRIT);
      sigma:=0.2358*(1 - Theta)^1.256*(1 - 0.625*(1 - Theta));
      annotation(smoothOrder=5);
    end surfaceTension;

    function cond_industrial_dT "Thermal conductivity lam(d,T) (industrial use version) only in one-phase region"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "temperature (K)";
      output Modelica.SIunits.ThermalConductivity lambda "thermal conductivity";
    protected
      constant Modelica.SIunits.Density rhostar2=317.7 "Reference density";
      constant Modelica.SIunits.Temperature Tstar2=647.25 "Reference temperature";
      constant Modelica.SIunits.ThermalConductivity lambdastar=1 "Reference thermal conductivity";
      constant Real[:] C={0.642857,-4.11717,-6.17937,0.00308976,0.0822994,10.0932};
      constant Real[:] dpar={0.0701309,0.011852,0.00169937,-1.02};
      constant Real[:] b={-0.39707,0.400302,1.06};
      constant Real[:] B={-0.171587,2.39219};
      constant Real[:] a={0.0102811,0.0299621,0.0156146,-0.00422464};
      Integer region(min=1, max=5) "IF97 region, valid values:1,2,3, and 5";
      Real TREL "Relative temperature";
      Real rhoREL "Relative density";
      Real lambdaREL "Relative thermal conductivity";
      Real deltaTREL "Relative temperature increment";
      Real Q;
      Real S;
      Real lambdaREL2 "function, part of the interpolating equation of the thermal conductivity";
      Real lambdaREL1 "function, part of the interpolating equation of the thermal conductivity";
      Real lambdaREL0 "function, part of the interpolating equation of the thermal conductivity";
    algorithm
      assert(d > triple.dvtriple, "IF97 medium function cond_dTp called with too low density\n" + "d = " + String(d) + " <= " + String(triple.dvtriple) + " (triple point density)");
      TREL:=T/Tstar2;
      rhoREL:=d/rhostar2;
      deltaTREL:=abs(TREL - 1) + C[4];
      Q:=2 + C[5]/deltaTREL^(3/5);
      S:=if TREL >= 1 then 1/deltaTREL else C[6]/deltaTREL^(3/5);
      lambdaREL2:=(dpar[1]/TREL^10 + dpar[2])*rhoREL^(9/5)*Modelica.Math.exp(C[1]*(1 - rhoREL^(14/5))) + dpar[3]*S*rhoREL^Q*Modelica.Math.exp(Q/(1 + Q)*(1 - rhoREL^(1 + Q))) + dpar[4]*Modelica.Math.exp(C[2]*TREL^(3/2) + C[3]/rhoREL^5);
      lambdaREL1:=b[1] + b[2]*rhoREL + b[3]*Modelica.Math.exp(B[1]*(rhoREL + B[2])^2);
      lambdaREL0:=TREL^(1/2)*sum(a[i]*TREL^(i - 1) for i in 1:4);
      lambdaREL:=lambdaREL0 + lambdaREL1 + lambdaREL2;
      lambda:=lambdaREL*lambdastar;
      annotation(smoothOrder=5);
    end cond_industrial_dT;

    annotation(Documentation(info="<HTML><h4>Package description</h4>
          <p></p>
          <h4>Package contents</h4>
          <p>
          <ul>
          <li>Function <b>visc_dTp</b> implements a function to compute the industrial formulation of the
          dynamic viscosity of water as a function of density and temperature.
          The details are described in the document <a href=\"IF97documentation/visc.pdf\">visc.pdf</a>.</li>
          <li>Function <b>cond_dTp</b> implements a function to compute  the industrial formulation of the thermal conductivity of water as
          a function of density, temperature and pressure. <b>Important note</b>: Obviously only two of the three
          inputs are really needed, but using three inputs speeds up the computation and the three variables are known in most models anyways.
          The inputs d,T and p have to be consistent.
          The details are described in the document <a href=\"IF97documentation/surf.pdf\">surf.pdf</a>.</li>
          <li>Function <b>surfaceTension</b> implements a function to compute the surface tension between vapour
          and liquid water as a function of temperature.
          The details are described in the document <a href=\"IF97documentation/thcond.pdf\">thcond.pdf</a>.</li>
          </ul>
          </p>
          <h4>Version Info and Revision history
          </h4>
          <ul>
          <li>First implemented: <i>October, 2002</i>
          by <a href=\"http://www.control.lth.se/~hubertus/\">Hubertus Tummescheit</a>
          </li>
          </ul>
          <address>Authors: Hubertus Tummescheit and Jonas Eborn<br>
      Modelon AB<br>
      Ideon Science Park<br>
      SE-22370 Lund, Sweden<br>
      email: hubertus@modelon.se
          </address>
          <ul>
          <li>Initial version: October 2002</li>
          </ul>
          </HTML>
          "));
  end Transport;

  package Isentropic "functions for calculating the isentropic enthalpy from pressure p and specific entropy s"
    extends Modelica.Icons.Library;
    function hofpT1 "intermediate function for isentropic specific enthalpy in region 1"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature (K)";
      output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
    protected
      Real[13] o "vector of auxiliary variables";
      Real pi1 "dimensionless pressure";
      Real tau "dimensionless temperature";
      Real tau1 "dimensionless temperature";
    algorithm
      tau:=data.TSTAR1/T;
      pi1:=7.1 - p/data.PSTAR1;
      assert(p > triple.ptriple, "IF97 medium function hofpT1  called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
      tau1:=-1.222 + tau;
      o[1]:=tau1*tau1;
      o[2]:=o[1]*tau1;
      o[3]:=o[1]*o[1];
      o[4]:=o[3]*o[3];
      o[5]:=o[1]*o[4];
      o[6]:=o[1]*o[3];
      o[7]:=o[3]*tau1;
      o[8]:=o[3]*o[4];
      o[9]:=pi1*pi1;
      o[10]:=o[9]*o[9];
      o[11]:=o[10]*o[10];
      o[12]:=o[4]*o[4];
      o[13]:=o[12]*o[12];
      h:=data.RH2O*T*tau*(pi1*((-0.00254871721114236 + o[1]*(0.00424944110961118 + (0.018990068218419 + (-0.021841717175414 - 0.00015851507390979*o[1])*o[1])*o[6]))/o[5] + pi1*((0.00141552963219801 + o[3]*(4.7661393906987e-05 + o[1]*(-1.32425535992538e-05 - 1.2358149370591e-14*o[1]*o[3]*o[4])))/o[3] + pi1*((0.000126718579380216 - 5.11230768720618e-09*o[5])/o[7] + pi1*((1.1212640954e-05 + o[2]*(1.30342445791202e-06 - 1.4341729937924e-12*o[8]))/o[6] + pi1*(o[9]*pi1*((1.40077319158051e-08 + 1.04549227383804e-09*o[7])/o[8] + o[10]*o[11]*pi1*(1.9941018075704e-17/(o[1]*o[12]*o[3]*o[4]) + o[9]*(-4.48827542684151e-19/o[13] + o[10]*o[9]*(pi1*(4.65957282962769e-22/(o[13]*o[4]) + pi1*(3.83502057899078e-24*pi1/(o[1]*o[13]*o[4]) - 7.2912378325616e-23/(o[13]*o[4]*tau1))) - 1.00075970318621e-21/(o[1]*o[13]*o[3]*tau1))))) + 3.24135974880936e-06/(o[4]*tau1)))))) + (-0.29265942426334 + tau1*(0.84548187169114 + o[1]*(3.3855169168385 + tau1*(-1.91583926775744 + tau1*(0.47316115539684 + (-0.066465668798004 + 0.0040607314991784*tau1)*tau1)))))/o[2]);
    end hofpT1;

    function handsofpT1 "special function for specific enthalpy and specific entropy in region 1"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature (K)";
      output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      output Modelica.SIunits.SpecificEntropy s "specific entropy";
    protected
      Real[28] o "vector of auxiliary variables";
      Real pi1 "dimensionless pressure";
      Real tau "dimensionless temperature";
      Real tau1 "dimensionless temperature";
      Real g "dimensionless Gibbs energy";
      Real gtau "derivative of  dimensionless Gibbs energy w.r.t. tau";
    algorithm
      assert(p > triple.ptriple, "IF97 medium function handsofpT1 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
      tau:=data.TSTAR1/T;
      pi1:=7.1 - p/data.PSTAR1;
      tau1:=-1.222 + tau;
      o[1]:=tau1*tau1;
      o[2]:=o[1]*o[1];
      o[3]:=o[2]*o[2];
      o[4]:=o[3]*tau1;
      o[5]:=1/o[4];
      o[6]:=o[1]*o[2];
      o[7]:=o[1]*tau1;
      o[8]:=1/o[7];
      o[9]:=o[1]*o[2]*o[3];
      o[10]:=1/o[2];
      o[11]:=o[2]*tau1;
      o[12]:=1/o[11];
      o[13]:=o[2]*o[3];
      o[14]:=pi1*pi1;
      o[15]:=o[14]*pi1;
      o[16]:=o[14]*o[14];
      o[17]:=o[16]*o[16];
      o[18]:=o[16]*o[17]*pi1;
      o[19]:=o[14]*o[16];
      o[20]:=o[3]*o[3];
      o[21]:=o[20]*o[20];
      o[22]:=o[21]*o[3]*tau1;
      o[23]:=1/o[22];
      o[24]:=o[21]*o[3];
      o[25]:=1/o[24];
      o[26]:=o[1]*o[2]*o[21]*tau1;
      o[27]:=1/o[26];
      o[28]:=o[1]*o[3];
      g:=pi1*(pi1*(pi1*(o[10]*(-3.1679644845054e-05 + o[2]*(-2.8270797985312e-06 - 8.5205128120103e-10*o[6])) + pi1*(o[12]*(-2.2425281908e-06 + (-6.5171222895601e-07 - 1.4341729937924e-13*o[13])*o[7]) + pi1*(-4.0516996860117e-07/o[3] + o[15]*(o[18]*(o[14]*(o[19]*(2.6335781662795e-23/(o[1]*o[2]*o[21]) + pi1*(-1.1947622640071e-23*o[27] + pi1*(1.8228094581404e-24*o[25] - 9.3537087292458e-26*o[23]*pi1))) + 1.4478307828521e-20/(o[1]*o[2]*o[20]*o[3]*tau1)) - 6.8762131295531e-19/(o[2]*o[20]*o[3]*tau1)) + (-1.2734301741641e-09 - 1.7424871230634e-10*o[11])/(o[1]*o[3]*tau1))))) + o[8]*(-0.00047184321073267 + o[7]*(-0.00030001780793026 + (4.7661393906987e-05 + o[1]*(-4.4141845330846e-06 - 7.2694996297594e-16*o[9]))*tau1))) + o[5]*(0.00028319080123804 + o[1]*(-0.00060706301565874 + o[6]*(-0.018990068218419 + tau1*(-0.032529748770505 + (-0.021841717175414 - 5.283835796993e-05*o[1])*tau1))))) + (0.14632971213167 + tau1*(-0.84548187169114 + tau1*(-3.756360367204 + tau1*(3.3855169168385 + tau1*(-0.95791963387872 + tau1*(0.15772038513228 + (-0.016616417199501 + 0.00081214629983568*tau1)*tau1))))))/o[1];
      gtau:=pi1*((-0.00254871721114236 + o[1]*(0.00424944110961118 + (0.018990068218419 + (-0.021841717175414 - 0.00015851507390979*o[1])*o[1])*o[6]))/o[28] + pi1*(o[10]*(0.00141552963219801 + o[2]*(4.7661393906987e-05 + o[1]*(-1.32425535992538e-05 - 1.2358149370591e-14*o[9]))) + pi1*(o[12]*(0.000126718579380216 - 5.11230768720618e-09*o[28]) + pi1*((1.1212640954e-05 + (1.30342445791202e-06 - 1.4341729937924e-12*o[13])*o[7])/o[6] + pi1*(3.24135974880936e-06*o[5] + o[15]*((1.40077319158051e-08 + 1.04549227383804e-09*o[11])/o[13] + o[18]*(1.9941018075704e-17/(o[1]*o[2]*o[20]*o[3]) + o[14]*(-4.48827542684151e-19/o[21] + o[19]*(-1.00075970318621e-21*o[27] + pi1*(4.65957282962769e-22*o[25] + pi1*(-7.2912378325616e-23*o[23] + 3.83502057899078e-24*pi1/(o[1]*o[21]*o[3])))))))))))) + o[8]*(-0.29265942426334 + tau1*(0.84548187169114 + o[1]*(3.3855169168385 + tau1*(-1.91583926775744 + tau1*(0.47316115539684 + (-0.066465668798004 + 0.0040607314991784*tau1)*tau1)))));
      h:=data.RH2O*T*tau*gtau;
      s:=data.RH2O*(tau*gtau - g);
    end handsofpT1;

    function hofps1 "function for isentropic specific enthalpy in region 1"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEntropy s "specific entropy";
      output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
    protected
      Modelica.SIunits.Temperature T "temperature (K)";
    algorithm
      T:=Basic.tps1(p, s);
      h:=hofpT1(p, T);
    end hofps1;

    function hofpT2 "intermediate function for isentropic specific enthalpy in region 2"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature (K)";
      output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
    protected
      Real[16] o "vector of auxiliary variables";
      Real pi "dimensionless pressure";
      Real tau "dimensionless temperature";
      Real tau2 "dimensionless temperature";
    algorithm
      assert(p > triple.ptriple, "IF97 medium function hofpT2 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
      pi:=p/data.PSTAR2;
      tau:=data.TSTAR2/T;
      tau2:=-0.5 + tau;
      o[1]:=tau*tau;
      o[2]:=o[1]*o[1];
      o[3]:=tau2*tau2;
      o[4]:=o[3]*tau2;
      o[5]:=o[3]*o[3];
      o[6]:=o[5]*o[5];
      o[7]:=o[6]*o[6];
      o[8]:=o[5]*o[6]*o[7]*tau2;
      o[9]:=o[3]*o[5];
      o[10]:=o[5]*o[6]*tau2;
      o[11]:=o[3]*o[7]*tau2;
      o[12]:=o[3]*o[5]*o[6];
      o[13]:=o[5]*o[6]*o[7];
      o[14]:=pi*pi;
      o[15]:=o[14]*o[14];
      o[16]:=o[7]*o[7];
      h:=data.RH2O*T*tau*((0.0280439559151 + tau*(-0.2858109552582 + tau*(1.2213149471784 + tau*(-2.848163942888 + tau*(4.38395111945 + o[1]*(10.08665568018 + (-0.5681726521544 + 0.06380539059921*tau)*tau))))))/(o[1]*o[2]) + pi*(-0.017834862292358 + tau2*(-0.09199202739273 + (-0.172743777250296 - 0.30195167236758*o[4])*tau2) + pi*(-3.3032641670203e-05 + (-0.0003789797503263 + o[3]*(-0.015757110897342 + o[4]*(-0.306581069554011 - 0.000960283724907132*o[8])))*tau2 + pi*(4.3870667284435e-07 + o[3]*(-9.683303171571e-05 + o[4]*(-0.0090203547252888 - 1.42338887469272*o[8])) + pi*(-7.8847309559367e-10 + (2.558143570457e-08 + 1.44676118155521e-06*tau2)*tau2 + pi*(1.60454534363627e-05*o[9] + pi*((-5.0144299353183e-11 + o[10]*(-0.033874355714168 - 836.35096769364*o[11]))*o[3] + pi*((-1.38839897890111e-05 - 0.973671060893475*o[12])*o[3]*o[6] + pi*((9.0049690883672e-11 - 296.320827232793*o[13])*o[3]*o[5]*tau2 + pi*(2.57526266427144e-07*o[5]*o[6] + pi*(o[4]*(4.1627860840696e-19 + (-1.0234747095929e-12 - 1.40254511313154e-08*o[5])*o[9]) + o[14]*o[15]*(o[13]*(-2.34560435076256e-09 + 5.3465159397045*o[5]*o[7]*tau2) + o[14]*(-19.1874828272775*o[16]*o[6]*o[7] + o[14]*(o[11]*(1.78371690710842e-23 + (1.07202609066812e-11 - 0.000201611844951398*o[10])*o[3]*o[5]*o[6]*tau2) + pi*(-1.24017662339842e-24*o[5]*o[7] + pi*(0.000200482822351322*o[16]*o[5]*o[7] + pi*(-4.97975748452559e-14*o[16]*o[3]*o[5] + o[6]*o[7]*(1.90027787547159e-27 + o[12]*(2.21658861403112e-15 - 5.47344301999018e-05*o[3]*o[7]))*pi*tau2)))))))))))))))));
    end hofpT2;

    function handsofpT2 "function for isentropic specific enthalpy and specific entropy in region 2"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature (K)";
      output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      output Modelica.SIunits.SpecificEntropy s "specific entropy";
    protected
      Real[22] o "vector of auxiliary variables";
      Real pi "dimensionless pressure";
      Real tau "dimensionless temperature";
      Real tau2 "dimensionless temperature";
      Real g "dimensionless Gibbs energy";
      Real gtau "derivative of  dimensionless Gibbs energy w.r.t. tau";
    algorithm
      assert(p > triple.ptriple, "IF97 medium function handsofpT2 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
      tau:=data.TSTAR2/T;
      pi:=p/data.PSTAR2;
      tau2:=tau - 0.5;
      o[1]:=tau2*tau2;
      o[2]:=o[1]*tau2;
      o[3]:=o[1]*o[1];
      o[4]:=o[3]*o[3];
      o[5]:=o[4]*o[4];
      o[6]:=o[3]*o[4]*o[5]*tau2;
      o[7]:=o[1]*o[3]*tau2;
      o[8]:=o[3]*o[4]*tau2;
      o[9]:=o[1]*o[5]*tau2;
      o[10]:=o[1]*o[3]*o[4];
      o[11]:=o[3]*o[4]*o[5];
      o[12]:=o[1]*o[3];
      o[13]:=pi*pi;
      o[14]:=o[13]*o[13];
      o[15]:=o[13]*o[14];
      o[16]:=o[3]*o[5]*tau2;
      o[17]:=o[5]*o[5];
      o[18]:=o[3]*o[5];
      o[19]:=o[1]*o[3]*o[4]*tau2;
      o[20]:=o[1]*o[5];
      o[21]:=tau*tau;
      o[22]:=o[21]*o[21];
      g:=pi*(-0.0017731742473213 + tau2*(-0.017834862292358 + tau2*(-0.045996013696365 + (-0.057581259083432 - 0.05032527872793*o[2])*tau2)) + pi*(tau2*(-3.3032641670203e-05 + (-0.00018948987516315 + o[1]*(-0.0039392777243355 + o[2]*(-0.043797295650573 - 2.6674547914087e-05*o[6])))*tau2) + pi*(2.0481737692309e-08 + (4.3870667284435e-07 + o[1]*(-3.227767723857e-05 + o[2]*(-0.0015033924542148 - 0.040668253562649*o[6])))*tau2 + pi*(tau2*(-7.8847309559367e-10 + (1.2790717852285e-08 + 4.8225372718507e-07*tau2)*tau2) + pi*(2.2922076337661e-06*o[7] + pi*(o[2]*(-1.6714766451061e-11 + o[8]*(-0.0021171472321355 - 23.895741934104*o[9])) + pi*(-5.905956432427e-18 + o[1]*(-1.2621808899101e-06 - 0.038946842435739*o[10])*o[4]*tau2 + pi*((1.1256211360459e-11 - 8.2311340897998*o[11])*o[4] + pi*(1.9809712802088e-08*o[8] + pi*((1.0406965210174e-19 + o[12]*(-1.0234747095929e-13 - 1.0018179379511e-09*o[3]))*o[3] + o[15]*((-8.0882908646985e-11 + 0.10693031879409*o[16])*o[6] + o[13]*(-0.33662250574171*o[17]*o[4]*o[5]*tau2 + o[13]*(o[18]*(8.9185845355421e-25 + o[19]*(3.0629316876232e-13 - 4.2002467698208e-06*o[8])) + pi*(-5.9056029685639e-26*o[16] + pi*(3.7826947613457e-06*o[17]*o[3]*o[5]*tau2 + pi*(o[1]*(7.3087610595061e-29 + o[10]*(5.5414715350778e-17 - 9.436970724121e-07*o[20]))*o[4]*o[5]*pi - 1.2768608934681e-15*o[1]*o[17]*o[3]*tau2)))))))))))))))) + (-0.00560879118302 + tau*(0.07145273881455 + tau*(-0.4071049823928 + tau*(1.424081971444 + tau*(-4.38395111945 + tau*(-9.692768600217 + tau*(10.08665568018 + (-0.2840863260772 + 0.02126846353307*tau)*tau) + Modelica.Math.log(pi)))))))/(o[22]*tau);
      gtau:=(0.0280439559151 + tau*(-0.2858109552582 + tau*(1.2213149471784 + tau*(-2.848163942888 + tau*(4.38395111945 + o[21]*(10.08665568018 + (-0.5681726521544 + 0.06380539059921*tau)*tau))))))/(o[21]*o[22]) + pi*(-0.017834862292358 + tau2*(-0.09199202739273 + (-0.172743777250296 - 0.30195167236758*o[2])*tau2) + pi*(-3.3032641670203e-05 + (-0.0003789797503263 + o[1]*(-0.015757110897342 + o[2]*(-0.306581069554011 - 0.000960283724907132*o[6])))*tau2 + pi*(4.3870667284435e-07 + o[1]*(-9.683303171571e-05 + o[2]*(-0.0090203547252888 - 1.42338887469272*o[6])) + pi*(-7.8847309559367e-10 + (2.558143570457e-08 + 1.44676118155521e-06*tau2)*tau2 + pi*(1.60454534363627e-05*o[12] + pi*(o[1]*(-5.0144299353183e-11 + o[8]*(-0.033874355714168 - 836.35096769364*o[9])) + pi*(o[1]*(-1.38839897890111e-05 - 0.973671060893475*o[10])*o[4] + pi*((9.0049690883672e-11 - 296.320827232793*o[11])*o[7] + pi*(2.57526266427144e-07*o[3]*o[4] + pi*(o[2]*(4.1627860840696e-19 + o[12]*(-1.0234747095929e-12 - 1.40254511313154e-08*o[3])) + o[15]*(o[11]*(-2.34560435076256e-09 + 5.3465159397045*o[16]) + o[13]*(-19.1874828272775*o[17]*o[4]*o[5] + o[13]*((1.78371690710842e-23 + o[19]*(1.07202609066812e-11 - 0.000201611844951398*o[8]))*o[9] + pi*(-1.24017662339842e-24*o[18] + pi*(0.000200482822351322*o[17]*o[3]*o[5] + pi*(-4.97975748452559e-14*o[1]*o[17]*o[3] + (1.90027787547159e-27 + o[10]*(2.21658861403112e-15 - 5.47344301999018e-05*o[20]))*o[4]*o[5]*pi*tau2))))))))))))))));
      h:=data.RH2O*T*tau*gtau;
      s:=data.RH2O*(tau*gtau - g);
    end handsofpT2;

    function hofps2 "function for isentropic specific enthalpy in region 2"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEntropy s "specific entropy";
      output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
    protected
      Modelica.SIunits.Temperature T "temperature (K)";
    algorithm
      T:=Basic.tps2(p, s);
      h:=hofpT2(p, T);
    end hofps2;

    function hofdT3 "function for isentropic specific enthalpy in region 3"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "temperature (K)";
      output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
    protected
      Real delta;
      Real tau "dimensionless temperature";
      Real[13] o "vector of auxiliary variables";
      Real ftau "derivative of  dimensionless Helmholtz energy w.r.t. tau";
      Real fdelta "derivative of  dimensionless Helmholtz energy w.r.t. delta";
    algorithm
      tau:=data.TCRIT/T;
      delta:=d/data.DCRIT;
      o[1]:=tau*tau;
      o[2]:=o[1]*o[1];
      o[3]:=o[2]*o[2];
      o[4]:=o[3]*tau;
      o[5]:=o[1]*o[2]*o[3]*tau;
      o[6]:=o[2]*o[3];
      o[7]:=o[1]*o[3];
      o[8]:=o[3]*o[3];
      o[9]:=o[1]*o[2]*o[8];
      o[10]:=o[1]*o[2]*o[8]*tau;
      o[11]:=o[3]*o[8];
      o[12]:=o[3]*o[8]*tau;
      o[13]:=o[1]*o[3]*o[8];
      ftau:=20.944396974307 + tau*(-15.3735415757432 + o[2]*tau*(18.3301634515678 + o[1]*tau*(-28.08078114862 + o[1]*(14.4640436358204 - 0.194503669468755*o[1]*o[3]*tau)))) + delta*((-2.5308630955428 + o[2]*(-6.9146446840086 + (13.2781565976477 - 10.9153200808732*o[1])*o[4]))*tau + delta*(tau*(-1.70429417648412 + o[2]*(29.3833689251262 + (-21.3518320798755 + (0.867251811341388 + 3.26518619032008*o[2])*o[5])*tau)) + delta*((2.779959913892 + o[1]*(-8.075966009428 + o[6]*(-0.131436219478341 - 12.37496929108*o[7])))*tau + delta*((-0.88952870857478 + o[1]*(3.62288282878932 + 18.3358370228714*o[9]))*tau + delta*(0.10770512626332 + o[1]*(-0.98740869776862 - 13.2264761307011*o[10]) + delta*((0.188521503330184 + 4.27343239646986*o[11])*tau + delta*(-0.027006744482696*tau + delta*(-0.385692979164272*o[12] + delta*(delta*(-0.00016557679795037 - 0.00116802137560719*delta*o[12]) + (0.00115845907256168 + 0.0840031522296486*o[11])*tau)))))))));
      fdelta:=(1.0658070028513 + delta*(o[1]*(-1.2654315477714 + o[2]*(-1.1524407806681 + (0.88521043984318 - 0.64207765181607*o[1])*o[4])) + delta*(0.76986920373342 + o[1]*(-1.70429417648412 + o[2]*(9.7944563083754 + (-6.100523451393 + (0.078841073758308 + 0.25116816848616*o[2])*o[5])*tau)) + delta*(-0.8399798909613 + o[1]*(4.169939870838 + o[1]*(-6.056974507071 + o[6]*(-0.0246442911521889 - 1.42788107204769*o[7]))) + delta*(0.175936297894 + o[1]*(-1.77905741714956 + o[1]*(3.62288282878932 + 2.82089800351868*o[9])) + delta*(delta*(-0.133052405238576 + o[1]*(0.565564509990552 + 0.98617670687766*o[11]) + delta*(-0.094523605689436*o[1] + delta*(-0.118674762819776*o[13] + delta*(o[1]*(0.00521306582652756 + 0.0290780142333399*o[11]) + delta*(0.00080964802996215 - 0.000494162889679965*delta*o[13] - 0.0016557679795037*tau))))) + (0.5385256313166 + o[1]*(-1.6456811629477 - 2.5435531020579*o[10]))*tau))))))/delta;
      h:=data.RH2O*T*(tau*ftau + delta*fdelta);
    end hofdT3;

    function hofps3 "isentropic specific enthalpy in region 3 h(p,s)"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEntropy s "specific entropy";
      output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
    protected
      Modelica.SIunits.Density d "density";
      Modelica.SIunits.Temperature T "temperature (K)";
      Modelica.SIunits.Pressure delp=IterationData.DELP "iteration accuracy";
      Modelica.SIunits.SpecificEntropy dels=IterationData.DELS "iteration accuracy";
      Integer error "error if not 0";
    algorithm
      (d,T,error):=Inverses.dtofps3(p=p, s=s, delp=delp, dels=dels);
      h:=hofdT3(d, T);
    end hofps3;

    function hofpsdt3 "isentropic specific enthalpy in region 3 h(p,s) with given good guess in d and T"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEntropy s "specific entropy";
      input Modelica.SIunits.Density dguess "good guess density, e.g. from adjacent volume";
      input Modelica.SIunits.Temperature Tguess "good guess temperature, e.g. from adjacent volume";
      input Modelica.SIunits.Pressure delp=IterationData.DELP "relative error in p";
      input Modelica.SIunits.SpecificEntropy dels=IterationData.DELS "relative error in s";
      output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
    protected
      Modelica.SIunits.Density d "density";
      Modelica.SIunits.Temperature T "temperature (K)";
      Integer error "error flag";
    algorithm
      (d,T,error):=Inverses.dtofpsdt3(p=p, s=s, dguess=dguess, Tguess=Tguess, delp=delp, dels=dels);
      h:=hofdT3(d, T);
    end hofpsdt3;

    function hofps4 "isentropic specific enthalpy in region 4 h(p,s)"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEntropy s "specific entropy";
      output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
    protected
      Modelica.SIunits.Temp_K Tsat "saturation temperature";
      Modelica.SIunits.MassFraction x "dryness fraction";
      Modelica.SIunits.SpecificEntropy sl "saturated liquid specific entropy";
      Modelica.SIunits.SpecificEntropy sv "saturated vapour specific entropy";
      Modelica.SIunits.SpecificEnthalpy hl "saturated liquid specific enthalpy";
      Modelica.SIunits.SpecificEnthalpy hv "saturated vapour specific enthalpy";
    algorithm
      if p <= data.PLIMIT4A then
        Tsat:=Basic.tsat(p);
        (hl,sl):=handsofpT1(p, Tsat);
        (hv,sv):=handsofpT2(p, Tsat);
      elseif p < data.PCRIT then
        sl:=Regions.sl_p_R4b(p);
        sv:=Regions.sv_p_R4b(p);
        hl:=Regions.hl_p_R4b(p);
        hv:=Regions.hv_p_R4b(p);
      end if;
      x:=max(min(if sl <> sv then (s - sl)/(sv - sl) else 1.0, 1.0), 0.0);
      h:=hl + x*(hv - hl);
    end hofps4;

    function hofpT5 "specific enthalpy in region 5 h(p,T)"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature (K)";
      output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
    protected
      Real[4] o "vector of auxiliary variables";
      Real tau "dimensionless temperature";
      Real pi "dimensionless pressure";
    algorithm
      tau:=data.TSTAR5/T;
      pi:=p/data.PSTAR5;
      assert(p > triple.ptriple, "IF97 medium function hofpT5 called with too low pressure\n" + "p = " + String(p) + " Pa <= " + String(triple.ptriple) + " Pa (triple point pressure)");
      o[1]:=tau*tau;
      o[2]:=o[1]*o[1];
      o[3]:=pi*pi;
      o[4]:=o[2]*o[2];
      h:=data.RH2O*T*tau*(6.8540841634434 + 3.1161318213925/o[1] + 0.074415446800398/o[2] - 3.57523455236121e-05*o[3]*o[4] + 0.0021774678714571*pi - 0.013782846269973*o[1]*pi + 3.8757684869352e-07*o[1]*o[3]*pi - 0.73803069960666/(o[1]*tau) - 0.65923253077834*tau);
    end hofpT5;

    function water_hisentropic "isentropic specific enthalpy from p,s (preferably use water_hisentropic_dyn in dynamic simulation!)"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEntropy s "specific entropy";
      input Integer phase=0 "phase: 2 for two-phase, 1 for one phase, 0 if unknown";
      output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
    protected
      Modelica.Media.Common.GibbsDerivs g "derivatives of dimensionless Gibbs-function w.r.t dimensionless pi and tau";
      Modelica.Media.Common.HelmholtzDerivs f "derivatives of dimensionless Helmholtz-function w.r.t dimensionless delta and tau";
      Integer region(min=1, max=5) "IF97 region";
      Integer error "error if not 0";
      Modelica.SIunits.Temperature T "temperature";
      Modelica.SIunits.Density d "density";
    algorithm
      region:=Regions.region_ps(p=p, s=s, phase=phase);
      if region == 1 then
        h:=hofps1(p, s);
      elseif region == 2 then
        h:=hofps2(p, s);

      elseif region == 3 then
        (d,T,error):=Inverses.dtofps3(p=p, s=s, delp=IterationData.DELP, dels=IterationData.DELS);
        h:=hofdT3(d, T);

      elseif region == 4 then
        h:=hofps4(p, s);

      elseif region == 5 then
        (T,error):=Inverses.tofps5(p=p, s=s, relds=IterationData.DELS);
        h:=hofpT5(p, T);
      end if;
    end water_hisentropic;

    function water_hisentropic_dyn "isentropic specific enthalpy from p,s and good guesses of d and T"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEntropy s "specific entropy";
      input Modelica.SIunits.Density dguess "good guess density, e.g. from adjacent volume";
      input Modelica.SIunits.Temperature Tguess "good guess temperature, e.g. from adjacent volume";
      input Integer phase "1 for one phase, 2 for two phase";
      output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
    protected
      Modelica.Media.Common.GibbsDerivs g "derivatives of dimensionless Gibbs-function w.r.t dimensionless pi and tau";
      Modelica.Media.Common.HelmholtzDerivs f "derivatives of dimensionless Helmholtz-function w.r.t dimensionless delta and tau";
      Integer region(min=1, max=5) "IF97 region";
      Integer error "error if not 0";
      Modelica.SIunits.Temperature T "temperature";
      Modelica.SIunits.Density d "density";
    algorithm
      region:=Regions.region_ps(p=p, s=s, phase=phase);
      if region == 1 then
        h:=hofps1(p, s);
      elseif region == 2 then
        h:=hofps2(p, s);

      elseif region == 3 then
        h:=hofpsdt3(p=p, s=s, dguess=dguess, Tguess=Tguess, delp=IterationData.DELP, dels=IterationData.DELS);

      elseif region == 4 then
        h:=hofps4(p, s);

      elseif region == 5 then
        (T,error):=Inverses.tofpst5(p=p, s=s, Tguess=Tguess, relds=IterationData.DELS);
        h:=hofpT5(p, T);
      end if;
    end water_hisentropic_dyn;

    annotation(Documentation(info="<HTML><h4>Package description</h4>
          <p></p>
          <h4>Package contents</h4>
          <p>
          <ul>
          <li>Function <b>hofpT1</b> computes h(p,T) in region 1.</li>
          <li>Function <b>handsofpT1</b> computes (s,h)=f(p,T) in region 1, needed for two-phase properties.</li>
          <li>Function <b>hofps1</b> computes h(p,s) in region 1.</li>
          <li>Function <b>hofpT2</b> computes h(p,T) in region 2.</li>
          <li>Function <b>handsofpT2</b> computes (s,h)=f(p,T) in region 2, needed for two-phase properties.</li>
          <li>Function <b>hofps2</b> computes h(p,s) in region 2.</li>
          <li>Function <b>hofdT3</b> computes h(d,T) in region 3.</li>
          <li>Function <b>hofpsdt3</b> computes h(p,s,dguess,Tguess) in region 3, where dguess and Tguess are initial guess
          values for the density and temperature consistent with p and s.</li>
          <li>Function <b>hofps4</b> computes h(p,s) in region 4.</li>
          <li>Function <b>hofpT5</b> computes h(p,T) in region 5.</li>
          <li>Function <b>water_hisentropic</b> computes h(p,s,phase) in all regions.
          The phase input is needed due to discontinuous derivatives at the phase boundary.</li>
          <li>Function <b>water_hisentropic_dyn</b> computes h(p,s,dguess,Tguess,phase) in all regions.
          The phase input is needed due to discontinuous derivatives at the phase boundary. Tguess and dguess are initial guess
          values for the density and temperature consistent with p and s. This function should be preferred in
          dynamic simulations where good guesses are often available.</li>
          </ul>
          </p>
          <h4>Version Info and Revision history
          </h4>
          <ul>
          <li>First implemented: <i>July, 2000</i>
          by <a href=\"http://www.control.lth.se/~hubertus/\">Hubertus Tummescheit</a>
          </li>
          </ul>
          <address>Author: Hubertus Tummescheit, <br>
      Modelon AB<br>
      Ideon Science Park<br>
      SE-22370 Lund, Sweden<br>
      email: hubertus@modelon.se
          </address>
          <ul>
          <li>Initial version: July 2000</li>
          <li>Documentation added: December 2002</li>
          </ul>
          </HTML>
          "));
  end Isentropic;

  package Inverses "efficient inverses for selected pairs of variables"
    extends Modelica.Icons.Library;
    function fixdT "region limits for inverse iteration in region 3"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density din "density";
      input Modelica.SIunits.Temperature Tin "temperature";
      output Modelica.SIunits.Density dout "density";
      output Modelica.SIunits.Temperature Tout "temperature";
    protected
      Modelica.SIunits.Temperature Tmin "approximation of minimum temperature";
      Modelica.SIunits.Temperature Tmax "approximation of maximum temperature";
    algorithm
      if din > 765.0 then
        dout:=765.0;
      elseif din < 110.0 then
        dout:=110.0;
      else
        dout:=din;
      end if;
      if dout < 390.0 then
        Tmax:=554.3557377 + dout*0.809344262;
      else
        Tmax:=1116.85 - dout*0.632948717;
      end if;
      if dout < data.DCRIT then
        Tmin:=data.TCRIT*(1.0 - (dout - data.DCRIT)*(dout - data.DCRIT)/1000000.0);
      else
        Tmin:=data.TCRIT*(1.0 - (dout - data.DCRIT)*(dout - data.DCRIT)/1440000.0);
      end if;
      if Tin < Tmin then
        Tout:=Tmin;
      elseif Tin > Tmax then
        Tout:=Tmax;
      else
        Tout:=Tin;
      end if;
    end fixdT;

    function dofp13 "density at the boundary between regions 1 and 3"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      output Modelica.SIunits.Density d "density";
    protected
      Real p2 "auxiliary variable";
      Real[3] o "vector of auxiliary variables";
    algorithm
      p2:=7.1 - 6.04960677555959e-08*p;
      o[1]:=p2*p2;
      o[2]:=o[1]*o[1];
      o[3]:=o[2]*o[2];
      d:=57.4756752485113/(0.0737412153522555 + p2*(0.00145092247736023 + p2*(0.000102697173772229 + p2*(1.14683182476084e-05 + p2*(1.99080616601101e-06 + o[1]*p2*(1.13217858826367e-08 + o[2]*o[3]*p2*(1.35549330686006e-17 + o[1]*(-3.11228834832975e-19 + o[1]*o[2]*(-7.02987180039442e-22 + p2*(3.29199117056433e-22 + (-5.17859076694812e-23 + 2.73712834080283e-24*p2)*p2))))))))));
    end dofp13;

    function dofp23 "density at the boundary between regions 2 and 3"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      output Modelica.SIunits.Density d "density";
    protected
      Modelica.SIunits.Temperature T;
      Real[13] o "vector of auxiliary variables";
      Real taug "auxiliary variable";
      Real pi "dimensionless pressure";
      Real gpi23 "derivative of g w.r.t. pi on the boundary between regions 2 and 3";
    algorithm
      pi:=p/data.PSTAR2;
      T:=572.54459862746 + 31.3220101646784*(-13.91883977887 + pi)^0.5;
      o[1]:=(-13.91883977887 + pi)^0.5;
      taug:=-0.5 + 540.0/(572.54459862746 + 31.3220101646784*o[1]);
      o[2]:=taug*taug;
      o[3]:=o[2]*taug;
      o[4]:=o[2]*o[2];
      o[5]:=o[4]*o[4];
      o[6]:=o[5]*o[5];
      o[7]:=o[4]*o[5]*o[6]*taug;
      o[8]:=o[4]*o[5]*taug;
      o[9]:=o[2]*o[4]*o[5];
      o[10]:=pi*pi;
      o[11]:=o[10]*o[10];
      o[12]:=o[4]*o[6]*taug;
      o[13]:=o[6]*o[6];
      gpi23:=(1.0 + pi*(-0.0017731742473213 + taug*(-0.017834862292358 + taug*(-0.045996013696365 + (-0.057581259083432 - 0.05032527872793*o[3])*taug)) + pi*(taug*(-6.6065283340406e-05 + (-0.0003789797503263 + o[2]*(-0.007878555448671 + o[3]*(-0.087594591301146 - 5.3349095828174e-05*o[7])))*taug) + pi*(6.1445213076927e-08 + (1.31612001853305e-06 + o[2]*(-9.683303171571e-05 + o[3]*(-0.0045101773626444 - 0.122004760687947*o[7])))*taug + pi*(taug*(-3.15389238237468e-09 + (5.116287140914e-08 + 1.92901490874028e-06*taug)*taug) + pi*(1.14610381688305e-05*o[2]*o[4]*taug + pi*(o[3]*(-1.00288598706366e-10 + o[8]*(-0.012702883392813 - 143.374451604624*o[2]*o[6]*taug)) + pi*(-4.1341695026989e-17 + o[2]*o[5]*(-8.8352662293707e-06 - 0.272627897050173*o[9])*taug + pi*(o[5]*(9.0049690883672e-11 - 65.8490727183984*o[4]*o[5]*o[6]) + pi*(1.78287415218792e-07*o[8] + pi*(o[4]*(1.0406965210174e-18 + o[2]*(-1.0234747095929e-12 - 1.0018179379511e-08*o[4])*o[4]) + o[10]*o[11]*((-1.29412653835176e-09 + 1.71088510070544*o[12])*o[7] + o[10]*(-6.05920510335078*o[13]*o[5]*o[6]*taug + o[10]*(o[4]*o[6]*(1.78371690710842e-23 + o[2]*o[4]*o[5]*(6.1258633752464e-12 - 8.4004935396416e-05*o[8])*taug) + pi*(-1.24017662339842e-24*o[12] + pi*(8.32192847496054e-05*o[13]*o[4]*o[6]*taug + pi*(o[2]*o[5]*o[6]*(1.75410265428146e-27 + (1.32995316841867e-15 - 2.26487297378904e-05*o[2]*o[6])*o[9])*pi - 2.93678005497663e-14*o[13]*o[2]*o[4]*taug)))))))))))))))))/pi;
      d:=p/(data.RH2O*T*pi*gpi23);
    end dofp23;

    function dofpt3 "inverse iteration in region 3: (d) = f(p,T)"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature (K)";
      input Modelica.SIunits.Pressure delp "iteration converged if (p-pre(p) < delp)";
      output Modelica.SIunits.Density d "density";
      output Integer error=0 "error flag: iteration failed if different from 0";
    protected
      Modelica.SIunits.Density dguess "guess density";
      Integer i=0 "loop counter";
      Real dp "pressure difference";
      Modelica.SIunits.Density deld "density step";
      Modelica.Media.Common.HelmholtzDerivs f "dimensionless Helmholtz function and dervatives wrt delta and tau";
      Modelica.Media.Common.NewtonDerivatives_pT nDerivs "derivatives needed in Newton iteration";
      Boolean found=false "flag for iteration success";
      Boolean supercritical "flag, true for supercritical states";
      Boolean liquid "flag, true for liquid states";
      Modelica.SIunits.Density dmin "lower density limit";
      Modelica.SIunits.Density dmax "upper density limit";
      Modelica.SIunits.Temperature Tmax "maximum temperature";
    algorithm
      assert(p >= data.PLIMIT4A, "BaseIF97.dofpt3: function called outside of region 3! p too low\n" + "p = " + String(p) + " Pa < " + String(data.PLIMIT4A) + " Pa");
      assert(T >= data.TLIMIT1, "BaseIF97.dofpt3: function called outside of region 3! T too low\n" + "T = " + String(T) + " K < " + String(data.TLIMIT1) + " K");
      assert(p >= Regions.boundary23ofT(T), "BaseIF97.dofpt3: function called outside of region 3! T too high\n" + "p = " + String(p) + " Pa, T = " + String(T) + " K");
      supercritical:=p > data.PCRIT;
      dmax:=dofp13(p);
      dmin:=dofp23(p);
      Tmax:=Regions.boundary23ofp(p);
      if supercritical then
        dguess:=dmin + (T - data.TLIMIT1)/(data.TLIMIT1 - Tmax)*(dmax - dmin);
      else
        liquid:=T < Basic.tsat(p);
        if liquid then
          dguess:=0.5*(Regions.rhol_p_R4b(p) + dmax);
        else
          dguess:=0.5*(Regions.rhov_p_R4b(p) + dmin);
        end if;
      end if;
      while (i < IterationData.IMAX and not found) loop
        d:=dguess;
        f:=Basic.f3(d, T);
        nDerivs:=Modelica.Media.Common.Helmholtz_pT(f);
        dp:=nDerivs.p - p;
        if abs(dp/p) <= delp then
          found:=true;
        end if;
        deld:=dp/nDerivs.pd;
        d:=d - deld;
        if d > dmin and d < dmax then
          dguess:=d;
        else
          if d > dmax then
            dguess:=dmax - sqrt(Modelica.Constants.eps);
          else
            dguess:=dmin + sqrt(Modelica.Constants.eps);
          end if;
        end if;
        i:=i + 1;
      end while;
      if not found then
        error:=1;
      end if;
      assert(error <> 1, "error in inverse function dofpt3: iteration failed");
    end dofpt3;

    function dtofph3 "inverse iteration in region 3: (d,T) = f(p,h)"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input Modelica.SIunits.Pressure delp "iteration accuracy";
      input Modelica.SIunits.SpecificEnthalpy delh "iteration accuracy";
      output Modelica.SIunits.Density d "density";
      output Modelica.SIunits.Temperature T "temperature (K)";
      output Integer error "error flag: iteration failed if different from 0";
    protected
      Modelica.SIunits.Temperature Tguess "initial temperature";
      Modelica.SIunits.Density dguess "initial density";
      Integer i "iteration counter";
      Real dh "Newton-error in h-direction";
      Real dp "Newton-error in p-direction";
      Real det "determinant of directional derivatives";
      Real deld "Newton-step in d-direction";
      Real delt "Newton-step in T-direction";
      Modelica.Media.Common.HelmholtzDerivs f "dimensionless Helmholtz function and dervatives wrt delta and tau";
      Modelica.Media.Common.NewtonDerivatives_ph nDerivs "derivatives needed in Newton iteration";
      Boolean found "flag for iteration success";
      Integer subregion "1 for subregion 3a, 2 for subregion 3b";
    algorithm
      if p < data.PCRIT then
        subregion:=if h < Regions.hl_p(p) + 10.0 then 1 else if h > Regions.hv_p(p) - 10.0 then 2 else 0;
        assert(subregion <> 0, "inverse iteration of dt from ph called in 2 phase region: this can not work");
      else
        subregion:=if h < Basic.h3ab_p(p) then 1 else 2;
      end if;
      T:=if subregion == 1 then Basic.T3a_ph(p, h) else Basic.T3b_ph(p, h);
      d:=if subregion == 1 then 1/Basic.v3a_ph(p, h) else 1/Basic.v3b_ph(p, h);
      i:=0;
      error:=0;
      while (i < IterationData.IMAX and not found) loop
        f:=Basic.f3(d, T);
        nDerivs:=Modelica.Media.Common.Helmholtz_ph(f);
        dh:=nDerivs.h - h;
        dp:=nDerivs.p - p;
        if abs(dh/h) <= delh and abs(dp/p) <= delp then
          found:=true;
        end if;
        det:=nDerivs.ht*nDerivs.pd - nDerivs.pt*nDerivs.hd;
        delt:=(nDerivs.pd*dh - nDerivs.hd*dp)/det;
        deld:=(nDerivs.ht*dp - nDerivs.pt*dh)/det;
        T:=T - delt;
        d:=d - deld;
        dguess:=d;
        Tguess:=T;
        i:=i + 1;
        (d,T):=fixdT(dguess, Tguess);
      end while;
      if not found then
        error:=1;
      end if;
      assert(error <> 1, "error in inverse function dtofph3: iteration failed");
    end dtofph3;

    function dtofps3 "inverse iteration in region 3: (d,T) = f(p,s)"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEntropy s "specific entropy";
      input Modelica.SIunits.Pressure delp "iteration accuracy";
      input Modelica.SIunits.SpecificEntropy dels "iteration accuracy";
      output Modelica.SIunits.Density d "density";
      output Modelica.SIunits.Temperature T "temperature (K)";
      output Integer error "error flag: iteration failed if different from 0";
    protected
      Modelica.SIunits.Temperature Tguess "initial temperature";
      Modelica.SIunits.Density dguess "initial density";
      Integer i "iteration counter";
      Real ds "Newton-error in s-direction";
      Real dp "Newton-error in p-direction";
      Real det "determinant of directional derivatives";
      Real deld "Newton-step in d-direction";
      Real delt "Newton-step in T-direction";
      Modelica.Media.Common.HelmholtzDerivs f "dimensionless Helmholtz function and dervatives wrt delta and tau";
      Modelica.Media.Common.NewtonDerivatives_ps nDerivs "derivatives needed in Newton iteration";
      Boolean found "flag for iteration success";
      Integer subregion "1 for subregion 3a, 2 for subregion 3b";
    algorithm
      i:=0;
      error:=0;
      found:=false;
      if p < data.PCRIT then
        subregion:=if s < Regions.sl_p(p) + 10.0 then 1 else if s > Regions.sv_p(p) - 10.0 then 2 else 0;
        assert(subregion <> 0, "inverse iteration of dt from ps called in 2 phase region: this is illegal!");
      else
        subregion:=if s < data.SCRIT then 1 else 2;
      end if;
      T:=if subregion == 1 then Basic.T3a_ps(p, s) else Basic.T3b_ps(p, s);
      d:=if subregion == 1 then 1/Basic.v3a_ps(p, s) else 1/Basic.v3b_ps(p, s);
      while (i < IterationData.IMAX and not found) loop
        f:=Basic.f3(d, T);
        nDerivs:=Modelica.Media.Common.Helmholtz_ps(f);
        ds:=nDerivs.s - s;
        dp:=nDerivs.p - p;
        if abs(ds/s) <= dels and abs(dp/p) <= delp then
          found:=true;
        end if;
        det:=nDerivs.st*nDerivs.pd - nDerivs.pt*nDerivs.sd;
        delt:=(nDerivs.pd*ds - nDerivs.sd*dp)/det;
        deld:=(nDerivs.st*dp - nDerivs.pt*ds)/det;
        T:=T - delt;
        d:=d - deld;
        dguess:=d;
        Tguess:=T;
        i:=i + 1;
        (d,T):=fixdT(dguess, Tguess);
      end while;
      if not found then
        error:=1;
      end if;
      assert(error <> 1, "error in inverse function dtofps3: iteration failed");
    end dtofps3;

    function dtofpsdt3 "inverse iteration in region 3: (d,T) = f(p,s)"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEntropy s "specific entropy";
      input Modelica.SIunits.Density dguess "guess density, e.g. from adjacent volume";
      input Modelica.SIunits.Temperature Tguess "guess temperature, e.g. from adjacent volume";
      input Modelica.SIunits.Pressure delp "iteration accuracy";
      input Modelica.SIunits.SpecificEntropy dels "iteration accuracy";
      output Modelica.SIunits.Density d "density";
      output Modelica.SIunits.Temperature T "temperature (K)";
      output Integer error "error flag: iteration failed if different from 0";
    protected
      Integer i "iteration counter";
      Real ds "Newton-error in s-direction";
      Real dp "Newton-error in p-direction";
      Real det "determinant of directional derivatives";
      Real deld "Newton-step in d-direction";
      Real delt "Newton-step in T-direction";
      Modelica.Media.Common.HelmholtzDerivs f "dimensionless Helmholtz function and dervatives wrt delta and tau";
      Modelica.Media.Common.NewtonDerivatives_ps nDerivs "derivatives needed in Newton iteration";
      Boolean found "flag for iteration success";
      Modelica.SIunits.Density diter "density";
      Modelica.SIunits.Temperature Titer "temperature (K)";
    algorithm
      i:=0;
      error:=0;
      found:=false;
      (diter,Titer):=fixdT(dguess, Tguess);
      while (i < IterationData.IMAX and not found) loop
        (d,T):=fixdT(diter, Titer);
        f:=Basic.f3(d, T);
        nDerivs:=Modelica.Media.Common.Helmholtz_ps(f);
        ds:=nDerivs.s - s;
        dp:=nDerivs.p - p;
        if abs(ds/s) <= dels and abs(dp/p) <= delp then
          found:=true;
        end if;
        det:=nDerivs.st*nDerivs.pd - nDerivs.pt*nDerivs.sd;
        delt:=(nDerivs.pd*ds - nDerivs.sd*dp)/det;
        deld:=(nDerivs.st*dp - nDerivs.pt*ds)/det;
        T:=T - delt;
        d:=d - deld;
        diter:=d;
        Titer:=T;
        i:=i + 1;
      end while;
      if not found then
        error:=1;
      end if;
      assert(error <> 1, "error in inverse function dtofpsdt3: iteration failed");
    end dtofpsdt3;

    function pofdt125 "inverse iteration in region 1,2 and 5: p = g(d,T)"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "temperature (K)";
      input Modelica.SIunits.Pressure reldd "relative iteration accuracy of density";
      input Integer region "region in IAPWS/IF97 in which inverse should be calculated";
      output Modelica.SIunits.Pressure p "pressure";
      output Integer error "error flag: iteration failed if different from 0";
    protected
      Integer i "counter for while-loop";
      Modelica.Media.Common.GibbsDerivs g "dimensionless Gibbs funcion and dervatives wrt pi and tau";
      Boolean found "flag if iteration has been successful";
      Real dd "difference between density for  guessed p and the current density";
      Real delp "step in p in Newton-iteration";
      Real relerr "relative error in d";
      Modelica.SIunits.Pressure pguess1=1000000.0 "initial pressure guess in region 1";
      Modelica.SIunits.Pressure pguess2 "initial pressure guess in region 2";
      constant Modelica.SIunits.Pressure pguess5=500000.0 "initial pressure guess in region 5";
    algorithm
      i:=0;
      error:=0;
      pguess2:=42800*d;
      found:=false;
      if region == 1 then
        p:=pguess1;
      elseif region == 2 then
        p:=pguess2;
      else
        p:=pguess5;
      end if;
      while (i < IterationData.IMAX and not found) loop
        if region == 1 then
          g:=Basic.g1(p, T);
        elseif region == 2 then
          g:=Basic.g2(p, T);
        else
          g:=Basic.g5(p, T);
        end if;
        dd:=p/(data.RH2O*T*g.pi*g.gpi) - d;
        relerr:=dd/d;
        if abs(relerr) < reldd then
          found:=true;
        end if;
        delp:=dd*(-p*p/(d*d*data.RH2O*T*g.pi*g.pi*g.gpipi));
        p:=p - delp;
        i:=i + 1;
        if not found then
          if p < triple.ptriple then
            p:=2.0*triple.ptriple;
          end if;
          if p > data.PLIMIT1 then
            p:=0.95*data.PLIMIT1;
          end if;
        end if;
      end while;
      if not found then
        error:=1;
      end if;
      assert(error <> 1, "error in inverse function pofdt125: iteration failed");
    end pofdt125;

    function tofph5 "inverse iteration in region 5: (p,T) = f(p,h)"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input Modelica.SIunits.SpecificEnthalpy reldh "iteration accuracy";
      output Modelica.SIunits.Temperature T "temperature (K)";
      output Integer error "error flag: iteration failed if different from 0";
    protected
      Modelica.Media.Common.GibbsDerivs g "dimensionless Gibbs funcion and dervatives wrt pi and tau";
      Modelica.SIunits.SpecificEnthalpy proh "h for current guess in T";
      constant Modelica.SIunits.Temperature Tguess=1500 "initial temperature";
      Integer i "iteration counter";
      Real relerr "relative error in h";
      Real dh "Newton-error in h-direction";
      Real dT "Newton-step in T-direction";
      Boolean found "flag for iteration success";
    algorithm
      i:=0;
      error:=0;
      T:=Tguess;
      found:=false;
      while (i < IterationData.IMAX and not found) loop
        g:=Basic.g5(p, T);
        proh:=data.RH2O*T*g.tau*g.gtau;
        dh:=proh - h;
        relerr:=dh/h;
        if abs(relerr) < reldh then
          found:=true;
        end if;
        dT:=dh/(-data.RH2O*g.tau*g.tau*g.gtautau);
        T:=T - dT;
        i:=i + 1;
      end while;
      if not found then
        error:=1;
      end if;
      assert(error <> 1, "error in inverse function tofph5: iteration failed");
    end tofph5;

    function tofps5 "inverse iteration in region 5: (p,T) = f(p,s)"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEntropy s "specific entropy";
      input Modelica.SIunits.SpecificEnthalpy relds "iteration accuracy";
      output Modelica.SIunits.Temperature T "temperature (K)";
      output Integer error "error flag: iteration failed if different from 0";
    protected
      Modelica.Media.Common.GibbsDerivs g "dimensionless Gibbs funcion and dervatives wrt pi and tau";
      Modelica.SIunits.SpecificEntropy pros "s for current guess in T";
      parameter Modelica.SIunits.Temperature Tguess=1500 "initial temperature";
      Integer i "iteration counter";
      Real relerr "relative error in s";
      Real ds "Newton-error in s-direction";
      Real dT "Newton-step in T-direction";
      Boolean found "flag for iteration success";
    algorithm
      i:=0;
      error:=0;
      T:=Tguess;
      found:=false;
      while (i < IterationData.IMAX and not found) loop
        g:=Basic.g5(p, T);
        pros:=data.RH2O*(g.tau*g.gtau - g.g);
        ds:=pros - s;
        relerr:=ds/s;
        if abs(relerr) < relds then
          found:=true;
        end if;
        dT:=ds*T/(-data.RH2O*g.tau*g.tau*g.gtautau);
        T:=T - dT;
        i:=i + 1;
      end while;
      if not found then
        error:=1;
      end if;
      assert(error <> 1, "error in inverse function tofps5: iteration failed");
    end tofps5;

    function tofpst5 "inverse iteration in region 5: (p,T) = f(p,s)"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEntropy s "specific entropy";
      input Modelica.SIunits.Temperature Tguess "guess temperature, e.g. from adjacent volume";
      input Modelica.SIunits.SpecificEntropy relds "iteration accuracy";
      output Modelica.SIunits.Temperature T "temperature (K)";
      output Integer error "error flag: iteration failed if different from 0";
    protected
      Modelica.Media.Common.GibbsDerivs g "dimensionless Gibbs funcion and dervatives wrt pi and tau";
      Modelica.SIunits.SpecificEntropy pros "s for current guess in T";
      Integer i "iteration counter";
      Real relerr "relative error in s";
      Real ds "Newton-error in s-direction";
      Real dT "Newton-step in T-direction";
      Boolean found "flag for iteration success";
    algorithm
      i:=0;
      error:=0;
      T:=Tguess;
      found:=false;
      while (i < IterationData.IMAX and not found) loop
        g:=Basic.g5(p, T);
        pros:=data.RH2O*(g.tau*g.gtau - g.g);
        ds:=pros - s;
        relerr:=ds/s;
        if abs(relerr) < relds then
          found:=true;
        end if;
        dT:=ds*T/(-data.RH2O*g.tau*g.tau*g.gtautau);
        T:=T - dT;
        i:=i + 1;
      end while;
      if not found then
        error:=1;
      end if;
      assert(error <> 1, "error in inverse function tofpst5: iteration failed");
    end tofpst5;

    annotation(Documentation(info="<HTML><h4>Package description</h4>
          <p></p>
          <h4>Package contents</h4>
          <p>
          <ul>
          <li>Function <b>fixdT</b> constrains density and temperature to allowed region</li>
          <li>Function <b>dofp13</b> computes d as a function of p at boundary between regions 1 and 3</li>
          <li>Function <b>dofp23</b> computes d as a function of p at boundary between regions 2 and 3</li>
          <li>Function <b>dofpt3</b> iteration to compute d as a function of p and T in region 3</li>
          <li>Function <b>dtofph3</b> iteration to compute d and T as a function of p and h in region 3</li>
          <li>Function <b>dtofps3</b> iteration to compute d and T as a function of p and s in region 3</li>
          <li>Function <b>dtofpsdt3</b> iteration to compute d and T as a function of p and s in region 3,
          with initial guesses</li>
          <li>Function <b>pofdt125</b> iteration to compute p as a function of p and T in regions 1, 2 and 5</li>
          <li>Function <b>tofph5</b> iteration to compute T as a function of p and h in region 5</li>
          <li>Function <b>tofps5</b> iteration to compute T as a function of p and s in region 5</li>
          <li>Function <b>tofpst5</b> iteration to compute T as a function of p and s in region 5, with initial guess in T</li>
          <li>Function <b></b></li>
          </ul>
          </p>
          <h4>Version Info and Revision history
          </h4>
          <ul>
          <li>First implemented: <i>July, 2000</i>
          by <a href=\"http://www.control.lth.se/~hubertus/\">Hubertus Tummescheit</a>
          </li>
          </ul>
          <address>Author: Hubertus Tummescheit, <br>
      Modelon AB<br>
      Ideon Science Park<br>
      SE-22370 Lund, Sweden<br>
      email: hubertus@modelon.se
          </address>
          <ul>
          <li>Initial version: July 2000</li>
          <li>Documentation added: December 2002</li>
          </ul>
          </HTML>
          "));
  end Inverses;

  package TwoPhase "steam properties in the two-phase rgion and on the phase boundaries"
    function waterLiq_p "properties on the liquid phase boundary of region 4"
      extends Modelica.Icons.Function;
      input SI.Pressure p "pressure";
      output Modelica.Media.Common.PhaseBoundaryProperties liq "liquid thermodynamic property collection";
    protected
      SI.Temperature Tsat "saturation temperature";
      Real dpT "derivative of saturation pressure wrt temperature";
      SI.Density dl "liquid density";
      Modelica.Media.Common.GibbsDerivs g "dimensionless Gibbs funcion and dervatives wrt pi and tau";
      Modelica.Media.Common.HelmholtzDerivs f "dimensionless Helmholtz function and dervatives wrt delta and tau";
    algorithm
      Tsat:=Basic.tsat(p);
      dpT:=Basic.dptofT(Tsat);
      if p < data.PLIMIT4A then
        g:=Basic.g1(p, Tsat);
        liq:=Modelica.Media.Common.gibbsToBoundaryProps(g);
      else
        dl:=Regions.rhol_p_R4b(p);
        f:=Basic.f3(dl, Tsat);
        liq:=Modelica.Media.Common.helmholtzToBoundaryProps(f);
      end if;
    end waterLiq_p;

    function waterVap_p "properties on the vapour phase boundary of region 4"
      extends Modelica.Icons.Function;
      input SI.Pressure p "pressure";
      output Modelica.Media.Common.PhaseBoundaryProperties vap "vapour thermodynamic property collection";
    protected
      SI.Temperature Tsat "saturation temperature";
      Real dpT "derivative of saturation pressure wrt temperature";
      SI.Density dv "vapour density";
      Modelica.Media.Common.GibbsDerivs g "dimensionless Gibbs funcion and dervatives wrt pi and tau";
      Modelica.Media.Common.HelmholtzDerivs f "dimensionless Helmholtz function and dervatives wrt delta and tau";
    algorithm
      Tsat:=Basic.tsat(p);
      dpT:=Basic.dptofT(Tsat);
      if p < data.PLIMIT4A then
        g:=Basic.g2(p, Tsat);
        vap:=Modelica.Media.Common.gibbsToBoundaryProps(g);
      else
        dv:=Regions.rhov_p_R4b(p);
        f:=Basic.f3(dv, Tsat);
        vap:=Modelica.Media.Common.helmholtzToBoundaryProps(f);
      end if;
    end waterVap_p;

    function waterSat_ph "Water saturation properties in the 2-phase region (4) as f(p,h)"
      extends Modelica.Icons.Function;
      input SI.Pressure p "pressure";
      input SI.SpecificEnthalpy h "specific enthalpy";
      output Modelica.Media.Common.SaturationProperties pro "thermodynamic property collection";
    protected
      SI.Density dl "liquid density";
      SI.Density dv "vapour density";
      Modelica.Media.Common.GibbsDerivs gl "dimensionless Gibbs funcion and dervatives wrt pi and tau";
      Modelica.Media.Common.GibbsDerivs gv "dimensionless Gibbs funcion and dervatives wrt pi and tau";
      Modelica.Media.Common.HelmholtzDerivs fl "dimensionless Helmholtz function and dervatives wrt delta and tau";
      Modelica.Media.Common.HelmholtzDerivs fv "dimensionless Helmholtz function and dervatives wrt delta and tau";
    algorithm
      pro.h:=h;
      pro.p:=p;
      pro.T:=Basic.tsat(p);
      pro.dpT:=Basic.dptofT(pro.T);
      if p < data.PLIMIT4A then
        gl:=Basic.g1(p, pro.T);
        gv:=Basic.g2(p, pro.T);
        pro.liq:=Modelica.Media.Common.gibbsToBoundaryProps(gl);
        pro.vap:=Modelica.Media.Common.gibbsToBoundaryProps(gv);
      else
        dl:=Regions.rhol_p_R4b(p);
        dv:=Regions.rhov_p_R4b(p);
        fl:=Basic.f3(dl, pro.T);
        fv:=Basic.f3(dv, pro.T);
        pro.liq:=Modelica.Media.Common.helmholtzToBoundaryProps(fl);
        pro.vap:=Modelica.Media.Common.helmholtzToBoundaryProps(fv);
      end if;
      pro.x:=if h < pro.liq.h then 0.0 else if pro.vap.h <> pro.liq.h then (h - pro.liq.h)/(pro.vap.h - pro.liq.h) else 1.0;
      pro.d:=pro.liq.d*pro.vap.d/(pro.vap.d + pro.x*(pro.liq.d - pro.vap.d));
      pro.u:=pro.x*pro.vap.u + (1 - pro.x)*pro.liq.u;
      pro.s:=pro.x*pro.vap.s + (1 - pro.x)*pro.liq.s;
      pro.cp:=Modelica.Constants.inf;
      pro.cv:=Modelica.Media.Common.cv2Phase(pro.liq, pro.vap, pro.x, pro.T, p);
      pro.kappa:=1/(pro.d*p)*pro.dpT*pro.dpT*pro.T/pro.cv;
      pro.R:=data.RH2O;
    end waterSat_ph;

    function waterR4_ph "Water/Steam properties in region 4 of IAPWS/IF97 (two-phase)"
      extends Modelica.Icons.Function;
      input SI.Pressure p "pressure";
      input SI.SpecificEnthalpy h "specific enthalpy";
      output ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph pro "thermodynamic property collection";
    protected
      SI.Density dl "liquid density";
      SI.Density dv "vapour density";
      ThermoSysPro.Properties.WaterSteam.Common.PhaseBoundaryProperties liq "phase boundary property record";
      ThermoSysPro.Properties.WaterSteam.Common.PhaseBoundaryProperties vap "phase boundary property record";
      Modelica.Media.Common.GibbsDerivs gl "dimensionless Gibbs funcion and dervatives wrt pi and tau";
      Modelica.Media.Common.GibbsDerivs gv "dimensionless Gibbs funcion and dervatives wrt pi and tau";
      Modelica.Media.Common.HelmholtzDerivs fl "dimensionless Helmholtz function and dervatives wrt delta and tau";
      Modelica.Media.Common.HelmholtzDerivs fv "dimensionless Helmholtz function and dervatives wrt delta and tau";
      Modelica.SIunits.SpecificHeatCapacity cv;
      Real dpT "derivative of saturation curve";
    algorithm
      pro.T:=Basic.tsat(p);
      dpT:=Basic.dptofT(pro.T);
      dl:=Regions.rhol_p_R4b(p);
      dv:=Regions.rhov_p_R4b(p);
      if p < data.PLIMIT4A then
        gl:=Basic.g1(p, pro.T);
        gv:=Basic.g2(p, pro.T);
        liq:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToBoundaryProps(gl);
        vap:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToBoundaryProps(gv);
      else
        fl:=Basic.f3(dl, pro.T);
        fv:=Basic.f3(dv, pro.T);
        liq:=ThermoSysPro.Properties.WaterSteam.Common.helmholtzToBoundaryProps(fl);
        vap:=ThermoSysPro.Properties.WaterSteam.Common.helmholtzToBoundaryProps(fv);
      end if;
      pro.x:=if vap.h <> liq.h then (h - liq.h)/(vap.h - liq.h) else 1.0;
      pro.d:=liq.d*vap.d/(vap.d + pro.x*(liq.d - vap.d));
      pro.u:=pro.x*vap.u + (1 - pro.x)*liq.u;
      pro.s:=pro.x*vap.s + (1 - pro.x)*liq.s;
      pro.cp:=Modelica.Constants.inf;
      cv:=ThermoSysPro.Properties.WaterSteam.Common.cv2Phase(liq, vap, pro.x, pro.T, p);
      pro.ddph:=pro.d*(pro.d*cv/dpT + 1.0)/(dpT*pro.T);
      pro.ddhp:=-pro.d*pro.d/(dpT*pro.T);
    end waterR4_ph;

    function waterR4_dT "Water properties in region 4 as function of d and T"
      extends Modelica.Icons.Function;
      input SI.Density d "Density";
      input SI.Temperature T "temperature";
      output ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_dT pro "thermodynamic property collection";
    protected
      SI.Density dl "liquid density";
      SI.Density dv "vapour density";
      Modelica.Media.Common.PhaseBoundaryProperties liq "phase boundary property record";
      Modelica.Media.Common.PhaseBoundaryProperties vap "phase boundary property record";
      Modelica.Media.Common.GibbsDerivs gl "dimensionless Gibbs funcion and dervatives wrt pi and tau";
      Modelica.Media.Common.GibbsDerivs gv "dimensionless Gibbs funcion and dervatives wrt pi and tau";
      Modelica.Media.Common.HelmholtzDerivs fl "dimensionless Helmholtz function and dervatives wrt delta and tau";
      Modelica.Media.Common.HelmholtzDerivs fv "dimensionless Helmholtz function and dervatives wrt delta and tau";
      Real x "dryness fraction";
      Real dpT "derivative of saturation curve";
    algorithm
      pro.p:=Basic.psat(T);
      dpT:=Basic.dptofT(T);
      dl:=Regions.rhol_p_R4b(pro.p);
      dv:=Regions.rhov_p_R4b(pro.p);
      if pro.p < data.PLIMIT4A then
        gl:=Basic.g1(pro.p, T);
        gv:=Basic.g2(pro.p, T);
        liq:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToBoundaryProps(gl);
        vap:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToBoundaryProps(gv);
      else
        fl:=Basic.f3(dl, T);
        fv:=Basic.f3(dv, T);
        liq:=ThermoSysPro.Properties.WaterSteam.Common.helmholtzToBoundaryProps(fl);
        vap:=ThermoSysPro.Properties.WaterSteam.Common.helmholtzToBoundaryProps(fv);
      end if;
      x:=if vap.d <> liq.d then (1/d - 1/liq.d)/(1/vap.d - 1/liq.d) else 1.0;
      pro.u:=x*vap.u + (1 - x)*liq.u;
      pro.h:=x*vap.h + (1 - x)*liq.h;
      pro.cp:=Modelica.Constants.inf;
      pro.dudT:=(pro.p - T*dpT)/(d*d);
    end waterR4_dT;

    annotation(Documentation(info="<HTML><h4>Package description</h4>
          <p>Package TwoPhase provides functions to compute the steam properties
          in the two-phase region and on the phase boundaries</p>
          <h4>Package contents</h4>
          <p>
          <ul>
          <li>Function <b>WaterLiq_p</b> computes properties on the boiling boundary as a function of p</li>
          <li>Function <b>WaterVap_p</b> computes properties on the dew line boundary as a function of p</li>
          <li>Function <b>WaterSat_ph</b> computes properties on both phase boundaries and in the two
          phase region as a function of p</li>
          <li>Function <b>WaterR4_ph</b> computes dynamic simulation properties in region 4 with (p,h) as inputs</li>
          <li>Function <b>WaterR4_dT</b> computes dynamic simulation properties in region 4 with (d,T) as inputs</li>
          </ul>
          </p>
          <h4>Version Info and Revision history
          </h4>
          <ul>
          <li>First implemented: <i>July, 2000</i>
          by <a href=\"http://www.control.lth.se/~hubertus/\">Hubertus Tummescheit</a>
          </li>
          </ul>
          <address>Author: Hubertus Tummescheit, <br>
      Modelon AB<br>
      Ideon Science Park<br>
      SE-22370 Lund, Sweden<br>
      email: hubertus@modelon.se
          </address>
          <ul>
          <li>Initial version: July 2000</li>
          <li>Documented and re-organized: January 2003</li>
          </ul>
          </HTML>
"));
  end TwoPhase;

  annotation(Documentation(info="<HTML>
    <h4>Version Info and Revision history
        </h4>
        <ul>
        <li>First implemented: <i>July, 2000</i>
        by Hubertus Tummescheit
        for the ThermoFluid Library with help from Jonas Eborn and Falko Jens Wagner
        </li>
      <li>Code reorganization, enhanced documentation, additional functions:   <i>December, 2002</i>
      by <a href=\"mailto:Hubertus.Tummescheit@modelon.se\">Hubertus Tummescheit</a> and moved to Modelica
      properties library.</li>
        </ul>
      <address>Author: Hubertus Tummescheit, <br>
      Modelon AB<br>
      Ideon Science Park<br>
      SE-22370 Lund, Sweden<br>
      email: hubertus@modelon.se
      </address>
        <P>In September 1997, the International Association for the Properties
        of Water and Steam (<A HREF=\"http://www.iapws.org\">IAPWS</A>) adopted a
        new formulation for the thermodynamic properties of water and steam for
        industrial use. This new industrial standard is called \"IAPWS Industrial
        Formulation for the Thermodynamic Properties of Water and Steam\" (IAPWS-IF97).
        The formulation IAPWS-IF97 replaces the previous industrial standard IFC-67.
        <P>Based on this new formulation, a new steam table, titled \"<a
        href=\"http://www.springer.de/cgi-bin/search_book.pl?isbn=3-540-64339-7\">Properties
        of Water and Steam</a>\" by W. Wagner and A. Kruse, was published by
        the Springer-Verlag, Berlin - New-York - Tokyo in April 1998. This
        steam table, ref. <a href=\"#steamprop\">[1]</a> is bilingual (English /
        German) and contains a complete description of the equations of
        IAPWS-IF97. This reference is the authoritative source of information
        for this implementation. A mostly identical version has been published by the International
        Association for the Properties
        of Water and Steam (<A HREF=\"http://www.iapws.org\">IAPWS</A>) with permission granted to re-publish the
        information if credit is given to IAPWS. This document is distributed with this library as
        <a href=\"IF97documentation/IF97.pdf\">IF97.pdf</a>.
        In addition, the equations published by <A HREF=\"http://www.iapws..org\">IAPWS</A> for
        the transport properties dynamic viscosity (standards document: <a href=\"IF97documentation/visc.pdf\">visc.pdf</a>)
        and thermal conductivity (standards document: <a href=\"IF97documentation/thcond.pdf\">thcond.pdf</a>)
        and equations for the surface tension (standards document: <a href=\"IF97documentation/surf.pdf\">surf.pdf</a>)
        are also implemented in this library and included for reference.
        <P>
        The functions in BaseIF97.mo are low level functions which should
        only be used in those exceptions when the standard user level
        functions in Water.mo do not contain the wanted properties.
        </p>
<P>Based on IAPWS-IF97, Modelica functions are available for calculating
the most common thermophysical properties (thermodynamic and transport
properties). The implementation requires part of the common medium
property infrastructure of the Modelica.Thermal.Properties library in the file
Common.mo. There are a few extensions from the version of IF97 as
documented in <a href=\"IF97documentation/IF97.pdf\">IF97.pdf</a> in order to improve performance for
dynamic simulations. Input variables for calculating the properties are
only implemented for a limited number of variable pairs which make sense as dynamic states: (p,h), (p,T), (p,s) and (d,T).
<hr size=3 width=\"70%\">
<p><a name=\"regions\"><h4>1. Structure and Regions of IAPWS-IF97</h4></a>
<P>The IAPWS Industrial Formulation 1997 consists of
a set of equations for different regions which cover the following range
of validity:
<table border=0 cellpadding=4 align=center>
<tr>
<td valign=\"top\">273,15 K &lt; <I>T</I> &lt; 1073,15 K</td>
<td valign=\"top\"><I>p</I> &lt; 100 MPa</td>
</tr>
<tr>
<td valign=\"top\">1073,15 K &lt; <I>T</I> &lt; 2273,15 K</td>
<td valign=\"top\"><I>p</I> &lt; 10 MPa</td>
</tr>
</table><br>
Figure 1 shows the 5 regions into which the entire range of validity of
IAPWS-IF97 is divided. The boundaries of the regions can be directly taken
from Fig. 1 except for the boundary between regions 2 and 3; this boundary,
which corresponds approximately to the isentropic line <nobr><I>s</I> = 5.047 kJ kg
<FONT SIZE=-1><sup>-1</sup></FONT>
K<FONT SIZE=-1><sup>-1</sup></FONT>,</nobr> is defined
by a corresponding auxiliary equation. Both regions 1 and 2 are individually
covered by a fundamental equation for the specific Gibbs free energy <nobr><I>g</I>(<I>
p</I>,<I>T </I>)</nobr>, region 3 by a fundamental equation for the specific Helmholtz
free energy <nobr><I>f </I>(<I> <FONT FACE=\"Symbol\">r</FONT></I>,<I>T
</I>)</nobr>, and the saturation curve, corresponding to region 4, by a saturation-pressure
equation <nobr><I>p</I><FONT SIZE=-1><sub>s</sub></FONT>(<I>T</I>)</nobr>. The high-temperature
region 5 is also covered by a <nobr><I>g</I>(<I> p</I>,<I>T </I>)</nobr> equation. These
5 equations, shown in rectangular boxes in Fig. 1, form the so-called <I>basic
equations</I>.
      <p>
      <img src=\"IF97documentation/if97.png\" alt=\"Regions and equations of IAPWS-IF97\"></p>
      <p align=center>Figure 1: Regions and equations of IAPWS-IF97</p>
<P>In addition to these basic equations, so-called <I>backward
equations</I> are provided for regions 1, 2, and 4 in form of
<nobr><I>T </I>(<I> p</I>,<I>h </I>)</nobr> and <nobr><I>T </I>(<I>
p</I>,<I>s </I>)</nobr> for regions 1 and 2, and <nobr><I>T</I><FONT
SIZE=-1><sub>s</sub> </FONT>(<I> p </I>)</nobr> for region 4. These
backward equations, marked in grey in Fig. 1, were developed in such a
way that they are numerically very consistent with the corresponding
basic equation. Thus, properties as functions of&nbsp; <I>p</I>,<I>h
</I>and of&nbsp;<I> p</I>,<I>s </I>for regions 1 and 2, and of
<I>p</I> for region 4 can be calculated without any iteration. As a
result of this special concept for the development of the new
industrial standard IAPWS-IF97, the most important properties can be
calculated extremely quickly. All modelica functions are optimized
with regard to short computing times.
<P>The complete description of the individual equations of the new industrial
formulation IAPWS-IF97 is given in <a href=\"IF97documentation/IF97.pdf\">IF97.pdf</a>. Comprehensive information on
IAPWS-IF97 (requirements, concept, accuracy, consistency along region boundaries,
and the increase of computing speed in comparison with IFC-67, etc.) can
be taken from <a href=\"IF97documentation/IF97.pdf\">IF97.pdf</a> or [2].
<P><a name=\"steamprop\">[1]<I>Wagner, W., Kruse, A.</I> Properties of Water
and Steam / Zustandsgr&ouml;&szlig;en von Wasser und Wasserdampf / IAPWS-IF97.
Springer-Verlag, Berlin, 1998.
<P>[2] <I>Wagner, W., Cooper, J. R., Dittmann, A., Kijima,
J., Kretzschmar, H.-J., Kruse, A., Mare� R., Oguchi, K., Sato, H., St&ouml;cker,
I., �fner, O., Takaishi, Y., Tanishita, I., Tr&uuml;benbach, J., and Willkommen,
Th.</I> The IAPWS Industrial Formulation 1997 for the Thermodynamic Properties
of Water and Steam. ASME Journal of Engineering for Gas Turbines and Power 122 (2000), 150 - 182.
<p>
<HR size=3 width=\"90%\">
<h4>2. Calculable Properties      </h4>
<table border=\"1\" cellpadding=\"2\" cellspacing=\"0\">
       <tbody>
       <tr>
       <td valign=\"top\" bgcolor=\"#cccccc\"><br>
      </td>
      <td valign=\"top\" bgcolor=\"#cccccc\"><b>Common name</b><br>
       </td>
       <td valign=\"top\" bgcolor=\"#cccccc\"><b>Abbreviation </b><br>
       </td>
       <td valign=\"top\" bgcolor=\"#cccccc\"><b>Unit</b><br>
       </td>
       </tr>
       <tr>
       <td valign=\"top\">&nbsp;1<br>
      </td>
      <td valign=\"top\">Pressure</td>
       <td valign=\"top\">p<br>
        </td>
       <td valign=\"top\">Pa<br>
       </td>
       </tr>
       <tr>
       <td valign=\"top\">&nbsp;2<br>
      </td>
      <td valign=\"top\">Temperature</td>
       <td valign=\"top\">T<br>
       </td>
       <td valign=\"top\">K<br>
       </td>
       </tr>
       <tr>
       <td valign=\"top\">&nbsp;3<br>
      </td>
      <td valign=\"top\">Density</td>
        <td valign=\"top\">d<br>
        </td>
       <td valign=\"top\">kg/m<sup>3</sup><br>
       </td>
       </tr>
       <tr>
       <td valign=\"top\">&nbsp;4<br>
      </td>
      <td valign=\"top\">Specific volume</td>
        <td valign=\"top\">v<br>
        </td>
       <td valign=\"top\">m<sup>3</sup>/kg<br>
       </td>
       </tr>
       <tr>
       <td valign=\"top\">&nbsp;5<br>
      </td>
      <td valign=\"top\">Specific enthalpy</td>
       <td valign=\"top\">h<br>
       </td>
       <td valign=\"top\">J/kg<br>
       </td>
       </tr>
       <tr>
       <td valign=\"top\">&nbsp;6<br>
      </td>
      <td valign=\"top\">Specific entropy</td>
       <td valign=\"top\">s<br>
       </td>
       <td valign=\"top\">J/(kg K)<br>
       </td>
       </tr>
       <tr>
       <td valign=\"top\">&nbsp;7<br>
      </td>
      <td valign=\"top\">Specific internal energy<br>
       </td>
       <td valign=\"top\">u<br>
       </td>
       <td valign=\"top\">J/kg<br>
       </td>
       </tr>
       <tr>
       <td valign=\"top\">&nbsp;8<br>
      </td>
      <td valign=\"top\">Specific isobaric heat capacity</td>
       <td valign=\"top\">c<font size=\"-1\"><sub>p</sub></font><br>
       </td>
       <td valign=\"top\">J/(kg K)<br>
       </td>
       </tr>
       <tr>
       <td valign=\"top\">&nbsp;9<br>
      </td>
      <td valign=\"top\">Specific isochoric heat capacity</td>
       <td valign=\"top\">c<font size=\"-1\"><sub>v</sub></font><br>
       </td>
       <td valign=\"top\">J/(kg K)<br>
       </td>
       </tr>
       <tr>
       <td valign=\"top\">10<br>
      </td>
      <td valign=\"top\">Isentropic exponent, kappa<nobr>=       <font face=\"Symbol\">-</font>(v/p)
(dp/dv)<font size=\"-1\"><sub>s</sub> </font></nobr></td>
     <td valign=\"top\">kappa (     <font face=\"Symbol\">k</font>)<br>
     </td>
     <td valign=\"top\">1<br>
     </td>
     </tr>
     <tr>
     <td valign=\"top\">11<br>
      </td>
      <td valign=\"top\">Speed of sound<br>
     </td>
     <td valign=\"top\">a<br>
     </td>
     <td valign=\"top\">m/s<br>
     </td>
     </tr>
     <tr>
     <td valign=\"top\">12<br>
      </td>
      <td valign=\"top\">Dryness fraction<br>
     </td>
     <td valign=\"top\">x<br>
     </td>
     <td valign=\"top\">kg/kg<br>
     </td>
     </tr>
     <tr>
     <td valign=\"top\">13<br>
      </td>
      <td valign=\"top\">Specific Helmholtz free energy,     f = u - Ts</td>
     <td valign=\"top\">f<br>
     </td>
     <td valign=\"top\">J/kg<br>
     </td>
     </tr>
     <tr>
     <td valign=\"top\">14<br>
      </td>
      <td valign=\"top\">Specific Gibbs free energy,     g = h - Ts</td>
     <td valign=\"top\">g<br>
     </td>
     <td valign=\"top\">J/kg<br>
     </td>
     </tr>
     <tr>
     <td valign=\"top\">15<br>
      </td>
      <td valign=\"top\">Isenthalpic exponent, <nobr> theta     = -(v/p)(dp/dv)<font
 size=\"-1\"><sub>h</sub></font></nobr></td>
     <td valign=\"top\">theta (<font face=\"Symbol\">q</font>)<br>
     </td>
     <td valign=\"top\">1<br>
     </td>
     </tr>
     <tr>
     <td valign=\"top\">16<br>
      </td>
      <td valign=\"top\">Isobaric volume expansion coefficient,     alpha = v<font
 size=\"-1\"><sup>-1</sup></font>       (dv/dT)<font size=\"-1\"><sub>p</sub>
    </font></td>
     <td valign=\"top\">alpha  (<font face=\"Symbol\">a</font>)<br>
     </td>
       <td valign=\"top\">1/K<br>
     </td>
     </tr>
     <tr>
     <td valign=\"top\">17<br>
      </td>
      <td valign=\"top\">Isochoric pressure coefficient,     <nobr>beta = p<font
 size=\"-1\"><sup><font face=\"Symbol\">-</font>1</sup>     </font>(dp/dT)<font
 size=\"-1\"><sub>v</sub></font></nobr>     </td>
     <td valign=\"top\">beta (<font face=\"Symbol\">b</font>)<br>
     </td>
     <td valign=\"top\">1/K<br>
     </td>
     </tr>
     <tr>
     <td valign=\"top\">18<br>
      </td>
      <td valign=\"top\">Isothermal compressibility,     g<nobr>amma  = <font
 face=\"Symbol\">-</font>v        <sup><font size=\"-1\"><font face=\"Symbol\">-</font>1</font></sup>(dv/dp)<font
 size=\"-1\"><sub>T</sub></font></nobr> </td>
        <td valign=\"top\">gamma (<font face=\"Symbol\">g</font>)<br>
     </td>
     <td valign=\"top\">1/Pa<br>
     </td>
     </tr>
     <!-- <tr><td valign=\"top\">f</td><td valign=\"top\">Fugacity</td></tr> --> <tr>
     <td valign=\"top\">19<br>
      </td>
      <td valign=\"top\">Dynamic viscosity</td>
     <td valign=\"top\">eta (<font face=\"Symbol\">h</font>)<br>
     </td>
     <td valign=\"top\">Pa s<br>
     </td>
     </tr>
     <tr>
     <td valign=\"top\">20<br>
      </td>
      <td valign=\"top\">Kinematic viscosity</td>
     <td valign=\"top\">nu (<font face=\"Symbol\">n</font>)<br>
     </td>
     <td valign=\"top\">m<sup>2</sup>/s<br>
     </td>
     </tr>
     <!-- <tr><td valign=\"top\">Pr</td><td valign=\"top\">Prandtl number</td></tr> --> <tr>
     <td valign=\"top\">21<br>
      </td>
      <td valign=\"top\">Thermal conductivity</td>
     <td valign=\"top\">lambda (<font face=\"Symbol\">l</font>)<br>
     </td>
     <td valign=\"top\">W/(m K)<br>
     </td>
     </tr>
     <tr>
     <td valign=\"top\">22 <br>
      </td>
      <td valign=\"top\">Surface tension</td>
     <td valign=\"top\">sigma (<font face=\"Symbol\">s</font>)<br>
     </td>
     <td valign=\"top\">N/m<br>
     </td>
     </tr>
  </tbody>
</table>
        <p>The properties 1-11 are calculated by default with the functions for dynamic
        simulation, 2 of these variables are the dynamic states and are the inputs
        to calculate all other properties. In addition to these properties
        of general interest, the entries to the thermodynamic Jacobian matrix which render
        the mass- and energy balances explicit in the input variables to the property calculation are also calculated.
        For an explanatory example using pressure and specific enthalpy as states, see the Examples sub-package.</p>
        <p>The high-level calls to steam properties are grouped into records comprising both the properties of general interest
        and the entries to the thermodynamic Jacobian. If additional properties are
        needed the low level functions in BaseIF97 provide more choice.</p>
        <HR size=3 width=\"90%\">
        <h4>Additional functions</h4>
        <ul>
        <li>Function <b>boundaryvals_p</b> computes the temperature and the specific enthalpy and
        entropy on both phase boundaries as a function of p</li>
        <li>Function <b>boundaryderivs_p</b> is the Modelica derivative function of <b>boundaryvals_p</b></li>
        <li>Function <b>extraDerivs_ph</b> computes all entries to Bridgmans tables for all
        one-phase regions of IF97 using inputs (p,h). All 336 directional derivatives of the
        thermodynamic surface can be computed as a ratio of two entries in the return data, see package Common
        for details.</li>
        <li>Function <b>extraDerivs_pT</b> computes all entries to Bridgmans tables for all
        one-phase regions of IF97 using inputs (p,T).</li>
        </ul>
        </p>
        </HTML>"));
end BaseIF97;
