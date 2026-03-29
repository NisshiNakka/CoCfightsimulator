require 'rails_helper'

RSpec.describe "ローディングアニメーション", type: :system do
  let(:user) { create(:user) }
  let!(:ally)  { create(:quick_character, user: user, name: "味方戦士") }
  let!(:enemy) { create(:slow_character,  user: user, name: "敵モンスター") }

  before { sign_in user }

  describe "ローディングオーバーレイの存在" do
    it "全ページのレイアウトにローディングオーバーレイ要素が存在すること" do
      visit new_simulations_path
      expect(page).to have_selector(".loading-overlay", visible: :all),
        "loading-overlay 要素がレイアウトに存在しません"
    end

    it "初期状態ではローディングオーバーレイが非表示であること" do
      visit new_simulations_path
      expect(page).not_to have_selector(".loading-overlay.loading-overlay--visible"),
        "ページ読み込み直後にオーバーレイが表示されています"
    end

    it "スピナー要素がオーバーレイ内に存在すること" do
      visit new_simulations_path
      within(".loading-overlay") do
        expect(page).to have_selector(".spinner-border", visible: :all),
          "spinner-border 要素がオーバーレイ内に存在しません"
      end
    end
  end

  describe "シミュレーション実行時のローディング表示", js: true do
    before do
      visit new_simulations_path
      within(".card.border-danger") { select "敵モンスター", from: "enemy_id" }
      within(".card.border-primary") { select "味方戦士",   from: "ally_id" }
      expect(page).to have_button I18n.t("simulations.start_simulation.start"), wait: 5
    end

    it "シミュレーションボタンを押した後、結果が表示されること（ローディング完了後）" do
      click_button I18n.t("simulations.start_simulation.start")
      # ローディング完了後に結果が描画されることを確認
      expect(page).to have_selector("#dice_result .card", wait: 15),
        "ローディング後にシミュレーション結果が表示されませんでした"
    end

    it "シミュレーション結果表示後にローディングオーバーレイが非表示になること" do
      click_button I18n.t("simulations.start_simulation.start")
      expect(page).to have_selector("#dice_result .card", wait: 15)

      # MIN_DISPLAY_MS (400ms) 経過後にオーバーレイが消えていることを確認
      expect(page).not_to have_selector(".loading-overlay.loading-overlay--visible", wait: 3),
        "シミュレーション完了後もオーバーレイが表示されたままです"
    end

    # combat_roll では turbo:before-fetch-request と turbo:submit-start の両方が発火するため
    # show() が2回呼ばれる。show() 冒頭で前回の showDelayTimer をキャンセルすることで
    # 孤立タイマーによる永久表示を防いでいることを確認する
    it "combat_roll 実行後にローディングオーバーレイが永久表示にならないこと" do
      click_button I18n.t("simulations.start_simulation.start")
      expect(page).to have_selector("#dice_result .card", wait: 15)

      # 結果表示から十分な時間（MIN_DISPLAY_MS + バッファ）が経過してもオーバーレイが消えていること
      expect(page).not_to have_selector(".loading-overlay.loading-overlay--visible", wait: 5),
        "show() の二重呼び出しによる孤立タイマーでオーバーレイが永久表示になっています"
    end
  end

  describe "ページ遷移時のローディング", js: true do
    it "ページ遷移後に正しいページが表示され、オーバーレイが非表示になること" do
      visit characters_path
      click_on I18n.t("defaults.go_simulation")
      expect(page).to have_current_path(new_simulations_path, ignore_query: true), wait: 5
      expect(page).not_to have_selector(".loading-overlay.loading-overlay--visible", wait: 3),
        "ページ遷移完了後もオーバーレイが表示されたままです"
    end
  end

  describe "キャラクター登録フォーム送信時のローディング", js: true do
    before { visit new_character_path }

    it "キャラクター登録後に結果ページが表示され、オーバーレイが非表示になること" do
      fill_in "character_name",       with: "ローディングテスト用キャラ"
      fill_in "character_hitpoint",   with: 10
      fill_in "character_dexterity",  with: 50
      fill_in "character_evasion_rate",   with: 20
      fill_in "character_evasion_correction", with: 0
      fill_in "character_armor",      with: 0
      fill_in "character_damage_bonus", with: "1d4"
      fill_in "character_attack_attributes_name",               with: "テスト技能"
      fill_in "character_attack_attributes_success_probability", with: 50
      fill_in "character_attack_attributes_dice_correction",    with: 0
      fill_in "character_attack_attributes_damage",             with: "1d6"
      click_button I18n.t("characters.form.character_create")

      expect(page).to have_content(
        I18n.t("defaults.flash_message.created", item: Character.model_name.human), wait: 10
      )
      expect(page).not_to have_selector(".loading-overlay.loading-overlay--visible", wait: 3),
        "キャラクター登録完了後もオーバーレイが表示されたままです"
    end
  end
end
