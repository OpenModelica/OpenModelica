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
//   parameter Real port.UNom(start = 400000.0);
//   final parameter Real port.UStart = UStart;
//   final parameter Real port.vStart.re = port.UStart / 1.732050807568877 * cos(port.UStart);
//   final parameter Real port.vStart.im = port.UStart / 1.732050807568877 * sin(port.UStart);
// end Inline4;
// endResult
