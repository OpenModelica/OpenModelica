#include <gtest/gtest.h>
#include "arrayIndex.h"

// Test fixture
class ArrayMatrix : public ::testing::Test
{
protected:
    const size_t dim1 = 2;
    const size_t dim2 = 3;

    DIMENSION_ATTRIBUTE dimensions[2] = {
        {.type = DIMENSION_BY_START,
         .start = static_cast<modelica_integer>(dim1),
         .valueReference = static_cast<modelica_integer>(-1)},
        {.type = DIMENSION_BY_START,
         .start = static_cast<modelica_integer>(dim2),
         .valueReference = static_cast<modelica_integer>(-1)}};

    DIMENSION_INFO dimension_info = {
        .numberOfDimensions = 2,
        .dimensions = dimensions};
};

// Test calculation of array length of matrix variable
TEST_F(ArrayMatrix, MatrixHasCorrectLength)
{
    // Arrange
    const size_t expected_length = dim1 * dim2;

    // Act
    size_t actual_length = calculateLength(&dimension_info, nullptr, 0);

    // Assert
    EXPECT_EQ(actual_length, expected_length)
        << "Matrix variable length mismatch: expected " << expected_length
        << ", got " << actual_length;
}
