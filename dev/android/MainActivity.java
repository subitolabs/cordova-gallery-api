package com.subitolabs.android.cordova.gallerypicker;

import android.content.Context;
import android.support.v7.app.ActionBarActivity;
import android.os.Bundle;
import android.view.Menu;
import android.view.MenuItem;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;

import java.util.logging.Logger;


public class MainActivity extends ActionBarActivity {

    static public Context context;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        context = this.getApplicationContext();

        GalleryPickerPlugin plugin = new GalleryPickerPlugin();

        try {
            plugin.execute("getMedia", new JSONArray(), new MyCallbackContext());
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }


    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.menu_main, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        // Handle action bar item clicks here. The action bar will
        // automatically handle clicks on the Home/Up button, so long
        // as you specify a parent activity in AndroidManifest.xml.
        int id = item.getItemId();

        //noinspection SimplifiableIfStatement
        if (id == R.id.action_settings) {
            return true;
        }

        return super.onOptionsItemSelected(item);
    }

    private class MyCallbackContext extends CallbackContext
    {
        public MyCallbackContext()
        {
            super("", null);
        }

        public void sendPluginResult(PluginResult pluginResult)
        {
            Logger.getLogger("my.output").info("Result: " + pluginResult.getJSONString());
        }
    }
}
