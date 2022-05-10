//#include <iostream>
//#include <omp.h>
//
//#ifdef WIN32
//#include <windows.h>
//#endif
//
//#define THREAD_NUM 2
//#define REPLICATIONS 10000
//#define WARMUP 10000
//
//#define PACKAGE_SIZE_BIG 128
//#define PACKAGE_SIZE_SMALL 1
//
//int itemCount = 0;
//double items[PACKAGE_SIZE_BIG];
//unsigned long long comTimes[REPLICATIONS];
//
//inline volatile long long RDTSC() {
//   register long long TSC asm("eax");
//   asm volatile (".byte 15, 49" : : : "eax", "edx");
//   return TSC;
//}
#include "expat.h"
#include <list>
#include <string>
#include <sstream>
#include <stdio.h>
#include <fstream>
#include "cJSON.h"
#include "util/omc_file.h"

struct Equation {
  int id;
  unsigned long calcTimeCount;
  double calcTime;

  Equation() :
      id(-1), calcTimeCount(-1), calcTime(-1.0) {
  }
};

/**
 * Approximate the required time for operations (mult,add).
 * result: 2-parameters (m,n) y=mx+n
 */
void* HpcOmBenchmarkExtImpl__requiredTimeForOp() {
//  unsigned long long calcTimesMul[REPLICATIONS];
//  unsigned long long calcTimesAdd[REPLICATIONS];
//  unsigned int sumCalc = 0;
//  void *res = mmc_mk_nil();
//
//  //warmup
//  for (int i = 0; i < REPLICATIONS; i++)
//  {
//    double last = 1234.123 + i;
//    last = last * 3.6424;
//  }
//
//  //bench mul
//  for (int i = 0; i < REPLICATIONS; i++)
//  {
//    double last = 1234.123 + i;
//    unsigned long long t1 = RDTSC();
//    double res = last * 3.6424;
//    unsigned long long t2 = RDTSC();
//    calcTimesMul[i] = (t2-t1);
//  }
//
//  //bench add
//  for (int i = 0; i < REPLICATIONS; i++)
//  {
//    double last = 1234.123 + i;
//    unsigned long long t1 = RDTSC();
//    double res = last + 3.6424;
//    unsigned long long t2 = RDTSC();
//    calcTimesAdd[i] = (t2-t1);
//  }
//
//  for (int i = 0; i < REPLICATIONS; i++)
//  {
//    sumCalc += calcTimesAdd[i];
//    sumCalc += calcTimesMul[i];
//  }
//
//  int m = 1;
//  res = mmc_mk_cons(mmc_mk_icon((sumCalc/(REPLICATIONS*2))),res); //push n
//  res = mmc_mk_cons(mmc_mk_icon(m),res); //push m
  void *res = mmc_mk_nil();
  res = mmc_mk_cons(mmc_mk_icon(24), res); //push n
  res = mmc_mk_cons(mmc_mk_icon(1), res); //push m
  return res;
}

//void sendMessage (int warmUp, int replications, int packageSize)
//{
//  for (int i = 0; i < warmUp; i++)
//  {
//    for(int j=0; j < packageSize; j++)
//    {
//      items[j] = 672364.8897+i+j;
//    }
//    itemCount++;
//    while(itemCount > 0);
//  }
//
//  for (int i = 0; i < replications; i++)
//  {
//    for(int j=0; j < packageSize; j++)
//    {
//      items[j] = 672364.8897+i+j;
//    }
//    itemCount++;
//    unsigned long long t1 = RDTSC();
//    while(itemCount > 0);
//    unsigned long long t2 = RDTSC();
//    comTimes[i] = (t2-t1);
//  }
//}
//
//void waitForMessage(int warmUp, int replications, int packageSize)pt..str()
//{
//  double last[packageSize];
//
//  for (int i = 0; i < warmUp; i++)
//  {
//    while(itemCount == 0);
//    for(int j=0; j < packageSize; j++)
//    {
//      last[j] = items[j];
//    }
//    itemCount--;
//  }
//
//  for (int i = 0; i < replications; i++)
//  {
//    while(itemCount == 0);
//    for(int j=0; j < packageSize; j++)
//    {
//      last[j] = items[j];
//    }
//    itemCount--;
//  }
//}

/**
 * Approximate the required time to send doubles to another cpu.
 * result: 2-parameters (m,n) y=mx+n
 */
void* HpcOmBenchmarkExtImpl__requiredTimeForComm() {
//  void *res = mmc_mk_nil();
//  unsigned int sumComSmall = 0;
//  unsigned int sumComBig = 0;
//
//  omp_set_num_threads(THREAD_NUM);
//  omp_set_dynamic(0);
//
//  //Benchmark for small package
//  #pragma omp parallel for shared(items) shared(itemCount)
//  for (int i=0; i < THREAD_NUM; i++)
//  {
//    if((i % 2) == 0)
//    {
//#ifdef WIN32
//      DWORD_PTR mask = (1 << omp_get_thread_num());
//      SetThreadAffinityMask( GetCurrentThread(), mask );
//      SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_TIME_CRITICAL);
//#endif
//      sendMessage(WARMUP,REPLICATIONS, PACKAGE_SIZE_SMALL);
//    }
//    else
//    {
//#ifdef WIN32
//      DWORD_PTR mask = (1 << omp_get_thread_num());
//      SetThreadAffinityMask( GetCurrentThread(), mask );
//      SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_TIME_CRITICAL);
//#endif
//      waitForMessage(WARMUP,REPLICATIONS, PACKAGE_SIZE_SMALL);
//    }
//  }
//
//  for (int i = 0; i < REPLICATIONS; i++)
//    sumComSmall += comTimes[i];
//
//  //Benchmark for big package
//  #pragma omp parallel for shared(items) shared(itemCount)
//  for (int i=0; i < THREAD_NUM; i++)
//  {
//    if((i % 2) == 0)
//    {
//#ifdef WIN32
//      DWORD_PTR mask = (1 << omp_get_thread_num());
//      SetThreadAffinityMask( GetCurrentThread(), mask );
//      SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_TIME_CRITICAL);
//#endif
//      sendMessage(WARMUP,REPLICATIONS, PACKAGE_SIZE_BIG);
//    }
//    else
//    {
//#ifdef WIN32
//      DWORD_PTR mask = (1 << omp_get_thread_num());
//      SetThreadAffinityMask( GetCurrentThread(), mask );
//      SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_TIME_CRITICAL);
//#endif
//      waitForMessage(WARMUP,REPLICATIONS, PACKAGE_SIZE_BIG);
//    }
//  }
//
//  for (int i = 0; i < REPLICATIONS; i++)
//    sumComBig += comTimes[i];
//
//  res = mmc_mk_cons(mmc_mk_icon(sumComSmall/(REPLICATIONS*2)),res); //push n
//  res = mmc_mk_cons(mmc_mk_icon((sumComBig-sumComSmall)/((PACKAGE_SIZE_BIG-PACKAGE_SIZE_SMALL)*(REPLICATIONS*2))),res); //push m
  void *res = mmc_mk_nil();
  res = mmc_mk_cons(mmc_mk_icon(70), res); //push n
  res = mmc_mk_cons(mmc_mk_icon(4), res); //push m
  return res;
}

class XmlBenchReader {
private:
  struct ParserUserData {
    std::string *errorMsg;
    int level;
    Equation *currentEquation;
    std::list<Equation*> *equations;

    ParserUserData(std::string *_errorMsg, int _level,
        Equation *_currentEquation, std::list<Equation*> *_equations) {
      errorMsg = _errorMsg;
      level = _level;
      currentEquation = _currentEquation;
      equations = _equations;
    }
  };

protected:
  static void StartElement(void *data, const XML_Char *name,
      const XML_Char **attribute) {
    ParserUserData *userData = (ParserUserData*) data;
    userData->level++;

    if ((userData->level == 3) && (strcmp("equation", name) == 0)) {
      userData->currentEquation = new Equation();
      for (int i = 0; attribute[i]; i += 2) {
        if (strcmp("id", attribute[i]) == 0) {
          userData->currentEquation->id = strtol(attribute[i + 1] + 2,
              0, 10);
        }
      }
    }

    if ((userData->level == 4) && (strcmp("calcinfo", name) == 0)
        && (userData->currentEquation != 0)) {
      //find attributes
      for (int i = 0; attribute[i]; i += 2) {
        if (strcmp("time", attribute[i]) == 0)
          userData->currentEquation->calcTime = atof(
              attribute[i + 1]);

        if (strcmp("count", attribute[i]) == 0)
          userData->currentEquation->calcTimeCount = strtoul(
              attribute[i + 1], 0, 10);
      }
      userData->equations->push_back(userData->currentEquation);
      userData->currentEquation = 0;
    }
  }

  static void EndElement(void *data, const XML_Char *el) {
    ParserUserData *userData = (ParserUserData*) data;
    userData->level--;
  }

  static bool deleteAll(Equation *theElement) {
    delete theElement;
    return true;
  }

public:
  XmlBenchReader(void) {
  }

  ~XmlBenchReader(void) {
  }

  static std::list<std::list<double> > ReadBenchFileEquations(std::string filePath) {
    FILE *xmlFile;
    const int bufferSize = 10000;
    char buffer[bufferSize];
    XML_Parser parser;
    int len; /* len is the number of bytes in the current buffer of data */
    int done = 0;
    std::string errMsg = "";
    std::list<Equation*> eqList = std::list<Equation*>();
    std::list<std::list<double> > resultList =
        std::list<std::list<double> >();
    ParserUserData userData = ParserUserData(&errMsg, 0, 0, &eqList);

    xmlFile = omc_fopen(filePath.c_str(), "r");
    parser = XML_ParserCreate(NULL);
    XML_SetUserData(parser, &userData);
    XML_SetElementHandler(parser, StartElement, EndElement);
    do {
      //Read the graphml-file piece by piece
      len = omc_fread(buffer, sizeof(char), bufferSize, xmlFile, 0);

      if (len < bufferSize)
        done = true;

      if (XML_Parse(parser, buffer, len, done) == XML_STATUS_ERROR) {
        //std::cout << "Error during xml-parsing" << std::endl;
        break;
      }

    } while (!done);
    XML_ParserFree(parser);
    fclose(xmlFile);

    //Copy equation list to result list
    for (std::list<Equation*>::iterator it = eqList.begin();
        it != eqList.end(); it++) {
      //std::cout << "Equation " << (*it)->id << " calcTime: " << (*it)->calcTime << "  calcCount: " << (*it)->calcTimeCount << std::endl;
      std::list<double> tmpLst = std::list<double>();
      tmpLst.push_back((*it)->id);
      tmpLst.push_back((*it)->calcTime);
      tmpLst.push_back((*it)->calcTimeCount);
      resultList.push_back(tmpLst);
    }

    //Clean equation list
    eqList.remove_if(deleteAll);

    return resultList;
  }
};

std::list<std::list<double> > ReadJsonBenchFileEquations(std::string filePath)
{
    std::list<std::list<double> > resultList = std::list<std::list<double> >();

    FILE *fp;
    long lSize;
    char *buffer;
    int arraySize, i;
    cJSON *root;
    cJSON *profileBlocks;

    fp = omc_fopen ( filePath.c_str() , "rb" );
    if( !fp ) perror(filePath.c_str()),exit(1);

    fseek( fp , 0L , SEEK_END);
    lSize = ftell( fp );
    rewind( fp );

    /* allocate memory for entire content */
    buffer = (char*)calloc( 1, lSize+1 );
    if( !buffer )
    {
      fclose(fp),fputs("memory alloc fails\n",stderr);
      return resultList;
    }

    /* copy the file into the buffer */
    if( 1!=omc_fread( buffer , lSize, 1 , fp, 0) )
    {
      fclose(fp),free(buffer),fputs("entire read fails\n",stderr);
      return resultList;
    }
    /* do your work here, buffer is a string contains the whole text */
    root = cJSON_Parse(buffer);

    if(root == 0)
    {
      fclose(fp),free(buffer),fputs("no root object defined in json-file - maybe the json file is corrupt\n",stderr);
      return resultList;
    }

    profileBlocks = cJSON_GetObjectItem(root,"profileBlocks");
    if(profileBlocks == 0)
    {
      fclose(fp),free(buffer),fputs("no profile blocks defined in json-file\n",stderr);
      return resultList;
    }

    arraySize = cJSON_GetArraySize(profileBlocks);

    for(i = 0; i < arraySize; i++)
    {
      cJSON *item = cJSON_GetArrayItem(profileBlocks, i);
      cJSON *idItem = cJSON_GetObjectItem(item, "id");
      cJSON *ncallItem = cJSON_GetObjectItem(item, "ncall");
      cJSON *timeItem = cJSON_GetObjectItem(item, "time");
      std::list<double> tmpLst = std::list<double>();

      if(idItem->type == cJSON_String)
        tmpLst.push_back(atof(idItem->valuestring));
      else
        tmpLst.push_back(idItem->valuedouble);

      tmpLst.push_back(timeItem->valuedouble);
      tmpLst.push_back(ncallItem->valuedouble);
      resultList.push_back(tmpLst);
    }

    fclose(fp);
    free(buffer);

    return resultList;
}

void* HpcOmBenchmarkExtImpl__readCalcTimesFromXml(const char *filename)
{
  void *res = mmc_mk_nil();
  std::string errorMsg = std::string("");
  std::ifstream ifile(filename);
  if (!ifile)
  {
    errorMsg = "File '";
    errorMsg += std::string(filename);
    errorMsg += "' does not exist";
    res = mmc_mk_cons(mmc_mk_scon(errorMsg.c_str()), mmc_mk_nil());
    printf("%s\n",errorMsg.c_str());
    return res;
  }

  std::list<std::list<double> > retLst =
      XmlBenchReader::ReadBenchFileEquations(filename);

  for (std::list<std::list<double> >::iterator it = retLst.begin();
      it != retLst.end(); it++) {
    int i = 0;
    for (std::list<double>::iterator iter = (*it).begin();
        iter != (*it).end(); iter++) {
      if (i >= 3)
        break;
      res = mmc_mk_cons(mmc_mk_rcon(*iter), res);
      //std::cerr << "value " << *iter << std::endl;
    }
  }
  //std::cerr << "Blaaaa2" << std::endl;
  return res;
}

void* HpcOmBenchmarkExtImpl__readCalcTimesFromJson(const char *filename)
{
  void *res = mmc_mk_nil();
  std::string errorMsg = std::string("");
  std::ifstream ifile(filename);
  if (!ifile)
  {
    errorMsg = "File '";
    errorMsg += std::string(filename);
    errorMsg += "' does not exist";
    res = mmc_mk_cons(mmc_mk_scon(errorMsg.c_str()), mmc_mk_nil());
    printf("%s\n",errorMsg.c_str());
    return res;
  }

  std::list<std::list<double> > retLst = ReadJsonBenchFileEquations(filename);

  for (std::list<std::list<double> >::iterator it = retLst.begin();
      it != retLst.end(); it++) {
    int i = 0;
    for (std::list<double>::iterator iter = (*it).begin();
        iter != (*it).end(); iter++) {
      if (i >= 3)
        break;
      res = mmc_mk_cons(mmc_mk_rcon(*iter), res);
      //std::cerr << "value " << *iter << std::endl;
    }
  }
  //std::cerr << "Blaaaa2" << std::endl;
  return res;
}
