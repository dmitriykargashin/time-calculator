/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.timecalculator


import com.dmitriykargashin.timecalculator.data.expression.isErrorsInExpression

import org.junit.Test

class WhenCheckExpressionForErrors {

    @Test
    fun `Check expression for double PLUS`() {

        val expression = "0+"
        val expressionToAdd = "+"

        assert(isErrorsInExpression(expressionToAdd, expression))

    }

    @Test
    fun `Check expression for double MINUS`() {

        val expression = "0-"
        val expressionToAdd = "-"

        assert(isErrorsInExpression(expressionToAdd, expression))

    }

    @Test
    fun `Check expression for double DIV`() {

        val expression = "0/"
        val expressionToAdd = "/"

        assert(isErrorsInExpression(expressionToAdd, expression))

    }

    @Test
    fun `Check expression for double MULTIPLY`() {

        val expression = "0*"
        val expressionToAdd = "*"

        assert(isErrorsInExpression(expressionToAdd, expression))

    }

    @Test
    fun `Check expression for OPERATORS * and div `() {

        val expression = "0*"
        val expressionToAdd = "/"

        assert(isErrorsInExpression(expressionToAdd, expression))

    }
    @Test
    fun `Check expression for double OPERATORS * and +`() {

        val expression = "0*"
        val expressionToAdd = "+"

        assert(isErrorsInExpression (expressionToAdd, expression))



    }
    @Test
    fun `Check expression for double OPERATORS * and -`() {

        val expression = "0*"
        val expressionToAdd = "-"

        assert(isErrorsInExpression (expressionToAdd, expression))
    }

    @Test
    fun `Check expression for double OPERATORS - and +`() {

        val expression = "0-"
        val expressionToAdd = "+"

        assert(isErrorsInExpression (expressionToAdd, expression))
    }

    @Test
    fun `Check expression for double OPERATORS - and div`() {

        val expression = "0-"
        val expressionToAdd = "/"

        assert(isErrorsInExpression (expressionToAdd, expression))
    }

    @Test
    fun `Check expression for double OPERATORS - and *`() {

        val expression = "0-"
        val expressionToAdd = "*"

        assert(isErrorsInExpression (expressionToAdd, expression))
    }

    @Test
    fun `Check expression for double OPERATORS + and -`() {

        val expression = "0+"
        val expressionToAdd = "-"

        assert(isErrorsInExpression (expressionToAdd, expression))
    }

    @Test
    fun `Check expression for double OPERATORS + and *`() {

        val expression = "0+"
        val expressionToAdd = "*"

        assert(isErrorsInExpression (expressionToAdd, expression))
    }
    @Test
    fun `Check expression for double OPERATORS + and div`() {

        val expression = "0+"
        val expressionToAdd = "/"

        assert(isErrorsInExpression (expressionToAdd, expression))
    }

    @Test
    fun `Check expression for double OPERATORS div and -`() {

        val expression = "0/"
        val expressionToAdd = "-"

        assert(isErrorsInExpression (expressionToAdd, expression))
    }

    @Test
    fun `Check expression for double OPERATORS div and +`() {

        val expression = "0/"
        val expressionToAdd = "+"

        assert(isErrorsInExpression (expressionToAdd, expression))
    }

    @Test
    fun `Check expression for double OPERATORS div and *`() {

        val expression = "0/"
        val expressionToAdd = "*"

        assert(isErrorsInExpression (expressionToAdd, expression))
    }
    ////////////// checks for TimeOperators
    @Test
    fun `Check expression for double TIME KEYWORDS YEAR and YEAR`() {

        val expression = "0 Year"
        val expressionToAdd = "Year"

        assert(isErrorsInExpression (expressionToAdd, expression))
    }
    @Test
    fun `Check expression for double TIME KEYWORDS MONTH and MONTH`() {

        val expression = "0 Month"
        val expressionToAdd = "Month"

        assert(isErrorsInExpression (expressionToAdd, expression))
    }

    @Test
    fun `Check expression for double TIME KEYWORDS WEEK and WEEK`() {

        val expression = "0 Week"
        val expressionToAdd = "Week"

        assert(isErrorsInExpression (expressionToAdd, expression))
    }
    @Test
    fun `Check expression for double TIME KEYWORDS DAY and DAY`() {

        val expression = "0 Day"
        val expressionToAdd = "Day"

        assert(isErrorsInExpression (expressionToAdd, expression))
    }
    @Test
    fun `Check expression for double TIME KEYWORDS HOUR and HOUR`() {

        val expression = "0 Hour"
        val expressionToAdd = "Hour"

        assert(isErrorsInExpression (expressionToAdd, expression))
    }

    @Test
    fun `Check expression for double TIME KEYWORDS MINUTE and MINUTE`() {

        val expression = "0 Minute"
        val expressionToAdd = "Minute"

        assert(isErrorsInExpression (expressionToAdd, expression))
    }
    @Test
    fun `Check expression for double TIME KEYWORDS SECOND0 and SECOND`() {

        val expression = "0 Second"
        val expressionToAdd = "Second"

        assert(isErrorsInExpression (expressionToAdd, expression))
    }
    @Test
    fun `Check expression for double TIME KEYWORDS MSecond and MSecond`() {

        val expression = "0 Hour"
        val expressionToAdd = "Hour"

        assert(isErrorsInExpression (expressionToAdd, expression))
    }
    ////another logic tests
    @Test
    fun `Check expression for dividing on NUMBER with TIME OPERATOR`() {

        val expression = "10 Hour / 2"
        val expressionToAdd = "Hour"

        assert(isErrorsInExpression (expressionToAdd, expression))
    }

    @Test
    fun `Check expression for multiplying NUMBER with TIME OPERATOR on NUMBER with TIME OPERATOR`() {

        val expression = "10 Hour * 2"
        val expressionToAdd = "Hour"

        assert(isErrorsInExpression (expressionToAdd, expression))
    }

    @Test
    fun `Check NOT ERROR expression for dividing NUMBER with TIME OPERATOR on NUMBER with TIME OPERATOR`() {

        val expression = "10  / 2"
        val expressionToAdd = "Hour"

        assert(!isErrorsInExpression (expressionToAdd, expression))
    }

    @Test
    fun `Check NOT ERROR expression for multiplying on NUMBER with TIME OPERATOR`() {

        val expression = "10  * 2"
        val expressionToAdd = "Hour"

        assert(!isErrorsInExpression (expressionToAdd, expression))
    }

    @Test
    fun `Check NOT ERROR expression for Adding NUMBER with TIME OPERATOR and NUMBER with TIME OPERATOR`() {

        val expression = "10 Hour + 2"
        val expressionToAdd = "Hour"

        assert(!isErrorsInExpression (expressionToAdd, expression))
    }

    @Test
    fun `Check NOT ERROR expression for substracting NUMBER with TIME OPERATOR and NUMBER with TIME OPERATOR`() {

        val expression = "10 Hour - 2"
        val expressionToAdd = "Hour"

        assert(!isErrorsInExpression (expressionToAdd, expression))
    }

    @Test
    fun `Check expression for starting with OPERATOR +`() {

        val expression = ""
        val expressionToAdd = "+"

        assert(isErrorsInExpression (expressionToAdd, expression))
    }

    @Test
    fun `Check expression for starting with OPERATOR -`() {

        val expression = ""
        val expressionToAdd = "-"

        assert(isErrorsInExpression (expressionToAdd, expression))
    }

    @Test
    fun `Check expression for starting with OPERATOR *`() {

        val expression = ""
        val expressionToAdd = "*"

        assert(isErrorsInExpression (expressionToAdd, expression))
    }

    @Test
    fun `Check expression for starting with OPERATOR div`() {

        val expression = ""
        val expressionToAdd = "/"

        assert(isErrorsInExpression (expressionToAdd, expression))
    }

    @Test
    fun `Check expression for double OPERATORS div and YEAR`() {

        val expression = "0/"
        val expressionToAdd = "Year"

        assert(isErrorsInExpression (expressionToAdd, expression))
    }

    @Test
    fun `Check expression for starting with YEAR Keyword`() {

        val expression = ""
        val expressionToAdd = "Year"

        assert(isErrorsInExpression (expressionToAdd, expression))
    }

    @Test
    fun `Check NOT ERROR expression for Number multiply`() {

        val expression = "5"
        val expressionToAdd = "*"

        assert(!isErrorsInExpression (expressionToAdd, expression))
    }

    @Test
    fun `Check NOT ERROR expression for + after Year Keyword`() {

        val expression = "5 Year"
        val expressionToAdd = "+"

        assert(!isErrorsInExpression (expressionToAdd, expression))
    }

    @Test
    fun `Check expression for Multiply NUMBER Years on Year Keyword`() {

        val expression = "5 Year *"
        val expressionToAdd = "Year"

        assert(isErrorsInExpression (expressionToAdd, expression))
    }

    @Test
    fun `Check NOT ERROR float point()`() {

        val expression = "5"
        val expressionToAdd = "."

        assert(!isErrorsInExpression (expressionToAdd, expression))
    }
}

