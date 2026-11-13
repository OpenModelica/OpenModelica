// name: ResizableStreamElements
// keywords: resizable stream inStream
// status: correct
// cflags: --newBackend --resizableArrays -i=ResizableStreamElements.Test
//
// inStream of the elements of an array stream variable in a resizable chain
// that is connected to the outside.
//

package ResizableStreamElements
  connector Port
    constant Integer nXi;
    Real p;
    flow Real m_flow;
    stream Real Xi[nXi];
  end Port;

  model Source
    Port port(nXi = 2);
    parameter Real X[2] = {0.25, 0.75};
  equation
    port.m_flow = -1;
    port.Xi = X;
  end Source;

  model Pipe
    constant Integer nX;
    Port inlet(nXi = nX), outlet(nXi = nX);
  equation
    inlet.m_flow + outlet.m_flow = 0;
    inlet.p - outlet.p = inlet.m_flow;
    outlet.Xi = inStream(inlet.Xi);
    inlet.Xi = inStream(outlet.Xi);
  end Pipe;

  model Sink
    Port port(nXi = 2);
    Real Xi[2] = inStream(port.Xi);
  equation
    port.p = 0;
    port.Xi = zeros(2);
  end Sink;

  model Wrapper
    Port port(nXi = 2);
    Source source;
    parameter Integer N = 3 annotation(__OpenModelica_resizable = true);
    Pipe pipes[N](each nX = 2);
  equation
    connect(source.port, pipes[1].inlet);
    connect(pipes[1:end - 1].outlet, pipes[2:end].inlet);
    connect(pipes[end].outlet, port);
  end Wrapper;

  model Test
    Wrapper source;
    Pipe pipe(nX = 2);
    Sink sink;
  equation
    connect(source.port, pipe.inlet);
    connect(pipe.outlet, sink.port);
  end Test;
end ResizableStreamElements;
// Result:
// class ResizableStreamElements.Test
//   constant Integer source.port.nXi = 2;
//   Real source.port.p;
//   Real source.port.m_flow;
//   Real[2] source.port.Xi;
//   constant Integer source.source.port.nXi = 2;
//   Real source.source.port.p;
//   Real source.source.port.m_flow;
//   Real[2] source.source.port.Xi;
//   parameter Real[2] source.source.X = {0.25, 0.75};
//   parameter Integer source.N = 3;
//   constant Integer[source.N] source.pipes.nX = {2, 2, 2};
//   constant Integer[source.N] source.pipes.inlet.nXi = {2, 2, 2};
//   Real[source.N] source.pipes.inlet.p;
//   Real[source.N] source.pipes.inlet.m_flow;
//   Real[source.N, 2] source.pipes.inlet.Xi;
//   constant Integer[source.N] source.pipes.outlet.nXi = {2, 2, 2};
//   Real[source.N] source.pipes.outlet.p;
//   Real[source.N] source.pipes.outlet.m_flow;
//   Real[source.N, 2] source.pipes.outlet.Xi;
//   constant Integer pipe.nX = 2;
//   constant Integer pipe.inlet.nXi = 2;
//   Real pipe.inlet.p;
//   Real pipe.inlet.m_flow;
//   Real[2] pipe.inlet.Xi;
//   constant Integer pipe.outlet.nXi = 2;
//   Real pipe.outlet.p;
//   Real pipe.outlet.m_flow;
//   Real[2] pipe.outlet.Xi;
//   constant Integer sink.port.nXi = 2;
//   Real sink.port.p;
//   Real sink.port.m_flow;
//   Real[2] sink.port.Xi;
//   Real[2] sink.Xi = {pipe.outlet.Xi[1], pipe.outlet.Xi[2]};
// equation
//   source.source.port.m_flow = -1.0;
//   source.source.port.Xi = source.source.X;
//   for $i3 in 1:source.N loop
//     source.pipes[$i3].inlet.m_flow + source.pipes[$i3].outlet.m_flow = 0.0;
//   end for;
//   for $i2 in 1:source.N loop
//     source.pipes[$i2].inlet.p - source.pipes[$i2].outlet.p = source.pipes[$i2].inlet.m_flow;
//   end for;
//   for $i1 in 1:source.N loop
//     source.pipes[$i1].outlet.Xi = {if $i1 == 1 then source.source.port.Xi[1] else source.pipes[-1 + $i1].outlet.Xi[1], if $i1 == 1 then source.source.port.Xi[2] else source.pipes[-1 + $i1].outlet.Xi[2]};
//   end for;
//   for $i0 in 1:source.N loop
//     source.pipes[$i0].inlet.Xi = {if 1 <= $i0 and $i0 <= source.N - 1 then source.pipes[1 + $i0].inlet.Xi[1] else pipe.inlet.Xi[1], if 1 <= $i0 and $i0 <= source.N - 1 then source.pipes[1 + $i0].inlet.Xi[2] else pipe.inlet.Xi[2]};
//   end for;
//   pipe.inlet.m_flow + pipe.outlet.m_flow = 0.0;
//   pipe.inlet.p - pipe.outlet.p = pipe.inlet.m_flow;
//   pipe.outlet.Xi = {source.port.Xi[1], source.port.Xi[2]};
//   pipe.inlet.Xi = {sink.port.Xi[1], sink.port.Xi[2]};
//   sink.port.p = 0.0;
//   sink.port.Xi = array(0.0 for $f1 in 1:2);
//   source.pipes[1].inlet.p = source.source.port.p;
//   source.source.port.m_flow + source.pipes[1].inlet.m_flow = 0.0;
//   for $i4 in 1:source.N - 1 loop
//     source.pipes[$i4].outlet.p = source.pipes[$i4 + 1].inlet.p;
//   end for;
//   for $i4 in 1:source.N - 1 loop
//     source.pipes[$i4 + 1].inlet.m_flow + source.pipes[$i4].outlet.m_flow = 0.0;
//   end for;
//   source.port.Xi = source.pipes[source.N].outlet.Xi;
//   source.port.p = source.pipes[source.N].outlet.p;
//   source.pipes[source.N].outlet.m_flow - source.port.m_flow = 0.0;
//   source.port.p = pipe.inlet.p;
//   pipe.inlet.m_flow + source.port.m_flow = 0.0;
//   pipe.outlet.p = sink.port.p;
//   sink.port.m_flow + pipe.outlet.m_flow = 0.0;
// end ResizableStreamElements.Test;
// endResult
