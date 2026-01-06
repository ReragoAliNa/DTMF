"""
spectrogram_cnn.py
基于频谱图的卷积神经网络 DTMF 分类器
这是一个轻量级的 CNN，使用 STFT 频谱图作为输入
"""
import numpy as np
import os
from sklearn.model_selection import train_test_split
from ..core import config
from ..core import dsp

# 尝试导入 PyTorch，如果没有则使用 sklearn 的 MLP 作为备选
try:
    import torch
    import torch.nn as nn
    import torch.optim as optim
    from torch.utils.data import DataLoader, TensorDataset
    HAS_TORCH = True
except ImportError:
    HAS_TORCH = False
    from sklearn.neural_network import MLPClassifier


def compute_spectrogram(signal, n_fft=128, hop_length=32):
    """
    计算短时傅里叶变换 (STFT) 频谱图
    返回: 2D 数组 (频率 x 时间)
    """
    # 简化版 STFT
    n_frames = (len(signal) - n_fft) // hop_length + 1
    spectrogram = []
    
    window = np.hanning(n_fft)
    
    for i in range(n_frames):
        start = i * hop_length
        frame = signal[start:start + n_fft] * window
        fft_result = np.abs(np.fft.rfft(frame))
        spectrogram.append(fft_result)
    
    spectrogram = np.array(spectrogram).T  # (freq_bins, time_frames)
    
    # 只取 0-2500Hz 范围（DTMF 频率都在这个范围内）
    freq_bins = n_fft // 2 + 1
    max_freq_bin = int(2500 / (config.fs / 2) * freq_bins)
    spectrogram = spectrogram[:max_freq_bin, :]
    
    # 归一化
    spectrogram = np.log1p(spectrogram)  # 对数压缩
    if spectrogram.max() > 0:
        spectrogram = spectrogram / spectrogram.max()
    
    return spectrogram


class SimpleCNN(nn.Module):
    """简单的 CNN 分类器"""
    def __init__(self, input_shape, num_classes=12):
        super(SimpleCNN, self).__init__()
        
        h, w = input_shape
        
        self.conv = nn.Sequential(
            nn.Conv2d(1, 16, kernel_size=3, padding=1),
            nn.ReLU(),
            nn.MaxPool2d(2),
            nn.Conv2d(16, 32, kernel_size=3, padding=1),
            nn.ReLU(),
            nn.MaxPool2d(2),
            nn.Conv2d(32, 64, kernel_size=3, padding=1),
            nn.ReLU(),
            nn.AdaptiveAvgPool2d((4, 4))
        )
        
        self.fc = nn.Sequential(
            nn.Flatten(),
            nn.Linear(64 * 4 * 4, 128),
            nn.ReLU(),
            nn.Dropout(0.3),
            nn.Linear(128, num_classes)
        )
    
    def forward(self, x):
        x = self.conv(x)
        x = self.fc(x)
        return x


class SpectrogramCNNClassifier:
    """频谱图 CNN 分类器"""
    
    def __init__(self):
        self.model = None
        self.key_to_idx = {key: idx for idx, key in enumerate(config.keys)}
        self.idx_to_key = {idx: key for key, idx in self.key_to_idx.items()}
        self.input_shape = None
        self.is_trained = False
    
    def _signal_to_features(self, signal):
        """将信号转换为频谱图特征"""
        spec = compute_spectrogram(signal)
        return spec
    
    def train(self, samples_per_key=500, epochs=30):
        """训练 CNN 模型"""
        print("Generating spectrogram training data...")
        
        X, y = [], []
        for key in config.keys:
            for _ in range(samples_per_key):
                # 覆盖广泛的 SNR 范围，重点低 SNR
                if np.random.random() < 0.6:
                    snr = np.random.uniform(-30, -5)
                else:
                    snr = np.random.uniform(-5, 20)
                
                signal = dsp.generate_dtmf(key, snr_db=snr)
                spec = self._signal_to_features(signal)
                X.append(spec)
                y.append(self.key_to_idx[key])
        
        X = np.array(X)
        y = np.array(y)
        
        self.input_shape = X[0].shape
        print(f"Spectrogram shape: {self.input_shape}")
        
        X_train, X_val, y_train, y_val = train_test_split(
            X, y, test_size=0.2, random_state=42
        )
        
        if HAS_TORCH:
            self._train_pytorch(X_train, y_train, X_val, y_val, epochs)
        else:
            self._train_sklearn(X_train, y_train, X_val, y_val)
        
        self.is_trained = True
    
    def _train_pytorch(self, X_train, y_train, X_val, y_val, epochs):
        """使用 PyTorch 训练"""
        print("Training CNN with PyTorch...")
        
        # 添加通道维度
        X_train = X_train[:, np.newaxis, :, :]
        X_val = X_val[:, np.newaxis, :, :]
        
        train_dataset = TensorDataset(
            torch.FloatTensor(X_train),
            torch.LongTensor(y_train)
        )
        val_dataset = TensorDataset(
            torch.FloatTensor(X_val),
            torch.LongTensor(y_val)
        )
        
        train_loader = DataLoader(train_dataset, batch_size=64, shuffle=True)
        val_loader = DataLoader(val_dataset, batch_size=64)
        
        self.model = SimpleCNN(self.input_shape, num_classes=12)
        criterion = nn.CrossEntropyLoss()
        optimizer = optim.Adam(self.model.parameters(), lr=0.001)
        
        for epoch in range(epochs):
            self.model.train()
            for batch_x, batch_y in train_loader:
                optimizer.zero_grad()
                outputs = self.model(batch_x)
                loss = criterion(outputs, batch_y)
                loss.backward()
                optimizer.step()
            
            # 验证
            if (epoch + 1) % 10 == 0:
                self.model.eval()
                correct = 0
                total = 0
                with torch.no_grad():
                    for batch_x, batch_y in val_loader:
                        outputs = self.model(batch_x)
                        _, predicted = torch.max(outputs, 1)
                        total += batch_y.size(0)
                        correct += (predicted == batch_y).sum().item()
                print(f"  Epoch {epoch+1}/{epochs}, Val Accuracy: {correct/total:.2%}")
        
        # 最终验证
        self.model.eval()
        correct = 0
        total = 0
        with torch.no_grad():
            for batch_x, batch_y in val_loader:
                outputs = self.model(batch_x)
                _, predicted = torch.max(outputs, 1)
                total += batch_y.size(0)
                correct += (predicted == batch_y).sum().item()
        print(f"Final validation accuracy: {correct/total:.2%}")
    
    def _train_sklearn(self, X_train, y_train, X_val, y_val):
        """使用 sklearn MLP 作为备选"""
        print("Training MLP with sklearn (PyTorch not available)...")
        
        # 展平频谱图
        X_train_flat = X_train.reshape(len(X_train), -1)
        X_val_flat = X_val.reshape(len(X_val), -1)
        
        self.model = MLPClassifier(
            hidden_layer_sizes=(256, 128, 64),
            max_iter=100,
            random_state=42,
            verbose=True
        )
        self.model.fit(X_train_flat, y_train)
        
        val_acc = self.model.score(X_val_flat, y_val)
        print(f"Validation accuracy: {val_acc:.2%}")
    
    def predict(self, signal):
        """预测按键"""
        if not self.is_trained:
            raise RuntimeError("Model not trained.")
        
        spec = self._signal_to_features(signal)
        
        if HAS_TORCH:
            self.model.eval()
            with torch.no_grad():
                x = torch.FloatTensor(spec[np.newaxis, np.newaxis, :, :])
                output = self.model(x)
                _, predicted = torch.max(output, 1)
                return self.idx_to_key[predicted.item()]
        else:
            spec_flat = spec.reshape(1, -1)
            pred_idx = self.model.predict(spec_flat)[0]
            return self.idx_to_key[pred_idx]


def run_cnn_comparison():
    """运行 CNN vs Goertzel 对比实验"""
    import matplotlib.pyplot as plt
    
    print("=" * 60)
    print("Spectrogram CNN vs Goertzel Comparison")
    print("=" * 60)
    
    # 训练 CNN
    cnn = SpectrogramCNNClassifier()
    cnn.train(samples_per_key=600, epochs=40)
    
    # 测试
    snr_range = np.arange(-30, 16, 2)
    iterations = 150
    
    goertzel_acc = []
    cnn_acc = []
    
    print("\nRunning comparison...")
    for snr in snr_range:
        g_correct, c_correct = 0, 0
        
        for _ in range(iterations):
            key = np.random.choice(config.keys)
            signal = dsp.generate_dtmf(key, snr_db=snr)
            
            if dsp.identify_key(signal) == key:
                g_correct += 1
            if cnn.predict(signal) == key:
                c_correct += 1
        
        goertzel_acc.append(g_correct / iterations)
        cnn_acc.append(c_correct / iterations)
        
        print(f"  SNR={snr:3d}dB: Goertzel={goertzel_acc[-1]:.1%}, CNN={cnn_acc[-1]:.1%}")
    
    # 绘图
    plt.figure(figsize=(12, 7))
    plt.plot(snr_range, goertzel_acc, 'b-o', label='Goertzel (Traditional)', linewidth=2, markersize=8)
    plt.plot(snr_range, cnn_acc, 'm-^', label='Spectrogram + CNN (Deep Learning)', linewidth=2, markersize=8)
    
    plt.fill_between(snr_range, goertzel_acc, cnn_acc, 
                     where=[c > g for g, c in zip(goertzel_acc, cnn_acc)],
                     alpha=0.3, color='green', label='CNN Advantage')
    plt.fill_between(snr_range, goertzel_acc, cnn_acc,
                     where=[g > c for g, c in zip(goertzel_acc, cnn_acc)],
                     alpha=0.3, color='blue', label='Goertzel Advantage')
    
    plt.axhline(y=0.95, color='orange', linestyle=':', alpha=0.7)
    plt.xlabel('SNR (dB)', fontsize=12)
    plt.ylabel('Accuracy', fontsize=12)
    plt.title('DTMF Detection: Goertzel vs Spectrogram CNN', fontsize=14)
    plt.legend(loc='lower right', fontsize=10)
    plt.grid(True, alpha=0.3)
    plt.xlim(snr_range[0] - 1, snr_range[-1] + 1)
    plt.ylim(0, 1.05)
    
    out_path = os.path.join(config.IMG_DIR, 'cnn_comparison.png')
    plt.savefig(out_path, dpi=150, bbox_inches='tight')
    print(f"\nPlot saved: {out_path}")
    
    # 统计
    print("\n" + "=" * 60)
    print("SUMMARY")
    print("=" * 60)
    low_idx = [i for i, s in enumerate(snr_range) if s < 0]
    high_idx = [i for i, s in enumerate(snr_range) if s >= 0]
    
    print(f"Low SNR (<0dB):")
    print(f"  Goertzel: {np.mean([goertzel_acc[i] for i in low_idx]):.2%}")
    print(f"  CNN:      {np.mean([cnn_acc[i] for i in low_idx]):.2%}")
    
    print(f"\nHigh SNR (>=0dB):")
    print(f"  Goertzel: {np.mean([goertzel_acc[i] for i in high_idx]):.2%}")
    print(f"  CNN:      {np.mean([cnn_acc[i] for i in high_idx]):.2%}")


if __name__ == "__main__":
    run_cnn_comparison()
