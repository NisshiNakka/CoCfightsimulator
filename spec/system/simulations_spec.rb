require 'rails_helper'

RSpec.describe "Simulations", type: :system do
  include DiceRollable
  let(:user) { create(:user) }
  # DEX差をつけてソートを確認（味方: 60, 敵: 40）
  let!(:ally) { create(:character, user: user, name: "味方戦士", dexterity: 60, hitpoint: 20) }
  let!(:enemy) { create(:character, user: user, name: "敵モンスター", dexterity: 40, hitpoint: 20) }
  let!(:ally_attack) { create(:attack, character: ally, name: "剣攻撃", success_probability: 100) }
  let!(:enemy_attack) { create(:attack, character: enemy, name: "噛みつき", success_probability: 100) }

  before do
    sign_in user
    visit new_simulations_path
  end

  describe "キャラクター読み込み機能" do
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
        select "敵モンスター", from: "enemy_id"
      end
      within "#enemy_display" do
        expect(page).to have_content "敵モンスター"
        expect(page).to have_content "噛みつき"
      end

      within "#ally_display" do
        expect(page).to have_content I18n.t('simulations.new.select_character_instruction')
        expect(page).not_to have_content "敵モンスター"
      end
    end

    it "味方側のプルダウンからキャラクターを選択すると、味方側にのみ情報が表示されること", js: true do
      within ".card.border-primary" do
        select "味方戦士", from: "ally_id"
      end
      within "#ally_display" do
        expect(page).to have_content "味方戦士"
        expect(page).to have_content "剣攻撃"
      end

      within "#enemy_display" do
        expect(page).to have_content I18n.t('simulations.new.select_character_instruction')
        expect(page).not_to have_content "味方戦士"
      end
    end

    it "他人のキャラクターはプルダウンの選択肢に表示されないこと" do
      other_user = create(:user)
      create(:character, user: other_user, name: "他人のキャラ")
      visit new_simulations_path
      expect(page).to have_select("enemy_id", with_options: [ "敵モンスター", "味方戦士" ])
      expect('select[name="enemy_id"]').not_to have_content "他人のキャラ"
      expect(page).to have_select("ally_id", with_options: [ "敵モンスター", "味方戦士" ])
      expect('select[name="ally_id"]').not_to have_content "他人のキャラ"
    end

    it "片方の選択を解除しても、もう片方の表示に影響を与えないこと", js: true do
      within(".card.border-danger") { select "敵モンスター", from: "enemy_id" }
      within(".card.border-primary") { select "味方戦士", from: "ally_id" }

      within(".card.border-danger") { select I18n.t('simulations.new.not_select'), from: "enemy_id" }
      within "#enemy_display" do
        expect(page).to have_content I18n.t('simulations.new.select_character_instruction')
        expect(page).not_to have_content "敵モンスター"
      end

      within "#ally_display" do
        expect(page).to have_content "味方戦士"
      end
    end
  end

  describe "同時シミュレート機能", js: true do
    context "キャラクター選択とボタン表示" do
      it "両方のキャラクターを選択すると同時シミュレートボタンが表示され、解除すると消えること" do
        expect(page).not_to have_button "同時シミュレート"

        within ".card.border-danger" do
          select "敵モンスター", from: "enemy_id"
        end
        within ".card.border-primary" do
          select "味方戦士", from: "ally_id"
        end

        expect(page).to have_button "同時シミュレート", wait: 5

        within ".card.border-danger" do
          select I18n.t('simulations.new.not_select'), from: "enemy_id"
        end

        expect(page).not_to have_button "同時シミュレート"
        expect(page).to have_content I18n.t('simulations.new.select_character_instruction')
      end
    end

    context "同時シミュレートの実行" do
      before do
        within ".card.border-danger" do
          select "敵モンスター", from: "enemy_id"
        end
        within ".card.border-primary" do
          select "味方戦士", from: "ally_id"
        end

        expect(page).to have_button "同時シミュレート", wait: 5
      end

      it "ボタンを押すと、DEX順に攻撃結果が表示されること" do
        click_button "同時シミュレート"
        expect(page).to have_selector ".alert", minimum: 2, wait: 10

        within "#dice_result" do
          aggregate_failures "結果の表示順と内容の検証" do
            results = all(".alert")
            expect(results[0].text).to include "味方戦士"
            expect(results[1].text).to include "敵モンスター"

            expect(page).to have_content "味方戦士の攻撃"
            expect(page).to have_content "敵モンスターの攻撃"
          end
        end
      end

      it "攻撃が命中した場合、ダメージと残りHPが表示されること" do
        click_button "同時シミュレート"

        expect(page).to have_selector ".alert", wait: 10
        aggregate_failures do
          expect(page).to have_content "味方戦士"
          expect(page).to have_content "HP"
          expect(page).to have_content "ダメージ"
        end
      end
    end
  end
end
