/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.cardamontimecalculator.utilites

import android.util.Log
import com.dmitriykargashin.cardamontimecalculator.engine.calculator.*
import com.dmitriykargashin.cardamontimecalculator.data.tokens.Token
import com.dmitriykargashin.cardamontimecalculator.data.tokens.TokenType
import com.dmitriykargashin.cardamontimecalculator.data.tokens.Tokens
import java.math.BigDecimal
import java.math.BigDecimal.ZERO
import java.math.RoundingMode

abstract class TimeConverter {

    companion object {
        // here we convert result expression to nearest time
        fun convertExpressionInMsecsToNearest(token: Token): Tokens {
            val convertedTokens = Tokens()
            val valueOfToken = token.strRepresentation.toBigDecimal()
            val years = valueOfToken.div(MILLISECONDS_IN_YEAR).setScale(0, RoundingMode.DOWN)
            val months = (valueOfToken - years * MILLISECONDS_IN_YEAR).div(
                MILLISECONDS_IN_MONTH
            ).setScale(0, RoundingMode.DOWN)
            val weeks =
                (valueOfToken - (years * MILLISECONDS_IN_YEAR + months * MILLISECONDS_IN_MONTH)).div(
                    MILLISECONDS_IN_WEEK
                ).setScale(0, RoundingMode.DOWN)
            val days =
                (valueOfToken - (years * MILLISECONDS_IN_YEAR + months * MILLISECONDS_IN_MONTH + weeks * MILLISECONDS_IN_WEEK)).div(
                    MILLISECONDS_IN_DAY
                ).setScale(0, RoundingMode.DOWN)
            val hours =
                (valueOfToken - (years * MILLISECONDS_IN_YEAR + months * MILLISECONDS_IN_MONTH + weeks * MILLISECONDS_IN_WEEK + days * MILLISECONDS_IN_DAY)).div(
                    MILLISECONDS_IN_HOUR
                ).setScale(0, RoundingMode.DOWN)

            val minutes =
                (valueOfToken - (years * MILLISECONDS_IN_YEAR + months * MILLISECONDS_IN_MONTH + weeks * MILLISECONDS_IN_WEEK + days * MILLISECONDS_IN_DAY + hours * MILLISECONDS_IN_HOUR)).div(
                    MILLISECONDS_IN_MINUTE
                ).setScale(0, RoundingMode.DOWN)

            val seconds =
                (valueOfToken - (years * MILLISECONDS_IN_YEAR + months * MILLISECONDS_IN_MONTH + weeks * MILLISECONDS_IN_WEEK + days * MILLISECONDS_IN_DAY + hours * MILLISECONDS_IN_HOUR + minutes * MILLISECONDS_IN_MINUTE)).div(
                    MILLISECONDS_IN_SECOND
                ).setScale(0, RoundingMode.DOWN)

            val mseconds =
                (valueOfToken - (years * MILLISECONDS_IN_YEAR + months * MILLISECONDS_IN_MONTH + weeks * MILLISECONDS_IN_WEEK + days * MILLISECONDS_IN_DAY + hours * MILLISECONDS_IN_HOUR + minutes * MILLISECONDS_IN_MINUTE + seconds * MILLISECONDS_IN_SECOND)).setScale(
                    0,
                    RoundingMode.DOWN
                )

            if (years.compareTo(ZERO) != 0) {
                convertedTokens.add(
                    Token(
                        TokenType.NUMBER,
                        years.toPlainString()
                    )
                )
                convertedTokens.add(Token(TokenType.YEAR))
            }


            if (months.compareTo(ZERO) != 0) {
                convertedTokens.add(
                    Token(
                        TokenType.NUMBER,
                        months.toPlainString()
                    )
                )
                convertedTokens.add(Token(TokenType.MONTH))
            }

            if (weeks.compareTo(ZERO) != 0) {
                convertedTokens.add(
                    Token(
                        TokenType.NUMBER,
                        weeks.toPlainString()
                    )
                )
                convertedTokens.add(Token(TokenType.WEEK))
            }
            if (days.compareTo(ZERO) != 0) {
                convertedTokens.add(
                    Token(
                        TokenType.NUMBER,
                        days.toPlainString()
                    )
                )
                convertedTokens.add(Token(TokenType.DAY))
            }
            if (hours.compareTo(ZERO) != 0) {
                convertedTokens.add(
                    Token(
                        TokenType.NUMBER,
                        hours.toPlainString()
                    )
                )
                convertedTokens.add(Token(TokenType.HOUR))
            }

            if (minutes.compareTo(ZERO) != 0) {
                convertedTokens.add(
                    Token(
                        TokenType.NUMBER,
                        minutes.toPlainString()
                    )
                )
                convertedTokens.add(Token(TokenType.MINUTE))
            }

            if (seconds.compareTo(ZERO) != 0) {
                convertedTokens.add(
                    Token(
                        TokenType.NUMBER,
                        seconds.toPlainString()
                    )
                )
                convertedTokens.add(Token(TokenType.SECOND))
            }

            if (mseconds.compareTo(ZERO) != 0) {
                convertedTokens.add(
                    Token(
                        TokenType.NUMBER,
                        mseconds.toPlainString()
                    )
                )
                convertedTokens.add(Token(TokenType.MSECOND))
            }
            return convertedTokens
        }


        fun convertExpressionToMsecs(tokensToConvert: Tokens): Tokens {
            val convertedTokens = Tokens()

            for (token in tokensToConvert) {
                when (token.type) {
                    // main idea is to convert all time strings to "multiply on it's representation of one unit in Msecs"

                    TokenType.SECOND -> {
                        convertedTokens.add(Token(TokenType.MULTIPLY))
                        convertedTokens.add(
                            Token(
                                TokenType.NUMBER,
                                MILLISECONDS_IN_SECOND.toPlainString()
                            )
                        )
                    }
                    TokenType.MINUTE -> {
                        convertedTokens.add(Token(TokenType.MULTIPLY))
                        convertedTokens.add(
                            Token(
                                TokenType.NUMBER,
                                MILLISECONDS_IN_MINUTE.toPlainString()
                            )
                        )
                    }

                    TokenType.HOUR -> {
                        convertedTokens.add(Token(TokenType.MULTIPLY))
                        convertedTokens.add(
                            Token(
                                TokenType.NUMBER,
                                MILLISECONDS_IN_HOUR.toPlainString()
                            )
                        )
                    }

                    TokenType.DAY -> {
                        convertedTokens.add(Token(TokenType.MULTIPLY))
                        convertedTokens.add(
                            Token(
                                TokenType.NUMBER,
                                MILLISECONDS_IN_DAY.toPlainString()
                            )
                        )
                    }

                    TokenType.WEEK -> {
                        convertedTokens.add(Token(TokenType.MULTIPLY))
                        convertedTokens.add(
                            Token(
                                TokenType.NUMBER,
                                MILLISECONDS_IN_WEEK.toPlainString()
                            )
                        )
                    }


                    TokenType.MONTH -> {
                        convertedTokens.add(Token(TokenType.MULTIPLY))
                        convertedTokens.add(
                            Token(
                                TokenType.NUMBER,
                                MILLISECONDS_IN_MONTH.toPlainString()
                            )
                        )
                    }

                    TokenType.YEAR -> {
                        convertedTokens.add(Token(TokenType.MULTIPLY))
                        convertedTokens.add(
                            Token(
                                TokenType.NUMBER,
                                MILLISECONDS_IN_YEAR.toPlainString()
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

                    TokenType.MULTIPLY, TokenType.DIVIDE, TokenType.MINUS, TokenType.PLUS, TokenType.PARENTHESESRIGHT, TokenType.PARENTHESESLEFT -> {
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

                TokenType.MSECOND -> {

                    convertedTokens.add(
                        Token(
                            TokenType.NUMBER,
                            (token.strRepresentation.toBigDecimal()).toPlainString()
                        )
                    )
                }

                TokenType.SECOND -> {

                    convertedTokens.add(
                        Token(
                            TokenType.NUMBER,
                            (token.strRepresentation.toBigDecimal() / MILLISECONDS_IN_SECOND).toPlainString()
                        )
                    )
                }
                TokenType.MINUTE -> {
                    convertedTokens.add(
                        Token(
                            TokenType.NUMBER,
                            (token.strRepresentation.toBigDecimal() / MILLISECONDS_IN_MINUTE).toPlainString()
                        )
                    )
                }

                TokenType.HOUR -> {
                    convertedTokens.add(
                        Token(
                            TokenType.NUMBER,
                            (token.strRepresentation.toBigDecimal() / MILLISECONDS_IN_HOUR).toPlainString()
                        )
                    )
                }

                TokenType.DAY -> {
                    convertedTokens.add(
                        Token(
                            TokenType.NUMBER,
                            (token.strRepresentation.toBigDecimal() / MILLISECONDS_IN_DAY).toPlainString()
                        )
                    )
                }

                TokenType.WEEK -> {
                    convertedTokens.add(
                        Token(
                            TokenType.NUMBER,
                            (token.strRepresentation.toBigDecimal() / MILLISECONDS_IN_WEEK).toPlainString()
                        )
                    )
                }


                TokenType.MONTH -> {
                    convertedTokens.add(
                        Token(
                            TokenType.NUMBER,
                            (token.strRepresentation.toBigDecimal() / MILLISECONDS_IN_MONTH).toPlainString()
                        )
                    )
                }

                TokenType.YEAR -> {
                    convertedTokens.add(
                        Token(
                            TokenType.NUMBER,
                            (token.strRepresentation.toBigDecimal() / MILLISECONDS_IN_YEAR).toPlainString()
                        )
                    )
                }

            }
            convertedTokens.add(Token(type))
            return convertedTokens
        }


        private fun convertMsecsToMSecsInType(mSecToConvert: BigDecimal, type: TokenType): BigDecimal {
            var result = ZERO
            when (type) {

                TokenType.MSECOND -> {

                    result = mSecToConvert

                }
                TokenType.SECOND -> {

                    result = mSecToConvert / MILLISECONDS_IN_SECOND

                }
                TokenType.MINUTE -> {
                    result = mSecToConvert / MILLISECONDS_IN_MINUTE
                }

                TokenType.HOUR -> {
                    result = mSecToConvert / MILLISECONDS_IN_HOUR
                }

                TokenType.DAY -> {
                    result = mSecToConvert / MILLISECONDS_IN_DAY
                }

                TokenType.WEEK -> {
                    result = mSecToConvert / MILLISECONDS_IN_WEEK
                }


                TokenType.MONTH -> {
                    result = mSecToConvert / MILLISECONDS_IN_MONTH
                }

                TokenType.YEAR -> {
                    result = mSecToConvert / MILLISECONDS_IN_YEAR
                }

            }

            return result
        }


        fun convertTokensToMScecToken(tokens: Tokens): Token {

            var multipliedResult = ZERO
            var currentNumber = ZERO


            for (token in tokens) {
                when (token.type) {
                    // main idea is to convert all time strings to "multiply on it's representation of one unit in Msecs"

                    TokenType.NUMBER -> {
                        currentNumber = token.strRepresentation.toBigDecimal()


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
                TokenType.NUMBER, multipliedResult.toPlainString()
            )

        }


        private fun convertTokensToMScec(tokens: Tokens): BigDecimal {

            var multipliedResult = ZERO
            var currentNumber = ZERO
            Log.d("TOKENS", tokens.toString())

            for (token in tokens) {
                when (token.type) {
                    // main idea is to convert all time strings to "multiply on it's representation of one unit in Msecs"

                    TokenType.NUMBER -> {
                        currentNumber = token.strRepresentation.toBigDecimal()
                        Log.d("currentNumber", "*" + currentNumber.toPlainString())

                        Log.d("currentNumberString", "*" + token.strRepresentation)

                    }
                    TokenType.MSECOND -> {

                        multipliedResult += currentNumber

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

            return multipliedResult
        }


        private fun convertPartOfUnitToMScec(partOfUnit: BigDecimal, type: TokenType): BigDecimal {

            var multipliedResult = ZERO


            when (type) {


                TokenType.SECOND -> {

                    multipliedResult += (partOfUnit * MILLISECONDS_IN_SECOND)


                }
                TokenType.MINUTE -> {
                    multipliedResult += (partOfUnit * MILLISECONDS_IN_MINUTE)

                }

                TokenType.HOUR -> {

                    multipliedResult += (partOfUnit * MILLISECONDS_IN_HOUR)

                }

                TokenType.DAY -> {
                    multipliedResult += (partOfUnit * MILLISECONDS_IN_DAY)
                }

                TokenType.WEEK -> {
                    multipliedResult += (partOfUnit * MILLISECONDS_IN_WEEK)

                }


                TokenType.MONTH -> {
                    multipliedResult += (partOfUnit * MILLISECONDS_IN_MONTH)

                }

                TokenType.YEAR -> {
                    multipliedResult += (partOfUnit * MILLISECONDS_IN_YEAR)

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

        fun convertTokensToTokensWithFormat(
            tokensToConvert: Tokens,
            tokensFormat: Tokens,
            removeZeroUnits: Boolean = true
        ): Tokens {

            val endResult = Tokens()

            var reminderInMsec = convertTokensToMScec(tokensToConvert)

            Log.d("before convert", reminderInMsec.toPlainString())
            // var remainderInMsec=0.0


            for ((index, tokenFormat) in tokensFormat.withIndex()) {
                //  when (tokenFormat.type) {

                //  TokenType.HOUR -> {

                Log.d("reminder", reminderInMsec.toPlainString())

                reminderInMsec = addTimeUnitToResultAndGetReminder(
                    reminderInMsec,
                    tokenFormat.type, (index == tokensFormat.lastIndex),
                    endResult,
                    removeZeroUnits
                )
                Log.d("reminder after", reminderInMsec.toPlainString())

                //    }
                // }
            }
            return endResult

        }

        private fun addTimeUnitToResultAndGetReminder(
            reminderInMsec: BigDecimal,
            type: TokenType,
            isLast: Boolean,
            endResult: Tokens,
            removeZeroUnits: Boolean
        ): BigDecimal {


            var reminderInMsecResult = ZERO

            val currentResult = convertMsecsToMSecsInType(
                reminderInMsec.setScale(26, RoundingMode.HALF_UP), type
            )

            Log.d("currentResult:", currentResult.toPlainString() + " isLast=$isLast")
            if (isLast) //if it`s last unit we should leave it decimal
            {
                //   Log.d("ADD currentResultZERO:", ZERO.toPlainString() + " isLast=$isLast")
                if (!(currentResult.compareTo(ZERO) == 0 && removeZeroUnits)) {
                    Log.d("ADD LAST currentResult:", currentResult.toPlainString() )

                    endResult.add(
                        Token(
                            TokenType.NUMBER,
                            currentResult.setScale(
                                7,
                                RoundingMode.HALF_UP
                            ).stripTrailingZeros().toPlainString()
                        )
                    )
                    endResult.add(Token(type))
                }
            } else {

                val currentResultRounded = currentResult.setScale(0, RoundingMode.DOWN)

                val reminderFromFullNumber =
                    (currentResult - currentResultRounded).setScale(26, RoundingMode.HALF_UP)

                if (!(currentResultRounded.compareTo(ZERO) == 0 && removeZeroUnits)) {

                    Log.d(
                        "ADD currentResNOTLAST:",
                        currentResult.toPlainString()
                    )

                    endResult.add(
                        Token(
                            TokenType.NUMBER,
                            currentResultRounded.toPlainString()
                        )
                    )
                    endResult.add(Token(type))
                }

                reminderInMsecResult = if (reminderFromFullNumber.compareTo(ZERO) != 0) {

                    convertPartOfUnitToMScec(reminderFromFullNumber, type)


                } else ZERO


            }
            return reminderInMsecResult.setScale(7, RoundingMode.HALF_UP).stripTrailingZeros()

        }


    }
}