/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.cardamontimecalculator.data.resultFormat

import com.dmitriykargashin.cardamontimecalculator.data.tokens.Tokens

class ResultFormat(val formatTokens: Tokens, var convertedResultTokens: Tokens) {
    var isSelected: Boolean = false
    var textPresentationOfTokens: String = ""

    init {
        textPresentationOfTokens = formatTokens.toStringWithSpaces()
    }

    constructor (
        formatTokens: Tokens,
        convertedResultTokens: Tokens,
        exactlyTextPresentationOfTokens: String
    ) : this(formatTokens, convertedResultTokens) {
        textPresentationOfTokens = exactlyTextPresentationOfTokens
    }


}