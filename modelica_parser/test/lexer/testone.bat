@echo off
set testin=%1
set testout=%testin:.in.txt=.out.txt%
set testdiff=%testin:.in.txt=.diff.txt%

if exist %testdiff% del %testdiff%

echo testing %testin%

test_lexer %testin% > tmp 
diff tmp %testout% > tmp2 
if errorlevel 1 echo %testin% failed && type tmp2 > %testdiff%

del tmp
del tmp2