package com.subitolabs.android.cordova.galleryapi;

import android.app.Application;
import android.content.Context;
import android.database.Cursor;
import android.net.Uri;
import android.provider.MediaStore;

import org.apache.cordova.*;
import org.json.JSONObject;
import org.json.JSONArray;
import org.json.JSONException;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.logging.Logger;

public class GalleryAPI extends CordovaPlugin
{
    public static final String ACTION_GET_MEDIA = "getMedia";
    public static final String ACTION_GET_ALBUMS = "getAlbums";

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException
    {
        try {
            if (ACTION_GET_MEDIA.equals(action))
            {
                ArrayOfObjects albums = getMedia("Camera");

                callbackContext.success(new JSONArray(albums));

                return true;
            }
            else if (ACTION_GET_ALBUMS.equals(action))
            {
                ArrayOfObjects albums = getBuckets();

                callbackContext.success(new JSONArray(albums));

                return true;
            }
            callbackContext.error("Invalid action");
            return false;
        } catch(Exception e) {
            e.printStackTrace();
            callbackContext.error(e.getMessage());
            return false;
        }
    }

    public ArrayOfObjects getBuckets()
    {
        Object columns = new Object(){{
            put("id", MediaStore.Images.ImageColumns.BUCKET_ID);
            put("title", MediaStore.Images.ImageColumns.BUCKET_DISPLAY_NAME);
        }};

        return queryContentProvider(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, columns, "1) GROUP BY 1,(2");
    }

    private ArrayOfObjects getMedia(String bucket)
    {
        Object columns = new Object(){{
            put("id", MediaStore.Images.Media._ID);
            put("date_added", MediaStore.Images.ImageColumns.DATE_ADDED);
            put("title", MediaStore.Images.ImageColumns.DISPLAY_NAME);
            put("height", MediaStore.Images.ImageColumns.HEIGHT);
            put("width", MediaStore.Images.ImageColumns.WIDTH);
            put("orientation", MediaStore.Images.ImageColumns.ORIENTATION);
            put("mime_type", MediaStore.Images.ImageColumns.MIME_TYPE);
            put("thumbnail_id", MediaStore.Images.ImageColumns.MINI_THUMB_MAGIC);
        }};

        return queryContentProvider(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, columns, "bucket_display_name = \""+bucket+"\"");
    }

    private Context getContext()
    {
        if (this.cordova != null && this.cordova.getActivity() != null)
        {
            return this.cordova.getActivity().getApplicationContext();
        }
        else
        {
            return MainActivity.context;
        }
    }

    private ArrayOfObjects queryContentProvider(Uri collection, Object columns, String whereClause)
    {
        final Cursor cursor = getContext().getContentResolver().query(collection, columns.values().toArray(new String[columns.values().size()]), whereClause, null, null);
        final ArrayOfObjects buffer = new ArrayOfObjects();

        if (cursor.moveToFirst())
        {
            do
            {
                Object item = new Object();

                for (String column : columns.keySet())
                {
                    item.put(column, cursor.getString(cursor.getColumnIndex(columns.get(column))));
                }

                buffer.add(item);
            }
            while (cursor.moveToNext());
        }

        cursor.close();

        return buffer;
    }

    private class Object extends HashMap<String, String>
    {

    }

    private class ArrayOfObjects extends ArrayList<Object>
    {

    }
}
