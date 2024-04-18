// name: VectorizeBindings3
// keywords:
// status: correct
// cflags: -d=newInst --newBackend
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

  encapsulated operator '*'
    function multiply
      import Complex;
      input Complex c1;
      input Complex c2;
      output Complex c3;
    algorithm
      c3 := Complex(c1.re*c2.re - c1.im*c2.im, c1.re*c2.im + c1.im*c2.re);
      annotation(Inline = true);
    end multiply;

    function scalarProduct
      import Complex;
      input Complex[:] c1;
      input Complex[size(c1, 1)] c2;
      output Complex c3;
    algorithm
      c3 := Complex(0);
      for i in 1:size(c1, 1) loop
        c3 := c3 + c1[i]*c2[i];
      end for;
      annotation(Inline = true);
    end scalarProduct;
  end '*';

  encapsulated operator function '+'
    import Complex;
    input Complex c1;
    input Complex c2;
    output Complex c3;
  algorithm
    c3 := Complex(c1.re + c2.re, c1.im + c2.im);
    annotation(Inline = true);
  end '+';
end Complex;

package ComplexMath
  function exp
    input Complex c1;
    output Complex c2;
  algorithm
    c2 := Complex(.exp(c1.re)*.cos(c1.im), .exp(c1.re)*.sin(c1.im));
  end exp;
end ComplexMath;

function symmetricOrientation
  input Integer m;
  output Real[m] orientation;
algorithm
  orientation := {(k - 1)*2*3/m for k in 1:m};
end symmetricOrientation;

model SinglePhaseElectroMagneticConverter
  parameter Real effectiveTurns annotation(Evaluate = true);
  parameter Real orientation annotation(Evaluate = true);
  final parameter Complex N = effectiveTurns*ComplexMath.exp(Complex(0, orientation));
end SinglePhaseElectroMagneticConverter;

model PolyphaseElectroMagneticConverter
  parameter Integer m = 3 annotation(Evaluate = true);
  parameter Real[m] effectiveTurns;
  parameter Real[m] orientation;
  SinglePhaseElectroMagneticConverter[m] singlePhaseElectroMagneticConverter(final effectiveTurns = effectiveTurns, final orientation = orientation);
end PolyphaseElectroMagneticConverter;

model SymmetricPolyphaseWinding
  parameter Integer m = 3 annotation(Evaluate = true);
  parameter Real effectiveTurns = 1;
  PolyphaseElectroMagneticConverter electroMagneticConverter(final m = m, final effectiveTurns = fill(effectiveTurns, m), final orientation = symmetricOrientation(m));
end SymmetricPolyphaseWinding;

model IM_SquirrelCage
  parameter Integer m(min = 3) = 3;
  parameter Real effectiveStatorTurns = 1;
  SymmetricPolyphaseWinding stator(final m = m, final effectiveTurns = effectiveStatorTurns);
end IM_SquirrelCage;

model VectorizeBindings3
  constant Integer m = 3;
  parameter Integer effectiveStatorTurns = 1;
  IM_SquirrelCage aimc(effectiveStatorTurns = effectiveStatorTurns);
end VectorizeBindings3;

// Result:
// function Complex "Automatically generated record constructor for Complex"
//   input Real re;
//   input Real im;
//   output Complex res;
// end Complex;
//
// function Complex.'*'.multiply
//   input Complex c1;
//   input Complex c2;
//   output Complex c3;
// algorithm
//   c3 := Complex.'constructor'.fromReal(c1.re * c2.re - c1.im * c2.im, c1.re * c2.im + c1.im * c2.re);
// end Complex.'*'.multiply;
//
// function Complex.'constructor'.fromReal
//   input Real re;
//   input Real im = 0.0;
//   output Complex result;
// algorithm
// end Complex.'constructor'.fromReal;
//
// function ComplexMath.exp
//   input Complex c1;
//   output Complex c2;
// algorithm
//   c2 := Complex.'constructor'.fromReal(exp(c1.re) * cos(c1.im), exp(c1.re) * sin(c1.im));
// end ComplexMath.exp;
//
// class VectorizeBindings3
//   constant Integer m = 3;
//   parameter Integer effectiveStatorTurns = 1;
//   final parameter Integer aimc.m(min = 3) = 3;
//   parameter Real aimc.effectiveStatorTurns = /*Real*/(effectiveStatorTurns);
//   final parameter Integer aimc.stator.m = 3;
//   final parameter Real aimc.stator.effectiveTurns = aimc.effectiveStatorTurns;
//   final parameter Integer aimc.stator.electroMagneticConverter.m = 3;
//   final parameter Real[3] aimc.stator.electroMagneticConverter.effectiveTurns = array(aimc.stator.effectiveTurns for $i1 in 1:3);
//   final parameter Real[3] aimc.stator.electroMagneticConverter.orientation = {0.0, 2.0, 4.0};
//   parameter Complex[3] aimc.stator.electroMagneticConverter.singlePhaseElectroMagneticConverter.N = array(Complex.'*'.multiply(Complex.'constructor'.fromReal(aimc.stator.electroMagneticConverter.singlePhaseElectroMagneticConverter[$singlePhaseElectroMagneticConverter1].effectiveTurns, 0.0), ComplexMath.exp(Complex.'constructor'.fromReal(0.0, {0.0, 2.0, 4.0}[$singlePhaseElectroMagneticConverter1]))) for $singlePhaseElectroMagneticConverter1 in 1:3);
//   final parameter Real[3] aimc.stator.electroMagneticConverter.singlePhaseElectroMagneticConverter.orientation = {0.0, 2.0, 4.0};
//   final parameter Real[3] aimc.stator.electroMagneticConverter.singlePhaseElectroMagneticConverter.effectiveTurns = array(aimc.stator.electroMagneticConverter.effectiveTurns[$singlePhaseElectroMagneticConverter1] for $singlePhaseElectroMagneticConverter1 in 1:3);
// end VectorizeBindings3;
// endResult
