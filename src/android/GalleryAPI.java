package com.subitolabs.cordova.galleryapi;

import android.content.Context;
import android.database.Cursor;
import android.net.Uri;
import android.provider.MediaStore;

import org.apache.cordova.*;
import org.json.JSONArray;
import org.json.JSONException;

import java.util.ArrayList;
import java.util.HashMap;

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
        Object columns = new Object()
        {{
            put("id", MediaStore.Images.ImageColumns.BUCKET_ID);
            put("title", MediaStore.Images.ImageColumns.BUCKET_DISPLAY_NAME);
        }};

        return queryContentProvider(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, columns, "1) GROUP BY 1,(2");
    }

    private ArrayOfObjects getMedia(String bucket)
    {
        Object columns = new Object()
        {{
            put("int.id", MediaStore.Images.Media._ID);
            put("data", MediaStore.MediaColumns.DATA);
            put("int.date_added", MediaStore.Images.ImageColumns.DATE_ADDED);
            put("title", MediaStore.Images.ImageColumns.DISPLAY_NAME);
            put("int.height", MediaStore.Images.ImageColumns.HEIGHT);
            put("int.width", MediaStore.Images.ImageColumns.WIDTH);
            put("int.orientation", MediaStore.Images.ImageColumns.ORIENTATION);
            put("mime_type", MediaStore.Images.ImageColumns.MIME_TYPE);
            put("float.lat", MediaStore.Images.ImageColumns.LATITUDE);
            put("float.lon", MediaStore.Images.ImageColumns.LONGITUDE);
            put("int.size", MediaStore.Images.ImageColumns.SIZE);
            put("int.thumbnail", MediaStore.Images.ImageColumns.MINI_THUMB_MAGIC);
        }};

        Object thumbnailsColumns = new Object()
        {{
            put("int.source_id", MediaStore.Images.Thumbnails.IMAGE_ID);
            put("data", MediaStore.MediaColumns.DATA);
        }};

        final ArrayOfObjects results    = queryContentProvider(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, columns, "bucket_display_name = \""+bucket+"\"");
        final ArrayOfObjects thumbnails = queryContentProvider(MediaStore.Images.Thumbnails.EXTERNAL_CONTENT_URI, thumbnailsColumns, MediaStore.Images.Thumbnails.KIND + " = " + MediaStore.Images.Thumbnails.MINI_KIND);

        for (Object media : results)
        {
            for (Object thumbnail : thumbnails)
            {
               // Logger.getLogger("my.output").info("" + thumbnail.get("source_id"));

                if ((int) thumbnail.get("source_id") == (int) media.get("id"))
                {
                    media.put("thumbnail", thumbnail.get("data"));

                    //Logger.getLogger("my.output").info("" + media.get("id"));

                    break;
                }
            }
        }

        return results;
    }

    private Context getContext()
    {
        return this.cordova.getActivity().getApplicationContext();
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
                    int columnIndex = cursor.getColumnIndex(columns.get(column).toString());

                    if (column.startsWith("int."))
                    {
                        item.put(column.substring(4), cursor.getInt(columnIndex));
                    }
                    else if (column.startsWith("float."))
                    {
                        item.put(column.substring(6), cursor.getFloat(columnIndex));
                    }
                    else
                    {
                        item.put(column, cursor.getString(columnIndex));
                    }
                }

                buffer.add(item);
            }
            while (cursor.moveToNext());
        }

        cursor.close();

        return buffer;
    }

    private class Object extends HashMap<String, java.lang.Object>
    {

    }

    private class ArrayOfObjects extends ArrayList<Object>
    {

    }
}
