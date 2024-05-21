#!/bin/bash

# Лог-файл для хранения результатов
LOG_FILE="trivy-scan.log"
IMAGE_NAME=$1  # Имя образа передается как аргумент скрипта

# Проверка наличия аргумента
if [ -z "$IMAGE_NAME" ]; then
  echo "Ошибка: Укажите имя образа Docker для сканирования."
  exit 1
fi

# Функция для проверки уязвимостей с помощью Trivy
run_trivy_scan() {
  echo "Запуск сканирования Trivy для образа $IMAGE_NAME..." | tee -a $LOG_FILE
  trivy image $IMAGE_NAME | tee -a $LOG_FILE

  if grep -q 'CRITICAL\|HIGH' $LOG_FILE; then
    echo "Найдены критические или высокие уязвимости в образе $IMAGE_NAME:" | tee -a $LOG_FILE
    grep 'CRITICAL\|HIGH' $LOG_FILE | tee -a $LOG_FILE

    while true; do
      read -p "Обнаружены уязвимости в образе $IMAGE_NAME. Вы уверены, что хотите продолжить развертывание? (yes/no): " yn
      case $yn in
        yes ) return 0; break;;
        no ) echo "Развертывание отменено." | tee -a $LOG_FILE; exit 1;;
        * ) echo "Пожалуйста, ответьте yes или no.";;
      esac
    done
  else
    echo "Критических или высоких уязвимостей в образе $IMAGE_NAME не обнаружено." | tee -a $LOG_FILE
  fi
}

# Основная логика скрипта
main() {
  echo "Запуск процесса сканирования образа $IMAGE_NAME на уязвимости..." > $LOG_FILE

  run_trivy_scan
  if [ $? -ne 0 ]; then
    exit 1
  fi

  echo "Сканирование завершено. Вы можете продолжить развертывание." | tee -a $LOG_FILE
}

main

