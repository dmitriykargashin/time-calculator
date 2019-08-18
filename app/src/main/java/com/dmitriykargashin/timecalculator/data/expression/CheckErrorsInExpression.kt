/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.timecalculator.data.expression

import com.dmitriykargashin.timecalculator.data.lexer.LexicalAnalyzer

fun noErrorsInExpression(expressionToAdd: String, expression: String): Boolean {
//here we should check all future errors when we will add the new expression to existing expression
    val expressionTokens = LexicalAnalyzer.analyze(expression)
    val expressionToAddTokens = LexicalAnalyzer.analyze(expressionToAdd)


    return true
}