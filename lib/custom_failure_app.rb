class CustomFailureApp < Devise::FailureApp
  def redirect
    store_location!
    
    if warden_message == :invalid
      flash[:alert] = "Invalid email or password"
    elsif warden_message == :not_authenticated_in_database
      flash[:alert] = "Invalid email or password"
    end
    
    redirect_to new_user_session_path
  end
end
