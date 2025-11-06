#include <gtest/gtest.h>
#include "arrayIndex.h"
#include "simulation_data.h"
#include "openmodelica_types.h"

/**
 * @brief Tests conversion between linear and multidimensional indices
 *        for a 2×3×4 tensor (row-major order).
 *
 * Dimensions: T[2][3][4]
 * Row-major strides: [3*4=12, 4, 1]
 * Linear index = i*12 + j*4 + k
 */
class ArrayTensor : public ::testing::Test
{
protected:
  DIMENSION_ATTRIBUTE dimensions[3] = {
      {.type = DIMENSION_BY_START,
       .start = 2,
       .valueReference = -1},
      {.type = DIMENSION_BY_START,
       .start = 3,
       .valueReference = -1},
      {.type = DIMENSION_BY_START,
       .start = 4,
       .valueReference = -1}};
  DIMENSION_INFO dimension_info = {
      .numberOfDimensions = 3,
      .dimensions = dimensions,
      .scalar_length = 2 * 3 * 4};
};

// [0, 0, 0] → 0
TEST_F(ArrayTensor, Index000_ToLinear)
{
  size_t input_array_index[3] = {0, 0, 0};
  size_t expected_linear_index = 0;

  size_t actual_linear_index = multiDimArrayToLinearIndex(&dimension_info, input_array_index);

  EXPECT_EQ(actual_linear_index, expected_linear_index);
}

// 0 → [0, 0, 0]
TEST_F(ArrayTensor, Linear0_ToArray)
{
  size_t expected_array_index[3] = {0, 0, 0};

  size_t* actual_array_index = linearToMultiDimArrayIndex(&dimension_info, 0);

  ASSERT_NE(actual_array_index, nullptr);
  EXPECT_EQ(actual_array_index[0], expected_array_index[0]);
  EXPECT_EQ(actual_array_index[1], expected_array_index[1]);
  EXPECT_EQ(actual_array_index[2], expected_array_index[2]);

  free(actual_array_index);
}

// [1, 0, 0] → 12
TEST_F(ArrayTensor, Index100_ToLinear)
{
  size_t input_array_index[3] = {1, 0, 0};
  size_t expected_linear_index = 12;

  size_t actual_linear_index = multiDimArrayToLinearIndex(&dimension_info, input_array_index);

  EXPECT_EQ(actual_linear_index, expected_linear_index);
}

// 12 → [1, 0, 0]
TEST_F(ArrayTensor, Linear12_ToArray)
{
  size_t expected_array_index[3] = {1, 0, 0};

  size_t* actual_array_index = linearToMultiDimArrayIndex(&dimension_info, 12);

  ASSERT_NE(actual_array_index, nullptr);
  EXPECT_EQ(actual_array_index[0], expected_array_index[0]);
  EXPECT_EQ(actual_array_index[1], expected_array_index[1]);
  EXPECT_EQ(actual_array_index[2], expected_array_index[2]);

  free(actual_array_index);
}

// [0, 1, 0] → 4
TEST_F(ArrayTensor, Index010_ToLinear)
{
  size_t input_array_index[3] = {0, 1, 0};
  size_t expected_linear_index = 4;

  size_t actual_linear_index = multiDimArrayToLinearIndex(&dimension_info, input_array_index);

  EXPECT_EQ(actual_linear_index, expected_linear_index);
}

// 4 → [0, 1, 0]
TEST_F(ArrayTensor, Linear4_ToArray)
{
  size_t expected_array_index[3] = {0, 1, 0};

  size_t* actual_array_index = linearToMultiDimArrayIndex(&dimension_info, 4);

  ASSERT_NE(actual_array_index, nullptr);
  EXPECT_EQ(actual_array_index[0], expected_array_index[0]);
  EXPECT_EQ(actual_array_index[1], expected_array_index[1]);
  EXPECT_EQ(actual_array_index[2], expected_array_index[2]);

  free(actual_array_index);
}

// [1, 2, 3] → 23 (max index)
TEST_F(ArrayTensor, Index123_ToLinear)
{
  size_t input_array_index[3] = {1, 2, 3};
  size_t expected_linear_index = 23;

  size_t actual_linear_index = multiDimArrayToLinearIndex(&dimension_info, input_array_index);

  EXPECT_EQ(actual_linear_index, expected_linear_index);
}

// 23 → [1, 2, 3]
TEST_F(ArrayTensor, Linear23_ToArray)
{
  size_t expected_array_index[3] = {1, 2, 3};

  size_t* actual_array_index = linearToMultiDimArrayIndex(&dimension_info, 23);

  ASSERT_NE(actual_array_index, nullptr);
  EXPECT_EQ(actual_array_index[0], expected_array_index[0]);
  EXPECT_EQ(actual_array_index[1], expected_array_index[1]);
  EXPECT_EQ(actual_array_index[2], expected_array_index[2]);

  free(actual_array_index);
}
