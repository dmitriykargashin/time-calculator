/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.timecalculator.utilites

import com.dmitriykargashin.timecalculator.data.calculator.*
import com.dmitriykargashin.timecalculator.data.tokens.Token
import com.dmitriykargashin.timecalculator.data.tokens.TokenType
import com.dmitriykargashin.timecalculator.data.tokens.Tokens
import java.math.BigDecimal
import java.math.RoundingMode
import kotlin.math.roundToInt
import kotlin.math.roundToLong

abstract class TimeConverter {

    companion object {
        // here we convert result expression to nearest time
        fun convertExpressionInMsecsToNearest(token: Token): Tokens {
            val convertedTokens = Tokens()
            val valueOfToken = token.strRepresentation.toDouble()
            val years = valueOfToken.div(MILLISECONDS_IN_YEAR).toInt()
            val months = (valueOfToken - years * MILLISECONDS_IN_YEAR).div(
                MILLISECONDS_IN_MONTH
            ).toInt()
            val weeks =
                (valueOfToken - (years * MILLISECONDS_IN_YEAR + months * MILLISECONDS_IN_MONTH)).div(
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


        fun convertExpressionToMsecs(tokensToConvert: Tokens): Tokens {
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
        fun convertExpressionInMsecsToType(token: Token, type: TokenType): Tokens {
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


        fun convertMsecsToMSecsInType(mSecToConvert: BigDecimal, type: TokenType): BigDecimal {
            var result = BigDecimal.ZERO
            when (type) {

                TokenType.SECOND -> {

                    result = mSecToConvert / MILLISECONDS_IN_SECOND.toBigDecimal()

                }
                TokenType.MINUTE -> {
                    result = mSecToConvert / MILLISECONDS_IN_MINUTE.toBigDecimal()
                }

                TokenType.HOUR -> {
                    result = mSecToConvert / MILLISECONDS_IN_HOUR.toBigDecimal()
                }

                TokenType.DAY -> {
                    result = mSecToConvert / MILLISECONDS_IN_DAY.toBigDecimal()
                }

                TokenType.WEEK -> {
                    result = mSecToConvert / MILLISECONDS_IN_WEEK.toBigDecimal()
                }


                TokenType.MONTH -> {
                    result = mSecToConvert / MILLISECONDS_IN_MONTH.toBigDecimal()
                }

                TokenType.YEAR -> {
                    result = mSecToConvert / MILLISECONDS_IN_YEAR.toBigDecimal()
                }

            }

            return result
        }


        fun convertTokensToMScecToken(tokens: Tokens): Token {

            var multipliedResult = 0.0
            var currentNumber = 0.0


            for (token in tokens) {
                when (token.type) {
                    // main idea is to convert all time strings to "multiply on it's representation of one unit in Msecs"

                    TokenType.NUMBER -> {
                        currentNumber = token.strRepresentation.toDouble()


                    }
                    TokenType.SECOND -> {

                        multipliedResult += (currentNumber * MILLISECONDS_IN_SECOND)


                    }
                    TokenType.MINUTE -> {
                        multipliedResult += (currentNumber * MILLISECONDS_IN_MINUTE)

                    }

                    TokenType.HOUR -> {

                        multipliedResult += (currentNumber * MILLISECONDS_IN_HOUR)

                    }

                    TokenType.DAY -> {
                        multipliedResult += (currentNumber * MILLISECONDS_IN_DAY)
                    }

                    TokenType.WEEK -> {
                        multipliedResult += (currentNumber * MILLISECONDS_IN_WEEK)

                    }


                    TokenType.MONTH -> {
                        multipliedResult += (currentNumber * MILLISECONDS_IN_MONTH)

                    }

                    TokenType.YEAR -> {
                        multipliedResult += (currentNumber * MILLISECONDS_IN_YEAR)

                    }


                }
            }
            /*        val fmt = NumberFormat.getInstance()
                    fmt.setGroupingUsed(false)
                    fmt.setMaximumIntegerDigits(999)
                    fmt.setMaximumFractionDigits(999)
                    val resultAsString = fmt.format(multipliedResult)*/

            return Token(
                TokenType.NUMBER, multipliedResult.toString()
            )

        }


        fun convertTokensToMScec(tokens: Tokens): BigDecimal {

            var multipliedResult = BigDecimal.ZERO
            var currentNumber = BigDecimal.ZERO


            for (token in tokens) {
                when (token.type) {
                    // main idea is to convert all time strings to "multiply on it's representation of one unit in Msecs"

                    TokenType.NUMBER -> {
                        currentNumber = token.strRepresentation.toBigDecimal()


                    }
                    TokenType.SECOND -> {

                        multipliedResult += (currentNumber * MILLISECONDS_IN_SECOND.toBigDecimal())


                    }
                    TokenType.MINUTE -> {
                        multipliedResult += (currentNumber * MILLISECONDS_IN_MINUTE.toBigDecimal())

                    }

                    TokenType.HOUR -> {

                        multipliedResult += (currentNumber * MILLISECONDS_IN_HOUR.toBigDecimal())

                    }

                    TokenType.DAY -> {
                        multipliedResult += (currentNumber * MILLISECONDS_IN_DAY.toBigDecimal())
                    }

                    TokenType.WEEK -> {
                        multipliedResult += (currentNumber * MILLISECONDS_IN_WEEK.toBigDecimal())

                    }


                    TokenType.MONTH -> {
                        multipliedResult += (currentNumber * MILLISECONDS_IN_MONTH.toBigDecimal())

                    }

                    TokenType.YEAR -> {
                        multipliedResult += (currentNumber * MILLISECONDS_IN_YEAR.toBigDecimal())

                    }


                }
            }
            /*        val fmt = NumberFormat.getInstance()
                    fmt.setGroupingUsed(false)
                    fmt.setMaximumIntegerDigits(999)
                    fmt.setMaximumFractionDigits(999)
                    val resultAsString = fmt.format(multipliedResult)*/

            return multipliedResult
        }


        fun convertPartOfUnitToMScec(partOfUnit: BigDecimal, type: TokenType): BigDecimal {

            var multipliedResult = BigDecimal.ZERO


            when (type) {


                TokenType.SECOND -> {

                    multipliedResult += (partOfUnit * MILLISECONDS_IN_SECOND.toBigDecimal())


                }
                TokenType.MINUTE -> {
                    multipliedResult += (partOfUnit * MILLISECONDS_IN_MINUTE.toBigDecimal())

                }

                TokenType.HOUR -> {

                    multipliedResult += (partOfUnit * MILLISECONDS_IN_HOUR.toBigDecimal())

                }

                TokenType.DAY -> {
                    multipliedResult += (partOfUnit * MILLISECONDS_IN_DAY.toBigDecimal())
                }

                TokenType.WEEK -> {
                    multipliedResult += (partOfUnit * MILLISECONDS_IN_WEEK.toBigDecimal())

                }


                TokenType.MONTH -> {
                    multipliedResult += (partOfUnit * MILLISECONDS_IN_MONTH.toBigDecimal())

                }

                TokenType.YEAR -> {
                    multipliedResult += (partOfUnit * MILLISECONDS_IN_YEAR.toBigDecimal())

                }


            }

            /*        val fmt = NumberFormat.getInstance()
                    fmt.setGroupingUsed(false)
                    fmt.setMaximumIntegerDigits(999)
                    fmt.setMaximumFractionDigits(999)
                    val resultAsString = fmt.format(multipliedResult)*/

            return multipliedResult
        }
        /*   fun convertTokensToTokensWithFormat(tokensToConvert: Tokens, tokensFormat: Tokens): Tokens {

               var endResult = Tokens()
               var currentResult: Tokens
               val tokensToConvertConvertedToMsec = convertTokensToMScecToken(tokensToConvert)


               for (tokenFormat in tokensFormat) {
                   when (tokenFormat.type) {

                       TokenType.YEAR -> {
                           currentResult = convertExpressionInMsecsToType(
                               tokensToConvertConvertedToMsec,
                               TokenType.HOUR
                           )

                           endResult.add(Token(TokenType.NUMBER, currentResult[0].strRepresentation))
                           endResult.add(Token(TokenType.HOUR))

                       }

                       TokenType.MONTH -> {
                           currentResult = convertExpressionInMsecsToType(
                               tokensToConvertConvertedToMsec,
                               TokenType.HOUR
                           )

                           endResult.add(Token(TokenType.NUMBER, currentResult[0].strRepresentation))
                           endResult.add(Token(TokenType.HOUR))

                       }


                       TokenType.WEEK -> {
                           currentResult = convertExpressionInMsecsToType(
                               tokensToConvertConvertedToMsec,
                               TokenType.HOUR
                           )

                           endResult.add(Token(TokenType.NUMBER, currentResult[0].strRepresentation))
                           endResult.add(Token(TokenType.HOUR))

                       }


                       TokenType.DAY -> {
                           currentResult = convertExpressionInMsecsToType(
                               tokensToConvertConvertedToMsec,
                               TokenType.HOUR
                           )

                           endResult.add(Token(TokenType.NUMBER, currentResult[0].strRepresentation))
                           endResult.add(Token(TokenType.HOUR))
                       }


                       TokenType.HOUR -> {

                           if (endResult.lastIndex > 0) {

                           }

                           currentResult = convertExpressionInMsecsToType(
                               tokensToConvertConvertedToMsec,
                               TokenType.HOUR
                           )

                           endResult.add(Token(TokenType.NUMBER, currentResult[0].strRepresentation))
                           endResult.add(Token(TokenType.HOUR))
                       }


                       TokenType.MINUTE -> {
                           if (endResult.lastIndex > 1) {
                               val fullNumber =
                                   endResult[endResult.lastIndex - 1].strRepresentation.toDouble()
                               val remainder = fullNumber - fullNumber.toLong()
                               if (remainder > 0) {
                                   endResult[endResult.lastIndex - 1].strRepresentation =
                                       (fullNumber - remainder).toString()



                                   val tempConv = convertTokensToMScecToken(tokensToConvert)
                               }


                           }

                           currentResult = convertExpressionInMsecsToType(
                               tokensToConvertConvertedToMsec,
                               TokenType.HOUR
                           )

                           endResult.add(Token(TokenType.NUMBER, currentResult[0].strRepresentation))
                           endResult.add(Token(TokenType.HOUR))

                       }

                       TokenType.SECOND -> {

                           currentResult = convertExpressionInMsecsToType(
                               tokensToConvertConvertedToMsec,
                               TokenType.HOUR
                           )

                           endResult.add(Token(TokenType.NUMBER, currentResult[0].strRepresentation))
                           endResult.add(Token(TokenType.HOUR))


                       }
                   }
               }
               *//*        val fmt = NumberFormat.getInstance()
                    fmt.setGroupingUsed(false)
                    fmt.setMaximumIntegerDigits(999)
                    fmt.setMaximumFractionDigits(999)
                    val resultAsString = fmt.format(multipliedResult)*//*

            return Token(
                TokenType.NUMBER, multipliedResult.toString()
            )

        }*/

        fun convertTokensToTokensWithFormat(tokensToConvert: Tokens, tokensFormat: Tokens): Tokens {

            var endResult = Tokens()

            var reminderInMsec = convertTokensToMScec(tokensToConvert)
            // var remainderInMsec=0.0


            for ((index, tokenFormat) in tokensFormat.withIndex()) {
                //  when (tokenFormat.type) {

                //  TokenType.HOUR -> {


                reminderInMsec = addTimeUnitToResultAndGetReminder(
                    reminderInMsec,
                    tokenFormat.type, (index == tokensFormat.lastIndex),
                    endResult
                )


                //    }
                // }
            }
            return endResult

        }

        private fun addTimeUnitToResultAndGetReminder(
            reminderInMsec: BigDecimal,
            type: TokenType,
            isLast: Boolean,
            endResult: Tokens
        ): BigDecimal {



            var reminderInMsecResult = BigDecimal.ZERO

            val currentResult = convertMsecsToMSecsInType(
                reminderInMsec.setScale(8, RoundingMode.HALF_EVEN), type
            )

            if (isLast) //if it`s last unit we should leave it decimal
            {
                endResult.add(
                    Token(
                        TokenType.NUMBER,
                        currentResult.setScale(4, RoundingMode.HALF_EVEN).stripTrailingZeros().toString()
                    )
                )
                endResult.add(Token(type))
            } else {

                val currentResultRounded = currentResult.setScale(0, RoundingMode.HALF_EVEN)
                val reminderFromFullNumber = (currentResult - currentResultRounded).setScale(8, RoundingMode.HALF_EVEN)

                endResult.add(
                    Token(
                        TokenType.NUMBER,
                        currentResultRounded.toString()
                    )
                )
                endResult.add(Token(type))


                if (reminderFromFullNumber > BigDecimal.ZERO) {

                    reminderInMsecResult =
                        convertPartOfUnitToMScec(reminderFromFullNumber, type)


                }
                else reminderInMsecResult= BigDecimal.ZERO



            }
            return reminderInMsecResult

        }


    }
}