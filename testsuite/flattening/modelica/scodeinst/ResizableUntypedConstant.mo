// name: ResizableUntypedConstant
// keywords: resizable
// status: correct
// cflags: --newBackend --resizableArrays
//
// An integer constant whose binding is only typed with the function using it.
//

package P
  constant Integer m = 2;
  function f
    input Real x;
    input Integer k = m;
    output Real y = x * k;
  end f;
end P;

model ResizableUntypedConstant
  parameter Integer N = 2 annotation(__OpenModelica_resizable = true);
  Real x[N] = fill(P.f(time), N);
end ResizableUntypedConstant;
// Result:
// function P.f
//   input Real x;
//   input Integer k = 2;
//   output Real y = x * /*Real*/(k);
// end P.f;
//
// class ResizableUntypedConstant
//   parameter Integer N = 2;
//   Real[N] x = array(P.f(time, 2) for $f1 in 1:N);
// end ResizableUntypedConstant;
// endResult
