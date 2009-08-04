package Math "copyright MathCore Engineering AB 2008 

author Peter Aronsson (peter.aronsson@mathcore.com)

This package contains a datatype for rational numbers and operations on rational numbers
"
public
uniontype Rational 
record RATIONAL "represents a rational number, e.g. 6/7"
   Integer nom "nominator";
   Integer denom "denominator";
  end RATIONAL;    
end Rational;
  
public function addRational "adds two rationals"
  input Rational r1;
  input Rational r2;
  output Rational r;
algorithm
  r := matchcontinue(r1,r2)
  local Integer i1,i2,i3,i4,ri1,ri2,d;            
    case(RATIONAL(i1,i2),RATIONAL(i3,i4)) equation
      ri1 =  i1*i4 + i3*i2;
      ri2 = i2*i4;
      d = intGcd(ri1,ri2);
      ri1 = ri1 / d;
      ri2 = ri2 / d;     
    then normalizeZero(RATIONAL(ri1,ri2));
  end matchcontinue;
end addRational;

protected function normalizeZero "if numerator is zero, set denominator to 1"
  input Rational r;
  output Rational outR;
algorithm
  outR := matchcontinue(r)
    case(RATIONAL(0,_)) then RATIONAL(0,1);
    case(r) then r;  
  end matchcontinue;
end normalizeZero;

public function subRational "subtracts two rationals"
  input Rational r1;
  input Rational r2;
  output Rational r;
algorithm
  r := matchcontinue(r1,r2)
  local Integer i1,i2,i3,i4,ri1,ri2,d;  
    case(RATIONAL(i1,i2),RATIONAL(i3,i4)) equation
      ri1 =  i1*i4 - i3*i2;
      ri2 = i2*i4;
      d = intGcd(ri1,ri2);
      ri1 = ri1 / d;
      ri2 = ri2 / d;      
    then normalizeZero(RATIONAL(ri1,ri2));
  end matchcontinue;
end subRational;

public function multRational "multiply two rationals"
  input Rational r1;
  input Rational r2;
  output Rational r;
algorithm
  r := matchcontinue(r1,r2)
    local Integer i1,i2,i3,i4,ri1,ri2,d;
    case(RATIONAL(i1,i2),RATIONAL(i3,i4)) equation
      ri1 = i1*i3;
      ri2 = i2*i4;       
      d = intGcd(ri1,ri2);
      ri1 = ri1 / d;
      ri2 = ri2 / d;      
   then normalizeZero(RATIONAL(ri1,ri2));      
  end matchcontinue;
end multRational;

public function divRational "division of two rationals i1/i2 / i3/i4 = (i1*i4) / (i3*i2) "
  input Rational r1;
  input Rational r2;
  output Rational r;
algorithm
  r := matchcontinue(r1,r2)
  local Integer i1,i2,i3,i4,ri1,ri2,d; 
    case(RATIONAL(i1,i2),RATIONAL(i3,i4)) equation
      ri1 = i1*i4;
      ri2 = i3*i2;
      d = intGcd(ri1,ri2);
      ri1 = ri1 / d;
      ri2 = ri2 / d;       
   then normalizeZero(RATIONAL(ri1,ri2));      
  end matchcontinue;
end divRational;

public function intGcd "returns the greatest common divisor for two Integers"
  input Integer i1;
  input Integer i2;
  output Integer i;
algorithm
  i := matchcontinue(i1,i2)
  local Integer i1,i2;   
    case(i1,0) then i1;
    case(i1,i2) then intGcd(i2,intMod(i1,i2));
  end matchcontinue;
end intGcd;


/* Tests */

public function testRational "test rational operators"
algorithm
  _ := matchcontinue()
    
    case() equation
      RATIONAL(7,6) =  addRational(RATIONAL(1,2),RATIONAL(2,3));
      RATIONAL(2,1) = addRational(RATIONAL(1,2),RATIONAL(3,2));
      
      RATIONAL(1,1) = subRational(RATIONAL(3,2),RATIONAL(1,2));
      RATIONAL(1,3) = subRational(RATIONAL(1,2),RATIONAL(1,6));
      
      RATIONAL(4,3) = multRational(RATIONAL(2,3),RATIONAL(4,2));
      RATIONAL(1,1) = multRational(RATIONAL(1,1),RATIONAL(1,1));
      
      RATIONAL(1,2) = divRational(RATIONAL(1,3),RATIONAL(2,3));
      print("testRational succeeded\n");
    then ();
    case() equation
      print("testRationals failed\n");
    then ();
      
  end matchcontinue;
end testRational;

end Math;