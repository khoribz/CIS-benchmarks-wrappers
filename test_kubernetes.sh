#!/bin/bash

# Лог-файл для хранения результатов
LOG_FILE="kubernetes-deployment.log"
KUBE_BENCH_CMD="kube-bench"  # Команда для запуска kube-bench
APPLY_MANIFESTS_FILE="app/apply_manifests"  # Файл с командами kubectl для развертывания
MANIFESTS_DIR="app"  # Директория, в которой находятся файлы манифестов

export KUBECONFIG=/home/khoribz/.kube/config  # Указать путь, можно узнать с помощью ls ~/.kube/config

# Функция для проверки соединения с Kubernetes API сервером
check_k8s_connection() {
    kubectl cluster-info > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "Ошибка: Не удалось подключиться к серверу Kubernetes. Проверьте настройки kubectl." | tee -a $LOG_FILE
        exit 1
    fi
}

# Функция для запуска манифестов и развертывания микросервисной архитектуры
deploy_microservices() {
    echo "Развертывание микросервисной архитектуры с использованием команд из файла $APPLY_MANIFESTS_FILE..." | tee -a $LOG_FILE

    # Проверяем наличие файла с манифестами
    if [ ! -f "$APPLY_MANIFESTS_FILE" ]; then
        echo "Ошибка: Файл $APPLY_MANIFESTS_FILE не найден." | tee -a $LOG_FILE
        exit 1
    fi

    # Сохраняем текущую директорию
    CURRENT_DIR=$(pwd)
    
    # Переход в директорию с манифестами
    cd $MANIFESTS_DIR

    while IFS= read -r line
    do
        if [[ $line == kubectl* ]]; then
            echo "Выполнение: sudo $line" | tee -a $LOG_FILE
            $line | tee -a $LOG_FILE  # Используем sudo для выполнения команд
            if [ $? -ne 0 ]; then
                echo "Ошибка выполнения команды: sudo $line" | tee -a $LOG_FILE
                # Возвращаемся в исходную директорию
                cd $CURRENT_DIR
                exit 1
            fi
        fi
    done < "$(basename "$APPLY_MANIFESTS_FILE")"

    # Возвращаемся в исходную директорию
    cd $CURRENT_DIR
}

# Функция для запуска kube-bench и анализа результатов
run_kube_bench() {
    echo "Запуск kube-bench для проверки безопасности Kubernetes..." | tee -a $LOG_FILE
    sudo $KUBE_BENCH_CMD > kube-bench-results.txt  # Запуск с sudo для прав доступа

    if grep -q 'WARN\|FAIL' kube-bench-results.txt; then
        echo "Найдены проблемы безопасности в Kubernetes:" | tee -a $LOG_FILE
        grep 'WARN\|FAIL' kube-bench-results.txt | tee -a $LOG_FILE

        while true; do
            read -p "Обнаружены проблемы безопасности в Kubernetes. Вы уверены, что хотите продолжить развертывание? (yes/no): " yn
            case $yn in
                yes ) return 0; break;;
                no ) echo "Развертывание отменено." | tee -a $LOG_FILE; exit 1;;
                * ) echo "Пожалуйста, ответьте yes или no.";;
            esac
        done
    else
        echo "Проблем безопасности в Kubernetes не обнаружено." | tee -a $LOG_FILE
    fi

    # Выводим результаты
    cat kube-bench-results.txt | tee -a $LOG_FILE
}

# Основная логика скрипта
main() {
    echo "Запуск процесса проверки безопасности и развертывания микросервисной архитектуры..." > $LOG_FILE

    run_kube_bench
    if [ $? -ne 0 ]; then
        exit 1
    fi

    check_k8s_connection  # Проверка соединения с Kubernetes API сервером

    deploy_microservices
}

main

