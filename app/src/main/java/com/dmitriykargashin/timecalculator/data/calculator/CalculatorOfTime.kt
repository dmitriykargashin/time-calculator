/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.timecalculator.data.calculator

import android.util.Log
import com.dmitriykargashin.timecalculator.data.tokens.Token
import com.dmitriykargashin.timecalculator.data.tokens.TokenType
import com.dmitriykargashin.timecalculator.data.tokens.Tokens
import net.objecthunter.exp4j.ExpressionBuilder
import java.text.DecimalFormat
import java.text.NumberFormat


abstract class CalculatorOfTime {


    companion object {


        fun evaluate(tokensToEvaluate: Tokens): Tokens {


            //

            if (tokensToEvaluate.isSimpleArithmeticExpression())
                return evaluateSimpleArithmeticExpression(tokensToEvaluate)
            else {
                val tokensWithParentheses = setParenthesesToExpression(tokensToEvaluate)
                val tokensinMsecs = convertExpressionToMsecs(tokensWithParentheses)
                val evaluatedToken = evaluateSimpleArithmeticExpression(tokensinMsecs)

                //  return convertExpressionInMsecsToType(evaluatedToken[0], TokenType.HOUR)
                return convertExpressionInMsecsToNearest(evaluatedToken[0])
            }


        }


        private fun evaluateSimpleArithmeticExpression(tokensToEvaluate: Tokens): Tokens {


            val txt = tokensToEvaluate.toString()
//            Log.i("evaluate", txt)

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

