require 'rails_helper'

RSpec.describe BattleCoordinator, type: :service do
  let(:ally) { create(:character, name: "味方", dexterity: 60, hitpoint: 20) }
  let(:enemy) { create(:character, name: "敵", dexterity: 40, hitpoint: 20) }
  let(:ally_attack) { create(:attack, character: ally) }
  let(:enemy_attack) { create(:attack, character: enemy) }
  let(:ally_hp) { 20 }
  let(:enemy_hp) { 20 }

  describe '.call' do
    subject(:result) do
      BattleCoordinator.call(ally, enemy, ally_attack, enemy_attack, ally_hp, enemy_hp)
    end

    context '味方のDEXが敵より高い場合' do
      it '味方が先制攻撃を行うこと' do
        allow(BattleProcessor).to receive(:call).and_return(
          { status: :failed, attack_text: "失敗", remaining_hp: 20 }
        )

        expect(result[:results].first[:side]).to eq :ally
      end
    end

    context '敵のHPが2以下になった場合' do
      it '戦闘が終了し、味方が勝利すること' do
        # 敵のHPを2にする
        allow(BattleProcessor).to receive(:call)
          .with(ally, enemy, ally_attack, 20)
          .and_return(
            { status: :hit, remaining_hp: 2, final_damage: 18, attack_text: "成功" }
          )

        allow(BattleProcessor).to receive(:call)
          .with(enemy, ally, enemy_attack, 20)
          .and_return(
            { status: :failed, attack_text: "失敗", remaining_hp: 20 }
          )

        expect(result[:battle_ended]).to be true
        expect(result[:decision][:side]).to eq :ally
        expect(result[:decision][:side]).not_to eq :enemy
        expect(result[:decision][:winner]).to eq ally
        expect(result[:determination]).to eq :fainting
      end
    end

    context '20ターンが経過した場合' do
      it '20ターンで強制終了し、引き分け判定になること' do
        allow(BattleProcessor).to receive(:call).and_return(
          { status: :failed, attack_text: "失敗", remaining_hp: 20 }
        )

        expect(result[:finish_turn]).to eq 20
        expect(result[:decision][:side]).to eq :draw
      end
    end

    context 'HPが0以下（死亡状態）で決着がついた場合' do
      it '判定（determination）が :death になること' do
        allow(BattleProcessor).to receive(:call).and_return(
          { status: :hit, remaining_hp: 0, final_damage: 20, attack_text: "成功" }
        )

        expect(result[:decision][:side]).to eq :ally
        expect(result[:determination]).to eq :death
      end
    end

    context '引数で現在のHPが渡された場合' do
      let(:ally_hp) { 10 }
      let(:enemy_hp) { 5 }

      it '渡されたHPから戦闘が開始されること' do
        # BattleProcessor が呼ばれる際の引数をチェックする
        # 第4引数が target_hp として渡されているはず
        allow(BattleProcessor).to receive(:call).with(ally, enemy, ally_attack, 5).and_return(
          { status: :failed, attack_text: "失敗", remaining_hp: 5 }
        )
        allow(BattleProcessor).to receive(:call).with(enemy, ally, enemy_attack, 10).and_return(
          { status: :failed, attack_text: "失敗", remaining_hp: 10 }
        )

        expect(result[:final_hp][:ally]).to eq 10
        expect(result[:final_hp][:enemy]).to eq 5
      end
    end
  end
end
