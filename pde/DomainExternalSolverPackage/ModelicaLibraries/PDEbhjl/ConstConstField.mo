package ConstConstField 
  extends Field;
  
  redeclare record Data 
    parameter domainP.Data domain;
    parameter FieldType constval;
  end Data;
  
  redeclare function value 
    input Point x;
    input Data d;
    output FieldType y;
  algorithm 
    y := d.constval;
  end value;
  
end ConstConstField;
