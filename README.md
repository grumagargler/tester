# Тестер

[![Join the chat at https://gitter.im/tester1c/Lobby](https://badges.gitter.im/tester1c/Lobby.svg)](https://gitter.im/tester1c/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Система сценарного тестирования решений на базе 1С:Предприятие 8.3, управляемые формы.
Cправка здесь http://tester.help и внутри конфигурации. Пример решения, написанного с использованием системы Тестер: https://github.com/Contabilizare/c5.

Возможности:
- Программирование и запуск сложных сценарных тестов в одной среде
- Глубокое тестирование интерфейса и бизнес логики
- Запись работы пользователя с переводом сценария в программный код
- Организация коллективной работы по созданию базы тестов
- Гибкий ролевой доступ, раздельный RLS-доступ пользователей к тестируемым конфигурациям
- Организация разветвленной разработки тестов с использованием git-репозиториев, хранение базы тестов вместе с проектами EDT
- Интеграция с сервисами управления и контроля версий github.com, gitlab.com и других с использованием Webhook-ов
- Формирование протоколов и сводных отчетов по выполненным сценариям
- Настройка рассылки результатов тестов по электронной почте
- Тестирование по расписанию, организация непрерывного процесса прогона тестов в рамках CI
- Интеграция с Visual Studio Code
- Возможность подключения к тестируемым клиентам разных версий платформ
- Пошаговая видеозапись и воспроизведение хода выполнения сценария 

Особенности:
- Быстро устанавливается, не требует специальных (кроме 1С) знаний и программного обеспечения
- Быстро интегрируется в процесс разработки
- Не требует фундаметального пересмотра философии программирования
- Сфокусирован на процесс создания реальных тестов
- Не требует подготовки отдельных баз и эталонных данных

Другое применение:

Тестер может быть использован как автоматизатор рутинных операций, как в процессе разработки, так и в режиме реальной эксплуатации продуктовых баз. Среди таких задач можно выделить:
- Выгрузка/загрузка данных, пакетный запуск 1С для административных задач
- Запуск и манипуляции обработками, отчетами. Тестером можно написать сценарий, который будет формировать отчет, проверять какие-то данные или открывать обработку и нажимать там нужные кнопки и выбирать поля
- Формирование начальных или тестовых данных для ваших решений (вместо использования конвертации данных)
- Нагрузочное тестирование. Например, у вас есть доработка и вы хотите проверить работу этого функционала под нагрузкой. Для этого можно написать сценарий запуска Тестера нужное кол-во раз с передачей целевого тестируемого сценария в качестве параметра

Несколько примеров:
- создание теста путем записи сценария: https://youtu.be/ZyqQ-YjKB3A
- создание теста кодированием: https://youtu.be/IqiwrzD5pWg
- полтора часа жизни программиста со сценарным тестированием: https://youtu.be/Lr6ew_Nu1aE

Совместимость:

Конфигурация выкладывается без режима совместимости, и как правило на базе последних версий 1С (на момент публикации в GitHub). Попытка загрузки cf-файла Тестера в ранние версии платформы, может завершаться сообщением о несовместимости файла конфигурации.
В этом случае, необходимо выполнить следующие действия:
- Под последней версией платформы, создать пустую базу и загрузить конфигурацию cf-файла Тестера
- В конфигураторе, в палитре свойств корня конфигурации Тестера, установить требуемый режим совместимости
- Сохранить полученную конфигурацию в файл и использовать его в качестве обновления Тестера

---

**Внимание!**

Для обеспечения работы конфигурации в операционной системе Windows, требуется наличие установленной стандартной библиотеки с++. В подавляющем большинстве случаев, данная библиотека входит в состав операционной системы или дистрибутива 1С:Предприятие. Однако, если вы сталкиваетесь с ошибками создания объектов тестера в процессе работы с конфигурацией, выполните пожалуйста установку библиотеки самостоятельно:
- Для Windows x64 https://aka.ms/vs/16/release/vc_redist.x64.exe
- Для Windows x32 https://aka.ms/vs/16/release/vc_redist.x86.exe

---
