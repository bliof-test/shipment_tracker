# frozen_string_literal: true

class User
  include Virtus.value_object

  values do
    attribute :first_name, String
    attribute :email, String
  end

  def logged_in?
    email.present?
  end

  def owner_of?(repository)
    logged_in? && as_repo_admin.owner_of?(repository)
  end

  def as_repo_admin
    @repo_admin ||= RepoAdmin.find_by(email: email) || RepoAdmin.new(email: email, name: first_name)
  end
end
