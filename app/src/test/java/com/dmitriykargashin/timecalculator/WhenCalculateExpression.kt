/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.timecalculator

import com.dmitriykargashin.timecalculator.calculator.CalculatorOfTime
import com.dmitriykargashin.timecalculator.extension.addStartAndEndSpace
import com.dmitriykargashin.timecalculator.lexer.LexicalAnalyzer
import com.dmitriykargashin.timecalculator.lexer.TokenType
import com.dmitriykargashin.timecalculator.lexer.Tokens
import org.junit.Assert
import org.junit.Test

class WhenCalculateExpression {
    private fun CalculateExpression(stringExpression: String): Tokens {
        val lexicalAnalyzer = LexicalAnalyzer(stringExpression)
        val listOfTokens = lexicalAnalyzer.analyze()

        return CalculatorOfTime.evaluate(listOfTokens)
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
            CalculateExpression("10 ${TokenType.MINUTE.value} ${TokenType.PLUS.value.addStartAndEndSpace()}5 ${TokenType.HOUR.value}")

        Assert.assertEquals(3, listOfResultTokens.lastIndex)
        Assert.assertEquals("5", listOfResultTokens[0].strRepresentation)
        Assert.assertEquals(TokenType.HOUR.value, listOfResultTokens[1].type.value)
        Assert.assertEquals("10", listOfResultTokens[2].strRepresentation)
        Assert.assertEquals(TokenType.MINUTE.value, listOfResultTokens[3].type.value)
    }
}