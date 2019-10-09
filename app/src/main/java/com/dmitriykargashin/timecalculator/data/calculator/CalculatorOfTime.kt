/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.timecalculator.data.calculator

import android.util.Log
import com.dmitriykargashin.timecalculator.data.tokens.Token
import com.dmitriykargashin.timecalculator.data.tokens.TokenType
import com.dmitriykargashin.timecalculator.data.tokens.Tokens
import com.dmitriykargashin.timecalculator.utilites.TimeConverter
import net.objecthunter.exp4j.ExpressionBuilder
import java.text.NumberFormat


abstract class CalculatorOfTime {


    companion object {


        fun evaluate(tokensToEvaluate: Tokens): Tokens {

            val clonedTokensToEvaluate = tokensToEvaluate.clone()
            //

            if (clonedTokensToEvaluate.isSimpleArithmeticExpression())
                return evaluateSimpleArithmeticExpression(clonedTokensToEvaluate)
            else {
                val tokensWithParentheses = setParenthesesToExpression(clonedTokensToEvaluate)
                val tokensinMsecs = TimeConverter.convertExpressionToMsecs(tokensWithParentheses)
                val evaluatedToken = evaluateSimpleArithmeticExpression(tokensinMsecs)

                //  return convertExpressionInMsecsToType(evaluatedToken[0], TokenType.HOUR)
                return TimeConverter.convertExpressionInMsecsToNearest(evaluatedToken[0])
            }


        }


        private fun evaluateSimpleArithmeticExpression(tokensToEvaluate: Tokens): Tokens {

            Log.i("evaluate before", tokensToEvaluate.toString())

//if we have trailing operator in expression we need to delete it
            if (tokensToEvaluate.lastIndex >= 0 && tokensToEvaluate.last().type.isOperator()) {
                tokensToEvaluate.removeLastToken()
            }

            if (tokensToEvaluate.lastIndex >= 1 && tokensToEvaluate.last().type == TokenType.PARENTHESES_RIGHT
                && tokensToEvaluate.elementAt(tokensToEvaluate.lastIndex - 1).type.isOperator())
             {
                tokensToEvaluate.removeLastToken().removeLastToken()
            }


            val txt = tokensToEvaluate.toString()
            Log.i("evaluate", txt)

            val resultTokens = Tokens()
            if (txt == "") return resultTokens // expression is empty so return empty Tokens list

            // Create an Expression (A class from exp4j library)

            try {
                val expression = ExpressionBuilder(txt).build()
                // Calculate the result
                val result = expression.evaluate()

                // we'll return result as one NUMBER token

                val fmt = NumberFormat.getInstance()
                fmt.setGroupingUsed(false)
                fmt.setMaximumIntegerDigits(999)
                fmt.setMaximumFractionDigits(999)
                val resultAsString = fmt.format(result)


//                Log.i("result", result.toString())
                resultTokens.add(
                    Token(
                        TokenType.NUMBER,
                        resultAsString
                        /*result.toString()*/
                    )
                )

                return resultTokens

                // txtInput.text = result.toString()
                //     lastDot = true // Result contains a dot
            } catch (ex: Exception) {
                //   val resultTokens = Tokens()
                resultTokens.add(
                    Token(
                        TokenType.ERROR,
                        "ERROR"
                    )
                )
                Log.i("TAG", "Catch ERROR")
                return resultTokens

            }

        }





        private fun setParenthesesToExpression(tokensToSetParntheses: Tokens): Tokens {
            val tokensWithParentheses = Tokens()
            var isParenthesesBegins = false
            for (token in tokensToSetParntheses) {
                when (token.type) {
                    TokenType.NUMBER -> {
                        if (!isParenthesesBegins) {
                            tokensWithParentheses.add(
                                Token(
                                    TokenType.PARENTHESES_LEFT
                                )
                            )
                            isParenthesesBegins = true
                        }
                    }
                    TokenType.MULTIPLY, TokenType.DIVIDE, TokenType.MINUS, TokenType.PLUS -> {

                        tokensWithParentheses.add(Token(TokenType.PARENTHESES_RIGHT))
                        isParenthesesBegins = false

                    }
                }
                tokensWithParentheses.add(
                    Token(
                        token.type,
                        token.strRepresentation
                    )
                )

            }
            tokensWithParentheses.add(Token(TokenType.PARENTHESES_RIGHT))
            return tokensWithParentheses
        }

    }

    //todo -In result of negative expression will be terms with MINUS symbol EACH

}

