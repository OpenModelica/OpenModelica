// name: AlgorithmElseOpt
// status: correct

class AlgorithmElseOpt
  function f
    output Real r;
  algorithm
  end f;
  Real r;
algorithm
  if false then
    r := 178;
  end if;
  if true then
    r := 1.5;
  else
    r := 2.1;
  end if;

  if false then
    r := 1.5;
  else
    r := 2.1;
  end if;

  if false then
    r := 1.5;
  elseif true then
    r := 1.7;
  else
    r := 2.1;
  end if;

  if false then
    r := 1.5;
  elseif false then
    r := 1.7;
  else
    r := 2.1;
  end if;

  if false then
    r := 1.5;
  elseif time>0.5 then
    r := 13.37;
  elseif true then
    r := 1.7;
  else
    r := 2.1;
  end if;

  if false then
    r := 1.5;
  elseif time>0.5 then
    r := 13.37;
  elseif false then
    r := 1.7;
  else
    r := 2.1;
  end if;

end AlgorithmElseOpt;

// Result:
// class AlgorithmElseOpt
//   Real r;
// algorithm
//   r := 1.5;
//   r := 2.1;
//   r := 1.7;
//   r := 2.1;
//   if time > 0.5 then
//     r := 13.37;
//   else
//     r := 1.7;
//   end if;
//   if time > 0.5 then
//     r := 13.37;
//   else
//     r := 2.1;
//   end if;
// end AlgorithmElseOpt;
// endResult
