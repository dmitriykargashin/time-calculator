/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.timecalculator.ui.calculator

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import com.dmitriykargashin.timecalculator.data.repository.ExpressionRepository
import com.dmitriykargashin.timecalculator.data.repository.ResultFormatsRepository
import com.dmitriykargashin.timecalculator.data.repository.TokensRepository

class CalculatorViewModelFactory(
    private val expressionRepository: ExpressionRepository,
    private val tokensRepository: TokensRepository,
    private val resultFormatsRepository: ResultFormatsRepository
) :
    ViewModelProvider.NewInstanceFactory() {

    @Suppress("UNCHECKED_CAST")
    override fun <T : ViewModel?> create(modelClass: Class<T>): T {
        return CalculatorViewModel(expressionRepository, tokensRepository,resultFormatsRepository) as T
    }
}