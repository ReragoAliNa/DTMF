<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
    <%@ taglib prefix="c" uri="jakarta.tags.core" %>
        <!DOCTYPE html>
        <html lang="zh-CN">

        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>${title} | Audio Analysis</title>
            <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
            <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
            <style>
                /* Analyze Mode Specific Styles */

                /* Override visual-stage to NOT center content vertically */
                .visual-stage {
                    justify-content: flex-start !important;
                    padding-top: 2rem;
                }

                .session-list-container {
                    flex: 1;
                    overflow-y: auto;
                    border: 1px solid var(--border-color);
                    background: rgba(0, 0, 0, 0.3);
                    margin-bottom: 1rem;
                    min-height: 100px;
                    max-height: 600px;
                    height: 250px;
                    resize: vertical;
                }

                .session-item {
                    padding: 1rem;
                    border-bottom: 1px solid var(--border-color);
                    cursor: pointer;
                    transition: 0.3s;
                    display: flex;
                    justify-content: space-between;
                    align-items: center;
                }

                .session-item:hover {
                    background: rgba(255, 255, 255, 0.05);
                }

                .session-item.selected {
                    background: white;
                    color: black;
                }

                .session-item.selected .session-meta {
                    color: #555;
                }

                .session-item.multi-selected {
                    background: rgba(74, 163, 223, 0.15);
                    border-left: 3px solid #4aa3df;
                }

                .session-item.multi-selected .session-checkbox {
                    accent-color: #4aa3df;
                }

                .session-name {
                    font-size: 0.9rem;
                    font-weight: bold;
                }

                .session-meta {
                    font-size: 0.75rem;
                    color: var(--text-sub);
                }

                .analysis-hero {
                    text-align: center;
                    padding: 3rem 0;
                    border-bottom: 1px solid var(--border-color);
                    margin-bottom: 2rem;
                }

                .recognized-num {
                    font-family: 'Cinzel', serif;
                    font-size: 4rem;
                    color: white;
                    letter-spacing: 0.2em;
                    margin: 1rem 0;
                    text-shadow: 0 0 30px rgba(255, 255, 255, 0.3);
                }

                .accuracy-bar-container {
                    width: 80%;
                    height: 4px;
                    background: #333;
                    margin: 1rem auto;
                    position: relative;
                }

                .accuracy-bar-fill {
                    height: 100%;
                    background: white;
                    box-shadow: 0 0 10px white;
                    transition: width 1s ease-out;
                }

                .stats-row {
                    display: grid;
                    grid-template-columns: repeat(3, 1fr);
                    gap: 1rem;
                    text-align: center;
                    margin-bottom: 2rem;
                }

                .details-container {
                    flex: 1;
                    overflow-y: auto;
                    border: 1px solid var(--border-color);
                    background: rgba(0, 0, 0, 0.3);
                    margin-bottom: 2rem;
                    max-height: 400px;
                    scrollbar-width: thin;
                    scrollbar-color: var(--border-color) transparent;
                }

                .log-table {
                    width: 100%;
                    border-collapse: collapse;
                    font-family: monospace;
                    font-size: 0.75rem;
                    table-layout: fixed;
                }

                .log-table th {
                    position: sticky;
                    top: 0;
                    background: #111;
                    padding: 8px 5px;
                    text-align: left;
                    border-bottom: 2px solid var(--border-color);
                    color: var(--text-sub);
                    text-transform: uppercase;
                    font-size: 0.65rem;
                    z-index: 10;
                    white-space: nowrap;
                }

                .log-table td {
                    padding: 8px 5px;
                    border-bottom: 1px solid rgba(255, 255, 255, 0.05);
                    color: #ccc;
                    overflow: hidden;
                    text-overflow: ellipsis;
                    white-space: nowrap;
                }

                .log-table th:nth-child(1),
                .log-table td:nth-child(1) {
                    width: 28%;
                }

                .log-table th:nth-child(2),
                .log-table td:nth-child(2) {
                    width: 6%;
                    text-align: center;
                }

                .log-table th:nth-child(3),
                .log-table td:nth-child(3) {
                    width: 6%;
                    text-align: center;
                }

                .log-table th:nth-child(4),
                .log-table td:nth-child(4) {
                    width: 18%;
                }

                .log-table th:nth-child(5),
                .log-table td:nth-child(5) {
                    width: 11%;
                    text-align: center;
                }

                .log-table th:nth-child(6),
                .log-table td:nth-child(6) {
                    width: 11%;
                    text-align: center;
                }

                .log-table th:nth-child(7),
                .log-table td:nth-child(7) {
                    width: 10%;
                    text-align: center;
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
            </style>
        </head>

        <body>
            <div class="split-layout">
                <!-- LEFT: Visual Stage -->
                <div class="visual-stage">
                    <div id="initialState" style="text-align:center; color: var(--text-sub); margin-top: 20%;">
                        <div style="font-size: 3rem; margin-bottom: 1rem; opacity: 0.3;">📂</div>
                        <div>Select a session from the sidebar to analyze</div>
                    </div>

                    <div id="analysisResult" style="display:none; width: 100%; max-width: 900px; margin: 0 auto;">
                        <div class="analysis-hero">
                            <div style="color:var(--text-sub); letter-spacing: 0.2em; font-size:0.8rem;">DETECTED
                                SEQUENCE</div>
                            <div class="recognized-num" id="heroNumber">-</div>
                            <div style="color:var(--text-sub); letter-spacing: 0.1em; font-size:0.8rem;">CONFIDENCE
                                <span id="heroAccuracy" style="color:white;">0%</span>
                            </div>
                            <div class="accuracy-bar-container">
                                <div class="accuracy-bar-fill" id="accuracyBar" style="width: 0%"></div>
                            </div>
                        </div>

                        <div class="stats-row" style="grid-template-columns: repeat(4, 1fr);">
                            <div>
                                <div class="stat-val" id="statTotal">0</div>
                                <div class="stat-label">Audio Files</div>
                            </div>
                            <div>
                                <div class="stat-val" id="statSuccess">0</div>
                                <div class="stat-label">Identified</div>
                            </div>
                            <div>
                                <div class="stat-val" id="statFail">0</div>
                                <div class="stat-label">Failures</div>
                            </div>
                            <div>
                                <div class="stat-val" id="statAvgTime" style="color:#7ecf8e;">-</div>
                                <div class="stat-label">Avg Response</div>
                            </div>
                        </div>

                        <div class="chart-card">
                            <div class="chart-title">KEY FREQUENCY DISTRIBUTION</div>
                            <div style="width:100%; height:100%;"><canvas id="distributionChart"></canvas></div>
                        </div>

                        <div style="display:flex; gap:1rem; margin-top:2rem;">
                            <div class="chart-card" style="flex:1;">
                                <div class="chart-title">SELECTED FILE - TIME DOMAIN</div>
                                <div style="width:100%; height:150px;"><canvas id="analyzeWaveformChart"></canvas></div>
                            </div>
                            <div class="chart-card" style="flex:1;">
                                <div class="chart-title">SELECTED FILE - FREQUENCY SPECTRUM</div>
                                <div style="width:100%; height:150px;"><canvas id="analyzeEnergyChart"></canvas></div>
                            </div>
                        </div>
                        <div id="selectedFileInfo"
                            style="text-align:center; color:var(--text-sub); font-size:0.75rem; margin-top:0.5rem;">
                            Click a file in the log to view its waveform and spectrum
                        </div>

                        <div style="margin-top:2rem;">
                            <div class="section-title">Log Details</div>
                            <div class="details-container">
                                <table class="log-table">
                                    <thead>
                                        <tr>
                                            <th>File</th>
                                            <th>Ref</th>
                                            <th>Out</th>
                                            <th>Mode</th>
                                            <th>SNR</th>
                                            <th>Time</th>
                                            <th>Status</th>
                                        </tr>
                                    </thead>
                                    <tbody id="detailsList">
                                        <!-- Details items -->
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- RIGHT: Control Panel -->
                <div class="control-sidebar">
                    <h1 class="brand-title">ReragoAliNa<span style="font-weight:300; opacity:0.5;">Data</span></h1>

                    <div class="nav-menu">
                        <div class="section-title">Navigation</div>
                        <a href="${pageContext.request.contextPath}/" class="nav-link">Experiment Mode</a>
                        <a href="${pageContext.request.contextPath}/phone" class="nav-link">Phone Mode</a>
                        <a href="${pageContext.request.contextPath}/analyze" class="nav-link active">Audio Analysis</a>
                    </div>

                    <div class="control-group" style="display: flex; flex-direction: column; height: 60%;">
                        <div class="section-title">Session Explorer</div>
                        <div class="action-btns">
                            <button id="refreshBtn" class="btn-secondary" style="width:100%;">Refresh List</button>
                            <button id="selectAllBtn" class="btn-secondary" style="width:100%;">Select All</button>
                        </div>
                        <div id="selectionInfo"
                            style="font-size:0.75rem; color:var(--text-sub); text-align:center; margin:0.5rem 0; display:none;">
                            <span id="selectedCount">0</span> selected
                        </div>

                        <div class="session-list-container" id="sessionList">
                            <div style="padding:1rem; text-align:center; color:var(--text-sub); font-size:0.8rem;">Click
                                Refresh to load...</div>
                        </div>

                        <div class="control-group" style="margin-top:1rem;">
                            <div class="section-title">Detection Settings</div>
                            <label style="display:flex; align-items:center; gap:8px; margin-bottom:0.5rem;">
                                <input type="checkbox" id="adaptiveCheck" style="width:auto;">
                                Adaptive Mode (40ms-1000ms Auto)
                            </label>
                            <div id="manualDurationControl">
                                <label>Signal Duration: <span id="durationVal">1000</span> ms</label>
                                <input type="range" id="durationSlider" min="40" max="1000" value="1000" step="10"
                                    style="padding:0; height:4px; margin:10px 0;">
                                <div
                                    style="display:flex; justify-content:space-between; font-size:0.7rem; color:var(--text-sub);">
                                    <span>40ms (Fast)</span>
                                    <span>200ms (Standard)</span>
                                    <span>1000ms (Deep)</span>
                                </div>
                            </div>
                        </div>

                        <div class="action-btns" style="margin-top:0.5rem;">
                            <button id="analyzeBtn" class="btn-primary" style="margin:0;" disabled>Analyze</button>
                            <button id="deleteBtn" class="btn-secondary"
                                style="margin:0; color: #d9534f; border-color: #d9534f;" disabled>Delete (<span
                                    id="deleteCount">0</span>)</button>
                        </div>
                    </div>
                </div>
            </div>

            <script>
                var selectedSession = null;
                var selectedSessions = new Set();
                var distributionChart = null;

                // Duration slider handler
                document.getElementById('durationSlider').addEventListener('input', e => {
                    document.getElementById('durationVal').innerText = e.target.value;
                });

                // Adaptive mode checkbox handler
                document.getElementById('adaptiveCheck').addEventListener('change', e => {
                    const manualControl = document.getElementById('manualDurationControl');
                    manualControl.style.opacity = e.target.checked ? '0.3' : '1';
                    manualControl.style.pointerEvents = e.target.checked ? 'none' : 'auto';
                });

                function updateSelectionUI() {
                    const count = selectedSessions.size;
                    document.getElementById('selectedCount').innerText = count;
                    document.getElementById('deleteCount').innerText = count;
                    document.getElementById('selectionInfo').style.display = count > 0 ? 'block' : 'none';
                    document.getElementById('deleteBtn').disabled = count === 0;
                    // Analyze button only enabled for single selection
                    document.getElementById('analyzeBtn').disabled = selectedSession === null;
                }

                document.getElementById('selectAllBtn').addEventListener('click', () => {
                    const items = document.querySelectorAll('#sessionList .session-item');
                    const allSelected = selectedSessions.size === items.length && items.length > 0;

                    if (allSelected) {
                        // Deselect all
                        selectedSessions.clear();
                        items.forEach(item => {
                            item.classList.remove('multi-selected');
                            item.querySelector('.session-checkbox').checked = false;
                        });
                        document.getElementById('selectAllBtn').innerText = 'Select All';
                    } else {
                        // Select all
                        items.forEach(item => {
                            selectedSessions.add(item.dataset.name);
                            item.classList.add('multi-selected');
                            item.querySelector('.session-checkbox').checked = true;
                        });
                        document.getElementById('selectAllBtn').innerText = 'Deselect All';
                    }
                    updateSelectionUI();
                });

                document.getElementById('refreshBtn').addEventListener('click', async () => {
                    const list = document.getElementById('sessionList');
                    list.innerHTML = '<div style="padding:1rem; text-align:center;">Loading...</div>';
                    selectedSessions.clear();
                    selectedSession = null;
                    updateSelectionUI();

                    try {
                        const res = await fetch('${pageContext.request.contextPath}/api/dtmf/phone/sessions');
                        const data = await res.json();

                        if (data.sessions && data.sessions.length > 0) {
                            list.innerHTML = data.sessions.map(s => `
                        <div class="session-item" data-name="\${s.name}">
                            <input type="checkbox" class="session-checkbox" style="width:auto; margin-right:10px; cursor:pointer;">
                            <div style="flex:1;">
                                <div class="session-name">\${s.name}</div>
                                <div class="session-meta">\${s.fileCount} files</div>
                            </div>
                            <div style="font-size:0.7rem; color:var(--text-sub);">▶</div>
                        </div>
                    `).join('');

                            list.querySelectorAll('.session-item').forEach(item => {
                                const checkbox = item.querySelector('.session-checkbox');

                                // Checkbox click for multi-select
                                checkbox.addEventListener('click', (e) => {
                                    e.stopPropagation();
                                    const name = item.dataset.name;
                                    if (checkbox.checked) {
                                        selectedSessions.add(name);
                                        item.classList.add('multi-selected');
                                    } else {
                                        selectedSessions.delete(name);
                                        item.classList.remove('multi-selected');
                                    }
                                    updateSelectionUI();
                                });

                                // Row click for single select (analyze)
                                item.addEventListener('click', (e) => {
                                    if (e.target === checkbox) return;
                                    list.querySelectorAll('.session-item').forEach(i => i.classList.remove('selected'));
                                    item.classList.add('selected');
                                    selectedSession = item.dataset.name;
                                    updateSelectionUI();
                                });
                            });
                        } else {
                            list.innerHTML = '<div style="padding:1rem; text-align:center; color:var(--text-sub);">No sessions found.<br>Go to Phone Mode to create one.</div>';
                        }
                    } catch (err) {
                        list.innerHTML = '<div style="padding:1rem; text-align:center; color:#d9534f;">Error loading list.</div>';
                    }
                    document.getElementById('selectAllBtn').innerText = 'Select All';
                });

                document.getElementById('deleteBtn').addEventListener('click', async () => {
                    const toDelete = selectedSessions.size > 0 ? Array.from(selectedSessions) : (selectedSession ? [selectedSession] : []);
                    if (toDelete.length === 0) return;

                    const msg = toDelete.length === 1
                        ? '确定要删除会话 "' + toDelete[0] + '" 吗？'
                        : '确定要删除 ' + toDelete.length + ' 个会话吗？';

                    if (!confirm(msg + '\n\n此操作不可撤销。')) return;

                    let successCount = 0, failCount = 0;
                    for (const sessionName of toDelete) {
                        try {
                            const res = await fetch('${pageContext.request.contextPath}/api/dtmf/phone/session?sessionName=' +
                                encodeURIComponent(sessionName), {
                                method: 'DELETE'
                            });
                            const data = await res.json();
                            if (data.success) successCount++;
                            else failCount++;
                        } catch (err) {
                            failCount++;
                        }
                    }

                    // 显示结果
                    if (failCount > 0) {
                        alert('删除完成：成功 ' + successCount + ' 个，失败 ' + failCount + ' 个');
                    }

                    // 刷新列表
                    document.getElementById('refreshBtn').click();

                    // 重置界面
                    selectedSession = null;
                    selectedSessions.clear();
                    updateSelectionUI();
                });

                document.getElementById('analyzeBtn').addEventListener('click', async () => {
                    if (!selectedSession) return;

                    document.getElementById('initialState').style.display = 'none';
                    document.getElementById('analysisResult').style.display = 'block';
                    document.getElementById('heroNumber').innerText = 'ANALYZING...';
                    document.getElementById('accuracyBar').style.width = '0%';

                    try {
                        const useAdaptive = document.getElementById('adaptiveCheck').checked;
                        const durationMs = parseInt(document.getElementById('durationSlider').value);
                        const durationSec = durationMs / 1000.0;

                        let url = '${pageContext.request.contextPath}/api/dtmf/phone/analyze?sessionName=' +
                            encodeURIComponent(selectedSession);
                        if (useAdaptive) {
                            url += '&duration=adaptive';
                        } else {
                            // Always send manual duration (in seconds) when not adaptive
                            url += '&duration=' + durationSec.toFixed(3);
                        }


                        const res = await fetch(url);
                        const data = await res.json();

                        if (data.phoneNumber) {
                            const accuracy = data.accuracy || 0;
                            const total = data.details ? data.details.length : 0;
                            const successNum = data.details ? data.details.filter(d => d.match === true).length : 0;
                            const failNum = total - successNum;

                            document.getElementById('heroNumber').innerText = data.phoneNumber;
                            document.getElementById('heroAccuracy').innerText = accuracy.toFixed(1) + '%';
                            setTimeout(() => {
                                document.getElementById('accuracyBar').style.width = accuracy + '%';
                            }, 100);

                            document.getElementById('statTotal').innerText = total;
                            document.getElementById('statSuccess').innerText = successNum;
                            document.getElementById('statFail').innerText = failNum;

                            // 计算平均信号时长（自适应算法使用的时长）
                            const signalDurations = data.details
                                .map(d => d.signalDuration)
                                .filter(t => typeof t === 'number');
                            if (signalDurations.length > 0) {
                                const avgDuration = signalDurations.reduce((a, b) => a + b, 0) / signalDurations.length;
                                document.getElementById('statAvgTime').innerText = avgDuration.toFixed(0) + 'ms';
                            } else {
                                document.getElementById('statAvgTime').innerText = '-';
                            }

                            updateDistributionChart(data.phoneNumber);

                            if (data.details && data.details.length > 0) {
                                const detailsList = document.getElementById('detailsList');
                                detailsList.innerHTML = data.details.map((d, i) => {
                                    const isSuccess = d.match === true;
                                    const snrVal = (typeof d.snrEstimate === 'number') ? d.snrEstimate.toFixed(1) + 'dB' : (d.snrEstimate || '-');
                                    const modeVal = d.mode || '-';
                                    const signalTime = (typeof d.signalDuration === 'number') ? d.signalDuration.toFixed(0) + 'ms' : '-';
                                    return `
                                    <tr class="log-row" data-index="\${i}" style="cursor:pointer;">
                                        <td style="font-size:0.7rem;">\${d.filename || 'item_' + i}</td>
                                        <td style="color:white; font-weight:bold;">\${d.originalKey || '-'}</td>
                                        <td style="color:\${isSuccess ? '#4aa3df' : '#d9534f'}; font-weight:bold;">\${d.identified || '?'}</td>
                                        <td style="font-size:0.7rem; opacity:0.7;">\${modeVal}</td>
                                        <td style="font-size:0.75rem;">\${snrVal}</td>
                                        <td style="font-size:0.75rem; color:#7ecf8e;">\${signalTime}</td>
                                        <td class="\${isSuccess ? 'log-status-ok' : 'log-status-fail'}">\${isSuccess ? 'OK' : 'FAIL'}</td>
                                    </tr>
                                    `;
                                }).join('');

                                // Bind click events
                                detailsList.querySelectorAll('.log-row').forEach(row => {
                                    row.addEventListener('click', () => {
                                        // Highlight selection
                                        detailsList.querySelectorAll('.log-row').forEach(r => r.style.background = '');
                                        row.style.background = 'rgba(74, 163, 223, 0.2)';

                                        // Update charts
                                        const idx = parseInt(row.dataset.index);
                                        const item = data.details[idx];

                                        // Update file info text
                                        document.getElementById('selectedFileInfo').innerHTML =
                                            `Viewing: <span style="color:white;">\${item.filename}</span> | ` +
                                            `Key: \${item.originalKey} -> \${item.identified} | ` +
                                            `SNR: \${(item.snrEstimate||0).toFixed(1)}dB`;

                                        if (item.waveformSample) updateAnalyzeWaveformChart(item.waveformSample);
                                        if (item.energies) updateAnalyzeEnergyChart(item.energies);
                                    });
                                });
                            }
                        } else {
                            document.getElementById('heroNumber').innerText = 'NO DATA';
                        }
                    } catch (err) {
                        document.getElementById('heroNumber').innerText = 'ERROR';
                    }
                });

                function updateDistributionChart(number) {
                    const counts = {};
                    for (let c of number) counts[c] = (counts[c] || 0) + 1;
                    const labels = Object.keys(counts).sort();
                    const data = labels.map(l => counts[l]);

                    if (distributionChart) distributionChart.destroy();
                    distributionChart = new Chart(document.getElementById('distributionChart').getContext('2d'), {
                        type: 'bar',
                        data: {
                            labels: labels,
                            datasets: [{
                                data: data,
                                backgroundColor: '#ffffff',
                                borderRadius: 0,
                                barPercentage: 0.5
                            }]
                        },
                        options: {
                            responsive: true,
                            maintainAspectRatio: false,
                            scales: {
                                y: { beginAtZero: true, grid: { display: false } },
                                x: { display: true, ticks: { color: '#888' } }
                            },
                            plugins: { legend: { display: false } }
                        }
                    });
                }

                let analyzeWaveformChart = null;
                let analyzeEnergyChart = null;

                function updateAnalyzeWaveformChart(waveform) {
                    const ctx = document.getElementById('analyzeWaveformChart').getContext('2d');
                    if (analyzeWaveformChart) analyzeWaveformChart.destroy();

                    analyzeWaveformChart = new Chart(ctx, {
                        type: 'line',
                        data: {
                            labels: Array.from({ length: waveform.length }, (_, i) => i),
                            datasets: [{
                                label: 'Amplitude',
                                data: waveform,
                                borderColor: '#4aa3df',
                                borderWidth: 1,
                                pointRadius: 0,
                                fill: false,
                                tension: 0.1
                            }]
                        },
                        options: {
                            responsive: true,
                            maintainAspectRatio: false,
                            animation: false,
                            scales: {
                                x: { display: false },
                                y: {
                                    display: true,
                                    min: -1.2,
                                    max: 1.2,
                                    grid: { color: '#333' }
                                }
                            },
                            plugins: { legend: { display: false } }
                        }
                    });
                }

                function updateAnalyzeEnergyChart(energies) {
                    const ctx = document.getElementById('analyzeEnergyChart').getContext('2d');
                    if (analyzeEnergyChart) analyzeEnergyChart.destroy();

                    const freqs = ['697', '770', '852', '941', '1209', '1336', '1477', '1633'];
                    // Find max energy to normalize colors
                    const maxE = Math.max(...energies);
                    const bgColors = energies.map(e => e > maxE * 0.5 ? '#4aa3df' : '#555');

                    analyzeEnergyChart = new Chart(ctx, {
                        type: 'bar',
                        data: {
                            labels: freqs,
                            datasets: [{
                                data: energies,
                                backgroundColor: bgColors,
                                borderRadius: 2
                            }]
                        },
                        options: {
                            responsive: true,
                            maintainAspectRatio: false,
                            animation: false,
                            scales: {
                                y: { beginAtZero: true, display: false },
                                x: { ticks: { color: '#888', font: { size: 10 } }, grid: { display: false } }
                            },
                            plugins: { legend: { display: false } }
                        }
                    });
                }

                // Auto load on enter
                document.getElementById('refreshBtn').click();
            </script>
        </body>

        </html>