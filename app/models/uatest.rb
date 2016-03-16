class Uatest
  include Virtus.value_object

  values do
    attribute :success, Boolean
    attribute :test_suite_version, String
  end
end
