package Synchronous

  package Constructors

    model inferredClock
      Integer y(start=0);
    equation
      when Clock() then
        y = previous(y) + 1;
      end when;
    end inferredClock;
  end Constructors;

  //annotation(uses(Modelica(version="4.0.0")));
end Synchronous;