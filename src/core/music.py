"""
MUSIC (Multiple Signal Classification) Algorithm Implementation for DTMF
基于子空间的高分辨率频率估计算法
"""
import numpy as np
from scipy import linalg
from . import config

class MusicDetector:
    def __init__(self, fs=8000, n_elements=100, n_signals=4):
        """
        初始化 MUSIC 检测器
        :param fs: 采样率
        :param n_elements: 观测向量长度 (M)，即子空间维数，相当于 DFT 的 N
                           也常称为 M (阵元数/抽头数)。需满足 p < M < N_samples
        :param n_signals: 预计信号源数量 (p)。DTMF 是双音实信号，包含 2 个频率成分。
                          每个实正弦波对应 2 个复指数 (e^jwt, e^-jwt)，
                          所以理论上信号子空间维数为 4。
        """
        self.fs = fs
        self.M = n_elements
        self.p = n_signals
        
    def compute_spectrum(self, signal, freq_grid):
        """
        计算指定频率点的 MUSIC 伪谱
        :param signal: 输入信号 (时域采样)
        :param freq_grid: 需要计算伪谱的频率点数组
        :return: 伪谱值 (dB)
        """
        N = len(signal)
        if N < self.M:
            raise ValueError(f"Signal length {N} must be greater than subspace dimension {self.M}")
            
        # 1. 构造自相关矩阵 (Covariance Matrix)
        # 使用空间平滑技术或简单的数据矩阵重排
        # 这里使用前向-后向平均或简单的快拍数据矩阵构造
        
        # 构造数据矩阵 X (Hankel Matrix 形式，模拟滑动窗口)
        # 列数 K = N - M + 1
        K = N - self.M + 1
        X = linalg.hankel(signal[:self.M], signal[self.M-1:]) 
        
        # 计算自相关矩阵 R = (1/K) * X * X^H
        R = (1/K) * (X @ X.T)
        
        # 2. 特征分解
        eigvals, eigvecs = linalg.eigh(R)
        
        # linalg.eigh 返回的特征值是升序排列的
        # 噪声子空间对应较小的特征值 (前 M-p 个)
        # 信号子空间对应较大的特征值 (后 p 个)
        
        # 获取噪声子空间特征向量 En (Noise Subspace)
        # 维度: (M, M-p)
        En = eigvecs[:, :self.M - self.p]
        
        # 3. 计算伪谱 P_music(f) = 1 / (a^H * En * En^H * a)
        # 预计算噪声投影矩阵 Pn = En * En^H
        Pn = En @ En.T
        
        spectrum = []
        for f in freq_grid:
            # 构造导向矢量 a(f) = [1, e^-jw, ..., e^-j(M-1)w]^T
            # 注意：这里的相位符号取决于定义，通常 e^{-j\omega n}
            w = 2 * np.pi * f / self.fs
            t = np.arange(self.M)
            a = np.exp(-1j * w * t)
            
            # 计算分母: |a^H * En|^2 = a^H * Pn * a
            # 由于 R 是实对称的，En 是实的 (如果 X 是实矩阵)
            # 但导向矢量 a 是复的。
            # P_music = 1 / abs(a.conj().T @ Pn @ a)
            
            # 优化计算: denom = a.H @ Pn @ a
            denom = np.vdot(a, Pn @ a).real
            
            # 避免除零
            if denom < 1e-15:
                ps = 100 # 极大值
            else:
                ps = 10 * np.log10(1.0 / denom)
            spectrum.append(ps)
            
        return np.array(spectrum)

    def detect(self, signal):
        """
        使用 MUSIC 算法识别 DTMF 按键
        """
        # 定义搜索频率网格：覆盖低频群和高频群
        # 为了提高效率，只搜索 DTMF 标称频率附近
        
        low_freqs = config.low_freqs
        high_freqs = config.high_freqs
        
        # 计算伪谱
        # 我们只关心 8 个标准频率点的伪谱高度
        target_freqs = low_freqs + high_freqs
        spectrum = self.compute_spectrum(signal, target_freqs)
        
        # 分离低频和高频的谱值
        l_spectrum = spectrum[:4]
        h_spectrum = spectrum[4:]
        
        # 找峰值
        idx_l = np.argmax(l_spectrum)
        idx_h = np.argmax(h_spectrum)
        
        best_l = low_freqs[idx_l]
        best_h = high_freqs[idx_h]
        
        # 匹配按键
        for key, (fL, fH) in config.freq_map.items():
            if fL == best_l and fH == best_h:
                return key, (l_spectrum[idx_l], h_spectrum[idx_h])
        
        return None, (0, 0)
