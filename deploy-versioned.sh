#!/bin/bash
set -e

REGION="us-east-1"
ECR_REPO="bia"
CLUSTER="cluster-bia"
SERVICE="service-bia"
TASK_FAMILY="task-def-bia"

get_commit_hash() {
    git rev-parse --short=7 HEAD 2>/dev/null || { echo "Erro: não é um repositório git"; exit 1; }
}

get_account_id() {
    aws sts get-caller-identity --query Account --output text
}

build_and_push() {
    local tag=$1
    local ecr_uri=$2
    
    echo "[BUILD] Tag: $tag"
    docker build -t $ecr_uri:$tag .
    
    echo "[LOGIN] ECR..."
    aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ecr_uri
    
    echo "[PUSH] Enviando imagem..."
    docker push $ecr_uri:$tag
}

create_task_def() {
    local image=$1
    
    echo "[TASK-DEF] Criando nova versão..." >&2
    
    local current=$(aws ecs describe-task-definition --task-definition $TASK_FAMILY --region $REGION --query 'taskDefinition' --output json)
    
    local new_def=$(echo "$current" | jq -c --arg img "$image" '
        .containerDefinitions[0].image = $img |
        del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .compatibilities, .registeredAt, .registeredBy)
    ')
    
    aws ecs register-task-definition --region $REGION --cli-input-json "$new_def" --query 'taskDefinition.revision' --output text
}

update_service() {
    local revision=$1
    
    echo "[DEPLOY] Atualizando serviço..."
    aws ecs update-service --region $REGION --cluster $CLUSTER --service $SERVICE --task-definition $TASK_FAMILY:$revision --query 'service.taskDefinition' --output text
    
    echo "[WAIT] Aguardando estabilização..."
    aws ecs wait services-stable --region $REGION --cluster $CLUSTER --services $SERVICE
    
    echo "[OK] Deploy concluído: $TASK_FAMILY:$revision"
}

list_versions() {
    echo "[VERSÕES] Imagens disponíveis no ECR:"
    aws ecr describe-images --repository-name $ECR_REPO --region $REGION \
        --query 'sort_by(imageDetails,&imagePushedAt)[*].[imageTags[0],imagePushedAt]' \
        --output table
}

deploy() {
    local tag=$(get_commit_hash)
    local account=$(get_account_id)
    local ecr_uri="$account.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO"
    local image="$ecr_uri:$tag"
    
    echo "[DEPLOY] Versão: $tag"
    
    build_and_push $tag $ecr_uri
    local revision=$(create_task_def $image)
    update_service $revision
}

rollback() {
    local tag=$1
    [ -z "$tag" ] && { echo "Erro: especifique a tag (ex: ./deploy-versioned.sh rollback abc1234)"; exit 1; }
    
    local account=$(get_account_id)
    local image="$account.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO:$tag"
    
    echo "[ROLLBACK] Versão: $tag"
    
    aws ecr describe-images --repository-name $ECR_REPO --region $REGION --image-ids imageTag=$tag >/dev/null 2>&1 || \
        { echo "Erro: imagem $tag não encontrada"; exit 1; }
    
    local revision=$(create_task_def $image)
    update_service $revision
}

case "${1:-deploy}" in
    deploy) deploy ;;
    list) list_versions ;;
    rollback) rollback $2 ;;
    *) echo "Uso: $0 [deploy|list|rollback <tag>]"; exit 1 ;;
esac
