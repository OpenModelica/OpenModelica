// status: correct
// cflags: -g=MetaModelica -d=gen

model TestContinue
  function f
    input Real arr[:];
    output Real r = 0;
  algorithm
    for i in arr loop
      if i<0 then
        continue;
      end if;
      r := r + i;
    end for;
  end f;

  constant Real r1 = f(-30:30), r2 = f(0:30); // Should give the same result
end TestContinue;

// Result:
// function TestContinue.f
//   input Real[:] arr;
//   output Real r = 0.0;
// algorithm
//   for i in arr loop
//     if i < 0.0 then
//       continue;
//     end if;
//     r := r + i;
//   end for;
// end TestContinue.f;
//
// class TestContinue
//   constant Real r1 = 465.0;
//   constant Real r2 = 465.0;
// end TestContinue;
// endResult
