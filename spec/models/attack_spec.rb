require 'rails_helper'

RSpec.describe Attack, type: :model do
  describe 'バリデーション確認' do
    let(:attack) { build(:attack) }

    it '有効な属性値の場合は有効であること' do
      expect(attack).to be_valid
    end

    describe '名前(name)' do
      it '空の場合は無効であること' do
        attack.name = nil
        expect(attack).to be_invalid
        expect(attack.errors[:name]).to include("を入力してください")
      end

      it '25文字を超える場合は無効であること' do
        attack.name = 'a' * 26
        expect(attack).to be_invalid
        expect(attack.errors[:name]).to include("は25文字以内で入力してください")
      end
    end

    describe '成功確率(success_probability)' do
      it '空の場合は無効であること' do
        attack.success_probability = nil
        expect(attack).to be_invalid
        expect(attack.errors[:success_probability]).to include("を入力してください")
      end

      it '1から100の範囲外（0以下）の場合は無効であること' do
        attack.success_probability = 0
        expect(attack).to be_invalid
        expect(attack.errors[:success_probability]).to include("は1..100の範囲に含めてください")
      end

      it '1から100の範囲外（101以上）の場合は無効であること' do
        attack.success_probability = 101
        expect(attack).to be_invalid
        expect(attack.errors[:success_probability]).to include("は1..100の範囲に含めてください")
      end

      it '整数でない場合は無効であること' do
        attack.success_probability = 50.5
        expect(attack).to be_invalid
        expect(attack.errors[:success_probability]).to include("は整数で入力してください")
      end
    end

    describe 'ダイス補正(dice_correction)' do
      it '空の場合は無効であること' do
        attack.dice_correction = nil
        expect(attack).to be_invalid
        expect(attack.errors[:dice_correction]).to include("を入力してください")
      end

      it '-10から10の範囲外（-11以下）の場合は無効であること' do
        attack.dice_correction = -11
        expect(attack).to be_invalid
        expect(attack.errors[:dice_correction]).to include("は-10..10の範囲に含めてください")
      end

      it '-10から10の範囲外（11以上）の場合は無効であること' do
        attack.dice_correction = 11
        expect(attack).to be_invalid
        expect(attack.errors[:dice_correction]).to include("は-10..10の範囲に含めてください")
      end
    end

    describe 'ダメージ(damage)' do
      it '空の場合は無効であること' do
        attack.damage = nil
        expect(attack).to be_invalid
        expect(attack.errors[:damage]).to include("を入力してください")
      end

      it '15文字を超える場合は無効であること' do
        attack.damage = '1' * 16
        expect(attack).to be_invalid
        expect(attack.errors[:damage]).to include("は15文字以内で入力してください")
      end

      context 'フォーマット確認' do
        it '正しいダイスロール記法（数値のみ）の場合は有効であること' do
          attack.damage = "10"
          expect(attack).to be_valid
        end

        it '正しいダイスロール記法（1d6）の場合は有効であること' do
          attack.damage = "1d6"
          expect(attack).to be_valid
        end

        it '正しいダイスロール記法（複合）の場合は有効であること' do
          attack.damage = "1d6+1d3-2"
          expect(attack).to be_valid
        end

        it '不正な記法（文字が含まれる）の場合は無効であること' do
          attack.damage = "1d6+invalid"
          expect(attack).to be_invalid
          expect(attack.errors[:damage]).to include("は正しいダイスロール記法で入力してください（例: 1, 1d6, 1d6+1d3, 1d6-1d3）")
        end

        it '負のダイスロールの場合は無効であること' do
          attack.damage = "-1d6"
          expect(attack).to be_invalid
          expect(attack.errors[:damage]).to include("は正しいダイスロール記法で入力してください（例: 1, 1d6, 1d6+1d3, 1d6-1d3）")
        end
      end
    end

    describe '射程(attack_range)' do
      it '空の場合は無効であること' do
        attack.attack_range = nil
        expect(attack).to be_invalid
        expect(attack.errors[:attack_range]).to include("を入力してください")
      end
    end
  end

  describe '列挙型(enum)確認' do
    it 'proximity(1) と ranged(2) が定義されていること' do
      expect(Attack.attack_ranges[:proximity]).to eq 1
      expect(Attack.attack_ranges[:ranged]).to eq 2
    end
  end

  describe 'アソシエーション確認' do
    it 'Characterに属していること' do
      association = described_class.reflect_on_association(:character)
      expect(association.macro).to eq :belongs_to
    end
  end
end
