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

#include "util/omc_error.h"
#include "simulation_data.h"
#include "openmodelica_func.h"
#include "simulation/solver/external_input.h"
#include "simulation/options.h"
#include "simulation/solver/model_help.h"
#include <iostream>
#include <sstream>
#include <string>
#include <fstream>
#include <vector>
#include <algorithm>
#include <iomanip>
#include <stdlib.h>
#include <math.h>
#include <ctime>
#include "omc_config.h"
#include <boost/math/distributions/chi_squared.hpp>
using boost::math::chi_squared;
#include "dataReconciliation.h"

extern "C"
{
int dgesv_(int *n, int *nrhs, double *a, int *lda, int *ipiv, double *b, int *ldb, int *info);
int dgemm_(char *transa, char *transb, int *m, int *n, int *k, double *alpha, double *a, int *lda,
		double *b, int *ldb, double *beta, double *c, int *ldc);
int dgetrf_(int *m, int *n, double *a, int *lda, int *ipiv, int *info);
int dgetri_(int *n, double *a, int *lda, int *ipiv, double *work, int *lwork, int *info);
int dscal_(int *n, double *da, double *dx, int *incx);
int dcopy_(int *n, double *dx, int *incx, double *dy, int *incy);
}


using namespace std;

extern "C" {


struct csvData {
	int linecount;
	int rowcount;
	int columncount;
	vector<double> rowdata;
	vector<string> headers;
};

struct matrixData {
	int rows;
	int column;
	double * data;
};

struct inputData {
	int rows;
	int column;
	double * data;
	vector<int> index;
};

/*
 * Function which reads the csv file
 * and stores the covariance matrix Sx for DataReconciliation
 */
csvData readcsvfiles(const char * filename, ofstream & logfile)
{
	ifstream ip(filename);
	string line;
	vector<double> vals;
	vector<string> names;
	int Sxrowcount=0;
	int linecount=1;
	int Sxcolscount=0;
	bool flag=false;
	int myarraycount=0;
	if(!ip.good())
	{
		//errorStreamPrint(LOG_STDOUT, 0, "file name not found %s.",filename);
		logfile << "|  error   |   " << "file name not found " << filename << "\n";
		logfile.close();
		exit(1);
	}
	while(ip.good())
	{
		getline(ip,line);
		if(linecount>1 && !line.empty())
		{
			//cout << "array info:" << line << "\n";
			std::replace(line.begin(), line.end(), ';', ' ');
			std::replace(line.begin(), line.end(), ',', ' ');
			stringstream ss(line);
			string temp;
			int skip=0;
			while(ss >> temp){
				if(skip==0)
				{
					names.push_back(temp.c_str());
					Sxrowcount++;
				}
				if(skip>0){
					//cout << "check temp:" << temp << " double" << atof(temp.c_str()) <<"\n";
					vals.push_back(atof(temp.c_str()));
					if(flag==false){
						Sxcolscount++;
					}
				}
				skip++;
			}
			flag=true;
			//Sxrowcount++;
		}
		linecount++;
	}
	//cout << "csvdata header:" << names[0] << names[1] << names[2] << "";
	//cout << "linecount:" << linecount << " " << "rowcount :" << Sxrowcount << " " << "colscount:" << Sxcolscount << "\n";
	csvData  data={linecount,Sxrowcount,Sxcolscount,vals,names};
	return data;
}

/*
 * Function which arranges the elements in column major
 */
void initColumnMatrix(vector<double> data, int rows, int cols, double * tempSx)
{
	for (int i=0; i<rows; i++)
	{
		for (int j=0; j<cols;j++)
		{
			// store the matrix in column order
			tempSx[j+i*rows]=data[i+j*rows];
		}
	}
}

/*
 * Function to print and debug whether the matrices are stored in column major
 */
void printColumnAlginment(double * matrix, int rows, int cols, string name)
{
	cout << "\n" << "************ "<< name << " **********" << "\n";
	for (int i=0; i < rows*cols ; i++)
	{
		cout << matrix[i] << " ";
	}
	cout << "\n";
}

/*
 * Function to Print the matrix in row based format
 */
void printMatrix(double* matrix, int rows, int cols, string name, ofstream& logfile)
{
	logfile << "\n" << "************ "<< name << " **********" <<"\n";
	for (int i=0;i<rows; i++)
	{
		for (int j=0;j<cols;j++)
		{
			//cout << setprecision(5);
			logfile << std::right << setw(15) << matrix[i+j*rows];
			logfile.flush();
		}
		logfile << "\n";
	}
	logfile << "\n";
}

/*
 *
 Function to Print the matrix in row based format with headers
 */
void printMatrixWithHeaders(double* matrix, int rows, int cols, vector<string> headers, string name, ofstream& logfile)
{
	logfile << "\n" << "************ "<< name << " **********" <<"\n";
	for (int i=0;i<rows; i++)
	{
		logfile << std::right << setw(10) << headers[i];
		for (int j=0;j<cols;j++)
		{
			//cout << setprecision(5);
			logfile << std::right << setw(15) << matrix[i+j*rows];
			logfile.flush();
			//printf("% .5e ", matrix[i+j*rows]);
		}
		logfile << "\n";
	}
	logfile << "\n";
}

/*
 *
 Function Which gets the diagonal elements of the matrix
 */
void getDiagonalElements(double *matrix, int rows, int cols, double* result)
{
	int k=0;
	for (int i=0;i<rows; i++)
	{
		for (int j=0;j<cols;j++)
		{
			if(i==j)
			{
				result[k++] = matrix[i+j*rows];
			}
		}
	}
}

/*
 * Function to transpose the Matrix
 */
void transposeMatrix(double * jacF, double * jacFT, int rows, int cols)
{
	for (int i=0;i<rows; i++)
	{
		for (int j=0;j<cols;j++)
		{
			// Perform matrix transpose store the elements in column major
			jacFT[i*cols+j]= jacF[i+j*rows] ;
		}
	}
}


/*
 * Matrix Multiplication using dgemm LaPack routine
 */
void solveMatrixMultiplication(double *matrixA, double *matrixB, int rowsa, int colsa, int rowsb, int colsb , double *matrixC, ofstream & logfile)
{
	char trans = 'N';
	double one = 1.0, zero = 0.0;
	int rowsA = rowsa;
	int colsA = colsa;
	int rowsB = rowsb;
	int colsB = colsb;
	int common = colsa;

	if(colsA!=rowsB)
	{
		//cout << "\n Error: Column of First Matrix not equal to Rows  of Second Matrix \n ";
		//errorStreamPrint(LOG_STDOUT, 0, "solveMatrixMultiplication() Failed!, Column of First Matrix not equal to Rows of Second Matrix %i != %i.",colsA,rowsB);
		logfile << "|  error   |   " << "solveMatrixMultiplication() Failed!, Column of First Matrix not equal to Rows of Second Matrix " << colsA << " != "<< rowsB <<  "\n";
		logfile.close();
		exit(1);
	}
	// solve matrix multiplication using dgemm_ LAPACK routine
	dgemm_(&trans, &trans, &rowsA, &colsB, &common, &one, matrixA, &rowsA, matrixB, &common, &zero, matrixC, &rowsA);
}

/*
 * Solve the Linear System A*x=b using LAPACK Solver routine dgesv_
 */
void solveSystemFstar(int n, int nhrs, double * tmpMatrixD, double * tmpMatrixC, ofstream & logfile)
{
	int N=n; // number of rows of Matrix A
	int NRHS=nhrs;  // number of columns of Matrix B
	int LDA=N;
	int LDB=N;
	int ipiv[N];
	int info;
	// call the external function
	dgesv_( &N, &NRHS, tmpMatrixD, &LDA, ipiv, tmpMatrixC, &LDB, &info);
	if( info > 0 ) {
		//cout << "The solution could not be computed, The info satus is : " << info;
		//errorStreamPrint(LOG_STDOUT, 0, "solveSystemFstar() Failed !, The solution could not be computed, The info satus is %i.", info);
		logfile << "|  error   |   " << "solveSystemFstar() Failed !, The solution could not be computed, The info satus is" << info << "\n";
		logfile.close();
		exit(1);
	}
}

/*
 * Solve the matrix Subtraction of two matrices
 */
void solveMatrixSubtraction(matrixData A, matrixData B, double * result, ofstream & logfile)
{
	if(A.rows!=B.rows && A.column!=B.column)
	{
		//cout << "The Matrix Dimensions are not equal to Compute ! \n";
		//errorStreamPrint(LOG_STDOUT, 0, "solveMatrixSubtraction() Failed !, The Matrix Dimensions are not equal to Compute ! %i != %i.", A.rows,B.rows);
		logfile << "|  error   |   " << "solveMatrixSubtraction() Failed !, The Matrix Dimensions are not equal to Compute" << A.rows << " != " << B.rows << "\n";
		logfile.close();
		exit(1);
	}
	//printColumnAlginment(A.data,A.rows,A.column,"A-Matrix");
	//printColumnAlginment(B.data,B.rows,B.column,"B-Matrix");

	// subtract elements in cloumn major
	for(int i=0; i < A.rows*A.column; i++)
	{
		result[i]=A.data[i]-B.data[i];
	}
}

/*
 * Solve the matrix addition of two matrices
 */
matrixData solveMatrixAddition(matrixData A, matrixData B, ofstream & logfile)
{
	double* result = (double*)calloc(A.rows*A.column,sizeof(double));
	if(A.rows!=B.rows && A.column!=B.column)
	{
		//cout << "The Matrix Dimensions are not equal to Compute ! \n";
		//errorStreamPrint(LOG_STDOUT, 0, "solveMatrixAddition() Failed !, The Matrix Dimensions are not equal to Compute ! %i != %i.", A.rows,B.rows);
		logfile << "|  error   |   " << "solveMatrixAddition() Failed !, The Matrix Dimensions are not equal to Compute" << A.rows << " != " << B.rows << "\n";
		logfile.close();
		exit(1);
	}
	//printColumnAlginment(A.data,A.rows,A.column,"A-Matrix");
	//printColumnAlginment(B.data,B.rows,B.column,"B-Matrix");
	// Add the elements in cloumn major
	for(int i=0; i < A.rows*A.column; i++)
	{
		result[i]=A.data[i]+B.data[i];
	}
	matrixData tmpadd_a_b = {A.rows,A.column,result};
	return tmpadd_a_b;
}

/*
 * Function which Calculates the Matrix Multiplication
 * of (Sx*Ft)*Fstar
 */
matrixData Calculate_Sx_Ft_Fstar(matrixData Sx, matrixData Ft, matrixData Fstar, ofstream & logfile)
{
	// Sx*Ft
	double* tmpMatrixA = (double*)calloc(Sx.rows*Ft.column,sizeof(double));
	solveMatrixMultiplication(Sx.data,Ft.data,Sx.rows,Sx.column,Ft.rows,Ft.column,tmpMatrixA,logfile);
	//printMatrix1(tmpMatrixA,Sx.rows,Ft.column,"Reconciled-(Sx*Ft)");
	//printMatrix1(Fstar.data,Fstar.rows,Fstar.column,"REconciled-FStar");

	//(Sx*Ft)*Fstar
	double* tmpMatrixB = (double*)calloc(Sx.rows*Fstar.column,sizeof(double));
	solveMatrixMultiplication(tmpMatrixA,Fstar.data,Sx.rows,Ft.column,Fstar.rows,Fstar.column,tmpMatrixB,logfile);
	matrixData rhsdata= {Sx.rows,Fstar.column,tmpMatrixB};

	free(tmpMatrixA);
	free(tmpMatrixB);
	return rhsdata;
}

/*
 * Solves the system
 * recon_x = x - (Sx*Ft*fstar)
 */
matrixData solveReconciledX(matrixData x, matrixData Sx, matrixData Ft, matrixData Fstar, ofstream& logfile)
{
	// Sx*Ft
	double* tmpMatrixAf = (double*)calloc(Sx.rows*Ft.column,sizeof(double));
	solveMatrixMultiplication(Sx.data,Ft.data,Sx.rows,Sx.column,Ft.rows,Ft.column,tmpMatrixAf,logfile);
	//printMatrix(tmpMatrixAf,Sx.rows,Ft.column,"Sx*Ft");
	//(Sx*Ft)*fstar
	double* tmpMatrixBf = (double*)calloc(Sx.rows*Fstar.column,sizeof(double));
	solveMatrixMultiplication(tmpMatrixAf,Fstar.data,Sx.rows,Ft.column,Fstar.rows,Fstar.column,tmpMatrixBf,logfile);
	//printMatrix(tmpMatrixBf,Sx.rows,Fstar.column,"(Sx*Ft*fstar)");

	matrixData rhs= {Sx.rows,Fstar.column,tmpMatrixBf};
	//matrixData rhs = Calculate_Sx_Ft_Fstar(Sx,Ft,Fstar);

	double* reconciledX = (double*)calloc(x.rows*x.column,sizeof(double));
	solveMatrixSubtraction(x,rhs,reconciledX,logfile);
	//printMatrix(reconciledX,x.rows,x.column,"reconciled X^cap ===> (x - (Sx*Ft*fstar))");
	if(ACTIVE_STREAM(LOG_JAC))
	{
		logfile << "Calculations of Reconciled_x ==> (x - (Sx*Ft*f*))" << "\n";
		logfile << "====================================================";
		printMatrix(tmpMatrixAf,Sx.rows,Ft.column,"Sx*Ft",logfile);
		printMatrix(tmpMatrixBf,Sx.rows,Fstar.column,"(Sx*Ft*f*)",logfile);
		printMatrix(reconciledX,x.rows,x.column,"x - (Sx*Ft*f*))",logfile);
		logfile << "***** Completed ****** \n\n";
	}
	matrixData recon_x = {x.rows,x.column,reconciledX};
	//free(reconciledX);
	free(tmpMatrixAf);
	free(tmpMatrixBf);
	return recon_x;
}

/*
 * Solves the system
 * recon_Sx = Sx - (Sx*Ft*Fstar)
 */
matrixData solveReconciledSx(matrixData Sx, matrixData Ft, matrixData Fstar, ofstream& logfile)
{
	// Sx*Ft
	double* tmpMatrixA = (double*)calloc(Sx.rows*Ft.column,sizeof(double));
	solveMatrixMultiplication(Sx.data,Ft.data,Sx.rows,Sx.column,Ft.rows,Ft.column,tmpMatrixA, logfile);
	//printMatrix(tmpMatrixA,Sx.rows,Ft.column,"Reconciled-(Sx*Ft)");
	//printMatrix(Fstar.data,Fstar.rows,Fstar.column,"REconciled-FStar");

	//(Sx*Ft)*Fstar
	double* tmpMatrixB = (double*)calloc(Sx.rows*Fstar.column,sizeof(double));
	solveMatrixMultiplication(tmpMatrixA,Fstar.data,Sx.rows,Ft.column,Fstar.rows,Fstar.column,tmpMatrixB, logfile);
	//printMatrix(tmpMatrixB,Sx.rows,Fstar.column,"Reconciled-(Sx*Ft*Fstar)");

	matrixData rhs= {Sx.rows,Fstar.column,tmpMatrixB};

	//matrixData rhs = Calculate_Sx_Ft_Fstar(Sx,Ft,Fstar);
	double* reconciledSx = (double*)calloc(Sx.rows*Sx.column,sizeof(double));
	solveMatrixSubtraction(Sx,rhs,reconciledSx, logfile);
	//printMatrix(reconciledSx,Sx.rows,Sx.column,"reconciled Sx ===> (Sx - (Sx*Ft*Fstar))");
	if(ACTIVE_STREAM(LOG_JAC))
	{
		logfile << "Calculations of Reconciled_Sx ===> (Sx - (Sx*Ft*F*))" << "\n";
		logfile << "============================================";
		printMatrix(tmpMatrixA,Sx.rows,Ft.column,"(Sx*Ft)",logfile);
		printMatrix(tmpMatrixB,Sx.rows,Fstar.column,"(Sx*Ft*F*)",logfile);
		printMatrix(reconciledSx,Sx.rows,Sx.column,"Sx - (Sx*Ft*F*))",logfile);
		logfile << "***** Completed ****** \n\n";
	}
	matrixData recon_sx ={Sx.rows,Sx.column,reconciledSx};
	//free(reconciledSx);
	free(tmpMatrixA);
	free(tmpMatrixB);
	return recon_sx;
}

/*
 * Function Which Computes the
 * Jacobian Matrix F
 */
matrixData getJacobianMatrixF(DATA* data, threadData_t *threadData, ofstream & logfile)
{
	// initialize the jacobian call
	const int index = data->callback->INDEX_JAC_F;
	ANALYTIC_JACOBIAN* jacobian = &(data->simulationInfo->analyticJacobians[index]);
	data->callback->initialAnalyticJacobianF(data, threadData, jacobian);
	int cols = jacobian->sizeCols;
	int rows = jacobian->sizeRows;
	if(cols == 0) {
		//errorStreamPrint(LOG_STDOUT, 0, "Cannot Compute Jacobian Matrix F");
		logfile << "|  error   |   " << "Cannot Compute Jacobian Matrix F" << "\n";
		logfile.close();
		exit(1);
	}
	double* jacF = (double*)calloc(rows*cols,sizeof(double)); // allocate for Matrix F
	int k=0;
	for (int x=0; x < cols ; x++)
	{
		jacobian->seedVars[x] = 1.0;
		data->callback->functionJacF_column(data, threadData, jacobian, NULL);
		//cout << "Calculate one column\n:";
		for (int y=0; y < rows ; y++)
		{
			jacF[k++]=jacobian->resultVars[y];
		}
		jacobian->seedVars[x] = 0.0;
	}
	matrixData Fdata ={rows,cols,jacF};
	return Fdata;
}

/*
 * Function Which Computes the
 * Transpose of Jacobian Matrix FT
 */
matrixData getTransposeMatrix(matrixData jacF)
{
	int rows=jacF.column;
	int cols=jacF.rows;
	double* jacFT = (double*)calloc(rows*cols,sizeof(double)); // allocate for Matrix F-transpose
	int k=0;
	for (int i=0;i<jacF.rows; i++)
	{
		for (int j=0;j<jacF.column;j++)
		{
			// Perform matrix transpose store the elements in column major
			//cout << (i1*jacF.rows+j1) << " index :" << (i1+j1*jacF.rows) << " value is: " << jacF.data[i1+j1*jacF.rows] << "\n";
			jacFT[k++]= jacF.data[i+j*jacF.rows];

		}
	}
	matrixData Ft_data ={rows,cols,jacFT};
	return Ft_data;
}

/*
 * function which checks and reads
 * covariance matrix Sx from csv files
 * and stores the data in vector format
 */
csvData readCovarianceMatrixSx(DATA* data, threadData_t *threadData, ofstream & logfile)
{
	char * Sxfile = NULL;
	Sxfile = (char*)omc_flagValue[FLAG_DATA_RECONCILE_Sx];
	if(Sxfile==NULL)
	{
		//errorStreamPrint(LOG_STDOUT, 0, "Sx file not given (eg:-sx=filename.csv), DataReconciliation cannot be computed!.");
		logfile << "|  error   |   " << "Sx file not given (eg:-sx=filename.csv), DataReconciliation cannot be computed!.\n";
		logfile.close();
		exit(1);
	}
	csvData Sx_result=readcsvfiles(Sxfile,logfile);
	return Sx_result;
}

/*
 * Function which reads the vector
 * and assign to c pointer arrays
 */
matrixData getCovarianceMatrixSx(csvData Sx_result, DATA* data, threadData_t *threadData)
{
	double* tempSx = (double*)calloc(Sx_result.rowcount*Sx_result.columncount,sizeof(double));
	initColumnMatrix(Sx_result.rowdata , Sx_result.rowcount, Sx_result.columncount, tempSx);
	matrixData Sx_data = {Sx_result.rowcount,Sx_result.columncount,tempSx};
	return Sx_data;
}

/*
 * Function which reads the input data X from start Attribute
 * and also stores the index of input variables which are the
 * variables to be reconciled for Data Reconciliation
 */
inputData getInputDataFromStartAttribute(csvData Sx_result, matrixData Sx, DATA* data, threadData_t *threadData)
{
	double *tempx = (double*)calloc(Sx_result.rowcount,sizeof(double));
	char ** knowns = (char**)malloc(data->modelData->nInputVars * sizeof(char*));
	vector<int> index;
	data->callback->inputNames(data, knowns);
	int headercount = Sx_result.headers.size();
	/* Read data from input vars which has start attribute value set as input */
	for (int h=0; h < headercount; h++)
	{
		for (int in=0; in < data->modelData->nInputVars; in++)
		{
			if(strcmp(knowns[in], Sx_result.headers[h].c_str()) == 0)
			{
				tempx[h] = data->simulationInfo->inputVars[in];
				index.push_back(in);
				//cout << knowns[in] << "  start value :" << data->simulationInfo->inputVars[in] << "\n";
				//cout << "fetch index :" << in << "\n";
			}
		}
	}
	inputData x_data ={Sx_result.rowcount,1,tempx,index};
	free(knowns);
	return x_data;
}

/*
 * Function  which Copy Matrix
 * using dcopy_ LAPACK routine
 * this is mostly used when LAPACK routines override arrays
 */
matrixData copyMatrix(matrixData matdata)
{
	double * tmpcopymatrix = (double*)calloc(matdata.rows*matdata.column,sizeof(double));
	int n = matdata.rows*matdata.column;
	int inc = 1;
	dcopy_(&n,matdata.data,&inc,tmpcopymatrix,&inc);

	//  for (int i=0; i < matdata.rows*matdata.column; i++)
	//  {
	//	  tmpcopymatrix[i]=matdata.data[i];
	//  }
	matrixData tmpcopymatrixdata = {matdata.rows, matdata.column, tmpcopymatrix};
	return tmpcopymatrixdata;
}

/*
 * Function which scales the MAtrix with constant
 * dscal_ LAPACK_routine and result is updated in data
 * eg: alpha = 2, data=[2,4,5]
 * result = [4,8,10]
 */
void scaleVector(int rows, int cols, double alpha, double * data)
{
	int n=rows*cols;
	int inc=1;
	dscal_(&n, &alpha, data, &inc);
}

/*
 * Function which calculates the square root of elements
 * eg : a=[1,2,3,4]
 * result a = [srt(1),sqrt(2).......]
 */
void calculateSquareRoot(double * data, int length)
{
	for(int i=0; i<length; i++)
	{
		data[i]=sqrt(data[i]);
	}
}

/*
 * Function which calculates
 * J*=(recon_x-x)T*(Sx^-1)*(recon_x-x)+2.[f+F*(recon_x-x)]T*fstar
 * where T= transpose of matrix
 * and returns the converged value
 */

double solveConvergence(DATA* data, matrixData conv_recon_x, matrixData conv_recon_sx, inputData conv_x, matrixData conv_sx, matrixData conv_jacF, matrixData conv_vector_c, matrixData conv_fstar, ofstream & logfile)
{

	//printMatrix(conv_vector_c.data,conv_vector_c.rows,conv_vector_c.column,"Convergence_C(x,y)");
	//printMatrix(conv_fstar.data,conv_fstar.rows,conv_fstar.column,"Convergence_f*");
	//printMatrix(conv_recon_x.data,conv_recon_x.rows,conv_recon_x.column,"check_recon_x*");

	// calculate(recon_x-x)
	double* conv_data1 = (double*)calloc(conv_x.rows*conv_x.column,sizeof(double));
	matrixData conv_inputs = {conv_x.rows,conv_x.column,conv_x.data};
	solveMatrixSubtraction(conv_recon_x,conv_inputs,conv_data1,logfile);
	matrixData conv_data1result={conv_x.rows,conv_x.column,conv_data1};
	matrixData copy_reconx_x = copyMatrix(conv_data1result);

	//printMatrix(conv_inputs.data,conv_inputs.rows,conv_inputs.column,"check_inputs");
	//printMatrix(conv_data1result.data,conv_data1result.rows,conv_data1result.column,"(recon_X - X)");

	// calculate Transpose_(recon_x-x)
	matrixData conv_data1Transpose = getTransposeMatrix(conv_data1result);
	//printMatrix(conv_data1Transpose.data,conv_data1Transpose.rows,conv_data1Transpose.column,"Transpose(recon_X - X)");

	/* solves (Sx^-1)*(recon_x-x)
	 * Solve the inverse of matrix Sx using linear form
	 * Ax=b
	 * where A=Sx and b= (recon_x-x) to avoid inversion of Sx which is
	 * expensive
	 */
	solveSystemFstar(conv_sx.rows,1,conv_sx.data,conv_data1result.data,logfile);
	//printMatrix(conv_data1result.data,conv_sx.rows,conv_data1result.column,"inverse multiplication_without inverse");

	double *conv_tmpmatrixlhs = (double*)calloc(conv_data1Transpose.rows*conv_data1result.column,sizeof(double));
	/*
	 * Solve (recon_x-x)T*(Sx^-1)*(recon_x-x)
	 */
	solveMatrixMultiplication(conv_data1Transpose.data,conv_data1result.data,conv_data1Transpose.rows,conv_data1Transpose.column,conv_data1result.rows,conv_data1result.column,conv_tmpmatrixlhs,logfile);
	//printMatrix(conv_tmpmatrixlhs,conv_data1Transpose.rows,conv_data1result.column,"(recon_x-x)T*(Sx^-1)*(recon_x-x)");
	matrixData struct_conv_tmpmatrixlhs = {conv_data1Transpose.rows,conv_data1result.column,conv_tmpmatrixlhs};

	/*
	 * Solve rhs = 2.[f+F*(recon_x-x)]T*fstar
	 *
	 */
	// Calculate F*(recon_x-x)
	double * tmp_F_recon_x_x = (double*)calloc(conv_jacF.rows*copy_reconx_x.column,sizeof(double));
	solveMatrixMultiplication(conv_jacF.data, copy_reconx_x.data, conv_jacF.rows, conv_jacF.column, copy_reconx_x.rows, copy_reconx_x.column,tmp_F_recon_x_x, logfile);
	//printMatrix(tmp_F_recon_x_x,conv_jacF.rows,copy_reconx_x.column,"F*(recon_x-x)");
	matrixData mult_F_recon_x_x = {conv_jacF.rows,copy_reconx_x.column,tmp_F_recon_x_x};

	// Calculate f + F*(recon_x-x)
	matrixData add_f_F_recon_x_x = solveMatrixAddition(conv_vector_c, mult_F_recon_x_x, logfile);
	//printMatrix(add_f_F_recon_x_x.data,add_f_F_recon_x_x.rows,add_f_F_recon_x_x.column,"f + F*(recon_x-x)");

	matrixData transpose_add_f_F_recon_x_x = getTransposeMatrix(add_f_F_recon_x_x);
	//printMatrix(transpose_add_f_F_recon_x_x.data,transpose_add_f_F_recon_x_x.rows,transpose_add_f_F_recon_x_x.column,"transpose-[f + F*(recon_x-x)]");

	// calculate [f + F*(recon_x-x)]T*fstar
	double *conv_tmpmatrixrhs = (double*)calloc(transpose_add_f_F_recon_x_x.rows*conv_fstar.column,sizeof(double));
	solveMatrixMultiplication(transpose_add_f_F_recon_x_x.data, conv_fstar.data, transpose_add_f_F_recon_x_x.rows, transpose_add_f_F_recon_x_x.column, conv_fstar.rows, conv_fstar.column, conv_tmpmatrixrhs, logfile);
	//printMatrix(conv_tmpmatrixrhs, transpose_add_f_F_recon_x_x.rows, conv_fstar.column,"[f + F*(recon_x-x)]*fstar");

	// scale the matrix with 2*[f + F*(recon_x-x)]T*fstar
	scaleVector(transpose_add_f_F_recon_x_x.rows , conv_fstar.column, 2.0, conv_tmpmatrixrhs);
	//printMatrix(conv_tmpmatrixrhs, transpose_add_f_F_recon_x_x.rows, conv_fstar.column,"2*[f + F*(recon_x-x)]*fstar");
	matrixData struct_conv_tmpmatrixrhs= {transpose_add_f_F_recon_x_x.rows, conv_fstar.column,conv_tmpmatrixrhs};

	/*
	 * solve the final J*=J*=(recon_x-x)T*(Sx^-1)*(recon_x-x)+2.[f+F*(recon_x-x)]T*fstar
	 * J*=_struct_conv_tmpmatrixlhs + struct_conv_tmpmatrixrhs
	 */
	matrixData struct_Jstar= solveMatrixAddition(struct_conv_tmpmatrixlhs,struct_conv_tmpmatrixrhs, logfile);
	//printMatrix(struct_Jstar.data,struct_Jstar.rows,struct_Jstar.column,"J*",logfile);

	int r=data->modelData->nSetcVars; // number of setc equations
	double val=1.0/r;

	/*
	 * calculate J/r < epselon
	 */
	scaleVector(struct_Jstar.rows,struct_Jstar.column,val,struct_Jstar.data);
	//printMatrix(struct_Jstar.data,struct_Jstar.rows,struct_Jstar.column,"J*/r ");
	double convergedvalue=struct_Jstar.data[0];

	//  free(struct_Jstar.data);
	//  free(struct_conv_tmpmatrixrhs.data);
	//  free(conv_tmpmatrixrhs);
	//  free(transpose_add_f_F_recon_x_x.data);
	//  free(add_f_F_recon_x_x.data);
	//  free(transpose_add_f_F_recon_x_x.data);
	//  free(mult_F_recon_x_x.data);
	//  free(tmp_F_recon_x_x);
	//  free(struct_conv_tmpmatrixlhs.data);
	//  free(conv_tmpmatrixlhs);
	//  free(conv_data1Transpose.data);
	//  free(copy_reconx_x.data);
	//  free(conv_data1result.data);
	//  free(conv_data1);

	return convergedvalue;
}

/*
 * Example Function which performs matrix inverse
 * using dgetri_ and dgetrf_ LAPACK routine
 * which is expensive one and not recommended
 * use it when no other way to compute it
 */
void checkExpensiveMatrixInverse()
{
	double  newval[3*3]={3,2,0,
			0,0,1,
			2,-2,1};

	int N=3;
	int LDA=N;
	int LDB=N;
	int ipiv[N];
	int info=1;
	int LWORK =N;
	double * WORK = (double*)calloc(LWORK,sizeof(double));

	dgetrf_(&N,&N,newval,&N,ipiv,&info);
	dgetri_(&N,newval,&N,ipiv,WORK,&LWORK,&info);
	//printMatrix(newval,3,3,"Expensive_Matrix_Inverse");
}

/*
 * Function which performs matrix inverse without performing
 * actual matrix inverse, Instead use the dgesv to get result
 * Ax=b where matrix mutiplication of x=bA gives the inversed
 * mutiplication result b with A inverse
 */
void checkInExpensiveMatrixInverse(ofstream & logfile)
{
	double newchecksx[3*3]={1,1,1,
			0,0.95,0,
			0,0,0.95};
	double checksx[3*1]={-0.028,0.026,-0.004};
	solveSystemFstar(3,1,newchecksx,checksx,logfile);
	//printMatrix(checksx,3,1,"InExpensive_Matrix_Inverse");
}

int RunReconciliation(DATA* data, threadData_t *threadData, inputData x, matrixData Sx, matrixData tmpjacF, matrixData tmpjacFt, double eps, int iterationcount, vector<string> headers, matrixData xdiag, matrixData sxdiag, ofstream& logfile)
{
	// set the inputs first
	for (int i=0; i< x.rows*x.column; i++)
	{
		data->simulationInfo->inputVars[x.index[i]]=x.data[i];
		//cout << "input data:" << x.data[i]<<"\n";
	}
	data->callback->input_function_updateStartValues(data, threadData);
	data->callback->input_function(data, threadData);

	data->callback->functionDAE(data,threadData);
	//data->callback->functionODE(data,threadData);
	data->callback->setc_function(data, threadData);

	matrixData jacF = getJacobianMatrixF(data,threadData,logfile);
	matrixData jacFt = getTransposeMatrix(jacF);

	printMatrix(jacF.data,jacF.rows,jacF.column,"F",logfile);
	printMatrix(jacFt.data,jacFt.rows,jacFt.column,"Ft",logfile);


	double* setc = (double*)calloc(data->modelData->nSetcVars,sizeof(double)); // allocate data for setc array
	// store the setc data to compute for convergence as setc will be overriddeen with new values
	double* tmpsetc = (double*)calloc(data->modelData->nSetcVars,sizeof(double));

	/* loop to store the data C(x,y) rhs side, get the elements in reverse order */
	int t=0;
	for (int i=data->modelData->nSetcVars; i > 0; i--)
	{
		setc[t]=data->simulationInfo->setcVars[i-1];
		tmpsetc[t]=data->simulationInfo->setcVars[i-1];
		t++;
		//cout << "array_setc_vars:=>" << t << ":" << data->simulationInfo->setcVars[i-1] << "\n";
	}

	int nsetcvars= data->modelData->nSetcVars;
	matrixData vector_c = {nsetcvars,1,tmpsetc};
	//allocate data for matrix multiplication F*Sx
	double * tmpmatrixC = (double*)calloc(jacF.rows*Sx.column,sizeof(double));
	solveMatrixMultiplication(jacF.data,Sx.data,jacF.rows,jacF.column,Sx.rows,Sx.column,tmpmatrixC,logfile);
	//printMatrix(tmpmatrixC,jacF.rows,Sx.column,"F*Sx");

	//allocate data for matrix multiplication (F*Sx)*Ftranspose
	double * tmpmatrixD = (double*)calloc(jacF.rows*jacFt.column,sizeof(double));
	solveMatrixMultiplication(tmpmatrixC,jacFt.data,jacF.rows,Sx.column,jacFt.rows,jacFt.column,tmpmatrixD,logfile);
	//printMatrix(tmpmatrixD,jacF.rows,jacFt.column,"F*Sx*Ft");
	//printMatrix(setc,nsetcvars,1,"c(x,y)");
	/*
	 * Copy tmpmatrixC and tmpmatrixD to avoid loss of data
	 * when calculating F*
	 */
	matrixData cpytmpmatrixC = {jacF.rows,Sx.column,tmpmatrixC};
	matrixData cpytmpmatrixD = {jacF.rows,jacFt.column,tmpmatrixD};
	matrixData tmpmatrixC1 = copyMatrix(cpytmpmatrixC);
	matrixData tmpmatrixD1 = copyMatrix(cpytmpmatrixD);

	if(ACTIVE_STREAM(LOG_JAC))
	{
		logfile << "Calculations of Matrix (F*Sx*Ft) f* = c(x,y) " << "\n";
		logfile << "============================================\n";
		printMatrix(tmpmatrixC,jacF.rows,Sx.column,"F*Sx",logfile);
		printMatrix(tmpmatrixD,jacF.rows,jacFt.column,"F*Sx*Ft",logfile);
		printMatrix(setc,nsetcvars,1,"c(x,y)",logfile);
	}
	/*
	 * calculate f* for covariance matrix (F*Sx*Ftranspose).F*= c(x,y)
	 * matrix setc will be overridden with new values which is the output
	 * for the calculation A *x =B
	 * A = tmpmatrixD
	 * B = setc
	 */
	solveSystemFstar(jacF.rows,1,tmpmatrixD,setc,logfile);
	//printMatrix(setc,jacF.rows,1,"f*");
	if(ACTIVE_STREAM(LOG_JAC))
	{
		printMatrix(setc,jacF.rows,1,"f*",logfile);
		logfile << "***** Completed ****** \n\n";
	}
	matrixData tmpxcap ={x.rows,1,x.data};
	matrixData tmpfstar = {jacF.rows,1,setc};
	matrixData reconciled_X = solveReconciledX(tmpxcap,Sx,jacFt,tmpfstar,logfile);
	//printMatrix(reconciled_X.data,reconciled_X.rows,reconciled_X.column,"reconciled_X ===> (x - (Sx*Ft*fstar))");
	if(ACTIVE_STREAM(LOG_JAC))
	{
		logfile << "Calculations of Matrix (F*Sx*Ft) F* = F*Sx " << "\n";
		logfile << "===============================================\n";
		//printMatrix(tmpmatrixC,jacF.rows,Sx.column,"F*Sx");
		//printMatrix(tmpmatrixD,jacF.rows,jacFt.column,"F*Sx*Ft");
		printMatrix(tmpmatrixC1.data,tmpmatrixC1.rows,tmpmatrixC1.column,"F*Sx",logfile);
		printMatrix(tmpmatrixD1.data,tmpmatrixD1.rows,tmpmatrixD1.column,"F*Sx*Ft",logfile);
	}
	/*
	 * calculate F* for covariance matrix (F*Sx*Ftranspose).F*= (F*Sx)
	 * tmpmatrixC1 will be overridden with new values which is the output
	 * for the calculation A *x =B
	 * A = tmpmatrixD
	 * B = tmpmatrixC
	 */
	solveSystemFstar(jacF.rows,Sx.column,tmpmatrixD1.data,tmpmatrixC1.data,logfile);
	//printMatrix(tmpmatrixC,jacF.rows,Sx.column,"Sx_F*");
	if(ACTIVE_STREAM(LOG_JAC))
	{
		printMatrix(tmpmatrixC1.data,jacF.rows,Sx.column,"F*",logfile);
		logfile << "***** Completed ****** \n\n";
	}

	matrixData tmpFstar = {jacF.rows,Sx.column,tmpmatrixC1.data};
	matrixData reconciled_Sx = solveReconciledSx(Sx,jacFt,tmpFstar,logfile);
	//printMatrix(reconciled_Sx.data,reconciled_Sx.rows,reconciled_Sx.column,"reconciled Sx ===> (Sx - (Sx*Ft*Fstar))");

	double value = solveConvergence(data,reconciled_X,reconciled_Sx,x,Sx,jacF,vector_c,tmpfstar,logfile);
	if(value > eps )
	{
		logfile << "J*/r" << "(" << value << ")"  << " > " << eps << ", Value not Converged \n";
		logfile << "==========================================\n\n";
	}
	if(value > eps)
	{
		logfile << "Running Convergence iteration: " << iterationcount << " with the following reconciled values:" << "\n";
		logfile << "========================================================================" << "\n";
		//cout << "J*/r :=" << value << "\n";
		//printMatrix(jacF.data,jacF.rows,jacF.column,"F");
		//printMatrix(jacFt.data,jacFt.rows,jacFt.column,"Ft");
		//printMatrix(setc,jacF.rows,1,"f*");
		//printMatrix(tmpmatrixC,jacF.rows,Sx.column,"F*");
		printMatrixWithHeaders(reconciled_X.data,reconciled_X.rows,reconciled_X.column,headers,"reconciled_X ===> (x - (Sx*Ft*fstar))",logfile);
		printMatrixWithHeaders(reconciled_Sx.data,reconciled_Sx.rows,reconciled_Sx.column,headers,"reconciled_Sx ===> (Sx - (Sx*Ft*Fstar))",logfile);
		//free(x.data);
		//free(Sx.data);
		x.data=reconciled_X.data;
		//Sx.data=reconciled_Sx.data;
		iterationcount++;
		return RunReconciliation(data, threadData, x, Sx, jacF, jacFt,eps,iterationcount,headers,xdiag,sxdiag,logfile);
	}
	if(value < eps && iterationcount==1)
	{
		logfile << "J*/r" << "(" << value << ")"  << " > " << eps << ", Convergence iteration not required \n\n";
	}
	else
	{
		logfile << "***** Value Converged, Convergence Completed******* \n\n";
	}
	logfile << "Final Results:\n";
	logfile << "=============\n";
	logfile << "Total Iteration to Converge : " << iterationcount << "\n";
	logfile << "Final Converged Value(J*/r) : " << value << "\n";
	logfile << "Epsilon                     : " << eps << "\n";
	printMatrixWithHeaders(reconciled_X.data,reconciled_X.rows,reconciled_X.column,headers,"reconciled_X ===> (x - (Sx*Ft*fstar))",logfile);
	printMatrixWithHeaders(reconciled_Sx.data,reconciled_Sx.rows,reconciled_Sx.column,headers,"reconciled_Sx ===> (Sx - (Sx*Ft*Fstar))",logfile);

	/*
	 * Calculate half width Confidence interval
	 * W=lambda*sqrt(Sx)
	 * where lamba = 1.96 and
	 * Sx - diagonal elements of reconciled_Sx
	 */
	double* reconSx_diag = (double*)calloc(reconciled_Sx.rows*1,sizeof(double));
	getDiagonalElements(reconciled_Sx.data,reconciled_Sx.rows,reconciled_Sx.column,reconSx_diag);

	matrixData copyreconSx_diag = {reconciled_Sx.rows,1,reconSx_diag};
	matrixData tmpcopyreconSx_diag = copyMatrix(copyreconSx_diag);
	if(ACTIVE_STREAM(LOG_JAC))
	{
		logfile << "Calculations of HalfWidth Confidence Interval " << "\n";
		logfile << "===============================================\n";
		printMatrix(copyreconSx_diag.data,reconciled_Sx.rows,1,"reconciled-Sx_Diagonal",logfile);
	}
	calculateSquareRoot(copyreconSx_diag.data,reconciled_Sx.rows);
	if(ACTIVE_STREAM(LOG_JAC))
	{
		printMatrix(copyreconSx_diag.data,reconciled_Sx.rows,1,"reconciled-Sx_SquareRoot",logfile);
		logfile << "*****Completed***********\n";
	}
	scaleVector(reconciled_Sx.rows,1,1.96,copyreconSx_diag.data);
	printMatrixWithHeaders(copyreconSx_diag.data,reconciled_Sx.rows,1,headers,"Wx-HalfWidth-Interval-(1.96)*sqrt(Sx_diagonal)",logfile);


	/*
	 * Calculate individual tests
	 * (recon_x - x)/sqrt(Sx-recon_Sx)
	 */
	double* newSx_diag = (double*)calloc(reconciled_Sx.rows*1,sizeof(double));
	solveMatrixSubtraction(sxdiag,tmpcopyreconSx_diag,newSx_diag,logfile);
	if(ACTIVE_STREAM(LOG_JAC))
	{
		logfile << "Calculations of Individual Tests " << "\n";
		logfile << "===============================================\n";
		printMatrix(newSx_diag,sxdiag.rows,sxdiag.column,"Sx-recon_Sx",logfile);
	}
	calculateSquareRoot(newSx_diag,reconciled_Sx.rows);
	if(ACTIVE_STREAM(LOG_JAC))
	{
		printMatrix(newSx_diag,sxdiag.rows,sxdiag.column,"squareroot-newSx",logfile);
	}

	double *newX = (double*)calloc(xdiag.rows*1,sizeof(double));
	solveMatrixSubtraction(reconciled_X,xdiag,newX,logfile);
	// calculate absolute value for this numeric analysis
	for (unsigned int a=0; a < sizeof(newX); a++)
	{
		newX[a]=abs(newX[a]);
	}
	if(ACTIVE_STREAM(LOG_JAC))
	{
		printMatrix(newX,xdiag.rows,xdiag.column,"recon_X - X",logfile);
		logfile << "*********Completed***********\n";
	}

	for (int val=0; val < xdiag.rows; val++)
	{
		newX[val]=newX[val]/newSx_diag[val];
	}

	printMatrixWithHeaders(newX,xdiag.rows,xdiag.column,headers,"IndividualTests_Value- (recon_x-x)/sqrt(Sx_diag)",logfile);

	/*
	 * create HTML Report
	 */
	ofstream myfile;
	time_t now = time(0);
	std::stringstream htmlfile;
	htmlfile << data->modelData->modelName << ".html";
	string html= htmlfile.str();
	myfile.open(html.c_str());

	/* Add Overview Data */
	myfile << "<!DOCTYPE html><html>\n <head> <h1> DataReconciliation Report</h1></head> \n <body> \n ";
	myfile << "<h2> Overview: </h2>\n";
	myfile << "<table> \n";
	myfile << "<tr> \n" << "<th align=right> ModelFile: </th> \n" << "<td>" << data->modelData->modelFilePrefix << ".mo" << "</td> </tr>\n";
	myfile << "<tr> \n" << "<th align=right> ModelName: </th> \n" << "<td>" << data->modelData->modelName << "</td> </tr>\n";
	myfile << "<tr> \n" << "<th align=right> ModelDirectory: </th> \n" << "<td>" << data->modelData->modelDir << "</td> </tr>\n";
	myfile << "<tr> \n" << "<th align=right> Measurement Files: </th> \n" << "<td>" << omc_flagValue[FLAG_DATA_RECONCILE_Sx] << "</td> </tr>\n";
	myfile << "<tr> \n" << "<th align=right> Generated: </th> \n" << "<td>" << ctime(&now) << " by <b>OpenModelica-</b>"<< "<b>" << CONFIG_VERSION << "</b>" << "</td> </tr>\n";
	myfile << "</table>\n";

	/* Add Analysis data */
	myfile << "<h2> Analysis: </h2>\n";
	myfile << "<table> \n";
	myfile << "<tr> \n" << "<th align=right> Number of Extracted equations: </th> \n" << "<td>" << data->modelData->nSetcVars << "</td> </tr>\n";
	myfile << "<tr> \n" << "<th align=right> Number of Variables to be Reconciled: </th> \n" << "<td>" << headers.size() << "</td> </tr>\n";
	myfile << "<tr> \n" << "<th align=right> Number of Iteration to Converge: </th> \n" << "<td>" << iterationcount << "</td> </tr>\n";
	myfile << "<tr> \n" << "<th align=right> Final Converged Value(J*/r) : </th> \n" << "<td>" << value << "</td> </tr>\n";
	myfile << "<tr> \n" << "<th align=right> Epsilon : </th> \n" << "<td>" << eps << "</td> </tr>\n";
	myfile << "<tr> \n" << "<th align=right> Final Value of the objective Function (J*) : </th> \n" << "<td>" << (value*data->modelData->nSetcVars) << "</td> </tr>\n";
	myfile << "<tr> \n" << "<th align=right> Chi-square value : </th> \n" << "<td>" << quantile(complement(chi_squared(data->modelData->nSetcVars), 0.05)) << "</td> </tr>\n";
	myfile << "<tr> \n" << "<th align=right> Result of Global Test : </th> \n" << "<td>" << "TRUE" << "</td> </tr>\n";
	myfile << "</table>\n";

	/* Add Results data */
	myfile << "<h2> Results: </h2>\n";
	myfile << "<table border=2>\n";
	myfile << "<tr>\n" << "<th> Variables to be Reconciled </th>\n" << "<th> Initial Measured Values </th>\n" << "<th> Reconciled Values </th>\n" <<"<th> Reconciled Uncertainty Values </th>\n";
	myfile << "<th> Results of Local Tests </th>\n" << "<th> Values of Local Tests </th>\n" << "<th> Margin to Correctness(distance from 1.96) </th>\n" << "</tr>\n";

	for (unsigned int r=0; r < headers.size(); r++)
	{
		myfile << "<tr>\n";
		myfile << "<td>" << headers[r] << "</td>\n";
		myfile << "<td>" << xdiag.data[r] << "</td>\n";
		myfile << "<td>" << reconciled_X.data[r] << "</td>\n";
		myfile << "<td>" << copyreconSx_diag.data[r] << "</td>\n";
		if(newX[r] < 1.96)
		{
			myfile << "<td>" << "TRUE" << "</td>\n";
		}
		else
		{
			myfile << "<td>" << "FALSE" << "</td>\n";
		}
		myfile << "<td>" << newX[r] << "</td>\n";
		myfile << "<td>" << (1.96-newX[r]) << "</td>\n";
		myfile << "</tr>\n";
		myfile.flush();
	}

	myfile << "</table>\n";
	myfile << "</body>\n</html>";
	myfile.close();

	free(tmpFstar.data);
	free(tmpfstar.data);
	//free(tmpmatrixC);
	//free(tmpmatrixD);
	//free(setc);
	free(reconciled_Sx.data);
	free(reconciled_X.data);
	free(copyreconSx_diag.data);
	free(tmpcopyreconSx_diag.data);
	free(newSx_diag);
	free(newX);
	//free(jacF.data);
	//free(jacFt.data);
	//free(x.data);
	//free(Sx.data);
	return 0;
}


int dataReconciliation(DATA* data, threadData_t *threadData)
{
	TRACE_PUSH
	const char* epselon = NULL;
	epselon = (char*)omc_flagValue[FLAG_DATA_RECONCILE_Eps];

	/*
	 * Create a Debug Log file
	 */
	ofstream  logfile;
	std::stringstream logfilename;
	logfilename << data->modelData->modelName << "_debug.log";
	string tmplogfilename= logfilename.str();
	logfile.open(tmplogfilename.c_str());
	logfile << "|  info    |   " << "DataReconciliation Starting!\n";
	logfile << "|  info    |   " << data->modelData->modelName << "\n";

	if(epselon==NULL)
	{
		//errorStreamPrint(LOG_STDOUT, 0, "Epsilon Value not given, Please specify a convergence value (eg: -eps=0.0002), DataReconciliation cannot be computed!.");
		logfile << "|  error   |   " << "Epsilon Value not given, Please specify a convergence value (eg: -eps=0.0002), DataReconciliation cannot be computed!.\n";
		logfile.close();
		exit(1);
	}

	csvData Sx_data = readCovarianceMatrixSx(data, threadData, logfile);  // read the covariance matrix from csv files
	matrixData Sx = getCovarianceMatrixSx(Sx_data, data, threadData); // Prepare the data from csv file
	inputData x = getInputDataFromStartAttribute(Sx_data, Sx, data, threadData);  // Read the inputs from the start attribute of the modelica model
	matrixData jacF = getJacobianMatrixF(data, threadData, logfile); // Compute the Jacobian Matrix F
	matrixData jacFt = getTransposeMatrix(jacF); // Compute the Transpose of jacobian Matrix F

	double* Sx_diag = (double*)calloc(Sx.rows*1,sizeof(double));
	getDiagonalElements(Sx.data,Sx.rows,Sx.column,Sx_diag);
	matrixData tmpSx_diag={Sx.rows,1,Sx_diag};

	matrixData tmp_x={x.rows,x.column,x.data};
	matrixData x_diag=copyMatrix(tmp_x);

	// Print the initial information
	logfile << "\n\nInitial Data \n" << "=============\n";
	printMatrixWithHeaders(x.data,x.rows,x.column,Sx_data.headers,"X",logfile);
	printMatrixWithHeaders(Sx.data,Sx.rows,Sx.column,Sx_data.headers,"Sx",logfile);
	//printMatrix(Sx_diag,Sx.rows,1,"Sx-Diagonal elements",logfile);

	//printMatrix(jacF.data,jacF.rows,jacF.column,"F",logfile);
	//printMatrix(jacFt.data,jacFt.rows,jacFt.column,"Ft",logfile);
	// Start the Algorithm
	RunReconciliation(data,threadData,x,Sx,jacF,jacFt,atof(epselon),1,Sx_data.headers,x_diag,tmpSx_diag,logfile);
	logfile << "|  info    |   " << "DataReconciliation Completed! \n";
	logfile.close();
	free(Sx.data);
	free(x.data);
	free(jacF.data);
	free(jacFt.data);
	free(tmpSx_diag.data);
	free(x_diag.data);
	TRACE_POP
	return 0;
}

}
