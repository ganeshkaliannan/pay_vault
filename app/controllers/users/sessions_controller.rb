class Users::SessionsController < Devise::SessionsController
  layout 'devise'

  # GET /resource/sign_in
  def new
    super
  end

  # POST /resource/sign_in
  def create
    self.resource = warden.authenticate(auth_options)

    if self.resource
      set_flash_message!(:notice, :signed_in)
      sign_in(resource_name, resource)
      yield resource if block_given?
      respond_with resource, location: after_sign_in_path_for(resource)
    else
      flash[:alert] = "Invalid email or password"
      redirect_to new_user_session_path
    end
  end

  # DELETE /resource/sign_out
  def destroy
    sign_out(current_user) if current_user
    flash[:notice] = "You have been logged out successfully."
    redirect_to new_user_session_path
  end

  protected

  def after_sign_in_path_for(resource)
    root_path
  end

  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end

  private

  def require_no_authentication
    if user_signed_in?
      redirect_to root_path
    end
  end
end
