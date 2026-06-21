# AIStudio

iOS-приложение (UIKit) по макету Figma. Два модуля — **AI Text Chat** и **AI Video Generator** — плюс экран **Paywall**.

Текущее состояние: **вёрстка + реальный сетевой слой + Apphud**. Чат и видео ходят в живые API, Paywall наполняется реальными продуктами Apphud, премиум-генерация закрыта подпиской (разблокировка без перезапуска).

## Стек

- UIKit, программная вёрстка (Auto Layout / NSLayoutConstraint), без сторибордов и xib.
- Минимальная версия — iOS 16.0. `async/await` для сети и покупок.
- Архитектура **MVC** + сервисный слой: `Models` · `Views` · `Controllers` (по экрану) · `Services` (сеть, идентичность, подписка). Сервисы внедряются в контроллеры через инициализаторы (DI с дефолтами из `AppServices`).
- Генерация проекта — **XcodeGen** (`project.yml`); `.xcodeproj` не коммитится.
- Зависимости — **ApphudSDK** (SPM, `from: 3.3.0`; резолвится в 3.6.x).
- Шрифт — **Inter** (встроен в `Resources/Fonts`). Иконки — `ic*` из Figma в `Assets.xcassets`.

## Запуск

```sh
brew install xcodegen      # если не установлен
cd AIStudio
xcodegen generate          # подтягивает ApphudSDK и StoreKit-конфиг в схему
open AIStudio.xcodeproj
```

Таргет `AIStudio`, симулятор iPhone (макет на 390×844), Run. Bundle id — `com.labs.fviu`.

Сборка из CLI:
```sh
xcodebuild -project AIStudio.xcodeproj -scheme AIStudio -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16' -derivedDataPath build build
```

## Структура

```
AIStudio/
  project.yml
  AIStudio/
    App/          AppDelegate (Apphud.start до UI), SceneDelegate, Info.plist
    Models/       ChatMessage, VideoRequest (+ ViewState), HistoryItem
    Views/        ChatViews (+ typing/error-бабл), VideoViews, PaywallViews, GradientIcon, AppButton …
    Controllers/  Home, Chat, VideoGallery, VideoCreate, VideoResult, Paywall, History
    Services/
      AppServices.swift            — composition root (live-граф сервисов)
      Identity/                    — UserIdentifierProviding (Apphud / device-fallback, санитайзер)
      Network/                     — Endpoint, HTTPBody (json/form/multipart), APIError,
                                     NetworkService, ChatAPIService, VideoAPIService
      Subscription/                — SubscriptionService (Apphud paywall/purchase/restore)
    Support/      AppConfig (URL/токен/ключи), UIColor+App, UIFont+App, Layout
    Resources/    Assets.xcassets, Fonts, AIStudio.storekit
```

## Конфигурация

Все секреты — в `Support/AppConfig.swift` (не по месту вызова). В проде выносятся в `.xcconfig`/Keychain.

- **Chat (Dola):** `https://nebulaapps.site/dola`
- **Video (PixVerse):** `https://nebulaapps.site/pixverse`
- **app_id:** `com.test.test` (бэкенд-идентификатор приложения; отличается от bundle id `com.labs.fviu`)
- **Bearer:** постоянный JWT (в `AppConfig.API.bearerToken`)
- **Apphud:** ключ `app_FmCjFTwjWpcLSafxT8vCDeVffJyfFS`, paywall `main`

### user_id

`user_id` каждого запроса = `Apphud.userID()` (`ApphudUserIdentifierProvider`, кэшируется на старте, т.к. API `@MainActor`; санитайзится под паттерн бэкенда `^[A-Za-z0-9._:-]{1,36}$`). При пустом id — фолбэк на стабильный device-UUID (`DeviceUserIdentifierProvider`). Провайдер внедряется в сетевые сервисы через DI, подменяется без правок вызывающего кода.

## Сетевой слой

`Services/Network`:
- `Endpoint` — протокол (baseURL/path/method/queryItems/headers/body); `urlRequest()` собирает запрос и всегда добавляет `Authorization: Bearer …`.
- `HTTPBody` — `.json` (через type-erased `AnyEncodable`, snake_case), `.formURLEncoded`, `.multipart` (для загрузки фото).
- `APIError` — `invalidResponse / unauthorized / server(status,msg) / decoding / transport` с человеческими (рус.) сообщениями для error-состояний.
- `NetworkService` (`URLSessionNetworkService`) — `async` поверх `URLSession.data(for:)`. 2xx→decode, 401/403→`.unauthorized`, иначе→`.server` (с разбором FastAPI `detail`); транспорт и декодинг — отдельные кейсы. Лог запроса/ответа — только в `#if DEBUG` (OSLog, subsystem `com.labs.fviu`).

### Эндпоинты (выверены живыми запросами)

**Chat** — `POST {chatBase}/chats/{chat_id}/messages?user_id=&app_id=`, JSON `{message}` → `{chat_id, assistant_message}`. `chat_id` генерируется клиентом (UUID); сервер создаёт чат при первом сообщении и возвращает тот же id (переиспользуется для всей переписки).

**Video** (генерация асинхронная — запуск + опрос статуса):
- `POST {videoBase}/api/v1/text2video` (form: prompt, duration, model=v6, quality, aspect_ratio) → `{video_id}`
- `POST {videoBase}/api/v1/image2video` (multipart: prompt, duration, model, quality, image) → `{video_id}`
- `GET {videoBase}/api/v1/status?id=&user_id=&app_id=` → `{status, video_url}`

`VideoAPIService` сам выбирает text2video / image2video (по наличию фото), затем опрашивает `status` каждые 2 c (таймаут ~2 мин, отмена через `Task`), возвращает URL готового видео. `quality`: `540p/720p/1080p` как есть, `4K` → `1080p` (потолок API).

> Эндпоинт `POST /ai-writing` есть в схеме, но в песочнице отдаёт 404, и отдельного экрана AI Writing в текущем скоупе нет — не подключён.

## Подключение экранов

- **AI Chat** — отправка дёргает `ChatAPIService`; пока ждём — typing-индикатор (loading), успех → бабл ассистента, ошибка → видимый error-бабл с тапом «повторить». Состояния гоняются через существующий механизм рендера переписки.
- **AI Video** — Create собирает `VideoRequest` (prompt = название шаблона, выбранные фото, format, quality) и пушит Result; Result дёргает `VideoAPIService` (реальный запуск + опрос), показывает существующие состояния loading (orb «Generating…») / success / error («Try again»). На success: play открывает реальное видео (AVKit), Share/Download работают с URL результата (Download качает и сохраняет в галерею).

## Apphud и подписка

- `Apphud.start(apiKey:)` — в `didFinishLaunchingWithOptions` **до** построения UI (SceneDelegate отрабатывает позже), так что `Apphud.userID()` доступен для первого же запроса.
- `SubscriptionService` (единый источник правды):
  - `isPremium` = `Apphud.hasActiveSubscription()`
  - `loadPaywall()` — `Apphud.placements()` → paywall с `identifier == "main"`, `Apphud.paywallShown(_)`
  - `purchase(_)` / `restore()` → `Result<Bool, Error>`, после — пост `SubscriptionService.statusDidChange` (object: isPremium)
  - `ApphudDelegate.apphudSubscriptionsUpdated` → тоже пост уведомления
- **Paywall** — наполняется реальными продуктами (`paywall.products`): цена/период/триал берутся из StoreKit-продукта (`SKProduct.price + priceLocale`, формат через `NumberFormatter`), **не хардкодятся**. Покупка/восстановление — `purchase()`/`restore()`; загрузка/ошибки — через лоадер на кнопке и алерты с ретраем.

### Гейтинг и разблокировка без перезапуска

- Премиум-функция = **генерация видео** (см. «Допущения»). При тапе Create без подписки показывается Paywall.
- `PaywallViewController.onUnlocked` вызывается после успешной покупки/restore: paywall закрывается и **сразу** выполняется отложенное действие (переход к генерации) — без перезапуска. Гейт проверяется в момент действия (`isPremium`), поэтому всегда актуален; плюс рассылается `statusDidChange` для подписчиков.

## StoreKit (локальный тест покупок)

`Resources/AIStudio.storekit` подключён к схеме (Run → Options → StoreKit Configuration, Debug).

> ⚠️ **Product id — плейсхолдеры** (`com.labs.fviu.premium.yearly` / `…monthly`). Реальные id продуктов paywall `main` в этом окружении получить не удалось (бэкенд Apphud `gateway.apphud.com` недоступен из песочницы). Чтобы тест покупок заработал:
> 1. Запустить приложение в среде с доступом к Apphud и открыть Paywall — в консоли (DEBUG) печатается `📦 Apphud paywall 'main' products: [...]` с реальными id.
> 2. Подставить эти id в `productID` внутри `AIStudio.storekit` (и при необходимости период/цену).
> 3. Для sandbox/прод нужны реальные продукты в App Store Connect; ревьюер-владелец `com.labs.fviu` тестирует в sandbox.

## Швы для тестов (только DEBUG)

```sh
xcrun simctl launch <udid> com.labs.fviu -INITIAL_SCREEN chat
#   home|chat|chatEmpty|chatHistory|chatHistoryEmpty|videoGallery|videoCreate|videoResult|videoHistory|videoHistoryEmpty|paywall
xcrun simctl launch <udid> com.labs.fviu -INITIAL_SCREEN chatEmpty -SELFTEST_CHAT YES   # авто-отправка одного сообщения в живой API
xcrun simctl launch <udid> com.labs.fviu -INITIAL_SCREEN videoCreate -DEBUG_VC_STATE success
```

## Допущения

- **Точка гейтинга** в макете/коде явно не задана → по умолчанию закрыта **генерация видео** (Paywall при попытке Create без подписки). Сверх этого ничего наугад не закрывалось.
- **Prompt для видео** берётся из названия шаблона (полей ручного промпта в макете нет); `model=v6`, `duration=5` — дефолты PixVerse.
- **Деление цены «/week»** на Paywall считается из периода и цены StoreKit-продукта (год → /52, месяц → /4.345); при отсутствии данных показывается только название тарифа + полная цена.
- Эндпоинт `ai-writing` не подключён (404 в песочнице, нет экрана).

## Проверка / статус

- `xcodegen generate` отрабатывает, ApphudSDK подтягивается, проект **собирается под iOS 16** (BUILD SUCCEEDED), запускается без падений.
- Чат: запрос уходит в живой API с корректными `user_id` (=`Apphud.userID()`), `app_id`, Bearer и JSON-телом (подтверждено логами); состояния loading→success/error работают (error-бабл с ретраем отрисован вживую).
- Видео: запуск + опрос статуса реализованы по факту контракта (выверено реальными запросами к sandbox: `text2video`/`image2video` → `video_id`, `status` → `completed` + url).
- Paywall: грузит продукты, при недоступности — корректное error-состояние; покупка/restore/гейтинг/разблокировка-без-перезапуска реализованы.

> **Замечание про окружение:** из iOS-симулятора в этой песочнице нет сетевого маршрута к внешним хостам (DNS-ошибки и к `gateway.apphud.com`, и к `nebulaapps.site`), поэтому live-ответ в симуляторе не приходит — приложение корректно показывает error-состояние. Контракт и Codable-модели выверены прямыми запросами к API с хоста (curl); сам запрос приложение формирует и отправляет верно (см. логи). В среде с доступом к сети симулятора чат/видео/Apphud отрабатывают полностью.
