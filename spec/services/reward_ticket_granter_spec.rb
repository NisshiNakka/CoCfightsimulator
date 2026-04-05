require 'rails_helper'

RSpec.describe RewardTicketGranter, type: :service do
  # after_create コールバックを持つ User を使う。
  # create(:user) 時点で first_registration が達成済み、reward_tickets が 1 になる。
  let(:user) { create(:user) }

  describe '.call' do
    subject(:granted) { RewardTicketGranter.call(user, action: action) }

    # ===== 初回利用マイルストーン =====
    context ':registration アクション' do
      let(:action) { :registration }

      it '初回は first_registration チケットを付与済みであること（after_create 時に付与）' do
        # after_create で既に付与されているため、2回目は付与しない
        expect { granted }.not_to change { user.reload.reward_tickets }
      end

      it '返り値が空配列であること（already achieved）' do
        expect(granted).to be_empty
      end
    end

    context ':profile_view アクション（初回）' do
      let(:action) { :profile_view }

      it 'first_profile_view マイルストーンを達成すること' do
        expect(granted).to include("first_profile_view")
      end

      it 'reward_tickets が 1 増加すること' do
        expect { granted }.to change { user.reload.reward_tickets }.by(1)
      end

      it '2回目は付与しないこと' do
        RewardTicketGranter.call(user, action: :profile_view)
        expect { RewardTicketGranter.call(user, action: :profile_view) }
          .not_to change { user.reload.reward_tickets }
      end
    end

    context ':character_create アクション（初回）' do
      let(:action) { :character_create }

      it 'first_character_create マイルストーンを達成すること' do
        expect(granted).to include("first_character_create")
      end

      it 'reward_tickets が 1 増加すること' do
        expect { granted }.to change { user.reload.reward_tickets }.by(1)
      end
    end

    context ':character_index アクション（初回）' do
      let(:action) { :character_index }

      it 'first_character_index マイルストーンを達成すること' do
        expect(granted).to include("first_character_index")
      end
    end

    context ':character_show アクション（初回）' do
      let(:action) { :character_show }

      it 'first_character_show マイルストーンを達成すること' do
        expect(granted).to include("first_character_show")
      end
    end

    context ':character_edit アクション（初回）' do
      let(:action) { :character_edit }

      it 'first_character_edit マイルストーンを達成すること' do
        expect(granted).to include("first_character_edit")
      end
    end

    context ':dice_update アクション（初回）' do
      let(:action) { :dice_update }

      it 'first_dice_update マイルストーンを達成すること' do
        expect(granted).to include("first_dice_update")
      end
    end

    context ':simulation アクション（初回）' do
      let(:action) { :simulation }

      it 'first_simulation マイルストーンを達成すること' do
        expect(granted).to include("first_simulation")
      end

      it 'reward_tickets が 1 増加すること' do
        expect { granted }.to change { user.reload.reward_tickets }.by(1)
      end
    end

    # ===== 累積マイルストーン =====
    context '累積マイルストーン: characters_3' do
      let(:action) { :character_create }

      context 'キャラクターが 3 体のとき' do
        before { create_list(:character, 3, user: user) }

        it 'characters_3 マイルストーンを達成すること' do
          expect(granted).to include("characters_3")
        end

        it 'characters_5 マイルストーンは達成しないこと' do
          expect(granted).not_to include("characters_5")
        end
      end

      context 'キャラクターが 2 体のとき' do
        before { create_list(:character, 2, user: user) }

        it 'characters_3 マイルストーンを達成しないこと' do
          expect(granted).not_to include("characters_3")
        end
      end
    end

    context '累積マイルストーン: simulations_3' do
      let(:action) { :simulation }

      context 'simulations_count が 3 のとき' do
        before { user.update!(simulations_count: 3) }

        it 'simulations_3 マイルストーンを達成すること' do
          expect(granted).to include("simulations_3")
        end
      end

      context 'simulations_count が 2 のとき' do
        before { user.update!(simulations_count: 2) }

        it 'simulations_3 マイルストーンを達成しないこと' do
          expect(granted).not_to include("simulations_3")
        end
      end
    end

    context '累積マイルストーン: edits_3' do
      let(:action) { :character_edit }

      context 'character_edits_count が 3 のとき' do
        before { user.update!(character_edits_count: 3) }

        it 'edits_3 マイルストーンを達成すること' do
          expect(granted).to include("edits_3")
        end
      end
    end

    context '累積マイルストーン: dice_updates_3' do
      let(:action) { :dice_update }

      context 'dice_updates_count が 3 のとき' do
        before { user.update!(dice_updates_count: 3) }

        it 'dice_updates_3 マイルストーンを達成すること' do
          expect(granted).to include("dice_updates_3")
        end
      end
    end

    # ===== 複数マイルストーン同時達成 =====
    context '初回 character_create かつ characters_3 同時達成' do
      let(:action) { :character_create }

      before { create_list(:character, 3, user: user) }

      it 'first_character_create と characters_3 の両方を達成すること' do
        expect(granted).to include("first_character_create", "characters_3")
      end

      it 'reward_tickets が 2 増加すること' do
        expect { granted }.to change { user.reload.reward_tickets }.by(2)
      end
    end

    # ===== 達成済みマイルストーンは再付与しない =====
    context '同じアクションを2回呼んだとき' do
      let(:action) { :profile_view }

      before { RewardTicketGranter.call(user, action: :profile_view) }

      it '2回目はチケットを付与しないこと' do
        expect { granted }.not_to change { user.reload.reward_tickets }
      end

      it '2回目は空配列を返すこと' do
        expect(granted).to be_empty
      end
    end

    # ===== 不明なアクションは何もしない =====
    context '不明なアクション' do
      let(:action) { :unknown_action }

      it 'チケットを付与しないこと' do
        expect { granted }.not_to change { user.reload.reward_tickets }
      end

      it '空配列を返すこと' do
        expect(granted).to be_empty
      end
    end
  end
end
