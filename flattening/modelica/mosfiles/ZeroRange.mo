package ZeroRange

function testRangeLoop "Returns the number of iterations a loop over a range this length has"
  input Integer start;
  input Integer step;
  input Integer stop;
  output Integer o;
algorithm
  o := 0;
  for i in start:step:stop loop
    o := o + 1;
  end for;
end testRangeLoop;

end ZeroRange;
