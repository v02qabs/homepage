package com.hiro.take.mywebview

import android.os.Bundle
import android.app.Activity
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.Button
import android.widget.EditText
import android.widget.Toast
import android.content.ClipboardManager
import android.content.ClipData
import android.content.Context
import android.view.ContextMenu
import android.view.MenuItem

class Web : Activity() {
    private lateinit var web_view : WebView
    private lateinit var go_site : Button
    private lateinit var url_box : EditText

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.web)
        url_box = findViewById(R.id.urlEditText)
        go_site = findViewById(R.id.go_site)
        web_view = findViewById(R.id.webview)
        web_view.loadUrl("https://www.google.co.jp")
        web_view.webViewClient = object : WebViewClient() {}
        web_view.settings.javaScriptEnabled =  true



    }

}