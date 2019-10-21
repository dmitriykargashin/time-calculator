/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.cardamontimecalculator



import com.dmitriykargashin.cardamontimecalculator.engine.calculator.CalculatorOfTime
import com.dmitriykargashin.cardamontimecalculator.engine.lexer.LexicalAnalyzer
import com.dmitriykargashin.cardamontimecalculator.data.tokens.Token
import com.dmitriykargashin.cardamontimecalculator.data.tokens.TokenType
import com.dmitriykargashin.cardamontimecalculator.data.tokens.Tokens

import com.dmitriykargashin.cardamontimecalculator.internal.extension.addStartAndEndSpace
import com.dmitriykargashin.cardamontimecalculator.internal.extension.toTokens



import org.hamcrest.Description
import org.junit.Assert
import org.junit.Test
import org.hamcrest.MatcherAssert.assertThat

import org.hamcrest.TypeSafeDiagnosingMatcher


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
                if (value.strRepresentation != expectedTokens[index].strRepresentation) {
                    isMatches = false
                }
            }

        mismatchDescription.appendText("$tokens ")
        return isMatches
    }
}


class WhenCalculateExpression {
    private fun calculateExpression(stringExpression: String): Tokens {
        val listOfTokens = LexicalAnalyzer.analyze(stringExpression)

        return CalculatorOfTime.evaluate(listOfTokens)
    }


    @Test
    fun `Calculate Empty expression`() {

        val expressionForCalculate = ""
        val listOfExpectedTokens = "".toTokens()

        val listOfActualTokens = calculateExpression(expressionForCalculate)

        assertThat(listOfActualTokens, isEqualTo(listOfExpectedTokens))
    }


    @Test
    fun calculate_Expr_0_plus_10_Equals_10() {
        val listOfResultTokens = calculateExpression("0${TokenType.PLUS.value.addStartAndEndSpace()}10")

        Assert.assertEquals(0, listOfResultTokens.lastIndex)
        Assert.assertEquals("10", listOfResultTokens[0].strRepresentation)
    }


    @Test
    fun calculate_Expr_0_minus_10_Equals_minus10() {
        val listOfResultTokens = calculateExpression("0${TokenType.MINUS.value.addStartAndEndSpace()}10")

        Assert.assertEquals(0, listOfResultTokens.lastIndex)
        Assert.assertEquals("-10", listOfResultTokens[0].strRepresentation)
    }

    @Test
    fun calculate_Expr_0_multiply_10_Equals_0() {
        val listOfResultTokens = calculateExpression("0${TokenType.MULTIPLY.value.addStartAndEndSpace()}10")

        Assert.assertEquals(0, listOfResultTokens.lastIndex)
        Assert.assertEquals("0", listOfResultTokens[0].strRepresentation)
    }

    @Test

    fun calculate_Expr_0_divide_10_Equals_0() {
        val listOfResultTokens = calculateExpression("0${TokenType.DIVIDE.value.addStartAndEndSpace()}10")

        Assert.assertEquals(0, listOfResultTokens.lastIndex)
        Assert.assertEquals("0", listOfResultTokens[0].strRepresentation)
    }

    @Test
    fun calculate_Expr_10Minute_plus_5Hour_Equals_5Hour10Minute() {
        val listOfResultTokens =
            calculateExpression("10 Minute+ 5 Hour")
        Assert.assertEquals(3, listOfResultTokens.lastIndex)
        Assert.assertEquals("5", listOfResultTokens[0].strRepresentation)
        Assert.assertEquals(TokenType.HOUR.value, listOfResultTokens[1].type.value)
        Assert.assertEquals("10", listOfResultTokens[2].strRepresentation)
        Assert.assertEquals(TokenType.MINUTE.value, listOfResultTokens[3].type.value)
    }

    @Test
    fun calculate_Expr_10Minute_multiply_5_Equals_50Minute() {
        val listOfResultTokens =
            calculateExpression("10 ${TokenType.MINUTE.value} ${TokenType.MULTIPLY.value.addStartAndEndSpace()}5")

        Assert.assertEquals(1, listOfResultTokens.lastIndex)
        Assert.assertEquals("50", listOfResultTokens[0].strRepresentation)
        Assert.assertEquals(TokenType.MINUTE.value, listOfResultTokens[1].type.value)

    }

    @Test
    fun calculate_Expr_10Minute_plus_5Hour_Equals_5Hour10Minute_a() {
        val listOfExpectedTokens = Tokens()

        with(listOfExpectedTokens) {
            add(Token(TokenType.NUMBER, "5"))
            add(Token(TokenType.HOUR))
            add(Token(TokenType.NUMBER, "10"))
            add(Token(TokenType.MINUTE))
        }


        val stringExpression ="10 Minute + 5 Hour"

        val listOfResultTokens = calculateExpression(stringExpression)

        assertThat(listOfResultTokens, isEqualTo(listOfExpectedTokens))

    }

    @Test
    fun calculate_Expr_5Hour_Minus_10_Minute_Equals_4Hour50Minute() {
        val listOfExpectedTokens = Tokens()

        with(listOfExpectedTokens) {
            add(Token(TokenType.NUMBER, "4"))
            add(Token(TokenType.HOUR))
            add(Token(TokenType.NUMBER, "50"))
            add(Token(TokenType.MINUTE))
        }

    //    listOfExpectedTokens= LexicalAnalyzer.
        val stringExpression ="5 Hour-10 Minute"

        val listOfResultTokens = calculateExpression(stringExpression)

        assertThat(listOfResultTokens, isEqualTo(listOfExpectedTokens))

    }
}