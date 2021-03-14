/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.cardamontimecalculator.ui.calculator

import android.content.Context
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import com.dmitriykargashin.cardamontimecalculator.data.repository.*

class CalculatorViewModelFactory(
    private val expressionRepository: ExpressionRepository,
    private val tokensRepository: TokensRepository,
    private val resultFormatsRepository: ResultFormatsRepository,
    private val perUnitsRepository: PerUnitsRepository,
    private val prefRepository: PrefRepository,
    private val utilityRepository: UtilityRepository,
    private val context: Context
) :
    ViewModelProvider.NewInstanceFactory() {

    @Suppress("UNCHECKED_CAST")
    override fun <T : ViewModel?> create(modelClass: Class<T>): T {
        return CalculatorViewModel(expressionRepository, tokensRepository,resultFormatsRepository,perUnitsRepository,prefRepository,utilityRepository, context) as T
    }
}