@file:JvmName("ExtensionsUtils")

package com.dmitriykargashin.timecalculator.internal.extension


import android.text.Html
import android.text.Spanned
import android.text.TextUtils


fun String.toHTMLWithColor(): Spanned {


//todo how to get color from colors.xml?
    return Html.fromHtml("<small><small><font color='#33691e'>$this</font></small></small>")
}


fun String.removeHTML(): String {
    val spanned = this
    val chars = CharArray(spanned.length)
    TextUtils.getChars(spanned, 0, spanned.length, chars, 0)
    return String(chars)
}

fun String.addStartAndEndSpace(): String {
    return " $this "
}

fun String.removeAllSpaces(): String {
    return  this.replace(" ","")
}