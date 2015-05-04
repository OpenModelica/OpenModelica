class AllWild
  uniontype Union
    record REC
      Real r1,r2,r3,r4,r5;
    end REC;
  end Union;
  function fn
    output Real r;
  algorithm
    r := match REC(1,2,3,4,5) case REC(__) then 6.0; end match;
  end fn;
  constant Real r = fn();
end AllWild;
