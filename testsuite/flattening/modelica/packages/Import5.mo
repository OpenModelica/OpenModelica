// name:     Import5
// keywords: import
// status:   correct
//
// Import of constants in packages.

package A
   constant Real PI=3.14;
   constant Real e=2.7;
   package B
     constant Real c=3.0e8;
   end B;
end A;

model Import5
  import A.PI;
  import my_e=A.e;
  import A.B.*;
  Real x=3*PI;
  Real x2=my_e;
  Real x3=c;
end Import5;

// Result:
// class Import5
//   Real x = 9.42;
//   Real x2 = 2.7;
//   Real x3 = 300000000.0;
// end Import5;
// endResult
