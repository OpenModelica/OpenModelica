package MatchCaseInteractive2

  function matchInMatch
    input Integer x;
    output Integer z;
  protected
    Integer y;
  algorithm
    y := x*2;
    z := matchcontinue (x,y)
      local Integer i1,i2,res;
      case (i1,4)
        equation
          res = matchcontinue (i1)
            case i2 then fail();
            case 1 then -3;
            case 2 then fail();
            case 2 then 3;
            case _ then -2;
          end matchcontinue;
        then res;
      case (_,_) then -1;
    end matchcontinue;
  end matchInMatch;

  uniontype UT
    record UT1
    end UT1;
    record UT2
      Integer a;
      Integer b;
      Integer c;
    end UT2;
    record UT3
      String s;
    end UT3;
  end UT;

  record REC
    Integer i;
    Boolean b;
    String str;
  end REC;

  function matchRecord
    input REC x;
    output String s;
  algorithm
    s := matchcontinue (x)
      local String str;
      case REC(1,true,"abc") then "REC(1,true,\"abc\")";
      case REC(1,true,str) then "REC(1,true,\""+str+"\")";
      case REC(b=true,str=str) then "REC(str=\""+str+"\")";
      case REC(i=1) then "REC(i=1)";
      case REC(_,false,"abc") then "REC(_,false,\"abc\")";
      case REC(_,_,_) then "REC(_,_,_)";
      case _ then "default";
    end matchcontinue;
  end matchRecord;

  function matchUniontype
    input Integer x;
    output String s;
  protected
    UT ut;
  algorithm
    ut := matchcontinue (x)
      case 1 then UT1();
      case 2 then UT2(1,2,3);
      case 3 then UT3("abc");
      case 4 then UT2(1,3,2);
      case 5 then UT2(1,2,2);
    end matchcontinue;
    s := matchcontinue (ut)
      local String str;
      case UT1() then "UT1()";
      case UT2(1,2,_) then "UT2(1,2,_)";
      case UT2(1,3,c=_) then "UT2(1,3,c=_)";
      case UT2(c=_) then "UT2(c=_)";
      case UT3(s = str) then str;
      case _ then "default";
    end matchcontinue;
  end matchUniontype;

end MatchCaseInteractive2;
