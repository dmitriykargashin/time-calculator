/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.timecalculator.ui.calculator

import android.arch.lifecycle.ViewModel
import com.dmitriykargashin.timecalculator.data.tokens.Token
import com.dmitriykargashin.timecalculator.data.tokens.TokensRepository

class CalculatorViewModel (private val tokensRepository: TokensRepository): ViewModel() {
    fun getQuotes() = tokensRepository.getTokens()

    fun addQuote(token: Token) = tokensRepository.addToken(token)
}