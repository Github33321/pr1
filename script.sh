#!/bin/bash

print_help() {
    echo "Использование: $0 [опции]"
    echo ""
    echo "Опции:"
    echo "  -u, --users      Выводит перечень пользователей и их домашних директорий."
    echo "  -p, --processes  Выводит перечень запущенных процессов."
    echo "  -h, --help       Выводит эту справку."
    echo "  -l PATH, --log PATH    Записывает вывод в указанный файл."
    echo "  -e PATH, --errors PATH  Записывает ошибки в указанный файл."
}
list_users() {
    awk -F: '{ print $1, $6 }' /etc/passwd | sort 2> /dev/null
}
list_processes() {
    ps -eo pid,comm --sort=pid 2> /dev/null
}
log_file=""
error_file=""
while getopts ":uphl:e:-:" opt; do
    case $opt in
        u)
            output_function=list_users
            ;;
        p)
            output_function=list_processes
            ;;
        h)
            print_help
            exit 0
            ;;
        l)
            log_file="$OPTARG"
            ;;
        e)
            error_file="$OPTARG"
            ;;
        -)
            case "${OPTARG}" in
                users)
                    output_function=list_users
                    ;;
                processes)
                    output_function=list_processes
                    ;;
                help)
                    print_help
                    exit 0
                    ;;
                log)
                    log_file="${!OPTIND}"; OPTIND=$(( OPTIND + 1 ))
                    ;;
                errors)
                    error_file="${!OPTIND}"; OPTIND=$(( OPTIND + 1 ))
                    ;;
                *)
                    echo "Неизвестная опция --${OPTARG}" >&2
                    exit 1
                    ;;
            esac
            ;;
        \?)
            echo "Неизвестный аргумент: -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "Опция -$OPTARG требует аргумент." >&2
            exit 1
            ;;
    esac
done
if [ -z "$output_function" ]; then
    echo "Необходимо указать хотя бы одну опцию." >&2
    exit 1
fi


if [ -n "$log_file" ]; then
    if [ ! -w "$(dirname "$log_file")" ]; then
        echo "Ошибка: нет доступа для записи в файл $log_file" >&2
        exit 1
    fi
    exec &> "$log_file"
fi

if [ -n "$error_file" ]; then
    if [ ! -w "$(dirname "$error_file")" ]; then
        echo "Ошибка: нет доступа для записи в файл $error_file" >&2
        exit 1
    fi
    exec 2> "$error_file"
fi

"$output_function"
