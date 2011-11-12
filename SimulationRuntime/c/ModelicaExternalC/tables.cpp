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

void openFile(const char *filename, const char* tableName, size_t rows, size_t cols, double *data);


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

typedef struct TEXT_FILE
{
  std::ifstream fp;
  size_t line;
  size_t cpos;
  std::ifstream::pos_type lnStart;
  char *filename;
} TEXT_FILE;

TEXT_FILE *Text_open(const char *filename)
{
  size_t l,i;
  TEXT_FILE *f=(TEXT_FILE*)calloc(1,sizeof(TEXT_FILE));
  l = strlen(filename);
  f->filename = (char*)calloc(1,l+1);
  ASSERT(f->filename,"Not enough memory for Filename %s",filename);
  for (i=0;i<l;i++)
  {
    f->filename[i] = filename[i];
  }
  f->fp.open(filename);
  return f;
}

void Text_close(TEXT_FILE *f)
{
  if (f)
  {
    if (f->filename)
      free(f->filename);
    f->fp.close();
    free(f);
  }
}

void skipLine(TEXT_FILE *f)
{
  f->fp.ignore(std::numeric_limits<std::streamsize>::max(),'\n');
  ++f->line;
  f->lnStart = f->fp.tellg();
}

inline void trim(const char* &ptr, size_t& len)
{
  for(; len > 0; ++ptr, --len)
    if (!isspace(*ptr)) return;
}
inline bool readChr(const char* &ptr, size_t& len, char chr)
{
  trim(ptr,len);
  if (len-- > 0 && *(ptr++) != chr)
    return false;
  trim(ptr,len);
  return true;
}

bool parseHead(TEXT_FILE *f, const char* hdr, size_t hdrLen, std::string& name,
  size_t& rows, size_t& cols)
{
  char* endptr;
  size_t hLen = hdrLen;
  size_t len = 0;

  trim(hdr,hLen);

  if (strncmp("double",hdr,std::min((size_t)6,hLen)) != 0)
    return false;
  trim(hdr += 6, hLen -= 6);

  for(len = 1; len < hLen; ++len)
    if (isspace(hdr[len]) || hdr[len] == '(') 
    {
      name.assign(hdr,len);
      hdr += len;
      hLen -= len;
      break;
    }
  if (!readChr(hdr,hLen,'('))
  {
    f->fp.close();
    THROW("In file `%s': parsing error at line %d and col %d.",f->filename,f->line,hdrLen-hLen);
  }
  rows = (size_t)strtol(hdr,&endptr,10);
  if (hdr == endptr)
  {
    f->fp.close();
    THROW("In file `%s': parsing error at line %d and col %d.",f->filename,f->line,hdrLen-hLen);
  }
  hLen -= endptr-hdr;
  hdr = endptr;
  if (!readChr(hdr,hLen,','))
  {
    f->fp.close();
    THROW("In file `%s': parsing error at line %d and col %d.",f->filename,f->line,hdrLen-hLen);
  }
  cols = (size_t)strtol(hdr,&endptr,10);
  if (hdr == endptr)
  {
    f->fp.close();
    THROW("In file `%s': parsing error at line %d and col %d.",f->filename,f->line,hdrLen-hLen);
  }
  hLen -= endptr-hdr;
  hdr = endptr;
  readChr(hdr,hLen,')');

  if (hLen > 0 && *hdr != '#')
  {
    f->fp.close();
    THROW("In file `%s': parsing error at line %d and col %d.",f->filename,f->line,hdrLen-hLen);
  }

  return true;
}

char Text_findTable(TEXT_FILE *f, const char* tableName, size_t& cols, size_t& rows)
{
  std::string strLn, tblName;
  size_t _cols, _rows;

  while (f->fp.good()) {
    /* start new line, update counters */
    ++f->line;
    f->lnStart= f->fp.tellg();

    /* read whole line */
    std::getline(f->fp,strLn);
    if (!f->fp)
    {
      f->fp.close();
      THROW("In file `%s': parsing error at line %d and col %d.",f->filename,f->line,(size_t)(f->fp.tellg()-f->lnStart));
    }
    /* check if we read header */
    if (parseHead(f,strLn.data(),strLn.length(),tblName,_rows,_cols)) {
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

void Text_readTable(TEXT_FILE *f, double *buf, size_t rows, size_t cols)
{
  size_t i = 0;
  size_t j = 0;
  for(i = 0; i < rows; ++i)
  {
    f->lnStart = f->fp.tellg();
    ++f->line;
    for(j = 0; j < cols; ++j) 
    {
      f->fp >> buf[i*cols+j];
      if (!f->fp)
      {
        f->fp.close();
        THROW("In file `%s': parsing error at line %d and col %d.",f->filename,f->line,(size_t)(f->fp.tellg()-f->lnStart));
      }
    }
    f->fp.ignore(std::numeric_limits<std::streamsize>::max(),'\n');
  }

}

/*
  Mat File implementation
*/
typedef struct {
  long type;
  long mrows;
  long ncols;
  long imagf;
  long namelen;
} hdr_t;

typedef struct MAT_FILE
{
  std::ifstream fp;
  hdr_t hdr;
  char *filename;
} MAT_FILE;

MAT_FILE *Mat_open(const char *filename)
{
  size_t l,i;
  MAT_FILE *f=(MAT_FILE*)calloc(1,sizeof(MAT_FILE));
  memset(&(f->hdr),0,sizeof(hdr_t));
  l = strlen(filename);
  f->filename = (char*)calloc(1,l+1);
  ASSERT(f->filename,"Not enough memory for Filename %s",filename);
  for (i=0;i<l;i++)
  {
    f->filename[i] = filename[i];
  }
  f->fp.open(filename,std::ios::in|std::ios::binary);
  return f;
}

void Mat_close(MAT_FILE *f)
{
  if (f)
  {
    if (f->filename)
      free(f->filename);
    f->fp.close();
    free(f);
  }
}

size_t Mat_getTypeSize(MAT_FILE *f, long type)
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
    f->fp.close();
    THROW("Corrupted MAT-file: `%s'",f->filename);
  }
}

char Mat_findTable(MAT_FILE *f, const char* tableName, size_t cols, size_t rows)
{
  char name[256];
  long pos=0;
  while (!f->fp.eof()) 
  {
    f->fp.read((char*)&f->hdr,sizeof(hdr_t));
    if (!f->fp.good())
    {
      f->fp.close();
      THROW("Could not read from file `%s'.",f->filename);
    }
    f->fp.read(name,fmin(f->hdr.namelen,(long)256));
    if (strncmp(tableName,name,strlen(tableName)) == 0) 
    {
      if (f->hdr.type%10 != 0 || f->hdr.type/1000 > 1)
      {
        f->fp.close();
        THROW("Table `%s' not in supported format.",tableName);
      }
      if (f->hdr.mrows <= 0 || f->hdr.ncols <= 0)
      {
        f->fp.close();
        THROW("Table `%s' has zero dimensions.",tableName);
      }
      if (f->hdr.mrows < rows || f->hdr.ncols < cols)
      {
        f->fp.close();
        THROW("Table `%s'[%d,%d] has not enough entries [%d,%d].",tableName,f->hdr.mrows,f->hdr.ncols,rows,cols);
      }
      return 1;
    }
    pos = f->fp.tellg();
    f->fp.seekg(pos+f->hdr.mrows*f->hdr.ncols*Mat_getTypeSize(f,f->hdr.type)*(f->hdr.imagf?2:1));
  }
  return 0;
}

typedef union {
  char p[8];
  double d;
  float f;
  int i;
  short s;
  unsigned short us;
  unsigned char c;
} elem_t;

#define correctEndianness(stype,type)  inline type correctEndianness_ ## stype (type _num, bool dataEndianness)  \
{ \
  if (getEndianness() != dataEndianness) \
  { \
    union \
    { \
      type num; \
      unsigned char b[sizeof(type)]; \
    } dat1, dat2; \
    dat1.num = _num; \
    for(size_t i=0; i < sizeof(type); ++i) \
      dat2.b[i] = dat1.b[sizeof(type)-i-1]; \
    return dat2.num; \
  } \
  return _num; \
} \

inline static bool getEndianness()
{
  const int endian_test = 1;
  return ((*(char*)&endian_test) == 0);
}

correctEndianness(d,double)
correctEndianness(f,float)
correctEndianness(i,int)
correctEndianness(s,short)
correctEndianness(us,unsigned short)
correctEndianness(c,unsigned char)




double Mat_getElem(elem_t& num, char type, bool dataEndianness)
{
  switch(type) {
  case 0:
    return correctEndianness_d(num.d,dataEndianness);
  case 1:
    return correctEndianness_f(num.f,dataEndianness);
  case 2:
    return correctEndianness_i(num.i,dataEndianness);
  case 3:
    return correctEndianness_s(num.s,dataEndianness);
  case 4:
    return correctEndianness_us(num.us,dataEndianness);
  default:
    return correctEndianness_c(num.c,dataEndianness);
  }
}

void Mat_readTable(MAT_FILE *f, double *buf, size_t rows, size_t cols)
{
  elem_t readbuf;
  size_t i=0;
  size_t j=0;
  long P = (f->hdr.type%1000)/100;
  char isBigEndian = (f->hdr.type/1000) == 1;
  size_t elemSize = Mat_getTypeSize(f,f->hdr.type);

  for(i=0; i < rows; ++i)
    for(j=0; j < cols; ++j) 
  {
    f->fp.read(readbuf.p,elemSize);
    if (!f->fp.good())
    {
      f->fp.close();
      THROW("Could not read from file `%s'.",f->filename);
    }
    buf[i*cols+j] = Mat_getElem(readbuf,P,isBigEndian);
  }
}

/*
  CSV File implementation
*/
typedef struct CSV_FILE
{
  std::ifstream fp;
  char *filename;
} CSV_FILE;

CSV_FILE *csv_open(const char *filename)
{
  return NULL;
}

void csv_close(CSV_FILE *f)
{;}

char csv_findTable(CSV_FILE *f, const char *tableName, size_t rows, size_t cols)
{
  return 0;
}

void csv_readTable(CSV_FILE *f, double *data, size_t rows, size_t cols)
{

}

/*
  Open specified file
*/
void openFile(const char *filename, const char* tableName, size_t rows, size_t cols, double *data)
{
  size_t i = 0;
  size_t sl = 0;
  char filetype[5] = {0};
  /* get File Type */
  sl = strlen(filename);
  filetype[3] = filename[sl-1];
  filetype[2] = filename[sl-2];
  filetype[1] = filename[sl-3];
  filetype[0] = filename[sl-4];

  /* read data from file*/
  if (strncmp(".txt",filetype,4) != 0) /* text file */
  {
    CSV_FILE *f=NULL;
    THROW("Sorry, loading tables from CSV files is not supported.");
    f = csv_open(filename);
    if (csv_findTable(f,tableName,cols,rows)) 
    {
      csv_readTable(f,data,rows,cols);
      csv_close(f);
      return;
    } 
    csv_close(f);
    THROW("No table named `%s' in file `%s'.",tableName,filename);
  } 
  else if (strncmp(".mat",filetype,4) != 0) /* mat file */
  {
    MAT_FILE *f= Mat_open(filename);
    if (Mat_findTable(f,tableName,cols,rows)) 
    {
      Mat_readTable(f,data,rows,cols);
      Mat_close(f);
      return;
    } 
    Mat_close(f);
    THROW("No table named `%s' in file `%s'.",tableName,filename);
  }
  else if (strncmp(".txt",filetype,4) != 0) /* csv file */
  {
    TEXT_FILE *f= Text_open(filename);
    if (Text_findTable(f,tableName,cols,rows)) 
    {
      Text_readTable(f,data,rows,cols);
      Text_close(f);
      return;
    } 
    Text_close(f);
    THROW("No table named `%s' in file `%s'.",tableName,filename);
  }
  THROW("Interpolation table: %s from file %s uknown file extension -- `%s'.",tableName,filename,filetype);
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

    tpl->data = (double*)calloc(size,sizeof(double));
    ASSERT(tpl->data,"Not enough memory for Table: %s",tableName);
    tpl->own_data = 1;

    openFile(fileName,tableName,tpl->cols,tpl->rows,tpl->data);
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

    tpl->data = (double*)calloc(size,sizeof(double));
    ASSERT(tpl->data,"Not enough memory for Table: %s",tableName);
    tpl->own_data = 1;

    openFile(fileName,tableName,tpl->cols,tpl->rows,tpl->data);
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


