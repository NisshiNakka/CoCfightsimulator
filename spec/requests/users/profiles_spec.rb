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

      it "ダイスを保存ボタンが表示されること" do
        get profile_path
        expect(response.body).to include(I18n.t('users.profiles.show.save_dice'))
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

  describe "PATCH /profile" do
    context "未ログインの場合" do
      it "ログインページへリダイレクトされること" do
        patch profile_path, params: { user: { site_icon: "defaults" } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "ログイン済みの場合" do
      let(:user) { create(:user) }
      before { sign_in user }

      context "有効な値の場合" do
        it "site_icon を更新してプロフィールへリダイレクトすること" do
          patch profile_path, params: { user: { site_icon: "cat/cat_azuki_webp" } }
          expect(response).to redirect_to(profile_path)
          expect(user.reload.site_icon).to eq "cat/cat_azuki_webp"
        end

        it '"defaults" を選択したとき更新されること' do
          patch profile_path, params: { user: { site_icon: "defaults" } }
          expect(response).to redirect_to(profile_path)
          expect(user.reload.site_icon).to eq "defaults"
        end

        it '"none"（表示しない）を選択したとき更新されること' do
          patch profile_path, params: { user: { site_icon: "none" } }
          expect(response).to redirect_to(profile_path)
          expect(user.reload.site_icon).to eq "none"
        end
      end

      context "無効な値の場合" do
        it "許可リスト外の値では 422 を返すこと" do
          patch profile_path, params: { user: { site_icon: "../../etc/passwd" } }
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "空文字列では 422 を返すこと" do
          patch profile_path, params: { user: { site_icon: "" } }
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "無効な場合 site_icon は更新されないこと" do
          original_icon = user.site_icon
          patch profile_path, params: { user: { site_icon: "invalid/value" } }
          expect(user.reload.site_icon).to eq original_icon
        end
      end
    end
  end
end
