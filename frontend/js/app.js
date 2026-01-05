/*
   Main Application Logic
   Handles UI interactions, data rendering, and tab navigation
*/

// Application state
let allRoutes = [];
let allSchedules = [];
let allDelays = [];
let allStations = [];

// ============================================================================
// INITIALIZATION
// ============================================================================

document.addEventListener('DOMContentLoaded', async () => {
    console.log('🚀 Public Transport Tracker initialized');

    // Check API health
    await updateApiStatus();

    // Load initial data
    await loadAllData();

    // Set up event listeners
    setupEventListeners();

    // Set up periodic health checks
    setInterval(updateApiStatus, 30000); // Every 30 seconds
});

/**
 * Update API health status indicator
 */
async function updateApiStatus() {
    const statusIndicator = document.getElementById('status-indicator');
    const statusText = document.getElementById('status-text');

    const isHealthy = await checkHealth();

    if (isHealthy) {
        statusIndicator.classList.add('healthy');
        statusIndicator.classList.remove('unhealthy');
        statusText.textContent = '✅ API Connected';
    } else {
        statusIndicator.classList.add('unhealthy');
        statusIndicator.classList.remove('healthy');
        statusText.textContent = '❌ API Disconnected';
    }
}

/**
 * Load all data from API
 */
async function loadAllData() {
    try {
        [allRoutes, allSchedules, allDelays, allStations] = await Promise.all([
            fetchRoutes(),
            fetchSchedules(),
            fetchDelays(true),
            fetchStations()
        ]);

        // Render initial content
        renderRoutes();
        renderSchedules();
        renderDelays();
        renderStations();
    } catch (error) {
        console.error('Error loading data:', error);
        showAlert('Failed to load data from API', 'error');
    }
}

/**
 * Set up event listeners
 */
function setupEventListeners() {
    // Search schedule functionality
    const searchSchedule = document.getElementById('search-schedule');
    if (searchSchedule) {
        searchSchedule.addEventListener('input', filterSchedules);
    }
}

// ============================================================================
// TAB MANAGEMENT
// ============================================================================

/**
 * Switch between tabs
 */
function switchTab(tabName) {
    // Hide all tabs
    document.querySelectorAll('.tab-content').forEach(tab => {
        tab.classList.remove('active');
    });

    // Remove active class from all nav links
    document.querySelectorAll('.nav-link').forEach(link => {
        link.classList.remove('active');
    });

    // Show selected tab
    const tabId = `${tabName}-tab`;
    const tab = document.getElementById(tabId);
    if (tab) {
        tab.classList.add('active');
    }

    // Add active class to clicked nav link
    event.target.classList.add('active');
}

// ============================================================================
// ROUTES SECTION
// ============================================================================

/**
 * Render all routes
 */
function renderRoutes() {
    const container = document.getElementById('routes-list');

    if (allRoutes.length === 0) {
        container.innerHTML = `
            <div class="empty-state">
                <div class="empty-state-icon">🚌</div>
                <h3>No routes found</h3>
                <p>Start by adding a new route</p>
            </div>
        `;
        return;
    }

    container.innerHTML = allRoutes.map(route => `
        <div class="route-card">
            <div class="card-header">
                <h3 class="card-title">${escapeHtml(route.route_name)}</h3>
                <span class="badge ${route.route_type === 'bus' ? 'badge-bus' : 'badge-train'}">
                    ${route.route_type.toUpperCase()}
                </span>
            </div>
            <div class="card-info">
                <div class="info-row">
                    <span class="info-label">Operator:</span>
                    <span class="info-value">${route.operator || 'N/A'}</span>
                </div>
                <div class="info-row">
                    <span class="info-label">From:</span>
                    <span class="info-value">${escapeHtml(route.start_station)}</span>
                </div>
                <div class="info-row">
                    <span class="info-label">To:</span>
                    <span class="info-value">${escapeHtml(route.end_station)}</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Route ID:</span>
                    <span class="info-value">#${route.route_id}</span>
                </div>
            </div>
            <div style="margin-top: 15px; display: flex; gap: 10px;">
                <button class="btn btn-primary" onclick="viewRouteSchedules(${route.route_id})">
                    View Schedules
                </button>
                <button class="btn btn-secondary" onclick="viewRouteDelays(${route.route_id})">
                    View Delays
                </button>
            </div>
        </div>
    `).join('');
}

/**
 * Toggle add route form
 */
function toggleAddRoute() {
    const form = document.getElementById('add-route-form');
    form.classList.toggle('hidden');
}

/**
 * Add new route
 */
async function addRoute(event) {
    event.preventDefault();

    const routeData = {
        route_name: document.getElementById('route_name').value,
        route_type: document.getElementById('route_type').value,
        operator: document.getElementById('operator').value,
        start_station: document.getElementById('start_station').value,
        end_station: document.getElementById('end_station').value
    };

    try {
        await createRoute(routeData);
        showAlert('Route created successfully!', 'success');

        // Reset form and reload data
        event.target.reset();
        toggleAddRoute();
        allRoutes = await fetchRoutes();
        renderRoutes();
    } catch (error) {
        showAlert('Error creating route: ' + error.message, 'error');
    }
}

/**
 * View schedules for a specific route
 */
async function viewRouteSchedules(routeId) {
    try {
        const schedules = await getRouteSchedules(routeId);
        switchTab('schedules');

        // Filter to show only this route's schedules
        const container = document.getElementById('schedules-list');
        if (schedules.length === 0) {
            container.innerHTML = '<p class="empty-state">No schedules found for this route</p>';
            return;
        }

        renderSchedulesList(schedules);
    } catch (error) {
        showAlert('Error loading schedules: ' + error.message, 'error');
    }
}

/**
 * Toggle add schedule form visibility
 */
function toggleAddSchedule() {
    const form = document.getElementById('add-schedule-form');
    form.classList.toggle('hidden');
}

/**
 * Add new schedule
 */
async function addSchedule(e) {
    e.preventDefault();

    const form = e.target;

    const scheduleData = {
        route_id: Number(form.route_id.value),
        departure_station_id: Number(form.departure_station_id.value),
        arrival_station_id: Number(form.arrival_station_id.value),
        arrival_time: form.arrival_time.value,
        departure_time: form.departure_time.value,
        day_of_week: form.day_of_week.value
    };

    console.log("📤 Sending schedule:", scheduleData);

    if (!Number.isFinite(scheduleData.route_id) || scheduleData.route_id <= 0) {
        showAlert('Please enter a valid Route ID', 'error');
        return;
    }
    if (!Number.isFinite(scheduleData.departure_station_id) || scheduleData.departure_station_id <= 0) {
        showAlert('Please enter a valid Departure Station ID', 'error');
        return;
    }
    if (!Number.isFinite(scheduleData.arrival_station_id) || scheduleData.arrival_station_id <= 0) {
        showAlert('Please enter a valid Arrival Station ID', 'error');
        return;
    }

    try {
        await createSchedule(scheduleData);
        showAlert('Schedule created successfully!', 'success');

        // Reset form and reload data
        form.reset();
        toggleAddSchedule();
        allSchedules = await fetchSchedules();
        renderSchedulesList(allSchedules);
    } catch (error) {
        showAlert('Error creating schedule: ' + error.message, 'error');
    }
}

/**
 * View delays for a specific route
 */
async function viewRouteDelays(routeId) {
    try {
        const delays = await fetchDelays(true, routeId);
        switchTab('delays');
        renderDelaysList(delays);
    } catch (error) {
        showAlert('Error loading delays: ' + error.message, 'error');
    }
}

// ============================================================================
// SCHEDULES SECTION
// ============================================================================

/**
 * Render all schedules
 */
function renderSchedules() {
    renderSchedulesList(allSchedules);
}

/**
 * Render schedules list
 */
function renderSchedulesList(schedules) {
    const container = document.getElementById('schedules-list');

    if (schedules.length === 0) {
        container.innerHTML = `
            <div class="empty-state">
                <div class="empty-state-icon">📅</div>
                <h3>No schedules found</h3>
            </div>
        `;
        return;
    }

    const table = `
        <table>
            <thead>
                <tr>
                    <th>Route</th>
                    <th>From</th>
                    <th>To</th>
                    <th>Departure</th>
                    <th>Arrival</th>
                    <th>Day</th>
                    <th>Frequency (min)</th>
                </tr>
            </thead>
            <tbody>
                ${schedules.map(schedule => `
                    <tr onclick="viewScheduleDetails(${schedule.schedule_id})" style="cursor: pointer;">
                        <td><strong>${escapeHtml(schedule.route_name)}</strong></td>
                        <td>${escapeHtml(schedule.departure_station)}</td>
                        <td>${escapeHtml(schedule.arrival_station)}</td>
                        <td>${schedule.departure_time}</td>
                        <td>${schedule.arrival_time}</td>
                        <td>${schedule.day_of_week || 'All'}</td>
                        <td>${schedule.frequency}</td>
                    </tr>
                `).join('')}
            </tbody>
        </table>
    `;

    container.innerHTML = table;
}

/**
 * Filter schedules by day
 */
async function filterSchedules() {
    const dayOfWeek = document.getElementById('day-filter').value;
    const searchQuery = document.getElementById('search-schedule').value.toLowerCase();

    let filtered = allSchedules;

    if (dayOfWeek) {
        filtered = filtered.filter(s => s.day_of_week === dayOfWeek);
    }

    if (searchQuery) {
        filtered = filtered.filter(s =>
            s.route_name.toLowerCase().includes(searchQuery) ||
            s.departure_station.toLowerCase().includes(searchQuery) ||
            s.arrival_station.toLowerCase().includes(searchQuery)
        );
    }

    renderSchedulesList(filtered);
}

/**
 * View schedule details and delays
 */
async function viewScheduleDetails(scheduleId) {
    try {
        const schedule = await getSchedule(scheduleId);
        const delays = await getScheduleDelays(scheduleId);

        alert(`
Schedule #${schedule.schedule_id}
Route: ${schedule.route_name}
${schedule.departure_station} → ${schedule.arrival_station}
Time: ${schedule.departure_time} - ${schedule.arrival_time}
Day: ${schedule.day_of_week || 'All days'}
Frequency: Every ${schedule.frequency} minutes

Active Delays: ${delays.filter(d => d.is_active).length}
        `);
    } catch (error) {
        showAlert('Error loading schedule details: ' + error.message, 'error');
    }
}

// ============================================================================
// DELAYS SECTION
// ============================================================================

/**
 * Render all delays
 */
function renderDelays() {
    renderDelaysList(allDelays);
}

/**
 * Render delays list
 */
function renderDelaysList(delays) {
    const container = document.getElementById('delays-list');

    if (delays.length === 0) {
        container.innerHTML = `
            <div class="empty-state">
                <div class="empty-state-icon">✅</div>
                <h3>No active delays</h3>
                <p>All services are running on schedule</p>
            </div>
        `;
        return;
    }

    container.innerHTML = delays.map(delay => `
        <div class="delay-card">
            <div class="card-header">
                <h3 class="card-title">${escapeHtml(delay.route_name)}</h3>
                <span class="badge badge-active">DELAY</span>
            </div>
            <div class="card-info">
                <div class="info-row">
                    <span class="info-label">Delay:</span>
                    <span class="info-value" style="color: var(--danger-color); font-weight: bold;">
                        ${delay.delay_minutes} minutes
                    </span>
                </div>
                <div class="info-row">
                    <span class="info-label">Scheduled Time:</span>
                    <span class="info-value">${delay.departure_time}</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Reason:</span>
                    <span class="info-value">${delay.reason || 'Not specified'}</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Reported:</span>
                    <span class="info-value">${new Date(delay.reported_at).toLocaleString()}</span>
                </div>
            </div>
            <div style="margin-top: 15px;">
                <button class="btn btn-success" onclick="resolveDelay(${delay.delay_id})">
                    Mark as Resolved
                </button>
            </div>
        </div>
    `).join('');
}

/**
 * Toggle report delay form
 */
function toggleReportDelay() {
    const form = document.getElementById('report-delay-form');
    form.classList.toggle('hidden');
}

/**
 * Report a new delay
 */
async function reportDelay(event) {
    event.preventDefault();

    const delayData = {
        schedule_id: parseInt(document.getElementById('delay_schedule_id').value),
        delay_minutes: parseInt(document.getElementById('delay_minutes').value),
        reason: document.getElementById('delay_reason').value
    };

    try {
        await apiPost('/delays', delayData);
        showAlert('Delay reported successfully!', 'success');

        // Reset form and reload data
        event.target.reset();
        toggleReportDelay();
        allDelays = await fetchDelays(true);
        renderDelays();
    } catch (error) {
        showAlert('Error reporting delay: ' + error.message, 'error');
    }
}

/**
 * Mark delay as resolved
 */
async function resolveDelay(delayId) {
    try {
        await updateDelay(delayId, false);
        showAlert('Delay marked as resolved', 'success');

        allDelays = await fetchDelays(true);
        renderDelays();
    } catch (error) {
        showAlert('Error resolving delay: ' + error.message, 'error');
    }
}

// ============================================================================
// STATIONS SECTION
// ============================================================================

/**
 * Render all stations
 */
function renderStations() {
    const container = document.getElementById('stations-list');

    if (allStations.length === 0) {
        container.innerHTML = `
            <div class="empty-state">
                <div class="empty-state-icon">🏢</div>
                <h3>No stations found</h3>
                <p>Start by adding a new station</p>
            </div>
        `;
        return;
    }

    container.innerHTML = allStations.map(station => `
        <div class="station-card">
            <div class="card-header">
                <h3 class="card-title">${escapeHtml(station.station_name)}</h3>
                <span class="badge ${station.station_type === 'bus_stop' ? 'badge-bus' : 'badge-train'}">
                    ${station.station_type === 'bus_stop' ? '🚌 Bus' : '🚆 Train'}
                </span>
            </div>
            <div class="card-info">
                ${station.address ? `
                    <div class="info-row">
                        <span class="info-label">Address:</span>
                        <span class="info-value">${escapeHtml(station.address)}</span>
                    </div>
                ` : ''}
                ${station.latitude && station.longitude ? `
                    <div class="info-row">
                        <span class="info-label">Location:</span>
                        <span class="info-value">${station.latitude.toFixed(6)}, ${station.longitude.toFixed(6)}</span>
                    </div>
                ` : ''}
                <div class="info-row">
                    <span class="info-label">Station ID:</span>
                    <span class="info-value">#${station.station_id}</span>
                </div>
            </div>
        </div>
    `).join('');
}

/**
 * Toggle add station form
 */
function toggleAddStation() {
    const form = document.getElementById('add-station-form');
    form.classList.toggle('hidden');
}

/**
 * Add new station
 */
async function addStation(event) {
    event.preventDefault();

    const stationData = {
        station_name: document.getElementById('station_name').value,
        station_type: document.getElementById('station_type').value,
        address: document.getElementById('station_address').value,
        latitude: parseFloat(document.getElementById('station_latitude').value) || null,
        longitude: parseFloat(document.getElementById('station_longitude').value) || null
    };

    try {
        await createStation(stationData);
        showAlert('Station created successfully!', 'success');

        // Reset form and reload data
        event.target.reset();
        toggleAddStation();
        allStations = await fetchStations();
        renderStations();
    } catch (error) {
        showAlert('Error creating station: ' + error.message, 'error');
    }
}

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

/**
 * Show alert message
 */
function showAlert(message, type = 'info') {
    const alertDiv = document.createElement('div');
    alertDiv.className = `alert alert-${type}`;
    alertDiv.innerHTML = `
        <span>${escapeHtml(message)}</span>
        <button onclick="this.parentElement.remove()" style="margin-left: auto; background: none; border: none; color: inherit; cursor: pointer; font-size: 1.2rem;">×</button>
    `;

    const container = document.querySelector('.main-content');
    if (container) {
        container.insertBefore(alertDiv, container.firstChild);

        // Auto-remove after 5 seconds
        setTimeout(() => alertDiv.remove(), 5000);
    }
}

/**
 * Escape HTML to prevent XSS
 */
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

/**
 * Format date/time
 */
function formatDateTime(dateString) {
    return new Date(dateString).toLocaleString();
}

/**
 * Format time only
 */
function formatTime(timeString) {
    return timeString.substring(0, 5); // HH:MM
}
