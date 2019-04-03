// name: TupleOperation5
// keywords:
// status: correct
// cflags: -d=newInst
//

function f
  input Real t;
  output Real n1 = 2;
  output Real n2 = 3;
end f;

model TupleOperation5
  Real x[1, 3];
equation
  if time > 1 then
    x = [1, 0, 1];
  else
    x = [f(time), f(time), f(time)];
  end if;
end TupleOperation5;

// Result:
// function f
//   input Real t;
//   output Real n1 = 2.0;
//   output Real n2 = 3.0;
// end f;
//
// class TupleOperation5
//   Real x[1,1];
//   Real x[1,2];
//   Real x[1,3];
// equation
//   if time > 1.0 then
//     x[1,1] = 1.0;
//     x[1,2] = 0.0;
//     x[1,3] = 1.0;
//   else
//     x[1,1] = f(time)[1];
//     x[1,2] = f(time)[1];
//     x[1,3] = f(time)[1];
//   end if;
// end TupleOperation5;
// endResult
