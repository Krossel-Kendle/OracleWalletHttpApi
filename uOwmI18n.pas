unit uOwmI18n;

interface

uses
  System.SysUtils;

function OwmText(const AKey, ADefault: string): string;
function OwmTextFmt(const AKey, ADefault: string; const AArgs: array of const): string;
procedure OwmSetLanguage(const ALanguageCode: string);
function OwmGetLanguage: string;

implementation

type
  TTranslationItem = record
    Key: string;
    Ru: string;
    En: string;
    Id: string;
  end;

const
  CDefaultLanguage = 'ru';

  CTranslations: array[0..214] of TTranslationItem = (
    (Key:'main.caption'; Ru:'Менеджер сертификатов Oracle Wallet'; En:'Oracle Wallet Certificate Manager'; Id:'Oracle Wallet Certificate Manager'),
    (Key:'main.tab.general'; Ru:'Общее'; En:'General'; Id:'Umum'),
    (Key:'main.tab.log'; Ru:'Лог'; En:'Log'; Id:'Log'),
    (Key:'main.tab.add_wallet'; Ru:'Добавить Wallet'; En:'Add Wallet'; Id:'Tambah Wallet'),
    (Key:'main.group.wallet'; Ru:'Сертификаты Wallet'; En:'Wallet Certificates'; Id:'Sertifikat Wallet'),
    (Key:'main.group.summary'; Ru:'Сводка'; En:'Summary'; Id:'Ringkasan'),
    (Key:'main.group.details'; Ru:'Выбранный сертификат'; En:'Selected Certificate'; Id:'Sertifikat Terpilih'),
    (Key:'main.label.total'; Ru:'Установлено сертификатов:'; En:'Installed certificates:'; Id:'Sertifikat terpasang:'),
    (Key:'main.label.expiring'; Ru:'Скоро истекают:'; En:'Expiring soon:'; Id:'Segera kedaluwarsa:'),
    (Key:'main.label.cn'; Ru:'CN'; En:'CN'; Id:'CN'),
    (Key:'main.label.issuer'; Ru:'Издатель'; En:'Issuer'; Id:'Penerbit'),
    (Key:'main.label.not_after'; Ru:'Срок до'; En:'NotAfter'; Id:'Berlaku sampai'),
    (Key:'main.label.thumbprint'; Ru:'Отпечаток'; En:'Thumbprint'; Id:'Sidik jari'),
    (Key:'main.label.path'; Ru:'Путь'; En:'Path'; Id:'Path'),

    (Key:'menu.app'; Ru:'Приложение'; En:'App'; Id:'Aplikasi'),
    (Key:'menu.settings'; Ru:'Настройки'; En:'Settings'; Id:'Pengaturan'),
    (Key:'menu.add_wallet'; Ru:'Добавить новый Wallet'; En:'Add New Wallet'; Id:'Tambah Wallet Baru'),
    (Key:'menu.api_reference'; Ru:'Справочник API'; En:'API Reference'; Id:'Referensi API'),
    (Key:'menu.about'; Ru:'О программе'; En:'About'; Id:'Tentang'),
    (Key:'menu.options'; Ru:'Конфигурация Wallet'; En:'Wallet Configuration'; Id:'Konfigurasi Wallet'),
    (Key:'menu.configure'; Ru:'Конфигурация'; En:'Configure'; Id:'Konfigurasi'),

    (Key:'btn.view'; Ru:'Просмотр'; En:'View'; Id:'Lihat'),
    (Key:'btn.add'; Ru:'Добавить'; En:'Add'; Id:'Tambah'),
    (Key:'btn.remove'; Ru:'Удалить'; En:'Remove'; Id:'Hapus'),
    (Key:'btn.load_folder'; Ru:'Загрузить из папки'; En:'Load From Folder'; Id:'Muat dari Folder'),
    (Key:'btn.remove_all'; Ru:'Удалить все'; En:'Remove All'; Id:'Hapus Semua'),
    (Key:'btn.save'; Ru:'Сохранить'; En:'Save'; Id:'Simpan'),
    (Key:'btn.cancel'; Ru:'Отмена'; En:'Cancel'; Id:'Batal'),
    (Key:'btn.close'; Ru:'Закрыть'; En:'Close'; Id:'Tutup'),
    (Key:'btn.browse'; Ru:'Обзор...'; En:'Browse...'; Id:'Telusuri...'),
    (Key:'btn.ellipsis'; Ru:'...'; En:'...'; Id:'...'),
    (Key:'btn.generate'; Ru:'Сгенерировать'; En:'Generate'; Id:'Buat'),

    (Key:'status.ready'; Ru:'Готово'; En:'Ready'; Id:'Siap'),
    (Key:'status.tools'; Ru:'Инструменты:'; En:'Tools:'; Id:'Tools:'),
    (Key:'status.wallet_tool_ok'; Ru:'wallet tool: найден'; En:'wallet tool: OK'; Id:'wallet tool: OK'),
    (Key:'status.wallet_tool_missing'; Ru:'wallet tool: не найден'; En:'wallet tool: MISSING'; Id:'wallet tool: TIDAK ADA'),
    (Key:'status.sqlplus_ok'; Ru:'sqlplus: найден'; En:'sqlplus: OK'; Id:'sqlplus: OK'),
    (Key:'status.sqlplus_missing'; Ru:'sqlplus: не найден'; En:'sqlplus: MISSING'; Id:'sqlplus: TIDAK ADA'),
    (Key:'status.server'; Ru:'Сервер:'; En:'Server:'; Id:'Server:'),
    (Key:'status.server_running'; Ru:'ЗАПУЩЕН'; En:'RUNNING'; Id:'AKTIF'),
    (Key:'status.server_stopped'; Ru:'ОСТАНОВЛЕН'; En:'STOPPED'; Id:'BERHENTI'),
    (Key:'status.enhanced_api'; Ru:'Enhanced api:'; En:'Enhanced api:'; Id:'Enhanced api:'),
    (Key:'status.on'; Ru:'вкл'; En:'on'; Id:'on'),
    (Key:'status.off'; Ru:'выкл'; En:'off'; Id:'off'),

    (Key:'filefilter.certificates'; Ru:'Сертификаты'; En:'Certificates'; Id:'Sertifikat'),
    (Key:'filefilter.tnsnames'; Ru:'Файл TNS names'; En:'TNS names file'; Id:'File TNS names'),
    (Key:'filefilter.oracle_files'; Ru:'Файлы Oracle'; En:'Oracle files'; Id:'File Oracle'),
    (Key:'filefilter.all_files'; Ru:'Все файлы'; En:'All files'; Id:'Semua file'),

    (Key:'msg.api_start_failed'; Ru:'Не удалось запустить API: %s'; En:'API start failed: %s'; Id:'Gagal menjalankan API: %s'),
    (Key:'msg.orapki_disabled'; Ru:'orapki.exe не найден. Операции с wallet отключены.'; En:'orapki.exe not found. Wallet actions are disabled.'; Id:'orapki.exe tidak ditemukan. Operasi wallet dinonaktifkan.'),
    (Key:'msg.wallet_not_configured'; Ru:'Путь к wallet не настроен.'; En:'Wallet path is not configured.'; Id:'Path wallet belum dikonfigurasi.'),
    (Key:'msg.wallet_read_error'; Ru:'Ошибка чтения wallet: %s'; En:'Wallet read error: %s'; Id:'Kesalahan baca wallet: %s'),
    (Key:'msg.loaded_certs'; Ru:'Загружено сертификатов: %d'; En:'Loaded %d certificate(s).'; Id:'Memuat %d sertifikat.'),
    (Key:'msg.settings_updated'; Ru:'Настройки обновлены.'; En:'Settings updated.'; Id:'Pengaturan diperbarui.'),
    (Key:'msg.wallet_config_saved'; Ru:'Конфигурация wallet сохранена.'; En:'Wallet configuration saved.'; Id:'Konfigurasi wallet disimpan.'),
    (Key:'msg.wallet_create_failed'; Ru:'Не удалось создать wallet: %s'; En:'Failed to create wallet: %s'; Id:'Gagal membuat wallet: %s'),
    (Key:'msg.wallet_created_switched'; Ru:'Новый wallet создан и активирован: %s'; En:'New wallet created and activated: %s'; Id:'Wallet baru dibuat dan diaktifkan: %s'),
    (Key:'msg.add_failed'; Ru:'Не удалось добавить сертификат: %s'; En:'Failed to add certificate: %s'; Id:'Gagal menambah sertifikat: %s'),
    (Key:'msg.remove_failed'; Ru:'Не удалось удалить сертификат: %s'; En:'Failed to remove certificate: %s'; Id:'Gagal menghapus sertifikat: %s'),
    (Key:'msg.confirm_remove_selected'; Ru:'Удалить выбранный сертификат?'; En:'Remove selected certificate?'; Id:'Hapus sertifikat terpilih?'),
    (Key:'msg.select_cert_folder'; Ru:'Выберите папку с сертификатами'; En:'Select folder with certificates'; Id:'Pilih folder sertifikat'),
    (Key:'msg.folder_import_result'; Ru:'Добавлено: %d, пропущено: %d, ошибок: %d'; En:'Added: %d, skipped: %d, failed: %d'; Id:'Ditambahkan: %d, dilewati: %d, gagal: %d'),
    (Key:'msg.confirm_remove_all'; Ru:'Удалить ВСЕ сертификаты из wallet?'; En:'Remove ALL certificates from wallet?'; Id:'Hapus SEMUA sertifikat dari wallet?'),
    (Key:'msg.remove_all_result'; Ru:'Удалено: %d, ошибок: %d'; En:'Removed: %d, errors: %d'; Id:'Dihapus: %d, error: %d'),

    (Key:'log.orapki_found'; Ru:'orapki найден: %s'; En:'orapki found: %s'; Id:'orapki ditemukan: %s'),
    (Key:'log.orapki_not_found'; Ru:'orapki не найден'; En:'orapki not found'; Id:'orapki tidak ditemukan'),
    (Key:'log.sqlplus_found'; Ru:'sqlplus найден: %s'; En:'sqlplus found: %s'; Id:'sqlplus ditemukan: %s'),
    (Key:'log.sqlplus_not_found'; Ru:'sqlplus не найден'; En:'sqlplus not found'; Id:'sqlplus tidak ditemukan'),
    (Key:'log.folder_import_warn'; Ru:'Импорт папки завершён с предупреждениями: %s'; En:'Folder import warnings: %s'; Id:'Peringatan impor folder: %s'),
    (Key:'log.remove_all_warn'; Ru:'Удаление всех завершилось с предупреждениями: %s'; En:'Remove all finished with warnings: %s'; Id:'Hapus semua selesai dengan peringatan: %s'),

    (Key:'settings.caption'; Ru:'Настройки'; En:'Settings'; Id:'Pengaturan'),
    (Key:'settings.group.language'; Ru:'Язык'; En:'Language'; Id:'Bahasa'),
    (Key:'settings.label.ui_language'; Ru:'Язык интерфейса'; En:'UI language'; Id:'Bahasa UI'),
    (Key:'settings.group.api'; Ru:'API'; En:'API'; Id:'API'),
    (Key:'settings.enable_api'; Ru:'Включить API'; En:'Enable API'; Id:'Aktifkan API'),
    (Key:'settings.auth_type'; Ru:'Тип авторизации'; En:'Auth type'; Id:'Tipe autentikasi'),
    (Key:'settings.auth.header'; Ru:'Header'; En:'Header'; Id:'Header'),
    (Key:'settings.auth.basic'; Ru:'Basic'; En:'Basic'; Id:'Basic'),
    (Key:'settings.api_key'; Ru:'X-API-Key'; En:'X-API-Key'; Id:'X-API-Key'),
    (Key:'settings.basic_login'; Ru:'Basic логин'; En:'Basic login'; Id:'Login Basic'),
    (Key:'settings.basic_password'; Ru:'Basic пароль'; En:'Basic password'; Id:'Password Basic'),
    (Key:'settings.api_port'; Ru:'Порт API'; En:'API port'; Id:'Port API'),
    (Key:'settings.allowed_hosts'; Ru:'Разрешённые хосты'; En:'Allowed hosts'; Id:'Host diizinkan'),
    (Key:'settings.hosts.all'; Ru:'Все'; En:'All'; Id:'Semua'),
    (Key:'settings.hosts.list'; Ru:'Список'; En:'List'; Id:'Daftar'),
    (Key:'settings.ips_hint'; Ru:'# один IP в строке'; En:'# one IP per line'; Id:'# satu IP per baris'),
    (Key:'settings.enhanced'; Ru:'Enhanced API (ACL через SQL*Plus)'; En:'Enhanced API (ACL via SQL*Plus)'; Id:'Enhanced API (ACL via SQL*Plus)'),
    (Key:'settings.pdb_name'; Ru:'PDB (из TNS)'; En:'PDB (from TNS)'; Id:'PDB (dari TNS)'),
    (Key:'settings.acl_user'; Ru:'ACL admin user'; En:'ACL admin user'; Id:'User admin ACL'),
    (Key:'settings.acl_password'; Ru:'ACL пароль'; En:'ACL password'; Id:'Password ACL'),
    (Key:'settings.tns'; Ru:'Файл TNS'; En:'TNS file'; Id:'File TNS'),
    (Key:'settings.tns_hint'; Ru:'Укажите путь к tnsnames.ora. Кнопка "..." открывает выбор файла. Список PDB загружается из этого файла.'; En:'Set path to tnsnames.ora. Use "..." button to choose file. PDB list is loaded from this file.'; Id:'Tentukan path ke tnsnames.ora. Gunakan tombol "..." untuk memilih file. Daftar PDB dimuat dari file ini.'),
    (Key:'settings.tns_dialog_title'; Ru:'Выбор tnsnames.ora'; En:'Select tnsnames.ora'; Id:'Pilih tnsnames.ora'),
    (Key:'settings.validation.port'; Ru:'Порт API должен быть в диапазоне 1..65535'; En:'API port must be in range 1..65535'; Id:'Port API harus dalam rentang 1..65535'),
    (Key:'settings.validation.api_key'; Ru:'Для Header auth требуется API key'; En:'API key is required for Header auth'; Id:'API key wajib untuk Header auth'),
    (Key:'settings.validation.basic'; Ru:'Для Basic auth нужны логин и пароль'; En:'Basic login and password are required for Basic auth'; Id:'Login dan password wajib untuk Basic auth'),
    (Key:'settings.validation.pdb'; Ru:'При включенном Enhanced API выберите PDB из списка'; En:'Select PDB from list when Enhanced API is enabled'; Id:'Pilih PDB dari daftar saat Enhanced API aktif'),
    (Key:'settings.validation.acl_user'; Ru:'При включенном Enhanced API укажите ACL admin user'; En:'ACL admin user is required when Enhanced API is enabled'; Id:'User admin ACL wajib saat Enhanced API aktif'),
    (Key:'settings.validation.acl_password'; Ru:'При включенном Enhanced API укажите ACL пароль'; En:'ACL admin password is required when Enhanced API is enabled'; Id:'Password ACL wajib saat Enhanced API aktif'),
    (Key:'settings.validation.tns_file'; Ru:'При включенном Enhanced API укажите путь к tnsnames.ora'; En:'Path to tnsnames.ora is required when Enhanced API is enabled'; Id:'Path ke tnsnames.ora wajib saat Enhanced API aktif'),
    (Key:'settings.validation.tns_file_not_found'; Ru:'Файл TNS не найден: %s'; En:'TNS file was not found: %s'; Id:'File TNS tidak ditemukan: %s'),

    (Key:'walletcfg.caption'; Ru:'Конфигурация Wallet'; En:'Wallet Configuration'; Id:'Konfigurasi Wallet'),
    (Key:'walletcfg.group.access'; Ru:'Доступ к Wallet'; En:'Wallet Access'; Id:'Akses Wallet'),
    (Key:'walletcfg.wallet_path'; Ru:'Путь к папке Wallet'; En:'Wallet folder path'; Id:'Path folder Wallet'),
    (Key:'walletcfg.wallet_password'; Ru:'Пароль Wallet'; En:'Wallet password'; Id:'Password Wallet'),
    (Key:'walletcfg.validation.path'; Ru:'Требуется путь к Wallet'; En:'Wallet path is required'; Id:'Path Wallet wajib diisi'),
    (Key:'walletcfg.warning.orapki'; Ru:'orapki.exe не найден. Операции с Wallet отключены.'; En:'orapki.exe was not found. Wallet operations are disabled.'; Id:'orapki.exe tidak ditemukan. Operasi Wallet dinonaktifkan.'),
    (Key:'walletcfg.select_folder'; Ru:'Выберите папку Wallet'; En:'Select wallet folder'; Id:'Pilih folder Wallet'),

    (Key:'addwallet.caption'; Ru:'Создание нового Wallet (существующий: Конфигурация Wallet -> Конфигурация)'; En:'Create New Wallet (existing wallet: Wallet Configuration -> Configure)'; Id:'Buat Wallet Baru (wallet yang sudah ada: Konfigurasi Wallet -> Konfigurasi)'),
    (Key:'addwallet.group'; Ru:'Создание Wallet'; En:'Wallet Creation'; Id:'Pembuatan Wallet'),
    (Key:'addwallet.path'; Ru:'Путь к папке Wallet'; En:'Wallet folder path'; Id:'Path folder Wallet'),
    (Key:'addwallet.password'; Ru:'Пароль Wallet'; En:'Wallet password'; Id:'Password Wallet'),
    (Key:'addwallet.autologin'; Ru:'Включить auto-login (cwallet.sso)'; En:'Enable auto-login (cwallet.sso)'; Id:'Aktifkan auto-login (cwallet.sso)'),
    (Key:'addwallet.autologin_local'; Ru:'Включить локальный auto-login'; En:'Enable local auto-login only'; Id:'Aktifkan auto-login lokal saja'),
    (Key:'addwallet.create'; Ru:'Создать и переключить'; En:'Create and Switch'; Id:'Buat dan Aktifkan'),
    (Key:'addwallet.path_invalid'; Ru:'Неверный путь!'; En:'Invalid path!'; Id:'Path tidak valid!'),
    (Key:'addwallet.path_wallet_exists'; Ru:'В этой папке уже есть wallet. Создать ещё один здесь нельзя.'; En:'Wallet already exists in this folder. Cannot create another one here.'; Id:'Wallet sudah ada di folder ini. Tidak dapat membuat wallet lain di sini.'),
    (Key:'addwallet.validation.path'; Ru:'Требуется путь к Wallet'; En:'Wallet path is required'; Id:'Path Wallet wajib diisi'),
    (Key:'addwallet.validation.password'; Ru:'Требуется пароль Wallet'; En:'Wallet password is required'; Id:'Password Wallet wajib diisi'),
    (Key:'addwallet.select_folder'; Ru:'Выберите папку Wallet'; En:'Select wallet folder'; Id:'Pilih folder Wallet'),

    (Key:'about.caption'; Ru:'О программе'; En:'About'; Id:'Tentang'),
    (Key:'about.group.caption'; Ru:'Oracle Wallet Certificate Manager'; En:'Oracle Wallet Certificate Manager'; Id:'Oracle Wallet Certificate Manager'),
    (Key:'about.author'; Ru:'Автор: Vladislav Filimonov, Krossel Apps'; En:'Author: Vladislav Filimonov, Krossel Apps'; Id:'Author: Vladislav Filimonov, Krossel Apps'),
    (Key:'about.website_caption'; Ru:'Сайт:'; En:'Website:'; Id:'Website:'),
    (Key:'about.description'; Ru:'VCL-утилита для управления сертификатами Oracle Wallet: список, добавление, удаление, импорт из папки, сводка сроков истечения и опциональный локальный API.'; En:'VCL utility for Oracle Wallet certificate lifecycle: list, add, remove, folder import, summary of upcoming expirations, and optional local API for remote operations.'; Id:'Utilitas VCL untuk siklus sertifikat Oracle Wallet: daftar, tambah, hapus, impor folder, ringkasan kedaluwarsa, dan API lokal opsional untuk operasi jarak jauh.'),

    (Key:'apiref.caption'; Ru:'Справочник API'; En:'API Reference'; Id:'Referensi API'),
    (Key:'apiref.content_type_json'; Ru:'Content-Type: application/json'; En:'Content-Type: application/json'; Id:'Content-Type: application/json'),
    (Key:'apiref.jsonapi_content_type'; Ru:'Content-Type: application/vnd.api+json'; En:'Content-Type: application/vnd.api+json'; Id:'Content-Type: application/vnd.api+json'),
    (Key:'apiref.section.request'; Ru:'Пример запроса'; En:'Request example'; Id:'Contoh request'),
    (Key:'apiref.section.response'; Ru:'Пример ответа'; En:'Response example'; Id:'Contoh response'),
    (Key:'apiref.root.wallet_api'; Ru:'Oracle Wallet API'; En:'Oracle Wallet API'; Id:'Oracle Wallet API'),
    (Key:'apiref.root.enhanced_api'; Ru:'Enhanced API'; En:'Enhanced API'; Id:'Enhanced API'),
    (Key:'apiref.placeholder.endpoint'; Ru:'Выберите эндпоинт в дереве.'; En:'Select an endpoint in the tree.'; Id:'Pilih endpoint pada tree.'),
    (Key:'apiref.placeholder.description'; Ru:'Описание и примеры запроса/ответа будут показаны здесь.'; En:'Endpoint description and examples will be displayed here.'; Id:'Deskripsi endpoint dan contoh akan ditampilkan di sini.'),
    (Key:'apiref.node.openapi'; Ru:'OpenAPI документ'; En:'OpenAPI document'; Id:'Dokumen OpenAPI'),
    (Key:'apiref.node.wallet_health'; Ru:'Проверка состояния'; En:'Health check'; Id:'Pemeriksaan kesehatan'),
    (Key:'apiref.node.wallet_create'; Ru:'Создать wallet'; En:'Create wallet'; Id:'Buat wallet'),
    (Key:'apiref.node.wallet_list'; Ru:'Список сертификатов'; En:'List certificates'; Id:'Daftar sertifikat'),
    (Key:'apiref.node.wallet_expiring'; Ru:'Истекающие сертификаты'; En:'Expiring certificates'; Id:'Sertifikat segera kedaluwarsa'),
    (Key:'apiref.node.wallet_get_one'; Ru:'Получить сертификат'; En:'Get certificate'; Id:'Ambil sertifikat'),
    (Key:'apiref.node.wallet_add_by_url'; Ru:'Добавить по URL'; En:'Add certificate by URL'; Id:'Tambah dari URL'),
    (Key:'apiref.node.wallet_upload'; Ru:'Загрузка сертификата'; En:'Upload certificate'; Id:'Upload sertifikat'),
    (Key:'apiref.node.wallet_remove_all'; Ru:'Удалить все сертификаты'; En:'Remove all certificates'; Id:'Hapus semua sertifikat'),
    (Key:'apiref.node.wallet_delete'; Ru:'Удалить сертификат'; En:'Delete certificate'; Id:'Hapus sertifikat'),
    (Key:'apiref.node.acl_types'; Ru:'Типы ACL'; En:'Supported ACL types'; Id:'Tipe ACL didukung'),
    (Key:'apiref.node.acl_grant'; Ru:'Выдать ACL'; En:'Grant ACL'; Id:'Grant ACL'),
    (Key:'apiref.node.acl_list'; Ru:'Список ACL'; En:'List ACL'; Id:'Daftar ACL'),
    (Key:'apiref.node.acl_revoke'; Ru:'Отозвать ACL'; En:'Revoke ACL'; Id:'Revoke ACL'),
    (Key:'apiref.desc.wallet_health'; Ru:'Возвращает состояние API, доступность инструментов и факт настройки wallet.'; En:'Returns server/runtime status: API flags, tools availability and wallet configuration.'; Id:'Mengembalikan status server/API, ketersediaan tools, dan konfigurasi wallet.'),
    (Key:'apiref.desc.wallet_create'; Ru:'Создаёт новый wallet и при необходимости переключает активный wallet приложения (JSON:API data.attributes). Ошибки: 400 Invalid path, 409 wallet is already exists.'; En:'Creates a new wallet and can switch active wallet to it (JSON:API data.attributes). Errors: 400 Invalid path, 409 wallet is already exists.'; Id:'Membuat wallet baru dan dapat mengganti wallet aktif aplikasi (JSON:API data.attributes). Error: 400 Invalid path, 409 wallet is already exists.'),
    (Key:'apiref.desc.wallet_list'; Ru:'Возвращает список всех сертификатов wallet с базовыми метаданными.'; En:'Returns all certificates from wallet with basic metadata.'; Id:'Mengembalikan semua sertifikat wallet dengan metadata dasar.'),
    (Key:'apiref.desc.wallet_expiring'; Ru:'Возвращает сертификаты, истекающие в заданный период, отсортированные по ближайшему сроку.'; En:'Returns certificates expiring in specified period, sorted by closest expiration.'; Id:'Mengembalikan sertifikat yang kedaluwarsa pada periode tertentu, diurutkan dari yang terdekat.'),
    (Key:'apiref.desc.wallet_get_one'; Ru:'Возвращает один сертификат по thumbprint/имени/subject.'; En:'Returns one certificate by thumbprint/name/subject.'; Id:'Mengembalikan satu sertifikat berdasarkan thumbprint/nama/subjek.'),
    (Key:'apiref.desc.wallet_add_by_url'; Ru:'Скачивает сертификат по URL и добавляет его как trusted (JSON:API data.attributes.url).'; En:'Downloads certificate by URL and adds it as trusted cert (JSON:API data.attributes.url).'; Id:'Mengunduh sertifikat dari URL dan menambahkannya sebagai trusted cert (JSON:API data.attributes.url).'),
    (Key:'apiref.desc.wallet_upload'; Ru:'Добавляет сертификат из base64 payload (JSON:API data.attributes.contentBase64).'; En:'Adds certificate from base64 payload (JSON:API data.attributes.contentBase64).'; Id:'Menambahkan sertifikat dari payload base64 (JSON:API data.attributes.contentBase64).'),
    (Key:'apiref.desc.wallet_remove_all'; Ru:'Массово удаляет сертификаты из wallet. Требует JSON:API data.attributes.confirm=true.'; En:'Bulk-delete endpoint for wallet certificates. Requires JSON:API data.attributes.confirm=true.'; Id:'Endpoint hapus massal sertifikat wallet. Membutuhkan JSON:API data.attributes.confirm=true.'),
    (Key:'apiref.desc.wallet_delete'; Ru:'Удаляет сертификат из wallet по thumbprint/имени/subject.'; En:'Deletes one certificate from wallet by thumbprint/name/subject.'; Id:'Menghapus sertifikat dari wallet berdasarkan thumbprint/nama/subjek.'),
    (Key:'apiref.desc.openapi'; Ru:'Возвращает OpenAPI 3.0 JSON-документ для всех доступных эндпоинтов API.'; En:'Returns OpenAPI 3.0 JSON document for all available API endpoints.'; Id:'Mengembalikan dokumen JSON OpenAPI 3.0 untuk semua endpoint API yang tersedia.'),
    (Key:'apiref.desc.acl_types'; Ru:'Возвращает поддерживаемые значения aclType для Enhanced API.'; En:'Returns ACL type values supported by Enhanced API.'; Id:'Mengembalikan nilai aclType yang didukung oleh Enhanced API.'),
    (Key:'apiref.desc.acl_grant'; Ru:'Выдаёт ACL-привилегию для schema/host/port/type (Enhanced API, JSON:API data.attributes).'; En:'Grants ACL privilege for schema/host/port/type (Enhanced API, JSON:API data.attributes).'; Id:'Memberi privilege ACL untuk schema/host/port/type (Enhanced API, JSON:API data.attributes).'),
    (Key:'apiref.desc.acl_list'; Ru:'Возвращает список ACL для выбранной схемы и фильтра host.'; En:'Lists ACL grants for selected schema and optional host filter.'; Id:'Menampilkan grant ACL untuk schema terpilih dan filter host.'),
    (Key:'apiref.desc.acl_revoke'; Ru:'Отзывает ранее выданную ACL-привилегию (JSON:API data.attributes).'; En:'Revokes previously granted ACL privilege (JSON:API data.attributes).'; Id:'Mencabut privilege ACL yang sebelumnya diberikan (JSON:API data.attributes).'),

    (Key:'wallet.err.orapki_not_found'; Ru:'orapki.exe не найден'; En:'orapki.exe not found'; Id:'orapki.exe tidak ditemukan'),
    (Key:'wallet.err.timeout'; Ru:'Таймаут выполнения orapki'; En:'orapki timeout'; Id:'Timeout orapki'),
    (Key:'wallet.err.exit_code'; Ru:'orapki завершился с кодом %d'; En:'orapki exited with code %d'; Id:'orapki keluar dengan kode %d'),
    (Key:'wallet.err.path_empty'; Ru:'Путь к wallet пуст'; En:'Wallet path is empty'; Id:'Path wallet kosong'),
    (Key:'wallet.err.password_empty'; Ru:'Пароль wallet пуст'; En:'Wallet password is empty'; Id:'Password wallet kosong'),
    (Key:'wallet.err.invalid_path'; Ru:'Неверный путь'; En:'Invalid path'; Id:'Path tidak valid'),
    (Key:'wallet.err.already_exists'; Ru:'Wallet уже существует в папке: %s'; En:'Wallet already exists in folder: %s'; Id:'Wallet sudah ada di folder: %s'),
    (Key:'wallet.err.file_not_found'; Ru:'Файл сертификата не найден: %s'; En:'Certificate file not found: %s'; Id:'File sertifikat tidak ditemukan: %s'),
    (Key:'wallet.err.subject_empty'; Ru:'Тема сертификата пуста'; En:'Certificate subject is empty'; Id:'Subjek sertifikat kosong'),
    (Key:'wallet.err.folder_not_found'; Ru:'Папка не найдена: %s'; En:'Folder not found: %s'; Id:'Folder tidak ditemukan: %s'),
    (Key:'wallet.log.loaded'; Ru:'Сертификатов в wallet: %d'; En:'Wallet loaded: %d certificate(s)'; Id:'Wallet dimuat: %d sertifikat'),
    (Key:'wallet.log.added'; Ru:'Сертификат добавлен: %s'; En:'Certificate added: %s'; Id:'Sertifikat ditambahkan: %s'),
    (Key:'wallet.log.add_failed'; Ru:'Ошибка добавления сертификата: %s'; En:'Add certificate failed: %s'; Id:'Gagal menambah sertifikat: %s'),
    (Key:'wallet.log.created'; Ru:'Wallet создан: %s'; En:'Wallet created: %s'; Id:'Wallet dibuat: %s'),
    (Key:'wallet.log.create_failed'; Ru:'Ошибка создания wallet: %s'; En:'Create wallet failed: %s'; Id:'Gagal membuat wallet: %s'),
    (Key:'wallet.log.removed'; Ru:'Сертификат удалён: %s'; En:'Certificate removed: %s'; Id:'Sertifikat dihapus: %s'),
    (Key:'wallet.log.remove_failed'; Ru:'Ошибка удаления сертификата: %s'; En:'Remove certificate failed: %s'; Id:'Gagal menghapus sertifikat: %s'),

    (Key:'api.log.started'; Ru:'API сервер запущен на порту %d'; En:'API server started on port %d'; Id:'Server API aktif di port %d'),
    (Key:'api.log.start_failed'; Ru:'Ошибка запуска API: %s'; En:'API server start failed: %s'; Id:'Gagal start server API: %s'),
    (Key:'api.log.stopped'; Ru:'API сервер остановлен'; En:'API server stopped'; Id:'Server API dihentikan'),
    (Key:'api.err.download_failed_http'; Ru:'Ошибка загрузки. HTTP %d'; En:'Download failed. HTTP %d'; Id:'Gagal download. HTTP %d'),
    (Key:'api.err.route_not_found'; Ru:'Маршрут не найден'; En:'Route not found'; Id:'Rute tidak ditemukan'),
    (Key:'api.err.host_not_allowed'; Ru:'Хост не разрешён'; En:'Host is not allowed'; Id:'Host tidak diizinkan'),
    (Key:'api.err.auth_failed'; Ru:'Ошибка авторизации'; En:'Authentication failed'; Id:'Autentikasi gagal'),
    (Key:'api.err.cert_not_found'; Ru:'Сертификат не найден'; En:'Certificate not found'; Id:'Sertifikat tidak ditemukan'),
    (Key:'api.err.invalid_json'; Ru:'Требуется JSON body'; En:'JSON body required'; Id:'Body JSON wajib'),
    (Key:'api.err.invalid_value'; Ru:'Некорректное значение для %s'; En:'Invalid value for %s'; Id:'Nilai tidak valid untuk %s'),
    (Key:'api.err.jsonapi_data_object'; Ru:'JSON:API запрос требует объект data'; En:'JSON:API request requires data object'; Id:'Request JSON:API membutuhkan objek data'),
    (Key:'api.err.jsonapi_type_required'; Ru:'JSON:API запрос требует data.type'; En:'JSON:API request requires data.type'; Id:'Request JSON:API membutuhkan data.type'),
    (Key:'api.err.jsonapi_type_mismatch'; Ru:'JSON:API data.type должен быть %s'; En:'JSON:API data.type must be %s'; Id:'JSON:API data.type harus %s'),
    (Key:'api.err.jsonapi_attributes_required'; Ru:'JSON:API запрос требует объект data.attributes'; En:'JSON:API request requires data.attributes object'; Id:'Request JSON:API membutuhkan objek data.attributes'),
    (Key:'api.err.invalid_path'; Ru:'Invalid path'; En:'Invalid path'; Id:'Invalid path'),
    (Key:'api.err.wallet_exists'; Ru:'wallet is already exists'; En:'wallet is already exists'; Id:'wallet is already exists'),
    (Key:'api.err.url_required'; Ru:'Требуется url'; En:'url is required'; Id:'url wajib'),
    (Key:'api.err.confirm_true_required'; Ru:'Требуется confirm=true'; En:'confirm=true is required'; Id:'confirm=true wajib'),
    (Key:'api.err.upload_content_required'; Ru:'Требуется поле contentBase64'; En:'contentBase64 is required'; Id:'field contentBase64 wajib'),
    (Key:'api.err.upload_base64_invalid'; Ru:'Некорректный base64 payload'; En:'Invalid base64 payload'; Id:'Payload base64 tidak valid'),
    (Key:'api.err.sqlplus_missing'; Ru:'sqlplus.exe не найден'; En:'sqlplus.exe not found'; Id:'sqlplus.exe tidak ditemukan'),
    (Key:'api.err.sqlplus_timeout'; Ru:'Таймаут выполнения sqlplus'; En:'sqlplus execution timeout'; Id:'Timeout eksekusi sqlplus'),
    (Key:'api.err.sqlplus_exit_code'; Ru:'sqlplus завершился с кодом %d'; En:'sqlplus exited with code %d'; Id:'sqlplus keluar dengan kode %d'),
    (Key:'api.msg.cert_removed'; Ru:'Сертификат удалён'; En:'Certificate removed'; Id:'Sertifikat dihapus'),
    (Key:'api.msg.cert_added'; Ru:'Сертификат добавлен'; En:'Certificate added'; Id:'Sertifikat ditambahkan'),
    (Key:'api.msg.wallet_created'; Ru:'Новый wallet создан: %s'; En:'New wallet created: %s'; Id:'Wallet baru dibuat: %s'),
    (Key:'api.msg.wallet_created_switched'; Ru:'Новый wallet создан и активирован: %s'; En:'New wallet created and activated: %s'; Id:'Wallet baru dibuat dan diaktifkan: %s'),
    (Key:'api.msg.remove_all_done'; Ru:'Массовое удаление завершено'; En:'Remove-all completed'; Id:'Hapus massal selesai'),
    (Key:'api.msg.acl_granted'; Ru:'ACL выдан для %s (%s)'; En:'ACL granted for %s (%s)'; Id:'ACL diberikan untuk %s (%s)'),
    (Key:'api.msg.acl_revoked'; Ru:'ACL отозван для %s (%s)'; En:'ACL revoked for %s (%s)'; Id:'ACL dicabut untuk %s (%s)'),
    (Key:'api.err.upload_not_impl'; Ru:'Endpoint multipart upload пока не реализован'; En:'Multipart upload endpoint is not implemented yet'; Id:'Endpoint upload multipart belum diimplementasikan'),
    (Key:'api.err.enhanced_disabled'; Ru:'Enhanced API отключен'; En:'Enhanced API is disabled'; Id:'Enhanced API dinonaktifkan'),
    (Key:'api.err.acl_not_impl'; Ru:'ACL endpoint''ы будут добавлены на следующем этапе'; En:'ACL endpoints will be added in next iteration'; Id:'Endpoint ACL akan ditambahkan pada iterasi berikutnya'),
    (Key:'crypto.err.protect'; Ru:'Ошибка CryptProtectData. код=%d'; En:'CryptProtectData failed. code=%d'; Id:'CryptProtectData gagal. kode=%d'),
    (Key:'crypto.err.unprotect'; Ru:'Ошибка CryptUnprotectData. код=%d'; En:'CryptUnprotectData failed. code=%d'; Id:'CryptUnprotectData gagal. kode=%d'),

    (Key:'types.unknown'; Ru:'(неизвестно)'; En:'(unknown)'; Id:'(tidak diketahui)')
  );

var
  GLanguage: string = CDefaultLanguage;

function NormalizeLanguage(const AValue: string): string;
var
  L: string;
begin
  L := LowerCase(Trim(AValue));

  if (L = 'ru') or (L = 'rus') then
    Exit('ru');

  if (L = 'id') or (L = 'in') or (L = 'id-id') then
    Exit('id');

  if (L = 'en') or (L = 'en-us') or (L = 'en-gb') then
    Exit('en');

  Result := CDefaultLanguage;
end;

function FindTranslation(const AKey: string; out AItem: TTranslationItem): Boolean;
var
  I: Integer;
begin
  for I := Low(CTranslations) to High(CTranslations) do
    if SameText(CTranslations[I].Key, AKey) then
    begin
      AItem := CTranslations[I];
      Exit(True);
    end;

  Result := False;
end;

function OwmText(const AKey, ADefault: string): string;
var
  LItem: TTranslationItem;
  LLang: string;
begin
  if not FindTranslation(AKey, LItem) then
    Exit(ADefault);

  LLang := NormalizeLanguage(GLanguage);
  if LLang = 'ru' then
    Result := LItem.Ru
  else if LLang = 'id' then
    Result := LItem.Id
  else
    Result := LItem.En;

  if Result = '' then
    Result := ADefault;
end;

function OwmTextFmt(const AKey, ADefault: string; const AArgs: array of const): string;
begin
  Result := Format(OwmText(AKey, ADefault), AArgs);
end;

procedure OwmSetLanguage(const ALanguageCode: string);
begin
  GLanguage := NormalizeLanguage(ALanguageCode);
end;

function OwmGetLanguage: string;
begin
  Result := GLanguage;
end;

end.
