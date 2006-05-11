// Influenza model

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
  input Real Introduction = 77;
  
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

