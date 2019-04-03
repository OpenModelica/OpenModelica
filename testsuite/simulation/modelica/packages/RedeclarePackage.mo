package BasePackage
  replaceable partial function func
    input Real value;
    output Real result;
  end func;
end BasePackage;

package ConcretePackage
  extends BasePackage;
  redeclare function extends func
  algorithm
    result := value;
  end func;
end ConcretePackage;

model TestModel
  replaceable package Function = BasePackage;        // Does not work
  //replaceable package Function = ConcretePackage;  // This way it works

  parameter Real value = 1;
  parameter Real result1(fixed = false) = Function.func(value);
  parameter Real result2 = Function.func(1);
  Real x;

equation
  x = Function.func(time + 1);
end TestModel;

model Test
  TestModel mod(redeclare package Function = ConcretePackage);
equation
end Test;