/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.timecalculator

import com.dmitriykargashin.timecalculator.calculator.CalculatorOfTime
import com.dmitriykargashin.timecalculator.lexer.LexicalAnalyzer
import org.junit.Assert
import org.junit.Test

class WhenCalculateExpression {
    @Test
    fun Calculate_Expr_0_plus_10_Equals_10() {
        val lexicalAnalyzer = LexicalAnalyzer("0+10")
        val listOfTokens = lexicalAnalyzer.analyze()

        val listOfResultTokens = CalculatorOfTime.evaluate(listOfTokens)

        Assert.assertEquals(0, listOfResultTokens.lastIndex)
        Assert.assertEquals("10", listOfResultTokens[0].strRepresentation)
    }
}