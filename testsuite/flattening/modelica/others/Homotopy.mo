// name:     Homotopy.mo
// keywords: ticket #2542
// status:   correct
// cflags: -d=-newInst
//
// Ticket #2542
//


model HomotopyTest
  parameter Real a = 20;
  parameter Real p = homotopy(a + 1, a);
end HomotopyTest;

