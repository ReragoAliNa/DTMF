<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
    <%@ taglib prefix="c" uri="jakarta.tags.core" %>
        <!DOCTYPE html>
        <html lang="zh-CN">

        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>${title} | DTMF System</title>
            <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
            <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
        </head>

        <body>
            <div class="split-layout">
                <!-- LEFT SIDE: Visual Stage (Charts) -->
                <div class="visual-stage">
                    <div class="chart-card">
                        <div class="chart-title">TIMEDOMAIN WAVEFORM // 01</div>
                        <div style="width:100%; height:100%;"><canvas id="waveChart"></canvas></div>
                    </div>

                    <div class="chart-card">
                        <div class="chart-title">GOERTZEL SPECTRUM // 02</div>
                        <div style="width:100%; height:100%;"><canvas id="energyChart"></canvas></div>
                    </div>
                </div>

                <!-- RIGHT SIDE: Control & Navigation -->
                <div class="control-sidebar">
                    <h1 class="brand-title">ReragoAliNa<span style="font-weight:300; opacity:0.5;">Lab</span></h1>

                    <div class="nav-menu">
                        <div class="section-title">Navigation</div>
                        <a href="${pageContext.request.contextPath}/" class="nav-link active">Experiment Mode</a>
                        <a href="${pageContext.request.contextPath}/phone" class="nav-link">Phone Mode</a>
                        <a href="${pageContext.request.contextPath}/analyze" class="nav-link">Audio Analysis</a>
                    </div>

                    <div class="control-group">
                        <div class="section-title">Input Signal</div>
                        <label>DTMF Key Selection</label>
                        <div class="numpad-grid" id="numpad">
                            <!-- Standard DTMF Keypad layout -->
                            <div class="numpad-key">1</div>
                            <div class="numpad-key">2</div>
                            <div class="numpad-key">3</div>
                            <div class="numpad-key">A</div>
                            <div class="numpad-key">4</div>
                            <div class="numpad-key active">5</div>
                            <div class="numpad-key">6</div>
                            <div class="numpad-key">B</div>
                            <div class="numpad-key">7</div>
                            <div class="numpad-key">8</div>
                            <div class="numpad-key">9</div>
                            <div class="numpad-key">C</div>
                            <div class="numpad-key">*</div>
                            <div class="numpad-key">0</div>
                            <div class="numpad-key">#</div>
                            <div class="numpad-key">D</div>
                        </div>
                    </div>

                    <div class="control-group">
                        <div class="section-title">Channel Parameters</div>
                        <label>Noise Type</label>
                        <select id="noiseType">
                            <option value="GAUSSIAN">Gaussian White Noise</option>
                            <option value="PINK">Pink Noise</option>
                            <option value="IMPULSE">Impulse Noise</option>
                            <option value="UNIFORM">Uniform Noise</option>
                        </select>

                        <br><br>
                        <label style="display:flex; justify-content:space-between;">
                            Signal-to-Noise Ratio (dB)
                            <span id="snrVal">0</span>
                        </label>
                        <input type="range" id="snrRange" min="-20" max="30" value="0"
                            style="padding:0; height:4px; margin:10px 0;">

                        <br><br>
                        <label
                            style="display: flex; justify-content: space-between; align-items: center; cursor:pointer;">
                            Adaptive Algorithm (Hybrid)
                            <input type="checkbox" id="adaptiveToggle" checked style="width: auto;">
                        </label>
                    </div>

                    <button id="runBtn" class="btn-primary">Execute Analysis</button>

                    <div id="resultPanel" class="result-box" style="display: none;">
                        <div class="result-row"><span>Input Key</span> <span id="resInput" class="result-val">-</span>
                        </div>
                        <div class="result-row"><span>Identified</span> <span id="resOutput" class="result-val">-</span>
                        </div>
                        <div class="result-row"><span>SNR Estimate</span> <span id="resSnr" class="result-val">-</span>
                            dB</div>
                        <div class="result-row"><span>Status</span> <span id="resStatus"
                                class="result-val">Waiting...</span></div>
                    </div>

                    <div style="margin-top:2rem; font-size:0.7rem; color:var(--text-sub); text-align:center;">
                        &copy; 2024 DTMF Processing System
                    </div>
                </div>
            </div>

            <!-- JavaScript Logic -->
            <script>
                var selectedKey = '5', energyChart = null, waveChart = null;

                // Keypad Interaction
                document.getElementById('numpad').querySelectorAll('.numpad-key').forEach(k => {
                    k.addEventListener('click', () => {
                        document.querySelectorAll('.numpad-key').forEach(x => x.classList.remove('active'));
                        k.classList.add('active');
                        selectedKey = k.innerText;
                    });
                });

                // SNR Slider Update
                document.getElementById('snrRange').addEventListener('input', e => {
                    document.getElementById('snrVal').innerText = e.target.value;
                });

                // Run Experiment
                document.getElementById('runBtn').addEventListener('click', async () => {
                    const snr = document.getElementById('snrRange').value;
                    const adaptive = document.getElementById('adaptiveToggle').checked;
                    const noiseType = document.getElementById('noiseType').value;

                    const resultPanel = document.getElementById('resultPanel');
                    resultPanel.style.display = 'block';
                    document.getElementById('resStatus').innerText = 'Processing...';

                    try {
                        const res = await fetch('${pageContext.request.contextPath}/api/dtmf/test?key=' + encodeURIComponent(selectedKey) + '&snr=' + snr + '&adaptive=' + adaptive + '&noiseType=' + noiseType);
                        if (!res.ok) throw new Error("Network response was not ok");
                        const data = await res.json();

                        document.getElementById('resInput').innerText = data.key;
                        document.getElementById('resOutput').innerText = data.identified || '?';
                        document.getElementById('resSnr').innerText = data.snrEstimate ? data.snrEstimate.toFixed(1) : '-';

                        const isSuccess = data.key === data.identified;
                        document.getElementById('resStatus').innerHTML = isSuccess ?
                            '<span style="color:#4aa3df">SUCCESS</span>' : '<span style="color:#d9534f">FAILURE</span>';

                        // --- Chart Update Logic ---
                        const freqs = ['697', '770', '852', '941', '1209', '1336', '1477', '1633'];

                        // Energy Chart
                        if (energyChart) energyChart.destroy();
                        const ctxEnergy = document.getElementById('energyChart').getContext('2d');
                        energyChart = new Chart(ctxEnergy, {
                            type: 'bar',
                            data: {
                                labels: freqs.map(f => f + 'Hz'),
                                datasets: [{
                                    data: data.energies || [],
                                    backgroundColor: freqs.map((_, i) => i < 4 ? '#ffffff' : '#666666'), // White for Low, Gray for High
                                    borderRadius: 0,
                                    barPercentage: 0.6
                                }]
                            },
                            options: {
                                responsive: true,
                                maintainAspectRatio: false,
                                scales: {
                                    y: { display: false, grid: { display: false } },
                                    x: {
                                        grid: { color: 'rgba(255,255,255,0.1)' },
                                        ticks: { color: '#888', font: { family: 'Raleway' } }
                                    }
                                },
                                plugins: { legend: { display: false } }
                            }
                        });

                        // Wave Chart
                        if (waveChart) waveChart.destroy();
                        const ctxWave = document.getElementById('waveChart').getContext('2d');
                        waveChart = new Chart(ctxWave, {
                            type: 'line',
                            data: {
                                labels: (data.waveformSample || []).map((_, i) => i),
                                datasets: [{
                                    data: data.waveformSample || [],
                                    borderColor: '#ffffff',
                                    borderWidth: 1.5,
                                    pointRadius: 0,
                                    tension: 0.4
                                }]
                            },
                            options: {
                                responsive: true,
                                maintainAspectRatio: false,
                                scales: {
                                    y: { display: false, grid: { color: 'rgba(255,255,255,0.05)' } },
                                    x: { display: false }
                                },
                                plugins: { legend: { display: false } }
                            }
                        });

                    } catch (err) {
                        console.error(err);
                        document.getElementById('resStatus').innerText = 'Error';
                    }
                });
            </script>
        </body>

        </html>