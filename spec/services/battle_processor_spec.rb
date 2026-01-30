require 'rails_helper'

RSpec.describe BattleProcessor, type: :service do
  let(:attacker) { create(:character, name: "攻撃者", dexterity: 50, damage_bonus: "1d4") }
  let(:defender) { create(:character, name: "防御者", armor: 2, hitpoint: 15) }
  let(:use_attack) { create(:attack, character: attacker, success_probability: 50, damage: "1d6") }

  describe '.call' do
    context '攻撃が失敗した場合' do
      it 'ステータス failed を返し、回避判定が行われないこと' do
        fail_result = double('DiceResult', success?: false, text: '判定結果: 失敗')
        allow(use_attack).to receive(:attack_roll).and_return(fail_result)

        result = BattleProcessor.call(attacker, defender, use_attack, defender.hitpoint)

        expect(result[:status]).to eq :failed
        expect(result[:success]).to be false
        expect(result[:attack_text]).to eq '判定結果: 失敗'
        expect(result[:attacker_name]).to eq "攻撃者"
        expect(result[:defender_name]).to eq "防御者"
        expect(result[:dexterity]).to eq 50

        expect(result).not_to have_key(:evasion_text)
        expect(result).not_to have_key(:damage_text)
      end

      it '回避判定が行われないこと' do
        fail_result = double('DiceResult', success?: false, text: '判定結果: 失敗')
        allow(use_attack).to receive(:attack_roll).and_return(fail_result)

        expect(defender).not_to receive(:evasion_roll)

        BattleProcessor.call(attacker, defender, use_attack, defender.hitpoint)
      end
    end

    context '攻撃が成功し、防御者が回避に成功した場合' do
      it 'ステータス evaded を返すこと' do
        success_result = double('AttackResult', success?: true, text: '判定結果: 成功')
        allow(use_attack).to receive(:attack_roll).and_return(success_result)
        allow(use_attack).to receive(:success_correction).and_return('r')

        evade_result = double('EvasionResult', success?: true, text: '回避成功')
        allow(defender).to receive(:evasion_roll).and_return(evade_result)

        result = BattleProcessor.call(attacker, defender, use_attack, defender.hitpoint)

        expect(result[:status]).to eq :evaded
        expect(result[:success]).to be true
        expect(result[:evasion_text]).to eq '回避成功'

        expect(result).not_to have_key(:damage_text)
      end

      it 'ダメージ計算が行われないこと' do
        success_result = double('AttackResult', success?: true, text: '判定結果: 成功')
        allow(use_attack).to receive(:attack_roll).and_return(success_result)
        allow(use_attack).to receive(:success_correction).and_return('r')

        evade_result = double('EvasionResult', success?: true, text: '回避成功')
        allow(defender).to receive(:evasion_roll).and_return(evade_result)

        expect(use_attack).not_to receive(:damage_roll)
      end
    end

    context '攻撃が成功し、防御者が回避に失敗した場合' do
      let(:success_result) { double('AttackResult', success?: true, text: '攻撃成功') }
      let(:evade_fail) { double('EvasionResult', success?: false, text: '回避失敗') }
      let(:damage_result) { double('DamageResult', text: '6') }

      before do
        allow(use_attack).to receive(:attack_roll).and_return(success_result)
        allow(use_attack).to receive(:success_correction).and_return('r')
        allow(defender).to receive(:evasion_roll).and_return(evade_fail)
        allow(use_attack).to receive(:damage_roll).and_return(damage_result)
        allow(defender).to receive(:hp_calculation).and_return({ hp: 11, damage: 4 })
      end

      it 'ステータス hit を返し、ダメージと残りHPが計算されること' do
        result = BattleProcessor.call(attacker, defender, use_attack, defender.hitpoint)

        expect(result[:status]).to eq :hit
        expect(result[:remaining_hp]).to eq 11
        expect(result[:final_damage]).to eq 4
        expect(result[:armor]).to eq 2
        expect(result[:evasion_text]).to eq '回避失敗'
        expect(result[:damage_text]).to eq '6'
      end

      it '攻撃ロールが呼ばれること' do
        expect(use_attack).to receive(:attack_roll).and_return(success_result)
        BattleProcessor.call(attacker, defender, use_attack, defender.hitpoint)
      end

      it '成功補正が正しく計算されること' do
        expect(use_attack).to receive(:success_correction).with(success_result).and_return('r')
        BattleProcessor.call(attacker, defender, use_attack, defender.hitpoint)
      end

      it '回避ロールが正しい補正値で呼ばれること' do
        expect(defender).to receive(:evasion_roll).with('r').and_return(evade_fail)
        BattleProcessor.call(attacker, defender, use_attack, defender.hitpoint)
      end

      it 'ダメージロールが攻撃者のダメージボーナスで呼ばれること' do
        expect(use_attack).to receive(:damage_roll).with("1d4").and_return(damage_result)
        BattleProcessor.call(attacker, defender, use_attack, defender.hitpoint)
      end

      it 'HP計算が正しく呼ばれること' do
        expect(defender).to receive(:hp_calculation).with(damage_result, defender.hitpoint).and_return({ hp: 11, damage: 6 })
        BattleProcessor.call(attacker, defender, use_attack, defender.hitpoint)
      end
    end
  end
end
