@file:JvmName("ExtensionsUtils")

package com.dmitriykargashin.timecalculator.extension


import android.text.Html
import android.text.Spanned


fun String.toHTMLWithColor(): Spanned {

//todo how to get color from colors.xml&?
    return Html.fromHtml("<small><small><font color='#33691e'>" + this + "</font></small></small>")
}