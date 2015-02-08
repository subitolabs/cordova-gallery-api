# cordova-gallery-api

This plugin defines a global `galleryAPI` object, which offer methods to query gallery albums and media:

- getAlbums
- getMedia

### Method `getAlbums`

Returns an array of object `{"id" : ..., "title" : ...}`.

### Method `getMedia`

Returns an array of object with the following fields:

- id
- title
- lat
- lon
- thumbnail
- data
- width
- height
- size
- date_create

### Installation

    cordova plugin add https://github.com/subitolabs/cordova-gallery-api.git

### Quick example

```js
document.addEventListener('deviceready', function()
{
    var $content = document.getElementById("content");

    $content.innerHTML = "Loading albums ...";

    galleryAPI.getAlbums(function(items)
    {
        var html = "";

        for(var i = 0; i < items.length; i++)
        {
            var album = items[i];

            html += '<a href="javascript:loadAlbum(\'' + album.title + '\')" class="album"><span>' + escape(album.title) + '</span></a>';
        }

        $content.innerHTML = html;

    }, function(error){alert(error);});

    window.loadAlbum = function(albumName)
    {
        galleryAPI.getMedia(albumName, function(items)
        {
            var html = "";

            for(var i = 0; i < items.length; i++)
            {
                var media = items[i];

                html += '<a href="javascript:void()" class="media"><img src="file://' + media.thumbnail + '" /></a>';
            }

            $content.innerHTML = html;

        }, function(error){alert(error);});
    };

}, false);
```
