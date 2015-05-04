//############################################################################################################

model Element
  Profile profile;
  Real angle;
equation
  angle = funct(alpha=profile.alpha);
end Element;

//############################################################################################################

function funct
  input Real[:] alpha;
  output Real cOut;
algorithm
  cOut:= alpha[5];
end funct;

//############################################################################################################

record Profile
  //parameter Real alpha[25]={1.0,2.0,3.0,4.0,5.0,6.0,7.0,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0,16.0,17.0,18.0,19.0,20.0,21,22,23,24,25};
  parameter Real alpha[6]={1.0,2.0,3.0,4.0,5.0,6.0};
  //parameter Real alpha[19]={1.0,2.0,3.0,4.0,5.0,6.0,7.0,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0,16.0,17.0,18.0,19.0};
end Profile;

model ModelFrameTest
// --- MAIN CLASS ---

  Element element[2];
end ModelFrameTest;

