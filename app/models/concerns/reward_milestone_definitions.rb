module RewardMilestoneDefinitions
  DEFINITIONS = {
    # === 初回利用（8枚） ===
    "first_registration"     => { description: "ユーザー登録",           category: :first_use },
    "first_profile_view"     => { description: "プロフィール確認",       category: :first_use },
    "first_dice_update"      => { description: "ダイスコレクション更新", category: :first_use },
    "first_character_create" => { description: "キャラクター登録",       category: :first_use },
    "first_character_index"  => { description: "キャラクター一覧表示",   category: :first_use },
    "first_character_show"   => { description: "キャラクター閲覧",       category: :first_use },
    "first_character_edit"   => { description: "キャラクター編集",       category: :first_use },
    "first_simulation"       => { description: "シミュレーション実行",   category: :first_use },

    # === 累積マイルストーン（14枚） ===
    "characters_3"   => { description: "キャラクターを3体作成",      category: :milestone, counter: :characters_count,      threshold: 3 },
    "characters_5"   => { description: "キャラクターを5体作成",      category: :milestone, counter: :characters_count,      threshold: 5 },
    "characters_10"  => { description: "キャラクターを10体作成",     category: :milestone, counter: :characters_count,      threshold: 10 },
    "simulations_3"  => { description: "シミュレーションを3回実行",  category: :milestone, counter: :simulations_count,     threshold: 3 },
    "simulations_5"  => { description: "シミュレーションを5回実行",  category: :milestone, counter: :simulations_count,     threshold: 5 },
    "simulations_10" => { description: "シミュレーションを10回実行", category: :milestone, counter: :simulations_count,     threshold: 10 },
    "simulations_20" => { description: "シミュレーションを20回実行", category: :milestone, counter: :simulations_count,     threshold: 20 },
    "simulations_30" => { description: "シミュレーションを30回実行", category: :milestone, counter: :simulations_count,     threshold: 30 },
    "simulations_40" => { description: "シミュレーションを40回実行", category: :milestone, counter: :simulations_count,     threshold: 40 },
    "simulations_50" => { description: "シミュレーションを50回実行", category: :milestone, counter: :simulations_count,     threshold: 50 },
    "edits_3"        => { description: "キャラクターを3回編集",      category: :milestone, counter: :character_edits_count, threshold: 3 },
    "edits_5"        => { description: "キャラクターを5回編集",      category: :milestone, counter: :character_edits_count, threshold: 5 },
    "dice_updates_3" => { description: "ダイスを3回更新",            category: :milestone, counter: :dice_updates_count,    threshold: 3 },
    "dice_updates_5" => { description: "ダイスを5回更新",            category: :milestone, counter: :dice_updates_count,    threshold: 5 }
  }.freeze
end
