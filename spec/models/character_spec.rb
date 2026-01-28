require 'rails_helper'

RSpec.describe Character, type: :model do
  let(:character) { build(:character) }

  describe 'Validation' do
    context '正常系' do
      it '全ての属性が正しく入力されていれば有効であること' do
        expect(character).to be_valid
      end
    end

    context '異常形: 必須入力' do
      it 'nameが空であれば無効であること' do
        character.name = nil
        character.valid?
        expect(character.errors[:name]).to include("を入力してください")
      end

      it 'hitpointが空であれば無効であること' do
        character.hitpoint = nil
        character.valid?
        expect(character.errors[:hitpoint]).to include("を入力してください")
      end

      it 'dexterityが空であれば無効であること' do
        character.dexterity = nil
        character.valid?
        expect(character.errors[:dexterity]).to include("を入力してください")
      end

      it 'evasion_rateが空であれば無効であること' do
        character.evasion_rate = nil
        character.valid?
        expect(character.errors[:evasion_rate]).to include("を入力してください")
      end

      it 'evasion_correctionが空であれば無効であること' do
        character.evasion_correction = nil
        character.valid?
        expect(character.errors[:evasion_correction]).to include("を入力してください")
      end

      it 'armorが空であれば無効であること' do
        character.armor = nil
        character.valid?
        expect(character.errors[:armor]).to include("を入力してください")
      end

      it 'damage_bonusが空であれば無効であること' do
        character.damage_bonus = nil
        character.valid?
        expect(character.errors[:damage_bonus]).to include("を入力してください")
      end
    end

    context '異常系: 整数バリデーション' do
      it 'hitpointが小数であれば無効であること' do
        character.hitpoint = 50.5
        character.valid?
        expect(character.errors[:hitpoint]).to include("は整数で入力してください")
      end

      it 'dexterityが小数であれば無効であること' do
        character.dexterity = 100.5
        character.valid?
        expect(character.errors[:dexterity]).to include("は整数で入力してください")
      end

      it 'evasion_rateが小数であれば無効であること' do
        character.evasion_rate = 50.5
        character.valid?
        expect(character.errors[:evasion_rate]).to include("は整数で入力してください")
      end

      it 'evasion_correctionが小数であれば無効であること' do
        character.evasion_correction = 5.5
        character.valid?
        expect(character.errors[:evasion_correction]).to include("は整数で入力してください")
      end

      it 'armorが小数であれば無効であること' do
        character.armor = 10.5
        character.valid?
        expect(character.errors[:armor]).to include("は整数で入力してください")
      end
    end

    context '異常系: 名前' do
      it '名前が51文字以上であれば無効であること' do
        character.name = 'a' * 51
        character.valid?
        expect(character.errors[:name]).to include("は50文字以内で入力してください")
      end
    end

    context '異常系: 数値バリデーション' do
      it 'hitpointが範囲外(0)であれば無効であること' do
        character.hitpoint = 0
        character.valid?
        expect(character.errors[:hitpoint]).to include("は1..100の範囲に含めてください")
      end

      it 'hitpointが範囲外(101)であれば無効であること' do
        character.hitpoint = 101
        character.valid?
        expect(character.errors[:hitpoint]).to include("は1..100の範囲に含めてください")
      end

      it 'dexterityが範囲外(0)であれば無効であること' do
        character.dexterity = 0
        character.valid?
        expect(character.errors[:dexterity]).to include("は1..200の範囲に含めてください")
      end

      it 'dexterityが範囲外(201)であれば無効であること' do
        character.dexterity = 201
        character.valid?
        expect(character.errors[:dexterity]).to include("は1..200の範囲に含めてください")
      end

      it 'evasion_correctionが範囲外(-11)であれば無効であること' do
        character.evasion_correction = -11
        character.valid?
        expect(character.errors[:evasion_correction]).to include("は-10..10の範囲に含めてください")
      end

      it 'evasion_rateが範囲外(0)であれば無効であること' do
        character.evasion_rate = 0
        character.valid?
        expect(character.errors[:evasion_rate]).to include("は1..100の範囲に含めてください")
      end

      it 'evasion_rateが範囲外(101)であれば無効であること' do
        character.evasion_rate = 101
        character.valid?
        expect(character.errors[:evasion_rate]).to include("は1..100の範囲に含めてください")
      end

      it 'evasion_correctionが範囲外(11)であれば無効であること' do
        character.evasion_correction = 11
        character.valid?
        expect(character.errors[:evasion_correction]).to include("は-10..10の範囲に含めてください")
      end

      it 'armorが負の数であれば無効であること' do
        character.armor = -1
        character.valid?
        expect(character.errors[:armor]).to include("は0..20の範囲に含めてください")
      end

      it 'armorが範囲外(21)であれば無効であること' do
        character.armor = 21
        character.valid?
        expect(character.errors[:armor]).to include("は0..20の範囲に含めてください")
      end
    end

    context 'damage_bonus (正規表現)' do
      context '正常形' do
        it '正しい形式（1d6）であれば有効であること' do
          character.damage_bonus = '1d6'
          expect(character).to be_valid
        end

        it '固定値（3）であれば有効であること' do
          character.damage_bonus = '3'
          expect(character).to be_valid
        end

        it '負の値から始まる形式（-1d6）であれば有効であること' do
          character.damage_bonus = '-1d6'
          expect(character).to be_valid
        end

        it '固定値付きの形式（1D6+1）であれば有効であること' do
          character.damage_bonus = '1d6+1'
          expect(character).to be_valid
        end

        it '符号の後に計算式が連なる形式（1D6+1d3）であれば有効であること' do
          character.damage_bonus = '1d6+1d3'
          expect(character).to be_valid
        end
      end

      context '異常形' do
        it '不正な形式の文字列（例: abc）であれば無効であること' do
          character.damage_bonus = 'abc'
          character.valid?
          expect(character.errors[:damage_bonus]).to include("は正しいダイスロール記法で入力してください（例: 1, 1d6, 1d6+1d3, 1d6-1d3）")
        end

        it 'damage_bonusが16文字以上であれば無効であること' do
          character.damage_bonus = '1' * 16
          character.valid?
          expect(character.errors[:damage_bonus]).to include("は15文字以内で入力してください")
        end
      end
    end

    context 'アソシエーション' do
      it 'userに属していること' do
        expect(Character.reflect_on_association(:user).macro).to eq :belongs_to
      end
    end
  end

  describe 'ビジネスロジックのテスト' do
    let(:character) { create(:character, hitpoint: 15, armor: 2, evasion_rate: 40, evasion_correction: 0) }

    describe '#evasion_roll' do
      it 'BCDiceの実行結果オブジェクト（DiceRollResult等）を返すこと' do
        result = character.evasion_roll('r')

        expect(result).to respond_to(:success?)
        expect(result).to respond_to(:text)
        expect(result.text).to include('ボーナス・ペナルティダイス[0]')
      end
    end

    describe '#hp_calculation' do
      context 'ダメージ結果が正しく渡された場合' do
        it '装甲（armor）を差し引いたダメージ分、HPが減り、正しい計算結果ハッシュを返すこと' do
          damage_result = double('DiceRollResult', text: '1d6+1d4 ＞ 6+2 ＞ 8')

          # 計算式:
          # damage_value = 8
          # effective_damage = [0, 8 - 2].max = 6
          # remaining_hp = 15 - 6 = 9
          result = character.hp_calculation(damage_result, character.hitpoint)

          expect(result[:hp]).to eq 9
          expect(result[:damage]).to eq 6
        end

        it 'ダメージが装甲以下の場合はダメージ0として計算され、HPが減らないこと' do
          damage_result = double('DiceRollResult', text: '1d4 ＞ 1')

          # 計算式:
          # damage_value = 1
          # effective_damage = [0, 1 - 2].max = 0
          # remaining_hp = 15 - 0 = 15
          result = character.hp_calculation(damage_result, character.hitpoint)

          expect(result[:hp]).to eq 15
          expect(result[:damage]).to eq 0
        end
      end
    end
  end
end
