function [neweb,poly]=femlabdomainfix(v,e);

% v=[4.5 2 1;2 2 1;2 1 1;-0.5 1 1;-1.5 2 1;-4.5 2 1;-4.5 -2 2;-1 -2 3;-1 -1.5 3;-1.5 -1 3;-1.5 0 3;1.5 0 3;1.5 -1 3;1 -1.5 3;1 -2 3;4.5 -2 3];

% e=[1 2 1;2 3 1;3 4 1;4 5 1;5 6 1;6 7 2;7 8 3;8 9 3;9 10 3;10 11 3;11 12 3;12 13 3;13 14 3;14 15 3;15 16 3;16 1 4];


vx = v(:,1);
vy = v(:,2);
vb = v(:,3);

es = e(:,1);
ee = e(:,2);
eb = e(:,3);

poly=line2(vx,vy);

newvertices=flgeomvtx(poly)';
newedges=flgeomse(poly)';

newvx=newvertices(:,1);
newvy=newvertices(:,2);

newes=newedges(:,1);
newee=newedges(:,2);

n=length(newes);
neweb=-ones(n,1);

myeps = eps*100;

for i=1:n
  news = newes(i);
  newe = newee(i);
  newsx = newvx(news);
  newsy = newvy(news);
  newex = newvx(newe);
  newey = newvy(newe);
  for j=1:n
    s2 = es(j);
    e2 = ee(j);
    sx = vx(s2);
    sy = vy(s2);
    ex = vx(e2);
    ey = vy(e2);
    if ((abs(newsx-sx) < myeps) & (abs(newsy-sy) < myeps) & ... 
        (abs(newex-ex) < myeps) & (abs(newey-ey) < myeps)) | ...
       ((abs(newsx-ex) < myeps) & (abs(newsy-ey) < myeps) & ... 
        (abs(newex-sx) < myeps) & (abs(newey-sy) < myeps))
      neweb(i) = eb(j);
    end
  end
end
