
function GalleryAPI()
{
    
}

GalleryAPI.prototype.checkPermission = function(successCallback, errorCallback) {
    cordova.exec(
        successCallback,
        errorCallback,
        'GalleryAPI',
        'checkPermission',
        []
    );
};


GalleryAPI.prototype.getAlbums = function(successCallback, errorCallback) {
    cordova.exec(
        successCallback,
        errorCallback,
        'GalleryAPI',
        'getAlbums',
        []
    );
};

GalleryAPI.prototype.getMedia = function(albumName, successCallback, errorCallback) {
    cordova.exec(
        successCallback,
        errorCallback,
        'GalleryAPI',
        'getMedia',
        [albumName]
    );
};

GalleryAPI.prototype.getMediaThumbnail = function(media, successCallback, errorCallback) {
    cordova.exec(
        successCallback,
        errorCallback,
        'GalleryAPI',
        'getMediaThumbnail',
        [media]
    );
};

GalleryAPI.prototype.getHQImageData = function(media, successCallback, errorCallback) {
    cordova.exec(
        successCallback,
        errorCallback,
        'GalleryAPI',
        'getHQImageData',
        [media]
    );
};

module.exports = new GalleryAPI();
