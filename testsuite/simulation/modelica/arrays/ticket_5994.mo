package Ticket_5994
  function modifyArray
      input Real values[:];
      output Real result[size(values, 1)];
    algorithm
      result[size(values, 1)] := 42.0;
  end modifyArray;

  model Test
    Real sample[:] = {1.0, 2.0, 3.0};
    Real modified[:] = modifyArray(values = sample);
  end Test;
end Ticket_5994;