// This file provides you how to compile and test the Matlab translator
// This translator can translate the MAtlab code with the following grammar, Function Statements with Loops statement,
// Arithmetic Operators, relational Operators, logical Operators. For array operations the users should specify the size in the translated code 
// Some examples of the matlab code the translator can handle are placed in the folder Workingexamples

// look for the file SCRIPT.mos in the folder where the test cases are added 

1) Open the mingw terminal if you are a windows user and normal terminal for linux user

2) Go to the path and put your  matlab files(test cases to be translated) in SCRIPT.mos, look into comment for add your test cases here

3) A Make file is created to make the compilation process easier. 

4) For application users run the command "make test" without quotes (or) ../../../build/bin/omc SCRIPT.mos, you can see the translated modelica code as output

5) To add more grammars to the existing subset and test the parser, add your changes in the file lexermodelica.l and parsermodelica.y and run "make parser" (or)
   ../../../build/bin/omc OMCC.mos
    
   