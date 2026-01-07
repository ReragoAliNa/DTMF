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
            <style>
                .mode-toggle {
                    display: flex;
                    background: rgba(255, 255, 255, 0.05);
                    border: 1px solid var(--border-color);
                    margin-bottom: 1.5rem;
                }

                .mode-btn {
                    flex: 1;
                    padding: 0.8rem;
                    background: transparent;
                    border: none;
                    color: var(--text-sub);
                    cursor: pointer;
                    transition: 0.3s;
                    font-size: 0.8rem;
                }

                .mode-btn.active {
                    background: white;
                    color: black;
                }

                .compare-grid {
                    display: grid;
                    grid-template-columns: 1fr 1fr;
                    gap: 20px;
                    margin-bottom: 2rem;
                }

                .compare-box {
                    border: 1px solid var(--border-color);
                    padding: 1.5rem;
                    text-align: center;
                }

                .compare-box.success {
                    border-color: #4aa3df;
                }

                .compare-box.fail {
                    border-color: #d9534f;
                }

                .compare-val {
                    font-size: 2rem;
                    font-family: 'Cinzel', serif;
                    margin: 1rem 0;
                }

                .compare-label {
                    font-size: 0.8rem;
                    color: var(--text-sub);
                    text-transform: uppercase;
                }

                .result-note {
                    padding: 1rem;
                    background: rgba(255, 255, 255, 0.05);
                    border-left: 2px solid #4aa3df;
                    margin-bottom: 2rem;
                    font-size: 0.9rem;
                }
            </style>
        </head>

        <body>
            <div class="split-layout">
                <!-- LEFT SIDE: Visual Stage -->
                <div class="visual-stage" id="visualStage">
                    <!-- SINGLE MODE VISUALS -->
                    <div id="singleModeVisuals">
                        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; margin-bottom: 1rem;">
                            <div class="chart-card">
                                <div class="chart-title">CLEAN SIGNAL // 01</div>
                                <div style="width:100%; height:100%;"><canvas id="cleanWaveChart"></canvas></div>
                            </div>
                            <div class="chart-card">
                                <div class="chart-title">NOISY SIGNAL // 02</div>
                                <div style="width:100%; height:100%;"><canvas id="noisyWaveChart"></canvas></div>
                            </div>
                        </div>
                        <div class="chart-card">
                            <div class="chart-title">GOERTZEL SPECTRUM // 03</div>
                            <div style="width:100%; height:100%;"><canvas id="energyChart"></canvas></div>
                        </div>
                    </div>

                    <!-- COMPARE MODE VISUALS -->
                    <div id="compareModeVisuals" style="display:none; width: 100%; max-width: 900px; margin: 0 auto;">
                        <div class="section-title">Algorithmic Comparison</div>
                        <div class="compare-grid" id="compareResultBoxes" style="display:none;">
                            <div class="compare-box" id="stdBox">
                                <div class="compare-label">Standard Algorithm</div>
                                <div class="compare-val" id="stdResult">-</div>
                                <div class="compare-label" id="stdMode">-</div>
                            </div>
                            <div class="compare-box" id="adpBox">
                                <div class="compare-label">Adaptive Algorithm</div>
                                <div class="compare-val" id="adpResult">-</div>
                                <div class="compare-label" id="adpMode">-</div>
                            </div>
                        </div>
                        <div id="compareNote" class="result-note" style="display:none;"></div>
                        <div class="chart-card">
                            <div class="chart-title">STANDARD SPECTRUM</div>
                            <div style="width:100%; height:100%;"><canvas id="compareEnergyChart1"></canvas></div>
                        </div>
                        <div class="chart-card">
                            <div class="chart-title">ADAPTIVE SPECTRUM</div>
                            <div style="width:100%; height:100%;"><canvas id="compareEnergyChart2"></canvas></div>
                        </div>
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
                        <div class="section-title">Mode Selection</div>
                        <div class="mode-toggle">
                            <button class="mode-btn active" data-mode="single">Single Analysis</button>
                            <button class="mode-btn" data-mode="compare">Algorithm Compare</button>
                        </div>
                    </div>

                    <div class="control-group">
                        <div class="section-title">Input Signal</div>
                        <label>DTMF Key</label>
                        <div class="numpad-grid" id="numpad">
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
                        <div class="section-title">Parameters</div>
                        <label>Noise Type</label>
                        <select id="noiseType">
                            <optgroup label="Synthetic Noise">
                                <option value="GAUSSIAN">Gaussian White Noise</option>
                                <option value="PINK">Pink Noise (1/f)</option>
                                <option value="IMPULSE">Impulse Noise</option>
                                <option value="UNIFORM">Uniform Noise</option>
                            </optgroup>
                            <optgroup label="ESC-50 Dataset">
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
                        <label>SNR: <span id="snrVal">0</span> dB</label>
                        <input type="range" id="snrRange" min="-20" max="30" value="0"
                            style="padding:0; height:4px; margin:10px 0;">

                        <br><br>
                        <label>Freq Offset: <span id="freqOffsetVal">0</span>%</label>
                        <input type="range" id="freqOffsetRange" min="0" max="10" step="0.5" value="0"
                            style="padding:0; height:4px; margin:10px 0;">
                        <div style="font-size:0.65rem; color:var(--text-sub); margin-top:-5px;">
                            模拟电话线路频率漂移 (>3% 可能导致识别失败)
                        </div>

                        <div id="singleControls">
                            <br>
                            <label
                                style="display: flex; justify-content: space-between; align-items: center; cursor:pointer;">
                                Adaptive Algorithm
                                <input type="checkbox" id="adaptiveToggle" checked style="width: auto;">
                            </label>
                        </div>
                    </div>

                    <button id="runBtn" class="btn-primary">Execute Analysis</button>

                    <!-- Single Result Box -->
                    <div id="resultPanel" class="result-box" style="display: none;">
                        <div class="result-row"><span>Input</span> <span id="resInput" class="result-val">-</span></div>
                        <div class="result-row"><span>Identified</span> <span id="resOutput" class="result-val">-</span>
                        </div>
                        <div class="result-row"><span>Algorithm</span> <span id="resMode" class="result-val">-</span>
                        </div>
                        <div class="result-row"><span>Duration</span> <span id="resDuration" class="result-val">-</span>
                            ms</div>
                        <div class="result-row"><span>SNR Est.</span> <span id="resSnr" class="result-val">-</span> dB
                        </div>
                        <div class="result-row"><span>Status</span> <span id="resStatus"
                                class="result-val">Waiting...</span></div>
                        <div style="display:flex; gap:0.5rem; margin-top:1rem;">
                            <button id="playCleanBtn" class="btn-secondary"
                                style="flex:1; padding:8px; font-size:0.75rem;" disabled>
                                ▶ Clean
                            </button>
                            <button id="playNoisyBtn" class="btn-secondary"
                                style="flex:1; padding:8px; font-size:0.75rem;" disabled>
                                ▶ Noisy
                            </button>
                        </div>
                    </div>
                </div>
            </div>

            <script>
                var selectedKey = '5';
                var energyChart = null, cleanWaveChart = null, noisyWaveChart = null;
                var cmpChart1 = null, cmpChart2 = null;
                var currentMode = 'single';

                // DTMF Audio Context for sound feedback
                const audioContext = new (window.AudioContext || window.webkitAudioContext)();
                const DTMF_FREQS = {
                    '1': [697, 1209], '2': [697, 1336], '3': [697, 1477], 'A': [697, 1633],
                    '4': [770, 1209], '5': [770, 1336], '6': [770, 1477], 'B': [770, 1633],
                    '7': [852, 1209], '8': [852, 1336], '9': [852, 1477], 'C': [852, 1633],
                    '*': [941, 1209], '0': [941, 1336], '#': [941, 1477], 'D': [941, 1633]
                };

                function playDtmfTone(key, duration = 0.15) {
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

                // Store latest waveform data for playback
                var lastCleanWaveform = null;
                var lastNoisyWaveform = null;

                function playWaveformArray(waveformData, sampleRate = 8000) {
                    if (!waveformData || waveformData.length === 0) return;
                    if (audioContext.state === 'suspended') audioContext.resume();

                    // Create audio buffer
                    const buffer = audioContext.createBuffer(1, waveformData.length, sampleRate);
                    const channelData = buffer.getChannelData(0);

                    // Normalize and copy data
                    let maxAbs = 0;
                    for (let i = 0; i < waveformData.length; i++) {
                        maxAbs = Math.max(maxAbs, Math.abs(waveformData[i]));
                    }
                    const scale = maxAbs > 0 ? 0.5 / maxAbs : 1;
                    for (let i = 0; i < waveformData.length; i++) {
                        channelData[i] = waveformData[i] * scale;
                    }

                    // Play the buffer
                    const source = audioContext.createBufferSource();
                    source.buffer = buffer;
                    source.connect(audioContext.destination);
                    source.start();
                }

                document.getElementById('playCleanBtn').addEventListener('click', () => {
                    if (lastCleanWaveform) playWaveformArray(lastCleanWaveform);
                });

                document.getElementById('playNoisyBtn').addEventListener('click', () => {
                    if (lastNoisyWaveform) playWaveformArray(lastNoisyWaveform);
                });

                document.getElementById('numpad').querySelectorAll('.numpad-key').forEach(k => {
                    k.addEventListener('click', () => {
                        document.querySelectorAll('.numpad-key').forEach(x => x.classList.remove('active'));
                        k.classList.add('active');
                        selectedKey = k.innerText;
                        playDtmfTone(selectedKey);  // Play DTMF sound
                    });
                });

                document.querySelectorAll('.mode-btn').forEach(btn => {
                    btn.addEventListener('click', () => {
                        document.querySelectorAll('.mode-btn').forEach(b => b.classList.remove('active'));
                        btn.classList.add('active');
                        currentMode = btn.dataset.mode;

                        if (currentMode === 'single') {
                            document.getElementById('singleModeVisuals').style.display = 'block';
                            document.getElementById('compareModeVisuals').style.display = 'none';
                            document.getElementById('singleControls').style.display = 'block';
                            document.getElementById('resultPanel').style.display = 'none';
                            document.getElementById('runBtn').innerText = 'Execute Analysis';
                        } else {
                            document.getElementById('singleModeVisuals').style.display = 'none';
                            document.getElementById('compareModeVisuals').style.display = 'block';
                            document.getElementById('singleControls').style.display = 'none';
                            document.getElementById('resultPanel').style.display = 'none';
                            document.getElementById('runBtn').innerText = 'Run Comparison';
                        }
                    });
                });

                document.getElementById('snrRange').addEventListener('input', e => {
                    document.getElementById('snrVal').innerText = e.target.value;
                });

                document.getElementById('freqOffsetRange').addEventListener('input', e => {
                    document.getElementById('freqOffsetVal').innerText = e.target.value;
                });

                document.getElementById('runBtn').addEventListener('click', async () => {
                    const snr = document.getElementById('snrRange').value;
                    const noiseType = document.getElementById('noiseType').value;
                    const freqOffset = document.getElementById('freqOffsetRange').value;

                    if (currentMode === 'single') {
                        const adaptive = document.getElementById('adaptiveToggle').checked;
                        runSingle(snr, adaptive, noiseType, freqOffset);
                    } else {
                        runCompare(snr, noiseType, freqOffset);
                    }
                });

                async function runSingle(snr, adaptive, noiseType, freqOffset) {
                    document.getElementById('resultPanel').style.display = 'block';
                    document.getElementById('resStatus').innerText = 'Processing...';
                    document.getElementById('playCleanBtn').disabled = true;
                    document.getElementById('playNoisyBtn').disabled = true;

                    try {
                        const res = await fetch('${pageContext.request.contextPath}/api/dtmf/test?key=' + encodeURIComponent(selectedKey) + '&snr=' + snr + '&adaptive=' + adaptive + '&noiseType=' + noiseType + '&freqOffset=' + freqOffset);
                        const data = await res.json();

                        document.getElementById('resInput').innerText = data.key;
                        document.getElementById('resOutput').innerText = data.identified || '?';
                        document.getElementById('resMode').innerText = data.mode || (adaptive ? 'Adaptive' : 'Fixed');
                        document.getElementById('resDuration').innerText = data.signalDuration ? data.signalDuration.toFixed(0) : '-';
                        document.getElementById('resSnr').innerText = data.snrEstimate ? data.snrEstimate.toFixed(1) : '-';
                        const isSuccess = data.key === data.identified;
                        document.getElementById('resStatus').innerHTML = isSuccess ? '<span style="color:#4aa3df">SUCCESS</span>' : '<span style="color:#d9534f">FAILURE</span>';

                        // Store waveforms for playback
                        lastCleanWaveform = data.cleanWaveform || null;
                        lastNoisyWaveform = data.noisyWaveform || null;
                        document.getElementById('playCleanBtn').disabled = !lastCleanWaveform;
                        document.getElementById('playNoisyBtn').disabled = !lastNoisyWaveform;

                        updateSingleCharts(data);
                    } catch (e) { console.error(e); }
                }

                async function runCompare(snr, noiseType, freqOffset) {
                    document.getElementById('compareNote').style.display = 'block';
                    document.getElementById('compareNote').innerText = 'Running Comparison...';
                    document.getElementById('compareResultBoxes').style.display = 'grid';

                    try {
                        const res = await fetch('${pageContext.request.contextPath}/api/dtmf/compare?key=' + encodeURIComponent(selectedKey) + '&snr=' + snr + '&noiseType=' + noiseType + '&freqOffset=' + freqOffset);
                        const data = await res.json();

                        const stdSuccess = data.standard.identified === data.key;
                        const adpSuccess = data.adaptive.identified === data.key;

                        document.getElementById('stdResult').innerText = data.standard.identified || '?';
                        document.getElementById('stdBox').className = 'compare-box ' + (stdSuccess ? 'success' : 'fail');
                        document.getElementById('stdMode').innerText = data.standard.mode;

                        document.getElementById('adpResult').innerText = data.adaptive.identified || '?';
                        document.getElementById('adpBox').className = 'compare-box ' + (adpSuccess ? 'success' : 'fail');
                        document.getElementById('adpMode').innerText = data.adaptive.mode;

                        let note = "";
                        if (!stdSuccess && adpSuccess) note = "Adaptive algorithm outperformed Standard.";
                        else if (stdSuccess && adpSuccess) note = "Both algorithms successful.";
                        else note = "Both algorithms failed (High Noise).";
                        document.getElementById('compareNote').innerText = note;

                        updateCompareCharts(data);
                    } catch (e) { console.error(e); }
                }

                function createChart(ctx, labels, data, color) {
                    return new Chart(ctx, {
                        type: 'bar',
                        data: {
                            labels: labels,
                            datasets: [{ data: data, backgroundColor: color, borderRadius: 0, barPercentage: 0.6 }]
                        },
                        options: {
                            responsive: true, maintainAspectRatio: false,
                            scales: { y: { display: false }, x: { ticks: { color: '#888' }, grid: { display: false } } },
                            plugins: { legend: { display: false } }
                        }
                    });
                }

                function createLineChart(ctx, data, color) {
                    return new Chart(ctx, {
                        type: 'line',
                        data: {
                            labels: (data || []).map((_, i) => i),
                            datasets: [{ data: data || [], borderColor: color, borderWidth: 1, pointRadius: 0, fill: false }]
                        },
                        options: {
                            responsive: true,
                            maintainAspectRatio: false,
                            scales: { x: { display: false }, y: { display: false } },
                            plugins: { legend: { display: false } }
                        }
                    });
                }

                function updateSingleCharts(data) {
                    const freqs = ['697', '770', '852', '941', '1209', '1336', '1477', '1633'].map(f => f + 'Hz');

                    // Energy chart
                    if (energyChart) energyChart.destroy();
                    energyChart = createChart(document.getElementById('energyChart').getContext('2d'), freqs, data.energies || [], '#ffffff');

                    // Clean waveform chart (original signal without noise)
                    if (cleanWaveChart) cleanWaveChart.destroy();
                    cleanWaveChart = createLineChart(document.getElementById('cleanWaveChart').getContext('2d'), data.cleanWaveform || [], '#4aa3df');

                    // Noisy waveform chart
                    if (noisyWaveChart) noisyWaveChart.destroy();
                    noisyWaveChart = createLineChart(document.getElementById('noisyWaveChart').getContext('2d'), data.noisyWaveform || data.waveformSample || [], '#ffffff');
                }

                function updateCompareCharts(data) {
                    const freqs = ['697', '770', '852', '941', '1209', '1336', '1477', '1633'].map(f => f + 'Hz');

                    if (cmpChart1) cmpChart1.destroy();
                    cmpChart1 = createChart(document.getElementById('compareEnergyChart1').getContext('2d'), freqs, data.standard.energies || [], '#888888');

                    if (cmpChart2) cmpChart2.destroy();
                    cmpChart2 = createChart(document.getElementById('compareEnergyChart2').getContext('2d'), freqs, data.adaptive.energies || [], '#ffffff');
                }
            </script>
        </body>

        </html>