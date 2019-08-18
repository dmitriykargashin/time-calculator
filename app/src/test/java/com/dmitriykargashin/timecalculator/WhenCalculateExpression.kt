/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.timecalculator


import com.dmitriykargashin.timecalculator.calculator.CalculatorOfTime
import com.dmitriykargashin.timecalculator.extension.addStartAndEndSpace
import com.dmitriykargashin.timecalculator.lexer.LexicalAnalyzer
import com.dmitriykargashin.timecalculator.lexer.Token
import com.dmitriykargashin.timecalculator.lexer.TokenType
import com.dmitriykargashin.timecalculator.lexer.Tokens


import org.hamcrest.Description
import org.junit.Assert
import org.junit.Test
import org.hamcrest.MatcherAssert.assertThat

import org.hamcrest.TypeSafeDiagnosingMatcher
import org.junit.Ignore


// function for checking equality of Tokens Object instances
fun isEqualTo(expectedTokens: Tokens) = object : TypeSafeDiagnosingMatcher<Tokens>() {
    override fun describeTo(description: Description) {
        description.appendText("$expectedTokens")
    }

    override fun matchesSafely(tokens: Tokens, mismatchDescription: Description): Boolean {
        var isMatches = true
        if (tokens.size != expectedTokens.size) isMatches = false
        else
            for ((index, value) in tokens.withIndex()) {
                if (!value.strRepresentation.equals(expectedTokens[index].strRepresentation)) {
                    isMatches = false
                }
            }

        mismatchDescription.appendText("$tokens ")
        return isMatches
    }
}


class WhenCalculateExpression {
    private fun CalculateExpression(stringExpression: String): Tokens {
        val listOfTokens = LexicalAnalyzer.analyze(stringExpression)

        return CalculatorOfTime.evaluate(listOfTokens)
    }


    @Test
    fun `Calculate Empty expression`() {

        val expressionForCalculate = ""
        val listOfExpectedTokens = "".toTokens()

        val listOfActualTokens = CalculateExpression(expressionForCalculate)

        assertThat(listOfActualTokens, isEqualTo(listOfExpectedTokens))
    }


    @Test
    fun Calculate_Expr_0_plus_10_Equals_10() {
        val listOfResultTokens = CalculateExpression("0${TokenType.PLUS.value.addStartAndEndSpace()}10")

        Assert.assertEquals(0, listOfResultTokens.lastIndex)
        Assert.assertEquals("10", listOfResultTokens[0].strRepresentation)
    }


    @Test
    fun Calculate_Expr_0_minus_10_Equals_minus10() {
        val listOfResultTokens = CalculateExpression("0${TokenType.MINUS.value.addStartAndEndSpace()}10")

        Assert.assertEquals(0, listOfResultTokens.lastIndex)
        Assert.assertEquals("-10", listOfResultTokens[0].strRepresentation)
    }

    @Test
    fun Calculate_Expr_0_multiply_10_Equals_0() {
        val listOfResultTokens = CalculateExpression("0${TokenType.MULTIPLY.value.addStartAndEndSpace()}10")

        Assert.assertEquals(0, listOfResultTokens.lastIndex)
        Assert.assertEquals("0", listOfResultTokens[0].strRepresentation)
    }

    @Test

    fun Calculate_Expr_0_divide_10_Equals_0() {
        val listOfResultTokens = CalculateExpression("0${TokenType.DIVIDE.value.addStartAndEndSpace()}10")

        Assert.assertEquals(0, listOfResultTokens.lastIndex)
        Assert.assertEquals("0", listOfResultTokens[0].strRepresentation)
    }

    @Test
    fun Calculate_Expr_10Minute_plus_5Hour_Equals_5Hour10Minute() {
        val listOfResultTokens =
            CalculateExpression("10 Minute+ 5 Hour")
        Assert.assertEquals(3, listOfResultTokens.lastIndex)
        Assert.assertEquals("5", listOfResultTokens[0].strRepresentation)
        Assert.assertEquals(TokenType.HOUR.value, listOfResultTokens[1].type.value)
        Assert.assertEquals("10", listOfResultTokens[2].strRepresentation)
        Assert.assertEquals(TokenType.MINUTE.value, listOfResultTokens[3].type.value)
    }

    @Test
    fun Calculate_Expr_10Minute_multiply_5_Equals_50Minute() {
        val listOfResultTokens =
            CalculateExpression("10 ${TokenType.MINUTE.value} ${TokenType.MULTIPLY.value.addStartAndEndSpace()}5")

        Assert.assertEquals(1, listOfResultTokens.lastIndex)
        Assert.assertEquals("50", listOfResultTokens[0].strRepresentation)
        Assert.assertEquals(TokenType.MINUTE.value, listOfResultTokens[1].type.value)

    }

    @Test
    fun Calculate_Expr_10Minute_plus_5Hour_Equals_5Hour10Minute_a() {
        val listOfExpectedTokens = Tokens()

        with(listOfExpectedTokens) {
            add(Token(TokenType.NUMBER, "5"))
            add(Token(TokenType.HOUR))
            add(Token(TokenType.NUMBER, "10"))
            add(Token(TokenType.MINUTE))
        }


        val stringExpression ="10 Minute + 5 Hour"

        val listOfResultTokens = CalculateExpression(stringExpression)

        assertThat(listOfResultTokens, isEqualTo(listOfExpectedTokens))

    }

    @Test
    fun Calculate_Expr_5Hour_Minus_10_Minute_Equals_4Hour50Minute() {
        val listOfExpectedTokens = Tokens()

        with(listOfExpectedTokens) {
            add(Token(TokenType.NUMBER, "4"))
            add(Token(TokenType.HOUR))
            add(Token(TokenType.NUMBER, "50"))
            add(Token(TokenType.MINUTE))
        }

    //    listOfExpectedTokens= LexicalAnalyzer.
        val stringExpression ="5 Hour-10 Minute"

        val listOfResultTokens = CalculateExpression(stringExpression)

        assertThat(listOfResultTokens, isEqualTo(listOfExpectedTokens))

    }
}