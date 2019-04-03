// name: BlockResult
// keywords: block output
// status: correct
//
// Tests that block outputs are handled correctly.
//

block foo
  input Integer foo1[:];
  input Integer foo2[:];
  output Real result[size(foo1,1)];
algorithm
  for i in 1:size(foo1,1) loop
    if foo1[i] >= foo2[i] then
      result[i] := 7.0;
    else
      result[i] := 8.0;
    end if;
  end for;
end foo;

model BlockResult
  parameter Integer mod1[:]={1,1,1};
  parameter Integer mod2[:]={2,0,0};
  Real result[size(mod1,1)];
  foo f1(foo1=mod1, foo2=mod2);
equation
  result = f1.result;
end BlockResult;

// Result:
// class BlockResult
//   parameter Integer mod1[1] = 1;
//   parameter Integer mod1[2] = 1;
//   parameter Integer mod1[3] = 1;
//   parameter Integer mod2[1] = 2;
//   parameter Integer mod2[2] = 0;
//   parameter Integer mod2[3] = 0;
//   Real result[1];
//   Real result[2];
//   Real result[3];
//   Integer f1.foo1[1];
//   Integer f1.foo1[2];
//   Integer f1.foo1[3];
//   Integer f1.foo2[1];
//   Integer f1.foo2[2];
//   Integer f1.foo2[3];
//   Real f1.result[1];
//   Real f1.result[2];
//   Real f1.result[3];
// equation
//   f1.foo1 = {mod1[1], mod1[2], mod1[3]};
//   f1.foo2 = {mod2[1], mod2[2], mod2[3]};
//   result[1] = f1.result[1];
//   result[2] = f1.result[2];
//   result[3] = f1.result[3];
// algorithm
//   for i in 1:3 loop
//     if f1.foo1[i] >= f1.foo2[i] then
//       f1.result[i] := 7.0;
//     else
//       f1.result[i] := 8.0;
//     end if;
//   end for;
// end BlockResult;
// endResult
