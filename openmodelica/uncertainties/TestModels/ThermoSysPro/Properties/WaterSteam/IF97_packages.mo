within ThermoSysPro.Properties.WaterSteam;
package IF97_packages
  package IF97_wAJ
    constant IF97_wAJ.Spline_Utilities.Data IF97_spline(ndim=1, ncontrol=100, degree=3, knots={2.93063160225403e-07,2.93063160225403e-07,2.93063160225403e-07,2.93063160225403e-07,0.0150553301018805,0.0225746360796844,0.0300841766610507,0.0375864719559614,0.0450833779282367,0.0525763026035424,0.0600663541987385,0.0675544420190098,0.0750413446792581,0.0825277558142009,0.0900143143696351,0.0975016244159301,0.104990267916964,0.11248081283071,0.119973818177067,0.127469837190213,0.134969419310924,0.14247311152242,0.149981459358957,0.157495007796453,0.165014302152702,0.172539889069826,0.180072317615317,0.187612140514708,0.195159915514515,0.202716206865773,0.21028158691427,0.217856637782066,0.225441953125109,0.233038139953034,0.240645820499176,0.248265634131007,0.255898239293619,0.26354431548115,0.271204565233372,0.278879716156774,0.286570522971491,0.294277769587339,0.302002271213962,0.309744876511783,0.317506469792076,0.325287973276035,0.333090349424309,0.340914603350119,0.348761785330786,0.356632993434437,0.364529376280738,0.372452135957019,0.380402531113975,0.388381880268579,0.39639156534589,0.404433035496425,0.412507811231662,0.420617488927502,0.42876374575417,0.436948345101518,0.445173142581185,0.453440092702033,0.461751256332929,0.470108809087968,0.478515050793845,0.486972416228223,0.495483487352128,0.50405100729972,0.512677896436249,0.521367270850924,0.53012246371707,0.538947050028345,0.547844875307676,0.556820088984304,0.565877183242573,0.575021038260507,0.584256974874285,0.593590815826759,0.603028956896544,0.612578449397273,0.622247095874125,0.632043561486359,0.641977504873387,0.652059734791795,0.662302403295546,0.672719253852374,0.6833259549907,0.694140568427125,0.705184226398132,0.716482126202646,0.728064988229839,0.739971159691273,0.752249564928059,0.764963678571606,0.77819659006882,0.79205900502822,0.806726369054731,0.822437269975835,0.839573763094594,0.858852425095749,1,1,1,1}, controlPoints=[6.41617166788097;6.59657375859249;6.85956502478188;7.19550228677957;7.44003141655459;7.67746343199683;7.90809030002524;8.1321863948823;8.35001072138466;8.56180824123764;8.76781112389037;8.96823977601129;9.16330374171574;9.35320248746118;9.53812609634101;9.71825588651749;9.89376496619584;10.064818734583;10.2315753364618;10.394186076569;10.552795798896;10.7075432351955;10.8585613263155;11.0059775194514;11.1499140439677;11.2904881680785;11.427812438369;11.561994903882;11.6931393262684;11.8213453773153;11.9467088249962;12.0693217090492;12.1892725069664;12.3066462911727;12.421524878079;12.5339869696189;12.644108287808;12.7519617028068;12.8576173549182;12.9611427709053;13.06260297498;13.1620605947781;13.25957596261;13.355207212251;13.4490103715159;13.5410394508422;13.6313465280923;13.7199818297721;13.8069938088494;13.892429219348;13.9763331878828;14.0587492822951;14.1397195775398;14.2192847189711;14.297483983169;14.3743553364442;14.4499354911556;14.524259959973;14.5973631082143;14.6692782043857;14.740037469051;14.8096721221595;14.8782124289575;14.9456877446163;15.0121265577065;15.0775565326579;15.1420045513451;15.2054967539465;15.2680585792283;15.3297148044048;15.3904895847271;15.4504064929423;15.5094885587568;15.5677583084284;15.6252378046292;15.6819486867911;15.7379122123276;15.7931492995096;15.8476805734722;15.9015264179811;15.9547070373259;16.0072425350593;16.0591530191528;16.11045874587;16.1611803164475;16.211338938197;16.2609567565343;16.3100572327281;16.3586655540358;16.4068088127073;16.4545163733577;16.501817689937;16.5487496364798;16.5953631575021;16.6418467771832;16.6879750106034;16.7343150270632;16.8752144692458;16.9266730020941;16.9094578790152]);
    function Water_Ph
      input ThermoSysPro.Units.AbsolutePressure p "Pressure";
      input ThermoSysPro.Units.SpecificEnthalpy h "Specific enthalpy";
      input Integer mode=0 "IF97 region. 0:automatic";
    protected
      Integer phase;
      Integer region;
      Integer error;
      ThermoSysPro.Units.AbsoluteTemperature T;
      Modelica.SIunits.Density d;
      Boolean supercritical;
    public
      output ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph pro annotation(Placement(transformation(x=-66.66665, y=38.33335, scale=0.2333335, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
    protected
      ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs g annotation(extent=[-90,-85;-43.3333,-38.3333]);
      ThermoSysPro.Properties.WaterSteam.Common.HelmholtzDerivs f annotation(extent=[-23.3333,-85;23.3333,-38.3333]);
    algorithm
      supercritical:=p > ThermoSysPro.Properties.WaterSteam.BaseIF97.data.PCRIT;
      phase:=if h < ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.hl_p(p) or h > ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.hv_p(p) or supercritical then 1 else 2;
      region:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.region_ph(p, h, phase, mode);
      if region == 1 then
        T:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tph1(p, h);
        g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g1(p, T);
        pro:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToProps_ph(g);
        pro.x:=if supercritical then -1 else 0;
      elseif region == 2 then
        T:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tph2(p, h);
        g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g2(p, T);
        pro:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToProps_ph(g);
        pro.x:=if supercritical then -1 else 1;

      elseif region == 3 then
        (d,T,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.dtofph3(p=p, h=h, delp=1e-07, delh=1e-06);
        f:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3(d, T);
        pro:=ThermoSysPro.Properties.WaterSteam.Common.helmholtzToProps_ph(f);
        if h > ThermoSysPro.Properties.WaterSteam.BaseIF97.data.HCRIT then
          pro.x:=if supercritical then -1 else 1;
        else
          pro.x:=if supercritical then -1 else 0;
        end if;

      elseif region == 4 then
        pro:=ThermoSysPro.Properties.WaterSteam.Common.water_ph_r4(p, h);

      elseif region == 5 then
        (T,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.tofph5(p=p, h=h, reldh=1e-07);
        g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g5(p, T);
        pro:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToProps_ph(g);
        pro.x:=if supercritical then -1 else 1;
      else
        assert(false, "Water_Ph: Incorrect region number (" + String(region) + ")");
      end if;
      annotation(derivative(noDerivative=mode)=Water_Ph_der, Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Text(lineColor={0,0,255}, extent={{-134,104},{142,44}}, textString="%name"),Ellipse(extent={{-100,40},{100,-100}}, fillPattern=FillPattern.Solid, lineColor={255,127,0}, fillColor={255,255,255}),Text(lineColor={0,0,255}, extent={{-84,-4},{84,-52}}, textString="fonction", fillColor={255,127,0})}), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
    end Water_Ph;

    function Water_Ps
      input ThermoSysPro.Units.AbsolutePressure p "Pressure";
      input Modelica.SIunits.SpecificEntropy s "Specific entropy";
      input Integer mode=0 "IF97 region. 0:automatic";
    protected
      Integer phase;
      Integer region;
      Integer error;
      ThermoSysPro.Units.AbsoluteTemperature T;
      Modelica.SIunits.Density d;
      Boolean supercritical;
    public
      output ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ps pro;
    protected
      ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs g annotation(extent=[-90,-85;-43.3333,-38.3333]);
      ThermoSysPro.Properties.WaterSteam.Common.HelmholtzDerivs f annotation(extent=[-23.3333,-85;23.3333,-38.3333]);
    algorithm
      supercritical:=p > ThermoSysPro.Properties.WaterSteam.BaseIF97.data.PCRIT;
      phase:=if s < ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.sl_p(p) or s > ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.sv_p(p) or supercritical then 1 else 2;
      region:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.region_ps(p, s, phase, mode);
      if region == 1 then
        T:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tps1(p, s);
        g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g1(p, T);
        pro:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToProps_ps(g);
        pro.x:=if supercritical then -1 else 0;
      elseif region == 2 then
        T:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tps2(p, s);
        g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g2(p, T);
        pro:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToProps_ps(g);
        pro.x:=if supercritical then -1 else 1;

      elseif region == 3 then
        (d,T,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.dtofps3(p=p, s=s, delp=1e-07, dels=1e-06);
        f:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3(d, T);
        pro:=ThermoSysPro.Properties.WaterSteam.Common.helmholtzToProps_ps(f);
        pro.x:=if supercritical then -1 else 0;

      elseif region == 4 then
        pro:=ThermoSysPro.Properties.WaterSteam.Common.water_ps_r4(p, s);

      elseif region == 5 then
        (T,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.tofps5(p=p, s=s, relds=1e-07);
        g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g5(p, T);
        pro:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToProps_ps(g);
        pro.x:=if supercritical then -1 else 1;
      else
        assert(false, "Water_Ps: Incorrect region number");
      end if;
      annotation(derivative(noDerivative=mode)=Water_Ps_der, Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Text(lineColor={0,0,255}, extent={{-134,104},{142,44}}, textString="%name"),Ellipse(extent={{-100,40},{100,-100}}, fillPattern=FillPattern.Solid, lineColor={255,127,0}, fillColor={255,255,255}),Text(lineColor={0,0,255}, extent={{-84,-4},{84,-52}}, textString="fonction", fillColor={255,127,0})}), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
    end Water_Ps;

    function Water_sat_P
      input ThermoSysPro.Units.AbsolutePressure P "Pressure";
    protected
      ThermoSysPro.Units.AbsoluteTemperature T;
    public
      output ThermoSysPro.Properties.WaterSteam.Common.PropThermoSat lsat annotation(Placement(transformation(x=-50.0, y=50.0, scale=0.35, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
      output ThermoSysPro.Properties.WaterSteam.Common.PropThermoSat vsat annotation(Placement(transformation(x=50.0, y=50.0, scale=0.35, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
    protected
      ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs gl annotation(extent=[-85,-85;-15,-15]);
      ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs gv annotation(extent=[15,-85;85,-15]);
    algorithm
      T:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tsat(P);
      gl:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g1(P, T);
      lsat:=ThermoSysPro.Properties.WaterSteam.Common.gibbsPropsSat(P, T, gl);
      gv:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g2(P, T);
      vsat:=ThermoSysPro.Properties.WaterSteam.Common.gibbsPropsSat(P, T, gv);
      annotation(derivative=Water_sat_P_der, Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Text(lineColor={0,0,255}, extent={{-134,104},{142,44}}, textString="%name"),Ellipse(extent={{-100,40},{100,-100}}, fillPattern=FillPattern.Solid, lineColor={255,127,0}, fillColor={255,255,255}),Text(lineColor={0,0,255}, extent={{-84,-4},{84,-52}}, textString="fonction", fillColor={255,127,0})}), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
    end Water_sat_P;

    function DynamicViscosity_rhoT
      input Modelica.SIunits.Density rho "Density";
      input ThermoSysPro.Units.AbsoluteTemperature T "Temperature";
      output Modelica.SIunits.DynamicViscosity mu "Dynamic viscosity";
    algorithm
      mu:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Transport.visc_dT(rho, T);
      annotation(smoothOrder=2, Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Text(lineColor={0,0,255}, extent={{-134,104},{142,44}}, textString="%name"),Ellipse(extent={{-100,40},{100,-100}}, fillPattern=FillPattern.Solid, lineColor={255,127,0}, fillColor={255,255,255}),Text(lineColor={0,0,255}, extent={{-84,-4},{84,-52}}, textString="fonction", fillColor={255,127,0})}), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
    end DynamicViscosity_rhoT;

    function ThermalConductivity_rhoT
      input Modelica.SIunits.Density rho "Density";
      input ThermoSysPro.Units.AbsoluteTemperature T "Temperature";
      input ThermoSysPro.Units.AbsolutePressure P "Pressure";
      input Integer region=0 "IF97 region. 0:automatic";
      output Modelica.SIunits.ThermalConductivity lambda "Thermal conductivity";
    algorithm
      lambda:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Transport.cond_industrial_dT(rho, T);
      annotation(smoothOrder=2, Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Text(lineColor={0,0,255}, extent={{-134,104},{142,44}}, textString="%name"),Ellipse(extent={{-100,40},{100,-100}}, fillPattern=FillPattern.Solid, lineColor={255,127,0}, fillColor={255,255,255}),Text(lineColor={0,0,255}, extent={{-84,-4},{84,-52}}, textString="fonction", fillColor={255,127,0})}), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
    end ThermalConductivity_rhoT;

    function SurfaceTension_T
      input ThermoSysPro.Units.AbsoluteTemperature T "Temperature";
      output Modelica.SIunits.SurfaceTension sigma "Surface tension";
    algorithm
      sigma:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Transport.surfaceTension(T);
      annotation(smoothOrder=2, Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Text(lineColor={0,0,255}, extent={{-134,104},{142,44}}, textString="%name"),Ellipse(extent={{-100,40},{100,-100}}, fillPattern=FillPattern.Solid, lineColor={255,127,0}, fillColor={255,255,255}),Text(lineColor={0,0,255}, extent={{-84,-4},{84,-52}}, textString="fonction", fillColor={255,127,0})}), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
    end SurfaceTension_T;

    function SpecificEnthalpy_PT
      input ThermoSysPro.Units.AbsolutePressure p "Pressure";
      input ThermoSysPro.Units.AbsoluteTemperature T "Temperature";
      input Integer mode=0 "IF97 region. 0:automatic";
      output ThermoSysPro.Units.SpecificEnthalpy H "Specific enthalpy";
    protected
      ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_pT pro;
    algorithm
      pro:=ThermoSysPro.Properties.WaterSteam.IF97_packages.IF97_wAJ.Water_PT(p, T, mode);
      H:=pro.h;
      annotation(derivative(noDerivative=mode)=SpecificEnthalpy_PT_der, Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Text(lineColor={0,0,255}, extent={{-134,104},{142,44}}, textString="%name"),Ellipse(extent={{-100,40},{100,-100}}, fillPattern=FillPattern.Solid, lineColor={255,127,0}, fillColor={255,255,255}),Text(lineColor={0,0,255}, extent={{-84,-4},{84,-52}}, textString="fonction", fillColor={255,127,0})}), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
    end SpecificEnthalpy_PT;

    function Pressure_sat_hl
      input ThermoSysPro.Units.SpecificEnthalpy hl "Liquid specific enthalpy on the saturation line";
      output ThermoSysPro.Units.AbsolutePressure P "Liquid pressure on the saturation line";
    protected
      ThermoSysPro.Units.AbsolutePressure tmp[1];
    algorithm
      assert(hl > ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.hl_p(ThermoSysPro.Properties.WaterSteam.BaseIF97.triple.ptriple), "Pressure_sat_hl called with too low specific enthalpy (below triple point)");
      assert(hl < ThermoSysPro.Properties.WaterSteam.BaseIF97.critical.HCRIT, "Pressure_sat_hl called with too high specific enthalpy (above critical point)");
      tmp:=ThermoSysPro.Properties.WaterSteam.IF97_packages.IF97_wAJ.Spline_Utilities.safeEvaluate(IF97_spline, hl/ThermoSysPro.Properties.WaterSteam.BaseIF97.critical.HCRIT);
      P:=Modelica.Math.exp(tmp[1]);
      annotation(derivative=Pressure_sat_hl_der, Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Text(lineColor={0,0,255}, extent={{-134,104},{142,44}}, textString="%name"),Ellipse(extent={{-100,40},{100,-100}}, fillPattern=FillPattern.Solid, lineColor={255,127,0}, fillColor={255,255,255}),Text(lineColor={0,0,255}, extent={{-84,-4},{84,-52}}, textString="fonction", fillColor={255,127,0})}), Documentation(info="<html>
<p><b>Version 1.2</b> </p>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro_AJ Version 2.0</b></p>
</HTML>
"));
    end Pressure_sat_hl;

    function Water_PT
      input ThermoSysPro.Units.AbsolutePressure p "Pressure";
      input ThermoSysPro.Units.AbsoluteTemperature T "Temperature";
      input Integer mode=0 "IF97 region. 0:automatic";
      output ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_pT pro;
    protected
      Integer region;
      Boolean supercritical;
      Integer error;
      ThermoSysPro.Properties.WaterSteam.Common.HelmholtzDerivs f;
      Modelica.SIunits.Density d;
      ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs g;
    algorithm
      supercritical:=p > ThermoSysPro.Properties.WaterSteam.BaseIF97.data.PCRIT;
      region:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.region_pT(p, T, mode);
      if region == 1 then
        g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g1(p, T);
        pro:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToProps_pT(g);
        pro.x:=if supercritical then -1 else 0;
      elseif region == 2 then
        g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g2(p, T);
        pro:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToProps_pT(g);
        pro.x:=if supercritical then -1 else 1;

      elseif region == 3 then
        (d,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.dofpt3(p=p, T=T, delp=ThermoSysPro.Properties.WaterSteam.BaseIF97.IterationData.DELP);
        f:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3(d, T);
        pro:=ThermoSysPro.Properties.WaterSteam.Common.helmholtzToProps_pT(f);
        pro.x:=if supercritical then -1 else 0;

      elseif region == 5 then
        g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g5(p, T);
        pro:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToProps_pT(g);
        pro.x:=if supercritical then -1 else 1;
      else
        assert(false, "Water_PT: Incorrect region number");
      end if;
      annotation(derivative(noDerivative=mode)=Water_PT_der, Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Text(lineColor={0,0,255}, extent={{-134,104},{142,44}}, textString="%name"),Ellipse(extent={{-100,40},{100,-100}}, fillPattern=FillPattern.Solid, lineColor={255,127,0}, fillColor={255,255,255}),Text(lineColor={0,0,255}, extent={{-84,-4},{84,-52}}, textString="fonction", fillColor={255,127,0})}), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
    end Water_PT;

    function Pressure_sat_hl_der
      input ThermoSysPro.Units.SpecificEnthalpy hl "Liquid specific enthalpy on the saturation line";
      input Real hl_der;
      output Real P_der;
    protected
      ThermoSysPro.Units.AbsolutePressure P[1] "Liquid pressure on the saturation line";
      Real tmp[1];
    algorithm
      assert(hl > ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.hl_p(ThermoSysPro.Properties.WaterSteam.BaseIF97.triple.ptriple), "Pressure_sat_hl_der called with too low specific enthalpy (below triple point)");
      assert(hl < ThermoSysPro.Properties.WaterSteam.BaseIF97.critical.HCRIT, "Pressure_sat_hl_der called with too high specific enthalpy (above critical point)");
      (P,tmp):=ThermoSysPro.Properties.WaterSteam.IF97_packages.IF97_wAJ.Spline_Utilities.safeEvaluateDer(IF97_spline, hl/ThermoSysPro.Properties.WaterSteam.BaseIF97.critical.HCRIT);
      P_der:=Modelica.Math.exp(P[1])*tmp[1]*hl_der;
      annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Text(lineColor={0,0,255}, extent={{-134,104},{142,44}}, textString="%name"),Ellipse(extent={{-100,40},{100,-100}}, fillPattern=FillPattern.Solid, lineColor={255,127,0}, fillColor={255,255,255}),Text(lineColor={0,0,255}, extent={{-84,-4},{84,-52}}, textString="fonction", fillColor={255,127,0})}), Documentation(info="<html>
<p><b>Version 1.2</b> </p>
<p>Needs to be redone. Iterative functions don&apos;t work for Analytic Jacobian</p>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro_AJ Version 2.0</b></p>
</HTML>
"));
    end Pressure_sat_hl_der;

    function Water_Ph_der "Derivative function of Water_Ph"
      input ThermoSysPro.Units.AbsolutePressure p "Pressure";
      input ThermoSysPro.Units.SpecificEnthalpy h "Specific enthalpy";
      input Integer mode=0 "Région IF97 - 0:calcul automatique";
      input Real p_der "derivative of Pressure";
      input Real h_der "derivative of Specific enthalpy";
      output ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph der_pro "Derivative";
    protected
      Integer phase;
      Integer region;
      Boolean supercritical;
      ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs3rd g "dimensionless Gibbs funcion and dervatives wrt pi and tau";
      ThermoSysPro.Properties.WaterSteam.Common.HelmholtzDerivs3rd f "dimensionless Helmholtz funcion and dervatives wrt delta and tau";
      Modelica.SIunits.Temperature T;
      Modelica.SIunits.SpecificHeatCapacity R "gas constant";
      Modelica.SIunits.Density rho "density";
      Real vt "derivative of specific volume w.r.t. temperature";
      Modelica.SIunits.SpecificHeatCapacity cp "specific heat capacity";
      Modelica.SIunits.SpecificHeatCapacity cv "specific heat capacity";
      Real vp "derivative of specific volume w.r.t. pressure";
      ThermoSysPro.Units.DerPressureByDensity pd "derivative of pressure wrt density";
      ThermoSysPro.Units.DerPressureByTemperature pt "derivative of pressure wrt temperature";
      Real dpT "dp/dT derivative of saturation curve";
      Real dxv "der of x wrt v";
      Real dvTl "der of v wrt T at boiling";
      Real dvTv "der of v wrt T at dew";
      Real dxT "der of x wrt T";
      Real duTl "der of u wrt T at boiling";
      Real duTv "der of u wrt T at dew";
      Real vtt "2nd derivative of specific volume w.r.t. temperature";
      Real cpt "derivative of cp w.r.t. temperature";
      Real cvt "derivative of cv w.r.t. temperature";
      Real dpTT "2nd der of p wrt T";
      Real dxdd "2nd der of x wrt d";
      Real dxTd "2nd der of x wrt d and T";
      Real dvTTl "2nd der of v wrt T at boiling";
      Real dvTTv "2nd der of v wrt T at dew";
      Real dxTT " 2nd der of x wrt T";
      Real duTTl "2nd der of u wrt T at boiling";
      Real duTTv "2nd der of u wrt T at dew";
      Integer error "error flag for inverse iterations";
      Modelica.SIunits.SpecificEnthalpy h_liq "liquid specific enthalpy";
      Modelica.SIunits.Density d_liq "liquid density";
      Modelica.SIunits.SpecificEnthalpy h_vap "vapour specific enthalpy";
      Modelica.SIunits.Density d_vap "vapour density";
      Real x "dryness fraction";
      ThermoSysPro.Properties.WaterSteam.Common.PhaseBoundaryProperties3rd liq "phase boundary property record";
      ThermoSysPro.Properties.WaterSteam.Common.PhaseBoundaryProperties3rd vap "phase boundary property record";
      Modelica.SIunits.Temperature t1 "temperature at phase boundary, using inverse from region 1";
      Modelica.SIunits.Temperature t2 "temperature at phase boundary, using inverse from region 2";
      ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs3rd gl "dimensionless Gibbs funcion and dervatives wrt pi and tau";
      ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs3rd gv "dimensionless Gibbs funcion and dervatives wrt pi and tau";
      ThermoSysPro.Properties.WaterSteam.Common.HelmholtzDerivs3rd fl "dimensionless Helmholtz function and dervatives wrt delta and tau";
      ThermoSysPro.Properties.WaterSteam.Common.HelmholtzDerivs3rd fv "dimensionless Helmholtz function and dervatives wrt delta and tau";
      Modelica.SIunits.SpecificVolume v;
      Real ptt "2nd derivative of pressure wrt temperature";
      Real pdd "2nd derivative of pressure wrt density";
      Real ptd "mixed derivative of pressure w.r.t. density and temperature";
      Real vpp "2nd derivative of specific volume w.r.t. pressure";
      Real vtp "mixed derivative of specific volume w.r.t. pressure and temperature";
      Real vp3 "vp^3";
      Real ivp3 "1/vp3";
      Real detPH "Determinant";
      Real dht;
      Real dhd;
      Real ddhp;
      Real ddph;
      Real dtph;
      Real dthp;
      Real detPH_d;
      Real detPH_t;
      Real dhtt;
      Real dhtd;
      Real ddph_t;
      Real ddph_d;
      Real ddhp_t;
      Real ddhp_d;
      Real duhp_t;
      Real duph_t;
      Real duph_d;
      Real dupp;
      Real duph;
      Real duhh;
      Real dcp_d;
      Real rho2 "square of density";
      Real rho3 "cube of density";
      Real cp3 "cube of specific heat capacity";
      Real cpcpp;
      Real quotient;
      Real vt2;
      Real pt2;
      Real pt3;
    algorithm
      supercritical:=p > ThermoSysPro.Properties.WaterSteam.BaseIF97.data.PCRIT;
      phase:=if h < ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.hl_p(p) or h > ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.hv_p(p) or supercritical then 1 else 2;
      region:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.region_ph(p, h, phase, mode);
      R:=ThermoSysPro.Properties.WaterSteam.BaseIF97.data.RH2O;
      if region == 1 then
        T:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tph1(p, h);
        g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g1L3(p, T);
        rho:=p/(R*T*g.pi*g.gpi);
        rho2:=rho*rho;
        vt:=R/p*(g.pi*g.gpi - g.tau*g.pi*g.gpitau);
        vt2:=vt*vt;
        cp:=-R*g.tau*g.tau*g.gtautau;
        cp3:=cp*cp*cp;
        cpcpp:=cp*cp*p;
        vp:=R*T/(p*p)*g.pi*g.pi*g.gpipi;
        v:=1/rho;
        vtt:=R*g.pi/p*g.tau/T*g.tau*g.gpitautau;
        vtp:=R*g.pi*g.pi/(p*p)*(g.gpipi - g.tau*g.gpipitau);
        vpp:=R*T*g.pi*g.pi*g.pi/(p*p*p)*g.gpipipi;
        cpt:=R*g.tau*g.tau/T*(2*g.gtautau + g.tau*g.gtautautau);
        pt:=-g.p/g.T*(g.gpi - g.tau*g.gpitau)/(g.gpipi*g.pi);
        pd:=-g.R*g.T*g.gpi*g.gpi/g.gpipi;
        vp3:=vp*vp*vp;
        ivp3:=1/vp3;
        ptt:=-(vtt*vp*vp - 2.0*vt*vtp*vp + vt2*vpp)*ivp3;
        pdd:=-vpp*ivp3/(rho2*rho2) - 2*v*pd "= pvv/d^4";
        ptd:=(vtp*vp - vt*vpp)*ivp3/rho2 "= -ptv/d^2";
        cvt:=(vp3*cpt + vp*vp*vt2 + 3.0*vp*vp*T*vt*vtt - 3.0*vtp*vp*T*vt2 + T*vt2*vt*vpp)*ivp3;
        detPH:=cp*pd;
        dht:=cv + pt/rho;
        dhd:=(pd - T*pt/rho)/rho;
        ddph:=dht/detPH;
        ddhp:=-pt/detPH;
        dtph:=-dhd/detPH;
        dthp:=pd/detPH;
        detPH_d:=cv*pdd + (2.0*pt*(ptd - pt/rho) - ptt*pd)*T/rho2;
        detPH_t:=cvt*pd + cv*ptd + (pt + 2.0*T*ptt)*pt/rho2;
        dhtt:=cvt + ptt*v;
        dhtd:=(ptd - (T*ptt + pt)*v)*v;
        ddhp_t:=ddhp*(ptt/pt - detPH_t/detPH);
        ddhp_d:=ddhp*(ptd/pt - detPH_d/detPH);
        ddph_t:=ddph*(dhtt/dht - detPH_t/detPH);
        ddph_d:=ddph*(dhtd/dht - detPH_d/detPH);
        dupp:=-(2.0*cp3*vp + cp3*p*vpp - 2.0*cp*cp*vt*v - 2.0*cpcpp*vtp*v - cpcpp*vt*vp + 2.0*cp*cp*T*vt2 + 3.0*cpcpp*vt*T*vtp - 4.0*T*vtt*cp*p*vt*v + 3.0*T*T*vtt*cp*p*vt2 + cp*p*vtt/rho2 - cpt*p*vt/rho2 + 2.0*cpt*p*vt2*v*T - cpt*p*vt2*T^2)/cp3;
        duph:=-(vtp*cpcpp + cp*cp*vt - cp*p*vtt*v + 2.0*cp*p*vt*T*vtt + cpt*p*vt*v - cpt*p*vt2*T)/cp3;
        duhh:=-p*(cp*vtt - cpt*vt)/cp3;
        der_pro.x:=0.0;
        der_pro.duhp:=duph*p_der + duhh*h_der;
        der_pro.duph:=dupp*p_der + duph*h_der;
        der_pro.ddph:=(ddph*ddph_d + dtph*ddph_t)*p_der + (ddph*ddhp_d + dtph*ddhp_t)*h_der;
        der_pro.ddhp:=(ddhp*ddhp_d + dthp*ddhp_t)*h_der + (ddph*ddhp_d + dtph*ddhp_t)*p_der;
        der_pro.cp:=(-(T*vtt*cp + cpt/rho - cpt*T*vt)/cp)*p_der + cpt/cp*h_der;
        der_pro.s:=-1/(rho*T)*p_der + 1/T*h_der;
        der_pro.u:=(-(p*vp*cp + cp*v - p*vt*v + p*vt2*T)/cp)*p_der + (cp - p*vt)/cp*h_der;
        der_pro.T:=(-v + T*vt)/cp*p_der + 1/cp*h_der;
        der_pro.d:=(-rho2*(vp*cp - vt/rho + T*vt2)/cp)*p_der + (-rho2*vt/cp)*h_der;
      elseif region == 2 then
        T:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tph2(p, h);
        g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g2L3(p, T);
        rho:=p/(R*T*g.pi*g.gpi);
        rho2:=rho*rho;
        vt:=R/p*(g.pi*g.gpi - g.tau*g.pi*g.gpitau);
        vt2:=vt*vt;
        cp:=-R*g.tau*g.tau*g.gtautau;
        cp3:=cp*cp*cp;
        cpcpp:=cp*cp*p;
        vp:=R*T/(p*p)*g.pi*g.pi*g.gpipi;
        v:=1/rho;
        vtt:=R*g.pi/p*g.tau/T*g.tau*g.gpitautau;
        vtp:=R*g.pi*g.pi/(p*p)*(g.gpipi - g.tau*g.gpipitau);
        vpp:=R*T*g.pi*g.pi*g.pi/(p*p*p)*g.gpipipi;
        cpt:=R*g.tau*g.tau/T*(2*g.gtautau + g.tau*g.gtautautau);
        pt:=-g.p/g.T*(g.gpi - g.tau*g.gpitau)/(g.gpipi*g.pi);
        pd:=-g.R*g.T*g.gpi*g.gpi/g.gpipi;
        vp3:=vp*vp*vp;
        ivp3:=1/vp3;
        ptt:=-(vtt*vp*vp - 2.0*vt*vtp*vp + vt2*vpp)*ivp3;
        pdd:=-vpp*ivp3/(rho2*rho2) - 2*v*pd "= pvv/d^4";
        ptd:=(vtp*vp - vt*vpp)*ivp3/rho2 "= -ptv/d^2";
        cvt:=(vp3*cpt + vp*vp*vt2 + 3.0*vp*vp*T*vt*vtt - 3.0*vtp*vp*T*vt2 + T*vt2*vt*vpp)*ivp3;
        detPH:=cp*pd;
        dht:=cv + pt/rho;
        dhd:=(pd - T*pt/rho)/rho;
        ddph:=dht/detPH;
        ddhp:=-pt/detPH;
        dtph:=-dhd/detPH;
        dthp:=pd/detPH;
        detPH_d:=cv*pdd + (2.0*pt*(ptd - pt/rho) - ptt*pd)*T/rho2;
        detPH_t:=cvt*pd + cv*ptd + (pt + 2.0*T*ptt)*pt/rho2;
        dhtt:=cvt + ptt*v;
        dhtd:=(ptd - (T*ptt + pt)*v)*v;
        ddhp_t:=ddhp*(ptt/pt - detPH_t/detPH);
        ddhp_d:=ddhp*(ptd/pt - detPH_d/detPH);
        ddph_t:=ddph*(dhtt/dht - detPH_t/detPH);
        ddph_d:=ddph*(dhtd/dht - detPH_d/detPH);
        dupp:=-(2.0*cp3*vp + cp3*p*vpp - 2.0*cp*cp*vt*v - 2.0*cpcpp*vtp*v - cpcpp*vt*vp + 2.0*cp*cp*T*vt2 + 3.0*cpcpp*vt*T*vtp - 4.0*T*vtt*cp*p*vt*v + 3.0*T*T*vtt*cp*p*vt2 + cp*p*vtt/rho2 - cpt*p*vt/rho2 + 2.0*cpt*p*vt2*v*T - cpt*p*vt2*T^2)/cp3;
        duph:=-(vtp*cpcpp + cp*cp*vt - cp*p*vtt*v + 2.0*cp*p*vt*T*vtt + cpt*p*vt*v - cpt*p*vt2*T)/cp3;
        duhh:=-p*(cp*vtt - cpt*vt)/cp3;
        der_pro.x:=0.0;
        der_pro.duhp:=duph*p_der + duhh*h_der;
        der_pro.duph:=dupp*p_der + duph*h_der;
        der_pro.ddph:=(ddph*ddph_d + dtph*ddph_t)*p_der + (ddph*ddhp_d + dtph*ddhp_t)*h_der;
        der_pro.ddhp:=(ddhp*ddhp_d + dthp*ddhp_t)*h_der + (ddph*ddhp_d + dtph*ddhp_t)*p_der;
        der_pro.cp:=(-(T*vtt*cp + cpt/rho - cpt*T*vt)/cp)*p_der + cpt/cp*h_der;
        der_pro.s:=-1/(rho*T)*p_der + 1/T*h_der;
        der_pro.u:=(-(p*vp*cp + cp*v - p*vt*v + p*vt2*T)/cp)*p_der + (cp - p*vt)/cp*h_der;
        der_pro.T:=(-v + T*vt)/cp*p_der + 1/cp*h_der;
        der_pro.d:=(-rho2*(vp*cp - vt/rho + T*vt2)/cp)*p_der + (-rho2*vt/cp)*h_der;

      elseif region == 3 then
        (rho,T,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.dtofph3(p, h, delp=1e-07, delh=1e-06);
        f:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3L3(rho, T);
        rho2:=rho*rho;
        rho3:=rho*rho2;
        pd:=R*T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
        pt:=R*rho*f.delta*(f.fdelta - f.tau*f.fdeltatau);
        pt2:=pt*pt;
        pt3:=pt2*pt;
        cv:=abs(R*(-f.tau*f.tau*f.ftautau)) "can be close to neg. infinity near critical point";
        cp:=(rho2*pd*cv + T*pt2)/(rho2*pd);
        pdd:=R*T*f.delta/rho*(2.0*f.fdelta + 4.0*f.delta*f.fdeltadelta + f.delta*f.delta*f.fdeltadeltadelta);
        ptt:=R*rho*f.delta*f.tau*f.tau/T*f.fdeltatautau;
        ptd:=R*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta - 2.0*f.tau*f.fdeltatau - f.delta*f.tau*f.fdeltadeltatau);
        cvt:=R*f.tau*f.tau/T*(2.0*f.ftautau + f.tau*f.ftautautau);
        cpt:=(cvt*pd + cv*ptd + (pt + 2.0*T*ptt)*pt/rho2 - cp*ptd)/pd;
        detPH:=cp*pd;
        dht:=cv + pt/rho;
        dhd:=(pd - T*pt/rho)/rho;
        ddph:=dht/detPH;
        ddhp:=-pt/detPH;
        dtph:=-dhd/detPH;
        dthp:=pd/detPH;
        detPH_d:=cv*pdd + (2.0*pt*(ptd - pt/rho) - ptt*pd)*T/rho2;
        detPH_t:=cvt*pd + cv*ptd + (pt + 2.0*T*ptt)*pt/rho2;
        dhtt:=cvt + ptt*v;
        dhtd:=(ptd - (T*ptt + pt)*v)*v;
        ddhp_t:=ddhp*(ptt/pt - detPH_t/detPH);
        ddhp_d:=ddhp*(ptd/pt - detPH_d/detPH);
        ddph_t:=ddph*(dhtt/dht - detPH_t/detPH);
        ddph_d:=ddph*(dhtd/dht - detPH_d/detPH);
        dcp_d:=(detPH_d - cp*pdd)/pd;
        quotient:=1/(cv*rho2*pd + T*pt2)^3;
        dupp:=-(-4.0*ptt*p*cv*rho2*pd*T*pt + 2.0*p*cvt*rho2*T*pt2*pd - 2.0*ptt*p*T*pt2*rho*pd + 3.0*p*cv^2*rho3*ptd*T*pt + 3.0*p*cv*rho*T^2*pt2*ptt - 2.0*pt*p*cv*rho3*ptd*pd + 4.0*pt2*p*cv*rho2*ptd*T - 2.0*T^2*pt2*pt3 - 4.0*pt2*cv^2*rho3*pd*T - 4.0*pt3*cv*rho2*T*pd - p*cvt*rho*T^2*pt3 + ptt*p*cv*rho3*pd^2 - 2.0*p*cv^2*rho2*rho2*ptd*pd + 2.0*p*cv*rho2*pt2*pd + 2.0*p*cv*rho*pt3*T - pt*p*cvt*rho3*pd^2 + ptd*p*rho*T*pt3 + 5.0*pt*p*cv^2*rho3*pd + 2*pt*p*cv^2*rho2*rho2*pdd + pt2*p*cv*rho3*pdd + 2.0*pt2*pt2*p*T - 2.0*cv^3*rho3*rho2*pd^2 - 2.0*pt*cv^2*rho2*rho2*pd^2 - 2.0*pt2*pt2*cv*rho*T^2 + 2.0*ptt*p*T^2*pt3 - pt3*p*rho*pd + 2.0*p*cv^3*rho2*rho2*pd + p*cv^3*rho2*rho3*pdd)*quotient/rho;
        duph:=(-2.0*ptt*p*cv*rho2*pd*T*pt + p*cvt*rho2*T*pt2*pd - 2.0*ptt*p*T*pt2*rho*pd - 2.0*pt*p*cv*rho3*ptd*pd + 2.0*pt2*p*cv*rho2*ptd*T - T^2*pt3*pt2 - 2*pt3*cv*rho2*T*pd + ptt*p*cv*rho3*pd^2 - p*cv^2*rho2*rho2*ptd*pd + 2.0*p*cv*rho2*pt2*pd - pt*p*cvt*rho3*pd^2 + ptd*p*rho*T*pt3 + 2.0*pt*p*cv^2*rho3*pd + pt*p*cv^2*rho2*rho2*pdd + pt2*p*cv*rho3*pdd + pt2*pt2*p*T - pt*cv^2*rho2*rho2*pd^2 + ptt*p*T^2*pt3 - pt3*p*rho*pd)*quotient;
        duhh:=p*(-pt3*T*ptd + 2.0*ptd*cv*rho2*pd*pt - 2.0*pt2*cv*rho*pd + pt*cvt*rho2*pd^2 - pt2*cv*rho2*pdd + 2.0*pt2*T*ptt*pd - ptt*cv*rho2*pd^2 + pt3*pd)*rho2*quotient;
        der_pro.x:=0.0;
        der_pro.duhp:=duph*p_der + duhh*h_der;
        der_pro.duph:=dupp*p_der + duph*h_der;
        der_pro.ddph:=(ddph*ddph_d + dtph*ddph_t)*p_der + (ddph*ddhp_d + dtph*ddhp_t)*h_der;
        der_pro.ddhp:=(ddhp*ddhp_d + dthp*ddhp_t)*h_der + (ddph*ddhp_d + dtph*ddhp_t)*p_der;
        der_pro.cp:=(ddph*dcp_d + dtph*cpt)*p_der + (ddhp*dcp_d + dthp*cpt)*h_der;
        der_pro.s:=-1/(rho*T)*p_der + 1/T*h_der;
        der_pro.u:=(cv*rho2*pd - pt*p + T*pt2)/(cv*rho2*pd + T*pt2)*h_der + (cv*rho2*pd - p*cv*rho - pt*p + T*pt2)/(rho*(cv*rho2*pd + T*pt2))*p_der;
        der_pro.T:=(-rho*pd + T*pt)/(rho2*pd*cv + T*pt*pt)*p_der + rho2*pd/(rho2*pd*cv + T*pt2)*h_der;
        der_pro.d:=rho*(cv*rho + pt)/(rho2*pd*cv + T*pt2)*p_der + (-rho2*pt/(rho2*pd*cv + T*pt2))*h_der;

      elseif region == 4 then
        h_liq:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.hl_p(p);
        h_vap:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.hv_p(p);
        x:=if h_vap <> h_liq then (h - h_liq)/(h_vap - h_liq) else 1.0;
        if p < ThermoSysPro.Properties.WaterSteam.BaseIF97.data.PLIMIT4A then
          t1:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tph1(p, h_liq);
          t2:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tph2(p, h_vap);
          gl:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g1L3(p, t1);
          gv:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g2L3(p, t2);
          liq:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToBoundaryProps3rd(gl);
          vap:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToBoundaryProps3rd(gv);
          T:=t1 + x*(t2 - t1);
        else
          T:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tsat(p);
          d_liq:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.rhol_T(T);
          d_vap:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.rhov_T(T);
          fl:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3L3(d_liq, T);
          fv:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3L3(d_vap, T);
          liq:=ThermoSysPro.Properties.WaterSteam.Common.helmholtzToBoundaryProps3rd(fl);
          vap:=ThermoSysPro.Properties.WaterSteam.Common.helmholtzToBoundaryProps3rd(fv);
        end if;
        rho:=liq.d*vap.d/(vap.d + x*(liq.d - vap.d));
        rho2:=rho*rho;
        rho3:=rho*rho2;
        v:=1/rho;
        dxv:=if liq.d <> vap.d then liq.d*vap.d/(liq.d - vap.d) else 0.0;
        dpT:=if liq.d <> vap.d then (vap.s - liq.s)*dxv else ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.dptofT(T);
        dvTl:=(liq.pt - dpT)/(liq.pd*liq.d*liq.d);
        dvTv:=(vap.pt - dpT)/(vap.pd*vap.d*vap.d);
        dxT:=-dxv*(dvTl + x*(dvTv - dvTl));
        duTl:=liq.cv + (T*liq.pt - p)*dvTl;
        duTv:=vap.cv + (T*vap.pt - p)*dvTv;
        cv:=duTl + x*(duTv - duTl) + dxT*(vap.u - liq.u);
        dpTT:=dxv*(vap.cv/T - liq.cv/T + dvTv*(vap.pt - dpT) - dvTl*(liq.pt - dpT));
        dxdd:=2.0*dxv/rho3;
        dxTd:=dxv*dxv*(dvTv - dvTl)/rho2;
        dvTTl:=((liq.ptt - dpTT)/(liq.d*liq.d) + dvTl*(liq.d*dvTl*(2.0*liq.pd + liq.d*liq.pdd) - 2.0*liq.ptd))/liq.pd;
        dvTTv:=((vap.ptt - dpTT)/(vap.d*vap.d) + dvTv*(vap.d*dvTv*(2.0*vap.pd + vap.d*vap.pdd) - 2.0*vap.ptd))/vap.pd;
        dxTT:=-dxv*(2.0*dxT*(dvTv - dvTl) + dvTTl + x*(dvTTv - dvTTl));
        duTTl:=liq.cvt + (liq.pt - dpT + T*(2.0*liq.ptt - liq.d*liq.d*liq.ptd*dvTl))*dvTl + (T*liq.pt - p)*dvTTl;
        duTTv:=vap.cvt + (vap.pt - dpT + T*(2.0*vap.ptt - vap.d*vap.d*vap.ptd*dvTv))*dvTv + (T*vap.pt - p)*dvTTv;
        cvt:=duTTl + x*(duTTv - duTTl) + 2.0*dxT*(duTv - duTl) + dxTT*(vap.u - liq.u);
        ptt:=dpTT;
        dht:=cv + dpT*v;
        dhd:=-T*dpT*v*v;
        detPH:=-dpT*dhd;
        dtph:=1.0/dpT;
        ddph:=dht/detPH;
        ddhp:=-dpT/detPH;
        detPH_d:=-2.0*v;
        detPH_t:=2.0*ptt/dpT + 1.0/T;
        dhtt:=cvt + ptt*v;
        dhtd:=-(T*ptt + dpT)*v*v;
        ddhp_t:=ddhp*(ptt/dpT - detPH_t);
        ddhp_d:=ddhp*(-detPH_d);
        ddph_t:=ddph*(dhtt/dht - detPH_t);
        ddph_d:=ddph*(dhtd/dht - detPH_d);
        duhp_t:=(ddhp*dpT + p*ddhp_t)/rho2;
        duph_t:=(ddph*dpT + p*ddph_t)/rho2;
        duph_d:=((-2.0*ddph/rho + ddph_d)*p + 1.0)/rho2;
        der_pro.x:=if h_vap <> h_liq then h_der/(h_vap - h_liq) else 0.0;
        der_pro.duhp:=dtph*duhp_t*p_der;
        der_pro.duph:=(ddph*duph_d + dtph*duph_t)*p_der + dtph*duhp_t*h_der;
        der_pro.ddph:=(ddph*ddph_d + dtph*ddph_t)*p_der + ddhp*ddph_d*h_der;
        der_pro.ddhp:=ddhp*ddhp_d*h_der + ddhp*ddph_d*p_der;
        der_pro.cp:=0.0;
        der_pro.s:=-1/(rho*T)*p_der + 1/T*h_der;
        der_pro.u:=(ddph*p/rho - 1.0)/rho*p_der + (ddhp*p/rho2 + 1.0)*h_der;
        der_pro.T:=1/dpT*p_der;
        der_pro.d:=rho*(rho*cv/dpT + 1.0)/(dpT*T)*p_der + (-rho2/(dpT*T))*h_der;

      elseif region == 5 then
        (T,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.tofph5(p, h, reldh=1e-07);
        assert(error == 0, "error in inverse iteration of steam tables");
        g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g5L3(p, T);
        rho:=p/(R*T*g.pi*g.gpi);
        rho2:=rho*rho;
        vt:=R/p*(g.pi*g.gpi - g.tau*g.pi*g.gpitau);
        vt2:=vt*vt;
        cp:=-R*g.tau*g.tau*g.gtautau;
        cp3:=cp*cp*cp;
        cpcpp:=cp*cp*p;
        vp:=R*T/(p*p)*g.pi*g.pi*g.gpipi;
        v:=1/rho;
        vtt:=R*g.pi/p*g.tau/T*g.tau*g.gpitautau;
        vtp:=R*g.pi*g.pi/(p*p)*(g.gpipi - g.tau*g.gpipitau);
        vpp:=R*T*g.pi*g.pi*g.pi/(p*p*p)*g.gpipipi;
        cpt:=R*g.tau*g.tau/T*(2*g.gtautau + g.tau*g.gtautautau);
        pt:=-g.p/g.T*(g.gpi - g.tau*g.gpitau)/(g.gpipi*g.pi);
        pd:=-g.R*g.T*g.gpi*g.gpi/g.gpipi;
        vp3:=vp*vp*vp;
        ivp3:=1/vp3;
        ptt:=-(vtt*vp*vp - 2.0*vt*vtp*vp + vt2*vpp)*ivp3;
        pdd:=-vpp*ivp3/(rho2*rho2) - 2*v*pd "= pvv/d^4";
        ptd:=(vtp*vp - vt*vpp)*ivp3/rho2 "= -ptv/d^2";
        cvt:=(vp3*cpt + vp*vp*vt2 + 3.0*vp*vp*T*vt*vtt - 3.0*vtp*vp*T*vt2 + T*vt2*vt*vpp)*ivp3;
        detPH:=cp*pd;
        dht:=cv + pt/rho;
        dhd:=(pd - T*pt/rho)/rho;
        ddph:=dht/detPH;
        ddhp:=-pt/detPH;
        dtph:=-dhd/detPH;
        dthp:=pd/detPH;
        detPH_d:=cv*pdd + (2.0*pt*(ptd - pt/rho) - ptt*pd)*T/rho2;
        detPH_t:=cvt*pd + cv*ptd + (pt + 2.0*T*ptt)*pt/rho2;
        dhtt:=cvt + ptt*v;
        dhtd:=(ptd - (T*ptt + pt)*v)*v;
        ddhp_t:=ddhp*(ptt/pt - detPH_t/detPH);
        ddhp_d:=ddhp*(ptd/pt - detPH_d/detPH);
        ddph_t:=ddph*(dhtt/dht - detPH_t/detPH);
        ddph_d:=ddph*(dhtd/dht - detPH_d/detPH);
        dupp:=-(2.0*cp3*vp + cp3*p*vpp - 2.0*cp*cp*vt*v - 2.0*cpcpp*vtp*v - cpcpp*vt*vp + 2.0*cp*cp*T*vt2 + 3.0*cpcpp*vt*T*vtp - 4.0*T*vtt*cp*p*vt*v + 3.0*T*T*vtt*cp*p*vt2 + cp*p*vtt/rho2 - cpt*p*vt/rho2 + 2.0*cpt*p*vt2*v*T - cpt*p*vt2*T^2)/cp3;
        duph:=-(vtp*cpcpp + cp*cp*vt - cp*p*vtt*v + 2.0*cp*p*vt*T*vtt + cpt*p*vt*v - cpt*p*vt2*T)/cp3;
        duhh:=-p*(cp*vtt - cpt*vt)/cp3;
        der_pro.x:=0.0;
        der_pro.duhp:=duph*p_der + duhh*h_der;
        der_pro.duph:=dupp*p_der + duph*h_der;
        der_pro.ddph:=(ddph*ddph_d + dtph*ddph_t)*p_der + (ddph*ddhp_d + dtph*ddhp_t)*h_der;
        der_pro.ddhp:=(ddhp*ddhp_d + dthp*ddhp_t)*h_der + (ddph*ddhp_d + dtph*ddhp_t)*p_der;
        der_pro.cp:=(-(T*vtt*cp + cpt/rho - cpt*T*vt)/cp)*p_der + cpt/cp*h_der;
        der_pro.s:=-1/(rho*T)*p_der + 1/T*h_der;
        der_pro.u:=(-(p*vp*cp + cp*v - p*vt*v + p*vt2*T)/cp)*p_der + (cp - p*vt)/cp*h_der;
        der_pro.T:=(-v + T*vt)/cp*p_der + 1/cp*h_der;
        der_pro.d:=(-rho2*(vp*cp - vt/rho + T*vt2)/cp)*p_der + (-rho2*vt/cp)*h_der;
      else
        assert(false, "Water_Ph_der: Incorrect region number");
      end if;
      annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Text(lineColor={0,0,255}, extent={{-134,104},{142,44}}, textString="%name"),Ellipse(extent={{-100,40},{100,-100}}, fillPattern=FillPattern.Solid, lineColor={255,127,0}, fillColor={255,255,255}),Text(lineColor={0,0,255}, extent={{-84,-4},{84,-52}}, textString="fonction", fillColor={255,127,0})}), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
    end Water_Ph_der;

    function Water_Ps_der
      input ThermoSysPro.Units.AbsolutePressure p "Pression";
      input Modelica.SIunits.SpecificEntropy s "Entropie spécifique";
      input Integer mode=0 "Région IF97 - 0:calcul automatique";
      input Real p_der "derivative of Pressure";
      input Real s_der "derivative of Specific enthropy";
    protected
      Boolean supercritical;
      Integer phase "phase: 2 for two-phase, 1 for one phase, 0 if unknown";
      Integer region(min=1, max=5) "IF 97 region";
      Modelica.SIunits.Temperature T "temperature";
      Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      Modelica.SIunits.SpecificHeatCapacity R "gas constant";
      Modelica.SIunits.SpecificHeatCapacity cp "specific heat capacity";
      Real cpt "derivative of cp w.r.t. temperature";
      Modelica.SIunits.SpecificHeatCapacity cv "specific heat capacity";
      Real cvt "derivative of cv w.r.t. temperature";
      Modelica.SIunits.Density rho "density";
      ThermoSysPro.Units.DerPressureByTemperature pt "derivative of pressure wrt temperature";
      ThermoSysPro.Units.DerPressureByDensity pd "derivative of pressure wrt density";
      Real ptt "2nd derivative of pressure wrt temperature";
      Real pdd "2nd derivative of pressure wrt density";
      Real ptd "mixed derivative of pressure w.r.t. density and temperature";
      Real vt "derivative of specific volume w.r.t. temperature";
      Real vp "derivative of specific volume w.r.t. pressure";
      Real vtt "2nd derivative of specific volume w.r.t. temperature";
      Real vpp "2nd derivative of specific volume w.r.t. pressure";
      Real vtp "mixed derivative of specific volume w.r.t. pressure and temperature";
      Real x "dryness fraction";
      Real dpT "dp/dT derivative of saturation curve";
      Modelica.SIunits.SpecificEntropy auxs "specific entropy";
      Integer error "error flag for inverse iterations";
      Modelica.SIunits.SpecificEntropy s_liq "liquid specific entropy";
      Modelica.SIunits.Density d_liq "liquid density";
      Modelica.SIunits.SpecificEntropy s_vap "vapour specific entropy";
      Modelica.SIunits.Density d_vap "vapour density";
      ThermoSysPro.Properties.WaterSteam.Common.PhaseBoundaryProperties3rd liq "phase boundary property record";
      ThermoSysPro.Properties.WaterSteam.Common.PhaseBoundaryProperties3rd vap "phase boundary property record";
      ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs3rd gl "dimensionless Gibbs funcion and dervatives wrt pi and tau";
      ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs3rd gv "dimensionless Gibbs funcion and dervatives wrt pi and tau";
      ThermoSysPro.Properties.WaterSteam.Common.HelmholtzDerivs3rd fl "dimensionless Helmholtz function and dervatives wrt delta and tau";
      ThermoSysPro.Properties.WaterSteam.Common.HelmholtzDerivs3rd fv "dimensionless Helmholtz function and dervatives wrt delta and tau";
      Modelica.SIunits.Temperature t1 "temperature at phase boundary, using inverse from region 1";
      Modelica.SIunits.Temperature t2 "temperature at phase boundary, using inverse from region 2";
      Real detPH;
      Real dtsp;
      Real dtps;
      Real ddsp;
      Real ddps;
      Real dsd;
      Real detPH_t;
      Real detPH_d;
      Real dcp_t;
      Real dcp_d;
      Real dcps;
      Real dcpp;
      Real dxv;
      Real dxd;
      Real dvTl;
      Real dvTv;
      Real dxT;
      Real duTl;
      Real duTv;
      Real dpTT;
      Real dxdd;
      Real dxTd;
      Real dvTTl;
      Real dvTTv;
      Real dxTT;
      Real duTTl;
      Real duTTv;
      Real rho2;
      Real cp3;
      Real invcp3;
      Real cpinv;
      Real vt2;
      Real pt2;
      Real pt3;
      Real quotient;
    public
      output ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ps pro_der;
    protected
      ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs3rd g "dimensionless Gibbs funcion and dervatives wrt pi and tau" annotation(extent=[-90,-85;-43.3333,-38.3333]);
      ThermoSysPro.Properties.WaterSteam.Common.HelmholtzDerivs3rd f "dimensionless Helmholtz funcion and dervatives wrt delta and tau" annotation(extent=[-23.3333,-85;23.3333,-38.3333]);
    algorithm
      supercritical:=p > ThermoSysPro.Properties.WaterSteam.BaseIF97.data.PCRIT;
      phase:=if s < ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.sl_p(p) or s > ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.sv_p(p) or supercritical then 1 else 2;
      region:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.region_ps(p, s, phase, mode);
      R:=ThermoSysPro.Properties.WaterSteam.BaseIF97.data.RH2O;
      auxs:=s;
      if region == 1 then
        T:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tps1(p, s);
        g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g1L3(p, T);
        h:=R*T*g.tau*g.gtau;
        rho:=p/(R*T*g.pi*g.gpi);
        rho2:=rho*rho;
        vt:=R/p*(g.pi*g.gpi - g.tau*g.pi*g.gpitau);
        vt2:=vt*vt;
        vp:=R*T/(p*p)*g.pi*g.pi*g.gpipi;
        cp:=-R*g.tau*g.tau*g.gtautau;
        cpinv:=1/cp;
        cp3:=cp*cp*cp;
        invcp3:=1/cp3;
        cv:=R*(-g.tau*g.tau*g.gtautau + (g.gpi - g.tau*g.gpitau)*(g.gpi - g.tau*g.gpitau)/g.gpipi);
        x:=0.0;
        vtt:=R*g.pi/p*g.tau/T*g.tau*g.gpitautau;
        vtp:=R*g.pi*g.pi/(p*p)*(g.gpipi - g.tau*g.gpipitau);
        vpp:=R*T*g.pi*g.pi*g.pi/(p*p*p)*g.gpipipi;
        cpt:=R*g.tau*g.tau/T*(2*g.gtautau + g.tau*g.gtautautau);
        pro_der.cp:=cpinv*T*(-(vtt*cp - cpt*vt)*p_der + cpt*s_der);
        pro_der.x:=0.0;
        pro_der.ddps:=(-rho2*(cp3*vpp + 3.0*cp*cp*T*vt*vtp + 3.0*T*T*vtt*cp*vt2 - T*T*vt2*vt*cpt + T*vt2*vt*cp)*invcp3)*p_der + (-rho2*T*(2.0*vtt*T*vt*cp + cp*cp*vtp - cpt*T*vt2 + cp*vt2)*invcp3)*s_der;
        pro_der.ddsp:=(-rho2*T*(2.0*vtt*T*vt*cp + cp*cp*vtp - cpt*T*vt2 + cp*vt2)*invcp3)*p_der + (-rho2*(-cpt*T*vt + cp*vt + T*vtt*cp)*T*invcp3)*s_der;
        pro_der.h:=p_der/rho + T*s_der;
        pro_der.u:=cpinv*(-p*(vp*cp + T*vt2)*p_der + (cp - p*vt)*T*s_der);
        pro_der.d:=cpinv*(-rho2*(vp*cp + T*vt2)*p_der + (-rho2*vt*T)*s_der);
        pro_der.T:=T*cpinv*(vt*p_der + s_der);
      elseif region == 2 then
        T:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tps2(p, s);
        g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g2L3(p, T);
        h:=R*T*g.tau*g.gtau;
        rho:=p/(R*T*g.pi*g.gpi);
        rho2:=rho*rho;
        vt:=R/p*(g.pi*g.gpi - g.tau*g.pi*g.gpitau);
        vt2:=vt*vt;
        vp:=R*T/(p*p)*g.pi*g.pi*g.gpipi;
        cp:=-R*g.tau*g.tau*g.gtautau;
        cpinv:=1/cp;
        cp3:=cp*cp*cp;
        invcp3:=1/cp3;
        cv:=R*(-g.tau*g.tau*g.gtautau + (g.gpi - g.tau*g.gpitau)*(g.gpi - g.tau*g.gpitau)/g.gpipi);
        x:=0.0;
        vtt:=R*g.pi/p*g.tau/T*g.tau*g.gpitautau;
        vtp:=R*g.pi*g.pi/(p*p)*(g.gpipi - g.tau*g.gpipitau);
        vpp:=R*T*g.pi*g.pi*g.pi/(p*p*p)*g.gpipipi;
        cpt:=R*g.tau*g.tau/T*(2*g.gtautau + g.tau*g.gtautautau);
        pro_der.cp:=cpinv*T*(-(vtt*cp - cpt*vt)*p_der + cpt*s_der);
        pro_der.x:=0.0;
        pro_der.ddps:=(-rho2*(cp3*vpp + 3.0*cp*cp*T*vt*vtp + 3.0*T*T*vtt*cp*vt2 - T*T*vt2*vt*cpt + T*vt2*vt*cp)*invcp3)*p_der + (-rho2*T*(2.0*vtt*T*vt*cp + cp*cp*vtp - cpt*T*vt2 + cp*vt2)*invcp3)*s_der;
        pro_der.ddsp:=(-rho2*T*(2.0*vtt*T*vt*cp + cp*cp*vtp - cpt*T*vt2 + cp*vt2)*invcp3)*p_der + (-rho2*(-cpt*T*vt + cp*vt + T*vtt*cp)*T*invcp3)*s_der;
        pro_der.h:=p_der/rho + T*s_der;
        pro_der.u:=cpinv*(-p*(vp*cp + T*vt2)*p_der + (cp - p*vt)*T*s_der);
        pro_der.d:=cpinv*(-rho2*(vp*cp + T*vt2)*p_der + (-rho2*vt*T)*s_der);
        pro_der.T:=T*cpinv*(vt*p_der + s_der);

      elseif region == 3 then
        (rho,T,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.dtofps3(p, s, delp=1e-07, dels=1e-06);
        f:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3L3(rho, T);
        rho2:=rho*rho;
        h:=R*T*(f.tau*f.ftau + f.delta*f.fdelta);
        auxs:=R*(f.tau*f.ftau - f.f);
        pd:=R*T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
        pt:=R*rho*f.delta*(f.fdelta - f.tau*f.fdeltatau);
        pt2:=pt*pt;
        pt3:=pt2*pt;
        cv:=abs(R*(-f.tau*f.tau*f.ftautau)) "can be close to neg. infinity near critical point";
        cp:=(rho2*pd*cv + T*pt*pt)/(rho*rho*pd);
        pdd:=R*T*f.delta/rho*(2.0*f.fdelta + 4.0*f.delta*f.fdeltadelta + f.delta*f.delta*f.fdeltadeltadelta);
        ptt:=R*rho*f.delta*f.tau*f.tau/T*f.fdeltatautau;
        ptd:=R*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta - 2.0*f.tau*f.fdeltatau - f.delta*f.tau*f.fdeltadeltatau);
        cvt:=R*f.tau*f.tau/T*(2.0*f.ftautau + f.tau*f.ftautautau);
        x:=0.0;
        dsd:=-pt/rho2;
        detPH:=cp*pd;
        dtsp:=T*pd/detPH;
        dtps:=-T*dsd/detPH;
        ddsp:=-T*pt/detPH;
        ddps:=cv/detPH;
        detPH_t:=cvt*pd + cv*ptd + (pt + 2.0*T*ptt)*pt/rho2;
        detPH_d:=cv*pdd + (2.0*pt*(ptd - pt/rho) - ptt*pd)*T/rho2;
        dcp_t:=(detPH_t - cp*ptd)/pd;
        dcp_d:=(detPH_d - cp*pdd)/pd;
        dcps:=ddsp*dcp_d + dtsp*dcp_t;
        dcpp:=ddps*dcp_d + dtps*dcp_t;
        quotient:=1/(cv*rho2*pd + pt2*T);
        pro_der.cp:=dcps*s_der + dcpp*p_der;
        pro_der.x:=0.0;
        pro_der.ddps:=rho2/(quotient*quotient*quotient)*(-(-cvt*T^2*pt3 + 3.0*cv^2*T*pt*rho2*ptd + 3.0*cv*T^2*pt2*ptt + cv*T*pt3 - 2.0*cv^2*rho*pt2*T + cv^3*rho2*rho2*pdd)*p_der + (pt2*T*cvt*rho2*pd + 2*pt2*T*cv*rho2*ptd + pt3*T^2*ptt - pt2*cv*rho2*pd - 2.0*pt*T*ptt*cv*rho2*pd + cv^2*rho2*rho2*pt*pdd - 2.0*cv*rho*T*pt3 - cv^2*rho2*rho2*ptd*pd)*T*s_der);
        pro_der.ddsp:=quotient/(rho2*T*pt2)*(-(pt2*T*cvt*rho2*pd + 2.0*pt2*T*cv*rho2*ptd + pt3*T^2*ptt - pt2*cv*rho2*pd - 2.0*pt*T*ptt*cv*rho2*pd + cv^2*rho2*rho2*pt*pdd - 2.0*cv*rho*T*pt3 - cv^2*rho2*rho2*ptd*pd)*p_der - (rho^3*pd^2*T*pt*cvt + 2.0*rho2*rho*pd*T*pt*cv*ptd + 2.0*rho*pd*T^2*pt2*ptt - rho2*rho*pd^2*pt*cv - ptt*rho2*rho*T*pd^2*cv - T*pt2*rho2*rho*cv*pdd - T^2*pt3*rho*ptd + 2.0*T^2*pt2*pt2)*s_der);
        pro_der.h:=p_der/rho + T*s_der;
        pro_der.u:=quotient*((cv*rho2*pd - pt*p + pt2*T)*T*s_der + cv*p*p_der);
        pro_der.d:=rho2*quotient*(-T*pt*s_der + cv*p_der);
        pro_der.T:=T*quotient*(pt*p_der + rho2*pd*s_der);

      elseif region == 4 then
        s_liq:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.sl_p(p);
        s_vap:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.sv_p(p);
        x:=if s_vap <> s_liq then (s - s_liq)/(s_vap - s_liq) else 1.0;
        if p < ThermoSysPro.Properties.WaterSteam.BaseIF97.data.PLIMIT4A then
          t1:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tps1(p, s_liq);
          t2:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tps2(p, s_vap);
          gl:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g1L3(p, t1);
          gv:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g2L3(p, t2);
          liq:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToBoundaryProps3rd(gl);
          vap:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToBoundaryProps3rd(gv);
          T:=t1 + x*(t2 - t1);
        else
          T:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tsat(p);
          d_liq:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.rhol_T(T);
          d_vap:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.rhov_T(T);
          fl:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3L3(d_liq, T);
          fv:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3L3(d_vap, T);
          liq:=ThermoSysPro.Properties.WaterSteam.Common.helmholtzToBoundaryProps3rd(fl);
          vap:=ThermoSysPro.Properties.WaterSteam.Common.helmholtzToBoundaryProps3rd(fv);
        end if;
        dpT:=if liq.d <> vap.d then (vap.s - liq.s)*liq.d*vap.d/(liq.d - vap.d) else ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.dptofT(T);
        h:=h + x*(vap.h - liq.h);
        rho:=liq.d*vap.d/(vap.d + x*(liq.d - vap.d));
        rho2:=rho*rho;
        dxv:=if liq.d <> vap.d then liq.d*vap.d/(liq.d - vap.d) else 0.0;
        dxd:=-dxv/rho2;
        dpT:=if liq.d <> vap.d then (vap.s - liq.s)*dxv else ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.dptofT(T);
        dvTl:=(liq.pt - dpT)/(liq.pd*liq.d*liq.d);
        dvTv:=(vap.pt - dpT)/(vap.pd*vap.d*vap.d);
        dxT:=-dxv*(dvTl + x*(dvTv - dvTl));
        duTl:=liq.cv + (T*liq.pt - p)*dvTl;
        duTv:=vap.cv + (T*vap.pt - p)*dvTv;
        cv:=duTl + x*(duTv - duTl) + dxT*(vap.u - liq.u);
        dpTT:=dxv*(vap.cv/T - liq.cv/T + dvTv*(vap.pt - dpT) - dvTl*(liq.pt - dpT));
        dxdd:=2.0*dxv/(rho2*rho);
        dxTd:=dxv*dxv*(dvTv - dvTl)/rho2;
        dvTTl:=((liq.ptt - dpTT)/(liq.d*liq.d) + dvTl*(liq.d*dvTl*(2.0*liq.pd + liq.d*liq.pdd) - 2.0*liq.ptd))/liq.pd;
        dvTTv:=((vap.ptt - dpTT)/(vap.d*vap.d) + dvTv*(vap.d*dvTv*(2.0*vap.pd + vap.d*vap.pdd) - 2.0*vap.ptd))/vap.pd;
        dxTT:=-dxv*(2.0*dxT*(dvTv - dvTl) + dvTTl + x*(dvTTv - dvTTl));
        duTTl:=liq.cvt + (liq.pt - dpT + T*(2.0*liq.ptt - liq.d*liq.d*liq.ptd*dvTl))*dvTl + (T*liq.pt - p)*dvTTl;
        duTTv:=vap.cvt + (vap.pt - dpT + T*(2.0*vap.ptt - vap.d*vap.d*vap.ptd*dvTv))*dvTv + (T*vap.pt - p)*dvTTv;
        cvt:=duTTl + x*(duTTv - duTTl) + 2.0*dxT*(duTv - duTl) + dxTT*(vap.u - liq.u);
        detPH:=T*dpT*dpT/rho2;
        dtps:=1.0/dpT;
        ddsp:=-T*dpT/detPH;
        ddps:=cv/detPH;
        ptt:=dpTT;
        pro_der.x:=if s_vap <> s_liq then s_der/(s_vap - s_liq) else 0.0;
        pro_der.ddps:=(-rho2*(-cvt*T*dpT + 3.0*cv*T*ptt + cv*dpT - 2.0*cv^2*rho)/(dpT*dpT*dpT*dpT*T*T))*p_der + (T*ptt - 2.0*cv*rho)*rho2/(dpT*dpT*dpT*T)*s_der;
        pro_der.ddsp:=(-(T*ptt - 2.0*cv*rho)/(rho2*T*dpT))*p_der + (-2.0/rho)*s_der;
        pro_der.cp:=0.0;
        pro_der.h:=p_der/rho + T*s_der;
        pro_der.u:=ddps*p/rho2*p_der + (ddsp*p/rho2 + T)*s_der;
        pro_der.d:=ddps*p_der + ddsp*s_der;
        pro_der.T:=dtps*p_der;

      elseif region == 5 then
        (T,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.tofps5(p, s, relds=1e-07);
        assert(error == 0, "error in inverse iteration of steam tables");
        g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g5L3(p, T);
        h:=R*T*g.tau*g.gtau;
        rho:=p/(R*T*g.pi*g.gpi);
        rho2:=rho*rho;
        vt:=R/p*(g.pi*g.gpi - g.tau*g.pi*g.gpitau);
        vt2:=vt*vt;
        vp:=R*T/(p*p)*g.pi*g.pi*g.gpipi;
        cp:=-R*g.tau*g.tau*g.gtautau;
        cpinv:=1/cp;
        cp3:=cp*cp*cp;
        invcp3:=1/cp3;
        cv:=R*(-g.tau*g.tau*g.gtautau + (g.gpi - g.tau*g.gpitau)*(g.gpi - g.tau*g.gpitau)/g.gpipi);
        x:=0.0;
        vtt:=R*g.pi/p*g.tau/T*g.tau*g.gpitautau;
        vtp:=R*g.pi*g.pi/(p*p)*(g.gpipi - g.tau*g.gpipitau);
        vpp:=R*T*g.pi*g.pi*g.pi/(p*p*p)*g.gpipipi;
        cpt:=R*g.tau*g.tau/T*(2*g.gtautau + g.tau*g.gtautautau);
        pro_der.cp:=cpinv*T*(-(vtt*cp - cpt*vt)*p_der + cpt*s_der);
        pro_der.x:=0.0;
        pro_der.ddps:=(-rho2*(cp3*vpp + 3.0*cp*cp*T*vt*vtp + 3.0*T*T*vtt*cp*vt2 - T*T*vt2*vt*cpt + T*vt2*vt*cp)*invcp3)*p_der + (-rho2*T*(2.0*vtt*T*vt*cp + cp*cp*vtp - cpt*T*vt2 + cp*vt2)*invcp3)*s_der;
        pro_der.ddsp:=(-rho2*T*(2.0*vtt*T*vt*cp + cp*cp*vtp - cpt*T*vt2 + cp*vt2)*invcp3)*p_der + (-rho2*(-cpt*T*vt + cp*vt + T*vtt*cp)*T*invcp3)*s_der;
        pro_der.h:=p_der/rho + T*s_der;
        pro_der.u:=cpinv*(-p*(vp*cp + T*vt2)*p_der + (cp - p*vt)*T*s_der);
        pro_der.d:=cpinv*(-rho2*(vp*cp + T*vt2)*p_der + (-rho2*vt*T)*s_der);
        pro_der.T:=T*cpinv*(vt*p_der + s_der);
      else
        assert(false, "Water_Ps_der: Incorrect region number");
      end if;
      annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Text(lineColor={0,0,255}, extent={{-134,104},{142,44}}, textString="%name"),Ellipse(extent={{-100,40},{100,-100}}, fillPattern=FillPattern.Solid, lineColor={255,127,0}, fillColor={255,255,255}),Text(lineColor={0,0,255}, extent={{-84,-4},{84,-52}}, textString="fonction", fillColor={255,127,0})}), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
    end Water_Ps_der;

    function Water_PT_der
      input ThermoSysPro.Units.AbsolutePressure p "pressure";
      input ThermoSysPro.Units.AbsoluteTemperature T "Temperature";
      input Integer mode=0 "Région IF97 - 0:calcul automatique";
      input Real p_der "Pression";
      input Real T_der "Température";
      output ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_pT pro_der;
    protected
      Integer region;
      Boolean supercritical;
      Integer error;
      Modelica.SIunits.Density d;
      Modelica.SIunits.Pressure p_aux "pressure";
      Modelica.SIunits.Temperature T_aux "temperature";
      Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      Modelica.SIunits.SpecificHeatCapacity R "gas constant";
      Modelica.SIunits.SpecificHeatCapacity cp "specific heat capacity";
      Real cpt "derivative of cp w.r.t. temperature";
      Modelica.SIunits.SpecificHeatCapacity cv "specific heat capacity";
      Real cvt "derivative of cv w.r.t. temperature";
      Modelica.SIunits.Density rho "density";
      Modelica.SIunits.SpecificEntropy s "specific entropy";
      ThermoSysPro.Units.DerPressureByTemperature pt "derivative of pressure wrt temperature";
      ThermoSysPro.Units.DerPressureByDensity pd "derivative of pressure wrt density";
      Real ptt "2nd derivative of pressure wrt temperature";
      Real pdd "2nd derivative of pressure wrt density";
      Real ptd "mixed derivative of pressure w.r.t. density and temperature";
      Real vt "derivative of specific volume w.r.t. temperature";
      Real vp "derivative of specific volume w.r.t. pressure";
      Real vtt "2nd derivative of specific volume w.r.t. temperature";
      Real vpp "2nd derivative of specific volume w.r.t. pressure";
      Real vtp "mixed derivative of specific volume w.r.t. pressure and temperature";
      Real x "dryness fraction";
      Real dpT "dp/dT derivative of saturation curve";
      ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs3rd g "dimensionless Gibbs funcion and dervatives wrt pi and tau";
      ThermoSysPro.Properties.WaterSteam.Common.HelmholtzDerivs3rd f "dimensionless Helmholtz funcion and dervatives wrt delta and tau";
      Real vp3 "vp^3";
      Real ivp3 "1/vp3";
      Modelica.SIunits.SpecificVolume v;
      Real rho2;
      Real quotient;
      Real quotient2;
      Real pd2;
      Real pd3;
      Real pt2;
      Real pt3;
    algorithm
      supercritical:=p > ThermoSysPro.Properties.WaterSteam.BaseIF97.data.PCRIT;
      region:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.region_pT(p, T, mode);
      R:=ThermoSysPro.Properties.WaterSteam.BaseIF97.data.RH2O;
      if region == 1 then
        g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g1L3(p, T);
        x:=0.0;
        h:=R*T*g.tau*g.gtau;
        s:=R*(g.tau*g.gtau - g.g);
        rho:=p/(R*T*g.pi*g.gpi);
        rho2:=rho*rho;
        vt:=R/p*(g.pi*g.gpi - g.tau*g.pi*g.gpitau);
        vp:=R*T/(p*p)*g.pi*g.pi*g.gpipi;
        cp:=-R*g.tau*g.tau*g.gtautau;
        cv:=R*(-g.tau*g.tau*g.gtautau + (g.gpi - g.tau*g.gpitau)*(g.gpi - g.tau*g.gpitau)/g.gpipi);
        vtt:=R*g.pi/p*g.tau/T*g.tau*g.gpitautau;
        vtp:=R*g.pi*g.pi/(p*p)*(g.gpipi - g.tau*g.gpipitau);
        vpp:=R*T*g.pi*g.pi*g.pi/(p*p*p)*g.gpipipi;
        cpt:=R*g.tau*g.tau/T*(2*g.gtautau + g.tau*g.gtautautau);
        pt:=-g.p/g.T*(g.gpi - g.tau*g.gpitau)/(g.gpipi*g.pi);
        pd:=-g.R*g.T*g.gpi*g.gpi/g.gpipi;
        v:=1/rho;
        vp3:=vp*vp*vp;
        ivp3:=1/vp3;
        ptt:=-(vtt*vp*vp - 2.0*vt*vtp*vp + vt*vt*vpp)*ivp3;
        pdd:=-vpp*ivp3/(rho2*rho2) - 2*v*pd;
        ptd:=(vtp*vp - vt*vpp)*ivp3/rho2 "= -ptv/d^2";
        cvt:=(vp3*cpt + vp*vp*vt*vt + 3.0*vp*vp*T*vt*vtt - 3.0*vtp*vp*T*vt*vt + T*vt*vt*vt*vpp)*ivp3;
        pro_der.x:=0;
        pro_der.duTp:=(-vt - T*vtt - p*vtp)*p_der + (cpt - p*vtt)*T_der;
        pro_der.dupT:=(-T*vtp - vp - p*vpp)*p_der + (-vt - T*vtt - p*vtp)*T_der;
        pro_der.ddpT:=-rho2*(vpp*p_der + vtp*T_der);
        pro_der.ddTp:=-rho2*(vtp*p_der + vtt*T_der);
        pro_der.cp:=(-T*vtt)*p_der + cpt*T_der;
        pro_der.s:=(-vt)*p_der + cp/T*T_der;
        pro_der.u:=(v - T*vt)*p_der + (cp - p*vt)*T_der;
        pro_der.h:=(v - T*vt)*p_der + cp*T_der;
        pro_der.d:=-rho2*(vp*p_der + vt*T_der);
      elseif region == 2 then
        g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g2L3(p, T);
        x:=1.0;
        h:=R*T*g.tau*g.gtau;
        s:=R*(g.tau*g.gtau - g.g);
        rho:=p/(R*T*g.pi*g.gpi);
        rho2:=rho*rho;
        vt:=R/p*(g.pi*g.gpi - g.tau*g.pi*g.gpitau);
        vp:=R*T/(p*p)*g.pi*g.pi*g.gpipi;
        cp:=-R*g.tau*g.tau*g.gtautau;
        cv:=R*(-g.tau*g.tau*g.gtautau + (g.gpi - g.tau*g.gpitau)*(g.gpi - g.tau*g.gpitau)/g.gpipi);
        vtt:=R*g.pi/p*g.tau/T*g.tau*g.gpitautau;
        vtp:=R*g.pi*g.pi/(p*p)*(g.gpipi - g.tau*g.gpipitau);
        vpp:=R*T*g.pi*g.pi*g.pi/(p*p*p)*g.gpipipi;
        cpt:=R*g.tau*g.tau/T*(2*g.gtautau + g.tau*g.gtautautau);
        pt:=-g.p/g.T*(g.gpi - g.tau*g.gpitau)/(g.gpipi*g.pi);
        pd:=-g.R*g.T*g.gpi*g.gpi/g.gpipi;
        v:=1/rho;
        vp3:=vp*vp*vp;
        ivp3:=1/vp3;
        ptt:=-(vtt*vp*vp - 2.0*vt*vtp*vp + vt*vt*vpp)*ivp3;
        pdd:=-vpp*ivp3/(rho2*rho2) - 2*v*pd;
        ptd:=(vtp*vp - vt*vpp)*ivp3/rho2 "= -ptv/d^2";
        cvt:=(vp3*cpt + vp*vp*vt*vt + 3.0*vp*vp*T*vt*vtt - 3.0*vtp*vp*T*vt*vt + T*vt*vt*vt*vpp)*ivp3;
        pro_der.x:=0;
        pro_der.duTp:=(-vt - T*vtt - p*vtp)*p_der + (cpt - p*vtt)*T_der;
        pro_der.dupT:=(-T*vtp - vp - p*vpp)*p_der + (-vt - T*vtt - p*vtp)*T_der;
        pro_der.ddpT:=-rho2*(vpp*p_der + vtp*T_der);
        pro_der.ddTp:=-rho2*(vtp*p_der + vtt*T_der);
        pro_der.cp:=(-T*vtt)*p_der + cpt*T_der;
        pro_der.s:=(-vt)*p_der + cp/T*T_der;
        pro_der.u:=(v - T*vt)*p_der + (cp - p*vt)*T_der;
        pro_der.h:=(v - T*vt)*p_der + cp*T_der;
        pro_der.d:=-rho2*(vp*p_der + vt*T_der);

      elseif region == 3 then
        (rho,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.dofpt3(p, T, delp=1e-07);
        f:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3L3(rho, T);
        rho2:=rho*rho;
        h:=R*T*(f.tau*f.ftau + f.delta*f.fdelta);
        s:=R*(f.tau*f.ftau - f.f);
        pd:=R*T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
        pd2:=pd*pd;
        pd3:=pd*pd2;
        pt:=R*rho*f.delta*(f.fdelta - f.tau*f.fdeltatau);
        pt2:=pt*pt;
        pt3:=pt*pt*pt;
        cv:=R*(-f.tau*f.tau*f.ftautau);
        x:=0.0;
        pdd:=R*T*f.delta/rho*(2.0*f.fdelta + 4.0*f.delta*f.fdeltadelta + f.delta*f.delta*f.fdeltadeltadelta);
        ptt:=R*rho*f.delta*f.tau*f.tau/T*f.fdeltatautau;
        ptd:=R*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta - 2.0*f.tau*f.fdeltatau - f.delta*f.tau*f.fdeltadeltatau);
        cvt:=R*f.tau*f.tau/T*(2.0*f.ftautau + f.tau*f.ftautautau);
        cpt:=(cvt*pd + cv*ptd + (pt + 2.0*T*ptt)*pt/rho2 - pt*ptd)/pd;
        pro_der.x:=0;
        quotient:=1/(rho2*pd);
        quotient2:=quotient/(rho*pd2);
        pro_der.duTp:=quotient2*(-(rho*pd2*T*ptt + ptd*rho*pd*p - 2.0*rho*pd*pt*T*ptd + rho*pd2*pt - 2.0*pt*pd*p + 2.0*pd*pt2*T - pt*pdd*rho*p + pdd*rho*pt2*T)*p_der + (rho2*rho*pd3*cvt - rho*pd2*ptt*p + 3.0*rho*pd2*pt*T*ptt + 2.0*ptd*rho*pd*pt*p - 3.0*ptd*rho*pd*pt2*T + rho*pd2*pt2 - 2.0*pt2*pd*p + 2.0*T*pt3*pd - pt2*pdd*rho*p + T*pt3*pdd*rho)*T_der);
        pro_der.dupT:=quotient2*((rho*pd2 - rho*pd*T*ptd - 2.0*pd*p + 2.0*pd*T*pt - pdd*rho*p + pdd*rho*T*pt)*p_der - (rho*pd2*T*ptt + ptd*rho*pd*p - 2.0*rho*pd*pt*T*ptd + rho*pd2*pt - 2.0*pt*pd*p + 2.0*pd*pt2*T - pt*pdd*rho*p + pdd*rho*pt2*T)*T_der);
        pro_der.ddpT:=-1/pd3*(pdd*p_der + (ptd*pd - pt*pdd)*T_der);
        pro_der.ddTp:=-1/pd3*((ptd*pd - pt*pdd)*p_der + (ptt*pd2 - 2.0*pt*ptd*pd + pt2*pdd)*T_der);
        pro_der.cp:=quotient2*(-T*(rho*pd2*ptt - 2.0*rho*pd*pt*ptd + 2.0*pd*pt2 + pdd*rho*pt^2)*p_der + (rho2*rho*pd3*cvt + 3.0*rho*pd2*pt*T*ptt + rho*pd2*pt2 - 3.0*ptd*rho*pd*pt2*T + 2.0*T*pt3*pd + T*pt3*pdd*rho)*T_der);
        pro_der.s:=quotient*(-pt*p_der + (cv*rho2*pd/T + pt2)*T_der);
        pro_der.u:=quotient*(-(-rho*pd + T*pt)*p_der + (cv*rho2*pd - pt*p + pt2*T)*T_der);
        pro_der.h:=quotient*((-rho*pd + T*pt)*p_der + (rho2*pd*cv + T*pt*pt)*T_der);
        pro_der.d:=1/pd*(p_der - pt*T_der);

      elseif region == 5 then
        g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g5L3(p, T);
        x:=1.0;
        h:=R*T*g.tau*g.gtau;
        s:=R*(g.tau*g.gtau - g.g);
        rho:=p/(R*T*g.pi*g.gpi);
        rho2:=rho*rho;
        vt:=R/p*(g.pi*g.gpi - g.tau*g.pi*g.gpitau);
        vp:=R*T/(p*p)*g.pi*g.pi*g.gpipi;
        cp:=-R*g.tau*g.tau*g.gtautau;
        cv:=R*(-g.tau*g.tau*g.gtautau + (g.gpi - g.tau*g.gpitau)*(g.gpi - g.tau*g.gpitau)/g.gpipi);
        vtt:=R*g.pi/p*g.tau/T*g.tau*g.gpitautau;
        vtp:=R*g.pi*g.pi/(p*p)*(g.gpipi - g.tau*g.gpipitau);
        vpp:=R*T*g.pi*g.pi*g.pi/(p*p*p)*g.gpipipi;
        cpt:=R*g.tau*g.tau/T*(2*g.gtautau + g.tau*g.gtautautau);
        pt:=-g.p/g.T*(g.gpi - g.tau*g.gpitau)/(g.gpipi*g.pi);
        pd:=-g.R*g.T*g.gpi*g.gpi/g.gpipi;
        v:=1/rho;
        vp3:=vp*vp*vp;
        ivp3:=1/vp3;
        ptt:=-(vtt*vp*vp - 2.0*vt*vtp*vp + vt*vt*vpp)*ivp3;
        pdd:=-vpp*ivp3/(rho2*rho2) - 2*v*pd;
        ptd:=(vtp*vp - vt*vpp)*ivp3/rho2 "= -ptv/d^2";
        cvt:=(vp3*cpt + vp*vp*vt*vt + 3.0*vp*vp*T*vt*vtt - 3.0*vtp*vp*T*vt*vt + T*vt*vt*vt*vpp)*ivp3;
        pro_der.x:=0;
        pro_der.duTp:=(-vt - T*vtt - p*vtp)*p_der + (cpt - p*vtt)*T_der;
        pro_der.dupT:=(-T*vtp - vp - p*vpp)*p_der + (-vt - T*vtt - p*vtp)*T_der;
        pro_der.ddpT:=-rho2*(vpp*p_der + vtp*T_der);
        pro_der.ddTp:=-rho2*(vtp*p_der + vtt*T_der);
        pro_der.cp:=(-T*vtt)*p_der + cpt*T_der;
        pro_der.s:=(-vt)*p_der + cp/T*T_der;
        pro_der.u:=(v - T*vt)*p_der + (cp - p*vt)*T_der;
        pro_der.h:=(v - T*vt)*p_der + cp*T_der;
        pro_der.d:=-rho2*(vp*p_der + vt*T_der);
      else
        assert(false, "Water_pT_der: error in region computation of IF97 steam tables" + "(p = " + String(p) + ", T = " + String(T) + ", region = " + String(region) + ")");
      end if;
      annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Text(lineColor={0,0,255}, extent={{-134,104},{142,44}}, textString="%name"),Ellipse(extent={{-100,40},{100,-100}}, fillPattern=FillPattern.Solid, lineColor={255,127,0}, fillColor={255,255,255}),Text(lineColor={0,0,255}, extent={{-84,-4},{84,-52}}, textString="fonction", fillColor={255,127,0})}), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
    end Water_PT_der;

    function Water_sat_P_der
      input ThermoSysPro.Units.AbsolutePressure P "Pression";
      input Real P_der "derivative of pressure";
    protected
      ThermoSysPro.Units.AbsoluteTemperature T;
      ThermoSysPro.Units.DerPressureByTemperature dpT "dp/dT derivative of saturation curve";
      Modelica.SIunits.Density d "density";
      Modelica.SIunits.SpecificHeatCapacity cp "Chaleur spécifique à pression constante";
      Modelica.SIunits.SpecificHeatCapacity cv "specific heat capacity";
      Real vt(unit="m3/(kg.K)") "derivative of specific volume w.r.t. temperature";
      Real vp(unit="m3/(kg.Pa)") "derivative of specific volume w.r.t. pressure";
      ThermoSysPro.Units.DerPressureByDensity pd "Derivative of pressure wrt density";
      Real vp3 "Third power of vp";
      Real ivp3 "Inverse of third power of vp";
      Real cvt "Derivative of cv w.r.t. temperature";
      Real cpt "Derivative of cp w.r.t. temperature";
      Real ptt "2nd derivative of pressure wrt temperature";
      Real vtt "2nd derivative of specific volume w.r.t. temperature";
      Real vpp "2nd derivative of specific volume w.r.t. pressure";
      Real vtp "Mixed derivative of specific volume w.r.t. pressure and temperature";
      Real v "specific volume";
      Real pv;
      Real tp;
      Real p2;
      Real pi2;
    public
      output ThermoSysPro.Properties.WaterSteam.Common.PropThermoSat dlsat annotation(Placement(transformation(x=-50.0, y=50.0, scale=0.35, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
      output ThermoSysPro.Properties.WaterSteam.Common.PropThermoSat dvsat annotation(Placement(transformation(x=50.0, y=50.0, scale=0.35, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
    protected
      ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs3rd gl annotation(extent=[-85,-85;-15,-15]);
      ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs3rd gv annotation(extent=[15,-85;85,-15]);
    algorithm
      T:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tsat(P);
      gl:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g1L3(P, T);
      gv:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g2L3(P, T);
      dpT:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.dptofT(T);
      ptt:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.d2ptofT(T);
      tp:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.dtsatofp(P);
      p2:=gl.p*gl.p;
      pi2:=gl.pi*gl.pi;
      d:=gl.p/(gl.R*T*gl.pi*gl.gpi);
      vp:=gl.R*T/p2*pi2*gl.gpipi;
      vt:=gl.R/gl.p*gl.pi*(gl.gpi - gl.tau*gl.gpitau);
      cp:=-gl.R*gl.tau*gl.tau*gl.gtautau;
      v:=1/d;
      cv:=gl.R*(-gl.tau*gl.tau*gl.gtautau + (gl.gpi - gl.tau*gl.gpitau)*(gl.gpi - gl.tau*gl.gpitau)/gl.gpipi);
      pd:=-gl.R*T*gl.gpi*gl.gpi/gl.gpipi;
      pv:=-pd*d*d;
      vtt:=gl.R*gl.pi/gl.p*gl.tau/T*gl.tau*gl.gpitautau;
      vtp:=gl.R*pi2/p2*(gl.gpipi - gl.tau*gl.gpipitau);
      vpp:=gl.R*T*pi2*gl.pi/(p2*gl.p)*gl.gpipipi;
      vp3:=vp*vp*vp;
      ivp3:=1/vp3;
      cpt:=gl.R*gl.tau*gl.tau/T*(2*gl.gtautau + gl.tau*gl.gtautautau);
      cvt:=(vp3*cpt + vp*vp*vt*vt + 3.0*vp*vp*T*vt*vtt - 3.0*vtp*vp*T*vt*vt + T*vt*vt*vt*vpp)*ivp3;
      dlsat.pt:=ptt*tp*P_der;
      dlsat.cv:=cvt*tp*P_der;
      dlsat.cp:=(cvt*tp + vp*dpT + ((v*pv + T*dpT)*vtp + (vp*pv + tp*dpT)*vt))*P_der;
      dlsat.h:=(v - T*vt)*P_der + cp/dpT*P_der;
      dlsat.rho:=-d*d*(vp + vt/dpT)*P_der;
      dlsat.T:=tp*P_der;
      dlsat.P:=P_der;
      p2:=gv.p*gv.p;
      pi2:=gv.pi*gv.pi;
      d:=gv.p/(gv.R*T*gv.pi*gv.gpi);
      vp:=gv.R*T/p2*pi2*gv.gpipi;
      vt:=gv.R/gv.p*gv.pi*(gv.gpi - gv.tau*gv.gpitau);
      cp:=-gv.R*gv.tau*gv.tau*gv.gtautau;
      v:=1/d;
      cv:=gv.R*(-gv.tau*gv.tau*gv.gtautau + (gv.gpi - gv.tau*gv.gpitau)*(gv.gpi - gv.tau*gv.gpitau)/gv.gpipi);
      pd:=-gv.R*T*gv.gpi*gv.gpi/gv.gpipi;
      pv:=-pd*d*d;
      vtt:=gv.R*gv.pi/gv.p*gv.tau/T*gv.tau*gv.gpitautau;
      vtp:=gv.R*pi2/p2*(gv.gpipi - gv.tau*gv.gpipitau);
      vpp:=gv.R*T*pi2*gv.pi/(p2*gv.p)*gv.gpipipi;
      vp3:=vp*vp*vp;
      ivp3:=1/vp3;
      cpt:=gv.R*gv.tau*gv.tau/T*(2*gv.gtautau + gv.tau*gv.gtautautau);
      cvt:=(vp3*cpt + vp*vp*vt*vt + 3.0*vp*vp*T*vt*vtt - 3.0*vtp*vp*T*vt*vt + T*vt*vt*vt*vpp)*ivp3;
      dvsat.pt:=ptt*tp*P_der;
      dvsat.cv:=cvt*tp*P_der;
      dvsat.cp:=(cvt*tp + vp*dpT + ((v*pv + T*dpT)*vtp + (vp*pv + tp*dpT)*vt))*P_der;
      dvsat.h:=(v - T*vt)*P_der + cp/dpT*P_der;
      dvsat.rho:=-d*d*(vp + vt/dpT)*P_der;
      dvsat.T:=tp*P_der;
      dvsat.P:=P_der;
      annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Text(lineColor={0,0,255}, extent={{-134,104},{142,44}}, textString="%name"),Ellipse(extent={{-100,40},{100,-100}}, fillPattern=FillPattern.Solid, lineColor={255,127,0}, fillColor={255,255,255}),Text(lineColor={0,0,255}, extent={{-84,-4},{84,-52}}, textString="fonction", fillColor={255,127,0})}), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
    end Water_sat_P_der;

    function SpecificEnthalpy_PT_der
      input ThermoSysPro.Units.AbsolutePressure p "pressure";
      input ThermoSysPro.Units.AbsoluteTemperature T "Temperature";
      input Integer mode=0 "Région IF97 - 0:calcul automatique";
      input Real p_der "Pression";
      input Real T_der "Température";
      output Real H "specific enthalpy";
    protected
      Integer region;
      Boolean supercritical;
      Integer error;
      Modelica.SIunits.SpecificHeatCapacity R "gas constant";
      Modelica.SIunits.SpecificHeatCapacity cp "specific heat capacity";
      Modelica.SIunits.SpecificHeatCapacity cv "specific heat capacity";
      Modelica.SIunits.Density rho "density";
      ThermoSysPro.Units.DerPressureByTemperature pt "derivative of pressure wrt temperature";
      ThermoSysPro.Units.DerPressureByDensity pd "derivative of pressure wrt density";
      Real vt "derivative of specific volume w.r.t. temperature";
      ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs g "dimensionless Gibbs funcion and dervatives wrt pi and tau";
      ThermoSysPro.Properties.WaterSteam.Common.HelmholtzDerivs f "dimensionless Helmholtz funcion and dervatives wrt delta and tau";
      Real rho2;
    algorithm
      supercritical:=p > ThermoSysPro.Properties.WaterSteam.BaseIF97.data.PCRIT;
      region:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.region_pT(p, T, mode);
      R:=ThermoSysPro.Properties.WaterSteam.BaseIF97.data.RH2O;
      if region == 1 then
        g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g1(p, T);
        rho:=p/(R*T*g.pi*g.gpi);
        vt:=R/p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
        cp:=-R*g.tau*g.tau*g.gtautau;
        H:=(1/rho - T*vt)*p_der + cp*T_der;
      elseif region == 2 then
        g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g2(p, T);
        rho:=p/(R*T*g.pi*g.gpi);
        vt:=R/p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
        cp:=-R*g.tau*g.tau*g.gtautau;
        H:=(1/rho - T*vt)*p_der + cp*T_der;

      elseif region == 3 then
        (rho,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.dofpt3(p, T, delp=1e-07);
        rho2:=rho*rho;
        f:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3(rho, T);
        pd:=R*T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
        pt:=R*rho*f.delta*(f.fdelta - f.tau*f.fdeltatau);
        cv:=R*(-f.tau*f.tau*f.ftautau);
        H:=1/(rho2*pd)*((-rho*pd + T*pt)*p_der + (rho2*pd*cv + T*pt*p)*T_der);

      elseif region == 5 then
        g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g5(p, T);
        rho:=p/(R*T*g.pi*g.gpi);
        vt:=R/p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
        cp:=-R*g.tau*g.tau*g.gtautau;
        H:=(1/rho - T*vt)*p_der + cp*T_der;
      else
        assert(false, "Water_pT_der: error in region computation of IF97 steam tables" + "(p = " + String(p) + ", T = " + String(T) + ", region = " + String(region) + ")");
      end if;
      annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Text(lineColor={0,0,255}, extent={{-134,104},{142,44}}, textString="%name"),Ellipse(extent={{-100,40},{100,-100}}, fillPattern=FillPattern.Solid, lineColor={255,127,0}, fillColor={255,255,255}),Text(lineColor={0,0,255}, extent={{-84,-4},{84,-52}}, textString="fonction", fillColor={255,127,0})}), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
    end SpecificEnthalpy_PT_der;

    package Unused "unused functions for which no analytic derivative can be provided"
      function Water_rhoT
        input Modelica.SIunits.Density rho "Masse volumique";
        input ThermoSysPro.Units.AbsoluteTemperature T "Température";
        input Integer phase "2: diphasique, 1 sinon";
        input Integer mode=0 "Région IF97 - 0:calcul automatique";
        output ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_dT pro;
      protected
        Integer region;
        Integer error;
        Boolean supercritical;
        ThermoSysPro.Units.AbsolutePressure p;
      protected
        ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs g annotation(extent=[-90,-85;-43.3333,-38.3333]);
        ThermoSysPro.Properties.WaterSteam.Common.HelmholtzDerivs f annotation(extent=[-23.3333,-85;23.3333,-38.3333]);
      algorithm
        region:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.region_dT(rho, T, phase, mode);
        if region == 1 then
          (p,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.pofdt125(d=rho, T=T, reldd=ThermoSysPro.Properties.WaterSteam.BaseIF97.IterationData.DELD, region=1);
          g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g1(p, T);
          supercritical:=p > ThermoSysPro.Properties.WaterSteam.BaseIF97.data.PCRIT;
          pro:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToProps_dT(g);
          pro.x:=if supercritical then -1 else 0;
        elseif region == 2 then
          (p,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.pofdt125(d=rho, T=T, reldd=ThermoSysPro.Properties.WaterSteam.BaseIF97.IterationData.DELD, region=2);
          g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g2(p, T);
          supercritical:=p > ThermoSysPro.Properties.WaterSteam.BaseIF97.data.PCRIT;
          pro:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToProps_dT(g);
          pro.x:=if supercritical then -1 else 1;

        elseif region == 3 then
          f:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3(rho, T);
          pro:=ThermoSysPro.Properties.WaterSteam.Common.helmholtzToProps_dT(f);
          pro.x:=if supercritical then -1 else 0;
          supercritical:=p > ThermoSysPro.Properties.WaterSteam.BaseIF97.data.PCRIT;

        elseif region == 4 then
          pro:=ThermoSysPro.Properties.WaterSteam.BaseIF97.TwoPhase.waterR4_dT(d=rho, T=T);

        elseif region == 5 then
          (p,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.pofdt125(d=rho, T=T, reldd=ThermoSysPro.Properties.WaterSteam.BaseIF97.IterationData.DELD, region=5);
          g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g5(p, T);
          supercritical:=p > ThermoSysPro.Properties.WaterSteam.BaseIF97.data.PCRIT;
          pro:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToProps_dT(g);
          pro.x:=if supercritical then -1 else 1;
        else
          assert(false, "Eau_rhoT: Numéro de région incorrect");
        end if;
        annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Text(lineColor={0,0,255}, extent={{-134,104},{142,44}}, textString="%name"),Ellipse(extent={{-100,40},{100,-100}}, fillPattern=FillPattern.Solid, lineColor={255,127,0}, fillColor={255,255,255}),Text(lineColor={0,0,255}, extent={{-84,-4},{84,-52}}, textString="fonction", fillColor={255,127,0}),Ellipse(extent={{-100,100},{-60,-100}}, lineColor={255,0,0}, fillColor={255,0,0}, fillPattern=FillPattern.Solid)}), Documentation(info="<html>
<p><b>Version 1.0</b></p>
</HTML>
"));
      end Water_rhoT;

      function Water_h_is
        input ThermoSysPro.Units.AbsolutePressure p;
        input Modelica.SIunits.SpecificEntropy s;
        input Integer phase;
        input Integer mode=0;
        output ThermoSysPro.Units.SpecificEnthalpy h;
      protected
        Integer region;
        Integer error;
        ThermoSysPro.Units.AbsoluteTemperature T;
        Modelica.SIunits.Density d;
      protected
        ThermoSysPro.Properties.WaterSteam.Common.HelmholtzData dTR(R=ThermoSysPro.Properties.WaterSteam.BaseIF97.data.RH2O) annotation(Placement(transformation(x=-50.0, y=50.0, scale=0.35, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
        ThermoSysPro.Properties.WaterSteam.Common.GibbsData pTR(R=ThermoSysPro.Properties.WaterSteam.BaseIF97.data.RH2O) annotation(Placement(transformation(x=50.0, y=50.0, scale=0.35, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
        ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs g annotation(extent=[-85,-85;-15,-15]);
        ThermoSysPro.Properties.WaterSteam.Common.HelmholtzDerivs f annotation(extent=[15,-85;85,-15]);
      algorithm
        region:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.region_ps(p, s, phase, mode);
        if region == 1 then
          h:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Isentropic.hofps1(p, s);
        elseif region == 2 then
          h:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Isentropic.hofps2(p, s);

        elseif region == 3 then
          (d,T,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.dtofps3(p=p, s=s, delp=1e-07, dels=1e-06);
          h:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Isentropic.hofdT3(d, T);

        elseif region == 4 then
          h:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Isentropic.hofps4(p, s);

        elseif region == 5 then
          (T,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.tofps5(p=p, s=s, relds=1e-07);
          h:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Isentropic.hofpT5(p, T);
        else
          assert(false, "Eau_H_is: Numéro de région incorrect");
        end if;
        annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Text(lineColor={0,0,255}, extent={{-134,104},{142,44}}, textString="%name"),Ellipse(extent={{-100,40},{100,-100}}, fillPattern=FillPattern.Solid, lineColor={255,127,0}, fillColor={255,255,255}),Text(lineColor={0,0,255}, extent={{-84,-4},{84,-52}}, textString="fonction", fillColor={255,127,0}),Ellipse(extent={{-100,100},{-60,-100}}, lineColor={255,0,0}, fillColor={255,0,0}, fillPattern=FillPattern.Solid)}), Documentation(info="<html>
<p><b>Version 1.4</b></p>
</HTML>
"));
      end Water_h_is;

    end Unused;

    annotation(Icon(coordinateSystem(extent={{0,0},{312,220}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-100,-100},{80,50}}, fillColor={235,235,235}, fillPattern=FillPattern.Solid),Polygon(lineColor={0,0,255}, points={{-100,50},{-80,70},{100,70},{80,50},{-100,50}}, fillColor={235,235,235}, fillPattern=FillPattern.Solid),Polygon(lineColor={0,0,255}, points={{100,70},{100,-80},{80,-100},{80,50},{100,70}}, fillColor={235,235,235}, fillPattern=FillPattern.Solid),Text(lineColor={0,0,255}, extent={{-90,40},{70,10}}, textString="Library", fillColor={160,160,160}),Rectangle(extent={{-32,-6},{16,-35}}, lineColor={0,0,0}),Rectangle(extent={{-32,-56},{16,-85}}, lineColor={0,0,0}),Line(points={{16,-20},{49,-20},{49,-71},{16,-71}}, color={0,0,0}),Line(points={{-32,-72},{-64,-72},{-64,-21},{-32,-21}}, color={0,0,0}),Text(lineColor={0,0,255}, extent={{-116,133},{124,68}}, textString="%name", fillColor={255,0,0})}), Documentation(info="<html>
<p><b>Version 1.2</b></p>
</HTML>
"));
    package Spline_Utilities
      constant Spline_Utilities.Modelica_Interpolation.Bspline1D.Data IF97_spline(ndim=1, ncontrol=100, degree=3, knots={2.93063160225403e-07,2.93063160225403e-07,2.93063160225403e-07,2.93063160225403e-07,0.0150553301018805,0.0225746360796844,0.0300841766610507,0.0375864719559614,0.0450833779282367,0.0525763026035424,0.0600663541987385,0.0675544420190098,0.0750413446792581,0.0825277558142009,0.0900143143696351,0.0975016244159301,0.104990267916964,0.11248081283071,0.119973818177067,0.127469837190213,0.134969419310924,0.14247311152242,0.149981459358957,0.157495007796453,0.165014302152702,0.172539889069826,0.180072317615317,0.187612140514708,0.195159915514515,0.202716206865773,0.21028158691427,0.217856637782066,0.225441953125109,0.233038139953034,0.240645820499176,0.248265634131007,0.255898239293619,0.26354431548115,0.271204565233372,0.278879716156774,0.286570522971491,0.294277769587339,0.302002271213962,0.309744876511783,0.317506469792076,0.325287973276035,0.333090349424309,0.340914603350119,0.348761785330786,0.356632993434437,0.364529376280738,0.372452135957019,0.380402531113975,0.388381880268579,0.39639156534589,0.404433035496425,0.412507811231662,0.420617488927502,0.42876374575417,0.436948345101518,0.445173142581185,0.453440092702033,0.461751256332929,0.470108809087968,0.478515050793845,0.486972416228223,0.495483487352128,0.50405100729972,0.512677896436249,0.521367270850924,0.53012246371707,0.538947050028345,0.547844875307676,0.556820088984304,0.565877183242573,0.575021038260507,0.584256974874285,0.593590815826759,0.603028956896544,0.612578449397273,0.622247095874125,0.632043561486359,0.641977504873387,0.652059734791795,0.662302403295546,0.672719253852374,0.6833259549907,0.694140568427125,0.705184226398132,0.716482126202646,0.728064988229839,0.739971159691273,0.752249564928059,0.764963678571606,0.77819659006882,0.79205900502822,0.806726369054731,0.822437269975835,0.839573763094594,0.858852425095749,1,1,1,1}, controlPoints=[6.41617166788097;6.59657375859249;6.85956502478188;7.19550228677957;7.44003141655459;7.67746343199683;7.90809030002524;8.1321863948823;8.35001072138466;8.56180824123764;8.76781112389037;8.96823977601129;9.16330374171574;9.35320248746118;9.53812609634101;9.71825588651749;9.89376496619584;10.064818734583;10.2315753364618;10.394186076569;10.552795798896;10.7075432351955;10.8585613263155;11.0059775194514;11.1499140439677;11.2904881680785;11.427812438369;11.561994903882;11.6931393262684;11.8213453773153;11.9467088249962;12.0693217090492;12.1892725069664;12.3066462911727;12.421524878079;12.5339869696189;12.644108287808;12.7519617028068;12.8576173549182;12.9611427709053;13.06260297498;13.1620605947781;13.25957596261;13.355207212251;13.4490103715159;13.5410394508422;13.6313465280923;13.7199818297721;13.8069938088494;13.892429219348;13.9763331878828;14.0587492822951;14.1397195775398;14.2192847189711;14.297483983169;14.3743553364442;14.4499354911556;14.524259959973;14.5973631082143;14.6692782043857;14.740037469051;14.8096721221595;14.8782124289575;14.9456877446163;15.0121265577065;15.0775565326579;15.1420045513451;15.2054967539465;15.2680585792283;15.3297148044048;15.3904895847271;15.4504064929423;15.5094885587568;15.5677583084284;15.6252378046292;15.6819486867911;15.7379122123276;15.7931492995096;15.8476805734722;15.9015264179811;15.9547070373259;16.0072425350593;16.0591530191528;16.11045874587;16.1611803164475;16.211338938197;16.2609567565343;16.3100572327281;16.3586655540358;16.4068088127073;16.4545163733577;16.501817689937;16.5487496364798;16.5953631575021;16.6418467771832;16.6879750106034;16.7343150270632;16.8752144692458;16.9266730020941;16.9094578790152]);
      record Data "Datastructure of a Bspline"
        parameter Integer ndim(min=1) "Number of dimensions of one control point";
        parameter Integer ncontrol(min=1) "Number of control points";
        parameter Integer degree(min=1) "Polynomial degree of the Bspline";
        Real knots[ncontrol + degree + 1] "Knot vector of the Bspline";
        Real controlPoints[ncontrol,ndim] "[i,:] is data of control point i";
      end Data;

      function safeEvaluate "Evaluate Bspline at one parameter safely, i.e. points outside the domain of the spline are moved inside the domain."
        extends Modelica.Icons.Function;
        input Data spline "Bspline to be evaluated";
        input Real u "Parameter value at which Bspline shall be evaluated";
        output Real x[spline.ndim] "Value of Bspline at u";
      protected
        Real eps=1e-10 "accurate enough?";
        Real umin=spline.knots[1] + eps*abs(spline.knots[1]);
        Real umax=spline.knots[end] - eps*abs(spline.knots[end]);
        Real ulim;
      algorithm
        ulim:=min(max(u, umin), umax);
        x:=ThermoSysPro.Properties.WaterSteam.IF97_packages.IF97_wAJ.Spline_Utilities.evaluate(spline, ulim);
      end safeEvaluate;

      function safeEvaluateDer "Evaluate Bspline at one parameter safely, i.e. points outside the domain of the spline are moved inside the domain."
        extends Modelica.Icons.Function;
        input Data spline "Bspline to be evaluated";
        input Real u "Parameter value at which Bspline shall be evaluated";
        output Real x[spline.ndim] "Value of Bspline at u";
        output Real xd[spline.ndim] "First derivative of Bspline at u";
      protected
        Real eps=1e-10 "accurate enough?";
        Real umin=spline.knots[1] + eps*abs(spline.knots[1]);
        Real umax=spline.knots[end] - eps*abs(spline.knots[end]);
        Real ulim;
      algorithm
        ulim:=min(max(u, umin), umax);
        (x,xd):=evaluateDer(spline, ulim);
      end safeEvaluateDer;

      function evaluate "Evaluate Bspline at one parameter"
        extends Modelica.Icons.Function;
        input Data spline "Bspline to be evaluated";
        input Real u "Parameter value at which Bspline shall be evaluated";
        output Real x[spline.ndim] "Value of Bspline at u";
      protected
        Integer span;
        Real N[spline.degree + 1];
      algorithm
        x:=zeros(spline.ndim);
        span:=Utilities.n_findSpan(spline.degree, u, spline.knots);
        N:=Utilities.n_BasisFuns(span, u, spline.degree, spline.knots);
        for i in 1:spline.ndim loop
          x[i]:=N*spline.controlPoints[span - spline.degree:span,i];
        end for;
      end evaluate;

      function evaluateDer "Evaluate Bspline and its first derivative at one parameter"
        extends Modelica.Icons.Function;
        input Data spline "Bspline to be evaluated";
        input Real u "Parameter value at which Bspline shall be evaluated";
        output Real x[spline.ndim] "Value of Bspline at u";
        output Real xd[spline.ndim] "First derivative of Bspline at u";
      protected
        Integer span;
        Real N[2,spline.degree + 1];
      algorithm
        x:=zeros(spline.ndim);
        xd:=zeros(spline.ndim);
        span:=Utilities.n_findSpan(spline.degree, u, spline.knots);
        N:=Utilities.n_DersBasisFuns(span, u, spline.degree, 1, spline.knots);
        for i in 1:spline.ndim loop
          x[i]:=N[1,:]*spline.controlPoints[span - spline.degree:span,i];
          xd[i]:=N[2,:]*spline.controlPoints[span - spline.degree:span,i];
        end for;
      end evaluateDer;

      package Utilities "spline utility functions"
        function n_BasisFuns "Compute the nonvanishing basis functions"
          extends Modelica.Icons.Function;
          input Integer i "index";
          input Real u "parameter";
          input Integer p "degree";
          input Real knots[:] "knot vector";
          output Real N[p + 1] "Basis functions";
        protected
          Integer j;
          Integer r;
          Real left[p + 1];
          Real right[p + 1];
          Real temp;
          Real saved;
        algorithm
          N[1]:=1;
          for j in 1:p loop
            left[j]:=u - knots[i + 1 - j];
            right[j]:=knots[i + j] - u;
            saved:=0.0;
            for r in 1:j loop
              temp:=N[r]/(right[r] + left[j - r + 1]);
              N[r]:=saved + right[r]*temp;
              saved:=left[j - r + 1]*temp;
            end for;
            N[j + 1]:=saved;
          end for;
        end n_BasisFuns;

        function n_DersBasisFuns "Compute nonzero basis functions and their derivatives"
          extends Modelica.Icons.Function;
          input Integer i "index";
          input Real u "parameter";
          input Integer p "degree";
          input Integer n "n-th derivative";
          input Real knots[:] "knot vector";
          output Real ders[n + 1,p + 1] "ders[k,:] is (k-1)-th derivative";
        protected
          Integer j;
          Integer r;
          Real left[p + 1];
          Real right[p + 1];
          Real temp;
          Real saved;
          Real ndu[p + 1,p + 1];
          Integer s1;
          Integer s2;
          Integer j1;
          Integer j2;
          Real a[2,p + 1];
          Real d;
          Integer rk;
          Integer pk;
          Integer prod;
          Integer tt;
        algorithm
          ndu[1,1]:=1;
          for j in 1:p loop
            left[j]:=u - knots[i + 1 - j];
            right[j]:=knots[i + j] - u;
            saved:=0.0;
            for r in 1:j loop
              ndu[j + 1,r]:=right[r] + left[j - r + 1];
              temp:=ndu[r,j]/ndu[j + 1,r];
              ndu[r,j + 1]:=saved + right[r]*temp;
              saved:=left[j - r + 1]*temp;
            end for;
            ndu[j + 1,j + 1]:=saved;
          end for;
          for j in 1:p + 1 loop
            ders[1,j]:=ndu[j,p + 1];
          end for;
          for r in 1:p + 1 loop
            s1:=1;
            s2:=2;
            a[1,1]:=1.0;
            for k in 1:n loop
              d:=0.0;
              rk:=r - k - 1;
              pk:=p - k;
              if r - 1 >= k then
                a[s2,1]:=a[s1,1]/ndu[pk + 2,rk + 1];
                d:=a[s2,1]*ndu[rk + 1,pk + 1];
              end if;
              if rk >= -1 then
                j1:=1;
              else
                j1:=-rk;
              end if;
              if r - 1 <= pk + 1 then
                j2:=k - 1;
              else
                j2:=p - r + 1;
              end if;
              for j in j1:j2 loop
                a[s2,j + 1]:=(a[s1,j + 1] - a[s1,j])/ndu[pk + 2,rk + j + 1];
                d:=d + a[s2,j + 1]*ndu[rk + j + 1,pk + 1];
              end for;
              if r - 1 <= pk then
                a[s2,k + 1]:=-a[s1,k]/ndu[pk + 2,r];
                d:=d + a[s2,k + 1]*ndu[r,pk + 1];
              end if;
              ders[k + 1,r]:=d;
              tt:=s1;
              s1:=s2;
              s2:=tt;
            end for;
          end for;
          prod:=p;
          for k in 1:n loop
            for j in 1:p + 1 loop
              ders[k + 1,j]:=ders[k + 1,j]*prod;
            end for;
            prod:=prod*(p - k);
          end for;
        end n_DersBasisFuns;

        function n_findSpan "Determine the knot span index"
          extends Modelica.Icons.Function;
          input Integer p "degree";
          input Real u "parameter";
          input Real knots[:] "knot vector";
          output Integer i "The knot span index";
        protected
          Integer n;
          Integer low;
          Integer high;
          Integer mid;
        algorithm
          n:=size(knots, 1) - p - 1;
          if abs(u - knots[n + 1]) < 1e-11 then
            i:=n;
          elseif abs(u - knots[1]) < 1e-11 then
            i:=1;
          else
            low:=p;
            high:=n + 1;
            mid:=integer((low + high)/2);
            while (u < knots[mid] or u >= knots[mid + 1]) loop
              assert(low + 1 < high, "Value must be within limits for Utilities.n_findSpan");
              if u < knots[mid] then
                high:=mid;
              else
                low:=mid;
              end if;
              mid:=integer((low + high)/2);
            end while;
            i:=mid;
          end if;
        end n_findSpan;

      end Utilities;

      function linspace "Returns a vector with linear spacing"
        input Real min;
        input Real max;
        input Integer npoints;
        output Real[npoints] res;
      protected
        Real delta;
      algorithm
        res[1]:=min;
        res[end]:=max;
        delta:=(max - min)/npoints;
        for i in 2:npoints - 1 loop
          res[i]:=res[i - 1] + delta;
        end for;
      end linspace;

      function dumpOneSpline "Write Modelica.Interpolation.Bspline1D.Data to file as record (not finished)."
        import Util = Modelica.Utilities;
        input String fileName "file name";
        input String splineName "Name of the spline in the array of records.";
        input ThermoSysPro.Properties.WaterSteam.IF97_packages.IF97_wAJ.Spline_Utilities.Modelica_Interpolation.Bspline1D.Data spline "Data.";
        input Boolean lastSpline=false;
        output Boolean status "true if succesful.";
      protected
        constant Integer recordsPerLine=4;
        Integer nKnots;
        Integer n;
        Integer nLeftovers;
      algorithm
        assert(spline.ndim == 1, "Bailing out - spline.ndim != 1");
        Util.Streams.print("record IF97_spline = ThermoSysPro_addon.IF97.SplineUtilities.Modelica_Interpolation.Bspline1D.Data(", fileName);
        Util.Streams.print("    ndim = " + integerString(spline.ndim) + ",", fileName);
        Util.Streams.print("    ncontrol = " + integerString(spline.ncontrol) + ",", fileName);
        Util.Streams.print("    degree = " + integerString(spline.degree) + ",", fileName);
        nKnots:=size(spline.knots, 1);
        Util.Streams.print("    knots = {", fileName);
        n:=integer(nKnots/recordsPerLine);
        nLeftovers:=nKnots - n*recordsPerLine;
        if nLeftovers == 0 then
          for j in 1:n - 1 loop
            Util.Streams.print("    " + String(spline.knots[recordsPerLine*j - 3], significantDigits=15) + ", " + String(spline.knots[recordsPerLine*j - 2], significantDigits=15) + ", " + String(spline.knots[recordsPerLine*j - 1], significantDigits=15) + ", " + String(spline.knots[recordsPerLine*j], significantDigits=15) + ",", fileName);
          end for;
          Util.Streams.print("    " + String(spline.knots[nKnots - 3], significantDigits=15) + ", " + String(spline.knots[nKnots - 2], significantDigits=15) + ", " + String(spline.knots[nKnots - 1], significantDigits=15) + ", " + String(spline.knots[nKnots], significantDigits=15), fileName);
        else
          for j in 1:n loop
            Util.Streams.print("    " + String(spline.knots[recordsPerLine*j - 3], significantDigits=15) + ", " + String(spline.knots[recordsPerLine*j - 2], significantDigits=15) + ", " + String(spline.knots[recordsPerLine*j - 1], significantDigits=15) + ", " + String(spline.knots[recordsPerLine*j], significantDigits=15) + ",", fileName);
          end for;
          if nLeftovers == 3 then
            Util.Streams.print("    " + String(spline.knots[nKnots - 2], significantDigits=15) + ", " + String(spline.knots[nKnots - 1], significantDigits=15) + ", " + String(spline.knots[nKnots], significantDigits=15), fileName);
          elseif nLeftovers == 2 then
            Util.Streams.print("    " + String(spline.knots[nKnots - 1], significantDigits=15) + ", " + String(spline.knots[nKnots], significantDigits=15), fileName);

          elseif nLeftovers == 1 then
            Util.Streams.print("    " + String(spline.knots[nKnots], significantDigits=15), fileName);
          end if;
        end if;
        Util.Streams.print("    },", fileName);
        Util.Streams.print("    controlPoints = [", fileName);
        n:=integer(spline.ncontrol/recordsPerLine);
        nLeftovers:=spline.ncontrol - n*recordsPerLine;
        if nLeftovers == 0 then
          for j in 1:n - 1 loop
            Util.Streams.print("    " + String(spline.controlPoints[recordsPerLine*j - 3,1], significantDigits=15) + "; " + String(spline.controlPoints[recordsPerLine*j - 2,1], significantDigits=15) + "; " + String(spline.controlPoints[recordsPerLine*j - 1,1], significantDigits=15) + "; " + String(spline.controlPoints[recordsPerLine*j,1], significantDigits=15) + ";", fileName);
          end for;
          Util.Streams.print("    " + String(spline.controlPoints[spline.ncontrol - 3,1], significantDigits=15) + "; " + String(spline.controlPoints[spline.ncontrol - 2,1], significantDigits=15) + "; " + String(spline.controlPoints[spline.ncontrol - 1,1], significantDigits=15) + "; " + String(spline.controlPoints[spline.ncontrol,1], significantDigits=15), fileName);
        else
          for j in 1:n loop
            Util.Streams.print("    " + String(spline.controlPoints[recordsPerLine*j - 3,1], significantDigits=15) + "; " + String(spline.controlPoints[recordsPerLine*j - 2,1], significantDigits=15) + "; " + String(spline.controlPoints[recordsPerLine*j - 1,1], significantDigits=15) + "; " + String(spline.controlPoints[recordsPerLine*j,1], significantDigits=15) + ";", fileName);
          end for;
          if nLeftovers == 3 then
            Util.Streams.print("    " + String(spline.controlPoints[spline.ncontrol - 2,1], significantDigits=15) + "; " + String(spline.controlPoints[spline.ncontrol - 1,1], significantDigits=15) + "; " + String(spline.controlPoints[spline.ncontrol,1], significantDigits=15), fileName);
          elseif nLeftovers == 2 then
            Util.Streams.print("    " + String(spline.controlPoints[spline.ncontrol - 1,1], significantDigits=15) + "; " + String(spline.controlPoints[spline.ncontrol,1], significantDigits=15), fileName);

          elseif nLeftovers == 1 then
            Util.Streams.print("    " + String(spline.controlPoints[spline.ncontrol,1], significantDigits=15), fileName);
          end if;
        end if;
        if lastSpline then
          Util.Streams.print("    ])", fileName);
        else
          Util.Streams.print("    ]),", fileName);
        end if;
        Util.Streams.print("end IF97_spline;", fileName);
        status:=true;
        annotation();
      end dumpOneSpline;

      package Modelica_Interpolation
        package Table1D "Table interpolation in one dimension"
          extends Modelica.Icons.Library;
          function init "Initialize 1-dim. table interpolation"
            extends Modelica.Icons.Function;
            input Real table[:,:] "[x, y1(x), y2(x), ..., yn(x)] data points";
            input Integer degree(min=1)=1 "Polynomial degree of interpolation";
            output Bspline1D.Data tableSpline(ndim=size(table, 2) - 1, ncontrol=size(table, 1), degree=degree) "Table data in a form which can be quickly interpolated";
          protected
            Integer nknots=size(tableSpline.knots, 1);
            Integer ndim=size(table, 2);
          algorithm
            tableSpline:=Bspline1D.init(table[:,2:ndim], table[:,1], degree, false);
          end init;

          function evaluate "Evaluate Table data at one parameter"
            extends Modelica.Icons.Function;
            input Bspline1D.Data tableSpline "Bspline table to be evaluated";
            input Real x "Parameter value at which table shall be evaluated";
            output Real y[tableSpline.ndim] "Value of table at x";
          algorithm
            y:=Bspline1D.evaluate(tableSpline, x);
          end evaluate;

          function evaluateDer "Evaluate Table data and first derivative at one parameter"
            extends Modelica.Icons.Function;
            input ThermoSysPro.Properties.WaterSteam.IF97_packages.IF97_wAJ.Spline_Utilities.Modelica_Interpolation.Bspline1D.Data tableSpline "Bspline table to be evaluated";
            input Real x "Parameter value at which the table shall be evaluated";
            output Real y[tableSpline.ndim] "Value of the table at x";
            output Real yd[tableSpline.ndim] "Value of the first derivative at x";
          algorithm
            (y,yd):=Bspline1D.evaluateDer(tableSpline, x);
          end evaluateDer;

          function evaluateDer2 "Evaluate Table data and first and second derivative at one parameter"
            extends Modelica.Icons.Function;
            input Bspline1D.Data tableSpline "Bspline table to be evaluated";
            input Real x "Parameter value at which the table shall be evaluated";
            output Real y[tableSpline.ndim] "Value of the table at x";
            output Real yd[tableSpline.ndim] "Value of the first derivative at x";
            output Real ydd[tableSpline.ndim] "Value of the second derivative at x";
          algorithm
            (y,yd,ydd):=Bspline1D.evaluateDer2(tableSpline, x);
          end evaluateDer2;

          annotation(Documentation(info="With this package interpolation with B-Splines
of 1-dim. tables is provided."));
        end Table1D;

        package Bspline1D "1-dimensional Bspline interpolation"
          extends Modelica.Icons.Library;
          record Data "Datastructure of a Bspline"
            Integer ndim(min=1) "Number of dimensions of one control point";
            Integer ncontrol(min=1) "Number of control points";
            Integer degree(min=1) "Polynomial degree of the Bspline";
            Real knots[ncontrol + degree + 1] "Knot vector of the Bspline";
            Real controlPoints[ncontrol,ndim] "[i,:] is data of control point i";
          end Data;

          record ParametrizationType "will be later replaced by enumeration"
            constant Integer Equidistant=1 "not recommended";
            constant Integer ChordLength=2;
            constant Integer Centripetal=3 "recommended";
            constant Integer Foley=4;
            constant Integer Angular=5;
            constant Integer AreaBased=6;
          end ParametrizationType;

          annotation(Documentation(info="<HTML>
<p>
With this package 1-dimensional interpolation with B-Splines
is performed.
</p>
<p>
The following functions are supported:
</p>
<pre>
  init          Initialize interpolation
  initDer       Initialize interpolation (points and first derivatives are given)
  evaluate      Determine data at one point by interpolation
  evaluateDer   Determine data and first derivative at one point by interpolation
  evaluateDer2  Determine data, first and second derivative at one point by interpolation
  evaluateDerN  Determine the n-th derivative at one point by interpolation
  plot          Compute all data needed to make a nice plot of the data and plot it
                (since in Dymola plotArray cannot be called in a function, currently
                just the plot data is computed and returned. In a calling script
                this data can be used to plot it with operator plotArray).
</pre>
<p><b>Release Notes:</b></p>
<ul>
<li><i>Sept. 13, 2002</i>
       by Gerhard Schillhuber:<br>
       first version implemented
</li>
</ul>
<br>
<p><b>Copyright (C) 2002, Modelica Association and DLR.</b></p>
<p><i>
This package is <b>free</b> software. It can be redistributed and/or modified
under the terms of the <b>Modelica license</b>, see the license conditions
and the accompanying <b>disclaimer</b> in the documentation of package
Modelica in file \"Modelica/package.mo\".
</i></p>
</HTML>
"));
          function evaluate "Evaluate Bspline at one parameter"
            extends Modelica.Icons.Function;
            input Data spline "Bspline to be evaluated";
            input Real u "Parameter value at which Bspline shall be evaluated";
            output Real x[spline.ndim] "Value of Bspline at u";
          protected
            Integer span;
            Real N[spline.degree + 1];
          algorithm
            x:=zeros(spline.ndim);
            span:=Utilities.n_findSpan(spline.degree, u, spline.knots);
            N:=Utilities.n_BasisFuns(span, u, spline.degree, spline.knots);
            for i in 1:spline.ndim loop
              x[i]:=N*spline.controlPoints[span - spline.degree:span,i];
            end for;
          end evaluate;

          function evaluateDer "Evaluate Bspline and its first derivative at one parameter"
            extends Modelica.Icons.Function;
            input Data spline "Bspline to be evaluated";
            input Real u "Parameter value at which Bspline shall be evaluated";
            output Real x[spline.ndim] "Value of Bspline at u";
            output Real xd[spline.ndim] "First derivative of Bspline at u";
          protected
            Integer span;
            Real N[2,spline.degree + 1];
          algorithm
            x:=zeros(spline.ndim);
            xd:=zeros(spline.ndim);
            span:=Utilities.n_findSpan(spline.degree, u, spline.knots);
            N:=Utilities.n_DersBasisFuns(span, u, spline.degree, 1, spline.knots);
            for i in 1:spline.ndim loop
              x[i]:=N[1,:]*spline.controlPoints[span - spline.degree:span,i];
              xd[i]:=N[2,:]*spline.controlPoints[span - spline.degree:span,i];
            end for;
          end evaluateDer;

          function evaluateDer2 "Evaluate Bspline and its first and second derivatives at one parameter"
            extends Modelica.Icons.Function;
            input Data spline "Bspline to be evaluated";
            input Real u "Parameter value at which Bspline shall be evaluated";
            output Real x[spline.ndim] "Value of Bspline at u";
            output Real xd[spline.ndim] "First derivative of Bspline at u";
            output Real xdd[spline.ndim] "Second derivative of Bspline at u";
          protected
            Integer span;
            Real N[3,spline.degree + 1];
          algorithm
            x:=zeros(spline.ndim);
            xd:=zeros(spline.ndim);
            xdd:=zeros(spline.ndim);
            span:=Utilities.n_findSpan(spline.degree, u, spline.knots);
            N:=Utilities.n_DersBasisFuns(span, u, spline.degree, 2, spline.knots);
            for i in 1:spline.ndim loop
              x[i]:=N[1,:]*spline.controlPoints[span - spline.degree:span,i];
              xd[i]:=N[2,:]*spline.controlPoints[span - spline.degree:span,i];
              xdd[i]:=N[3,:]*spline.controlPoints[span - spline.degree:span,i];
            end for;
          end evaluateDer2;

          function evaluateDerN "Evaluate k-th derivative of Bspline at one parameter"
            extends Modelica.Icons.Function;
            input Data spline "Bspline to be evaluated";
            input Real u "Parameter value at which Bspline shall be evaluated";
            input Integer k(min=0) "Differentation order (0: function value, 1: first derivative, ...)";
            output Real x_derN[spline.ndim] "k-th derivative of Bspline at u";
          protected
            Integer span;
            Real N[k + 1,spline.degree + 1];
          algorithm
            x_derN:=zeros(spline.ndim);
            span:=Utilities.n_findSpan(spline.degree, u, spline.knots);
            N:=Utilities.n_DersBasisFuns(span, u, spline.degree, k, spline.knots);
            for i in 1:spline.ndim loop
              x_derN[i]:=N[k + 1,:]*spline.controlPoints[span - spline.degree:span,i];
            end for;
          end evaluateDerN;

          function init "Initialize Bspline (end conditions are automatically selected, see docu)"
            extends Modelica.Icons.Function;
            input Real points[:,:] "[i,:] is point i on the curve to be interpolated";
            input Real param[size(points, 1)] "parameterization of the data points (not necessarily in the range 0..1)";
            input Integer degree(min=1)=3 "Polynomial degree of interpolation (max number of points -1)";
            input Boolean Bessel=true "If true and degree=3, Bessel end condition is used";
            output Data spline(ndim=size(points, 2), ncontrol=if Bessel and degree == 3 then size(points, 1) + 2 else size(points, 1), degree=degree) "Bspline in a form which can be quickly interpolated";
          protected
            Integer nknots=size(spline.knots, 1);
            Integer ndim=size(points, 2);
          algorithm
            if degree == 3 and Bessel then
              spline:=ThermoSysPro.Properties.WaterSteam.IF97_packages.IF97_wAJ.Spline_Utilities.Modelica_Interpolation.Bspline1D.Utilities.interpolationBessel(points, param);
            else
              spline:=ThermoSysPro.Properties.WaterSteam.IF97_packages.IF97_wAJ.Spline_Utilities.Modelica_Interpolation.Bspline1D.Utilities.interpolation(points, param, degree);
            end if;
          end init;

          function initDer "Initialize Bspline which interpolates the points and first derivatives"
            extends Modelica.Icons.Function;
            input Real points[:,:] "[i,:] is point i on the curve to be interpolated";
            input Real derivs[size(points, 1),size(points, 2)] "derivs[i,:] is the derivative at points[i,:]";
            input Real param[size(points, 1)] "parameterization of the data points (not necessarily in the range 0..1)";
            input Integer degree(min=2)=3 "Polynomial degree of interpolation (max: number of points -1)
    at the moment degree=3 is supported";
            output Data spline(ndim=size(points, 2), ncontrol=2*size(points, 1), degree=degree) "Bspline in a form which can be quickly interpolated";
          protected
            Integer nknots=size(spline.knots, 1);
            Integer ndim=size(points, 2);
          algorithm
            spline:=Utilities.interpolationder(points, derivs, param, degree);
          end initDer;

          function parametrization "Automatic parameterization of a Bspline in the range 0..1 (if ndim > 1)"
            extends Modelica.Icons.Function;
            input Real points[:,:] "[i,:] is point i on the curve to be interpolated";
            input Integer paramType=ParametrizationType.Centripetal "type of parametrization";
            output Real param[size(points, 1)] "parametrization of the data points";
          protected
            Real pi=3.141592653589;
            Integer i;
            Integer n_points;
            Real d;
            Real d_1[size(points, 2)];
            Real d_2[size(points, 2)];
            Real d_3[size(points, 2)];
            Real phi_1;
            Real phi_2;
            Real lambda;
            Real nu;
          algorithm
            n_points:=size(points, 1);
            if paramType == ParametrizationType.Equidistant then
              param:=ThermoSysPro.Properties.WaterSteam.IF97_packages.IF97_wAJ.Spline_Utilities.linspace(0, 1, size(points, 1));
            elseif paramType == ParametrizationType.ChordLength then
              param[1]:=0;
              for i in 2:n_points loop
                d:=Utilities.norm(points[i,:] - points[i - 1,:]);
                param[i]:=param[i - 1] + d;
              end for;
              param:=param/param[n_points];

            elseif paramType == ParametrizationType.Centripetal then
              param[1]:=0;
              for i in 2:n_points loop
                d:=Utilities.norm(points[i,:] - points[i - 1,:]);
                param[i]:=param[i - 1] + sqrt(d);
              end for;
              param:=param/param[n_points];

            elseif paramType == ParametrizationType.Foley then
              param[1]:=0;
              d_2:=points[2,:] - points[1,:];
              d_3:=points[3,:] - points[2,:];
              phi_2:=min(pi - acos(d_2*d_3/(Utilities.norm(d_2)*Utilities.norm(d_3))), pi/2);
              d:=Utilities.norm(d_2)*(1 + 3/2*phi_2*Utilities.norm(d_3)/(Utilities.norm(d_2) + Utilities.norm(d_3)));
              param[2]:=param[1] + d;
              for i in 3:n_points - 1 loop
                d_1:=points[i - 1,:] - points[i - 2,:];
                d_2:=points[i,:] - points[i - 1,:];
                d_3:=points[i + 1,:] - points[i,:];
                phi_1:=min(pi - acos(d_1*d_2/(Utilities.norm(d_1)*Utilities.norm(d_2))), pi/2);
                phi_2:=min(pi - acos(d_2*d_3/(Utilities.norm(d_2)*Utilities.norm(d_3))), pi/2);
                d:=Utilities.norm(d_2)*(1 + 3/2*phi_1*Utilities.norm(d_1)/(Utilities.norm(d_1) + Utilities.norm(d_2)) + 3/2*phi_2*Utilities.norm(d_3)/(Utilities.norm(d_2) + Utilities.norm(d_3)));
                param[i]:=param[i - 1] + d;
              end for;
              d_1:=points[n_points - 1,:] - points[n_points - 2,:];
              d_2:=points[n_points,:] - points[n_points - 1,:];
              phi_1:=min(pi - acos(d_1*d_2/(Utilities.norm(d_1)*Utilities.norm(d_2))), pi/2);
              d:=Utilities.norm(d_2)*(1 + 3/2*phi_1*Utilities.norm(d_1)/(Utilities.norm(d_1) + Utilities.norm(d_2)));
              param[n_points]:=param[n_points - 1] + d;
              param:=param/param[n_points];

            elseif paramType == ParametrizationType.Angular then
              param[1]:=0;
              lambda:=1.5;
              for i in 2:n_points - 1 loop
                d_1:=points[i,:] - points[i - 1,:];
                d_2:=points[i + 1,:] - points[i,:];
                phi_1:=acos(d_1*d_2/(Utilities.norm(d_1)*Utilities.norm(d_2)));
                d:=sqrt(Utilities.norm(d_1))*(1 + lambda*phi_1/pi);
                param[i]:=param[i - 1] + d;
              end for;
              d_1:=points[n_points - 2,:] - points[n_points - 1,:];
              d_2:=points[n_points - 1,:] - points[n_points,:];
              phi_1:=acos(d_2*d_1/(Utilities.norm(d_1)*Utilities.norm(d_2)));
              d:=sqrt(Utilities.norm(d_2))*(1 + lambda*phi_1/pi);
              param[n_points]:=param[n_points - 1] + d;
              param:=param/param[n_points];

            elseif paramType == ParametrizationType.AreaBased then
              lambda:=2/3;
              nu:=0.3;
              param[1]:=0;
              d_2:=points[2,:] - points[1,:];
              d_3:=points[3,:] - points[2,:];
              phi_2:=max(acos((-d_2*d_3)/(Utilities.norm(d_2)*Utilities.norm(d_3))), pi/2);
              d:=nu*Utilities.norm(d_2) + (1 - nu)*(sin(phi_2)*Utilities.norm(d_3))/Utilities.norm(d_3);
              param[2]:=param[1] + d;
              for i in 3:n_points - 1 loop
                d_1:=points[i - 1,:] - points[i - 2,:];
                d_2:=points[i,:] - points[i - 1,:];
                d_3:=points[i + 1,:] - points[i,:];
                phi_1:=max(acos((-d_1*d_2)/(Utilities.norm(d_1)*Utilities.norm(d_2))), pi/2);
                phi_2:=max(acos((-d_2*d_3)/(Utilities.norm(d_2)*Utilities.norm(d_3))), pi/2);
                d:=lambda*Utilities.norm(d_2) + (1 - lambda)*(sin(phi_1)*Utilities.norm(d_1) + sin(phi_2)*Utilities.norm(d_3))/(Utilities.norm(d_1) + Utilities.norm(d_3));
                param[i]:=param[i - 1] + d;
              end for;
              d_1:=points[n_points - 1,:] - points[n_points - 2,:];
              d_2:=points[n_points,:] - points[n_points - 1,:];
              phi_1:=max(acos((-d_1*d_2)/(Utilities.norm(d_1)*Utilities.norm(d_2))), pi/2);
              d:=nu*Utilities.norm(d_2) + (1 - nu)*(sin(phi_1)*Utilities.norm(d_1))/Utilities.norm(d_1);
              param[n_points]:=param[n_points - 1] + d;
              param:=param/param[n_points];
            end if;
          end parametrization;

          function plot "Plot Bspline curve (currently not fully functional, since feature in Dymola missing)"
            extends Modelica.Icons.Function;
            input Data spline "Bspline to be plotted";
            input Integer npoints=100 "Number of points";
            output Real x[npoints,spline.ndim + 1] "Table with u and function value at Bspline curve points";
          end plot;

          package Utilities "Utility functions for package Bspline1D"
            extends Modelica.Icons.Library;
            annotation(Documentation(info="<HTML>
<p>
Utility functions are provided here which are usually not called directly
by a user, but are needed in the functions of this package
</p>
<p>
The following functions are supported:
</p>
<pre>
  interpolation          Compute the interpolation Bspline
  interpolation_raw      Compute the interpolation Bspline, but only return the control points
                                                                                           and the knots
  interpolationBessel    Compute the interpolation Bspline with Bessel end-conditions
  interpolationDer       Compute the interpolation Bspline when the first derivative are given
  n_BasisFuns            Compute the non zero basis functions of the Bspline
  n_DersBasisFuns        Compute the non zero basis functions and their derivatives
  n_findSpan             Compute the interval in which the parameter lies
  norm                   The euklidian norm of a vector
</pre>
<p><b>Release Notes:</b></p>
<ul>
<li><i>Sept. 13, 2002</i>
       by Gerhard Schillhuber:<br>
       first version implemented
</li>
<li><i>Oct. 17, 2002</i>
       by Gerhard Schillhuber:<br>
       new function: interpolation_raw. return only the control points and the knots.
                       'interpolation' calls 'interpolation_raw'.
</li>
</ul>
<br>
<p><b>Copyright (C) 2002, Modelica Association and DLR.</b></p>
<p><i>
This package is <b>free</b> software. It can be redistributed and/or modified
under the terms of the <b>Modelica license</b>, see the license conditions
and the accompanying <b>disclaimer</b> in the documentation of package
Modelica in file \"Modelica/package.mo\".
</i></p>
</HTML>
"));
            function interpolation "Interpolation of the points with a Bspline of degree n"
              extends Modelica.Icons.Function;
              input Real points[:,:] "[i,:] is point i on the curve to be interpolated";
              input Real param[size(points, 1)] "parameterization of the data points (not necessarily in the range 0..1)";
              input Integer degree(min=1)=3 "Polynomial degree of interpolation";
              output Data spline(ndim=size(points, 2), ncontrol=size(points, 1), degree=degree) "Bspline in a form which can be quickly interpolated";
            protected
              Real ctrlp[spline.ncontrol,spline.ndim];
              Real k[spline.ncontrol + degree + 1];
            algorithm
              (ctrlp,k):=interpolation_bandmatrix(points, param, degree);
              spline.controlPoints:=ctrlp;
              spline.knots:=k;
            end interpolation;

            function interpolation_bandmatrix "Interpolation of the points with a Bspline of degree n. Do NOT return a Bspline struct.
  Return the the raw information of control points and knots."
              import U = ThermoSysPro.Properties.WaterSteam.IF97_packages.IF97_wAJ.Spline_Utilities.Modelica_Interpolation.Bspline1D.Utilities;
              extends Modelica.Icons.Function;
              input Real points[:,:] "[i,:] is point i on the curve to be interpolated";
              input Real param[size(points, 1)] "parameterization of the data points (not necessarily in the range 0..1)";
              input Integer degree(min=1)=3 "Polynomial degree of interpolation";
              output Real controlPoints[size(points, 1),size(points, 2)] "Control points";
              output Real knots[size(points, 1) + degree + 1] "knots";
            protected
              Integer nknots=size(knots, 1);
              Integer ndim=size(points, 2);
              Integer npoints;
              Integer knots_tech;
              Real u;
              Integer span;
              Real evalBasisFuns[degree + 1];
              Real Band[3*degree + 1,size(points, 1)];
              Integer kl=degree;
              Integer ku=degree;
              Integer info=0;
              String sout;
            algorithm
              npoints:=size(points, 1);
              knots_tech:=2;
              if knots_tech == 1 then
                knots[1:degree]:=ones(degree)*param[1];
                knots[degree + 1:npoints + degree]:=param;
                knots[npoints + degree + 1:npoints + 2*degree]:=ones(degree)*param[npoints];
              end if;
              if knots_tech == 2 then
                knots[1:degree + 1]:=ones(degree + 1)*param[1];
                for j in 1:npoints - degree - 1 loop
                  knots[degree + j + 1]:=sum(param[j + 1:j + degree])/degree;
                end for;
                knots[npoints + 1:npoints + degree + 1]:=ones(degree + 1)*param[npoints];
              end if;
              if knots_tech == 3 then
                knots[1:degree + 1]:=ones(degree + 1)*param[1];
                for j in 1:npoints - 1 loop
                  knots[degree + j + 1]:=j/(npoints - 1);
                end for;
                knots[npoints + degree + 1:npoints + 2*degree]:=ones(degree)*param[npoints];
              end if;
              for i in 1:npoints loop
                u:=param[i];
                span:=U.n_findSpan(degree, u, knots);
                evalBasisFuns:=U.n_BasisFuns(span, u, degree, knots);
                for j in 1:degree + 1 loop
                  Band[kl + 1 + ku + i - span + degree - j + 1,span - degree + j - 1]:=evalBasisFuns[j];
                end for;
              end for;
              (controlPoints,info):=ThermoSysPro.Properties.WaterSteam.IF97_packages.IF97_wAJ.Spline_Utilities.Modelica_Interpolation.Utilities.solveBandedWithMatrix(kl, ku, Band, points);
              if info <> 0 then
                (controlPoints,knots):=U.interpolation_raw(points, param, degree);
              end if;
            end interpolation_bandmatrix;

            function interpolation_raw "Interpolation of the points with a Bspline of degree n. Do NOT return a Bspline struct.
  Return the the raw information of control points and knots."
              extends Modelica.Icons.Function;
              input Real points[:,:] "[i,:] is point i on the curve to be interpolated";
              input Real param[size(points, 1)] "parameterization of the data points (not necessarily in the range 0..1)";
              input Integer degree(min=1)=3 "Polynomial degree of interpolation";
              output Real controlPoints[size(points, 1),size(points, 2)] "Control points";
              output Real knots[size(points, 1) + degree + 1] "knots";
            protected
              Integer nknots=size(knots, 1);
              Integer ndim=size(points, 2);
              Integer npoints;
              Integer knots_tech;
              Real S[size(points, 1),size(points, 1)];
              Real u;
              Integer span;
            algorithm
              npoints:=size(points, 1);
              knots_tech:=2;
              if knots_tech == 1 then
                knots[1:degree]:=ones(degree)*param[1];
                knots[degree + 1:npoints + degree]:=param;
                knots[npoints + degree + 1:npoints + 2*degree]:=ones(degree)*param[npoints];
              end if;
              if knots_tech == 2 then
                knots[1:degree + 1]:=ones(degree + 1)*param[1];
                for j in 1:npoints - degree - 1 loop
                  knots[degree + j + 1]:=sum(param[j + 1:j + degree])/degree;
                end for;
                knots[npoints + 1:npoints + degree + 1]:=ones(degree + 1)*param[npoints];
              end if;
              if knots_tech == 3 then
                knots[1:degree + 1]:=ones(degree + 1)*param[1];
                for j in 1:npoints - 1 loop
                  knots[degree + j + 1]:=j/(npoints - 1);
                end for;
                knots[npoints + degree + 1:npoints + 2*degree]:=ones(degree)*param[npoints];
              end if;
              S:=zeros(npoints, npoints);
              for i in 1:npoints loop
                u:=param[i];
                span:=n_findSpan(degree, u, knots);
                S[i,span - degree:span]:=n_BasisFuns(span, u, degree, knots);
              end for;
              controlPoints:=ThermoSysPro.Properties.WaterSteam.IF97_packages.IF97_wAJ.Spline_Utilities.Modelica_Interpolation.Utilities.solveMatrix(S, points);
            end interpolation_raw;

            function interpolationBessel "Interpolation of the points with a Bspline of degree 3 and Bessel end condition"
              extends Modelica.Icons.Function;
              input Real points[:,:] "[i,:] is point i on the curve to be interpolated";
              input Real param[size(points, 1)] "parameterization of the data points (not necessarily in the range 0..1)";
              output Data Bspline(ndim=size(points, 2), ncontrol=size(points, 1) + 2, degree=3) "Bspline in a form which can be quickly interpolated";
            protected
              Integer ndim=size(points, 2);
              Real S[size(points, 1) - 2,size(points, 1) - 2];
              Real u;
              Real u2;
              Real nik[4];
              Real nik2[4];
              Integer degree;
              Real knots[size(points, 1) + 2*3];
              Integer n_data;
              Real alpha;
              Real beta;
              Real a[ndim];
              Real rs[ndim];
              Real re[ndim];
              Real p_vec[Bspline.ncontrol - 4,Bspline.ndim];
              Integer span;
            algorithm
              degree:=3;
              n_data:=size(points, 1);
              knots[1:degree]:=ones(3)*param[1];
              knots[degree + 1:n_data + degree]:=param;
              knots[n_data + degree + 1:n_data + 2*degree]:=ones(3)*param[n_data];
              Bspline.controlPoints:=zeros(n_data + 2, Bspline.ndim);
              Bspline.controlPoints[1,:]:=points[1,:];
              Bspline.controlPoints[n_data + 2,:]:=points[n_data,:];
              alpha:=(param[3] - param[2])/(param[3] - param[1]);
              beta:=1 - alpha;
              a:=(points[2,:] - alpha^2*points[1,:] - beta^2*points[3,:])/(2*alpha*beta);
              Bspline.controlPoints[2,:]:=2/3*(alpha*points[1,:] + beta*a) + points[1,:]/3;
              alpha:=(param[n_data - 2] - param[n_data - 1])/(param[n_data - 2] - param[n_data]);
              beta:=1 - alpha;
              a:=(points[n_data - 1,:] - alpha^2*points[n_data,:] - beta^2*points[n_data - 2,:])/(2*alpha*beta);
              Bspline.controlPoints[n_data + 1,:]:=2/3*(alpha*points[n_data,:] + beta*a) + points[n_data,:]/3;
              S:=zeros(n_data - 2, n_data - 2);
              u2:=param[2];
              span:=n_findSpan(degree, u2, knots);
              nik2:=n_BasisFuns(span, u2, degree, knots);
              S[1,1:2]:=nik2[2:3];
              rs:=points[2,:] - Bspline.controlPoints[2,:]*nik2[1];
              for i in 1:n_data - 4 loop
                u:=param[i + 2];
                span:=n_findSpan(degree, u, knots);
                nik:=n_BasisFuns(span, u, degree, knots);
                S[i + 1,i:i + 2]:=nik[1:3];
              end for;
              u:=param[n_data - 1];
              span:=n_findSpan(degree, u, knots);
              nik:=n_BasisFuns(span, u, degree, knots);
              S[n_data - 2,n_data - 3:n_data - 2]:=nik[1:2];
              re:=points[n_data - 1,:] - Bspline.controlPoints[n_data + 1,:]*nik[3];
              p_vec[1,:]:=rs;
              p_vec[2:n_data - 3,:]:=points[3:n_data - 2,:];
              p_vec[n_data - 2,:]:=re;
              Bspline.controlPoints[3:n_data,:]:=ThermoSysPro.Properties.WaterSteam.IF97_packages.IF97_wAJ.Spline_Utilities.Modelica_Interpolation.Utilities.solveMatrix(S, p_vec);
              Bspline.knots:=knots;
            end interpolationBessel;

            function interpolationder "Interpolation of the points and its first derivatives with a Bspline of degree n"
              extends Modelica.Icons.Function;
              input Real points[:,:] "[i,:] is point i on the curve to be interpolated";
              input Real derivs[size(points, 1),size(points, 2)] "derivs[i,:] is the derivative at points[i,:]";
              input Real param[size(points, 1)] "parameterization of the data points (not necessarily in the range 0..1)";
              input Integer degree(min=2)=3 "Polynomial degree of interpolation";
              output Data spline(ndim=size(points, 2), ncontrol=2*size(points, 1), degree=degree) "Bspline in a form which can be quickly interpolated";
            protected
              Integer nknots=size(spline.knots, 1);
              Integer ndim=size(points, 2);
              Integer npoints;
              Integer i;
              Integer k;
              Real S[2*size(points, 1),2*size(points, 1)];
              Real u;
              Real b[2*size(points, 1),size(points, 2)];
              Integer span;
              Real N[2,degree + 1];
            algorithm
              npoints:=size(points, 1);
              k:=integer(degree/2);
              spline.knots[1:degree + 1]:=ones(degree + 1)*param[1];
              if degree == 2*k then
                k:=k - 1;
                for j in 1:k loop
                  spline.knots[degree + 1 + j]:=param[j + 1];
                end for;
                for j in 1:npoints - (k + 1) loop
                  spline.knots[degree + k + 2*j]:=(param[j + k] + param[j + k + 1])/2;
                  spline.knots[degree + k + 2*j + 1]:=param[j + k + 1];
                end for;
                for j in 1:k loop
                  spline.knots[2*npoints - k + j]:=param[npoints - k + j - 1];
                end for;
              else
                for j in 1:k loop
                  spline.knots[degree + 1 + j]:=spline.knots[degree + 1] + j*(param[k + 1] - param[1])/k;
                end for;
                for j in 1:npoints - (k + 1) loop
                  spline.knots[degree + k + 2*j]:=(2*param[j + k] + param[j + k + 1])/3;
                  spline.knots[degree + k + 2*j + 1]:=(param[j + k] + 2*param[j + k + 1])/3;
                end for;
                for j in 1:k loop
                  spline.knots[2*npoints - k + j]:=spline.knots[2*npoints - k] + j*(param[npoints] - param[npoints - k])/k;
                end for;
              end if;
              spline.knots[2*npoints + 1:2*npoints + degree + 1]:=ones(degree + 1)*param[npoints];
              S:=zeros(2*npoints, 2*npoints);
              for i in 1:npoints loop
                u:=param[i];
                span:=n_findSpan(spline.degree, u, spline.knots);
                N:=Utilities.n_DersBasisFuns(span, u, spline.degree, 1, spline.knots);
                S[2*i - 1:2*i,span - spline.degree:span]:=N;
                b[2*i - 1,:]:=points[i,:];
                b[2*i,:]:=derivs[i,:];
              end for;
              spline.controlPoints:=ThermoSysPro.Properties.WaterSteam.IF97_packages.IF97_wAJ.Spline_Utilities.Modelica_Interpolation.Utilities.solveMatrix(S, b);
            end interpolationder;

            function n_BasisFuns "Compute the nonvanishing basis functions"
              extends Modelica.Icons.Function;
              input Integer i "index";
              input Real u "parameter";
              input Integer p "degree";
              input Real knots[:] "knot vector";
              output Real N[p + 1] "Basis functions";
            protected
              Integer j;
              Integer r;
              Real left[p + 1];
              Real right[p + 1];
              Real temp;
              Real saved;
            algorithm
              N[1]:=1;
              for j in 1:p loop
                left[j]:=u - knots[i + 1 - j];
                right[j]:=knots[i + j] - u;
                saved:=0.0;
                for r in 1:j loop
                  temp:=N[r]/(right[r] + left[j - r + 1]);
                  N[r]:=saved + right[r]*temp;
                  saved:=left[j - r + 1]*temp;
                end for;
                N[j + 1]:=saved;
              end for;
            end n_BasisFuns;

            function n_DersBasisFuns "Compute nonzero basis functions and their derivatives"
              extends Modelica.Icons.Function;
              input Integer i "index";
              input Real u "parameter";
              input Integer p "degree";
              input Integer n "n-th derivative";
              input Real knots[:] "knot vector";
              output Real ders[n + 1,p + 1] "ders[k,:] is (k-1)-th derivative";
            protected
              Integer j;
              Integer r;
              Real left[p + 1];
              Real right[p + 1];
              Real temp;
              Real saved;
              Real ndu[p + 1,p + 1];
              Integer s1;
              Integer s2;
              Integer j1;
              Integer j2;
              Real a[2,p + 1];
              Real d;
              Integer rk;
              Integer pk;
              Integer prod;
              Integer tt;
            algorithm
              ndu[1,1]:=1;
              for j in 1:p loop
                left[j]:=u - knots[i + 1 - j];
                right[j]:=knots[i + j] - u;
                saved:=0.0;
                for r in 1:j loop
                  ndu[j + 1,r]:=right[r] + left[j - r + 1];
                  temp:=ndu[r,j]/ndu[j + 1,r];
                  ndu[r,j + 1]:=saved + right[r]*temp;
                  saved:=left[j - r + 1]*temp;
                end for;
                ndu[j + 1,j + 1]:=saved;
              end for;
              for j in 1:p + 1 loop
                ders[1,j]:=ndu[j,p + 1];
              end for;
              for r in 1:p + 1 loop
                s1:=1;
                s2:=2;
                a[1,1]:=1.0;
                for k in 1:n loop
                  d:=0.0;
                  rk:=r - k - 1;
                  pk:=p - k;
                  if r - 1 >= k then
                    a[s2,1]:=a[s1,1]/ndu[pk + 2,rk + 1];
                    d:=a[s2,1]*ndu[rk + 1,pk + 1];
                  end if;
                  if rk >= -1 then
                    j1:=1;
                  else
                    j1:=-rk;
                  end if;
                  if r - 1 <= pk + 1 then
                    j2:=k - 1;
                  else
                    j2:=p - r + 1;
                  end if;
                  for j in j1:j2 loop
                    a[s2,j + 1]:=(a[s1,j + 1] - a[s1,j])/ndu[pk + 2,rk + j + 1];
                    d:=d + a[s2,j + 1]*ndu[rk + j + 1,pk + 1];
                  end for;
                  if r - 1 <= pk then
                    a[s2,k + 1]:=-a[s1,k]/ndu[pk + 2,r];
                    d:=d + a[s2,k + 1]*ndu[r,pk + 1];
                  end if;
                  ders[k + 1,r]:=d;
                  tt:=s1;
                  s1:=s2;
                  s2:=tt;
                end for;
              end for;
              prod:=p;
              for k in 1:n loop
                for j in 1:p + 1 loop
                  ders[k + 1,j]:=ders[k + 1,j]*prod;
                end for;
                prod:=prod*(p - k);
              end for;
            end n_DersBasisFuns;

            function n_findSpan "Determine the knot span index"
              extends Modelica.Icons.Function;
              input Integer p "degree";
              input Real u "parameter";
              input Real knots[:] "knot vector";
              output Integer i "The knot span index";
            protected
              Integer n;
              Integer low;
              Integer high;
              Integer mid;
            algorithm
              n:=size(knots, 1) - p - 1;
              if abs(u - knots[n + 1]) < 1e-11 then
                i:=n;
              else
                low:=p;
                high:=n + 1;
                mid:=integer((low + high)/2);
                while (u < knots[mid] or u >= knots[mid + 1]) loop
                  assert(low + 1 < high, "Value must be within limits for Bspline1D.Utilities.n_findSpan");
                  if u < knots[mid] then
                    high:=mid;
                  else
                    low:=mid;
                  end if;
                  mid:=integer((low + high)/2);
                end while;
                i:=mid;
              end if;
            end n_findSpan;

            function norm "The euklidian norm of a vector"
              extends Modelica.Icons.Function;
              input Real v[:] "A vector";
              output Real n "The norm of the vector";
            algorithm
              n:=sqrt(v*v);
            end norm;

          end Utilities;

        end Bspline1D;

        package Utilities "Utility functions for package Interpolation"
          extends Modelica.Icons.Library;
          annotation(Documentation(info="<HTML>
<p>
Utility functions are provided here which are usually not called directly
by a user, but are needed in the functions of this package
</p>
<p>
The following functions are supported:
</p>
<pre>
  curveLength                          Compute the length of a curve with adaptive quadrature
  dummy                                return a dummy Bspline with zero entries
  getNumberControlPoints        Compute the number of control points for the given data points
  getNumberControlPoints2        Compute the number of control points for the given data points
                                                                                                  and transformation matrices
  quat2T                               Compute the transformation matrix of the given quaternions
  T2quat                               Compute the quaternions of the given transformation matrix
</pre>
<p><b>Release Notes:</b></p>
<ul>
<li><i>Sept. 13, 2002</i>
       by Gerhard Schillhuber:<br>
       first version implemented
</li>
<li><i>Oct. 17, 2002</i>
       by Gerhard Schillhuber:<br>
       new functions: getNumberControlPoints, getNumberControlPoints2
                               compute the number of control points for the given data points. It's needed
                               to initialize the curve.
</li>
</ul>
<br>
<p><b>Copyright (C) 2002, Modelica Association and DLR.</b></p>
<p><i>
This package is <b>free</b> software. It can be redistributed and/or modified
under the terms of the <b>Modelica license</b>, see the license conditions
and the accompanying <b>disclaimer</b> in the documentation of package
Modelica in file \"Modelica/package.mo\".
</i></p>
</HTML>
"));
          function curveLength "Computes the length of the curve from a to b"
            import ThermoSysPro.Properties.WaterSteam.IF97_packages.IF97_wAJ.Spline_Utilities.Modelica_Interpolation;
            extends Modelica.Icons.Function;
            input Modelica_Interpolation.Bspline1D.Data spline "Bspline data";
            input Real a "left end";
            input Real b "right end";
            input Real err=1e-08 "relative error";
            output Real I "curve length from a to b";
          protected
            Real m;
            Real h;
            Real alpha;
            Real beta;
            Real x1=0.94288241569548;
            Real x2=0.641853342345781;
            Real x3=0.23638319966215;
            Real x[13];
            Real y[13];
            Real fa;
            Real fb;
            Real i1;
            Real i2;
            Real is;
            Real erri1;
            Real erri2;
            Real R;
            Real tol;
            Real eps=1e-16;
            Integer s;
            package internal "Funtions to be used only in function curveLength"
              import ThermoSysPro.Properties.WaterSteam.IF97_packages.IF97_wAJ.Spline_Utilities.Modelica_Interpolation;
              function quadStep "Recursive function used by curveLength"
                input ThermoSysPro.Properties.WaterSteam.IF97_packages.IF97_wAJ.Spline_Utilities.Modelica_Interpolation.Bspline1D.Data spline;
                input Real a "right interval end";
                input Real b "left interval end";
                input Real fa "function value at a";
                input Real fb "function value at b";
                input Real is "first approximation of the integral";
                output Real I "Integral value";
              protected
                Real m;
                Real h;
                Real alpha;
                Real beta;
                Real x[5];
                Real y[5];
                Real mll;
                Real ml;
                Real mr;
                Real mrr;
                Real fmll;
                Real fml;
                Real fm;
                Real fmr;
                Real fmrr;
                Real i1;
                Real i2;
              algorithm
                h:=(b - a)/2;
                m:=(a + b)/2;
                alpha:=sqrt(2/3);
                beta:=1/sqrt(5);
                mll:=m - alpha*h;
                ml:=m - beta*h;
                mr:=m + beta*h;
                mrr:=m + alpha*h;
                x:={mll,ml,m,mr,mrr};
                y:=eval(spline, x);
                fmll:=y[1];
                fml:=y[2];
                fm:=y[3];
                fmr:=y[4];
                fmrr:=y[5];
                i2:=h/6*(fa + fb + 5*(fml + fmr));
                i1:=h/1470*(77*(fa + fb) + 432*(fmll + fmrr) + 625*(fml + fmr) + 672*fm);
                if is + (i1 - i2) == is or mll <= a or b <= mrr then
                  I:=i1;
                else
                  I:=quadStep(spline, a, mll, fa, fmll, is) + quadStep(spline, mll, ml, fmll, fml, is) + quadStep(spline, ml, m, fml, fm, is) + quadStep(spline, m, mr, fm, fmr, is) + quadStep(spline, mr, mrr, fmr, fmrr, is) + quadStep(spline, mrr, b, fmrr, fb, is);
                end if;
              end quadStep;

              function eval "evaluate the integrand"
                input Modelica_Interpolation.Bspline1D.Data spline "Bspline data";
                input Real u[:] "parameters at which the integrand shall be evaluated";
                output Real f[size(u, 1)];
              protected
                Real xd[spline.ndim];
                Integer n;
              algorithm
                n:=size(u, 1);
                for i in 1:n loop
                  xd:=Modelica_Interpolation.Bspline1D.evaluateDerN(spline, u[i], 1);
                  f[i]:=sqrt(xd*xd);
                end for;
              end eval;

            end internal;

          algorithm
            tol:=err;
            m:=(a + b)/2;
            h:=(b - a)/2;
            alpha:=sqrt(2/3);
            beta:=1/sqrt(5);
            x:={a,m - x1*h,m - alpha*h,m - x2*h,m - beta*h,m - x3*h,m,m + x3*h,m + beta*h,m + x2*h,m + alpha*h,m + x1*h,b};
            y:=internal.eval(spline, x);
            fa:=y[1];
            fb:=y[13];
            i2:=h/6*(y[1] + y[13] + 5*(y[5] + y[9]));
            i1:=h/1470*(77*(y[1] + y[13]) + 432*(y[3] + y[11]) + 625*(y[5] + y[9]) + 672*y[7]);
            is:=h*(0.0158271919734802*(y[1] + y[13]) + 0.09427384021885*(y[2] + y[12]) + 0.155071987336585*(y[3] + y[11]) + 0.188821573960182*(y[4] + y[10]) + 0.199773405226859*(y[5] + y[9]) + 0.22492646533334*(y[6] + y[8]) + 0.242611071901408*y[7]);
            s:=sign(is);
            if s == 0 then
              s:=1;
            end if;
            erri1:=abs(i1 - is);
            erri2:=abs(i2 - is);
            R:=1;
            if erri2 <> 0 then
              R:=erri1/erri2;
            end if;
            if R > 0 and R < 1 then
              tol:=tol/R;
            end if;
            is:=s*abs(is)*tol/eps;
            if is == 0 then
              is:=b - a;
            end if;
            I:=internal.quadStep(spline, a, b, fa, fb, is);
          end curveLength;

          function dgbsv "Solve real system of linear equations A*X=B with a banded A matrix and a B matrix (copy from protected package Matrices.Lapack)"
            extends Modelica.Icons.Function;
            input Integer n "Number of equations";
            input Integer kLower "Number of lower bands";
            input Integer kUpper "Number of upper bands";
            input Real A[2*kLower + kUpper + 1,n];
            input Real B[n,:];
            output Real X[n,size(B, 2)]=B;
            output Integer info;
          protected
            Real Awork[size(A, 1),size(A, 2)]=A;
            Integer ipiv[n];

            external "FORTRAN 77" dgbsv(n,kLower,kUpper,size(B, 2),Awork,size(Awork, 1),ipiv,X,n,info)             annotation(Library="Lapack");
            annotation(Documentation(info="Lapack documentation:
Purpose
=======
DGBSV computes the solution to a real system of linear equations
A * X = B, where A is a band matrix of order N with KL subdiagonals
and KU superdiagonals, and X and B are N-by-NRHS matrices.
The LU decomposition with partial pivoting and row interchanges is
used to factor A as A = L * U, where L is a product of permutation
and unit lower triangular matrices with KL subdiagonals, and U is
upper triangular with KL+KU superdiagonals.  The factored form of A
is then used to solve the system of equations A * X = B.
Arguments
=========
N       (input) INTEGER
        The number of linear equations, i.e., the order of the
        matrix A.  N >= 0.
KL      (input) INTEGER
        The number of subdiagonals within the band of A.  KL >= 0.
KU      (input) INTEGER
        The number of superdiagonals within the band of A.  KU >= 0.
NRHS    (input) INTEGER
        The number of right hand sides, i.e., the number of columns
        of the matrix B.  NRHS >= 0.
AB      (input/output) DOUBLE PRECISION array, dimension (LDAB,N)
        On entry, the matrix A in band storage, in rows KL+1 to
        2*KL+KU+1; rows 1 to KL of the array need not be set.
        The j-th column of A is stored in the j-th column of the
        array AB as follows:
        AB(KL+KU+1+i-j,j) = A(i,j) for max(1,j-KU)<=i<=min(N,j+KL)
        On exit, details of the factorization: U is stored as an
        upper triangular band matrix with KL+KU superdiagonals in
        rows 1 to KL+KU+1, and the multipliers used during the
        factorization are stored in rows KL+KU+2 to 2*KL+KU+1.
        See below for further details.
LDAB    (input) INTEGER
        The leading dimension of the array AB.  LDAB >= 2*KL+KU+1.
IPIV    (output) INTEGER array, dimension (N)
        The pivot indices that define the permutation matrix P;
        row i of the matrix was interchanged with row IPIV(i).
B       (input/output) DOUBLE PRECISION array, dimension (LDB,NRHS)
        On entry, the N-by-NRHS right hand side matrix B.
        On exit, if INFO = 0, the N-by-NRHS solution matrix X.
LDB     (input) INTEGER
        The leading dimension of the array B.  LDB >= max(1,N).
INFO    (output) INTEGER
        = 0:  successful exit
        < 0:  if INFO = -i, the i-th argument had an illegal value
        > 0:  if INFO = i, U(i,i) is exactly zero.  The factorization
              has been completed, but the factor U is exactly
              singular, and the solution has not been computed.
Further Details
===============
The band storage scheme is illustrated by the following example, when
M = N = 6, KL = 2, KU = 1:
On entry:                       On exit:
    *    *    *    +    +    +       *    *    *   u14  u25  u36
    *    *    +    +    +    +       *    *   u13  u24  u35  u46
    *   a12  a23  a34  a45  a56      *   u12  u23  u34  u45  u56
   a11  a22  a33  a44  a55  a66     u11  u22  u33  u44  u55  u66
   a21  a32  a43  a54  a65   *      m21  m32  m43  m54  m65   *
   a31  a42  a53  a64   *    *      m31  m42  m53  m64   *    *
Array elements marked * are not used by the routine; elements marked
+ need not be set on entry, but are required by the routine to store
elements of U because of fill-in resulting from the row interchanges."), Window(x=0.4, y=0.4, width=0.6, height=0.6));
          end dgbsv;

          function dgesv "Solve real system of linear equations A*X=B with a B matrix (copy from protected package Matrices.Lapack)"
            extends Modelica.Icons.Function;
            input Real A[:,size(A, 1)];
            input Real B[size(A, 1),:];
            output Real X[size(A, 1),size(B, 2)]=B;
            output Integer info;
          protected
            Real Awork[size(A, 1),size(A, 1)]=A;
            Integer ipiv[size(A, 1)];

            external "FORTRAN 77" dgesv(size(A, 1),size(B, 2),Awork,size(A, 1),ipiv,X,size(A, 1),info)             annotation(Library="Lapack");
            annotation(Documentation(info="Lapack documentation:
    Purpose
    =======
    DGESV computes the solution to a real system of linear equations
       A * X = B,
    where A is an N-by-N matrix and X and B are N-by-NRHS matrices.
    The LU decomposition with partial pivoting and row interchanges is
    used to factor A as
       A = P * L * U,
    where P is a permutation matrix, L is unit lower triangular, and U is

    upper triangular.  The factored form of A is then used to solve the
    system of equations A * X = B.
    Arguments
    =========
    N       (input) INTEGER
            The number of linear equations, i.e., the order of the
            matrix A.  N >= 0.
    NRHS    (input) INTEGER
            The number of right hand sides, i.e., the number of columns
            of the matrix B.  NRHS >= 0.
    A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)
            On entry, the N-by-N coefficient matrix A.
            On exit, the factors L and U from the factorization
            A = P*L*U; the unit diagonal elements of L are not stored.
    LDA     (input) INTEGER
            The leading dimension of the array A.  LDA >= max(1,N).
    IPIV    (output) INTEGER array, dimension (N)
            The pivot indices that define the permutation matrix P;
            row i of the matrix was interchanged with row IPIV(i).
    B       (input/output) DOUBLE PRECISION array, dimension (LDB,NRHS)
            On entry, the N-by-NRHS matrix of right hand side matrix B.
            On exit, if INFO = 0, the N-by-NRHS solution matrix X.
    LDB     (input) INTEGER
            The leading dimension of the array B.  LDB >= max(1,N).
    INFO    (output) INTEGER
            = 0:  successful exit
            < 0:  if INFO = -i, the i-th argument had an illegal value
            > 0:  if INFO = i, U(i,i) is exactly zero.  The factorization

                  has been completed, but the factor U is exactly
                  singular, so the solution could not be computed.
"), Window(x=0.4, y=0.4, width=0.6, height=0.6));
          end dgesv;

          function dummy "Dummy Bspline"
            extends Modelica.Icons.Function;
            input Integer nd "Dimension";
            input Integer nc "Number of control points";
            input Integer deg "degree";
            output ThermoSysPro.Properties.WaterSteam.IF97_packages.IF97_wAJ.Spline_Utilities.Modelica_Interpolation.Bspline1D.Data spline(ndim=nd, ncontrol=nc, degree=deg) "A dummy Bspline with zero entries";
          protected
            Integer j;
          algorithm
            j:=1;
          end dummy;

          function getNumberControlPoints "Return the number of control points"
            extends Modelica.Icons.Function;
            input Real r[:,:] "r[i,:] is position vector to point i on the curve";
            input Integer degree "degree of the Bspline";
            output Integer ncontrol "number of control points";
          protected
            Integer n;
            Integer multi;
            Integer begin;
            Real delta[size(r, 2)];
            Integer j;
            Integer jstart;
          algorithm
            n:=size(r, 1);
            multi:=1;
            for j in 1:n - 1 loop
              delta:=r[1,:] - r[1 + j,:];
              if sqrt(delta*delta) < 1e-12 then
                multi:=multi + 1;
              end if;
            end for;
            begin:=multi;
            multi:=0;
            for j in 1:n - 1 loop
              delta:=r[n,:] - r[n - j,:];
              if sqrt(delta*delta) < 1e-12 then
                multi:=multi + 1;
              end if;
            end for;
            n:=n - multi;
            ncontrol:=n;
            jstart:=begin;
            for j in begin + 1:n - 1 loop
              delta:=r[j,:] - r[j - 1,:];
              if sqrt(delta*delta) < 1e-12 then
                if j - 1 - jstart >= 1 and j - 1 - jstart < degree then
                  ncontrol:=ncontrol + degree - (j - 1 - jstart);
                end if;
                jstart:=j;
                delta:=r[j + 1,:] - r[j,:];
                if sqrt(delta*delta) < 1e-12 then
                  ncontrol:=ncontrol - 1;
                  jstart:=j + 1;
                end if;
              end if;
            end for;
            if n - jstart < degree then
              ncontrol:=ncontrol + degree - (n - jstart);
            end if;
            ncontrol:=ncontrol - begin + 1;
          end getNumberControlPoints;

          function getNumberControlPoints2 "Return the number of control points"
            extends Modelica.Icons.Function;
            input Real r[:,:] "r[i,:] is position vector to point i on the curve";
            input Real T[size(r, 1),3,3] "T[i,:,:] is transformation matrix from base frame to path frame at point i";
            input Integer degree "degree of the Bspline";
            output Integer ncontrol "number of control points";
          protected
            Integer n;
            Real data[size(r, 1),7];
            Real q[4];
            Real q_old[4];
          algorithm
            n:=size(r, 1);
            data:=zeros(size(r, 1), 7);
            data[:,1:3]:=r;
            for i in 1:size(r, 1) loop
              q:=T2quat(T[i,:,:]);
              if i > 1 and q_old*q < 0 then
                q:=-q;
              end if;
              data[i,4:7]:=q;
              q_old:=q;
            end for;
            ncontrol:=getNumberControlPoints(data, degree);
          end getNumberControlPoints2;

          function quat2T "Compute transformation matrix from non-consistent quaternions"
            extends Modelica.Icons.Function;
            input Real q[4] "Quaternions (non-consistent)";
            output Real T[3,3] "orthogonal transformation matrix";
          algorithm
            T[1,1]:=q[1]^2 + q[2]^2 - q[3]^2 - q[4]^2;
            T[2,2]:=q[1]^2 - q[2]^2 + q[3]^2 - q[4]^2;
            T[3,3]:=q[1]^2 - q[2]^2 - q[3]^2 + q[4]^2;
            T[1,2]:=2*(q[2]*q[3] + q[1]*q[4]);
            T[1,3]:=2*(q[2]*q[4] - q[1]*q[3]);
            T[2,1]:=2*(q[2]*q[3] - q[1]*q[4]);
            T[2,3]:=2*(q[3]*q[4] + q[1]*q[2]);
            T[3,1]:=2*(q[2]*q[4] + q[1]*q[3]);
            T[3,2]:=2*(q[3]*q[4] - q[1]*q[2]);
            T:=T/(q*q);
          end quat2T;

          function solveBandedWithMatrix "Solve linear system with banded system matrix and right hand side matrix (similar to Modelica.Matrices.solve)"
            extends Modelica.Icons.Function;
            input Integer kLower "Number of lower bands";
            input Integer kUpper "Number of upper bands";
            input Real A[2*kLower + kUpper + 1,:] "Matrix A of A*X = B";
            input Real B[size(A, 2),:] "Matrix B of A*X = B";
            output Real X[size(A, 2),size(B, 2)]=B "Matrix X such that A*X = B";
            output Integer info;
          algorithm
            (X,info):=dgbsv(size(A, 2), kLower, kUpper, A, B);
            assert(info == 0, "Solving a linear system of equations with function
\"Modelica_Interpolation.Utilities.solveBandedWithMatrix\" is not possible, since matrix A
is singular, i.e., no unique solution exists.");
          end solveBandedWithMatrix;

          function solveMatrix "Solve linear system with right hand side matrix (similar to Modelica_Interpolation.Utilities.solveMatrix)"
            extends Modelica.Icons.Function;
            input Real A[:,size(A, 1)] "Matrix A of A*X = B";
            input Real B[size(A, 1),:] "Matrix B of A*X = B";
            output Real X[size(B, 1),size(B, 2)]=B "Matrix X such that A*X = B";
          protected
            Integer info;
          algorithm
            (X,info):=dgesv(A, B);
            assert(info == 0, "Solving a linear system of equations with function
\"Modelica_Interpolation.Utilities.solveMatrix\" is not possible, since matrix A
is singular, i.e., no unique solution exists.");
          end solveMatrix;

          function T2quat "Compute Quaternions from a transformation matrix"
            extends Modelica.Icons.Function;
            input Real T[3,3] "transformation matrix";
            output Real q[4] "Quaternions of T (q and -q have same T)";
          protected
            Real branch "only for test purposes";
            Real paux;
            Real paux4;
            Real c1;
            Real c2;
            Real c3;
            Real c4;
            Real p4limit=0.1;
            Real c4limit=4*p4limit*p4limit;
          algorithm
            c1:=1 + T[1,1] - T[2,2] - T[3,3];
            c2:=1 + T[2,2] - T[1,1] - T[3,3];
            c3:=1 + T[3,3] - T[1,1] - T[2,2];
            c4:=1 + T[1,1] + T[2,2] + T[3,3];
            if c4 > c4limit or c4 > c1 and c4 > c2 and c4 > c3 then
              branch:=4;
              paux:=sqrt(c4)/2;
              paux4:=4*paux;
              q:={paux,(T[2,3] - T[3,2])/paux4,(T[3,1] - T[1,3])/paux4,(T[1,2] - T[2,1])/paux4};
            elseif c1 > c2 and c1 > c3 and c1 > c4 then
              branch:=1;
              paux:=sqrt(c1)/2;
              paux4:=4*paux;
              q:={(T[2,3] - T[3,2])/paux4,paux,(T[1,2] + T[2,1])/paux4,(T[1,3] + T[3,1])/paux4};

            elseif c2 > c1 and c2 > c3 and c2 > c4 then
              branch:=2;
              paux:=sqrt(c2)/2;
              paux4:=4*paux;
              q:={(T[3,1] - T[1,3])/paux4,(T[1,2] + T[2,1])/paux4,paux,(T[2,3] + T[3,2])/paux4};
            else
              branch:=3;
              paux:=sqrt(c3)/2;
              paux4:=4*paux;
              q:={(T[1,2] - T[2,1])/paux4,(T[1,3] + T[3,1])/paux4,(T[2,3] + T[3,2])/paux4,paux};
            end if;
          end T2quat;

        end Utilities;

      end Modelica_Interpolation;

      model PhaseBoundary "Model used to create the phase boundary"
        parameter Integer npoints=100;
        Real p[npoints] "pressure";
        Real hl[npoints] "liquid specific enthalpy";
        Real hv[npoints] "vapour specific enthalpy";
        parameter Real TMAX=ThermoSysPro.Properties.WaterSteam.BaseIF97.critical.TCRIT;
        parameter Real TMIN=ThermoSysPro.Properties.WaterSteam.BaseIF97.triple.Ttriple - 0.01;
      protected
        Real[npoints] T "temperature";
      algorithm
        T:=ThermoSysPro.Properties.WaterSteam.IF97_packages.IF97_wAJ.Spline_Utilities.linspace(TMIN, TMAX, npoints);
        p[1]:=ThermoSysPro.Properties.WaterSteam.BaseIF97.triple.ptriple;
        for i in 2:npoints - 1 loop
          p[i]:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.psat(T[i]);
        end for;
        p[end]:=ThermoSysPro.Properties.WaterSteam.BaseIF97.critical.PCRIT;
        for i in 1:npoints loop
          hl[i]:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.hl_p(p[i]);
          hv[i]:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.hv_p(p[i]);
        end for;
        annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={graphics()}));
      end PhaseBoundary;

    end Spline_Utilities;

  end IF97_wAJ;

end IF97_packages;
