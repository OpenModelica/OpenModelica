within ;
model RightHeartStarling "right heart"
   parameter Real K(  final quantity="TimeCoefficient", final unit="1/min") = 1
    "time adaptation coeficient of average ventricle blood volume";
   parameter Real HR=70 "heart rate";
   parameter Real PericardiumPressure =     -3;
   parameter Real stiffnes=1;
   parameter Real contractility =           1;
   parameter Real Po=12.7 "artery pressure";
   Real Pi "atrium pressure";
   Real bloodFlow;
   Real EDV "end diastolic volume";
   Real ESV "end systolic volume";
   Real inflow;
   Real outflow;
   Real delta;
   Real ventricleSteadyStateVolume;
   Real volume(start=95.7) "average ventricle volume";
equation
   Pi=time;
   bloodFlow = HR * (EDV - ESV);
   EDV = ((Pi-PericardiumPressure)/(stiffnes*0.00026))^(1/2);
   ESV = ((Po+9-PericardiumPressure)/(contractility*3.53))^(2);

  ventricleSteadyStateVolume = (EDV+ESV)/2;
  delta = (ventricleSteadyStateVolume - volume)*K;
  der(volume) = delta/60;

  inflow + outflow = delta;
  inflow = if (delta<0) then bloodFlow else bloodFlow+delta;
  annotation (uses(Modelica(version="3.1")));
end RightHeartStarling;
