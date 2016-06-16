/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE
 * OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */
/*
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#include <iostream>
#include "GDBMIParser.h"

using namespace GDBMIParser;

int main(int argc, char** argv)
{
  while (1)
  {
    cout << "Enter the GDB MI output to parse OR type exit to quit,\n\n";
    string str;
    getline(cin, str);
    if (str.compare("exit") == 0)
      break;

    GDBMIResponse *miResponse = parseGDBOutput(str.c_str());
    if (miResponse)
    {
      fprintf(stdout, "------------GDBMIResponse------------\n\n");fflush(NULL);
      printGDBMIResponse(miResponse);
      fprintf(stdout, "\n------------------------------------\n\n");fflush(NULL);
      delete miResponse;
    }
    else
    {
      list<string> errorsList = getParserErrorsList();
      list<string>::iterator errorsListIterator;
      for (errorsListIterator = errorsList.begin(); errorsListIterator != errorsList.end(); ++errorsListIterator)
      {
        fprintf(stderr, "Error : %s\n", (*errorsListIterator).c_str());fflush(NULL);
      }
    }
  }
//  /* Parse the result */
//  GDBMIResult *miResult1 = parseGDBResult("number=\"1\"");
//  fprintf(stdout, "------------GDBMIResult------------\n\n");fflush(NULL);
//  printGDBMIResult(miResult1);
//  //fprintf(stdout, "%s=%s\n", miResult1->key.c_str(), miResult1->miValue->value.c_str());fflush(NULL);
//  fprintf(stdout, "\n------------------------------------\n\n\n");fflush(NULL);
//  GDBMIResult *miResult2 = parseGDBResult("bkpt={number=\"1\"}");
//  fprintf(stdout, "------------GDBMIResult------------\n\n");fflush(NULL);
//  printGDBMIResult(miResult2);
//  fprintf(stdout, "\n------------------------------------\n\n\n");fflush(NULL);
//  /* Parse the tuple */
//  GDBMITuple *miTuple = parseGDBTuple("{number=\"1\",type=\"breakpoint\",disp=\"keep\",enabled=\"y\",addr=\"0x00d0e905\"}");
//  fprintf(stdout, "------------GDBMITuple------------\n\n");fflush(NULL);
//  fprintf(stdout, "{");fflush(NULL);
//  printGDBMITuple(miTuple);
//  fprintf(stdout, "}\n");fflush(NULL);
//  fprintf(stdout, "------------------------------------\n\n\n");fflush(NULL);
//  GDBMIList *miList = parseGDBList("[frame={level=\"0\",line=\"1424\"},frame={level=\"1\",line=\"1191\"}]");
//  fprintf(stdout, "------------GDBMIList------------\n\n");fflush(NULL);
//  printGDBMIList(miList);
//  fprintf(stdout, "\n------------------------------------\n\n\n");fflush(NULL);
//  /* Parse the result record */
//  GDBMIResultRecord *miResultRecord1 = parseGDBResultRecord("6^done,bkpt={number=\"1\",type=\"breakpoint\",disp=\"keep\",enabled=\"y\",addr=\"0x00d0e905\"}\n");
//  fprintf(stdout, "------------GDBMIResultRecord------------\n\n");fflush(NULL);
//  fprintf(stdout, "%d^,%s,", miResultRecord1->token, miResultRecord1->cls.c_str());fflush(NULL);
//  printGDBMIResultList(miResultRecord1->miResultsList);
//  fprintf(stdout, "\n------------------------\n\n\n");fflush(NULL);
//  /* Parse the stream record */
//  /*GDBMIStreamRecord *miStreamRecord = parseGDBStreamRecord("~\"[New Thread 4784.0x2dbc]\"");
//  fprintf(stdout, "------------GDBMIStreamRecord------------\n\n");fflush(NULL);
//  fprintf(stdout, "%s", miStreamRecord->value.c_str());fflush(NULL);
//  fprintf(stdout, "\n------------------------------------\n\n\n");fflush(NULL);*/
//  /* Parse the result record */
//  GDBMIResultRecord *miResultRecord2 = parseGDBResultRecord("14^done,stack=[frame={level=\"0\",line=\"1424\"},frame={level=\"1\",line=\"1191\"},frame={level=\"2\",line=\"283\"},frame={level=\"3\",line=\"183\"}]\n");
//  fprintf(stdout, "------------GDBMIResultRecord------------\n\n");fflush(NULL);
//  fprintf(stdout, "%d^,%s,", miResultRecord2->token, miResultRecord2->cls.c_str());fflush(NULL);
//  printGDBMIResultList(miResultRecord2->miResultsList);
//  fprintf(stdout, "\n------------------------------------\n\n\n");fflush(NULL);
//  /* parse exec_async_output */
//  GDBMIResultRecord *miResultRecord3 = parseGDBExecAsyncOutput("*stopped,reason=\"breakpoint-hit\",disp=\"keep\",bkptno=\"1\"\n");
//  fprintf(stdout, "------------GDBMIResultRecord------------\n\n");fflush(NULL);
//  fprintf(stdout, "%d,%s,", miResultRecord3->token, miResultRecord3->cls.c_str());fflush(NULL);
//  printGDBMIResultList(miResultRecord3->miResultsList);
//  fprintf(stdout, "\n------------------------------------\n\n\n");fflush(NULL);
//  /* parse output */
//  GDBMIResponse *miResponse1 = parseGDBOutput("6^done,bkpt={number=\"1\",type=\"breakpoint\",disp=\"keep\",enabled=\"y\",addr=\"0x00d0e905\"}");
//  fprintf(stdout, "------------GDBMIResponse1------------\n\n");fflush(NULL);
//  printGDBMIResponse(miResponse1);
//  fprintf(stdout, "\n------------------------------------\n\n\n");fflush(NULL);
//  GDBMIResponse *miResponse2 = parseGDBOutput("14^done,stack=[frame={level=\"0\",line=\"1424\"},frame={level=\"1\",line=\"1191\"},frame={level=\"2\",line=\"283\"},frame={level=\"3\",line=\"183\"}]");
//  fprintf(stdout, "------------GDBMIResponse2------------\n\n");fflush(NULL);
//  printGDBMIResponse(miResponse2);
//  fprintf(stdout, "\n------------------------------------\n\n\n");fflush(NULL);
//  GDBMIResponse *miResponse3 = parseGDBOutput("*stopped,reason=\"breakpoint-hit\",disp=\"keep\",bkptno=\"1\"");
//  fprintf(stdout, "------------GDBMIResponse3------------\n\n");fflush(NULL);
//  printGDBMIResponse(miResponse3);
//  fprintf(stdout, "\n------------------------------------\n\n\n");fflush(NULL);
//  GDBMIResponse *miResponse4 = parseGDBOutput("~\"Reading symbols from c:\\openmodelica\\trunk\\testsuite\\openmodelica\\bootstrapping\\main.exe...\"");
//  fprintf(stdout, "------------GDBMIResponse4------------\n\n");fflush(NULL);
//  printGDBMIResponse(miResponse4);
//  fprintf(stdout, "\n------------------------------------\n\n\n");fflush(NULL);
//  GDBMIResponse *miResponse5 = parseGDBOutput("&\"Undefined info command: \"proc\".  Try \"help info\".\"");
//  fprintf(stdout, "------------GDBMIResponse5------------\n\n");fflush(NULL);
//  printGDBMIResponse(miResponse5);
//  fprintf(stdout, "\n------------------------------------\n\n\n");fflush(NULL);
//  GDBMIResponse *miResponse6 = parseGDBOutput("(gdb)");
//  fprintf(stdout, "------------GDBMIResponse6------------\n\n");fflush(NULL);
//  if (!printGDBMIResponse(miResponse6))
//    fprintf(stdout, "Output not parsed by GDBMIParser. No rule is applied.");fflush(NULL);
//  fprintf(stdout, "\n------------------------------------\n\n\n");fflush(NULL);
//  GDBMIResponse *miResponse7 = parseGDBOutput("=thread-group-added,id=\"i1\"");
//  fprintf(stdout, "------------GDBMIResponse7------------\n\n");fflush(NULL);
//  printGDBMIResponse(miResponse7);
//  fprintf(stdout, "\n------------------------------------\n\n\n");fflush(NULL);
//  GDBMIResponse *miResponse8 = parseGDBOutput("{{Placement(true,0.0,0.0,100.0,-10.0,120.0,10.0,0.0,0.0,0.0,100.0,-10.0,120.0,10.0,0.0)},{Placement(true,0.0,0.0,100.0,-10.0,120.0,10.0,0.0,0.0,0.0,100.0,-10.0,120.0,10.0,0.0)},{},{},{},{}}");
//  fprintf(stdout, "------------GDBMIResponse7------------\n\n");fflush(NULL);
//  printGDBMIResponse(miResponse8);
//  fprintf(stdout, "\n------------------------------------\n\n\n");fflush(NULL);
  return 0;
}
