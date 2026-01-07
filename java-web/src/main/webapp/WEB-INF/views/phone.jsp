<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
    <%@ taglib prefix="c" uri="jakarta.tags.core" %>
        <!DOCTYPE html>
        <html lang="zh-CN">

        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>${title} | Phone Mode</title>
            <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
            <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
            <style>
                /* Phone Mode Specific Styles */
                .hero-display {
                    font-family: 'Cinzel', serif;
                    font-size: clamp(1.5rem, 4vw, 4rem);
                    color: white;
                    text-align: center;
                    margin-bottom: 1rem;
                    text-shadow: 0 0 20px rgba(255, 255, 255, 0.5);
                    min-height: 60px;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    letter-spacing: 0.15em;
                    word-break: break-all;
                    overflow-wrap: break-word;
                    padding: 0 1rem;
                    max-width: 100%;
                }

                .session-info {
                    position: absolute;
                    top: 1rem;
                    right: 2rem;
                    color: var(--text-sub);
                    font-family: var(--font-body);
                    text-transform: uppercase;
                    letter-spacing: 0.1em;
                    font-size: 0.75rem;
                    opacity: 0.7;
                    z-index: 10;
                }

                .stats-box-container {
                    display: grid;
                    grid-template-columns: repeat(3, 1fr);
                    gap: 1px;
                    background: var(--border-color);
                    border: 1px solid var(--border-color);
                    margin-bottom: 2rem;
                    max-width: 800px;
                    width: 100%;
                }

                .stat-item {
                    background: rgba(0, 0, 0, 0.5);
                    padding: 1.5rem;
                    text-align: center;
                }

                .stat-val {
                    font-size: 1.5rem;
                    color: white;
                    margin-bottom: 0.5rem;
                }

                .stat-label {
                    font-size: 0.7rem;
                    color: var(--text-sub);
                    text-transform: uppercase;
                }

                .history-list {
                    width: 100%;
                    max-width: 800px;
                    height: 250px;
                    overflow-y: auto;
                    border: 1px solid var(--border-color);
                    background: rgba(0, 0, 0, 0.3);
                    margin-bottom: 2rem;
                    scrollbar-width: thin;
                    scrollbar-color: var(--border-color) transparent;
                }

                .log-table {
                    width: 100%;
                    border-collapse: collapse;
                    font-family: monospace;
                    font-size: 0.8rem;
                }

                .log-table th {
                    position: sticky;
                    top: 0;
                    background: #111;
                    padding: 8px;
                    text-align: left;
                    border-bottom: 2px solid var(--border-color);
                    color: var(--text-sub);
                    text-transform: uppercase;
                    font-size: 0.7rem;
                    z-index: 10;
                }

                .log-table td {
                    padding: 8px;
                    border-bottom: 1px solid rgba(255, 255, 255, 0.05);
                    color: #ccc;
                }

                .log-row {
                    transition: background 0.2s;
                }

                .log-row:hover {
                    background: rgba(255, 255, 255, 0.05);
                }

                .log-status-ok {
                    color: #4aa3df !important;
                    font-weight: bold;
                }

                .log-status-fail {
                    color: #ff4d4d !important;
                    font-weight: bold;
                }

                .log-header-actions {
                    display: flex;
                    justify-content: space-between;
                    align-items: center;
                    margin-bottom: 0.5rem;
                }

                .log-btn {
                    background: transparent;
                    border: 1px solid var(--border-color);
                    color: var(--text-sub);
                    padding: 2px 8px;
                    font-size: 0.7rem;
                    cursor: pointer;
                    transition: 0.2s;
                }

                .log-btn:hover {
                    border-color: white;
                    color: white;
                }

                .action-btns {
                    display: grid;
                    grid-template-columns: 1fr 1fr;
                    gap: 10px;
                    margin-bottom: 1rem;
                }

                .btn-secondary {
                    background: transparent;
                    border: 1px solid var(--border-color);
                    color: var(--text-sub);
                    padding: 0.8rem;
                    cursor: pointer;
                    transition: 0.3s;
                }

                .btn-secondary:hover {
                    border-color: white;
                    color: white;
                }
            </style>
        </head>

        <body>
            <div class="split-layout">
                <!-- LEFT: Visual Stage -->
                <div class="visual-stage">
                    <div class="hero-display" id="phoneNumberDisplay">-</div>
                    <div class="session-info" id="sessionInfo">Session Idle</div>

                    <div class="stats-box-container" id="statsGrid" style="display:none; margin: 0 auto 2rem auto;">
                        <div class="stat-item">
                            <div class="stat-val" id="totalCount">0</div>
                            <div class="stat-label">Total Inputs</div>
                        </div>
                        <div class="stat-item">
                            <div class="stat-val" id="successCount">0</div>
                            <div class="stat-label">Success</div>
                        </div>
                        <div class="stat-item">
                            <div class="stat-val" id="accuracyRate">0%</div>
                            <div class="stat-label">Accuracy</div>
                        </div>
                    </div>

                    <div style="display:flex; gap:1rem; margin: 0 auto 2rem auto; max-width:900px;">
                        <div class="chart-card" style="flex:1;">
                            <div class="chart-title">TIME DOMAIN</div>
                            <div style="width:100%; height:150px;"><canvas id="waveformChart"></canvas></div>
                        </div>
                        <div class="chart-card" style="flex:1;">
                            <div class="chart-title">FREQUENCY SPECTRUM</div>
                            <div style="width:100%; height:150px;"><canvas id="energyChart"></canvas></div>
                        </div>
                    </div>

                    <div style="width:100%; max-width:800px; margin: 0 auto;">
                        <div class="log-header-actions">
                            <div class="section-title" style="margin:0;">Input Log</div>
                            <div style="display:flex; gap:5px;">
                                <button class="log-btn" onclick="exportLog()">Export CSV</button>
                                <button class="log-btn" onclick="clearLog()">Clear UI</button>
                            </div>
                        </div>
                        <div class="history-list">
                            <table class="log-table">
                                <thead>
                                    <tr>
                                        <th>Time</th>
                                        <th>In</th>
                                        <th>Out</th>
                                        <th>SNR</th>
                                        <th>Mode</th>
                                        <th>Status</th>
                                    </tr>
                                </thead>
                                <tbody id="historyList">
                                    <!-- Log rows will be inserted here -->
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>

                <!-- RIGHT: Control Panel -->
                <div class="control-sidebar">
                    <h1 class="brand-title">ReragoAliNa<span style="font-weight:300; opacity:0.5;">Phone</span></h1>

                    <div class="nav-menu">
                        <div class="section-title">Navigation</div>
                        <a href="${pageContext.request.contextPath}/" class="nav-link">Experiment Mode</a>
                        <a href="${pageContext.request.contextPath}/phone" class="nav-link active">Phone Mode</a>
                        <a href="${pageContext.request.contextPath}/analyze" class="nav-link">Audio Analysis</a>
                    </div>

                    <div class="control-group">
                        <div class="section-title">Session Control</div>
                        <div class="action-btns">
                            <button id="startBtn" class="btn-primary"
                                style="margin:0; background: white; color: black;">Start</button>
                            <button id="endBtn" class="btn-primary"
                                style="margin:0; background: #333; color: white; border:1px solid #555;"
                                disabled>End</button>
                        </div>
                    </div>

                    <div class="control-group">
                        <div class="section-title">Dialpad</div>
                        <div class="numpad-grid" id="phoneNumpad">
                            <!-- Using data-key as per original JS requirement -->
                            <div class="numpad-key" data-key="1">1</div>
                            <div class="numpad-key" data-key="2">2</div>
                            <div class="numpad-key" data-key="3">3</div>
                            <div class="numpad-key" data-key="A">A</div>
                            <div class="numpad-key" data-key="4">4</div>
                            <div class="numpad-key" data-key="5">5</div>
                            <div class="numpad-key" data-key="6">6</div>
                            <div class="numpad-key" data-key="B">B</div>
                            <div class="numpad-key" data-key="7">7</div>
                            <div class="numpad-key" data-key="8">8</div>
                            <div class="numpad-key" data-key="9">9</div>
                            <div class="numpad-key" data-key="C">C</div>
                            <div class="numpad-key" data-key="*">*</div>
                            <div class="numpad-key" data-key="0">0</div>
                            <div class="numpad-key" data-key="#">#</div>
                            <div class="numpad-key" data-key="D">D</div>
                        </div>
                    </div>

                    <div class="control-group">
                        <div class="action-btns">
                            <button id="backspaceBtn" class="btn-secondary">Backspace</button>
                            <button id="clearBtn" class="btn-secondary">Clear</button>
                        </div>
                        <div style="margin-top:10px; display:flex; align-items:center; gap:8px; font-size:0.8rem;">
                            <input type="checkbox" id="hwModeCheck">
                            <label for="hwModeCheck" style="cursor:pointer; color:var(--text-sub);">Hardware Only (No
                                Web Save)</label>
                        </div>
                    </div>

                    <div class="control-group">
                        <div class="section-title">Signal Settings</div>
                        <label>Noise</label>
                        <select id="noiseType">
                            <optgroup label="Synthetic">
                                <option value="GAUSSIAN">Gaussian</option>
                                <option value="PINK">Pink</option>
                                <option value="IMPULSE">Impulse</option>
                                <option value="UNIFORM">Uniform</option>
                            </optgroup>
                            <optgroup label="Environmental (ESC-50)">
                                <option value="RAIN">Rain 🌧️</option>
                                <option value="WIND">Wind 💨</option>
                                <option value="THUNDERSTORM">Thunderstorm ⛈️</option>
                                <option value="DOG">Dog Barking 🐕</option>
                                <option value="CAR_HORN">Car Horn 🚗</option>
                                <option value="ENGINE">Engine 🏎️</option>
                                <option value="HELICOPTER">Helicopter 🚁</option>
                                <option value="TRAIN">Train 🚂</option>
                                <option value="CHAINSAW">Chainsaw 🪓</option>
                                <option value="SIREN">Siren 🚨</option>
                                <option value="KEYBOARD_TYPING">Keyboard ⌨️</option>
                                <option value="VACUUM_CLEANER">Vacuum Cleaner 🧹</option>
                                <option value="CLOCK_TICK">Clock Tick ⏰</option>
                                <option value="CRACKLING_FIRE">Crackling Fire 🔥</option>
                            </optgroup>
                        </select>
                        <br><br>
                        <label>SNR: <span id="snrVal">10</span> dB</label>
                        <input type="range" id="snrRange" min="-20" max="30" value="10" step="1"
                            style="padding:0; height:4px; margin:10px 0;">
                    </div>

                    <div id="realtimeFeedback"
                        style="display:none; margin-top:1rem; padding:1rem; border:1px solid var(--border-color); text-align:center;">
                        <div style="font-size:0.8rem; color:var(--text-sub);">Last Detection (Adaptive)</div>
                        <div
                            style="display:flex; justify-content:center; gap:10px; font-size:1.5rem; margin-top:0.5rem;">
                            <span id="pressedKey" style="color:white;">-</span>
                            <span>&rarr;</span>
                            <span id="identifiedKey" style="color:white;">-</span>
                        </div>
                        <div id="matchIndicator" style="margin-top:0.5rem; font-size:0.8rem;"></div>
                        <div id="adaptiveInfo" style="margin-top:0.3rem; font-size:0.7rem; color:var(--text-sub);">
                        </div>
                    </div>

                </div>
            </div>

            <script>
                var sessionActive = false;
                var dialedNumber = '';
                var totalCount = 0, successCount = 0;
                var energyChart = null;

                const audioContext = new (window.AudioContext || window.webkitAudioContext)();
                const DTMF_FREQS = {
                    '1': [697, 1209], '2': [697, 1336], '3': [697, 1477], 'A': [697, 1633],
                    '4': [770, 1209], '5': [770, 1336], '6': [770, 1477], 'B': [770, 1633],
                    '7': [852, 1209], '8': [852, 1336], '9': [852, 1477], 'C': [852, 1633],
                    '*': [941, 1209], '0': [941, 1336], '#': [941, 1477], 'D': [941, 1633]
                };

                function playDtmfTone(key, duration = 0.2) {
                    const freqs = DTMF_FREQS[key];
                    if (!freqs) return;
                    if (audioContext.state === 'suspended') audioContext.resume();

                    const now = audioContext.currentTime;
                    const gainNode = audioContext.createGain();
                    gainNode.connect(audioContext.destination);
                    gainNode.gain.setValueAtTime(0.3, now);
                    gainNode.gain.exponentialRampToValueAtTime(0.01, now + duration);

                    [freqs[0], freqs[1]].forEach(freq => {
                        const osc = audioContext.createOscillator();
                        osc.type = 'sine';
                        osc.frequency.setValueAtTime(freq, now);
                        osc.connect(gainNode);
                        osc.start(now);
                        osc.stop(now + duration);
                    });
                }

                // 播放加噪后的波形数据
                function playNoisyWaveform(waveformData, sampleRate = 8000) {
                    if (!waveformData || waveformData.length === 0) return;
                    if (audioContext.state === 'suspended') audioContext.resume();

                    const buffer = audioContext.createBuffer(1, waveformData.length, sampleRate);
                    const channelData = buffer.getChannelData(0);

                    let maxAbs = 0;
                    for (let i = 0; i < waveformData.length; i++) {
                        maxAbs = Math.max(maxAbs, Math.abs(waveformData[i]));
                    }
                    const scale = maxAbs > 0 ? 0.5 / maxAbs : 1;
                    for (let i = 0; i < waveformData.length; i++) {
                        channelData[i] = waveformData[i] * scale;
                    }

                    const source = audioContext.createBufferSource();
                    source.buffer = buffer;
                    source.connect(audioContext.destination);
                    source.start();
                }

                document.getElementById('snrRange').addEventListener('input', e => {
                    document.getElementById('snrVal').innerText = e.target.value;
                });

                document.getElementById('startBtn').addEventListener('click', async () => {
                    try {
                        const res = await fetch('${pageContext.request.contextPath}/api/dtmf/phone/start', { method: 'POST' });
                        const data = await res.json();
                        if (data.success) {  // Fixed: was data.status === 'started'
                            sessionActive = true;
                            lastKeyTime = Date.now(); // Ignore any events that happened before clicking start
                            dialedNumber = '';
                            totalCount = 0;
                            successCount = 0;
                            document.getElementById('phoneNumberDisplay').innerText = '-';
                            document.getElementById('sessionInfo').innerText = 'Session Active: ' + data.sessionName;
                            document.getElementById('sessionInfo').style.color = '#4aa3df';
                            document.getElementById('startBtn').disabled = true;
                            document.getElementById('endBtn').disabled = false;
                            document.getElementById('realtimeFeedback').style.display = 'block';
                            document.getElementById('statsGrid').style.display = 'grid';
                            document.getElementById('historyList').innerHTML = '';
                            updateStats();
                        }
                    } catch (e) { console.error(e); }
                });

                document.getElementById('endBtn').addEventListener('click', async () => {
                    await fetch('${pageContext.request.contextPath}/api/dtmf/phone/end', { method: 'POST' });
                    sessionActive = false;
                    document.getElementById('sessionInfo').innerText = 'Session Ended - Total ' + totalCount + ' Events';
                    document.getElementById('sessionInfo').style.color = 'var(--text-sub)';
                    document.getElementById('startBtn').disabled = false;
                    document.getElementById('endBtn').disabled = true;
                });

                document.getElementById('clearBtn').addEventListener('click', () => {
                    dialedNumber = '';
                    document.getElementById('phoneNumberDisplay').innerText = '-';
                });

                document.getElementById('backspaceBtn').addEventListener('click', () => {
                    dialedNumber = dialedNumber.slice(0, -1);
                    document.getElementById('phoneNumberDisplay').innerText = dialedNumber || '-';
                });

                function updateStats() {
                    document.getElementById('totalCount').innerText = totalCount;
                    document.getElementById('successCount').innerText = successCount;
                    const rate = totalCount > 0 ? (successCount / totalCount * 100).toFixed(1) : 0;
                    document.getElementById('accuracyRate').innerText = rate + '%';
                }

                function clearLog() {
                    document.getElementById('historyList').innerHTML = '';
                    totalCount = 0;
                    successCount = 0;
                    updateStats();
                }

                function exportLog() {
                    const rows = document.querySelectorAll('#historyList tr');
                    if (rows.length === 0) return;
                    let csv = 'Time,Target,Identified,SNR,Mode,Status\n';
                    rows.forEach(row => {
                        const cols = row.querySelectorAll('td');
                        csv += Array.from(cols).map(c => c.innerText).join(',') + '\n';
                    });
                    const blob = new Blob([csv], { type: 'text/csv' });
                    const url = window.URL.createObjectURL(blob);
                    const a = document.createElement('a');
                    a.setAttribute('hidden', '');
                    a.setAttribute('href', url);
                    a.setAttribute('download', 'dtmf_log_' + new Date().getTime() + '.csv');
                    document.body.appendChild(a);
                    a.click();
                    document.body.removeChild(a);
                }

                function updateEnergyChart(energies) {
                    const freqLabels = ['697', '770', '852', '941', '1209', '1336', '1477', '1633'];
                    if (energyChart) energyChart.destroy();
                    const ctx = document.getElementById('energyChart').getContext('2d');
                    energyChart = new Chart(ctx, {
                        type: 'bar',
                        data: {
                            labels: freqLabels.map(f => f + 'Hz'),
                            datasets: [{
                                data: energies || [],
                                backgroundColor: freqLabels.map((_, i) => i < 4 ? '#ffffff' : '#555555'),
                                borderRadius: 0,
                                barPercentage: 0.6
                            }]
                        },
                        options: {
                            responsive: true,
                            maintainAspectRatio: false,
                            plugins: { legend: { display: false } },
                            scales: {
                                y: { display: false },
                                x: { display: false }
                            }
                        }
                    });
                }

                var waveformChart = null;
                function updateWaveformChart(waveformData) {
                    if (!waveformData || waveformData.length === 0) return;
                    if (waveformChart) waveformChart.destroy();
                    const ctx = document.getElementById('waveformChart').getContext('2d');
                    const labels = waveformData.map((_, i) => i);
                    waveformChart = new Chart(ctx, {
                        type: 'line',
                        data: {
                            labels: labels,
                            datasets: [{
                                data: waveformData,
                                borderColor: '#4aa3df',
                                borderWidth: 1,
                                pointRadius: 0,
                                fill: false,
                                tension: 0
                            }]
                        },
                        options: {
                            responsive: true,
                            maintainAspectRatio: false,
                            plugins: { legend: { display: false } },
                            scales: {
                                y: { display: false },
                                x: { display: false }
                            },
                            animation: false
                        }
                    });
                }

                function handleKeyPressUI(key, updateNumber = true) {
                    const btn = document.querySelector('.numpad-key[data-key="' + key + '"]');
                    if (!btn) return;

                    // Visual feedback
                    btn.style.backgroundColor = 'white';
                    btn.style.color = 'black';
                    setTimeout(() => {
                        btn.style.backgroundColor = '';
                        btn.style.color = '';
                    }, 200);

                    // Update Display Number (only if updateNumber is true)
                    if (updateNumber) {
                        dialedNumber += key;
                        document.getElementById('phoneNumberDisplay').innerText = dialedNumber;
                    }

                    // Play Sound
                    playDtmfTone(key);
                }

                document.getElementById('phoneNumpad').querySelectorAll('.numpad-key').forEach(keyEl => {
                    keyEl.addEventListener('click', async () => {
                        if (!sessionActive) return;
                        const key = keyEl.dataset.key;

                        // Hardware Mode: ignore all web clicks
                        if (document.getElementById('hwModeCheck').checked) {
                            return;
                        }

                        // 1. Update UI immediately (without updating dialed number - will be done after backend response)
                        handleKeyPressUI(key, false);

                        // If Hardware Only mode is ON, skip sending data to backend
                        if (document.getElementById('hwModeCheck').checked) {
                            return;
                        }

                        // 2. Send to Backend
                        const snr = document.getElementById('snrRange').value;
                        const noiseType = document.getElementById('noiseType').value;

                        try {
                            const res = await fetch('${pageContext.request.contextPath}/api/dtmf/phone/press?key=' + encodeURIComponent(key) + '&duration=1.0&snr=' + snr + '&noiseType=' + noiseType + '&source=web', { method: 'POST' });
                            const data = await res.json();

                            // 播放加噪后的声音
                            if (data.noisyWaveform) {
                                playNoisyWaveform(data.noisyWaveform);
                            } else {
                                playDtmfTone(key); // 回退到纯净音
                            }

                            totalCount++;
                            const match = key === data.identified;
                            if (match) successCount++;
                            updateStats();

                            dialedNumber += data.identified || '?';
                            document.getElementById('phoneNumberDisplay').innerText = dialedNumber;
                            document.getElementById('pressedKey').innerText = key;
                            document.getElementById('identifiedKey').innerText = data.identified || '?';

                            const ind = document.getElementById('matchIndicator');
                            ind.innerText = match ? 'MATCH' : 'MISMATCH';
                            ind.style.color = match ? '#4aa3df' : '#ff4d4d';

                            // Display adaptive algorithm info
                            const adaptiveInfo = document.getElementById('adaptiveInfo');
                            const mode = data.mode || 'Unknown';
                            const duration = data.signalDuration ? data.signalDuration.toFixed(0) + 'ms' : '-';
                            const snrEst = data.snrEstimate ? data.snrEstimate.toFixed(1) + 'dB' : '-';
                            adaptiveInfo.innerText = mode + ' | Duration: ' + duration + ' | SNR Est: ' + snrEst;

                            // Rebuilt Log Logic
                            const now = new Date();
                            const timeStr = now.getHours().toString().padStart(2, '0') + ':' +
                                now.getMinutes().toString().padStart(2, '0') + ':' +
                                now.getSeconds().toString().padStart(2, '0') + '.' +
                                now.getMilliseconds().toString().padStart(3, '0');

                            const historyRow = document.createElement('tr');
                            historyRow.className = 'log-row';
                            historyRow.style.cursor = 'pointer';
                            historyRow.innerHTML = `
                                <td>\${timeStr}</td>
                                <td style="font-weight:bold; color:white;">\${key}</td>
                                <td style="font-weight:bold; color:\${match ? '#4aa3df' : '#ff4d4d'}">\${data.identified || '?'}</td>
                                <td>\${snrEst}</td>
                                <td style="opacity:0.6; font-size:0.75rem;">\${mode}</td>
                                <td class="\${match ? 'log-status-ok' : 'log-status-fail'}">\${match ? 'MATCH' : 'MISMATCH'}</td>
                            `;

                            // Store chart data for click-to-view
                            historyRow._chartData = {
                                energies: data.energies,
                                waveformSample: data.waveformSample
                            };
                            historyRow.addEventListener('click', function () {
                                document.querySelectorAll('#historyList tr').forEach(r => r.style.background = '');
                                this.style.background = 'rgba(74, 163, 223, 0.2)';
                                if (this._chartData.energies) updateEnergyChart(this._chartData.energies);
                                if (this._chartData.waveformSample) updateWaveformChart(this._chartData.waveformSample);
                            });

                            const historyList = document.getElementById('historyList');
                            historyList.insertBefore(historyRow, historyList.firstChild);

                            if (data.energies) updateEnergyChart(data.energies);
                            if (data.waveformSample) updateWaveformChart(data.waveformSample);
                        } catch (e) { console.error(e); }
                    });
                });
                // Auto Polling for Hardware events
                let lastKeyTime = 0;
                setInterval(async () => {
                    if (!sessionActive) return;
                    try {
                        const res = await fetch('${pageContext.request.contextPath}/api/dtmf/phone/last-key?since=' + lastKeyTime);
                        const data = await res.json();
                        if (data.hasNew) {
                            // Non-Hardware Mode: ignore all FPGA events
                            if (!document.getElementById('hwModeCheck').checked) {
                                return;
                            }

                            lastKeyTime = data.time;
                            const key = String(data.key);

                            // Only update UI, do NOT call backend again!
                            handleKeyPressUI(key);

                            // Add a simplified log entry for hardware event
                            const now = new Date();
                            const timeStr = now.getHours().toString().padStart(2, '0') + ':' +
                                now.getMinutes().toString().padStart(2, '0') + ':' +
                                now.getSeconds().toString().padStart(2, '0');

                            const historyRow = document.createElement('tr');
                            historyRow.className = 'log-row';
                            historyRow.style.cursor = 'pointer';
                            historyRow.innerHTML = `<td>\${timeStr}</td><td style="color:#4aa3df;font-weight:bold;">\${key}</td><td>(HW)</td><td>-</td><td>FPGA</td><td class="log-status-ok">RX</td>`;

                            // Store chart data for click-to-view
                            historyRow._chartData = {
                                energies: data.energies,
                                waveformSample: data.waveformSample
                            };
                            historyRow.addEventListener('click', function () {
                                document.querySelectorAll('#historyList tr').forEach(r => r.style.background = '');
                                this.style.background = 'rgba(74, 163, 223, 0.2)';
                                if (this._chartData.energies) updateEnergyChart(this._chartData.energies);
                                if (this._chartData.waveformSample) updateWaveformChart(this._chartData.waveformSample);
                            });

                            const list = document.getElementById('historyList');
                            list.insertBefore(historyRow, list.firstChild);

                            // Update stats for hardware events
                            totalCount++;
                            successCount++; // FPGA events are always considered successful
                            updateStats();

                            // Update charts from polling data
                            if (data.energies) updateEnergyChart(data.energies);
                            if (data.waveformSample) updateWaveformChart(data.waveformSample);
                        }
                    } catch (e) { }
                }, 200);
            </script>
        </body>

        </html>