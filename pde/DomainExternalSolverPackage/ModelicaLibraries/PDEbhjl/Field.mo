package Field 
  replaceable type FieldType = Real;
  replaceable package domainP = Domain extends Domain;
  //replaceable package initialField = Field extends ConstField;
  
  replaceable record Data 
    parameter domainP.Data domain;
  end Data;
  
  replaceable function value 
    input Point x;
    input Data d;
    output FieldType y;
  algorithm 
    y := 0;
  end value;
  
end Field;
