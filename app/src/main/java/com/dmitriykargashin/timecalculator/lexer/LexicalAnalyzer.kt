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
    val listOfTokens: Tokens = Tokens() //MutableList<Token> = ArrayList()
    var currentPosition: Int = 0
    val stringExrpessionLength: Int = stringExrpession.length


    fun analyze(): Tokens {
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
        // In Kotlin we dont need BUILDER Pattern!
        var findedToken = Token(type = TokenType.ERROR, position = currentPosition)

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
                return Token(type = TokenType.PLUS, position = currentPosition)
            }
            stringExrpession[currentPosition] == TokenType.MINUS.value[0] -> {
                return Token(type = TokenType.MINUS, position = currentPosition)
            }
            stringExrpession[currentPosition] == TokenType.DIVIDE.value[0] -> {
                return Token(type = TokenType.DIVIDE, position = currentPosition)
            }
            stringExrpession[currentPosition] == TokenType.MULTIPLY.value[0] -> {
                return Token(type =  TokenType.MULTIPLY, position =  currentPosition)
            }
            else -> return Token(type = TokenType.ERROR, position = currentPosition)
        }

    }

    private fun findCurrentLetterToken(): Token {
        when {
            stringExrpession.startsWith( TokenType.YEAR.value, currentPosition) -> {
                return Token(type = TokenType.YEAR, position = currentPosition)
            }

            stringExrpession.startsWith(TokenType.MONTH.value, currentPosition) -> {
                return Token(type = TokenType.MONTH, position = currentPosition)
            }

            stringExrpession.startsWith( TokenType.WEEK.value, currentPosition) -> {
                return Token(type = TokenType.WEEK, position = currentPosition)
            }

            stringExrpession.startsWith( TokenType.DAY.value, currentPosition) -> {
                return Token(type = TokenType.DAY, position = currentPosition)
            }

            stringExrpession.startsWith( TokenType.HOUR.value, currentPosition) -> {
                return Token(type = TokenType.HOUR, position = currentPosition)
            }

            stringExrpession.startsWith(TokenType.MINUTE.value, currentPosition) -> {
                return Token(type = TokenType.MINUTE, position = currentPosition)
            }

            stringExrpession.startsWith( TokenType.SECOND.value, currentPosition) -> {
                return Token(type = TokenType.SECOND, position = currentPosition)
            }

            stringExrpession.startsWith( TokenType.MSECOND.value, currentPosition) -> {
                return Token(type = TokenType.MSECOND, position = currentPosition)
            }

            else -> return Token(type = TokenType.ERROR, position = currentPosition)
        }
    }

    private fun findCurrentDigitalToken(): Token {


        val p = Pattern.compile("-?[\\d\\.]+")
        val m = p.matcher(stringExrpession)

        m.find(currentPosition)

        return Token(type = TokenType.NUMBER, strRepresentation = m.group(), position = currentPosition)

    }


}