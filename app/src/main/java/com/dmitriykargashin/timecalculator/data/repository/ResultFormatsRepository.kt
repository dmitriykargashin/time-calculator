/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.timecalculator.data.repository

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import com.dmitriykargashin.timecalculator.data.resultFormat.ResultFormat
import com.dmitriykargashin.timecalculator.data.resultFormat.ResultFormats
import com.dmitriykargashin.timecalculator.data.tokens.Tokens
import com.dmitriykargashin.timecalculator.internal.extension.toTokens
import com.dmitriykargashin.timecalculator.utilites.TimeConverter
import java.text.FieldPosition

class ResultFormatsRepository {

    private var resultFormatsList = ResultFormats()
    private val resultFormats = MutableLiveData<ResultFormats>()
    private lateinit var selectedResFormat: ResultFormat
    private val selectedResultFormats = MutableLiveData<ResultFormat>()


    init {
        resultFormats.value = resultFormatsList
       // selectedResultFormats.value = selectedResFormat
    }

    fun addResultFormat(resultFormat: ResultFormat): ResultFormat {

        resultFormatsList.add(resultFormat)
        resultFormats.value = resultFormatsList
        return resultFormat

    }

    fun length(): Int = resultFormatsList.lastIndex + 1


    fun getResultFormats() = resultFormats as LiveData<ResultFormats>

    fun getSelectedFormat() = selectedResultFormats as LiveData<ResultFormat> /*: LiveData<ResultFormat> {
        for (resformat in resultFormatsList) {
            if (resformat.isSelected) {
                selectedResFormat = resformat
                selectedResultFormats.value = selectedResFormat

            }
        }
        resultFormats.value = resultFormatsList
        return selectedResultFormats
    }*/

    fun setSelectedFormat(position: Int): LiveData<ResultFormat> {

        selectedResFormat = resultFormatsList.setSelection(position)
        selectedResultFormats.value = selectedResFormat
      //  resultFormats.value = resultFormatsList
        return selectedResultFormats
    }

    fun updateFormatsWithPreview(resultTokens: Tokens) {

        for (resultFormatElement in resultFormatsList) {

            resultFormatElement.convertedResultTokens =
                TimeConverter.convertTokensToTokensWithFormat(
                    resultTokens,
                    resultFormatElement.formatTokens
                )
        }

        resultFormats.value = resultFormatsList
    }

    fun setTokens(newResultFormats: ResultFormats) {

        resultFormatsList = newResultFormats
        //    Log.i("TAG", tokensList.toString())
        resultFormats.postValue(resultFormatsList) // for executing in background thread

        //     emit()
        //  Log.i("TAG", tokensList.toString())
    }

    private fun fillRepository() {


        addResultFormat(ResultFormat("Year".toTokens(), "1 Year".toTokens()))
        addResultFormat(ResultFormat("Year Month".toTokens(), "1 Year 2 Month".toTokens()))
        addResultFormat(
            ResultFormat(
                "Year Month Day".toTokens(),
                "1 Year 2 Month 3 Day".toTokens()
            )
        )
        addResultFormat(
            ResultFormat(
                "Year Month Day Minute".toTokens(),
                "1 Year 2 Month 3 Day 4 Minute".toTokens()
            )
        )

        addResultFormat(ResultFormat("Month".toTokens(), "1 Month".toTokens()))
        addResultFormat(ResultFormat("Month Day".toTokens(), "Month Day".toTokens()))
        addResultFormat(
            ResultFormat(
                "Month Day Hour".toTokens(),
                "1 Month 2 Day 3 Hour".toTokens()
            )
        )
        addResultFormat(
            ResultFormat(
                "Month Day Hour Minute".toTokens(),
                "1 Month 2 Day 3 Hour 4 Minute".toTokens()
            )
        )
        addResultFormat(
            ResultFormat(
                "Month Day Hour Minute Second".toTokens(),
                "1 Month 2 Day 3 Hour 4 Minute 5 Second".toTokens()
            )
        )
        addResultFormat(ResultFormat("Month Week".toTokens(), "1 Month 2 Week".toTokens()))

        addResultFormat(ResultFormat("Week".toTokens(), "1 Week".toTokens()))
        addResultFormat(ResultFormat("Week Day".toTokens(), "1 Week 2 Day".toTokens()))

        addResultFormat(ResultFormat("Day".toTokens(), "1 Day".toTokens()))
        addResultFormat(ResultFormat("Day Hour".toTokens(), "1 Day 1 Hour".toTokens()))
        addResultFormat(
            ResultFormat(
                "Day Hour Minute".toTokens(),
                "1 Day 2 Hour 3 Minute".toTokens()
            )
        )
        addResultFormat(
            ResultFormat(
                "Day Hour Minute Second".toTokens(),
                "1 Day 2 Hour 3 Minute 4 Second".toTokens()
            )
        )

        addResultFormat(ResultFormat("Hour".toTokens(), "1 Hour".toTokens()))
        addResultFormat(ResultFormat("Hour Minute".toTokens(), "1 Hour 2 Minute".toTokens()))
        addResultFormat(
            ResultFormat(
                "Hour Minute Second".toTokens(),
                "1 Hour 2 Minute 3 Second".toTokens()
            )
        )

        addResultFormat(ResultFormat("Minute".toTokens(), "1 Minute".toTokens()))
        addResultFormat(ResultFormat("Minute Second".toTokens(), "1 Minute 2 Second".toTokens()))

        addResultFormat(ResultFormat("Second".toTokens(), "1 Second".toTokens()))


        addResultFormat(
            ResultFormat(
                "Year Month Week Day Hour Minute Second MSecond".toTokens(),
                "1 Year 2 Month 3 Week 4 Day 5 Hour 6 Minute 7 Second 8 MSecond".toTokens(),
                "All Units"

            )
        ).isSelected = true
        selectedResFormat = resultFormatsList.getSelectedResulFormat()
        selectedResultFormats.value = selectedResFormat

    }

    companion object {
        // @Volatile - Writes to this property are immediately visible to other threads
        @Volatile
        private var instance: ResultFormatsRepository? = null

        // The only way to get hold of the FakeDatabase object
        fun getInstance() =
        // Already instantiated? - return the instance
            // Otherwise instantiate in a thread-safe manner
            instance ?: synchronized(this) {
                // If it's still not instantiated, finally create an object
                // also set the "instance" property to be the currently created one
                instance
                    ?: ResultFormatsRepository().also {
                        //fiil list only once
                        it.fillRepository()


                        instance = it
                    }
            }
    }
}