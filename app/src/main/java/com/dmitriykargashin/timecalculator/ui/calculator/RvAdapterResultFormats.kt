/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.timecalculator.ui.calculator

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.recyclerview.widget.RecyclerView
import com.dmitriykargashin.timecalculator.R
import com.dmitriykargashin.timecalculator.data.resultFormat.ResultFormats
import kotlinx.android.synthetic.main.card_view_formats.view.*


class RvAdapterResultFormats(val formatsResult: ResultFormats) :
    RecyclerView.Adapter<RvAdapterResultFormats.ViewHolder>() {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int)
            : ViewHolder {
        val v: View = LayoutInflater.from(parent.context)
            .inflate(R.layout.card_view_formats, parent, false)
        return ViewHolder(v)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {

        holder.id.text = formatsResult[position].formatTokens.toSpannableString()
        holder.name.text = formatsResult[position].convertedResultTokens.toLightSpannableString()
    }

    override fun getItemCount(): Int {
        return formatsResult.size
    }

    override fun getItemId(position: Int): Long {
        return super.getItemId(position)
    }

    override fun getItemViewType(position: Int): Int {
        return super.getItemViewType(position)
    }

    class ViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        val id = itemView.tvFormat
        val name = itemView.tvResultFormat
    }
}