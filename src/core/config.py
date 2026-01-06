import numpy as np
import os

# 基础参数
fs = 8000
duration = 0.2

# 频率与按键映射
# 频率与按键映射
keys = ['1', '2', '3', 'A', '4', '5', '6', 'B', '7', '8', '9', 'C', '*', '0', '#', 'D']
freq_map = {
    '1': (697, 1209), '2': (697, 1336), '3': (697, 1477), 'A': (697, 1633),
    '4': (770, 1209), '5': (770, 1336), '6': (770, 1477), 'B': (770, 1633),
    '7': (852, 1209), '8': (852, 1336), '9': (852, 1477), 'C': (852, 1633),
    '*': (941, 1209), '0': (941, 1336), '#': (941, 1477), 'D': (941, 1633)
}
low_freqs = [697, 770, 852, 941]
high_freqs = [1209, 1336, 1477, 1633]

# 路径配置
# 此文件在 python/core/ 目录下，向上三级是项目根目录
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
IMG_DIR = os.path.join(PROJECT_ROOT, 'images')
WAV_DIR = os.path.join(PROJECT_ROOT, 'audio')

# 确保目录存在
for d in [IMG_DIR, WAV_DIR]:
    if not os.path.exists(d):
        os.makedirs(d)
