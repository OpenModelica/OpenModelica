within ;
package Tearing13
  constant Real dp_small = 1e3;

  model FluidExample
    parameter Real pa = 2e5;
    parameter Real ha = 3.2e6;
    parameter Real hb = 3.0e6;
    parameter Real k = 1e-4;
    Real pb;
    Real p(start = 1.5e5);
    Real rho1;
    Real rho2;
    Real w;
  equation
    pb = 2e5+sin(time)*1e5;
    rho1=f(pa, p, ha, hb);
    rho2=f(p, pb, ha, hb);
    w = g(pa-p, rho1, k);
    w = g(p-pb, rho2, k);
  end FluidExample;

  function f
    input Real p1;
    input Real p2;
    input Real h1;
    input Real h2;
    output Real rho;
    package IF97=Modelica.Media.Water.StandardWater;
  protected
    IF97.ThermodynamicState state1;
    IF97.ThermodynamicState state2;
    IF97.ThermodynamicState state;
  algorithm
    state1 := IF97.setState_ph(p1,h1);
    state2 := IF97.setState_ph(p2,h2);
    state := IF97.setSmoothState(p1-p2, state1, state2, dp_small);
    rho := IF97.density(state);
  end f;

  function g
    input Real dp;
    input Real rho;
    input Real k;
    output Real w;
  algorithm
    w :=k*sqrt(rho)*dp/(dp^2+dp_small^2)^0.25;
  end g;

end Tearing13;
