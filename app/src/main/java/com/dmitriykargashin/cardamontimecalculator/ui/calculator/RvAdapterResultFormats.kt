/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.cardamontimecalculator.ui.calculator

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.dmitriykargashin.cardamontimecalculator.R
import com.dmitriykargashin.cardamontimecalculator.internal.extension.toHTMLWithGreenColor
import com.google.android.material.card.MaterialCardView
import kotlinx.android.synthetic.main.card_view_formats.view.*


class RvAdapterResultFormats(private val viewModel: CalculatorViewModel, private val context: Context) :
    RecyclerView.Adapter<RvAdapterResultFormats.ViewHolder>() {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int)
            : ViewHolder {
        val v: View = LayoutInflater.from(parent.context)
            .inflate(R.layout.card_view_formats, parent, false)
        return ViewHolder(v)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {

        holder.id.text =
            viewModel.getResultFormats().value!![position].textPresentationOfTokens.toHTMLWithGreenColor(context)
        holder.name.text =
            viewModel.getResultFormats().value!![position].convertedResultTokens.toLightSpannableString(context)


        holder.cardView.setOnClickListener {
            viewModel.setSelectedFormat(position)

        }
    }

    override fun getItemCount(): Int {
        return viewModel.getResultFormats().value!!.size
    }


    class ViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        val id =  itemView.tvFormat as TextView
        val name = itemView.tvResultFormat as TextView
        val cardView = itemView.materialCardView as MaterialCardView


    }


}