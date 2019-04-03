model TestTwoOut
  Real out(fixed=false);
  Real[3] si;
  Real[3] so(start={0,0,0},each fixed=false);

equation
  si={1,2,3}*time;
  when {sample(0,0.1),initial()} then
      (out, so) = funcTwoOut(si);
  end when;

end TestTwoOut;

function funcTwoOut
input Real[3] inp1;
output Real out1;
output Real[3] out2;
algorithm
out2[1]:=10*inp1[1];
out2[2]:=10*inp1[2];
out2[3]:=10*inp1[3];

out1:=-(inp1[1] + inp1[2] + inp1[3]);
end funcTwoOut;