/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.timecalculator.ui.calculator

import android.arch.lifecycle.ViewModel
import android.text.SpannableString
import android.text.Spanned
import com.dmitriykargashin.timecalculator.data.expression.ExpressionRepository
import com.dmitriykargashin.timecalculator.data.tokens.Token
import com.dmitriykargashin.timecalculator.data.tokens.TokenType
import com.dmitriykargashin.timecalculator.data.tokens.TokensRepository
import com.dmitriykargashin.timecalculator.internal.extension.addStartAndEndSpace
import com.dmitriykargashin.timecalculator.internal.extension.toHTMLWithColor

class CalculatorViewModel(
    private val expressionRepository: ExpressionRepository,
    private val tokensRepository: TokensRepository
) : ViewModel() {
    fun getTokens() = tokensRepository.getTokens()

    fun addToken(token: Token) = tokensRepository.addToken(token)

    fun setExpression(expression: SpannableString) = expressionRepository.setExpression(expression)
    fun addToExpression(element: String) = expressionRepository.addToExpression(element)

    fun addToExpression(element: TokenType) {
        when (element) {
            TokenType.PLUS, TokenType.MINUS, TokenType.DIVIDE, TokenType.MULTIPLY ->
                expressionRepository.addToExpression(element.value.addStartAndEndSpace())
            else -> expressionRepository.addToExpression(element.value.addStartAndEndSpace().toHTMLWithColor())
        }
    }

    fun getExpression() = expressionRepository.getExpression()
}