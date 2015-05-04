within ThermoSysPro.Properties.WaterSteam;
package Region
  function boilingcurveL3_p "properties on the boiling curve"
    extends Modelica.Icons.Function;
    input Modelica.SIunits.Pressure p "pressure";
    output ThermoSysPro.Properties.WaterSteam.Common.IF97PhaseBoundaryProperties3rd bpro "property record";
  protected
    ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs3rd g "dimensionless Gibbs funcion and dervatives";
    ThermoSysPro.Properties.WaterSteam.Common.HelmholtzDerivs3rd f "dimensionless Helmholtz function and dervatives";
    Modelica.SIunits.Pressure plim=min(p, ThermoSysPro.Properties.WaterSteam.BaseIF97.data.PCRIT - 1e-07) "pressure limited to critical pressure - epsilon";
    Modelica.SIunits.SpecificVolume v "Specific Volume";
    Real vp3 "vp^3";
    Real ivp3 "1/vp^3";
    Real pv "partial derivative of p w.r.t v";
    Real pv2 "pv^2";
    Real pv3 "pv^3";
    Real ptv "2nd partial derivative of p w.r.t t and v";
    Real pvv "2nd partial derivative of p w.r.t v and v";
  algorithm
    g.R:=ThermoSysPro.Properties.WaterSteam.BaseIF97.data.RH2O;
    bpro.T:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tsat(plim);
    (bpro.dpT,bpro.dpTT):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.d2ptofT(bpro.T);
    if not bpro.T > ThermoSysPro.Properties.WaterSteam.BaseIF97.data.TLIMIT1 then
      g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g1L3(p, bpro.T);
      bpro.d:=p/(g.R*bpro.T*g.pi*g.gpi);
      bpro.h:=if p > plim then ThermoSysPro.Properties.WaterSteam.BaseIF97.data.HCRIT else g.R*bpro.T*g.tau*g.gtau;
      bpro.s:=g.R*(g.tau*g.gtau - g.g);
      bpro.cp:=-g.R*g.tau*g.tau*g.gtautau;
      bpro.vt:=g.R/p*(g.pi*g.gpi - g.tau*g.pi*g.gpitau);
      bpro.vp:=g.R*bpro.T/(p*p)*g.pi*g.pi*g.gpipi;
      bpro.pt:=-p/bpro.T*(g.gpi - g.tau*g.gpitau)/(g.gpipi*g.pi);
      bpro.pd:=-g.R*bpro.T*g.gpi*g.gpi/g.gpipi;
      bpro.vtt:=g.R*g.pi/p*g.tau/bpro.T*g.tau*g.gpitautau;
      bpro.vtp:=g.R*g.pi*g.pi/(p*p)*(g.gpipi - g.tau*g.gpipitau);
      bpro.vpp:=g.R*bpro.T*g.pi*g.pi*g.pi/(p*p*p)*g.gpipipi;
      bpro.cpt:=g.R*g.tau*g.tau/bpro.T*(2*g.gtautau + g.tau*g.gtautautau);
      v:=1/bpro.d;
      vp3:=bpro.vp*bpro.vp*bpro.vp;
      ivp3:=1/vp3;
      bpro.ptt:=-(bpro.vtt*bpro.vp*bpro.vp - 2.0*bpro.vt*bpro.vtp*bpro.vp + bpro.vt*bpro.vt*bpro.vpp)*ivp3;
      bpro.pdd:=-bpro.vpp*ivp3*v*v*v*v - 2*v*bpro.pd "= pvv/d^4";
      bpro.ptd:=(bpro.vtp*bpro.vp - bpro.vt*bpro.vpp)*ivp3*v*v "= -ptv/d^2";
      bpro.cvt:=(vp3*bpro.cpt + bpro.vp*bpro.vp*bpro.vt*bpro.vt + 3.0*bpro.vp*bpro.vp*bpro.T*bpro.vt*bpro.vtt - 3.0*bpro.vtp*bpro.vp*bpro.T*bpro.vt*bpro.vt + bpro.T*bpro.vt*bpro.vt*bpro.vt*bpro.vpp)*ivp3;
    else
      bpro.d:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.rhol_p_R4b(plim);
      f:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3L3(bpro.d, bpro.T);
      bpro.h:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.hl_p_R4b(plim);
      bpro.s:=f.R*(f.tau*f.ftau - f.f);
      bpro.cv:=g.R*(-f.tau*f.tau*f.ftautau);
      bpro.pt:=g.R*bpro.d*f.delta*(f.fdelta - f.tau*f.fdeltatau);
      bpro.pd:=g.R*bpro.T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
      pv:=-f.d*f.d*bpro.pd;
      bpro.vp:=1/pv;
      bpro.vt:=-bpro.pt/pv;
      bpro.pdd:=f.R*bpro.T*f.delta/bpro.d*(2.0*f.fdelta + 4.0*f.delta*f.fdeltadelta + f.delta*f.delta*f.fdeltadeltadelta);
      bpro.ptt:=f.R*bpro.d*f.delta*f.tau*f.tau/bpro.T*f.fdeltatautau;
      bpro.ptd:=f.R*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta - 2.0*f.tau*f.fdeltatau - f.delta*f.tau*f.fdeltadeltatau);
      bpro.cvt:=f.R*f.tau*f.tau/bpro.T*(2.0*f.ftautau + f.tau*f.ftautautau);
      bpro.cpt:=(bpro.cvt*bpro.pd + bpro.cv*bpro.ptd + (bpro.pt + 2.0*bpro.T*bpro.ptt)*bpro.pt/(bpro.d*bpro.d) - bpro.cp*bpro.ptd)/bpro.pd;
      pv2:=pv*pv;
      pv3:=pv2*pv;
      pvv:=bpro.pdd*f.d*f.d*f.d*f.d;
      ptv:=-f.d*f.d*bpro.ptd;
      bpro.vpp:=-pvv/pv3;
      bpro.vtt:=-(bpro.ptt*pv2 - 2.0*bpro.pt*ptv*pv + bpro.pt*bpro.pt*pvv)/pv3;
      bpro.vtp:=(-ptv*pv + bpro.pt*pvv)/pv3;
    end if;
  end boilingcurveL3_p;

  function dewcurveL3_p "properties on the dew curve"
    extends Modelica.Icons.Function;
    input Modelica.SIunits.Pressure p "pressure";
    output ThermoSysPro.Properties.WaterSteam.Common.IF97PhaseBoundaryProperties3rd bpro "property record";
  protected
    ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs3rd g "dimensionless Gibbs funcion and dervatives";
    ThermoSysPro.Properties.WaterSteam.Common.HelmholtzDerivs3rd f "dimensionless Helmholtz function and dervatives";
    Modelica.SIunits.Pressure plim=min(p, ThermoSysPro.Properties.WaterSteam.BaseIF97.data.PCRIT - 1e-07) "pressure limited to critical pressure - epsilon";
    Modelica.SIunits.SpecificVolume v "Specific Volume";
    Real vp3 "vp^3";
    Real ivp3 "1/vp^3";
    Real pv "partial derivative of p w.r.t v";
    Real pv2 "pv^2";
    Real pv3 "pv^3";
    Real ptv "2nd partial derivative of p w.r.t t and v";
    Real pvv "2nd partial derivative of p w.r.t v and v";
  algorithm
    bpro.T:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tsat(plim);
    (bpro.dpT,bpro.dpTT):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.d2ptofT(bpro.T);
    if not bpro.T > ThermoSysPro.Properties.WaterSteam.BaseIF97.data.TLIMIT1 then
      g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g2L3(p, bpro.T);
      bpro.d:=p/(g.R*bpro.T*g.pi*g.gpi);
      bpro.h:=if p > plim then ThermoSysPro.Properties.WaterSteam.BaseIF97.data.HCRIT else g.R*bpro.T*g.tau*g.gtau;
      bpro.s:=g.R*(g.tau*g.gtau - g.g);
      bpro.cp:=-g.R*g.tau*g.tau*g.gtautau;
      bpro.vt:=g.R/p*(g.pi*g.gpi - g.tau*g.pi*g.gpitau);
      bpro.vp:=g.R*bpro.T/(p*p)*g.pi*g.pi*g.gpipi;
      bpro.pt:=-p/bpro.T*(g.gpi - g.tau*g.gpitau)/(g.gpipi*g.pi);
      bpro.pd:=-g.R*bpro.T*g.gpi*g.gpi/g.gpipi;
      bpro.vtt:=g.R*g.pi/p*g.tau/bpro.T*g.tau*g.gpitautau;
      bpro.vtp:=g.R*g.pi*g.pi/(p*p)*(g.gpipi - g.tau*g.gpipitau);
      bpro.vpp:=g.R*bpro.T*g.pi*g.pi*g.pi/(p*p*p)*g.gpipipi;
      bpro.cpt:=g.R*g.tau*g.tau/bpro.T*(2*g.gtautau + g.tau*g.gtautautau);
      v:=1/bpro.d;
      vp3:=bpro.vp*bpro.vp*bpro.vp;
      ivp3:=1/vp3;
      bpro.ptt:=-(bpro.vtt*bpro.vp*bpro.vp - 2.0*bpro.vt*bpro.vtp*bpro.vp + bpro.vt*bpro.vt*bpro.vpp)*ivp3;
      bpro.pdd:=-bpro.vpp*ivp3*v*v*v*v - 2*v*bpro.pd "= pvv/d^4";
      bpro.ptd:=(bpro.vtp*bpro.vp - bpro.vt*bpro.vpp)*ivp3*v*v "= -ptv/d^2";
      bpro.cvt:=(vp3*bpro.cpt + bpro.vp*bpro.vp*bpro.vt*bpro.vt + 3.0*bpro.vp*bpro.vp*bpro.T*bpro.vt*bpro.vtt - 3.0*bpro.vtp*bpro.vp*bpro.T*bpro.vt*bpro.vt + bpro.T*bpro.vt*bpro.vt*bpro.vt*bpro.vpp)*ivp3;
    else
      bpro.d:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.rhov_p_R4b(plim);
      f:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3L3(bpro.d, bpro.T);
      bpro.h:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.hv_p_R4b(plim);
      bpro.s:=f.R*(f.tau*f.ftau - f.f);
      bpro.cv:=f.R*(-f.tau*f.tau*f.ftautau);
      bpro.pt:=f.R*bpro.d*f.delta*(f.fdelta - f.tau*f.fdeltatau);
      bpro.pd:=f.R*bpro.T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
      pv:=-f.d*f.d*bpro.pd;
      bpro.vp:=1/pv;
      bpro.vt:=-bpro.pt/pv;
      bpro.pdd:=f.R*bpro.T*f.delta/bpro.d*(2.0*f.fdelta + 4.0*f.delta*f.fdeltadelta + f.delta*f.delta*f.fdeltadeltadelta);
      bpro.ptt:=f.R*bpro.d*f.delta*f.tau*f.tau/bpro.T*f.fdeltatautau;
      bpro.ptd:=f.R*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta - 2.0*f.tau*f.fdeltatau - f.delta*f.tau*f.fdeltadeltatau);
      bpro.cvt:=f.R*f.tau*f.tau/bpro.T*(2.0*f.ftautau + f.tau*f.ftautautau);
      bpro.cpt:=(bpro.cvt*bpro.pd + bpro.cv*bpro.ptd + (bpro.pt + 2.0*bpro.T*bpro.ptt)*bpro.pt/(bpro.d*bpro.d) - bpro.cp*bpro.ptd)/bpro.pd;
      pv2:=pv*pv;
      pv3:=pv2*pv;
      pvv:=bpro.pdd*f.d*f.d*f.d*f.d;
      ptv:=-f.d*f.d*bpro.ptd;
      bpro.vpp:=-pvv/pv3;
      bpro.vtt:=-(bpro.ptt*pv2 - 2.0*bpro.pt*ptv*pv + bpro.pt*bpro.pt*pvv)/pv3;
      bpro.vtp:=(-ptv*pv + bpro.pt*pvv)/pv3;
    end if;
  end dewcurveL3_p;

  function hvl_dp "derivative function for the specific enthalpy along the phase boundary"
    extends Modelica.Icons.Function;
    input Modelica.SIunits.Pressure p "pressure";
    input ThermoSysPro.Properties.WaterSteam.Common.IF97PhaseBoundaryProperties3rd bpro "property record";
    output Real dh_dp "derivative of specific enthalpy along the phase boundary";
  algorithm
    dh_dp:=1/bpro.d - bpro.T*bpro.vt + bpro.cp/bpro.dpT;
    annotation(derivative(noDerivative=bpro)=hvl_dp_der, Inline=false, LateInline=true);
  end hvl_dp;

  function hvl_dp_der "derivative function for the specific enthalpy along the phase boundary"
    extends Modelica.Icons.Function;
    input Modelica.SIunits.Pressure p "pressure";
    input ThermoSysPro.Properties.WaterSteam.Common.IF97PhaseBoundaryProperties3rd bpro "property record";
    input Real p_der "Pressure derivative";
    output Real dh_dp_der "Second derivative of specific enthalpy along the phase boundary";
  protected
    Real cpp "Derivative of cp w.r.t. p";
    Real pv "partial derivative of p w.r.t. v";
    Real pv2 "pv*pv";
    Real pv3 "pv*pv*pv";
    Real ptv "2nd partial derivative of p w.r.t t and v";
    Real pvv "2nd partial derivative of p w.r.t v and v";
  algorithm
    pv:=-bpro.d*bpro.d*bpro.pd;
    pv2:=pv*pv;
    pv3:=pv2*pv;
    pvv:=bpro.pdd*bpro.d*bpro.d*bpro.d*bpro.d;
    ptv:=-bpro.d*bpro.d*bpro.ptd;
    cpp:=bpro.T*(bpro.ptt*pv2 - 2.0*bpro.pt*ptv*pv + bpro.pt*bpro.pt*pvv)/pv3 "T*(ptt*pv^2 - 2*pt*ptv*pv + pt^2*pvv)/pv^3";
    dh_dp_der:=0.0;
    annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-100,100},{100,-100}}, lineColor={255,0,0}, lineThickness=0.5)}));
  end hvl_dp_der;

  function dhl_dp "derivative of liquid specific enthalpy on the boundary between regions 4 and 3 or 1 w.r.t pressure"
    extends Modelica.Icons.Function;
    input Modelica.SIunits.Pressure p "pressure";
    output Modelica.SIunits.DerEnthalpyByPressure dh_dp "specific enthalpy derivative w.r.t. pressure";
  algorithm
    dh_dp:=ThermoSysPro.Properties.WaterSteam.Region.hvl_dp(p, ThermoSysPro.Properties.WaterSteam.Region.boilingcurveL3_p(p));
    annotation(smoothOrder=2);
  end dhl_dp;

  function dhv_dp "derivative of vapour specific enthalpy on the boundary between regions 4 and 3 or 1 w.r.t pressure"
    extends Modelica.Icons.Function;
    input Modelica.SIunits.Pressure p "pressure";
    output Modelica.SIunits.DerEnthalpyByPressure dh_dp "specific enthalpy derivative w.r.t. pressure";
  algorithm
    dh_dp:=ThermoSysPro.Properties.WaterSteam.Region.hvl_dp(p, ThermoSysPro.Properties.WaterSteam.Region.dewcurveL3_p(p));
    annotation(smoothOrder=2);
  end dhv_dp;

  function drhovl_dp
    extends Modelica.Icons.Function;
    input Modelica.SIunits.Pressure p "saturation pressure";
    input ThermoSysPro.Properties.WaterSteam.Common.IF97PhaseBoundaryProperties3rd bpro "property record";
    output Real dd_dp(unit="kg/(m3.Pa)") "derivative of density along the phase boundary";
  algorithm
    dd_dp:=-bpro.d*bpro.d*(bpro.vp + bpro.vt/bpro.dpT);
    annotation(derivative(noDerivative=bpro)=drhovl_dp_der, Inline=false, LateInline=true);
  end drhovl_dp;

  function drhol_dp "derivative of density of saturated water w.r.t. pressure"
    extends Modelica.Icons.Function;
    input Modelica.SIunits.Pressure p "saturation pressure";
    output Modelica.SIunits.DerDensityByPressure dd_dp "derivative of density of water at the boiling point";
  algorithm
    dd_dp:=ThermoSysPro.Properties.WaterSteam.Region.drhovl_dp(p, ThermoSysPro.Properties.WaterSteam.Region.boilingcurveL3_p(p));
  end drhol_dp;

  function drhov_dp "derivative of density of saturated steam w.r.t. pressure"
    extends Modelica.Icons.Function;
    input Modelica.SIunits.Pressure p "saturation pressure";
    output Modelica.SIunits.DerDensityByPressure dd_dp "derivative of density of water at the boiling point";
  algorithm
    dd_dp:=ThermoSysPro.Properties.WaterSteam.Region.drhovl_dp(p, ThermoSysPro.Properties.WaterSteam.Region.dewcurveL3_p(p));
  end drhov_dp;

  function drhovl_dp_der "Time derivative of density derivative along phase boundary"
    extends Modelica.Icons.Function;
    input Modelica.SIunits.Pressure p "saturation pressure";
    input ThermoSysPro.Properties.WaterSteam.Common.IF97PhaseBoundaryProperties3rd bpro "property record";
    input Real p_der "Time derivative of pressure";
    output Real dd_dp_der "derivative of density along the phase boundary";
  algorithm
    dd_dp_der:=0.0;
  end drhovl_dp_der;

end Region;
