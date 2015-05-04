package SusanTestSmall

import interface SusanTestTV;

template helloWorld()
::= "Hello, World!"
end helloWorld;

template testLet(list<String> strs)
::=
  let x = "Testing Let, "
  <<
  <%x + helloWorld()%>
  Some more text here...
  listLength(strs): <%(strs |> str => str ; separator = " x ")%>
  >>
end testLet;

template testArray(array<Integer> ints)
::= ""
end testArray;

end SusanTestSmall;

// vim: filetype=susan sw=2 sts=2
