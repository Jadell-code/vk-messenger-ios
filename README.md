# VK Messenger для iOS

Нативный клиент ВКонтакте на SwiftUI: авторизация, список чатов, переписка, лента и профиль.
Проект собран с нуля как MVP под iOS 17+, без сторонних зависимостей.

> **Важно.** Проект не аффилирован с VK. Использование VK API, названия и логотипа
> регулируется правилами VK. Перед публикацией в App Store получи разрешение VK
> или используй нейтральный бренд. Подробнее — в разделе «App Store».

## Статус

Проект успешно собирается в GitHub Actions: workflow `iOS Build` проходит,
приложение запускается в симуляторе в демо-режиме. Скриншот доступен в artifact
`demo-screenshot`.

Создано реальное приложение VK ID (`client_id` = `54882991`). Проверено на
Windows: OAuth 2.1 PKCE, обмен кода на токен, `user_info` и `users.get` работают.
Но `messages.getConversations` возвращает ошибку **1051** — VK не выдаёт новым
приложениям доступ к сообщениям. Подробности — в разделе «Ограничение VK API».

Что ещё не проверено:

- интеграция VK ID в само iOS-приложение (сейчас — только скрипты);
- LongPoll с двумя аккаунтами (заблокировано отсутствием `messages`);
- установка на физический iPhone и TestFlight.

Иконка приложения — временная заглушка, её нужно заменить перед релизом.
Подробная инструкция по всем уровням тестирования — в разделе «Тестирование».

## Что уже реализовано

- Вход через VK OAuth (`ASWebAuthenticationSession`) и хранение токена в Keychain
- Список диалогов: аватары, последнее сообщение, время, непрочитанные, online
- Поиск по чатам и pull-to-refresh
- Переписка: история с пагинацией, отправка текста, отметка о прочтении
- Real-time через LongPoll: новые сообщения, typing, прочтение, счётчик непрочитанных
- Лента `newsfeed.get` с фото и ленивой подгрузкой
- Профиль и выход из аккаунта
- Демо-режим без VK API и без ключей
- GitHub Actions для сборки на macOS

## Требования

- macOS + Xcode 16 **или** macOS-раннер GitHub Actions
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- Apple Developer Program — для запуска на устройстве и публикации
- Приложение VK ID (для входа и профиля). Доступ к `messages.*` у новых приложений
  закрыт — см. раздел «Ограничение VK API»

На Windows собрать iOS-приложение нельзя: SwiftUI-код можно редактировать, но сборка
и запуск выполняются только на macOS.

## Быстрый старт

1. В `Config/Local.xcconfig` уже указан `client_id` созданного приложения VK ID:

   ```
   VK_CLIENT_ID = 54882991
   ```

   Это приложение типа Web с redirect URI `http://localhost`. Оно даёт доступ
   только к профилю (имя, фото, пол, дата рождения), почте и телефону.

2. Сгенерируй проект и открой его в Xcode:

   ```bash
   brew install xcodegen
   xcodegen generate
   open VKMessenger.xcodeproj
   ```

3. В настройках таргета `VKMessenger` укажи свою команду разработчика и bundle id
   (сейчас стоит заглушка `com.example.messenger`).

4. Запусти на симуляторе. Без `VK_CLIENT_ID` доступен только демо-режим.

## Настройка приложения VK

Новые Standalone-приложения в `dev.vk.com` больше не создаются: VK перенёс их
в сервис авторизации **VK ID** (`id.vk.ru`). Созданное приложение:

- название: `Messenger iOS`;
- ID приложения: `54882991`;
- платформа: Web;
- базовый домен: `localhost`;
- доверенный redirect URL: `http://localhost`.

В разделе «Доступы» у приложения доступны только:

- личные данные (`vkid.personal_info`) — всегда;
- почта (`email`) — опционально;
- телефон (`phone`) — расширенный доступ.

Ни `messages`, ни `wall`, ни `friends` в списке нет даже при подтверждённом
бизнес-профиле.

### Ограничение VK API

Проверено практически 8 ноября 2026 года:

| Запрос | Результат |
|---|---|
| Обмен кода VK ID на токен (PKCE) | OK |
| `id.vk.ru/oauth2/user_info` | OK, профиль возвращается |
| `users.get` с токеном VK ID | OK |
| `messages.getConversations` | **FAIL: ошибка 1051** |
| Запрос `scope=messages` | VK ID молча выдаёт только `vkid.personal_info` |

Ошибка 1051: `Method is not available for this profile type`. Это ограничение
платформы, а не код приложения. Новые приложения VK ID не получают доступ к
сообщениям, поэтому полноценный сторонний VK-мессенджер через официальный API
сейчас построить нельзя.

Что можно сделать:

1. Оставить приложение как MVP с демо-чатами и реальной авторизацией VK ID
   (профиль, почта, телефон).
2. Написать в `devsupport@corp.vk.com` и запросить доступ к `messages` для
   бизнес-профиля. Решение VK, сроки и вероятность одобрения не гарантированы.
3. Выбрать мессенджер с открытым API (Telegram, Matrix, Discord и т.п.) и
   переиспользовать UI.

### Если VK требует VK ID вместо OAuth implicit flow

Старый implicit flow (`https://oauth.vk.com/authorize` с `response_type=token`)
с новым client_id возвращает `Security Error`. Для VK ID используется OAuth 2.1
с PKCE:

1. `https://id.vk.ru/authorize` с `response_type=code`, `code_challenge` и
   `code_challenge_method=S256`.
2. VK возвращает `code`, `state` и `device_id` на redirect URI.
3. `POST https://id.vk.ru/oauth2/auth` с `grant_type=authorization_code`
   обменивает код на `access_token`, `refresh_token` и `id_token`.
4. Токен живёт 1 час, обновляется через `grant_type=refresh_token`.

Готовые скрипты для Windows:

```powershell
.\scripts\vk-id-auth-url.ps1 -Open
.\scripts\vk-id-exchange.ps1 -RedirectUrl "<URL из адресной строки>"
```

Для iOS-приложения VK ID требует платформу iOS и Universal Link на реальном
домене (например, `https://example.com/vk-id`). Без домена и Apple Developer
аккаунта этот шаг не завершить. Текущее приложение пока использует старый
`AuthStore` с implicit flow; его нужно заменить на PKCE-обмен, когда появится
домен и доступ к VK API.

## Демо-режим

На экране входа нажми «Посмотреть демо-режим». Приложение покажет тестовые чаты,
сообщения, ленту и профиль без сетевых запросов к VK. Демо-данные лежат в
`VKMessenger/Demo/DemoData.swift`.

Демо можно запустить сразу, без нажатия кнопки — добавь аргумент `--demo`:

- в Xcode: **Product → Scheme → Edit Scheme → Run → Arguments → Arguments Passed On Launch**
  и добавь `--demo`;
- из терминала: `xcrun simctl launch booted com.example.messenger --demo`.

## Тестирование

Проверять приложение можно на четырёх уровнях. Начинай сверху вниз: каждый следующий
уровень требует больше настроек.

| Уровень | Что проверяет | Что нужно |
|---|---|---|
| 1. Демо в симуляторе | UI, навигация, отправка сообщений на фейковых данных | Mac с Xcode |
| 2. GitHub Actions | Компиляцию и запуск в симуляторе | Только GitHub |
| 3. Реальный VK | OAuth, VK API, LongPoll | `VK_CLIENT_ID` и доступ к Messages API |
| 4. Устройство / TestFlight | Подпись, работу на iPhone, установку | Apple ID или Developer Program |

### 1. Демо-режим в симуляторе (Mac)

```bash
brew install xcodegen
xcodegen generate
open VKMessenger.xcodeproj
```

В Xcode:

1. Выбери схему `VKMessenger` и любой iPhone-симулятор с iOS 17+.
2. Нажми **Run** (⌘R). Первая сборка может занять несколько минут.
3. На экране входа нажми **«Посмотреть демо-режим»**.

Если хочешь запускать демо автоматически, добавь `--demo` в аргументы схемы
(см. раздел «Демо-режим»).

Полный запуск из терминала, без ручных кликов:

```bash
# 1. Собрать под конкретный симулятор
xcodebuild -project VKMessenger.xcodeproj \
  -scheme VKMessenger \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO build

# 2. Запустить симулятор
xcrun simctl boot "iPhone 16" || true
open -a Simulator
xcrun simctl bootstatus "iPhone 16" -b

# 3. Установить и запустить приложение в демо-режиме
xcrun simctl install booted \
  build/Build/Products/Debug-iphonesimulator/VKMessenger.app
xcrun simctl launch booted com.example.messenger --demo
```

Имя симулятора (`iPhone 16`) замени на доступное:

```bash
xcrun simctl list devices available
```

Что проверить в демо:

- в списке 4 чата: «Анна Петрова», «Рабочий чат», «Дмитрий Соколов», «VK Team»;
- у Анны 2 непрочитанных, у VK Team — 1;
- открой чат с Анной: 3 сообщения, история отображается снизу;
- отправь сообщение — оно появляется в переписке;
- открой «Рабочий чат» — есть фото-вложение;
- лента: 3 поста, у первых двух загружаются картинки;
- профиль: имя «Демо Пользователь», режим «Демо»;
- выйди из аккаунта — вернёшься на экран входа.

Демо не проверяет сеть, OAuth и LongPoll — это только UI-прогон.

### 2. CI без Mac (GitHub Actions)

Если Mac нет, единственный способ реально скомпилировать проект — GitHub Actions.

Сначала установи на Windows [Git for Windows](https://git-scm.com/download/win) или
[GitHub Desktop](https://desktop.github.com) — без них не получится загрузить проект
в репозиторий.

1. Создай пустой репозиторий на GitHub (можно private).
2. В папке проекта выполни:

   ```bash
   git init
   git add .
   git commit -m "Initial VK Messenger MVP"
   git branch -M main
   git remote add origin https://github.com/<username>/<repo>.git
   git push -u origin main
   ```

3. Открой вкладку **Actions** → workflow **iOS Build**.
4. Он запустится сам после push. Если нет — **Run workflow** (workflow_dispatch).
5. Дождись зелёной галочки. Сборка занимает примерно 5–15 минут.
6. Внизу страницы запуска скачай artifact **demo-screenshot** — внутри `demo.png`.
   Это скриншот приложения, запущенного в симуляторе с аргументом `--demo`.

Как читать результат:

- **Build for simulator** упал — ошибка компиляции. Открой лог, найди строки
  с `error:`; это первые реальные ошибки в коде, их нужно исправить.
- **Boot iOS Simulator** упал — на раннере не нашёлся iPhone-симулятор или
  не поднялся runtime.
- **Launch demo and capture screenshot** упал — приложение собралось, но не
  установилось/не запустилось. Проверь bundle id и имя `.app`.
- Артефакт со скриншотом есть — приложение запускается и доходит до списка чатов.

Важно: workflow собирает только симуляторную сборку без подписи. Установить её
на iPhone нельзя. Если поменяешь bundle id в `project.yml`, обнови строку запуска
в `.github/workflows/ios.yml`:

```yaml
xcrun simctl launch "${{ steps.simulator.outputs.device_id }}" \
  com.example.messenger --demo
```

Приватные репозитории расходуют минуты GitHub Actions; macOS-раннер считается
с повышенным коэффициентом. Для публичного репозитория минуты бесплатны.

### 3. Тест с реальным VK

Сейчас реальный VK проверяется в два этапа.

**Этап A. Авторизация VK ID (работает).**

На Windows, без Mac:

1. Сгенерируй ссылку и открой её:

   ```powershell
   .\scripts\vk-id-auth-url.ps1 -Open
   ```

2. Войди в VK и нажми «Разрешить».
3. Браузер перейдёт на `http://localhost/?code=...`. Скопируй весь URL из
   адресной строки.
4. Обменяй код на токен и проверь профиль:

   ```powershell
   .\scripts\vk-id-exchange.ps1 -RedirectUrl "<URL из адресной строки>"
   ```

Скрипт покажет:

- обмен кода на токен — OK;
- `id.vk.ru/oauth2/user_info` — OK;
- `users.get` — OK;
- `messages.getConversations` — ошибка 1051.

Токен нигде не печатается.

**Этап B. Сообщения и LongPoll (заблокировано VK).**

Проверить `messages.*` и LongPoll не получится: VK ID не выдаёт scope `messages`.
Если у тебя есть старый Standalone-токен с доступом к сообщениям, его можно
проверить скриптом:

```powershell
.\scripts\vk-smoke-test.ps1
```

Скрипт скрыто запросит токен и проверит `users.get`,
`messages.getConversations` и `messages.getLongPollServer`. Для токена VK ID
второй и третий пункты вернут ошибку — это ожидаемо.

**Что это значит для iOS-приложения.**

Вход через VK ID в приложении ещё не подключён: текущий `AuthStore` использует
старый implicit flow и с новым client_id не работает. Для полноценной проверки
на iPhone нужны:

1. Домен с HTTPS и Universal Link для платформы iOS в VK ID.
2. Apple Developer аккаунт для Associated Domains.
3. Доступ к `messages`, которого у новых приложений нет.

Поэтому на данном этапе приложение проверяется в демо-режиме, а VK ID — через
скрипты на Windows.

### 4. Устройство и TestFlight

**Бесплатный Apple ID (7 дней):**

1. Подключи iPhone к Mac, включи режим разработчика.
2. В Xcode: таргет `VKMessenger` → **Signing & Capabilities** → выбери свой
   Personal Team.
3. Смени bundle id на уникальный, например `com.<твоёимя>.messenger`.
4. Выбери iPhone как устройство и нажми Run. Приложение будет работать 7 дней,
   потом нужно переустановить.

**Developer Program ($99/год):**

1. Оформи подписку и создай App ID в Apple Developer.
2. В Xcode укажи команду и bundle id, проверь подпись.
3. **Product → Archive** → **Distribute App** → App Store Connect.
4. Загрузи сборку в TestFlight и добавь тестировщиков.

Для реального устройства текущая URL-схема `vk$(VK_CLIENT_ID)` не подойдёт:
VK ID требует Universal Link на HTTPS-домене. Понадобится домен, файл
`apple-app-site-association` и entitlement Associated Domains. Схема в
`Info.plist` останется как запасной вариант для демо и старых Standalone-токенов.

### 5. Ручной smoke-чеклист

Проходи по списку перед каждым релизом:

- [ ] холодный запуск без падений;
- [ ] вход через VK открывает страницу и возвращает в приложение;
- [ ] неверный/пустой `VK_CLIENT_ID` показывает понятную ошибку;
- [ ] список чатов загружается, аватары и время отображаются;
- [ ] поиск фильтрует чаты по имени и тексту;
- [ ] pull-to-refresh обновляет список;
- [ ] открытие чата грузит историю;
- [ ] «Загрузить ещё» подгружает старые сообщения;
- [ ] отправка текста работает, поле очищается;
- [ ] новое сообщение приходит по LongPoll без ручного обновления;
- [ ] «печатает» появляется и исчезает;
- [ ] отметка о прочтении обновляется;
- [ ] лента грузится, картинки отображаются;
- [ ] профиль показывает имя, аватар и режим;
- [ ] выход возвращает на экран входа;
- [ ] повторный запуск сохраняет сессию (реальный VK);
- [ ] тёмная тема выглядит корректно;
- [ ] на маленьком экране (iPhone SE) ничего не обрезается;
- [ ] нет крашей при быстром переключении вкладок и pull-to-refresh.

### 6. Частые ошибки при тестировании

| Симптом | Причина | Что делать |
|---|---|---|
| `invalid client_id` | Неверный `VK_CLIENT_ID` или приложение VK неактивно | Сверь ID в `Local.xcconfig` и на dev.vk.com |
| `redirect_uri` mismatch | Redirect URI в VK не совпадает с `vk<id>://authorize` | Исправь настройки приложения VK и `Info.plist` |
| Ошибка VK 5 | Токен истёк или отозван | Выйди и войди заново |
| Ошибка VK 7/15 | Нет доступа к `messages.*` | Запроси доступ к Messages API у VK |
| Ошибка VK 14 | VK требует капчу | Подожди или обработай капчу отдельно |
| LongPoll не подключается | Нет доступа к `messages.getLongPollServer` | Проверь права приложения VK |
| Лента пустая | У аккаунта нет подписок | Подпишись на сообщества и обнови ленту |
| CI не находит `.app` | Изменился bundle id или схема | Проверь путь и `simctl launch` в workflow |

### 7. Чего пока нет

- Автотестов (unit/UI). Их можно добавить отдельным таргетом в `project.yml`.
- Проверки сети в демо-режиме: демо полностью локальное.
- CI-скриншот доказывает только запуск, а не корректность всех экранов.
- Push-уведомлений и фоновой доставки — их тестировать пока нечего.

## Архитектура

```
VKMessenger/
  App/            точка входа, AppEnvironment, RootView, MainTabView
  Auth/           AuthStore, LoginView
  Core/           AppConfig, VKSession, KeychainStore, форматтеры
  Networking/     VKAPI-протокол, HTTP-клиент, модели, лента
  Realtime/       LongPoll и мультикаст событий
  Demo/           DemoAPIClient и тестовые данные
  Features/
    Chats/        список диалогов
    Chat/         переписка
    Feed/         лента
    Profile/      профиль
  UI/             тема, аватар, бабблы, бейджи
  Resources/      Info.plist, Assets.xcassets
```

- **SwiftUI + Observation** (`@Observable`), MVVM без внешних библиотек.
- **VKAPI** — протокол; реальный клиент `VKAPIClient`, демо — `DemoAPIClient`.
- **LongPoll** — один общий поток событий, подписчики получают `AsyncStream`.
- **Токен** — только в Keychain, в коде и логах не хранится.

## Сборка в CI

Workflow `.github/workflows/ios.yml` собирает приложение на `macos-15`:

```bash
xcodegen generate
xcodebuild -project VKMessenger.xcodeproj -scheme VKMessenger \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build
```

Для TestFlight/App Store нужны подпись и секреты Apple Developer (сертификат,
provisioning profile, App Store Connect API key). Их нельзя хранить в репозитории:
добавь их в GitHub Secrets и отдельный release-workflow.

## App Store: критичные ограничения

1. **Guideline 4.2 (Minimum Functionality).** Простая WebView-обёртка сайта будет
   отклонена. Здесь нативный UI и работа с API — это требование выполнено, но
   приложение должно оставаться полезным без сайта.
2. **Guideline 5.2 (Intellectual Property).** Нельзя использовать имя, логотип и
   фирменный стиль VK без разрешения. Для публикации нужен договор/разрешение VK
   либо нейтральное название и бренд.
3. **Guideline 4.8 (Login Services).** Если VK-вход — основной, Apple может
   потребовать добавить Sign in with Apple. Проверь актуальную формулировку перед
   ревью.
4. **Доступ к VK API.** Проверено: VK ID не выдаёт `messages` новым приложениям,
   `messages.getConversations` возвращает ошибку 1051. Без доступа к сообщениям и
   LongPoll приложение не сможет работать как мессенджер. Это главный блокер,
   который нужно закрыть до релиза (запрос в `devsupport@corp.vk.com` или смена
   платформы).
5. **Push-уведомления.** Для фоновых пушей нужен сервер: APNs + подписка на
   LongPoll/события VK. В MVP пуши не входят.
6. **UGC и модерация (Guideline 1.2).** Для мессенджера и ленты Apple требует
   механизмы жалоб, блокировки пользователей и фильтрации контента. Это следующий
   этап перед публикацией.
7. **Приватность.** Нужны политика конфиденциальности и корректная работа с
   аккаунтом (выход/удаление данных).

## Дальнейшие шаги

- Push-уведомления (сервер + APNs)
- Отправка фото/файлов, голосовые сообщения
- Локальный кэш чатов и офлайн-очередь (SwiftData/GRDB)
- Поиск по сообщениям, закреплённые чаты, папки
- Интеграция VK ID PKCE в приложение (сейчас VK ID проверен только скриптами)
- Тесты сетевого слоя и моделей
- Локализация (ru/en), Dynamic Type, VoiceOver
- Модерация UGC, жалобы и блокировки для App Store

## Известные ограничения MVP

- Вложения только отображаются, загрузить свои нельзя.
- Нет пушей и фонового обновления.
- Нет кэша: при каждом запуске данные загружаются заново.
- LongPoll не переподключается при смене сети мгновенно (есть retry с задержкой).
- Тёмная тема — системная, отдельных настроек нет.
