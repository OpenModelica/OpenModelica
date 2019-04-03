type Posture = enumeration(
    Lying,
    Sitting,
    Standing,
    Tilting);

model TorsoModel
   parameter Real arrayByEnum[Posture];
   parameter Real arrayByInt[5];
   Posture enmIndex;
   Integer intIndex;
   Real resultE;
   Real resultI;
equation
   resultE = arrayByEnum[enmIndex];
   resultI = arrayByInt[intIndex];
end TorsoModel;

model TestPosture
  TorsoModel tmodel;
initial equation
  tmodel.enmIndex = Posture.Lying;
  tmodel.intIndex = 1;
equation
  when time >= 1.0 then
    tmodel.enmIndex = Posture.Sitting;
    tmodel.intIndex = 2;
  end when;
end TestPosture;