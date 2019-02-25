/*
 * Copyright (c) 2019. Dmitriy Kargashin
 *
 * Uses for Lexical analyze for string expression
 */

package com.dmitriykargashin.timecalculator.lexer

import com.dmitriykargashin.timecalculator.extension.removeAllSpaces

import java.util.regex.Pattern


class LexicalAnalyzer(var stringExrpession: String) {

    // as result list of tokens
    val listOfTokens: MutableList<Token> = ArrayList()
    var currentPosition: Int = 0
    val stringExrpessionLength: Int = stringExrpession.length

    fun analyze(): MutableList<Token> {
        // removes spaces
        stringExrpession = stringExrpession.removeAllSpaces()

        startAnalyze()
        //stringExrpession.indexOf("Month")

        return listOfTokens
    }

    private fun startAnalyze() {
        var tmpToken: Token

        while (currentPosition < stringExrpessionLength) {
            tmpToken = findCurrentFullToken()
            listOfTokens.add(tmpToken)
            currentPosition += tmpToken.length()
        }
    }

    //Finding out that current symbol is digit
    fun isDigit(x: Char): Boolean = x.isDigit()

    //Finding out that current symbol is letter
    fun isLetter(x: Char): Boolean = x.isLetter()

    //Finding out that current symbol is operator
    fun isOperator(x: Char): Boolean = x.equals(TokenType.PLUS.value[0]) or x.equals(TokenType.MINUS.value[0]) or
            x.equals(TokenType.MULTIPLY.value[0]) or x.equals(TokenType.DIVIDE.value[0])

    //Finding out that current symbol is dot
    fun isDot(x: Char): Boolean = x.equals('.')


    // finding full token body from current position
    fun findCurrentFullToken(): Token {
        var findedToken = Token(TokenType.ERROR, currentPosition)

        if (currentPosition <= stringExrpessionLength) {

            when {
                isDigit((stringExrpession[currentPosition])) -> {
                    findedToken = findCurrentDigitalToken()
                }

                isLetter((stringExrpession[currentPosition])) -> {
                    findedToken = findCurrentLetterToken()
                }

                isOperator((stringExrpession[currentPosition])) -> {
                    findedToken = findCurrentOperatorToken()
                }

                isDot((stringExrpession[currentPosition])) -> {
                    findedToken = findCurrentDigitalToken()
                }

            }

        }
        return findedToken

    }

    private fun findCurrentOperatorToken(): Token {
        when {
            stringExrpession[currentPosition] == TokenType.PLUS.value[0] -> {
                return Token(TokenType.PLUS, currentPosition)
            }
            stringExrpession[currentPosition] == TokenType.MINUS.value[0] -> {
                return Token(TokenType.MINUS, currentPosition)
            }
            stringExrpession[currentPosition] == TokenType.DIVIDE.value[0] -> {
                return Token(TokenType.DIVIDE, currentPosition)
            }
            stringExrpession[currentPosition] == TokenType.MULTIPLY.value[0] -> {
                return Token(TokenType.MULTIPLY, currentPosition)
            }
            else -> return Token(TokenType.ERROR, currentPosition)
        }

    }

    private fun findCurrentLetterToken(): Token {
        when {
            stringExrpession.startsWith(TokenType.YEAR.value, currentPosition) -> {
                return Token(TokenType.YEAR, currentPosition)
            }

            stringExrpession.startsWith(TokenType.MONTH.value, currentPosition) -> {
                return Token(TokenType.MONTH, currentPosition)
            }

            stringExrpession.startsWith(TokenType.WEEK.value, currentPosition) -> {
                return Token(TokenType.WEEK, currentPosition)
            }

            stringExrpession.startsWith(TokenType.DAY.value, currentPosition) -> {
                return Token(TokenType.DAY, currentPosition)
            }

            stringExrpession.startsWith(TokenType.HOUR.value, currentPosition) -> {
                return Token(TokenType.HOUR, currentPosition)
            }

            stringExrpession.startsWith(TokenType.MINUTE.value, currentPosition) -> {
                return Token(TokenType.MINUTE, currentPosition)
            }

            stringExrpession.startsWith(TokenType.SECOND.value, currentPosition) -> {
                return Token(TokenType.SECOND, currentPosition)
            }

            stringExrpession.startsWith(TokenType.MSECOND.value, currentPosition) -> {
                return Token(TokenType.MSECOND, currentPosition)
            }

            else -> return Token(TokenType.ERROR, currentPosition)
        }
    }

    private fun findCurrentDigitalToken(): Token {


        val p = Pattern.compile("-?[\\d\\.]+")
        val m = p.matcher(stringExrpession)

        m.find(currentPosition)

        return Token(TokenType.NUMBER, m.group(), currentPosition)

    }


}