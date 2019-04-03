#include <stdio.h>
#include <stdlib.h> /* for Linux malloc and exit */
#include <string.h>

/* External object.
 * Implementation based on example in
 * Modelica Language Specification v.2.2 on page 113-114
 */

#include "ExtObj.h"

#define MATRIX_ROW_BUFSIZE 4000

/* Constructor
 * File format is the same as Tables.mo
 *
 * #1
 * double A(2,2)
 *   1 0
 *   0 1
 * double M(3,3)
 *   1 2 3
 *   3 4 5
 *   1 1 1
 *
 */

void* initMyTable(const char* fileName, const char* tableName, const double* dummyTable, size_t dummySize)
{
  double f;
  int r,c,foundTable=0;
  int dim1,dim2,i;

  FILE *file;

  char buf[MATRIX_ROW_BUFSIZE ];
  MyTable* table = (MyTable*)malloc(sizeof(MyTable));
  if ( table == NULL ) printf("Not enough memory");
  // read table from file and store all data in *table

  file = fopen(fileName,"r");
  if(!file) {
    printf("Error opening file %s\n",fileName);
    exit(-2);
  }
  if (fgetc(file) != '#' || fgetc(file) != '1') {
    printf("Error, wrong table format. File must begin with \"#1\"\n");
    exit(-2);
  }

  while(fgets(buf,MATRIX_ROW_BUFSIZE ,file)) {
    if (strncmp(buf,"double",6) == 0) {
      char*name; char*dim1Str;char*dim2Str;
      name = strtok(&buf[6],"(,) ");
      if(strcmp(name,tableName)==0) { // Found table
  foundTable=1;
  dim1Str = strtok(NULL,"(,) ");
  dim2Str = strtok(NULL,"(,) ");
  dim1 = atoi(dim1Str);
  dim2 = atoi(dim2Str);
  if (dim1<1 || dim2 < 1) {
    printf("Error, illegal matrix dimensions: [%d,%d]\n",dim1,dim2);
    exit(-2);
  }
  table->array = (double*)malloc(dim1*dim2*sizeof(double));
  if(!table->array) {
    printf("Error allocating array in myTable\n");
    exit(-2);
  }
  for (r=0,i=0; r < dim1; r++) {
    for (c = 0; c < dim2; c++) {
      if (fscanf(file,"%le",&f) != 1) {
        printf("error reading double value near: %s\n",buf);
        exit(-2);
      }
      table->array[i++]=f;
    }
  }
  break;
      }
    }
  }
  if (!foundTable) {
    printf("Error, table named %s not found in file %s\n",tableName,fileName);
    exit(-2);
  }

  table->nrow = dim1;
  table->ncol = dim2;
  table->type = 1; // currently only supports linear interpolation.
  table->lastIndex = 0;
  return (void*) table;
}

/* Destructor */
void closeMyTable(void* object)
{
  /* Release table storage */
  MyTable* table = (MyTable*) object;
  if ( object == NULL ) return;
  free(table->array);
  free(table);
}

/* Interpolation in table*/
double interpolateMyTable(void* object, double u)
{
  MyTable* table = (MyTable*) object;
  double y;
  int i,n;
  double u1,u2,y1,y2;
  if(!table->array) { printf("Error, table object is not initialized\n");
    exit(-2);
  }
  if (table->ncol != 2) {
    printf("Error, table dimension (%d,%d) is not [:,2]\n",
     table->nrow,table->ncol);
    exit(-2);
  }

  /* Translated from Modelica.Math.tempInterpol */
  n = table->nrow;

  if (n <= 1) {
    y = table->array[1];
  } else {
    // Search interval

    if (u <= table->array[0]) {
      i = 0;
    } else {
      i = 1;
      // Supports duplicate table[i, 1] values
      // in the interior to allow discontinuities.
      // Interior means that
      // if table[i, 1] = table[i+1, 1] we require i>1 and i+1<n

      while (i < n-1 && u >= table->array[i*2]) {
        i = i + 1;
      }
      i = i - 1;
    }
    // Get interpolation data
    u1 = table->array[i*2];
    u2 = table->array[(i + 1)*2];
    y1 = table->array[i*2+1];
    y2 = table->array[(i + 1)*2+1];

    if (u2 < u1)
    {
      printf("Table index must be increasing, u1=%f, u2=%f\n", u1, u2);
      exit(-2);
    }
    // Interpolate
    y = y1 + (y2 - y1)*(u - u1)/(u2 - u1);
  }
  return y;
}
