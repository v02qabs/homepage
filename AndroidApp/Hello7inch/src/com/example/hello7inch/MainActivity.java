package com.example.hello7inch;

import android.app.Activity;
import android.os.Bundle;
import android.widget.TextView;

public class MainActivity extends Activity {

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        setContentView(R.layout.main);

        TextView tv = (TextView)findViewById(R.id.text1);
        tv.setText("Hello Android-9 (Java Embedded Text)");
    }
}
