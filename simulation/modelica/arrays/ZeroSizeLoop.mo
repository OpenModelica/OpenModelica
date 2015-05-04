model ZeroSizeLoopTest
  block activationCon
    parameter input Integer nIn;
    parameter input Integer nOut;
    input Real tIn[:];
    input Real tOut[:];
    input Integer tIntIn[:];
    input Integer tIntOut[:];
    input Integer arcType[:];
    input Real arcWeightIn[:];
    input Real arcWeightOut[:];
    input Integer arcWeightIntIn[:];
    input Integer arcWeightIntOut[:];
    input Real minTokens[:];
    input Real maxTokens[:];
    input Integer minTokensInt[:];
    input Integer maxTokensInt[:];
    input Boolean firingCon;
    input Boolean fed[:];
    input Boolean emptied[:];
    input Boolean disPlaceIn[:];
    input Boolean disPlaceOut[:];
    input Real testValue[:];
    input Integer testValueInt[:];
    input Integer normalArc[:];
    input Boolean testChange[:];
    output Boolean active;
    output Boolean weaklyInputActiveVec[nIn];
    output Boolean weaklyOutputActiveVec[nOut];
  algorithm
    active:=true;
    weaklyInputActiveVec:=fill(false, nIn);
    weaklyOutputActiveVec:=fill(false, nOut);

    for i in 1:nIn loop
      if disPlaceIn[i] then
        if arcType[i]==1 and not (tIntIn[i]-arcWeightIntIn[i]  >= minTokensInt[i]) then
          active:=false;
        elseif arcType[i]==2 and not (tIntIn[i] > testValueInt[i]) then
          active:=false;
        elseif arcType[i]==3 and not (tIntIn[i] < testValueInt[i]) then
          active:=false;
        end if;
      else
        if arcType[i]==1 or normalArc[i]==2 then
           if not (tIn[i]>minTokens[i] or (tIn[i]<=minTokens[i] and fed[i])) then
              active:=false;
           elseif tIn[i]<=minTokens[i] and fed[i] then
              weaklyInputActiveVec[i]:=true;
           end if;
        end if;
        if arcType[i]==2 then
            if not (tIn[i] > testValue[i]) then
              active:=false;
            end if;
             if testChange[i] and fed[i] and normalArc[i]==2 then
               weaklyInputActiveVec[i]:=true;
             end if;
        elseif arcType[i]==3 and not (tIn[i] < testValue[i]) then
          active:=false;
        end if;
      end if;
    end for;

    for i in 1:nOut loop
       if disPlaceOut[i] then
         if not (tIntOut[i]+arcWeightIntOut[i]<=maxTokensInt[i]) then
          active:=false;
         end if;
       else
        if not (tOut[i]<maxTokens[i] or (tOut[i]>=maxTokens[i] and emptied[i])) then
          active:=false;
        elseif tOut[i]>=maxTokens[i] and emptied[i] then
          weaklyOutputActiveVec[i]:=true;
        end if;
       end if;
    end for;
    active:=active and firingCon;
    weaklyOutputActiveVec:=weaklyOutputActiveVec and fill(firingCon,nOut);
    weaklyInputActiveVec:=weaklyInputActiveVec and fill(firingCon,nIn);
  end activationCon;

  activationCon activation(nIn=0,
                           nOut=0,
                           tIn=fill(0, 0),
                           tOut=fill(0, 0),
                           tIntIn=fill(0, 0),
                           tIntOut=fill(0, 0),
                           arcType=fill(0, 0),
                           arcWeightIn=fill(0, 0),
                           arcWeightOut=fill(0, 0),
                           arcWeightIntIn=fill(0, 0),
                           arcWeightIntOut=fill(0, 0),
                           minTokens=fill(0, 0),
                           maxTokens=fill(0, 0),
                           minTokensInt=fill(0, 0),
                           maxTokensInt=fill(0, 0),
                           firingCon=false,
                           fed=fill(false, 0),
                           emptied=fill(false, 0),
                           disPlaceIn=fill(false, 0),
                           disPlaceOut=fill(false, 0),
                           testValue=fill(0, 0),
                           testValueInt=fill(0, 0),
                           normalArc=fill(0, 0),
                           testChange=fill(false, 0));
end ZeroSizeLoopTest;
