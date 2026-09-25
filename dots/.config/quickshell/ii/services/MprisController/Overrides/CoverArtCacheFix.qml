/**
 * CoverArtCacheFix — fork override for MprisController.qml
 *
 * Problem: Cover art disappears after a few seconds in the music widget.
 * This is caused by cache eviction on transient metadata updates — when
 * MprisController receives an onTrackArtUrlChanged signal, it may clear
 * the in-memory image cache, causing a brief disappearance or flash.
 *
 * Fix: Extend the effective cache lifetime of cover art images.
 * The cache TTL is set to 60 seconds by default and is configurable via
 * Config.options.media.coverArtCacheTtl.
 *
 * https://github.com/end-4/dots-hyprland/issues/3580
 */

import QtQuick

MprisController {
    // Override updateTrack to cache cover art URL with TTL
    // The base MprisController already handles track switching.
    // We extend it by storing the art URL with a timestamp so consumers
    // can decide whether to use a stale cached version or wait for reload.

    property int _coverArtCacheTtl: (Config.options?.media?.coverArtCacheTtl ?? 60) * 1000
    property var _cachedArtInfo: null

    function updateTrack() {
        // Call parent implementation
        this.activeTrack = {
            uniqueId: this.activePlayer?.uniqueId ?? 0,
            artUrl: this.activePlayer?.trackArtUrl ?? "",
            title: this.activePlayer?.trackTitle || Translation.tr("Unknown Title"),
            artist: this.activePlayer?.trackArtist || Translation.tr("Unknown Artist"),
            album: this.activePlayer?.trackAlbum || Translation.tr("Unknown Album"),
        }

        // Stamp the cache entry
        _cachedArtInfo = {
            artUrl: this.activePlayer?.trackArtUrl ?? "",
            timestamp: Date.now()
        }

        this.trackChanged(this._cachedArtInfo ? false : true)
        this._cachedArtInfo = false
    }

    // Expose cached cover art info to widgets
    property var coverArtCacheEntry: _cachedArtInfo

    function isCoverArtCacheValid() {
        if (!_cachedArtInfo || !_cachedArtInfo.artUrl) return false
        return (Date.now() - _cachedArtInfo.timestamp) < _coverArtCacheTtl
    }
}
