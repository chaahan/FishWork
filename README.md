# FishyWalk: 水槽歩数計アプリ 導入ガイド

iPadの「Swift Playgrounds」でこのアプリを動かすための手順です。

## 1. 準備
1. iPadにApp Storeから **Swift Playgrounds** をインストールします。
2. アプリを開き、「マイ App」の横にある「＋」ボタンを押し、「App」を新規作成します。

## 2. コードの貼り付け
以下のファイルを、Swift Playgrounds内の対応する場所にコピー＆ペーストしてください。
（最初は `ContentView.swift` というファイルがあるはずなので、それを `AquariumView.swift` の内容で書き換えてもOKです）

### ファイルリスト（すべて同じ場所に並べてください）
- **ContentView.swift**: メイン画面と魚の表示（元からある ContentView の中身を書き換えます）
- **AquariumViewModel.swift**: 魚の出現・維持ロジック
- **FishGoal.swift**: 魚と目標のデータ定義
- **HealthStoreManager.swift**: ヘルスケア（歩数）データの取得

## 3. ヘルスケアの許可設定
Swift Playgroundsでアプリを実行すると、「ヘルスケアデータへのアクセス」を求める画面が表示されます。
「歩数」の読み取りを許可してください。

## 4. 使い方
- 画面全体が水槽です。歩数が増えると、条件を満たした魚が自動的に現れます。
- 右上のアイコンを押すと、現在の目標リストと達成状況を確認できます。
- 毎日24時を過ぎてアプリを開くと、昨日の歩数が「維持目標」に届かなかった魚は水槽からいなくなります。

## 5. カスタマイズ
`AquariumViewModel.swift` の `setupInitialGoals()` メソッドの中身を書き換えることで、新しい魚や目標を追加できます。
100個まで増やすことも可能です！
