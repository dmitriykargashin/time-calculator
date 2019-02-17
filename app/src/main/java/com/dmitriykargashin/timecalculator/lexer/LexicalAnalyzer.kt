/*
 * Copyright (c) 2019. Dmitriy Kargashin
 *
 * Uses for Lexical analyze for string expression
 */

package com.dmitriykargashin.timecalculator.lexer

class LexicalAnalyzer(var stringExrpession: String) {

    // as result list of tokens
    val listOfTokens: MutableList<Token> = ArrayList()
    val currentPosition: Int = 0

    fun analyze(): MutableList<Token> {
        // removes spaces
        stringExrpession = stringExrpession.replace(" ", "")
stringExrpession.indexOf("Month")


        return listOfTokens
    }


}