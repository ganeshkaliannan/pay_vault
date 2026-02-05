module ApplicationHelper
  def current_page?(path)
    request.path == path
  end

  def devise_controller?
    defined?(Devise::Controller) && controller_path.include?('devise')
  end
end
