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

                html += '<a href="javascript:void()" class="media"><img src="' + media.thumbnail + '" /></a>';
            }

            $content.innerHTML = html;

        }, function(error){alert(error);});
    };

    function escape(v)
    {
        return v.replace(/[\u00A0-\u9999<>\&]/gim, function(i) {
            return '&#'+i.charCodeAt(0)+';';
        });
    }


}, false);
