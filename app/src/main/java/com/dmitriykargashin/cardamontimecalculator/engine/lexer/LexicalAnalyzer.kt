/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.cardamontimecalculator.engine.lexer

import com.dmitriykargashin.cardamontimecalculator.data.tokens.Token
import com.dmitriykargashin.cardamontimecalculator.data.tokens.TokenType
import com.dmitriykargashin.cardamontimecalculator.data.tokens.Tokens
import com.dmitriykargashin.cardamontimecalculator.internal.extension.removeAllSpaces

import java.util.regex.Pattern


abstract class LexicalAnalyzer {


    companion object {

        // as result list of tokens
        //   val listOfTokens = Tokens()

        private var expressionLength = 0
        //   var expression = ""


        fun analyze(stringexpression: String): Tokens {
            //      currentPosition=0
            // removes spaces
            val expression = stringexpression.removeAllSpaces()
            expressionLength = expression.length

            return startAnalyze(
                expression
            )
        }

        private fun startAnalyze(expression: String): Tokens {
            val resultTokens = Tokens()
            var currentPosition = 0
            while (currentPosition < expressionLength) {
                val tmpToken =
                    findCurrentFullToken(
                        expression,
                        currentPosition,
                        resultTokens
                    )
                resultTokens.add(tmpToken)
                currentPosition += tmpToken.length()
            }
            return resultTokens
        }

        //Finding out that current symbol is digit
        private fun isDigit(x: Char): Boolean = x.isDigit()

        //Finding out that current symbol is letter
        private fun isLetter(x: Char): Boolean = x.isLetter()

        //Finding out that current symbol is operator
        private fun isOperator(x: Char): Boolean =
            (x == TokenType.PLUS.value[0]) or (x == TokenType.MINUS.value[0]) or
                    (x == TokenType.MULTIPLY.value[0]) or (x == TokenType.DIVIDE.value[0]) or (x == '-') or (x == '/') or (x == '*') or (x == '+')

        //Finding out that current symbol is dot
        //     fun isDot(x: Char): Boolean = x == '.'


        // finding full token body from current position
        private fun findCurrentFullToken(
            expression: String,
            currentPosition: Int,
            currentTokens: Tokens
        ): Token {
            // In Kotlin we dont need BUILDER Pattern!
            var findedToken =
                Token(type = TokenType.ERROR, value = 1.toBigDecimal())

            if (currentPosition <= expressionLength) {

                when {
                    isDigit((expression[currentPosition])) -> {
                        findedToken =
                            findCurrentDigitalToken(
                                expression,
                                currentPosition
                            )
                    }

                    isLetter((expression[currentPosition])) -> {
                        findedToken =
                            findCurrentLetterToken(
                                expression,
                                currentPosition,
                                currentTokens
                            )
                    }

                    isOperator((expression[currentPosition])) -> {
                        findedToken =
                            findCurrentOperatorToken(
                                expression,
                                currentPosition
                            )
                    }

                    /*   isDot((expression[currentPosition])) -> {
                           findedToken =
                               findCurrentDigitalToken(
                                   expression,
                                   currentPosition
                               )
                       }*/

                }

            }
            return findedToken

        }

        private fun findCurrentOperatorToken(expression: String, currentPosition: Int): Token {
            return when {
                (expression[currentPosition] == TokenType.PLUS.value[0]) or (expression[currentPosition] == '+') -> {
                    Token(type = TokenType.PLUS, value = 1.toBigDecimal())
                }
                (expression[currentPosition] == TokenType.MINUS.value[0]) or (expression[currentPosition] == '-') -> {
                    Token(type = TokenType.MINUS, value = 1.toBigDecimal())
                }
                (expression[currentPosition] == TokenType.DIVIDE.value[0]) or (expression[currentPosition] == '/') -> {
                    Token(type = TokenType.DIVIDE, value = 1.toBigDecimal())
                }
                (expression[currentPosition] == TokenType.MULTIPLY.value[0]) or (expression[currentPosition] == '*') -> {
                    Token(type = TokenType.MULTIPLY, value = 1.toBigDecimal())
                }
                else -> Token(type = TokenType.ERROR, value = 1.toBigDecimal())
            }

        }

        private fun findCurrentLetterToken(
            expression: String,
            currentPosition: Int,
            currentTokens: Tokens
        ): Token {
            var tokenValue = 1.toBigDecimal()
            if (currentTokens.isNotEmpty() && currentTokens.last().type == TokenType.NUMBER) {
                tokenValue = currentTokens.last().value
            }

            when {
                expression.startsWith(TokenType.YEAR.value, currentPosition) -> {
                    return Token(type = TokenType.YEAR, tokenValue)
                }

                expression.startsWith(TokenType.MONTH.value, currentPosition) -> {
                    return Token(type = TokenType.MONTH, tokenValue)
                }

                expression.startsWith(TokenType.WEEK.value, currentPosition) -> {
                    return Token(type = TokenType.WEEK, tokenValue)
                }

                expression.startsWith(TokenType.DAY.value, currentPosition) -> {
                    return Token(type = TokenType.DAY, tokenValue)
                }

                expression.startsWith(TokenType.HOUR.value, currentPosition) -> {
                    return Token(type = TokenType.HOUR, tokenValue)
                }

                expression.startsWith(TokenType.MINUTE.value, currentPosition) -> {
                    return Token(type = TokenType.MINUTE, tokenValue)
                }

                expression.startsWith(TokenType.SECOND.value, currentPosition) -> {
                    return Token(type = TokenType.SECOND, tokenValue)
                }

                expression.startsWith(TokenType.MSECOND.value, currentPosition) -> {
                    return Token(type = TokenType.MSECOND, tokenValue)
                }

                else -> return Token(type = TokenType.ERROR,tokenValue)
            }
        }

        private fun findCurrentDigitalToken(expression: String, currentPosition: Int): Token {


            val p = Pattern.compile("-?[\\d\\.]+")
            val m = p.matcher(expression)

            m.find(currentPosition)

            return Token(
                type = TokenType.NUMBER,
                m.group().toBigDecimal(),
                strRepresentation = m.group()
            )

        }

    }
}