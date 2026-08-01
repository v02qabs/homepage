package com.hiro.myapplication;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.ListView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;

import java.util.ArrayList;

public class MainActivity extends AppCompatActivity {

    private Toolbar toolbar;
    private ListView listView;
    private ArrayAdapter<String> adapter;
    private ArrayList<String> menuItemList = new ArrayList<>();
    private Button addButton;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        // ツールバーの設定
        toolbar = findViewById(R.id.my_toolbar);
        setSupportActionBar(toolbar);

        // ListViewの設定
        listView = findViewById(R.id.list_menu);
        adapter = new ArrayAdapter<>(this, android.R.layout.simple_list_item_1, menuItemList);
        listView.setAdapter(adapter);

        // 初期データを追加する場合
        addInitialMenuItems();

        // ボタンの初期化とクリックリスナー
        addButton = findViewById(R.id.add_button); // activity_main.xml にボタンが必要
        if (addButton != null) { // findViewById がnullを返さないか確認
            addButton.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    addItem("New Item " + (menuItemList.size() + 1));
                }
            });
        } else {
            Toast.makeText(this, "Add button not found!", Toast.LENGTH_SHORT).show();
        }

        // ListViewのアイテムクリック処理
        listView.setOnItemClickListener((parent, view, position, id) -> {
            String selectedItem = menuItemList.get(position);
            Toast.makeText(MainActivity.this, "Clicked: " + selectedItem, Toast.LENGTH_SHORT).show();

            if (selectedItem.equals("Download")) {
                // "Download" アイテムがクリックされたら、SecondActivity を起動
                Intent intent = new Intent(MainActivity.this, Downloads.class);
                startActivity(intent);
            }
            // 他のアイテムの処理...
        });
    }

    private void addInitialMenuItems() {
        addItem("Download");
        addItem("WebView");
        addItem("editor");
        addItem("Help");
        addItem("About Us");
        addItem("Exit");
    }

    private void addItem(String item) {
        adapter.add(item);
    }

    private void removeItem(int position) {
        if (position >= 0 && position < menuItemList.size()) {
            menuItemList.remove(position);
            adapter.notifyDataSetChanged();
        }
    }

    private void removeItem(String item) {
        if (menuItemList.contains(item)) {
            menuItemList.remove(item);
            adapter.remove(item);
        }
    }

    private void clearItems() {
        menuItemList.clear();
        adapter.clear();
    }

    private void updateItem(int position, String newItem) {
        if (position >= 0 && position < menuItemList.size()) {
            menuItemList.set(position, newItem);
            adapter.notifyDataSetChanged();
        }
    }
}