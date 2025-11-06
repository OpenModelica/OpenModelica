#include <gtest/gtest.h>
#include "arrayIndex.h"
#include "simulation_data.h"

// Forward declaration of private function
extern "C" void computeVarsIndex(void *variableData, enum var_type type, size_t num_variables, size_t *varsIndex);

// Test fixture
class ArrayTensor : public ::testing::Test
{
protected:
    const size_t dim1_1 = 2;
    const size_t dim1_2 = 3;
    const size_t dim3_1 = 4;
    const size_t dim3_2 = 3;
    const size_t dim3_3 = 2;

    DIMENSION_ATTRIBUTE dimensions_var1[2] = {
        {.type = DIMENSION_BY_START, .start = static_cast<modelica_integer>(dim1_1), .valueReference = static_cast<modelica_integer>(-1)},
        {.type = DIMENSION_BY_START, .start = static_cast<modelica_integer>(dim1_2), .valueReference = static_cast<modelica_integer>(-1)}};
    DIMENSION_INFO dimension_info_var1 = {
        .numberOfDimensions = 2,
        .dimensions = dimensions_var1,
        .scalar_length = dim1_1 * dim1_2};

    DIMENSION_INFO dimension_info_var2 = {
        .numberOfDimensions = 0,
        .dimensions = nullptr,
        .scalar_length = 1};

    DIMENSION_ATTRIBUTE dimensions_var3[3] = {
        {.type = DIMENSION_BY_START, .start = static_cast<modelica_integer>(dim3_1), .valueReference = static_cast<modelica_integer>(-1)},
        {.type = DIMENSION_BY_START, .start = static_cast<modelica_integer>(dim3_2), .valueReference = static_cast<modelica_integer>(-1)},
        {.type = DIMENSION_BY_START, .start = static_cast<modelica_integer>(dim3_3), .valueReference = static_cast<modelica_integer>(-1)}};
    DIMENSION_INFO dimension_info_var3 = {
        .numberOfDimensions = 3,
        .dimensions = dimensions_var3,
        .scalar_length = dim3_1 * dim3_2 * dim3_3};

    STATIC_REAL_DATA realVarsData[3] = {
        {.dimension = dimension_info_var1, .info = {.id = 0}},
        {.dimension = dimension_info_var2, .info = {.id = 1}},
        {.dimension = dimension_info_var3, .info = {.id = 2}}};
};

// Test calculation of array length and index offsets of tensor variable
TEST_F(ArrayTensor, TensorVariableIndexCalculation)
{
    // Arrange
    size_t varsIndex[4] = {0};

    // Act
    computeVarsIndex(&realVarsData, T_REAL, 3, varsIndex);

    // Expected results
    const size_t expected0 = 0;
    const size_t expected1 = dim1_1 * dim1_2;
    const size_t expected2 = expected1 + 1;
    const size_t expected3 = expected2 + (dim3_1 * dim3_2 * dim3_3);

    // Assert
    EXPECT_EQ(varsIndex[0], expected0) << "varsIndex[0] mismatch.";
    EXPECT_EQ(varsIndex[1], expected1) << "varsIndex[1] mismatch.";
    EXPECT_EQ(varsIndex[2], expected2) << "varsIndex[2] mismatch.";
    EXPECT_EQ(varsIndex[3], expected3) << "varsIndex[3] mismatch.";
}
