/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#include "error.h"

#include <deque>
#include <string>
#include <iostream>
#include <fstream>
#include <utility>
#include <memory>
#include <cstring>
#include <limits>
#include <algorithm>
#include <cmath>
#include <cassert>
#include <cstdarg>
#include <cctype>

#include "tables.h"

#ifdef _MSC_VER
#include "omc_msvc.h"
#endif

/*extern char *model_dir; // defined somewhere else (where?) */



/* \brief This class is used for throwing an exception when simulation code should be terminated.
 * For instance, when a terminate call occurse or if an assert becomes active
 */

/* std::deque wrapper that calls deletes stores pointer in destructor */
template <typename item_t>
class Holder {
public:
  inline item_t* &operator[](size_t idx)  { return list[idx]; }
  inline void push_back(item_t* item) { list.push_back(item); }
  inline size_t size() { return list.size(); }
  ~Holder()
  { std::for_each(list.begin(),list.end(),free); }
private:
  std::deque<item_t*> list;
  static void free(item_t* item) { delete item; }
};

typedef struct InterpolationTable
{
  char *filename;
  char *tablename;
  char own_data;
  double* data;
  size_t rows;
  size_t cols;
  char colWise;
  int ipoType;
  int expoType;
  double startTime;
} InterpolationTable;

typedef struct InterpolationTable2D
{
  char *filename;
  char *tablename;
  char own_data;
  double *data;
  size_t rows;
  size_t cols;

  char colWise;
  int ipoType;
  int expoType;
} InterpolationTable2D;

Holder<InterpolationTable> interpolationTables;
Holder<InterpolationTable2D> interpolationTables2D;


InterpolationTable *InterpolationTable_init(double time,double startTime, int ipoType, int expoType,
         const char* tableName, const char* fileName, 
         const double *table, 
         int tableDim1, int tableDim2,int colWise);
/* InterpolationTable *InterpolationTable_Copy(InterpolationTable *orig); */
void InterpolationTable_deinit(InterpolationTable **tpl);
double InterpolationTable_interpolate(InterpolationTable *tpl, double time, size_t col);
double InterpolationTable_maxTime(InterpolationTable *tpl);
double InterpolationTable_minTime(InterpolationTable *tpl);
char InterpolationTable_compare(InterpolationTable *tpl, const char* fname, const char* tname, const double* table);

double InterpolationTable_extrapolate(InterpolationTable *tpl, double time, size_t col, bool beforeData);
inline double InterpolationTable_interpolateLin(InterpolationTable *tpl, double time, size_t i, size_t j);
inline const double InterpolationTable_getElt(InterpolationTable *tpl, size_t row, size_t col);
void InterpolationTable_checkValidityOfData(InterpolationTable *tpl);


InterpolationTable2D *InterpolationTable2D_init(int ipoType, const char* tableName,
           const char* fileName, const double *table,
           int tableDim1, int tableDim2, int colWise);
void InterpolationTable2D_deinit(InterpolationTable2D **table);
double InterpolationTable2D_interpolate(InterpolationTable2D *tpl, double x1, double x2);
char InterpolationTable2D_compare(InterpolationTable2D *tpl, const char* fname, const char* tname, const double* table);
double InterpolationTable2D_linInterpolate(double x, double x_1, double x_2, double f_1, double f_2);
const double InterpolationTable2D_getElt(InterpolationTable2D *tpl, size_t row, size_t col);
void InterpolationTable2D_checkValidityOfData(InterpolationTable2D *tpl);



/* Initialize table.
 * timeIn - time
 * startTime - time-Offset for the signal.
 * ipoType - type of interpolation.
 *   0 = linear interpolation,
 *    1 = smooth interpolation with akima splines s.t der(y) is continuous
 * expoType - extrapolation type
 *   0 = hold first/last value outside the range
 *   1 = extrapolate outside the rang using last/first two values
 *   2 = periodically repeat table data
 * tableName - name of table
 * table - matrix with table data
 * tableDim1 - number of rows of table
 * tableDim2 - number of columns of table.
 * colWise - 0 = column major order
 *           1 = row major order
 */

extern "C"
int omcTableTimeIni(double timeIn, double startTime,int ipoType,int expoType,
        const char *tableName, const char* fileName, 
        const double *table,int tableDim1, int tableDim2,int colWise)
{
  /* if table is already initialized, find it */
  for(size_t i = 0; i < interpolationTables.size(); ++i)
    if (InterpolationTable_compare(interpolationTables[i],fileName,tableName,table))
      return i;
  /* otherwise initialize new table */
  interpolationTables.push_back(InterpolationTable_init(timeIn,startTime,
                   ipoType,expoType, 
                   tableName, fileName, 
                   table, tableDim1, 
                   tableDim2, colWise));
  return (interpolationTables.size()-1);
}

extern "C"
void omcTableTimeIpoClose(int tableID)
{
  if (tableID >= 0 && tableID < (int)interpolationTables.size())
  {
    InterpolationTable_deinit(&interpolationTables[tableID]); 
  }
}

extern "C"
double omcTableTimeIpo(int tableID, int icol, double timeIn)
{
  if (tableID >= 0 && tableID < (int)interpolationTables.size())
    return InterpolationTable_interpolate(interpolationTables[tableID],timeIn,icol-1);
  else
    return 0.0;
}

extern "C"
double omcTableTimeTmax(int tableID)
{
  if (tableID >= 0 && tableID < (int)interpolationTables.size())
    return InterpolationTable_maxTime(interpolationTables[tableID]);
  else
    return 0.0;
}

extern "C"
double omcTableTimeTmin(int tableID)
{
  if (tableID >= 0 && tableID < (int)interpolationTables.size())
    return InterpolationTable_minTime(interpolationTables[tableID]);
  else
    return 0.0;
}

extern "C"
int omcTable2DIni(int ipoType, const char *tableName, const char* fileName, 
      const double *table,int tableDim1,int tableDim2,int colWise)
{
  /* if table is already initialized, find it */
  for(size_t i = 0; i < interpolationTables2D.size(); ++i)
    if (InterpolationTable2D_compare(interpolationTables2D[i],fileName,tableName,table))
      return i;
  /* otherwise initialize new table */
  interpolationTables2D.push_back(InterpolationTable2D_init(ipoType,tableName,
                      fileName,table,tableDim1,tableDim2,colWise));
  return (interpolationTables2D.size()-1);
}

extern "C"
void omcTable2DIpoClose(int tableID)
{
  if (tableID >= 0 && tableID < (int)interpolationTables2D.size())
  {
    InterpolationTable2D_deinit(&interpolationTables2D[tableID]);
  }
}

extern "C"
double omcTable2DIpo(int tableID,double u1_, double u2_)
{
  if (tableID >= 0 && tableID < (int)interpolationTables2D.size())
    return InterpolationTable2D_interpolate(interpolationTables2D[tableID], u1_, u2_);
  else
    return 0.0;
}

/* ******************************
   ***    IMPLEMENTATION    ***
   ******************************
*/

class FileWrapper {
public:
  virtual bool findTable(const char* tableName,
       size_t& cols, size_t& rows) =0;
  virtual void readTable(double *buf, size_t rows, size_t cols) =0;
  virtual void close() =0;

  static FileWrapper* openFile(const std::string& filename);
};

/* \brief Read data from text file.
  
   Text file format:
    #1
   double A(2,2) # comment here
     1 0
     0 1
   double M(3,3) # comment
     1 2 3
     3 4 5
     1 1 1
*/ 
class TextFile : public FileWrapper {
public:
  static FileWrapper* create(const std::string& fileName)
  {  return new TextFile(fileName); }
  TextFile(const std::string& fileName):filename(fileName),line(0),lnStart(0)
  {
    fp.open(filename.c_str());
    if (!fp)
      THROW("Could not open file `%s' for reading",filename.c_str());
  }
  virtual ~TextFile()
  {
    fp.close();
  }

  virtual bool findTable(const char* tableName, 
       size_t& cols, size_t& rows)
  {
    std::string strLn, tblName;
    size_t _cols, _rows;

    while (fp.good()) {
      /* start new line, update counters */
      ++line;
      lnStart= fp.tellg();

      /* read whole line */
      std::getline(fp,strLn);
      if (!fp)
  THROW("In file `%s': parsing error at line %d and col %d.",filename,line,(size_t)(fp.tellg()-lnStart));
      /* check if we read header */
      if (parseHead(strLn.data(),strLn.length(),tblName,_rows,_cols)) {
  /* is table name the one we are looking for? */
  if (tblName == tableName) {
    cols = _cols;
    rows = _rows;
    return true;
  }
      }
    }
    /* no header found */
    return false;
  }

  virtual void readTable(double *buf, size_t rows, size_t cols)
  {
    for(size_t i = 0; i < rows; ++i) {
      lnStart = fp.tellg();
      ++line;
      for(size_t j = 0; j < cols; ++j) {
  fp >> buf[i*cols+j];
  if (!fp) THROW("In file `%s': parsing error at line %d and col %d.",filename,line,(size_t)(fp.tellg()-lnStart));
      }
      fp.ignore(std::numeric_limits<std::streamsize>::max(),'\n');
    }

  }

  virtual void close()
  {
    fp.close();
    if (!fp.good())
      THROW("Could not close file `%s'.",filename.c_str());
  }
private:
  std::string filename;
  std::ifstream fp;
  size_t line;
  size_t cpos;
  std::ifstream::pos_type lnStart;

  void skipLine()
  {
    fp.ignore(std::numeric_limits<std::streamsize>::max(),'\n');
    ++line;
    lnStart = fp.tellg();
  }

  bool parseHead(const char* hdr, size_t hdrLen, std::string& name,
     size_t& rows, size_t& cols) const
  {
    char* endptr;
    size_t hLen = hdrLen;

    trim(hdr,hLen);
    
    if (strncmp("double",hdr,std::min((size_t)6,hLen)) != 0)
      return false;
    trim(hdr += 6, hLen -= 6);

    for(size_t len = 1; len < hLen; ++len)
      if (isspace(hdr[len]) || hdr[len] == '(') {
  name.assign(hdr,len);
  hdr += len;
  hLen -= len;
  break;
      }
    if (!readChr(hdr,hLen,'('))
      THROW("In file `%s': parsing error at line %d and col %d.",filename,line,hdrLen-hLen);
    rows = (size_t)strtol(hdr,&endptr,10);
    if (hdr == endptr)
      THROW("In file `%s': parsing error at line %d and col %d.",filename,line,hdrLen-hLen);
    hLen -= endptr-hdr;
    hdr = endptr;
    if (!readChr(hdr,hLen,','))
      THROW("In file `%s': parsing error at line %d and col %d.",filename,line,hdrLen-hLen);
    cols = (size_t)strtol(hdr,&endptr,10);
    if (hdr == endptr)
      THROW("In file `%s': parsing error at line %d and col %d.",filename,line,hdrLen-hLen);
    hLen -= endptr-hdr;
    hdr = endptr;
    readChr(hdr,hLen,')');
    
    if (hLen > 0 && *hdr != '#')
      THROW("In file `%s': parsing error at line %d and col %d.",filename,line,hdrLen-hLen);

    return true;
  }
  inline void trim(const char* &ptr, size_t& len) const
  {
    for(; len > 0; ++ptr, --len)
      if (!isspace(*ptr)) return;
  }
  inline bool readChr(const char* &ptr, size_t& len, char chr) const
  {
    trim(ptr,len);
    if (len-- > 0 && *(ptr++) != chr)
      return false;
    trim(ptr,len);
    return true;
  }
};


class MatFile : public FileWrapper {
public:
  static FileWrapper* create(const std::string& fileName)
  { 
    return new MatFile(fileName);
  }
  MatFile(const std::string& fileName):filename(fileName)
  {
    memset(&hdr,0,sizeof(hdr_t));
    fp.open(filename.c_str(),std::ios::in|std::ios::binary);
    if (!fp)
      THROW("Could not open file `%s' for reading.",filename.c_str());
  }
  virtual ~MatFile() {
    fp.close();
  }
  bool findTable(const char* tableName, size_t& cols, size_t& rows)
  {
    char name[256];
    long pos;
    while (!fp.eof()) {
      fp.read((char*)&hdr,sizeof(hdr));
      if (!fp.good())
  THROW("Could not read from file `%s'.",filename.c_str());
      fp.read(name,std::min(hdr.namelen,(long)256));
      if (strncmp(tableName,name,strlen(tableName)) == 0) {
  if (hdr.type%10 != 0 || hdr.type/1000 > 1)
    THROW("Table `%s' not in supported format.",tableName);
  if (hdr.mrows <= 0 || hdr.ncols <= 0)
    THROW("Table `%s' has zero dimensions.",tableName);
  rows = hdr.mrows;
  cols = hdr.ncols;
  return true;
      }
      pos = fp.tellg();
      fp.seekg(pos+hdr.mrows*hdr.ncols*getTypeSize(hdr.type)*(hdr.imagf?2:1));
    }
    return false;
  }
  void readTable(double *buf, size_t rows, size_t cols)
  {
    elem_t readbuf;
    long P = (hdr.type%1000)/100;
    bool isBigEndian = (hdr.type/1000) == 1;
    size_t elemSize = getTypeSize(hdr.type);

    for(size_t i=0; i < rows; ++i)
      for(size_t j=0; j < cols; ++j) {
  fp.read(readbuf.p,elemSize);
  if (!fp.good())
    THROW("Could not read from file `%s'.",filename.c_str());
  buf[i*cols+j] = getElem(readbuf,P,isBigEndian);
      }
  }
  void close() 
  {
    fp.close();
  }
private:
  typedef struct {
    long type;
    long mrows;
    long ncols;
    long imagf;
    long namelen;
  } hdr_t;
  typedef union {
    char p[8];
    double d;
    float f;
    int i;
    short s;
    unsigned short us;
    unsigned char c;
  } elem_t;
  std::string filename;
  std::ifstream fp;
  hdr_t hdr;
  size_t getTypeSize(long type) const
  {
    switch((type%1000)/100) {
    case 0:
      return sizeof(double);
    case 1:
      return sizeof(float);
    case 2:
      return 4;
    case 3:
    case 4:
      return 2;
    case 5:
      return 1;
    default:
      THROW("Corrupted MAT-file: `%s'",filename.c_str());
    }
  }
  double getElem(elem_t& num, char type, bool dataEndianness)
  {
    switch(type) {
    case 0:
      return correctEndianness(num.d,dataEndianness);
    case 1:
      return correctEndianness(num.f,dataEndianness);
    case 2:
      return correctEndianness(num.i,dataEndianness);
    case 3:
      return correctEndianness(num.s,dataEndianness);
    case 4:
      return correctEndianness(num.us,dataEndianness);
    default:
      return correctEndianness(num.c,dataEndianness);
    }
  }
  template<typename num_t>
  inline num_t correctEndianness(num_t _num, bool dataEndianness) {
    if (getEndianness() != dataEndianness) {
      union {
  num_t num;
  unsigned char b[sizeof(num_t)];
      } dat1, dat2;
      dat1.num = _num;
      for(size_t i=0; i < sizeof(num_t); ++i)
  dat2.b[i] = dat1.b[sizeof(num_t)-i-1];
      return dat2.num;
    }
    return _num;
  }
  inline static bool getEndianness()
  {
    const int endian_test = 1;
    return ((*(char*)&endian_test) == 0);
  }
};

class CSVFile : public FileWrapper {
public:
  static FileWrapper* create(const std::string& fileName)
  { 
    THROW("Loading tables from CSV files not supported.");
    return NULL;
  }
};

FileWrapper *FileWrapper::openFile(const std::string& filename)
{
  static const std::pair<const char*,FileWrapper* (*)(const std::string&)> 
    fileFormats[3] = {
    std::make_pair(".txt",&TextFile::create),
    std::make_pair(".mat",&MatFile::create),
    std::make_pair(".csv",&CSVFile::create)
  };
  FileWrapper *fptr;
  std::string fileExt = filename.substr(filename.rfind('.'));

  for (int i = 0; i < 3; ++i)
    if (fileExt == fileFormats[i].first) {
      fptr = fileFormats[i].second(filename);
      if (!fptr) 
  THROW("Could not allocate memory to read file `%s'",
        filename.c_str());
      return (fptr);
    }
  THROW("Interpolation table: uknown file extension -- `%s'.",
        fileExt.c_str());
  return NULL;
}

/*
   implementation of InterpolationTable methods
*/
InterpolationTable* InterpolationTable_init(double time, double startTime,
               int ipoType, int expoType,
               const char* tableName, const char* fileName, 
               const double* table, int tableDim1,
               int tableDim2, int colWise)
{
  size_t i=0;
  size_t l=0;
  size_t size = tableDim1*tableDim2;
  InterpolationTable *tpl = 0;
  tpl = (InterpolationTable*)calloc(1,sizeof(InterpolationTable));
  ASSERT(tpl,"Not enough memory for Table: %s",tableName);

  tpl->rows = tableDim1;
  tpl->cols = tableDim2;
  tpl->colWise = colWise;
  tpl->ipoType = ipoType;
  tpl->expoType = expoType;
  tpl->startTime = startTime;

  if (tableName)
  {
    l = strlen(tableName);
    tpl->tablename = (char*)calloc(1,l+1);
    ASSERT(tpl->tablename,"Not enough memory for Table: %s",tableName);
    for (i=0;i<l;i++)
    {
      tpl->tablename[i] = tableName[i];
    }
  }

  if (fileName && strncmp("NoName",fileName,6) != 0) 
  {
    l = strlen(fileName);
    tpl->filename = (char*)calloc(1,l+1);
    ASSERT(tpl->filename,"Not enough memory for Table: %s",tableName);
    for (i=0;i<l;i++)
    {
      tpl->filename[i] = fileName[i];
    }
    
    std::auto_ptr<FileWrapper> file(FileWrapper::openFile(fileName));
    
    if (file->findTable(tableName,tpl->cols,tpl->rows)) 
    {
      tpl->data = (double*)calloc(size,sizeof(double));
      ASSERT(tpl->data,"Not enough memory for Table: %s",tableName);
      tpl->own_data = 1;
      
      file->readTable(tpl->data,tpl->rows,tpl->cols);
      file->close();
    } else 
    {
      THROW("No table named `%s' in file `%s'.",tableName,fileName);
    }
  } else 
  {
    tpl->data = (double*)calloc(size,sizeof(double));
    ASSERT(tpl->data,"Not enough memory for Table: %s",tableName);
    tpl->own_data = 1;

    for (i=0;i<size;i++)
    {
      tpl->data[i] = table[i];
    }
  }
  /* check that time column is strictly monotonous */
  InterpolationTable_checkValidityOfData(tpl);
  return tpl;
}

void InterpolationTable_deinit(InterpolationTable **tpl)
{
  if (tpl)
  {
    if ((*tpl)->own_data)
      free((*tpl)->data);
    free(*tpl);
    *tpl = NULL;
  }
}

double InterpolationTable_interpolate(InterpolationTable *tpl, double time, size_t col)
{
  size_t i = 0;
  size_t lastIdx = tpl->colWise ? tpl->cols : tpl->rows;

  if (!tpl->data) return 0.0;

  /* substract time offset */
  /*fprintf(stderr, "time %g startTime %g\n", time, startTime); */
  
  if (time < InterpolationTable_minTime(tpl))
    return InterpolationTable_extrapolate(tpl,time,col,time <= InterpolationTable_minTime(tpl));

  for(i = 0; i < lastIdx; ++i) {
    /* fprintf(stderr, "getElt: %d %g->%g\n", i, getElt(i,0), getElt(i,1)); */
    if (InterpolationTable_getElt(tpl,i,0) > time) {
      return InterpolationTable_interpolateLin(tpl,time, i-1,col);
    }
  }
  return InterpolationTable_extrapolate(tpl,time,col,time <= InterpolationTable_minTime(tpl));
}

double InterpolationTable_maxTime(InterpolationTable *tpl) 
{ 
  return (tpl->data?InterpolationTable_getElt(tpl,tpl->rows-1,0):0.0); 
}
double InterpolationTable_minTime(InterpolationTable *tpl) 
{ 
  return (tpl->data?tpl->data[0]:0.0); 
}

char InterpolationTable_compare(InterpolationTable *tpl, const char* fname, const char* tname,
         const double* table)
{
  if (fname == NULL || tname == NULL) return 0;
  if (strncmp("NoName",fname,6) == 0 && strncmp("NoName",tname,6) == 0)
  {
    /* table passed as memory location */
    return (tpl->data == table);
  }
  else
  {
    /* table loaded from file */
    return (tpl->filename == fname && tpl->tablename == tname);
  return 0;
  }
}
double InterpolationTable_extrapolate(InterpolationTable *tpl, double time, size_t col, 
               bool beforeData)
{
  size_t lastIdx;

  switch(tpl->expoType) {
  case 1:
    /* hold last/first value */
    return InterpolationTable_getElt(tpl,(beforeData ? 0 :tpl->rows-1),col);
  case 2:
    /* extrapolate through first/last two values */
    lastIdx = (tpl->colWise ? tpl->cols : tpl->rows) - 2;
    return InterpolationTable_interpolateLin(tpl,time,(beforeData?0:lastIdx),col);
  case 3:
    /* periodically repeat signal */
    time = tpl->startTime + (time - InterpolationTable_maxTime(tpl)*floor(time/InterpolationTable_maxTime(tpl)));
    return InterpolationTable_interpolate(tpl,time,col);
  default:
    return 0.0;
  }
}
double InterpolationTable_interpolateLin(InterpolationTable *tpl, double time, size_t i, size_t j)
{
  double t_1 = InterpolationTable_getElt(tpl,i,0);
  double t_2 = InterpolationTable_getElt(tpl,i+1,0);
  double y_1 = InterpolationTable_getElt(tpl,i,j);
  double y_2 = InterpolationTable_getElt(tpl,i+1,j);
  /*if (std::abs(t_2-t_1) < 100.0*std::numeric_limits<double>::epsilon())
    return y_1;
    else
  */
  return (y_1 + ((time-t_1)/(t_2-t_1)) * (y_2-y_1));
}

const double InterpolationTable_getElt(InterpolationTable *tpl, size_t row, size_t col)
{
  ASSERT(row < tpl->rows && col < tpl->cols,"In Table: %s from File: %s with Size[%d,%d] try to get Element[%d,$d] aut of range!", tpl->tablename, tpl->filename, tpl->rows, tpl->cols, row,col);
  return tpl->data[tpl->colWise ? col*tpl->rows+row : row*tpl->cols+col];
}
void InterpolationTable_checkValidityOfData(InterpolationTable *tpl)
{
  size_t i = 0;
  size_t maxSize = tpl->colWise ? tpl->cols : tpl->rows;
  for(i = 1; i < maxSize; ++i)
    if (InterpolationTable_getElt(tpl,i-1,0) > InterpolationTable_getElt(tpl,i,0))
      THROW("TimeTable: Column with time variable not monotonous: %g >= %g.", InterpolationTable_getElt(tpl,i-1,0),InterpolationTable_getElt(tpl,i,0));
}


/*
  interpolation 2D
*/
InterpolationTable2D* InterpolationTable2D_init(int ipoType, const char* tableName,
           const char* fileName, const double *table,
           int tableDim1, int tableDim2, int colWise)
{
  size_t i=0;
  size_t l=0;
  size_t size = tableDim1*tableDim2;
  InterpolationTable2D *tpl = 0;
  tpl = (InterpolationTable2D*)calloc(1,sizeof(InterpolationTable2D));
  ASSERT(tpl,"Not enough memory for Table: %s",tableName);

  tpl->rows = tableDim1;
  tpl->cols = tableDim2;
  tpl->colWise = colWise;

  if (tableName)
  {
    l = strlen(tableName);
    tpl->tablename = (char*)calloc(1,l+1);
    ASSERT(tpl->tablename,"Not enough memory for Table: %s",tableName);
    for (i=0;i<l;i++)
    {
      tpl->tablename[i] = tableName[i];
    }
  }

  if (fileName && strncmp("NoName",fileName,6) != 0) 
  {
    l = strlen(fileName);
    tpl->filename = (char*)calloc(1,l+1);
    ASSERT(tpl->filename,"Not enough memory for Table: %s",tableName);
    for (i=0;i<l;i++)
    {
      tpl->filename[i] = fileName[i];
    }
    
    std::auto_ptr<FileWrapper> file(FileWrapper::openFile(fileName));
    
    if (file->findTable(tableName,tpl->cols,tpl->rows)) 
    {
      tpl->data = (double*)calloc(size,sizeof(double));
      ASSERT(tpl->data,"Not enough memory for Table: %s",tableName);
      tpl->own_data = 1;

      file->readTable(tpl->data,tpl->rows,tpl->cols);
      file->close();
    } else {
      THROW("No table named `%s' in file `%s'.",tableName,fileName);
    }
  } else {
    tpl->data = (double*)calloc(size,sizeof(double));
    ASSERT(tpl->data,"Not enough memory for Table: %s",tableName);
    tpl->own_data = 1;

    for (i=0;i<size;i++)
    {
      tpl->data[i] = table[i];
    }
  }
  /* check if table is valid */
  InterpolationTable2D_checkValidityOfData(tpl);
  return tpl;
}

void InterpolationTable2D_deinit(InterpolationTable2D **table)
{
  if (table)
  {
    if ((*table)->own_data)
      free((*table)->data);
    free(*table);
    *table = NULL;
  }
}

double InterpolationTable2D_interpolate(InterpolationTable2D *table, double x1, double x2)
{
  size_t i, j;
  double f_1, f_2;
  if (table->colWise)
  {
    double tmp = x1;
    x1 = x2;
    x1 = tmp;
  }

  /* if out of boundary, just set to min/max */
  x1 = fmin(fmax(x1,InterpolationTable2D_getElt(table,1,0)),InterpolationTable2D_getElt(table,table->rows-1,0));
  x2 = fmin(fmax(x2,InterpolationTable2D_getElt(table,0,1)),InterpolationTable2D_getElt(table,0,table->cols-1));

  /* find intervals corresponding x1 and x2 */
  for(i = 2; i < table->rows; ++i)
    if (InterpolationTable2D_getElt(table,i,0) >= x1) break;
  for(j = 2; j < table->cols; ++j)
    if (InterpolationTable2D_getElt(table,0,j) >= x2) break;
  
  /* bilinear interpolation */
  f_1 = InterpolationTable2D_linInterpolate(x1,InterpolationTable2D_getElt(table,i-1,0),InterpolationTable2D_getElt(table,i,0),InterpolationTable2D_getElt(table,i-1,j-1),InterpolationTable2D_getElt(table,i,j-1));
  f_2 = InterpolationTable2D_linInterpolate(x1,InterpolationTable2D_getElt(table,i-1,0),InterpolationTable2D_getElt(table,i,0),InterpolationTable2D_getElt(table,i-1,j),InterpolationTable2D_getElt(table,i,j));
  return InterpolationTable2D_linInterpolate(x2,InterpolationTable2D_getElt(table,0,j-1),InterpolationTable2D_getElt(table,0,j),f_1,f_2);
}

char InterpolationTable2D_compare(InterpolationTable2D *tpl, const char* fname, const char* tname, const double* table) 
{
  if (fname == NULL || tname == NULL) return 0;
  if (strncmp("NoName",fname,6) == 0 && strncmp("NoName",tname,6) == 0)
  {
    /* table passed as memory location */
    return (tpl->data == table);
  }
  else
  {
    /* table loaded from file */
    return (tpl->filename == fname && tpl->tablename == tname);
  }
  return 0;
}

double InterpolationTable2D_linInterpolate(double x, double x_1, double x_2,
              double f_1, double f_2) 
{
  return ((x_2 - x)*f_1 + (x - x_1)*f_2) / (x_2-x_1);
}
const double InterpolationTable2D_getElt(InterpolationTable2D *tpl, size_t row, size_t col)
{
  ASSERT(row < tpl->rows && col < tpl->cols,"In Table: %s from File: %s with Size[%d,%d] try to get Element[%d,$d] aut of range!", tpl->tablename, tpl->filename, tpl->rows, tpl->cols, row,col);
  return tpl->data[row*tpl->cols+col];
}

void InterpolationTable2D_checkValidityOfData(InterpolationTable2D *tpl) 
{
  size_t i = 0;
  /* check that first row and column are strictly monotonous */
  for(i=2; i < tpl->rows; ++i)
  {
    if (InterpolationTable2D_getElt(tpl,i-1,0) >= InterpolationTable2D_getElt(tpl,i,0))
      THROW("Table: %s independent variable u1 not strictly \
            monotonous: %g >= %g.",tpl->tablename, InterpolationTable2D_getElt(tpl,i-1,0), InterpolationTable2D_getElt(tpl,i,0));
  for(size_t i=2; i < tpl->cols; ++i)
    if (InterpolationTable2D_getElt(tpl,0,i-1) >= InterpolationTable2D_getElt(tpl,0,i))
      THROW("Table: %s independent variable u2 not strictly \
            monotonous: %g >= %g.",tpl->tablename, InterpolationTable2D_getElt(tpl,0,i-1), InterpolationTable2D_getElt(tpl,0,i));
  }
}


