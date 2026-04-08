/// アプリ内の全ラベル・メッセージ定義.
///
/// ユーザーに表示される全てのテキストをここで一元管理する.
/// 将来の多言語対応にも対応しやすい構造.
library;

/// アプリ全体で使用するラベル・メッセージ.
class AppLabels {
  AppLabels._();

  // ── アプリ情報 ──────────────────────────────────────────────
  static const appName = 'ユメハシ';
  static const appTitle = 'ユメハシ - 夢を現実へとつなぐ橋渡し';
  static const appSubtitle = '夢を言葉にし、一歩ずつ現実へ';
  static const appCatchphraseMain = '夢を現実へとつなぐ橋渡し';
  static const appCatchphraseSub = '夢を言葉にし、一歩ずつ現実へ';

  // ── ページ名（ナビゲーション・タイトル共通） ────────────────────────
  static const pageHome = 'ホーム';
  static const pageDreams = '夢';
  static const pageGoals = '目標';
  static const pageSchedule = '活動予定';
  static const pageBooks = '書籍';
  static const pageConstellations = '星座';
  static const pageStats = '統計';
  static const pageSettings = '設定';

  // ── 共通ボタン ──────────────────────────────────────────────
  static const btnCancel = 'キャンセル';
  static const btnClose = '閉じる';
  static const btnBack = '戻る';
  static const btnDelete = '削除';
  static const btnAdd = '追加';
  static const btnUpdate = '更新';
  static const btnSave = '保存';
  static const btnNext = '次へ';
  static const btnSend = '送信する';
  static const btnSending = '送信中...';
  static const btnRecord = '記録';
  static const btnYes = 'はい';
  static const btnNo = 'いいえ';
  static const btnLater = 'あとで';
  static const btnReset = 'リセット';
  static const btnStart = '開始する';
  static const btnBegin = 'はじめる';

  // ── ツールチップ ──────────────────────────────────────────
  static const tooltipMenu = 'メニュー';
  static const tooltipHelp = 'ヘルプ';
  static const tooltipHowToUse = '使い方';
  static const tooltipExport = '書き出し';
  static const tooltipInbox = '受信ボックス';
  static const tooltipSizeChange = 'サイズ変更';
  static const tooltipDelete = '削除';

  // ── ホーム ──────────────────────────────────────────
  static const dashGreetingMorning = 'おはようございます';
  static const dashGreetingAfternoon = 'こんにちは';
  static const dashGreetingEvening = 'こんばんは';
  static const dashGreetingLate = 'お疲れさまです';
  static const dashTodayActivity = '今日の活動状況';
  static const dashTotalTime = '合計活動時間';
  static const dashStudyDays = '活動日数';
  static const dashDreamCount = '夢の数';
  static const dashGoalCount = '目標数';
  static const dashStreak = '連続活動';
  static const dashBookshelf = '本棚';
  static const dashPersonalRecord = '自己ベスト';
  static const dashConsistency = '活動の実施率';
  static const dashActivity = 'アクティビティ';
  static const dashConstellationPreview = '星座';
  static const dashInbox = '受信ボックス';
  static const dashAddableParts = '追加できるパーツ';
  static const dashNoData = 'データなし';
  static const dashHowToUse = 'アプリの使い方';

  // ── 夢 ────────────────────────────────────────────────────
  static const dreamTitle = 'タイトル';
  static const dreamDescription = '説明';
  static const dreamWhy = 'Why（なぜこの夢を叶えたいか）';
  static const dreamCategory = 'カテゴリ';
  static const dreamDialogAdd = '新しい夢を追加';
  static const dreamDialogEdit = '夢を編集';
  static const dreamDialogDelete = '夢を削除';
  static const dreamEmptyTitle = 'やりたいことはありますか？';
  static const dreamEmptyAction = 'ガイドで見つける';
  static const dreamPageDesc = '将来の夢を設定し、夢の実現に向けた目標を管理します。';
  static const dreamDiscoveryGuide = '発見ガイド';
  static const discoveryGuideComingSoon = '発見ガイドは現在リニューアル中です。より良い体験をお届けできるよう開発を進めていますので、お楽しみに！';
  static const dreamAddButton = '夢を追加';
  static const dreamEmptyHeading = 'やりたいことを見つけよう';
  static const dreamEmptyHint = '「夢を追加」ボタンから直接追加するか、\n「発見ガイド」でやりたいことを見つけましょう';
  static const dreamTutorialGuideChoice = 'すでにやりたいことがある方はそのまま入力できます。\nまだ決まっていない方は、ガイドが一緒に見つけるお手伝いをします。';
  static const dreamTutorialSelfInput = '自分で入力する';
  static const dreamHintTitle = '例: 医者になる、世界一周する';
  static const dreamHintDescription = '例: 困っている人を助けられる医者になりたい';
  static const dreamHintWhy = '例: 幼い頃に医者に助けられた経験がある';

  // ── 夢カテゴリ ──────────────────────────────────────────────
  static const catCareer = 'キャリア';
  static const catLearning = '学び';
  static const catHealth = '健康';
  static const catFinance = 'お金';
  static const catHobby = '趣味';
  static const catRelationship = '人間関係';
  static const catTravel = '旅行';
  static const catOther = 'その他';

  // ── 目標 ────────────────────────────────────────────────────
  static const goalWhat = 'What（何を目標とするか）';
  static const goalWhen = 'When（いつまでに達成するか）';
  static const goalHow = 'How（どうやって達成するか）';
  static const goalDialogAdd = '新しい目標を追加';
  static const goalDialogEdit = '目標を編集';
  static const goalDialogDelete = '目標を削除';
  static const goalEmptyTitle = 'どんな目標を立てますか？';
  static const goalEmptyAction = 'ガイドで考える';
  static const goalPageDesc = 'やりたいことに向けた目標を管理します。';
  static const goalDiscoveryGuide = '発見ガイド';
  static const goalAddButton = '目標を追加';
  static const goalEmptyHeading = '最初の目標を設定しよう';
  static const goalEmptyHint = '「目標を追加」ボタンから始められます';
  static const goalIndependentSection = '独立した目標';
  static const goalTutorialGuideChoice = '夢を実現するための具体的な目標を設定します。\nまだ決まっていない方は、ガイドが一緒に考えるお手伝いをします。';
  static const goalTutorialSelfInput = '自分で入力する';
  static const goalTaskNotSet = 'タスク未設定';
  static const goalLinkedDream = '紐づく夢（任意）';
  static const goalSelectDream = '夢を選択してください';
  static const goalIndependent = 'なし（独立した目標）';
  static const goalDateType = '日付指定';
  static const goalPeriodType = '期間指定';
  static const goalHintWhat = '例: TOEIC 900点を取得する';
  static const goalHintWhen = '例: 3ヶ月以内';
  static const goalHintHow = '例: 公式問題集を毎日1セット解く';
  static const goalColor = 'カラー';

  // ── タスク ────────────────────────────────────────────────
  static const taskName = 'タスク名';
  static const taskDialogAdd = '新しいタスクを追加';
  static const taskDialogEdit = 'タスクを編集';
  static const taskDialogDelete = 'タスクを削除';
  static const taskAdd = 'タスクを追加';
  static const taskProgress = '進捗';
  static const taskMemo = 'メモ';
  static const taskMemoHint = 'メモ（任意）';
  static const taskStartDate = '開始日';
  static const taskEndDate = '終了日';
  static const taskGoal = '目標';
  static const taskIndependent = '独立タスク';
  static const taskRelatedBook = '関連書籍';
  static const taskNone = 'なし';
  static const taskHintName = '例: 第1章を読む';
  static const taskStatusNotStarted = '未着手';
  static const taskStatusInProgress = '進行中';
  static const taskStatusCompleted = '完了';

  // ── 書籍 ────────────────────────────────────────────────────
  static const bookTitle = '書籍名';
  static const bookDialogAdd = '書籍を追加';
  static const bookDialogEdit = '書籍を編集';
  static const bookDialogDelete = '書籍を削除';
  static const bookAddButton = '書籍を追加';
  static const bookDescription = '本棚に登録した書籍を管理できます。';
  static const bookSortCreated = '登録日順';
  static const bookSortUpdated = '更新日順';
  static const bookSortTitle = '50音順';
  static const bookCreatedAt = '登録日';
  static const bookUpdatedAt = '更新日';
  static const bookEmptyTitle = '最初の一冊を登録しよう';
  static const bookEmptySubtitle = '上のフォームから書籍を登録できます';
  static const bookCategory = 'カテゴリ';
  static const bookWhy = 'なぜ読むのか';
  static const bookMemo = '内容メモ';
  static const bookHintTitle = '書籍のタイトルを入力';
  static const bookHintWhy = 'この本を読む理由や目的';
  static const bookHintMemo = '気になるポイントや期待する学びなど';
  static const bookStatusUnread = '未読';
  static const bookStatusReading = '読書中';
  static const bookStatusCompleted = '読了';

  // ── 書籍カテゴリ ──────────────────────────────────────────
  static const bookCatIt = 'IT・技術';
  static const bookCatBusiness = 'ビジネス';
  static const bookCatNovel = '小説・文学';
  static const bookCatSelfHelp = '自己啓発';
  static const bookCatAcademic = '学術・教育';
  static const bookCatHobby = '趣味・実用';
  static const bookCatOther = 'その他';

  // ── 読書活動予定 ──────────────────────────────────────────
  static const scheduleDialogAdd = '読書活動予定を追加';
  static const scheduleDialogEdit = '読書活動予定を編集';
  static const scheduleAddButton = '読書活動予定を追加';
  static const scheduleDeleteConfirm = '活動予定削除';
  static const scheduleNewBook = '新しい書籍を作成';
  static const scheduleStatus = 'ステータス';
  static const scheduleProgress = '進捗率';
  static const scheduleHintTitle = '例: Python入門';

  // ── 活動ログ ──────────────────────────────────────────────
  static const logDialogTitle = '活動ログを記録';
  static const logDate = '活動日';
  static const logDuration = '活動時間';
  static const logHours = '時間';
  static const logMinutes = '分';
  static const logMemo = 'メモ';
  static const logMemoHint = '活動内容のメモ（任意）';
  static const logMinRequired = '活動時間は1分以上で入力してください';
  static const logRecordActivity = '活動時間を記録';

  // ── 活動予定（旧活動予定） ──────────────────────────────
  static const ganttAllTasks = '全タスク';
  static const ganttByGoal = '目標別';
  static const ganttAllBooks = '全書籍';
  static const ganttDiscoveryGuide = '発見ガイド';
  static const ganttToday = '今日';
  static const ganttJumpToDate = '日付へ移動';

  /// 活動予定メニュー: 完了タスクの表示/非表示切替.
  static const ganttShowCompleted = '完了タスクも表示';
  static const ganttEmptyTitle = '最初のタスクを追加しよう';
  static const ganttEmptySubtitle = '目標を選択してタスクを追加しましょう';
  static const ganttEditTask = 'タスクを編集';
  static const ganttEditSchedule = '活動予定を編集';
  static const ganttLabelGoal = '目標';

  // ── 日付範囲 ────────────────────────────────────────────────
  static const range3Months = '直近3ヶ月';
  static const range6Months = '直近6ヶ月';
  static const range1Year = '直近1年';
  static const rangeAll = '全期間';

  // ── 書き出し ──────────────────────────────────────────────
  static const exportSelectFormat = '書き出し形式を選択';
  static const exportNoTasks = '書き出すタスクがありません';
  static const exportHtmlDesc = 'ブラウザで閲覧・共有に最適';
  static const exportExcelDesc = 'Excel / Google スプレッドシートで開けます';
  static const exportCsvDesc = 'Google スプレッドシート / 各種ツールで利用可能';
  static String exportSuccess(String fileName) => '$fileName を書き出しました';
  static String exportError(String error) => '書き出しに失敗しました: $error';

  // ── 設定 ────────────────────────────────────────────────────
  static const settingsDarkMode = 'ダークモード';
  static const settingsReleaseNotes = 'リリース通知';
  static const settingsAchievementNotif = '実績通知';
  static const settingsExportData = 'データを書き出す';
  static const settingsImportData = 'データを読み込む';
  static const settingsDeleteAll = '全データを削除';
  static const settingsDeleteWarning = 'この操作は取り消せません';
  static const settingsCloudRestore = 'クラウドからデータ復元';
  static const settingsCloudRestoreDesc = 'バックアップからデータを復元します';
  static const settingsUpgradeTitle = 'もっと自由に、もっと先へ';
  static const settingsUpgradeDesc = '月額200円で全機能を利用可能';
  static const settingsManageSubscription = 'サブスクリプション管理';
  static const settingsManageSubscriptionDesc = 'プラン変更・解約はこちら';
  static const settingsVersion = 'バージョン';
  static const settingsLastDeploy = '最終更新日';
  static const settingsPlatform = 'クロスプラットフォーム対応';
  static const settingsPlan = 'ご利用プラン';
  static const settingsAccount = 'アカウント情報';
  static const settingsAppInfo = 'アプリ情報';
  static const settingsAppearance = '外観';
  static const settingsNotifications = '通知設定';
  static const settingsDataManagement = 'データ管理';

  // ── 読み込み ──────────────────────────────────────────────
  static const importUnavailable = '読み込み不可';
  static const importUnavailableMsg = 'スタータープランではデータの読み込みはご利用いただけません。';
  static const importConfirmTitle = 'データを読み込む';
  static const importConfirmMsg = '以下のデータを読み込みます。';
  static const importButton = '読み込む';
  static const importComplete = '読み込み完了';
  static String importError(String error) => '読み込みに失敗しました: $error';

  // ── 統計 ────────────────────────────────────────────────────
  static const statsSummary = 'サマリー';
  static const statsPersonalRecord = '自己ベスト';
  static const statsConsistency = '活動の実施率';
  static const statsActivity = 'アクティビティ';
  static const statsRecentLogs = '最近の活動ログ';
  static const statsBookStats = '読書統計';
  static const statsGoalStats = '目標別統計';
  static const statsNoData = 'データなし';
  static const statsTotalTime = '合計活動時間';
  static const statsStudyDays = '活動日数';
  static const statsStreak = '連続活動';
  static const statsToday = '今日';
  static const statsGoalCount = '目標数';
  static const statsThisWeek = '今週';
  static const statsThisMonth = '今月';
  static const statsBestDay = '1日の最高活動時間';
  static const statsBestWeek = '1週間の最高活動時間';
  static const statsLongestStreak = '最長連続活動';
  static const statsOverall = '全体';
  static const statsCategory = 'カテゴリ別';
  static const statsCompletionRate = '読了率';
  static const statsRegistered = '登録';
  static const statsCompleted = '読了';
  static const statsReading = '読書中';
  static const statsUnread = '未読';
  static const statsNoLogs = '活動を始めるとログが表示されます';
  static const statsGoalEmptyHint = '目標を追加すると統計が表示されます';
  static const statsBookEmptyHint = '読書を始めると統計が表示されます';
  static const statsTotal = '合計';

  // ── 受信ボックス ──────────────────────────────────────────
  static const inboxTitle = '受信ボックス';
  static const inboxEmpty = '受信ボックスは空です';
  static const inboxMarkAllRead = '全て既読';
  static String inboxUnread(int count) => '$count件の未読';
  static const inboxNoNotifications = '新しい通知はありません';
  static const inboxTypeReminder = 'リマインド';
  static const inboxTypeAchievement = '実績';
  static const inboxTypeSystem = 'お知らせ';

  // ── クラウド認証 ──────────────────────────────────────────
  static const authLogin = 'ログイン';
  static const authLink = '連携する';
  static const authDialogLogin = 'アカウントでログイン';
  static const authDialogLink = 'アカウント連携';
  static const authEmail = 'メールアドレス';
  static const authPassword = 'パスワード';
  static const authPasswordHint = '6文字以上';
  static const authEmailHint = 'example@email.com';
  static const authLinked = 'アカウント連携済み';
  static String authLinkedEmail(String email) => email;

  // ── アプリの感想 ──────────────────────────────────────────
  static const feedbackTitle = 'アプリの感想を送信';
  static const feedbackCategory = 'カテゴリ *';
  static const feedbackSelectCategory = 'カテゴリを選択してください';
  static const feedbackContent = 'ご意見・ご感想 *';
  static const feedbackContentHint = '内容を入力してください';
  static const feedbackGuide = 'アプリの改善点や使いにくい部分、改善要望などをお聞かせください。';
  static const feedbackSendAction = 'アプリの感想を送る';
  static const feedbackSendDesc = 'こんな機能が欲しいやこんな不具合があったなどをお知らせください。';
  static const feedbackSendTitle = 'アプリの感想を送る';
  static const feedbackSendSubtitle = 'アプリへのご意見・改善要望';
  static const contactTitle = 'ご意見・お問い合わせ';

  // ── お問い合わせ ──────────────────────────────────────────
  static const inquiryTitle = 'お問い合わせ';
  static const inquiryEmail = 'メールアドレス *';
  static const inquiryContent = 'お問い合わせ内容 *';
  static const inquiryContentHint = '詳細を入力してください';
  static const inquiryGuide = 'ご相談内容をご記入ください。';
  static const inquirySuccess = 'お問い合わせを送信しました。連絡をお待ちください。';
  static const inquirySubtitle = '追加開発・案件のご相談など';

  // ── プレミアム ──────────────────────────────────────────────
  static const premiumViewPlan = 'プレミアムプランを見る';
  static const premiumStarterPlan = 'スタータープラン';
  static const premiumAboutStarter = 'スタータープランについて';
  static const premiumLabel = 'プレミアム';
  static const premiumFeature = 'プレミアム機能';
  static const premiumAvailable = 'プレミアムプランで利用できます';
  static const premiumInviteActive = '招待プラン利用中です';
  static const premiumStarterActive = 'スタータープランをご利用中です';
  static const premiumUnderstood = '理解しました';

  // ── チュートリアル ──────────────────────────────────────────
  static const tutorialTitle = 'アプリの使い方';
  static const tutorialAsk = 'アプリの基本的な使い方を説明しますか？\n'
      '実際の操作を通じて、夢・目標・タスクの登録方法を体験できます。';
  static const tutorialDeleteData = 'データを削除';
  static const tutorialKeepData = 'データを保持';
  static const tutorialCompleted = 'チュートリアル完了！';
  static const tutorialCompletedMsg = 'アプリの基本操作を体験しました。\n'
      'チュートリアルで作成したデータをどうしますか？';
  static const tutorialRestart = '設定画面からいつでもチュートリアルを再実行できます';
  static const tutorialStart = 'チュートリアルを開始';
  static const tutorialAppBarTitle = '画面右上のアイコンについて';
  static const tutorialAppBarHowToUse = '使い方';
  static const tutorialAppBarHowToUseDesc =
      'アプリの全体像・操作手順を確認できます。チュートリアルもここから再開できます。';
  static const tutorialAppBarHelp = 'ヘルプ';
  static const tutorialAppBarHelpDesc =
      'よくある質問（FAQ）を検索できます。困った時はまずここを確認してください。';
  static const tutorialAppBarInbox = '受信ボックス';
  static const tutorialAppBarInboxDesc =
      '期限のリマインドや開発者からのお知らせ、実績通知が届きます。未読件数がバッジで表示されます。';
  static const tutorialAppBarContact = 'アプリの感想・お問い合わせ';
  static const tutorialAppBarContactDesc =
      'アプリへのご意見・改善要望の送信や、開発に関するお問い合わせができます。';
  static const tutorialAppBarAchievement = '実績';
  static const tutorialAppBarAchievementDesc =
      '活動の積み重ねで解除される実績を確認できます。新しい実績はバッジでお知らせします。';
  static String tutorialStep(int current, int total) =>
      'ステップ $current / $total';

  // ── チュートリアルステップ ──────────────────────────────────────
  static const tutorialGoToDreams = '画面下の「夢」タブをタップしてください';
  static const tutorialGoToDreamsHint =
      '下部ナビゲーションバーの ✨ アイコンが「夢」ページです';
  static const tutorialAddDream = '右上の「夢を追加」ボタンをタップしてください';
  static const tutorialAddDreamHint =
      'タイトルを入力するだけでOK！説明や理由は後から編集できます';
  static const tutorialGoToGoals = '画面下の「目標」タブをタップしてください';
  static const tutorialGoToGoalsHint =
      '下部ナビゲーションバーの 🚩 アイコンが「目標」ページです';
  static const tutorialAddGoal = '右上の「目標を追加」ボタンをタップしてください';
  static const tutorialAddGoalHint =
      '夢に紐づく具体的な目標を設定します。What・When・Howを入力してください';
  static const tutorialGoToSchedule = '画面下の「活動予定」タブをタップしてください';
  static const tutorialGoToScheduleHint =
      '下部ナビゲーションバーのタイムラインアイコンが「活動予定」ページです';
  static const tutorialAddTask =
      'ドロップダウンから目標を選び「タスクを追加」をタップ';
  static const tutorialAddTaskHint =
      '左上のプルダウンで先ほど作成した目標を選択すると、追加ボタンが表示されます';
  static const tutorialExplainAppBar = '画面右上のアイコンを確認しましょう';
  static const tutorialExplainAppBarHint =
      '各アイコンの役割を紹介します。「次へ」で進めてください';
  static const tutorialCompletedStep = 'チュートリアル完了！';
  static const tutorialCompletedStepHint = 'アプリの基本的な使い方を体験しました';

  // ── チュートリアル補助メッセージ ──────────────────────────────────
  static const tutorialInputTitle = 'タイトルを入力して「追加」をタップしてください';
  static const tutorialInputFields = '各項目を入力して「追加」をタップしてください';
  static const tutorialEditLater = '説明やWhyは後から編集できます';
  static const tutorialGanttPremiumMsg =
      '活動予定で目標達成までの道のりを可視化しよう！';
  static const tutorialGanttPremiumUpgrade =
      'プレミアムプランにアップグレードするとタスク管理・進捗トラッキングなど全機能をご利用いただけます';

  // ── オンボーディング ──────────────────────────────────────────
  static const onboardingStep1Body = '小さなことでも、大きなことでも。\n'
      '「こうなれたらいいな」と\n心に浮かんだことがあるはずです。';
  static const onboardingStep1Emphasis = 'その想いを、一歩ずつ形にしていこう。';
  static const onboardingStep2Body = '言葉にして書き出すことで、\n'
      '脳はそれを「目標」として認識します。';
  static const onboardingStep2Emphasis = '文字にすることで、\n想いは「目標」へ変わる。';
  static const onboardingStep3Body = '動き出した人は、動き続けられる。\n'
      '最初の一歩さえ踏み出せば、\nあとは自然と進んでいけます。';
  static const onboardingStep4Title = 'ユメハシは、あなたの\n「最初の一歩」を支えます。';
  static const onboardingStep4Body = '夢を書き出し、目標に分解し、\n'
      '日々の行動に落とし込む。\n'
      '動き出したあなたと一緒に走り続けます。';
  static const onboardingStep4Emphasis = '自分の力で未来を切り拓こう。';

  // ── 星座 ────────────────────────────────────────────────
  static const constellationComplete = '完成';

  // ── 読了レビュー ──────────────────────────────────────────
  static String reviewTitle(String bookTitle) => '読了レビュー: $bookTitle';

  // ── 書籍活動予定 ──────────────────────────────────────────
  static const scheduleDeleteConfirmTitle = '確認';
  static const scheduleDeleteConfirmMsg =
      'この書籍の活動予定を削除しますか？\n（書籍自体は削除されません）';

  // ── 実績通知テンプレート ──────────────────────────────────────
  static String achievementTotalHoursTitle(int value) => '累計$value時間達成！';
  static String achievementStudyDaysTitle(int value) => '活動$value日目達成！';
  static String achievementStreakTitle(int value) => '$value日連続活動達成！';
  static String achievementTotalHoursMsg(int value) =>
      '累計活動時間が$value時間に到達しました。素晴らしい継続力です！';
  static String achievementStudyDaysMsg(int value) =>
      '活動日数が$value日に到達しました。コツコツ積み重ねていますね！';
  static String achievementStreakMsg(int value) =>
      '$value日間連続で活動を続けています。この調子で頑張りましょう！';

  // ── リマインダーテンプレート ──────────────────────────────────
  static String reminderOverdueTitle(String name) => '$nameが期限を過ぎています';
  static String reminderOverdueMsg(int days) =>
      '期限を$days日超過しています。確認してください。';
  static String reminderTodayTitle(String name) => '$nameの期限は今日です';
  static const reminderTodayMsg = '今日が期限日です。最後の追い込みを！';
  static String reminderSoonTitle(String name, int days) =>
      '$nameの期限まであと$days日';
  static const reminderSoonMsg = '期限が近づいています。計画を確認しましょう。';

  // ── 制限説明 ──────────────────────────────────────────────
  static const limitUnlocked = '制限は完全に解除されています。';
  static String limitDescription(int level, int maxLevel, int dreams,
          int goals, int books) =>
      '現在の制限（レベル$level / $maxLevel）:\n'
      '- 夢: $dreams個まで\n'
      '- 目標: $goals個まで\n'
      '- 書籍: $books冊まで';

  // ── 使い方ガイド ──────────────────────────────────────────
  static const guideTabOverview = '全体像';
  static const guideTabHowTo = '使い方';
  static const guideDream = '夢';
  static const guideDreamSub = '最終ゴール';
  static const guideGoal = '目標';
  static const guideGoalSub = '具体的なステップ';
  static const guideDecompose = '分解';
  static const guideExecute = '実行';
  static const guideScheduleSub = '活動予定管理・進捗記録';
  static const guideRelatedScreens = '連携する画面';
  static const guideBookSub = '何を読むか\nどう読んだか';
  static const guideScheduleBookSub = 'いつ読むか\n活動予定管理';
  static const guideReadingPlan = '読書計画';
  static const guideGoalWhatSub = '何を達成するか';
  static const guideScheduleTaskSub = 'いつ・どのくらい\nやるか';
  static const guideTaskManagement = 'タスク管理';
  static const guideBookGoalLink = '紐づけ';
  static const guideDashboardSub = '今日の状況';
  static const guideStatsSub = '振り返り';
  static const guideConstellationSub = 'モチベーション';
  static const guideBookManagement = '読書管理';

  // ── 使い方ガイドステップ ──────────────────────────────────────
  static const guideStepDream = '夢を登録する';
  static const guideStepGoal = '目標を設定する';
  static const guideStepSchedule = '活動予定でタスク管理';
  static const guideStepBook = '書籍を管理する';
  static const guideStepStats = '統計で振り返る';
  static const guideStepConstellation = '星座で成長を実感';
  static const guideDashboardLabel = 'ダッシュ\nボード';

  // ── リリースノートダイアログ ──────────────────────────────────
  static const releaseNotesSubtitle = '新機能・改善のお知らせ';
  static const releaseNotesConfirm = '確認しました';

  // ── バリデーション ──────────────────────────────────────────
  static const validRequired = '必須項目です';
  static const validBookTitle = '書籍名は必須です';
  static const validEmail = '有効なメールアドレスを入力してください';

  // ── エラー ────────────────────────────────────────────────
  static const errorGeneral = 'エラーが発生しました';
  static String errorWithDetail(String error) => 'エラーが発生しました: $error';
  static const errorRetryLater = 'エラーが発生しました。しばらく後にお試しください。';

  // ── 確認ダイアログ ──────────────────────────────────────────
  static String deleteConfirm(String title) => '「$title」を削除しますか？';
  static const deleteIrreversible = 'この操作は取り消せません。';

  // ── オンボーディング ──────────────────────────────────────────
  static const onboardingStep1 = 'あなたには、\n「やりたいこと」がありますか？';
  static const onboardingStep2 = '書き出すことで、\n実現に向けて動き出します。';
  static const onboardingStep3 = '一歩踏み出せば、\n自然と前に進めます。';

  // ── 読了レビュー ──────────────────────────────────────────
  static const reviewDate = '読了日';
  static const reviewSummary = '要約';
  static const reviewSummaryHint = '本の概要やポイント（任意）';
  static const reviewImpressions = '感想';
  static const reviewImpressionsHint = '感想や学んだこと（任意）';

  // ── ヘルプ ────────────────────────────────────────────────
  static const helpTitle = 'ヘルプ';
  static const helpTabAbout = 'アプリについて';
  static const helpTabFaq = 'FAQ';
  static const helpTabPlan = 'スタータープラン';
  static const helpSearchHint = 'キーワードで検索...';
  static const helpUpdateInfo = 'アップデート情報';

  // ── アップグレードダイアログ ──────────────────────────────────
  static const upgradeTitle = 'もっと自由に、もっと先へ';
  static const upgradeSubtitle =
      '月額200円で、あなたの「やりたい」を全力でサポートします。';
  static const upgradeFeature1Title = 'やりたいことを、制限なく追いかけられる';
  static const upgradeFeature1Desc = '夢・目標・タスク・書籍を好きなだけ登録';
  static const upgradeFeature2Title = 'やるべきことが一目でわかる';
  static const upgradeFeature2Desc =
      '活動予定で全体像を把握し、迷わず行動できる';
  static const upgradeFeature3Title = '自分の成長が見える';
  static const upgradeFeature3Desc = '活動統計で努力の積み重ねを実感できる';
  static const upgradeFeature4Title = 'あなたの声が、新機能になる';
  static const upgradeFeature4Desc =
      '要望した機能を最優先で利用可能';
  static const upgradePlanName = 'プレミアムプラン';
  static const upgradeTrialDesc = '初回7日間無料 ── まず試してみてください';
  static const upgradePaidDesc = '月額200円で全機能を利用可能';
  static const upgradePrice = '¥200/月';
  static const upgradeTrialButton = '7日間無料で試してみる';
  static const upgradeProcessing = '処理中...';
  static String upgradeSubscribeNow(String price) => 'すぐに申し込む（$price）';
  static String upgradePlanSubscribe(String price) =>
      'プレミアムプランに申し込む（$price）';
  static String upgradeTrialStarted(int days) =>
      '無料トライアルを開始しました（残り$days日間）';
  static const upgradeCheckoutFailed =
      '決済ページの取得に失敗しました。しばらく後にお試しください。';

  // ── 制限ダイアログ ──────────────────────────────────────────
  static String limitReachedTitle(String itemName) =>
      '$itemNameの上限に達しました';
  static String limitReachedDesc(String itemName, int maxCount) =>
      'スタータープランでは$itemNameを$maxCount件まで登録できます。';
  static const limitUnlockByFeedback = 'アプリの感想を送って制限を解除';
  static const limitUnlockByFeedbackDesc =
      'アプリの改善にご協力いただくと、制限が段階的に解除されます。';
  static const limitNeedUpgrade = 'さらに制限を解除するには';
  static const limitNeedUpgradeDesc =
      'アプリの感想を送ることによる制限解除は上限に達しました。\n'
      'すべての機能を無制限で使うには、\n'
      '有料プランをご検討ください。';
  static const limitSendFeedback = 'アプリの感想を送信';
  static const limitViewPlan = '無制限プランを見る';

  // ── 読書ログダイアログ ──────────────────────────────────────────
  static String readingLogDefaultTitle(String bookTitle) =>
      '読書時間 - $bookTitle';
  static String readingLogTotal(String duration) => '合計: $duration';
  static const readingLogDate = '日付';
  static const readingLogDuration = '読書時間';
  static const readingLogHours = '時間';
  static const readingLogMinutes = '分';
  static const readingLogMemoHint = 'メモ（任意）';
  static const readingLogListTitle = '記録一覧';
  static const readingLogEmpty = '読書を始めると記録が表示されます';
  static const readingLogMinRequired = '1分以上で入力してください';

  // ── クラウド認証ダイアログ追加 ──────────────────────────────────
  static const authDescLogin = '登録済みのアカウントでログインしてデータを復元します。';
  static const authDescLink =
      'メールアドレスを連携すると、端末変更やキャッシュクリア時も'
      'データを復元できます。';
  static const authSwitchToLink = '初めてご利用の方はこちら（アカウント連携）';
  static const authSwitchToLogin =
      '既にアカウントをお持ちの方はこちら（ログイン）';
  static const authErrorEmailInUse =
      'このメールアドレスは既に登録されています。'
      '「既にアカウントをお持ちの方」からログインしてください。';
  static const authErrorWeakPassword = 'パスワードは6文字以上で設定してください。';
  static const authErrorInvalidEmail = 'メールアドレスの形式が正しくありません。';
  static const authErrorUserNotFound =
      'アカウントが見つかりません。新規連携してください。';
  static const authErrorWrongPassword =
      'メールアドレスまたはパスワードが正しくありません。';
  static String authErrorGeneral(String code) => '認証エラーが発生しました（$code）';

  // ── モニター提出 ──────────────────────────────────────────
  static const monitorTitle = 'モニターデータの提出';
  static const monitorAnswer = '回答する';
  static const monitorSubmit = '提出する';
  static String monitorRemainingDays(int days) =>
      '招待プランの残り日数: $days日';
  static const monitorExpired = '招待プランの期限が終了しました';
  static const monitorThanks =
      'モニターとしてアプリをご利用いただきありがとうございます。';
  static const monitorRequestDesc =
      'アプリの改善のため、ご利用データと簡単なアンケートの'
      '提出にご協力をお願いいたします。';
  static const monitorDataHandlingTitle = 'データの取り扱いについて';
  static const monitorDataHandlingDesc =
      '提出いただいたデータはアプリの改善を目的とした'
      '参考資料としてのみ使用いたします。\n'
      '第三者への提供や、改善目的以外での流用は一切行いません。';
  static const monitorSubmissionContents = '提出内容:';
  static const monitorBullet1 = 'アプリの使いやすさに関するアンケート（3問）';
  static const monitorBullet2 =
      'アプリ内の登録データ（夢・目標・タスク・書籍・活動ログ）';
  static const monitorQ1 = 'Q1. アプリの使いやすさはいかがでしたか？';
  static const monitorRating1 = '使いにくい';
  static const monitorRating2 = 'やや使いにくい';
  static const monitorRating3 = '普通';
  static const monitorRating4 = '使いやすい';
  static const monitorRating5 = 'とても使いやすい';
  static const monitorRatingHint = '星をタップして評価してください';
  static const monitorQ2 = 'Q2. 良かった点を教えてください（任意）';
  static const monitorQ2Hint = '例: 夢から目標に落とし込む流れがわかりやすい';
  static const monitorQ3 = 'Q3. 改善点やほしい機能はありますか？（任意）';
  static const monitorQ3Hint = '例: 通知機能がほしい、画面遷移が分かりにくい';
  static const monitorSending = 'データを送信しています...';
  static const monitorSendFailed = '送信に失敗しました。後ほど再度お試しください。';
  static const monitorNetworkError =
      '通信エラーが発生しました。後ほど再度お試しください。';
  static const monitorComplete = 'ご協力ありがとうございます！';
  static const monitorCompleteDesc =
      'いただいたデータはアプリの改善に活用させていただきます。';

  // ── クラウド復元 ──────────────────────────────────────────
  static const cloudNoBackup = 'クラウドにバックアップデータが見つかりません';
  static const cloudRestored = 'クラウドからデータを復元しました';
  static const cloudLoginRestored = 'ログインしてデータを復元しました';
  static const cloudLoginRestoreFailed = 'ログインしました（データ復元に失敗）';
  static const cloudAccountLinked = 'アカウントを連携しました';

  // ── リリースノート ──────────────────────────────────────────
  static String releaseVersion(String version) => 'バージョン $version';

  // ── 夢発見ガイド ──────────────────────────────────────────
  static const dreamDiscoveryTitle = 'やりたいこと発見ガイド';
  static const dreamDiscoveryQuestionsDesc = 'いくつかの質問に答えてみましょう';
  static const dreamDiscoveryCategoryDesc =
      'あなたの回答から、興味のある分野が見えてきました。\n'
      '気になるカテゴリを選んでください。';
  static const dreamDiscoverySelectCategory = 'カテゴリを選択してください';
  static String dreamDiscoveryTemplateTitle(String label) =>
      '$labelの夢テンプレート';
  static const dreamDiscoveryTemplateDesc =
      '気になるものを選ぶか、自分で入力もできます。';
  static const dreamDiscoverySelfInput = '自分で入力する';
  static const dreamDiscoveryFormDesc = 'あなたの夢を言葉にしましょう';
  static const dreamDiscoveryFormTitle = 'タイトル';
  static const dreamDiscoveryFormTitleHint = '例: 英語を話せるようになる';
  static const dreamDiscoveryFormDescription = '説明（任意）';
  static const dreamDiscoveryFormDescriptionHint =
      '例: 日常会話レベルの英語力を身につける';
  static const dreamDiscoveryFormWhy = 'Why ── なぜ実現したいか（任意）';
  static const dreamDiscoveryFormWhyHint =
      '例: 世界中の人と話せるようになりたいから';
  static const dreamDiscoveryCreate = '夢を作成';
  static const dreamDiscoveryRecommended = 'おすすめ';

  // ── 目標発見ガイド ──────────────────────────────────────────
  static const goalDiscoveryTitle = '目標設定ガイド';
  static const goalDiscoveryDreamQuestion = 'どの夢に向けた目標ですか？';
  static const goalDiscoveryDreamDesc =
      '夢と紐づけることで、目標の意味がより明確になります。';
  static const goalDiscoveryNoDream = '夢とは紐づけず、独立した目標を立てる';
  static String goalDiscoveryThinkFor(String dreamTitle) =>
      '「$dreamTitle」を実現するために考えてみましょう';
  static const goalDiscoveryTemplateTitle = 'テンプレートから選ぶ';
  static const goalDiscoveryTemplateDesc =
      'そのまま使っても、自分なりにアレンジしてもOKです。\n'
      '「自分で考える」場合はそのまま「次へ」を押してください。';
  static String goalDiscoverySuggestedPeriod(String period) =>
      '推奨期間: $period';
  static const goalDiscoveryFormTitle = '目標を具体化しよう';
  static const goalDiscoveryFormWhat = 'What（何を達成する？）';
  static const goalDiscoveryFormWhatHint = '例: TOEIC 800点を取る';
  static const goalDiscoveryFormWhen = 'When（いつまでに？）';
  static const goalDiscoveryFormWhenHint = '例: 2026年12月, 3ヶ月以内';
  static const goalDiscoveryFormHow = 'How（どうやって？）';
  static const goalDiscoveryFormHowHint = '例: 毎日1時間の英語学習を継続する';
  static String goalDiscoveryLinkedDream(String title) => '紐づく夢: $title';
  static const goalDiscoveryCreate = '目標を作成';

  // ── ヘルプ・FAQ ──────────────────────────────────────────
  static const helpFaqSearchNoResult = '該当するFAQが見つかりません';

  // FAQ Q&A: 基本的な使い方
  static const helpFaqDreamGoalTaskQ = '夢・目標・タスクの違いは何ですか？';
  static const helpFaqDreamGoalTaskA =
      '大きさの異なる3つの段階です。\n\n'
      '・夢 … 最終的に達成したい大きなビジョン\n'
      '・目標 … 夢を実現するための具体的なステップ\n'
      '・タスク … 目標を達成するための日々のアクション\n\n'
      '例: 夢「ITエンジニアになる」→ 目標「基本情報技術者を取得する」'
      '→ タスク「午前問題を毎日10問解く」';
  static const helpFaqNoDreamQ = '夢がなくても使えますか？';
  static const helpFaqNoDreamA =
      'はい、目標やタスクだけでも利用できます。\n\n'
      'やりたいことが見つからない場合は、'
      '「発見ガイド」機能が見つけるお手伝いをします（現在リニューアル中）。';
  static const helpFaqScheduleQ = '活動予定とは何ですか？';
  static const helpFaqScheduleA =
      'タスクの期間と進捗を横棒グラフで一覧表示する機能です。\n\n'
      '各タスクの開始日・終了日・進捗を視覚的に確認でき、'
      '全体の活動予定管理に役立ちます。\n'
      '※プレミアムプランで利用できます。';
  static const helpFaqActivityLogQ = '活動ログはどうやって記録しますか？';
  static const helpFaqActivityLogA =
      '活動予定のタスクをタップ →「活動時間を記録」から記録できます。\n\n'
      '手動入力またはタイマー機能が使えます。\n'
      'ホーム画面の「活動を記録」ボタンからも記録できます。';
  static const helpFaqConstellationQ = '星座はどうすれば完成しますか？';
  static const helpFaqConstellationA =
      '活動ログを記録すると、5時間ごとに星が1つ灯ります。\n\n'
      '必要な星を全て集めると星座が完成します。';

  // FAQ Q&A: データ管理
  static const helpFaqDataStorageQ = 'データはどこに保存されますか？';
  static const helpFaqDataStorageA =
      '認証状態によって異なります。\n\n'
      '・メール連携済み … クラウド（Firestore）に自動バックアップ\n'
      '・未認証（匿名） … ブラウザ内のみに保存';
  static const helpFaqDataStorageCloudQ = 'クラウド保存の場合、データはどうなりますか？';
  static const helpFaqDataStorageCloudA =
      'データの変更時にクラウドへ自動バックアップされます。\n\n'
      '別の端末でも同じメールアドレスでログインすればデータが復元されます。\n'
      'ブラウザのデータを消去しても、再ログインで復元できます。';
  static const helpFaqDataStorageLocalQ = 'ブラウザ内保存の場合、データはどうなりますか？';
  static const helpFaqDataStorageLocalA =
      'データはブラウザ内にのみ保存され、サーバーには送信されません。\n\n'
      '※ブラウザのデータを消去するとアプリのデータも削除されます。\n'
      'データを守るために、メール連携または手動バックアップをお勧めします。';
  static const helpFaqBackupQ = 'データのバックアップはできますか？';
  static const helpFaqBackupA =
      'はい、2つの方法があります。\n\n'
      '・メール連携 … クラウドに自動バックアップ（設定 →「メールアドレスを連携する」）\n'
      '・手動書き出し … 設定 →「データを書き出す」でJSON形式で保存';
  static const helpFaqOtherBrowserQ = '別のブラウザや端末でデータを使えますか？';
  static const helpFaqOtherBrowserA =
      'メール連携済みなら、別の端末でも同じメールアドレスでログインすると'
      'データが自動復元されます。\n\n'
      'メール未連携の場合は、設定からデータを書き出し → 新しい端末で読み込んでください。';

  /// データ肥大化対策で自動削除される既読通知・完了タスクの説明.
  static const helpFaqAutoDeleteQ =
      '古いデータが自動的に削除されることはありますか？';
  static const helpFaqAutoDeleteA =
      'はい、以下のデータは起動時に自動で削除されます（v2.1.0 以降）。\n\n'
      '・受信ボックス … 既読かつ作成から30日経過した通知\n'
      '・活動予定のタスク … 完了済みかつ最終更新から30日経過したタスク\n\n'
      '未読の通知・未完了のタスクは期間にかかわらず削除されません。\n\n'
      '削除されたくない完了タスクや通知がある場合は、事前に'
      '「設定 → データを書き出す」でエクスポートしておいてください。'
      'クラウド同期（メール連携）を利用していれば、同じアカウントで'
      'ログインしている端末間で復元できます。';

  // FAQ Q&A: プラン・料金
  static const helpFaqPremiumSubscribeQ =
      'プレミアムプランを契約したい場合はどうすればよいですか？';
  static const helpFaqPremiumSubscribeA =
      '設定 →「プランのアップグレード」から申し込めます。\n\n'
      '【手順】\n'
      '1. 画面左上の「≡」→「設定」を開く\n'
      '2.「プランのアップグレード」をタップ\n'
      '3.「7日間無料で試す」または「申し込む」を選択\n\n'
      '月額200円（税込）で全機能が利用できます。';
  static const helpFaqStarterLimitQ = 'スタータープランの制限を解除するには？';
  static const helpFaqStarterLimitA =
      'アプリの感想を送信すると段階的に制限が解除されます。\n\n'
      'すべての制限を解除するには、プレミアムプラン（月額200円）へ'
      'アップグレードしてください。\n'
      '設定 →「プランのアップグレード」から申し込めます。';
  static const helpFaqPremiumCancelQ =
      'プレミアムプランを解約したい場合はどうすればよいですか？';
  static const helpFaqPremiumCancelA =
      '設定 →「サブスクリプション管理」から解約できます。\n\n'
      '解約後は次回更新日まで利用でき、その後スタータープランに移行します。\n'
      '登録済みのデータはそのまま残ります。';

  // FAQ Q&A: 問い合わせ・アプリの感想
  static const helpFaqInquiryQ = '問い合わせをしたい場合はどうすればよいですか？';
  static const helpFaqInquiryA =
      '画面右上のメールアイコン →「お問い合わせ」から送信できます。\n\n'
      '追加開発のご相談や案件のご依頼なども受け付けています。';
  static const helpFaqFeedbackQ =
      'アプリの感想を送りたい場合はどうすればよいですか？';
  static const helpFaqFeedbackA =
      '画面右上のメールアイコン →「アプリの感想」から送信できます。\n\n'
      '改善要望・不具合報告・その他のご意見を受け付けています。\n'
      'いただいた感想は新機能の開発や改善に活用させていただきます。';
  static const helpFaqFeedbackWhyQ =
      'どんな感想を送ればいいですか？';
  static const helpFaqFeedbackWhyA =
      'どんな小さなことでも大歓迎です。\n\n'
      '例えば…\n'
      '・こんな機能がほしい\n'
      '・この画面をもっとこうしてほしい\n'
      '・使っていて困ったこと\n'
      '・使いやすかった機能\n\n'
      'このアプリは開発者一人で作っているため、'
      '一人の視点だけでは気づけないことがたくさんあります。\n'
      'ユーザーの皆さんと一緒に育てていきたいと考えていますので、'
      'ぜひ気軽にお声を聞かせてください。';

  // FAQ Q&A: 端末・環境
  static const helpFaqSmartphoneQ = 'スマートフォンでも使えますか？';
  static const helpFaqSmartphoneA =
      'はい、スマホのブラウザからそのまま使えます。\n\n'
      'ホーム画面に追加するとアプリのように使えます。\n'
      '・iOS … Safari → 共有ボタン →「ホーム画面に追加」\n'
      '・Android … Chrome → メニュー →「ホーム画面に追加」';
  static const helpFaqBrowserQ = '対応しているブラウザはどれですか？';
  static const helpFaqBrowserA =
      'Chrome / Edge / Safari / Firefox の最新版に対応しています。\n\n'
      'PC・スマートフォンのどちらでも利用できます。';

  // FAQ Q&A: アプリの利用終了
  static const helpFaqQuitQ =
      'アプリの利用を終了（退会）したい場合はどうすればよいですか？';
  static const helpFaqQuitA =
      'ユーザー登録がないため、退会手続きは不要です。\n\n'
      '設定 →「全データを削除」でデータを消去し、'
      'ブックマークを削除すれば完了です。\n\n'
      '※プレミアムプランご契約中の場合は、'
      '必ず先に「サブスクリプション管理」から解約してください。'
      '解約しないと毎月の請求が継続されます。';

  // FAQ Q&A: 書籍
  static const helpFaqBookQ = '書籍はどこから登録できますか？';
  static const helpFaqBookA =
      '画面左上の「≡」→「書籍」ページの「＋」ボタンから登録できます。\n\n'
      '登録した書籍をタップすると、カテゴリ・メモ・ステータスの編集ができます。';

  // FAQ Q&A: その他
  static const helpFaqTutorialQ = 'チュートリアルをもう一度やりたい場合は？';
  static const helpFaqTutorialA =
      '画面右上の「?」アイコン →「チュートリアルを開始」から再度体験できます。\n\n'
      'チュートリアル中に作成したデータは、'
      '完了時に保持するか削除するかを選べます。';
  static const helpFaqAchievementQ = '実績はどこで確認できますか？';
  static const helpFaqAchievementA =
      '画面右上のトロフィーアイコンから確認できます。\n\n'
      '活動時間や連続日数に応じて実績が解除されます。\n'
      '新しい実績を達成するとアイコンにバッジが表示されます。';
  static const helpFaqDevThoughtQ = '開発者の思いはどこで読めますか？';
  static const helpFaqDevThoughtA =
      '画面右上の「?」アイコン →「アプリについて」タブの下部に掲載しています。\n\n'
      'このアプリを作った理由や、ユーザーの皆さんへのメッセージを載せています。';

  // ── ヘルプ・アプリについてタブ ──────────────────────────────────
  static const helpAboutAnonymousTitle = '完全匿名でご利用いただけます';
  static const helpAboutAnonymousDesc =
      'ユーザー登録・ログインは不要です。\n'
      '入力したデータは全てお使いのブラウザ内にのみ保存され、'
      '開発者を含む第三者に送信・公開されることはありません。';
  static const helpAboutDataDeleteTitle = 'ブラウザのデータ削除で全データが消えます';
  static const helpAboutDataDeleteDesc =
      'ブラウザのキャッシュやデータを消去すると、'
      'アプリで登録した夢・目標・タスク・書籍・活動ログ等'
      '全てのデータが削除されます。';
  static const helpAboutDeviceTitle = '別の端末・ブラウザではデータを引き継げません';
  static const helpAboutDeviceDesc =
      'データはブラウザごとに独立して保存されます。\n'
      'プレミアムプランでは設定画面の書き出し/読み込み機能で'
      'データ移行が可能です。';
  static const helpAboutBackupTip =
      '大切なデータは定期的に書き出して'
      'バックアップすることをおすすめします。';

  // ── 開発者の思い ──────────────────────────────────
  static const helpDevThoughtTitle = '開発者の思い';
  static const helpDevThoughtMessage =
      '「夢を持つことで、大きな壁も乗り越えられる」\n\n'
      '私は学生時代、夢を持てず将来に希望を見出せませんでした。\n'
      'あの頃の自分のように、やりたいことが見つからない人や、'
      '見つけても一歩を踏み出せない人の力になりたい。\n'
      'そんな思いから、このアプリを作りました。\n\n'
      '夢は頭の中に閉じ込めておくと、いつの間にか薄れてしまいます。\n'
      '言葉にして外に出すことで、脳が認識し、行動につながる。\n'
      'ユメハシは、その「言語化」と「行動」をつなぐ道具です。\n\n'
      '人は慣性で動きます。\n'
      '止まっている人を動かすこと、動いている人を支えること。\n'
      'このアプリが、あなたの一歩目になれたら嬉しいです。\n\n'
      'このアプリは私一人で開発しています。\n'
      '一人の視点では気づけないことがたくさんあります。\n'
      '皆さんと一緒に、もっと良いアプリに育てていきたいと思っていますので、\n'
      'ぜひ気軽にご感想やご要望をお聞かせください。';
  static const helpDevHomepageLabel = '開発者のホームページ';
  static const helpDevHomepageUrl = 'https://teppei19980914.github.io/HomePage/';

  // ── ヘルプ・スタータープランタブ ──────────────────────────────────
  static const helpPlanRegistrationLimit = '登録上限';
  static const helpPlanDreamLimit = '夢: 1個まで';
  static const helpPlanGoalLimit = '目標: 夢1つにつき2個まで';
  static const helpPlanBookLimit = '書籍: 3冊まで';
  static const helpPlanLockedFeatures = '活動予定・詳細統計: 利用不可';
  static const helpPlanFeedbackUnlock =
      'アプリの感想送信で段階的に登録上限が緩和されます';
  static const helpPlanPremiumName = 'プレミアムプラン';
  static const helpPlanPremiumDesc =
      '月額200円（税込）で全機能を制限なくご利用いただけます。\n'
      '初回7日間の無料トライアルもご用意しています。';
  static const helpPlanPremiumUpgradeHint =
      '設定ページの「プランのアップグレード」からお申し込みください。';

  // ── 使い方ガイド手順 ──────────────────────────────────────
  static const guideStepDreamP1 = '画面下部の「夢」タブをタップ';
  static const guideStepDreamP2 = '右上の「＋ 夢を追加」ボタンをタップ';
  static const guideStepDreamP3 = '夢のタイトルを入力して「追加」をタップ';
  static const guideStepDreamExample =
      '例: 「ITエンジニアになる」「英語を話せるようになる」';
  static const guideStepGoalP1 = '画面下部の「目標」タブをタップ';
  static const guideStepGoalP2 = '「＋ 目標を追加」ボタンをタップ';
  static const guideStepGoalP3 = '紐づける夢を選択';
  static const guideStepGoalP4 =
      'What（何を）・When（いつまでに）・How（どうやって）を入力';
  static const guideStepGoalP5 = '「追加」をタップ';
  static const guideStepGoalExample =
      '夢を細分化し、具体的な行動目標に落とし込みましょう';
  static const guideStepScheduleP1 = '画面下部の「活動予定」タブをタップ';
  static const guideStepScheduleP2 = '上部のドロップダウンで目標を選択';
  static const guideStepScheduleP3 = '「＋ タスク追加」ボタンをタップ';
  static const guideStepScheduleP4 = 'タスク名・開始日・終了日を入力して追加';
  static const guideStepScheduleP5 = 'チャート上のタスクをタップして進捗を更新';
  static const guideStepScheduleExample =
      'タスクをタップすると活動ログの記録やタイマーも使えます';
  static const guideStepBookP1 = 'ハンバーガーメニューから「書籍」を選択';
  static const guideStepBookP2 = '「＋ 書籍を追加」ボタンをタップ';
  static const guideStepBookP3 = 'タイトルを入力して追加';
  static const guideStepBookP4 = 'カレンダーアイコンで読書活動予定を設定';
  static const guideStepBookP5 = '読了時にチェックアイコンで要約・感想を記録';
  static const guideStepBookExample = '読書の進捗管理と振り返りに活用できます';
  static const guideStepStatsP1 = 'ハンバーガーメニューから「統計」を選択';
  static const guideStepStatsP2 = '期間（週・月・全期間）を切り替えて推移を確認';
  static const guideStepStatsP3 = '活動時間・活動日数・連続記録を把握';
  static const guideStepStatsExample =
      '定期的に振り返ることで、学習習慣を定着させましょう';
  static const guideStepConstellationP1 = 'ハンバーガーメニューから「星座」を選択';
  static const guideStepConstellationP2 = '夢ごとに割り当てられた星座を確認';
  static const guideStepConstellationP3 = '活動ログを記録して星を輝かせる';
  static const guideStepConstellationP4 =
      '完成した星座をタップすると説明が表示されます';
  static const guideStepConstellationExample =
      '活動の積み重ねが星座として可視化されます';

  // ── タスク発見ガイド ──────────────────────────────────────────
  static const taskEmptyTitle = 'どんなタスクを追加しますか？';
  static const taskEmptyAction = 'ガイドで見つける';
  static const taskTutorialGuideChoice = '目標を達成するための具体的なアクションを設定します。\nまだ決まっていない方は、ガイドが一緒に見つけるお手伝いをします。';
  static const taskTutorialSelfInput = '自分で入力する';
  static const taskDiscoveryTitle = 'タスク発見ガイド';
  static const taskDiscoveryGoalQuestion = 'どの目標に向けたタスクですか？';
  static const taskDiscoveryGoalDesc =
      '目標を達成するための具体的な行動を考えましょう。';
  static const taskDiscoveryNoGoals =
      '目標がまだありません。\n先に目標を作成してください。';
  static String taskDiscoveryThinkFor(String goalTitle) =>
      '「$goalTitle」を達成するための行動を考えましょう';
  static const taskDiscoveryTemplateTitle = 'テンプレートから選ぶ';
  static const taskDiscoveryTemplateDesc =
      'そのまま使っても、自分なりにアレンジしてもOKです。\n'
      '「自分で考える」場合はそのまま「次へ」を押してください。';
  static String taskDiscoverySuggestedDays(int days) => '推奨期間: $days日間';
  static const taskDiscoveryFormTitle = 'タスクを具体化しよう';
  static const taskDiscoveryFormName = 'タスク名';
  static const taskDiscoveryFormNameHint = '例: 参考書を1章読む';
  static const taskDiscoveryFormStartDate = '開始日';
  static const taskDiscoveryFormEndDate = '終了日';
  static String taskDiscoveryLinkedGoal(String title) => '紐づく目標: $title';
  static const taskDiscoveryCreate = 'タスクを作成';

  // ── 設定画面追加 ──────────────────────────────────────────
  static const settingsAchievementNotifDesc = '実績達成時に通知を表示';
  static const settingsReleaseNotesDesc = '新機能リリース時にお知らせを表示';
  static const settingsExportDesc = '夢・目標・タスク・書籍・活動ログ・通知をJSON形式でバックアップ';
  static const settingsImportRestoreDesc = 'バックアップから復元';
  static const settingsImportPremiumOnly = 'プレミアムプランで利用可能';
  static const settingsCloudRestoreConfirm =
      'クラウドに保存されたデータでローカルデータを上書きします。\n'
      '現在のローカルデータは失われます。\n\n'
      '復元しますか？';
  static const settingsRestoreButton = '復元する';
  static String settingsRestoreError(String error) => '復元に失敗しました: $error';
  static String settingsExportSuccess(String fileName) => '$fileNameを書き出しました';
  static String settingsExportError(String error) => '書き出しに失敗しました: $error';
  static const settingsImportUpgradeMsg = 'プレミアムプランにアップグレードしてご利用ください。';
  static const settingsImportOverwriteWarning = '既存データは全て上書きされます。';
  static String settingsImportCounts({
    required int dreams,
    required int goals,
    required int tasks,
    required int books,
    required int studyLogs,
    required int notifications,
  }) =>
      '夢: $dreams件\n目標: $goals件\nタスク: $tasks件\n書籍: $books件\n活動ログ: $studyLogs件\n通知: $notifications件';
  static String settingsImportResult({
    required int dreams,
    required int goals,
    required int tasks,
    required int books,
    required int logs,
  }) =>
      '${AppLabels.importComplete}: 夢$dreams件, 目標$goals件, タスク$tasks件, 書籍$books件, ログ$logs件';
  static const settingsDeleteConfirmMsg =
      'すべてのデータを削除します。\nこの操作は取り消せません。\n本当に削除しますか？';
  static const settingsDeleteSuccess = '全データを削除しました';
  static String settingsDeleteError(String error) => '削除に失敗しました: $error';
  static const settingsAppSubtitle = '夢実現支援アプリ';
  static const settingsUpgradeSection = 'プランのアップグレード';
  static String settingsInvitePlanDays(int days) => '招待プラン（残り$days日）';
  static const settingsPremiumPlanAuth = 'プレミアムプラン（認証）';
  static const settingsPremiumPlanNoAuth = 'プレミアムプラン（未認証）';
  static const settingsPremiumPlan = 'プレミアムプラン';
  static const settingsStarterPlan = 'スタータープラン';
  static const settingsAnonymousUser = '匿名ユーザー';
  static const settingsLinkEmailDesc = 'メール連携するとデータを安全に保護できます';
  static const settingsLinkEmailButton = 'メールアドレスを連携する';
  static const settingsInvitePlanSection = '招待プラン';
  static const settingsInviteActive = '招待プラン利用中';
  static const settingsInviteExpired = '招待プラン期限切れ';
  static String settingsInviteActiveDesc(String name, int days) =>
      '$name　残り$days日（全機能利用可能）';
  static const settingsInviteExpiredDesc =
      '有効期限が終了しました。'
      '有効期限が終了しました。'
      'プレミアムプランへのアップグレードで引き続き全機能をご利用いただけます。';

  // ── ホーム追加 ──────────────────────────────────────────
  static const dashTutorialMsg =
      'アプリの基本的な使い方を説明しますか？\n'
      '実際の操作を通じて、夢・目標・タスクの登録方法を体験できます。';
  static const dashEditReset = 'リセット';
  static const dashEditDone = '完了';
  static const dashEditWidgets = 'ウィジェット編集';
  static const dashCustomize = 'カスタマイズ';
  static const dashTodayStudied = '今日は活動済み!';
  static const dashTodayStart = '今日の活動を始めよう';
  static String dashTodayDetail(int hours, int minutes, int sessions) =>
      '$hours時間$minutes分 / $sessionsセッション';
  static const dashBookshelfLabel = '本棚';
  static String dashBookshelfCount(int completed, int total) =>
      '$completed/$total冊 読了';
  static const dashBookshelfEmpty = '読書を始めると本棚に並びます';
  static const dashPersonalRecordLabel = '自己ベスト';
  static const dashBestDay = '1日最高';
  static const dashBestWeek = '1週間最高';
  static const dashLongestStreak = '最長連続';
  static const dashConsistencyLabel = '活動の実施率';
  static String dashConsistencyDetail(int weekDays, int monthDays) =>
      '今週: $weekDays日 / 今月: $monthDays日';
  static String dashStreakSubtitle(int days) => '最長: $days日';
  static const dashActivityLabel = 'アクティビティ (30日)';
  static String dashConstellationProgress(int completed, int total) =>
      '$completed/$total 星座完成';
  static String dashUnreadCount(int count) => '$count件の未読';

  // ── 活動予定追加 ──────────────────────────────────────────
  static const ganttPremiumPoint1 = 'タスクの日程をタイムラインでビジュアル管理';
  static const ganttPremiumPoint2 = 'Excel書き出しでさらに活用・共有';
  static const ganttPremiumPoint3 = '読書活動予定を一元管理';
  static const ganttPremiumPoint4 = '目標別・書籍別のフィルタリング表示';
  static const ganttBookLabel = '書籍';
  static const ganttIndependentTask = '独立タスク';
  static const ganttEditTaskOption = 'タスクを編集';
  static const ganttRecordActivity = '活動時間を記録';
  static String ganttActivityTitle(String title) => '活動時間 - $title';
  static const ganttEditScheduleOption = '活動予定を編集';
  static const ganttRecordReading = '読書時間を記録';
  static const ganttViewAllTasks = '全タスク';
  static const ganttViewBooks = '書籍タスク';
  static String ganttDeleteConfirm(String title) => '「$title」を削除しますか？';
  static String ganttTrialLimitTask(int count) => 'タスク（この目標）';

  // ── 統計画面追加 ──────────────────────────────────────────
  static const statsPeriodDaily = '日';
  static const statsPeriodWeekly = '週';
  static const statsPeriodMonthly = '月';
  static const statsPeriodYearly = '年';
  static const statsGoalStatsPremiumName = '目標別統計';
  static const statsGoalStatsPremiumPoint1 = '目標ごとの活動時間・日数を詳細分析';
  static const statsGoalStatsPremiumPoint2 = 'タスク単位の時間内訳を確認';
  static const statsGoalStatsPremiumPoint3 = '読書ごとの進捗・時間を管理';
  static const statsActivityPremiumName = 'アクティビティチャート';
  static const statsActivityPremiumPoint1 = '日・週・月・年単位の活動推移をグラフ表示';
  static const statsActivityPremiumPoint2 = '活動の継続パターンを可視化';
  static const statsActivityPremiumPoint3 = 'モチベーション管理に最適';

  // ── Web体験版バナー ──────────────────────────────────────────
  static const webTrialInviteDesc = '全機能をご利用いただけます。';
  static String webTrialInviteDays(int days) => '残り$days日';
  static const webTrialUnlimitedDesc =
      '基本機能の制限は完全に解除されています。'
      '活動予定等のプレミアム機能はプレミアムプランをご利用ください。';
  static String webTrialLimitDesc(int level, int maxLevel, int dreams, int goals, int books) =>
      '夢$dreams個・目標$goals個・書籍$books冊まで'
      '（レベル$level / $maxLevel）。'
      '活動予定等のプレミアム機能はプレミアムプランをご利用ください。';
  static const webTrialDialogIntro =
      'このアプリはスタータープランです。デスクトップ版のインストール前に'
      '機能をお試しいただけます。';
  static const webTrialPrivacy =
      '完全匿名でご利用いただけます。\n'
      'ユーザー登録・ログインは不要です。入力したデータは全て'
      'お使いのブラウザ内にのみ保存され、開発者を含む第三者に'
      '送信・公開されることはありません。';
  static const webTrialCacheWarning =
      'ブラウザのキャッシュ/データを削除すると、'
      '全ての活動記録が消えます。';
  static const webTrialDeviceWarning =
      '別の端末や別のブラウザからアクセスすると、'
      'データは引き継がれません。\n'
      '(設定画面の書き出し/読み込み機能で移行可能)';
  static const webTrialLimitUnlocked = '制限は完全に解除されています。';
  static String webTrialLimitDetail(int level, int maxLevel, int dreams, int goals, int books) =>
      'スタータープランの登録上限（レベル$level / $maxLevel）: '
      '夢$dreams個、目標$goals個、書籍$books冊';
  static const webTrialUpgradeNote =
      'プレミアムプランにアップグレードすると、活動予定・'
      '高度な統計等のプレミアム機能も含め全機能を制限なくご利用いただけます。';
  static const webTrialSettingsNote = 'この情報は設定画面からいつでも確認できます。';

  // ── アプリの感想追加 ──────────────────────────────────────────
  static const feedbackThanksMessage = 'いつもご利用ありがとうございます。引き続きご意見をお聞かせください';
  static String feedbackUnlockNext(int nextLevel, int currentLevel, int maxLevel) =>
      '送信すると制限がレベル$nextLevelに解除されます'
      '（現在: レベル$currentLevel / $maxLevel）';
  static String feedbackRemainingChars(int remaining) => 'あと$remaining文字';
  static String feedbackCharCount(int count) => '$count文字';
  static const feedbackPrivacyNote =
      'アプリの感想は匿名で送信されます。'
      '個人を特定する情報は含まれません。';
  static const feedbackCategoryRequired = 'カテゴリの選択は必須です';
  static const feedbackSuccessMax = 'アプリの感想を送信しました。ありがとうございます！';
  static String feedbackSuccessUnlockMax(int _) => 'ありがとうございます！制限が完全に解除されました';
  static String feedbackSuccessUnlock(int newLevel) => 'ありがとうございます！制限がレベル$newLevelに解除されました';

  // ── 単位フォーマット ──────────────────────────────────────────
  static String unitDays(int count) => '$count日';
  static String unitDaysSlash(int days, int totalDays) => '$days / $totalDays 日';
  static String unitBooks(int count) => '$count冊';
  static String unitBooksSlash(int completed, int count) => '$completed/$count冊';
  static String unitHoursMinutes(int h, int m) {
    if (h > 0 && m > 0) return '$h時間$m分';
    if (h > 0) return '$h時間';
    return '$m分';
  }
  static String unitWeekStart(String date) => '$date〜';

  // ── お問い合わせ追加 ──────────────────────────────────────────
  static const inquiryDescription = '追加開発や案件のご相談など、お気軽にお問い合わせください';
  static const inquiryPrivacyNote =
      'メールアドレスはご返信のみに使用し、'
      '第三者に提供することはありません。';
  static const inquiryCategoryRequired = 'カテゴリの選択は必須です';

  // ── 実績（マイルストーン） ──────────────────────────────────
  static const milestoneTooltip = '実績';
  static const milestoneTitle = '実績';
  static const milestoneTotalHours = '累計活動時間';
  static const milestoneTotalDays = '累計活動日数';
  static const milestoneStreakDays = '連続活動日数';
  static const milestoneFirstGoal = '最初の実績を目指そう';
  static String milestoneNextGoal(String label) => '次の目標: $label';

  // ── 活動予定内部ラベル ──────────────────────────────────
  static const ganttHeaderGoal = '目標';
  static const weekDays = ['月', '火', '水', '木', '金', '土', '日'];

  // ── 目標ダイアログ追加 ──────────────────────────────────────
  static const validSelectDate = '日付を選択してください';
  static const validEnterPeriod = '期間を入力してください';
  static String goalDeleteConfirm(String title) =>
      '「$title」を削除しますか？\n紐づくタスクも削除されます。';
  static String dreamDeleteConfirm(String title) =>
      '「$title」を削除しますか？\n紐づく目標・タスクも削除されます。';

  // ── 星座ページ ──────────────────────────────────────────
  static String constellationDesc(int hoursPerStar) =>
      '活動時間に応じて星が灯り、星座が完成します。$hoursPerStar時間ごとに1つの星が輝きます。';
  static String constellationStarCount(int lit, int total) =>
      '　$lit/$total 星';
}
