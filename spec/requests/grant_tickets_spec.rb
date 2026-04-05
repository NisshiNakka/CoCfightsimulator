require 'rails_helper'

# ApplicationController#grant_tickets の抑制条件（any_tutorial_active?）のテスト
# チュートリアル中（既存 or コレクション）は特典券の付与通知が抑制されることを確認する
RSpec.describe "GrantTickets（特典券付与の抑制）", type: :request do
  describe "プロフィール画面（grant_tickets が呼ばれる例）" do
    context '既存チュートリアル中（tutorial_step > 0）の場合' do
      let(:user) { create(:user, tutorial_step: 1, collection_tutorial_step: 0) }
      before { sign_in user }

      it '特典券が付与されないこと' do
        expect {
          get profile_path
        }.not_to change { user.reload.reward_tickets }
      end

      it 'フラッシュに reward_ticket_granted が設定されないこと' do
        get profile_path
        expect(flash[:reward_ticket_granted]).to be_nil
      end
    end

    context 'コレクションチュートリアル中（collection_tutorial_step > 0）の場合' do
      let(:user) { create(:user, tutorial_step: 0, collection_tutorial_step: 1) }
      before { sign_in user }

      it '特典券が付与されないこと' do
        expect {
          get profile_path
        }.not_to change { user.reload.reward_tickets }
      end

      it 'フラッシュに reward_ticket_granted が設定されないこと' do
        get profile_path
        expect(flash[:reward_ticket_granted]).to be_nil
      end
    end

    context '両方のチュートリアルが完了済み（両方とも 0）の場合' do
      let(:user) { create(:user, tutorial_step: 0, collection_tutorial_step: 0) }
      before { sign_in user }

      it '初回アクセス時に特典券が付与されること' do
        expect {
          get profile_path
        }.to change { user.reload.reward_tickets }.by(1)
      end

      it 'フラッシュに reward_ticket_granted が設定されること' do
        get profile_path
        expect(flash[:reward_ticket_granted]).to eq 1
      end
    end
  end
end
