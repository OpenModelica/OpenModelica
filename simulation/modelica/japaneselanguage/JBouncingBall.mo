// Google-translated Bouncing Ball model word by word
// This probably does not make much sense to a native speaker of Japanese, but at least it tests what it should...
// Sadly, Modelica does not allow quoted identifiers to be UTF-8 characters

model '跳ねるボール'
  parameter Real e=0.7 "反発係数";
  parameter Real g=9.81 "重力加速度";
  Real '高さ'(start=1) "ボールの高さ";
  Real '速度' "ボールの速度";
  Boolean '飛行'(start=true) "trueの場合、ボールが飛んでいる場合、";
  Boolean '影響';
  Real '新しい速度';
  discrete Integer 'バウンスの数'(start=0);
equation
  '影響' = '高さ' <= 0.0;
  der('速度') = if '飛行' then -g else 0;
  der('高さ') = '速度';

  when {'高さ' <= 0.0 and '速度' <= 0.0,'影響'} then
    '新しい速度' = if edge('影響') then -e*pre('速度') else 0;
    '飛行' = '新しい速度' > 0;
    reinit('速度', '新しい速度');
        'バウンスの数'=pre('バウンスの数')+1;
  end when;

end '跳ねるボール';
