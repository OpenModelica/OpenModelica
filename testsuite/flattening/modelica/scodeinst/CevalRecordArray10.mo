// name: CevalRecordArray10
// keywords:
// status: correct
//

package Tilt
  constant Real Floor = 3.1415;
  constant Real Wall = 3.1415 / 2;
end Tilt;

record Generic
  parameter Real til;
  parameter Boolean isFloor = til > 2.74889125 and til < 3.53428875 annotation(Evaluate = true);
end Generic;

model RoomHeatMassBalance
  parameter Generic[3] surBou;
  parameter Boolean[3] isFloorSurBou = surBou.isFloor;
end RoomHeatMassBalance;

model CevalRecordArray10
  RoomHeatMassBalance roo(surBou(til = {Tilt.Wall, Tilt.Floor, Tilt.Wall}));
end CevalRecordArray10;

// Result:
// class CevalRecordArray10
//   final parameter Real roo.surBou[1].til = 1.57075;
//   final parameter Boolean roo.surBou[1].isFloor = false;
//   final parameter Real roo.surBou[2].til = 3.1415;
//   final parameter Boolean roo.surBou[2].isFloor = true;
//   final parameter Real roo.surBou[3].til = 1.57075;
//   final parameter Boolean roo.surBou[3].isFloor = false;
//   final parameter Boolean roo.isFloorSurBou[1] = false;
//   final parameter Boolean roo.isFloorSurBou[2] = true;
//   final parameter Boolean roo.isFloorSurBou[3] = false;
// end CevalRecordArray10;
// endResult
