function ArrayFromRangeTest
  input Integer length;
  output Integer outArrayInteger[length];
  output Real outArrayReal[length];
algorithm
  outArrayInteger := 1:length;
  outArrayReal := 1:length;
end ArrayFromRangeTest;
