/*
 * Copyright (c) 2021. Dmitriy Kargashin
 */

package com.dmitriykargashin.cardamontimecalculator.data.repository

import android.content.Context
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import com.dmitriykargashin.cardamontimecalculator.data.tokens.Tokens


class UtilityRepository() {

    private var isInFormatsChooseModeRepository: Boolean =
        false // for controlling whenever opened format chooser view or not

    private val isInFormatsChooseMode = MutableLiveData<Boolean>()

    private var isInPerViewModeRepository: Boolean =
        false // for controlling whenever opened per view or not

    private val isInPerViewMode = MutableLiveData<Boolean>()


    private var isInSupportAppViewModeRepository: Boolean =
        false // for controlling whenever opened Support app view or not
    private val isInSupportAppViewMode = MutableLiveData<Boolean>()


    private var isInSettingsViewModeRepository: Boolean =
        false // for controlling whenever opened Settings view or not
    private val isInSettingsViewMode = MutableLiveData<Boolean>()

    //  private var tempResultInMsec = Tokens()
    private var tempResultInMsecRepository = Tokens()
    private var tempResultInMsec = MutableLiveData<Tokens>()


    private var isPerViewButtonDisabledRepository: Boolean =
        true
    private val isPerViewButtonDisabled = MutableLiveData<Boolean>()

    private var isFormatsViewButtonDisabledRepository: Boolean =
        true
    private val isFormatsViewButtonDisabled = MutableLiveData<Boolean>()


    init {

        isInFormatsChooseMode.value = isInFormatsChooseModeRepository
        isInPerViewMode.value = isInPerViewModeRepository
        isInSupportAppViewMode.value = isInSupportAppViewModeRepository
        isInSettingsViewMode.value = isInSettingsViewModeRepository

        isPerViewButtonDisabled.value = isPerViewButtonDisabledRepository
        isFormatsViewButtonDisabled.value = isFormatsViewButtonDisabledRepository

    }



    fun getIsFormatsLayoutVisible() = isInFormatsChooseMode as LiveData<Boolean>

    fun getIsPerLayoutVisible() = isInPerViewMode as LiveData<Boolean>

    fun getIsSupportAppLayoutVisible() = isInSupportAppViewMode as LiveData<Boolean>

    fun getIsSettingsLayoutVisible() = isInSettingsViewMode as LiveData<Boolean>

    fun setIsFormatsLayoutVisible(visible: Boolean) {
        isInFormatsChooseModeRepository = visible
        isInFormatsChooseMode.value = isInFormatsChooseModeRepository
    }


    fun setIsPerLayoutVisible(visible: Boolean) {
        isInPerViewModeRepository = visible
        isInPerViewMode.value = isInPerViewModeRepository
    }

    fun setIsSupportAppLayoutVisible(visible: Boolean) {
        isInSupportAppViewModeRepository = visible
        isInSupportAppViewMode.value = isInSupportAppViewModeRepository
    }

    fun setIsSettingsLayoutVisible(visible: Boolean) {
        isInSettingsViewModeRepository = visible
        isInSettingsViewMode.value = isInSettingsViewModeRepository
    }


    fun getIsPerViewButtonDisabled() = isPerViewButtonDisabled as LiveData<Boolean>

    fun setIsPerViewButtonDisabled(visible: Boolean) {
        isPerViewButtonDisabledRepository = visible
        isPerViewButtonDisabled.value = isPerViewButtonDisabledRepository
    }


    fun getIsFormatsViewButtonDisabled() = isFormatsViewButtonDisabled as LiveData<Boolean>

    fun setIsFormatsViewButtonDisabled(visible: Boolean) {
        isFormatsViewButtonDisabledRepository = visible
        isFormatsViewButtonDisabled.value = isFormatsViewButtonDisabledRepository
    }


    fun getTempResultInMsec() = tempResultInMsec as LiveData<Tokens>

    fun setTempResultInMsec(value: Tokens) {
        tempResultInMsecRepository = value
        tempResultInMsec.value = tempResultInMsecRepository
    }




    companion object {
        // @Volatile - Writes to this property are immediately visible to other threads
        @Volatile
        private var instance: UtilityRepository? = null

        // The only way to get hold of the FakeDatabase object
        fun getInstance() =
        // Already instantiated? - return the instance
            // Otherwise instantiate in a thread-safe manner
            instance ?: synchronized(this) {
                // If it's still not instantiated, finally create an object
                // also set the "instance" property to be the currently created one
                instance
                    ?: UtilityRepository().also {
                        //  it.getPrefThemeColor()
                        instance = it
                    }
            }
    }
}
