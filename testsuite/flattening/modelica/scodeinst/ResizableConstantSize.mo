// name: ResizableConstantSize
// keywords: resizable connect
// status: correct
// cflags: --newBackend --resizableArrays -i=ResizableConstantSize.Test
//
// A connector size bound to a constant, connected into a resizable array.
//

package ResizableConstantSize
  connector RealInput = input Real;
  connector RealOutput = output Real;

  partial block MO
    parameter Integer nout(min = 1) = 1;
    RealOutput y[nout];
  end MO;

  block Source
    extends MO(final nout = nX);
    constant Integer nX;
  equation
    y = fill(time, nout);
  end Source;

  block Gain
    parameter Integer n = 2;
    RealInput u[n];
    RealOutput y[n];
  equation
    y = 2 * u;
  end Gain;

  model Test
    parameter Integer N = 3 annotation(__OpenModelica_resizable = true);
    Source s(nX = 2);
    Gain g[N];
  equation
    connect(s.y, g[1].u);
    connect(g[1:end - 1].y, g[2:end].u);
  end Test;
end ResizableConstantSize;
// Result:
// class ResizableConstantSize.Test
//   parameter Integer N = 3;
//   final parameter Integer s.nout(min = 1) = 2;
//   Real[s.nout] s.y;
//   constant Integer s.nX = 2;
//   parameter Integer[N] g.n = array(2 for $f1 in 1:N);
//   Real[N, 2] g.u;
//   Real[N, 2] g.y;
// equation
//   s.y = array(time for $f1 in 1:s.nout);
//   for $i0 in 1:N loop
//     g[$i0].y = g[$i0].u * 2.0;
//   end for;
//   for $i1 in 1:2 loop
//     g[1].u[$i1] = s.y[$i1];
//   end for;
//   for $i2 in 1:N - 1 loop
//     for $i3 in 1:2 loop
//       g[$i2].y[$i3] = g[$i2 + 1].u[$i3];
//     end for;
//   end for;
// end ResizableConstantSize.Test;
// endResult
