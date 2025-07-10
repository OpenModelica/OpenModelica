#include "jacobian_analysis.h"

// LAPACK dense SVD routine
extern void dgesvd_(char *jobu, char *jobvt, int *m, int *n,
                    modelica_real *a, int *lda, modelica_real *s,
                    modelica_real *u, int *ldu, modelica_real *vt, int *ldvt,
                    modelica_real *work, int *lwork, int *info);

// cmp for sorting singular vectors by magnitude
static int cmp_fabs_desc(const void *a, const void *b)
{
    modelica_real abs_a = fabs(((SVD_Component*)a)->value);
    modelica_real abs_b = fabs(((SVD_Component*)b)->value);
    if (abs_a < abs_b) return 1;
    if (abs_a > abs_b) return -1;
    return 0;
}

/**
 * @brief Create and initialize SVD data structure for a given nonlinear system.
 *
 * Builds a dense matrix from a sparse pattern (if provided), applies scaling,
 * and allocates buffers for the SVD results (singular values and vectors).
 *
 * @param data         Pointer to the global simulation DATA structure.
 * @param nls_data     Pointer to the nonlinear system data.
 * @param values       Non-zero values of the sparse Jacobian (CSC format).
 * @param x_scale      Optional scaling factors for variables (NULL if not used).
 * @param f_scale      Optional scaling factors for residuals (NULL if not used).
 *
 * @return Pointer to an allocated SVD_DATA structure, or NULL on allocation failure.
 */
static SVD_DATA *svd_create(DATA *data, NONLINEAR_SYSTEM_DATA *nls_data, modelica_real *values, modelica_boolean scaled)
{
    SVD_DATA *svd_data = calloc(1, sizeof(SVD_DATA));
    if (!svd_data) return NULL;

    int rows = nls_data->size;
    int cols = nls_data->size;
    SPARSE_PATTERN *sparse_pattern = nls_data->sparsePattern;
    unsigned int *lead, *index;
    unsigned int row, column, nz;

    svd_data->data           = data;
    svd_data->nls_data       = nls_data;
    svd_data->rows           = rows;
    svd_data->cols           = cols;
    svd_data->sparse_pattern = sparse_pattern;
    svd_data->sp_values      = values;
    svd_data->min_rows_cols  = rows < cols ? rows : cols;
    svd_data->scaled         = scaled;

    svd_data->A_dense = calloc(rows * cols, sizeof(modelica_real));

    // for now, create dense matrix from sparse CSC
    if (sparse_pattern)
    {
        lead = sparse_pattern->leadindex;
        index = sparse_pattern->index;

        for (column = 0; column < cols; column++)
        {
            for (nz = lead[column]; nz < lead[column + 1]; nz++)
            {
                row = index[nz];
                svd_data->A_dense[column * rows + row] = values[nz];
            }
        }
    }
    else
    {
        memcpy(svd_data->A_dense, values, rows * cols * sizeof(modelica_real));
    }

    // allocate SVD result buffers
    svd_data->S = malloc(svd_data->min_rows_cols * sizeof(modelica_real));
    svd_data->U = malloc(rows * rows * sizeof(modelica_real));
    svd_data->VT = malloc(cols * cols * sizeof(modelica_real));

    return svd_data;
}

static void svd_free(SVD_DATA* svd_data)
{
    if (!svd_data) return;
    free(svd_data->A_dense);
    free(svd_data->S);
    free(svd_data->U);
    free(svd_data->VT);
    free(svd_data);
}

/**
 * @brief Computes the singular value decomposition (SVD) of a matrix using LAPACK's DGESVD.
 *
 * This function performs an SVD on the matrix stored in svd_data->A_dense,
 * producing singular values in svd_data->S and singular vectors in svd_data->U and svd_data->VT.
 *
 * @param svd_data Pointer to the structure containing SVD results and statistics.
 * @return LAPACK info code
 */
static int svd_compute_lapack(SVD_DATA* svd_data)
{
    int rows = svd_data->rows;
    int cols = svd_data->cols;
    int lda = rows;
    int ldu = rows;
    int ldvt = cols;
    int info;
    char jobu = 'A';
    char jobvt = 'A';
    modelica_real *work;

    // workspace query
    int lwork = -1;
    modelica_real wkopt;
    dgesvd_(&jobu, &jobvt, &rows, &cols,
            svd_data->A_dense, &lda,
            svd_data->S, svd_data->U, &ldu, svd_data->VT, &ldvt,
            &wkopt, &lwork, &info);

    if (info != 0) return info;

    lwork = (int)wkopt;
    work = malloc(sizeof(modelica_real) * lwork);

    // actual SVD, O(n^3)
    dgesvd_(&jobu, &jobvt, &rows, &cols,
            svd_data->A_dense, &lda,
            svd_data->S, svd_data->U, &ldu, svd_data->VT, &ldvt,
            work, &lwork, &info);

    return info;
}

/**
 * @brief Calculates statistics from the computed singular values.
 *
 * Updates condition number, estimated rank, and identifies the index of the first singular value
 * below 1% of the maximum singular value.
 *
 * @param svd_data Pointer to the structure containing SVD results and statistics.
 */
static void svd_calculate_statistics(SVD_DATA* svd_data)
{
    int dim, low, mid, high, first_below;
    modelica_real sigma_max, threshold;

    // condition statistics
    svd_data->sigma_max = svd_data->S[0];
    svd_data->sigma_min = svd_data->S[svd_data->min_rows_cols - 1];
    svd_data->cond = svd_data->sigma_min > 0.0 ? svd_data->sigma_max / svd_data->sigma_min : INFINITY;

    // rank estimation
    svd_data->estimated_rank = 0;
    svd_data->rank_est_tol = _svd_max2(svd_data->rows, svd_data->cols) * DBL_EPSILON * svd_data->sigma_max;
    for (dim = 0; dim < svd_data->min_rows_cols; dim++)
    {
        if (svd_data->S[dim] > svd_data->rank_est_tol)
        {
            svd_data->estimated_rank++;
        }
    }

    // binary search to find first singular value < threshold, O(log(n))
    sigma_max = svd_data->S[0];
    threshold = 0.01 * sigma_max;

    low = 0;
    high = svd_data->min_rows_cols - 1;
    first_below = svd_data->min_rows_cols;

    while (low <= high)
    {
        mid = (low + high) / 2;
        if (svd_data->S[mid] < threshold)
        {
            first_below = mid;
            high = mid - 1;
        }
        else
        {
            low = mid + 1;
        }
    }
    svd_data->least_one_percent = first_below;
}

/**
 * @brief Logs computed SVD statistics.
 *
 * Outputs singular value statistics such as condition number, estimated rank, and others.
 *
 * @param svd_data Pointer to the structure containing SVD results and statistics.
 * @param scaled If true: statistics are marked as scaled.
 */
static void svd_dump_statistics(const SVD_DATA *svd_data)
{
    int i, u, v, var_idx, eq_idx, start, end, count;
    modelica_real val;
    modelica_integer size_of_torns;
    SVD_Component *entries = (SVD_Component*)malloc(svd_data->rows * sizeof(SVD_Component));
    NONLINEAR_SYSTEM_DATA *nls_data = svd_data->nls_data;
    NONLINEAR_SOLVER solver = nls_data->nlsMethod;

    if (!svd_data || !svd_data->S) {
        infoStreamPrint(OMC_LOG_NLS_SVD, 1, "No SVD data available.");
        messageClose(OMC_LOG_NLS_SVD);
        return;
    }
    else
    {
        infoStreamPrint(OMC_LOG_NLS_SVD, 1, "%s: SVD analysis (scaled = %s).", NLS_NAME[solver], (svd_data->scaled ? "true" : "false"));
        infoStreamPrint(OMC_LOG_NLS_SVD, 1, "Matrix Info");
        infoStreamPrint(OMC_LOG_NLS_SVD, 0, "NLS eq index = %ld", nls_data->equationIndex);
        infoStreamPrint(OMC_LOG_NLS_SVD, 0, "Columns      = %ld", nls_data->size);
        infoStreamPrint(OMC_LOG_NLS_SVD, 0, "Rows         = %ld", nls_data->size);
        infoStreamPrint(OMC_LOG_NLS_SVD, 0, "NNZ          = %u", nls_data->sparsePattern->numberOfNonZeros);
        infoStreamPrint(OMC_LOG_NLS_SVD, 0, "Curr Time    = %-11.5e", svd_data->data->localData[0]->timeValue);

        messageClose(OMC_LOG_NLS_SVD);
    }

    // condition number
    infoStreamPrint(OMC_LOG_NLS_SVD, 1, "Matrix condition");
    infoStreamPrint(OMC_LOG_NLS_SVD, 0, "Cond(M) = %.8e", svd_data->cond);
    if (svd_data->cond > 1e12)
    {
        warningStreamPrint(OMC_LOG_NLS_SVD, 0, "Matrix is very ill-conditioned: 1e12 < Cond(M) = %.8e", svd_data->cond);
    }
    else if (svd_data->cond > 1e8)
    {
        warningStreamPrint(OMC_LOG_NLS_SVD, 0, "Matrix is fairly ill-conditioned: 1e8 < Cond(M) = %.8e < 1e12", svd_data->cond);
    }
    else if (svd_data->cond > 1e4)
    {
        warningStreamPrint(OMC_LOG_NLS_SVD, 0, "Matrix is moderately ill-conditioned: 1e4 < Cond(M) = %.8e < 1e8", svd_data->cond);
    }
    else
    {
        infoStreamPrint(OMC_LOG_NLS_SVD, 0, "Matrix is well conditioned: Cond(M) = %.8e < 1e4", svd_data->cond);
    }
    messageClose(OMC_LOG_NLS_SVD);

    // singular values
    infoStreamPrint(OMC_LOG_NLS_SVD, 1, "Singular values");
    for (i = 0; i < svd_data->min_rows_cols; i++)
    {
        infoStreamPrint(OMC_LOG_NLS_SVD, 0, "sigma_%-3d =  %.8e", i + 1, svd_data->S[i]);
    }
    messageClose(OMC_LOG_NLS_SVD);

    // rank estimation
    infoStreamPrint(OMC_LOG_NLS_SVD, 1, "Rank estimation");
    infoStreamPrint(OMC_LOG_NLS_SVD, 0, "estimated = %d", svd_data->estimated_rank);
    infoStreamPrint(OMC_LOG_NLS_SVD, 0, "actual    = %d", svd_data->min_rows_cols);
    infoStreamPrint(OMC_LOG_NLS_SVD, 0, "estimation tolerance = %.8e (= sigma_max * max(rows, cols) * DBL_EPSILON)", svd_data->rank_est_tol);
    if (svd_data->estimated_rank < svd_data->min_rows_cols)
    {
        infoStreamPrint(OMC_LOG_NLS_SVD, 0, "Matrix may be rank-deficient.");
    }
    else
    {
        infoStreamPrint(OMC_LOG_NLS_SVD, 0, "Matrix should have full rank.");
    }
    messageClose(OMC_LOG_NLS_SVD);

    // print right singular vectors for singular values below 1% of sigma_max
    infoStreamPrint(OMC_LOG_NLS_SVD, 1, "Smallest right singular vectors (variable space)");

    if (svd_data->least_one_percent == svd_data->min_rows_cols)
    {
        infoStreamPrint(OMC_LOG_NLS_SVD, 0, "No singular values below %.8e (1%% of max)", 0.01 * svd_data->sigma_max);
    }
    else
    {
        start = svd_data->min_rows_cols - 1;
        end   = svd_data->least_one_percent;
        count = start - end + 1;

        infoStreamPrint(OMC_LOG_NLS_SVD, 0,
            "Found %d singular %s below %.8e (1%% of sigma_max)", count, count > 1 ? "values" : "value", 0.01 * svd_data->sigma_max);

        for (v = start; v >= end; v--)
        {
            infoStreamPrint(OMC_LOG_NLS_SVD, 1, "V[:,%d] (singular value %.8e)", v + 1, svd_data->S[v]);

            entries = (SVD_Component*)malloc(svd_data->cols * sizeof(SVD_Component));
            for (i = 0; i < svd_data->cols; i++)
            {
                // V[i][v] = VT[v][i]
                entries[i].index = i;
                entries[i].value = svd_data->VT[v * svd_data->cols + i];
            }

            // sort by abs value descending O(n * log(n))
            qsort(entries, svd_data->cols, sizeof(SVD_Component), cmp_fabs_desc);

            for (i = 0; i < svd_data->cols; i++)
            {
                var_idx = entries[i].index;
                val = entries[i].value;
                infoStreamPrint(OMC_LOG_NLS_SVD, 0, "V[%d][%d] = %+.8e for NLS Var: %d with Name: %s", var_idx + 1, v + 1, val, var_idx + 1,
                                modelInfoGetEquation(&svd_data->data->modelData->modelDataXml, nls_data->equationIndex).vars[var_idx]);
            }

            messageClose(OMC_LOG_NLS_SVD);
        }
    }
    messageClose(OMC_LOG_NLS_SVD);

    // print left singular vectors for singular values below 1% of sigma_max
    infoStreamPrint(OMC_LOG_NLS_SVD, 1, "Smallest left singular vectors (function space)");

    if (svd_data->least_one_percent == svd_data->min_rows_cols)
    {
        infoStreamPrint(OMC_LOG_NLS_SVD, 0, "No singular values below %.8e (1%% of max)", 0.01 * svd_data->sigma_max);
    }
    else
    {
        start = svd_data->min_rows_cols - 1;
        end = svd_data->least_one_percent;
        count = start - end + 1;

        infoStreamPrint(OMC_LOG_NLS_SVD, 0,
            "Found %d singular %s below %.8e (1%% of sigma_max)", count, count > 1 ? "values" : "value", 0.01 * svd_data->sigma_max);

        for (u = start; u >= end; u--)
        {
            infoStreamPrint(OMC_LOG_NLS_SVD, 1, "U[:,%d] (singular value %.8e)", u + 1, svd_data->S[u]);

            for (i = 0; i < svd_data->rows; i++)
            {
                entries[i].index = i;
                entries[i].value = svd_data->U[i * svd_data->min_rows_cols + u];
            }

            // sort by abs value descending O(n * log(n))
            qsort(entries, svd_data->rows, sizeof(SVD_Component), cmp_fabs_desc);

            size_of_torns = nls_data->torn_plus_residual_size - nls_data->size;
            for (i = 0; i < svd_data->rows; i++)
            {
                eq_idx = entries[i].index;
                val = entries[i].value;

                infoStreamPrint(OMC_LOG_NLS_SVD, 0, "U[%d][%d] = %+.8e for NLS Eqn: %d with transformational debugger Idx: %d", eq_idx + 1, u + 1, val, eq_idx + 1,
                                nls_data->eqn_simcode_indices[size_of_torns + entries[i].index]);
            }

            messageClose(OMC_LOG_NLS_SVD);
        }
    }
    messageClose(OMC_LOG_NLS_SVD);

    free(entries);
    messageClose(OMC_LOG_NLS_SVD);
}

/**
 * @brief Main routine to compute the SVD of the Jacobian matrix.
 *
 * Creates the SVD data structure, performs the SVD, calculates statistics,
 * and outputs the results. Currently computes the unscaled SVD.
 *
 * @param data       Pointer to simulation data.
 * @param nls_data   Pointer to the nonlinear system data.
 * @param values     Pointer to the matrix values to decompose.
 * @param x_scale    Optional scaling factors for variables (can be NULL).
 * @param f_scale    Optional scaling factors for functions (can be NULL).
 * @return return code: 0 = success
 */
int svd_compute(DATA *data, NONLINEAR_SYSTEM_DATA *nls_data, modelica_real *values, modelica_boolean scaled)
{
    int ret = 0;

   /**
    * TODO: check how KINSOL scales variables internally!
    * better be sure! Does KINSOL apply J_newton := D_f * J_passed_by_om * D_x^{-1} or are these values
    * only used to modify the internal tolerances?
    **/

    /*
    // scaled
    SVD_DATA *svd_data = svd_create(sparse_pattern, values, rows, cols, x_scale, f_scale);
    svd_compute_lapack(svd_data);
    svd_calculate_statistics(svd_data);
    svd_dump_statistics(svd_data, !omc_flag[FLAG_NO_SCALING]);
    svd_free(svd_data);
    */

    // unscaled
    SVD_DATA *svd_data = svd_create(data, nls_data, values, scaled);
    ret = svd_compute_lapack(svd_data);
    if (ret != 0) return ret;
    svd_calculate_statistics(svd_data);
    svd_dump_statistics(svd_data);
    svd_free(svd_data);

    return ret;
}

// ================================ Sums of absolute values of Jacobian Columns and Rows ================================ //

// quick struct + cmp operator, to sort the arrays of col / row sums and keep their respective index
typedef struct {
  modelica_real value;
  int index;
} IndexedValue;

static int compare_desc(const void *a, const void *b) {
  modelica_real diff = ((IndexedValue*)b)->value - ((IndexedValue*)a)->value;
  return (diff > 0) - (diff < 0); // returns 1 if b > a, -1 if a > b
}

/**
 * @brief analyze absolute row and column sums of a sparse KINSOL Jacobian matrix
 *
 * computes the absolute row and column sums of a sparse Jacobian (CSC format)
 * and prints them sorted in descending order. This is useful for diagnosing
 * scaling issues, structural sparsity, or ill-conditioning in nonlinear systems.
 *
 * @param data
 * @param nlsData     pointer to nonlinear system data
 * @param J           sparse Jacobian matrix in CSC format
 * @param caller      caller of the method (solver + where in the code it was called)
 * @param scaled      boolean indicating if the passed Jacobian is scaled (only used for printout)
 */
void nlsJacobianRowColSums(DATA *data, NONLINEAR_SYSTEM_DATA *nlsData, SUNMatrix J,
                           SolverCaller caller, modelica_boolean scaled)
{
  int i, row, col, nz, count;
  modelica_real value;
  const int size = (int)nlsData->size;
  const int size_of_torns = (int)nlsData->torn_plus_residual_size - size;

  sunindextype nnz = SUNSparseMatrix_NNZ(J);

  sunindextype *colPointers = SM_INDEXPTRS_S(J);
  sunindextype *rowIndices = SM_INDEXVALS_S(J);
  realtype *values = SM_DATA_S(J);

  modelica_real *rowSumsRaw = (modelica_real*)calloc(size, sizeof(modelica_real));
  modelica_real *colSumsRaw = (modelica_real*)calloc(size, sizeof(modelica_real));
  IndexedValue *rowSums = (IndexedValue*)malloc(size * sizeof(IndexedValue));
  IndexedValue *colSums = (IndexedValue*)malloc(size * sizeof(IndexedValue));

  for (col = 0; col < size; col++)
  {
    for (nz = colPointers[col]; nz < colPointers[col + 1]; nz++)
    {
      row = rowIndices[nz];
      value = values[nz];

      rowSumsRaw[row] += fabs(value);
      colSumsRaw[col] += fabs(value);
    }
  }

  for (int i = 0; i < size; i++)
  {
    rowSums[i].value = rowSumsRaw[i];
    rowSums[i].index = i;

    colSums[i].value = colSumsRaw[i];
    colSums[i].index = i;
  }

  qsort(rowSums, size, sizeof(IndexedValue), compare_desc);
  qsort(colSums, size, sizeof(IndexedValue), compare_desc);

  infoStreamPrint(OMC_LOG_NLS_JAC_SUMS, 1, "%s: Jacobian absolute row & col sum analysis (scaled = %s, Caller: %s).",
                  SolverCaller_callerString(caller), scaled ? "true" : "false", SolverCaller_toString(caller));

  infoStreamPrint(OMC_LOG_NLS_JAC_SUMS, 1, "Matrix Info");
  infoStreamPrint(OMC_LOG_NLS_JAC_SUMS, 0, "NLS eq index = %ld", nlsData->equationIndex);
  infoStreamPrint(OMC_LOG_NLS_JAC_SUMS, 0, "Columns      = %d", size);
  infoStreamPrint(OMC_LOG_NLS_JAC_SUMS, 0, "Rows         = %d", size);
  infoStreamPrint(OMC_LOG_NLS_JAC_SUMS, 0, "NNZ          = %u", nlsData->sparsePattern->numberOfNonZeros);
  infoStreamPrint(OMC_LOG_NLS_JAC_SUMS, 0, "Curr Time    = %-11.5e", data->localData[0]->timeValue);
  messageClose(OMC_LOG_NLS_JAC_SUMS);

  int print_count = (size < 5) ? size : 5;

  // top row sums
  infoStreamPrint(OMC_LOG_NLS_JAC_SUMS, 1, "Top %d Jacobian row abs sums (sorted by descending value):", print_count);
  for (i = 0; i < print_count; i++)
  {
    row = rowSums[i].index;
    modelica_integer eq_debug_idx = nlsData->eqn_simcode_indices[size_of_torns + row];
    infoStreamPrint(OMC_LOG_NLS_JAC_SUMS, 0, "fabs(Row[%d]) = %+.5e for NLS Eq ID (debugger): %ld", row + 1, rowSums[i].value, eq_debug_idx);
  }
  messageClose(OMC_LOG_NLS_JAC_SUMS);

  // bottom row sums
  if (size > 5)
  {
    infoStreamPrint(OMC_LOG_NLS_JAC_SUMS, 1, "Bottom %d Jacobian row abs sums (sorted by descending value):", print_count);
    for (i = size - print_count; i < size; i++)
    {
      row = rowSums[i].index;
      modelica_integer eq_debug_idx = nlsData->eqn_simcode_indices[size_of_torns + row];
      infoStreamPrint(OMC_LOG_NLS_JAC_SUMS, 0, "fabs(Row[%d]) = %+.5e for NLS Eq ID (debugger): %ld", row + 1, rowSums[i].value, eq_debug_idx);
    }
    messageClose(OMC_LOG_NLS_JAC_SUMS);
  }


  // top column sums
  infoStreamPrint(OMC_LOG_NLS_JAC_SUMS, 1, "Top %d Jacobian column abs sums (sorted by descending value):", print_count);
  for (i = 0; i < print_count; i++)
  {
    col = colSums[i].index;
    const char *var_name = modelInfoGetEquation(&data->modelData->modelDataXml, nlsData->equationIndex).vars[col];
    infoStreamPrint(OMC_LOG_NLS_JAC_SUMS, 0, "fabs(Col[%d]) = %+.5e for Variable %d: %s", col + 1, colSums[i].value, col + 1, var_name);
  }
  messageClose(OMC_LOG_NLS_JAC_SUMS);

  // bottom column sums
  if (size > 5)
  {
    infoStreamPrint(OMC_LOG_NLS_JAC_SUMS, 1, "Bottom %d Jacobian column abs sums (sorted by descending value):", print_count);
    for (i = size - print_count; i < size; i++)
    {
      col = colSums[i].index;
      const char *var_name = modelInfoGetEquation(&data->modelData->modelDataXml, nlsData->equationIndex).vars[col];
      infoStreamPrint(OMC_LOG_NLS_JAC_SUMS, 0, "fabs(Col[%d]) = %+.5e for Variable %d: %s", col + 1, colSums[i].value, col + 1, var_name);
    }
    messageClose(OMC_LOG_NLS_JAC_SUMS);
  }

  // row sums
  infoStreamPrint(OMC_LOG_NLS_JAC_SUMS, 1, "All Jacobian row abs sums (sorted by descending value):");
  for (i = 0; i < size; i++)
  {
    row = rowSums[i].index;
    modelica_integer eq_debug_idx = nlsData->eqn_simcode_indices[size_of_torns + row];
    infoStreamPrint(OMC_LOG_NLS_JAC_SUMS, 0, "fabs(Row[%d]) = %+.5e for NLS Eq ID (debugger): %ld", row + 1, rowSums[i].value, eq_debug_idx);
  }
  messageClose(OMC_LOG_NLS_JAC_SUMS);

  // column sums
  infoStreamPrint(OMC_LOG_NLS_JAC_SUMS, 1, "All Jacobian column abs sums (sorted by descending value):");
  for (i = 0; i < size; i++)
  {
    col = colSums[i].index;
    const char *var_name = modelInfoGetEquation(&data->modelData->modelDataXml, nlsData->equationIndex).vars[col];
    infoStreamPrint(OMC_LOG_NLS_JAC_SUMS, 0, "fabs(Col[%d]) = %+.5e for Variable %d: %s", col + 1, colSums[i].value, col + 1, var_name);
  }
  messageClose(OMC_LOG_NLS_JAC_SUMS);

  messageClose(OMC_LOG_NLS_JAC_SUMS);

  free(rowSumsRaw);
  free(colSumsRaw);
  free(rowSums);
  free(colSums);
}
