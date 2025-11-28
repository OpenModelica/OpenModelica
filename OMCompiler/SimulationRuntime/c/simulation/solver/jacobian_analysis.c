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
static SVD_DATA *svd_dense_create(DATA *data, NONLINEAR_SYSTEM_DATA *nls_data, modelica_real *values, modelica_boolean scaled, SolverCaller caller)
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
    svd_data->caller         = caller;

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

static void svd_dense_free(SVD_DATA* svd_data)
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
static int svd_dense_compute_lapack(SVD_DATA* svd_data)
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

    // U = U - column major
    // S = diag(S)
    // VT = V^T - column major

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
static void svd_dense_calculate_statistics(SVD_DATA* svd_data)
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

static void svd_general_matrix_print_info(DATA *data, NONLINEAR_SYSTEM_DATA *nls_data, SolverCaller caller, modelica_boolean scaled, modelica_boolean sparse)
{
    infoStreamPrint(OMC_LOG_NLS_SVD, 1, "%s: %s SVD analysis (scaled = %s, Caller: %s).",
                SolverCaller_callerString(caller), sparse ? "sparse" : "dense", scaled ? "true" : "false", SolverCaller_toString(caller));

    infoStreamPrint(OMC_LOG_NLS_SVD, 1, "Matrix Info");
    infoStreamPrint(OMC_LOG_NLS_SVD, 0, "NLS eq index = %ld", nls_data->equationIndex);
    infoStreamPrint(OMC_LOG_NLS_SVD, 0, "Columns      = %ld", nls_data->size);
    infoStreamPrint(OMC_LOG_NLS_SVD, 0, "Rows         = %ld", nls_data->size);
    infoStreamPrint(OMC_LOG_NLS_SVD, 0, "NNZ          = %u", nls_data->sparsePattern->numberOfNonZeros);
    infoStreamPrint(OMC_LOG_NLS_SVD, 0, "Curr Time    = %-11.5e", data->localData[0]->timeValue);

    messageClose(OMC_LOG_NLS_SVD);
}

static void svd_general_matrix_print_cond(modelica_real cond)
{
    infoStreamPrint(OMC_LOG_NLS_SVD, 1, "Matrix condition");
    infoStreamPrint(OMC_LOG_NLS_SVD, 0, "Cond(M) = %.8e", cond);
    if (cond > 1e12)
    {
        warningStreamPrint(OMC_LOG_NLS_SVD, 0, "Matrix is very ill-conditioned: 1e12 < Cond(M) = %.8e", cond);
    }
    else if (cond > 1e8)
    {
        warningStreamPrint(OMC_LOG_NLS_SVD, 0, "Matrix is fairly ill-conditioned: 1e8 < Cond(M) = %.8e < 1e12", cond);
    }
    else if (cond > 1e4)
    {
        warningStreamPrint(OMC_LOG_NLS_SVD, 0, "Matrix is moderately ill-conditioned: 1e4 < Cond(M) = %.8e < 1e8", cond);
    }
    else
    {
        infoStreamPrint(OMC_LOG_NLS_SVD, 0, "Matrix is well conditioned: Cond(M) = %.8e < 1e4", cond);
    }
    messageClose(OMC_LOG_NLS_SVD);
}

/**
 * @brief Logs computed SVD statistics.
 *
 * Outputs singular value statistics such as condition number, estimated rank, and others.
 *
 * @param svd_data Pointer to the structure containing SVD results and statistics.
 * @param scaled If true: statistics are marked as scaled.
 */
static void svd_dense_dump_statistics(const SVD_DATA *svd_data)
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

    svd_general_matrix_print_info(svd_data->data, nls_data, svd_data->caller, svd_data->scaled, /* sparse */ FALSE);
    svd_general_matrix_print_cond(svd_data->cond);

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

            for (i = 0; i < svd_data->cols; i++)
            {
                // V[i][v] = VT[v][i]
                entries[i].index = i;
                entries[i].value = svd_data->VT[v + i * svd_data->rows]; // VT = V^T when reading column-wise
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
                entries[i].value = svd_data->U[i + svd_data->min_rows_cols * u];
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

static int svd_dense_main(DATA *data, NONLINEAR_SYSTEM_DATA *nls_data, modelica_real *values, modelica_boolean scaled, SolverCaller caller)
{
    int ret = 0;
    SVD_DATA *svd_data = svd_dense_create(data, nls_data, values, scaled, caller);
    ret = svd_dense_compute_lapack(svd_data);
    if (ret != 0) return ret;
    svd_dense_calculate_statistics(svd_data);
    svd_dense_dump_statistics(svd_data);
    svd_dense_free(svd_data);
    return ret;
}

#ifdef OMC_HAVE_PRIMME

#include <primme_svds.h>

/**
 * @brief Function pointer for the matrix-vector product (transpose and standard).
 */
typedef void (*primme_mvp_fn_t)(void *x, PRIMME_INT *ldx, void *y, PRIMME_INT *ldy, int *blockSize,
                                int *transpose, primme_svds_params *primme_svds, int *ierr);


typedef void (*primme_prec_fn_t)(void *x, PRIMME_INT *ldx, void *y, PRIMME_INT *ldy, int *blockSize,
                                 int *mode, primme_svds_params *primme_svds, int *ierr);
/**
 * @brief Public struct containing the results of the SVD computation.
 * @attention The user is responsible for freeing this struct using `svd_sparse_free`.
 */
typedef struct primme_result_t
{
    int rows;          /* Number of rows of the original matrix. */
    int cols;          /* Number of columns of the original matrix. */
    int target_size;   /* Number of singular values found. */
    double *svals;     /* Array with the computed singular values. */
    double *svecs;     /* Array with the computed singular vectors. */
    double *rnorms;    /* Array with the computed residual norms. */
} primme_result_t;

/**
 * @brief Encapsulates SVD problem data and results.
 * Contains matrix dimensions, config, and result pointers for SVD computations.
 */
typedef struct primme_handle_t
{
    primme_result_t result;     /* The results of the SVD. */
    primme_svds_params primme_svds; /* PRIMME's internal state. */
} primme_handle_t;

/**
 * @brief Context for callback Matrix-vector products, stored in primme_svds->matrix field.
 */
typedef struct primme_callback_ctx_t
{
    DATA *data;
    NONLINEAR_SYSTEM_DATA *nls_data;
    modelica_real *values;
    modelica_boolean scaled;
    SolverCaller caller;
    int svd_count;

    // must be freed in svd_sparse_free_ctx
    double *inv_diag_AtA;
    double *inv_diag_AAt;
} primme_callback_ctx_t;

static void svd_sparse_free_ctx(primme_callback_ctx_t *ctx)
{
    free(ctx->inv_diag_AAt);
    free(ctx->inv_diag_AtA);
};

/**
 * @brief Computes both Jacobi scaling vectors for preconditioning:
 *        inv_diag_AtA = 1 / diag(A^T * A)
 *        inv_diag_AAt = 1 / diag(A * A^T)
 */
static void compute_jacobi_diags(const NONLINEAR_SYSTEM_DATA *nls_data,
                                 const double *values,
                                 primme_callback_ctx_t *ctx)
{
    const SPARSE_PATTERN *sp = nls_data->sparsePattern;
    const modelica_integer size = nls_data->size;
    double sigma = 1e-8;

    if(omc_flag[FLAG_SVD_SPARSE_SIGMA])
    {
        sigma = fabs(atof(omc_flagValue[FLAG_SVD_SPARSE_SIGMA]));
    }

    const double reg = sigma * sigma;

    for (modelica_integer j = 0; j < size; j++)
    {
        for (modelica_integer nz = sp->leadindex[j]; nz < sp->leadindex[j + 1]; nz++)
        {
            modelica_integer i = sp->index[nz];
            double val = values[nz];

            ctx->inv_diag_AtA[j] += val * val;
            ctx->inv_diag_AAt[i] += val * val;
        }
    }

    for (modelica_integer j = 0; j < size; j++)
    {
        double a_AtA = ctx->inv_diag_AtA[j] + reg;
        double a_AAt = ctx->inv_diag_AAt[j] + reg;

        ctx->inv_diag_AtA[j] = 1.0 / a_AtA;
        ctx->inv_diag_AAt[j] = 1.0 / a_AAt;
    }
}

/**
 * @brief Allocates and initializes an SVD computation handle.
 * @param rows [in] The number of rows of the matrix.
 * @param cols [in] The number of columns of the matrix.
 * @param target_size [in] The number of singular values to compute.
 * @param linear_operator [in] The callback function for the matrix-vector product.
 * @return A handle to the internal SVD state.
 */
static primme_handle_t* svd_sparse_allocate(primme_callback_ctx_t *ctx, primme_mvp_fn_t linear_operator, primme_prec_fn_t precond)
{
    primme_handle_t *handle = (primme_handle_t*)malloc(sizeof(primme_handle_t));
    primme_svds_initialize(&handle->primme_svds);
    handle->primme_svds.m = ctx->nls_data->size;
    handle->primme_svds.n = ctx->nls_data->size;
    handle->primme_svds.numSvals = ctx->svd_count < ctx->nls_data->size ? ctx->svd_count : ctx->nls_data->size;
    handle->primme_svds.matrixMatvec = linear_operator;
    handle->primme_svds.matrix = ctx;

    if (ctx->inv_diag_AAt == NULL && ctx->inv_diag_AtA == NULL)
    {
        ctx->inv_diag_AAt = (double *)malloc(handle->primme_svds.n * sizeof(double));
        ctx->inv_diag_AtA = (double *)malloc(handle->primme_svds.n * sizeof(double));
        compute_jacobi_diags(ctx->nls_data, ctx->values, ctx);
    }

    handle->primme_svds.applyPreconditioner = precond;
    handle->primme_svds.preconditioner = ctx;

    handle->result.rows = handle->primme_svds.m;
    handle->result.cols = handle->primme_svds.n;;
    handle->result.target_size = handle->primme_svds.numSvals;
    handle->result.svals = (double *) malloc(handle->primme_svds.numSvals * sizeof(double));
    handle->result.svecs = (double *) malloc((handle->primme_svds.n + handle->primme_svds.m) * handle->primme_svds.numSvals * sizeof(double));
    handle->result.rnorms = (double *) malloc(handle->primme_svds.numSvals * sizeof(double));

    return handle;
}

/**
 * @brief Deallocates all memory associated with the SVD computation handle.
 *
 * @param handle [in] The handle returned by `svd_sparse_allocate`.
 */
static void svd_sparse_free(primme_handle_t* handle)
{
    primme_svds_free(&handle->primme_svds);
    free(handle->result.svals);
    free(handle->result.svecs);
    free(handle->result.rnorms);
    free(handle);
}

/**
 * @brief Performs the singular value decomposition.
 *
 * @param handle [in] The handle returned by `svd_sparse_allocate`.
 * @param target [in] Specifies whether to find the `TOP` or `LEAST` singular values.
 * @return A reference pointer to a `primme_result_t` struct on success, or `NULL` on error (owned by handle).
 */
static primme_result_t* svd_sparse_compute(primme_handle_t* handle, primme_svds_target target)
{
    primme_callback_ctx_t * ctx = (primme_callback_ctx_t *)(handle->primme_svds.matrix);

    /* some default values for now */
    double eps = 1e-8; // TODO: add svdTol?

    /* ||r|| <= eps * ||matrix|| */
    handle->primme_svds.eps = eps;
    handle->primme_svds.target = target;

    // we only need the largest for the condition
    handle->primme_svds.numSvals = (target == primme_svds_largest) ? 1 : handle->primme_svds.numSvals;

    primme_svds_set_method(primme_svds_normalequations, PRIMME_DEFAULT_MIN_TIME,
                           PRIMME_DEFAULT_MIN_MATVECS, &handle->primme_svds);

    if (omc_useStream[OMC_LOG_NLS_SVD_V])
    {
        // we write these to stdout, since we cant really redirect them
        handle->primme_svds.printLevel = 2;
        primme_svds_display_params(handle->primme_svds);
    }
    else
    {
        handle->primme_svds.printLevel = 0;
    }

    handle->primme_svds.precondition = (target == primme_svds_smallest) ? 1 : 0;


    int ret = dprimme_svds(handle->result.svals, handle->result.svecs, handle->result.rnorms, &handle->primme_svds);

    if (ret != 0)
    {
        errorStreamPrint(OMC_LOG_STDOUT, 0, "Error: primme_svds returned with nonzero exit status: %d\n", ret);
        return NULL;
    }

    return &handle->result;
}

static void matrix_vector(const NONLINEAR_SYSTEM_DATA *nls_data, const double *values, const double *x, double *y)
{
    modelica_integer row, column, nz;
    const SPARSE_PATTERN *sparsity = nls_data->sparsePattern;
    memset(y, 0, nls_data->size * sizeof(double));

    for (column = 0; column < nls_data->size; column++)
    {
        for (nz = sparsity->leadindex[column]; nz < sparsity->leadindex[column + 1]; nz++)
        {
            row = sparsity->index[nz];
            y[row] += values[nz] * x[column];
        }
    }
}

static void matrix_vector_transpose(const NONLINEAR_SYSTEM_DATA *nls_data, const double *values, const double *x, double *y)
{
    modelica_integer row, column, nz;
    const SPARSE_PATTERN *sparsity = nls_data->sparsePattern;
    memset(y, 0, nls_data->size * sizeof(double));

    for (column = 0; column < nls_data->size; column++)
    {
        for (nz = sparsity->leadindex[column]; nz < sparsity->leadindex[column + 1]; nz++)
        {
            row = sparsity->index[nz];
            y[column] += values[nz] * x[row];
        }
    }
}

/**
 * @brief Implements the matrix-vector products for the given matrix.
 * It operates on blocks of vectors for improved performance and
 * in general looks like this (depending on input):
 *                             Y := A * X,   for transpose = 0
 *                          or Y := A^T * X, for transpose = 1
 *
 * @attention get column i of x: (double *)x + (*ldx) * i;
 * @attention get column i of y: (double *)y + (*ldy) * i;
 *
 * @param x [in] Input dense matrix of vectors `X`.
 * @param ldx [in] Leading dimension of the input matrix `X`.
 * @param y [out] Output dense matrix of vectors `Y`.
 * @param ldy [in] Leading dimension of the output matrix `Y`.
 * @param blockSize [in] Number of vectors in the current block, number of columns of the X matrix.
 * @param transpose [in] Flag indicating if the transpose is applied (0 for A*x, 1 for A^T*x).
 * @param primme_svds [in] PRIMME configuration struct.
 * @param err [out] Error status; must be set to 0 on success.
 */
static void LinearOperator(void *x, PRIMME_INT *ldx, void *y, PRIMME_INT *ldy, int *blockSize,
                           int *transpose, primme_svds_params *primme_svds, int *err)
{
    int i, j;         /* vector index, from 0 to *blockSize-1 */
    double *xvec;     /* pointer to i-th input vector x */
    double *yvec;     /* pointer to i-th output vector y */

    primme_callback_ctx_t *ctx = (void*) primme_svds->matrix;
    NONLINEAR_SYSTEM_DATA *nls_data = ctx->nls_data;
    double *values = ctx->values;

    if (*transpose == 0)
    {
        /* Do y <- A * x */
        for (i = 0; i < *blockSize; i++)
        {
            xvec = (double *)x + (*ldx) * i;
            yvec = (double *)y + (*ldy) * i;
            matrix_vector(nls_data, values, xvec, yvec);
        }
    }
    else
    {
        /* Do y <- A^t * x */
        for (i = 0; i < *blockSize; i++)
        {
            xvec = (double *)x + (*ldx) * i;
            yvec = (double *)y + (*ldy) * i;
            matrix_vector_transpose(nls_data, values, xvec, yvec);
        }
    }
    *err = 0;
}

void GenericJacobiPreconditioner(void *x, PRIMME_INT *ldx, void *y, PRIMME_INT *ldy, int *blockSize,
                                 int *mode, primme_svds_params *primme_svds, int *ierr)
{
    int i, j;         /* vector index, from 0 to *blockSize-1 */
    double *xvec;     /* pointer to i-th input vector x */
    double *yvec;     /* pointer to i-th output vector y */

    primme_callback_ctx_t *ctx = (primme_callback_ctx_t*)primme_svds->matrix;
    int size = ctx->nls_data->size;
    const double *d_AtA = ctx->inv_diag_AtA;
    const double *d_AAt = ctx->inv_diag_AAt;

    int modeAtA = primme_svds_op_AtA;
    int modeAAt = primme_svds_op_AAt;
    int modeAug = primme_svds_op_augmented;
    PRIMME_INT ldaux = 2 * size;
    int notrans = 0;
    int trans = 1;
    double *aux;

    if (*mode == modeAtA)
    {
        /* Preconditioner for A^t * A, diag(A^t * A + sigma_est * I)^{-1} */
            for (i = 0; i < *blockSize; i++)
            {
                xvec = (double *)x + (*ldx) * i;
                yvec = (double *)y + (*ldy) * i;
                for (j = 0; j < size; j++)
                {
                    yvec[j] = xvec[j] * d_AtA[j];
                }
        }
        *ierr = 0;
    }
    else if (*mode == modeAAt)
    {
        /* Preconditioner for A * A^t, diag(A * A^t + sigma_est * I)^{-1} */
        for (i = 0; i<*blockSize; i++)
        {
            xvec = (double *)x + (*ldx) * i;
            yvec = (double *)y + (*ldy) * i;
            for (j = 0; j < size; j++)
            {
                yvec[j] = xvec[j] * d_AAt[j];
            }
        }
        *ierr = 0;
    }
    else if (*mode == modeAug)
    {
        /* Preconditioner for [0 A^t; A 0],
            [diag(A^t * A + sigma_est * I)               0              ]^{-1} * [0  A^t]
            [              0               diag(A * A^t + sigma_est * I)]        [A   0 ]
        */

        // [y0; y1] <- [0 A^t; A 0] * [x0; x1]
        aux = (double*)malloc((*blockSize) * ldaux * sizeof(double));
        primme_svds->matrixMatvec(x, ldx, &aux[size], &ldaux, blockSize, &notrans, primme_svds, ierr);

        xvec = (double *)x + size;
        primme_svds->matrixMatvec(xvec, ldx, aux, &ldaux, blockSize, &trans, primme_svds, ierr);

        /* y0 <- preconditioner for A^t*A  * y0 */
        GenericJacobiPreconditioner(aux, &ldaux, y, ldy, blockSize, &modeAtA, primme_svds, ierr);

        /* y1 <- preconditioner for A*A^t  * y1 */
        yvec = (double *)y + size;
        GenericJacobiPreconditioner(&aux[size], &ldaux, yvec, ldy, blockSize, &modeAAt, primme_svds, ierr);
        free(aux);
    }
}

static void svd_sparse_print_singular_values(primme_callback_ctx_t *ctx, primme_handle_t *handle_top, primme_handle_t *handle_least,
                                                                         primme_result_t *res_top,    primme_result_t *res_least)
{
    infoStreamPrint(OMC_LOG_NLS_SVD, 1, "Smallest Singular values");
    for (int i = 0; i < handle_least->primme_svds.numSvals; i++)
    {
        infoStreamPrint(OMC_LOG_NLS_SVD, 0, "sigma_%-3d =  %.8e, rnorm_%-3d =  %.8e", i + 1, res_least->svals[i], i + 1, res_least->rnorms[i]);
    }
    messageClose(OMC_LOG_NLS_SVD);
    infoStreamPrint(OMC_LOG_NLS_SVD, 1, "Largest Singular values");
    for (int i = 0; i < handle_top->primme_svds.numSvals; i++)
    {
        infoStreamPrint(OMC_LOG_NLS_SVD, 0, "sigma_%-3d =  %.8e, rnorm_%-3d =  %.8e", i + 1, res_top->svals[i], i + 1, res_top->rnorms[i]);
    }
    messageClose(OMC_LOG_NLS_SVD);
}

static void svd_sparse_print_vectors(primme_callback_ctx_t *ctx, primme_handle_t *handle, primme_result_t *res, modelica_boolean smallest)
{
    int i, u, v, var_idx, eq_idx, sing_value_idx;
    modelica_real val;
    modelica_integer size_of_torns;
    int size = res->rows;
    SVD_Component *entries = (SVD_Component*)malloc(size * sizeof(SVD_Component));
    NONLINEAR_SYSTEM_DATA *nls_data = ctx->nls_data;
    NONLINEAR_SOLVER solver = nls_data->nlsMethod;

    const char* target_string = smallest ? "Smallest" : "Largest";

    infoStreamPrint(OMC_LOG_NLS_SVD, 1, "%s right singular vectors (variable space)", target_string);
    infoStreamPrint(OMC_LOG_NLS_SVD, 0, "Found %d singular vectors.", handle->primme_svds.numSvals);

    for (v = 0; v < handle->primme_svds.numSvals; v++)
    {
        sing_value_idx = smallest ? size - v : v + 1;
        infoStreamPrint(OMC_LOG_NLS_SVD, 1, "V[:,%d] (singular value %.8e)", sing_value_idx, res->svals[v]);

        for (i = 0; i < size; i++)
        {
            // V[i][v] = VT[v][i]
            entries[i].index = i;
            entries[i].value = res->svecs[size * (res->target_size + v) + i];
        }

        // sort by abs value descending O(n * log(n))
        qsort(entries, size, sizeof(SVD_Component), cmp_fabs_desc);

        for (i = 0; i < size; i++)
        {
            var_idx = entries[i].index;
            val = entries[i].value;
            infoStreamPrint(OMC_LOG_NLS_SVD, 0, "V[%d][%d] = %+.8e for NLS Var: %d with Name: %s", var_idx + 1, sing_value_idx, val, var_idx + 1,
                            modelInfoGetEquation(&ctx->data->modelData->modelDataXml, nls_data->equationIndex).vars[var_idx]);
        }
        messageClose(OMC_LOG_NLS_SVD);
    }
    messageClose(OMC_LOG_NLS_SVD);

    infoStreamPrint(OMC_LOG_NLS_SVD, 1, "%s left singular vectors (function space)", target_string);
    infoStreamPrint(OMC_LOG_NLS_SVD, 0, "Found %d singular vectors.", handle->primme_svds.numSvals);

    for (u = 0; u < handle->primme_svds.numSvals; u++)
    {
        sing_value_idx = smallest ? size - u : u + 1;
        infoStreamPrint(OMC_LOG_NLS_SVD, 1, "U[:,%d] (singular value %.8e)", sing_value_idx, res->svals[u]);

        for (i = 0; i < size; i++)
        {
            entries[i].index = i;
            entries[i].value = res->svecs[size * u + i];
        }

        // sort by abs value descending O(n * log(n))
        qsort(entries, size, sizeof(SVD_Component), cmp_fabs_desc);

        size_of_torns = nls_data->torn_plus_residual_size - nls_data->size;
        for (i = 0; i < size; i++)
        {
            eq_idx = entries[i].index;
            val = entries[i].value;

            infoStreamPrint(OMC_LOG_NLS_SVD, 0, "U[%d][%d] = %+.8e for NLS Eqn: %d with transformational debugger Idx: %d", eq_idx + 1, sing_value_idx, val, eq_idx + 1,
                            nls_data->eqn_simcode_indices[size_of_torns + entries[i].index]);
        }
        messageClose(OMC_LOG_NLS_SVD);
    }
    messageClose(OMC_LOG_NLS_SVD);
    free(entries);
}

static void svd_sparse_dump_statistics(primme_callback_ctx_t *ctx, primme_handle_t *handle_top, primme_handle_t *handle_least,
                                                                   primme_result_t *res_top,    primme_result_t *res_least)
{
    if (res_top == NULL || res_least == NULL)
    {
        errorStreamPrint(OMC_LOG_STDOUT, 0, "Error: primme_result_t* is NULL, no statistics available.\n");
        return;
    }

    svd_general_matrix_print_info(ctx->data, ctx->nls_data, ctx->caller, ctx->scaled, /* sparse */ TRUE);

    modelica_real sigma_max = res_top->svals[0];
    modelica_real sigma_min = res_least->svals[0];
    modelica_real cond = sigma_min != 0.0 ? sigma_max / sigma_min : INFINITY;

    svd_general_matrix_print_cond(cond);
    svd_sparse_print_singular_values(ctx, handle_top, handle_least, res_top, res_least);
    svd_sparse_print_vectors(ctx, handle_least, res_least, TRUE);

    messageClose(OMC_LOG_NLS_SVD);
}

static int svd_sparse_main(DATA *data, NONLINEAR_SYSTEM_DATA *nls_data, modelica_real *values, modelica_boolean scaled, SolverCaller caller, int svd_count) {
    primme_callback_ctx_t ctx = { .data = data, .nls_data = nls_data, .values = values, .scaled = scaled, .caller = caller,
                                  .svd_count = svd_count, .inv_diag_AtA = NULL, .inv_diag_AAt = NULL};

    primme_handle_t *handle_top = svd_sparse_allocate(&ctx, LinearOperator, GenericJacobiPreconditioner);
    primme_handle_t *handle_least = svd_sparse_allocate(&ctx, LinearOperator, GenericJacobiPreconditioner);

    primme_result_t* res_top = svd_sparse_compute(handle_top, primme_svds_largest);
    primme_result_t* res_least = svd_sparse_compute(handle_least, primme_svds_smallest);

    svd_sparse_dump_statistics(&ctx, handle_top, handle_least, res_top, res_least);

    svd_sparse_free(handle_top);
    svd_sparse_free(handle_least);
    svd_sparse_free_ctx(&ctx);

    return 0;
}

#endif // OMC_HAVE_PRIMME

/**
 * @brief Main routine to compute the SVD of the Jacobian matrix.
 *
 * Creates the SVD data structure, performs the SVD, calculates statistics,
 * and outputs the results. Currently computes the unscaled SVD.
 *
 * @param data       Pointer to simulation data.
 * @param nls_data   Pointer to the nonlinear system data.
 * @param values     Pointer to the matrix values to decompose.
 * @param scaled     Boolean if matrix is scaled (only for printout)
 * @param caller     Caller of the routine (only for printout)
 * @return return code: 0 = success
 */
int svd_compute(DATA *data, NONLINEAR_SYSTEM_DATA *nls_data, modelica_real *values, modelica_boolean scaled, SolverCaller caller)
{
    const char* cflags = omc_flagValue[FLAG_SVD_SPARSE_COUNT];
    int sparse_svd_count = (cflags ? atoi(cflags) : 0);

    if (sparse_svd_count > 0)
    {
#ifdef OMC_HAVE_PRIMME
        return svd_sparse_main(data, nls_data, values, scaled, caller, sparse_svd_count);
#else
        errorStreamPrint(OMC_LOG_STDOUT, 0, "Cannot call sparse SVD analysis, because OpenModelica was not build with PRIMME. "
                                            "Set FLAG_SVD_SPARSE_COUNT=0 to perform dense SVD or build OpenModelica with "
                                            "PRIMME via -DOM_OMC_ENABLE_PRIMME=ON.");
        return -1;
#endif
    }
    else if (sparse_svd_count < 0)
    {
        errorStreamPrint(OMC_LOG_STDOUT, 0, "Invalid argument specified for SVD_SPARSE_COUNT (must be >= 0).");
        return -1;
    }
    else
    {
        return svd_dense_main(data, nls_data, values, scaled, caller);
    }
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
