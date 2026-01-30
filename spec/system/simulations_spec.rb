require 'rails_helper'

RSpec.describe "Simulations", type: :system do
  include DiceRollable
  let(:user) { create(:user) }
  # DEX差をつけてソートを確認（味方: 60, 敵: 40）
  let!(:ally) { create(:quick_character, user: user, name: "味方戦士") }
  let!(:enemy) { create(:slow_character, user: user, name: "敵モンスター") }
  let!(:enemy_attack) { create(:attack, character: enemy, name: "噛みつき") }
  let!(:ally_attack) { create(:attack, character: ally, name: "剣攻撃") }

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

        expect(page).to have_button I18n.t('simulations.start_simulation.start'), wait: 5

        within ".card.border-danger" do
          select I18n.t('simulations.new.not_select'), from: "enemy_id"
        end

        expect(page).not_to have_button "同時シミュレート"
        expect(page).to have_content I18n.t('simulations.new.select_character_instruction')
      end
    end

    context "戦闘結果の表示" do
      before do
        within ".card.border-danger" do
          select "敵モンスター", from: "enemy_id"
        end
        within ".card.border-primary" do
          select "味方戦士", from: "ally_id"
        end

        expect(page).to have_button I18n.t('simulations.start_simulation.start'), wait: 5
      end

      it "シミュレートボタンを押すと戦闘結果がTurbo Streamで表示されること" do
        allow(BattleProcessor).to receive(:call).and_wrap_original do |method, attacker, defender, attack, target_hp|
          if attacker == ally
            { status: :hit, remaining_hp: 0, final_damage: 20, attack_text: "成功" }
          else
            { status: :failed, attack_text: "失敗", remaining_hp: ally.hitpoint }
          end
        end

        click_button I18n.t('simulations.start_simulation.start')
        expect(page).to have_selector "#dice_result .card", wait: 10

        within "#dice_result" do
          aggregate_failures "表示内容の検証" do
            expect(page).to have_content "勝利"
            expect(page).to have_content I18n.t('simulations.combat_roll.final_hp')
            expect(page).to have_content I18n.t('simulations.combat_roll.title')
            expect(page).to have_content "1 #{I18n.t('simulations.combat_roll.turn')}"
          end
        end
      end

      it "20ターン経過した際に引き分け結果が表示されること" do
        allow(BattleProcessor).to receive(:call).and_wrap_original do |method, attacker, defender, attack, target_hp|
          if attacker == ally
            { status: :failed, attack_text: "失敗", remaining_hp: enemy.hitpoint }
          else
            { status: :failed, attack_text: "失敗", remaining_hp: ally.hitpoint }
          end
        end

        click_button I18n.t('simulations.start_simulation.start')

        expect(page).to have_content I18n.t('simulations.combat_roll.draw'), wait: 10
        expect(page).to have_content I18n.t('simulations.combat_roll.finish_turn_suffix', finish_turn: 20)
      end

      it "戦闘結果のアコーディオンを開閉して詳細ログを確認できること" do
        click_button I18n.t('simulations.start_simulation.start')

        expect(page).to have_selector "button", text: "1 #{I18n.t('simulations.combat_roll.turn')}"

        within "#dice_result" do
          expect(page).to have_selector ".alert"
          expect(page).to have_content "攻撃"
        end
      end

      it "一度シミュレートした後にHPがセッションに保存され、継続して戦えること" do
        click_button I18n.t('simulations.start_simulation.start'), wait: 10
        expect(page).to have_selector "#dice_result", wait: 10
      end
    end
  end
end
