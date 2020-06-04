/* Sadly, Modelica does not allow this:

function 'オーペンモーデリッカー・ロックス'
  input Real 'キャン・ザー・デバガー・シー・ミー';
  output Real 'イェッス・イット・キャン';
algorithm
  'イェッス・イット・キャン' := sin('キャン・ザー・デバガー・シー・ミー');
end 'オーペンモーデリッカー・ロックス';

*/

function '\"\''
  input Real '#';
  output Real '23'; // Same hex code as # to test this better...
algorithm
  '23' := sin('#');
end '\"\'';

