/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.timecalculator.ui.calculator

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.dmitriykargashin.timecalculator.data.calculator.CalculatorOfTime
import com.dmitriykargashin.timecalculator.data.expression.ExpressionRepository
import com.dmitriykargashin.timecalculator.data.lexer.LexicalAnalyzer
import com.dmitriykargashin.timecalculator.data.tokens.Token
import com.dmitriykargashin.timecalculator.data.tokens.TokenType
import com.dmitriykargashin.timecalculator.data.tokens.Tokens
import com.dmitriykargashin.timecalculator.data.tokens.TokensRepository
import com.dmitriykargashin.timecalculator.internal.extension.addStartAndEndSpace
import kotlinx.coroutines.*
import kotlin.coroutines.CoroutineContext

class CalculatorViewModel(
    private val expressionRepository: ExpressionRepository,
    private val tokensRepository: TokensRepository
) : ViewModel() {

    //for corooutunes
    //   protected val job = SupervisorJob() // the instance of a Job for this activity
    //   val scopeIO = CoroutineScope(Dispatchers.IO + job)
    //  val scopeIO = CoroutineScope(Dispatchers.Default)
    // val scopeUI = viewModelScope //.. CoroutineScope(Dispatchers.Main)
///


    /*  private val job = Job()
      override val coroutineContext: CoroutineContext
          get() = job + Dispatchers.Main
  */
    fun getTokens() = tokensRepository.getTokens()

    fun addToken(token: Token) = tokensRepository.addToken(token)

    fun setExpression(expression: String) {
       // if (
            expressionRepository.setExpression(expression)//) {
       //     viewModelScope.coroutineContext.cancelChildren()
         //   viewModelScope.launch { evaluateExpression() }
      //  }
    }

    fun addToExpression(element: String) {
        if (expressionRepository.addToExpression(element)) {
            viewModelScope.coroutineContext.cancelChildren()
            viewModelScope.launch {

                evaluateExpression()
            }
        }
    }

    fun addToExpression(element: TokenType) {
        when (element) {
            TokenType.PLUS, TokenType.MINUS, TokenType.DIVIDE, TokenType.MULTIPLY ->
                expressionRepository.addToExpression(element.value.addStartAndEndSpace()) // when we add operators dont need to evaluate
            else -> {

                if (expressionRepository.addToExpression(element.value.addStartAndEndSpace())) {
                    viewModelScope.coroutineContext.cancelChildren()
                    viewModelScope.launch { evaluateExpression() }
                }
            }
        }


    }

    fun getExpression() = expressionRepository.getExpression()


    private suspend fun evaluateExpression() {

        val resulTokens = withContext(Dispatchers.Default) {
            analyzeAndCalculateExpression(getExpression().value.toString())
        }
        tokensRepository.setTokens(resulTokens)


    }


    private fun analyzeAndCalculateExpression(expr: String): Tokens {
        val listOfTokens = LexicalAnalyzer.analyze(expr)
        //   delay(1000)
        return CalculatorOfTime.evaluate(listOfTokens)

    }

    fun clearAll() {
        tokensRepository.setTokens(Tokens())
        expressionRepository.setExpression("")

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