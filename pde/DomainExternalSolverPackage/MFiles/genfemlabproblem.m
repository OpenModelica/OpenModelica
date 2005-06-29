function fem=genfemlabproblem(filename,bcfilename,f,c,da,t2,N)
clear fem;
[v,e,vh]=readgeom(filename);
[neweb,poly]=femlabdomainfix(v,e);

[bctype,bcgval,bcqval,bcind]=readbc(bcfilename);
%bcgroups=cell(size(bcind',1),1);
%for i=1:size(neweb,1),
%    bcgroups{neweb(i)}=[bcgroups{neweb(i)} i];
%end
fem.const={};
for i=1:size(bcind',1),
    if bctype(i) == 1 % dirichlet
        gval{i}={{0}};
        qval{i}={{0}};
        hval{i}={{1}};
        rval{i}={{bcgval(i)}};
    elseif bctype(i) == 2 % neumann
        gval{i}={{bcgval(i)}};
        qval{i}={{0}}; % should be zero also in bcqval
        hval{i}={{0}};
        rval{i}={{0}};        
    elseif bctype(i) == 3 % robin
        gval{i}={{bcgval(i)}};
        qval{i}={{bcqval(i)}};
        hval{i}={{0}};
        rval{i}={{0}};        
    elseif bctype(i) == 4 % timedepdirichlet
        warning('timedepdirichlet not implemented yet, using constant g value');
        gval{i}={{0}};
        qval{i}={{0}};
        hval{i}={{1}};
        %rstr=sprintf('''%f * t''',bcgval(i));
        rval{i}={{'timedepgval'}};        
        fem.const=cat(2,fem.const, {'timedepgval' bcgval(i)});
    end
end
%fem.dim='u';
%fem.form='coefficient';
fem.equ.f=f;
fem.equ.init=0;
fem.equ.c=c;
fem.geom=poly; % see femlabdomainfix.m
fem.bnd.ind=neweb; % see femlabdomainfix.m
%fem.bnd.ind=bcgroups; % see femlabdomainfix.m
fem.bnd.g=gval;
fem.bnd.q=qval;
fem.bnd.h=hval;
fem.bnd.r=rval;
fem.shape=2;
hmax=max(vh); % Get the biggest h
fem.equ.da=da;
fem.mesh=meshinit(fem,'hmax',hmax,'Report','off');
%fem.xmesh=meshextend(fem,'report','off');
if da==0
%    fem.sol=femlin(fem,'Report','off');
else
%    fem.init = asseminit(fem);
%    fem.sol=femtime(fem,'tlist',linspace(0,t2,N));
%    fem.sol=femtime(fem,'tlist',0:t2/N:t2);
end

