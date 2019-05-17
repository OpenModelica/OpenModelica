
#include "OMC.h"
#include <string>
#include <iostream>
#include "meta/meta_modelica.h"

int main(int argc, const char* argv[])
{


   std::cout << "Test OMC C-API dll ..." << std::endl;
   OMCData omcPtr = {0};
   int status =0;

   string omhome;
   if(argc > 0)
	   omhome = argv[0];
   /*----------------------------------------*/
   std::cout << "Intialize OMC, use gcc compiler" << std::endl;
   status = InitOMC(&omcPtr,"gcc",omhome);
   if(status > 0)
     std::cout << "..ok" << std::endl;
   else
	 std::cout << "..failed" << std::endl;
   /*----------------------------------------*/



   /*----------------------------------------*/
   std::cout << "Get version of OMC" << std::endl;
   char* version =0;
   status = GetOMCVersion(omcPtr,& version);
   if(status > 0)
     std::cout << "..ok " << version << std::endl;
   else
	 std::cout << "..failed" << std::endl;
   /*------------------------------------------*/




  /*------------------------------------------*/
   std::cout << "load wrong library" << std::endl;
   status = LoadModel(omcPtr,"NoName");
   if(status < 0)
     std::cout << "..ok "  << std::endl;
   else
	 std::cout << "..failed" << std::endl;

   char* errorMsg=0;
   status = GetError(omcPtr,&errorMsg);
   if(status > 0)
     std::cout << "..Errors/warnings: "<< errorMsg << std::endl;
   else
	 std::cout << "..failed" << std::endl;
   /*------------------------------------------*/


    /*------------------------------------------*/
   std::cout << "load MSL" << std::endl;
   status = LoadModel(omcPtr,"Modelica");
   if(status > 0)
     std::cout << "..ok "  << std::endl;
   else
	 std::cout << "..failed" << std::endl;
   status = GetError(omcPtr,&errorMsg);
   if(status > 0)
     std::cout << "..Errors/warnings: "<< errorMsg << std::endl;
   else
	 std::cout << "..failed" << std::endl;
  /*------------------------------------------*/


   /*------------------------------------------*/
  std::cout << "Simulate MSL example Modelica.Blocks.Examples.PID_Controller" << std::endl;
   std::string simulateModel = "simulate(Modelica.Blocks.Examples.PID_Controller)";
  char* simulateResult =0;
  status = SendCommand(omcPtr,simulateModel.c_str(),&simulateResult);
  if(status > 0)
    std::cout << "..ok " << simulateResult << std::endl;
  else
	std::cout << "..failed" << std::endl;

   char* errorMsg2=0;
   status = GetError(omcPtr,&errorMsg2);
   std::cout << "..Errors/warnings: "<< errorMsg2 << std::endl;


  /*------------------------------------------*/
  FreeOMC(omcPtr);

}