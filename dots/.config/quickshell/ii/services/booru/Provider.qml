import QtQuick

/**
 * Base interface for Booru providers.
 * Implement this to add new providers.
 */
QtObject {
    // Provider identity
    property string providerId: ""
    property string name: ""
    property string url: ""
    property string api: ""
    property string description: ""

    // Whether this provider supports NSFW content filtering
    property bool supportsNsfwFiltering: true

    // Whether this provider requires a User-Agent header
    property bool requiresUserAgent: false

    /**
     * Build the search URL for this provider.
     * @param tags Array of search tags
     * @param nsfw Whether to include NSFW content
     * @param limit Maximum number of results
     * @param page Page number
     * @return Complete URL string
     */
    function constructUrl(tags, nsfw, limit, page) {
        throw new Error("Provider.constructUrl must be implemented")
    }

    /**
     * Map raw API response to standard image format.
     * @param response Raw response from API
     * @param getWorkingImageSource Function to transform image sources
     * @return Array of standardized image objects
     */
    function mapResponse(response, getWorkingImageSource) {
        throw new Error("Provider.mapResponse must be implemented")
    }

    /**
     * Get tag search URL template.
     * @return URL string with {{query}} placeholder, or null if not supported
     */
    function getTagSearchTemplate() { return null }

    /**
     * Map tag search response to standard format.
     * @param response Raw response from tag search API
     * @return Array of {name, count} objects
     */
    function mapTagResponse(response) {
        throw new Error("Provider.mapTagResponse must be implemented")
    }

    /**
     * Get fixed tags for providers with static tag lists.
     * @return Array of {name, count} or null
     */
    function getFixedTags() { return null }

    /**
     * Whether this provider uses manual parsing (non-JSON).
     * @return true if manualParseFunc should be used
     */
    function usesManualParsing() { return false }

    /**
     * Parse non-JSON response manually.
     * @param responseText Raw text response
     * @return Array of standardized image objects
     */
    function manualParse(responseText) {
        throw new Error("Provider.manualParse must be implemented if usesManualParsing returns true")
    }

    /**
     * Get User-Agent value for this provider.
     * @param defaultAgent Default user agent to use as fallback
     * @param configOptions Full config options object
     * @return User-Agent string
     */
    function getUserAgent(defaultAgent, configOptions) {
        return defaultAgent
    }
}
