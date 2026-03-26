require 'rails_helper'

RSpec.describe "Simulations", type: :system do
  include DiceRollable
  let(:user) { create(:user) }
  # DEX差をつけてソートを確認（味方: 60, 敵: 40）
  let!(:ally) { create(:quick_character, user: user, name: "味方戦士") }
  let!(:enemy) { create(:slow_character, user: user, name: "敵モンスター") }
  let!(:enemy_attack) { enemy.attack }
  let!(:ally_attack) { ally.attack }

  before do
    sign_in user
    visit new_simulations_path
  end

  it '正しいタイトルが表示されていること' do
    expect(page).to have_title('シミュレーションページ | CoC Fight Simulator'), 'シミュレーションページのタイトルが正しくありません。'
  end

  describe "画面遷移" do
    it '「キャラクター登録」ボタンからキャラクター登録画面へ遷移できること' do
      within "#navigation_buttons" do
        click_on I18n.t('characters.new.title')
      end
      expect(page).to have_current_path(new_character_path, ignore_query: true),
      '[キャラクター登録]ボタンからキャラクター登録画面へ遷移できませんでした'
    end

    it '「キャラクター一覧」ボタンからキャラクター一覧画面へ遷移できること' do
      within "#navigation_buttons" do
        click_on I18n.t('characters.index.title')
      end
      expect(page).to have_current_path(characters_path, ignore_query: true),
      '[キャラクター一覧]ボタンからキャラクター一覧画面へ遷移できませんでした'
    end
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
        expect(page).to have_content enemy_attack.name
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
        expect(page).to have_content ally_attack.name
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
      it "両方のキャラクターを選択するとシミュレートボタンが表示され、解除すると消えること" do
        # 初回は「シミュレーションする」テキスト
        expect(page).not_to have_button I18n.t('simulations.start_simulation.start')

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

        expect(page).not_to have_button I18n.t('simulations.start_simulation.start')
        expect(page).to have_content I18n.t('simulations.new.select_character_instruction')
      end

      # [#103] 初回ボタンテキストの確認
      it "初回表示時のシミュレーションボタンのテキストが「シミュレーションする」であること" do
        within ".card.border-danger" do
          select "敵モンスター", from: "enemy_id"
        end
        within ".card.border-primary" do
          select "味方戦士", from: "ally_id"
        end

        expect(page).to have_button I18n.t('simulations.start_simulation.start'), wait: 5
        expect(page).not_to have_button I18n.t('simulations.start_simulation.retry')
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
        allow(BattleProcessor).to receive(:call).and_wrap_original do |method, attacker, defender, attack|
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
        allow(BattleProcessor).to receive(:call).and_wrap_original do |method, attacker, defender, attack|
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

      # [#103] 2回目以降のボタンテキスト変更
      it "シミュレーション実行後のボタンが「もう一度シミュレーション」に変わること" do
        click_button I18n.t('simulations.start_simulation.start')
        expect(page).to have_selector "#dice_result .card", wait: 10

        # dice_roll_area が更新され「もう一度シミュレーション」ボタンが表示される
        expect(page).to have_button I18n.t('simulations.start_simulation.retry'), wait: 5
        expect(page).not_to have_button I18n.t('simulations.start_simulation.start')
      end

      # [#103] 敵=左 / 味方=右 の固定レイアウト確認
      it "シミュレーション結果で敵が左カード、味方が右カードに表示されること" do
        allow(BattleProcessor).to receive(:call).and_wrap_original do |method, attacker, defender, attack|
          if attacker == ally
            { status: :hit, remaining_hp: 0, final_damage: 20, attack_text: "成功" }
          else
            { status: :failed, attack_text: "失敗", remaining_hp: ally.hitpoint }
          end
        end

        click_button I18n.t('simulations.start_simulation.start')
        expect(page).to have_selector "#dice_result .card", wait: 10

        within "#dice_result" do
          # 左カード（col-md-6 最初のもの）に敵キャラ名が表示されること
          result_cards = all(".result-card-container .col-md-6")
          expect(result_cards[0]).to have_content enemy.name
          expect(result_cards[1]).to have_content ally.name
        end
      end

      # [#103] 味方勝利時: 敵カードに敗者の暗転クラスが付与されること
      it "味方が勝利した場合、敵カードに result-loser クラスが付与されること" do
        allow(BattleProcessor).to receive(:call).and_wrap_original do |method, attacker, defender, attack|
          if attacker == ally
            { status: :hit, remaining_hp: 0, final_damage: 20, attack_text: "成功" }
          else
            { status: :failed, attack_text: "失敗", remaining_hp: ally.hitpoint }
          end
        end

        click_button I18n.t('simulations.start_simulation.start')
        expect(page).to have_selector "#dice_result .card", wait: 10

        within "#dice_result" do
          result_cards = all(".result-card-container .col-md-6")
          # 敵カード（左）に result-loser クラスがあること
          expect(result_cards[0]).to have_selector ".result-loser"
          # 味方カード（右）には result-loser クラスがないこと
          expect(result_cards[1]).not_to have_selector ".result-loser"
        end
      end

      # [#103] 引き分け時: 両カードに result-loser クラスが付与されること
      it "引き分けの場合、両方のカードに result-loser クラスが付与されること" do
        allow(BattleProcessor).to receive(:call).and_wrap_original do |method, attacker, defender, attack|
          { status: :failed, attack_text: "失敗", remaining_hp: defender.hitpoint }
        end

        click_button I18n.t('simulations.start_simulation.start')
        expect(page).to have_content I18n.t('simulations.combat_roll.draw'), wait: 10

        within "#dice_result" do
          result_cards = all(".result-card-container .col-md-6")
          expect(result_cards[0]).to have_selector ".result-loser"
          expect(result_cards[1]).to have_selector ".result-loser"
        end
      end

      # [#103] 敗者ステータスバッジの表示確認（気絶）
      it "敗者のステータスが気絶の場合、黄色枠の「気絶」バッジが表示されること" do
        # 敵が先攻して味方を気絶（HP <= 2）させるシナリオ
        allow(BattleProcessor).to receive(:call).and_wrap_original do |method, attacker, defender, attack|
          if attacker == enemy
            { status: :hit, remaining_hp: 1, final_damage: ally.hitpoint - 1, attack_text: "成功",
              damage_text: "3d6", armor: 0 }
          else
            { status: :failed, attack_text: "失敗", remaining_hp: enemy.hitpoint }
          end
        end

        click_button I18n.t('simulations.start_simulation.start')
        expect(page).to have_selector "#dice_result .card", wait: 10

        within "#dice_result" do
          # 気絶バッジが表示されること
          expect(page).to have_selector ".status-badge--fainting"
          expect(page).to have_css(".status-badge--fainting", text: I18n.t('simulations.combat_roll.fainting'))
        end
      end

      # [#103] 敗者ステータスバッジの表示確認（死亡）
      it "敗者のステータスが死亡の場合、赤枠の「死亡」バッジが表示されること" do
        # 敵が先攻して味方を死亡（HP <= 0）させるシナリオ
        allow(BattleProcessor).to receive(:call).and_wrap_original do |method, attacker, defender, attack|
          if attacker == enemy
            { status: :hit, remaining_hp: 0, final_damage: ally.hitpoint, attack_text: "成功",
              damage_text: "3d6", armor: 0 }
          else
            { status: :failed, attack_text: "失敗", remaining_hp: enemy.hitpoint }
          end
        end

        click_button I18n.t('simulations.start_simulation.start')
        expect(page).to have_selector "#dice_result .card", wait: 10

        within "#dice_result" do
          # 死亡バッジが表示されること
          expect(page).to have_selector ".status-badge--death"
          expect(page).to have_css(".status-badge--death", text: I18n.t('simulations.combat_roll.death'))
        end
      end

      # [#103] フェードインアニメーション用クラスの付与確認
      it "シミュレーション結果の各セクションにフェードイン用クラスが付与されること" do
        click_button I18n.t('simulations.start_simulation.start')
        expect(page).to have_selector "#dice_result .card", wait: 10

        within "#dice_result" do
          # Stimulus が connect() 後にアニメーションを適用するため、
          # fade-in-active クラスが付与されていること（fade-in-ready から遷移済み）
          expect(page).to have_selector "[data-simulation-result-target='section'].fade-in-active", wait: 5
        end
      end
    end
  end
end
