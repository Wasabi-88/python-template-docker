#!/bin/bash

# 色付き出力用の定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# デフォルト値
DEFAULT_IMAGE_NAME="python-uv"
DEFAULT_CONTAINER_NAME="python-uv-container"

# ヘルプ関数
show_help() {
    echo "使用方法: $0 [オプション]"
    echo ""
    echo "オプション:"
    echo "  -t, --type [cpu|gpu]     ビルドタイプを指定 (必須)"
    echo "  -i, --image NAME         Dockerイメージ名を指定 (デフォルト: $DEFAULT_IMAGE_NAME)"
    echo "  -c, --container NAME     コンテナ名を指定 (デフォルト: $DEFAULT_CONTAINER_NAME)"
    echo "  -r, --run                ビルド後にコンテナを起動"
    echo "  -j, --jupyter            Jupyterサーバーとして起動"
    echo "  -h, --help               このヘルプを表示"
    echo ""
    echo "例:"
    echo "  $0 -t cpu -i my-python -c my-container"
    echo "  $0 -t gpu -r -j"
}

# 変数の初期化
BUILD_TYPE=""
IMAGE_NAME="$DEFAULT_IMAGE_NAME"
CONTAINER_NAME="$DEFAULT_CONTAINER_NAME"
RUN_CONTAINER=false
RUN_JUPYTER=false

# 引数の解析
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--type)
            BUILD_TYPE="$2"
            shift 2
            ;;
        -i|--image)
            IMAGE_NAME="$2"
            shift 2
            ;;
        -c|--container)
            CONTAINER_NAME="$2"
            shift 2
            ;;
        -r|--run)
            RUN_CONTAINER=true
            shift
            ;;
        -j|--jupyter)
            RUN_JUPYTER=true
            RUN_CONTAINER=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}エラー: 不明なオプション: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# ビルドタイプの確認
if [ -z "$BUILD_TYPE" ]; then
    echo -e "${RED}エラー: ビルドタイプを指定してください (-t cpu または -t gpu)${NC}"
    show_help
    exit 1
fi

if [ "$BUILD_TYPE" != "cpu" ] && [ "$BUILD_TYPE" != "gpu" ]; then
    echo -e "${RED}エラー: ビルドタイプは 'cpu' または 'gpu' である必要があります${NC}"
    exit 1
fi

# Dockerfileの存在確認
DOCKERFILE="Dockerfile.$BUILD_TYPE"
if [ ! -f "$DOCKERFILE" ]; then
    echo -e "${RED}エラー: $DOCKERFILE が見つかりません${NC}"
    exit 1
fi

# ビルド設定の表示
echo -e "${GREEN}=== Docker ビルド設定 ===${NC}"
echo -e "ビルドタイプ: ${YELLOW}$BUILD_TYPE${NC}"
echo -e "Dockerfile: ${YELLOW}$DOCKERFILE${NC}"
echo -e "イメージ名: ${YELLOW}$IMAGE_NAME-$BUILD_TYPE${NC}"
echo -e "コンテナ名: ${YELLOW}$CONTAINER_NAME-$BUILD_TYPE${NC}"
echo ""

# 既存のコンテナ確認
if docker ps -a --format '{{.Names}}' | grep -q "^$CONTAINER_NAME-$BUILD_TYPE$"; then
    echo -e "${YELLOW}警告: 既存のコンテナ '$CONTAINER_NAME-$BUILD_TYPE' が見つかりました${NC}"
    read -p "削除して続行しますか? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker rm -f "$CONTAINER_NAME-$BUILD_TYPE"
    else
        echo "中止しました"
        exit 0
    fi
fi

# Dockerイメージのビルド
echo -e "${GREEN}Dockerイメージをビルド中...${NC}"
docker build -f "$DOCKERFILE" -t "$IMAGE_NAME-$BUILD_TYPE" .

if [ $? -ne 0 ]; then
    echo -e "${RED}エラー: Dockerイメージのビルドに失敗しました${NC}"
    exit 1
fi

echo -e "${GREEN}Dockerイメージのビルドが完了しました！${NC}"

# コンテナの起動
if [ "$RUN_CONTAINER" = true ]; then
    echo -e "${GREEN}コンテナを起動中...${NC}"
    
    # 基本のdocker runコマンド
    DOCKER_CMD="docker run -d --name $CONTAINER_NAME-$BUILD_TYPE"
    
    # GPU版の場合はGPUオプションを追加
    if [ "$BUILD_TYPE" = "gpu" ]; then
        DOCKER_CMD="$DOCKER_CMD --gpus all"
    fi
    
    # 共通オプション
    DOCKER_CMD="$DOCKER_CMD -v $(pwd):/app/workspace"
    DOCKER_CMD="$DOCKER_CMD -p 8888:8888"
    
    # Jupyterモードの場合
    if [ "$RUN_JUPYTER" = true ]; then
        DOCKER_CMD="$DOCKER_CMD $IMAGE_NAME-$BUILD_TYPE jupyter notebook --ip=0.0.0.0 --port=8888 --no-browser --allow-root --NotebookApp.token=''"
        echo -e "${YELLOW}Jupyter Notebookを起動しています...${NC}"
    else
        DOCKER_CMD="$DOCKER_CMD -it $IMAGE_NAME-$BUILD_TYPE /bin/bash"
    fi
    
    # コンテナ起動
    eval $DOCKER_CMD
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}コンテナが正常に起動しました！${NC}"
        if [ "$RUN_JUPYTER" = true ]; then
            echo -e "${YELLOW}Jupyter Notebookにアクセス: http://localhost:8888${NC}"
        else
            echo -e "${YELLOW}コンテナに接続: docker exec -it $CONTAINER_NAME-$BUILD_TYPE /bin/bash${NC}"
        fi
    else
        echo -e "${RED}エラー: コンテナの起動に失敗しました${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}完了！${NC}"