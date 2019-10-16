/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.timecalculator.engine.expression


import com.dmitriykargashin.timecalculator.data.tokens.Token
import com.dmitriykargashin.timecalculator.data.tokens.TokenType
import com.dmitriykargashin.timecalculator.data.tokens.Tokens

fun isErrorsInExpression(expressionForAdd: Token, expression: Tokens): Boolean {
//here we should check all future errors when we will add the new expression to existing expression
    // if (expression.isEmpty() &&) return false


    //  val expressionTokens = expression
    //   val expressionForAddTokens = expressionForAdd


    //  val lastTokenInExpressionForAdd = expressionForAddTokens.last()
    // no need to check further if we add number to empty expression


    if (expression.isEmpty() && expressionForAdd.type == TokenType.NUMBER) return false



    if (expression.isEmpty() && (expressionForAdd.type.isTimeKeyword() || expressionForAdd.type.isOperator() || expressionForAdd.type==TokenType.DOT))
        return true

    val lastTokenInExpression = expression.last()


// check for double operators
    if (lastTokenInExpression.type.isOperator() && expressionForAdd.type.isOperator())
        return true

    // check for dot after operators
    if (lastTokenInExpression.type.isOperator() && expressionForAdd.type == TokenType.DOT)
        return true

// check for operator and time keyword in row
    if (lastTokenInExpression.type.isOperator()
        && expressionForAdd.type.isTimeKeyword()
    )
        return true

// check for double Time operators
    if (lastTokenInExpression.type.isTimeKeyword() && expressionForAdd.type.isTimeKeyword())
        return true

    // check for divide or multiply on number with time keyword
    if (expression.size > 1) {
        val preLastTokenInExpression = expression[expression.size - 2]
        if (!expression.isSimpleArithmeticExpression() &&
            (preLastTokenInExpression.type == TokenType.MULTIPLY || preLastTokenInExpression.type == TokenType.DIVIDE)
            && expressionForAdd.type.isTimeKeyword()
        )
            return true
    }

    return false

}

fun isErrorAfterCheckForPoint(expressionForAdd: String, expression: String): Boolean {
    //  Log.i("TAG", "check for point: $expression     $expressionForAdd")
//    val lastTokenInExpressionForAdd = expressionForAddTokens.last()
    // no need to check further if we add number to empty expression
//    if (expression.isEmpty() && lastTokenInExpressionForAdd.type == TokenType.NUMBER) return false


    // check for point to add!
    if (expressionForAdd == ".") {
        if (expression.isNotEmpty() && expression.last().isDigit()) {
            //    Log.i("TAG", "Point: $expression     $expressionForAdd")
            return false
        }
    } else return false

    return true
}

