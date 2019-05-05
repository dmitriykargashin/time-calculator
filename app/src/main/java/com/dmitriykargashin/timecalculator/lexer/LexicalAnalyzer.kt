/*
 * Copyright (c) 2019. Dmitriy Kargashin
 *
 * Uses for Lexical analyze for string expression
 */

package com.dmitriykargashin.timecalculator.lexer

import com.dmitriykargashin.timecalculator.extension.removeAllSpaces

import java.util.regex.Pattern


abstract class LexicalAnalyzer {


    companion object {

        // as result list of tokens
        //   val listOfTokens = Tokens()

        var expressionLength = 0
        //   var expression = ""


        fun analyze(stringexpression: String): Tokens {
            //      currentPosition=0
            // removes spaces
            val expression = stringexpression.removeAllSpaces()
            expressionLength = expression.length

            return startAnalyze(expression)
        }

        private fun startAnalyze(expression: String): Tokens {
            val resultTokens = Tokens()
            var currentPosition = 0
            while (currentPosition < expressionLength) {
                val tmpToken = findCurrentFullToken(expression, currentPosition)
                resultTokens.add(tmpToken)
                currentPosition += tmpToken.length()
            }
            return resultTokens
        }

        //Finding out that current symbol is digit
        fun isDigit(x: Char): Boolean = x.isDigit()

        //Finding out that current symbol is letter
        fun isLetter(x: Char): Boolean = x.isLetter()

        //Finding out that current symbol is operator
        fun isOperator(x: Char): Boolean = (x == TokenType.PLUS.value[0]) or (x == TokenType.MINUS.value[0]) or
                (x == TokenType.MULTIPLY.value[0]) or (x == TokenType.DIVIDE.value[0]) or (x == '-') or (x == '/') or (x == '*') or (x == '+')

        //Finding out that current symbol is dot
        fun isDot(x: Char): Boolean = x == '.'


        // finding full token body from current position
        fun findCurrentFullToken(expression: String, currentPosition: Int): Token {
            // In Kotlin we dont need BUILDER Pattern!
            var findedToken = Token(type = TokenType.ERROR)

            if (currentPosition <= expressionLength) {

                when {
                    isDigit((expression[currentPosition])) -> {
                        findedToken = findCurrentDigitalToken(expression, currentPosition)
                    }

                    isLetter((expression[currentPosition])) -> {
                        findedToken = findCurrentLetterToken(expression, currentPosition)
                    }

                    isOperator((expression[currentPosition])) -> {
                        findedToken = findCurrentOperatorToken(expression, currentPosition)
                    }

                    isDot((expression[currentPosition])) -> {
                        findedToken = findCurrentDigitalToken(expression, currentPosition)
                    }

                }

            }
            return findedToken

        }

        private fun findCurrentOperatorToken(expression: String, currentPosition: Int): Token {
            when {
                (expression[currentPosition] == TokenType.PLUS.value[0]) or (expression[currentPosition] == '+') -> {
                    return Token(type = TokenType.PLUS)
                }
                (expression[currentPosition] == TokenType.MINUS.value[0]) or (expression[currentPosition] == '-') -> {
                    return Token(type = TokenType.MINUS)
                }
                (expression[currentPosition] == TokenType.DIVIDE.value[0]) or (expression[currentPosition] == '/') -> {
                    return Token(type = TokenType.DIVIDE)
                }
                (expression[currentPosition] == TokenType.MULTIPLY.value[0]) or (expression[currentPosition] == '*') -> {
                    return Token(type = TokenType.MULTIPLY)
                }
                else -> return Token(type = TokenType.ERROR)
            }

        }

        private fun findCurrentLetterToken(expression: String, currentPosition: Int): Token {
            when {
                expression.startsWith(TokenType.YEAR.value, currentPosition) -> {
                    return Token(type = TokenType.YEAR)
                }

                expression.startsWith(TokenType.MONTH.value, currentPosition) -> {
                    return Token(type = TokenType.MONTH)
                }

                expression.startsWith(TokenType.WEEK.value, currentPosition) -> {
                    return Token(type = TokenType.WEEK)
                }

                expression.startsWith(TokenType.DAY.value, currentPosition) -> {
                    return Token(type = TokenType.DAY)
                }

                expression.startsWith(TokenType.HOUR.value, currentPosition) -> {
                    return Token(type = TokenType.HOUR)
                }

                expression.startsWith(TokenType.MINUTE.value, currentPosition) -> {
                    return Token(type = TokenType.MINUTE)
                }

                expression.startsWith(TokenType.SECOND.value, currentPosition) -> {
                    return Token(type = TokenType.SECOND)
                }

                expression.startsWith(TokenType.MSECOND.value, currentPosition) -> {
                    return Token(type = TokenType.MSECOND)
                }

                else -> return Token(type = TokenType.ERROR)
            }
        }

        private fun findCurrentDigitalToken(expression: String, currentPosition: Int): Token {


            val p = Pattern.compile("-?[\\d\\.]+")
            val m = p.matcher(expression)

            m.find(currentPosition)

            return Token(type = TokenType.NUMBER, strRepresentation = m.group())

        }


    }
}