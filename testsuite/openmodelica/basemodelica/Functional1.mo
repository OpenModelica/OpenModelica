// name: Functional1
// status: correct

partial function PF
  input Real x;
  output Real y;
end PF;

function f
  input Real x;
  input PF pf;
  output Real y;
algorithm
  y := pf(x);
end f;

function f2
  input Real x;
  output Real y = 2*x;
end f2;

model Functional1
  Real x = f(time, f2);
  annotation(__OpenModelica_commandLineOptions="-d=newInst -f");
end Functional1;

// Result:
// //! base 0.1.0
// package 'Functional1'
//   function 'f'
//     input Real 'x';
//     input 'PF' 'pf';
//     output Real 'y';
//   algorithm
//     'y' := 'pf'('x');
//   end 'f';
//
//   function 'f2'
//     input Real 'x';
//     output Real 'y' = 2.0 * 'x';
//   end 'f2';
//
//   partial function 'PF'
//     input Real 'x';
//     output Real 'y';
//   end 'PF';
//
//   model 'Functional1'
//     Real 'x' = 'f'(time, 'f2');
//   end 'Functional1';
// end 'Functional1';
// endResult
