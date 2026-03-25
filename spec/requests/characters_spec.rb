require 'rails_helper'

RSpec.describe "Characters", type: :request do
  let(:valid_params) do
    {
      character: {
        name: "テストキャラ",
        hitpoint: 10,
        dexterity: 50,
        evasion_rate: 30,
        evasion_correction: 0,
        armor: 0,
        damage_bonus: "1d3",
        attack_attributes: {
          name: "パンチ",
          success_probability: 50,
          dice_correction: 0,
          damage: "1d6",
          attack_range: "proximity"
        }
      }
    }
  end

  describe "GET /characters/new（チュートリアル進行）" do
    context '認証済みユーザーの場合' do
      context 'tutorial_step が 2 のとき' do
        let(:user) { create(:user, tutorial_step: 2) }
        before { sign_in user }

        it '/characters/new へのアクセスで tutorial_step が 3 に進むこと' do
          expect {
            get new_character_path
          }.to change { user.reload.tutorial_step }.from(2).to(3)
        end
      end

      context 'tutorial_step が 2 以外のとき' do
        let(:user) { create(:user, tutorial_step: 1) }
        before { sign_in user }

        it 'tutorial_step が変化しないこと' do
          expect {
            get new_character_path
          }.not_to change { user.reload.tutorial_step }
        end
      end
    end
  end

  describe "POST /characters（チュートリアル進行）" do
    context '認証済みユーザーの場合' do
      context 'tutorial_step が 1 のとき' do
        let(:user) { create(:user, tutorial_step: 1) }
        before { sign_in user }

        it 'キャラクター作成成功で tutorial_step が 2 に進むこと' do
          expect {
            post characters_path, params: valid_params
          }.to change { user.reload.tutorial_step }.from(1).to(2)
        end
      end

      context 'tutorial_step が 3 のとき' do
        let(:user) { create(:user, tutorial_step: 3) }
        before { sign_in user }

        it 'キャラクター作成成功で tutorial_step が 4 に進むこと' do
          expect {
            post characters_path, params: valid_params
          }.to change { user.reload.tutorial_step }.from(3).to(4)
        end
      end

      context 'tutorial_step が 1 でも 3 でもないとき' do
        let(:user) { create(:user, tutorial_step: 2) }
        before { sign_in user }

        it 'キャラクター作成しても tutorial_step が変化しないこと' do
          expect {
            post characters_path, params: valid_params
          }.not_to change { user.reload.tutorial_step }
        end
      end

      context 'tutorial_step が 0（チュートリアル非表示）のとき' do
        let(:user) { create(:user, tutorial_step: 0) }
        before { sign_in user }

        it 'tutorial_step が変化しないこと' do
          expect {
            post characters_path, params: valid_params
          }.not_to change { user.reload.tutorial_step }
        end
      end

      context 'キャラクター作成が失敗した場合' do
        let(:user) { create(:user, tutorial_step: 1) }
        before { sign_in user }

        it 'tutorial_step が変化しないこと' do
          invalid_params = valid_params.deep_merge(character: { name: "" })
          expect {
            post characters_path, params: invalid_params
          }.not_to change { user.reload.tutorial_step }
        end
      end
    end
  end
end
