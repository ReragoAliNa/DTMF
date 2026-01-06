"""
enhanced_classifier.py
增强型 DTMF 分类器
使用更丰富的特征设计，包括二阶谐波检测和置信度特征
"""
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from ..core import config
from ..core import dsp

class EnhancedClassifier:
    """
    增强型 DTMF 分类器
    特征包括：
    1. 7 个基频能量（归一化）
    2. 7 个二阶谐波能量
    3. 低频组和高频组的峰值比（置信度）
    4. 总信号能量
    """
    
    def __init__(self):
        # 使用随机森林（比 KNN 更鲁棒）
        self.model = RandomForestClassifier(
            n_estimators=100,
            max_depth=10,
            random_state=42
        )
        self.is_trained = False
        
        # 二阶谐波频率
        self.harmonic_freqs = [f * 2 for f in config.low_freqs + config.high_freqs]
    
    def extract_features(self, signal):
        """
        提取增强特征向量
        """
        features = []
        
        # 1. 基频能量 (7 维)
        all_freqs = config.low_freqs + config.high_freqs
        base_energies = [dsp.goertzel(signal, f) for f in all_freqs]
        max_base = max(base_energies) if max(base_energies) > 0 else 1
        features.extend([e / max_base for e in base_energies])
        
        # 2. 二阶谐波能量 (7 维)
        harmonic_energies = [dsp.goertzel(signal, f) for f in self.harmonic_freqs]
        max_harm = max(harmonic_energies) if max(harmonic_energies) > 0 else 1
        features.extend([e / max_harm for e in harmonic_energies])
        
        # 3. 低频组置信度：最大值 / 第二大值 (1 维)
        low_energies = sorted(base_energies[:4], reverse=True)
        low_conf = low_energies[0] / (low_energies[1] + 1e-10)
        features.append(min(low_conf, 10) / 10)  # 归一化到 0-1
        
        # 4. 高频组置信度 (1 维)
        high_energies = sorted(base_energies[4:], reverse=True)
        high_conf = high_energies[0] / (high_energies[1] + 1e-10)
        features.append(min(high_conf, 10) / 10)
        
        # 5. 基频能量与谐波能量比（纯正弦波这个值应该很大）(1 维)
        total_base = sum(base_energies)
        total_harm = sum(harmonic_energies) + 1e-10
        harmonic_ratio = total_base / total_harm
        features.append(min(harmonic_ratio, 100) / 100)
        
        # 6. 总信号能量 (1 维)
        signal_energy = np.mean(signal**2)
        features.append(min(signal_energy, 10) / 10)
        
        # 总计: 7 + 7 + 1 + 1 + 1 + 1 = 18 维
        return features
    
    def train(self, samples_per_key=400):
        """
        训练模型，重点覆盖低 SNR 区间
        """
        print("Generating enhanced training data...")
        X, y = [], []
        
        for key in config.keys:
            # 30% 极低 SNR (-30 to -15)
            for _ in range(int(samples_per_key * 0.3)):
                snr = np.random.uniform(-30, -15)
                signal = dsp.generate_dtmf(key, snr_db=snr)
                X.append(self.extract_features(signal))
                y.append(key)
            
            # 40% 中低 SNR (-15 to 0)
            for _ in range(int(samples_per_key * 0.4)):
                snr = np.random.uniform(-15, 0)
                signal = dsp.generate_dtmf(key, snr_db=snr)
                X.append(self.extract_features(signal))
                y.append(key)
            
            # 30% 高 SNR (0 to 20)
            for _ in range(int(samples_per_key * 0.3)):
                snr = np.random.uniform(0, 20)
                signal = dsp.generate_dtmf(key, snr_db=snr)
                X.append(self.extract_features(signal))
                y.append(key)
        
        X, y = np.array(X), np.array(y)
        
        X_train, X_val, y_train, y_val = train_test_split(
            X, y, test_size=0.2, random_state=42
        )
        
        print(f"Training Random Forest with {len(X_train)} samples, {len(X[0])} features...")
        self.model.fit(X_train, y_train)
        self.is_trained = True
        
        val_accuracy = self.model.score(X_val, y_val)
        print(f"Validation accuracy: {val_accuracy:.2%}")
        
        return val_accuracy
    
    def predict(self, signal):
        if not self.is_trained:
            raise RuntimeError("Model not trained.")
        features = self.extract_features(signal)
        return self.model.predict([features])[0]
    
    def predict_proba(self, signal):
        """
        预测并返回置信度
        """
        if not self.is_trained:
            raise RuntimeError("Model not trained.")
        
        features = self.extract_features(signal)
        proba = self.model.predict_proba([features])[0]
        predicted_key = self.model.classes_[np.argmax(proba)]
        confidence = np.max(proba)
        return predicted_key, confidence


def run_enhanced_comparison():
    """
    运行增强版对比实验
    """
    import matplotlib.pyplot as plt
    import os
    from .ml_classifier import MLClassifier
    
    print("=" * 60)
    print("Enhanced Algorithm Comparison Experiment")
    print("=" * 60)
    
    # 初始化分类器
    print("\n[1/2] Training KNN (Basic ML)...")
    basic_ml = MLClassifier(n_neighbors=5)
    basic_ml.train(samples_per_key=300)
    
    print("\n[2/2] Training Random Forest (Enhanced ML)...")
    enhanced_ml = EnhancedClassifier()
    enhanced_ml.train(samples_per_key=400)
    
    # 测试
    snr_range = np.arange(-30, 16, 2)
    iterations = 200
    
    goertzel_acc = []
    basic_acc = []
    enhanced_acc = []
    
    print("\nRunning comparison...")
    for snr in snr_range:
        g_correct, b_correct, e_correct = 0, 0, 0
        
        for _ in range(iterations):
            key = np.random.choice(config.keys)
            signal = dsp.generate_dtmf(key, snr_db=snr)
            
            if dsp.identify_key(signal) == key:
                g_correct += 1
            if basic_ml.predict(signal) == key:
                b_correct += 1
            if enhanced_ml.predict(signal) == key:
                e_correct += 1
        
        goertzel_acc.append(g_correct / iterations)
        basic_acc.append(b_correct / iterations)
        enhanced_acc.append(e_correct / iterations)
        
        print(f"  SNR={snr:3d}dB: Goertzel={goertzel_acc[-1]:.1%}, "
              f"Basic ML={basic_acc[-1]:.1%}, Enhanced={enhanced_acc[-1]:.1%}")
    
    # 绘图
    plt.figure(figsize=(12, 7))
    plt.plot(snr_range, goertzel_acc, 'b-o', label='Goertzel (Traditional)', linewidth=2)
    plt.plot(snr_range, basic_acc, 'r-s', label='KNN (Basic ML)', linewidth=2)
    plt.plot(snr_range, enhanced_acc, 'g-^', label='Random Forest + Enhanced Features', linewidth=2, markersize=8)
    
    plt.axhline(y=0.95, color='orange', linestyle=':', alpha=0.7, label='95% Accuracy')
    plt.xlabel('SNR (dB)', fontsize=12)
    plt.ylabel('Accuracy', fontsize=12)
    plt.title('DTMF Detection: Traditional vs Basic ML vs Enhanced ML', fontsize=14)
    plt.legend(loc='lower right', fontsize=10)
    plt.grid(True, alpha=0.3)
    plt.xlim(snr_range[0] - 1, snr_range[-1] + 1)
    plt.ylim(0, 1.05)
    
    out_path = os.path.join(config.IMG_DIR, 'enhanced_comparison.png')
    plt.savefig(out_path, dpi=150, bbox_inches='tight')
    print(f"\nPlot saved: {out_path}")
    
    # 统计
    print("\n" + "=" * 60)
    print("SUMMARY (Low SNR Region: SNR < 0dB)")
    print("=" * 60)
    low_idx = [i for i, s in enumerate(snr_range) if s < 0]
    print(f"  Goertzel:     {np.mean([goertzel_acc[i] for i in low_idx]):.2%}")
    print(f"  Basic ML:     {np.mean([basic_acc[i] for i in low_idx]):.2%}")
    print(f"  Enhanced ML:  {np.mean([enhanced_acc[i] for i in low_idx]):.2%}")


if __name__ == "__main__":
    run_enhanced_comparison()
