@file:JvmName("ExtensionsUtils")

package com.dmitriykargashin.cardamontimecalculator.internal.extension


import android.app.Activity
import android.graphics.Color


import android.text.SpannableString

import android.text.TextUtils
import android.util.Log
import com.dmitriykargashin.cardamontimecalculator.utilites.TimeConverter
import com.dmitriykargashin.cardamontimecalculator.engine.lexer.LexicalAnalyzer
import com.dmitriykargashin.cardamontimecalculator.data.tokens.Token
import com.dmitriykargashin.cardamontimecalculator.data.tokens.Tokens


// this is cool Kotlin feature - extension of standard classes!!
fun String.toTokens(): Tokens {
    return LexicalAnalyzer.analyze(this)
}
fun String.toToken(): Token {
    return LexicalAnalyzer.analyze(this).last()
}


fun String.toTokenInMSec(): Token {
    val tempTokens= LexicalAnalyzer.analyze(this)

    return TimeConverter.convertTokensToMScecToken(tempTokens)

}


fun String.toHTMLWithGreenColor(): SpannableString {


//todo how to get color from colors.xml?

    return spannable { size(0.7f, color(Color.parseColor("#33691e"), this)) }


}


fun String.toHTMLWithLightGreenColor(): SpannableString {


//todo how to get color from colors.xml?

    return spannable { size(0.7f, color(Color.parseColor("#4c992e"), this)) }


}

fun String.toHTMLWithGrayColor(): SpannableString {


//todo how to get color from colors.xml?

    return spannable {  color(Color.parseColor("#807e7e"), this) }


}

fun String.toHTMLWithRedColor(): SpannableString {


//todo how to get color from colors.xml?

    return spannable { size(0.7f, color(Color.parseColor("RED"), this)) }


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

internal fun Activity.logger(message: String) {
    Log.d(this.localClassName, message)
}

internal fun Activity.logger(message: Int) {
    Log.d(this.localClassName, message.toString())
}