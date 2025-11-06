#include <gtest/gtest.h>
#include "arrayIndex.h"
#include "simulation_data.h"

/**
 * @brief Test calculation of linear and multi-dimensional array index.
 *
 * Test index conversion for 2x3 Matrix A =
 * ```txt
 *     a_{1,1} a_{1,2} a_{1,3}
 *     a_{2,1} a_{2,2} a_{2,3}
 * ```
 *
 * Expected output:
 * ```txt
 * Address | Access  | Value
 * --------|---------|--------
 *    0    | A[0][0] | a_{1,1}
 *    1    | A[0][1] | a_{1,2}
 *    2    | A[0][2] | a_{1,3}
 *    3    | A[1][0] | a_{2,1}
 *    4    | A[1][1] | a_{2,2}
 *    5    | A[1][2] | a_{2,3}
 * ```
 */
class ArrayMatrix : public ::testing::Test
{
protected:
  // Prepare dimension data
  DIMENSION_ATTRIBUTE dimensions[2] = {
      {.type = DIMENSION_BY_START,
       .start = 2,
       .valueReference = -1},
      {.type = DIMENSION_BY_START,
       .start = 3,
       .valueReference = -1}};
  DIMENSION_INFO dimension_info = {
      .numberOfDimensions = 2,
      .dimensions = dimensions,
      .scalar_length = 2 * 3};
};

// Test [0, 0] → 0
TEST_F(ArrayMatrix, Index0_0)
{
  size_t input_array_index[2] = {0, 0};
  size_t expectedIndex = 0;

  size_t actualIndex = multiDimArrayToLinearIndex(&dimension_info, input_array_index);

  EXPECT_EQ(actualIndex, expectedIndex);
}

// Test 0 → [0, 0]
TEST_F(ArrayMatrix, Index0)
{
  size_t expectedIndex[2] = {0, 0};

  size_t* actualIndex = linearToMultiDimArrayIndex(&dimension_info, 0);

  ASSERT_NE(actualIndex, nullptr);
  EXPECT_EQ(actualIndex[0], expectedIndex[0]);
  EXPECT_EQ(actualIndex[1], expectedIndex[1]);

  free(actualIndex);
}

// Test [1, 0] → 3
TEST_F(ArrayMatrix, Index1_0)
{
  size_t input_array_index[2] = {1, 0};
  size_t expected_linear_index = 3;

  size_t actual_linear_index = multiDimArrayToLinearIndex(&dimension_info, input_array_index);

  EXPECT_EQ(actual_linear_index, expected_linear_index);
}

// Test 3 → [1, 0]
TEST_F(ArrayMatrix, Index3)
{
  size_t expected_array_index[2] = {1, 0};

  size_t* actual_array_index = linearToMultiDimArrayIndex(&dimension_info, 3);

  ASSERT_NE(actual_array_index, nullptr);
  EXPECT_EQ(actual_array_index[0], expected_array_index[0]);
  EXPECT_EQ(actual_array_index[1], expected_array_index[1]);

  free(actual_array_index);
}

// Test [1, 2] → 5
TEST_F(ArrayMatrix, Index1_2)
{
  size_t input_array_index[2] = {1, 2};
  size_t expected_linear_index = 5;

  size_t actual_linear_index = multiDimArrayToLinearIndex(&dimension_info, input_array_index);

  EXPECT_EQ(actual_linear_index, expected_linear_index);
}

// Test 5 → [1, 2]
TEST_F(ArrayMatrix, Index5)
{
  size_t expected_array_index[2] = {1, 2};

  size_t* actual_array_index = linearToMultiDimArrayIndex(&dimension_info, 5);

  ASSERT_NE(actual_array_index, nullptr);
  EXPECT_EQ(actual_array_index[0], expected_array_index[0]);
  EXPECT_EQ(actual_array_index[1], expected_array_index[1]);

  free(actual_array_index);
}
