// name: Inline4
// keywords:
// status: correct
// cflags: -d=newInst
//

operator record Complex
  replaceable Real re;
  replaceable Real im;

  encapsulated operator 'constructor'
    function fromReal
      import Complex;
      input Real re;
      input Real im = 0;
      output Complex result(re = re, im = im);
    algorithm
      annotation(Inline = true);
    end fromReal;
  end 'constructor';
end Complex;

function fromPolar
  input Real len;
  input Real phi;
  output Complex c;
algorithm
  c := Complex(len*cos(phi), len*sin(phi));
  annotation(Inline = true);
end fromPolar;

model PortAC
  parameter Real UNom(start = 400e3);
  parameter Real UStart = UNom;
  final parameter Complex vStart = fromPolar(UStart/sqrt(3), UStart);
end PortAC;

model Inline4
  parameter Real UStart(fixed = false);
  PortAC port(final UStart = UStart);
end Inline4;

// Result:
// class Inline4
//   parameter Real UStart(fixed = false);
//   parameter Real port.UNom(start = 4e5);
//   final parameter Real port.UStart = UStart;
//   final parameter Real port.vStart.re = port.UStart / 1.7320508075688772 * cos(port.UStart);
//   final parameter Real port.vStart.im = port.UStart / 1.7320508075688772 * sin(port.UStart);
// end Inline4;
// [flattening/modelica/scodeinst/Inline4.mo:33:3-33:37:writable] Warning: Parameter port.UNom has no binding, and is fixed during initialization (fixed=true), using available start value (start=4e5) as default value.
//
// endResult
