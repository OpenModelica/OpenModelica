@echo off
set testin=%1
set testout=%testin:.in.mo=.out.mo%
set testdiff=%testin:.in.mo=.diff.mo%

if exist %testdiff% del %testdiff%

echo testing %testin%

test_parser %testin% > tmp
if not exist %testout% goto notestout
diff tmp %testout% > tmp2
if errorlevel 1 echo %testin% failed && type tmp2 > %testdiff%

del tmp
del tmp2

goto end

:notestout
echo Failed: %testout% does not exist

:end
