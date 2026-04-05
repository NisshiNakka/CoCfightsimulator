require 'rails_helper'

RSpec.describe UserDiceUnlock, type: :model do
  let(:user) { create(:user) }

  describe 'バリデーション' do
    context '正常系' do
      it 'user と有効な dice_key があれば有効であること' do
        unlock = build(:user_dice_unlock, user: user, dice_key: User::COLLECTABLE_DICE_KEYS.first)
        expect(unlock).to be_valid
      end

      it 'すべての COLLECTABLE_DICE_KEYS が有効であること' do
        User::COLLECTABLE_DICE_KEYS.each do |key|
          unlock = build(:user_dice_unlock, user: user, dice_key: key)
          expect(unlock).to be_valid, "#{key} が無効と判定されました"
        end
      end
    end

    context '異常系' do
      it 'dice_key が空の場合、無効であること' do
        unlock = build(:user_dice_unlock, user: user, dice_key: nil)
        expect(unlock).to be_invalid
        expect(unlock.errors[:dice_key]).to be_present
      end

      it '許可リスト外の dice_key は無効であること' do
        unlock = build(:user_dice_unlock, user: user, dice_key: "invalid/key")
        expect(unlock).to be_invalid
        expect(unlock.errors[:dice_key]).to be_present
      end

      it '"defaults" は dice_key として無効であること' do
        unlock = build(:user_dice_unlock, user: user, dice_key: "defaults")
        expect(unlock).to be_invalid
      end

      it '"none" は dice_key として無効であること' do
        unlock = build(:user_dice_unlock, user: user, dice_key: "none")
        expect(unlock).to be_invalid
      end

      it '同じ user_id と dice_key の組み合わせは重複不可であること' do
        create(:user_dice_unlock, user: user, dice_key: "cat/cat_azuki_webp")
        duplicate = build(:user_dice_unlock, user: user, dice_key: "cat/cat_azuki_webp")
        expect(duplicate).to be_invalid
        expect(duplicate.errors[:dice_key]).to be_present
      end

      it '異なるユーザーが同じ dice_key を持つことは有効であること' do
        other_user = create(:user)
        create(:user_dice_unlock, user: user,       dice_key: "cat/cat_azuki_webp")
        unlock2    = build(:user_dice_unlock, user: other_user, dice_key: "cat/cat_azuki_webp")
        expect(unlock2).to be_valid
      end
    end
  end

  describe 'アソシエーション' do
    it 'user に belongs_to すること' do
      unlock = create(:user_dice_unlock, user: user)
      expect(unlock.user).to eq user
    end

    it 'user が削除されると関連する dice_unlock も削除されること' do
      create(:user_dice_unlock, user: user)
      expect { user.destroy }.to change(UserDiceUnlock, :count).by(-1)
    end
  end
end
