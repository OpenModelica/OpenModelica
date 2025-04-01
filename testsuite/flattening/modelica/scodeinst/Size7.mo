// name: Size7
// keywords: size
// status: correct
//
// Tests the builtin size operator.
//

model Size7
  type listE = enumeration(one, two);
  parameter listE values[:] = {listE(i) for i in 1:size(Nlist, 1)};
  parameter Boolean Nlist[listE] = fill(true, size(Nlist, 1));
end Size7;

// Result:
// function Size7.listE "Automatically generated conversion operator for listE"
//   input Integer index;
//   output enumeration(one, two) value;
// algorithm
//   assert(index >= 1 and index <= 2, "Enumeration index '" + String(index, 0, true) + "' out of bounds in call to listE()");
//   value := {listE.one, listE.two}[index];
// end Size7.listE;
//
// class Size7
//   parameter enumeration(one, two) values[1] = listE.one;
//   parameter enumeration(one, two) values[2] = listE.two;
//   parameter Boolean Nlist[listE.one] = true;
//   parameter Boolean Nlist[listE.two] = true;
// end Size7;
// endResult
