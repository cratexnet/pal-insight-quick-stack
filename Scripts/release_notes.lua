local Localization = require("localization")

local ReleaseNotes = {}

-- Keep 1-5 single-topic, user-visible summaries per public release. dateUtc is
-- the earliest verified public timestamp across official channels; blank means
-- that no public timestamp has been verified. Preserve source precision rather
-- than inventing seconds. Repository times are not releases.
ReleaseNotes.versions = {
    { version = "1.2.0", dateUtc = "", groups = {
        { kind = "added", items = { 1, 2, 3, 4 } },
    } },
    { version = "1.1.0", dateUtc = "2026-09-04 16:22", groups = {
        { kind = "added", items = { 5, 6 } },
        { kind = "changed", items = { 7 } },
        { kind = "fixed", items = { 12 } },
    } },
    { version = "1.0.0", dateUtc = "2026-09-02 21:15", groups = {
        { kind = "added", items = { 8, 9, 10 } },
        { kind = "performance", items = { 11 } },
    } },
    { version = "0.1.0", dateUtc = "2026-08-30 18:07", groups = {
        { kind = "added", items = { 13, 14, 15, 16 } },
        { kind = "performance", items = { 17 } },
    } },
}

local TEXT = {
    en = {
        title = "Version updates", selectVersion = "Select version", added = "Added", changed = "Changed", performance = "Performance", fixed = "Fixed",
        [1] = "Added automatic selling for four independently configurable item categories: 9 high-value merchant items, 32 ammunition types, 10 Pal Sphere types, and 4 fishing baits. Every category is disabled by default.",
        [2] = "Added icon-assisted keep lists for every sale category. Checked items are not sold, and item names follow all 17 supported game languages. The selectors support mouse, keyboard, and controller input.",
        [3] = "Automatic selling runs before Quick Stack storage. Items excluded through Inventory Tab → R are always protected, and sales use the selected result-display mode.",
        [4] = "Added localized release history, opened by selecting the version number in the settings header.",
        [5] = "Added optional storage in an accessible Guild Chest at the current guild base, with permission and capacity checks. Disabled by default.",
        [6] = "Added optional small-incubator routing after large incubators, while skipping occupied incubators and unclaimed Pals. Disabled by default.",
        [7] = "Temporarily unavailable storage and incubator state is reread a limited number of times before the target is skipped.",
        [8] = "Added F5 quick storage for eligible backpack items in the current base, with rules for ignored and new item types.",
        [9] = "Added dedicated Incubator routing for Pal Eggs and Ancient Relic Recycler routing for Relics. Each Recycler keeps 10 World Tree Holy Water by default, adjustable from 1 to 100.",
        [10] = "Added F6 settings and detailed or text results, with optional Pal Insight hosting and all 17 Palworld interface languages. Released separate Steam/Win64 and WinGDK packages for Nexus Mods and CurseForge.",
        [11] = "Reduced storage stutter and waiting time with bounded work, serialized move requests, and destination revalidation.",
        [12] = "Fixed the small-incubator setting not being applied to storage runs and corrected detection of unclaimed hatched Pals.",
        [13] = "Introduced F5 Quick Stack for matching backpack items in private storage at the current base, prioritizing existing stacks before filter-compatible storage.",
        [14] = "Added Inventory Tab → R exclusions, including Pal Eggs, and incubator-first egg routing. Guild Chests were never automatic destinations.",
        [15] = "Added native-style progress messages and result cards for stored, excluded, and storage-full items, localized in all 17 Palworld interface languages.",
        [16] = "Added standalone shortcut configuration and optional shortcut editing through Pal Insight 1.8.0 or later. Pal Insight remained optional.",
        [17] = "Split storage scans into bounded steps and serialized destination requests to reduce one-frame stalls, with destination revalidation before each move.",
    },
    ["zh-hans"] = {
        title = "版本更新", selectVersion = "选择版本", added = "新增", changed = "改动", performance = "性能优化", fixed = "问题修复",
        [1] = "新增自动出售物品功能，可分别设置 4 类物品：9 种商人高价收购品、32 种弹药、10 种帕鲁球和 4 种钓饵。各类别均默认关闭。",
        [2] = "所有出售类别均新增带图标的保留列表。勾选的物品不会出售，物品名称支持全部 17 种游戏语言。选择框支持鼠标、键盘和手柄操作。",
        [3] = "自动出售先于一键归箱的收纳执行。通过背包 Tab → R 排除的物品始终受到保护，出售结果使用所选的结果显示方式。",
        [4] = "新增本地化版本历史，可点击设置页标题栏中的版本号查看。",
        [5] = "新增可选的当前公会据点公会箱收纳，并在使用前检查权限和容量；默认关闭。",
        [6] = "新增可选的小型孵化器收纳：大型孵化器优先，并跳过已有蛋或未领取帕鲁的孵化器；默认关闭。",
        [7] = "仓库或孵化器状态暂时不可读时，会进行有限次数的重读，仍无法确认则跳过该目标。",
        [8] = "新增当前据点内的 F5 快速收纳，并可设置是否收纳已排除物品和仓库中没有的物品种类。",
        [9] = "新增帕鲁蛋的孵化器路线和古代文明遗物的古代遗物回收机路线。每台回收机默认保留 10 个世界树圣水，可设置为 1–100。",
        [10] = "新增 F6 设置和详细或文字结果，可由 Pal Insight 托管，并支持全部 17 种帕鲁界面语言。Nexus Mods 与 CurseForge 分别提供 Steam/Win64 和 WinGDK 包。",
        [11] = "通过分段处理、逐个发送移动请求和移动前复核目标，减少收纳卡顿和等待时间。",
        [12] = "修复小型孵化器设置未应用于收纳任务的问题，并纠正未领取孵化帕鲁的识别。",
        [13] = "首次推出 F5 一键归箱：将当前据点背包中的匹配物品存入私人仓库，先使用已有同类物品的仓库，再使用过滤器允许的仓库。",
        [14] = "新增背包 Tab → R 排除规则（包括帕鲁蛋）和帕鲁蛋优先进入孵化器的路线；公会箱不会成为自动收纳目标。",
        [15] = "新增原生风格的进度提示和结果卡片，显示已收纳、已排除及仓库已满的物品，并支持全部 17 种帕鲁界面语言。",
        [16] = "新增独立快捷键设置，也可通过 Pal Insight 1.8.0 或更高版本编辑快捷键；Pal Insight 始终为可选依赖。",
        [17] = "将仓库扫描拆分为有界步骤，并逐个发送目标移动请求，以减少单帧卡顿；每次移动前都会重新验证目标。",
    },
    ["zh-hant"] = {
        title = "版本更新", selectVersion = "選擇版本", added = "新增", changed = "變更", performance = "效能最佳化", fixed = "問題修正",
        [1] = "新增自動出售物品功能，可分別設定 4 類物品：9 種商人高價收購品、32 種彈藥、10 種帕魯球和 4 種釣餌。各類別均預設關閉。",
        [2] = "所有出售類別均新增帶圖示的保留清單。勾選的物品不會出售，物品名稱支援全部 17 種遊戲語言。選擇框支援滑鼠、鍵盤和控制器操作。",
        [3] = "自動出售先於一鍵歸箱的收納執行。透過背包 Tab → R 排除的物品始終受到保護，出售結果使用所選的結果顯示方式。",
        [4] = "新增本地化版本記錄，可選取設定頁標題列中的版本號查看。",
        [5] = "新增可選的目前公會據點公會箱收納，並在使用前檢查權限和容量；預設關閉。",
        [6] = "新增可選的小型孵化器收納：大型孵化器優先，並略過已有蛋或未領取帕魯的孵化器；預設關閉。",
        [7] = "倉庫或孵化器狀態暫時無法讀取時，會進行有限次數的重讀，仍無法確認則略過該目標。",
        [8] = "新增目前據點內的 F5 快速收納，並可設定是否收納已排除物品和倉庫中沒有的物品種類。",
        [9] = "新增帕魯蛋的孵化器路線和古代文明遺物的古代遺物回收機路線。每台回收機預設保留 10 個世界樹聖水，可設定為 1–100。",
        [10] = "新增 F6 設定和詳細或文字結果，可由 Pal Insight 代管，並支援全部 17 種帕魯介面語言。Nexus Mods 與 CurseForge 分別提供 Steam/Win64 和 WinGDK 套件。",
        [11] = "透過分段處理、逐一傳送移動請求和移動前重新驗證目標，減少收納卡頓和等待時間。",
        [12] = "修正小型孵化器設定未套用至收納工作的問題，並修正未領取孵化帕魯的判定。",
        [13] = "首次推出 F5 一鍵歸箱：將目前據點背包中的匹配物品存入私人倉庫，先使用已有同類物品的倉庫，再使用篩選器允許的倉庫。",
        [14] = "新增背包 Tab → R 排除規則（包括帕魯蛋）和帕魯蛋優先進入孵化器的路線；公會箱不會成為自動收納目標。",
        [15] = "新增原生風格的進度提示和結果卡片，顯示已收納、已排除及倉庫已滿的物品，並支援全部 17 種帕魯介面語言。",
        [16] = "新增獨立快捷鍵設定，也可透過 Pal Insight 1.8.0 或更高版本編輯快捷鍵；Pal Insight 始終為選用依賴。",
        [17] = "將倉庫掃描拆分為有界步驟，並逐一傳送目標移動請求，以減少單幀卡頓；每次移動前都會重新驗證目標。",
    },
    ja = {
        title = "更新履歴", selectVersion = "バージョンを選択", added = "追加", changed = "変更", performance = "パフォーマンス", fixed = "修正",
        [1] = "個別に設定できる4カテゴリの自動売却を追加しました：高価買取品9種、弾薬32種、パルスフィア10種、釣り餌4種。各カテゴリは初期設定でオフです。",
        [2] = "全売却カテゴリにアイコン付き保持リストを追加しました。チェックした品は売却されず、名称は17言語に対応します。選択画面はマウス、キーボード、コントローラー入力に対応します。",
        [3] = "自動売却はQuick Stackの収納前に実行されます。バッグのTab → R除外品は常に保護され、売却結果には選択した結果表示方式が使われます。",
        [4] = "設定画面のヘッダーにあるバージョン番号から開ける、ローカライズ済みの更新履歴を追加しました。",
        [5] = "現在のギルド拠点で利用できるギルドチェストへの任意収納を、権限と容量の確認付きで追加しました。初期設定ではオフです。",
        [6] = "大型孵化器を優先し、使用中や未回収パルのいる孵化器を避ける小型孵化器ルートを追加しました。初期設定ではオフです。",
        [7] = "収納や孵化器の状態を一時的に読めない場合、回数を制限して再読込し、確認できなければスキップします。",
        [8] = "現在の拠点で対象アイテムを収納するF5機能と、除外品・新規品種のルールを追加しました。",
        [9] = "パルの卵を孵化器へ、遺物を古代遺物リサイクラーへ送る専用ルートを追加しました。各リサイクラーは世界樹の聖水を初期値10、範囲1–100で保持します。",
        [10] = "F6設定と詳細/テキスト結果を追加し、Pal Insight連携と17言語に対応しました。Nexus ModsとCurseForge向けにSteam/Win64版とWinGDK版を個別提供しました。",
        [11] = "処理の分割、移動要求の直列化、宛先の再確認により、収納時の停止と待ち時間を短縮しました。",
        [12] = "小型孵化器設定が収納処理に反映されない問題と、未受取の孵化済みパルの判定を修正しました。",
        [13] = "現在の拠点でバッグ内の一致するアイテムを個人収納へ移すF5 Quick Stackを初公開しました。既存スタックを優先し、その後フィルター対応収納を使います。",
        [14] = "パルの卵を含むバッグのTab → R除外と、卵の孵化器優先ルートを追加しました。ギルドチェストは自動収納先にしません。",
        [15] = "収納済み、除外、容量不足を示すネイティブ風の進行通知と結果カードを追加し、17言語に対応しました。",
        [16] = "単体用ショートカット設定と、Pal Insight 1.8.0以降からの任意編集を追加しました。Pal Insightは必須ではありません。",
        [17] = "収納スキャンを上限付きの段階に分割し、宛先要求を直列化して1フレームの停止を軽減しました。各移動前に宛先を再検証します。",
    },
    ko = {
        title = "버전 업데이트", selectVersion = "버전 선택", added = "추가", changed = "변경", performance = "성능", fixed = "수정",
        [1] = "각각 설정할 수 있는 4개 범주의 자동 판매를 추가했습니다: 고가 매입품 9종, 탄약 32종, 팰 스피어 10종, 낚시 미끼 4종. 각 범주는 기본적으로 꺼져 있습니다.",
        [2] = "모든 판매 범주에 아이콘 보관 목록을 추가했습니다. 체크한 아이템은 판매되지 않으며 이름은 17개 언어를 지원합니다. 선택 창은 마우스, 키보드, 컨트롤러 입력을 지원합니다.",
        [3] = "자동 판매는 Quick Stack 보관 전에 실행됩니다. 가방 Tab → R 제외 아이템은 항상 보호되며 판매 결과에는 선택한 결과 표시 방식이 사용됩니다.",
        [4] = "설정 헤더의 버전 번호를 선택해 열 수 있는 현지화된 버전 기록을 추가했습니다.",
        [5] = "현재 길드 거점에서 접근 가능한 길드 상자 보관을 권한과 용량 확인과 함께 추가했습니다. 기본적으로 꺼져 있습니다.",
        [6] = "대형 부화기를 우선하고 사용 중이거나 미수령 팰이 있는 부화기를 건너뛰는 소형 부화기 경로를 추가했습니다. 기본적으로 꺼져 있습니다.",
        [7] = "보관함이나 부화기 상태를 잠시 읽을 수 없으면 제한된 횟수만 다시 읽고 확인할 수 없는 대상은 건너뜁니다.",
        [8] = "현재 거점의 F5 빠른 보관과 제외 아이템 및 새 아이템 종류 규칙을 추가했습니다.",
        [9] = "팰 알의 부화기 경로와 유물의 고대 유물 재활용기 경로를 추가했습니다. 각 재활용기는 세계수 성수를 기본 10개, 1–100 범위로 보관합니다.",
        [10] = "F6 설정과 상세/텍스트 결과를 추가하고 Pal Insight 연동 및 17개 언어를 지원합니다. Nexus Mods와 CurseForge에 Steam/Win64 및 WinGDK 패키지를 별도로 제공했습니다.",
        [11] = "작업 분할, 이동 요청 직렬화, 대상 재확인으로 보관 멈춤과 대기 시간을 줄였습니다.",
        [12] = "소형 부화기 설정이 보관 작업에 적용되지 않던 문제와 미수령 부화 팰 감지를 수정했습니다.",
        [13] = "현재 거점의 가방에서 일치하는 아이템을 개인 보관함으로 옮기는 F5 Quick Stack을 처음 선보였습니다. 기존 스택을 우선한 뒤 필터 호환 보관함을 사용합니다.",
        [14] = "팰 알을 포함한 가방 Tab → R 제외와 알의 부화기 우선 경로를 추가했습니다. 길드 상자는 자동 보관 대상이 아닙니다.",
        [15] = "보관됨, 제외됨, 용량 부족 아이템을 보여 주는 기본 스타일 진행 메시지와 결과 카드를 추가하고 17개 언어를 지원했습니다.",
        [16] = "독립 실행형 단축키 설정과 Pal Insight 1.8.0 이상에서의 선택적 단축키 편집을 추가했습니다. Pal Insight는 필수가 아닙니다.",
        [17] = "보관함 스캔을 제한된 단계로 나누고 대상 이동 요청을 직렬화해 단일 프레임 멈춤을 줄였으며, 이동 전마다 대상을 다시 확인했습니다.",
    },
}

local COMPACT = {
    de = { [5] = "Optionale Gildentruhe im aktuellen Gildenstützpunkt mit Berechtigungs- und Kapazitätsprüfung. Standardmäßig deaktiviert.", [6] = "Optionale kleine Brutkästen nach großen; belegte Kästen und nicht abgeholte Pals werden übersprungen. Standardmäßig deaktiviert.", [7] = "Unlesbare Lager- und Brutkastenzustände werden begrenzt erneut gelesen, sonst wird das Ziel übersprungen.", [8] = "F5-Schnellverstauen im aktuellen Stützpunkt mit Regeln für ausgeschlossene und neue Gegenstandsarten.", [9] = "Eigene Routen für Pal-Eier zu Brutkästen und Relikte zu Relikt-Recyclern. Jeder Recycler behält standardmäßig 10 Weihwasser, einstellbar von 1 bis 100.", [10] = "F6-Einstellungen und Detail- oder Textergebnisse mit Pal Insight und 17 Sprachen. Separate Steam/Win64- und WinGDK-Pakete für Nexus Mods und CurseForge.", [11] = "Weniger Ruckeln durch begrenzte Arbeit, serielle Verschiebungen und erneute Zielprüfung." },
    fr = { [5] = "Coffre de guilde facultatif dans la base de guilde actuelle, avec contrôles des droits et de la capacité. Désactivé par défaut.", [6] = "Petits incubateurs facultatifs après les grands ; les incubateurs occupés et les Pals non récupérés sont ignorés. Désactivé par défaut.", [7] = "Les états illisibles sont relus de façon limitée, sinon la cible est ignorée.", [8] = "Rangement rapide F5 dans la base actuelle, avec règles pour objets exclus et nouveaux types.", [9] = "Routes dédiées des Œufs vers les incubateurs et des Reliques vers les recycleurs. Chaque recycleur conserve 10 Eaux sacrées par défaut, réglables de 1 à 100.", [10] = "Paramètres F6 et résultats détaillés ou texte, avec Pal Insight et 17 langues. Paquets Steam/Win64 et WinGDK séparés pour Nexus Mods et CurseForge.", [11] = "Moins de saccades grâce au travail borné, aux déplacements sérialisés et à la revalidation." },
    it = { [5] = "Cassa di Gilda opzionale nella base della gilda attuale, con controlli di permesso e capacità. Disattivata per impostazione predefinita.", [6] = "Incubatrici piccole opzionali dopo quelle grandi; quelle occupate e i Pal non riscossi vengono saltati. Disattivate per impostazione predefinita.", [7] = "Gli stati illeggibili vengono riletti in modo limitato, poi il bersaglio viene saltato.", [8] = "Deposito rapido F5 nella base attuale con regole per oggetti esclusi e tipi nuovi.", [9] = "Percorsi dedicati per Uova alle incubatrici e Reliquie ai riciclatori. Ogni riciclatore conserva 10 Acque Sacre per impostazione predefinita, regolabili da 1 a 100.", [10] = "Impostazioni F6 e risultati dettagliati o testuali, con Pal Insight e 17 lingue. Pacchetti Steam/Win64 e WinGDK separati per Nexus Mods e CurseForge.", [11] = "Meno scatti con lavoro limitato, spostamenti serializzati e nuova verifica della destinazione." },
    es = { [5] = "Cofre de Gremio opcional en la base actual del gremio, con comprobación de permisos y capacidad. Desactivado de forma predeterminada.", [6] = "Incubadoras pequeñas opcionales después de las grandes; se omiten las ocupadas y los Pals sin recoger. Desactivadas de forma predeterminada.", [7] = "Los estados ilegibles se vuelven a leer de forma limitada; si no, se omite el destino.", [8] = "Guardado rápido F5 en la base actual, con reglas para objetos excluidos y tipos nuevos.", [9] = "Rutas dedicadas de Huevos a incubadoras y de Reliquias a recicladores. Cada reciclador conserva 10 Aguas sagradas de forma predeterminada, ajustables de 1 a 100.", [10] = "Ajustes F6 y resultados detallados o de texto, con Pal Insight y 17 idiomas. Paquetes Steam/Win64 y WinGDK separados para Nexus Mods y CurseForge.", [11] = "Menos tirones con trabajo limitado, movimientos en serie y revalidación del destino." },
    ["pt-br"] = { [5] = "Baú de Guilda opcional na base atual da guilda, com verificação de permissão e capacidade. Desativado por padrão.", [6] = "Incubadoras pequenas opcionais após as grandes; incubadoras ocupadas e Pals não coletados são ignorados. Desativadas por padrão.", [7] = "Estados ilegíveis são relidos de forma limitada; se não, o destino é ignorado.", [8] = "Armazenamento rápido F5 na base atual, com regras para itens excluídos e tipos novos.", [9] = "Rotas de Ovos para incubadoras e de Relíquias para recicladores. Cada reciclador mantém 10 Águas Sagradas por padrão, ajustáveis de 1 a 100.", [10] = "Configurações F6 e resultados detalhados ou em texto, com Pal Insight e 17 idiomas. Pacotes Steam/Win64 e WinGDK separados para Nexus Mods e CurseForge.", [11] = "Menos travamentos com trabalho limitado, movimentos em série e revalidação do destino." },
    ru = { [5] = "Необязательный сундук гильдии на текущей базе гильдии с проверкой прав и вместимости. По умолчанию отключён.", [6] = "Необязательные малые инкубаторы после больших; занятые и с не забранными Палами пропускаются. По умолчанию отключены.", [7] = "Недоступные состояния перечитываются ограниченно; иначе цель пропускается.", [8] = "Быстрое складирование F5 на текущей базе с правилами для исключённых и новых типов.", [9] = "Отдельные маршруты яиц в инкубаторы и реликвий в переработчики. Каждый переработчик по умолчанию хранит 10 единиц Святой воды с настройкой от 1 до 100.", [10] = "Настройки F6 и подробные или текстовые результаты, с Pal Insight и 17 языками. Отдельные пакеты Steam/Win64 и WinGDK для Nexus Mods и CurseForge.", [11] = "Меньше задержек благодаря ограниченной обработке, последовательным перемещениям и проверке цели." },
    tr = { [5] = "Mevcut lonca üssündeki isteğe bağlı Lonca Sandığı, izin ve kapasite kontrolüyle. Varsayılan olarak kapalıdır.", [6] = "Büyüklerden sonra isteğe bağlı küçük kuluçkalar; dolu olanlar ve alınmamış Pallar atlanır. Varsayılan olarak kapalıdır.", [7] = "Okunamayan durumlar sınırlı kez yeniden okunur; doğrulanamazsa hedef atlanır.", [8] = "Mevcut üsteki çanta eşyaları için F5 hızlı depolama ve hariç/yeni tür kuralları.", [9] = "Yumurtalar için kuluçka ve Kalıntılar için geri dönüştürücü rotaları. Her geri dönüştürücü varsayılan olarak 10 Kutsal Su tutar; 1–100 arasında ayarlanabilir.", [10] = "F6 ayarları ve ayrıntılı ya da metin sonuçları; Pal Insight ve 17 dil. Nexus Mods ve CurseForge için ayrı Steam/Win64 ve WinGDK paketleri.", [11] = "Sınırlı iş, sıralı taşıma ve hedef doğrulamasıyla daha az takılma." },
    pl = { [5] = "Opcjonalna Skrzynia Gildii w bieżącej bazie gildii z kontrolą uprawnień i pojemności. Domyślnie wyłączona.", [6] = "Opcjonalne małe inkubatory po dużych; zajęte i z nieodebranymi Palami są pomijane. Domyślnie wyłączone.", [7] = "Nieczytelne stany są odczytywane ponownie ograniczoną liczbę razy, potem cel jest pomijany.", [8] = "Szybkie składowanie F5 w bieżącej bazie z regułami dla wykluczonych i nowych typów.", [9] = "Trasy Jaj do inkubatorów i Reliktów do recyklerów. Każdy recykler domyślnie zachowuje 10 Wód Świętych, z zakresem 1–100.", [10] = "Ustawienia F6 i wyniki szczegółowe lub tekstowe, z Pal Insight i 17 językami. Oddzielne pakiety Steam/Win64 i WinGDK dla Nexus Mods i CurseForge.", [11] = "Mniej przycięć dzięki ograniczonej pracy, szeregowym przeniesieniom i walidacji celu." },
    id = { [5] = "Peti Guild opsional di markas guild saat ini, dengan pemeriksaan izin dan kapasitas. Mati secara default.", [6] = "Inkubator kecil opsional setelah yang besar; yang terisi dan Pal belum diambil dilewati. Mati secara default.", [7] = "Status yang tidak terbaca dibaca ulang secara terbatas; jika tetap gagal, target dilewati.", [8] = "Penyimpanan cepat F5 di markas saat ini dengan aturan item dikecualikan dan jenis baru.", [9] = "Rute Telur ke inkubator dan Relik ke pendaur ulang. Setiap pendaur ulang menyimpan 10 Air Suci secara default, dapat diatur dari 1 hingga 100.", [10] = "Pengaturan F6 dan hasil rinci atau teks, dengan Pal Insight dan 17 bahasa. Paket Steam/Win64 dan WinGDK terpisah untuk Nexus Mods dan CurseForge.", [11] = "Lebih sedikit tersendat dengan pekerjaan terbatas, perpindahan berurutan, dan validasi target." },
    ["es-419"] = { [5] = "Cofre de Gremio opcional en la base actual del gremio, con verificación de permisos y capacidad. Viene desactivado.", [6] = "Incubadoras pequeñas opcionales después de las grandes; se omiten las ocupadas y los Pals sin recoger. Vienen desactivadas.", [7] = "Los estados ilegibles se vuelven a leer de forma limitada; si no, se omite el destino.", [8] = "Guardado rápido F5 en la base actual, con reglas para objetos excluidos y tipos nuevos.", [9] = "Rutas dedicadas de Huevos a incubadoras y de Reliquias a recicladores. Cada reciclador conserva 10 Aguas sagradas de forma predeterminada, ajustables de 1 a 100.", [10] = "Ajustes F6 y resultados detallados o de texto, con Pal Insight y 17 idiomas. Paquetes Steam/Win64 y WinGDK separados para Nexus Mods y CurseForge.", [11] = "Menos tirones con trabajo limitado, movimientos en serie y revalidación del destino." },
    th = { [5] = "เพิ่มหีบกิลด์แบบเลือกได้ในฐานกิลด์ปัจจุบัน พร้อมตรวจสิทธิ์และความจุ โดยปิดเป็นค่าเริ่มต้น", [6] = "เพิ่มตู้ฟักเล็กแบบเลือกได้หลังตู้ใหญ่ ข้ามตู้ที่มีของและ Pal ที่ยังไม่ได้รับ โดยปิดเป็นค่าเริ่มต้น", [7] = "สถานะที่อ่านไม่ได้จะถูกอ่านซ้ำแบบจำกัด หากยังไม่ได้จะข้ามเป้าหมาย", [8] = "เพิ่มการจัดเก็บด่วน F5 ในฐานปัจจุบัน พร้อมกฎของที่ยกเว้นและชนิดใหม่", [9] = "เพิ่มเส้นทางไข่ไปตู้ฟักและ Relic ไปเครื่องรีไซเคิล แต่ละเครื่องเก็บน้ำศักดิ์สิทธิ์ 10 ชิ้นเป็นค่าเริ่มต้น และตั้งได้ 1–100", [10] = "เพิ่มการตั้งค่า F6 และผลลัพธ์ละเอียดหรือข้อความ พร้อม Pal Insight และ 17 ภาษา มีแพ็ก Steam/Win64 และ WinGDK แยกสำหรับ Nexus Mods และ CurseForge", [11] = "ลดอาการกระตุกด้วยงานแบบจำกัด การย้ายทีละคำขอ และตรวจเป้าหมายซ้ำ" },
    vi = { [5] = "Thêm Rương Bang hội tùy chọn tại căn cứ bang hội hiện tại, kèm kiểm tra quyền và sức chứa. Mặc định tắt.", [6] = "Thêm máy ấp nhỏ tùy chọn sau máy lớn; bỏ qua máy đang chứa đồ và Pal chưa nhận. Mặc định tắt.", [7] = "Trạng thái không đọc được sẽ được đọc lại có giới hạn; nếu vẫn lỗi thì bỏ qua đích.", [8] = "Thêm cất nhanh F5 tại căn cứ hiện tại với quy tắc vật phẩm loại trừ và loại mới.", [9] = "Thêm tuyến Trứng đến máy ấp và Di vật đến máy tái chế. Mỗi máy giữ 10 Nước Thánh theo mặc định, có thể chỉnh từ 1 đến 100.", [10] = "Thêm cài đặt F6 và kết quả chi tiết hoặc văn bản, với Pal Insight và 17 ngôn ngữ. Có gói Steam/Win64 và WinGDK riêng cho Nexus Mods và CurseForge.", [11] = "Giảm giật bằng công việc có giới hạn, yêu cầu di chuyển tuần tự và xác thực lại đích." },
}

local COMPACT_120 = {
    de = {
        "Automatischer Verkauf für vier unabhängig konfigurierbare Kategorien: 9 teure Händlerwaren, 32 Munitionstypen, 10 Pal-Sphären und 4 Angelköder. Jede Kategorie ist standardmäßig deaktiviert.",
        "Symbolgestützte Behaltelisten für jede Verkaufskategorie wurden hinzugefügt. Markierte Gegenstände werden nicht verkauft, und die Namen folgen allen 17 unterstützten Spielsprachen. Die Auswahl unterstützt Maus, Tastatur und Controller.",
        "Der automatische Verkauf läuft vor dem Quick-Stack-Verstauen. Über Inventar Tab → R ausgeschlossene Gegenstände sind immer geschützt, und Verkäufe verwenden den gewählten Ergebnismodus.",
        "Ein lokalisierter Versionsverlauf wurde hinzugefügt, der über die Versionsnummer in der Kopfzeile der Einstellungen geöffnet wird.",
    },
    fr = {
        "Ajout de la vente automatique pour quatre catégories configurables séparément : 9 objets de grande valeur marchande, 32 types de munitions, 10 Sphères de Pal et 4 appâts de pêche. Chaque catégorie est désactivée par défaut.",
        "Ajout de listes illustrées d’objets à conserver pour chaque catégorie. Les objets cochés ne sont pas vendus et leurs noms suivent les 17 langues prises en charge. Les sélecteurs acceptent la souris, le clavier et la manette.",
        "La vente automatique s’exécute avant le rangement Quick Stack. Les objets exclus via Inventaire Tab → R sont toujours protégés et les ventes utilisent le mode d’affichage des résultats choisi.",
        "Ajout d’un historique des versions localisé, accessible via le numéro de version dans l’en-tête des paramètres.",
    },
    it = {
        "Aggiunta la vendita automatica per quattro categorie configurabili separatamente: 9 oggetti acquistati a caro prezzo, 32 tipi di munizioni, 10 Sfere Pal e 4 esche da pesca. Ogni categoria è disattivata per impostazione predefinita.",
        "Aggiunte liste con icone degli oggetti da conservare per ogni categoria. Gli oggetti selezionati non vengono venduti e i nomi seguono tutte le 17 lingue supportate. I selettori supportano mouse, tastiera e controller.",
        "La vendita automatica viene eseguita prima del deposito Quick Stack. Gli oggetti esclusi tramite Inventario Tab → R sono sempre protetti e le vendite usano la modalità di visualizzazione dei risultati scelta.",
        "Aggiunta una cronologia delle versioni localizzata, accessibile selezionando il numero di versione nell’intestazione delle impostazioni.",
    },
    es = {
        "Se añadió la venta automática para cuatro categorías configurables por separado: 9 objetos que los comerciantes compran a precio alto, 32 tipos de munición, 10 Esferas Pal y 4 cebos de pesca. Cada categoría está desactivada de forma predeterminada.",
        "Se añadieron listas con iconos de objetos que conservar para cada categoría. Los objetos marcados no se venden y sus nombres siguen los 17 idiomas compatibles. Los selectores admiten ratón, teclado y mando.",
        "La venta automática se ejecuta antes del guardado de Quick Stack. Los objetos excluidos mediante Inventario Tab → R siempre están protegidos y las ventas usan el modo de visualización de resultados elegido.",
        "Se añadió un historial de versiones localizado, accesible desde el número de versión del encabezado de ajustes.",
    },
    ["pt-br"] = {
        "Foi adicionada a venda automática para quatro categorias configuráveis separadamente: 9 itens comprados por preço alto, 32 tipos de munição, 10 Esferas de Pal e 4 iscas de pesca. Cada categoria vem desativada por padrão.",
        "Foram adicionadas listas com ícones de itens a manter para cada categoria. Itens marcados não são vendidos e os nomes seguem todos os 17 idiomas disponíveis. Os seletores aceitam mouse, teclado e controle.",
        "A venda automática ocorre antes do armazenamento do Quick Stack. Itens excluídos pelo Inventário Tab → R estão sempre protegidos, e as vendas usam o modo de exibição de resultados escolhido.",
        "Foi adicionado um histórico de versões localizado, acessível pelo número da versão no cabeçalho das configurações.",
    },
    ru = {
        "Добавлена автопродажа для четырёх независимо настраиваемых категорий: 9 дорогих товаров для торговцев, 32 типов боеприпасов, 10 Пал-сфер и 4 рыболовных наживок. Каждая категория по умолчанию отключена.",
        "Для каждой категории добавлены списки сохраняемых предметов с иконками. Отмеченные предметы не продаются, а названия доступны на всех 17 поддерживаемых языках. Выбор поддерживает мышь, клавиатуру и геймпад.",
        "Автопродажа выполняется до складирования Quick Stack. Предметы, исключённые через Инвентарь Tab → R, всегда защищены, а продажи используют выбранный режим показа результатов.",
        "Добавлена локализованная история версий, открываемая нажатием номера версии в заголовке настроек.",
    },
    tr = {
        "Birbirinden bağımsız ayarlanabilen dört kategori için otomatik satış eklendi: tüccarların yüksek fiyata aldığı 9 eşya, 32 mühimmat türü, 10 Pal Küresi ve 4 balık yemi. Her kategori varsayılan olarak kapalıdır.",
        "Her satış kategorisine simgeli koruma listeleri eklendi. İşaretlenen eşyalar satılmaz ve adlar desteklenen 17 oyun dilinin tümünü izler. Seçiciler fare, klavye ve kontrolcü girişini destekler.",
        "Otomatik satış, Quick Stack depolamasından önce çalışır. Envanter Tab → R ile hariç tutulan eşyalar her zaman korunur ve satışlarda seçilen sonuç görüntüleme modu kullanılır.",
        "Ayarlar başlığındaki sürüm numarası seçilerek açılan yerelleştirilmiş sürüm geçmişi eklendi.",
    },
    pl = {
        "Dodano automatyczną sprzedaż dla czterech niezależnie konfigurowanych kategorii: 9 drogich przedmiotów kupieckich, 32 rodzajów amunicji, 10 Sfer Pala i 4 przynęt wędkarskich. Każda kategoria jest domyślnie wyłączona.",
        "Dodano listy zachowywanych przedmiotów z ikonami dla każdej kategorii. Zaznaczone przedmioty nie są sprzedawane, a nazwy obsługują wszystkie 17 języków gry. Selektory obsługują mysz, klawiaturę i kontroler.",
        "Automatyczna sprzedaż działa przed składowaniem Quick Stack. Przedmioty wykluczone przez Ekwipunek Tab → R są zawsze chronione, a sprzedaż używa wybranego trybu wyświetlania wyników.",
        "Dodano zlokalizowaną historię wersji, otwieraną przez wybranie numeru wersji w nagłówku ustawień.",
    },
    id = {
        "Penjualan otomatis ditambahkan untuk empat kategori yang dapat diatur secara terpisah: 9 barang mahal bagi pedagang, 32 jenis amunisi, 10 Pal Sphere, dan 4 umpan pancing. Setiap kategori mati secara default.",
        "Daftar simpan berikon ditambahkan untuk setiap kategori. Item yang dicentang tidak dijual dan namanya tersedia dalam seluruh 17 bahasa yang didukung. Pemilih mendukung mouse, keyboard, dan controller.",
        "Penjualan otomatis berjalan sebelum penyimpanan Quick Stack. Item yang dikecualikan melalui Inventaris Tab → R selalu dilindungi, dan penjualan memakai mode tampilan hasil yang dipilih.",
        "Riwayat versi yang dilokalkan ditambahkan dan dapat dibuka melalui nomor versi di header pengaturan.",
    },
    ["es-419"] = {
        "Se agregó la venta automática para cuatro categorías configurables por separado: 9 objetos que los comerciantes compran a precio alto, 32 tipos de munición, 10 Esferas Pal y 4 cebos de pesca. Cada categoría viene desactivada.",
        "Se agregaron listas con iconos de objetos que conservar para cada categoría. Los objetos marcados no se venden y sus nombres siguen los 17 idiomas compatibles. Los selectores admiten mouse, teclado y control.",
        "La venta automática se ejecuta antes del guardado de Quick Stack. Los objetos excluidos mediante Inventario Tab → R siempre están protegidos y las ventas usan el modo de visualización de resultados elegido.",
        "Se agregó un historial de versiones localizado, accesible desde el número de versión del encabezado de configuración.",
    },
    th = {
        "เพิ่มการขายอัตโนมัติสำหรับ 4 หมวดที่ตั้งค่าแยกกันได้: ของที่พ่อค้ารับซื้อราคาสูง 9 ชนิด กระสุน 32 ชนิด Pal Sphere 10 ชนิด และเหยื่อตกปลา 4 ชนิด ทุกหมวดปิดเป็นค่าเริ่มต้น",
        "เพิ่มรายการเก็บพร้อมไอคอนสำหรับทุกหมวด ของที่ทำเครื่องหมายจะไม่ถูกขาย และชื่อรองรับภาษาของเกมทั้ง 17 ภาษา หน้าต่างเลือกใช้เมาส์ คีย์บอร์ด และจอยได้",
        "การขายอัตโนมัติทำงานก่อนการจัดเก็บของ Quick Stack ของที่ยกเว้นผ่านช่องเก็บของ Tab → R จะได้รับการปกป้องเสมอ และการขายใช้โหมดแสดงผลที่เลือก",
        "เพิ่มประวัติเวอร์ชันที่แปลภาษาแล้ว โดยเปิดได้จากหมายเลขเวอร์ชันในส่วนหัวการตั้งค่า",
    },
    vi = {
        "Đã thêm bán tự động cho bốn nhóm có thể cấu hình riêng: 9 vật phẩm được thương nhân mua giá cao, 32 loại đạn, 10 Pal Sphere và 4 mồi câu. Mỗi nhóm mặc định tắt.",
        "Đã thêm danh sách giữ có biểu tượng cho từng nhóm. Vật phẩm được chọn sẽ không bị bán và tên hỗ trợ đủ 17 ngôn ngữ trò chơi. Bộ chọn hỗ trợ chuột, bàn phím và tay cầm.",
        "Bán tự động chạy trước khi Quick Stack cất đồ. Vật phẩm bị loại trừ qua Túi đồ Tab → R luôn được bảo vệ và giao dịch dùng chế độ hiển thị kết quả đã chọn.",
        "Đã thêm lịch sử phiên bản được bản địa hóa, mở bằng cách chọn số phiên bản trong tiêu đề Cài đặt.",
    },
}

local COMPACT_110_FIXED = {
    de = "Die Einstellung für kleine Brutkästen wurde bei Lagerläufen wieder angewendet und die Erkennung nicht abgeholter geschlüpfter Pals korrigiert.",
    fr = "Correction du réglage des petits incubateurs qui n’était pas appliqué au rangement et de la détection des Pals éclos non récupérés.",
    it = "Corretta l’impostazione delle incubatrici piccole che non veniva applicata al deposito e il rilevamento dei Pal schiusi non riscossi.",
    es = "Se corrigió que el ajuste de incubadoras pequeñas no se aplicara al guardado y la detección de Pals eclosionados sin recoger.",
    ["pt-br"] = "Corrigida a configuração de incubadoras pequenas que não era aplicada ao armazenamento e a detecção de Pals chocados não coletados.",
    ru = "Исправлено неприменение настройки малых инкубаторов при складировании и распознавание не забранных вылупившихся Палов.",
    tr = "Küçük kuluçka ayarının depolama işlemlerine uygulanmaması ve alınmamış yumurtadan çıkmış Palların algılanması düzeltildi.",
    pl = "Naprawiono nieużywanie ustawienia małych inkubatorów podczas składowania oraz wykrywanie nieodebranych wyklutych Pali.",
    id = "Memperbaiki pengaturan inkubator kecil yang tidak diterapkan saat penyimpanan serta deteksi Pal yang sudah menetas tetapi belum diambil.",
    ["es-419"] = "Se corrigió que el ajuste de incubadoras pequeñas no se aplicara al guardado y la detección de Pals eclosionados sin recoger.",
    th = "แก้ไขการตั้งค่าตู้ฟักเล็กที่ไม่ถูกนำไปใช้กับงานจัดเก็บ และแก้การตรวจจับ Pal ที่ฟักแล้วแต่ยังไม่ได้รับ",
    vi = "Đã sửa cài đặt máy ấp nhỏ không được áp dụng khi cất đồ và sửa việc nhận diện Pal đã nở nhưng chưa nhận.",
}

local COMPACT_BETA = {
    de = {
        "F5 Quick Stack wurde eingeführt: passende Rucksackgegenstände werden in private Lager der aktuellen Basis verschoben, zuerst in vorhandene Stapel, dann in filterkompatible Lager.",
        "Inventar-Ausschlüsse über Tab → R einschließlich Pal-Eiern und Brutkasten-Priorität wurden hinzugefügt. Gildentruhen waren nie automatische Ziele.",
        "Native Fortschrittsmeldungen und Ergebniskarten für verstaute, ausgeschlossene und bei vollem Lager verbliebene Gegenstände wurden in allen 17 Sprachen hinzugefügt.",
        "Eigenständige Tastenkonfiguration und optionale Bearbeitung über Pal Insight 1.8.0 oder neuer wurden hinzugefügt. Pal Insight blieb optional.",
    },
    fr = {
        "Lancement de F5 Quick Stack : les objets correspondants du sac sont déplacés vers les stockages privés de la base actuelle, d’abord vers les piles existantes puis vers les stockages compatibles avec les filtres.",
        "Ajout des exclusions Inventaire Tab → R, y compris pour les Œufs de Pal, et du routage prioritaire vers les incubateurs. Les Coffres de guilde n’étaient jamais des destinations automatiques.",
        "Ajout de messages de progression et de cartes de résultat natifs pour les objets rangés, exclus ou laissés faute de place, dans les 17 langues.",
        "Ajout de la configuration autonome du raccourci et de son édition facultative via Pal Insight 1.8.0 ou ultérieur. Pal Insight restait facultatif.",
    },
    it = {
        "Introdotto F5 Quick Stack: gli oggetti corrispondenti dello zaino vengono spostati nei depositi privati della base attuale, prima nelle pile esistenti e poi nei depositi compatibili con i filtri.",
        "Aggiunte le esclusioni Inventario Tab → R, incluse le Uova Pal, e la priorità alle incubatrici. Le Casse di Gilda non erano mai destinazioni automatiche.",
        "Aggiunti messaggi di avanzamento e schede dei risultati in stile nativo per oggetti depositati, esclusi o rimasti per spazio esaurito, in tutte le 17 lingue.",
        "Aggiunte la configurazione autonoma della scorciatoia e la modifica opzionale tramite Pal Insight 1.8.0 o successivo. Pal Insight restava opzionale.",
    },
    es = {
        "Se presentó F5 Quick Stack: mueve los objetos coincidentes de la mochila al almacenamiento privado de la base actual, primero a pilas existentes y después a almacenes compatibles con los filtros.",
        "Se añadieron las exclusiones Inventario Tab → R, incluidos los Huevos Pal, y la prioridad de incubadoras. Los Cofres de Gremio nunca eran destinos automáticos.",
        "Se añadieron mensajes de progreso y tarjetas de resultados de estilo nativo para objetos guardados, excluidos o sin espacio, en los 17 idiomas.",
        "Se añadieron la configuración independiente del atajo y la edición opcional mediante Pal Insight 1.8.0 o posterior. Pal Insight seguía siendo opcional.",
    },
    ["pt-br"] = {
        "O F5 Quick Stack foi lançado: itens correspondentes da mochila são movidos para armazenamentos privados da base atual, primeiro para pilhas existentes e depois para armazenamentos aceitos pelos filtros.",
        "Foram adicionadas exclusões do Inventário Tab → R, incluindo Ovos de Pal, e prioridade para incubadoras. Baús de Guilda nunca eram destinos automáticos.",
        "Foram adicionadas mensagens de progresso e cartões de resultado nativos para itens guardados, excluídos ou sem espaço, em todos os 17 idiomas.",
        "Foram adicionadas a configuração independente do atalho e a edição opcional pelo Pal Insight 1.8.0 ou posterior. Pal Insight continuava opcional.",
    },
    ru = {
        "Представлен F5 Quick Stack: подходящие предметы из рюкзака перемещаются в личные хранилища текущей базы, сначала в существующие стопки, затем в хранилища с подходящими фильтрами.",
        "Добавлены исключения Инвентаря Tab → R, включая яйца Палов, и приоритет инкубаторов. Сундуки гильдии никогда не были автоматическими целями.",
        "Добавлены нативные сообщения о ходе работы и карточки результатов для складированных, исключённых и оставшихся из-за нехватки места предметов на всех 17 языках.",
        "Добавлены автономная настройка клавиши и необязательное редактирование через Pal Insight 1.8.0 или новее. Pal Insight оставался необязательным.",
    },
    tr = {
        "F5 Quick Stack kullanıma sunuldu: çantadaki eşleşen eşyalar mevcut üsteki özel depolara, önce mevcut yığınlara sonra filtre uyumlu depolara taşınır.",
        "Pal Yumurtaları dahil Envanter Tab → R hariç tutmaları ve kuluçka önceliği eklendi. Lonca Sandıkları hiçbir zaman otomatik hedef değildi.",
        "Depolanan, hariç tutulan ve yer olmadığı için kalan eşyalar için yerel tarzda ilerleme mesajları ve sonuç kartları 17 dilde eklendi.",
        "Bağımsız kısayol ayarı ve Pal Insight 1.8.0 veya üzeriyle isteğe bağlı düzenleme eklendi. Pal Insight isteğe bağlı kaldı.",
    },
    pl = {
        "Wprowadzono F5 Quick Stack: pasujące przedmioty z plecaka są przenoszone do prywatnych magazynów bieżącej bazy, najpierw do istniejących stosów, potem do magazynów zgodnych z filtrami.",
        "Dodano wykluczenia Ekwipunek Tab → R, także dla Jaj Pala, oraz pierwszeństwo inkubatorów. Skrzynie Gildii nigdy nie były celami automatycznymi.",
        "Dodano natywne komunikaty postępu i karty wyników dla przedmiotów odłożonych, wykluczonych lub pozostawionych z braku miejsca, we wszystkich 17 językach.",
        "Dodano samodzielną konfigurację skrótu i opcjonalną edycję przez Pal Insight 1.8.0 lub nowszy. Pal Insight pozostał opcjonalny.",
    },
    id = {
        "F5 Quick Stack diperkenalkan: item ransel yang cocok dipindahkan ke penyimpanan pribadi di markas saat ini, mendahulukan tumpukan yang ada lalu penyimpanan yang sesuai filter.",
        "Pengecualian Inventaris Tab → R, termasuk Telur Pal, dan prioritas inkubator ditambahkan. Peti Guild tidak pernah menjadi tujuan otomatis.",
        "Pesan progres dan kartu hasil bergaya asli ditambahkan untuk item yang tersimpan, dikecualikan, atau tertinggal karena penuh, dalam 17 bahasa.",
        "Konfigurasi pintasan mandiri dan pengeditan opsional melalui Pal Insight 1.8.0 atau lebih baru ditambahkan. Pal Insight tetap opsional.",
    },
    ["es-419"] = {
        "Se presentó F5 Quick Stack: mueve los objetos coincidentes de la mochila al almacenamiento privado de la base actual, primero a pilas existentes y después a almacenes compatibles con los filtros.",
        "Se agregaron las exclusiones Inventario Tab → R, incluidos los Huevos Pal, y la prioridad de incubadoras. Los Cofres de Gremio nunca eran destinos automáticos.",
        "Se agregaron mensajes de progreso y tarjetas de resultados de estilo nativo para objetos guardados, excluidos o sin espacio, en los 17 idiomas.",
        "Se agregaron la configuración independiente del atajo y la edición opcional mediante Pal Insight 1.8.0 o posterior. Pal Insight seguía siendo opcional.",
    },
    th = {
        "เปิดตัว F5 Quick Stack เพื่อย้ายของในกระเป๋าที่ตรงกันไปยังคลังส่วนตัวในฐานปัจจุบัน โดยเลือกกองที่มีอยู่ก่อน แล้วจึงเลือกคลังที่ตัวกรองยอมรับ",
        "เพิ่มการยกเว้นผ่านช่องเก็บของ Tab → R รวมถึงไข่ Pal และเส้นทางที่ให้ตู้ฟักมาก่อน หีบกิลด์ไม่เคยเป็นเป้าหมายอัตโนมัติ",
        "เพิ่มข้อความความคืบหน้าและการ์ดผลลัพธ์แบบเกมสำหรับของที่เก็บแล้ว ยกเว้น หรือเหลือเพราะคลังเต็ม พร้อมรองรับ 17 ภาษา",
        "เพิ่มการตั้งค่าปุ่มลัดแบบแยกและการแก้ไขเสริมผ่าน Pal Insight 1.8.0 ขึ้นไป โดย Pal Insight ยังคงเป็นตัวเลือก",
    },
    vi = {
        "Ra mắt F5 Quick Stack: chuyển vật phẩm phù hợp trong túi vào kho riêng tại căn cứ hiện tại, ưu tiên chồng có sẵn rồi đến kho phù hợp với bộ lọc.",
        "Thêm loại trừ qua Túi đồ Tab → R, gồm cả Trứng Pal, và ưu tiên máy ấp. Rương Bang hội không bao giờ là đích tự động.",
        "Thêm thông báo tiến trình và thẻ kết quả theo phong cách gốc cho vật phẩm đã cất, bị loại trừ hoặc còn lại vì đầy kho, hỗ trợ đủ 17 ngôn ngữ.",
        "Thêm cấu hình phím tắt độc lập và chỉnh sửa tùy chọn qua Pal Insight 1.8.0 trở lên. Pal Insight vẫn là tùy chọn.",
    },
}

local COMPACT_BETA_PERFORMANCE = {
    de = "Lagerscans wurden in begrenzte Schritte geteilt und Zielanfragen serialisiert, um Einzelbild-Ruckler zu reduzieren; vor jeder Bewegung wird das Ziel erneut geprüft.",
    fr = "Les analyses de stockage ont été divisées en étapes bornées et les demandes de déplacement sérialisées pour réduire les blocages d’une image, avec revalidation avant chaque déplacement.",
    it = "Le scansioni dei depositi sono state divise in passaggi limitati e le richieste di spostamento serializzate per ridurre i blocchi di un fotogramma, con nuova verifica prima di ogni movimento.",
    es = "Los análisis de almacenamiento se dividieron en pasos limitados y las solicitudes de movimiento se serializaron para reducir bloqueos de un fotograma, revalidando el destino antes de cada movimiento.",
    ["pt-br"] = "As verificações de armazenamento foram divididas em etapas limitadas e os pedidos de movimento serializados para reduzir travamentos de um quadro, revalidando o destino antes de cada movimento.",
    ru = "Сканирование хранилищ разделено на ограниченные этапы, а запросы перемещения выполняются последовательно для уменьшения остановок кадра с повторной проверкой цели перед каждым перемещением.",
    tr = "Depolama taramaları sınırlı adımlara bölündü ve tek karelik takılmaları azaltmak için hedef istekleri sıralandı; her taşımadan önce hedef yeniden doğrulanır.",
    pl = "Skanowanie magazynów podzielono na ograniczone kroki, a żądania przeniesienia uszeregowano, aby zmniejszyć jednoramkowe przycięcia; cel jest ponownie sprawdzany przed każdym ruchem.",
    id = "Pemindaian penyimpanan dibagi menjadi langkah terbatas dan permintaan perpindahan diurutkan untuk mengurangi macet satu frame, dengan validasi ulang sebelum setiap perpindahan.",
    ["es-419"] = "Los análisis de almacenamiento se dividieron en pasos limitados y las solicitudes de movimiento se serializaron para reducir bloqueos de un cuadro, revalidando el destino antes de cada movimiento.",
    th = "แบ่งการสแกนคลังเป็นขั้นตอนที่มีขอบเขตและส่งคำขอย้ายทีละรายการเพื่อลดอาการค้างหนึ่งเฟรม พร้อมตรวจเป้าหมายซ้ำก่อนทุกการย้าย",
    vi = "Chia quét kho thành các bước có giới hạn và gửi yêu cầu di chuyển tuần tự để giảm khựng một khung hình, đồng thời xác thực lại đích trước mỗi lần chuyển.",
}

local UI = {
    de = { title = "Versionsupdates", selectVersion = "Version auswählen", added = "Neu", changed = "Geändert", performance = "Leistung", fixed = "Behoben" },
    fr = { title = "Mises à jour", selectVersion = "Choisir une version", added = "Ajouts", changed = "Modifications", performance = "Performances", fixed = "Correctifs" },
    it = { title = "Aggiornamenti", selectVersion = "Seleziona versione", added = "Aggiunte", changed = "Modifiche", performance = "Prestazioni", fixed = "Correzioni" },
    es = { title = "Actualizaciones", selectVersion = "Seleccionar versión", added = "Añadido", changed = "Cambios", performance = "Rendimiento", fixed = "Correcciones" },
    ["pt-br"] = { title = "Atualizações", selectVersion = "Selecionar versão", added = "Adicionado", changed = "Alterações", performance = "Desempenho", fixed = "Correções" },
    ru = { title = "Обновления версий", selectVersion = "Выбрать версию", added = "Добавлено", changed = "Изменено", performance = "Производительность", fixed = "Исправлено" },
    tr = { title = "Sürüm güncellemeleri", selectVersion = "Sürüm seç", added = "Eklendi", changed = "Değişiklikler", performance = "Performans", fixed = "Düzeltmeler" },
    pl = { title = "Aktualizacje wersji", selectVersion = "Wybierz wersję", added = "Dodano", changed = "Zmiany", performance = "Wydajność", fixed = "Poprawki" },
    id = { title = "Pembaruan versi", selectVersion = "Pilih versi", added = "Ditambahkan", changed = "Perubahan", performance = "Performa", fixed = "Perbaikan" },
    ["es-419"] = { title = "Actualizaciones", selectVersion = "Seleccionar versión", added = "Añadido", changed = "Cambios", performance = "Rendimiento", fixed = "Correcciones" },
    th = { title = "อัปเดตเวอร์ชัน", selectVersion = "เลือกเวอร์ชัน", added = "เพิ่ม", changed = "เปลี่ยนแปลง", performance = "ประสิทธิภาพ", fixed = "แก้ไข" },
    vi = { title = "Cập nhật phiên bản", selectVersion = "Chọn phiên bản", added = "Đã thêm", changed = "Thay đổi", performance = "Hiệu năng", fixed = "Sửa lỗi" },
}

for locale, copy in pairs(COMPACT) do
    local row = UI[locale]
    for index, value in pairs(copy) do row[index] = value end
    for index, value in ipairs(COMPACT_120[locale]) do row[index] = value end
    row[12] = COMPACT_110_FIXED[locale]
    for index, value in ipairs(COMPACT_BETA[locale]) do
        row[index + 12] = value
    end
    row[17] = COMPACT_BETA_PERFORMANCE[locale]
    TEXT[locale] = row
end

function ReleaseNotes.current(requestedLocale)
    local locale = requestedLocale or Localization.localeKey()
    return TEXT[locale] or TEXT.en
end

return ReleaseNotes
