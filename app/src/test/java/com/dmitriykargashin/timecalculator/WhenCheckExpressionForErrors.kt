/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.timecalculator


import com.dmitriykargashin.timecalculator.data.expression.isErrorsInExpression
import com.dmitriykargashin.timecalculator.data.tokens.Token
import com.dmitriykargashin.timecalculator.data.tokens.TokenType
import com.dmitriykargashin.timecalculator.data.tokens.Tokens
import org.hamcrest.MatcherAssert
import org.junit.Test

class WhenCheckExpressionForErrors {

    @Test
    fun `Check expression for double PLUS`() {

        val expression = "0+"
        val expressionToAdd = "+"

       assert(isErrorsInExpression (expressionToAdd, expression))

        }

    @Test
    fun `Check expression for double MINUS`() {

        val expression = "0-"
        val expressionToAdd = "-"

        assert(isErrorsInExpression (expressionToAdd, expression))

    }
    @Test
    fun `Check expression for double DIV`() {

        val expression = "0/"
        val expressionToAdd = "/"

        assert(isErrorsInExpression (expressionToAdd, expression))

    }
    @Test
    fun `Check expression for double MULTIPLY`() {

        val expression = "0*"
        val expressionToAdd = "*"

        assert(isErrorsInExpression (expressionToAdd, expression))

    }

    @Test
    fun `Check expression for double OPERATORS`() {

        val expression = "0*"
        val expressionToAdd = "/"

        assert(isErrorsInExpression (expressionToAdd, expression))

        val expression1 = "0+"
        val expressionToAdd1 = "/"

        assert(isErrorsInExpression (expressionToAdd1, expression1))

    }
}