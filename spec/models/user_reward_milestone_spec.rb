require 'rails_helper'

RSpec.describe UserRewardMilestone, type: :model do
  let(:user) { create(:user) }

  describe 'バリデーション' do
    context '正常系' do
      it 'user と milestone_key があれば有効であること' do
        # after_create で first_registration は既に作成済みのため別のキーを使用
        milestone = build(:user_reward_milestone, user: user, milestone_key: "first_simulation")
        expect(milestone).to be_valid
      end

      it 'DEFINITIONS に定義されたすべてのキーが有効であること' do
        allow(RewardTicketGranter).to receive(:call)  # after_create を無効化し、新規登録時のマイルストーン付与を防止
        RewardMilestoneDefinitions::DEFINITIONS.keys.each_with_index do |key, i|
          other_user = create(:user)
          milestone = build(:user_reward_milestone, user: other_user, milestone_key: key)
          expect(milestone).to be_valid, "#{key} が無効と判定されました"
        end
      end
    end

    context '異常系' do
      it 'milestone_key が空の場合、無効であること' do
        milestone = build(:user_reward_milestone, user: user, milestone_key: nil)
        expect(milestone).to be_invalid
        expect(milestone.errors[:milestone_key]).to be_present
      end

      it '同じ user_id と milestone_key の組み合わせは重複不可であること' do
        # after_create で first_registration は既に作成済み
        duplicate = build(:user_reward_milestone, user: user, milestone_key: "first_registration")
        expect(duplicate).to be_invalid
        expect(duplicate.errors[:milestone_key]).to be_present
      end

      it '異なるユーザーが同じ milestone_key を持つことは有効であること' do
        other_user = create(:user)
        # 両ユーザーとも after_create で first_registration が作成済みなので
        # first_simulation を使ってテスト
        create(:user_reward_milestone, user: user,       milestone_key: "first_simulation")
        milestone2 = build(:user_reward_milestone, user: other_user, milestone_key: "first_simulation")
        expect(milestone2).to be_valid
      end
    end
  end

  describe 'アソシエーション' do
    it 'user に belongs_to すること' do
      milestone = create(:user_reward_milestone, user: user, milestone_key: "first_simulation")
      expect(milestone.user).to eq user
    end

    it 'user が削除されると関連する reward_milestone も削除されること' do
      initial_count = UserRewardMilestone.count
      user.destroy
      expect(UserRewardMilestone.count).to be initial_count
    end
  end
end
