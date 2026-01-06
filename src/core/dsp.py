import numpy as np
from scipy import signal as scipy_signal
from . import config

def bandpass_filter(sig, low_freq=600, high_freq=1600, order=4):
    """
    带通滤波预处理，保留 DTMF 频段 (600-1600Hz)
    """
    nyquist = config.fs / 2
    low = low_freq / nyquist
    high = high_freq / nyquist
    b, a = scipy_signal.butter(order, [low, high], btype='band')
    filtered = scipy_signal.filtfilt(b, a, sig)
    return filtered

def generate_dtmf(key, snr_db=None, duration=None):
    """
    生成 DTMF 信号
    :param key: 按键字符
    :param snr_db: 信噪比 (dB)，若为 None 则不加噪
    :param duration: 信号时长 (s)，若为 None 则使用 config 默认值
    :return: 信号数组
    """
    if duration is None:
        duration = config.duration
        
    fL, fH = config.freq_map[key]
    t = np.linspace(0, duration, int(config.fs * duration), endpoint=False)
    signal = np.sin(2 * np.pi * fL * t) + np.sin(2 * np.pi * fH * t)
    
    if snr_db is not None:
        signal_power = np.mean(signal**2)
        snr_linear = 10**(snr_db / 10)
        noise_power = signal_power / snr_linear
        noise = np.random.normal(0, np.sqrt(noise_power), len(signal))
        signal = signal + noise
        
    return signal

def goertzel(signal, target_freq):
    """
    Goertzel 算法计算特定频率能量
    """
    N = len(signal)
    if N == 0: return 0
    k = int(0.5 + (N * target_freq) / config.fs)
    w = (2 * np.pi / N) * k
    coeff = 2 * np.cos(w)
    
    s_prev1 = 0
    s_prev2 = 0
    for x in signal:
        s = x + coeff * s_prev1 - s_prev2
        s_prev2 = s_prev1
        s_prev1 = s
    
    power = s_prev1**2 + s_prev2**2 - coeff * s_prev1 * s_prev2
    return power

def identify_key(signal, use_filter=False, require_valid=False):
    """
    识别 DTMF 信号对应的按键
    :param signal: 输入信号
    :param use_filter: 是否使用带通滤波预处理
    :param require_valid: 是否要求通过有效性验证（能量门限+峰值显著性）
    :return: 按键字符，若 require_valid=True 且验证失败则返回 None
    """
    if use_filter:
        signal = bandpass_filter(signal)
    
    l_powers = [goertzel(signal, f) for f in config.low_freqs]
    h_powers = [goertzel(signal, f) for f in config.high_freqs]
    
    # ===== 有效性验证 =====
    if require_valid:
        # 检验1：峰值显著性 - 最大能量应显著高于次大能量
        sorted_l = sorted(l_powers, reverse=True)
        sorted_h = sorted(h_powers, reverse=True)
        
        # 峰值比阈值：最大值至少是次大值的 1.5 倍
        PEAK_RATIO_THRESHOLD = 1.5
        ratio_l = sorted_l[0] / (sorted_l[1] + 1e-10)
        ratio_h = sorted_h[0] / (sorted_h[1] + 1e-10)
        
        if ratio_l < PEAK_RATIO_THRESHOLD or ratio_h < PEAK_RATIO_THRESHOLD:
            return None  # 峰值不够显著，可能是噪声
        
        # 检验2：能量门限 - DTMF 能量需高于信号总能量的一定比例
        total_signal_power = np.mean(signal**2)
        dtmf_power = sorted_l[0] + sorted_h[0]
        
        # 归一化后的 DTMF 能量占比阈值
        ENERGY_RATIO_THRESHOLD = 0.01  # DTMF 能量应占总能量的至少 1%
        if total_signal_power > 0:
            energy_ratio = dtmf_power / (total_signal_power * len(signal))
            if energy_ratio < ENERGY_RATIO_THRESHOLD:
                return None  # 能量太低，可能无有效按键
    
    # ===== 最大值判决 =====
    best_l = config.low_freqs[np.argmax(l_powers)]
    best_h = config.high_freqs[np.argmax(h_powers)]
    
    for key, (fL, fH) in config.freq_map.items():
        if fL == best_l and fH == best_h:
            return key
    return None

def run_performance_test():
    """
    运行 SNR 性能测试
    """
    # 扩大噪声范围到 -30dB 到 10dB
    snr_range = np.arange(-30, 11, 2)
    accuracies = []
    iterations = 200 
    
    # 临时缩短 duration 以模拟更苛刻的拨号环境 (40ms)
    test_duration = 0.04 
    
    for snr in snr_range:
        correct = 0
        for _ in range(iterations):
            key = np.random.choice(config.keys)
            
            # 生成带噪信号
            sig_noisy = generate_dtmf(key, snr_db=snr, duration=test_duration)
            
            if identify_key(sig_noisy) == key:
                correct += 1
        accuracies.append(correct / iterations)
        
    return snr_range, accuracies
