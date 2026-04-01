require 'rails_helper'

RSpec.describe "Users::OmniauthCallbacks", type: :request do
  # OmniAuth をテストモードに切り替えるヘルパー
  def mock_auth(uid: "123456789", email: "google_user@example.com", name: "Google User")
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: uid,
      info: { email: email, name: name }
    )
    Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:google_oauth2]
  end

  def reset_auth
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  after { reset_auth }

  describe "GET /users/auth/google_oauth2/callback" do
    context '初回 Google ログインの場合（新規ユーザー作成）' do
      before { mock_auth }

      it '新規ユーザーが作成されること' do
        expect {
          get user_google_oauth2_omniauth_callback_path
        }.to change(User, :count).by(1)
      end

      it 'tutorial_step が 1 に設定されること' do
        get user_google_oauth2_omniauth_callback_path
        user = User.find_by(provider: "google_oauth2", uid: "123456789")
        expect(user.tutorial_step).to eq 1
      end

      it 'ログイン後にリダイレクトされること' do
        get user_google_oauth2_omniauth_callback_path
        expect(response).to have_http_status(:redirect)
      end
    end

    context '既存の Google ユーザーが再ログインする場合' do
      let!(:existing_user) do
        create(:user, provider: "google_oauth2", uid: "123456789",
               email: "google_user@example.com", tutorial_step: 3)
      end

      before { mock_auth }

      it '新規ユーザーが作成されないこと' do
        expect {
          get user_google_oauth2_omniauth_callback_path
        }.not_to change(User, :count)
      end

      it 'tutorial_step が変更されないこと' do
        get user_google_oauth2_omniauth_callback_path
        expect(existing_user.reload.tutorial_step).to eq 3
      end

      it 'ログイン後にリダイレクトされること' do
        get user_google_oauth2_omniauth_callback_path
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'Google 認証が失敗した場合' do
      before do
        OmniAuth.config.test_mode = true
        OmniAuth.config.mock_auth[:google_oauth2] = :invalid_credentials
        Rails.application.env_config["omniauth.auth"] = nil
      end

      it 'ルートパスにリダイレクトされること' do
        get user_google_oauth2_omniauth_callback_path
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
