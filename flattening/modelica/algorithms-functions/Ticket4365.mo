package Ticket4365
  model Top
    inner Real a;    
    Sub1 s1;
    
  initial algorithm
      a := 0;      
    
  algorithm
    when time > 1 then
      a := 1;
    end when;
  end Top;

  
  model Sub1
    outer Real a;    
  algorithm
    when time > 2 then
      a := 2;
    end when;
  end Sub1;

end Ticket4365;
