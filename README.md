# Python Docker環境（UV パッケージマネージャー使用）

このプロジェクトは、UVパッケージマネージャーを使用したPython実行環境のDockerコンテナを提供します。CPU版とGPU版の両方に対応しています。

## 必要な環境

- Docker
- Docker Compose（オプション）
- NVIDIA Docker（GPU版を使用する場合）

## ファイル構成

```
.
├── Dockerfile.cpu          # CPU版のDockerfile
├── Dockerfile.gpu          # GPU版のDockerfile（CUDA対応）
├── requirements.cpu.txt    # CPU版の依存パッケージリスト
├── requirements.gpu.txt    # GPU版の依存パッケージリスト
├── build.sh               # ビルド・実行スクリプト
├── docker-compose.yml     # Docker Compose設定（オプション）
├── .dockerignore          # Dockerビルド時の除外ファイル
├── test_environment.py    # 環境テストスクリプト
└── README.md              # このファイル
```

## クイックスタート

### 1. ビルドスクリプトに実行権限を付与

```bash
chmod +x build.sh
```

### 2. CPU版のビルド

```bash
./build.sh -t cpu
```

### 3. GPU版のビルド

```bash
./build.sh -t gpu
```

## 詳細な使用方法

### ビルドオプション

```bash
./build.sh [オプション]

オプション:
  -t, --type [cpu|gpu]     ビルドタイプを指定（必須）
  -i, --image NAME         Dockerイメージ名を指定
  -c, --container NAME     コンテナ名を指定
  -r, --run                ビルド後にコンテナを起動
  -j, --jupyter            Jupyterサーバーとして起動
  -h, --help               ヘルプを表示
```

### 使用例

1. **カスタム名でCPU版をビルド**
   ```bash
   ./build.sh -t cpu -i my-python-app -c my-container
   ```

2. **GPU版をビルドして即座に起動**
   ```bash
   ./build.sh -t gpu -r
   ```

3. **Jupyter Notebookとして起動**
   ```bash
   ./build.sh -t cpu -j
   # ブラウザで http://localhost:8888 にアクセス
   ```

## コンテナの操作

### コンテナに接続
```bash
# CPU版
docker exec -it python-uv-container-cpu /bin/bash

# GPU版
docker exec -it python-uv-container-gpu /bin/bash
```

### コンテナの停止・削除
```bash
# 停止
docker stop python-uv-container-cpu

# 削除
docker rm python-uv-container-cpu
```

## パッケージ管理

### 事前定義パッケージ

- **requirements.cpu.txt**: CPU版用のパッケージリスト
- **requirements.gpu.txt**: GPU版用のパッケージリスト（PyTorch、TensorFlow等を含む）

### パッケージの追加・更新

1. **requirements.txtを編集してビルド**
   ```bash
   # requirements.cpu.txt または requirements.gpu.txt を編集
   vim requirements.cpu.txt
   
   # 再ビルド
   ./build.sh -t cpu
   ```

2. **コンテナ内で直接インストール**
   ```bash
   # コンテナ内で実行
   uv pip install package-name
   
   # requirements.txtから再インストール
   uv pip install -r /app/requirements.txt
   ```

3. **カスタムrequirements.txtを使用**
   ```bash
   # コンテナ内で実行
   uv pip install -r /app/workspace/my-requirements.txt
   ```

## カスタマイズ

### パッケージリストの編集

1. **CPU版のパッケージを変更**
   `requirements.cpu.txt`を編集して必要なパッケージを追加・削除

2. **GPU版のパッケージを変更**
   `requirements.gpu.txt`を編集して必要なパッケージを追加・削除

### PyTorchのCUDAバージョン変更（GPU版）

`requirements.gpu.txt`内のインデックスURLを変更：
```txt
# CUDA 11.8用
--index-url https://download.pytorch.org/whl/cu118

# CUDA 12.1用（デフォルト）
--index-url https://download.pytorch.org/whl/cu121
```

### 作業ディレクトリのマウント

デフォルトでは、現在のディレクトリが `/app/workspace` にマウントされます。

## 環境の確認

付属の`test_environment.py`スクリプトで環境を確認できます：

```bash
# コンテナ内で実行
python /app/workspace/test_environment.py

# または外部から実行
docker exec python-uv-container-cpu python /app/workspace/test_environment.py
```

このスクリプトは以下を確認します：
- Pythonバージョンと基本情報
- インストール済みパッケージ
- GPU環境（GPU版の場合）
- 簡単な計算テスト

## トラブルシューティング

### GPU版でCUDAが認識されない場合

1. NVIDIA Dockerがインストールされているか確認
   ```bash
   docker run --rm --gpus all nvidia/cuda:12.2.0-base-ubuntu22.04 nvidia-smi
   ```

2. Dockerデーモンの再起動
   ```bash
   sudo systemctl restart docker
   ```

### UVのインストールに失敗する場合

プロキシ環境下の場合は、Dockerfileに以下を追加：
```dockerfile
ENV HTTP_PROXY=http://your-proxy:port
ENV HTTPS_PROXY=http://your-proxy:port
```

## ライセンス

このプロジェクトはMITライセンスの下で公開されています。