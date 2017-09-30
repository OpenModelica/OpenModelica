// name:     Implicit Integer to enumeration conversion
// keywords: type
// status:   correct
// cflags:   +intEnumConversion
//
// This tests that the +intEnumConversion flag works.
//

model IntegerToEnumeration
  type Enum = enumeration(one, two, three);
  Enum e(start = Enum.two, fixed = true);
  parameter Enum THREE = 3;
  Integer z(start = 0, fixed = true);
algorithm
  when time > 0.3 then
    if e == 2 then
      z := 1;
    else
      z := -1;
    end if;
  end when;
  when time > 0.4 then
    if 2 == e then
      z := 2;
    else
      z := -2;
    end if;
  end when;
  when time > 0.5 then
    e := 3;
  end when;
  when time > 0.6 then
    if e == THREE then
      z := 3;
    else
      z := -3;
    end if;
  end when;
end IntegerToEnumeration;

// Result:
// class IntegerToEnumeration
//   enumeration(one, two, three) e(start = IntegerToEnumeration.Enum.two, fixed = true);
//   parameter enumeration(one, two, three) THREE = IntegerToEnumeration.Enum.three;
//   Integer z(start = 0, fixed = true);
// algorithm
//   when time > 0.3 then
//     if e == IntegerToEnumeration.Enum$e.two then
//       z := 1;
//     else
//       z := -1;
//     end if;
//   end when;
//   when time > 0.4 then
//     if IntegerToEnumeration.Enum$e.two == e then
//       z := 2;
//     else
//       z := -2;
//     end if;
//   end when;
//   when time > 0.5 then
//     e := IntegerToEnumeration.Enum$e.three;
//   end when;
//   when time > 0.6 then
//     if e == THREE then
//       z := 3;
//     else
//       z := -3;
//     end if;
//   end when;
// end IntegerToEnumeration;
// Warning: Integer (3) to enumeration (.IntegerToEnumeration.Enum) conversion is not valid Modelica, please use enumeration constant (three) instead.
// Warning: Integer (2) to enumeration (.IntegerToEnumeration.Enum$e) conversion is not valid Modelica, please use enumeration constant (two) instead.
// Warning: Integer (3) to enumeration (.IntegerToEnumeration.Enum$e) conversion is not valid Modelica, please use enumeration constant (three) instead.
//
// endResult
