pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import QtPositioning

// Open-Meteo API weather service with 30-minute cache.
// Provides current conditions, 24h hourly forecast, and 7-day daily forecast.
Singleton {
    id: root

    // 30-minute cache
    readonly property int cacheDuration: 30 * 60 * 1000

    property bool available: false
    property bool loading: false
    property string error: ""
    property string location: ""
    property real lastUpdate: 0

    // Current conditions
    property var current: ({})

    // Hourly forecast (every hour for 24h)
    property var hourly: ([])

    // Daily forecast (7 days)
    property var daily: ([])

    // Weather codes to icons (Open-Meteo WMO codes)
    readonly property var weatherIcons: ({
            0: "\uf00d",   // Clear sky
            1: "\uf00c",   // Mainly clear
            2: "\uf002",   // Partly cloudy
            3: "\uf041",   // Overcast
            45: "\uf014",  // Fog
            48: "\uf014",  // Depositing rime fog
            51: "\uf019",  // Light drizzle
            53: "\uf019",  // Moderate drizzle
            55: "\uf019",  // Dense drizzle
            56: "\uf019",  // Light freezing drizzle
            57: "\uf019",  // Dense freezing drizzle
            61: "\uf01b",  // Slight rain
            63: "\uf01b",  // Moderate rain
            65: "\uf01b",  // Heavy rain
            66: "\uf01b",  // Light freezing rain
            67: "\uf01b",  // Heavy freezing rain
            71: "\uf076",  // Slight snow
            73: "\uf076",  // Moderate snow
            75: "\uf076",  // Heavy snow
            77: "\uf076",  // Snow grains
            80: "\uf019",  // Slight rain showers
            81: "\uf019",  // Moderate rain showers
            82: "\uf019",  // Violent rain showers
            85: "\uf076",  // Slight snow showers
            86: "\uf076",  // Heavy snow showers
            95: "\uf016",  // Thunderstorm
            96: "\uf016",  // Thunderstorm with slight hail
            99: "\uf016",  // Thunderstorm with heavy hail
        })

    // Weather codes to descriptions
    readonly property var weatherDescriptions: ({
            0: "Clear sky",
            1: "Mainly clear",
            2: "Partly cloudy",
            3: "Overcast",
            45: "Foggy",
            48: "Depositing rime fog",
            51: "Light drizzle",
            53: "Moderate drizzle",
            55: "Dense drizzle",
            56: "Light freezing drizzle",
            57: "Dense freezing drizzle",
            61: "Light rain",
            63: "Moderate rain",
            65: "Heavy rain",
            66: "Light freezing rain",
            67: "Heavy freezing rain",
            71: "Light snow",
            73: "Moderate snow",
            75: "Heavy snow",
            77: "Snow grains",
            80: "Light showers",
            81: "Moderate showers",
            82: "Violent showers",
            85: "Light snow showers",
            86: "Heavy snow showers",
            95: "Thunderstorm",
            96: "Thunderstorm with hail",
            99: "Severe thunderstorm",
        })

    function icon(code: int, isDay: bool): string {
        const icon = weatherIcons[code] ?? "\uf00d";
        // Use day/night variants for clear/partly cloudy
        if (code === 0) return isDay ? "\uf00d" : "\uf02e";
        if (code === 1) return isDay ? "\uf00c" : "\uf086";
        return icon;
    }

    function description(code: int): string {
        return weatherDescriptions[code] ?? "Unknown";
    }

    // Cache
    property var _cache: ({})
    property var _cacheTime: ({})
    property var _location: ({ lat: 0, lon: 0, valid: false })

    Timer {
        interval: cacheDuration
        running: false
        repeat: false
        onTriggered: refresh(true)
    }

    function refresh(force: bool) {
        if (!force && Date.now() - lastUpdate < cacheDuration) {
            return;
        }
        if (loading)
            return;

        const cacheKey = _location.lat.toFixed(2) + "," + _location.lon.toFixed(2);
        if (!force && _cache[cacheKey] && _cacheTime[cacheKey] && Date.now() - _cacheTime[cacheKey] < cacheDuration) {
            _applyCache(cacheKey);
            return;
        }

        loading = true;
        error = "";
        fetchWeather(cacheKey);
    }

    function fetchWeather(cacheKey) {
        const url = "https://api.open-meteo.com/v1/forecast?" +
            "latitude=" + _location.lat.toFixed(2) +
            "&longitude=" + _location.lon.toFixed(2) +
            "&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m,uv_index,is_day" +
            "&hourly=temperature_2m,precipitation_probability,weather_code,wind_speed_10m" +
            "&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max,sunrise,sunset,uv_index_max" +
            "&timezone=auto&forecast_days=7";

        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            loading = false;
            if (xhr.status === 200) {
                try {
                    const data = JSON.parse(xhr.responseText);
                    _cache[cacheKey] = data;
                    _cacheTime[cacheKey] = Date.now();
                    _applyCache(cacheKey);
                } catch (e) {
                    error = "Failed to parse weather data";
                    available = false;
                }
            } else {
                error = "Weather API request failed";
                available = false;
            }
        };
        xhr.open("GET", url);
        xhr.send();
    }

    function _applyCache(cacheKey) {
        const data = _cache[cacheKey];
        if (!data)
            return;

        lastUpdate = Date.now();
        available = true;

        // Current
        current = {
            temp: Math.round(data.current.temperature_2m),
            feelsLike: Math.round(data.current.apparent_temperature),
            humidity: data.current.relative_humidity_2m,
            wind: Math.round(data.current.wind_speed_10m),
            uv: Math.round(data.current.uv_index ?? 0),
            code: data.current.weather_code,
            isDay: data.current.is_day === 1,
            precip: data.current.precipitation ?? 0,
        };

        // Hourly (next 24 hours)
        hourly = [];
        const now = new Date();
        const currentHour = now.getHours();
        for (let i = 0; i < 24; i++) {
            const idx = currentHour + i;
            if (idx < data.hourly.time.length) {
                hourly.push({
                    time: data.hourly.time[idx],
                    temp: Math.round(data.hourly.temperature_2m[idx]),
                    precip: data.hourly.precipitation_probability[idx] ?? 0,
                    code: data.hourly.weather_code[idx],
                    wind: Math.round(data.hourly.wind_speed_10m[idx]),
                });
            }
        }

        // Daily
        daily = [];
        for (let i = 0; i < Math.min(7, data.daily.time.length); i++) {
            daily.push({
                date: data.daily.time[i],
                max: Math.round(data.daily.temperature_2m_max[i]),
                min: Math.round(data.daily.temperature_2m_min[i]),
                code: data.daily.weather_code[i],
                precip: data.daily.precipitation_sum[i] ?? 0,
                precipProb: data.daily.precipitation_probability_max[i] ?? 0,
                sunrise: data.daily.sunrise[i]?.split("T")[1] ?? "",
                sunset: data.daily.sunset[i]?.split("T")[1] ?? "",
                uv: Math.round(data.daily.uv_index_max[i] ?? 0),
            });
        }

        // Set location name (reverse geocode via timezone)
        location = Intl.DateTimeFormat().resolvedOptions().timeZone;
    }

    // Format time from "HH:MM" to readable format
    function formatTime(timeStr: string): string {
        if (!timeStr) return "";
        const parts = timeStr.split(":");
        if (parts.length < 2) return timeStr;
        const hour = parseInt(parts[0], 10);
        const ampm = hour >= 12 ? "PM" : "AM";
        const hour12 = hour % 12 || 12;
        return hour12 + ":" + parts[1] + " " + ampm;
    }

    property string sunrise: current ? formatTime(daily[0]?.sunrise ?? "") : ""
    property string sunset: current ? formatTime(daily[0]?.sunset ?? "") : ""

    // GeoClue position source for automatic location detection
    PositionSource {
        id: positionSource
        updateInterval: 1000 // Update once on startup, then stop
        onPositionChanged: {
            if (position.latitudeValid && position.longitudeValid) {
                root._location = {
                    lat: position.coordinate.latitude,
                    lon: position.coordinate.longitude,
                    valid: true
                };
                location = Intl.DateTimeFormat().resolvedOptions().timeZone;
                root.refresh(false);
                positionSource.stop();
            }
        }
        onValidityChanged: {
            if (!positionSource.valid) {
                positionSource.stop();
                // Fallback: try to get location from system timezone-based guess
                root._location = { lat: 0, lon: 0, valid: false };
                location = Intl.DateTimeFormat().resolvedOptions().timeZone;
            }
        }
    }

    Component.onCompleted: {
        // Try to get location from GeoClue
        positionSource.start();
        // Fallback: if no GPS, use timezone-based location name
        location = Intl.DateTimeFormat().resolvedOptions().timeZone;
    }

    // Timer for periodic refresh
    Timer {
        interval: cacheDuration
        running: true
        repeat: true
        onTriggered: refresh(false)
    }
}
