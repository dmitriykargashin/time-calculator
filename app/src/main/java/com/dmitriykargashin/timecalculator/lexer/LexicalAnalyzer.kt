/*
 * Copyright (c) 2019. Dmitriy Kargashin
 *
 * Uses for Lexical analyze for string expression
 */

package com.dmitriykargashin.timecalculator.lexer

import com.dmitriykargashin.timecalculator.extension.removeAllSpaces

class LexicalAnalyzer(var stringExrpession: String) {

    // as result list of tokens
    val listOfTokens: MutableList<Token> = ArrayList()
    val currentPosition: Int = 0
    val stringExrpessionLength: Int = stringExrpession.length

    fun analyze(): MutableList<Token> {
        // removes spaces
        stringExrpession = stringExrpession.removeAllSpaces()

        startAnalyze()
        //stringExrpession.indexOf("Month")

        return listOfTokens
    }

    private fun startAnalyze() {

        TODO("not implemented") //To change body of created functions use File | Settings | File Templates.
    }

    //Finding out that current symbol is digit
    fun isDigit(x: Char): Boolean = x.isDigit()

    //Finding out that current symbol is letter
    fun isLetter(x: Char): Boolean = x.isLetter()

    //Finding out that current symbol is operator
    fun isOperator(x: Char): Boolean = x.equals(TokenType.PLUS.value) or x.equals(TokenType.MINUS.value) or
            x.equals(TokenType.MULTIPLY.value) or x.equals(TokenType.DIVIDE.value)

    //Finding out that current symbol is dot
    fun isDot(x: Char): Boolean = x.equals('.')

    // finding full token body from current position
    fun findCurrentFullToken(): Token? {

        //   var currentTokenType:TokenType = findCurrentTokenType()
        //   when
        var findedToken: Token? = null

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
        {

        }

        return findedToken
    }

    private fun findCurrentOperatorToken(): Token? {
        TODO("not implemented") //To change body of created functions use File | Settings | File Templates.
    }

    private fun findCurrentLetterToken(): Token? {
        TODO("not implemented") //To change body of created functions use File | Settings | File Templates.
    }

    private fun findCurrentDigitalToken(): Token? {
        TODO("not implemented") //To change body of created functions use File | Settings | File Templates.
    }



}