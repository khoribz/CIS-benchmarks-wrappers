#!/bin/bash

# Лог-файл для хранения результатов
LOG_FILE="deployment.log"
DOCKER_BENCH_SECURITY_DIR="docker-bench-security"  # Директория со скриптом docker-bench-security

# Функция для запроса параметров контейнера у пользователя
get_container_options() {
    echo "Введите имя контейнера (например, my_container):"
    read CONTAINER_NAME
    echo "Введите имя образа контейнера (например, my_image:latest):"
    read IMAGE_NAME
    echo "Введите дополнительные опции для запуска контейнера (например, -p 80:80):"
    read CONTAINER_OPTIONS
}

# Функция для запуска контейнера
start_container() {
    echo "Запуск контейнера $CONTAINER_NAME с образом $IMAGE_NAME и опциями $CONTAINER_OPTIONS..." | tee -a $LOG_FILE
    # Пример команды для запуска контейнера
    docker run -d --name "$CONTAINER_NAME" $CONTAINER_OPTIONS "$IMAGE_NAME" | tee -a $LOG_FILE
}

# Функция для запуска docker-bench-security и анализа результатов
run_docker_bench() {
    echo "Запуск docker-bench-security для проверки безопасности Docker..." | tee -a $LOG_FILE

    # Переход в директорию со скриптом docker-bench-security
    pushd $DOCKER_BENCH_SECURITY_DIR > /dev/null
    sudo bash docker-bench-security.sh > ../docker-bench-security-results.txt  # Используем bash для запуска скрипта
    popd > /dev/null

    if grep -q 'WARN\|FAIL' docker-bench-security-results.txt; then
        echo "Найдены проблемы безопасности в Docker:" | tee -a $LOG_FILE
        grep 'WARN\|FAIL' docker-bench-security-results.txt | tee -a $LOG_FILE

        while true; do
            read -p "Обнаружены проблемы безопасности в Docker. Вы уверены, что хотите продолжить развертывание? (yes/no): " yn
            case $yn in
                yes ) start_container; return 0; break;;
                no ) echo "Развертывание отменено." | tee -a $LOG_FILE; exit 1;;
                * ) echo "Пожалуйста, ответьте yes или no.";;
            esac
        done
    else
        echo "Проблем безопасности в Docker не обнаружено." | tee -a $LOG_FILE
        start_container
    fi
}

# Основная логика скрипта
main() {
    echo "Запуск процесса проверки безопасности и развертывания контейнера..." > $LOG_FILE

    get_container_options
    run_docker_bench
}

main

