/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.timecalculator.ui.calculator

import android.arch.lifecycle.ViewModel
import android.arch.lifecycle.ViewModelProvider
import com.dmitriykargashin.timecalculator.data.expression.ExpressionRepository
import com.dmitriykargashin.timecalculator.data.tokens.TokensRepository

class CalculatorViewModelFactory( val expressionRepository: ExpressionRepository,  val tokensRepository: TokensRepository) :
    ViewModelProvider.NewInstanceFactory() {

    @Suppress("UNCHECKED_CAST")
    override fun <T : ViewModel?> create(modelClass: Class<T>): T {
        return CalculatorViewModel(expressionRepository, tokensRepository) as T
    }
}