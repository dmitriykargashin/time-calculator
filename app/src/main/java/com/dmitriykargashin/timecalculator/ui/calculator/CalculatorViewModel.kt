/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.timecalculator.ui.calculator

import androidx.lifecycle.ViewModel
import android.text.SpannableString
import android.text.Spanned
import com.dmitriykargashin.timecalculator.data.calculator.CalculatorOfTime
import com.dmitriykargashin.timecalculator.data.expression.ExpressionRepository
import com.dmitriykargashin.timecalculator.data.lexer.LexicalAnalyzer
import com.dmitriykargashin.timecalculator.data.tokens.Token
import com.dmitriykargashin.timecalculator.data.tokens.TokenType
import com.dmitriykargashin.timecalculator.data.tokens.TokensRepository
import com.dmitriykargashin.timecalculator.internal.extension.addStartAndEndSpace
import com.dmitriykargashin.timecalculator.internal.extension.toHTMLWithColor
import kotlinx.android.synthetic.main.activity_main.*
import kotlinx.coroutines.*

class CalculatorViewModel(
    private val expressionRepository: ExpressionRepository,
    private val tokensRepository: TokensRepository
) : ViewModel() {

    //for corooutunes
    protected val job = SupervisorJob() // the instance of a Job for this activity
    val scope = CoroutineScope(Dispatchers.IO + job)
///


    fun getTokens() = tokensRepository.getTokens()

    fun addToken(token: Token) = tokensRepository.addToken(token)

    fun setExpression(expression: String) {
        expressionRepository.setExpression(expression)
        evaluateExpression()
    }

    fun addToExpression(element: String) {
        expressionRepository.addToExpression(element)
        evaluateExpression()
    }

    fun addToExpression(element: TokenType) {
        when (element) {
            TokenType.PLUS, TokenType.MINUS, TokenType.DIVIDE, TokenType.MULTIPLY ->
                expressionRepository.addToExpression(element.value.addStartAndEndSpace()) // when we add operators dont need to evaluate
            else -> {
                expressionRepository.addToExpression(element.value.addStartAndEndSpace())
                evaluateExpression()
            }
        }

    }

    fun getExpression() = expressionRepository.getExpression()


    private fun evaluateExpression() {
        //viewModelScope
        scope.coroutineContext.cancelChildren() // here we cancel all previous
        // coroutines because we need only last result

        scope.launch {
            val expr = getExpression().value.toString()
            val listOfTokens = LexicalAnalyzer.analyze(expr)
            val tokensResult = CalculatorOfTime.evaluate(listOfTokens)

            withContext(Dispatchers.Main) {
                tokensRepository.setTokens(tokensResult)

            }


        }


    }

    /* private fun convertEvaluatedTokensToSpannedString(textView: TextView, listOfResultTokens: Tokens) {


         for (token in listOfResultTokens) {
             when (token.type) {
                 TokenType.NUMBER ->
                     textView.append(token.strRepresentation)

                 TokenType.SECOND, TokenType.MSECOND, TokenType.YEAR, TokenType.MONTH, TokenType.WEEK, TokenType.DAY, TokenType.HOUR, TokenType.MINUTE ->
                     textView.append(token.strRepresentation.addStartAndEndSpace().toHTMLWithColor())
             }
         }
         //      Log.i("TAG", textView.text.toString())

     }*/


}