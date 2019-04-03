model DerivativeCodeGenerationBase
  model MixedSystem "based on ideal_diode.mo, but changed to force code generation of der.
    Creates a mixed+linear system that we can try code generation on."
    Real v0;
    Real v1,v2;
    Real u;
    Real i1,i2;
    Real s;
    Boolean off;
    Real i0;
    parameter Real R1=1,R2=2,C=0.1;
  equation
    v0 = 2*sin(7*time);

    off = s < 0;
    u = der(v1) - v2;
    u = if off then s else 0;
    der(i0) = if off then 0 else s;
    R1*der(i0)= v0-der(v1);

    i2=v2/R2;
    i1 = der(i0)-i2;
    der(v2) = i1;
  end MixedSystem;

  function one
    input Real r;
    output Real o;
  algorithm
    o := 1.0;
  end one;

  function arrcall
    input Real r;
    output Real[3] rs;
  algorithm
    rs := {1.0,2.0,3.0};
  end arrcall;

  Real x[3];
  Real y(start=2.0);
  Real dery = der(y);
  Real z(start=15.0);
equation
  der(x) = arrcall(time); // Tests cref = arrayCall()
  dery = one(dery);       // Always 1 but omc does not know that = free non-linear equation to test!
  der(z) = time;          // Tests simple equation
end DerivativeCodeGenerationBase;

model DerivativeCodeGeneration
  extends DerivativeCodeGenerationBase;
  MixedSystem mixed;
end DerivativeCodeGeneration;
