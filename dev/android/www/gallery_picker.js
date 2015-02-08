var galleryPickerPlugin = {
    getAlbums: function(successCallback, errorCallback) {
        cordova.exec(
            successCallback, // success callback function
            errorCallback, // error callback function
            'GalleryPickerPlugin', // mapped to our native Java class called "CalendarPlugin"
            'getAlbums', // with this action name
            []
        );
     }
};