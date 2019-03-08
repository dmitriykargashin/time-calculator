/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.timecalculator.calculator

import android.util.Log
import com.dmitriykargashin.timecalculator.extension.removeAllSpaces
import com.dmitriykargashin.timecalculator.extension.removeHTML
import com.dmitriykargashin.timecalculator.lexer.LexicalAnalyzer
import com.dmitriykargashin.timecalculator.lexer.Token
import com.dmitriykargashin.timecalculator.lexer.TokenType
import com.dmitriykargashin.timecalculator.lexer.Tokens
import kotlinx.android.synthetic.main.activity_main.*
import net.objecthunter.exp4j.ExpressionBuilder


abstract class CalculatorOfTime {

    private val MILLIS_IN_SECOND = 1000
    private val SECONDS_IN_MINUTE = 60
    private val MINUTES_IN_HOUR = 60
    private val HOURS_IN_DAY = 24
    private val DAYS_IN_YEAR = 365
    private val MILLISECONDS_IN_YEAR =
        MILLIS_IN_SECOND.toLong() * SECONDS_IN_MINUTE.toLong() * MINUTES_IN_HOUR.toLong() * HOURS_IN_DAY.toLong() * DAYS_IN_YEAR.toLong()

    companion object {
        fun evaluate(tokensToEvaluate: Tokens): Tokens {


            return evaluateSimpleArithmeticExpression(tokensToEvaluate)

            if (isSimpleArithmeticExpression(tokensToEvaluate))
                return evaluateSimpleArithmeticExpression(tokensToEvaluate)
            else {
                var tokensinMsecs = convertExpressionToMsecs(tokensToEvaluate)
            }

            /*  for (token in tokensinMsecs) {
              when (token.type) {
                  TokenType.
              }
          }*/
            return tokensToEvaluate

        }


        private fun evaluateSimpleArithmeticExpression(tokensToEvaluate: Tokens): Tokens {


            val txt = tokensToEvaluate.toString()
            // Create an Expression (A class from exp4j library)
            val expression = ExpressionBuilder(txt).build()
            try {
                // Calculate the result and display
                val result = expression.evaluate()

                val resultTokens: Tokens = Tokens()
                resultTokens.add(Token(TokenType.NUMBER, result.toString(), 0))


                return resultTokens


                Log.d("TAG", result.toString())

                // txtInput.text = result.toString()
                //     lastDot = true // Result contains a dot
            } catch (ex: ArithmeticException) {
                // Display an error message
                //    txtInput.text = "Error"
                //    stateError = true
                //    lastNumeric = false
            }
            /*

        var term: Long
        for (token in tokensToEvaluate) {
            when (token.type) {

                TokenType.NUMBER -> term = token.strRepresentation.toLong()
                TokenType.PLUS
            }


            return tokensToEvaluate
            TODO("not implemented") //To change body of created functions use File | Settings | File Templates.

*/
            return tokensToEvaluate
        }


        // here we check whether the expression is a simple arithmetic expression
        fun isSimpleArithmeticExpression(tokensToEvaluate: Tokens): Boolean {
            for (token in tokensToEvaluate) {
                when (token.type) {
                    TokenType.MSECOND, TokenType.SECOND, TokenType.HOUR, TokenType.MINUTE, TokenType.DAY, TokenType.WEEK, TokenType.YEAR -> return false
                    else -> return true

                }
            }
            return false
        }

        private fun convertExpressionToMsecs(tokensToConvert: Tokens): Tokens {
            var convertedTokens: Tokens = Tokens()

            /*   for (token in tokensToConvert) {
               when (token.type) {
                   TokenType.
               }
           }*/
            return convertedTokens
        }

    }
}
