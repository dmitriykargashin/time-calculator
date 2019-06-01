/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.timecalculator.data.calculator

import com.dmitriykargashin.timecalculator.data.tokens.Token
import com.dmitriykargashin.timecalculator.data.tokens.TokenType
import com.dmitriykargashin.timecalculator.data.tokens.Tokens
import net.objecthunter.exp4j.ExpressionBuilder


abstract class CalculatorOfTime {


    companion object {


        private val MILLISECONDS_IN_SECOND = 1000
        private val SECONDS_IN_MINUTE = 60
        private val MINUTES_IN_HOUR = 60
        private val HOURS_IN_DAY = 24
        private val DAYS_IN_WEEK = 7
        private val DAYS_IN_MONTH = 30
        private val DAYS_IN_YEAR = 365

        private val MILLISECONDS_IN_YEAR =
            MILLISECONDS_IN_SECOND.toLong() * SECONDS_IN_MINUTE.toLong() * MINUTES_IN_HOUR.toLong() * HOURS_IN_DAY.toLong() * DAYS_IN_YEAR.toLong()

        private val MILLISECONDS_IN_MONTH =
            MILLISECONDS_IN_SECOND.toLong() * SECONDS_IN_MINUTE.toLong() * MINUTES_IN_HOUR.toLong() * HOURS_IN_DAY.toLong() * DAYS_IN_MONTH.toLong()

        private val MILLISECONDS_IN_WEEK =
            MILLISECONDS_IN_SECOND.toLong() * SECONDS_IN_MINUTE.toLong() * MINUTES_IN_HOUR.toLong() * HOURS_IN_DAY.toLong() * DAYS_IN_WEEK.toLong()

        private val MILLISECONDS_IN_DAY =
            MILLISECONDS_IN_SECOND.toLong() * SECONDS_IN_MINUTE.toLong() * MINUTES_IN_HOUR.toLong() * HOURS_IN_DAY.toLong()

        private val MILLISECONDS_IN_HOUR =
            MILLISECONDS_IN_SECOND.toLong() * SECONDS_IN_MINUTE.toLong() * MINUTES_IN_HOUR.toLong()

        private val MILLISECONDS_IN_MINUTE =
            MILLISECONDS_IN_SECOND.toLong() * SECONDS_IN_MINUTE.toLong()


        fun evaluate(tokensToEvaluate: Tokens): Tokens {


            //

            if (isSimpleArithmeticExpression(tokensToEvaluate))
                return evaluateSimpleArithmeticExpression(tokensToEvaluate)
            else {
                val tokensWithParentheses = setParenthesesToExpression(tokensToEvaluate)
                val tokensinMsecs = convertExpressionToMsecs(tokensWithParentheses)
                val evaluatedToken = evaluateSimpleArithmeticExpression(tokensinMsecs)

                //  return convertExpressionInMsecsToType(evaluatedToken[0], TokenType.HOUR)
                return convertExpressionInMsecsToNearest(evaluatedToken[0])
            }

            /*  for (token in tokensinMsecs) {
              when (token.type) {
                  TokenType.
              }
          }*/
            //      return tokensToEvaluate

        }


        private fun evaluateSimpleArithmeticExpression(tokensToEvaluate: Tokens): Tokens {


            val txt = tokensToEvaluate.toString()
            //   Log.i("TAG", txt)

            // Create an Expression (A class from exp4j library)
            val expression = ExpressionBuilder(txt).build()
            try {
                // Calculate the result and display
                val result = expression.evaluate()

                // we'll return result as one NUMBER token
                val resultTokens = Tokens()
                resultTokens.add(
                    Token(
                        TokenType.NUMBER,
                        result.toString()
                    )
                )

                return resultTokens

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


*/
            return tokensToEvaluate
        }


        // here we check whether the expression is a simple arithmetic expression
        fun isSimpleArithmeticExpression(tokensToEvaluate: Tokens): Boolean {
            for (token in tokensToEvaluate) {
                when (token.type) {
                    TokenType.MSECOND, TokenType.SECOND, TokenType.HOUR, TokenType.MINUTE, TokenType.DAY, TokenType.WEEK, TokenType.YEAR -> return false

                }
            }
            return true
        }

        private fun convertExpressionToMsecs(tokensToConvert: Tokens): Tokens {
            var convertedTokens = Tokens()

            for (token in tokensToConvert) {
                when (token.type) {
                    // main idea is to convert all time strings to "multiply on it's representation of one unit in Msecs"

                    TokenType.SECOND -> {
                        convertedTokens.add(Token(TokenType.MULTIPLY))
                        convertedTokens.add(
                            Token(
                                TokenType.NUMBER,
                                MILLISECONDS_IN_SECOND.toString()
                            )
                        )
                    }
                    TokenType.MINUTE -> {
                        convertedTokens.add(Token(TokenType.MULTIPLY))
                        convertedTokens.add(
                            Token(
                                TokenType.NUMBER,
                                MILLISECONDS_IN_MINUTE.toString()
                            )
                        )
                    }

                    TokenType.HOUR -> {
                        convertedTokens.add(Token(TokenType.MULTIPLY))
                        convertedTokens.add(
                            Token(
                                TokenType.NUMBER,
                                MILLISECONDS_IN_HOUR.toString()
                            )
                        )
                    }

                    TokenType.DAY -> {
                        convertedTokens.add(Token(TokenType.MULTIPLY))
                        convertedTokens.add(
                            Token(
                                TokenType.NUMBER,
                                MILLISECONDS_IN_DAY.toString()
                            )
                        )
                    }

                    TokenType.WEEK -> {
                        convertedTokens.add(Token(TokenType.MULTIPLY))
                        convertedTokens.add(
                            Token(
                                TokenType.NUMBER,
                                MILLISECONDS_IN_WEEK.toString()
                            )
                        )
                    }


                    TokenType.MONTH -> {
                        convertedTokens.add(Token(TokenType.MULTIPLY))
                        convertedTokens.add(
                            Token(
                                TokenType.NUMBER,
                                MILLISECONDS_IN_MONTH.toString()
                            )
                        )
                    }

                    TokenType.YEAR -> {
                        convertedTokens.add(Token(TokenType.MULTIPLY))
                        convertedTokens.add(
                            Token(
                                TokenType.NUMBER,
                                MILLISECONDS_IN_YEAR.toString()
                            )
                        )
                    }

                    TokenType.NUMBER -> {
                        convertedTokens.add(Token(TokenType.PLUS))
                        convertedTokens.add(
                            Token(
                                TokenType.NUMBER,
                                token.strRepresentation
                            )
                        )
                    }

                    TokenType.MULTIPLY, TokenType.DIVIDE, TokenType.MINUS, TokenType.PLUS, TokenType.PARENTHESES_RIGHT, TokenType.PARENTHESES_LEFT -> {
                        convertedTokens.add(
                            Token(
                                token.type
                            )
                        )
                    }

                }
            }
            return convertedTokens
        }


        // here we are converting result expression to specified type
        private fun convertExpressionInMsecsToType(token: Token, type: TokenType): Tokens {
            val convertedTokens = Tokens()
            when (type) {

                TokenType.SECOND -> {

                    convertedTokens.add(
                        Token(
                            TokenType.NUMBER,
                            (token.strRepresentation.toDouble() / MILLISECONDS_IN_SECOND).toString()
                        )
                    )
                }
                TokenType.MINUTE -> {
                    convertedTokens.add(
                        Token(
                            TokenType.NUMBER,
                            (token.strRepresentation.toDouble() / MILLISECONDS_IN_MINUTE).toString()
                        )
                    )
                }

                TokenType.HOUR -> {
                    convertedTokens.add(
                        Token(
                            TokenType.NUMBER,
                            (token.strRepresentation.toDouble() / MILLISECONDS_IN_HOUR).toString()
                        )
                    )
                }

                TokenType.DAY -> {
                    convertedTokens.add(
                        Token(
                            TokenType.NUMBER,
                            (token.strRepresentation.toDouble() / MILLISECONDS_IN_DAY).toString()
                        )
                    )
                }

                TokenType.WEEK -> {
                    convertedTokens.add(
                        Token(
                            TokenType.NUMBER,
                            (token.strRepresentation.toDouble() / MILLISECONDS_IN_WEEK).toString()
                        )
                    )
                }


                TokenType.MONTH -> {
                    convertedTokens.add(
                        Token(
                            TokenType.NUMBER,
                            (token.strRepresentation.toDouble() / MILLISECONDS_IN_MONTH).toString()
                        )
                    )
                }

                TokenType.YEAR -> {
                    convertedTokens.add(
                        Token(
                            TokenType.NUMBER,
                            (token.strRepresentation.toDouble() / MILLISECONDS_IN_YEAR).toString()
                        )
                    )
                }

            }
            convertedTokens.add(Token(type))
            return convertedTokens
        }

        // here we convert result expression to nearest time
        private fun convertExpressionInMsecsToNearest(token: Token): Tokens {
            val convertedTokens = Tokens()
            val valueOfToken = token.strRepresentation.toDouble()
            val years = valueOfToken.div(MILLISECONDS_IN_YEAR).toInt()
            val months = (valueOfToken - years * MILLISECONDS_IN_YEAR).div(MILLISECONDS_IN_MONTH).toInt()
            val weeks = (valueOfToken - (years * MILLISECONDS_IN_YEAR + months * MILLISECONDS_IN_MONTH)).div(
                MILLISECONDS_IN_WEEK
            ).toInt()
            val days =
                (valueOfToken - (years * MILLISECONDS_IN_YEAR + months * MILLISECONDS_IN_MONTH + weeks * MILLISECONDS_IN_WEEK)).div(
                    MILLISECONDS_IN_DAY
                ).toInt()
            val hours =
                (valueOfToken - (years * MILLISECONDS_IN_YEAR + months * MILLISECONDS_IN_MONTH + weeks * MILLISECONDS_IN_WEEK + days * MILLISECONDS_IN_DAY)).div(
                    MILLISECONDS_IN_HOUR
                ).toInt()

            val minutes =
                (valueOfToken - (years * MILLISECONDS_IN_YEAR + months * MILLISECONDS_IN_MONTH + weeks * MILLISECONDS_IN_WEEK + days * MILLISECONDS_IN_DAY + hours * MILLISECONDS_IN_HOUR)).div(
                    MILLISECONDS_IN_MINUTE
                ).toInt()

            val seconds =
                (valueOfToken - (years * MILLISECONDS_IN_YEAR + months * MILLISECONDS_IN_MONTH + weeks * MILLISECONDS_IN_WEEK + days * MILLISECONDS_IN_DAY + hours * MILLISECONDS_IN_HOUR + minutes * MILLISECONDS_IN_MINUTE)).div(
                    MILLISECONDS_IN_SECOND
                ).toInt()

            val mseconds =
                (valueOfToken - (years * MILLISECONDS_IN_YEAR + months * MILLISECONDS_IN_MONTH + weeks * MILLISECONDS_IN_WEEK + days * MILLISECONDS_IN_DAY + hours * MILLISECONDS_IN_HOUR + minutes * MILLISECONDS_IN_MINUTE + seconds * MILLISECONDS_IN_SECOND)).toInt()

            if (years != 0) {
                convertedTokens.add(
                    Token(
                        TokenType.NUMBER,
                        years.toString()
                    )
                )
                convertedTokens.add(Token(TokenType.YEAR))
            }


            if (months != 0) {
                convertedTokens.add(
                    Token(
                        TokenType.NUMBER,
                        months.toString()
                    )
                )
                convertedTokens.add(Token(TokenType.MONTH))
            }

            if (weeks != 0) {
                convertedTokens.add(
                    Token(
                        TokenType.NUMBER,
                        weeks.toString()
                    )
                )
                convertedTokens.add(Token(TokenType.WEEK))
            }
            if (days != 0) {
                convertedTokens.add(
                    Token(
                        TokenType.NUMBER,
                        days.toString()
                    )
                )
                convertedTokens.add(Token(TokenType.DAY))
            }
            if (hours != 0) {
                convertedTokens.add(
                    Token(
                        TokenType.NUMBER,
                        hours.toString()
                    )
                )
                convertedTokens.add(Token(TokenType.HOUR))
            }

            if (minutes != 0) {
                convertedTokens.add(
                    Token(
                        TokenType.NUMBER,
                        minutes.toString()
                    )
                )
                convertedTokens.add(Token(TokenType.MINUTE))
            }

            if (seconds != 0) {
                convertedTokens.add(
                    Token(
                        TokenType.NUMBER,
                        seconds.toString()
                    )
                )
                convertedTokens.add(Token(TokenType.SECOND))
            }

            if (mseconds != 0) {
                convertedTokens.add(
                    Token(
                        TokenType.NUMBER,
                        mseconds.toString()
                    )
                )
                convertedTokens.add(Token(TokenType.MSECOND))
            }
            return convertedTokens
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
