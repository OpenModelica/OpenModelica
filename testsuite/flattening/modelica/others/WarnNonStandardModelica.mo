package WarnNonStandardModelica
  model RealEquality
    Real x = time;
    Boolean b = x == 0.5;
  end RealEquality;

  model ReinitInAlgorithm
    Real x(start = 1, fixed = true);
  equation
    der(x) = -x;
  algorithm
    when x < 0.5 then
      reinit(x, 1);
    end when;
  end ReinitInAlgorithm;

  package P
  protected
    constant Real c = 2;
  end P;

  model ProtectedAccess
    Real x = P.c;
  end ProtectedAccess;

  model R
    parameter Real x = 1;
  end R;

  model TopLevelOuter
    outer R o;
  end TopLevelOuter;

  connector C
    Real e;
    Real f;
  end C;

  model UnbalancedConnector
    C c;
  equation
    c.e = 1;
    c.f = 2;
  end UnbalancedConnector;

  model ImplicitStart
    parameter Real p;
  end ImplicitStart;

  model ConditionalContext
    parameter Boolean b = false;
    Real y if b;
    Real z = y;
  end ConditionalContext;

  type E = enumeration(a, b);

  model EnumerationAsInteger
    Integer i = E.b;
  end EnumerationAsInteger;

  model IntegerAsEnumeration
    E e = 1;
  end IntegerAsEnumeration;

  function f0
    input Real x;
    output Real y;
    external "C" y = sin(x);
  end f0;

  function f1
    extends f0;
    external "C" y = cos(x);
  end f1;

  model MultipleExternal
    Real y = f1(time);
  end MultipleExternal;
end WarnNonStandardModelica;
