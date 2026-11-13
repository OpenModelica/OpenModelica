// name: RedeclareMod13
// keywords:
// status: correct
//

record CellData
  parameter Real table[:, 2] = [0, 0; 1, 1];
end CellData;

record BaseStackData
  replaceable parameter CellData cellDataOriginal;
end BaseStackData;

record StackData
  extends BaseStackData(redeclare CellData cellDataOriginal);
end StackData;

model Stack
  replaceable parameter BaseStackData stackData;
end Stack;

model RedeclareMod13
  parameter CellData cellData(table = [0, 0.5; 0.5, 0.8; 1, 1]);
  parameter StackData stackData(cellDataOriginal = cellData);
  StackData stackData2 = stackData;
end RedeclareMod13;

// Result:
// class RedeclareMod13
//   parameter Real cellData.table[1,1] = 0.0;
//   parameter Real cellData.table[1,2] = 0.5;
//   parameter Real cellData.table[2,1] = 0.5;
//   parameter Real cellData.table[2,2] = 0.8;
//   parameter Real cellData.table[3,1] = 1.0;
//   parameter Real cellData.table[3,2] = 1.0;
//   parameter Real stackData.cellDataOriginal.table[1,1] = cellData.table[1,1];
//   parameter Real stackData.cellDataOriginal.table[1,2] = cellData.table[1,2];
//   parameter Real stackData.cellDataOriginal.table[2,1] = cellData.table[2,1];
//   parameter Real stackData.cellDataOriginal.table[2,2] = cellData.table[2,2];
//   parameter Real stackData.cellDataOriginal.table[3,1] = cellData.table[3,1];
//   parameter Real stackData.cellDataOriginal.table[3,2] = cellData.table[3,2];
//   parameter Real stackData2.cellDataOriginal.table[1,1] = stackData.cellDataOriginal.table[1,1];
//   parameter Real stackData2.cellDataOriginal.table[1,2] = stackData.cellDataOriginal.table[1,2];
//   parameter Real stackData2.cellDataOriginal.table[2,1] = stackData.cellDataOriginal.table[2,1];
//   parameter Real stackData2.cellDataOriginal.table[2,2] = stackData.cellDataOriginal.table[2,2];
//   parameter Real stackData2.cellDataOriginal.table[3,1] = stackData.cellDataOriginal.table[3,1];
//   parameter Real stackData2.cellDataOriginal.table[3,2] = stackData.cellDataOriginal.table[3,2];
// end RedeclareMod13;
// endResult
