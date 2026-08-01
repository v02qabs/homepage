package hiro.take.html.viewer;

import android.app.Activity;
import android.os.Bundle;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.FrameLayout;
import android.Manifest;
import android.content.pm.PackageManager;
import java.io.File;

public class MainActivity extends Activity {
    private WebView mWebView;
    private final String HTML_PATH = "/sdcard/Documents/index.html";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // 1. 7インチの画面を最大限に使うためのフルスクリーン設定
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN,
                           WindowManager.LayoutParams.FLAG_FULLSCREEN);

        // 2. レイアウトの構築（XMLなし）
        FrameLayout layout = new FrameLayout(this);
        mWebView = new WebView(this);
        layout.addView(mWebView, new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT, 
                FrameLayout.LayoutParams.MATCH_PARENT));
        setContentView(layout);

        // 3. WebViewの最適化設定
        WebSettings s = mWebView.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        
        // 7インチ画面での視認性を高める設定
        s.setUseWideViewPort(true);       // 広いビューポートを許可
        s.setLoadWithOverviewMode(true);  // 画面サイズに収まるようにズーム
        s.setSupportZoom(true);           // ズーム機能をサポート
        s.setBuiltInZoomControls(true);   // ズームボタンを表示
        s.setDisplayZoomControls(false);  // ピンチ操作のみにする（ボタンは隠す）

        // ファイルアクセスの許可
        s.setAllowFileAccess(true);
        s.setAllowContentAccess(true);
        s.setAllowFileAccessFromFileURLs(true);
        s.setAllowUniversalAccessFromFileURLs(true);

        mWebView.setWebViewClient(new WebViewClient());

        // 4. 権限確認と読み込み
        checkAndLoad();
    }

    private void checkAndLoad() {
        if (checkSelfPermission(Manifest.permission.READ_EXTERNAL_STORAGE) 
            != PackageManager.PERMISSION_GRANTED) {
            requestPermissions(new String[]{Manifest.permission.READ_EXTERNAL_STORAGE}, 1);
        } else {
            loadHtml();
        }
    }

    private void loadHtml() {
        File f = new File("/sdcard/Documents/blog/index.html");
        if (f.exists()) {
            mWebView.loadUrl("file://" + HTML_PATH);
        } else {
            String msg = "<html><body style='padding:20px; font-size:1.2em;'>"
                       + "<h2>Fire 7 Viewer</h2>"
                       + "<p>File not found at:<br><b>" + HTML_PATH + "</b></p>"
                       + "</body></html>";
            mWebView.loadDataWithBaseURL(null, msg, "text/html", "UTF-8", null);
        }
    }

    @Override
    public void onRequestPermissionsResult(int rCode, String[] perms, int[] results) {
        if (results.length > 0 && results[0] == PackageManager.PERMISSION_GRANTED) {
            loadHtml();
        }
    }

    @Override
    public void onBackPressed() {
        if (mWebView.canGoBack()) {
            mWebView.goBack();
        } else {
            super.onBackPressed();
        }
    }
}
