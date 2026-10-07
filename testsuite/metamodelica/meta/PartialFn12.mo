// name:     PartialFn12
// keywords: PartialFn
// status:  correct
//
// Using function pointers, partially evaluated functions
//

partial function PartFn
  input Real x;
  output Real y;
end PartFn;

function FullFn
  extends PartFn;
  input Real extraReal1;
  input Real extraReal2;
algorithm
  y := x * ((extraReal1 + extraReal2) / 2.0);
end FullFn;

function CallerFn
  input Real inReal;
  input PartFn inPartFn;
  output Real outReal;
algorithm
  outReal := inPartFn(inReal) * 2.0;
end CallerFn;

function TestFn
  input Real inReal;
  output Real outReal;
algorithm
  outReal := 0;
  for i in 1:10 loop
    outReal := outReal + CallerFn(inReal, function FullFn(extraReal1=1.5,extraReal2=7.5));
  end for;
end TestFn;

model PartialFn12
  Real x;
  Real y;
equation
  x = 2.0;
  y = TestFn(x);
end PartialFn12;

// class PartialFn12
// Real x;
// Real y;
// equation
//   x = 2.0;
//   y = TestFn(x);
// end PartialFn12;
