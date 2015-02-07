var galleryAPI = {
    getAlbums: function(successCallback, errorCallback) {
        cordova.exec(
            successCallback, // success callback function
            errorCallback, // error callback function
            'GalleryAPI', // mapped to our native Java class called "CalendarPlugin"
            'getAlbums', // with this action name
            []
        );
     }
};
