/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.timecalculator.data.expression


import android.util.Log
import com.dmitriykargashin.timecalculator.data.tokens.TokenType
import com.dmitriykargashin.timecalculator.internal.extension.toTokens

fun isErrorsInExpression(expressionForAdd: String, expression: String): Boolean {
//here we should check all future errors when we will add the new expression to existing expression
    // if (expression.isEmpty() &&) return false
    Log.i("TAG", "check: $expression     $expressionForAdd")
    val expressionTokens = expression.toTokens()
    val expressionForAddTokens = expressionForAdd.toTokens()


    val lastTokenInExpressionForAdd = expressionForAddTokens.last()
    // no need to check further if we add number to empty expression
    if (expression.isEmpty() && lastTokenInExpressionForAdd.type == TokenType.NUMBER) return false

    if (expression.isEmpty() and (lastTokenInExpressionForAdd.type.isTimeKeyword() or lastTokenInExpressionForAdd.type.isOperator()))
        return true

    val lastTokenInExpression = expressionTokens.last()


// check for double operators
    if (lastTokenInExpression.type.isOperator() && lastTokenInExpressionForAdd.type.isOperator())
        return true


// check for operator and time keyword in row
    if (lastTokenInExpression.type.isOperator()
        and lastTokenInExpressionForAdd.type.isTimeKeyword()
    )
        return true

// check for double Time operators
    if (lastTokenInExpression.type.isTimeKeyword() && lastTokenInExpressionForAdd.type.isTimeKeyword())
        return true

    // check for divide or multiply on number with time keyword
    if (expressionTokens.size > 1) {
        val preLastTokenInExpression = expressionTokens[expressionTokens.size - 2]
        if (!expressionTokens.isSimpleArithmeticExpression() &&
            (preLastTokenInExpression.type == TokenType.MULTIPLY || preLastTokenInExpression.type == TokenType.DIVIDE)
            && lastTokenInExpressionForAdd.type.isTimeKeyword()
        )
            return true
    }

    return false
}