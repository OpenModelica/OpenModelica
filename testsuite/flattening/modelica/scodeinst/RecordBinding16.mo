// name: RecordBinding16
// keywords:
// status: correct
//

record Borefield
  parameter Configuration conDat;
end Borefield;

record Configuration
  parameter Real x;
end Configuration;

model TwoUTube
  parameter Borefield borFieDat;
equation
  if borFieDat.conDat.x > 0 then
  end if;
end TwoUTube;

model RecordBinding16
  TwoUTube borHol[1](final borFieDat = zonDat);
  parameter Borefield zonDat[1](conDat = zonConDat);
  parameter Configuration zonConDat[1](each x = 1);
end RecordBinding16;

// Result:
// class RecordBinding16
//   final parameter Real borHol[1].borFieDat.conDat.x = 1.0;
//   parameter Real zonDat[1].conDat.x = 1.0;
//   parameter Real zonConDat[1].x = 1.0;
// end RecordBinding16;
// endResult
