encapsulated package SystemTest
  import System.substring;
  import System.startTimer;
  import System.stopTimer;
  import System.resetTimer;
  import System.getTimerIntervalTime;
  import System.getTimerCummulatedTime;
  function substringTest
    input String str;
    input Integer i1,i2,i3;
    output String s1,s2,s3;
  algorithm
    s1 := substring(str,i1,i2);
    s2 := substring(str,i2,i3);
    s3 := substring(str,i1,i3);
  end substringTest;
  function timerTest
    output Real out;
  algorithm
    resetTimer();
    startTimer();
    stopTimer();
    out := getTimerIntervalTime();
    out := getTimerCummulatedTime();
  end timerTest;
  function randTest
    input Integer n,r;
    output String res;
  protected
    Integer i,j;
    array<Integer> vals;
  algorithm
    vals := arrayCreate(n, 0);
    for i in 1:n loop
      j := integer((System.realRand()*r)+1);
      arrayUpdate(vals, j, vals[j] + 1);
    end for;
    res := stringDelimitList(list(intString(i) + ": " + intString(arrayGet(vals,i)) for i in 1:r), ", ");
  end randTest;
end SystemTest;
