/*
   API Client - Handles all HTTP requests to the backend
   Base URL: http://backend-service:5000/api (configurable)
*/

// Configuration - Use internal Kubernetes service DNS for better reliability
// This allows the frontend to reach the backend without going through the external route
let API_BASE_URL = 'http://public-transport-tracker-git:5000/api';
const API_TIMEOUT = 30000; // 30 seconds

/**
 * Generic fetch wrapper with error handling
 * @param {string} endpoint - API endpoint (without base URL)
 * @param {object} options - fetch options
 * @returns {Promise}
 */
async function apiCall(endpoint, options = {}) {
    const url = `${API_BASE_URL}${endpoint}`;
    const defaultOptions = {
        headers: {
            'Content-Type': 'application/json'
        },
        timeout: API_TIMEOUT,
        ...options
    };

    try {
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), API_TIMEOUT);

        const response = await fetch(url, {
            ...defaultOptions,
            signal: controller.signal
        });

        clearTimeout(timeoutId);

        // Handle non-JSON responses
        const contentType = response.headers.get('content-type');
        let data;
        if (contentType && contentType.includes('application/json')) {
            data = await response.json();
        } else {
            data = await response.text();
        }

        if (!response.ok) {
            throw new Error(data.message || `HTTP Error: ${response.status}`);
        }

        return data;
    } catch (error) {
        console.error(`API Error: ${endpoint}`, error);
        throw error;
    }
}

/**
 * GET request helper
 */
async function apiGet(endpoint) {
    return apiCall(endpoint, { method: 'GET' });
}

/**
 * POST request helper
 */
async function apiPost(endpoint, data) {
    return apiCall(endpoint, {
        method: 'POST',
        body: JSON.stringify(data)
    });
}

/**
 * PUT request helper
 */
async function apiPut(endpoint, data) {
    return apiCall(endpoint, {
        method: 'PUT',
        body: JSON.stringify(data)
    });
}

/**
 * DELETE request helper
 */
async function apiDelete(endpoint) {
    return apiCall(endpoint, { method: 'DELETE' });
}

// ============================================================================
// ROUTES API
// ============================================================================

async function fetchRoutes() {
    try {
        const response = await apiGet('/routes');
        return response.data || [];
    } catch (error) {
        console.error('Error fetching routes:', error);
        return [];
    }
}

async function getRoute(routeId) {
    try {
        const response = await apiGet(`/routes/${routeId}`);
        return response.data;
    } catch (error) {
        console.error(`Error fetching route ${routeId}:`, error);
        throw error;
    }
}

async function createRoute(routeData) {
    try {
        const response = await apiPost('/routes', routeData);
        return response.data;
    } catch (error) {
        console.error('Error creating route:', error);
        throw error;
    }
}

// ============================================================================
// STATIONS API
// ============================================================================

async function fetchStations() {
    try {
        const response = await apiGet('/stations');
        return response.data || [];
    } catch (error) {
        console.error('Error fetching stations:', error);
        return [];
    }
}

async function getStation(stationId) {
    try {
        const response = await apiGet(`/stations/${stationId}`);
        return response.data;
    } catch (error) {
        console.error(`Error fetching station ${stationId}:`, error);
        throw error;
    }
}

async function createStation(stationData) {
    try {
        const response = await apiPost('/stations', stationData);
        return response.data;
    } catch (error) {
        console.error('Error creating station:', error);
        throw error;
    }
}

// ============================================================================
// SCHEDULES API
// ============================================================================

async function fetchSchedules(routeId = null, dayOfWeek = null) {
    try {
        let endpoint = '/schedules';
        const params = [];

        if (routeId) params.push(`route_id=${routeId}`);
        if (dayOfWeek) params.push(`day_of_week=${dayOfWeek}`);

        if (params.length > 0) {
            endpoint += '?' + params.join('&');
        }

        const response = await apiGet(endpoint);
        return response.data || [];
    } catch (error) {
        console.error('Error fetching schedules:', error);
        return [];
    }
}

async function getSchedule(scheduleId) {
    try {
        const response = await apiGet(`/schedules/${scheduleId}`);
        return response.data;
    } catch (error) {
        console.error(`Error fetching schedule ${scheduleId}:`, error);
        throw error;
    }
}

async function getRouteSchedules(routeId) {
    try {
        const response = await apiGet(`/routes/${routeId}/schedules`);
        return response.data || [];
    } catch (error) {
        console.error(`Error fetching schedules for route ${routeId}:`, error);
        return [];
    }
}

async function createSchedule(scheduleData) {
    try {
        const response = await apiPost('/schedules', scheduleData);
        return response.data;
    } catch (error) {
        console.error('Error creating schedule:', error);
        throw error;
    }
}

// ============================================================================
// DELAYS API
// ============================================================================

async function fetchDelays(isActive = true, routeId = null) {
    try {
        let endpoint = '/delays?is_active=' + isActive;

        if (routeId) {
            endpoint += `&route_id=${routeId}`;
        }

        const response = await apiGet(endpoint);
        return response.data || [];
    } catch (error) {
        console.error('Error fetching delays:', error);
        return [];
    }
}

async function getDelay(delayId) {
    try {
        const response = await apiGet(`/delays/${delayId}`);
        return response.data;
    } catch (error) {
        console.error(`Error fetching delay ${delayId}:`, error);
        throw error;
    }
}

async function getScheduleDelays(scheduleId) {
    try {
        const response = await apiGet(`/schedules/${scheduleId}/delays`);
        return response.data || [];
    } catch (error) {
        console.error(`Error fetching delays for schedule ${scheduleId}:`, error);
        return [];
    }
}

async function reportDelay(delayData) {
    try {
        const response = await apiPost('/delays', delayData);
        return response.data;
    } catch (error) {
        console.error('Error reporting delay:', error);
        throw error;
    }
}

async function updateDelay(delayId, isActive) {
    try {
        const response = await apiPut(`/delays/${delayId}`, { is_active: isActive });
        return response.data;
    } catch (error) {
        console.error(`Error updating delay ${delayId}:`, error);
        throw error;
    }
}

// ============================================================================
// SEARCH API
// ============================================================================

async function search(query, type = 'all') {
    try {
        if (!query.trim()) {
            return { routes: [], schedules: [] };
        }

        const response = await apiGet(`/search?q=${encodeURIComponent(query)}&type=${type}`);
        return response.data || { routes: [], schedules: [] };
    } catch (error) {
        console.error('Error searching:', error);
        return { routes: [], schedules: [] };
    }
}

// ============================================================================
// HEALTH CHECK API
// ============================================================================

async function checkHealth() {
    try {
        const response = await apiGet('/health');
        return response.status === 'healthy';
    } catch (error) {
        console.error('Health check failed:', error);
        return false;
    }
}

// ============================================================================
// API CONFIGURATION
// ============================================================================

/**
 * Set custom API base URL (useful for environment-specific URLs)
 */
function setApiBaseUrl(url) {
    API_BASE_URL = url;
}

/**
 * Get current API base URL
 */
function getApiBaseUrl() {
    return API_BASE_URL;
}

/**
 * Detect API URL from current location (useful in OpenShift)
 */
function detectApiUrl() {
    const protocol = window.location.protocol;
    const hostname = window.location.hostname;
    
    // In OpenShift, backend service DNS: http://backend-service:5000
    // But from browser, we need to use the exposed route
    if (hostname.includes('localhost') || hostname.includes('127.0.0.1')) {
        setApiBaseUrl('http://localhost:5000/api');
    } else {
        // In production OpenShift, adjust this based on your Route
        setApiBaseUrl(`${protocol}//${hostname}:5000/api`);
    }
}

// Call on page load
window.addEventListener('DOMContentLoaded', detectApiUrl);
