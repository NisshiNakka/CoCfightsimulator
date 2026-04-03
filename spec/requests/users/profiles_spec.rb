require 'rails_helper'

RSpec.describe "Users::Profiles", type: :request do
  describe "GET /profile" do
    context "未ログインの場合" do
      it "ログインページへリダイレクトされること" do
        get profile_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "ログイン済みの場合" do
      let(:user) { create(:user) }
      before { sign_in user }

      it "200 OK を返すこと" do
        get profile_path
        expect(response).to have_http_status(:ok)
      end

      it "ユーザー名が表示されること" do
        get profile_path
        expect(response.body).to include(user.name)
      end

      it "メールアドレスが表示されること" do
        get profile_path
        expect(response.body).to include(user.email)
      end

      it "ダイスコレクションセクションが表示されること" do
        get profile_path
        expect(response.body).to include(I18n.t('users.profiles.show.dice_collection'))
      end

      it "ユーザー情報を編集するリンクが表示されること" do
        get profile_path
        expect(response.body).to include(edit_user_registration_path)
      end

      it "トップページへのリンクが表示されること" do
        get profile_path
        expect(response.body).to include(root_path)
      end
    end
  end
end
