/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.cardamontimecalculator.ui.calculator

import android.content.Context
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import com.dmitriykargashin.cardamontimecalculator.data.repository.ExpressionRepository
import com.dmitriykargashin.cardamontimecalculator.data.repository.PerUnitsRepository
import com.dmitriykargashin.cardamontimecalculator.data.repository.ResultFormatsRepository
import com.dmitriykargashin.cardamontimecalculator.data.repository.TokensRepository

class CalculatorViewModelFactory(
    private val expressionRepository: ExpressionRepository,
    private val tokensRepository: TokensRepository,
    private val resultFormatsRepository: ResultFormatsRepository,
    private val perUnitsRepository: PerUnitsRepository,
    private val context: Context
) :
    ViewModelProvider.NewInstanceFactory() {

    @Suppress("UNCHECKED_CAST")
    override fun <T : ViewModel?> create(modelClass: Class<T>): T {
        return CalculatorViewModel(expressionRepository, tokensRepository,resultFormatsRepository,perUnitsRepository,context ) as T
    }
}