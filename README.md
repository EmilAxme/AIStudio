# AIStudio

iOS-приложение (UIKit) по макету Figma. Два модуля — **AI Text Chat** и **AI Video Generator** — плюс экран **Paywall**.

Этот проход — **вёрстка**: пиксель-в-пиксель повторение экранов, навигация и мок-состояния (Loading / Success / Error). Сетевой слой и Apphud в этом проходе не реализованы, но под них оставлены чистые швы в `Services/` (протоколы + моковые реализации).

## Стек

- UIKit, программная вёрстка (Auto Layout / NSLayoutConstraint), без сторибордов и xib.
- Минимальная версия — iOS 16.0.
- Архитектура **MVC**: `Models` (плоские структуры) · `Views` (переиспользуемые компоненты/ячейки) · `Controllers` (по одному на экран). Без ViewModel и Coordinator.
- Генерация проекта — **XcodeGen** (`project.yml`); `.xcodeproj` не коммитится.
- Шрифт — **Inter** (шрифт макета; встроен в `Resources/Fonts`, зарегистрирован в `UIAppFonts`).
- Иконки — экспортированы из Figma-дизайн-системы в `Assets.xcassets` (`ic*`, template-rendering): arrow, setting, refresh, mic, import, close, image-to-image, magic-pencil, prompt, mortarboard, generate и др. Градиентные иконки = `GradientIconView` (маска-градиент по ассету). Чистый спаркл (лого/поле/аватар) — SF Symbols, т.к. отдельного sparkle-ассета в выгрузке не было.

## Запуск

```sh
brew install xcodegen      # если не установлен
cd AIStudio
xcodegen generate
open AIStudio.xcodeproj
```

Выбрать симулятор iPhone (макет рассчитан на 390×844 pt — iPhone 14/15/16), таргет `AIStudio`, Run.

## Структура

```
AIStudio/
  project.yml
  AIStudio/
    App/          AppDelegate, SceneDelegate, Info.plist
    Models/       ChatMessage, VideoRequest (+ ViewState), Subscription
    Views/        GradientView/GlowView/GradientBorderView, GradientIcon (gradient-fill icon, sparkle logo, GradientLabel),
                  AppButton (GradientButton), HomeFeatureCard, ChatViews, VideoViews, PaywallViews
    Controllers/  Home, Chat, VideoGallery, VideoCreate, Paywall
    Services/     протоколы + моки (Chat / VideoGeneration / Subscription) — задел под сеть и Apphud
    Support/      UIColor+App (палитра), UIFont+App, Layout (константы)
    Resources/    Assets.xcassets
```

## Экраны

1. **Home** — герой-блок (лого, заголовок, поле «Ask anything»), бенто-карточки: «Turn Photo into Video» (→ AI Video), «Fix & Improve Writing» и «Understand Faster» (→ AI Chat). ⚙️ → Paywall.
2. **AI Chat** — кастомный заголовок (аватар + «AI Chat» + дата), переписка (user-бабл с градиентом и хвостом, assistant-бабл с градиентным заголовком и буллетами), поле ввода. Пустой/стартовый экран («Your AI assistant for anything») — тап по «Ask anything» на Home. Отправка добавляет сообщение и через мок-задержку — ответ ассистента. Иконка ↻ открывает **AI Chat History** (Today/Yesterday + пустое состояние).
3. **AI Video — Gallery** — заголовок с аватаром, скролл-чипы категорий, грид 2×N видео-шаблонов (Title по центру). Иконка ↻ открывает **AI Video History** (+ пустое «No videos yet»).
4. **AI Video — Create** («Clay Fool») — карусель-превью, загрузка изображения («+» → системный запрос доступа к фото), параметры Format / Quality и кнопка Create. Состояния:
   По тапу Create открывается **Result**: экран генерации (пульсирующий orb + «Generating…», мок ~2 c) → готовый результат с кнопками **Share** / **Download**; на ошибке — «Try again». (Long-press по Create демонстрирует error.)
5. **Paywall** — заголовок, список преимуществ, тарифы Year/Month (выбранный — с градиентным бордером и бейджем SAVE 80%), кнопка Unlock now, футер.

## Навигация

`UINavigationController` с Home в корне (системный бар скрыт, у экранов кастомные шапки — но сохранены стандартные push-переходы и swipe-back). Home → push Chat / VideoGallery; VideoGallery → push VideoCreate; Paywall показывается модально (по тапу на ⚙️). Таб-бара в макете нет.

## Мок-состояния

Общий `enum ViewState { idle, loading, success, error(String) }` (`Models/VideoRequest.swift`). Экран Video Create гоняет UI через него. Сервисы (`Services/AppServices.swift`) — протоколы `ChatServicing` / `VideoGenerationServicing` / `SubscriptionServicing` с моковыми реализациями (задержки через `DispatchQueue`). Это точки подключения реального API и Apphud на следующем проходе.

## Швы для тестов (только DEBUG)

Запуск сразу в нужный экран/состояние (для снапшотов и ручной проверки; в Release вырезается):

```sh
xcrun simctl launch <udid> com.labs.fviu -INITIAL_SCREEN chat            # home|chat|chatEmpty|chatHistory|chatHistoryEmpty|videoGallery|videoCreate|videoResult|videoHistory|videoHistoryEmpty|paywall
xcrun simctl launch <udid> com.labs.fviu -INITIAL_SCREEN videoCreate -DEBUG_VC_STATE loading   # loading|success|error
```

## Допущения

- Доступа к live-Figma не было (файл вне плана аккаунта) — вёрстка снята с переданных @3x-экспортов (`Тест.zip`); геометрия выверена попиксельным сравнением рендеров симулятора с макетами.
- Корневой экран и переходы из макета неочевидны явно — взят Home как корень с push-навигацией (см. выше); Paywall — по ⚙️.
- Отдельных кадров success/error для видео в макете нет — реализованы как живые состояния формы в стиле макета.
- Изображения-шаблоны — вырезки из референса (плейсхолдеры); реальные приходят с API на следующем проходе.
- Шрифт — системный SF Pro (совпадает с макетом), поэтому `UIAppFonts` пуст.

## Статус

Вёрстка готова, проект собирается под iOS 16 и запускается, мок-состояния работают, критических багов/падений нет. Следующие проходы: сетевой слой (реальные запросы, обработка Loading/Success/Error) и интеграция Apphud (Paywall, проверка подписки, гейтинг премиум-контента).
