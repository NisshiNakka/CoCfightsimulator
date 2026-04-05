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

      it "first_profile_view マイルストーンが付与されること" do
        expect { get profile_path }.to change { user.reload.reward_milestones.count }.by(1)
      end

      it "2回目のアクセスではマイルストーンが重複付与されないこと" do
        get profile_path
        expect { get profile_path }.not_to change { user.reload.reward_milestones.count }
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

      context "特殊アイコン（常時選択可能）の場合" do
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

      context "解放済みダイスを選択する場合" do
        before do
          create(:user_dice_unlock, user: user, dice_key: "cat/cat_azuki_webp")
        end

        it "site_icon を更新してプロフィールへリダイレクトすること" do
          patch profile_path, params: { user: { site_icon: "cat/cat_azuki_webp" } }
          expect(response).to redirect_to(profile_path)
          expect(user.reload.site_icon).to eq "cat/cat_azuki_webp"
        end

        it "dice_updates_count が 1 増加すること" do
          expect {
            patch profile_path, params: { user: { site_icon: "cat/cat_azuki_webp" } }
          }.to change { user.reload.dice_updates_count }.by(1)
        end

        it "first_dice_update マイルストーンが付与されること" do
          expect {
            patch profile_path, params: { user: { site_icon: "cat/cat_azuki_webp" } }
          }.to change { user.reward_milestones.reload.count }.by(1)
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

        it "未解放のダイスを選択した場合は 422 を返すこと" do
          patch profile_path, params: { user: { site_icon: "cat/cat_azuki_webp" } }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  describe "POST /profile/use_ticket" do
    context "未ログインの場合" do
      it "ログインページへリダイレクトされること" do
        post use_ticket_profile_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "ログイン済みの場合" do
      let(:user) { create(:user) }
      before { sign_in user }

      context "チケットがあり、未収集ダイスがある場合" do
        before { user.update!(reward_tickets: 3) }

        it "ダイスが解放されること" do
          expect {
            post use_ticket_profile_path, headers: { "Accept" => "text/vnd.turbo-stream.html" }
          }.to change { user.dice_unlocks.count }.by(1)
        end

        it "reward_tickets が 1 減少すること" do
          expect {
            post use_ticket_profile_path, headers: { "Accept" => "text/vnd.turbo-stream.html" }
          }.to change { user.reload.reward_tickets }.by(-1)
        end

        it "Turbo Stream で 200 OK を返すこと" do
          post use_ticket_profile_path, headers: { "Accept" => "text/vnd.turbo-stream.html" }
          expect(response).to have_http_status(:ok)
        end

        it "解放されたダイスが COLLECTABLE_DICE_KEYS に含まれること" do
          post use_ticket_profile_path, headers: { "Accept" => "text/vnd.turbo-stream.html" }
          expect(User::COLLECTABLE_DICE_KEYS).to include(user.dice_unlocks.last.dice_key)
        end
      end

      context "チケットがない場合" do
        before { user.update!(reward_tickets: 0) }

        it "プロフィールページへリダイレクトされること" do
          post use_ticket_profile_path
          expect(response).to redirect_to(profile_path)
        end

        it "ダイスが解放されないこと" do
          expect {
            post use_ticket_profile_path
          }.not_to change { user.dice_unlocks.count }
        end
      end

      context "全ダイスを収集済みの場合" do
        before do
          user.update!(reward_tickets: 1)
          User::COLLECTABLE_DICE_KEYS.each do |key|
            create(:user_dice_unlock, user: user, dice_key: key)
          end
        end

        it "プロフィールページへリダイレクトされること" do
          post use_ticket_profile_path
          expect(response).to redirect_to(profile_path)
        end

        it "新たなダイスが解放されないこと" do
          expect {
            post use_ticket_profile_path
          }.not_to change { user.dice_unlocks.count }
        end
      end
    end
  end
end
