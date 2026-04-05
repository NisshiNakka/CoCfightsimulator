require 'rails_helper'

RSpec.describe "Tutorials", type: :request do
  let(:user) { create(:user, tutorial_step: 2) }

  describe "PATCH /tutorial" do
    context '認証済みユーザーの場合' do
      before { sign_in user }

      context 'action_type=advance の場合' do
        it 'tutorial_step を 1 進めること' do
          expect {
            patch tutorial_path, params: { action_type: "advance" },
              as: :json
          }.to change { user.reload.tutorial_step }.from(2).to(3)
        end

        it '200 OK を返すこと' do
          patch tutorial_path, params: { action_type: "advance" },
            as: :json
          expect(response).to have_http_status(:ok)
        end
      end

      context 'action_type=dismiss の場合' do
        it 'tutorial_step を 0 にすること' do
          expect {
            patch tutorial_path, params: { action_type: "dismiss" },
              as: :json
          }.to change { user.reload.tutorial_step }.from(2).to(0)
        end

        it '200 OK を返すこと' do
          patch tutorial_path, params: { action_type: "dismiss" },
            as: :json
          expect(response).to have_http_status(:ok)
        end
      end

      context 'action_type が不正な値の場合' do
        it 'tutorial_step を変更しないこと' do
          expect {
            patch tutorial_path, params: { action_type: "invalid" },
              as: :json
          }.not_to change { user.reload.tutorial_step }
        end

        it '200 OK を返すこと' do
          patch tutorial_path, params: { action_type: "invalid" },
            as: :json
          expect(response).to have_http_status(:ok)
        end
      end

      context 'tutorial_step が最終ステップ(6)のとき advance した場合' do
        let(:user) { create(:user, tutorial_step: 6) }

        it 'tutorial_step が 0 にリセットされること' do
          expect {
            patch tutorial_path, params: { action_type: "advance" },
              as: :json
          }.to change { user.reload.tutorial_step }.from(6).to(0)
        end
      end

      context 'action_type=start_collection の場合' do
        let(:user) { create(:user, collection_tutorial_step: 0) }

        it 'collection_tutorial_step を 1 にすること' do
          expect {
            patch tutorial_path, params: { action_type: "start_collection" },
              as: :json
          }.to change { user.reload.collection_tutorial_step }.from(0).to(1)
        end

        it '200 OK を返すこと' do
          patch tutorial_path, params: { action_type: "start_collection" },
            as: :json
          expect(response).to have_http_status(:ok)
        end
      end

      context 'action_type=advance_collection の場合' do
        let(:user) { create(:user, collection_tutorial_step: 1) }

        it 'collection_tutorial_step を 1 進めること' do
          expect {
            patch tutorial_path, params: { action_type: "advance_collection" },
              as: :json
          }.to change { user.reload.collection_tutorial_step }.from(1).to(2)
        end

        it '200 OK を返すこと' do
          patch tutorial_path, params: { action_type: "advance_collection" },
            as: :json
          expect(response).to have_http_status(:ok)
        end
      end

      context 'action_type=advance_collection で最終ステップ(2)のとき' do
        let(:user) { create(:user, collection_tutorial_step: 2) }

        it 'collection_tutorial_step が 0 にリセットされること' do
          expect {
            patch tutorial_path, params: { action_type: "advance_collection" },
              as: :json
          }.to change { user.reload.collection_tutorial_step }.from(2).to(0)
        end
      end

      context 'action_type=dismiss_collection の場合' do
        let(:user) { create(:user, collection_tutorial_step: 1) }

        it 'collection_tutorial_step を 0 にすること' do
          expect {
            patch tutorial_path, params: { action_type: "dismiss_collection" },
              as: :json
          }.to change { user.reload.collection_tutorial_step }.from(1).to(0)
        end

        it '200 OK を返すこと' do
          patch tutorial_path, params: { action_type: "dismiss_collection" },
            as: :json
          expect(response).to have_http_status(:ok)
        end
      end
    end

    context '未認証ユーザーの場合' do
      it '401 を返すこと' do
        patch tutorial_path, params: { action_type: "advance" }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end

      it 'tutorial_step が変更されないこと' do
        patch tutorial_path, params: { action_type: "advance" },
          as: :json
        expect(user.reload.tutorial_step).to eq 2
      end
    end
  end
end
