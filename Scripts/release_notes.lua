local Localization = require("localization")

local ReleaseNotes = {}

-- Keep 1-4 single-topic, user-visible summaries per public release. dateUtc is
-- the earliest verified public timestamp across official channels; blank means
-- that no public timestamp has been verified. Repository times are not releases.
ReleaseNotes.versions = {
    { version = "1.2.0", dateUtc = "", groups = {
        { kind = "added", items = { 1, 2, 3, 4 } },
    } },
    { version = "1.1.0", dateUtc = "", groups = {
        { kind = "added", items = { 5, 6 } },
        { kind = "changed", items = { 7 } },
    } },
    { version = "1.0.0", dateUtc = "", groups = {
        { kind = "added", items = { 8, 9, 10 } },
        { kind = "performance", items = { 11 } },
    } },
}

local TEXT = {
    en = {
        title = "Version updates", selectVersion = "Select version", current = "Current", added = "Added", changed = "Changed", performance = "Performance", fixed = "Fixed",
        [1] = "Added optional automatic selling for 9 high-value items, 32 ammunition types, 10 Pal Sphere types, and 4 fishing baits. Each category is disabled by default.",
        [2] = "Added icon-assisted keep lists for every sale category. Checked items are not sold, and item names follow all 17 supported game languages.",
        [3] = "Automatic selling runs before storage, always protects items excluded through Inventory Tab → R, and reports sales through the selected result mode.",
        [4] = "Added a localized Version Updates panel beside About, with mouse, keyboard, and controller navigation.",
        [5] = "Added optional storage in an accessible Guild Chest at the current base, with permission and capacity checks.",
        [6] = "Added optional small-incubator routing after large incubators, while skipping occupied incubators and unclaimed Pals.",
        [7] = "Temporarily unavailable storage and incubator state is reread a limited number of times before the target is skipped.",
        [8] = "Added F5 quick storage for eligible backpack items in the current base, with rules for ignored and new item types.",
        [9] = "Added dedicated Incubator routing for Pal Eggs and Ancient Relic Recycler routing for Relics and World Tree Holy Water.",
        [10] = "Added F6 settings and detailed or text results, with optional Pal Insight hosting and all 17 Palworld interface languages.",
        [11] = "Reduced storage stutter and waiting time with bounded work, serialized move requests, and destination revalidation.",
    },
    ["zh-hans"] = {
        title = "版本更新", selectVersion = "选择版本", current = "当前", added = "新增", changed = "改动", performance = "性能优化", fixed = "问题修复",
        [1] = "新增自动出售物品功能，可分别出售 9 种高价品、32 种弹药、10 种帕鲁球和 4 种钓饵；各类别均默认关闭。",
        [2] = "所有出售类别均提供带图标的保留列表；勾选的物品不会出售，名称支持全部 17 种游戏语言。",
        [3] = "自动出售先于收纳执行，始终保护通过背包 Tab → R 排除的物品，并按所选结果显示方式报告出售结果。",
        [4] = "在“关于”左侧新增本地化的“版本更新”面板，支持鼠标、键盘和手柄操作。",
        [5] = "新增可选的当前据点公会箱收纳，并在使用前检查权限和容量。",
        [6] = "新增可选的小型孵化器收纳：大型孵化器优先，并跳过已有蛋或未领取帕鲁的孵化器。",
        [7] = "仓库或孵化器状态暂时不可读时，会进行有限次数的重读，仍无法确认则跳过该目标。",
        [8] = "新增当前据点内的 F5 快速收纳，并可设置是否收纳已排除物品和仓库中没有的物品种类。",
        [9] = "新增帕鲁蛋的孵化器路线，以及古代文明遗物和世界树圣水的古代遗物回收机路线。",
        [10] = "新增 F6 设置和详细或文字结果，可由 Pal Insight 托管，并支持全部 17 种帕鲁界面语言。",
        [11] = "通过分段处理、逐个发送移动请求和移动前复核目标，减少收纳卡顿和等待时间。",
    },
    ["zh-hant"] = {
        title = "版本更新", selectVersion = "選擇版本", current = "目前", added = "新增", changed = "變更", performance = "效能最佳化", fixed = "問題修正",
        [1] = "新增自動出售物品功能，可分別出售 9 種高價品、32 種彈藥、10 種帕魯球和 4 種釣餌；各類別均預設關閉。",
        [2] = "所有出售類別均提供帶圖示的保留清單；勾選的物品不會出售，名稱支援全部 17 種遊戲語言。",
        [3] = "自動出售先於收納執行，始終保護透過背包 Tab → R 排除的物品，並依所選結果顯示方式回報出售結果。",
        [4] = "在「關於」左側新增本地化的「版本更新」面板，支援滑鼠、鍵盤和控制器操作。",
        [5] = "新增可選的目前據點公會箱收納，並在使用前檢查權限和容量。",
        [6] = "新增可選的小型孵化器收納：大型孵化器優先，並略過已有蛋或未領取帕魯的孵化器。",
        [7] = "倉庫或孵化器狀態暫時無法讀取時，會進行有限次數的重讀，仍無法確認則略過該目標。",
        [8] = "新增目前據點內的 F5 快速收納，並可設定是否收納已排除物品和倉庫中沒有的物品種類。",
        [9] = "新增帕魯蛋的孵化器路線，以及古代文明遺物和世界樹聖水的古代遺物回收機路線。",
        [10] = "新增 F6 設定和詳細或文字結果，可由 Pal Insight 代管，並支援全部 17 種帕魯介面語言。",
        [11] = "透過分段處理、逐一傳送移動請求和移動前重新驗證目標，減少收納卡頓和等待時間。",
    },
    ja = {
        title = "更新履歴", selectVersion = "バージョンを選択", current = "現在", added = "追加", changed = "変更", performance = "パフォーマンス", fixed = "修正",
        [1] = "高価品9種、弾薬32種、パルスフィア10種、釣り餌4種の自動売却を追加しました。各カテゴリは初期設定でオフです。",
        [2] = "全売却カテゴリにアイコン付き保持リストを追加しました。チェックした品は売却されず、名称は17言語に対応します。",
        [3] = "自動売却は収納前に実行され、バッグのTab → R除外品を常に保護し、選択した結果表示で売却結果を通知します。",
        [4] = "Aboutの左に更新履歴パネルを追加し、マウス、キーボード、コントローラー操作に対応しました。",
        [5] = "現在の拠点で利用できるギルドチェストへの任意収納を、権限と容量の確認付きで追加しました。",
        [6] = "大型孵化器を優先し、使用中や未回収パルのいる孵化器を避ける小型孵化器ルートを追加しました。",
        [7] = "収納や孵化器の状態を一時的に読めない場合、回数を制限して再読込し、確認できなければスキップします。",
        [8] = "現在の拠点で対象アイテムを収納するF5機能と、除外品・新規品種のルールを追加しました。",
        [9] = "パルの卵は孵化器へ、遺物と世界樹の聖水は古代遺物リサイクラーへ送る専用ルートを追加しました。",
        [10] = "F6設定と詳細/テキスト結果を追加し、Pal Insight連携と17言語に対応しました。",
        [11] = "処理の分割、移動要求の直列化、宛先の再確認により、収納時の停止と待ち時間を短縮しました。",
    },
    ko = {
        title = "버전 업데이트", selectVersion = "버전 선택", current = "현재", added = "추가", changed = "변경", performance = "성능", fixed = "수정",
        [1] = "고가품 9종, 탄약 32종, 팰 스피어 10종, 낚시 미끼 4종의 자동 판매를 추가했습니다. 각 범주는 기본적으로 꺼져 있습니다.",
        [2] = "모든 판매 범주에 아이콘 보관 목록을 추가했습니다. 체크한 아이템은 판매되지 않으며 이름은 17개 언어를 지원합니다.",
        [3] = "자동 판매는 보관 전에 실행되고 가방 Tab → R 제외 아이템을 항상 보호하며 선택한 결과 표시 방식으로 판매 결과를 알립니다.",
        [4] = "정보 왼쪽에 버전 업데이트 패널을 추가하고 마우스, 키보드, 컨트롤러 조작을 지원합니다.",
        [5] = "현재 거점에서 접근 가능한 길드 상자 보관을 권한과 용량 확인과 함께 추가했습니다.",
        [6] = "대형 부화기를 우선하고 사용 중이거나 미수령 팰이 있는 부화기를 건너뛰는 소형 부화기 경로를 추가했습니다.",
        [7] = "보관함이나 부화기 상태를 잠시 읽을 수 없으면 제한된 횟수만 다시 읽고 확인할 수 없는 대상은 건너뜁니다.",
        [8] = "현재 거점의 F5 빠른 보관과 제외 아이템 및 새 아이템 종류 규칙을 추가했습니다.",
        [9] = "팰 알의 부화기 경로와 유물·세계수 성수의 고대 유물 재활용기 경로를 추가했습니다.",
        [10] = "F6 설정과 상세/텍스트 결과를 추가하고 Pal Insight 연동 및 17개 언어를 지원합니다.",
        [11] = "작업 분할, 이동 요청 직렬화, 대상 재확인으로 보관 멈춤과 대기 시간을 줄였습니다.",
    },
}

local COMPACT = {
    de = { "Optionaler Verkauf von 9 Wertgegenständen, 32 Munitionstypen, 10 Pal-Sphären und 4 Ködern; jede Kategorie ist standardmäßig aus.", "Symbolgestützte Behaltelisten für alle Verkaufskategorien; markierte Gegenstände werden nicht verkauft, Namen in 17 Sprachen.", "Der Verkauf erfolgt vor dem Verstauen, schützt immer mit Tab → R ausgeschlossene Gegenstände und meldet Ergebnisse im gewählten Modus.", "Lokalisierte Versionsupdates neben Über, bedienbar mit Maus, Tastatur und Controller.", "Optionale Gildentruhe im aktuellen Stützpunkt mit Berechtigungs- und Kapazitätsprüfung.", "Optionale kleine Brutkästen nach großen; belegte Kästen und nicht abgeholte Pals werden übersprungen.", "Unlesbare Lager- und Brutkastenzustände werden begrenzt erneut gelesen, sonst wird das Ziel übersprungen.", "F5-Schnellverstauen im aktuellen Stützpunkt mit Regeln für ausgeschlossene und neue Gegenstandsarten.", "Eigene Routen für Pal-Eier zu Brutkästen sowie Relikte und Weihwasser zu Relikt-Recyclern.", "F6-Einstellungen und Detail- oder Textergebnisse mit Pal Insight und 17 Sprachen.", "Weniger Ruckeln durch begrenzte Arbeit, serielle Verschiebungen und erneute Zielprüfung." },
    fr = { "Vente facultative de 9 objets précieux, 32 munitions, 10 Sphères de Pal et 4 appâts ; chaque catégorie est désactivée par défaut.", "Listes illustrées de conservation pour toutes les catégories ; les objets cochés ne sont pas vendus, noms en 17 langues.", "La vente précède le rangement, protège toujours les objets exclus avec Tab → R et utilise le mode de résultat choisi.", "Panneau Mises à jour localisé près d’À propos, avec souris, clavier et manette.", "Coffre de guilde facultatif dans la base actuelle, avec contrôles des droits et de la capacité.", "Petits incubateurs facultatifs après les grands ; les incubateurs occupés et Pals non récupérés sont ignorés.", "Les états illisibles sont relus de façon limitée, sinon la cible est ignorée.", "Rangement rapide F5 dans la base actuelle, avec règles pour objets exclus et nouveaux types.", "Routes dédiées des Œufs vers les incubateurs, et des Reliques et Eau sacrée vers les recycleurs.", "Paramètres F6 et résultats détaillés ou texte, avec Pal Insight et 17 langues.", "Moins de saccades grâce au travail borné, aux déplacements sérialisés et à la revalidation." },
    it = { "Vendita opzionale di 9 oggetti di valore, 32 munizioni, 10 Sfere Pal e 4 esche; ogni categoria è disattivata di default.", "Liste con icone per tutte le categorie; gli oggetti selezionati non vengono venduti, nomi in 17 lingue.", "La vendita avviene prima del deposito, protegge sempre gli oggetti esclusi con Tab → R e usa la modalità risultati scelta.", "Pannello Aggiornamenti localizzato accanto a Informazioni, con mouse, tastiera e controller.", "Cassa di Gilda opzionale nella base attuale, con controlli di permesso e capacità.", "Incubatrici piccole opzionali dopo quelle grandi; quelle occupate e i Pal non riscossi vengono saltati.", "Gli stati illeggibili vengono riletti in modo limitato, poi il bersaglio viene saltato.", "Deposito rapido F5 nella base attuale con regole per oggetti esclusi e tipi nuovi.", "Percorsi dedicati per Uova alle incubatrici e Reliquie e Acqua sacra ai riciclatori.", "Impostazioni F6 e risultati dettagliati o testuali, con Pal Insight e 17 lingue.", "Meno scatti con lavoro limitato, spostamenti serializzati e nuova verifica della destinazione." },
    es = { "Venta opcional de 9 objetos valiosos, 32 municiones, 10 Esferas Pal y 4 cebos; cada categoría está desactivada por defecto.", "Listas con iconos para todas las categorías; lo marcado no se vende, con nombres en 17 idiomas.", "La venta ocurre antes de guardar, siempre protege lo excluido con Tab → R y usa el modo de resultados elegido.", "Panel Actualizaciones localizado junto a Acerca de, con ratón, teclado y mando.", "Cofre de Gremio opcional en la base actual, con comprobación de permisos y capacidad.", "Incubadoras pequeñas opcionales después de las grandes; se omiten las ocupadas y los Pals sin recoger.", "Los estados ilegibles se vuelven a leer de forma limitada; si no, se omite el destino.", "Guardado rápido F5 en la base actual, con reglas para objetos excluidos y tipos nuevos.", "Rutas dedicadas de Huevos a incubadoras y de Reliquias y Agua sagrada a recicladores.", "Ajustes F6 y resultados detallados o de texto, con Pal Insight y 17 idiomas.", "Menos tirones con trabajo limitado, movimientos en serie y revalidación del destino." },
    ["pt-br"] = { "Venda opcional de 9 itens valiosos, 32 munições, 10 Esferas de Pal e 4 iscas; cada categoria vem desativada.", "Listas com ícones para todas as categorias; itens marcados não são vendidos, com nomes em 17 idiomas.", "A venda ocorre antes de guardar, sempre protege itens excluídos com Tab → R e usa o modo de resultado escolhido.", "Painel Atualizações localizado ao lado de Sobre, com mouse, teclado e controle.", "Baú de Guilda opcional na base atual, com verificação de permissão e capacidade.", "Incubadoras pequenas opcionais após as grandes; incubadoras ocupadas e Pals não coletados são ignorados.", "Estados ilegíveis são relidos de forma limitada; se não, o destino é ignorado.", "Armazenamento rápido F5 na base atual, com regras para itens excluídos e tipos novos.", "Rotas de Ovos para incubadoras e de Relíquias e Água Sagrada para recicladores.", "Configurações F6 e resultados detalhados ou em texto, com Pal Insight e 17 idiomas.", "Menos travamentos com trabalho limitado, movimentos em série e revalidação do destino." },
    ru = { "Необязательная продажа 9 ценностей, 32 типов боеприпасов, 10 Пал-сфер и 4 наживок; каждая категория по умолчанию выключена.", "Списки сохранения с иконками для всех категорий; отмеченное не продаётся, названия на 17 языках.", "Продажа идёт до складирования, всегда защищает исключённое через Tab → R и использует выбранный режим результатов.", "Локализованная панель обновлений рядом с «О программе», с мышью, клавиатурой и геймпадом.", "Необязательный сундук гильдии текущей базы с проверкой прав и вместимости.", "Необязательные малые инкубаторы после больших; занятые и с не забранными Палами пропускаются.", "Недоступные состояния перечитываются ограниченно; иначе цель пропускается.", "Быстрое складирование F5 на текущей базе с правилами для исключённых и новых типов.", "Маршруты яиц в инкубаторы, а Реликвий и Святой воды — в переработчики.", "Настройки F6 и подробные или текстовые результаты, с Pal Insight и 17 языками.", "Меньше задержек благодаря ограниченной обработке, последовательным перемещениям и проверке цели." },
    tr = { "9 değerli eşya, 32 mühimmat, 10 Pal Küresi ve 4 yem için isteğe bağlı satış; her kategori varsayılan kapalıdır.", "Tüm satış kategorileri için simgeli koruma listeleri; işaretlenenler satılmaz, adlar 17 dilde sunulur.", "Satış depolamadan önce yapılır, Tab → R ile hariç tutulanları daima korur ve seçilen sonuç modunu kullanır.", "Hakkında yanında fare, klavye ve kontrolcü destekli yerelleştirilmiş güncelleme paneli.", "Mevcut üsteki isteğe bağlı Lonca Sandığı, izin ve kapasite kontrolüyle.", "Büyüklerden sonra isteğe bağlı küçük kuluçkalar; dolu olanlar ve alınmamış Pallar atlanır.", "Okunamayan durumlar sınırlı kez yeniden okunur; doğrulanamazsa hedef atlanır.", "Mevcut üsteki çanta eşyaları için F5 hızlı depolama ve hariç/yeni tür kuralları.", "Yumurtalar için kuluçka, Kalıntılar ve Kutsal Su için geri dönüştürücü rotaları.", "F6 ayarları ve ayrıntılı ya da metin sonuçları; Pal Insight ve 17 dil.", "Sınırlı iş, sıralı taşıma ve hedef doğrulamasıyla daha az takılma." },
    pl = { "Opcjonalna sprzedaż 9 kosztowności, 32 rodzajów amunicji, 10 Sfer Pala i 4 przynęt; każda kategoria jest domyślnie wyłączona.", "Listy zachowania z ikonami dla wszystkich kategorii; zaznaczone przedmioty nie są sprzedawane, nazwy w 17 językach.", "Sprzedaż następuje przed składowaniem, zawsze chroni wykluczenia Tab → R i używa wybranego trybu wyników.", "Zlokalizowany panel Aktualizacje obok Informacji, obsługiwany myszą, klawiaturą i kontrolerem.", "Opcjonalna Skrzynia Gildii bieżącej bazy z kontrolą uprawnień i pojemności.", "Opcjonalne małe inkubatory po dużych; zajęte i z nieodebranymi Palami są pomijane.", "Nieczytelne stany są odczytywane ponownie ograniczoną liczbę razy, potem cel jest pomijany.", "Szybkie składowanie F5 w bieżącej bazie z regułami dla wykluczonych i nowych typów.", "Trasy Jaj do inkubatorów oraz Reliktów i Wody Świętej do recyklerów.", "Ustawienia F6 i wyniki szczegółowe lub tekstowe, z Pal Insight i 17 językami.", "Mniej przycięć dzięki ograniczonej pracy, szeregowym przeniesieniom i walidacji celu." },
    id = { "Penjualan opsional untuk 9 barang berharga, 32 amunisi, 10 Pal Sphere, dan 4 umpan; setiap kategori mati secara default.", "Daftar simpan berikon untuk semua kategori; item yang dipilih tidak dijual, dengan nama dalam 17 bahasa.", "Penjualan berjalan sebelum penyimpanan, selalu melindungi item Tab → R, dan memakai mode hasil yang dipilih.", "Panel Pembaruan lokal di sebelah Tentang, dengan mouse, keyboard, dan controller.", "Peti Guild opsional di markas saat ini, dengan pemeriksaan izin dan kapasitas.", "Inkubator kecil opsional setelah yang besar; yang terisi dan Pal belum diambil dilewati.", "Status yang tidak terbaca dibaca ulang secara terbatas; jika tetap gagal, target dilewati.", "Penyimpanan cepat F5 di markas saat ini dengan aturan item dikecualikan dan jenis baru.", "Rute Telur ke inkubator serta Relik dan Air Suci ke pendaur ulang.", "Pengaturan F6 dan hasil rinci atau teks, dengan Pal Insight dan 17 bahasa.", "Lebih sedikit tersendat dengan pekerjaan terbatas, perpindahan berurutan, dan validasi target." },
    ["es-419"] = { "Venta opcional de 9 objetos valiosos, 32 municiones, 10 Esferas Pal y 4 cebos; cada categoría viene apagada.", "Listas con iconos para todas las categorías; lo marcado no se vende, con nombres en 17 idiomas.", "La venta ocurre antes de guardar, siempre protege lo excluido con Tab → R y usa el modo de resultados elegido.", "Panel Actualizaciones localizado junto a Acerca de, con mouse, teclado y control.", "Cofre de Gremio opcional en la base actual, con verificación de permisos y capacidad.", "Incubadoras pequeñas opcionales después de las grandes; se omiten las ocupadas y los Pals sin recoger.", "Los estados ilegibles se vuelven a leer de forma limitada; si no, se omite el destino.", "Guardado rápido F5 en la base actual, con reglas para objetos excluidos y tipos nuevos.", "Rutas de Huevos a incubadoras y de Reliquias y Agua sagrada a recicladores.", "Ajustes F6 y resultados detallados o de texto, con Pal Insight y 17 idiomas.", "Menos tirones con trabajo limitado, movimientos en serie y revalidación del destino." },
    th = { "เพิ่มการขายของมีค่า 9 ชนิด กระสุน 32 ชนิด Pal Sphere 10 ชนิด และเหยื่อ 4 ชนิด โดยแต่ละหมวดปิดเป็นค่าเริ่มต้น", "ทุกรายการขายมีรายการเก็บพร้อมไอคอน ของที่เลือกจะไม่ถูกขาย และชื่อรองรับ 17 ภาษา", "การขายทำก่อนจัดเก็บ ปกป้องของที่ยกเว้นด้วย Tab → R เสมอ และใช้รูปแบบผลลัพธ์ที่เลือก", "เพิ่มแผงอัปเดตแบบแปลภาษาข้างเกี่ยวกับ รองรับเมาส์ คีย์บอร์ด และจอย", "เพิ่มหีบกิลด์แบบเลือกได้ในฐานปัจจุบัน พร้อมตรวจสิทธิ์และความจุ", "เพิ่มตู้ฟักเล็กหลังตู้ใหญ่แบบเลือกได้ ข้ามตู้ที่มีของและ Pal ที่ยังไม่ได้รับ", "สถานะที่อ่านไม่ได้จะถูกอ่านซ้ำแบบจำกัด หากยังไม่ได้จะข้ามเป้าหมาย", "เพิ่มการจัดเก็บด่วน F5 ในฐานปัจจุบัน พร้อมกฎของที่ยกเว้นและชนิดใหม่", "เพิ่มเส้นทางไข่ไปตู้ฟัก และ Relic กับน้ำศักดิ์สิทธิ์ไปเครื่องรีไซเคิล", "เพิ่มการตั้งค่า F6 และผลลัพธ์ละเอียดหรือข้อความ พร้อม Pal Insight และ 17 ภาษา", "ลดอาการกระตุกด้วยงานแบบจำกัด การย้ายทีละคำขอ และตรวจเป้าหมายซ้ำ" },
    vi = { "Thêm bán tùy chọn 9 vật phẩm giá trị, 32 loại đạn, 10 Pal Sphere và 4 mồi câu; mỗi nhóm mặc định tắt.", "Danh sách giữ có biểu tượng cho mọi nhóm bán; mục đã chọn không bị bán, tên hỗ trợ 17 ngôn ngữ.", "Bán tự động chạy trước khi cất, luôn bảo vệ mục loại trừ bằng Tab → R và dùng chế độ kết quả đã chọn.", "Thêm bảng Cập nhật đã bản địa hóa cạnh Giới thiệu, hỗ trợ chuột, bàn phím và tay cầm.", "Thêm Rương Bang hội tùy chọn tại căn cứ hiện tại, kèm kiểm tra quyền và sức chứa.", "Thêm máy ấp nhỏ tùy chọn sau máy lớn; bỏ qua máy đang chứa đồ và Pal chưa nhận.", "Trạng thái không đọc được sẽ được đọc lại có giới hạn; nếu vẫn lỗi thì bỏ qua đích.", "Thêm cất nhanh F5 tại căn cứ hiện tại với quy tắc vật phẩm loại trừ và loại mới.", "Thêm tuyến Trứng đến máy ấp, Di vật và Nước Thánh đến máy tái chế.", "Thêm cài đặt F6 và kết quả chi tiết hoặc văn bản, với Pal Insight và 17 ngôn ngữ.", "Giảm giật bằng công việc có giới hạn, yêu cầu di chuyển tuần tự và xác thực lại đích." },
}

local UI = {
    de = { title = "Versionsupdates", selectVersion = "Version auswählen", current = "Aktuell", added = "Neu", changed = "Geändert", performance = "Leistung", fixed = "Behoben" },
    fr = { title = "Mises à jour", selectVersion = "Choisir une version", current = "Actuelle", added = "Ajouts", changed = "Modifications", performance = "Performances", fixed = "Correctifs" },
    it = { title = "Aggiornamenti", selectVersion = "Seleziona versione", current = "Attuale", added = "Aggiunte", changed = "Modifiche", performance = "Prestazioni", fixed = "Correzioni" },
    es = { title = "Actualizaciones", selectVersion = "Seleccionar versión", current = "Actual", added = "Añadido", changed = "Cambios", performance = "Rendimiento", fixed = "Correcciones" },
    ["pt-br"] = { title = "Atualizações", selectVersion = "Selecionar versão", current = "Atual", added = "Adicionado", changed = "Alterações", performance = "Desempenho", fixed = "Correções" },
    ru = { title = "Обновления версий", selectVersion = "Выбрать версию", current = "Текущая", added = "Добавлено", changed = "Изменено", performance = "Производительность", fixed = "Исправлено" },
    tr = { title = "Sürüm güncellemeleri", selectVersion = "Sürüm seç", current = "Güncel", added = "Eklendi", changed = "Değişiklikler", performance = "Performans", fixed = "Düzeltmeler" },
    pl = { title = "Aktualizacje wersji", selectVersion = "Wybierz wersję", current = "Bieżąca", added = "Dodano", changed = "Zmiany", performance = "Wydajność", fixed = "Poprawki" },
    id = { title = "Pembaruan versi", selectVersion = "Pilih versi", current = "Saat ini", added = "Ditambahkan", changed = "Perubahan", performance = "Performa", fixed = "Perbaikan" },
    ["es-419"] = { title = "Actualizaciones", selectVersion = "Seleccionar versión", current = "Actual", added = "Añadido", changed = "Cambios", performance = "Rendimiento", fixed = "Correcciones" },
    th = { title = "อัปเดตเวอร์ชัน", selectVersion = "เลือกเวอร์ชัน", current = "ปัจจุบัน", added = "เพิ่ม", changed = "เปลี่ยนแปลง", performance = "ประสิทธิภาพ", fixed = "แก้ไข" },
    vi = { title = "Cập nhật phiên bản", selectVersion = "Chọn phiên bản", current = "Hiện tại", added = "Đã thêm", changed = "Thay đổi", performance = "Hiệu năng", fixed = "Sửa lỗi" },
}

for locale, copy in pairs(COMPACT) do
    local row = UI[locale]
    for index, value in ipairs(copy) do row[index] = value end
    TEXT[locale] = row
end

function ReleaseNotes.current(requestedLocale)
    local locale = requestedLocale or Localization.localeKey()
    return TEXT[locale] or TEXT.en
end

return ReleaseNotes
