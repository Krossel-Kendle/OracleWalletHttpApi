# Specification (RU only)

## 0. Что это вообще
Это десктопная тулза на Delphi/VCL для Oracle Wallet.
Основная идея простая: быстро руками и через API чинить/обслуживать wallet, не лазить каждый раз в консоль с километровыми командами.

Тут есть 2 режима работы:
- UI для админа (кнопки, списки, сводка, логи)
- HTTP API для автоматизации (JSON:API формат)

И да, отдельный блок Enhanced API — это ACL через sqlplus.

---

## 1. Основные цели
- Смотреть сертификаты в wallet
- Добавлять/удалять сертификаты
- Массово грузить cert'ы из папки
- Массово удалять cert'ы
- Создавать новый wallet прямо из приложения
- Опционально рулить тем же через локальный API
- Для DB-сценариев: выдавать/снимать ACL через Enhanced API

Не цель: заменять Oracle PKI. Мы сверху даём удобный слой и нормальный UX.

---

## 2. Тех-стек и среда
- Delphi 12
- VCL Win32
- `orapki` обязателен для wallet-операций
- `sqlplus` обязателен для Enhanced API

Если `orapki` не найден:
- операции с wallet блочатся
- пункт меню `Add New Wallet` неактивный
- в статусбаре сразу видно, что tool missing

---

## 3. UI, по-человечески

### Главное окно
Есть вкладки:
- General
- Log (показываем последние 100 событий)

### Меню
Порядок важен:
- `App`
- `Wallet Configuration`
- `Add New Wallet` (root item)

`Add New Wallet` — это именно создание нового wallet, не подключение старого.
Если надо подключить уже существующий wallet: `Wallet Configuration -> Configure`.

### Статусбар
Внизу показываем:
- KrosselApps + клик по `https://kapps.at`
- Состояние тулзов (`wallet tool`, `sqlplus`)
- Server статус
- Enhanced API on/off

Цвета:
- wallet tool missing -> красный
- sqlplus missing -> желтый
- server running/stopped -> зел/крас

---

## 4. Create New Wallet (UI flow)
Форма создания wallet:
- путь
- пароль
- auto-login
- local auto-login

Правила валидации:
- путь пустой -> создать нельзя
- путь кривой/диск не существует -> красный caption + disable `Create`
- если в папке уже есть wallet (`ewallet.p12` или `cwallet.sso`) -> желтый warning + disable `Create`
- если папки нет, пытаемся создать автоматически

После успешного создания:
- приложение переключается на новый wallet
- обновляется список сертификатов
- API начинает работать с новым wallet

---

## 5. API контракт (актуальный)
Base URL:
- `http://127.0.0.1:<port>/api/v1`

Auth:
- `X-API-Key`
- или Basic auth

Хосты:
- либо all
- либо allow-list IP

Формат:
- runtime ответы: JSON:API (`application/vnd.api+json`)
- ошибки: JSON:API `errors[]`
- POST умеет:
  - JSON:API body (`data.type`, `data.attributes`)
  - legacy flat json (backward compatible)

Отдельно:
- `GET /api/v1/openapi.json` возвращает OpenAPI JSON (`application/json`)

---

## 6. Список endpoint'ов

### Meta / health
- `GET /openapi.json`  
  отдаёт OpenAPI-док
- `GET /health`  
  состояние API + tools + wallet configured

### Wallet
- `POST /wallets`  
  создать новый wallet

Ошибки тут ключевые:
- 400 `Invalid path`
- 409 `wallet is already exists`

### Certificates
- `GET /certs`
- `GET /certs/expiring?days=30&limit=20`
- `GET /certs/{name}`
- `DELETE /certs/{name}`
- `POST /certs` (добавить по URL)
- `POST /certs/upload` (base64)
- `POST /certs/remove-all`

### Enhanced ACL
- `GET /acl/types`
- `GET /acl?schema=...&host=...`
- `POST /acl/grant`
- `POST /acl/revoke`

---

## 7. JSON:API resource types
Используем такие type:
- `health`
- `wallets`
- `certificates`
- `certificate-imports`
- `certificate-uploads`
- `wallet-operations`
- `acl-types`
- `acl-grants`
- `acl-operations`

---

## 8. Конфиг и хранение
Runtime конфиг:
- `config/settings.json` рядом с exe

Там есть поля вида `*Enc` (шифрованные значения):
- wallet password
- API key / basic creds
- ACL admin password

Явные секреты в логи не пишем.
Пароли в командных аргументах всегда маскируются.

---

## 9. Логи
Файл лога:
- `logs/app_YYYYMMDD.log`

UI memo держит только 100 последних строк, чтобы не раздуваться.

Важно: в репозиторий runtime логи/настройки не коммитим.

---

## 10. Локализация
Поддержка:
- RU
- EN
- ID

Переводы встроенные (без внешних lang-файлов), через `uOwmI18n`.
Если добавили новый текст и забыли ключ — это баг, чинить сразу.

---

## 11. Dev notes / техдолг
- Сейчас OpenAPI json генерится на лету, но для внешнего Swagger-импорта держим ещё и `openapi.yaml` в репе.
- SQL*Plus сценарии нужно и дальше держать максимально safe (валидация, экранирование, без unsafe concat).
- Если меняется контракт API — обновляем одновременно:
  1) сервер
  2) API Reference form
  3) `openapi.yaml`
  4) этот spec

---

## 12. Коротко о стиле работы
Это operational-first app.
Сначала починить/восстановить контур (wallet/API), потом уже косметика.

Сухой остаток: инструмент должен быть надёжным в бою, а не просто "красиво на скрине".
