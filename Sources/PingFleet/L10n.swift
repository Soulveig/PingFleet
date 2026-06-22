import Foundation

enum L10n {
    private static var isRussian: Bool {
        Locale.preferredLanguages.first?.hasPrefix("ru") == true
    }

    static func text(_ english: String, _ russian: String) -> String {
        isRussian ? russian : english
    }

    static let start = text("Start", "Старт")
    static let stop = text("Stop", "Стоп")
    static let pingNow = text("Ping Now", "Пинг")
    static let add = text("Add", "Добавить")
    static let remove = text("Remove", "Удалить")
    static let reset = text("Reset", "Сброс")
    static let importHosts = text("Import", "Импорт")
    static let importList = text("Import List", "Импорт списка")
    static let importListPlaceholder = text("Paste one host per line, or CSV lines like Name,Address.", "Вставьте по одному хосту в строке или CSV-строки вида Имя,Адрес.")
    static let importFromText = text("Import", "Импортировать")
    static let chooseFile = text("Choose File...", "Выбрать файл...")
    static let export = text("Export", "Экспорт")
    static let details = text("Details", "Детали")
    static let filter = text("Filter", "Фильтр")
    static let every = text("Every", "Каждые")
    static let pingIntervalHelp = text("Choose how often PingFleet pings enabled hosts.", "Выберите, как часто PingFleet проверяет включенные хосты.")
    static let update = text("Update", "Обновить")
    static let checkForUpdates = text("Check for Updates...", "Проверить обновления...")
    static let updates = text("Updates", "Обновления")
    static let checkNow = text("Check Now", "Проверить")
    static let checking = text("Checking", "Проверка")
    static let installUpdate = text("Install Update", "Установить")
    static let installing = text("Installing", "Установка")

    static let startHelp = text("Start automatic ping monitoring for enabled hosts.", "Запустить автоматический пинг включенных хостов.")
    static let stopHelp = text("Stop automatic ping monitoring.", "Остановить автоматический пинг.")
    static let pingNowHelp = text("Run one ping check for all enabled hosts immediately.", "Сразу выполнить одну проверку для всех включенных хостов.")
    static let addHelp = text("Add a new host or IP address to the monitor.", "Добавить новый хост или IP-адрес.")
    static let removeHelp = text("Remove the selected host from the monitor.", "Удалить выбранный хост.")
    static let resetHelp = text("Clear latency, packet, loss, and history statistics for all hosts.", "Очистить задержки, пакеты, потери и историю по всем хостам.")
    static let importHelp = text("Import hosts from a text or CSV file.", "Импортировать хосты из текстового или CSV-файла.")
    static let exportHelp = text("Export the current host table and statistics to a CSV file.", "Экспортировать текущую таблицу и статистику в CSV.")
    static let detailsHelp = text("Show details and latency history for the selected host.", "Показать детали и историю задержки выбранного хоста.")
    static let updatesHelp = text("Check for app updates.", "Проверить обновления приложения.")

    static let name = text("Name", "Имя")
    static let address = text("Address", "Адрес")
    static let status = text("Status", "Статус")
    static let last = text("Last", "Последний")
    static let average = text("Average", "Средний")
    static let minimum = text("Minimum", "Минимум")
    static let maximum = text("Maximum", "Максимум")
    static let min = text("Min", "Мин")
    static let max = text("Max", "Макс")
    static let loss = text("Loss", "Потери")
    static let sent = text("Sent", "Отпр.")
    static let received = text("Received", "Получ.")
    static let lastCheck = text("Last Check", "Проверка")
    static let cancel = text("Cancel", "Отмена")
    static let addHost = text("Add Host", "Добавить хост")
    static let noHostSelected = text("No Host Selected", "Хост не выбран")
    static let selectRow = text("Select a row to see ping history and details.", "Выберите строку, чтобы увидеть историю и детали.")
    static let closeWithoutAdding = text("Close this window without adding a host.", "Закрыть окно без добавления хоста.")
    static let addThisHost = text("Add this host to the monitor.", "Добавить этот хост в мониторинг.")
    static let changelog = text("Changelog", "История изменений")

    static let updatesReadyTitle = text("Ready to check", "Готово к проверке")
    static let updatesReadyMessage = text("PingFleet can check a hosted update manifest and install a newer build.", "PingFleet может проверить манифест обновления и установить новую сборку.")
    static let updatesNotConfiguredTitle = text("Update feed is not configured", "Источник обновлений не настроен")
    static let updatesNotConfiguredMessage = text("Add the GitHub Releases API URL to PingFleetUpdateURL in Info.plist.", "Добавьте URL GitHub Releases API в PingFleetUpdateURL в Info.plist.")
    static let updatesCheckingTitle = text("Checking for updates...", "Проверка обновлений...")
    static let updateAvailableMessage = text("A newer PingFleet build is ready to download.", "Доступна новая сборка PingFleet.")
    static let upToDateTitle = text("PingFleet is up to date", "PingFleet обновлен")
    static let updateErrorTitle = text("Could not check for updates", "Не удалось проверить обновления")
    static let preparingUpdateTitle = text("Preparing update...", "Подготовка обновления...")
    static let permissionMayBeRequiredTitle = text("macOS permission may be required", "Может понадобиться разрешение macOS")
    static let installingUpdateTitle = text("Installing update...", "Установка обновления...")
    static let installingUpdateMessage = text("PingFleet will restart automatically.", "PingFleet перезапустится автоматически.")
    static let installUpdateErrorTitle = text("Could not install update", "Не удалось установить обновление")

    static func updateAvailableTitle(_ version: String) -> String {
        text("Version \(version) is available", "Доступна версия \(version)")
    }

    static func upToDateMessage(_ versionDisplay: String) -> String {
        text("You are using \(versionDisplay).", "Установлена версия \(versionDisplay).")
    }

    static func downloadingUpdateTitle(_ version: String) -> String {
        text("Downloading version \(version)...", "Загрузка версии \(version)...")
    }

    static func unpackingUpdateMessage(_ version: String) -> String {
        text("Unpacking PingFleet \(version).", "Распаковка PingFleet \(version).")
    }

    static func permissionMayBeRequiredMessage(_ folderName: String) -> String {
        text(
            "PingFleet is running from your \(folderName) folder. If macOS asks for access, choose Allow so the updater can replace the app.",
            "PingFleet запущен из папки \(folderName). Если macOS запросит доступ, выберите Allow, чтобы обновлятор мог заменить приложение."
        )
    }

    static func updateServerHTTPError(_ code: Int) -> String {
        text("The update server returned HTTP \(code).", "Сервер обновлений вернул HTTP \(code).")
    }

    static let invalidUpdateManifest = text("The update manifest is missing required version information.", "В манифесте обновления нет обязательной информации о версии.")
    static let invalidUpdateArchive = text("The downloaded archive does not contain PingFleet.app.", "Скачанный архив не содержит PingFleet.app.")

    static func invalidDownloadedApp(_ reason: String) -> String {
        text("The downloaded app did not pass signature validation: \(reason)", "Скачанное приложение не прошло проверку подписи: \(reason)")
    }

    static func installFolderNotWritable(_ path: String) -> String {
        text("PingFleet cannot replace itself because the install folder is not writable: \(path).", "PingFleet не может заменить себя, потому что папка установки недоступна для записи: \(path).")
    }

    static func processFailed(_ executable: String, _ code: Int) -> String {
        text("\(executable) exited with status \(code).", "\(executable) завершился с кодом \(code).")
    }

    static func state(_ state: PingState) -> String {
        switch state {
        case .unknown: text("Unknown", "Неизвестно")
        case .online: text("Online", "Онлайн")
        case .offline: text("Offline", "Офлайн")
        }
    }
}
