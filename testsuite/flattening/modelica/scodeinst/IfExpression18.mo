// name: IfExpression18
// keywords:
// status: correct
//

model IfExpression18
  record CellData
    parameter Boolean useLinear = false;
    parameter Real table[:, 2] = [0, 0; 1, 1];
    final parameter Real internal[:, 2] = if useLinear then [0, 0; 1, 1] else table;
  end CellData;

  record ExampleData
    extends CellData(table = [0, 0; 0.1, 0.1; 0.2, 0.2; 0.3, 0.3; 1, 1]);
  end ExampleData;

  parameter CellData inline = ExampleData(useLinear = false);
end IfExpression18;

// Result:
// class IfExpression18
//   parameter Boolean inline.useLinear = false;
//   parameter Real inline.table[1,1] = 0.0;
//   parameter Real inline.table[1,2] = 0.0;
//   parameter Real inline.table[2,1] = 0.1;
//   parameter Real inline.table[2,2] = 0.1;
//   parameter Real inline.table[3,1] = 0.2;
//   parameter Real inline.table[3,2] = 0.2;
//   parameter Real inline.table[4,1] = 0.3;
//   parameter Real inline.table[4,2] = 0.3;
//   parameter Real inline.table[5,1] = 1.0;
//   parameter Real inline.table[5,2] = 1.0;
//   final parameter Real inline.internal[1,1] = 0.0;
//   final parameter Real inline.internal[1,2] = 0.0;
//   final parameter Real inline.internal[2,1] = 0.1;
//   final parameter Real inline.internal[2,2] = 0.1;
//   final parameter Real inline.internal[3,1] = 0.2;
//   final parameter Real inline.internal[3,2] = 0.2;
//   final parameter Real inline.internal[4,1] = 0.3;
//   final parameter Real inline.internal[4,2] = 0.3;
//   final parameter Real inline.internal[5,1] = 1.0;
//   final parameter Real inline.internal[5,2] = 1.0;
// end IfExpression18;
// endResult
