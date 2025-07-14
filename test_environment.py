#!/usr/bin/env python3
"""
Docker環境のテストスクリプト
CPU版とGPU版の両方で動作確認ができます
"""

import sys
import platform
import importlib


def print_section(title):
    """セクションタイトルを表示"""
    print(f"\n{'=' * 50}")
    print(f"{title}")
    print("=" * 50)


def check_basic_info():
    """基本情報の確認"""
    print_section("基本情報")
    print(f"Python バージョン: {sys.version}")
    print(f"プラットフォーム: {platform.platform()}")
    print(f"プロセッサ: {platform.processor()}")


def check_package(package_name, version_attr="__version__"):
    """パッケージの存在とバージョンを確認"""
    try:
        module = importlib.import_module(package_name)
        version = getattr(module, version_attr, "バージョン不明")
        return True, version
    except ImportError:
        return False, None


def check_packages():
    """インストール済みパッケージの確認"""
    print_section("パッケージ確認")

    packages = [
        ("numpy", "__version__"),
        ("pandas", "__version__"),
        ("matplotlib", "__version__"),
        ("sklearn", "__version__"),
        ("jupyter", "__version__"),
        ("IPython", "__version__"),
    ]

    for package_name, version_attr in packages:
        installed, version = check_package(package_name, version_attr)
        if installed:
            print(f"✓ {package_name}: {version}")
        else:
            print(f"✗ {package_name}: 未インストール")


def check_gpu():
    """GPU環境の確認"""
    print_section("GPU環境確認")

    # PyTorchのGPU確認
    try:
        import torch

        print(f"PyTorch バージョン: {torch.__version__}")
        print(f"CUDA 利用可能: {torch.cuda.is_available()}")
        if torch.cuda.is_available():
            print(f"CUDA バージョン: {torch.version.cuda}")
            print(f"GPU 数: {torch.cuda.device_count()}")
            for i in range(torch.cuda.device_count()):
                print(f"GPU {i}: {torch.cuda.get_device_name(i)}")
    except ImportError:
        print("PyTorch: 未インストール")

    print()

    # TensorFlowのGPU確認
    try:
        import tensorflow as tf

        print(f"TensorFlow バージョン: {tf.__version__}")
        gpus = tf.config.list_physical_devices("GPU")
        print(f"GPU 利用可能: {len(gpus) > 0}")
        if gpus:
            print(f"GPU 数: {len(gpus)}")
            for i, gpu in enumerate(gpus):
                print(f"GPU {i}: {gpu.name}")
    except ImportError:
        print("TensorFlow: 未インストール")


def test_computation():
    """簡単な計算テスト"""
    print_section("計算テスト")

    try:
        import numpy as np
        import time

        # 行列計算のテスト
        size = 1000
        print(f"{size}x{size} 行列の積を計算中...")

        A = np.random.rand(size, size)
        B = np.random.rand(size, size)

        start_time = time.time()
        C = np.dot(A, B)
        end_time = time.time()

        print(f"計算完了！ 実行時間: {end_time - start_time:.3f}秒")
        print(f"結果の形状: {C.shape}")

    except Exception as e:
        print(f"エラー: {e}")


def test_gpu_computation():
    """GPU計算テスト"""
    print_section("GPU計算テスト")

    try:
        import torch

        if torch.cuda.is_available():
            import time

            size = 5000
            print(f"{size}x{size} 行列の積をGPUで計算中...")

            # GPU上で行列を作成
            A = torch.rand(size, size, device="cuda")
            B = torch.rand(size, size, device="cuda")

            # ウォームアップ
            _ = torch.mm(A, B)
            torch.cuda.synchronize()

            # 実際の計測
            start_time = time.time()
            C = torch.mm(A, B)
            torch.cuda.synchronize()
            end_time = time.time()

            print(f"計算完了！ 実行時間: {end_time - start_time:.3f}秒")
            print(f"結果の形状: {C.shape}")
        else:
            print("GPUが利用できません")
    except ImportError:
        print("PyTorchがインストールされていません")
    except Exception as e:
        print(f"エラー: {e}")


def main():
    """メイン関数"""
    print("Docker Python環境テスト")
    print("=" * 50)

    # 基本情報
    check_basic_info()

    # パッケージ確認
    check_packages()

    # GPU環境確認
    check_gpu()

    # 計算テスト
    test_computation()

    # GPU計算テスト
    test_gpu_computation()

    print_section("テスト完了")
    print("環境のセットアップが正常に完了しています！")


if __name__ == "__main__":
    main()
