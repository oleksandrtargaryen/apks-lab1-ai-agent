#include <gtest/gtest.h>

#include "math.hpp"

TEST(MathTest, BasicAddition) {
    EXPECT_EQ(add(2, 3), 5);
}
