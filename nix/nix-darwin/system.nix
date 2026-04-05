{
  ...
}:
{
  # キーボードのリマップ設定を定義する
  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true; # Caps Lock を Control に変更
  };

  # macOS のシステム設定を変更する
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark"; # ダークモードを有効にする
      InitialKeyRepeat = 15; # キーリピート開始までの待機時間を最短に設定する
      KeyRepeat = 2; # キーリピートの速度を最速に設定する
      NSAutomaticCapitalizationEnabled = false; # 文頭の自動大文字化を無効化
      NSAutomaticPeriodSubstitutionEnabled = false; # ピリオドの自動置換を無効化
      NSAutomaticSpellingCorrectionEnabled = false; # スペル自動修正を無効化
      NSAutomaticDashSubstitutionEnabled = false; # ダッシュの自動置換を無効化
      NSAutomaticQuoteSubstitutionEnabled = false; # クォートの自動置換を無効化する
    };

    finder = {
      AppleShowAllExtensions = true; # ファイルの拡張子を常に表示する
      AppleShowAllFiles = true; # 隠しファイルを表示する
      ShowPathbar = true; # パスバーを表示する
      ShowStatusBar = true; # ステータスバーを表示する
    };

    dock = {
      autohide = true; # Dock を自動的に隠す
      mru-spaces = false; # 操作スペースを自動で並べ替えない
      show-recents = false; # 最近使ったアプリを表示しない
    };

    screencapture = {
      target = "clipboard"; # スクリーンショットの保存先をクリップボードに設定する
      disable-shadow = true; # スクリーンショットの影を無効化する
    };
  };
}
