/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.timecalculator.data.repository

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import com.dmitriykargashin.timecalculator.data.resultFormat.ResultFormat
import com.dmitriykargashin.timecalculator.data.resultFormat.ResultFormats
import com.dmitriykargashin.timecalculator.internal.extension.toTokens

class ResultFormatsRepository {

    private var resultFormatsList = ResultFormats()
    private val resultFormats = MutableLiveData<ResultFormats>()

    init {
        resultFormats.value = resultFormatsList
    }

    fun addResultFormat(resultFormat: ResultFormat) {

        resultFormatsList.add(resultFormat)
        resultFormats.value = resultFormatsList

    }

    fun length(): Int = resultFormatsList.lastIndex + 1

    fun getResultFormats() = resultFormats as LiveData<ResultFormats>

    fun setTokens(newResultFormats: ResultFormats) {

        resultFormatsList = newResultFormats
        //    Log.i("TAG", tokensList.toString())
        resultFormats.postValue(resultFormatsList) // for executing in background thread

        //     emit()
        //  Log.i("TAG", tokensList.toString())
    }

    private fun fillRepository() {
        val rf=ResultFormat("Hour Minute".toTokens(),"10 Hour 20 Minute".toTokens())
        val rf2=ResultFormat("Year Week".toTokens(),"4 Year 2 Week 4 Year 2 Week 4 Year 2 Week 4 Year 2 Week".toTokens())
        val rf3=ResultFormat("Hour".toTokens(),"1.5 Hour".toTokens())
        addResultFormat(rf)
        addResultFormat(rf2)
        addResultFormat(rf3)
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