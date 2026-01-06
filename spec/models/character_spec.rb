require 'rails_helper'

RSpec.describe Character, type: :model do
  let(:user) { build(:user) }
  let(:character) { build(:character) }

  describe 'Validation' do
    context '正常系' do
      it '全ての属性が正しく入力されていれば有効であること' do
        expect(character).to be_valid
      end
    end

    context '異常系: name' do
      it '名前が空であれば無効であること' do
        character.name = nil
        character.valid?
        expect(character.errors[:name]).to include("を入力してください")
      end

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
      end
    end

    context 'アソシエーション' do
      it 'userに属していること' do
        expect(Character.reflect_on_association(:user).macro).to eq :belongs_to
      end
    end
  end
end
