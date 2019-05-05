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
    val listOfTokens = Tokens() //MutableList<Token> = ArrayList()
    var currentPosition = 0
    var stringExrpessionLength = 0


    fun analyze(): Tokens {
        // removes spaces
        stringExrpession = stringExrpession.removeAllSpaces()
        stringExrpessionLength = stringExrpession.length
        startAnalyze()
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
    fun isOperator(x: Char): Boolean = (x == TokenType.PLUS.value[0]) or (x == TokenType.MINUS.value[0]) or
            (x == TokenType.MULTIPLY.value[0]) or (x == TokenType.DIVIDE.value[0]) or (x == '-') or (x == '/') or (x == '*') or (x == '+')

    //Finding out that current symbol is dot
    fun isDot(x: Char): Boolean = x == '.'


    // finding full token body from current position
    fun findCurrentFullToken(): Token {
        // In Kotlin we dont need BUILDER Pattern!
        var findedToken = Token(type = TokenType.ERROR)

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
            (stringExrpession[currentPosition] == TokenType.PLUS.value[0]) or (stringExrpession[currentPosition] == '+') -> {
                return Token(type = TokenType.PLUS)
            }
            (stringExrpession[currentPosition] == TokenType.MINUS.value[0]) or (stringExrpession[currentPosition] == '-') -> {
                return Token(type = TokenType.MINUS)
            }
            (stringExrpession[currentPosition] == TokenType.DIVIDE.value[0]) or (stringExrpession[currentPosition] == '/') -> {
                return Token(type = TokenType.DIVIDE)
            }
            (stringExrpession[currentPosition] == TokenType.MULTIPLY.value[0]) or (stringExrpession[currentPosition] == '*') -> {
                return Token(type = TokenType.MULTIPLY)
            }
            else -> return Token(type = TokenType.ERROR)
        }

    }

    private fun findCurrentLetterToken(): Token {
        when {
            stringExrpession.startsWith(TokenType.YEAR.value, currentPosition) -> {
                return Token(type = TokenType.YEAR)
            }

            stringExrpession.startsWith(TokenType.MONTH.value, currentPosition) -> {
                return Token(type = TokenType.MONTH)
            }

            stringExrpession.startsWith(TokenType.WEEK.value, currentPosition) -> {
                return Token(type = TokenType.WEEK)
            }

            stringExrpession.startsWith(TokenType.DAY.value, currentPosition) -> {
                return Token(type = TokenType.DAY)
            }

            stringExrpession.startsWith(TokenType.HOUR.value, currentPosition) -> {
                return Token(type = TokenType.HOUR)
            }

            stringExrpession.startsWith(TokenType.MINUTE.value, currentPosition) -> {
                return Token(type = TokenType.MINUTE)
            }

            stringExrpession.startsWith(TokenType.SECOND.value, currentPosition) -> {
                return Token(type = TokenType.SECOND)
            }

            stringExrpession.startsWith(TokenType.MSECOND.value, currentPosition) -> {
                return Token(type = TokenType.MSECOND)
            }

            else -> return Token(type = TokenType.ERROR)
        }
    }

    private fun findCurrentDigitalToken(): Token {


        val p = Pattern.compile("-?[\\d\\.]+")
        val m = p.matcher(stringExrpession)

        m.find(currentPosition)

        return Token(type = TokenType.NUMBER, strRepresentation = m.group())

    }


}