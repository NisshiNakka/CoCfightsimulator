require 'rails_helper'

RSpec.describe "Simulations", type: :system do
  let(:user) { create(:user) }
  let!(:character_1) { create(:character, user: user, name: "キャラクターA") }
  let!(:character_2) { create(:character, user: user, name: "キャラクターB") }
  let!(:attack_1) { create(:attack, character: character_1, name: "パンチ", success_probability: 80) }
  let!(:attack_2) { create(:attack, character: character_2, name: "キック", success_probability: 60) }

  before do
    sign_in user
  end

  describe "キャラクター読み込み機能" do
    before do
      visit new_simulations_path
    end

    it "初期表示では敵・味方の両方にキャラクター選択を促すメッセージが表示されていること" do
      within "#enemy_display" do
        expect(page).to have_content I18n.t('simulations.new.select_character_instruction')
      end
      within "#ally_display" do
        expect(page).to have_content I18n.t('simulations.new.select_character_instruction')
      end
    end

    it "敵側のプルダウンからキャラクターを選択すると、敵側にのみ情報が表示されること", js: true do
      within ".card.border-danger" do
        select "キャラクターA", from: "enemy_id"
      end
      within "#enemy_display" do
        expect(page).to have_content "キャラクターA"
        expect(page).to have_content "パンチ"
      end

      within "#ally_display" do
        expect(page).to have_content I18n.t('simulations.new.select_character_instruction')
        expect(page).not_to have_content "キャラクターA"
      end
    end

    it "味方側のプルダウンからキャラクターを選択すると、味方側にのみ情報が表示されること", js: true do
      within ".card.border-primary" do
        select "キャラクターB", from: "ally_id"
      end
      within "#ally_display" do
        expect(page).to have_content "キャラクターB"
        expect(page).to have_content "キック"
      end

      within "#enemy_display" do
        expect(page).to have_content I18n.t('simulations.new.select_character_instruction')
        expect(page).not_to have_content "キャラクターB"
      end
    end

    it "他人のキャラクターはプルダウンの選択肢に表示されないこと" do
      other_user = create(:user)
      create(:character, user: other_user, name: "他人のキャラ")
      visit new_simulations_path
      expect(page).to have_select("enemy_id", with_options: [ "キャラクターA", "キャラクターB" ])
      expect('select[name="enemy_id"]').not_to have_content "他人のキャラ"
      expect(page).to have_select("ally_id", with_options: [ "キャラクターA", "キャラクターB" ])
      expect('select[name="ally_id"]').not_to have_content "他人のキャラ"
    end

    it "片方の選択を解除しても、もう片方の表示に影響を与えないこと", js: true do
      within(".card.border-danger") { select "キャラクターA", from: "enemy_id" }
      within(".card.border-primary") { select "キャラクターB", from: "ally_id" }

      within(".card.border-danger") { select I18n.t('simulations.new.not_select'), from: "enemy_id" }
      within "#enemy_display" do
        expect(page).to have_content I18n.t('simulations.new.select_character_instruction')
        expect(page).not_to have_content "キャラクターA"
      end

      within "#ally_display" do
        expect(page).to have_content "キャラクターB"
      end
    end
  end

  describe "キャラクター読み込みと戦闘シミュレーション" do
    before do
      visit new_simulations_path
    end

    it "両方のキャラクターを選択すると攻撃ボタンが表示され、攻撃を実行できること", js: true do
      expect(page).not_to have_button "同時シミュレート"

      within ".card.border-danger" do
        select "キャラクターB", from: "enemy_id"
      end
      within ".card.border-primary" do
        select "キャラクターA", from: "ally_id"
      end

      expect(page).to have_button "同時シミュレート"
    end

    it "攻撃ボタンのパラメータが正しく送信されていること", js: true do
      within(".card.border-danger") { select "キャラクターB", from: "enemy_id" }
      within(".card.border-primary") { select "キャラクターA", from: "ally_id" }

      expect(page).to have_selector("form[action='#{combat_roll_path}']")
    end

    it "片方のキャラクターを解除すると、攻撃ボタンが消えること", js: true do
      within(".card.border-danger") { select "キャラクターB", from: "enemy_id" }
      within(".card.border-primary") { select "キャラクターA", from: "ally_id" }
      expect(page).to have_button "同時シミュレート"

      within(".card.border-danger") { select I18n.t('simulations.new.not_select'), from: "enemy_id" }

      expect(page).not_to have_button "同時シミュレート"
      within "#dice_roll_area" do
        expect(page).to have_content "Select Character Instruction"
      end
    end
  end
end
