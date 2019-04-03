within ThermoSysPro.Properties.WaterSteam;
package IF97_Utilities "Low level and utility computation for high accuracy water properties according to the IAPWS/IF97 standard"
  extends Modelica.Icons.Library;
  replaceable record iter= ThermoSysPro.Properties.WaterSteam.BaseIF97.IterationData;
  package AnalyticDerivatives "Functions with analytic derivatives"
    import ThermoSysPro.Properties.WaterSteam.BaseIF97.*;
    function waterBasePropAnalytic_ph "intermediate property record for water"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input Integer phase=0 "phase: 2 for two-phase, 1 for one phase, 0 if unknown";
      input Integer region=0 "if 0, do region computation, otherwise assume the region is this input";
      output ThermoSysPro.Properties.WaterSteam.Common.IF97TwoPhaseAnalytic aux "auxiliary record";
    protected
      ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs3rd g "dimensionless Gibbs funcion and dervatives wrt pi and tau";
      ThermoSysPro.Properties.WaterSteam.Common.HelmholtzDerivs3rd f "dimensionless Helmholtz funcion and dervatives wrt delta and tau";
      Integer error "error flag for inverse iterations";
      Modelica.SIunits.SpecificEnthalpy h_liq "liquid specific enthalpy";
      Modelica.SIunits.Density d_liq "liquid density";
      Modelica.SIunits.SpecificEnthalpy h_vap "vapour specific enthalpy";
      Modelica.SIunits.Density d_vap "vapour density";
      ThermoSysPro.Properties.WaterSteam.Common.PhaseBoundaryProperties3rd liq "phase boundary property record";
      ThermoSysPro.Properties.WaterSteam.Common.PhaseBoundaryProperties3rd vap "phase boundary property record";
      ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs3rd gl "dimensionless Gibbs funcion and dervatives wrt pi and tau";
      ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs3rd gv "dimensionless Gibbs funcion and dervatives wrt pi and tau";
      ThermoSysPro.Properties.WaterSteam.Common.HelmholtzDerivs3rd fl "dimensionless Helmholtz function and dervatives wrt delta and tau";
      ThermoSysPro.Properties.WaterSteam.Common.HelmholtzDerivs3rd fv "dimensionless Helmholtz function and dervatives wrt delta and tau";
      Modelica.SIunits.Temperature t1 "temperature at phase boundary, using inverse from region 1";
      Modelica.SIunits.Temperature t2 "temperature at phase boundary, using inverse from region 2";
      Real dxv "der of x wrt v";
      Real dxd "der of x wrt d";
      Real dvTl "der of v wrt T at boiling";
      Real dvTv "der of v wrt T at dew";
      Real dxT "der of x wrt T";
      Real duTl "der of u wrt T at boiling";
      Real duTv "der of u wrt T at dew";
      Real dpTT "2nd der of p wrt T";
      Real dxdd "2nd der of x wrt d";
      Real dxTd "2nd der of x wrt d and T";
      Real dvTTl "2nd der of v wrt T at boiling";
      Real dvTTv "2nd der of v wrt T at dew";
      Real dxTT " 2nd der of x wrt T";
      Real duTTl "2nd der of u wrt T at boiling";
      Real duTTv "2nd der of u wrt T at dew";
      Real vp3 "vp^3";
      Real ivp3 "1/vp3";
      Modelica.SIunits.SpecificVolume v;
    algorithm
      aux.region:=if region == 0 then if phase == 2 then 4 else ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.region_ph(p=p, h=h, phase=phase) else region;
      aux.phase:=if phase <> 0 then phase else if aux.region == 4 then 2 else 1;
      aux.p:=max(p, 611.657);
      aux.h:=max(h, 1000.0);
      aux.R:=ThermoSysPro.Properties.WaterSteam.BaseIF97.data.RH2O;
      if aux.region == 1 or aux.region == 2 or aux.region == 5 then
        if aux.region == 1 then
          aux.T:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tph1(aux.p, aux.h);
          g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g1L3(p, aux.T);
          aux.x:=0.0;
        elseif aux.region == 2 then
          aux.T:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tph2(aux.p, aux.h);
          g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g2L3(p, aux.T);
          aux.x:=1.0;
        else
          (aux.T,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.tofph5(p=aux.p, h=aux.h, reldh=1e-07);
          assert(error == 0, "error in inverse iteration of steam tables");
          g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g5L3(p, aux.T);
          aux.x:=1.0;
        end if;
        aux.s:=aux.R*(g.tau*g.gtau - g.g);
        aux.rho:=p/(aux.R*aux.T*g.pi*g.gpi);
        aux.vt:=aux.R/p*(g.pi*g.gpi - g.tau*g.pi*g.gpitau);
        aux.vp:=aux.R*aux.T/(p*p)*g.pi*g.pi*g.gpipi;
        aux.cp:=-aux.R*g.tau*g.tau*g.gtautau;
        aux.cv:=aux.R*(-g.tau*g.tau*g.gtautau + (g.gpi - g.tau*g.gpitau)*(g.gpi - g.tau*g.gpitau)/g.gpipi);
        aux.dpT:=-aux.vt/aux.vp;
        aux.vtt:=aux.R*g.pi/p*g.tau/aux.T*g.tau*g.gpitautau;
        aux.vtp:=aux.R*g.pi*g.pi/(p*p)*(g.gpipi - g.tau*g.gpipitau);
        aux.vpp:=aux.R*aux.T*g.pi*g.pi*g.pi/(p*p*p)*g.gpipipi;
        aux.cpt:=aux.R*g.tau*g.tau/aux.T*(2*g.gtautau + g.tau*g.gtautautau);
        aux.pt:=-g.p/g.T*(g.gpi - g.tau*g.gpitau)/(g.gpipi*g.pi);
        aux.pd:=-g.R*g.T*g.gpi*g.gpi/g.gpipi;
        v:=1/aux.rho;
        vp3:=aux.vp*aux.vp*aux.vp;
        ivp3:=1/vp3;
        aux.ptt:=-(aux.vtt*aux.vp*aux.vp - 2.0*aux.vt*aux.vtp*aux.vp + aux.vt*aux.vt*aux.vpp)*ivp3;
        aux.pdd:=-aux.vpp*ivp3*v*v*v*v - 2*v*aux.pd "= pvv/d^4";
        aux.ptd:=(aux.vtp*aux.vp - aux.vt*aux.vpp)*ivp3*v*v "= -ptv/d^2";
        aux.cvt:=(vp3*aux.cpt + aux.vp*aux.vp*aux.vt*aux.vt + 3.0*aux.vp*aux.vp*aux.T*aux.vt*aux.vtt - 3.0*aux.vtp*aux.vp*aux.T*aux.vt*aux.vt + aux.T*aux.vt*aux.vt*aux.vt*aux.vpp)*ivp3;
      elseif aux.region == 3 then
        (aux.rho,aux.T,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.dtofph3(p=aux.p, h=aux.h, delp=1e-07, delh=1e-06);
        f:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3L3(aux.rho, aux.T);
        aux.h:=aux.R*aux.T*(f.tau*f.ftau + f.delta*f.fdelta);
        aux.s:=aux.R*(f.tau*f.ftau - f.f);
        aux.pd:=aux.R*aux.T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
        aux.pt:=aux.R*aux.rho*f.delta*(f.fdelta - f.tau*f.fdeltatau);
        aux.cv:=abs(aux.R*(-f.tau*f.tau*f.ftautau)) "can be close to neg. infinity near critical point";
        aux.cp:=(aux.rho*aux.rho*aux.pd*aux.cv + aux.T*aux.pt*aux.pt)/(aux.rho*aux.rho*aux.pd);
        aux.x:=0.0;
        aux.dpT:=aux.pt;
        aux.pdd:=aux.R*aux.T*f.delta/aux.rho*(2.0*f.fdelta + 4.0*f.delta*f.fdeltadelta + f.delta*f.delta*f.fdeltadeltadelta);
        aux.ptt:=aux.R*aux.rho*f.delta*f.tau*f.tau/aux.T*f.fdeltatautau;
        aux.ptd:=aux.R*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta - 2.0*f.tau*f.fdeltatau - f.delta*f.tau*f.fdeltadeltatau);
        aux.cvt:=aux.R*f.tau*f.tau/aux.T*(2.0*f.ftautau + f.tau*f.ftautautau);
        aux.cpt:=(aux.cvt*aux.pd + aux.cv*aux.ptd + (aux.pt + 2.0*aux.T*aux.ptt)*aux.pt/(aux.rho*aux.rho) - aux.cp*aux.ptd)/aux.pd;

      elseif aux.region == 4 then
        h_liq:=hl_p(p);
        h_vap:=hv_p(p);
        aux.x:=if h_vap <> h_liq then (h - h_liq)/(h_vap - h_liq) else 1.0;
        if p < ThermoSysPro.Properties.WaterSteam.BaseIF97.data.PLIMIT4A then
          t1:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tph1(aux.p, h_liq);
          t2:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tph2(aux.p, h_vap);
          gl:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g1L3(aux.p, t1);
          gv:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g2L3(aux.p, t2);
          liq:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToBoundaryProps3rd(gl);
          vap:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToBoundaryProps3rd(gv);
          aux.T:=t1 + aux.x*(t2 - t1);
        else
          aux.T:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tsat(aux.p);
          d_liq:=rhol_T(aux.T);
          d_vap:=rhov_T(aux.T);
          fl:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3L3(d_liq, aux.T);
          fv:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3L3(d_vap, aux.T);
          liq:=ThermoSysPro.Properties.WaterSteam.Common.helmholtzToBoundaryProps3rd(fl);
          vap:=ThermoSysPro.Properties.WaterSteam.Common.helmholtzToBoundaryProps3rd(fv);
        end if;
        aux.rho:=liq.d*vap.d/(vap.d + aux.x*(liq.d - vap.d));
        dxv:=if liq.d <> vap.d then liq.d*vap.d/(liq.d - vap.d) else 0.0;
        dxd:=-dxv/(aux.rho*aux.rho);
        aux.dpT:=if liq.d <> vap.d then (vap.s - liq.s)*dxv else ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.dptofT(aux.T);
        dvTl:=(liq.pt - aux.dpT)/(liq.pd*liq.d*liq.d);
        dvTv:=(vap.pt - aux.dpT)/(vap.pd*vap.d*vap.d);
        dxT:=-dxv*(dvTl + aux.x*(dvTv - dvTl));
        duTl:=liq.cv + (aux.T*liq.pt - p)*dvTl;
        duTv:=vap.cv + (aux.T*vap.pt - p)*dvTv;
        aux.cv:=duTl + aux.x*(duTv - duTl) + dxT*(vap.u - liq.u);
        dpTT:=dxv*(vap.cv/aux.T - liq.cv/aux.T + dvTv*(vap.pt - aux.dpT) - dvTl*(liq.pt - aux.dpT));
        dxdd:=2.0*dxv/(aux.rho*aux.rho*aux.rho);
        dxTd:=dxv*dxv*(dvTv - dvTl)/(aux.rho*aux.rho);
        dvTTl:=((liq.ptt - dpTT)/(liq.d*liq.d) + dvTl*(liq.d*dvTl*(2.0*liq.pd + liq.d*liq.pdd) - 2.0*liq.ptd))/liq.pd;
        dvTTv:=((vap.ptt - dpTT)/(vap.d*vap.d) + dvTv*(vap.d*dvTv*(2.0*vap.pd + vap.d*vap.pdd) - 2.0*vap.ptd))/vap.pd;
        dxTT:=-dxv*(2.0*dxT*(dvTv - dvTl) + dvTTl + aux.x*(dvTTv - dvTTl));
        duTTl:=liq.cvt + (liq.pt - aux.dpT + aux.T*(2.0*liq.ptt - liq.d*liq.d*liq.ptd*dvTl))*dvTl + (aux.T*liq.pt - p)*dvTTl;
        duTTv:=vap.cvt + (vap.pt - aux.dpT + aux.T*(2.0*vap.ptt - vap.d*vap.d*vap.ptd*dvTv))*dvTv + (aux.T*vap.pt - p)*dvTTv;
        aux.cvt:=duTTl + aux.x*(duTTv - duTTl) + 2.0*dxT*(duTv - duTl) + dxTT*(vap.u - liq.u);
        aux.s:=liq.s + aux.x*(vap.s - liq.s);
        aux.cp:=liq.cp + aux.x*(vap.cp - liq.cp);
        aux.pt:=liq.pt + aux.x*(vap.pt - liq.pt);
        aux.pd:=liq.pd + aux.x*(vap.pd - liq.pd);
        aux.vt:=dvTl + aux.x*(dvTv - dvTl) + dxT*(1/vap.d - 1/liq.d);
        aux.vp:=aux.vt/aux.dpT;
        aux.pdd:=0.0;
        aux.ptd:=0.0;
        aux.ptt:=dpTT;
        aux.vtt:=dvTTl + aux.x*(dvTTv - dvTTl);
        aux.vtp:=aux.vtt/aux.dpT;
      else
        assert(false, "error in region computation of IF97 steam tables" + "(p = " + String(p) + ", h = " + String(h) + ")");
      end if;
      annotation(Icon);
    end waterBasePropAnalytic_ph;

    function waterBasePropAnalytic_pT "intermediate property record for water (p and T prefered states)"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature";
      input Integer region=0 "if 0, do region computation, otherwise assume the region is this input";
      output ThermoSysPro.Properties.WaterSteam.Common.IF97TwoPhaseAnalytic aux "auxiliary record";
    protected
      ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs3rd g "dimensionless Gibbs funcion and dervatives wrt pi and tau";
      ThermoSysPro.Properties.WaterSteam.Common.HelmholtzDerivs3rd f "dimensionless Helmholtz funcion and dervatives wrt delta and tau";
      Real vp3 "vp^3";
      Real ivp3 "1/vp3";
      Modelica.SIunits.SpecificVolume v;
      Integer error "error flag for inverse iterations";
    algorithm
      aux.phase:=1;
      aux.region:=if region == 0 then ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.region_pT(p=p, T=T) else region;
      aux.R:=ThermoSysPro.Properties.WaterSteam.BaseIF97.data.RH2O;
      aux.p:=p;
      aux.T:=T;
      if aux.region == 1 or aux.region == 2 or aux.region == 5 then
        if aux.region == 1 then
          g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g1L3(p, T);
          aux.x:=0.0;
        elseif aux.region == 2 then
          g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g2L3(p, T);
          aux.x:=1.0;
        else
          g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g5L3(p, T);
          aux.x:=1.0;
        end if;
        aux.h:=aux.R*aux.T*g.tau*g.gtau;
        aux.s:=aux.R*(g.tau*g.gtau - g.g);
        aux.rho:=p/(aux.R*T*g.pi*g.gpi);
        aux.vt:=aux.R/p*(g.pi*g.gpi - g.tau*g.pi*g.gpitau);
        aux.vp:=aux.R*T/(p*p)*g.pi*g.pi*g.gpipi;
        aux.cp:=-aux.R*g.tau*g.tau*g.gtautau;
        aux.cv:=aux.R*(-g.tau*g.tau*g.gtautau + (g.gpi - g.tau*g.gpitau)*(g.gpi - g.tau*g.gpitau)/g.gpipi);
        aux.x:=0.0;
        aux.vtt:=aux.R*g.pi/aux.p*g.tau/aux.T*g.tau*g.gpitautau;
        aux.vtp:=aux.R*g.pi*g.pi/(aux.p*aux.p)*(g.gpipi - g.tau*g.gpipitau);
        aux.vpp:=aux.R*aux.T*g.pi*g.pi*g.pi/(aux.p*aux.p*aux.p)*g.gpipipi;
        aux.cpt:=aux.R*g.tau*g.tau/aux.T*(2*g.gtautau + g.tau*g.gtautautau);
        aux.pt:=-g.p/g.T*(g.gpi - g.tau*g.gpitau)/(g.gpipi*g.pi);
        aux.pd:=-g.R*g.T*g.gpi*g.gpi/g.gpipi;
        v:=1/aux.rho;
        vp3:=aux.vp*aux.vp*aux.vp;
        ivp3:=1/vp3;
        aux.ptt:=-(aux.vtt*aux.vp*aux.vp - 2.0*aux.vt*aux.vtp*aux.vp + aux.vt*aux.vt*aux.vpp)*ivp3;
        aux.pdd:=-aux.vpp*ivp3*v*v*v*v - 2*v*aux.pd;
        aux.ptd:=(aux.vtp*aux.vp - aux.vt*aux.vpp)*ivp3*v*v "= -ptv/d^2";
        aux.cvt:=(vp3*aux.cpt + aux.vp*aux.vp*aux.vt*aux.vt + 3.0*aux.vp*aux.vp*aux.T*aux.vt*aux.vtt - 3.0*aux.vtp*aux.vp*aux.T*aux.vt*aux.vt + aux.T*aux.vt*aux.vt*aux.vt*aux.vpp)*ivp3;
      elseif aux.region == 3 then
        (aux.rho,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.dofpt3(p=p, T=T, delp=1e-07);
        f:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3L3(aux.rho, T);
        aux.h:=aux.R*T*(f.tau*f.ftau + f.delta*f.fdelta);
        aux.s:=aux.R*(f.tau*f.ftau - f.f);
        aux.pd:=aux.R*T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
        aux.pt:=aux.R*aux.rho*f.delta*(f.fdelta - f.tau*f.fdeltatau);
        aux.cv:=aux.R*(-f.tau*f.tau*f.ftautau);
        aux.x:=0.0;
        aux.pdd:=aux.R*aux.T*f.delta/aux.rho*(2.0*f.fdelta + 4.0*f.delta*f.fdeltadelta + f.delta*f.delta*f.fdeltadeltadelta);
        aux.ptt:=aux.R*aux.rho*f.delta*f.tau*f.tau/aux.T*f.fdeltatautau;
        aux.ptd:=aux.R*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta - 2.0*f.tau*f.fdeltatau - f.delta*f.tau*f.fdeltadeltatau);
        aux.cvt:=aux.R*f.tau*f.tau/aux.T*(2.0*f.ftautau + f.tau*f.ftautautau);
        aux.cpt:=(aux.cvt*aux.pd + aux.cv*aux.ptd + (aux.pt + 2.0*aux.T*aux.ptt)*aux.pt/(aux.rho*aux.rho) - aux.pt*aux.ptd)/aux.pd;
      else
        assert(false, "error in region computation of IF97 steam tables" + "(p = " + String(p) + ", T = " + String(T) + ")");
      end if;
    end waterBasePropAnalytic_pT;

    function waterBasePropAnalytic_dT "intermediate property record for water (d and T prefered states)"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density rho "density";
      input Modelica.SIunits.Temperature T "temperature";
      input Integer phase=0 "phase: 2 for two-phase, 1 for one phase, 0 if unknown";
      input Integer region=0 "if 0, do region computation, otherwise assume the region is this input";
      output ThermoSysPro.Properties.WaterSteam.Common.IF97TwoPhaseAnalytic aux "auxiliary record";
    protected
      Modelica.SIunits.SpecificEnthalpy h_liq "liquid specific enthalpy";
      Modelica.SIunits.Density d_liq "liquid density";
      Modelica.SIunits.SpecificEnthalpy h_vap "vapour specific enthalpy";
      Modelica.SIunits.Density d_vap "vapour density";
      ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs3rd g "dimensionless Gibbs funcion and dervatives wrt pi and tau";
      ThermoSysPro.Properties.WaterSteam.Common.HelmholtzDerivs3rd f "dimensionless Helmholtz funcion and dervatives wrt delta and tau";
      ThermoSysPro.Properties.WaterSteam.Common.PhaseBoundaryProperties3rd liq "phase boundary property record";
      ThermoSysPro.Properties.WaterSteam.Common.PhaseBoundaryProperties3rd vap "phase boundary property record";
      ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs3rd gl "dimensionless Gibbs funcion and dervatives wrt pi and tau";
      ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs3rd gv "dimensionless Gibbs funcion and dervatives wrt pi and tau";
      ThermoSysPro.Properties.WaterSteam.Common.HelmholtzDerivs3rd fl "dimensionless Helmholtz function and dervatives wrt delta and tau";
      ThermoSysPro.Properties.WaterSteam.Common.HelmholtzDerivs3rd fv "dimensionless Helmholtz function and dervatives wrt delta and tau";
      Integer error "error flag for inverse iterations";
      Real dxv "der of x wrt v";
      Real dxd "der of x wrt d";
      Real dvTl "der of v wrt T at boiling";
      Real dvTv "der of v wrt T at dew";
      Real dxT "der of x wrt T";
      Real duTl "der of u wrt T at boiling";
      Real duTv "der of u wrt T at dew";
      Real dpTT "2nd der of p wrt T";
      Real dxdd "2nd der of x wrt d";
      Real dxTd "2nd der of x wrt d and T";
      Real dvTTl "2nd der of v wrt T at boiling";
      Real dvTTv "2nd der of v wrt T at dew";
      Real dxTT " 2nd der of x wrt T";
      Real duTTl "2nd der of u wrt T at boiling";
      Real duTTv "2nd der of u wrt T at dew";
      Real vp3 "vp^3";
      Real ivp3 "1/vp3";
      Modelica.SIunits.SpecificVolume v;
    algorithm
      aux.region:=if region == 0 then if phase == 2 then 4 else ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.region_dT(d=rho, T=T, phase=phase) else region;
      aux.phase:=if aux.region == 4 then 2 else 1;
      aux.R:=ThermoSysPro.Properties.WaterSteam.BaseIF97.data.RH2O;
      aux.rho:=rho;
      aux.T:=T;
      if aux.region == 1 or aux.region == 2 or aux.region == 5 then
        if aux.region == 1 then
          (aux.p,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.pofdt125(d=rho, T=T, reldd=1e-09, region=1);
          g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g1L3(aux.p, T);
          aux.x:=0.0;
        elseif aux.region == 2 then
          (aux.p,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.pofdt125(d=rho, T=T, reldd=1e-08, region=2);
          g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g2L3(aux.p, T);
          aux.x:=1.0;
        else
          (aux.p,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.pofdt125(d=rho, T=T, reldd=1e-08, region=5);
          g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g2L3(aux.p, T);
          aux.x:=1.0;
        end if;
        aux.h:=aux.R*aux.T*g.tau*g.gtau;
        aux.s:=aux.R*(g.tau*g.gtau - g.g);
        aux.rho:=aux.p/(aux.R*T*g.pi*g.gpi);
        aux.vt:=aux.R/aux.p*(g.pi*g.gpi - g.tau*g.pi*g.gpitau);
        aux.vp:=aux.R*T/(aux.p*aux.p)*g.pi*g.pi*g.gpipi;
        aux.cp:=-aux.R*g.tau*g.tau*g.gtautau;
        aux.cv:=aux.R*(-g.tau*g.tau*g.gtautau + (g.gpi - g.tau*g.gpitau)*(g.gpi - g.tau*g.gpitau)/g.gpipi);
        aux.vtt:=aux.R*g.pi/aux.p*g.tau/aux.T*g.tau*g.gpitautau;
        aux.vtp:=aux.R*g.pi*g.pi/(aux.p*aux.p)*(g.gpipi - g.tau*g.gpipitau);
        aux.vpp:=aux.R*aux.T*g.pi*g.pi*g.pi/(aux.p*aux.p*aux.p)*g.gpipipi;
        aux.cpt:=aux.R*g.tau*g.tau/aux.T*(2*g.gtautau + g.tau*g.gtautautau);
        aux.pt:=-g.p/g.T*(g.gpi - g.tau*g.gpitau)/(g.gpipi*g.pi);
        aux.pd:=-g.R*g.T*g.gpi*g.gpi/g.gpipi;
        v:=1/aux.rho;
        vp3:=aux.vp*aux.vp*aux.vp;
        ivp3:=1/vp3;
        aux.ptt:=-(aux.vtt*aux.vp*aux.vp - 2.0*aux.vt*aux.vtp*aux.vp + aux.vt*aux.vt*aux.vpp)*ivp3;
        aux.pdd:=-aux.vpp*ivp3*v*v*v*v - 2*v*aux.pd;
        aux.ptd:=(aux.vtp*aux.vp - aux.vt*aux.vpp)*ivp3*v*v "= -ptv/d^2";
        aux.cvt:=(vp3*aux.cpt + aux.vp*aux.vp*aux.vt*aux.vt + 3.0*aux.vp*aux.vp*aux.T*aux.vt*aux.vtt - 3.0*aux.vtp*aux.vp*aux.T*aux.vt*aux.vt + aux.T*aux.vt*aux.vt*aux.vt*aux.vpp)*ivp3;
      elseif aux.region == 3 then
        f:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3L3(rho, T);
        aux.p:=aux.R*rho*T*f.delta*f.fdelta;
        aux.h:=aux.R*T*(f.tau*f.ftau + f.delta*f.fdelta);
        aux.s:=aux.R*(f.tau*f.ftau - f.f);
        aux.pd:=aux.R*T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
        aux.pt:=aux.R*rho*f.delta*(f.fdelta - f.tau*f.fdeltatau);
        aux.cp:=(aux.rho*aux.rho*aux.pd*aux.cv + aux.T*aux.pt*aux.pt)/(aux.rho*aux.rho*aux.pd);
        aux.cv:=aux.R*(-f.tau*f.tau*f.ftautau);
        aux.x:=0.0;
        aux.dpT:=aux.pt;
        aux.pdd:=aux.R*aux.T*f.delta/aux.rho*(2.0*f.fdelta + 4.0*f.delta*f.fdeltadelta + f.delta*f.delta*f.fdeltadeltadelta);
        aux.ptt:=aux.R*aux.rho*f.delta*f.tau*f.tau/aux.T*f.fdeltatautau;
        aux.ptd:=aux.R*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta - 2.0*f.tau*f.fdeltatau - f.delta*f.tau*f.fdeltadeltatau);
        aux.cvt:=aux.R*f.tau*f.tau/aux.T*(2.0*f.ftautau + f.tau*f.ftautautau);
        aux.cpt:=(aux.cvt*aux.pd + aux.cv*aux.ptd + (aux.pt + 2.0*aux.T*aux.ptt)*aux.pt/(aux.rho*aux.rho) - aux.pt*aux.ptd)/aux.pd;

      elseif aux.region == 4 then
        aux.p:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.psat(T);
        d_liq:=rhol_T(T);
        d_vap:=rhov_T(T);
        h_liq:=hl_p(aux.p);
        h_vap:=hv_p(aux.p);
        aux.x:=if d_vap <> d_liq then (1/rho - 1/d_liq)/(1/d_vap - 1/d_liq) else 1.0;
        aux.h:=h_liq + aux.x*(h_vap - h_liq);
        if T < ThermoSysPro.Properties.WaterSteam.BaseIF97.data.TLIMIT1 then
          gl:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g1L3(aux.p, T);
          gv:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g2L3(aux.p, T);
          liq:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToBoundaryProps3rd(gl);
          vap:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToBoundaryProps3rd(gv);
        else
          fl:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3L3(d_liq, T);
          fv:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3L3(d_vap, T);
          liq:=ThermoSysPro.Properties.WaterSteam.Common.helmholtzToBoundaryProps3rd(fl);
          vap:=ThermoSysPro.Properties.WaterSteam.Common.helmholtzToBoundaryProps3rd(fv);
        end if;
        aux.s:=liq.s + aux.x*(vap.s - liq.s);
        dxv:=if liq.d <> vap.d then liq.d*vap.d/(liq.d - vap.d) else 0.0;
        dxd:=-dxv/(aux.rho*aux.rho);
        aux.dpT:=if liq.d <> vap.d then (vap.s - liq.s)*dxv else ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.dptofT(aux.T);
        dvTl:=(liq.pt - aux.dpT)/(liq.pd*liq.d*liq.d);
        dvTv:=(vap.pt - aux.dpT)/(vap.pd*vap.d*vap.d);
        dxT:=-dxv*(dvTl + aux.x*(dvTv - dvTl));
        duTl:=liq.cv + (aux.T*liq.pt - aux.p)*dvTl;
        duTv:=vap.cv + (aux.T*vap.pt - aux.p)*dvTv;
        aux.cv:=duTl + aux.x*(duTv - duTl) + dxT*(vap.u - liq.u);
        dpTT:=dxv*(vap.cv/aux.T - liq.cv/aux.T + dvTv*(vap.pt - aux.dpT) - dvTl*(liq.pt - aux.dpT));
        dxdd:=2.0*dxv/(aux.rho*aux.rho*aux.rho);
        dxTd:=dxv*dxv*(dvTv - dvTl)/(aux.rho*aux.rho);
        dvTTl:=((liq.ptt - dpTT)/(liq.d*liq.d) + dvTl*(liq.d*dvTl*(2.0*liq.pd + liq.d*liq.pdd) - 2.0*liq.ptd))/liq.pd;
        dvTTv:=((vap.ptt - dpTT)/(vap.d*vap.d) + dvTv*(vap.d*dvTv*(2.0*vap.pd + vap.d*vap.pdd) - 2.0*vap.ptd))/vap.pd;
        dxTT:=-dxv*(2.0*dxT*(dvTv - dvTl) + dvTTl + aux.x*(dvTTv - dvTTl));
        duTTl:=liq.cvt + (liq.pt - aux.dpT + aux.T*(2.0*liq.ptt - liq.d*liq.d*liq.ptd*dvTl))*dvTl + (aux.T*liq.pt - aux.p)*dvTTl;
        duTTv:=vap.cvt + (vap.pt - aux.dpT + aux.T*(2.0*vap.ptt - vap.d*vap.d*vap.ptd*dvTv))*dvTv + (aux.T*vap.pt - aux.p)*dvTTv;
        aux.cvt:=duTTl + aux.x*(duTTv - duTTl) + 2.0*dxT*(duTv - duTl) + dxTT*(vap.u - liq.u);
        aux.cp:=liq.cp + aux.x*(vap.cp - liq.cp);
        aux.pt:=liq.pt + aux.x*(vap.pt - liq.pt);
        aux.pd:=liq.pd + aux.x*(vap.pd - liq.pd);
        aux.ptt:=dpTT;
      else
        assert(false, "error in region computation of IF97 steam tables" + "(rho = " + String(rho) + ", T = " + String(T) + ")");
      end if;
    end waterBasePropAnalytic_dT;

    function waterBaseProp_ps "intermediate property record for water"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEntropy s "specific entropy";
      input Integer phase=0 "phase: 2 for two-phase, 1 for one phase, 0 if unknown";
      input Integer region=0 "if 0, do region computation, otherwise assume the region is this input";
      output ThermoSysPro.Properties.WaterSteam.Common.IF97BaseTwoPhase aux "auxiliary record";
    protected
      ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs g "dimensionless Gibbs funcion and dervatives wrt pi and tau";
      ThermoSysPro.Properties.WaterSteam.Common.HelmholtzDerivs f "dimensionless Helmholtz funcion and dervatives wrt delta and tau";
      Integer error "error flag for inverse iterations";
      Modelica.SIunits.SpecificEntropy s_liq "liquid specific entropy";
      Modelica.SIunits.Density d_liq "liquid density";
      Modelica.SIunits.SpecificEntropy s_vap "vapour specific entropy";
      Modelica.SIunits.Density d_vap "vapour density";
      ThermoSysPro.Properties.WaterSteam.Common.PhaseBoundaryProperties liq "phase boundary property record";
      ThermoSysPro.Properties.WaterSteam.Common.PhaseBoundaryProperties vap "phase boundary property record";
      ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs gl "dimensionless Gibbs funcion and dervatives wrt pi and tau";
      ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs gv "dimensionless Gibbs funcion and dervatives wrt pi and tau";
      Modelica.Media.Common.HelmholtzDerivs fl "dimensionless Helmholtz function and dervatives wrt delta and tau";
      Modelica.Media.Common.HelmholtzDerivs fv "dimensionless Helmholtz function and dervatives wrt delta and tau";
      Modelica.SIunits.Temperature t1 "temperature at phase boundary, using inverse from region 1";
      Modelica.SIunits.Temperature t2 "temperature at phase boundary, using inverse from region 2";
    algorithm
      aux.region:=if region == 0 then if phase == 2 then 4 else ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.region_ps(p=p, s=s, phase=phase) else region;
      aux.phase:=if phase <> 0 then phase else if aux.region == 4 then 2 else 1;
      aux.p:=p;
      aux.s:=s;
      aux.R:=ThermoSysPro.Properties.WaterSteam.BaseIF97.data.RH2O;
      if aux.region == 1 then
        aux.T:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tps1(p, s);
        g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g1(p, aux.T);
        aux.h:=aux.R*aux.T*g.tau*g.gtau;
        aux.rho:=p/(aux.R*aux.T*g.pi*g.gpi);
        aux.vt:=aux.R/p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
        aux.vp:=aux.R*aux.T/(p*p)*g.pi*g.pi*g.gpipi;
        aux.cp:=-aux.R*g.tau*g.tau*g.gtautau;
        aux.cv:=aux.R*(-g.tau*g.tau*g.gtautau + (g.gpi - g.tau*g.gtaupi)*(g.gpi - g.tau*g.gtaupi)/g.gpipi);
        aux.x:=0.0;
      elseif aux.region == 2 then
        aux.T:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tps2(p, s);
        g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g2(p, aux.T);
        aux.h:=aux.R*aux.T*g.tau*g.gtau;
        aux.rho:=p/(aux.R*aux.T*g.pi*g.gpi);
        aux.vt:=aux.R/p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
        aux.vp:=aux.R*aux.T/(p*p)*g.pi*g.pi*g.gpipi;
        aux.cp:=-aux.R*g.tau*g.tau*g.gtautau;
        aux.cv:=aux.R*(-g.tau*g.tau*g.gtautau + (g.gpi - g.tau*g.gtaupi)*(g.gpi - g.tau*g.gtaupi)/g.gpipi);
        aux.x:=1.0;

      elseif aux.region == 3 then
        (aux.rho,aux.T,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.dtofps3(p=p, s=s, delp=1e-07, dels=1e-06);
        f:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3(aux.rho, aux.T);
        aux.h:=aux.R*aux.T*(f.tau*f.ftau + f.delta*f.fdelta);
        aux.s:=aux.R*(f.tau*f.ftau - f.f);
        aux.pd:=aux.R*aux.T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
        aux.pt:=aux.R*aux.rho*f.delta*(f.fdelta - f.tau*f.fdeltatau);
        aux.cv:=aux.R*(-f.tau*f.tau*f.ftautau);
        aux.cp:=(aux.rho*aux.rho*aux.pd*aux.cv + aux.T*aux.pt*aux.pt)/(aux.rho*aux.rho*aux.pd);
        aux.x:=0.0;

      elseif aux.region == 4 then
        s_liq:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.sl_p(p);
        s_vap:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.sv_p(p);
        aux.x:=if s_vap <> s_liq then (s - s_liq)/(s_vap - s_liq) else 1.0;
        if p < ThermoSysPro.Properties.WaterSteam.BaseIF97.data.PLIMIT4A then
          t1:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tps1(p, s_liq);
          t2:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tps2(p, s_vap);
          gl:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g1(p, t1);
          gv:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g2(p, t2);
          liq:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToBoundaryProps(gl);
          vap:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToBoundaryProps(gv);
          aux.T:=t1 + aux.x*(t2 - t1);
        else
          aux.T:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tsat(p);
          d_liq:=rhol_T(aux.T);
          d_vap:=rhov_T(aux.T);
          fl:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3(d_liq, aux.T);
          fv:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3(d_vap, aux.T);
          liq:=ThermoSysPro.Properties.WaterSteam.Common.helmholtzToBoundaryProps(fl);
          vap:=ThermoSysPro.Properties.WaterSteam.Common.helmholtzToBoundaryProps(fv);
        end if;
        aux.dpT:=if liq.d <> vap.d then (vap.s - liq.s)*liq.d*vap.d/(liq.d - vap.d) else ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.dptofT(aux.T);
        aux.h:=liq.h + aux.x*(vap.h - liq.h);
        aux.rho:=liq.d*vap.d/(vap.d + aux.x*(liq.d - vap.d));
        aux.cv:=ThermoSysPro.Properties.WaterSteam.Common.cv2Phase(liq, vap, aux.x, aux.T, p);
        aux.cp:=liq.cp + aux.x*(vap.cp - liq.cp);
        aux.pt:=liq.pt + aux.x*(vap.pt - liq.pt);
        aux.pd:=liq.pd + aux.x*(vap.pd - liq.pd);

      elseif aux.region == 5 then
        (aux.T,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.tofps5(p=p, s=s, relds=1e-07);
        assert(error == 0, "error in inverse iteration of steam tables");
        g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g5(p, aux.T);
        aux.h:=aux.R*aux.T*g.tau*g.gtau;
        aux.rho:=p/(aux.R*aux.T*g.pi*g.gpi);
        aux.vt:=aux.R/p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
        aux.vp:=aux.R*aux.T/(p*p)*g.pi*g.pi*g.gpipi;
        aux.cp:=-aux.R*g.tau*g.tau*g.gtautau;
        aux.cv:=aux.R*(-g.tau*g.tau*g.gtautau + (g.gpi - g.tau*g.gtaupi)*(g.gpi - g.tau*g.gtaupi)/g.gpipi);
      else
        assert(false, "error in region computation of IF97 steam tables" + "(p = " + String(p) + ", s = " + String(s) + ")");
      end if;
    end waterBaseProp_ps;

    replaceable record iter= ThermoSysPro.Properties.WaterSteam.BaseIF97.IterationData;
    function phase_ph "phase as a function of  pressure and specific enthalpy"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      output Integer phase "true if in liquid or gas or supercritical region";
    algorithm
      phase:=if h < hl_p(p) or h > hv_p(p) or p > ThermoSysPro.Properties.WaterSteam.BaseIF97.data.PCRIT then 1 else 2;
      annotation(InlineNoEvent=false);
    end phase_ph;

    function phase_dT "phase as a function of  pressure and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density rho "density";
      input Modelica.SIunits.Temperature T "temperature";
      output Integer phase "true if in liquid or gas or supercritical region";
    algorithm
      phase:=if not (rho < rhol_T(T) and rho > rhov_T(T) and T < ThermoSysPro.Properties.WaterSteam.BaseIF97.data.TCRIT) then 1 else 2;
      annotation(InlineNoEvent=false);
    end phase_dT;

    function rho_props_ph "density as function of pressure and specific enthalpy"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97TwoPhaseAnalytic aux "auxiliary record";
      output Modelica.SIunits.Density rho "density";
    algorithm
      rho:=aux.rho;
      annotation(derivative(noDerivative=aux)=rho_ph_d, Inline=false, LateInline=true);
    end rho_props_ph;

    function rho_ph "density as function of pressure and specific enthalpy"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.Density rho "density";
    algorithm
      rho:=rho_props_ph(p, h, waterBasePropAnalytic_ph(p, h, phase, region));
    end rho_ph;

    function rho_ph_d "derivative function of rho_ph"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97TwoPhaseAnalytic aux "auxiliary record";
      input Real p_d "derivative of pressure";
      input Real h_d "derivative of specific enthalpy";
      output Real rho_d "derivative of density";
    algorithm
      if aux.region == 4 then
        rho_d:=aux.rho*(aux.rho*aux.cv/aux.dpT + 1.0)/(aux.dpT*aux.T)*p_d + (-aux.rho*aux.rho/(aux.dpT*aux.T))*h_d;
      elseif aux.region == 3 then
        rho_d:=aux.rho*(aux.cv*aux.rho + aux.pt)/(aux.rho*aux.rho*aux.pd*aux.cv + aux.T*aux.pt*aux.pt)*p_d + (-aux.rho*aux.rho*aux.pt/(aux.rho*aux.rho*aux.pd*aux.cv + aux.T*aux.pt*aux.pt))*h_d;
      else
        rho_d:=(-aux.rho*aux.rho*(aux.vp*aux.cp - aux.vt/aux.rho + aux.T*aux.vt*aux.vt)/aux.cp)*p_d + (-aux.rho*aux.rho*aux.vt/aux.cp)*h_d;
      end if;
      annotation(derivative(noDerivative=aux)=rho_ph_dd);
    end rho_ph_d;

    function rho_ph_dd "Second order derivative function of rho_ph"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97TwoPhaseAnalytic aux "auxiliary record";
      input Real p_d "derivative of pressure";
      input Real h_d "derivative of specific enthalpy";
      input Real p_dd "second derivative of pressure";
      input Real h_dd "second derivative of specific enthalpy";
      output Real rho_dd "Second derivative of density";
    protected
      Modelica.SIunits.DerDensityByPressure ddph "Derivative of d by p at constant h";
      Modelica.SIunits.DerDensityByEnthalpy ddhp "Derivative of d by h at constant p";
      Real ddph_ph "Derivative of ddph by p";
      Real ddph_hp "Derivative of ddph by h";
      Real ddhp_hp "Derivative of ddhp by h";
      Real ddhp_ph "Derivative of ddhp by p";
    algorithm
      ddph:=ddph_props(p, h, aux);
      ddhp:=ddhp_props(p, h, aux);
      (ddph_ph,ddph_hp):=ddph_ph_dd(p, h, aux);
      (ddhp_hp,ddhp_ph):=ddhp_ph_dd(p, h, aux);
      rho_dd:=ddph*p_dd + 2.0*ddhp_ph*p_d*h_d + ddph_ph*p_d*p_d + ddhp_hp*h_d*h_d + ddhp*h_dd;
    end rho_ph_dd;

    function T_props_ph "temperature as function of pressure and specific enthalpy"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97TwoPhaseAnalytic properties "auxiliary record";
      output Modelica.SIunits.Temperature T "temperature";
    algorithm
      T:=properties.T;
      annotation(derivative(noDerivative=properties)=T_ph_der, Inline=false, LateInline=true);
    end T_props_ph;

    function T_ph "temperature as function of pressure and specific enthalpy"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.Temperature T "Temperature";
    algorithm
      T:=T_props_ph(p, h, waterBasePropAnalytic_ph(p, h, phase, region));
    end T_ph;

    function T_ph_der "derivative function of T_ph"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97TwoPhaseAnalytic aux "auxiliary record";
      input Real p_der "derivative of pressure";
      input Real h_der "derivative of specific enthalpy";
      output Real T_der "derivative of temperature";
    algorithm
      if aux.region == 4 then
        T_der:=1/aux.dpT*p_der;
      elseif aux.region == 3 then
        T_der:=(-aux.rho*aux.pd + aux.T*aux.pt)/(aux.rho*aux.rho*aux.pd*aux.cv + aux.T*aux.pt*aux.pt)*p_der + aux.rho*aux.rho*aux.pd/(aux.rho*aux.rho*aux.pd*aux.cv + aux.T*aux.pt*aux.pt)*h_der;
      else
        T_der:=(-1/aux.rho + aux.T*aux.vt)/aux.cp*p_der + 1/aux.cp*h_der;
      end if;
    end T_ph_der;

    function s_props_ph "specific entropy as function of pressure and specific enthalpy"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97TwoPhaseAnalytic properties "auxiliary record";
      output Modelica.SIunits.SpecificEntropy s "specific entropy";
    algorithm
      s:=properties.s;
      annotation(derivative(noDerivative=properties)=s_ph_der, Inline=false, LateInline=true);
    end s_props_ph;

    function s_ph "specific entropy as function of pressure and specific enthalpy"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.SpecificEntropy s "specific entropy";
    algorithm
      s:=s_props_ph(p, h, waterBasePropAnalytic_ph(p, h, phase, region));
    end s_ph;

    function s_ph_der "specific entropy as function of pressure and specific enthalpy"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97TwoPhaseAnalytic aux "auxiliary record";
      input Real p_der "derivative of pressure";
      input Real h_der "derivative of specific enthalpy";
      output Real s_der "derivative of entropy";
    algorithm
      s_der:=-1/(aux.rho*aux.T)*p_der + 1/aux.T*h_der;
    end s_ph_der;

    function cv_props_ph "specific heat capacity at constant volume as function of pressure and specific enthalpy"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97TwoPhaseAnalytic aux "auxiliary record";
      output Modelica.SIunits.SpecificHeatCapacity cv "specific heat capacity";
    algorithm
      cv:=aux.cv;
      annotation(Inline=false, LateInline=true);
    end cv_props_ph;

    function cv_ph "specific heat capacity at constant volume as function of pressure and specific enthalpy"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.SpecificHeatCapacity cv "specific heat capacity";
    algorithm
      cv:=cv_props_ph(p, h, waterBasePropAnalytic_ph(p, h, phase, region));
    end cv_ph;

    function regionAssertReal "assert function for inlining"
      extends Modelica.Icons.Function;
      input Boolean check "condition to check";
      output Real dummy "dummy output";
    algorithm
      assert(check, "this function can not be called with two-phase inputs!");
    end regionAssertReal;

    function cp_props_ph "specific heat capacity at constant pressure as function of pressure and specific enthalpy"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97TwoPhaseAnalytic aux "auxiliary record";
      output Modelica.SIunits.SpecificHeatCapacity cp "specific heat capacity";
    algorithm
      cp:=aux.cp;
      annotation(Inline=false, LateInline=true, derivative(noDerivative=aux)=cp_ph_der);
    end cp_props_ph;

    function cp_ph "specific heat capacity at constant pressure as function of pressure and specific enthalpy"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.SpecificHeatCapacity cp "specific heat capacity";
    algorithm
      cp:=cp_props_ph(p, h, waterBasePropAnalytic_ph(p, h, phase, region));
    end cp_ph;

    function cp_ph_der "derivative function of cp_ph"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97TwoPhaseAnalytic aux "auxiliary record";
      input Real p_der "derivative of pressure";
      input Real h_der "derivative of specific enthalpy";
      output Real cp_der "derivative of heat capacity";
    protected
      Real detPH "Determinant";
      Real dht;
      Real dhd;
      Real ddhp;
      Real ddph;
      Real dtph;
      Real dthp;
      Real detPH_d;
      Real dcp_d;
    algorithm
      if aux.region == 4 then
        cp_der:=0.0;
      elseif aux.region == 3 then
        detPH:=aux.cp*aux.pd;
        dht:=aux.cv + aux.pt/aux.rho;
        dhd:=(aux.pd - aux.T*aux.pt/aux.rho)/aux.rho;
        ddph:=dht/detPH;
        ddhp:=-aux.pt/detPH;
        dtph:=-dhd/detPH;
        dthp:=aux.pd/detPH;
        detPH_d:=aux.cv*aux.pdd + (2.0*aux.pt*(aux.ptd - aux.pt/aux.rho) - aux.ptt*aux.pd)*aux.T/(aux.rho*aux.rho);
        dcp_d:=(detPH_d - aux.cp*aux.pdd)/aux.pd;
        cp_der:=(ddph*dcp_d + dtph*aux.cpt)*p_der + (ddhp*dcp_d + dthp*aux.cpt)*h_der;
      else
        cp_der:=(-(aux.T*aux.vtt*aux.cp + aux.cpt/aux.rho - aux.cpt*aux.T*aux.vt)/aux.cp)*p_der + aux.cpt/aux.cp*h_der;
      end if;
      annotation(Documentation(info="<html></html>"));
    end cp_ph_der;

    function beta_props_ph "isobaric expansion coefficient as function of pressure and specific enthalpy"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97TwoPhaseAnalytic aux "auxiliary record";
      output Modelica.SIunits.RelativePressureCoefficient beta "isobaric expansion coefficient";
    algorithm
      beta:=if aux.region == 3 or aux.region == 4 then aux.pt/(aux.rho*aux.pd) else aux.vt*aux.rho;
      annotation(Inline=false, LateInline=true);
    end beta_props_ph;

    function beta_ph "isobaric expansion coefficient as function of pressure and specific enthalpy"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.RelativePressureCoefficient beta "isobaric expansion coefficient";
    algorithm
      beta:=beta_props_ph(p, h, waterBasePropAnalytic_ph(p, h, phase, region));
    end beta_ph;

    function kappa_props_ph "isothermal compressibility factor as function of pressure and specific enthalpy"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97TwoPhaseAnalytic aux "auxiliary record";
      output Modelica.SIunits.IsothermalCompressibility kappa "isothermal compressibility factor";
    algorithm
      kappa:=if aux.region == 3 or aux.region == 4 then 1/(aux.rho*aux.pd) else -aux.vp*aux.rho;
      annotation(Inline=false, LateInline=true);
    end kappa_props_ph;

    function kappa_ph "isothermal compressibility factor as function of pressure and specific enthalpy"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.IsothermalCompressibility kappa "isothermal compressibility factor";
    algorithm
      kappa:=kappa_props_ph(p, h, waterBasePropAnalytic_ph(p, h, phase, region));
    end kappa_ph;

    function velocityOfSound_props_ph "speed of sound as function of pressure and specific enthalpy"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97TwoPhaseAnalytic aux "auxiliary record";
      output Modelica.SIunits.Velocity v_sound "speed of sound";
    algorithm
      v_sound:=if aux.region == 3 then sqrt((aux.pd*aux.rho*aux.rho*aux.cv + aux.pt*aux.pt*aux.T)/(aux.rho*aux.rho*aux.cv)) else if aux.region == 4 then sqrt(1/(aux.rho*(aux.rho*aux.cv/aux.dpT + 1.0)/(aux.dpT*aux.T) - 1/aux.rho*aux.rho*aux.rho/(aux.dpT*aux.T))) else sqrt(-aux.cp/(aux.rho*aux.rho*(aux.vp*aux.cp + aux.vt*aux.vt*aux.T)));
      annotation(Inline=false, LateInline=true);
    end velocityOfSound_props_ph;

    function velocityOfSound_ph
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.Velocity v_sound "speed of sound";
    algorithm
      v_sound:=velocityOfSound_props_ph(p, h, waterBasePropAnalytic_ph(p, h, phase, region));
    end velocityOfSound_ph;

    function isentropicExponent_props_ph "isentropic exponent as function of pressure and specific enthalpy"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97TwoPhaseAnalytic aux "auxiliary record";
      output Real gamma "isentropic exponent";
    algorithm
      gamma:=if aux.region == 3 then 1/(aux.rho*p)*((aux.pd*aux.cv*aux.rho*aux.rho + aux.pt*aux.pt*aux.T)/aux.cv) else if aux.region == 4 then 1/(aux.rho*p)*aux.dpT*aux.dpT*aux.T/aux.cv else -1/(aux.rho*aux.p)*aux.cp/(aux.vp*aux.cp + aux.vt*aux.vt*aux.T);
      annotation(Inline=false, LateInline=true);
    end isentropicExponent_props_ph;

    function isentropicExponent_ph "isentropic exponent as function of pressure and specific enthalpy"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Real gamma "isentropic exponent";
    algorithm
      gamma:=isentropicExponent_props_ph(p, h, waterBasePropAnalytic_ph(p, h, phase, region));
      annotation(Inline=false, LateInline=true);
    end isentropicExponent_ph;

    function ddph_props "density derivative by pressure"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97TwoPhaseAnalytic aux "auxiliary record";
      output Modelica.SIunits.DerDensityByPressure ddph "density derivative by pressure";
    algorithm
      ddph:=if aux.region == 3 then aux.rho*(aux.cv*aux.rho + aux.pt)/(aux.rho*aux.rho*aux.pd*aux.cv + aux.T*aux.pt*aux.pt) else if aux.region == 4 then aux.rho*(aux.rho*aux.cv/aux.dpT + 1.0)/(aux.dpT*aux.T) else -aux.rho*aux.rho*(aux.vp*aux.cp - aux.vt/aux.rho + aux.T*aux.vt*aux.vt)/aux.cp;
      annotation(Inline=false, LateInline=true, derivative(noDerivative=aux)=ddph_ph_der);
    end ddph_props;

    function ddph "density derivative by pressure"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.DerDensityByPressure ddph "density derivative by pressure";
    algorithm
      ddph:=ddph_props(p, h, waterBasePropAnalytic_ph(p, h, phase, region));
    end ddph;

    function ddph_ph_der "derivative function of ddph"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97TwoPhaseAnalytic aux "auxiliary record";
      input Real p_der "derivative of pressure";
      input Real h_der "derivative of specific enthalpy";
      output Real ddph_der "Gradient of ddph";
    protected
      Modelica.SIunits.SpecificVolume v=1/aux.rho;
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
    algorithm
      if aux.region == 4 then
        dht:=aux.cv + aux.dpT*v;
        dhd:=-aux.T*aux.dpT*v*v;
        detPH:=-aux.dpT*dhd;
        dtph:=1.0/aux.dpT;
        ddph:=dht/detPH;
        ddhp:=-aux.dpT/detPH;
        detPH_t:=2.0*aux.ptt/aux.dpT + 1.0/aux.T;
        detPH_d:=-2.0*v;
        dhtt:=aux.cvt + aux.ptt*v;
        dhtd:=-(aux.T*aux.ptt + aux.dpT)*v*v;
        ddhp_t:=ddhp*(aux.ptt/aux.dpT - detPH_t);
        ddhp_d:=ddhp*(-detPH_d);
        ddph_t:=ddph*(dhtt/dht - detPH_t);
        ddph_d:=ddph*(dhtd/dht - detPH_d);
        ddph_der:=(ddph*ddph_d + dtph*ddph_t)*p_der + ddhp*ddph_d*h_der;
      else
        detPH:=aux.cp*aux.pd;
        dht:=aux.cv + aux.pt*v;
        dhd:=(aux.pd - aux.T*aux.pt*v)*v;
        ddph:=dht/detPH;
        ddhp:=-aux.pt/detPH;
        dtph:=-dhd/detPH;
        dthp:=aux.pd/detPH;
        detPH_d:=aux.cv*aux.pdd + (2.0*aux.pt*(aux.ptd - aux.pt*v) - aux.ptt*aux.pd)*aux.T*v*v;
        detPH_t:=aux.cvt*aux.pd + aux.cv*aux.ptd + (aux.pt + 2.0*aux.T*aux.ptt)*aux.pt*v*v;
        dhtt:=aux.cvt + aux.ptt*v;
        dhtd:=(aux.ptd - (aux.T*aux.ptt + aux.pt)*v)*v;
        ddph_t:=ddph*(dhtt/dht - detPH_t/detPH);
        ddph_d:=ddph*(dhtd/dht - detPH_d/detPH);
        ddhp_t:=ddhp*(aux.ptt/aux.pt - detPH_t/detPH);
        ddhp_d:=ddhp*(aux.ptd/aux.pt - detPH_d/detPH);
        ddph_der:=(ddph*ddph_d + dtph*ddph_t)*p_der + (ddph*ddhp_d + dtph*ddhp_t)*h_der;
      end if;
    end ddph_ph_der;

    function ddph_ph_dd "Second derivatives function of density"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97TwoPhaseAnalytic aux "auxiliary record";
      output Real ddph_ph "Second derivative of density by p at constant h";
      output Real ddph_hp "Second mixed derivative of density by p and h";
    protected
      Modelica.SIunits.SpecificVolume v=1/aux.rho;
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
    algorithm
      if aux.region == 4 then
        dht:=aux.cv + aux.dpT*v;
        dhd:=-aux.T*aux.dpT*v*v;
        detPH:=-aux.dpT*dhd;
        dtph:=1.0/aux.dpT;
        ddph:=dht/detPH;
        ddhp:=-aux.dpT/detPH;
        detPH_t:=2.0*aux.ptt/aux.dpT + 1.0/aux.T;
        detPH_d:=-2.0*v;
        dhtt:=aux.cvt + aux.ptt*v;
        dhtd:=-(aux.T*aux.ptt + aux.dpT)*v*v;
        ddhp_t:=ddhp*(aux.ptt/aux.dpT - detPH_t);
        ddhp_d:=ddhp*(-detPH_d);
        ddph_t:=ddph*(dhtt/dht - detPH_t);
        ddph_d:=ddph*(dhtd/dht - detPH_d);
        ddph_ph:=ddph*ddph_d + dtph*ddph_t;
        ddph_hp:=ddhp*ddph_d;
      else
        detPH:=aux.cp*aux.pd;
        dht:=aux.cv + aux.pt*v;
        dhd:=(aux.pd - aux.T*aux.pt*v)*v;
        ddph:=dht/detPH;
        ddhp:=-aux.pt/detPH;
        dtph:=-dhd/detPH;
        dthp:=aux.pd/detPH;
        detPH_d:=aux.cv*aux.pdd + (2.0*aux.pt*(aux.ptd - aux.pt*v) - aux.ptt*aux.pd)*aux.T*v*v;
        detPH_t:=aux.cvt*aux.pd + aux.cv*aux.ptd + (aux.pt + 2.0*aux.T*aux.ptt)*aux.pt*v*v;
        dhtt:=aux.cvt + aux.ptt*v;
        dhtd:=(aux.ptd - (aux.T*aux.ptt + aux.pt)*v)*v;
        ddph_t:=ddph*(dhtt/dht - detPH_t/detPH);
        ddph_d:=ddph*(dhtd/dht - detPH_d/detPH);
        ddhp_t:=ddhp*(aux.ptt/aux.pt - detPH_t/detPH);
        ddhp_d:=ddhp*(aux.ptd/aux.pt - detPH_d/detPH);
        ddph_ph:=ddph*ddph_d + dtph*ddph_t;
        ddph_hp:=ddph*ddhp_d + dtph*ddhp_t;
      end if;
    end ddph_ph_dd;

    function ddhp_props "density derivative by specific enthalpy"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97TwoPhaseAnalytic aux "auxiliary record";
      output Modelica.SIunits.DerDensityByEnthalpy ddhp "density derivative by specific enthalpy";
    algorithm
      ddhp:=if aux.region == 3 then -aux.rho*aux.rho*aux.pt/(aux.rho*aux.rho*aux.pd*aux.cv + aux.T*aux.pt*aux.pt) else if aux.region == 4 then -aux.rho*aux.rho/(aux.dpT*aux.T) else -aux.rho*aux.rho*aux.vt/aux.cp;
      annotation(Inline=false, LateInline=true, derivative(noDerivative=aux)=ddhp_ph_der);
    end ddhp_props;

    function ddhp "density derivative by specific enthalpy"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.DerDensityByEnthalpy ddhp "density derivative by specific enthalpy";
    algorithm
      ddhp:=ddhp_props(p, h, waterBasePropAnalytic_ph(p, h, phase, region));
    end ddhp;

    function ddhp_ph_der "derivative function of ddhp"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97TwoPhaseAnalytic aux "auxiliary record";
      input Real p_der "derivative of pressure";
      input Real h_der "derivative of specific enthalpy";
      output Real ddhp_der "Gradient of ddhp";
    protected
      Modelica.SIunits.SpecificVolume v=1/aux.rho;
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
      Real ddhp_d;
      Real ddhp_t;
      Real ddph_d;
    algorithm
      if aux.region == 4 then
        dht:=aux.cv + aux.dpT*v;
        dhd:=-aux.T*aux.dpT*v*v;
        detPH:=-aux.dpT*dhd;
        dtph:=1.0/aux.dpT;
        ddph:=dht/detPH;
        ddhp:=-aux.dpT/detPH;
        detPH_d:=-2.0*v;
        dhtt:=aux.cvt + aux.ptt*v;
        dhtd:=-(aux.T*aux.ptt + aux.dpT)*v*v;
        ddhp_d:=ddhp*(-detPH_d);
        ddph_d:=ddph*(dhtd/dht - detPH_d);
        ddhp_der:=ddhp*ddhp_d*h_der + ddhp*ddph_d*p_der;
      else
        detPH:=aux.cp*aux.pd;
        dht:=aux.cv + aux.pt*v;
        dhd:=(aux.pd - aux.T*aux.pt*v)*v;
        ddph:=dht/detPH;
        ddhp:=-aux.pt/detPH;
        dtph:=-dhd/detPH;
        dthp:=aux.pd/detPH;
        detPH_d:=aux.cv*aux.pdd + (2.0*aux.pt*(aux.ptd - aux.pt*v) - aux.ptt*aux.pd)*aux.T*v*v;
        detPH_t:=aux.cvt*aux.pd + aux.cv*aux.ptd + (aux.pt + 2.0*aux.T*aux.ptt)*aux.pt*v*v;
        dhtt:=aux.cvt + aux.ptt*v;
        dhtd:=(aux.ptd - (aux.T*aux.ptt + aux.pt)*v)*v;
        ddhp_t:=ddhp*(aux.ptt/aux.pt - detPH_t/detPH);
        ddhp_d:=ddhp*(aux.ptd/aux.pt - detPH_d/detPH);
        ddhp_der:=(ddhp*ddhp_d + dthp*ddhp_t)*h_der + (ddph*ddhp_d + dtph*ddhp_t)*p_der;
      end if;
    end ddhp_ph_der;

    function ddhp_ph_dd "Second derivatives of density w.r.t h and p"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97TwoPhaseAnalytic aux "auxiliary record";
      output Real ddhp_hp "Second derivative of density by h at constant p";
      output Real ddhp_ph "Second mixed derivative of density by p and h";
    protected
      Modelica.SIunits.SpecificVolume v=1/aux.rho;
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
      Real ddhp_d;
      Real ddhp_t;
      Real ddph_d;
    algorithm
      if aux.region == 4 then
        dht:=aux.cv + aux.dpT*v;
        dhd:=-aux.T*aux.dpT*v*v;
        detPH:=-aux.dpT*dhd;
        dtph:=1.0/aux.dpT;
        ddph:=dht/detPH;
        ddhp:=-aux.dpT/detPH;
        detPH_d:=-2.0*v;
        dhtt:=aux.cvt + aux.ptt*v;
        dhtd:=-(aux.T*aux.ptt + aux.dpT)*v*v;
        ddhp_d:=ddhp*(-detPH_d);
        ddph_d:=ddph*(dhtd/dht - detPH_d);
        ddhp_hp:=ddhp*ddhp_d;
        ddhp_ph:=ddhp*ddph_d;
      else
        detPH:=aux.cp*aux.pd;
        dht:=aux.cv + aux.pt*v;
        dhd:=(aux.pd - aux.T*aux.pt*v)*v;
        ddph:=dht/detPH;
        ddhp:=-aux.pt/detPH;
        dtph:=-dhd/detPH;
        dthp:=aux.pd/detPH;
        detPH_d:=aux.cv*aux.pdd + (2.0*aux.pt*(aux.ptd - aux.pt*v) - aux.ptt*aux.pd)*aux.T*v*v;
        detPH_t:=aux.cvt*aux.pd + aux.cv*aux.ptd + (aux.pt + 2.0*aux.T*aux.ptt)*aux.pt*v*v;
        dhtt:=aux.cvt + aux.ptt*v;
        dhtd:=(aux.ptd - (aux.T*aux.ptt + aux.pt)*v)*v;
        ddhp_t:=ddhp*(aux.ptt/aux.pt - detPH_t/detPH);
        ddhp_d:=ddhp*(aux.ptd/aux.pt - detPH_d/detPH);
        ddhp_hp:=ddhp*ddhp_d + dthp*ddhp_t;
        ddhp_hp:=ddph*ddhp_d + dtph*ddhp_t;
      end if;
    end ddhp_ph_dd;

    function rho_props_pT "density as function or pressure and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97TwoPhaseAnalytic aux "auxiliary record";
      output Modelica.SIunits.Density rho "density";
    algorithm
      rho:=aux.rho;
      annotation(derivative(noDerivative=aux)=rho_pT_der, Inline=false, LateInline=true);
    end rho_props_pT;

    function rho_pT "density as function or pressure and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.Density rho "density";
    algorithm
      rho:=rho_props_pT(p, T, waterBasePropAnalytic_pT(p, T, region));
    end rho_pT;

    function h_props_pT "specific enthalpy as function or pressure and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97TwoPhaseAnalytic aux "auxiliary record";
      output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
    algorithm
      h:=aux.h;
      annotation(derivative(noDerivative=aux)=h_pT_der, Inline=false, LateInline=true);
    end h_props_pT;

    function h_pT "specific enthalpy as function or pressure and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "Temperature";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
    algorithm
      h:=h_props_pT(p, T, waterBasePropAnalytic_pT(p, T, region));
    end h_pT;

    function h_pT_der "derivative function of h_pT"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97TwoPhaseAnalytic aux "auxiliary record";
      input Real p_der "derivative of pressure";
      input Real T_der "derivative of temperature";
      output Real h_der "derivative of specific enthalpy";
    algorithm
      if aux.region == 3 then
        h_der:=(-aux.rho*aux.pd + T*aux.pt)/(aux.rho*aux.rho*aux.pd)*p_der + (aux.rho*aux.rho*aux.pd*aux.cv + aux.T*aux.pt*aux.pt)/(aux.rho*aux.rho*aux.pd)*T_der;
      else
        h_der:=(1/aux.rho - aux.T*aux.vt)*p_der + aux.cp*T_der;
      end if;
    end h_pT_der;

    function rho_pT_der "derivative function of rho_pT"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97TwoPhaseAnalytic aux "auxiliary record";
      input Real p_der "derivative of pressure";
      input Real T_der "derivative of temperature";
      output Real rho_der "derivative of density";
    algorithm
      if aux.region == 3 then
        rho_der:=1/aux.pd*p_der - aux.pt/aux.pd*T_der;
      else
        rho_der:=(-aux.rho*aux.rho*aux.vp)*p_der + (-aux.rho*aux.rho*aux.vt)*T_der;
      end if;
    end rho_pT_der;

    function s_props_pT "specific entropy as function of pressure and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97TwoPhaseAnalytic aux "auxiliary record";
      output Modelica.SIunits.SpecificEntropy s "specific entropy";
    algorithm
      s:=aux.s;
      annotation(Inline=false, LateInline=true);
    end s_props_pT;

    function s_pT "temperature as function of pressure and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.SpecificEntropy s "specific entropy";
    algorithm
      s:=s_props_pT(p, T, waterBasePropAnalytic_pT(p, T, region));
      annotation(InlineNoEvent=false);
    end s_pT;

    function cv_props_pT "specific heat capacity at constant volume as function of pressure and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97TwoPhaseAnalytic aux "auxiliary record";
      output Modelica.SIunits.SpecificHeatCapacity cv "specific heat capacity";
    algorithm
      cv:=aux.cv;
      annotation(Inline=false, LateInline=true);
    end cv_props_pT;

    function cv_pT "specific heat capacity at constant volume as function of pressure and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.SpecificHeatCapacity cv "specific heat capacity";
    algorithm
      cv:=cv_props_pT(p, T, waterBasePropAnalytic_pT(p, T, region));
      annotation(InlineNoEvent=false);
    end cv_pT;

    function cp_props_pT "specific heat capacity at constant pressure as function of pressure and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97TwoPhaseAnalytic aux "auxiliary record";
      output Modelica.SIunits.SpecificHeatCapacity cp "specific heat capacity";
    algorithm
      cp:=if aux.region == 3 then (aux.rho*aux.rho*aux.pd*aux.cv + aux.T*aux.pt*aux.pt)/(aux.rho*aux.rho*aux.pd) else aux.cp;
      annotation(Inline=false, LateInline=true);
    end cp_props_pT;

    function cp_pT "specific heat capacity at constant pressure as function of pressure and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.SpecificHeatCapacity cp "specific heat capacity";
    algorithm
      cp:=cp_props_pT(p, T, waterBasePropAnalytic_pT(p, T, region));
      annotation(InlineNoEvent=false);
    end cp_pT;

    function beta_props_pT "isobaric expansion coefficient as function of pressure and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97TwoPhaseAnalytic aux "auxiliary record";
      output Modelica.SIunits.RelativePressureCoefficient beta "isobaric expansion coefficient";
    algorithm
      beta:=if aux.region == 3 then aux.pt/(aux.rho*aux.pd) else aux.vt*aux.rho;
      annotation(Inline=false, LateInline=true);
    end beta_props_pT;

    function beta_pT "isobaric expansion coefficient as function of pressure and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.RelativePressureCoefficient beta "isobaric expansion coefficient";
    algorithm
      beta:=beta_props_pT(p, T, waterBasePropAnalytic_pT(p, T, region));
      annotation(InlineNoEvent=false);
    end beta_pT;

    function kappa_props_pT "isothermal compressibility factor as function of pressure and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97TwoPhaseAnalytic aux "auxiliary record";
      output Modelica.SIunits.IsothermalCompressibility kappa "isothermal compressibility factor";
    algorithm
      kappa:=if aux.region == 3 then 1/(aux.rho*aux.pd) else -aux.vp*aux.rho;
      annotation(Inline=false, LateInline=true);
    end kappa_props_pT;

    function kappa_pT "isothermal compressibility factor as function of pressure and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.IsothermalCompressibility kappa "isothermal compressibility factor";
    algorithm
      kappa:=kappa_props_pT(p, T, waterBasePropAnalytic_pT(p, T, region));
      annotation(InlineNoEvent=false);
    end kappa_pT;

    function velocityOfSound_props_pT "speed of sound as function of pressure and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97TwoPhaseAnalytic aux "auxiliary record";
      output Modelica.SIunits.Velocity v_sound "speed of sound";
    algorithm
      v_sound:=if aux.region == 3 then sqrt((aux.pd*aux.rho*aux.rho*aux.cv + aux.pt*aux.pt*aux.T)/(aux.rho*aux.rho*aux.cv)) else sqrt(-aux.cp/(aux.rho*aux.rho*(aux.vp*aux.cp + aux.vt*aux.vt*aux.T)));
      annotation(Inline=false, LateInline=true);
    end velocityOfSound_props_pT;

    function velocityOfSound_pT "speed of sound as function of pressure and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.Velocity v_sound "speed of sound";
    algorithm
      v_sound:=velocityOfSound_props_pT(p, T, waterBasePropAnalytic_pT(p, T, region));
    end velocityOfSound_pT;

    function isentropicExponent_props_pT "isentropic exponent as function of pressure and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97TwoPhaseAnalytic aux "auxiliary record";
      output Real gamma "isentropic exponent";
    algorithm
      gamma:=if aux.region == 3 then 1/(aux.rho*p)*((aux.pd*aux.cv*aux.rho*aux.rho + aux.pt*aux.pt*aux.T)/aux.cv) else -1/(aux.rho*aux.p)*aux.cp/(aux.vp*aux.cp + aux.vt*aux.vt*aux.T);
      annotation(Inline=false, LateInline=true);
    end isentropicExponent_props_pT;

    function isentropicExponent_pT "isentropic exponent as function of pressure and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Real gamma "isentropic exponent";
    algorithm
      gamma:=isentropicExponent_props_pT(p, T, waterBasePropAnalytic_pT(p, T, region));
      annotation(Inline=false, LateInline=true);
    end isentropicExponent_pT;

    function h_props_dT "specific enthalpy as function of density and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "Temperature";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97TwoPhaseAnalytic aux "auxiliary record";
      output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
    algorithm
      h:=aux.h;
      annotation(derivative(noDerivative=aux)=h_dT_der, Inline=false, LateInline=true);
    end h_props_dT;

    function h_dT "specific enthalpy as function of density and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "Temperature";
      input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
    algorithm
      h:=h_props_dT(d, T, waterBasePropAnalytic_dT(d, T, phase, region));
    end h_dT;

    function h_dT_der "derivative function of h_dT"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "temperature";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97TwoPhaseAnalytic aux "auxiliary record";
      input Real d_der "derivative of density";
      input Real T_der "derivative of temperature";
      output Real h_der "derivative of specific enthalpy";
    algorithm
      if aux.region == 3 then
        h_der:=(-d*aux.pd + T*aux.pt)/(d*d)*d_der + (aux.cv*d + aux.pt)/d*T_der;
      elseif aux.region == 4 then
        h_der:=T*aux.dpT/(d*d)*d_der + (aux.cv*d + aux.dpT)/d*T_der;
      else
        h_der:=(-(-1/d + T*aux.vt)/(d*d*aux.vp))*d_der + (aux.vp*aux.cp - aux.vt/d + T*aux.vt*aux.vt)/aux.vp*T_der;
      end if;
    end h_dT_der;

    function p_props_dT "pressure as function of density and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "Temperature";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97TwoPhaseAnalytic aux "auxiliary record";
      output Modelica.SIunits.Pressure p "pressure";
    algorithm
      p:=aux.p;
      annotation(derivative(noDerivative=aux)=p_dT_der, Inline=false, LateInline=true);
    end p_props_dT;

    function p_dT "pressure as function of density and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "Temperature";
      input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.Pressure p "pressure";
    algorithm
      p:=p_props_dT(d, T, waterBasePropAnalytic_dT(d, T, phase, region));
    end p_dT;

    function p_dT_der "derivative function of p_dT"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "temperature";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97TwoPhaseAnalytic aux "auxiliary record";
      input Real d_der "derivative of density";
      input Real T_der "derivative of temperature";
      output Real p_der "derivative of pressure";
    algorithm
      if aux.region == 3 then
        p_der:=aux.pd*d_der + aux.pt*T_der;
      elseif aux.region == 4 then
        p_der:=aux.dpT*T_der;
      else
        p_der:=(-1/(d*d*aux.vp))*d_der + (-aux.vt/aux.vp)*T_der;
      end if;
    end p_dT_der;

    function s_props_dT "specific entropy as function of density and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "Temperature";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97TwoPhaseAnalytic aux "auxiliary record";
      output Modelica.SIunits.SpecificEntropy s "specific entropy";
    algorithm
      s:=aux.s;
      annotation(Inline=false, LateInline=true);
    end s_props_dT;

    function s_dT "temperature as function of density and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "Temperature";
      input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.SpecificEntropy s "specific entropy";
    algorithm
      s:=s_props_dT(d, T, waterBasePropAnalytic_dT(d, T, phase, region));
    end s_dT;

    function cv_props_dT "specific heat capacity at constant volume as function of density and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "temperature";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97TwoPhaseAnalytic aux "auxiliary record";
      output Modelica.SIunits.SpecificHeatCapacity cv "specific heat capacity";
    algorithm
      cv:=aux.cv;
      annotation(Inline=false, LateInline=true);
    end cv_props_dT;

    function cv_dT "specific heat capacity at constant volume as function of density and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "temperature";
      input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.SpecificHeatCapacity cv "specific heat capacity";
    algorithm
      cv:=cv_props_dT(d, T, waterBasePropAnalytic_dT(d, T, phase, region));
    end cv_dT;

    function cp_props_dT "specific heat capacity at constant pressure as function of density and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "temperature";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97TwoPhaseAnalytic aux "auxiliary record";
      output Modelica.SIunits.SpecificHeatCapacity cp "specific heat capacity";
    algorithm
      cp:=aux.cp;
      annotation(Inline=false, LateInline=true);
    end cp_props_dT;

    function cp_dT "specific heat capacity at constant pressure as function of density and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "temperature";
      input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.SpecificHeatCapacity cp "specific heat capacity";
    algorithm
      cp:=cp_props_dT(d, T, waterBasePropAnalytic_dT(d, T, phase, region));
    end cp_dT;

    function beta_props_dT "isobaric expansion coefficient as function of density and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "temperature";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97TwoPhaseAnalytic aux "auxiliary record";
      output Modelica.SIunits.RelativePressureCoefficient beta "isobaric expansion coefficient";
    algorithm
      beta:=if aux.region == 3 or aux.region == 4 then aux.pt/(aux.rho*aux.pd) else aux.vt*aux.rho;
      annotation(Inline=false, LateInline=true);
    end beta_props_dT;

    function beta_dT "isobaric expansion coefficient as function of density and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "temperature";
      input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.RelativePressureCoefficient beta "isobaric expansion coefficient";
    algorithm
      beta:=beta_props_dT(d, T, waterBasePropAnalytic_dT(d, T, phase, region));
    end beta_dT;

    function kappa_props_dT "isothermal compressibility factor as function of density and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "temperature";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97TwoPhaseAnalytic aux "auxiliary record";
      output Modelica.SIunits.IsothermalCompressibility kappa "isothermal compressibility factor";
    algorithm
      kappa:=if aux.region == 3 or aux.region == 4 then 1/(aux.rho*aux.pd) else -aux.vp*aux.rho;
      annotation(Inline=false, LateInline=true);
    end kappa_props_dT;

    function kappa_dT "isothermal compressibility factor as function of density and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "temperature";
      input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.IsothermalCompressibility kappa "isothermal compressibility factor";
    algorithm
      kappa:=kappa_props_dT(d, T, waterBasePropAnalytic_dT(d, T, phase, region));
    end kappa_dT;

    function velocityOfSound_props_dT "speed of sound as function of density and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "temperature";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97TwoPhaseAnalytic aux "auxiliary record";
      output Modelica.SIunits.Velocity v_sound "speed of sound";
    algorithm
      v_sound:=if aux.region == 3 then sqrt((aux.pd*aux.rho*aux.rho*aux.cv + aux.pt*aux.pt*aux.T)/(aux.rho*aux.rho*aux.cv)) else if aux.region == 4 then sqrt(1/(aux.rho*(aux.rho*aux.cv/aux.dpT + 1.0)/(aux.dpT*aux.T) - 1/aux.rho*aux.rho*aux.rho/(aux.dpT*aux.T))) else sqrt(-aux.cp/(aux.rho*aux.rho*(aux.vp*aux.cp + aux.vt*aux.vt*aux.T)));
      annotation(Inline=false, LateInline=true);
    end velocityOfSound_props_dT;

    function velocityOfSound_dT "speed of sound as function of density and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "temperature";
      input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.Velocity v_sound "speed of sound";
    algorithm
      v_sound:=velocityOfSound_props_dT(d, T, waterBasePropAnalytic_dT(d, T, phase, region));
    end velocityOfSound_dT;

    function isentropicExponent_props_dT "isentropic exponent as function of density and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "temperature";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97TwoPhaseAnalytic aux "auxiliary record";
      output Real gamma "isentropic exponent";
    algorithm
      gamma:=if aux.region == 3 then 1/(aux.rho*aux.p)*((aux.pd*aux.cv*aux.rho*aux.rho + aux.pt*aux.pt*aux.T)/aux.cv) else if aux.region == 4 then 1/(aux.rho*aux.p)*aux.dpT*aux.dpT*aux.T/aux.cv else -1/(aux.rho*aux.p)*aux.cp/(aux.vp*aux.cp + aux.vt*aux.vt*aux.T);
      annotation(Inline=false, LateInline=true);
    end isentropicExponent_props_dT;

    function isentropicExponent_dT "isentropic exponent as function of density and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "temperature";
      input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Real gamma "isentropic exponent";
    algorithm
      gamma:=isentropicExponent_props_dT(d, T, waterBasePropAnalytic_dT(d, T, phase, region));
      annotation(Inline=false, LateInline=true);
    end isentropicExponent_dT;

  protected
    package ThermoFluidSpecial
      function water_ph "calculate the property record for dynamic simulation properties using p,h as states"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
        input Integer phase=0 "phase: 2 for two-phase, 1 for one phase, 0 if unknown";
        output ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph pro "property record for dynamic simulation";
      protected
        Modelica.Media.Common.GibbsDerivs g "dimensionless Gibbs funcion and dervatives wrt pi and tau";
        Modelica.Media.Common.HelmholtzDerivs f "dimensionless Helmholtz funcion and dervatives wrt delta and tau";
        Integer region(min=1, max=5) "IF97 region";
        Integer error "error flag";
        Modelica.SIunits.Temperature T "temperature";
        Modelica.SIunits.Density d "density";
      algorithm
        region:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.region_ph(p, h, phase);
        if region == 1 then
          T:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tph1(p, h);
          g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g1(p, T);
          pro:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToProps_ph(g);
        elseif region == 2 then
          T:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tph2(p, h);
          g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g2(p, T);
          pro:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToProps_ph(g);

        elseif region == 3 then
          (d,T,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.dtofph3(p=p, h=h, delp=1e-07, delh=1e-06);
          f:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3(d, T);
          pro:=ThermoSysPro.Properties.WaterSteam.Common.helmholtzToProps_ph(f);

        elseif region == 4 then
          pro:=ThermoSysPro.Properties.WaterSteam.BaseIF97.TwoPhase.waterR4_ph(p=p, h=h);

        elseif region == 5 then
          (T,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.tofph5(p=p, h=h, reldh=1e-07);
          g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g5(p, T);
          pro:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToProps_ph(g);
        end if;
      end water_ph;

      function water_dT "calculate property record for dynamic simulation properties using d and T as dynamic states"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Density d "density";
        input Modelica.SIunits.Temperature T "temperature";
        input Integer phase=0 "phase: 2 for two-phase, 1 for one phase, 0 if unknown";
        output ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_dT pro "property record for dynamic simulation";
      protected
        Modelica.SIunits.Pressure p "pressure";
        Integer region(min=1, max=5) "IF97 region";
        Modelica.Media.Common.GibbsDerivs g "dimensionless Gibbs funcion and dervatives wrt pi and tau";
        Modelica.Media.Common.HelmholtzDerivs f "dimensionless Helmholtz funcion and dervatives wrt delta and tau";
        Integer error "error flag";
      algorithm
        region:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.region_dT(d, T, phase);
        if region == 1 then
          (p,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.pofdt125(d=d, T=T, reldd=iter.DELD, region=1);
          g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g1(p, T);
          pro:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToProps_dT(g);
        elseif region == 2 then
          (p,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.pofdt125(d=d, T=T, reldd=iter.DELD, region=2);
          g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g2(p, T);
          pro:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToProps_dT(g);

        elseif region == 3 then
          f:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3(d, T);
          pro:=ThermoSysPro.Properties.WaterSteam.Common.helmholtzToProps_dT(f);

        elseif region == 4 then
          pro:=ThermoSysPro.Properties.WaterSteam.BaseIF97.TwoPhase.waterR4_dT(d=d, T=T);

        elseif region == 5 then
          (p,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.pofdt125(d=d, T=T, reldd=iter.DELD, region=5);
          g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g5(p, T);
          pro:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToProps_dT(g);
        end if;
      end water_dT;

      function water_pT "calculate property record for dynamic simulation properties using p and T as dynamic states"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.Temperature T "temperature";
        output Modelica.Media.Common.ThermoFluidSpecial.ThermoProperties_pT pro "property record for dynamic simulation";
      protected
        Modelica.SIunits.Density d "density";
        Integer region(min=1, max=5) "IF97 region";
        Modelica.Media.Common.GibbsDerivs g "dimensionless Gibbs funcion and dervatives wrt pi and tau";
        Modelica.Media.Common.HelmholtzDerivs f "dimensionless Helmholtz funcion and dervatives wrt delta and tau";
        Integer error "error flag";
      algorithm
        region:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.region_pT(p, T);
        if region == 1 then
          g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g1(p, T);
          pro:=Modelica.Media.Common.ThermoFluidSpecial.gibbsToProps_pT(g);
        elseif region == 2 then
          g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g2(p, T);
          pro:=Modelica.Media.Common.ThermoFluidSpecial.gibbsToProps_pT(g);

        elseif region == 3 then
          (d,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.dofpt3(p=p, T=T, delp=iter.DELP);
          f:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3(d, T);
          pro:=Modelica.Media.Common.ThermoFluidSpecial.helmholtzToProps_pT(f);

        elseif region == 5 then
          g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g5(p, T);
          pro:=Modelica.Media.Common.ThermoFluidSpecial.gibbsToProps_pT(g);
        end if;
      end water_pT;

    end ThermoFluidSpecial;

  public
    function hl_p= ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.hl_p "compute the saturated liquid specific h(p)";
    function hv_p= ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.hv_p "compute the saturated vapour specific h(p)";
    function sl_p= ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.sl_p "compute the saturated liquid specific s(p)";
    function sv_p= ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.sv_p "compute the saturated vapour specific s(p)";
    function rhol_T= ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.rhol_T "compute the saturated liquid d(T)";
    function rhov_T= ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.rhov_T "compute the saturated vapour d(T)";
    function rhol_p= ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.rhol_p "compute the saturated liquid d(p)";
    function rhov_p= ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.rhov_p "compute the saturated vapour d(p)";
    function dynamicViscosity= ThermoSysPro.Properties.WaterSteam.BaseIF97.Transport.visc_dT "compute eta(d,T) in the one-phase region";
    function thermalConductivity= ThermoSysPro.Properties.WaterSteam.BaseIF97.Transport.cond_industrial_dT "compute lambda(d,T) in the one-phase region";
    function surfaceTension= ThermoSysPro.Properties.WaterSteam.BaseIF97.Transport.surfaceTension "compute sigma(T) at saturation T";
    function isentropicEnthalpy "isentropic specific enthalpy from p,s (preferably use dynamicIsentropicEnthalpy in dynamic simulation!)"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEntropy s "specific entropy";
      input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
    algorithm
      h:=isentropicEnthalpy_props(p, s, waterBaseProp_ps(p, s, phase, region));
    end isentropicEnthalpy;

    function isentropicEnthalpy_props
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEntropy s "specific entropy";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97BaseTwoPhase aux "auxiliary record";
      output Modelica.SIunits.SpecificEnthalpy h "isentropic enthalpay";
    algorithm
      h:=aux.h;
      annotation(derivative(noDerivative=aux)=isentropicEnthalpy_der, Inline=false, LateInline=true);
    end isentropicEnthalpy_props;

    function isentropicEnthalpy_der "derivative of isentropic specific enthalpy from p,s"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEntropy s "specific entropy";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97BaseTwoPhase aux "auxiliary record";
      input Real p_der "pressure derivative";
      input Real s_der "entropy derivative";
      output Real h_der "specific enthalpy derivative";
    algorithm
      h_der:=1/aux.rho*p_der + aux.T*s_der;
    end isentropicEnthalpy_der;

    function dynamicIsentropicEnthalpy "isentropic specific enthalpy from p,s and good guesses of d and T"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEntropy s "specific entropy";
      input Modelica.SIunits.Density dguess "good guess density, e.g. from adjacent volume";
      input Modelica.SIunits.Temperature Tguess "good guess temperature, e.g. from adjacent volume";
      input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
      output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
    algorithm
      h:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Isentropic.water_hisentropic_dyn(p, s, dguess, Tguess, 0);
    end dynamicIsentropicEnthalpy;

  end AnalyticDerivatives;

  package Standard "Standard version without Anaytic Jacobians"
    import ThermoSysPro.Properties.WaterSteam.BaseIF97.*;
    replaceable record iter= ThermoSysPro.Properties.WaterSteam.BaseIF97.IterationData;
    function waterBaseProp_ph "intermediate property record for water"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input Integer phase=0 "phase: 2 for two-phase, 1 for one phase, 0 if unknown";
      input Integer region=0 "if 0, do region computation, otherwise assume the region is this input";
      output ThermoSysPro.Properties.WaterSteam.Common.IF97BaseTwoPhase aux "auxiliary record";
    protected
      ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs g "dimensionless Gibbs funcion and dervatives wrt pi and tau";
      ThermoSysPro.Properties.WaterSteam.Common.HelmholtzDerivs f "dimensionless Helmholtz funcion and dervatives wrt delta and tau";
      Integer error "error flag for inverse iterations";
      Modelica.SIunits.SpecificEnthalpy h_liq "liquid specific enthalpy";
      Modelica.SIunits.Density d_liq "liquid density";
      Modelica.SIunits.SpecificEnthalpy h_vap "vapour specific enthalpy";
      Modelica.SIunits.Density d_vap "vapour density";
      ThermoSysPro.Properties.WaterSteam.Common.PhaseBoundaryProperties liq "phase boundary property record";
      ThermoSysPro.Properties.WaterSteam.Common.PhaseBoundaryProperties vap "phase boundary property record";
      ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs gl "dimensionless Gibbs funcion and dervatives wrt pi and tau";
      ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs gv "dimensionless Gibbs funcion and dervatives wrt pi and tau";
      Modelica.Media.Common.HelmholtzDerivs fl "dimensionless Helmholtz function and dervatives wrt delta and tau";
      Modelica.Media.Common.HelmholtzDerivs fv "dimensionless Helmholtz function and dervatives wrt delta and tau";
      Modelica.SIunits.Temperature t1 "temperature at phase boundary, using inverse from region 1";
      Modelica.SIunits.Temperature t2 "temperature at phase boundary, using inverse from region 2";
    algorithm
      aux.region:=if region == 0 then if phase == 2 then 4 else ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.region_ph(p=p, h=h, phase=phase) else region;
      aux.phase:=if phase <> 0 then phase else if aux.region == 4 then 2 else 1;
      aux.p:=max(p, 611.657);
      aux.h:=max(h, 1000.0);
      aux.R:=ThermoSysPro.Properties.WaterSteam.BaseIF97.data.RH2O;
      if aux.region == 1 then
        aux.T:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tph1(aux.p, aux.h);
        g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g1(p, aux.T);
        aux.s:=aux.R*(g.tau*g.gtau - g.g);
        aux.rho:=p/(aux.R*aux.T*g.pi*g.gpi);
        aux.vt:=aux.R/p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
        aux.vp:=aux.R*aux.T/(p*p)*g.pi*g.pi*g.gpipi;
        aux.cp:=-aux.R*g.tau*g.tau*g.gtautau;
        aux.cv:=aux.R*(-g.tau*g.tau*g.gtautau + (g.gpi - g.tau*g.gtaupi)*(g.gpi - g.tau*g.gtaupi)/g.gpipi);
        aux.x:=0.0;
        aux.dpT:=-aux.vt/aux.vp;
      elseif aux.region == 2 then
        aux.T:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tph2(aux.p, aux.h);
        g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g2(p, aux.T);
        aux.s:=aux.R*(g.tau*g.gtau - g.g);
        aux.rho:=p/(aux.R*aux.T*g.pi*g.gpi);
        aux.vt:=aux.R/p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
        aux.vp:=aux.R*aux.T/(p*p)*g.pi*g.pi*g.gpipi;
        aux.cp:=-aux.R*g.tau*g.tau*g.gtautau;
        aux.cv:=aux.R*(-g.tau*g.tau*g.gtautau + (g.gpi - g.tau*g.gtaupi)*(g.gpi - g.tau*g.gtaupi)/g.gpipi);
        aux.x:=1.0;
        aux.dpT:=-aux.vt/aux.vp;

      elseif aux.region == 3 then
        (aux.rho,aux.T,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.dtofph3(p=aux.p, h=aux.h, delp=1e-07, delh=1e-06);
        f:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3(aux.rho, aux.T);
        aux.h:=aux.R*aux.T*(f.tau*f.ftau + f.delta*f.fdelta);
        aux.s:=aux.R*(f.tau*f.ftau - f.f);
        aux.pd:=aux.R*aux.T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
        aux.pt:=aux.R*aux.rho*f.delta*(f.fdelta - f.tau*f.fdeltatau);
        aux.cv:=abs(aux.R*(-f.tau*f.tau*f.ftautau)) "can be close to neg. infinity near critical point";
        aux.cp:=(aux.rho*aux.rho*aux.pd*aux.cv + aux.T*aux.pt*aux.pt)/(aux.rho*aux.rho*aux.pd);
        aux.x:=0.0;
        aux.dpT:=aux.pt;

      elseif aux.region == 4 then
        h_liq:=hl_p(p);
        h_vap:=hv_p(p);
        aux.x:=if h_vap <> h_liq then (h - h_liq)/(h_vap - h_liq) else 1.0;
        if p < ThermoSysPro.Properties.WaterSteam.BaseIF97.data.PLIMIT4A then
          t1:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tph1(aux.p, h_liq);
          t2:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tph2(aux.p, h_vap);
          gl:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g1(aux.p, t1);
          gv:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g2(aux.p, t2);
          liq:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToBoundaryProps(gl);
          vap:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToBoundaryProps(gv);
          aux.T:=t1 + aux.x*(t2 - t1);
        else
          aux.T:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tsat(aux.p);
          d_liq:=rhol_T(aux.T);
          d_vap:=rhov_T(aux.T);
          fl:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3(d_liq, aux.T);
          fv:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3(d_vap, aux.T);
          liq:=ThermoSysPro.Properties.WaterSteam.Common.helmholtzToBoundaryProps(fl);
          vap:=ThermoSysPro.Properties.WaterSteam.Common.helmholtzToBoundaryProps(fv);
        end if;
        aux.dpT:=if liq.d <> vap.d then (vap.s - liq.s)*liq.d*vap.d/(liq.d - vap.d) else ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.dptofT(aux.T);
        aux.s:=liq.s + aux.x*(vap.s - liq.s);
        aux.rho:=liq.d*vap.d/(vap.d + aux.x*(liq.d - vap.d));
        aux.cv:=ThermoSysPro.Properties.WaterSteam.Common.cv2Phase(liq, vap, aux.x, aux.T, p);
        aux.cp:=liq.cp + aux.x*(vap.cp - liq.cp);
        aux.pt:=liq.pt + aux.x*(vap.pt - liq.pt);
        aux.pd:=liq.pd + aux.x*(vap.pd - liq.pd);

      elseif aux.region == 5 then
        (aux.T,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.tofph5(p=aux.p, h=aux.h, reldh=1e-07);
        assert(error == 0, "error in inverse iteration of steam tables");
        g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g5(aux.p, aux.T);
        aux.s:=aux.R*(g.tau*g.gtau - g.g);
        aux.rho:=p/(aux.R*aux.T*g.pi*g.gpi);
        aux.vt:=aux.R/p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
        aux.vp:=aux.R*aux.T/(p*p)*g.pi*g.pi*g.gpipi;
        aux.cp:=-aux.R*g.tau*g.tau*g.gtautau;
        aux.cv:=aux.R*(-g.tau*g.tau*g.gtautau + (g.gpi - g.tau*g.gtaupi)*(g.gpi - g.tau*g.gtaupi)/g.gpipi);
        aux.dpT:=-aux.vt/aux.vp;
      else
        assert(false, "error in region computation of IF97 steam tables" + "(p = " + String(p) + ", h = " + String(h) + ")");
      end if;
    end waterBaseProp_ph;

    function waterBaseProp_ps "intermediate property record for water"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEntropy s "specific entropy";
      input Integer phase=0 "phase: 2 for two-phase, 1 for one phase, 0 if unknown";
      input Integer region=0 "if 0, do region computation, otherwise assume the region is this input";
      output ThermoSysPro.Properties.WaterSteam.Common.IF97BaseTwoPhase aux "auxiliary record";
    protected
      ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs g "dimensionless Gibbs funcion and dervatives wrt pi and tau";
      ThermoSysPro.Properties.WaterSteam.Common.HelmholtzDerivs f "dimensionless Helmholtz funcion and dervatives wrt delta and tau";
      Integer error "error flag for inverse iterations";
      Modelica.SIunits.SpecificEntropy s_liq "liquid specific entropy";
      Modelica.SIunits.Density d_liq "liquid density";
      Modelica.SIunits.SpecificEntropy s_vap "vapour specific entropy";
      Modelica.SIunits.Density d_vap "vapour density";
      ThermoSysPro.Properties.WaterSteam.Common.PhaseBoundaryProperties liq "phase boundary property record";
      ThermoSysPro.Properties.WaterSteam.Common.PhaseBoundaryProperties vap "phase boundary property record";
      ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs gl "dimensionless Gibbs funcion and dervatives wrt pi and tau";
      ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs gv "dimensionless Gibbs funcion and dervatives wrt pi and tau";
      Modelica.Media.Common.HelmholtzDerivs fl "dimensionless Helmholtz function and dervatives wrt delta and tau";
      Modelica.Media.Common.HelmholtzDerivs fv "dimensionless Helmholtz function and dervatives wrt delta and tau";
      Modelica.SIunits.Temperature t1 "temperature at phase boundary, using inverse from region 1";
      Modelica.SIunits.Temperature t2 "temperature at phase boundary, using inverse from region 2";
    algorithm
      aux.region:=if region == 0 then if phase == 2 then 4 else ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.region_ps(p=p, s=s, phase=phase) else region;
      aux.phase:=if phase <> 0 then phase else if aux.region == 4 then 2 else 1;
      aux.p:=p;
      aux.s:=s;
      aux.R:=ThermoSysPro.Properties.WaterSteam.BaseIF97.data.RH2O;
      if aux.region == 1 then
        aux.T:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tps1(p, s);
        g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g1(p, aux.T);
        aux.h:=aux.R*aux.T*g.tau*g.gtau;
        aux.rho:=p/(aux.R*aux.T*g.pi*g.gpi);
        aux.vt:=aux.R/p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
        aux.vp:=aux.R*aux.T/(p*p)*g.pi*g.pi*g.gpipi;
        aux.cp:=-aux.R*g.tau*g.tau*g.gtautau;
        aux.cv:=aux.R*(-g.tau*g.tau*g.gtautau + (g.gpi - g.tau*g.gtaupi)*(g.gpi - g.tau*g.gtaupi)/g.gpipi);
        aux.x:=0.0;
      elseif aux.region == 2 then
        aux.T:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tps2(p, s);
        g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g2(p, aux.T);
        aux.h:=aux.R*aux.T*g.tau*g.gtau;
        aux.rho:=p/(aux.R*aux.T*g.pi*g.gpi);
        aux.vt:=aux.R/p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
        aux.vp:=aux.R*aux.T/(p*p)*g.pi*g.pi*g.gpipi;
        aux.cp:=-aux.R*g.tau*g.tau*g.gtautau;
        aux.cv:=aux.R*(-g.tau*g.tau*g.gtautau + (g.gpi - g.tau*g.gtaupi)*(g.gpi - g.tau*g.gtaupi)/g.gpipi);
        aux.x:=1.0;

      elseif aux.region == 3 then
        (aux.rho,aux.T,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.dtofps3(p=p, s=s, delp=1e-07, dels=1e-06);
        f:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3(aux.rho, aux.T);
        aux.h:=aux.R*aux.T*(f.tau*f.ftau + f.delta*f.fdelta);
        aux.s:=aux.R*(f.tau*f.ftau - f.f);
        aux.pd:=aux.R*aux.T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
        aux.pt:=aux.R*aux.rho*f.delta*(f.fdelta - f.tau*f.fdeltatau);
        aux.cv:=aux.R*(-f.tau*f.tau*f.ftautau);
        aux.cp:=(aux.rho*aux.rho*aux.pd*aux.cv + aux.T*aux.pt*aux.pt)/(aux.rho*aux.rho*aux.pd);
        aux.x:=0.0;

      elseif aux.region == 4 then
        s_liq:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.sl_p(p);
        s_vap:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.sv_p(p);
        aux.x:=if s_vap <> s_liq then (s - s_liq)/(s_vap - s_liq) else 1.0;
        if p < ThermoSysPro.Properties.WaterSteam.BaseIF97.data.PLIMIT4A then
          t1:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tps1(p, s_liq);
          t2:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tps2(p, s_vap);
          gl:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g1(p, t1);
          gv:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g2(p, t2);
          liq:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToBoundaryProps(gl);
          vap:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToBoundaryProps(gv);
          aux.T:=t1 + aux.x*(t2 - t1);
        else
          aux.T:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tsat(p);
          d_liq:=rhol_T(aux.T);
          d_vap:=rhov_T(aux.T);
          fl:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3(d_liq, aux.T);
          fv:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3(d_vap, aux.T);
          liq:=ThermoSysPro.Properties.WaterSteam.Common.helmholtzToBoundaryProps(fl);
          vap:=ThermoSysPro.Properties.WaterSteam.Common.helmholtzToBoundaryProps(fv);
        end if;
        aux.dpT:=if liq.d <> vap.d then (vap.s - liq.s)*liq.d*vap.d/(liq.d - vap.d) else ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.dptofT(aux.T);
        aux.h:=liq.h + aux.x*(vap.h - liq.h);
        aux.rho:=liq.d*vap.d/(vap.d + aux.x*(liq.d - vap.d));
        aux.cv:=ThermoSysPro.Properties.WaterSteam.Common.cv2Phase(liq, vap, aux.x, aux.T, p);
        aux.cp:=liq.cp + aux.x*(vap.cp - liq.cp);
        aux.pt:=liq.pt + aux.x*(vap.pt - liq.pt);
        aux.pd:=liq.pd + aux.x*(vap.pd - liq.pd);

      elseif aux.region == 5 then
        (aux.T,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.tofps5(p=p, s=s, relds=1e-07);
        assert(error == 0, "error in inverse iteration of steam tables");
        g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g5(p, aux.T);
        aux.h:=aux.R*aux.T*g.tau*g.gtau;
        aux.rho:=p/(aux.R*aux.T*g.pi*g.gpi);
        aux.vt:=aux.R/p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
        aux.vp:=aux.R*aux.T/(p*p)*g.pi*g.pi*g.gpipi;
        aux.cp:=-aux.R*g.tau*g.tau*g.gtautau;
        aux.cv:=aux.R*(-g.tau*g.tau*g.gtautau + (g.gpi - g.tau*g.gtaupi)*(g.gpi - g.tau*g.gtaupi)/g.gpipi);
      else
        assert(false, "error in region computation of IF97 steam tables" + "(p = " + String(p) + ", s = " + String(s) + ")");
      end if;
    end waterBaseProp_ps;

    function rho_props_ps "density as function of pressure and specific entropy"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEntropy s "specific entropy";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97BaseTwoPhase properties "auxiliary record";
      output Modelica.SIunits.Density rho "density";
    algorithm
      rho:=properties.rho;
      annotation(Inline=false, LateInline=true);
    end rho_props_ps;

    function rho_ps "density as function of pressure and specific entropy"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEntropy s "specific entropy";
      input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.Density rho "density";
    algorithm
      rho:=rho_props_ps(p, s, waterBaseProp_ps(p, s, phase, region));
    end rho_ps;

    function T_props_ps "temperature as function of pressure and specific entropy"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEntropy s "specific entropy";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97BaseTwoPhase properties "auxiliary record";
      output Modelica.SIunits.Temperature T "temperature";
    algorithm
      T:=properties.T;
      annotation(Inline=false, LateInline=true);
    end T_props_ps;

    function T_ps "temperature as function of pressure and specific entropy"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEntropy s "specific entropy";
      input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.Temperature T "Temperature";
    algorithm
      T:=T_props_ps(p, s, waterBaseProp_ps(p, s, phase, region));
    end T_ps;

    function h_props_ps "specific enthalpy as function or pressure and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEntropy s "specific entropy";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97BaseTwoPhase aux "auxiliary record";
      output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
    algorithm
      h:=aux.h;
      annotation(Inline=false, LateInline=true);
    end h_props_ps;

    function h_ps "specific enthalpy as function or pressure and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEntropy s "specific entropy";
      input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
    algorithm
      h:=h_props_ps(p, s, waterBaseProp_ps(p, s, phase, region));
    end h_ps;

    function phase_ps "phase as a function of  pressure and specific entropy"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEntropy s "specific entropy";
      output Integer phase "true if in liquid or gas or supercritical region";
    algorithm
      phase:=if s < sl_p(p) or s > sv_p(p) or p > ThermoSysPro.Properties.WaterSteam.BaseIF97.data.PCRIT then 1 else 2;
      annotation(InlineNoEvent=false);
    end phase_ps;

    function phase_ph "phase as a function of  pressure and specific enthalpy"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      output Integer phase "true if in liquid or gas or supercritical region";
    algorithm
      phase:=if h < hl_p(p) or h > hv_p(p) or p > ThermoSysPro.Properties.WaterSteam.BaseIF97.data.PCRIT then 1 else 2;
      annotation(InlineNoEvent=false);
    end phase_ph;

    function phase_dT "phase as a function of  pressure and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density rho "density";
      input Modelica.SIunits.Temperature T "temperature";
      output Integer phase "true if in liquid or gas or supercritical region";
    algorithm
      phase:=if not (rho < rhol_T(T) and rho > rhov_T(T) and T < ThermoSysPro.Properties.WaterSteam.BaseIF97.data.TCRIT) then 1 else 2;
      annotation(InlineNoEvent=false);
    end phase_dT;

    function rho_props_ph "density as function of pressure and specific enthalpy"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97BaseTwoPhase properties "auxiliary record";
      output Modelica.SIunits.Density rho "density";
    algorithm
      rho:=properties.rho;
      annotation(derivative(noDerivative=properties)=rho_ph_der, Inline=false, LateInline=true);
    end rho_props_ph;

    function rho_ph "density as function of pressure and specific enthalpy"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.Density rho "density";
    algorithm
      rho:=rho_props_ph(p, h, waterBaseProp_ph(p, h, phase, region));
    end rho_ph;

    function rho_ph_der "derivative function of rho_ph"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97BaseTwoPhase aux "auxiliary record";
      input Real p_der "derivative of pressure";
      input Real h_der "derivative of specific enthalpy";
      output Real rho_der "derivative of density";
    algorithm
      if aux.region == 4 then
        rho_der:=aux.rho*(aux.rho*aux.cv/aux.dpT + 1.0)/(aux.dpT*aux.T)*p_der + (-aux.rho*aux.rho/(aux.dpT*aux.T))*h_der;
      elseif aux.region == 3 then
        rho_der:=aux.rho*(aux.cv*aux.rho + aux.pt)/(aux.rho*aux.rho*aux.pd*aux.cv + aux.T*aux.pt*aux.pt)*p_der + (-aux.rho*aux.rho*aux.pt/(aux.rho*aux.rho*aux.pd*aux.cv + aux.T*aux.pt*aux.pt))*h_der;
      else
        rho_der:=(-aux.rho*aux.rho*(aux.vp*aux.cp - aux.vt/aux.rho + aux.T*aux.vt*aux.vt)/aux.cp)*p_der + (-aux.rho*aux.rho*aux.vt/aux.cp)*h_der;
      end if;
    end rho_ph_der;

    function T_props_ph "temperature as function of pressure and specific enthalpy"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97BaseTwoPhase properties "auxiliary record";
      output Modelica.SIunits.Temperature T "temperature";
    algorithm
      T:=properties.T;
      annotation(derivative(noDerivative=properties)=T_ph_der, Inline=false, LateInline=true);
    end T_props_ph;

    function T_ph "temperature as function of pressure and specific enthalpy"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.Temperature T "Temperature";
    algorithm
      T:=T_props_ph(p, h, waterBaseProp_ph(p, h, phase, region));
    end T_ph;

    function T_ph_der "derivative function of T_ph"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97BaseTwoPhase aux "auxiliary record";
      input Real p_der "derivative of pressure";
      input Real h_der "derivative of specific enthalpy";
      output Real T_der "derivative of temperature";
    algorithm
      if aux.region == 4 then
        T_der:=1/aux.dpT*p_der;
      elseif aux.region == 3 then
        T_der:=(-aux.rho*aux.pd + aux.T*aux.pt)/(aux.rho*aux.rho*aux.pd*aux.cv + aux.T*aux.pt*aux.pt)*p_der + aux.rho*aux.rho*aux.pd/(aux.rho*aux.rho*aux.pd*aux.cv + aux.T*aux.pt*aux.pt)*h_der;
      else
        T_der:=(-1/aux.rho + aux.T*aux.vt)/aux.cp*p_der + 1/aux.cp*h_der;
      end if;
    end T_ph_der;

    function s_props_ph "specific entropy as function of pressure and specific enthalpy"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97BaseTwoPhase properties "auxiliary record";
      output Modelica.SIunits.SpecificEntropy s "specific entropy";
    algorithm
      s:=properties.s;
      annotation(derivative(noDerivative=properties)=s_ph_der, Inline=false, LateInline=true);
    end s_props_ph;

    function s_ph "specific entropy as function of pressure and specific enthalpy"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.SpecificEntropy s "specific entropy";
    algorithm
      s:=s_props_ph(p, h, waterBaseProp_ph(p, h, phase, region));
    end s_ph;

    function s_ph_der "specific entropy as function of pressure and specific enthalpy"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97BaseTwoPhase aux "auxiliary record";
      input Real p_der "derivative of pressure";
      input Real h_der "derivative of specific enthalpy";
      output Real s_der "derivative of entropy";
    algorithm
      s_der:=-1/(aux.rho*aux.T)*p_der + 1/aux.T*h_der;
    end s_ph_der;

    function cv_props_ph "specific heat capacity at constant volume as function of pressure and specific enthalpy"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97BaseTwoPhase aux "auxiliary record";
      output Modelica.SIunits.SpecificHeatCapacity cv "specific heat capacity";
    algorithm
      cv:=aux.cv;
      annotation(Inline=false, LateInline=true);
    end cv_props_ph;

    function cv_ph "specific heat capacity at constant volume as function of pressure and specific enthalpy"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.SpecificHeatCapacity cv "specific heat capacity";
    algorithm
      cv:=cv_props_ph(p, h, waterBaseProp_ph(p, h, phase, region));
    end cv_ph;

    function regionAssertReal "assert function for inlining"
      extends Modelica.Icons.Function;
      input Boolean check "condition to check";
      output Real dummy "dummy output";
    algorithm
      assert(check, "this function can not be called with two-phase inputs!");
    end regionAssertReal;

    function cp_props_ph "specific heat capacity at constant pressure as function of pressure and specific enthalpy"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97BaseTwoPhase aux "auxiliary record";
      output Modelica.SIunits.SpecificHeatCapacity cp "specific heat capacity";
    algorithm
      cp:=aux.cp;
      annotation(Inline=false, LateInline=true);
    end cp_props_ph;

    function cp_ph "specific heat capacity at constant pressure as function of pressure and specific enthalpy"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.SpecificHeatCapacity cp "specific heat capacity";
    algorithm
      cp:=cp_props_ph(p, h, waterBaseProp_ph(p, h, phase, region));
    end cp_ph;

    function beta_props_ph "isobaric expansion coefficient as function of pressure and specific enthalpy"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97BaseTwoPhase aux "auxiliary record";
      output Modelica.SIunits.RelativePressureCoefficient beta "isobaric expansion coefficient";
    algorithm
      beta:=if aux.region == 3 or aux.region == 4 then aux.pt/(aux.rho*aux.pd) else aux.vt*aux.rho;
      annotation(Inline=false, LateInline=true);
    end beta_props_ph;

    function beta_ph "isobaric expansion coefficient as function of pressure and specific enthalpy"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.RelativePressureCoefficient beta "isobaric expansion coefficient";
    algorithm
      beta:=beta_props_ph(p, h, waterBaseProp_ph(p, h, phase, region));
    end beta_ph;

    function kappa_props_ph "isothermal compressibility factor as function of pressure and specific enthalpy"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97BaseTwoPhase aux "auxiliary record";
      output Modelica.SIunits.IsothermalCompressibility kappa "isothermal compressibility factor";
    algorithm
      kappa:=if aux.region == 3 or aux.region == 4 then 1/(aux.rho*aux.pd) else -aux.vp*aux.rho;
      annotation(Inline=false, LateInline=true);
    end kappa_props_ph;

    function kappa_ph "isothermal compressibility factor as function of pressure and specific enthalpy"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.IsothermalCompressibility kappa "isothermal compressibility factor";
    algorithm
      kappa:=kappa_props_ph(p, h, waterBaseProp_ph(p, h, phase, region));
    end kappa_ph;

    function velocityOfSound_props_ph "speed of sound as function of pressure and specific enthalpy"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97BaseTwoPhase aux "auxiliary record";
      output Modelica.SIunits.Velocity v_sound "speed of sound";
    algorithm
      v_sound:=if aux.region == 3 then sqrt((aux.pd*aux.rho*aux.rho*aux.cv + aux.pt*aux.pt*aux.T)/(aux.rho*aux.rho*aux.cv)) else if aux.region == 4 then sqrt(1/(aux.rho*(aux.rho*aux.cv/aux.dpT + 1.0)/(aux.dpT*aux.T) - 1/aux.rho*aux.rho*aux.rho/(aux.dpT*aux.T))) else sqrt(-aux.cp/(aux.rho*aux.rho*(aux.vp*aux.cp + aux.vt*aux.vt*aux.T)));
      annotation(Inline=false, LateInline=true);
    end velocityOfSound_props_ph;

    function velocityOfSound_ph
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.Velocity v_sound "speed of sound";
    algorithm
      v_sound:=velocityOfSound_props_ph(p, h, waterBaseProp_ph(p, h, phase, region));
    end velocityOfSound_ph;

    function isentropicExponent_props_ph "isentropic exponent as function of pressure and specific enthalpy"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97BaseTwoPhase aux "auxiliary record";
      output Real gamma "isentropic exponent";
    algorithm
      gamma:=if aux.region == 3 then 1/(aux.rho*p)*((aux.pd*aux.cv*aux.rho*aux.rho + aux.pt*aux.pt*aux.T)/aux.cv) else if aux.region == 4 then 1/(aux.rho*p)*aux.dpT*aux.dpT*aux.T/aux.cv else -1/(aux.rho*aux.p)*aux.cp/(aux.vp*aux.cp + aux.vt*aux.vt*aux.T);
      annotation(Inline=false, LateInline=true);
    end isentropicExponent_props_ph;

    function isentropicExponent_ph "isentropic exponent as function of pressure and specific enthalpy"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Real gamma "isentropic exponent";
    algorithm
      gamma:=isentropicExponent_props_ph(p, h, waterBaseProp_ph(p, h, phase, region));
      annotation(Inline=false, LateInline=true);
    end isentropicExponent_ph;

    function ddph_props "density derivative by pressure"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97BaseTwoPhase aux "auxiliary record";
      output Modelica.SIunits.DerDensityByPressure ddph "density derivative by pressure";
    algorithm
      ddph:=if aux.region == 3 then aux.rho*(aux.cv*aux.rho + aux.pt)/(aux.rho*aux.rho*aux.pd*aux.cv + aux.T*aux.pt*aux.pt) else if aux.region == 4 then aux.rho*(aux.rho*aux.cv/aux.dpT + 1.0)/(aux.dpT*aux.T) else -aux.rho*aux.rho*(aux.vp*aux.cp - aux.vt/aux.rho + aux.T*aux.vt*aux.vt)/aux.cp;
      annotation(Inline=false, LateInline=true);
    end ddph_props;

    function ddph "density derivative by pressure"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.DerDensityByPressure ddph "density derivative by pressure";
    algorithm
      ddph:=ddph_props(p, h, waterBaseProp_ph(p, h, phase, region));
    end ddph;

    function ddhp_props "density derivative by specific enthalpy"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97BaseTwoPhase aux "auxiliary record";
      output Modelica.SIunits.DerDensityByEnthalpy ddhp "density derivative by specific enthalpy";
    algorithm
      ddhp:=if aux.region == 3 then -aux.rho*aux.rho*aux.pt/(aux.rho*aux.rho*aux.pd*aux.cv + aux.T*aux.pt*aux.pt) else if aux.region == 4 then -aux.rho*aux.rho/(aux.dpT*aux.T) else -aux.rho*aux.rho*aux.vt/aux.cp;
      annotation(Inline=false, LateInline=true);
    end ddhp_props;

    function ddhp "density derivative by specific enthalpy"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.DerDensityByEnthalpy ddhp "density derivative by specific enthalpy";
    algorithm
      ddhp:=ddhp_props(p, h, waterBaseProp_ph(p, h, phase, region));
    end ddhp;

    function waterBaseProp_pT "intermediate property record for water (p and T prefered states)"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature";
      input Integer region=0 "if 0, do region computation, otherwise assume the region is this input";
      output ThermoSysPro.Properties.WaterSteam.Common.IF97BaseTwoPhase aux "auxiliary record";
    protected
      ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs g "dimensionless Gibbs funcion and dervatives wrt pi and tau";
      ThermoSysPro.Properties.WaterSteam.Common.HelmholtzDerivs f "dimensionless Helmholtz funcion and dervatives wrt delta and tau";
      Integer error "error flag for inverse iterations";
    algorithm
      aux.phase:=1;
      aux.region:=if region == 0 then ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.region_pT(p=p, T=T) else region;
      aux.R:=ThermoSysPro.Properties.WaterSteam.BaseIF97.data.RH2O;
      aux.p:=p;
      aux.T:=T;
      if aux.region == 1 then
        g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g1(p, T);
        aux.h:=aux.R*aux.T*g.tau*g.gtau;
        aux.s:=aux.R*(g.tau*g.gtau - g.g);
        aux.rho:=p/(aux.R*T*g.pi*g.gpi);
        aux.vt:=aux.R/p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
        aux.vp:=aux.R*T/(p*p)*g.pi*g.pi*g.gpipi;
        aux.cp:=-aux.R*g.tau*g.tau*g.gtautau;
        aux.cv:=aux.R*(-g.tau*g.tau*g.gtautau + (g.gpi - g.tau*g.gtaupi)*(g.gpi - g.tau*g.gtaupi)/g.gpipi);
        aux.x:=0.0;
      elseif aux.region == 2 then
        g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g2(p, T);
        aux.h:=aux.R*aux.T*g.tau*g.gtau;
        aux.s:=aux.R*(g.tau*g.gtau - g.g);
        aux.rho:=p/(aux.R*T*g.pi*g.gpi);
        aux.vt:=aux.R/p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
        aux.vp:=aux.R*T/(p*p)*g.pi*g.pi*g.gpipi;
        aux.cp:=-aux.R*g.tau*g.tau*g.gtautau;
        aux.cv:=aux.R*(-g.tau*g.tau*g.gtautau + (g.gpi - g.tau*g.gtaupi)*(g.gpi - g.tau*g.gtaupi)/g.gpipi);
        aux.x:=1.0;

      elseif aux.region == 3 then
        (aux.rho,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.dofpt3(p=p, T=T, delp=1e-07);
        f:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3(aux.rho, T);
        aux.h:=aux.R*T*(f.tau*f.ftau + f.delta*f.fdelta);
        aux.s:=aux.R*(f.tau*f.ftau - f.f);
        aux.pd:=aux.R*T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
        aux.pt:=aux.R*aux.rho*f.delta*(f.fdelta - f.tau*f.fdeltatau);
        aux.cv:=aux.R*(-f.tau*f.tau*f.ftautau);
        aux.x:=0.0;

      elseif aux.region == 5 then
        g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g5(p, T);
        aux.h:=aux.R*aux.T*g.tau*g.gtau;
        aux.s:=aux.R*(g.tau*g.gtau - g.g);
        aux.rho:=p/(aux.R*T*g.pi*g.gpi);
        aux.vt:=aux.R/p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
        aux.vp:=aux.R*T/(p*p)*g.pi*g.pi*g.gpipi;
        aux.cp:=-aux.R*g.tau*g.tau*g.gtautau;
        aux.cv:=aux.R*(-g.tau*g.tau*g.gtautau + (g.gpi - g.tau*g.gtaupi)*(g.gpi - g.tau*g.gtaupi)/g.gpipi);
      else
        assert(false, "error in region computation of IF97 steam tables" + "(p = " + String(p) + ", T = " + String(T) + ")");
      end if;
    end waterBaseProp_pT;

    function rho_props_pT "density as function or pressure and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97BaseTwoPhase aux "auxiliary record";
      output Modelica.SIunits.Density rho "density";
    algorithm
      rho:=aux.rho;
      annotation(derivative(noDerivative=aux)=rho_pT_der, Inline=false, LateInline=true);
    end rho_props_pT;

    function rho_pT "density as function or pressure and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.Density rho "density";
    algorithm
      rho:=rho_props_pT(p, T, waterBaseProp_pT(p, T, region));
    end rho_pT;

    function h_props_pT "specific enthalpy as function or pressure and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97BaseTwoPhase aux "auxiliary record";
      output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
    algorithm
      h:=aux.h;
      annotation(derivative(noDerivative=aux)=h_pT_der, Inline=false, LateInline=true);
    end h_props_pT;

    function h_pT "specific enthalpy as function or pressure and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "Temperature";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
    algorithm
      h:=h_props_pT(p, T, waterBaseProp_pT(p, T, region));
    end h_pT;

    function h_pT_der "derivative function of h_pT"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97BaseTwoPhase aux "auxiliary record";
      input Real p_der "derivative of pressure";
      input Real T_der "derivative of temperature";
      output Real h_der "derivative of specific enthalpy";
    algorithm
      if aux.region == 3 then
        h_der:=(-aux.rho*aux.pd + T*aux.pt)/(aux.rho*aux.rho*aux.pd)*p_der + (aux.rho*aux.rho*aux.pd*aux.cv + aux.T*aux.pt*aux.pt)/(aux.rho*aux.rho*aux.pd)*T_der;
      else
        h_der:=(1/aux.rho - aux.T*aux.vt)*p_der + aux.cp*T_der;
      end if;
    end h_pT_der;

    function rho_pT_der "derivative function of rho_pT"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97BaseTwoPhase aux "auxiliary record";
      input Real p_der "derivative of pressure";
      input Real T_der "derivative of temperature";
      output Real rho_der "derivative of density";
    algorithm
      if aux.region == 3 then
        rho_der:=1/aux.pd*p_der - aux.pt/aux.pd*T_der;
      else
        rho_der:=(-aux.rho*aux.rho*aux.vp)*p_der + (-aux.rho*aux.rho*aux.vt)*T_der;
      end if;
    end rho_pT_der;

    function s_props_pT "specific entropy as function of pressure and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97BaseTwoPhase aux "auxiliary record";
      output Modelica.SIunits.SpecificEntropy s "specific entropy";
    algorithm
      s:=aux.s;
      annotation(Inline=false, LateInline=true);
    end s_props_pT;

    function s_pT "temperature as function of pressure and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.SpecificEntropy s "specific entropy";
    algorithm
      s:=s_props_pT(p, T, waterBaseProp_pT(p, T, region));
      annotation(InlineNoEvent=false);
    end s_pT;

    function cv_props_pT "specific heat capacity at constant volume as function of pressure and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97BaseTwoPhase aux "auxiliary record";
      output Modelica.SIunits.SpecificHeatCapacity cv "specific heat capacity";
    algorithm
      cv:=aux.cv;
      annotation(Inline=false, LateInline=true);
    end cv_props_pT;

    function cv_pT "specific heat capacity at constant volume as function of pressure and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.SpecificHeatCapacity cv "specific heat capacity";
    algorithm
      cv:=cv_props_pT(p, T, waterBaseProp_pT(p, T, region));
      annotation(InlineNoEvent=false);
    end cv_pT;

    function cp_props_pT "specific heat capacity at constant pressure as function of pressure and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97BaseTwoPhase aux "auxiliary record";
      output Modelica.SIunits.SpecificHeatCapacity cp "specific heat capacity";
    algorithm
      cp:=if aux.region == 3 then (aux.rho*aux.rho*aux.pd*aux.cv + aux.T*aux.pt*aux.pt)/(aux.rho*aux.rho*aux.pd) else aux.cp;
      annotation(Inline=false, LateInline=true);
    end cp_props_pT;

    function cp_pT "specific heat capacity at constant pressure as function of pressure and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.SpecificHeatCapacity cp "specific heat capacity";
    algorithm
      cp:=cp_props_pT(p, T, waterBaseProp_pT(p, T, region));
      annotation(InlineNoEvent=false);
    end cp_pT;

    function beta_props_pT "isobaric expansion coefficient as function of pressure and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97BaseTwoPhase aux "auxiliary record";
      output Modelica.SIunits.RelativePressureCoefficient beta "isobaric expansion coefficient";
    algorithm
      beta:=if aux.region == 3 then aux.pt/(aux.rho*aux.pd) else aux.vt*aux.rho;
      annotation(Inline=false, LateInline=true);
    end beta_props_pT;

    function beta_pT "isobaric expansion coefficient as function of pressure and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.RelativePressureCoefficient beta "isobaric expansion coefficient";
    algorithm
      beta:=beta_props_pT(p, T, waterBaseProp_pT(p, T, region));
      annotation(InlineNoEvent=false);
    end beta_pT;

    function kappa_props_pT "isothermal compressibility factor as function of pressure and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97BaseTwoPhase aux "auxiliary record";
      output Modelica.SIunits.IsothermalCompressibility kappa "isothermal compressibility factor";
    algorithm
      kappa:=if aux.region == 3 then 1/(aux.rho*aux.pd) else -aux.vp*aux.rho;
      annotation(Inline=false, LateInline=true);
    end kappa_props_pT;

    function kappa_pT "isothermal compressibility factor as function of pressure and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.IsothermalCompressibility kappa "isothermal compressibility factor";
    algorithm
      kappa:=kappa_props_pT(p, T, waterBaseProp_pT(p, T, region));
      annotation(InlineNoEvent=false);
    end kappa_pT;

    function velocityOfSound_props_pT "speed of sound as function of pressure and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97BaseTwoPhase aux "auxiliary record";
      output Modelica.SIunits.Velocity v_sound "speed of sound";
    algorithm
      v_sound:=if aux.region == 3 then sqrt((aux.pd*aux.rho*aux.rho*aux.cv + aux.pt*aux.pt*aux.T)/(aux.rho*aux.rho*aux.cv)) else sqrt(-aux.cp/(aux.rho*aux.rho*(aux.vp*aux.cp + aux.vt*aux.vt*aux.T)));
      annotation(Inline=false, LateInline=true);
    end velocityOfSound_props_pT;

    function velocityOfSound_pT "speed of sound as function of pressure and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.Velocity v_sound "speed of sound";
    algorithm
      v_sound:=velocityOfSound_props_pT(p, T, waterBaseProp_pT(p, T, region));
    end velocityOfSound_pT;

    function isentropicExponent_props_pT "isentropic exponent as function of pressure and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97BaseTwoPhase aux "auxiliary record";
      output Real gamma "isentropic exponent";
    algorithm
      gamma:=if aux.region == 3 then 1/(aux.rho*p)*((aux.pd*aux.cv*aux.rho*aux.rho + aux.pt*aux.pt*aux.T)/aux.cv) else -1/(aux.rho*aux.p)*aux.cp/(aux.vp*aux.cp + aux.vt*aux.vt*aux.T);
      annotation(Inline=false, LateInline=true);
    end isentropicExponent_props_pT;

    function isentropicExponent_pT "isentropic exponent as function of pressure and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Real gamma "isentropic exponent";
    algorithm
      gamma:=isentropicExponent_props_pT(p, T, waterBaseProp_pT(p, T, region));
      annotation(Inline=false, LateInline=true);
    end isentropicExponent_pT;

    function waterBaseProp_dT "intermediate property record for water (d and T prefered states)"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density rho "density";
      input Modelica.SIunits.Temperature T "temperature";
      input Integer phase=0 "phase: 2 for two-phase, 1 for one phase, 0 if unknown";
      input Integer region=0 "if 0, do region computation, otherwise assume the region is this input";
      output ThermoSysPro.Properties.WaterSteam.Common.IF97BaseTwoPhase aux "auxiliary record";
    protected
      Modelica.SIunits.SpecificEnthalpy h_liq "liquid specific enthalpy";
      Modelica.SIunits.Density d_liq "liquid density";
      Modelica.SIunits.SpecificEnthalpy h_vap "vapour specific enthalpy";
      Modelica.SIunits.Density d_vap "vapour density";
      ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs g "dimensionless Gibbs funcion and dervatives wrt pi and tau";
      ThermoSysPro.Properties.WaterSteam.Common.HelmholtzDerivs f "dimensionless Helmholtz funcion and dervatives wrt delta and tau";
      Modelica.Media.Common.PhaseBoundaryProperties liq "phase boundary property record";
      Modelica.Media.Common.PhaseBoundaryProperties vap "phase boundary property record";
      Modelica.Media.Common.GibbsDerivs gl "dimensionless Gibbs funcion and dervatives wrt pi and tau";
      Modelica.Media.Common.GibbsDerivs gv "dimensionless Gibbs funcion and dervatives wrt pi and tau";
      Modelica.Media.Common.HelmholtzDerivs fl "dimensionless Helmholtz function and dervatives wrt delta and tau";
      Modelica.Media.Common.HelmholtzDerivs fv "dimensionless Helmholtz function and dervatives wrt delta and tau";
      Integer error "error flag for inverse iterations";
    algorithm
      aux.region:=if region == 0 then if phase == 2 then 4 else ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.region_dT(d=rho, T=T, phase=phase) else region;
      aux.phase:=if aux.region == 4 then 2 else 1;
      aux.R:=ThermoSysPro.Properties.WaterSteam.BaseIF97.data.RH2O;
      aux.rho:=rho;
      aux.T:=T;
      if aux.region == 1 then
        (aux.p,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.pofdt125(d=rho, T=T, reldd=1e-08, region=1);
        g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g1(aux.p, T);
        aux.h:=aux.R*aux.T*g.tau*g.gtau;
        aux.s:=aux.R*(g.tau*g.gtau - g.g);
        aux.rho:=aux.p/(aux.R*T*g.pi*g.gpi);
        aux.vt:=aux.R/aux.p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
        aux.vp:=aux.R*T/(aux.p*aux.p)*g.pi*g.pi*g.gpipi;
        aux.cp:=-aux.R*g.tau*g.tau*g.gtautau;
        aux.cv:=aux.R*(-g.tau*g.tau*g.gtautau + (g.gpi - g.tau*g.gtaupi)*(g.gpi - g.tau*g.gtaupi)/g.gpipi);
        aux.x:=0.0;
      elseif aux.region == 2 then
        (aux.p,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.pofdt125(d=rho, T=T, reldd=1e-08, region=2);
        g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g2(aux.p, T);
        aux.h:=aux.R*aux.T*g.tau*g.gtau;
        aux.s:=aux.R*(g.tau*g.gtau - g.g);
        aux.rho:=aux.p/(aux.R*T*g.pi*g.gpi);
        aux.vt:=aux.R/aux.p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
        aux.vp:=aux.R*T/(aux.p*aux.p)*g.pi*g.pi*g.gpipi;
        aux.cp:=-aux.R*g.tau*g.tau*g.gtautau;
        aux.cv:=aux.R*(-g.tau*g.tau*g.gtautau + (g.gpi - g.tau*g.gtaupi)*(g.gpi - g.tau*g.gtaupi)/g.gpipi);
        aux.x:=1.0;

      elseif aux.region == 3 then
        f:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3(rho, T);
        aux.p:=aux.R*rho*T*f.delta*f.fdelta;
        aux.h:=aux.R*T*(f.tau*f.ftau + f.delta*f.fdelta);
        aux.s:=aux.R*(f.tau*f.ftau - f.f);
        aux.pd:=aux.R*T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
        aux.pt:=aux.R*rho*f.delta*(f.fdelta - f.tau*f.fdeltatau);
        aux.cp:=(aux.rho*aux.rho*aux.pd*aux.cv + aux.T*aux.pt*aux.pt)/(aux.rho*aux.rho*aux.pd);
        aux.cv:=aux.R*(-f.tau*f.tau*f.ftautau);
        aux.x:=0.0;

      elseif aux.region == 4 then
        aux.p:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.psat(T);
        aux.dpT:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.dptofT(T);
        d_liq:=rhol_T(T);
        d_vap:=rhov_T(T);
        h_liq:=hl_p(aux.p);
        h_vap:=hv_p(aux.p);
        aux.x:=if d_vap <> d_liq then (1/rho - 1/d_liq)/(1/d_vap - 1/d_liq) else 1.0;
        aux.h:=h_liq + aux.x*(h_vap - h_liq);
        if T < ThermoSysPro.Properties.WaterSteam.BaseIF97.data.TLIMIT1 then
          gl:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g1(aux.p, T);
          gv:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g2(aux.p, T);
          liq:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToBoundaryProps(gl);
          vap:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToBoundaryProps(gv);
        else
          fl:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3(d_liq, T);
          fv:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3(d_vap, T);
          liq:=ThermoSysPro.Properties.WaterSteam.Common.helmholtzToBoundaryProps(fl);
          vap:=ThermoSysPro.Properties.WaterSteam.Common.helmholtzToBoundaryProps(fv);
        end if;
        aux.dpT:=if liq.d <> vap.d then (vap.s - liq.s)*liq.d*vap.d/(liq.d - vap.d) else ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.dptofT(aux.T);
        aux.s:=liq.s + aux.x*(vap.s - liq.s);
        aux.cv:=ThermoSysPro.Properties.WaterSteam.Common.cv2Phase(liq, vap, aux.x, aux.T, aux.p);
        aux.cp:=liq.cp + aux.x*(vap.cp - liq.cp);
        aux.pt:=liq.pt + aux.x*(vap.pt - liq.pt);
        aux.pd:=liq.pd + aux.x*(vap.pd - liq.pd);

      elseif aux.region == 5 then
        (aux.p,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.pofdt125(d=rho, T=T, reldd=1e-08, region=5);
        g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g2(aux.p, T);
        aux.h:=aux.R*aux.T*g.tau*g.gtau;
        aux.s:=aux.R*(g.tau*g.gtau - g.g);
        aux.rho:=aux.p/(aux.R*T*g.pi*g.gpi);
        aux.vt:=aux.R/aux.p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
        aux.vp:=aux.R*T/(aux.p*aux.p)*g.pi*g.pi*g.gpipi;
        aux.cp:=-aux.R*g.tau*g.tau*g.gtautau;
        aux.cv:=aux.R*(-g.tau*g.tau*g.gtautau + (g.gpi - g.tau*g.gtaupi)*(g.gpi - g.tau*g.gtaupi)/g.gpipi);
      else
        assert(false, "error in region computation of IF97 steam tables" + "(rho = " + String(rho) + ", T = " + String(T) + ")");
      end if;
    end waterBaseProp_dT;

    function h_props_dT "specific enthalpy as function of density and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "Temperature";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97BaseTwoPhase aux "auxiliary record";
      output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
    algorithm
      h:=aux.h;
      annotation(derivative(noDerivative=aux)=h_dT_der, Inline=false, LateInline=true);
    end h_props_dT;

    function h_dT "specific enthalpy as function of density and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "Temperature";
      input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
    algorithm
      h:=h_props_dT(d, T, waterBaseProp_dT(d, T, phase, region));
    end h_dT;

    function h_dT_der "derivative function of h_dT"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "temperature";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97BaseTwoPhase aux "auxiliary record";
      input Real d_der "derivative of density";
      input Real T_der "derivative of temperature";
      output Real h_der "derivative of specific enthalpy";
    algorithm
      if aux.region == 3 then
        h_der:=(-d*aux.pd + T*aux.pt)/(d*d)*d_der + (aux.cv*d + aux.pt)/d*T_der;
      elseif aux.region == 4 then
        h_der:=T*aux.dpT/(d*d)*d_der + (aux.cv*d + aux.dpT)/d*T_der;
      else
        h_der:=(-(-1/d + T*aux.vt)/(d*d*aux.vp))*d_der + (aux.vp*aux.cp - aux.vt/d + T*aux.vt*aux.vt)/aux.vp*T_der;
      end if;
    end h_dT_der;

    function p_props_dT "pressure as function of density and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "Temperature";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97BaseTwoPhase aux "auxiliary record";
      output Modelica.SIunits.Pressure p "pressure";
    algorithm
      p:=aux.p;
      annotation(derivative(noDerivative=aux)=p_dT_der, Inline=false, LateInline=true);
    end p_props_dT;

    function p_dT "pressure as function of density and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "Temperature";
      input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.Pressure p "pressure";
    algorithm
      p:=p_props_dT(d, T, waterBaseProp_dT(d, T, phase, region));
    end p_dT;

    function p_dT_der "derivative function of p_dT"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "temperature";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97BaseTwoPhase aux "auxiliary record";
      input Real d_der "derivative of density";
      input Real T_der "derivative of temperature";
      output Real p_der "derivative of pressure";
    algorithm
      if aux.region == 3 then
        p_der:=aux.pd*d_der + aux.pt*T_der;
      elseif aux.region == 4 then
        p_der:=aux.dpT*T_der;
      else
        p_der:=(-1/(d*d*aux.vp))*d_der + (-aux.vt/aux.vp)*T_der;
      end if;
    end p_dT_der;

    function s_props_dT "specific entropy as function of density and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "Temperature";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97BaseTwoPhase aux "auxiliary record";
      output Modelica.SIunits.SpecificEntropy s "specific entropy";
    algorithm
      s:=aux.s;
      annotation(Inline=false, LateInline=true);
    end s_props_dT;

    function s_dT "temperature as function of density and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "Temperature";
      input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.SpecificEntropy s "specific entropy";
    algorithm
      s:=s_props_dT(d, T, waterBaseProp_dT(d, T, phase, region));
    end s_dT;

    function cv_props_dT "specific heat capacity at constant volume as function of density and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "temperature";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97BaseTwoPhase aux "auxiliary record";
      output Modelica.SIunits.SpecificHeatCapacity cv "specific heat capacity";
    algorithm
      cv:=aux.cv;
      annotation(Inline=false, LateInline=true);
    end cv_props_dT;

    function cv_dT "specific heat capacity at constant volume as function of density and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "temperature";
      input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.SpecificHeatCapacity cv "specific heat capacity";
    algorithm
      cv:=cv_props_dT(d, T, waterBaseProp_dT(d, T, phase, region));
    end cv_dT;

    function cp_props_dT "specific heat capacity at constant pressure as function of density and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "temperature";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97BaseTwoPhase aux "auxiliary record";
      output Modelica.SIunits.SpecificHeatCapacity cp "specific heat capacity";
    algorithm
      cp:=aux.cp;
      annotation(Inline=false, LateInline=true);
    end cp_props_dT;

    function cp_dT "specific heat capacity at constant pressure as function of density and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "temperature";
      input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.SpecificHeatCapacity cp "specific heat capacity";
    algorithm
      cp:=cp_props_dT(d, T, waterBaseProp_dT(d, T, phase, region));
    end cp_dT;

    function beta_props_dT "isobaric expansion coefficient as function of density and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "temperature";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97BaseTwoPhase aux "auxiliary record";
      output Modelica.SIunits.RelativePressureCoefficient beta "isobaric expansion coefficient";
    algorithm
      beta:=if aux.region == 3 or aux.region == 4 then aux.pt/(aux.rho*aux.pd) else aux.vt*aux.rho;
      annotation(Inline=false, LateInline=true);
    end beta_props_dT;

    function beta_dT "isobaric expansion coefficient as function of density and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "temperature";
      input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.RelativePressureCoefficient beta "isobaric expansion coefficient";
    algorithm
      beta:=beta_props_dT(d, T, waterBaseProp_dT(d, T, phase, region));
    end beta_dT;

    function kappa_props_dT "isothermal compressibility factor as function of density and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "temperature";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97BaseTwoPhase aux "auxiliary record";
      output Modelica.SIunits.IsothermalCompressibility kappa "isothermal compressibility factor";
    algorithm
      kappa:=if aux.region == 3 or aux.region == 4 then 1/(aux.rho*aux.pd) else -aux.vp*aux.rho;
      annotation(Inline=false, LateInline=true);
    end kappa_props_dT;

    function kappa_dT "isothermal compressibility factor as function of density and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "temperature";
      input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.IsothermalCompressibility kappa "isothermal compressibility factor";
    algorithm
      kappa:=kappa_props_dT(d, T, waterBaseProp_dT(d, T, phase, region));
    end kappa_dT;

    function velocityOfSound_props_dT "speed of sound as function of density and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "temperature";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97BaseTwoPhase aux "auxiliary record";
      output Modelica.SIunits.Velocity v_sound "speed of sound";
    algorithm
      v_sound:=if aux.region == 3 then sqrt((aux.pd*aux.rho*aux.rho*aux.cv + aux.pt*aux.pt*aux.T)/(aux.rho*aux.rho*aux.cv)) else if aux.region == 4 then sqrt(1/(aux.rho*(aux.rho*aux.cv/aux.dpT + 1.0)/(aux.dpT*aux.T) - 1/aux.rho*aux.rho*aux.rho/(aux.dpT*aux.T))) else sqrt(-aux.cp/(aux.rho*aux.rho*(aux.vp*aux.cp + aux.vt*aux.vt*aux.T)));
      annotation(Inline=false, LateInline=true);
    end velocityOfSound_props_dT;

    function velocityOfSound_dT "speed of sound as function of density and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "temperature";
      input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.Velocity v_sound "speed of sound";
    algorithm
      v_sound:=velocityOfSound_props_dT(d, T, waterBaseProp_dT(d, T, phase, region));
    end velocityOfSound_dT;

    function isentropicExponent_props_dT "isentropic exponent as function of density and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "temperature";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97BaseTwoPhase aux "auxiliary record";
      output Real gamma "isentropic exponent";
    algorithm
      gamma:=if aux.region == 3 then 1/(aux.rho*aux.p)*((aux.pd*aux.cv*aux.rho*aux.rho + aux.pt*aux.pt*aux.T)/aux.cv) else if aux.region == 4 then 1/(aux.rho*aux.p)*aux.dpT*aux.dpT*aux.T/aux.cv else -1/(aux.rho*aux.p)*aux.cp/(aux.vp*aux.cp + aux.vt*aux.vt*aux.T);
      annotation(Inline=false, LateInline=true);
    end isentropicExponent_props_dT;

    function isentropicExponent_dT "isentropic exponent as function of density and temperature"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "temperature";
      input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Real gamma "isentropic exponent";
    algorithm
      gamma:=isentropicExponent_props_dT(d, T, waterBaseProp_dT(d, T, phase, region));
      annotation(Inline=false, LateInline=true);
    end isentropicExponent_dT;

  protected
    package ThermoFluidSpecial
      function water_ph "calculate the property record for dynamic simulation properties using p,h as states"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
        input Integer phase=0 "phase: 2 for two-phase, 1 for one phase, 0 if unknown";
        output ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph pro "property record for dynamic simulation";
      protected
        ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs g "dimensionless Gibbs funcion and dervatives wrt pi and tau";
        ThermoSysPro.Properties.WaterSteam.Common.HelmholtzDerivs f "dimensionless Helmholtz funcion and dervatives wrt delta and tau";
        Integer region(min=1, max=5) "IF97 region";
        Integer error "error flag";
        Modelica.SIunits.Temperature T "temperature";
        Modelica.SIunits.Density d "density";
      algorithm
        region:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.region_ph(p, h, phase);
        if region == 1 then
          T:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tph1(p, h);
          g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g1(p, T);
          pro:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToProps_ph(g);
        elseif region == 2 then
          T:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tph2(p, h);
          g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g2(p, T);
          pro:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToProps_ph(g);

        elseif region == 3 then
          (d,T,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.dtofph3(p=p, h=h, delp=1e-07, delh=1e-06);
          f:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3(d, T);
          pro:=ThermoSysPro.Properties.WaterSteam.Common.helmholtzToProps_ph(f);

        elseif region == 4 then
          pro:=ThermoSysPro.Properties.WaterSteam.BaseIF97.TwoPhase.waterR4_ph(p=p, h=h);

        elseif region == 5 then
          (T,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.tofph5(p=p, h=h, reldh=1e-07);
          g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g5(p, T);
          pro:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToProps_ph(g);
        end if;
      end water_ph;

      function water_dT "calculate property record for dynamic simulation properties using d and T as dynamic states"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Density d "density";
        input Modelica.SIunits.Temperature T "temperature";
        input Integer phase=0 "phase: 2 for two-phase, 1 for one phase, 0 if unknown";
        output ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_dT pro "property record for dynamic simulation";
      protected
        Modelica.SIunits.Pressure p "pressure";
        Integer region(min=1, max=5) "IF97 region";
        ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs g "dimensionless Gibbs funcion and dervatives wrt pi and tau";
        ThermoSysPro.Properties.WaterSteam.Common.HelmholtzDerivs f "dimensionless Helmholtz funcion and dervatives wrt delta and tau";
        Integer error "error flag";
      algorithm
        region:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.region_dT(d, T, phase);
        if region == 1 then
          (p,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.pofdt125(d=d, T=T, reldd=iter.DELD, region=1);
          g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g1(p, T);
          pro:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToProps_dT(g);
        elseif region == 2 then
          (p,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.pofdt125(d=d, T=T, reldd=iter.DELD, region=2);
          g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g2(p, T);
          pro:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToProps_dT(g);

        elseif region == 3 then
          f:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3(d, T);
          pro:=ThermoSysPro.Properties.WaterSteam.Common.helmholtzToProps_dT(f);

        elseif region == 4 then
          pro:=ThermoSysPro.Properties.WaterSteam.BaseIF97.TwoPhase.waterR4_dT(d=d, T=T);

        elseif region == 5 then
          (p,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.pofdt125(d=d, T=T, reldd=iter.DELD, region=5);
          g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g5(p, T);
          pro:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToProps_dT(g);
        end if;
      end water_dT;

      function water_pT "calculate property record for dynamic simulation properties using p and T as dynamic states"
        extends Modelica.Icons.Function;
        input Modelica.SIunits.Pressure p "pressure";
        input Modelica.SIunits.Temperature T "temperature";
        output Modelica.Media.Common.ThermoFluidSpecial.ThermoProperties_pT pro "property record for dynamic simulation";
      protected
        Modelica.SIunits.Density d "density";
        Integer region(min=1, max=5) "IF97 region";
        Modelica.Media.Common.GibbsDerivs g "dimensionless Gibbs funcion and dervatives wrt pi and tau";
        Modelica.Media.Common.HelmholtzDerivs f "dimensionless Helmholtz funcion and dervatives wrt delta and tau";
        Integer error "error flag";
      algorithm
        region:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.region_pT(p, T);
        if region == 1 then
          g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g1(p, T);
          pro:=Modelica.Media.Common.ThermoFluidSpecial.gibbsToProps_pT(g);
        elseif region == 2 then
          g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g2(p, T);
          pro:=Modelica.Media.Common.ThermoFluidSpecial.gibbsToProps_pT(g);

        elseif region == 3 then
          (d,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.dofpt3(p=p, T=T, delp=iter.DELP);
          f:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3(d, T);
          pro:=Modelica.Media.Common.ThermoFluidSpecial.helmholtzToProps_pT(f);

        elseif region == 5 then
          g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g5(p, T);
          pro:=Modelica.Media.Common.ThermoFluidSpecial.gibbsToProps_pT(g);
        end if;
      end water_pT;

    end ThermoFluidSpecial;

  public
    function hl_p= ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.hl_p "compute the saturated liquid specific h(p)";
    function hv_p= ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.hv_p "compute the saturated vapour specific h(p)";
    function sl_p= ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.sl_p "compute the saturated liquid specific s(p)";
    function sv_p= ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.sv_p "compute the saturated vapour specific s(p)";
    function rhol_T= ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.rhol_T "compute the saturated liquid d(T)";
    function rhov_T= ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.rhov_T "compute the saturated vapour d(T)";
    function rhol_p= ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.rhol_p "compute the saturated liquid d(p)";
    function rhov_p= ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.rhov_p "compute the saturated vapour d(p)";
    function dynamicViscosity= ThermoSysPro.Properties.WaterSteam.BaseIF97.Transport.visc_dT "compute eta(d,T) in the one-phase region";
    function thermalConductivity= ThermoSysPro.Properties.WaterSteam.BaseIF97.Transport.cond_industrial_dT "compute lambda(d,T) in the one-phase region";
    function surfaceTension= ThermoSysPro.Properties.WaterSteam.BaseIF97.Transport.surfaceTension "compute sigma(T) at saturation T";
    function isentropicEnthalpy "isentropic specific enthalpy from p,s (preferably use dynamicIsentropicEnthalpy in dynamic simulation!)"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEntropy s "specific entropy";
      input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
      input Integer region=0 "if 0, region is unknown, otherwise known and this input";
      output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
    algorithm
      h:=isentropicEnthalpy_props(p, s, waterBaseProp_ps(p, s, phase, region));
    end isentropicEnthalpy;

    function isentropicEnthalpy_props
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEntropy s "specific entropy";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97BaseTwoPhase aux "auxiliary record";
      output Modelica.SIunits.SpecificEnthalpy h "isentropic enthalpay";
    algorithm
      h:=aux.h;
      annotation(derivative(noDerivative=aux)=isentropicEnthalpy_der, Inline=false, LateInline=true);
    end isentropicEnthalpy_props;

    function isentropicEnthalpy_der "derivative of isentropic specific enthalpy from p,s"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEntropy s "specific entropy";
      input ThermoSysPro.Properties.WaterSteam.Common.IF97BaseTwoPhase aux "auxiliary record";
      input Real p_der "pressure derivative";
      input Real s_der "entropy derivative";
      output Real h_der "specific enthalpy derivative";
    algorithm
      h_der:=1/aux.rho*p_der + aux.T*s_der;
    end isentropicEnthalpy_der;

    function dynamicIsentropicEnthalpy "isentropic specific enthalpy from p,s and good guesses of d and T"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEntropy s "specific entropy";
      input Modelica.SIunits.Density dguess "good guess density, e.g. from adjacent volume";
      input Modelica.SIunits.Temperature Tguess "good guess temperature, e.g. from adjacent volume";
      input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
      output Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
    algorithm
      h:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Isentropic.water_hisentropic_dyn(p, s, dguess, Tguess, 0);
    end dynamicIsentropicEnthalpy;

  end Standard;

  annotation(Documentation(info="<HTML>
      <h4>Package description:</h4>
      <p>This package provides high accuracy physical properties for water according
      to the IAPWS/IF97 standard. It has been part of the ThermoFluid Modelica library and been extended,
      reorganized and documented to become part of the Modelica Standard library.</p>
      <p>An important feature that distinguishes this implementation of the IF97 steam property standard
      is that this implementation has been explicitly designed to work well in dynamic simulations. Computational
      performance has been of high importance. This means that there often exist several ways to get the same result
      from different functions if one of the functions is called often but can be optimized for that purpose.
      </p>
      <p>
      The original documentation of the IAPWS/IF97 steam properties can freely be distributed with computer
      implementations, so for curious minds the complete standard documentation is provided with the Modelica
      properties library. The following documents are included
      (in directory Modelica\\help\\IF97documentation):
      <ul>
      <li><a href=\"IF97documentation/IF97.pdf\">IF97.pdf</a> The standards document for the main part of the IF97.</li>
      <li><a href=\"IF97documentation/Back3.pdf\">Back3.pdf</a> The backwards equations for region 3.</li>
      <li><a href=\"IF97documentation/crits.pdf\">crits.pdf</a> The critical point data.</li>
      <li><a href=\"IF97documentation/meltsub.pdf\">meltsub.pdf</a> The melting- and sublimation line formulation (in IF97_Utilities.BaseIF97.IceBoundaries)</li>
      <li><a href=\"IF97documentation/surf.pdf\">surf.pdf</a> The surface tension standard definition</li>
      <li><a href=\"IF97documentation/thcond.pdf\">thcond.pdf</a> The thermal conductivity standard definition</li>
      <li><a href=\"IF97documentation/visc.pdf\">visc.pdf</a> The viscosity standard definition</li>
      </ul>
      </p>
      <h4>Package contents
      </h4>
      <p>
      <ul>
      <li>Package <b>BaseIF97</b> contains the implementation of the IAPWS-IF97 as described in
      <a href=\"IF97documentation/IF97.pdf\">IF97.pdf</a>. The explicit backwards equations for region 3 from
      <a href=\"IF97documentation/Back3.pdf\">Back3.pdf</a> are implemented as initial values for an inverse iteration of the exact
      function in IF97 for the input pairs (p,h) and (p,s).
      The low-level functions in BaseIF97 are not needed for standard simulation usage,
      but can be useful for experts and some special purposes.</li>
      <li>Function <b>water_ph</b> returns all properties needed for a dynamic control volume model and properties of general
      interest using pressure p and specific entropy enthalpy h as dynamic states in the record ThermoProperties_ph. </li>
      <li>Function <b>water_ps</b> returns all properties needed for a dynamic control volume model and properties of general
      interest using pressure p and specific entropy s as dynamic states in the record ThermoProperties_ps. </li>
      <li>Function <b>water_dT</b> returns all properties needed for a dynamic control volume model and properties of general
      interest using density d and temperature T as dynamic states in the record ThermoProperties_dT. </li>
      <li>Function <b>water_pT</b> returns all properties needed for a dynamic control volume model and properties of general
      interest using pressure p and temperature T as dynamic states in the record ThermoProperties_pT. Due to the coupling of
      pressure and temperature in the two-phase region, this model can obviously
      only be used for one-phase models or models treating both phases independently.</li>
      <li>Function <b>hl_p</b> computes the liquid specific enthalpy as a function of pressure. For overcritical pressures,
      the critical specific enthalpy is returned</li>
      <li>Function <b>hv_p</b> computes the vapour specific enthalpy as a function of pressure. For overcritical pressures,
      the critical specific enthalpy is returned</li>
      <li>Function <b>sl_p</b> computes the liquid specific entropy as a function of pressure. For overcritical pressures,
      the critical  specific entropy is returned</li>
      <li>Function <b>sv_p</b> computes the vapour  specific entropy as a function of pressure. For overcritical pressures,
      the critical  specific entropyis returned</li>
      <li>Function <b>rhol_T</b> computes the liquid density as a function of temperature. For overcritical temperatures,
      the critical density is returned</li>
      <li>Function <b>rhol_T</b> computes the vapour density as a function of temperature. For overcritical temperatures,
      the critical density is returned</li>
      <li>Function <b>dynamicViscosity</b> computes the dynamic viscosity as a function of density and temperature.</li>
      <li>Function <b>thermalConductivity</b> computes the thermal conductivity as a function of density, temperature and pressure.
      <b>Important note</b>: Obviously only two of the three
      inputs are really needed, but using three inputs speeds up the computation and the three variables
      are known in most models anyways. The inputs d,T and p have to be consistent.</li>
      <li>Function <b>surfaceTension</b> computes the surface tension between vapour
          and liquid water as a function of temperature.</li>
      <li>Function <b>isentropicEnthalpy</b> computes the specific enthalpy h(p,s,phase) in all regions.
          The phase input is needed due to discontinuous derivatives at the phase boundary.</li>
      <li>Function <b>dynamicIsentropicEnthalpy</b> computes the specific enthalpy h(p,s,,dguess,Tguess,phase) in all regions.
          The phase input is needed due to discontinuous derivatives at the phase boundary. Tguess and dguess are initial guess
          values for the density and temperature consistent with p and s. This function should be preferred in
          dynamic simulations where good guesses are often available.</li>
      </ul>
      </p>
      <h4>Version Info and Revision history
      </h4>
      <ul>
      <li>First implemented: <i>July, 2000</i>
      by Hubertus Tummescheit for the ThermoFluid Library with help from Jonas Eborn and Falko Jens Wagner
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
      </HTML>", revisions="<h4>Intermediate release notes during development<\\h4>
<p>Currenly the Events/noEvents switch is only implmented for p-h states. Only after testing that implmentation, it will be extended to dT.</p>"));
protected
  package ThermoFluidSpecial
    function water_ph "calculate the property record for dynamic simulation properties using p,h as states"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.SpecificEnthalpy h "specific enthalpy";
      input Integer phase=0 "phase: 2 for two-phase, 1 for one phase, 0 if unknown";
      output ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph pro "property record for dynamic simulation";
    protected
      ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs g "dimensionless Gibbs funcion and dervatives wrt pi and tau";
      ThermoSysPro.Properties.WaterSteam.Common.HelmholtzDerivs f "dimensionless Helmholtz funcion and dervatives wrt delta and tau";
      Integer region(min=1, max=5) "IF97 region";
      Integer error "error flag";
      Modelica.SIunits.Temperature T "temperature";
      Modelica.SIunits.Density d "density";
    algorithm
      region:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.region_ph(p, h, phase);
      if region == 1 then
        T:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tph1(p, h);
        g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g1(p, T);
        pro:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToProps_ph(g);
      elseif region == 2 then
        T:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tph2(p, h);
        g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g2(p, T);
        pro:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToProps_ph(g);

      elseif region == 3 then
        (d,T,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.dtofph3(p=p, h=h, delp=1e-07, delh=1e-06);
        f:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3(d, T);
        pro:=ThermoSysPro.Properties.WaterSteam.Common.helmholtzToProps_ph(f);

      elseif region == 4 then
        pro:=ThermoSysPro.Properties.WaterSteam.BaseIF97.TwoPhase.waterR4_ph(p=p, h=h);

      elseif region == 5 then
        (T,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.tofph5(p=p, h=h, reldh=1e-07);
        g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g5(p, T);
        pro:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToProps_ph(g);
      end if;
    end water_ph;

    function water_dT "calculate property record for dynamic simulation properties using d and T as dynamic states"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Density d "density";
      input Modelica.SIunits.Temperature T "temperature";
      input Integer phase=0 "phase: 2 for two-phase, 1 for one phase, 0 if unknown";
      output ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_dT pro "property record for dynamic simulation";
    protected
      Modelica.SIunits.Pressure p "pressure";
      Integer region(min=1, max=5) "IF97 region";
      ThermoSysPro.Properties.WaterSteam.Common.GibbsDerivs g "dimensionless Gibbs funcion and dervatives wrt pi and tau";
      ThermoSysPro.Properties.WaterSteam.Common.HelmholtzDerivs f "dimensionless Helmholtz funcion and dervatives wrt delta and tau";
      Integer error "error flag";
    algorithm
      region:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.region_dT(d, T, phase);
      if region == 1 then
        (p,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.pofdt125(d=d, T=T, reldd=iter.DELD, region=1);
        g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g1(p, T);
        pro:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToProps_dT(g);
      elseif region == 2 then
        (p,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.pofdt125(d=d, T=T, reldd=iter.DELD, region=2);
        g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g2(p, T);
        pro:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToProps_dT(g);

      elseif region == 3 then
        f:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3(d, T);
        pro:=ThermoSysPro.Properties.WaterSteam.Common.helmholtzToProps_dT(f);

      elseif region == 4 then
        pro:=ThermoSysPro.Properties.WaterSteam.BaseIF97.TwoPhase.waterR4_dT(d=d, T=T);

      elseif region == 5 then
        (p,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.pofdt125(d=d, T=T, reldd=iter.DELD, region=5);
        g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g5(p, T);
        pro:=ThermoSysPro.Properties.WaterSteam.Common.gibbsToProps_dT(g);
      end if;
    end water_dT;

    function water_pT "calculate property record for dynamic simulation properties using p and T as dynamic states"
      extends Modelica.Icons.Function;
      input Modelica.SIunits.Pressure p "pressure";
      input Modelica.SIunits.Temperature T "temperature";
      output Modelica.Media.Common.ThermoFluidSpecial.ThermoProperties_pT pro "property record for dynamic simulation";
    protected
      Modelica.SIunits.Density d "density";
      Integer region(min=1, max=5) "IF97 region";
      Modelica.Media.Common.GibbsDerivs g "dimensionless Gibbs funcion and dervatives wrt pi and tau";
      Modelica.Media.Common.HelmholtzDerivs f "dimensionless Helmholtz funcion and dervatives wrt delta and tau";
      Integer error "error flag";
    algorithm
      region:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Regions.region_pT(p, T);
      if region == 1 then
        g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g1(p, T);
        pro:=Modelica.Media.Common.ThermoFluidSpecial.gibbsToProps_pT(g);
      elseif region == 2 then
        g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g2(p, T);
        pro:=Modelica.Media.Common.ThermoFluidSpecial.gibbsToProps_pT(g);

      elseif region == 3 then
        (d,error):=ThermoSysPro.Properties.WaterSteam.BaseIF97.Inverses.dofpt3(p=p, T=T, delp=iter.DELP);
        f:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.f3(d, T);
        pro:=Modelica.Media.Common.ThermoFluidSpecial.helmholtzToProps_pT(f);

      elseif region == 5 then
        g:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.g5(p, T);
        pro:=Modelica.Media.Common.ThermoFluidSpecial.gibbsToProps_pT(g);
      end if;
    end water_pT;

  end ThermoFluidSpecial;

end IF97_Utilities;
