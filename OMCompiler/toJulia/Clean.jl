using DocumentFormat

f=ARGS[1]

fin=open(f)
c=read(fin)
fixed=DocumentFormat.format(String(c))
fout=open(f, "w")
write(fout,fixed)
