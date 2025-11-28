/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2025, Linköpings University,
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
 * This program is distributed    WITHOUT ANY WARRANTY; without
 * even the implied warranty of    MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#include <stdlib.h>
#include <sstream>
#include <iomanip>
#include <vector>

#include "hessian_finite_diff.h"

/**
 * @brief Constructs a compressed Hessian sparsity pattern C struct using Jacobian coloring.
 *
 * Given a sparse Jacobian J(x) of F: R^n → R^m, this builds the structure of the Hessian
 * of a scalar adjoint G(x) = Σ λ[i]·F[i](x), based on co-occurrence of variables in J(x).
 *
 * Variable pairs (i,j) are collected if they appear together in any function row f.
 * These define the nonzero Hessian structure (i.e. where ∂²G/∂xi∂xj != 0).
 *
 * A second coloring is induced: if variable x_i ∈ color c₁ and x_j ∈ color c₂, then (i,j) is assigned to the color pair (c₁, c₂).
 * This allows evaluating Hessian entries H[i,j] via directional finite differences: perturb x along seed vector s₁ (color c₁),
 * and apply a Jacobian-vector product with seed vector s₂ (color c₂).
 *
 * For each color pair (c₁, c₂), only a subset of Hessian entries is affected. Each entry H[i,j] receives contributions
 * only from those function rows r where both variables x_i and x_j appear (i.e. where ∂f/∂x_i and ∂f/∂x_j are nonzero).
 * The directional second derivative is given using:
 *
 *         H[i,j] = ∑_r λ[r] · ((J(x + h · s_1) - J(x)) · s_2 / h)[r]
 *
 * where λ ∈ ℝᵐ is the adjoint vector. This corresponds to evaluating the contraction λᵗ · ∇²F(x) · v without forming the full Hessian.
 *
 * The function makes heavy use of the STL, but the result is a `HESSIAN_PATTERN` pure C struct that includes:
 * - COO row/col index arrays for Hessian nonzeros (lower triangle).
 * - A lookup from (color₁, color₂) to `ColorPair`, listing variable pairs and contributing rows.
 *
 * @param jac [in] Pointer to a `JACOBIAN` struct (sparsity pattern and coloring).
 * @return [out] Pointer to newly allocated `HESSIAN_PATTERN` struct.
 */
HESSIAN_PATTERN* generate_hessian_pattern(JACOBIAN* jac) {
    if (jac == nullptr || jac->sparsePattern == nullptr) { return nullptr; }

    int numVars = jac->sizeCols;
    int numFuncs = jac->sizeRows;
    SPARSE_PATTERN* sp = jac->sparsePattern;
    int numColors = sp->maxColors;

    // 1. build adjacency list: which variables affect which functions
    std::vector<std::vector<int>> adj(numFuncs);
    for (int col = 0; col < numVars; col++) {
        for (unsigned int nz = sp->leadindex[col]; nz < sp->leadindex[col + 1]; nz++) {
            int row = sp->index[nz];
            adj[row].push_back(col);
        }
    }

    // 2. build M[v1, v2] = list of function rows where both variables appear
    std::map<std::pair<int, int>, std::vector<int>> M;
    for (int f = 0; f < numFuncs; f++) {
        const auto& vars = adj[f];
        for (size_t i = 0; i < vars.size(); i++) {
            for (size_t j = 0; j <= i; j++) {
                int v1 = vars[i];
                int v2 = vars[j];
                if (v1 < v2) std::swap(v1, v2);
                M[{v1, v2}].push_back(f);
            }
        }
    }

    // 3. assign flat indices (lower nnz) directly from sorted M keys
    std::map<std::pair<int, int>, int> cooMap;
    int lnnz = 0;
    for (const auto& [pair, _] : M) {
        cooMap[pair] = lnnz++;
    }

    // 4. build color groups :: TODO: implement this in OpenModelica for the JACOBIAN
    std::vector<std::vector<int>> colorCols(numColors);
    for (int col = 0; col < numVars; col++) {
        int c = sp->colorCols[col];
        if (c > 0) {
            colorCols[c - 1].push_back(col);
        }
    }

    // 5. allocate pattern
    HESSIAN_PATTERN* hes_pattern = (HESSIAN_PATTERN*)malloc(sizeof(HESSIAN_PATTERN));
    hes_pattern->colorPairs = (ColorPair**)calloc(numColors * (numColors + 1) / 2, sizeof(ColorPair*));
    hes_pattern->row = (int*)malloc(lnnz * sizeof(int));
    hes_pattern->col = (int*)malloc(lnnz * sizeof(int));
    hes_pattern->colsForColor = (int**)malloc(numColors * sizeof(int*));
    hes_pattern->colorSizes = (int*)malloc(numColors * sizeof(int));
    hes_pattern->numColors = numColors;
    hes_pattern->numFuncs = numFuncs;
    hes_pattern->size = numVars;
    hes_pattern->lnnz = lnnz;
    hes_pattern->jac = jac;

    // workspace memory
    hes_pattern->ws_oldX = (modelica_real*)malloc(numVars * sizeof(modelica_real));
    hes_pattern->ws_h = (modelica_real*)malloc(numVars * sizeof(modelica_real));
    hes_pattern->ws_baseJac = (modelica_real**)malloc(numFuncs * sizeof(modelica_real*));
    for (int row = 0; row < numFuncs; row++) {
        hes_pattern->ws_baseJac[row] = (modelica_real*)calloc(numColors, sizeof(modelica_real));
    }

    // 6. remember columns in each color
    for (int i = 0; i < numColors; i++) {
        int size = colorCols[i].size();
        hes_pattern->colorSizes[i] = size;
        hes_pattern->colsForColor[i] = (int*)malloc(size * sizeof(int));
        memcpy(hes_pattern->colsForColor[i], colorCols[i].data(), size * sizeof(int));
    }

    // 7. set mapping from Jacobian[row][color] -> Jacobian CSC index
    hes_pattern->cscJacIndexFromRowColor = (int**)malloc(numFuncs * sizeof(int*));
    for (int row = 0; row < numFuncs; row++) {
        hes_pattern->cscJacIndexFromRowColor[row] = (int*)malloc(numColors * sizeof(int));
        for (int color = 0; color < numColors; color++) {
            hes_pattern->cscJacIndexFromRowColor[row][color] = -1;
        }
    }

    for (int color = 0; color < numColors; color++) {
        const int* cols = hes_pattern->colsForColor[color];
        for (int colIdx = 0; colIdx < hes_pattern->colorSizes[color]; colIdx++) {
            int col = cols[colIdx];
            for (unsigned int nz = sp->leadindex[col]; nz < sp->leadindex[col + 1]; nz++) {
                int row = sp->index[nz];
                hes_pattern->cscJacIndexFromRowColor[row][color] = nz;
            }
        }
    }

    // 8. fill the coordinate format sparsity
    for (const auto& coo : cooMap) {
        int var_row = coo.first.first;
        int var_col = coo.first.second;
        int nz = coo.second;

        hes_pattern->row[nz] = var_row;
        hes_pattern->col[nz] = var_col;
    }

    ColorPair* colorPair;

    // 9. fill HESSIAN_PATTERN.colorPairs[c1][c2] -> ColorPair
    for (int c1 = 0; c1 < numColors; c1++) {
        for (int c2 = 0; c2 <= c1; c2++) {
            std::vector<std::vector<int>> rowsVec;
            std::vector<int> nnzIndicesVec;
            std::vector<VarPair> pairVec;

            for (int i1 : colorCols[c1]) {
                for (int i2 : colorCols[c2]) {
                    // copy and swap if needed
                    int v1 = i1;
                    int v2 = i2;
                    if (v1 < v2){
                        std::swap(v1, v2);
                    }

                    auto v_pair = std::make_pair(v1, v2);
                    auto it = M.find(v_pair);
                    if (it == M.end()) continue;

                    auto cooIt = cooMap.find(v_pair);
                    if (cooIt == cooMap.end()) continue;

                    rowsVec.push_back(it->second);          // function rows
                    nnzIndicesVec.push_back(cooIt->second); // flat Hessian index, nz index
                    pairVec.push_back({v1, v2});            // variable pair
                }
            }

            // create and allocate ColorPair
            int variablePairCount = rowsVec.size();
            if (variablePairCount == 0) {
                colorPair = nullptr;
            }
            else {
                colorPair = (ColorPair*)malloc(sizeof(ColorPair));
                colorPair->size = variablePairCount;
                colorPair->contributingRows = (int**)malloc(variablePairCount * sizeof(int*));
                colorPair->numContributingRows = (int*)malloc(variablePairCount * sizeof(int));
                colorPair->lnnzIndices = (int*)malloc(variablePairCount * sizeof(int));
                colorPair->varPairs = (VarPair*)malloc(variablePairCount * sizeof(VarPair));

                for (int i = 0; i < variablePairCount; i++) {
                    int sz = rowsVec[i].size();
                    colorPair->contributingRows[i] = (int*)malloc(sz * sizeof(int));
                    memcpy(colorPair->contributingRows[i], rowsVec[i].data(), sz * sizeof(int));
                    colorPair->numContributingRows[i] = sz;
                    colorPair->lnnzIndices[i] = nnzIndicesVec[i];
                    colorPair->varPairs[i] = pairVec[i];
                }
            }

            hes_pattern->colorPairs[get_color_pair_index(c1, c2)] = colorPair;
        }
    }

    return hes_pattern;
}

/**
 * @brief Compute Hessian-vector product λᵗH(x) using forward finite differences of the Jacobian.
 *
 * Approximates the entries of the Hessian matrix H(x) using first-order directional derivatives.
 * The method uses seed vector coloring for efficient evaluation and exploits sparse Hessian structure.
 * Assumes the current point x has all controls and states set in `data->localData[0]->realVars`.
 * For a more detailed explanation of the algorithm (see generate_hessian_pattern).
 *
 * Runtime: O(#colors * (#colors + 1) / 2 * T_{JVP} + #colors * T_{JVP} + #funcs_{avg} * nnz(Hessian)),
 *          where T_{JVP} is the time of one Jacobian column evaluation and funcs_{avg} is the average
 *          number of functions for each variable pair
 *
 * Driving term: O(#colors * (#colors + 1) / 2 * T_{JVP}, since #colors * T_{JVP} will be precomputed
 *               for the Jacobian anyway and #funcs_{avg} <= #funcs, thus comparably insignificant
 *               => just (#colors + 1) / 2 times the time for the Jacobian evaluation
 *
 * @param[in]  data           Runtime simulation data structure.
 * @param[in]  threadData     Thread-local data.
 * @param[in]  hes_pattern    Precomputed sparsity and coloring pattern for Hessian and Jacobian.
 * @param[in]  h              Perturbation step size (pre-scaling).
 * @param[in]  lambda         Adjoint vector (size = number of functions).
 * @param[in]  u_indices      Indices of the input variables. For Optimization, these can be obtained by calling data->callback->getInputVarIndicesInOptimization(). (I hate it that this is an arg; it should be somewhere in DATA or so.)
 * @param[in]  jac_csc        (Optional) Jacobian values in CSC format, used to speed up Hessian calculation. NULL -> compute from scratch.
 * @param[out] hes            Output sparse Hessian values (COO format of hes_pattern, length = hes_pattern->nnz).
 */
void eval_hessian_fwd_differences(DATA* data, threadData_t* threadData, HESSIAN_PATTERN* hes_pattern, modelica_real h,
                                   int* u_indices, const modelica_real* lambda, modelica_real* jac_csc, modelica_real* hes) {
    /* 0. retrieve pointers */
    JACOBIAN*       jacobian     = hes_pattern->jac;
    modelica_real** ws_baseJac   = hes_pattern->ws_baseJac;
    modelica_real*  ws_oldX      = hes_pattern->ws_oldX;
    modelica_real*  ws_h         = hes_pattern->ws_h;
    modelica_real*  seeds        = jacobian->seedVars;
    modelica_real*  jvp          = jacobian->resultVars;
    unsigned int*   jacLeadIndex = jacobian->sparsePattern->leadindex;
    unsigned int*   jacIndex     = jacobian->sparsePattern->index;

    int nStates = data->modelData->nStates;

    /* 1. compute standard Jacobian, if jac_csc is NULL, else use the jac_csc as precomputed Jacobian */
    if (!jac_csc) {
        /* 1.a. evaluate base system (needed for Jacobian columns) */
        data->callback->functionDAE(data, threadData);

        /* 1.b. evaluate all JVPs J(x) * s_{c} of the current point x */
        for (int color = 0; color < hes_pattern->numColors; color++) {
            set_seed_vector(hes_pattern->colorSizes[color], hes_pattern->colsForColor[color], 1, seeds);
            jacobian->evalColumn(data, threadData, jacobian, NULL);

            for (int colIndex = 0; colIndex < hes_pattern->colorSizes[color]; colIndex++) {
                int col = hes_pattern->colsForColor[color][colIndex];
                for (unsigned int nz = jacLeadIndex[col]; nz < jacLeadIndex[col + 1]; nz++) {
                    int row = jacIndex[nz];
                    ws_baseJac[row][color] = jvp[row];
                }
            }

            set_seed_vector(hes_pattern->colorSizes[color], hes_pattern->colsForColor[color], 0, seeds);
        }
    }

    /* 2. loop over all colors c1 */
    for (int c1 = 0; c1 < hes_pattern->numColors; c1++) {
        /* 3. define seed vector s_{c_1} with all cols in c_1 active (implicitly) */
        /* 4. peturbate current x_{c_1} := x + h * s_{c_1} */
        for (int columnIndex = 0; columnIndex < hes_pattern->colorSizes[c1]; columnIndex++) {
            int col = hes_pattern->colsForColor[c1][columnIndex];
            int realVarsIndex = (col < nStates ? col : u_indices[col - nStates]);
            /* remember the current realVars (to be perturbed) and perturbate */
            ws_oldX[col] = data->localData[0]->realVars[realVarsIndex];

            /* create perturbation size based on nominals and current entry */
            const modelica_real nom = data->modelData->realVarsData[realVarsIndex].attribute.nominal;
            ws_h[col] = h * (1.0 + fmax(ws_oldX[col], nom));
            if (ws_oldX[col] + ws_h[col] > data->modelData->realVarsData[realVarsIndex].attribute.max) {
                ws_h[col] *= -1.0;
            }

            data->localData[0]->realVars[realVarsIndex] += ws_h[col];
        }

        /* evaluate perturbed system (needed for Jacobian columns) */
        data->callback->functionDAE(data, threadData);

        /* 5. loop over all colors c2 with index less or equal to c_1 */
        for (int c2 = 0; c2 <= c1; c2++) {
            /* 6. define seed vector s_{c_2} with all cols in c_2 active */
            set_seed_vector(hes_pattern->colorSizes[c2], hes_pattern->colsForColor[c2], 1, seeds);

            /* 7. evaluate JVP J(x_{c_1}) * s_{c_2}: writes column to jvp = jacobian->resultVars */
            jacobian->evalColumn(data, threadData, jacobian, NULL);

            /* 8. retrieve Hessian approximation */
            ColorPair* colorPair = hes_pattern->colorPairs[get_color_pair_index(c1, c2)];
            if (colorPair) {
                for (int varPairIdx = 0; varPairIdx < colorPair->size; varPairIdx++) {
                    /* nz index in flattened Hessian array (COO format) */
                    int nz = colorPair->lnnzIndices[varPairIdx];

                    /* rows (functions) where both ∂f/∂xi and ∂f/∂xj are nonzero */
                    int* contributingRows = colorPair->contributingRows[varPairIdx];
                    int numContributingRows = colorPair->numContributingRows[varPairIdx];

                    /* second derivative eval at nz index */
                    modelica_real der = 0.0;

                    /* 10. Approximate directional second derivative:
                     *         (1/h) ∑_{f ∈ rows} λ[f] · (J(x + h·s_{c₁})[s_{c₂}][f] - J(x)[s_{c₂}][f])
                     *         where:
                     *             - f / fnRow indexes function rows where both ∂f/∂xᵢ and ∂f/∂xⱼ are nonzero */
                    for (int fIdx = 0; fIdx < numContributingRows; fIdx++) {
                        int fnRow = contributingRows[fIdx];
                        modelica_real J_fnRow_c2 = (jac_csc ? jac_csc[hes_pattern->cscJacIndexFromRowColor[fnRow][c2]] : ws_baseJac[fnRow][c2]);
                        der += lambda[fnRow] * (jvp[fnRow] - J_fnRow_c2);
                    }

                    /* store and divide by step size, retrieve step size via nz col index / same as for the perturbation (step 4) */
                    int col = hes_pattern->col[nz];
                    hes[nz] = der / ws_h[col];
                }
            }

            /* 11. reset s_{c_2} */
            set_seed_vector(hes_pattern->colorSizes[c2], hes_pattern->colsForColor[c2], 0.0, seeds);
        }

        /* 12. reset perturbation in x */
        for (int columnIndex = 0; columnIndex < hes_pattern->colorSizes[c1]; columnIndex++) {
            int col = hes_pattern->colsForColor[c1][columnIndex];
            int realVarsIndex = (col < nStates ? col : u_indices[col - nStates]);
            data->localData[0]->realVars[realVarsIndex] = ws_oldX[col];
        }
    }
}

void print_hessian_pattern(const HESSIAN_PATTERN* hes_pattern) {
    if (!hes_pattern) {
        errorStreamPrint(OMC_LOG_MOO, 0, "Hessian pattern is NULL.");
        return;
    }

    infoStreamPrint(OMC_LOG_MOO, 0, "\n=== HESSIAN SPARSITY INFO ===");
    infoStreamPrint(OMC_LOG_MOO, 0, "Matrix size: %d x %d", hes_pattern->size, hes_pattern->size);
    infoStreamPrint(OMC_LOG_MOO, 0, "Lower triangle NNZ: %d", hes_pattern->lnnz);
    infoStreamPrint(OMC_LOG_MOO, 0, "Number of colors: %d", hes_pattern->numColors);

    infoStreamPrint(OMC_LOG_MOO, 0, "\nBase Jacobian Colors:");
    for (int c = 0; c < hes_pattern->numColors; c++) {
        std::ostringstream oss;
        oss << "        Color " << c << " (size " << hes_pattern->colorSizes[c] << "): ";
        for (int j = 0; j < hes_pattern->colorSizes[c]; j++) {
            oss << hes_pattern->colsForColor[c][j] << " ";
        }
        infoStreamPrint(OMC_LOG_MOO, 0, "%s", oss.str().c_str());
    }

    infoStreamPrint(OMC_LOG_MOO, 0, "\nCoordinate Format (COO, lower triangle):");
    infoStreamPrint(OMC_LOG_MOO, 0, " lnnz | Row | Col");
    infoStreamPrint(OMC_LOG_MOO, 0, "------------------");
    for (int i = 0; i < hes_pattern->lnnz; i++) {
        infoStreamPrint(OMC_LOG_MOO, 0, " %3d | %3d | %3d", i, hes_pattern->row[i], hes_pattern->col[i]);
    }

    infoStreamPrint(OMC_LOG_MOO, 0, "\nColor Pair Entries:");
    for (int c1 = 0; c1 < hes_pattern->numColors; c1++) {
        for (int c2 = 0; c2 <= c1; c2++) { // symmetric lower triangle
            int idx = get_color_pair_index(c1, c2);
            ColorPair* colorPair = hes_pattern->colorPairs[idx];
            if (!colorPair) continue;

            infoStreamPrint(OMC_LOG_MOO, 0, "    Color pair (%d, %d): %d variable pairs",
                            c1, c2, colorPair->size);

            for (int i = 0; i < colorPair->size; i++) {
                int nnzIdx = colorPair->lnnzIndices[i];

                std::ostringstream oss;
                oss << "        VarPair: (" << hes_pattern->row[nnzIdx]
                    << ", " << hes_pattern->col[nnzIdx]
                    << "), nnz_index = " << nnzIdx << ", Functions = [";

                for (int j = 0; j < colorPair->numContributingRows[i]; j++) {
                    oss << colorPair->contributingRows[i][j];
                    if (j + 1 < colorPair->numContributingRows[i]) oss << ", ";
                }
                oss << "]";
                infoStreamPrint(OMC_LOG_MOO, 0, "%s", oss.str().c_str());
            }

            infoStreamPrint(OMC_LOG_MOO, 0, "----------------------------------------------------------------------------");
        }
    }

    int n = hes_pattern->size;
    {
        infoStreamPrint(OMC_LOG_MOO, 0, "\n=== HESSIAN SPARSITY PLOT (λᵗ·∇²F) ===");

        std::ostringstream oss;
        oss << "   ";
        for (int j = 0; j < n; j++) oss << j;
        infoStreamPrint(OMC_LOG_MOO, 0, "%s", oss.str().c_str());
    }

    char* sparsity = (char*)calloc(n * n, sizeof(char));
    for (int lnz = 0; lnz < hes_pattern->lnnz; lnz++) {
        int i = hes_pattern->row[lnz];
        int j = hes_pattern->col[lnz];
        sparsity[i + n * j] = 1;
        sparsity[j + n * i] = 1; // symmetric for display
    }

    for (int i = 0; i < n; i++) {
        std::ostringstream oss;
        oss << std::setw(2) << i << ": ";
        for (int j = 0; j < n; j++) {
            oss << (sparsity[i + n * j] ? '*' : ' ');
        }
        infoStreamPrint(OMC_LOG_MOO, 0, "%s", oss.str().c_str());
    }

    free(sparsity);
    infoStreamPrint(OMC_LOG_MOO, 0, "=====================================");
}

void free_hessian_pattern(HESSIAN_PATTERN* hes_pattern) {
    if (!hes_pattern) return;

    int numColorPairs = hes_pattern->numColors * (hes_pattern->numColors + 1) / 2;
    for (int i = 0; i < numColorPairs; i++) {
        ColorPair* colorPair = hes_pattern->colorPairs[i];
        if (!colorPair) continue;

        for (int j = 0; j < colorPair->size; j++) {
            free(colorPair->contributingRows[j]);
        }

        free(colorPair->contributingRows);
        free(colorPair->numContributingRows);
        free(colorPair->lnnzIndices);
        free(colorPair->varPairs);
        free(colorPair);
    }

    free(hes_pattern->colorPairs);
    free(hes_pattern->row);
    free(hes_pattern->col);

    if (hes_pattern->colsForColor) {
        for (int i = 0; i < hes_pattern->numColors; i++) {
            free(hes_pattern->colsForColor[i]);
        }
        free(hes_pattern->colsForColor);
    }
    free(hes_pattern->colorSizes);

    if (hes_pattern->cscJacIndexFromRowColor) {
        for (int row = 0; row < hes_pattern->numFuncs; row++) {
            free(hes_pattern->cscJacIndexFromRowColor[row]);
        }
        free(hes_pattern->cscJacIndexFromRowColor);
    }

    for (int row = 0; row < hes_pattern->numFuncs; row++) {
        free(hes_pattern->ws_baseJac[row]);
    }
    free(hes_pattern->ws_baseJac);
    free(hes_pattern->ws_oldX);
    free(hes_pattern->ws_h);

    free(hes_pattern);
}

// ====== EXTRAPOLATION ======

/**
 * @brief Allocate and initialize internal workspace for Richardson extrapolation.
 *
 * @param[in] resultSize Number of result values computed by `fn` (length of result array).
 * @param[in] maxSteps   Maximum number of extrapolation steps that may be used.
 * @return Pointer to an initialized ExtrapolationData struct.
 */
ExtrapolationData* init_extrapolation_data(int resultSize, int maxSteps) {
    ExtrapolationData* extrData = (ExtrapolationData*)malloc(sizeof(ExtrapolationData));
    extrData->resultSize = resultSize;
    extrData->maxSteps = maxSteps;
    extrData->ws_results = (modelica_real**)malloc(maxSteps * sizeof(modelica_real*));
    for (int i = 0; i < maxSteps; i++) {
        extrData->ws_results[i] = (modelica_real*)malloc(resultSize * sizeof(modelica_real));
    }
    return extrData;
}

void free_extrapolation_data(ExtrapolationData* extrData) {
    for (int i = 0; i < extrData->maxSteps; i++) {
        free(extrData->ws_results[i]);
    }
    free(extrData->ws_results);
    free(extrData);
}

/**
 * @brief Apply in-place Richardson extrapolation using a generic computation function.
 *
 * Accepts a function of the form `f(args, h, result)`, evaluated at decreasing step sizes.
 * Performs in-place extrapolation to increase accuracy. `steps <= 5` recommended to limit roundoff error.
 *
 * @param[in]  extrData       Workspace from init_extrapolation_data.
 * @param[in]  fn             Function pointer: computes result := f(args, h).
 * @param[in]  args           User data passed to fn.
 * @param[in]  h0             Initial step size.
 * @param[in]  steps          Number of extrapolation steps (1 means no extrapolation!).
 * @param[in]  stepDivisor    Step reduction factor (e.g. 2, then h_{i+1} = h_i / 2).
 * @param[in]  methodOrder    Order of the underlying method (e.g. 1 for Forward Differences).
 * @param[out] result         Final extrapolated result.
 */
void richardson_extrapolation(ExtrapolationData* extrData, computation_fn_t fn, void* args, modelica_real h0,
                             int steps, modelica_real stepDivisor, int methodOrder, modelica_real* result) {
    /* call fn_ptr if no extrapolation is executed */
    if (steps <= 1) {
        fn(args, h0, result);
        return;
    }
    else if (steps > extrData->maxSteps) {
        warningStreamPrint(OMC_LOG_MOO, 0, "Requested extrapolation steps '%d' exceed maximum '%d', set in init_extrapolation_data. Using '%d' instead.\n",
                                            steps, extrData->maxSteps, extrData->maxSteps);
        steps = extrData->maxSteps;
    }

    /* compute all stages for extrapolation */
    for (int i = 0; i < steps; i++) {
        modelica_real h = h0 / pow(stepDivisor, i);
        fn(args, h, extrData->ws_results[i]);
    }

    /* perform extrapolation: cancel taylor terms, in-place */
    for (int j = 0; j < extrData->resultSize; j++) {
        for (int k = 1; k < steps; k++) {
            for (int i = steps - 1; i >= k; i--) {
                modelica_real factor = pow(stepDivisor, methodOrder * k);
                extrData->ws_results[i][j] = (factor * extrData->ws_results[i][j] - extrData->ws_results[i - 1][j]) / (factor - 1);
            }
        }
        result[j] = extrData->ws_results[steps - 1][j];
    }
}

/* wrapper for eval_hessian_fwd_differences */
void hessian_fwd_differences_wrapper(void* args, modelica_real h, modelica_real* result) {
    HessianFiniteDiffArgs* hessianArgs = (HessianFiniteDiffArgs*)args;
    eval_hessian_fwd_differences(hessianArgs->data, hessianArgs->threadData, hessianArgs->hes_pattern, h,
                                  hessianArgs->u_indices, hessianArgs->lambda, hessianArgs->jac_csc, result);
}
