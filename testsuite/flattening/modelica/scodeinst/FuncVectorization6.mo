// name: FuncVectorization6
// keywords: vectorization function
// status: correct
//
//

model FuncVectorization6
  function f
    input Real[:, :] x;
    output Real s = 0.0;
  algorithm
    for i in 1:size(x, 1) loop
      s := s + min(abs(x[i, :]));
    end for;
  end f;

  Real x;
equation
  x = f({{time, 2, 3}, {4, 5, 6}});
  x = f({{1, 2, 3}, {4, 5, 6}});
end FuncVectorization6;


// Result:
// function FuncVectorization6.f
//   input Real[:, :] x;
//   output Real s = 0.0;
// algorithm
//   for i in 1:size(x, 1) loop
//     s := s + min(abs(x[i,$i0]) for $i0 in 1:size(x[i,:], 1));
//   end for;
// end FuncVectorization6.f;
//
// class FuncVectorization6
//   Real x;
// equation
//   x = FuncVectorization6.f({{time, 2.0, 3.0}, {4.0, 5.0, 6.0}});
//   x = 5.0;
// end FuncVectorization6;
// endResult
