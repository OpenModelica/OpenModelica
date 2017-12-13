
#include "OMC.h"
#include <string>
#include <iostream>
#include "meta/meta_modelica.h"
/*
#include <boost/thread.hpp>
#include <boost/chrono.hpp>
*/
#include <pthread.h>
void runTest(std::string testfolder,std::string omhome)
{
   OMCData* omcPtr=0;
   int status =0;
   /*----------------------------------------*/
   std::cout << "Initialize OMC, use Visual Studio 2013 compiler" << std::endl;
   status = InitOMC(&omcPtr,"msvc13",omhome.c_str());
   if(status > 0)
     std::cout << "..ok" << std::endl;
   else
	 std::cout << "..failed" << std::endl;
   /*----------------------------------------*/
   std::cout << "Set working directory of OMC" << std::endl;

   char* change_dir_results =0;
   status = SetWorkingDirectory(omcPtr,testfolder.c_str(),&change_dir_results);
   if(status > 0)
    std::cout << "..ok " << change_dir_results << std::endl;
   else
	 std::cout << "..failed" << std::endl;
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


   std::string dir2 = "..";
   status = SetWorkingDirectory(omcPtr,dir2.c_str(),&change_dir_results);
   if(status > 0)
    std::cout << "..ok " << change_dir_results << std::endl;
   else
	 std::cout << "..failed" << std::endl;

  /*------------------------------------------*/
  FreeOMC(omcPtr);


}

int main(int argc, const char* argv[])
{


   std::cout << "Test OMC C-API dll ..." << std::endl;
   InitMetaOMC();
   std::cout << "starting test 1" << std::endl;
   std::string dir = "./tmp1";
   runTest(dir,"");
   std::cout << "starting test 2" << std::endl;
   dir = "./tmp1";
   runTest(dir,"");
   std::cout << "starting test 3" << std::endl;
   dir = "./tmp2";
   runTest(dir,"");
}

