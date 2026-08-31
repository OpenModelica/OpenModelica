// name: VectorizeBindings5
// keywords:
// status: correct
//

model Failing
  parameter Boolean initialEquation = true;
  Real pOut(start=0);
initial equation
  if initialEquation then
    pOut = 1;
  end if;
equation
  der(pOut) = sin(time);
end Failing;

model Module
  parameter Boolean initialEquation = true;
  Failing f(initialEquation = initialEquation);
end Module;

model VectorizeBindings5
  parameter Integer N = 2;
  parameter Boolean initialEquation[N] = fill(true,N);
  Module module[N](initialEquation = initialEquation);
  annotation(__OpenModelica_commandLineOptions="--newBackend");
end VectorizeBindings5;

// Result:
// class VectorizeBindings5
//   final parameter Integer N = 2;
//   final parameter Boolean[2] initialEquation = array(true for $f1 in 1:2);
//   final parameter Boolean[2] module.initialEquation = {true, true};
//   final parameter Boolean[2] module.f.initialEquation = {true, true};
//   Real[2] module.f.pOut(start = array(0.0 for $f1 in 1:2));
// initial equation
//   for $i1 in 1:2 loop
//     module[$i1].f.pOut = 1.0;
//   end for;
// equation
//   for $i0 in 1:2 loop
//     der(module[$i0].f.pOut) = sin(time);
//   end for;
// end VectorizeBindings5;
// endResult
