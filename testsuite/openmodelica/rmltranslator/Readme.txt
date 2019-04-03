// This file provides you how to compile and test the rml to MetaModelica translator
// look for the file SCRIPT.mos in the folder 

1) Open the mingw terminal if you are a windows user and normal terminal for linux user

2) Go to the correct path and put your rml files(test cases to be translated) in SCRIPT.mos, look into comment for add your test cases here

3) To generate the parser run ../../../build/bin/omc OMCC.mos or make parser  which will genereated the lexer and parser components ( this run is optional, it should be run when u change the grammar in parserModelica.y, otherwise you can directly run step 4)

4) To run the translator, run ../../../build/bin/omc SCRIPT.mos or make test which will generate the final translated code, you can pass the ouput to a text file by running
   ../../../build/bin/omc SCRIPT.mos > output.txt
   