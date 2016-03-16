class User
  include Virtus.value_object

  values do
    attribute :first_name, String
    attribute :email, String
  end

  def logged_in?
    email.present?
  end
end
