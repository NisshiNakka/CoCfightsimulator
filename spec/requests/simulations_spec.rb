require 'rails_helper'

RSpec.describe "Simulations", type: :request do
  describe "GET /simulations/new（チュートリアル進行）" do
    let(:user) { create(:user) }
    before { sign_in user }

    context 'tutorial_step が 4 のとき' do
      let(:user) { create(:user, tutorial_step: 4) }

      it '/simulations/new へのアクセスで tutorial_step が 5 に進むこと' do
        expect {
          get new_simulations_path
        }.to change { user.reload.tutorial_step }.from(4).to(5)
      end
    end

    context 'tutorial_step が 4 以外のとき' do
      let(:user) { create(:user, tutorial_step: 5) }

      it 'tutorial_step が変化しないこと' do
        expect {
          get new_simulations_path
        }.not_to change { user.reload.tutorial_step }
      end
    end

    context 'キャラクター選択パラメータつきのアクセス（step=4）のとき' do
      let(:user) { create(:user, tutorial_step: 4) }
      let!(:character) { create(:character, user: user) }

      it 'tutorial_step が 5 に進むこと' do
        expect {
          get new_simulations_path, params: { enemy_id: character.id }
        }.to change { user.reload.tutorial_step }.from(4).to(5)
      end
    end

    context 'キャラクター選択パラメータつきのアクセス（step=5）のとき' do
      let(:user) { create(:user, tutorial_step: 5) }
      let!(:character) { create(:character, user: user) }

      it 'tutorial_step が変化しないこと' do
        expect {
          get new_simulations_path, params: { enemy_id: character.id }
        }.not_to change { user.reload.tutorial_step }
      end
    end
  end

  describe "POST /combat_roll（チュートリアル進行）" do
    # advance_tutorial! はセッション読み取りより先に実行されるため、
    # セッション設定・BattleCoordinator スタブは不要
    before { sign_in user }

    context 'tutorial_step が 5 のとき' do
      let(:user) { create(:user, tutorial_step: 5) }

      it 'combat_roll 実行で tutorial_step が 6 に進むこと' do
        expect {
          post combat_roll_path, as: :turbo_stream
        }.to change { user.reload.tutorial_step }.from(5).to(6)
      end
    end

    context 'tutorial_step が 5 以外のとき' do
      let(:user) { create(:user, tutorial_step: 4) }

      it 'tutorial_step が変化しないこと' do
        expect {
          post combat_roll_path, as: :turbo_stream
        }.not_to change { user.reload.tutorial_step }
      end
    end

    context 'tutorial_step が 0（チュートリアル非表示）のとき' do
      let(:user) { create(:user, tutorial_step: 0) }

      it 'tutorial_step が変化しないこと' do
        expect {
          post combat_roll_path, as: :turbo_stream
        }.not_to change { user.reload.tutorial_step }
      end
    end
  end
end
