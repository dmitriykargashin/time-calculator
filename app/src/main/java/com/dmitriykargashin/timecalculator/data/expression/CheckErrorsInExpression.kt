/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.timecalculator.data.expression

import com.dmitriykargashin.timecalculator.data.tokens.TokenType
import com.dmitriykargashin.timecalculator.internal.extension.toTokens

fun isErrorsInExpression(expressionForAdd: String, expression: String): Boolean {
//here we should check all future errors when we will add the new expression to existing expression
    if (expression.isEmpty()) return false

    val expressionTokens = expression.toTokens()
    val expressionForAddTokens = expressionForAdd.toTokens()


   val lastTokenInExpression= expressionTokens.last()
   val lastTokenInExpressionForAdd= expressionForAddTokens.last()


    if (lastTokenInExpression.type.isOperator() &&  lastTokenInExpressionForAdd.type.isOperator() )
        return true


    return false
}