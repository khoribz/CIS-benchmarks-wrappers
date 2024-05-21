#!/bin/bash

# Лог-файл для хранения результатов
LOG_FILE="trivy-scan-kubernetes.log"
MANIFESTS_DIR="app"  # Директория с манифестами Kubernetes

# Функция для проверки уязвимостей с помощью Trivy
run_trivy_scan() {
    local manifest=$1
    echo "Сканирование манифеста $manifest с помощью Trivy..." | tee -a $LOG_FILE
    trivy config $manifest | tee -a $LOG_FILE

    if grep -q 'CRITICAL\|HIGH' $LOG_FILE; then
        echo "Найдены критические или высокие уязвимости в манифесте $manifest:" | tee -a $LOG_FILE
        grep 'CRITICAL\|HIGH' $LOG_FILE | tee -a $LOG_FILE

        while true; do
            read -p "Обнаружены уязвимости в манифесте $manifest. Вы уверены, что хотите продолжить развертывание? (yes/no): " yn
            case $yn in
                yes ) return 0; break;;
                no ) echo "Развертывание отменено." | tee -a $LOG_FILE; exit 1;;
                * ) echo "Пожалуйста, ответьте yes или no.";;
            esac
        done
    else
        echo "Критических или высоких уязвимостей в манифесте $manifest не обнаружено." | tee -a $LOG_FILE
    fi
}

# Функция для сканирования всех манифестов в директории
scan_all_manifests() {
    for manifest in $MANIFESTS_DIR/*.yaml; do
        run_trivy_scan $manifest
    done
}

# Основная логика скрипта
main() {
    echo "Запуск процесса сканирования манифестов Kubernetes с помощью Trivy..." > $LOG_FILE

    scan_all_manifests
    if [ $? -ne 0 ]; then
        exit 1
    fi

    echo "Сканирование завершено. Вы можете продолжить развертывание." | tee -a $LOG_FILE
}

main

