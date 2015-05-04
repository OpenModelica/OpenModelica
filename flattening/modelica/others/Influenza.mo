// name:     Influenza
// keywords: connect, equation, modification
// cflags:   +std=2.x
// status:   correct

connector Port = Real;

model Population
  input Port in_1;
  input Port in_2;
  output Port out_1;
  output Real p(start=10);
equation
  der(p)=in_1 - in_2;
  out_1 = p;
end Population;


model Division
  input Port in_1;
  input Port in_2;
  output Port out_1;
  parameter Real c=1.00;
equation
  out_1 = c*in_1/in_2;
end Division;


model Constants
  output Port out_1;
  parameter Real c=1.0;
equation
  out_1 = c;
end Constants;


model Product1
  input Port in_1;
  output Port out_1;
  parameter Real c=0.10;
equation
  out_1=c*in_1;
end Product1;


model Product2
  input Port in_1;
  input Port in_2;
  output Port out_1;
  parameter Real c=1.00;
equation
  out_1=c*in_1*in_2;
end Product2;


model Sum
  input Port in_1;
  input Port in_2;
  output Port out_1;
equation
  out_1 = in_1 + in_2;
end Sum;


model Minimum
  input Port in_1;
  input Port in_2;
  output Port out_1;
equation
  out_1 = if (in_1 < in_2) then in_1 else in_2;
end Minimum;


model Influenza
  input Real Introduction(start = 77);

  Population Immune_Popul(p(start = 10));
  Population Non_Infected_Popul(p(start = 100));
  Population Infected_Popul(p(start = 50));
  Population Sick_Popul(p(start = 0));

  Division Incubation;
  Division Cure_Rate;
  Division Activation;
  Division Perc_Infected;

  Constants Time_to_Breakdown;
  Constants Sickness_Duration;
  Constants Contraction_Rate;
  Constants Immune_Period;

  Sum Contagious_Popul;
  Sum Non_Contagious_Popul;
  Sum Total_Popul;
  Sum Temp3;

  Product1 Contacts_Wk;

  Product2 Temp1;
  Product2 Temp2;

  Minimum Infection_Rate;

equation
  connect(Incubation.in_1,Infected_Popul.out_1);
  connect(Incubation.in_2,Time_to_Breakdown.out_1);
  connect(Infected_Popul.in_2,Incubation.out_1);
  connect(Sick_Popul.in_1,Incubation.out_1);
  connect(Cure_Rate.in_1,Sick_Popul.out_1);
  connect(Cure_Rate.in_2,Sickness_Duration.out_1);
  connect(Immune_Popul.in_1,Cure_Rate.out_1);
  connect(Sick_Popul.in_2,Cure_Rate.out_1);
  connect(Activation.in_1,Immune_Popul.out_1);
  connect(Activation.in_2,Immune_Period.out_1);
  connect(Immune_Popul.in_1,Activation.out_1);
  connect(Non_Infected_Popul.in_1,Activation.out_1);
  connect(Temp2.in_1,Contraction_Rate.out_1);
  connect(Contagious_Popul.in_1,Infected_Popul.out_1);
  connect(Contagious_Popul.in_2,Sick_Popul.out_1);
  connect(Perc_Infected.in_1,Contagious_Popul.out_1);
  connect(Total_Popul.in_1,Contagious_Popul.out_1);
  connect(Non_Contagious_Popul.in_1,Non_Infected_Popul.out_1);
  connect(Non_Contagious_Popul.in_2,Immune_Popul.out_1);
  connect(Total_Popul.in_2,Non_Contagious_Popul.out_1);
  connect(Perc_Infected.in_2,Total_Popul.out_1);
  connect(Temp1.in_1,Perc_Infected.out_1);
  connect(Contacts_Wk.in_1,Non_Infected_Popul.out_1);
  connect(Temp1.in_2,Contacts_Wk.out_1);
  connect(Temp2.in_2,Temp1.out_1);
  connect(Temp3.in_1,Temp2.out_1);
  Temp3.in_2 = Introduction;
  connect(Infection_Rate.in_1,Temp3.out_1);
  connect(Infection_Rate.in_2,Non_Infected_Popul.out_1);
  connect(Infected_Popul.in_1,Infection_Rate.out_1);
  connect(Non_Infected_Popul.in_2,Infection_Rate.out_1);

end Influenza;


// Result:
// class Influenza
//   input Real Introduction(start = 77.0);
//   Real Immune_Popul.in_1;
//   Real Immune_Popul.in_2;
//   Real Immune_Popul.out_1;
//   Real Immune_Popul.p(start = 10.0);
//   Real Non_Infected_Popul.in_1;
//   Real Non_Infected_Popul.in_2;
//   Real Non_Infected_Popul.out_1;
//   Real Non_Infected_Popul.p(start = 100.0);
//   Real Infected_Popul.in_1;
//   Real Infected_Popul.in_2;
//   Real Infected_Popul.out_1;
//   Real Infected_Popul.p(start = 50.0);
//   Real Sick_Popul.in_1;
//   Real Sick_Popul.in_2;
//   Real Sick_Popul.out_1;
//   Real Sick_Popul.p(start = 0.0);
//   Real Incubation.in_1;
//   Real Incubation.in_2;
//   Real Incubation.out_1;
//   parameter Real Incubation.c = 1.0;
//   Real Cure_Rate.in_1;
//   Real Cure_Rate.in_2;
//   Real Cure_Rate.out_1;
//   parameter Real Cure_Rate.c = 1.0;
//   Real Activation.in_1;
//   Real Activation.in_2;
//   Real Activation.out_1;
//   parameter Real Activation.c = 1.0;
//   Real Perc_Infected.in_1;
//   Real Perc_Infected.in_2;
//   Real Perc_Infected.out_1;
//   parameter Real Perc_Infected.c = 1.0;
//   Real Time_to_Breakdown.out_1;
//   parameter Real Time_to_Breakdown.c = 1.0;
//   Real Sickness_Duration.out_1;
//   parameter Real Sickness_Duration.c = 1.0;
//   Real Contraction_Rate.out_1;
//   parameter Real Contraction_Rate.c = 1.0;
//   Real Immune_Period.out_1;
//   parameter Real Immune_Period.c = 1.0;
//   Real Contagious_Popul.in_1;
//   Real Contagious_Popul.in_2;
//   Real Contagious_Popul.out_1;
//   Real Non_Contagious_Popul.in_1;
//   Real Non_Contagious_Popul.in_2;
//   Real Non_Contagious_Popul.out_1;
//   Real Total_Popul.in_1;
//   Real Total_Popul.in_2;
//   Real Total_Popul.out_1;
//   Real Temp3.in_1;
//   Real Temp3.in_2;
//   Real Temp3.out_1;
//   Real Contacts_Wk.in_1;
//   Real Contacts_Wk.out_1;
//   parameter Real Contacts_Wk.c = 0.1;
//   Real Temp1.in_1;
//   Real Temp1.in_2;
//   Real Temp1.out_1;
//   parameter Real Temp1.c = 1.0;
//   Real Temp2.in_1;
//   Real Temp2.in_2;
//   Real Temp2.out_1;
//   parameter Real Temp2.c = 1.0;
//   Real Infection_Rate.in_1;
//   Real Infection_Rate.in_2;
//   Real Infection_Rate.out_1;
// equation
//   der(Immune_Popul.p) = Immune_Popul.in_1 - Immune_Popul.in_2;
//   Immune_Popul.out_1 = Immune_Popul.p;
//   der(Non_Infected_Popul.p) = Non_Infected_Popul.in_1 - Non_Infected_Popul.in_2;
//   Non_Infected_Popul.out_1 = Non_Infected_Popul.p;
//   der(Infected_Popul.p) = Infected_Popul.in_1 - Infected_Popul.in_2;
//   Infected_Popul.out_1 = Infected_Popul.p;
//   der(Sick_Popul.p) = Sick_Popul.in_1 - Sick_Popul.in_2;
//   Sick_Popul.out_1 = Sick_Popul.p;
//   Incubation.out_1 = Incubation.c * Incubation.in_1 / Incubation.in_2;
//   Cure_Rate.out_1 = Cure_Rate.c * Cure_Rate.in_1 / Cure_Rate.in_2;
//   Activation.out_1 = Activation.c * Activation.in_1 / Activation.in_2;
//   Perc_Infected.out_1 = Perc_Infected.c * Perc_Infected.in_1 / Perc_Infected.in_2;
//   Time_to_Breakdown.out_1 = Time_to_Breakdown.c;
//   Sickness_Duration.out_1 = Sickness_Duration.c;
//   Contraction_Rate.out_1 = Contraction_Rate.c;
//   Immune_Period.out_1 = Immune_Period.c;
//   Contagious_Popul.out_1 = Contagious_Popul.in_1 + Contagious_Popul.in_2;
//   Non_Contagious_Popul.out_1 = Non_Contagious_Popul.in_1 + Non_Contagious_Popul.in_2;
//   Total_Popul.out_1 = Total_Popul.in_1 + Total_Popul.in_2;
//   Temp3.out_1 = Temp3.in_1 + Temp3.in_2;
//   Contacts_Wk.out_1 = Contacts_Wk.c * Contacts_Wk.in_1;
//   Temp1.out_1 = Temp1.c * Temp1.in_1 * Temp1.in_2;
//   Temp2.out_1 = Temp2.c * Temp2.in_1 * Temp2.in_2;
//   Infection_Rate.out_1 = if Infection_Rate.in_1 < Infection_Rate.in_2 then Infection_Rate.in_1 else Infection_Rate.in_2;
//   Temp3.in_2 = Introduction;
//   Contagious_Popul.in_1 = Incubation.in_1;
//   Contagious_Popul.in_1 = Infected_Popul.out_1;
//   Incubation.in_2 = Time_to_Breakdown.out_1;
//   Incubation.out_1 = Infected_Popul.in_2;
//   Incubation.out_1 = Sick_Popul.in_1;
//   Contagious_Popul.in_2 = Cure_Rate.in_1;
//   Contagious_Popul.in_2 = Sick_Popul.out_1;
//   Cure_Rate.in_2 = Sickness_Duration.out_1;
//   Activation.out_1 = Cure_Rate.out_1;
//   Activation.out_1 = Immune_Popul.in_1;
//   Activation.out_1 = Non_Infected_Popul.in_1;
//   Activation.out_1 = Sick_Popul.in_2;
//   Activation.in_1 = Immune_Popul.out_1;
//   Activation.in_1 = Non_Contagious_Popul.in_2;
//   Activation.in_2 = Immune_Period.out_1;
//   Contraction_Rate.out_1 = Temp2.in_1;
//   Contagious_Popul.out_1 = Perc_Infected.in_1;
//   Contagious_Popul.out_1 = Total_Popul.in_1;
//   Contacts_Wk.in_1 = Infection_Rate.in_2;
//   Contacts_Wk.in_1 = Non_Contagious_Popul.in_1;
//   Contacts_Wk.in_1 = Non_Infected_Popul.out_1;
//   Non_Contagious_Popul.out_1 = Total_Popul.in_2;
//   Perc_Infected.in_2 = Total_Popul.out_1;
//   Perc_Infected.out_1 = Temp1.in_1;
//   Contacts_Wk.out_1 = Temp1.in_2;
//   Temp1.out_1 = Temp2.in_2;
//   Temp2.out_1 = Temp3.in_1;
//   Infection_Rate.in_1 = Temp3.out_1;
//   Infected_Popul.in_1 = Infection_Rate.out_1;
//   Infected_Popul.in_1 = Non_Infected_Popul.in_2;
// end Influenza;
// endResult
