// name: CevalBinding10
// status: correct
//
//

pure function ext_fun
  input Real u1;
  output Real y;
  external "C";
end ext_fun;

model CevalBinding10
  parameter Real Q = ext_fun(0) annotation(Evaluate=true);
end CevalBinding10;

// Result:
// function ext_fun
//   input Real u1;
//   output Real y;
//
//   external "C" y = ext_fun(u1);
// end ext_fun;
//
// class CevalBinding10
//   final parameter Real Q = ext_fun(0.0);
// end CevalBinding10;
// endResult
