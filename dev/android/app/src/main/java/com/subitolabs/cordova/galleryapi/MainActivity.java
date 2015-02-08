package com.subitolabs.cordova.galleryapi;

import android.app.Activity;
import android.content.Intent;
import android.support.v7.app.ActionBarActivity;
import android.os.Bundle;
import android.view.Menu;
import android.view.MenuItem;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;

import java.util.concurrent.ExecutorService;
import java.util.logging.Logger;


public class MainActivity extends ActionBarActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        GalleryAPI plugin = new GalleryAPI();

        plugin.cordova = new MyCordova();

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

    private class MyCordova implements CordovaInterface
    {
        @Override
        public void startActivityForResult(CordovaPlugin cordovaPlugin, Intent intent, int i) {

        }

        @Override
        public void setActivityResultCallback(CordovaPlugin cordovaPlugin) {

        }

        @Override
        public Activity getActivity() {
            return MainActivity.this;
        }

        @Override
        public Object onMessage(String s, Object o) {
            return null;
        }

        @Override
        public ExecutorService getThreadPool() {
            return null;
        }
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
