/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * GPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs: http://www.openmodelica.org or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica
 * distribution. GNU version 3 is obtained from:
 * http://www.gnu.org/copyleft/gpl.html. The New BSD License is obtained from:
 * http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS
 * EXPRESSLY SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE
 * CONDITIONS OF OSMC-PL.
 *
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
#include <ctype.h>

#include "../omc_inline.h"
#include "../ModelicaUtilities.h"
#ifdef _MSC_VER
#include "omc_msvc.h"
#endif

/* Definition to get some Debug information if interface is called */
/* #define INFOS */

/* Definition to make a copy of the arrays */
#define COPY_ARRAYS

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

static InterpolationTable** interpolationTables=NULL;
static int ninterpolationTables=0;
static InterpolationTable2D** interpolationTables2D=NULL;
static int ninterpolationTables2D=0;

static InterpolationTable *InterpolationTable_init(double time,double startTime, int ipoType, int expoType,
         const char* tableName, const char* fileName,
         const double *table,
         int tableDim1, int tableDim2,int colWise);
/* InterpolationTable *InterpolationTable_Copy(InterpolationTable *orig); */
static void InterpolationTable_deinit(InterpolationTable *tpl);
static double InterpolationTable_interpolate(InterpolationTable *tpl, double time, size_t col);
static double InterpolationTable_maxTime(InterpolationTable *tpl);
static double InterpolationTable_minTime(InterpolationTable *tpl);
static char InterpolationTable_compare(InterpolationTable *tpl, const char* fname, const char* tname, const double* table);

static double InterpolationTable_extrapolate(InterpolationTable *tpl, double time, size_t col, char beforeData);
static inline double InterpolationTable_interpolateLin(InterpolationTable *tpl, double time, size_t i, size_t j);
static inline double InterpolationTable_interpolateSpline(InterpolationTable *tpl, double time, size_t i, size_t j);
static inline const double InterpolationTable_getElt(InterpolationTable *tpl, size_t row, size_t col);
static void InterpolationTable_checkValidityOfData(InterpolationTable *tpl);


static InterpolationTable2D *InterpolationTable2D_init(int ipoType, const char* tableName,
           const char* fileName, const double *table,
           int tableDim1, int tableDim2, int colWise);
static void InterpolationTable2D_deinit(InterpolationTable2D *table);
static double InterpolationTable2D_interpolate(InterpolationTable2D *tpl, double x1, double x2);
static char InterpolationTable2D_compare(InterpolationTable2D *tpl, const char* fname, const char* tname, const double* table);
static double InterpolationTable2D_linInterpolate(double x, double x_1, double x_2, double f_1, double f_2);
static const double InterpolationTable2D_getElt(InterpolationTable2D *tpl, size_t row, size_t col);
static void InterpolationTable2D_checkValidityOfData(InterpolationTable2D *tpl);



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


int omcTableTimeIni(double timeIn, double startTime,int ipoType,int expoType,
        const char *tableName, const char* fileName,
        const double *table,int tableDim1, int tableDim2,int colWise)
{
  int i = 0;
  InterpolationTable** tmp = NULL;
#ifdef INFOS
  INFO10("Init Table \n timeIn %f \n startTime %f \n ipoType %d \n expoType %d \n tableName %s \n fileName %s \n table %p \n tableDim1 %d \n tableDim2 %d \n colWise %d", timeIn, startTime, ipoType, expoType, tableName, fileName, table, tableDim1, tableDim2, colWise);
#endif
  /* if table is already initialized, find it */
  for(i = 0; i < ninterpolationTables; ++i)
    if(InterpolationTable_compare(interpolationTables[i],fileName,tableName,table))
    {
#ifdef INFOS
      infoStreamPrint("Table id = %d",i);
#endif
      return i;
    }
#ifdef INFOS
  infoStreamPrint("Table id = %d",ninterpolationTables);
#endif
  /* increase array */
  tmp = (InterpolationTable**)malloc((ninterpolationTables+1)*sizeof(InterpolationTable*));
  if (!tmp) {
    ModelicaFormatError("Not enough memory for new Table[%lu] Tablename %s Filename %s", (unsigned long)ninterpolationTables, tableName, fileName);
  }
  for(i = 0; i < ninterpolationTables; ++i)
  {
    tmp[i] = interpolationTables[i];
  }
  free(interpolationTables);
  interpolationTables = tmp;
  ninterpolationTables++;
  /* otherwise initialize new table */
  interpolationTables[ninterpolationTables-1] = InterpolationTable_init(timeIn,startTime,
                   ipoType,expoType,
                   tableName, fileName,
                   table, tableDim1,
                   tableDim2, colWise);
  return (ninterpolationTables-1);
}


void omcTableTimeIpoClose(int tableID)
{
#ifdef INFOS
  infoStreamPrint("Close Table[%d]",tableID);
#endif
  if(tableID >= 0 && tableID < (int)ninterpolationTables)
  {
    InterpolationTable_deinit(interpolationTables[tableID]);
    interpolationTables[tableID] = NULL;
    ninterpolationTables--;
  }
  if(ninterpolationTables <=0)
    free(interpolationTables);
}


double omcTableTimeIpo(int tableID, int icol, double timeIn)
{
#ifdef INFOS
  infoStreamPrint("Interpolate Table[%d][%d] add Time %f",tableID,icol,timeIn);
#endif
  if(tableID >= 0 && tableID < (int)ninterpolationTables)
  {
    return InterpolationTable_interpolate(interpolationTables[tableID],timeIn,icol-1);
  }
  else
    return 0.0;
}


double omcTableTimeTmax(int tableID)
{
#ifdef INFOS
  infoStreamPrint("Time max from Table[%d]",tableID);
#endif
  if(tableID >= 0 && tableID < (int)ninterpolationTables)
    return InterpolationTable_maxTime(interpolationTables[tableID]);
  else
    return 0.0;
}


double omcTableTimeTmin(int tableID)
{
#ifdef INFOS
  infoStreamPrint("Time min from Table[%d]",tableID);
#endif
  if(tableID >= 0 && tableID < (int)ninterpolationTables)
    return InterpolationTable_minTime(interpolationTables[tableID]);
  else
    return 0.0;
}


int omcTable2DIni(int ipoType, const char *tableName, const char* fileName,
      const double *table,int tableDim1,int tableDim2,int colWise)
{
  int i=0;
  InterpolationTable2D** tmp = NULL;
#ifdef INFOS
  infoStreamPrint("Init Table \n ipoType %f \n tableName %f \n fileName %d \n table %p \n tableDim1 %d \n tableDim2 %d \n colWise %d", ipoType, tableName, fileName, table, tableDim1, tableDim2, colWise);
#endif
  /* if table is already initialized, find it */
  for(i = 0; i < ninterpolationTables2D; ++i)
    if(InterpolationTable2D_compare(interpolationTables2D[i],fileName,tableName,table))
    {
#ifdef INFOS
      infoStreamPrint("Table id = %d",i);
#endif
      return i;
    }
#ifdef INFOS
  infoStreamPrint("Table id = %d",ninterpolationTables2D);
#endif
  /* increase array */
  tmp = (InterpolationTable2D**)malloc((ninterpolationTables2D+1)*sizeof(InterpolationTable2D*));
  if (!tmp) {
    ModelicaFormatError("Not enough memory for new Table[%lu] Tablename %s Filename %s", (unsigned long)ninterpolationTables, tableName, fileName);
  }
  for(i = 0; i < ninterpolationTables2D; ++i)
  {
    tmp[i] = interpolationTables2D[i];
  }
  free(interpolationTables2D);
  interpolationTables2D = tmp;
  ninterpolationTables2D++;
  /* otherwise initialize new table */
  interpolationTables2D[ninterpolationTables2D-1] = InterpolationTable2D_init(ipoType,tableName,
                      fileName,table,tableDim1,tableDim2,colWise);
  return (ninterpolationTables2D-1);
}


void omcTable2DIpoClose(int tableID)
{
#ifdef INFOS
  infoStreamPrint("Close Table[%d]",tableID);
#endif
  if(tableID >= 0 && tableID < (int)ninterpolationTables2D)
  {
    InterpolationTable2D_deinit(interpolationTables2D[tableID]);
    interpolationTables2D[tableID] = NULL;
    ninterpolationTables2D--;
  }
  if(ninterpolationTables2D <=0)
    free(interpolationTables2D);
}


double omcTable2DIpo(int tableID,double u1_, double u2_)
{
#ifdef INFOS
  infoStreamPrint("Interpolate Table[%d][%d] add Time %f",tableID,u1_,u2_);
#endif
  if(tableID >= 0 && tableID < (int)ninterpolationTables2D)
    return InterpolationTable2D_interpolate(interpolationTables2D[tableID], u1_, u2_);
  else
    return 0.0;
}

/* ******************************
   ***    IMPLEMENTATION    ***
   ******************************
*/

static void openFile(const char *filename, const char* tableName, size_t *rows, size_t *cols, double **data);


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
  FILE *fp;
  size_t line;
  size_t cpos;
  fpos_t *lnStart;
  char *filename;
} TEXT_FILE;

static TEXT_FILE *Text_open(const char *filename)
{
  TEXT_FILE *f=(TEXT_FILE*)calloc(1,sizeof(TEXT_FILE));
  if (!f) {
    ModelicaFormatError("Not enough memory for Filename: %s",filename);
  }
  else
  {
    size_t l = strlen(filename);
    f->filename = (char*)malloc((l+1)*sizeof(char));
    if (!f->filename) {
      ModelicaFormatError("Not enough memory for Filename: %s",filename);
    }
    else
    {
      size_t i;
      for(i=0;i<=l;i++) {
        f->filename[i] = filename[i];
      }
      f->fp = fopen(filename,"r");
      if (!f->fp) {
        ModelicaFormatError("Cannot open File %s",filename);
      }
    }
  }
  return f;
}

static void Text_close(TEXT_FILE *f)
{
  if(f)
  {
    if(f->filename)
      free(f->filename);
    fclose(f->fp);
    free(f);
  }
}

static void trim(const char **ptr, size_t *len)
{
  for(; *len > 0; ++(*ptr), --(*len))
    if(!isspace(*(*ptr))) return;
}

static char readChr(const char **ptr, size_t *len, char chr)
{
  trim(ptr,len);
  if((*len)-- > 0 && *((*ptr)++) != chr)
    return 0;
  trim(ptr,len);
  return 1;
}

static char parseHead(TEXT_FILE *f, const char* hdr, size_t hdrLen, const char **name,
               size_t *rows, size_t *cols)
{
  char* endptr;
  size_t hLen = hdrLen;
  size_t len = 0;

  trim(&hdr, &hLen);

  if(strncmp("double", hdr, fmin((size_t)6, hLen)) != 0)
    return 0;
  hdr += 6;
  hLen -= 6;
  trim(&hdr, &hLen);

  for(len = 1; len < hLen; ++len)
    if(isspace(hdr[len]) || hdr[len] == '(')
    {
      *name = hdr;
      hdr += len;
      hLen -= len;
      break;
    }
  if(!readChr(&hdr, &hLen, '('))
  {
    fclose(f->fp);
    ModelicaFormatError("In file `%s': parsing error at line %lu and col %lu.", f->filename, (unsigned long)f->line, (unsigned long)(hdrLen-hLen));
  }
  *rows = (size_t)strtol(hdr, &endptr, 10);
  if(hdr == endptr)
  {
    fclose(f->fp);
    ModelicaFormatError("In file `%s': parsing error at line %lu and col %lu.", f->filename, (unsigned long)f->line, (unsigned long)(hdrLen-hLen));
  }
  hLen -= endptr-hdr;
  hdr = endptr;
  if(!readChr(&hdr, &hLen, ','))
  {
    fclose(f->fp);
    ModelicaFormatError("In file `%s': parsing error at line %lu and col %lu.", f->filename, (unsigned long)f->line, (unsigned long)(hdrLen-hLen));
  }
  *cols = (size_t)strtol(hdr, &endptr, 10);
  if(hdr == endptr)
  {
    fclose(f->fp);
    ModelicaFormatError("In file `%s': parsing error at line %lu and col %lu.", f->filename, (unsigned long)f->line, (unsigned long)(hdrLen-hLen));
  }
  hLen -= endptr-hdr;
  hdr = endptr;
  readChr(&hdr, &hLen, ')');

  if((hLen > 0) && ((*hdr) != '#'))
  {
    fclose(f->fp);
    ModelicaFormatError("In file `%s': parsing error at line %lu and col %lu.", f->filename, (unsigned long)f->line, (unsigned long)(hdrLen-hLen));
  }

  return 1;
}

static size_t Text_readLine(TEXT_FILE *f, char **data, size_t *size)
__attribute__((nonnull));

static size_t Text_readLine(TEXT_FILE *f, char **data, size_t *size)
{
  size_t col = 0;
  size_t i = 0;
  char *buf = *data;
  memset(*data, 0, sizeof(char)*(*size));

  /* read whole line */
  while(!feof(f->fp))
  {
    int ch;
    if(col >= *size)
    {
      size_t s = *size * 2 + 1024;
      char *tmp = (char*)calloc(s, sizeof(char));
      if (!tmp) {
        ModelicaFormatError("Not enough memory for loading file %s",f->filename);
      }
      for(i = 0; i < *size; i++)
        tmp[i] = buf[i];
      if(buf)
        free(buf);
      *data = tmp;
      buf = *data;
      *size = s;
    }
    ch = fgetc(f->fp);
    if(ferror(f->fp))
    {
      fclose(f->fp);
      ModelicaFormatError("In file `%s': parsing error at line %lu and col %lu.", f->filename, (unsigned long)f->line, (unsigned long)col);
    }
    if(ch == '\n')
      break;
    buf[col] = ch;
    col++;
  }
  return col;
}

static char Text_findTable(TEXT_FILE *f, const char* tableName, size_t *cols, size_t *rows)
{
  char *strLn=0;
  const char *tblName=0;
  size_t buflen=0;
  size_t _cols = 0;
  size_t _rows = 0;

  while(!feof(f->fp))
  {
    size_t col;
    /* start new line, update counters */
    ++f->line;
    /* read whole line */
    col = Text_readLine(f,&strLn,&buflen);
    /* check if we read header */
    if(parseHead(f,strLn,col,&tblName,&_rows,&_cols))
    {
      /* is table name the one we are looking for? */
      if(strncmp(tblName,tableName,strlen(tableName))==0)
      {
        *cols = _cols;
        *rows = _rows;
        if(strLn)
          free(strLn);
        return 1;
      }
    }
  }
  /* no header found */
  if(strLn)
    free(strLn);
  return 0;
}

static void Text_readTable(TEXT_FILE *f, double *buf, size_t rows, size_t cols)
{
  size_t i = 0;
  size_t j = 0;
  char *strLn=0;
  size_t buflen=0;
  char *entp = 0;
  for(i = 0; i < rows; ++i)
  {
    size_t sl;
    char *number;
    ++f->line;
    sl = Text_readLine(f,&strLn,&buflen);
    number = strLn;
    for(j = 0; j < cols; ++j)
    {
      /* remove sufix whitespaces */
      buf[i*cols+j] = strtod(number,&entp);
      /* move to next number */
      number = entp;
    }
  }
  if(strLn)
    free(strLn);

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
  FILE *fp;
  hdr_t hdr;
  char *filename;
} MAT_FILE;

static MAT_FILE *Mat_open(const char *filename)
{
  size_t l,i;
  MAT_FILE *f=(MAT_FILE*)calloc(1,sizeof(MAT_FILE));
  if (!f) {
    ModelicaFormatError("Not enough memory for Filename %s",filename);
  }
  memset(&(f->hdr),0,sizeof(hdr_t));
  l = strlen(filename);
  f->filename = (char*)malloc((l+1)*sizeof(char));
  if (!f->filename) {
    ModelicaFormatError("Not enough memory for Filename %s",filename);
  }
  for(i=0;i<=l;i++)
  {
    f->filename[i] = filename[i];
  }
  f->fp = fopen(filename,"rb");
  if (!f->fp) {
    ModelicaFormatError("Cannot open File %s",filename);
  }
  return f;
}

static void Mat_close(MAT_FILE *f)
{
  if(f)
  {
    if(f->filename)
      free(f->filename);
    fclose(f->fp);
    free(f);
  }
}

static size_t Mat_getTypeSize(MAT_FILE *f, long type)
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
    fclose(f->fp);
    ModelicaFormatError("Corrupted MAT-file: `%s'",f->filename);
    return 0; /* Cannot reach this */
  }
}

static char Mat_findTable(MAT_FILE *f, const char* tableName, size_t *cols, size_t *rows)
{
  char name[256];
  while(!feof(f->fp))
  {
    long pos;

    char * returnTmp = fgets((char*)&f->hdr,sizeof(hdr_t),f->fp);
    if(ferror(f->fp))
    {
      fclose(f->fp);
      ModelicaFormatError("Could not read from file `%s'.",f->filename);
    }
    returnTmp = fgets(name,fmin(f->hdr.namelen,(long)256),f->fp);
    if(strncmp(tableName,name,strlen(tableName)) == 0)
    {
      if(f->hdr.type%10 != 0 || f->hdr.type/1000 > 1)
      {
        fclose(f->fp);
        ModelicaFormatError("Table `%s' not in supported format.",tableName);
      }
      if(f->hdr.mrows <= 0 || f->hdr.ncols <= 0)
      {
        fclose(f->fp);
        ModelicaFormatError("Table `%s' has zero dimensions.",tableName);
      }
      if(f->hdr.mrows <= 0 || f->hdr.ncols <= 0)
      {
        fclose(f->fp);
        ModelicaFormatError("Table `%s' has zero dimensions [%lu,%lu].", tableName, (unsigned long)f->hdr.mrows, (unsigned long)f->hdr.ncols);
      }
      *rows = f->hdr.mrows;
      *cols = f->hdr.ncols;
      return 1;
    }
    pos = ftell(f->fp);
    fseek(f->fp,f->hdr.mrows*f->hdr.ncols*Mat_getTypeSize(f,f->hdr.type)*(f->hdr.imagf?2:1),pos);
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

inline static char getEndianness()
{
  const int endian_test = 1;
  return ((*(char*)&endian_test) == 0);
}

#define correctEndianness(stype,type)  inline static type correctEndianness_ ## stype (type _num, char dataEndianness)  \
{ \
  typedef union  \
  { \
    type num; \
    unsigned char b[sizeof(type)]; \
  } elem_u_ ## stype; \
  elem_u_ ## stype dat1, dat2; \
  if(getEndianness() != dataEndianness) \
  { \
    size_t i; \
    dat1.num = _num; \
    for(i=0; i < sizeof(type); ++i) \
      dat2.b[i] = dat1.b[sizeof(type)-i-1]; \
    return dat2.num; \
  } \
  return _num; \
} \

correctEndianness(d,double)
correctEndianness(f,float)
correctEndianness(i,int)
correctEndianness(s,short)
correctEndianness(us,unsigned short)
correctEndianness(c,unsigned char)




static double Mat_getElem(elem_t *num, char type, char dataEndianness)
{
  switch(type) {
  case 0:
    return correctEndianness_d(num->d,dataEndianness);
  case 1:
    return correctEndianness_f(num->f,dataEndianness);
  case 2:
    return correctEndianness_i(num->i,dataEndianness);
  case 3:
    return correctEndianness_s(num->s,dataEndianness);
  case 4:
    return correctEndianness_us(num->us,dataEndianness);
  default:
    return correctEndianness_c(num->c,dataEndianness);
  }
}

static void Mat_readTable(MAT_FILE *f, double *buf, size_t rows, size_t cols)
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
      char * returnTmp = fgets(readbuf.p,elemSize,f->fp);
      if(ferror(f->fp))
      {
        fclose(f->fp);
        ModelicaFormatError("Could not read from file `%s'.",f->filename);
      }
      buf[i*cols+j] = Mat_getElem(&readbuf,(char)P,isBigEndian);
    }
}

/*
  CSV File implementation
*/
typedef struct CSV_FILE
{
  FILE *fp;
  char *filename;
  long int data;
  size_t line;
} CSV_FILE;

static CSV_FILE *csv_open(const char *filename)
{
  CSV_FILE *f=(CSV_FILE*)calloc(1,sizeof(CSV_FILE));
  if (!f) {
    ModelicaFormatError("Not enough memory for Filename %s",filename);
  }
  else
  {
    size_t l = strlen(filename);
    f->filename = (char*)malloc((l+1)*sizeof(char));
    if (!f->filename) {
      ModelicaFormatError("Not enough memory for Filename %s",filename);
    }
    else
    {
      size_t i;
      for(i=0;i<=l;i++) {
        f->filename[i] = filename[i];
      }
      f->fp = fopen(filename,"r");
      if (!f->fp) {
        ModelicaFormatError("Cannot open File %s",filename);
      }
    }
  }
  return f;
}

static void csv_close(CSV_FILE *f)
{
  if(f)
  {
    if(f->filename)
      free(f->filename);
    fclose(f->fp);
    free(f);
  }
}

static size_t csv_readLine(CSV_FILE *f, char **data, size_t *size)
{
  size_t col = 0;
  size_t i = 0;
  char *buf = *data;
  memset(*data, 0, sizeof(char)*(*size));

  /* read whole line */
  while(!feof(f->fp))
  {
    int ch;
    if(col >= *size)
    {
      size_t s = *size * 2 + 1024;
      char *tmp = (char*)calloc(s, sizeof(char));
      if (!tmp) {
        ModelicaFormatError("Not enough memory for loading file %s",f->filename);
      }
      for(i = 0; i < *size; i++)
        tmp[i] = buf[i];
      if(buf)
        free(buf);
      *data = tmp;
      buf = *data;
      *size = s;
    }
    ch = fgetc(f->fp);
    if(ferror(f->fp))
    {
      fclose(f->fp);
      ModelicaFormatError("In file `%s': parsing error at line %lu and col %lu.", f->filename, (unsigned long)f->line, (unsigned long)col);
    }
    if(ch == '\n')
      break;
    buf[col] = ch;
    col++;
  }
  return col;
}

static char csv_findTable(CSV_FILE *f, const char *tableName, size_t *cols, size_t *rows)
{
  char *strLn=0;
  size_t buflen=0;
  size_t i=0;
  size_t _cols = 1;
  char stop=0;
  *cols=0;
  *rows=0;
  while(!feof(f->fp))
  {
    size_t col;
    /* start new line, update counters */
    ++f->line;
    /* read whole line */
    col = csv_readLine(f,&strLn,&buflen);

    if(strcmp(strLn,tableName)==0)
    {
      f->data = ftell (f->fp);
      if(ferror(f->fp))
      {
        perror ("The following error occurred");
        ModelicaFormatError("Cannot get File Position! from File %s",f->filename);
      }
      while(!feof(f->fp) && (stop==0))
      {
        col = csv_readLine(f,&strLn,&buflen);
        for(i = 0; i<buflen;i++)
        {
          if(strLn[i]== ',')
          {
            _cols++;
            continue;
          }
          if(strLn[i]== 0)
            break;
          if(isdigit(strLn[i]) == 0)
          {
            if(strLn[i] != 'e')
              if(strLn[i] != 'E')
                if(strLn[i] != '+')
                  if(strLn[i] != '-')
                    stop = 1;
          }
        }
        (*rows)++;
        *cols = fmax(_cols,*cols);
        _cols = 1;
      }
      if(strLn)
        free(strLn);
      return 1;
    }
  }
  if(strLn)
    free(strLn);
  return 0;
}

static void csv_readTable(CSV_FILE *f, const char *tableName, double *data, size_t rows, size_t cols)
__attribute__((nonnull));

static void csv_readTable(CSV_FILE *f, const char *tableName, double *data, size_t rows, size_t cols)
{
  char *strLn=NULL;
  size_t buflen=0;
  size_t row=0;
  size_t lh=0;
  char *number=NULL;
  char *entp=NULL;
  fseek ( f->fp , 0 , SEEK_SET );
  /* WHY DOES THIS NOT WORK
  if(fseek ( f->fp , f->data , SEEK_CUR ))
  {
    throwStreamPrint("Cannot set File Position! from File %s, no data is readed",f->filename);
  }
  */
  while(!feof(f->fp))
  {
    size_t col = csv_readLine(f,&strLn,&buflen);

    if(strcmp(strLn,tableName)==0)
    {
      for(row=0;row<rows;row++)
      {
        size_t c = csv_readLine(f,&strLn,&buflen);
        number = strLn;
        for(col=0;col<cols;col++)
        {
          data[row*cols+col] = strtod(number,&entp);
          trim((const char**)&entp,&lh);
          number = entp+1;
        }
      }
      break;
    }
  }
  if(strLn)
    free(strLn);
}

/*
  Open specified file
*/
static void openFile(const char *filename, const char* tableName, size_t *rows, size_t *cols, double **data)
{
  size_t sl = 0;
  char filetype[5] = {0};
  /* get File Type */
  sl = strlen(filename);
  filetype[3] = filename[sl-1];
  filetype[2] = filename[sl-2];
  filetype[1] = filename[sl-3];
  filetype[0] = filename[sl-4];

  /* read data from file*/
  if(strncmp(filetype,".csv",4) == 0) /* text file */
  {
    CSV_FILE *f=NULL;
    f = csv_open(filename);
    if(csv_findTable(f,tableName,cols,rows))
    {
      *data = (double*)calloc((*cols)*(*rows),sizeof(double));
      if (!*data) {
        ModelicaFormatError("Not enough memory for Table: %s",tableName);
      }
      csv_readTable(f,tableName,*data,*rows,*cols);
      csv_close(f);
      return;
    }
    csv_close(f);
    ModelicaFormatError("No table named `%s' in file `%s'.",tableName,filename);
  }
  else if(strncmp(filetype,".mat",4) == 0) /* mat file */
  {
    MAT_FILE *f= Mat_open(filename);
    if(Mat_findTable(f,tableName,cols,rows))
    {
      *data = (double*)calloc((*cols)*(*rows),sizeof(double));
      if (!*data) {
        ModelicaFormatError("Not enough memory for Table: %s",tableName);
      }
      Mat_readTable(f,*data,*rows,*cols);
      Mat_close(f);
      return;
    }
    Mat_close(f);
    ModelicaFormatError("No table named `%s' in file `%s'.",tableName,filename);
  }
  else if(strncmp(filetype,".txt",4) == 0) /* csv file */
  {
    TEXT_FILE *f= Text_open(filename);
    if(Text_findTable(f,tableName,cols,rows))
    {
      *data = (double*)calloc((*cols)*(*rows),sizeof(double));
      if (!*data) {
        ModelicaFormatError("Not enough memory for Table: %s",tableName);
      }
      Text_readTable(f,*data,*rows,*cols);
      Text_close(f);
      return;
    }
    Text_close(f);
    ModelicaFormatError("No table named `%s' in file `%s'.",tableName,filename);
  }
  ModelicaFormatError("Interpolation table: %s from file %s uknown file extension -- `%s'.",tableName,filename,filetype);
}

/*
   implementation of InterpolationTable methods
*/

static char *copyTableNameFile(const char *name)
{
  size_t l = 0;
  char *dst=NULL;
  l = strlen(name);
  if(l==0)
    l = 6;
  dst = (char*)malloc((l+1)*sizeof(char));
  if (!dst) {
    ModelicaFormatError("Not enough memory for Table: %s",name);
  }
  if(name)
  {
    size_t i;
    for(i=0;i<=l;i++)
    {
      dst[i] = name[i];
    }
  }
  else
  {
    strcpy(dst,"NoName");
  }
  return dst;
}

static InterpolationTable* InterpolationTable_init(double time, double startTime,
               int ipoType, int expoType,
               const char* tableName, const char* fileName,
               const double* table, int tableDim1,
               int tableDim2, int colWise)
{
  size_t size = tableDim1*tableDim2;
  InterpolationTable *tpl = 0;
  tpl = (InterpolationTable*)calloc(1,sizeof(InterpolationTable));
  if (!tpl) {
    ModelicaFormatError("Not enough memory for Table: %s",tableName);
  }
  else
  {
    tpl->rows = tableDim1;
    tpl->cols = tableDim2;
    tpl->colWise = colWise;
    tpl->ipoType = ipoType;
    tpl->expoType = expoType;
    tpl->startTime = startTime;

    tpl->tablename = copyTableNameFile(tableName);
    tpl->filename = copyTableNameFile(fileName);

    if(fileName && strncmp("NoName",fileName,6) != 0)
    {
      openFile(fileName,tableName,&(tpl->rows),&(tpl->cols),&(tpl->data));
      tpl->own_data = 1;
    } else
    {
#ifndef COPY_ARRAYS
      if (!table) {
        ModelicaFormatError("Not enough memory for Table: %s",tableName);
      }
      tpl->data = *(double**)((void*)&table);
#else
      size_t i;
      /* tpl->data = const_cast<double*>(table); */
      tpl->data = (double*)malloc(size*sizeof(double));
      if (!tpl->data) {
        ModelicaFormatError("Not enough memory for Table: %s",tableName);
      }
      tpl->own_data = 1;

      for(i=0;i<size;i++)
      {
        tpl->data[i] = table[i];
      }
#endif
    }
    /* check that time column is strictly monotonous */
    InterpolationTable_checkValidityOfData(tpl);
  }
  return tpl;
}

static void InterpolationTable_deinit(InterpolationTable *tpl)
{
  if(tpl)
  {
    if(tpl->own_data)
      free(tpl->data);
    free(tpl);
  }
}

static double InterpolationTable_interpolate(InterpolationTable *tpl, double time, size_t col)
{
  size_t i = 0;
  size_t lastIdx = tpl->colWise ? tpl->cols : tpl->rows;

  if(!tpl->data) return 0.0;

  /* adrpo: if we have only one row [0, 0.7] return the value column */
  if(lastIdx == 1)
  {
    return InterpolationTable_getElt(tpl,0,col);
  }

  /* substract time offset */
  if(time < InterpolationTable_minTime(tpl))
    return InterpolationTable_extrapolate(tpl,time,col,time <= InterpolationTable_minTime(tpl));

  for(i = 0; i < lastIdx; ++i) {
    if(InterpolationTable_getElt(tpl,i,0) > time) {
      if(tpl->ipoType == 1 || lastIdx==2)
        return InterpolationTable_interpolateLin(tpl,time, i-1,col);
      else if(tpl->ipoType == 2){
        return InterpolationTable_interpolateSpline(tpl,time, i-1,col);
      }
    }
  }
  return InterpolationTable_extrapolate(tpl,time,col,time <= InterpolationTable_minTime(tpl));
}

static double InterpolationTable_maxTime(InterpolationTable *tpl)
{
  return (tpl->data?InterpolationTable_getElt(tpl,tpl->rows-1,0):0.0);
}
static double InterpolationTable_minTime(InterpolationTable *tpl)
{
  return (tpl->data?tpl->data[0]:0.0);
}

static char InterpolationTable_compare(InterpolationTable *tpl, const char* fname, const char* tname,
         const double* table)
{
  if( (fname == NULL || tname == NULL) || ((strncmp("NoName",fname,6) == 0 && strncmp("NoName",tname,6) == 0)) )
  {
    /* table passed as memory location */
    return (tpl->data == table);
  }
  else
  {
    /* table loaded from file */
    return ((!strncmp(tpl->filename,fname,6)) && (!strncmp(tpl->tablename,tname,6)));
  }
}

static double InterpolationTable_extrapolate(InterpolationTable *tpl, double time, size_t col,
               char beforeData)
{
  size_t lastIdx;

  switch(tpl->expoType) {
  case 1:
    /* hold last/first value */
    return InterpolationTable_getElt(tpl,(beforeData ? 0 : tpl->rows-1),col);
  case 2:
    /* extrapolate through first/last two values */
    lastIdx = (tpl->colWise ? tpl->cols : tpl->rows) - 2;
    return InterpolationTable_interpolateLin(tpl,time,(beforeData ? 0 : lastIdx),col);
  case 3:
    /* periodically repeat signal */
    time = tpl->startTime + (time - InterpolationTable_maxTime(tpl)*floor(time/InterpolationTable_maxTime(tpl)));
    return InterpolationTable_interpolate(tpl,time,col);
  default:
    return 0.0;
  }
}

static double InterpolationTable_interpolateLin(InterpolationTable *tpl, double time, size_t i, size_t j)
{
  double t_1 = InterpolationTable_getElt(tpl,i,0);
  double t_2 = InterpolationTable_getElt(tpl,i+1,0);
  double y_1 = InterpolationTable_getElt(tpl,i,j);
  double y_2 = InterpolationTable_getElt(tpl,i+1,j);
  /*if(std::abs(t_2-t_1) < 100.0*std::numeric_limits<double>::epsilon())
    return y_1;
    else
  */
  return (y_1 + ((time-t_1)/(t_2-t_1)) * (y_2-y_1));
}

static double InterpolationTable_interpolateSpline(InterpolationTable *tpl, double time, size_t i, size_t j)
{
  size_t lastIdx = tpl->colWise ? tpl->cols : tpl->rows;
  double x1,x2,x3,x4,x5,x6;
  double y1,y2,y3,y4,y5,y6;
  double m1,m2,m3,m4,m5;
  double t1,t2;
  double p0,p1,p2,p3;
  double x;

  x3 = InterpolationTable_getElt(tpl,i,0);
  x4 = InterpolationTable_getElt(tpl,i+1,0);
  y3 = InterpolationTable_getElt(tpl,i,j);
  y4 = InterpolationTable_getElt(tpl,i+1,j);

  if(i > 1){
    x1 = InterpolationTable_getElt(tpl,i-2,0);
    x2 = InterpolationTable_getElt(tpl,i-1,0);
    y1 = InterpolationTable_getElt(tpl,i-2,j);
    y2 = InterpolationTable_getElt(tpl,i-1,j);
  }
  else if(i == 1){
    x2 = InterpolationTable_getElt(tpl,i-1,0);
    x1 = x3 + x2 - x4;
    y2 = InterpolationTable_getElt(tpl,i-1,j);
    y1 = (y4-y3)*(x2-x1)/(x4-x3) - 2*(y3-y2)*(x2-x1)/(x3-x2) + y2;
  }
  else{
    x5 = InterpolationTable_getElt(tpl,i+2,0);
    x1 = 2*x3-x5;
    x2 = x4 + x3 - x5;
    y5 = InterpolationTable_getElt(tpl,i+2,j);
    y2 = (y5-y4)*(x3-x2)/(x5-x4) - 2*(y4-y3)*(x3-x2)/(x4-x3) + y3;
    y1 = (y4-y3)*(x2-x1)/(x4-x3) - 2*(y3-y2)*(x2-x1)/(x3-x2) + y2;
  }

  if(i < lastIdx-3){
    x5 = InterpolationTable_getElt(tpl,i+2,0);
    x6 = InterpolationTable_getElt(tpl,i+3,0);
    y5 = InterpolationTable_getElt(tpl,i+2,j);
    y6 = InterpolationTable_getElt(tpl,i+3,j);
  }
  else if(i < lastIdx-2){
    x5 = InterpolationTable_getElt(tpl,i+2,0);
    x6 = x5 - x3 + x4;
    y5 = InterpolationTable_getElt(tpl,i+2,j);
    y6 = 2*(y5-y4)*(x6-x5)/(x5-x4) - (y4-y3)*(x6-x5)/(x4-x3) + y5;
  }
  else{
    x5 = x4 - x2 + x3;
    x6 = 2*x4 - x2;
    y5 = 2*(y4-y3)*(x5-x4)/(x4-x3) - (y3-y2)*(x5-x4)/(x3-x2) + y4;
    y6 = 2*(y5-y4)*(x6-x5)/(x5-x4) - (y4-y3)*(x6-x5)/(x4-x3) + y5;
  }

  m1 = (y2-y1)/(x2-x1);
  m2 = (y3-y2)/(x3-x2);
  m3 = (y4-y3)/(x4-x3);
  m4 = (y5-y4)/(x5-x4);
  m5 = (y6-y5)/(x6-x5);

  if(m1==m2 && m3==m4)
    t1 = 0.5*(m2+m3);
  else
    t1 = (fabs(m4-m3)*m2+fabs(m2-m1)*m3) / (fabs(m4-m3)+fabs(m2-m1));

  if(m2==m3 && m4==m5)
    t2 = 0.5*(m3+m4);
  else
    t2 = (fabs(m5-m4)*m3+fabs(m3-m2)*m4) / (fabs(m5-m4)+fabs(m3-m2));

  p0 = y3;
  p1 = t1;
  p2 = (3*(y4-y3)/(x4-x3)-2*t1-t2)/(x4-x3);
  p3 = (t1+t2-2*(y4-y3)/(x4-x3))/((x4-x3)*(x4-x3));

  // printf("\ni=%d\n", i);
  // printf("\nx1=%g\nx2=%g\nx3=%g\nx4=%g\nx5=%g\nx6=%g\n", x1,x2,x3,x4,x5,x6);
  // printf("\ny1=%g\ny2=%g\ny3=%g\ny4=%g\ny5=%g\ny6=%g\n", y1,y2,y3,y4,y5,y6);
  // printf("\nm1=%g\nm2=%g\nm3=%g\nm4=%g\nm5=%g\n", m1,m2,m3,m4,m5);
  // printf("\nt1=%g\nt2=%g\n", t1,t2);
  // printf("\np0=%g\np1=%g\np2=%g\np3=%g\n", p0,p1,p2,p3);
  // printf("\nx=%g\n", x);

  return p0 + (time-x3) * (p1 + (time-x3) * (p2 + (time-x3) * p3));
}

static const double InterpolationTable_getElt(InterpolationTable *tpl, size_t row, size_t col)
{
  /* is this really correct? doesn't it depends on tpl>colWise? */
  if (!(row < tpl->rows && col < tpl->cols)) {
    ModelicaFormatError("In Table: %s from File: %s with Size[%lu,%lu] try to get Element[%lu,%lu] out of range!",
      tpl->tablename, tpl->filename,
      (unsigned long)tpl->rows, (unsigned long)tpl->cols,
      (unsigned long)row, (unsigned long)col);
  }

  return tpl->data[tpl->colWise ? col*tpl->rows+row : row*tpl->cols+col];
}

static void InterpolationTable_checkValidityOfData(InterpolationTable *tpl)
{
  size_t i = 0;
  size_t maxSize = tpl->colWise ? tpl->cols : tpl->rows;
  /* if we have only one row or column, return */
  if(maxSize == 1) return;
  /* else check the validity */
  for(i = 1; i < maxSize; ++i)
    if(InterpolationTable_getElt(tpl,i-1,0) > InterpolationTable_getElt(tpl,i,0))
      ModelicaFormatError("TimeTable: Column with time variable not monotonous: %g >= %g.", InterpolationTable_getElt(tpl,i-1,0),InterpolationTable_getElt(tpl,i,0));
}


/*
  interpolation 2D
*/
static InterpolationTable2D* InterpolationTable2D_init(int ipoType, const char* tableName,
           const char* fileName, const double *table,
           int tableDim1, int tableDim2, int colWise)
{
  size_t size = tableDim1*tableDim2;
  InterpolationTable2D *tpl = 0;
  tpl = (InterpolationTable2D*)calloc(1,sizeof(InterpolationTable2D));
  if (!tpl) {
    ModelicaFormatError("Not enough memory for Table: %s",tableName);
  }
  else
  {
    if (!((0 < ipoType) & (ipoType < 3))) {
      ModelicaFormatError("Unknown interpolation Type %d for Table %s from file %s!",ipoType,tableName,fileName);
    }
    tpl->rows = tableDim1;
    tpl->cols = tableDim2;
    tpl->colWise = colWise;
    tpl->ipoType = ipoType;

    tpl->tablename = copyTableNameFile(tableName);
    tpl->filename = copyTableNameFile(fileName);

    if(fileName && strncmp("NoName",fileName,6) != 0)
    {
      openFile(fileName,tableName,&(tpl->rows),&(tpl->cols),&(tpl->data));
      tpl->own_data = 1;
    } else {
#ifndef COPY_ARRAYS
      if (!table) {
        ModelicaFormatError("Not enough memory for Table: %s",tableName);
      }
      tpl->data = *(double**)((void*)&table);
#else
      size_t i;
      tpl->data = (double*)malloc(size*sizeof(double));
      if (!tpl->data) {
        ModelicaFormatError("Not enough memory for Table: %s",tableName);
      }
      tpl->own_data = 1;

      for(i=0;i<size;i++)
      {
        tpl->data[i] = table[i];
      }
#endif
}
  }
  /* check if table is valid */
  InterpolationTable2D_checkValidityOfData(tpl);
  return tpl;
}

static void InterpolationTable2D_deinit(InterpolationTable2D *table)
{
  if(table)
  {
    if(table->own_data)
      free(table->data);
    free(table);
  }
}

static double InterpolationTable2D_akime(double* tx, double* ty, size_t tlen, double x)
{
  double x1,x2,x3,y1,y2,y3,a,b,yd0,yd1,t,pd_li,pd_re,g0,g1,h0,h1,cden,t1,t2,t3;
  size_t index=0;
  if (!(tlen>0)) {
    ModelicaFormatError("InterpolationTable2D_akime called with empty table!");
  }
  /* smooth interpolation with Akima Splines such that der(y) is continuous */
  if((tlen < 4) | (x < tx[2]) | (x > tx[tlen-3]))
  {
    double c;
    if(tlen < 3)
    {
      if(tlen < 2)
      {
        return ty[0];
      }
      /* Linear Interpolation */
      return ((tx[1] - x)*ty[0] + (x - tx[0])*ty[1]) / (tx[1]-tx[0]);
    }
    /* parable interpolation */
    if(x > tx[tlen-3])
    {
      x1 = tx[tlen-3];
      x2 = tx[tlen-2];
      x3 = tx[tlen-1];
      y1 = ty[tlen-3];
      y2 = ty[tlen-2];
      y3 = ty[tlen-1];
    }
    else
    {
      x1 = tx[0];
      x2 = tx[1];
      x3 = tx[2];
      y1 = ty[0];
      y2 = ty[1];
      y3 = ty[2];
    }

    cden = (x1-x2)*(x1-x3)*(x2-x3);
    t1 = x1*(y2-y3);
    t2 = x2*(y3-y1);
    t3 = x3*(y1-y2);
    a =-(t1+t2+t3)/cden;
    b = (x1*t1+x2*t2+x3*t3)/cden;
    c = (x1*x1*(x2*y3-x3*y2)+x1*(x3*x3*y2-x2*x2*y3)+x2*x3*y1*(x2-x3))/cden;

    return x*(a*x + b) + c;
  }

  /* get index in table */
  for(index = 1; index < tlen-1; index++)
    if(tx[index] > x) break;

  if(index > 2)
  {
    if(index < tlen - 2)
    {
      double a1, a2;
      double q[5] = {0};
      int i;
      /* calc */
      int pos = 0;
      for(i = -2; i < 3; ++i)
      {
        q[pos] = (ty[index+i]-ty[index+i-1])/(tx[index+i]-tx[index+i-1]);
        pos = pos + 1;
      }

      a1 = fabs(q[3]-q[2]);
      a2 = fabs(q[1]-q[0]);
      if(a1+a2 == 0)
        yd0 = (q[1] + q[2])/2;
      else
        yd0 = (q[1]*a1 + q[2]*a2)/(a1+a2);
      a1 = fabs(q[4]-q[3]);
      a2 = fabs(q[2]-q[1]);
      if(a1+a2 == 0)
        yd1 = (q[2] + q[3])/2;
      else
        yd1 = (q[2]*a1 + q[3]*a2)/(a1+a2);
    }
    else
    {
      x1 = tx[tlen-3];
      x2 = tx[tlen-2];
      x3 = tx[tlen-1];
      y1 = ty[tlen-3];
      y2 = ty[tlen-2];
      y3 = ty[tlen-1];

      cden = (x1-x2)*(x1-x3)*(x2-x3);
      t1 = x1*(y2-y3);
      t2 = x2*(y3-y1);
      t3 = x3*(y1-y2);
      a =-(t1+t2+t3)/cden;
      b = (x1*t1+x2*t2+x3*t3)/cden;

      if(index < tlen - 1)
      {
       yd0 = 2*a*x1 - b;
       yd1 = 2*a*x2 - b;
      }
      else
      {
        yd0 = 2*a*x2 - b;
        yd1 = 2*a*x3 - b;
      }
    }
  }
  else
  {
    x1 = tx[0];
    x2 = tx[1];
    x3 = tx[2];
    y1 = ty[0];
    y2 = ty[1];
    y3 = tx[2];

    cden = (x1-x2)*(x1-x3)*(x2-x3);
    t1 = x1*(y2-y3);
    t2 = x2*(y3-y1);
    t3 = x3*(y1-y2);
    a =-(t1+t2+t3)/cden;
    b = (x1*t1+x2*t2+x3*t3)/cden;

    if(index > 0)
    {
      yd0 = 2*a*x2 - b;
      yd1 = 2*a*x3 - b;
    }
    else
    {
      yd0 = 2*a*x1 - b;
      yd1 = 2*a*x2 - b;
    }
  }
  t = (x-tx[index-1])/(tx[index]-tx[index-1]);

  pd_li = (tx[index] - tx[index-1])*yd0;
  pd_re = (tx[index] - tx[index-1])*yd1;

  g0 = 0.5-1.5*(t-0.5)+2*pow(t-0.5,3);
  g1 = 1-g0;
  h0 = t*pow((t-1),2);
  h1 = t*t*(t-1);

  return ty[index-1]*g0+ty[index]*g1+pd_li*h0+pd_re*h1;
}

static double InterpolationTable2D_interpolate(InterpolationTable2D *table, double x1, double x2)
{
  size_t i, j, start;
  double f_1, f_2;
  double tx[6];
  double ty[6];
  size_t tlen=0;
  if(table->colWise)
  {
    double tmp = x1;
    x1 = x2;
    x2 = tmp;
  }

  /* if out of boundary, use first or last two points for x2 */
  if(table->cols == 2)
  {
    if(table->rows == 2)
    {
      /*
       If the table has only one element, the table value is returned,
       independent of the value of the input signal.
      */
      return InterpolationTable2D_getElt(table,1,1);
    }
    /* find interval corresponding x1 */
    for(i = 2; i < table->rows; ++i)
      if(InterpolationTable2D_getElt(table,i,0) >= x1) break;
    if((table->ipoType == 2) && (table->rows > 3))
    {
      /* smooth interpolation with Akima Splines such that der(y) is continuous */
      tlen=0;
      if(i < 4)
        start = 1;
      else
        start = i-3;
      for(j = start; (j < table->rows) & (j < i+3); ++j)
      {
        tx[tlen] = InterpolationTable2D_getElt(table,j,0);
        ty[tlen] = InterpolationTable2D_getElt(table,j,1);
        tlen++;
      }
      return InterpolationTable2D_akime(tx,ty,tlen,x1);
    }
    /* Liniear Interpolation */
    f_2 = InterpolationTable2D_getElt(table,i,1) - InterpolationTable2D_getElt(table,i-1,1);
    return InterpolationTable2D_linInterpolate(x1,InterpolationTable2D_getElt(table,i-1,0),InterpolationTable2D_getElt(table,i,0),0,f_2);
  }
  if(table->rows == 2)
  {
    /* find interval corresponding x2 */
    for(j = 2; j < table->cols; ++j)
      if(InterpolationTable2D_getElt(table,0,j) >= x2) break;

    if((table->ipoType == 2) && (table->cols > 3))
    {
      /* smooth interpolation with Akima Splines such that der(y) is continuous */
      tlen=0;
      if(j < 4)
        start = 1;
      else
        start = j-3;
      for(i = start; (i < table->cols) & (i < j+3); ++i)
      {
        tx[tlen] = InterpolationTable2D_getElt(table,0,i);
        ty[tlen] = InterpolationTable2D_getElt(table,1,i);
        tlen++;
      }
      return InterpolationTable2D_akime(tx,ty,tlen,x2);
    }
    f_2 = InterpolationTable2D_getElt(table,1,j) - InterpolationTable2D_getElt(table,1,j-1);
    return InterpolationTable2D_linInterpolate(x2,InterpolationTable2D_getElt(table,0,j-1),InterpolationTable2D_getElt(table,0,j),0,f_2);
  }

  /* find intervals corresponding x1 and x2 */
  for(i = 2; i < table->rows-1; ++i)
    if(InterpolationTable2D_getElt(table,i,0) >= x1) break;
  for(j = 2; j < table->cols-1; ++j)
    if(InterpolationTable2D_getElt(table,0,j) >= x2) break;

  if((table->ipoType == 2) && (table->rows != 3) && (table->cols != 3)  )
  {
    size_t k, l, starte, telen;
    double te[6];
    /* smooth interpolation with Akima Splines such that der(y) is continuous */

    /* interpolate rows */
    if(i < 4)
      start = 1;
    else
      start = i-3;
    if(j < 4)
      starte = 1;
    else
      starte = j-3;
    tlen=0;
    for(k = start; (k < table->rows) & (k < i+3); ++k)
    {
      tx[tlen] = InterpolationTable2D_getElt(table,k,0);
      tlen++;
    }
    telen=0;
    for(l = starte; (l < table->cols) & (l < j+3); ++l)
    {
      tlen=0;
      for(k = start; (k < table->rows) & (k < i+3); ++k)
      {
        ty[tlen] = InterpolationTable2D_getElt(table,k,l);
        tlen++;
      }
      te[telen] = InterpolationTable2D_akime(tx,ty,tlen,x1);
      telen++;
    }
    telen=0;
    for(k = starte; (k < table->cols) & (k < j+3); ++k)
    {
      tx[telen] = InterpolationTable2D_getElt(table,0,k);
      telen++;
    }
    return InterpolationTable2D_akime(tx,te,telen,x2);
  }

  /* bilinear interpolation */
  f_1 = InterpolationTable2D_linInterpolate(x1,InterpolationTable2D_getElt(table,i-1,0),InterpolationTable2D_getElt(table,i,0),InterpolationTable2D_getElt(table,i-1,j-1),InterpolationTable2D_getElt(table,i,j-1));
  f_2 = InterpolationTable2D_linInterpolate(x1,InterpolationTable2D_getElt(table,i-1,0),InterpolationTable2D_getElt(table,i,0),InterpolationTable2D_getElt(table,i-1,j),InterpolationTable2D_getElt(table,i,j));
  return InterpolationTable2D_linInterpolate(x2,InterpolationTable2D_getElt(table,0,j-1),InterpolationTable2D_getElt(table,0,j),f_1,f_2);
}

static char InterpolationTable2D_compare(InterpolationTable2D *tpl, const char* fname, const char* tname, const double* table)
{
  if( (fname == NULL || tname == NULL) || ((strncmp("NoName",fname,6) == 0 && strncmp("NoName",tname,6) == 0)) )
  {
    /* table passed as memory location */
    return (tpl->data == table);
  }
  else
  {
    /* table loaded from file */
    return ((!strncmp(tpl->filename,fname,6)) && (!strncmp(tpl->tablename,tname,6)));
  }
  return 0;
}

static double InterpolationTable2D_linInterpolate(double x, double x_1, double x_2, double f_1, double f_2)
{
  return ((x_2 - x)*f_1 + (x - x_1)*f_2) / (x_2-x_1);
}

static const double InterpolationTable2D_getElt(InterpolationTable2D *tpl, size_t row, size_t col)
{
  if (!(row < tpl->rows && col < tpl->cols)) {
    ModelicaFormatError("In Table: %s from File: %s with Size[%lu,%lu] try to get Element[%lu,%lu] out of range!", tpl->tablename, tpl->filename, (unsigned long)tpl->rows, (unsigned long)tpl->cols, (unsigned long)row, (unsigned long)col);
  }
  return tpl->data[row*tpl->cols+col];
}

static void InterpolationTable2D_checkValidityOfData(InterpolationTable2D *tpl)
{
  size_t i = 0;
  /* check if table has values */
  if (!((tpl->rows > 1) && (tpl->cols > 1))) {
    ModelicaFormatError("Table %s from file %s has no data!", tpl->tablename, tpl->filename);
  }
  /* check that first row and column are strictly monotonous */
  for(i=2; i < tpl->rows; ++i)
  {
    if(InterpolationTable2D_getElt(tpl,i-1,0) >= InterpolationTable2D_getElt(tpl,i,0))
      ModelicaFormatError("Table: %s independent variable u1 not strictly \
             monotonous: %g >= %g.",tpl->tablename, InterpolationTable2D_getElt(tpl,i-1,0), InterpolationTable2D_getElt(tpl,i,0));
  }
  for(i=2; i < tpl->cols; ++i)
  {
    if(InterpolationTable2D_getElt(tpl,0,i-1) >= InterpolationTable2D_getElt(tpl,0,i))
      ModelicaFormatError("Table: %s independent variable u2 not strictly \
             monotonous: %g >= %g.",tpl->tablename, InterpolationTable2D_getElt(tpl,0,i-1), InterpolationTable2D_getElt(tpl,0,i));
  }
}

/* Start of public interface and wrappers for old tables (MSL 2.x ~ 3.2) */

#ifndef MODELICA_TABLES_H
#define MODELICA_TABLES_H

/* Definition of interface to external functions for table computation
   in the Modelica Standard Library:

       Modelica.Blocks.Sources.CombiTimeTable
       Modelica.Blocks.Tables.CombiTable1D
       Modelica.Blocks.Tables.CombiTable1Ds
       Modelica.Blocks.Tables.CombiTable2D


   Release Notes:
      Jan. 27, 2008: by Martin Otter.
                     Implemented a first version

   Copyright (C) 2008, Modelica Association and DLR.

   The content of this section of the file is free software; it can be redistributed
   and/or modified under the terms of the Modelica License 2, see the
   license conditions and the accompanying disclaimer in file
   Modelica/ModelicaLicense2.html or in Modelica.UsersGuide.ModelicaLicense2.
*/


/* A table can be defined in the following ways when initializing the table:

     (1) Explicitly supplied in the argument list
         (= table    is "NoName" or has only blanks AND
            fileName is "NoName" or has only blanks).

     (2) Read from a file (tableName, fileName have to be supplied).

   Tables may be linearly interpolated or the first derivative may be continuous.
   In the second case, Akima-Splines are used
   (algorithm 433 of ACM, http://portal.acm.org/citation.cfm?id=355605)
*/

extern int ModelicaTables_CombiTimeTable_init(
                      const char*   tableName,
                      const char*   fileName,
                      double const* table, int nRow, int nColumn,
                      double        startTime,
                      int           smoothness,
                      int           extrapolation);
  /* Initialize 1-dim. table where first column is time

      -> tableName : Name of table.
      -> fileName  : Name of file.
      -> table     : If tableName="NoName" or has only blanks AND
                        fileName ="NoName" or has only blanks, then
                     this pointer points to a 2-dim. array (row-wise storage)
                     in the Modelica environment that holds this matrix.
      -> nRow      : Number of rows of table
      -> nColumn   : Number of columns of table
      -> startTime : Output = offset for time < startTime
      -> smoothness: Interpolation type
                     = 1: linear
                     = 2: continuous first derivative
      <- RETURN    : ID of internal memory of table.
  */

extern void ModelicaTables_CombiTimeTable_close(int tableID);
  /* Close table and free allocated memory */


extern double ModelicaTables_CombiTimeTable_minimumTime(int tableID);
  /* Return minimum time defined in table (= table[1,1]) */


extern double ModelicaTables_CombiTimeTable_maximumTime(int tableID);
  /* Return maximum time defined in table (= table[end,1]) */


extern double ModelicaTables_CombiTimeTable_interpolate(int tableID, int icol, double u);
  /* Interpolate in table

     -> tableID: Pointer to table defined with ModelicaTables_CombiTimeTable_init
     -> icol   : Column to interpolate
     -> u      : Abscissa value (time)
     <- RETURN : Ordinate value
 */



extern int ModelicaTables_CombiTable1D_init(
                  const  char*  tableName,
                  const  char*  fileName,
                  double const* table, int nRow, int nColumn,
                  int smoothness);
  /* Initialize 1-dim. table defined by matrix, where first column
     is x-axis and further columns of matrix are interpolated

      -> tableName : Name of table.
      -> fileName  : Name of file.
      -> table     : If tableName="NoName" or has only blanks AND
                        fileName ="NoName" or has only blanks, then
                     this pointer points to a 2-dim. array (row-wise storage)
                     in the Modelica environment that holds this matrix.
      -> nRow      : Number of rows of table
      -> nColumn   : Number of columns of table
      -> smoothness: Interpolation type
                     = 1: linear
                     = 2: continuous first derivative
      <- RETURN    : ID of internal memory of table.
  */

extern void ModelicaTables_CombiTable1D_close(int tableID);
  /* Close table and free allocated memory */

extern double ModelicaTables_CombiTable1D_interpolate(int tableID, int icol, double u);
  /* Interpolate in table

     -> tableID: Pointer to table defined with ModelicaTables_CombiTable1D_init
     -> icol   : Column to interpolate
     -> u      : Abscissa value
     <- RETURN : Ordinate value
 */



extern int ModelicaTables_CombiTable2D_init(
                   const char*   tableName,
                   const char*   fileName,
                   double const* table, int nRow, int nColumn,
                   int smoothness);
  /* Initialize 2-dim. table defined by matrix, where first column
     is x-axis, first row is y-axis and the matrix elements are the
     z-values.
       table[2:end,1    ]: Values of x-axis
            [1    ,2:end]: Values of y-axis
            [2:end,2:end]: Values of z-axis

      -> tableName : Name of table.
      -> fileName  : Name of file.
      -> table     : If tableName="NoName" or has only blanks AND
                        fileName ="NoName" or has only blanks, then
                     this pointer points to a 2-dim. array (row-wise storage)
                     in the Modelica environment that holds this matrix.
      -> nRow      : Number of rows of table
      -> nColumn   : Number of columns of table
      -> smoothness: Interpolation type
                     = 1: linear
                     = 2: continuous first derivative
      <- RETURN    : ID of internal memory of table.
  */

extern void ModelicaTables_CombiTable2D_close(int tableID);
  /* Close table and free allocated memory */

extern double ModelicaTables_CombiTable2D_interpolate(int tableID, double u1, double u2);
  /* Interpolate in table

     -> tableID: Pointer to table defined with ModelicaTables_CombiTable1D_init
     -> u1     : x-axis value
     -> u2     : y-axis value
     <- RETURN : y-axis value
 */


#endif /* MODELICA_TABLES */

int ModelicaTables_CombiTimeTable_init(const char* tableName, const char* fileName,
                                        double const *table, int nRow, int nColumn,
                                        double startTime, int smoothness,
                                        int extrapolation)
{
  return omcTableTimeIni(startTime, startTime, smoothness, extrapolation,
                         tableName, fileName, table, nRow, nColumn, 0);
}

void ModelicaTables_CombiTimeTable_close(int tableID)
{
   omcTableTimeIpoClose(tableID);
};

double ModelicaTables_CombiTimeTable_interpolate(int tableID, int icol, double u)
{
  return omcTableTimeIpo(tableID,icol,u);
}

double ModelicaTables_CombiTimeTable_minimumTime(int tableID)
{
  return omcTableTimeTmin(tableID);
}

double ModelicaTables_CombiTimeTable_maximumTime(int tableID)
{
  return omcTableTimeTmax(tableID);
}

int ModelicaTables_CombiTable1D_init(const char* tableName, const char* fileName,
                                       double const *table, int nRow, int nColumn,
                                       int smoothness)
{
  return omcTableTimeIni(*table, *table, smoothness, 2 /* extrapolate based on two first/last values */, tableName, fileName, table, nRow, nColumn, 0);
}

void ModelicaTables_CombiTable1D_close(int tableID)
{
   omcTableTimeIpoClose(tableID);
};

double ModelicaTables_CombiTable1D_interpolate(int tableID, int icol, double u) {
  return omcTableTimeIpo(tableID,icol,u);
}

int ModelicaTables_CombiTable2D_init(const char* tableName, const char* fileName,
                                       double const *table, int nRow, int nColumn,
                                       int smoothness)
{
  return omcTable2DIni(smoothness,tableName,fileName,table,nRow,nColumn,0);
}

void ModelicaTables_CombiTable2D_close(int tableID)
{
   omcTable2DIpoClose(tableID);
};

double ModelicaTables_CombiTable2D_interpolate(int tableID, double u1, double u2)
{
  return omcTable2DIpo(tableID, u1, u2);
}
