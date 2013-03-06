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

//#include "error.h"
#include "tables.h"

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <math.h>

#include "inline.h"

/* Definition to get some Debug information if interface is called */
/* #define DEBUG_INFOS */

/* Definition to make a copy of the arrays */
#define COPY_ARRAYS */


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
static size_t ninterpolationTables=0;
static InterpolationTable2D** interpolationTables2D=NULL;
static size_t ninterpolationTables2D=0;

InterpolationTable *InterpolationTable_init(double time,double startTime, int ipoType, int expoType,
         const char* tableName, const char* fileName,
         const double *table,
         int tableDim1, int tableDim2,int colWise);
/* InterpolationTable *InterpolationTable_Copy(InterpolationTable *orig); */
void InterpolationTable_deinit(InterpolationTable *tpl);
double InterpolationTable_interpolate(InterpolationTable *tpl, double time, size_t col);
double InterpolationTable_maxTime(InterpolationTable *tpl);
double InterpolationTable_minTime(InterpolationTable *tpl);
char InterpolationTable_compare(InterpolationTable *tpl, const char* fname, const char* tname, const double* table);

double InterpolationTable_extrapolate(InterpolationTable *tpl, double time, size_t col, char beforeData);
inline double InterpolationTable_interpolateLin(InterpolationTable *tpl, double time, size_t i, size_t j);
inline const double InterpolationTable_getElt(InterpolationTable *tpl, size_t row, size_t col);
void InterpolationTable_checkValidityOfData(InterpolationTable *tpl);


InterpolationTable2D *InterpolationTable2D_init(int ipoType, const char* tableName,
           const char* fileName, const double *table,
           int tableDim1, int tableDim2, int colWise);
void InterpolationTable2D_deinit(InterpolationTable2D *table);
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


int omcTableTimeIni(double timeIn, double startTime,int ipoType,int expoType,
        const char *tableName, const char* fileName,
        const double *table,int tableDim1, int tableDim2,int colWise)
{
  size_t i = 0;
  InterpolationTable** tmp = NULL;
#ifdef DEBUG_INFOS
  INFO10("Init Table \n timeIn %f \n startTime %f \n ipoType %d \n expoType %d \n tableName %s \n fileName %s \n table %p \n tableDim1 %d \n tableDim2 %d \n colWise %d", timeIn, startTime, ipoType, expoType, tableName, fileName, table, tableDim1, tableDim2, colWise);
#endif
  /* if table is already initialized, find it */
  for(i = 0; i < ninterpolationTables; ++i)
    if (InterpolationTable_compare(interpolationTables[i],fileName,tableName,table))
    {
#ifdef DEBUG_INFOS
      INFO_AL1("Table id = %d",i);
#endif
      return i;
    }
#ifdef DEBUG_INFOS
  INFO_AL1("Table id = %d",ninterpolationTables);
#endif
  /* increase array */
  tmp = (InterpolationTable**)malloc((ninterpolationTables+1)*sizeof(InterpolationTable*));
  //throw// throw std::runtime_error"Not enough memory for new Table[%d] Tablename %s Filename %s",ninterpolationTables,tableName,fileName);
 // throw std::runtime_error"Not enough memory for new Table[%d] Tablename %s Filename %s");
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
#ifdef DEBUG_INFOS
  INFO1("Close Table[%d]",tableID);
#endif
  if (tableID >= 0 && tableID < (int)ninterpolationTables)
  {
    InterpolationTable_deinit(interpolationTables[tableID]);
    interpolationTables[tableID] = NULL;
    ninterpolationTables--;
  }
  if (ninterpolationTables <=0)
    free(interpolationTables);
}


double omcTableTimeIpo(int tableID, int icol, double timeIn)
{
#ifdef DEBUG_INFOS
  INFO3("Interpolate Table[%d][%d] add Time %f",tableID,icol,timeIn);
#endif
  if (tableID >= 0 && tableID < (int)ninterpolationTables)
  {
    return InterpolationTable_interpolate(interpolationTables[tableID],timeIn,icol-1);
  }
  else
    return 0.0;
}


double omcTableTimeTmax(int tableID)
{
#ifdef DEBUG_INFOS
  INFO1("Time max from Table[%d]",tableID);
#endif
  if (tableID >= 0 && tableID < (int)ninterpolationTables)
    return InterpolationTable_maxTime(interpolationTables[tableID]);
  else
    return 0.0;
}


double omcTableTimeTmin(int tableID)
{
#ifdef DEBUG_INFOS
  INFO1("Time min from Table[%d]",tableID);
#endif
  if (tableID >= 0 && tableID < (int)ninterpolationTables)
    return InterpolationTable_minTime(interpolationTables[tableID]);
  else
    return 0.0;
}


int omcTable2DIni(int ipoType, const char *tableName, const char* fileName,
      const double *table,int tableDim1,int tableDim2,int colWise)
{
  size_t i=0;
  InterpolationTable2D** tmp = NULL;
#ifdef DEBUG_INFOS
  INFO7("Init Table \n ipoType %f \n tableName %f \n fileName %d \n table %p \n tableDim1 %d \n tableDim2 %d \n colWise %d", ipoType, tableName, fileName, table, tableDim1, tableDim2, colWise);
#endif
  /* if table is already initialized, find it */
  for(i = 0; i < ninterpolationTables2D; ++i)
    if (InterpolationTable2D_compare(interpolationTables2D[i],fileName,tableName,table))
    {
#ifdef DEBUG_INFOS
      INFO_AL1("Table id = %d",i);
#endif
      return i;
    }
#ifdef DEBUG_INFOS
  INFO_AL1("Table id = %d",ninterpolationTables2D);
#endif
  /* increase array */
  tmp = (InterpolationTable2D**)malloc((ninterpolationTables2D+1)*sizeof(InterpolationTable2D*));

  //ASSERT3(tmp,"Not enough memory for new Table[%d] Tablename %s Filename %s",ninterpolationTables,tableName,fileName);
 // throw std::runtime_error"Not enough memory for new Table[%d] Tablename %s Filename %s");

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
#ifdef DEBUG_INFOS
  INFO1("Close Table[%d]",tableID);
#endif
  if (tableID >= 0 && tableID < (int)ninterpolationTables2D)
  {
    InterpolationTable2D_deinit(interpolationTables2D[tableID]);
    interpolationTables2D[tableID] = NULL;
    ninterpolationTables2D--;
  }
  if (ninterpolationTables2D <=0)
    free(interpolationTables2D);
}


double omcTable2DIpo(int tableID,double u1_, double u2_)
{
#ifdef DEBUG_INFOS
  INFO3("Interpolate Table[%d][%d] add Time %f",tableID,u1_,u2_);
#endif
  if (tableID >= 0 && tableID < (int)ninterpolationTables2D)
    return InterpolationTable2D_interpolate(interpolationTables2D[tableID], u1_, u2_);
  else
    return 0.0;
}

/* ******************************
   ***    IMPLEMENTATION    ***
   ******************************
*/

void openFile(const char *filename, const char* tableName, size_t *rows, size_t *cols, double **data);


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

TEXT_FILE *Text_open(const char *filename)
{
  size_t l,i;
  TEXT_FILE *f=(TEXT_FILE*)calloc(1,sizeof(TEXT_FILE));
  //std::runtime_error("Not enough memory for Filename %s");
 // throw std::runtime_error"Not enough memory for Filename %s");
  l = strlen(filename);
  f->filename = (char*)calloc(1,l+1);
  //std::runtime_error("Not enough memory for Filename %s");
 // throw std::runtime_error"Not enough memory for Filename %s");
  for (i=0;i<l;i++)
  {
    f->filename[i] = filename[i];
  }
  f->fp = fopen(filename,"r");
 // throw std::runtime_error"Cannot open File %s");
  return f;
}

void Text_close(TEXT_FILE *f)
{
  if (f)
  {
    if (f->filename)
      free(f->filename);
    fclose(f->fp);
    free(f);
  }
}

void trim(const char **ptr, size_t *len)
{
  for(; *len > 0; ++(*ptr), --(*len))
    if (!isspace(*(*ptr))) return;
}
char readChr(const char **ptr, size_t *len, char chr)
{
  trim(ptr,len);
  if ((*len)-- > 0 && *((*ptr)++) != chr)
    return 0;
  trim(ptr,len);
  return 1;
}

char parseHead(TEXT_FILE *f, const char* hdr, size_t hdrLen, char **name,
  size_t *rows, size_t *cols)
{
  char* endptr;
  size_t hLen = hdrLen;
  size_t len = 0;

  trim(&hdr,&hLen);

  if (strncmp("double",hdr,fmin((size_t)6,hLen)) != 0)
    return 0;
  hdr += 6;
  hLen -= 6;
  trim(&hdr, &hLen);

  for(len = 1; len < hLen; ++len)
    if (isspace(hdr[len]) || hdr[len] == '(')
    {
      *name = hdr;
      hdr += len;
      hLen -= len;
      break;
    }
  if (!readChr(&hdr,&hLen,'('))
  {
    fclose(f->fp);
   // throw std::runtime_error"In file `%s': parsing error at line %d and col %d.");
  }
  *rows = (size_t)strtol(hdr,&endptr,10);
  if (hdr == endptr)
  {
    fclose(f->fp);
   // throw std::runtime_error"In file `%s': parsing error at line %d and col %d.");
  }
  hLen -= endptr-hdr;
  hdr = endptr;
  if (!readChr(&hdr,&hLen,','))
  {
    fclose(f->fp);
   // throw std::runtime_error"In file `%s': parsing error at line %d and col %d.");
  }
  *cols = (size_t)strtol(hdr,&endptr,10);
  if (hdr == endptr)
  {
    fclose(f->fp);
   // throw std::runtime_error"In file `%s': parsing error at line %d and col %d.");
  }
  hLen -= endptr-hdr;
  hdr = endptr;
  readChr(&hdr,&hLen,')');

  if ((hLen > 0) && ((*hdr) != '#'))
  {
    fclose(f->fp);
   // throw std::runtime_error"In file `%s': parsing error at line %d and col %d.");
  }

  return 1;
}

size_t Text_readLine(TEXT_FILE *f, char **data, size_t *size)
{
  char *tmp = NULL;
  size_t col=0;
  size_t i=0;
  int ch=0;
  char *buf = *data;
  memset(*data,0,sizeof(char)*(*size));
  /* read whole line */
  while (!feof(f->fp))
  {
    if (col >= *size)
    {
      char *tmp = (char*)calloc(*size+100,sizeof(char));
     // throw std::runtime_error"Not enough memory for Filename %s");
      for (i = 0; i < *size; i++)
        tmp[i] = buf[i];
      if (buf)
        free(buf);
      *data = tmp;
      buf = *data;
      *size = *size+100;
    }
    ch = fgetc(f->fp);
    if (ferror(f->fp))
    {
      fclose(f->fp);
     // throw std::runtime_error"In file `%s': parsing error at line %d and col %d.");
    }
    if(ch == '\n')
      break;
    buf[col] = ch;
    col++;
  }
  return col;
}

char Text_findTable(TEXT_FILE *f, const char* tableName, size_t *cols, size_t *rows)
{
  char *strLn=0;
  char *tblName=0;
  int ch=0;
  size_t buflen=0;
  size_t _cols = 0;
  size_t _rows = 0;
  size_t i=0;
  size_t col = 0;

  while (!feof(f->fp))
  {
    /* start new line, update counters */
    ++f->line;
    /* read whole line */
    col = Text_readLine(f,&strLn,&buflen);
    /* check if we read header */
    if (parseHead(f,strLn,col,&tblName,&_rows,&_cols))
    {
      /* is table name the one we are looking for? */
      if (strncmp(tblName,tableName,strlen(tableName))==0)
      {
        *cols = _cols;
        *rows = _rows;
        if (strLn)
          free(strLn);
        return 1;
      }
    }
  }
  /* no header found */
  if (strLn)
    free(strLn);
  return 0;
}

void Text_readTable(TEXT_FILE *f, double *buf, size_t rows, size_t cols)
{
  size_t i = 0;
  size_t j = 0;
  char *strLn=0;
  size_t buflen=0;
  size_t sl=0;
  size_t nlen=0;
  char *number=0;
  char *entp = 0;
  for(i = 0; i < rows; ++i)
  {
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
  if (strLn)
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

MAT_FILE *Mat_open(const char *filename)
{
  size_t l,i;
  MAT_FILE *f=(MAT_FILE*)calloc(1,sizeof(MAT_FILE));
 // throw std::runtime_error"Not enough memory for Filename %s");
  memset(&(f->hdr),0,sizeof(hdr_t));
  l = strlen(filename);
  f->filename = (char*)calloc(1,l+1);
 // throw std::runtime_error"Not enough memory for Filename %s");
  for (i=0;i<l;i++)
  {
    f->filename[i] = filename[i];
  }
  f->fp = fopen(filename,"rb");
 // throw std::runtime_error"Cannot open File %s");
  return f;
}

void Mat_close(MAT_FILE *f)
{
  if (f)
  {
    if (f->filename)
      free(f->filename);
    fclose(f->fp);
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
    fclose(f->fp);
   // throw std::runtime_error"Corrupted MAT-file: `%s'");
  }
}

char Mat_findTable(MAT_FILE *f, const char* tableName, size_t *cols, size_t *rows)
{
  char name[256];
  long pos=0;
  while (!feof(f->fp))
  {
    fgets((char*)&f->hdr,sizeof(hdr_t),f->fp);
    if (ferror(f->fp))
    {
      fclose(f->fp);
     // throw std::runtime_error"Could not read from file `%s'.");
    }
    fgets(name,fmin(f->hdr.namelen,(long)256),f->fp);
    if (strncmp(tableName,name,strlen(tableName)) == 0)
    {
      if (f->hdr.type%10 != 0 || f->hdr.type/1000 > 1)
      {
        fclose(f->fp);
       // throw std::runtime_error"Table `%s' not in supported format.");
      }
      if (f->hdr.mrows <= 0 || f->hdr.ncols <= 0)
      {
        fclose(f->fp);
       // throw std::runtime_error"Table `%s' has zero dimensions.");
      }
      if (f->hdr.mrows <= 0 || f->hdr.ncols <= 0)
      {
        fclose(f->fp);
       // throw std::runtime_error"Table `%s' has zero dimensions [%d,%d].");
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
  size_t i=0; \
  elem_u_ ## stype dat1, dat2; \
  if (getEndianness() != dataEndianness) \
  { \
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




double Mat_getElem(elem_t *num, char type, char dataEndianness)
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
    fgets(readbuf.p,elemSize,f->fp);
    if (ferror(f->fp))
    {
      fclose(f->fp);
     // throw std::runtime_error"Could not read from file `%s'.");
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

CSV_FILE *csv_open(const char *filename)
{
  size_t l,i;
  CSV_FILE *f=(CSV_FILE*)calloc(1,sizeof(CSV_FILE));
 // throw std::runtime_error"Not enough memory for Filename %s");
  l = strlen(filename);
  f->filename = (char*)calloc(1,l+1);
 // throw std::runtime_error"Not enough memory for Filename %s");
  for (i=0;i<l;i++)
  {
    f->filename[i] = filename[i];
  }
  f->fp = fopen(filename,"r");
 // throw std::runtime_error"Cannot open File %s");
  return f;
}

void csv_close(CSV_FILE *f)
{
  if (f)
  {
    if (f->filename)
      free(f->filename);
    fclose(f->fp);
    free(f);
  }
}

size_t csv_readLine(CSV_FILE *f, char **data, size_t *size)
{
  char *tmp = NULL;
  size_t col=0;
  size_t i=0;
  int ch=0;
  char *buf = *data;
  memset(*data,0,sizeof(char)*(*size));
  /* read whole line */
  while (!feof(f->fp))
  {
    if (col >= *size)
    {
      char *tmp = (char*)calloc(*size+100,sizeof(char));
     // throw std::runtime_error"Not enough memory for Filename %s");
      for (i = 0; i < *size; i++)
        tmp[i] = buf[i];
      if (buf)
        free(buf);
      *data = tmp;
      buf = *data;
      *size = *size+100;
    }
    ch = fgetc(f->fp);
    if (ferror(f->fp))
    {
      fclose(f->fp);
     // throw std::runtime_error"In file `%s': parsing error at line %d and col %d.");
    }
    if(ch == '\n')
      break;
    buf[col] = ch;
    col++;
  }
  return col;
}

char csv_findTable(CSV_FILE *f, const char *tableName, size_t *cols, size_t *rows)
{
  char *strLn=0;
  size_t buflen=0;
  size_t i=0;
  size_t col = 0;
  size_t _cols = 1;
  char stop=0;
  *cols=0;
  *rows=0;
  while (!feof(f->fp))
  {
    /* start new line, update counters */
    ++f->line;
    /* read whole line */
    col = csv_readLine(f,&strLn,&buflen);

    if (strcmp(strLn,tableName)==0)
    {
      f->data = ftell (f->fp);
      if (ferror(f->fp))
      {
        perror ("The following error occurred");
       // throw std::runtime_error"Cannot get File Position! from File %s");
      }
      while (!feof(f->fp) && (stop==0))
      {
        col = csv_readLine(f,&strLn,&buflen);
        for (i = 0; i<buflen;i++)
        {
          if(strLn[i]== ',')
          {
            _cols++;
            continue;
          }
          if(strLn[i]== 0)
            break;
          if (isdigit(strLn[i]) == 0)
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
      if (strLn)
        free(strLn);
      return 1;
    }
  }
  if (strLn)
    free(strLn);
  return 0;
}

void csv_readTable(CSV_FILE *f, const char *tableName, double *data, size_t rows, size_t cols)
{
  char stop=0;
  char *strLn=NULL;
  size_t buflen=0;
  size_t c=0;
  size_t col=0;
  size_t row=0;
  size_t lh=0;
  char *number=NULL;
  char *entp=NULL;
  fseek ( f->fp , 0 , SEEK_SET );
  /* WHY DOES THIS NOT WORK
  if (fseek ( f->fp , f->data , SEEK_CUR ))
  {
    THROW("Cannot set File Position! from File %s, no data is readed");
  }
  */
  while (!feof(f->fp))
  {
    col = csv_readLine(f,&strLn,&buflen);

    if (strcmp(strLn,tableName)==0)
    {
      for (row=0;row<rows;row++)
      {
        c = csv_readLine(f,&strLn,&buflen);
        number = strLn;
        for (col=0;col<cols;col++)
        {
          data[row*cols+col] = strtod(number,&entp);
          trim(&entp,&lh);
          number = entp+1;
        }
      }
      break;
    }
  }
  if (strLn)
    free(strLn);
}

/*
  Open specified file
*/
void openFile(const char *filename, const char* tableName, size_t *rows, size_t *cols, double **data)
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
  if (strncmp(filetype,".csv",4) == 0) /* text file */
  {
    CSV_FILE *f=NULL;
    f = csv_open(filename);
    if (csv_findTable(f,tableName,cols,rows))
    {
      *data = (double*)calloc((*cols)*(*rows),sizeof(double));
     // throw std::runtime_error"Not enough memory for Table: %s");
      csv_readTable(f,tableName,*data,*rows,*cols);
      csv_close(f);
      return;
    }
    csv_close(f);
   // throw std::runtime_error"No table named `%s' in file `%s'.");
  }
  else if (strncmp(filetype,".mat",4) == 0) /* mat file */
  {
    MAT_FILE *f= Mat_open(filename);
    if (Mat_findTable(f,tableName,cols,rows))
    {
      *data = (double*)calloc((*cols)*(*rows),sizeof(double));
     // throw std::runtime_error"Not enough memory for Table: %s");
      Mat_readTable(f,*data,*rows,*cols);
      Mat_close(f);
      return;
    }
    Mat_close(f);
   // throw std::runtime_error"No table named `%s' in file `%s'.");
  }
  else if (strncmp(filetype,".txt",4) == 0) /* csv file */
  {
    TEXT_FILE *f= Text_open(filename);
    if (Text_findTable(f,tableName,cols,rows))
    {
      *data = (double*)calloc((*cols)*(*rows),sizeof(double));
     // throw std::runtime_error"Not enough memory for Table: %s");
      Text_readTable(f,*data,*rows,*cols);
      Text_close(f);
      return;
    }
    Text_close(f);
   // throw std::runtime_error"No table named `%s' in file `%s'.");
  }
 // throw std::runtime_error"Interpolation table: %s from file %s uknown file extension -- `%s'.");
}

/*
   implementation of InterpolationTable methods
*/

char *copyTableNameFile(const char *name)
{
  size_t l = 0;
  size_t i = 0;
  char *dst=NULL;
  l = strlen(name);
  if (l==0)
    l = 6;
  dst = (char*)calloc(1,l+1);
// throw std::runtime_error"Not enough memory for Table: %s");
  if (name)
  {
    for (i=0;i<l;i++)
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
 // throw std::runtime_error"Not enough memory for Table: %s");

  tpl->rows = tableDim1;
  tpl->cols = tableDim2;
  tpl->colWise = colWise;
  tpl->ipoType = ipoType;
  tpl->expoType = expoType;
  tpl->startTime = startTime;

  tpl->tablename = copyTableNameFile(tableName);
  tpl->filename = copyTableNameFile(fileName);

  if (fileName && strncmp("NoName",fileName,6) != 0)
  {
    openFile(fileName,tableName,&(tpl->rows),&(tpl->cols),&(tpl->data));
    tpl->own_data = 1;
  } else
  {
#ifndef COPY_ARRAYS
    ASSERT1(table,"No data for Table: %s");
    tpl->data = *(double**)((void*)&table);
#else
    //tpl->data = const_cast<double*>(table);
    tpl->data = (double*)calloc(size,sizeof(double));
   // throw std::runtime_error"Not enough memory for Table: %s");
    tpl->own_data = 1;

    for (i=0;i<size;i++)
    {
      tpl->data[i] = table[i];
    }
#endif
  }
  /* check that time column is strictly monotonous */
  InterpolationTable_checkValidityOfData(tpl);
  return tpl;
}

void InterpolationTable_deinit(InterpolationTable *tpl)
{
  if (tpl)
  {
    if (tpl->own_data)
      free(tpl->data);
    free(tpl);
  }
}

double InterpolationTable_interpolate(InterpolationTable *tpl, double time, size_t col)
{
  size_t i = 0;
  size_t lastIdx = tpl->colWise ? tpl->cols : tpl->rows;

  if (!tpl->data) return 0.0;

  /* substract time offset */
  if (time < InterpolationTable_minTime(tpl))
    return InterpolationTable_extrapolate(tpl,time,col,time <= InterpolationTable_minTime(tpl));

  for(i = 0; i < lastIdx; ++i) {
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
  if ( (fname == NULL || tname == NULL) || ((strncmp("NoName",fname,6) == 0 && strncmp("NoName",tname,6) == 0)) )
  {
    /* table passed as memory location */
    return (tpl->data == table);
  }
  else
  {
    /* table loaded from file */
    return ((!strncmp(tpl->filename,fname,6)) && (!strncmp(tpl->tablename,tname,6)));
  return 0;
  }
}
double InterpolationTable_extrapolate(InterpolationTable *tpl, double time, size_t col,
               char beforeData)
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
 // throw std::runtime_error"In Table: %s from File: %s with Size[%d,%d] try to get Element[%d,%d] aut of range!");
  return tpl->data[tpl->colWise ? col*tpl->rows+row : row*tpl->cols+col];
}
void InterpolationTable_checkValidityOfData(InterpolationTable *tpl)
{
  size_t i = 0;
  size_t maxSize = tpl->colWise ? tpl->cols : tpl->rows;
 // for(i = 1; i < maxSize; ++i)
   // if (InterpolationTable_getElt(tpl,i-1,0) > InterpolationTable_getElt(tpl,i,0))
     // throw std::runtime_error"TimeTable: Column with time variable not monotonous: %g >= %g.");
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
 // throw std::runtime_error"Not enough memory for Table: %s");
// throw std::runtime_error"Unknown interpolation Type %d for Table %s from file %s!");

  tpl->rows = tableDim1;
  tpl->cols = tableDim2;
  tpl->colWise = colWise;
  tpl->ipoType = ipoType;

  tpl->tablename = copyTableNameFile(tableName);
  tpl->filename = copyTableNameFile(fileName);

  if (fileName && strncmp("NoName",fileName,6) != 0)
  {
    openFile(fileName,tableName,&(tpl->rows),&(tpl->cols),&(tpl->data));
    tpl->own_data = 1;
  } else {
#ifndef COPY_ARRAYS
    ASSERT1(table,"No data for Table: %s");
    tpl->data = *(double**)((void*)&table);
#else
    tpl->data = (double*)calloc(size,sizeof(double));
   // throw std::runtime_error"Not enough memory for Table: %s");
    tpl->own_data = 1;

    for (i=0;i<size;i++)
    {
      tpl->data[i] = table[i];
    }
#endif
  }
  /* check if table is valid */
  InterpolationTable2D_checkValidityOfData(tpl);
  return tpl;
}

void InterpolationTable2D_deinit(InterpolationTable2D *table)
{
  if (table)
  {
    if (table->own_data)
      free(table->data);
    free(table);
  }
}

double InterpolationTable2D_akime(double* tx, double* ty, size_t tlen, double x)
{
  double x1,x2,x3,y1,y2,y3,a,b,c,yd0,yd1,a1,a2,t,pd_li,pd_re,g0,g1,h0,h1;
  double q[5];
  size_t index=0;
  size_t pos=0;
  size_t i=0;
// throw std::runtime_error"InterpolationTable2D_akime called with empty table!");
  /* smooth interpolation with Akima Splines such that der(y) is continuous */
  if ((tlen < 4) | (x < tx[2]) | (x > tx[tlen-3]))
  {
  if (tlen < 3)
  {
    if (tlen < 2)
    {
      return ty[0];
    }
    /* Linear Interpolation */
    return ((tx[1] - x)*ty[0] + (x - tx[0])*ty[1]) / (tx[1]-tx[0]);
  }
  /* parable interpolation */
    if (x > tx[tlen-3])
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

    a = (x1*(y2-y3)+x2*(y3-y1)+x3*(y1-y2))/((x1-x2)*(x1-x3)*(x3-x2));
    b = (x1*x1*(y2-y3)+x2*x2*(y3-y1)+x3*x3*(y1-y2))/((x1-x2)*(x1-x3)*(x2-x3));
    c = (x1*x1*(x2*y3-x3*y2)+x1*(x3*x3*y2-x2*x2*y3)+x2*x3*y1*(x2-x3))/((x1-x2)*(x1-x3)*(x2-x3));

    return a*x*x + b*x + c;
  }

  /* get index in table */
  for(index = 1; index < tlen-1; index++)
    if (tx[index] > x) break;

  if (index > 2)
  {
    if (index < tlen - 2)
    {
      /* calc */
      pos = 0;
      for(i = -2; i < 3; ++i)
      {
        q[pos] = (ty[index+i]-ty[index+i-1])/(tx[index+i]-tx[index+i-1]);
        pos = pos + 1;
      }

      a1 = abs(q[3]-q[2]);
      a2 = abs(q[1]-q[0]);
      if (a1+a2 == 0)
        yd0 = (q[1] + q[2])/2;
      else
        yd0 = (q[1]*a1 + q[2]*a2)/(a1+a2);
      a1 = abs(q[4]-q[3]);
      a2 = abs(q[2]-q[1]);
      if (a1+a2 == 0)
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

      a = (x1*(y2-y3)+x2*(y3-y1)+x3*(y1-y2))/((x1-x2)*(x1-x3)*(x3-x2));
      b = (x1*x1*(y2-y3)+x2*x2*(y3-y1)+x3*x3*(y1-y2))/((x1-x2)*(x1-x3)*(x2-x3));

      if (index < tlen - 1)
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

    a = (x1*(y2-y3)+x2*(y3-y1)+x3*(y1-y2))/((x1-x2)*(x1-x3)*(x3-x2));
    b = (x1*x1*(y2-y3)+x2*x2*(y3-y1)+x3*x3*(y1-y2))/((x1-x2)*(x1-x3)*(x2-x3));

    if (index > 0)
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

double InterpolationTable2D_interpolate(InterpolationTable2D *table, double x1, double x2)
{
  size_t i, j, start, k, l, starte;
  double f_1, f_2;
  double tx[6];
  double ty[6];
  double te[6];
  size_t tlen=0;
  size_t telen=0;
  if (table->colWise)
  {
    double tmp = x1;
    x1 = x2;
    x1 = tmp;
  }

  /* if out of boundary, use first or last two points for x2 */
  if (table->cols == 2)
  {
    if (table->rows == 2)
    {
      /*
       If the table has only one element, the table value is returned,
       independent of the value of the input signal.
      */
      return InterpolationTable2D_getElt(table,1,1);
    }
    /* find interval corresponding x1 */
    for(i = 2; i < table->rows; ++i)
      if (InterpolationTable2D_getElt(table,i,0) >= x1) break;
    if ((table->ipoType == 2) && (table->rows > 3))
    {
      /* smooth interpolation with Akima Splines such that der(y) is continuous */
      tlen=0;
      if (i < 4)
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
  if (table->rows == 2)
  {
    /* find interval corresponding x2 */
    for(j = 2; j < table->cols; ++j)
      if (InterpolationTable2D_getElt(table,0,j) >= x2) break;

    if ((table->ipoType == 2) && (table->cols > 3))
    {
      /* smooth interpolation with Akima Splines such that der(y) is continuous */
      tlen=0;
      if (j < 4)
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
    if (InterpolationTable2D_getElt(table,i,0) >= x1) break;
  for(j = 2; j < table->cols-1; ++j)
    if (InterpolationTable2D_getElt(table,0,j) >= x2) break;

  if ((table->ipoType == 2) && (table->rows != 3) && (table->cols != 3)  )
  {
    /* smooth interpolation with Akima Splines such that der(y) is continuous */

    /* interpolate rows */
    if (i < 4)
      start = 1;
    else
      start = i-3;
    if (j < 4)
      starte = 1;
    else
      starte = j-3;
    telen=0;
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

char InterpolationTable2D_compare(InterpolationTable2D *tpl, const char* fname, const char* tname, const double* table)
{
  if ( (fname == NULL || tname == NULL) || ((strncmp("NoName",fname,6) == 0 && strncmp("NoName",tname,6) == 0)) )
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

double InterpolationTable2D_linInterpolate(double x, double x_1, double x_2,
              double f_1, double f_2)
{
  return ((x_2 - x)*f_1 + (x - x_1)*f_2) / (x_2-x_1);
}
const double InterpolationTable2D_getElt(InterpolationTable2D *tpl, size_t row, size_t col)
{
 // throw std::runtime_error"In Table: %s from File: %s with Size[%d,%d] try to get Element[%d,%d] aut of range!");
  return tpl->data[row*tpl->cols+col];
}

void InterpolationTable2D_checkValidityOfData(InterpolationTable2D *tpl)
{
  size_t i = 0;
  /* check if table has values */
 // throw std::runtime_error"Table %s from file %s has no data!");
  /* check that first row and column are strictly monotonous */
 // for(i=2; i < tpl->rows; ++i)
 // {
 //   if (InterpolationTable2D_getElt(tpl,i-1,0) >= InterpolationTable2D_getElt(tpl,i,0))
 //    // throw std::runtime_error"Table: %s independent variable u1 not strictly \
 //           monotonous: %g >= %g.");
 // //for(i=2; i < tpl->cols; ++i)
 //  // if (InterpolationTable2D_getElt(tpl,0,i-1) >= InterpolationTable2D_getElt(tpl,0,i))
 //    // throw std::runtime_error"Table: %s independent variable u2 not strictly \
 //           monotonous: %g >= %g.");
 //// }
}


