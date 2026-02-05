class UserPolicy < ApplicationPolicy
  def index?
    user.has_role?("admin")
  end

  def show?
    user.has_role?("admin") || user == record
  end

  def update?
    user.has_role?("admin") || user == record
  end

  def destroy?
    user.has_role?("admin")
  end

  def assign_role?
    user.has_role?("admin")
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.has_role?("admin")
        scope.all
      else
        scope.where(id: user.id)
      end
    end
  end
end
