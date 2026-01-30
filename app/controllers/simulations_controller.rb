class SimulationsController < ApplicationController
  def new
    @all_characters = current_user.characters.order(created_at: :desc)

    if params.has_key?(:enemy_id)
      session[:enemy_id] = params[:enemy_id].presence
    end
    if params.has_key?(:ally_id)
      session[:ally_id] = params[:ally_id].presence
    end

    @enemy_character = @all_characters.includes(:attacks).find_by(id: session[:enemy_id])
    @ally_character = @all_characters.includes(:attacks).find_by(id: session[:ally_id])


    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def combat_roll
    # 1. 値の取得(controllerの役割 :各メソッドへの値の取得と受け渡し)
    ally_character = current_user.characters.includes(:attacks).find_by(id: session[:ally_id])
    enemy_character = current_user.characters.includes(:attacks).find_by(id: session[:enemy_id])
    return render_error("キャラクターが見つかりませんでした") if ally_character.nil? || enemy_character.nil?

    ally_attack = ally_character.attacks.first
    enemy_attack = enemy_character.attacks.first
    return render_error("攻撃技能が見つかりませんでした") if ally_attack.nil? || enemy_attack.nil?

    outcome = BattleCoordinator.call(
      ally_character,
      enemy_character,
      ally_attack,
      enemy_attack,
      session[:ally_hp],
      session[:enemy_hp]
    )

    @sorted_results = outcome[:results]
    @decision = outcome[:decision]
    @finish_turn = outcome[:finish_turn]
    @determination = outcome[:determination]

    session[:ally_hp] = outcome.dig(:final_hp, :ally)
    session[:enemy_hp] = outcome.dig(:final_hp, :enemy)

    if outcome[:battle_ended]
      session.delete(:ally_hp)
      session.delete(:enemy_hp)
    end

    respond_to do |format|
      format.turbo_stream { render :roll } # roll.turbo_stream.erbを再利用
    end
  end
end
