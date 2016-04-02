class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  include Concerns::AdditionalValidations
  include Concerns::Querying
end
