package com.example.dtmf_web.service;

import org.springframework.stereotype.Service;
import java.io.*;
import java.nio.file.*;
import java.util.*;
import java.text.SimpleDateFormat;

@Service
public class DtmfService {

    private static final int FS = 8000;
    private static final double[] LOW_FREQS = { 697, 770, 852, 941 };
    private static final double[] HIGH_FREQS = { 1209, 1336, 1477, 1633 };
    private static final Map<Character, double[]> FREQ_MAP = new HashMap<>();

    // Phone mode session management
    private String currentSessionFolder = null;
    private int keyPressIndex = 0;
    // For polling: store last key press info
    private Character lastKey = null;
    private long lastKeyTime = 0;
    private Map<String, Object> lastResult = null;

    static {
        FREQ_MAP.put('1', new double[] { 697, 1209 });
        FREQ_MAP.put('2', new double[] { 697, 1336 });
        FREQ_MAP.put('3', new double[] { 697, 1477 });
        FREQ_MAP.put('A', new double[] { 697, 1633 });
        FREQ_MAP.put('4', new double[] { 770, 1209 });
        FREQ_MAP.put('5', new double[] { 770, 1336 });
        FREQ_MAP.put('6', new double[] { 770, 1477 });
        FREQ_MAP.put('B', new double[] { 770, 1633 });
        FREQ_MAP.put('7', new double[] { 852, 1209 });
        FREQ_MAP.put('8', new double[] { 852, 1336 });
        FREQ_MAP.put('9', new double[] { 852, 1477 });
        FREQ_MAP.put('C', new double[] { 852, 1633 });
        FREQ_MAP.put('*', new double[] { 941, 1209 });
        FREQ_MAP.put('0', new double[] { 941, 1336 });
        FREQ_MAP.put('#', new double[] { 941, 1477 });
        FREQ_MAP.put('D', new double[] { 941, 1633 });
    }

    // Noise type enum - includes ESC-50 dataset categories
    public enum NoiseType {
        // Synthetic noise
        GAUSSIAN, // 高斯白噪声
        PINK, // 粉红噪声 (1/f)
        IMPULSE, // 脉冲噪声
        UNIFORM, // 均匀噪声
        SERIAL, // 串口/硬件实时数据 (不加噪)
        // ESC-50 dataset categories
        RAIN, // 雨声
        WIND, // 风声
        THUNDERSTORM, // 雷暴
        DOG, // 狗叫
        CAR_HORN, // 汽车喇叭
        ENGINE, // 发动机
        HELICOPTER, // 直升机
        TRAIN, // 火车
        CHAINSAW, // 电锯
        SIREN, // 警报
        KEYBOARD_TYPING, // 键盘打字
        VACUUM_CLEANER, // 吸尘器
        CLOCK_TICK, // 时钟滴答
        CRACKLING_FIRE // 火 crackling
    }

    // ESC-50 category name mappings
    private static final Map<NoiseType, String> ESC50_CATEGORIES = new HashMap<>();
    static {
        ESC50_CATEGORIES.put(NoiseType.RAIN, "rain");
        ESC50_CATEGORIES.put(NoiseType.WIND, "wind");
        ESC50_CATEGORIES.put(NoiseType.THUNDERSTORM, "thunderstorm");
        ESC50_CATEGORIES.put(NoiseType.DOG, "dog");
        ESC50_CATEGORIES.put(NoiseType.CAR_HORN, "car_horn");
        ESC50_CATEGORIES.put(NoiseType.ENGINE, "engine");
        ESC50_CATEGORIES.put(NoiseType.HELICOPTER, "helicopter");
        ESC50_CATEGORIES.put(NoiseType.TRAIN, "train");
        ESC50_CATEGORIES.put(NoiseType.CHAINSAW, "chainsaw");
        ESC50_CATEGORIES.put(NoiseType.SIREN, "siren");
        ESC50_CATEGORIES.put(NoiseType.KEYBOARD_TYPING, "keyboard_typing");
        ESC50_CATEGORIES.put(NoiseType.VACUUM_CLEANER, "vacuum_cleaner");
        ESC50_CATEGORIES.put(NoiseType.CLOCK_TICK, "clock_tick");
        ESC50_CATEGORIES.put(NoiseType.CRACKLING_FIRE, "crackling_fire");
    }

    public double[] generateDtmf(char key, double duration, Double snrDb) {
        return generateDtmf(key, duration, snrDb, NoiseType.GAUSSIAN, 0.0);
    }

    public double[] generateDtmf(char key, double duration, Double snrDb, NoiseType noiseType) {
        return generateDtmf(key, duration, snrDb, noiseType, 0.0);
    }

    /**
     * 生成 DTMF 信号，支持频率偏移模拟
     * 
     * @param key               DTMF 按键
     * @param duration          持续时间（秒）
     * @param snrDb             信噪比（dB），null 表示无噪声
     * @param noiseType         噪声类型
     * @param freqOffsetPercent 频率偏移百分比（例如 2.0 表示 ±2% 随机偏移）
     */
    public double[] generateDtmf(char key, double duration, Double snrDb, NoiseType noiseType,
            double freqOffsetPercent) {
        double[] freqs = FREQ_MAP.get(key);
        if (freqs == null)
            return new double[0];

        int numSamples = (int) (FS * duration);
        double[] signal = new double[numSamples];

        // 应用频率偏移（模拟电话线路导致的频率漂移）
        Random random = new Random();
        double lowFreq = freqs[0];
        double highFreq = freqs[1];

        if (freqOffsetPercent > 0) {
            // 对低频和高频分别施加随机偏移
            double lowOffset = 1.0 + (random.nextDouble() * 2 - 1) * freqOffsetPercent / 100.0;
            double highOffset = 1.0 + (random.nextDouble() * 2 - 1) * freqOffsetPercent / 100.0;
            lowFreq *= lowOffset;
            highFreq *= highOffset;
        }

        for (int i = 0; i < numSamples; i++) {
            double t = (double) i / FS;
            signal[i] = Math.sin(2 * Math.PI * lowFreq * t) + Math.sin(2 * Math.PI * highFreq * t);
        }

        if (snrDb != null) {
            double signalPower = 0;
            for (double s : signal)
                signalPower += s * s;
            signalPower /= numSamples;

            double snrLinear = Math.pow(10, snrDb / 10.0);
            double noisePower = signalPower / snrLinear;
            double noiseStd = Math.sqrt(noisePower);

            double[] noise = generateNoise(numSamples, noiseType, noiseStd, random);
            for (int i = 0; i < numSamples; i++) {
                signal[i] += noise[i];
            }
        }

        return signal;
    }

    private double[] generateNoise(int samples, NoiseType type, double std, Random random) {
        double[] noise = new double[samples];

        // Check if it's an ESC-50 category
        if (ESC50_CATEGORIES.containsKey(type)) {
            noise = loadEsc50Noise(type, samples, std, random);
            return noise;
        }

        switch (type) {
            case GAUSSIAN:
                for (int i = 0; i < samples; i++) {
                    noise[i] = random.nextGaussian() * std;
                }
                break;
            case PINK:
                // Pink noise using Paul Kellet's refined method
                double b0 = 0, b1 = 0, b2 = 0, b3 = 0, b4 = 0, b5 = 0, b6 = 0;
                for (int i = 0; i < samples; i++) {
                    double white = random.nextGaussian();
                    b0 = 0.99886 * b0 + white * 0.0555179;
                    b1 = 0.99332 * b1 + white * 0.0750759;
                    b2 = 0.96900 * b2 + white * 0.1538520;
                    b3 = 0.86650 * b3 + white * 0.3104856;
                    b4 = 0.55000 * b4 + white * 0.5329522;
                    b5 = -0.7616 * b5 - white * 0.0168980;
                    noise[i] = (b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362) * std * 0.11;
                    b6 = white * 0.115926;
                }
                break;
            case IMPULSE:
                // Impulse noise: sparse random spikes
                for (int i = 0; i < samples; i++) {
                    if (random.nextDouble() < 0.02) { // 2% probability
                        noise[i] = (random.nextBoolean() ? 1 : -1) * std * 5;
                    } else {
                        noise[i] = random.nextGaussian() * std * 0.3;
                    }
                }
                break;
            case UNIFORM:
                for (int i = 0; i < samples; i++) {
                    noise[i] = (random.nextDouble() - 0.5) * 2 * std * 1.73;
                }
                break;
            default:
                // Default to Gaussian if unknown
                for (int i = 0; i < samples; i++) {
                    noise[i] = random.nextGaussian() * std;
                }
        }
        return noise;
    }

    /**
     * Load noise from ESC-50 dataset WAV files
     */
    private double[] loadEsc50Noise(NoiseType type, int samples, double targetStd, Random random) {
        String category = ESC50_CATEGORIES.get(type);
        if (category == null) {
            return new double[samples]; // Return silence
        }

        // Find the datasets folder (project root relative to working directory)
        Path datasetsPath = Paths.get("../datasets/esc50/audio");
        if (!Files.exists(datasetsPath)) {
            datasetsPath = Paths.get("datasets/esc50/audio");
        }
        if (!Files.exists(datasetsPath)) {
            // Fallback to Gaussian noise if dataset not found
            double[] noise = new double[samples];
            for (int i = 0; i < samples; i++) {
                noise[i] = random.nextGaussian() * targetStd;
            }
            return noise;
        }

        try {
            // Find files matching this category
            List<Path> matchingFiles = new ArrayList<>();
            try (var stream = Files.list(datasetsPath)) {
                stream.filter(p -> p.getFileName().toString().endsWith(".wav"))
                        .filter(p -> {
                            // ESC-50 filename format: {fold}-{src_file}-{take}-{target}.wav
                            // We need to match by target number, but category name is in CSV
                            // Simpler: just look for category in filename
                            String name = p.getFileName().toString().toLowerCase();
                            // Match by target number from filename (e.g., "-10.wav" for rain)
                            return name.contains("-" + getTargetNumber(category) + ".wav");
                        })
                        .forEach(matchingFiles::add);
            }

            if (matchingFiles.isEmpty()) {
                // Fallback
                double[] noise = new double[samples];
                for (int i = 0; i < samples; i++) {
                    noise[i] = random.nextGaussian() * targetStd;
                }
                return noise;
            }

            // Pick a random file
            Path selectedFile = matchingFiles.get(random.nextInt(matchingFiles.size()));
            double[] rawNoise = loadWav(selectedFile.toString());

            // Resample if needed (ESC-50 is 44100Hz, we need 8000Hz)
            double[] resampledNoise = resample(rawNoise, 44100, FS, samples);

            // Normalize to target std
            double currentStd = calculateStd(resampledNoise);
            if (currentStd > 0) {
                double scale = targetStd / currentStd;
                for (int i = 0; i < resampledNoise.length; i++) {
                    resampledNoise[i] *= scale;
                }
            }

            return resampledNoise;
        } catch (Exception e) {
            // Fallback to Gaussian
            double[] noise = new double[samples];
            for (int i = 0; i < samples; i++) {
                noise[i] = random.nextGaussian() * targetStd;
            }
            return noise;
        }
    }

    private int getTargetNumber(String category) {
        // ESC-50 target numbers for categories
        switch (category) {
            case "dog":
                return 0;
            case "rain":
                return 10;
            case "wind":
                return 16;
            case "thunderstorm":
                return 19;
            case "car_horn":
                return 43;
            case "engine":
                return 44;
            case "train":
                return 45;
            case "helicopter":
                return 40;
            case "chainsaw":
                return 41;
            case "siren":
                return 42;
            case "keyboard_typing":
                return 32;
            case "vacuum_cleaner":
                return 36;
            case "clock_tick":
                return 38;
            case "crackling_fire":
                return 12;
            default:
                return -1;
        }
    }

    private double[] resample(double[] input, int srcRate, int dstRate, int targetLength) {
        if (input == null || input.length == 0) {
            return new double[targetLength];
        }
        double[] output = new double[targetLength];
        double ratio = (double) srcRate / dstRate;
        for (int i = 0; i < targetLength; i++) {
            int srcIdx = (int) (i * ratio);
            if (srcIdx < input.length) {
                output[i] = input[srcIdx];
            }
        }
        return output;
    }

    private double calculateStd(double[] data) {
        if (data == null || data.length == 0)
            return 0;
        double mean = 0;
        for (double d : data)
            mean += d;
        mean /= data.length;
        double variance = 0;
        for (double d : data)
            variance += (d - mean) * (d - mean);
        return Math.sqrt(variance / data.length);
    }

    public double goertzel(double[] signal, double targetFreq) {
        int N = signal.length;
        if (N == 0)
            return 0;
        int k = (int) (0.5 + (N * targetFreq) / FS);
        double w = (2 * Math.PI / N) * k;
        double coeff = 2 * Math.cos(w);

        double sPrev1 = 0;
        double sPrev2 = 0;
        for (double x : signal) {
            double s = x + coeff * sPrev1 - sPrev2;
            sPrev2 = sPrev1;
            sPrev1 = s;
        }

        return sPrev1 * sPrev1 + sPrev2 * sPrev2 - coeff * sPrev1 * sPrev2;
    }

    public Character identifyKey(double[] signal) {
        return identifyKeyWithThreshold(signal, 0.0);
    }

    public Character identifyKeyWithThreshold(double[] signal, double minPeakRatio) {
        double maxLPow = -1;
        double bestL = -1;
        double totalL = 0;
        for (double f : LOW_FREQS) {
            double p = goertzel(signal, f);
            totalL += p;
            if (p > maxLPow) {
                maxLPow = p;
                bestL = f;
            }
        }

        double maxHPow = -1;
        double bestH = -1;
        double totalH = 0;
        for (double f : HIGH_FREQS) {
            double p = goertzel(signal, f);
            totalH += p;
            if (p > maxHPow) {
                maxHPow = p;
                bestH = f;
            }
        }

        double avgL = (totalL - maxLPow) / (LOW_FREQS.length - 1);
        double avgH = (totalH - maxHPow) / (HIGH_FREQS.length - 1);
        double ratioL = maxLPow / (avgL + 1e-10);
        double ratioH = maxHPow / (avgH + 1e-10);

        if (ratioL < minPeakRatio || ratioH < minPeakRatio) {
            return null;
        }

        for (Map.Entry<Character, double[]> entry : FREQ_MAP.entrySet()) {
            if (entry.getValue()[0] == bestL && entry.getValue()[1] == bestH) {
                return entry.getKey();
            }
        }
        return null;
    }

    // 自适应检测核心逻辑 - 渐进式探测版本
    // 策略：从短窗口开始尝试，如果置信度不足则逐步延长
    // 确保在各种 SNR 条件下都能可靠检测
    public Map<String, Object> adaptiveDetect(double[] longSignal) {
        // 可用的探测窗口（毫秒）：从快到慢
        final int[] PROBE_DURATIONS_MS = { 40, 80, 160, 320, 640, 1000 };

        // SNR 阈值：在该 SNR 以上认为检测可靠
        // 根据实验，需要约 8-10dB 的 SNR 才能可靠检测 DTMF
        final double RELIABLE_SNR = 10.0;

        // 峰值比阈值：DTMF 双峰能量占总能量的比例
        // 高于此值说明信号特征明显
        final double RELIABLE_PEAK_RATIO = 0.7;

        Character bestResult = null;
        String bestMode = "Unknown";
        QualityResult bestQuality = new QualityResult();
        double usedDuration = 0;

        // 渐进式探测：从短到长尝试
        for (int durationMs : PROBE_DURATIONS_MS) {
            double duration = durationMs / 1000.0;

            // 确保不超过可用信号长度
            if (duration * FS > longSignal.length) {
                duration = (double) longSignal.length / FS;
            }

            double[] probeSig = truncate(longSignal, duration);
            QualityResult q = estimateQuality(probeSig);

            // 尝试识别
            Character result = identifyKeyWithThreshold(probeSig, getDynamicThreshold(durationMs));

            // 更新最佳结果
            if (result != null) {
                bestResult = result;
                bestQuality = q;
                usedDuration = duration;
                bestMode = getModeName(durationMs);

                // 判断是否足够可靠可以停止
                if (q.snr >= RELIABLE_SNR && q.peakRatio >= RELIABLE_PEAK_RATIO) {
                    // 信号质量足够好，可以提前返回
                    break;
                }
            }

            // 如果已经到最长窗口，无论如何都返回结果
            if (durationMs == PROBE_DURATIONS_MS[PROBE_DURATIONS_MS.length - 1]) {
                if (bestMode.equals("Unknown") && result == null) {
                    bestMode = getModeName(durationMs);
                }
                break;
            }

            // 如果 SNR 还不够，继续尝试更长窗口
            if (q.snr < RELIABLE_SNR || q.peakRatio < RELIABLE_PEAK_RATIO) {
                continue;
            }

            // SNR 足够且有结果，可以停止
            if (result != null) {
                break;
            }
        }

        return buildResult(
                truncate(longSignal, usedDuration > 0 ? usedDuration : 0.04),
                bestMode,
                bestQuality);
    }

    // 根据信号时长获取动态检测阈值
    private double getDynamicThreshold(int durationMs) {
        if (durationMs <= 50)
            return 1.5; // 极短信号：宽松
        if (durationMs <= 100)
            return 2.0; // 短信号
        if (durationMs <= 200)
            return 2.5; // 中短信号
        if (durationMs <= 400)
            return 3.0; // 中等信号
        return 3.5; // 长信号：较严格
    }

    // 获取模式名称
    private String getModeName(int durationMs) {
        if (durationMs <= 50)
            return "Fast(" + durationMs + "ms)";
        if (durationMs <= 200)
            return "Standard(" + durationMs + "ms)";
        return "Deep(" + durationMs + "ms)";
    }

    private double[] truncate(double[] sig, double duration) {
        int len = Math.min(sig.length, (int) (FS * duration));
        double[] res = new double[len];
        System.arraycopy(sig, 0, res, 0, len);
        return res;
    }

    private static class QualityResult {
        double snr;
        double peakRatio;
    }

    private QualityResult estimateQuality(double[] signal) {
        // 使用频域方法估算 SNR：计算 DTMF 双频峰值能量与噪声能量的比值
        double[] allFreqs = { 697, 770, 852, 941, 1209, 1336, 1477, 1633 };
        double[] energies = new double[8];
        double totalEnergy = 0;

        for (int i = 0; i < 8; i++) {
            energies[i] = goertzel(signal, allFreqs[i]);
            totalEnergy += energies[i];
        }

        // 找出最大的两个峰值（低频组一个，高频组一个）
        double maxLow = 0, maxHigh = 0;
        int maxLowIdx = 0, maxHighIdx = 4;
        for (int i = 0; i < 4; i++) {
            if (energies[i] > maxLow) {
                maxLow = energies[i];
                maxLowIdx = i;
            }
        }
        for (int i = 4; i < 8; i++) {
            if (energies[i] > maxHigh) {
                maxHigh = energies[i];
                maxHighIdx = i;
            }
        }

        // 信号能量 = 两个主频能量之和
        double signalEnergy = maxLow + maxHigh;

        // 噪声能量 = 其他6个频率的平均能量 × 6
        double noiseEnergy = 0;
        for (int i = 0; i < 8; i++) {
            if (i != maxLowIdx && i != maxHighIdx) {
                noiseEnergy += energies[i];
            }
        }
        // 避免除零
        noiseEnergy = Math.max(noiseEnergy, 1e-10);

        QualityResult res = new QualityResult();
        // SNR = 10 * log10(信号能量 / 噪声能量)
        res.snr = 10 * Math.log10(signalEnergy / noiseEnergy);

        // 峰值比：双峰能量占总能量的比例（用于检测可信度评估）
        res.peakRatio = signalEnergy / (totalEnergy + 1e-10);

        return res;
    }

    private Map<String, Object> buildResult(double[] signal, String mode, QualityResult q) {
        Map<String, Object> res = new HashMap<>();

        // 根据信号长度动态调整阈值
        // 短信号能量积累少，需要更宽松的阈值
        double signalDurationMs = (double) signal.length / FS * 1000;
        double threshold;
        if (signalDurationMs < 60) {
            threshold = 1.5; // 极短信号：非常宽松
        } else if (signalDurationMs < 150) {
            threshold = 2.0; // 短信号：较宽松
        } else if (signalDurationMs < 300) {
            threshold = 3.0; // 中等信号：标准
        } else {
            threshold = 5.0; // 长信号：严格
        }

        res.put("identified", identifyKeyWithThreshold(signal, threshold));
        res.put("mode", mode);
        res.put("snrEstimate", q.snr);
        res.put("peakRatio", q.peakRatio);

        // 计算并返回信号时长（毫秒）- 复用上面已计算的 signalDurationMs
        res.put("signalDuration", signalDurationMs);

        // 返回波形采样 (最多500个点用于前端显示)
        int sampleCount = Math.min(500, signal.length);
        double[] waveformSample = new double[sampleCount];
        double step = (double) signal.length / sampleCount;
        for (int i = 0; i < sampleCount; i++) {
            waveformSample[i] = signal[(int) (i * step)];
        }
        res.put("waveformSample", waveformSample);

        // 返回 Goertzel 能量分布 (用于前端频谱显示)

        // 返回能量数组 (按频率顺序: 697, 770, 852, 941, 1209, 1336, 1477, 1633)
        double[] energyArray = new double[8];
        for (int i = 0; i < LOW_FREQS.length; i++) {
            energyArray[i] = goertzel(signal, LOW_FREQS[i]);
        }
        for (int i = 0; i < HIGH_FREQS.length; i++) {
            energyArray[4 + i] = goertzel(signal, HIGH_FREQS[i]);
        }
        res.put("energies", energyArray);

        return res;
    }

    public Map<String, Object> runComparison(char key, double snr) {
        return runComparison(key, snr, "GAUSSIAN", 0.0);
    }

    public Map<String, Object> runComparison(char key, double snr, String noiseTypeStr) {
        return runComparison(key, snr, noiseTypeStr, 0.0);
    }

    public Map<String, Object> runComparison(char key, double snr, String noiseTypeStr, double freqOffset) {
        NoiseType noiseType = NoiseType.valueOf(noiseTypeStr.toUpperCase());
        double[] longSignal = generateDtmf(key, 1.0, snr, noiseType, freqOffset);

        double[] sig200 = truncate(longSignal, 0.2);
        Map<String, Object> standardRes = buildResult(sig200, "Standard(200ms)", estimateQuality(sig200));
        Map<String, Object> adaptiveRes = adaptiveDetect(longSignal);

        Map<String, Object> finalRes = new HashMap<>();
        finalRes.put("standard", standardRes);
        finalRes.put("adaptive", adaptiveRes);
        finalRes.put("key", key);
        finalRes.put("snr", snr);
        finalRes.put("noiseType", noiseTypeStr);
        finalRes.put("freqOffset", freqOffset);
        return finalRes;
    }

    public Map<String, Object> runExperiment(char key, double snr, boolean useAdaptive) {
        return runExperiment(key, snr, useAdaptive, "GAUSSIAN", 0.0);
    }

    public Map<String, Object> runExperiment(char key, double snr, boolean useAdaptive, String noiseTypeStr) {
        return runExperiment(key, snr, useAdaptive, noiseTypeStr, 0.0);
    }

    public Map<String, Object> runExperiment(char key, double snr, boolean useAdaptive, String noiseTypeStr,
            double freqOffset) {
        NoiseType noiseType = NoiseType.valueOf(noiseTypeStr.toUpperCase());

        // Generate clean signal (without noise)
        double[] cleanSignal = generateDtmf(key, 1.0, null, noiseType, 0.0);

        // Generate noisy signal with frequency offset
        double[] noisySignal = generateDtmf(key, 1.0, snr, noiseType, freqOffset);

        Map<String, Object> res;
        if (useAdaptive) {
            res = adaptiveDetect(noisySignal);
        } else {
            double[] sig200 = truncate(noisySignal, 0.2);
            res = buildResult(sig200, "Fixed(200ms)", estimateQuality(sig200));
        }

        res.put("key", key);
        res.put("snr", snr);
        res.put("noiseType", noiseTypeStr);
        res.put("freqOffset", freqOffset);

        // Add waveform samples for display and audio playback
        // Use 4000 samples (~0.5s at 8kHz) for decent audio quality
        int sampleCount = 4000;
        double[] cleanWaveform = new double[sampleCount];
        double step = (double) cleanSignal.length / sampleCount;
        for (int i = 0; i < sampleCount; i++) {
            cleanWaveform[i] = cleanSignal[(int) (i * step)];
        }
        res.put("cleanWaveform", cleanWaveform);

        // Noisy waveform for playback
        double[] noisyWaveform = new double[sampleCount];
        for (int i = 0; i < sampleCount; i++) {
            int idx = (int) (i * step);
            if (idx < noisySignal.length) {
                noisyWaveform[i] = noisySignal[idx];
            }
        }
        res.put("noisyWaveform", noisyWaveform);

        return res;
    }

    // ========== 电话模式功能 ==========

    // 开始新的电话会话
    public Map<String, Object> startPhoneSession() {
        SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMdd_HHmmss");
        String sessionName = "call_" + sdf.format(new Date());

        // 获取项目根目录 (java-web的上级目录)
        String projectRoot = System.getProperty("user.dir");
        if (projectRoot.endsWith("java-web")) {
            projectRoot = new File(projectRoot).getParent();
        }

        Path audioDir = Paths.get(projectRoot, "audio", sessionName);
        // Note: Do not create directory yet. We prefer lazy creation on first key press
        // to avoid empty folders for sessions with no activity.
        currentSessionFolder = audioDir.toString();
        keyPressIndex = 0;

        // Clear last hardware events to prevent false triggers on startup
        this.lastKey = null;
        this.lastResult = null;
        this.lastKeyTime = 0;

        Map<String, Object> result = new HashMap<>();
        result.put("success", true);
        result.put("sessionName", sessionName);
        result.put("sessionPath", currentSessionFolder);
        result.put("message", "会话已就绪: " + sessionName);
        return result;
    }

    // 按键并保存音频
    public Map<String, Object> pressKeyAndSave(char key, double duration, Double snrDb, String noiseTypeStr,
            String source, double[] fpgaWaveform) {
        if (currentSessionFolder == null) {
            Map<String, Object> result = new HashMap<>();
            result.put("success", false);
            result.put("error", "请先开始电话会话");
            return result;
        }

        double[] signal;
        boolean isFromFpga = fpgaWaveform != null && fpgaWaveform.length > 0;

        if (isFromFpga) {
            // Use actual FPGA waveform (contains real PWM noise)
            signal = fpgaWaveform;
        } else {
            // Generate synthetic signal with noise
            NoiseType noiseType = noiseTypeStr != null ? NoiseType.valueOf(noiseTypeStr.toUpperCase())
                    : NoiseType.GAUSSIAN;
            signal = generateDtmf(key, duration, snrDb, noiseType);
        }

        keyPressIndex++;
        String filename = String.format("%02d_%c.wav", keyPressIndex, key);
        Path filepath = Paths.get(currentSessionFolder, filename);

        try {
            // Lazy creation: Ensure directory exists before saving
            Files.createDirectories(Paths.get(currentSessionFolder));

            saveAsWav(signal, filepath.toString());

            Map<String, Object> result = new HashMap<>();
            result.put("success", true);
            result.put("key", key);
            result.put("index", keyPressIndex);
            result.put("filename", filename);
            result.put("filepath", filepath.toString());
            result.put("duration", duration);

            // 使用自适应算法进行实时识别
            Map<String, Object> adaptiveResult = adaptiveDetect(signal);
            Character identified = (Character) adaptiveResult.get("identified");
            result.put("identified", identified);
            result.put("identifySuccess", key == (identified != null ? identified : ' '));
            result.put("mode", adaptiveResult.get("mode")); // 使用的算法模式
            result.put("signalDuration", adaptiveResult.get("signalDuration")); // 实际使用的信号时长
            result.put("snrEstimate", adaptiveResult.get("snrEstimate")); // 估算的 SNR
            result.put("energies", adaptiveResult.get("energies")); // 频谱能量
            result.put("waveformSample", adaptiveResult.get("waveformSample")); // 波形采样

            // 返回加噪波形用于前端播放
            int sampleCount = Math.min(signal.length, 4000);
            double[] noisyWaveform = new double[sampleCount];
            System.arraycopy(signal, 0, noisyWaveform, 0, sampleCount);
            result.put("noisyWaveform", noisyWaveform);

            // Update memory state for polling ONLY if source is NOT 'web'
            // This prevents the web client from detecting its own key presses as "new
            // hardware events"
            if (source == null || !source.equalsIgnoreCase("web")) {
                this.lastKey = key;
                this.lastKeyTime = System.currentTimeMillis();
                this.lastResult = new HashMap<>(result);
                this.lastResult.remove("noisyWaveform"); // removing heavy data
            }

            return result;
        } catch (IOException e) {
            Map<String, Object> result = new HashMap<>();
            result.put("success", false);
            result.put("error", e.getMessage());
            return result;
        }
    }

    // 结束会话
    public Map<String, Object> endPhoneSession() {
        if (currentSessionFolder == null) {
            Map<String, Object> result = new HashMap<>();
            result.put("success", false);
            result.put("error", "没有活动的会话");
            return result;
        }

        Map<String, Object> result = new HashMap<>();
        result.put("success", true);
        result.put("sessionPath", currentSessionFolder);
        result.put("totalKeys", keyPressIndex);
        currentSessionFolder = null;
        keyPressIndex = 0;

        return result;
    }

    // Get last key press (for polling)
    public Map<String, Object> getLastKey(long sinceTime) {
        Map<String, Object> result = new HashMap<>();
        if (lastKey != null && lastKeyTime > sinceTime) {
            result.put("hasNew", true);
            result.put("key", lastKey);
            result.put("time", lastKeyTime);
            if (lastResult != null) {
                result.putAll(lastResult);
            }
        } else {
            result.put("hasNew", false);
        }
        return result;
    }

    // 获取所有可用的电话会话
    public Map<String, Object> listPhoneSessions() {
        String projectRoot = System.getProperty("user.dir");
        if (projectRoot.endsWith("java-web")) {
            projectRoot = new File(projectRoot).getParent();
        }

        Path audioDir = Paths.get(projectRoot, "audio");
        List<Map<String, Object>> sessions = new ArrayList<>();

        try {
            if (Files.exists(audioDir)) {
                Files.list(audioDir)
                        .filter(Files::isDirectory)
                        .sorted(Comparator.reverseOrder())
                        .forEach(path -> {
                            Map<String, Object> session = new HashMap<>();
                            session.put("name", path.getFileName().toString());
                            session.put("path", path.toString());
                            try {
                                long fileCount = Files.list(path).filter(p -> p.toString().endsWith(".wav")).count();
                                session.put("fileCount", fileCount);
                            } catch (IOException e) {
                                session.put("fileCount", 0);
                            }
                            sessions.add(session);
                        });
            }
        } catch (IOException e) {
            // ignore
        }

        Map<String, Object> result = new HashMap<>();
        result.put("sessions", sessions);
        result.put("currentSession", currentSessionFolder);
        return result;
    }

    // 删除指定的电话会话
    public Map<String, Object> deletePhoneSession(String sessionName) {
        String projectRoot = System.getProperty("user.dir");
        if (projectRoot.endsWith("java-web")) {
            projectRoot = new File(projectRoot).getParent();
        }

        Path sessionDir = Paths.get(projectRoot, "audio", sessionName);
        Map<String, Object> result = new HashMap<>();

        if (!Files.exists(sessionDir)) {
            result.put("success", false);
            result.put("error", "会话不存在: " + sessionName);
            return result;
        }

        // 安全检查：只允许删除 call_ 开头的会话文件夹
        if (!sessionName.startsWith("call_")) {
            result.put("success", false);
            result.put("error", "不允许删除非会话文件夹");
            return result;
        }

        try {
            // 递归删除目录及其内容
            Files.walk(sessionDir)
                    .sorted(Comparator.reverseOrder())
                    .forEach(path -> {
                        try {
                            Files.delete(path);
                        } catch (IOException e) {
                            // ignore individual file errors
                        }
                    });

            result.put("success", true);
            result.put("message", "会话已删除: " + sessionName);
            return result;
        } catch (IOException e) {
            result.put("success", false);
            result.put("error", "删除失败: " + e.getMessage());
            return result;
        }
    }

    // 分析指定会话中的音频文件,识别电话号码
    // duration: null/0 = full signal, "adaptive" = auto, or specific duration in
    // seconds (e.g., "0.2")
    public Map<String, Object> analyzePhoneSession(String sessionName, String durationStr) {
        String projectRoot = System.getProperty("user.dir");
        if (projectRoot.endsWith("java-web")) {
            projectRoot = new File(projectRoot).getParent();
        }

        Path sessionDir = Paths.get(projectRoot, "audio", sessionName);

        if (!Files.exists(sessionDir)) {
            Map<String, Object> result = new HashMap<>();
            result.put("success", false);
            result.put("error", "会话不存在: " + sessionName);
            return result;
        }

        // Parse duration parameter
        boolean useAdaptive = "adaptive".equalsIgnoreCase(durationStr);
        double fixedDuration = 0; // 0 means full signal
        if (durationStr != null && !durationStr.isEmpty() && !useAdaptive) {
            try {
                fixedDuration = Double.parseDouble(durationStr);
            } catch (NumberFormatException e) {
                // Ignore, use full signal
            }
        }

        List<Map<String, Object>> analysisResults = new ArrayList<>();
        StringBuilder phoneNumber = new StringBuilder();

        try {
            List<Path> wavFiles = Files.list(sessionDir)
                    .filter(p -> p.toString().endsWith(".wav"))
                    .sorted()
                    .toList();

            for (Path wavFile : wavFiles) {
                try {
                    double[] signal = loadWav(wavFile.toString());

                    Map<String, Object> detectResult;
                    String mode;

                    // 记录开始时间
                    long startTime = System.nanoTime();

                    if (useAdaptive) {
                        // Use adaptive detection
                        detectResult = adaptiveDetect(signal);
                        mode = (String) detectResult.get("mode");
                    } else if (fixedDuration > 0) {
                        // Use specified fixed duration (cap to signal length if needed)
                        double effectiveDuration = Math.min(fixedDuration, (double) signal.length / FS);
                        double[] truncatedSignal = truncate(signal, effectiveDuration);
                        int durationMs = (int) (effectiveDuration * 1000);
                        mode = "Fixed(" + durationMs + "ms)";
                        detectResult = buildResult(truncatedSignal, mode, estimateQuality(truncatedSignal));
                    } else {
                        // Use full signal (Deep mode) - only when no duration specified
                        mode = "Deep(Full)";
                        detectResult = buildResult(signal, mode, estimateQuality(signal));
                    }

                    // 计算处理耗时（毫秒）
                    long endTime = System.nanoTime();
                    double processTimeMs = (endTime - startTime) / 1_000_000.0;

                    Character identified = (Character) detectResult.get("identified");

                    Map<String, Object> fileResult = new HashMap<>();
                    fileResult.put("filename", wavFile.getFileName().toString());
                    fileResult.put("identified", identified);
                    fileResult.put("sampleCount", signal.length);
                    fileResult.put("mode", mode);
                    fileResult.put("snrEstimate", detectResult.get("snrEstimate"));
                    fileResult.put("signalDuration", detectResult.get("signalDuration")); // 自适应算法使用的信号时长(ms)
                    fileResult.put("processTimeMs", Math.round(processTimeMs * 100) / 100.0); // 保留2位小数

                    // Add visualization data (energies and waveform)
                    fileResult.put("energies", detectResult.get("energies"));
                    fileResult.put("waveformSample", detectResult.get("waveformSample")); // 确保包含波形数据

                    // 从文件名提取原始按键 (格式: 01_5.wav)
                    String fname = wavFile.getFileName().toString();
                    try {
                        if (fname.contains("_") && fname.contains(".")) {
                            String[] parts = fname.split("_");
                            if (parts.length > 1) {
                                char originalKey = parts[1].charAt(0);
                                fileResult.put("originalKey", originalKey);
                                fileResult.put("match", identified != null && identified == originalKey);
                            }
                        }
                    } catch (Exception e) {
                        // Ignore filename parsing errors
                        fileResult.put("originalKey", '?');
                        fileResult.put("match", false);
                    }

                    analysisResults.add(fileResult);
                    if (identified != null) {
                        phoneNumber.append(identified);
                    } else {
                        phoneNumber.append("?");
                    }
                } catch (Exception e) {
                    System.err.println("Error analyzing file " + wavFile + ": " + e.getMessage());
                    // Continue to next file
                }
            }

            Map<String, Object> result = new HashMap<>();
            result.put("success", true);
            result.put("sessionName", sessionName);
            result.put("phoneNumber", phoneNumber.toString());
            result.put("totalFiles", wavFiles.size());
            result.put("details", analysisResults);

            // 计算识别准确率
            long correctCount = analysisResults.stream()
                    .filter(r -> Boolean.TRUE.equals(r.get("match")))
                    .count();
            result.put("accuracy", wavFiles.isEmpty() ? 0 : (double) correctCount / wavFiles.size() * 100);

            return result;
        } catch (Exception e) {
            e.printStackTrace();
            Map<String, Object> result = new HashMap<>();
            result.put("success", false);
            result.put("error", e.getClass().getSimpleName() + ": " + e.getMessage());
            return result;
        }
    }

    // ========== WAV 文件 I/O ==========

    private void saveAsWav(double[] signal, String filepath) throws IOException {
        int numSamples = signal.length;
        int byteRate = FS * 2; // 16-bit mono
        int dataSize = numSamples * 2;

        try (DataOutputStream dos = new DataOutputStream(new FileOutputStream(filepath))) {
            // RIFF header
            dos.writeBytes("RIFF");
            dos.writeInt(Integer.reverseBytes(36 + dataSize));
            dos.writeBytes("WAVE");

            // fmt chunk
            dos.writeBytes("fmt ");
            dos.writeInt(Integer.reverseBytes(16)); // chunk size
            dos.writeShort(Short.reverseBytes((short) 1)); // PCM format
            dos.writeShort(Short.reverseBytes((short) 1)); // mono
            dos.writeInt(Integer.reverseBytes(FS)); // sample rate
            dos.writeInt(Integer.reverseBytes(byteRate)); // byte rate
            dos.writeShort(Short.reverseBytes((short) 2)); // block align
            dos.writeShort(Short.reverseBytes((short) 16)); // bits per sample

            // data chunk
            dos.writeBytes("data");
            dos.writeInt(Integer.reverseBytes(dataSize));

            // Normalize and write samples
            // 使用保守的归一化，保留更多动态范围用于微弱信号
            double maxVal = 0;
            for (double s : signal)
                maxVal = Math.max(maxVal, Math.abs(s));

            // 使用 0.8 倍峰值归一化，给低幅度信号留更多量化空间
            // 同时限制最大放大倍数，防止过度放大噪声中的微弱信号
            double scale = maxVal > 0 ? Math.min(32767.0 / maxVal * 0.8, 16000.0) : 1.0;

            for (double s : signal) {
                short sample = (short) Math.max(-32768, Math.min(32767, s * scale));
                dos.writeShort(Short.reverseBytes(sample));
            }
        }
    }

    private double[] loadWav(String filepath) throws IOException {
        try (DataInputStream dis = new DataInputStream(new BufferedInputStream(new FileInputStream(filepath)))) {
            // 1. RIFF Header
            byte[] buffer = new byte[4];
            dis.readFully(buffer);
            if (!"RIFF".equals(new String(buffer)))
                throw new IOException("Not a valid RIFF file");

            dis.readInt(); // Skip file size (can be ignored)

            dis.readFully(buffer);
            if (!"WAVE".equals(new String(buffer)))
                throw new IOException("Not a valid WAVE file");

            // 2. Scan Chunks
            while (dis.available() > 0) {
                // Read Chunk ID
                try {
                    dis.readFully(buffer);
                } catch (EOFException e) {
                    break;
                }
                String chunkId = new String(buffer);

                // Read Chunk Size (Little Endian)
                int chunkSize = Integer.reverseBytes(dis.readInt());

                if ("data".equals(chunkId)) {
                    // Found audio data
                    int numSamples = chunkSize / 2; // 16-bit = 2 bytes per sample
                    double[] signal = new double[numSamples];

                    for (int i = 0; i < numSamples; i++) {
                        // Read 16-bit Little Endian
                        int low = dis.read();
                        int high = dis.read();
                        if (low == -1 || high == -1)
                            break; // Unexpected EOF

                        int sample = (high << 8) | low;
                        // Sign extend for 16-bit
                        if (sample > 32767)
                            sample -= 65536;

                        signal[i] = sample / 32768.0;
                    }
                    return signal;
                } else {
                    // Skip other chunks (fmt, LIST, etc.)
                    long skipped = dis.skipBytes(chunkSize);
                    // Ensure we skipped everything (handle odd-sized chunks pad byte?)
                    // RIFF standard: chunks are word-aligned. If size is odd, there's a pad byte.
                    // But DataInputStream.readInt handles 4 bytes.
                    // Let's just rely on skipBytes. Ideally loop it.
                    while (skipped < chunkSize) {
                        long s = dis.skip(chunkSize - skipped);
                        if (s <= 0)
                            break;
                        skipped += s;
                    }
                }
            }
            throw new IOException("No data chunk found in WAV file");
        }
    }

    // 获取当前会话状态
    public Map<String, Object> getSessionStatus() {
        Map<String, Object> result = new HashMap<>();
        result.put("hasActiveSession", currentSessionFolder != null);
        result.put("sessionPath", currentSessionFolder);
        result.put("keyPressCount", keyPressIndex);
        return result;
    }
}
