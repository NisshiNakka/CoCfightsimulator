module LoginMacros
  def login_as(user)
    visit new_user_session_path
    fill_in 'ユーザー名', with: user.name
    fill_in 'パスワード', with: user.password
    click_button 'ログイン'
  end

  def logout
    click_on 'ログアウト'
  end
end
