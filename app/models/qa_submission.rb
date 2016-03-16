class QaSubmission
  include Virtus.value_object

  values do
    attribute :email, String
    attribute :comment, String
    attribute :accepted, Boolean
    attribute :created_at, Time
  end
end
